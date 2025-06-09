Red [
	Title:   "Red command-line front-end"
	Author:  "Nenad Rakocevic, Andreas Bolka"
	File: 	 %red2.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation, Andreas Bolka. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Usage:   {
		do/args %red.r "path/source.red"
	}
]

rs-runtime-dir: append copy system/options/cache #either config/OS = 'Windows [%rs-runtime/][%.rs-runtime/]

delete-dir:	func [
	"Deletes a directory including all files and subdirectories."
	dir	[file! url!] 
	/local files
][
	if all [
		dir? dir 
		dir: dirize	dir	
		attempt	[files:	read dir]
	] [
		foreach	file files [delete-dir dir/:file]
	] 
	attempt	[delete	dir]
]

#include %system2/rs-runtime.red
#include %system2/compiler.red

check-rs-runtime: func [/local rt-dir ts-file][
	rt-dir: rs-runtime-dir
	ts-file: rs-runtime-dir/_timestamp.red

	if all [	;-- delete the older version
		exists? ts-file
		system/build/date > load ts-file
	][
		delete-dir rt-dir
	]
	
	unless exists? rt-dir [
		make-dir/deep rt-dir
		foreach [name data] rs-runtime [
			write/binary rejoin [rt-dir name] data
		]
		write ts-file system/build/date
	]
]

