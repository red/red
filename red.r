REBOL [
	Title:   "Red command-line front-end"
	Author:  "Nenad Rakocevic, Andreas Bolka"
	File: 	 %red.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation, Andreas Bolka. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Usage:   {
		do/args %red.r "path/source.red"
	}
	Encap: [quiet secure none cgi title "Red" no-window]
]

unless value? 'encap-fs [do %utils/encap-fs.r]

unless all [value? 'red object? :red][
	do-cache %encapper/compiler.r
]

redc: context [
	crush-lib:		none								;-- points to compiled crush library
	crush-compress: none								;-- compression function
	win-version:	none								;-- Windows version extracted from "ver" command
	SSE3?:			yes

	Linux?:    system/version/4 = 4
	Windows?:  system/version/4 = 3
	macOS?:    system/version/4 = 2
	load-lib?: any [encap? find system/components 'Library]

	if encap? [
		temp-dir: switch/default system/version/4 [
			2 [											;-- MacOS X
				libc: load/library %libc.dylib
				sys-call: make routine! [cmd [string!] return: [integer!]] libc "system"
				join any [attempt [to-rebol-file get-env "HOME"] %/tmp] %/.red/
			]
			3 [											;-- Windows
				either lib?: find system/components 'Library [
					sys-path: to-rebol-file get-env "SystemRoot"
					shell32:  load/library sys-path/System32/shell32.dll
					kernel32: load/library sys-path/System32/kernel32.dll
					libc:  	  load/library sys-path/System32/msvcrt.dll

					CSIDL_COMMON_APPDATA: to integer! #{00000023}

					SHGetFolderPath: make routine! [
						hwndOwner 	[integer!]
						nFolder		[integer!]
						hToken		[integer!]
						dwFlags		[integer!]
						pszPath		[string!]
						return: 	[integer!]
					] shell32 "SHGetFolderPathA"

					ShellExecuteW: make routine! [
						hwnd 		 [integer!]
						lpOperation  [string!]
						lpFile		 [string!]
						lpParameters [string!]
						lpDirectory  [integer!]
						nShowCmd	 [integer!]
						return:		 [integer!]
					] shell32 "ShellExecuteW"
					
					GetCommandLineW: make routine! compose/deep [
						return: [integer!]
					] kernel32 "GetCommandLineW"

					WideCharToMultiByte: make routine! [
						CodePage				[integer!]
						dwFlags					[integer!]
						lpWideCharStr			[integer!]
						cchWideChar				[integer!]
						lpMultiByteStr			[string!]
						cbMultiByte				[integer!]
						lpDefaultChar			[integer!]
						lpUsedDefaultChar		[integer!]
						return:					[integer!]
					] kernel32 "WideCharToMultiByte"

					_wsystem: make routine! [cmd [string!] return: [integer!]] libc "_wsystem"
					
					IsProcessorFeaturePresent: make routine! [feat [integer!] return: [integer!]] kernel32 "IsProcessorFeaturePresent"

					gui-sys-call: func [cmd [string!] args [string!]][
						ShellExecuteW
							0
							utf8-to-utf16 "open"
							utf8-to-utf16 cmd
							utf8-to-utf16 args
							0 1
					]
					
					sys-call: func [cmd [string!]][_wsystem utf8-to-utf16 cmd]
					
					SSE3?: to logic! IsProcessorFeaturePresent 13
					
					path: head insert/dup make string! 255 null 255
					unless zero? SHGetFolderPath 0 CSIDL_COMMON_APPDATA 0 0 path [
						fail "SHGetFolderPath failed: can't determine temp folder path"
					]
					append dirize to-rebol-file trim path %Red/
				][
					sys-call: func [cmd [string!]][call/wait cmd]
					append to-rebol-file get-env "ALLUSERSPROFILE" %/Red/
				]
			]
		][												;-- Linux (default)
			cpuinfo: attempt [read %/proc/cpuinfo]
			either cpuinfo [
				SSE3?: parse cpuinfo [thru "flags" to "sse3" to end]
			][
				fail "Can't read /proc/cpuinfo"
			]
			any [
				exists? libc: %/lib/ld-musl-i386.so.1			; musl, e.g. Alpine Linux
				exists? libc: %libc.so.6
				exists? libc: %/lib32/libc.so.6
				exists? libc: %/lib/i386-linux-gnu/libc.so.6	; post 11.04 Ubuntu
				exists? libc: %/usr/lib32/libc.so.6				; e.g. 64-bit Arch Linux
				exists? libc: %/lib/libc.so.6
				exists? libc: %/System/Index/lib/libc.so.6  	; GoboLinux package
				exists? libc: %/system/index/framework/libraries/libc.so.6  ; Syllable
				exists? libc: %/lib/libc.so.5
			]
			libc: load/library libc
			sys-call: make routine! [cmd [string!] return: [integer!]] libc "system"
			join any [attempt [to-rebol-file get-env "HOME"] %/tmp] %/.red/
		]
	]

	if Windows? [
		use [buf cmd][
			cmd: "cmd /c ver"
			buf: make string! 128

			either load-lib? [
				do-cache %utils/call.r					;@@ put `call.r` in proper place when we encap
				win-call/output cmd buf
			][
				set 'win-call :call						;-- Rebol/Core compatible mode
				win-call/output/show cmd buf			;-- not using /show would freeze CALL
			]
			parse/all buf [[thru "[" | thru "Version" | thru "ver" | thru "v" | thru "indows"] to #"." pos:]
			
			win-version: any [
				attempt [load copy/part back back remove pos 3]
				0
			]
		]
	]

	;; Select a default target based on the REBOL version.
	default-target: does [
		any [
			switch/default system/version/4 [
				2 ["Darwin"]
				3 ["MSDOS"]
				4 [either system/version/5 = 8 ["RPI"]["Linux"]]
				7 ["FreeBSD"]
			]["MSDOS"]
		]
	]
	
	get-OS-name: does [
		switch/default system/version/4 [
			2 ['macOS]
			3 ['Windows]
			4 ['Linux]
		]['Linux]										;-- usage related to lib suffixes
	]

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
			err: disarm err
			foreach w [arg1 arg2 arg3][
				set w either unset? get/any in err w [none][
					get/any in err w
				]
			]
			fail [
				"***" component "Internal Error:"
				system/error/(err/type)/type #":"
				reduce system/error/(err/type)/(err/id) newline
				"*** Where:" mold/flat err/where newline
				"*** Near: " mold/flat err/near newline
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
			attempt [result: to-rebol-file filename]
		][
			fail-cmd ["Invalid filename:" filename]
		]
		result
	]

	load-targets: func [/local targets] [
		targets: load-cache %system/config.r
		if exists? %system/custom-targets.r [
			insert targets load %system/custom-targets.r
		]
		targets
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
		parse/all/case file [
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
		parse/all/case file [
			some [
				[thru "Red" | thru "red" | thru "RED"]
				any ws
				#"[" (return yes)
			]
		]
		no
	]

	fetch-cmdline: has [cmd buffer size][
		either Windows? [
			cmd: GetCommandLineW
			size: WideCharToMultiByte 65001 0 cmd -1 "" 0 0 0  ;-- CP_UTF8
			buffer: make string! size + 1
			insert/dup buffer null size + 1

			WideCharToMultiByte 65001 0 cmd -1 buffer size 0 0 ;-- CP_UTF8
			while [null = last buffer][take/last buffer]
			system/options/args: remove split-tokens system/script/args: buffer
		][
		
		]
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

	build-compress-lib: has [script basename filename text opts ext src][
		src: %runtime/crush.reds

		basename: either encap? [
			unless exists? temp-dir [make-dir temp-dir]
			script: temp-dir/crush.reds
			decorate-name %crush
		][
			temp-dir: %./
			script: %crush.reds
			copy %crush
		]
		filename: append temp-dir/:basename get-lib-suffix

		if any [
			not exists? filename
			all [
				not encap?
				(modified? filename) < modified? src
			]
		][
			if crush-lib [
				free crush-lib
				crush-lib: none
			]
			text: copy read-cache src
			append text " #export [crush/compress]"
			write script text
			unless encap? [basename: head insert basename %../]

			opts: make system-dialect/options-class [	;-- minimal set of compilation options
				link?: yes
				config-name: to word! default-target
				build-basename: basename
				build-prefix: temp-dir
				dev-mode?: no
			]
			opts: make opts select load-targets opts/config-name
			opts/type: 'dll
			if opts/OS <> 'Windows [opts/PIC?: yes]
			add-legacy-flags opts

			print "Compiling compression library..."
			unless encap? [
				change-dir %system/
				script: head insert script %../
			]
			system-dialect/compile/options script opts
			delete script
			unless encap? [change-dir %../]
		]

		unless crush-lib [
			crush-lib: load/library filename
			crush-compress: make routine! [
				in		[binary!]
				size	[integer!]						;-- size in bytes
				out		[binary!]						;-- output buffer (pre-allocated)
				return: [integer!]						;-- compressed data size
			] crush-lib "crush/compress"
		]
	]
	
	build-libRedRT: func [opts [object!] /local script result file path saved][
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
			not encap?
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
		saved: opts/verbosity
		opts/verbosity: max 0 opts/verbosity - 3
		unless encap? [change-dir %system/]
		result: system-dialect/compile/options/loaded file opts result
		unless encap? [change-dir %../]
		opts/verbosity: saved
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
			date: modified? lib
			current?: any [not encap? date > build-date]
			
			either all [load-lib? opts/OS = get-OS-name][
				lib: load/library lib
				get-date: make routine! [return: [string!]] lib "red/get-build-date"
				ts: get-date
				free lib
			][
				ts: date
			]
			if current? [print ["...using libRedRT built on" ts]]
		]
		not all [
			lib?
			current?
			exists? join path libRedRT/include-file
			exists? join path libRedRT/defs-file
		]
	]
	
	to-percent: func [v [decimal!]][copy/part mold v * 100 5]
	
	show-stats: func [result /local words][
		print ["...compilation time :" format-time result/1 "ms"]
		words: length? first system/words
		
		if result/2 [
			print [
				"...global words     :" words rejoin [#"(" to-percent words / 32894 "%)^/"]
				"...linking time     :" format-time result/2 "ms^/"
				"...output file size :" result/3 "bytes^/"
				"...output file      :" to-local-file result/4 lf
			]
		]
	]
	
	do-clear: func [args [block!] /local path file][
		either empty? args [path: %""][
			path: either args/1/1 = #"%" [
				attempt [load args/1]
			][
				attempt [to-rebol-file args/1]
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
				if all [encap? not exists? %libRed/][
					make-dir path: %libRed/
					foreach file [
						%libRed.def
						%libRed.red
						%red.h
					][
						write path/:file read-cache path/:file
					]
					write/binary path/libRed.lib read-cache path/libRed.lib
				]
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
	
	;-- it's a Windows-only function, since on POSIX OSes arguments are initially a block
	split-tokens: func [args /save into /local ws s e -split-mode- switch-mode arg-end][
		ws: charset " ^-" 								;-- according to MSDN "Parsing C++ Command-Line Arguments" article
		-split-mode-: tail [end skip] 					;-- dynamic (optionally failing) rule for whitespace behavior
		switch-mode: does [-split-mode-: skip head -split-mode- length? -split-mode-]
		collect [
			arg-end: has [s' e'] [
				unless same? s': s e': e [ 				;-- empty argument check
					;-- remove heading and trailing quotes (if any), even if it results in an empty arg
					if s/1 = #"^"" [s': next s]
					if all [e/-1 = #"^""  not same? e s'] [e': back e]
					keep copy/part s' e'
					if into [repend into [s e]]
				]
			]
			parse/all s: args [							;-- tokenize and collect
				some [e:
					#"^"" (switch-mode)
				|	-split-mode- some ws (arg-end) s:
				|	skip
				] e: (arg-end)
			]
		]
	]

	parse-options: func [
		args [string! none!]
		/local src opts output target verbose filename config config-name base-path type
		mode target? cmd spec cmds ws ssp modes engine
	][
		unless args [
			if encap? [fetch-cmdline]					;-- Fetch real command-line in UTF8 format
			args: any [system/options/args system/script/args ""] ;-- ssa for quick-test.r
		]	
		unless block? args [args: split-tokens args]
		
		target: default-target
		opts: make system-dialect/options-class [
			link?: yes
			libRedRT-update?: no
		]
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
				| "--no-view"					(opts/GUI-engine: none)
				| "--no-compress"				(opts/redbin-compress?: no)
				| "--show-func-map"				(opts/show-func-map?: yes)
				| "--view" set engine skip		(append any [spec spec: copy []] compose [GUI-engine: (to-lit-word load engine)])
				| "--" break							;-- stop options processing
			]
			set filename skip (unless empty? filename [src: load-filename filename])
		]
		if 1 < length? modes [
			fail-cmd ["Incompatible compilation modes:" mold/only modes]
		]

		if all [encap? mode][
			switch mode [
				help	[print read-cache %encapper/usage.txt]
				version [print load-cache %encapper/version.r]
			]
			quit/return 0
		]

		;; Process -t/--target first, so that all other command-line options
		;; can potentially override the target config settings.
		unless config: select load-targets config-name: to word! trim target [
			fail-cmd ["Unknown target:" target]
		]
		if target? [unless type [type: 'exe]]			;-- implies compilation
		
		base-path: either encap? [
			system/options/path
		][
			ssp: system/script/parent
			any [
				all [ssp ssp/path]
				system/script/path
			]
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
				attempt [opts/build-prefix: to-rebol-file output]
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
			if load-lib? [build-compress-lib]
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
			unless encap? [change-dir %system/]
			result: either rs? [
				system-dialect/compile/options src opts
			][
				opts/unicode?: yes							;-- force Red/System to use Red's Unicode API
				opts/verbosity: max 0 opts/verbosity - 3	;-- Red/System verbosity levels upped by 3
				system-dialect/compile/options/loaded src opts result
			]
			unless encap? [change-dir %../]
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
		unless encap? [save %build/git.r do %build/git-version.r]
		
		print [lf "-=== Red Compiler" read-cache %encapper/version.r "===-" lf]

		;-- libRedRT updating mode
		if opts/libRedRT-update? [
			if exists? file: rejoin [get-output-path opts %libRedRT get-lib-suffix][
				delete file
			]
			opts/dev-mode?: opts/link?: no
			compile src opts
			print ["libRedRT-extras.r file generated, recompiling..." lf]
			opts/dev-mode?: opts/link?: yes
			opts/libRedRT-update?: no
		]
		
		if result: compile src opts [
			show-stats result
			if all [word: in opts 'packager get word][
				file: join %system/formats/ [opts/packager %.r]
				unless exists?-cache file [fail-cmd ["Packager:" opts/packager "not found!"]]
				do bind load-cache file 'self
				packager/process opts src result/4
			]
			unless Windows? [print ""]					;-- extra LF for more readable output
		]
	]

	set 'rc func [cmd [file! string! block!]][
		fail-try "Driver" [redc/main/with reform cmd]
		()												;-- return unset value
	]
]

redc/fail-try "Driver" [redc/main]
if encap? [quit/return 0]