redc: context [
	targets:		#include %system2/config.red
	usage:			"Usage: red [command] [options] [file]"
	version:		0.7.0
	crush-lib:		none							;-- points to compiled crush library
	crush-compress: none							;-- compression function
	win-version:	100								;-- Windows version extracted from "ver" command
	SSE3?:			yes
	build-date:		now

	Linux?:    system/platform = 'Linux
	Windows?:  system/platform = 'Windows
	macOS?:    system/platform = 'macOS
	load-lib?: no

	;; Select a default target based on the platform
	default-target: does [
		any [
			switch/default system/platform [
				macOS ["Darwin"]
				Windows ["MSDOS"]
				Linux ["Linux"]
			]["MSDOS"]
		]
	]
	
	get-OS-name: does [system/platform]

	fail: func [value] [
		print value
		if system/options/args [quit/return 1]
		halt
	]
	
	fail-cmd: func [value][
		prin "*** Red command-line error: "
		fail value
	]

	fail-try: func [component body /local err] [
		if error? set/any 'err try body [
			fail [
				"***" component "Internal Error:" err/type newline
				"***" err/id newline
				"*** Where:" mold/flat err/where newline
				"*** Near: " copy/part mold/flat err/near 200 newline
			]
		]
	]

	format-time: func [time [time!]][
		round (time/second * 1000) + (time/minute * 60000)
	]

	decorate-name: func [name [file!]][
		rejoin [										;-- filename: <name>-year-month-day(ISO format)-time
			name #"-"
			build-date/year  "-"
			build-date/month "-"
			build-date/day   "-"
			to-integer build-date/time
		]
	]
	
	get-lib-suffix: does [
		case [
			Windows? [%.dll]
			macOS?   [%.dylib]
			'else    [%.so]
		]
	]

	load-filename: func [filename /local result] [
		unless any [
			all [
				#"%" = first filename
				attempt [result: load filename]
				file? result
			]
			attempt [result: to-red-file filename]
		][
			fail-cmd ["Invalid filename:" filename]
		]
		result
	]
	
	get-output-path: func [opts [object!] /local path][
		case [
			opts/build-basename [
				path: first split-path opts/build-basename
				either opts/build-prefix [join opts/build-prefix path][path]
			]
			opts/build-prefix [opts/build-prefix]
			'else			  [%""]
		]
	]

	red-system?: func [file [string!] /local ws rs?][
		ws: charset " ^-^M^/"
		parse/case file [
			some [
				thru "Red"
				opt ["/System" (rs?: yes)]
				any ws
				#"[" (return to logic! rs?)
			]
		]
		no
	]

	red?: func [file [string!] /local ws][
		ws: charset " ^-^M^/"
		parse/case file [
			some [
				[thru "Red" | thru "red" | thru "RED"]
				any ws
				#"[" (return yes)
			]
		]
		no
	]

	add-legacy-flags: func [opts [object!] /local out ver][
		if all [Windows? win-version <= 60][
			either opts/legacy [						;-- do not compile gesture support code for XP, Vista, Windows Server 2003/2008(R1)
				append opts/legacy 'no-touch
			][
				opts/legacy: copy [no-touch]
			]
		]
		all [
			not SSE3?
			any [
				all [Windows? opts/OS = 'Windows]
				all [Linux?   opts/OS = 'Linux]
			]
			opts/cpu-version: 1.0
		]
		if macOS? [						;-- macOS version extraction
			out: make string! 128
			call/output "sw_vers -productVersion" out
			attempt [
				ver: load out
				opts/OS-version: load rejoin [ver/1 #"." ver/2]
			]
		]
	]
	
	build-libRedRT: func [opts [object!] /local script result file path][
		print "Compiling libRedRT..."
		file: libRedRT/lib-file
		path: get-output-path opts
		
		opts: make opts [
			build-prefix: path
			build-basename: file
			type: 'dll
			libRedRT?: yes
			link?: yes
			unicode?: yes
		]
		if opts/OS <> 'Windows [opts/PIC?: yes]
		
		all [
			not empty? path: opts/build-prefix
			slash <> first path
			opts/build-prefix: head insert copy path %../
		]

		script: either all [
			opts/GUI-engine
			find [Windows macOS Linux] opts/OS
		][ [[Needs: [View CSV JSON]]] ][ [[Needs: [CSV JSON]]] ]
		
		result: red/compile script opts
		print [
			"...compilation time :" format-time result/2 "ms^/"
			"^/Compiling to native code..."
		]
		result: system-dialect/compile/options/loaded file opts result
		show-stats result
	]
	
	needs-libRedRT?: func [opts [object!] /local file path lib lib? get-date ts date current?][
		unless opts/dev-mode? [return no]
		
		path: get-output-path opts
		file: join path %libRedRT
		libRedRT/root-dir: path
		
		lib?: exists? lib: join file switch/default opts/OS [
			Windows [%.dll]
			macOS	[%.dylib]
		][%.so]
		
		if lib? [
			date: query lib
			current?: date > build-date
			ts: date
			if current? [print ["...using libRedRT built on" ts]]
		]
		not all [
			lib?
			current?
			exists? join path libRedRT/include-file
			exists? join path libRedRT/defs-file
		]
	]
	
	to-percent: func [v [float!]][copy/part mold v * 100 5]
	
	show-stats: func [result /local words][
		print ["...parsing time     :" format-time result/1 "ms"]
		print ["...compilation time :" format-time result/2 "ms"]
		words: length? keys-of system/words
		
		if result/3 [
			print [
				"...global words     :" words rejoin [#"(" to-percent words / 32894 "%)^/"]
				"...linking time     :" format-time result/3 "ms^/"
				"...output file size :" result/4 "bytes^/"
				"...output file      :" to-local-file result/5 lf
			]
		]
	]
	
	do-clear: func [args [block!] /local path file][
		either empty? args [path: %""][
			path: either args/1/1 = #"%" [
				attempt [load args/1]
			][
				attempt [to-red-file args/1]
			]
			unless all [path exists? path][
				fail-cmd "`red clear` command error: invalid path"
			]
		]
		foreach ext [%.dll %.dylib %.so][
			if exists? file: rejoin [path libRedRT/lib-file ext][delete file]
		]
		foreach file [include-file defs-file extras-file][
			if exists? file: join path libRedRT/:file [delete file]
		]
		reduce [none none]
	]
	
	do-build: func [args [block!] /local cmd src][
		switch/default args/1 [
			"libRed" [
				cmd: copy "-r libRed/libRed.red"
				if all [not tail? next args args/2 = "stdcall"][
					insert at cmd 3 { --config "[export-ABI: 'stdcall]"}
				]
				parse-options cmd
			]
		][
			fail-cmd reform ["Unknown command" args/1]
		]
	]

	parse-options: func [
		args [string! none!]
		/local src opts output target verbose filename config config-name base-path type
		mode target? cmd spec cmds ws ssp view? modes
	][
		unless args [
			args: any [system/options/args system/script/args ""] ;-- ssa for quick-test.r
		]	

		;unless block? args [args: split-tokens args]
		
		target: default-target
		opts: make system-dialect/options-class [
			link?: yes
			libRedRT-update?: no
		]
		view?: yes										;-- include view module by default

		either empty? args [
			mode: 'help
		][
			if cmd: select [
				"clear" do-clear
				"build" do-build
				"halt"	'halt
			] first args [
				return do reduce [cmd next args]
			]
		]
		modes: clear []

		parse/case args [
			any [
				  ["-c" | "--compile"]			(type: 'exe append modes '-c)
				| ["-r" | "--release"]			(type: 'exe opts/dev-mode?: no append modes '-r)
				| ["-e" | "--encap"]			(opts/encap?: yes)
				| ["-d" | "--debug-stabs" | "--debug"]	(opts/debug?: yes)
				| ["-o" | "--output"]			[set output  skip | (fail-cmd "Missing output filename")]
				| ["-t" | "--target"]			[set target  skip | (fail-cmd "Missing target")] (target?: yes)
				| ["-v" | "--verbose"]			[set verbose skip | (fail-cmd "Missing verbosity")] ;-- 1-3: Red, >3: Red/System
				| ["-h" | "--help"]				(mode: 'help)
				| ["-V" | "--version"]			(mode: 'version)
				| ["-u"	| "--update-libRedRT"]	(type: 'exe opts/dev-mode?: no opts/libRedRT-update?: yes append modes '-u)
				| ["-s" | "--show-expanded"]	(opts/show: 'expanded)
				| ["-dlib" | "--dynamic-lib"]	(type: 'dll)
				;| ["-slib" | "--static-lib"]	(type 'lib)
				| "--config" set spec skip		(attempt [spec: load spec])
				| "--red-only"					(opts/red-only?: yes)
				| "--dev"						(opts/dev-mode?: yes)
				| "--no-runtime"				(opts/runtime?: no)		;@@ overridable by config!
				| "--no-view"					(opts/GUI-engine: none view?: no)
				| "--no-compress"				(opts/redbin-compress?: no)
				| "--show-func-map"				(opts/show-func-map?: yes)
				| "--" break							;-- stop options processing
			]
			set filename skip (unless empty? filename [src: load-filename filename])
		]
		if 1 < length? modes [
			fail-cmd ["Incompatible compilation modes:" mold/only modes]
		]

		if mode [
			switch mode [
				help	[print usage]
				version [print version]
			]
			quit/return 0
		]

		;; Process -t/--target first, so that all other command-line options
		;; can potentially override the target config settings.
		unless config: select targets config-name: to word! trim target [
			fail-cmd ["Unknown target:" target]
		]
		if target? [unless type [type: 'exe]]			;-- implies compilation
		
		ssp: system/script/parent
		base-path: any [
			all [ssp ssp/path]
			system/options/path
		]

		opts: make opts config
		opts/config-name: config-name
		opts/build-prefix: base-path

		if all [target? none? opts/dev-mode?][
			opts/dev-mode?: opts/OS = get-OS-name		;-- forces release mode if other OS
		]

		;; Process -o/--output (if any).
		if output [
			either slash = last output [
				attempt [opts/build-prefix: to-red-file output]
			][
				opts/build-basename: load-filename output
				if slash = first opts/build-basename [
					opts/build-prefix: %""
				]
			]
		]

		;; Process -v/--verbose (if any).
		if verbose [
			unless attempt [opts/verbosity: to integer! trim verbose] [
				fail-cmd ["invalid verbosity:" verbose]
			]
		]

		;; Process -dlib/--dynamic-lib (if any).
		if any [type = 'dll opts/type = 'dll][
			if type = 'dll [opts/type: type]
			if opts/OS <> 'Windows [opts/PIC?: yes]
		]

		;; Check common syntax mistakes
		if all [
			any [type output verbose target?]			;-- -c | -o | -dlib | -t | -v
			none? src
		][
			fail-cmd "Source file is missing"
		]
		if all [output output/1 = #"-"][				;-- -o (not followed by option)
			fail-cmd "Missing output file or path"
		]

		;; Process input sources.
		unless src [return reduce [none none]]

		if slash <> first src [							;-- if relative path
			src: clean-path join base-path src			;-- add working dir path
		]
		unless exists? src [
			fail-cmd ["Cannot access source file:" to-local-file src]
		]

		add-legacy-flags opts
		if spec [
			opts: make opts spec
			opts/command-line: spec
		]
		
		if none? opts/dev-mode? [opts/dev-mode?: yes]	;-- fallback to dev mode if undefined
		
		reduce [src opts]
	]
	
	compile: func [src opts /local result saved rs? data][
		print [	"Compiling" to-local-file src "..."]

		data: read src
		unless rs?: red-system? data [
			unless red? data [fail "*** Syntax Error: Invalid Red program"]

	;--- 1st pass: Red compiler ---
			if needs-libRedRT? opts [build-libRedRT opts]
			
			fail-try "Red Compiler" [
				result: red/compile src opts
			]
			print ["...compilation time :" format-time result/2 "ms"]
			if opts/red-only? [probe result/1 return none]
		]

	;--- 2nd pass: Red/System compiler ---

		print [
			newline
			"Target:" opts/config-name lf lf
			"Compiling to native code..."
		]
		fail-try "Red/System Compiler" [
			result: either rs? [
				system-dialect/compile/options src opts
			][
				opts/unicode?: yes							;-- force Red/System to use Red's Unicode API
				opts/verbosity: max 0 opts/verbosity - 3	;-- Red/System verbosity levels upped by 3
				system-dialect/compile/options/loaded src opts result
			]
		]
		result
	]

	main: func [/with cmd [string!] /local src opts build-dir prefix result file][
		set [src opts] parse-options cmd
		unless src [do opts exit]						;-- run named command and terminates

		;-- If we use a build directory, ensure it exists.
		if all [prefix: opts/build-prefix find prefix %/] [
			build-dir: copy/part prefix find/last prefix %/
			unless attempt [make-dir/deep build-dir] [
				fail-cmd ["Cannot access build dir:" to-local-file build-dir]
			]
		]
		
		;-- Try to get version data from git repository if present
	
		print [lf "-=== Red Compiler" version "===-" lf]

		;-- libRedRT updating mode
		if opts/libRedRT-update? [
			if exists? file: rejoin [get-output-path opts %libRedRT get-lib-suffix][
				delete file
			]
			opts/dev-mode?: opts/link?: no
			compile src opts
			print ["libRedRT-extras.red file generated, recompiling..." lf]
			opts/dev-mode?: opts/link?: yes
			opts/libRedRT-update?: no
		]
		
		if result: compile src opts [
			show-stats result
			unless Windows? [print ""]					;-- extra LF for more readable output
		]
	]

	set 'rc func [cmd [file! string! block!]][
		fail-try "Driver" [redc/main/with reform cmd]
		()												;-- return unset value
	]
]

check-rs-runtime

redc/fail-try "Driver" [redc/main]
quit/return 0
