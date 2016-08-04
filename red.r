REBOL [
	Title:   "Red command-line front-end"
	Author:  "Nenad Rakocevic, Andreas Bolka"
	File: 	 %red.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic, Andreas Bolka. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Usage:   {
		do/args %red.r "path/source.red"
	}
	Encap: [quiet secure none title "Red" no-window]
]

unless value? 'encap-fs [do %system/utils/encap-fs.r]

unless all [value? 'red object? :red][
	do-cache %compiler.r
]

redc: context [
	crush-lib:		none								;-- points to compiled crush library
	crush-compress: none								;-- compression function
	win-version:	none								;-- Windows version extracted from "ver" command

	Windows?:  system/version/4 = 3
	load-lib?: any [encap? find system/components 'Library]

	if encap? [
		temp-dir: switch/default system/version/4 [
			2 [											;-- MacOS X
				libc: load/library %libc.dylib
				sys-call: make routine! [cmd [string!]] libc "system"
				join any [attempt [to-rebol-file get-env "HOME"] %/tmp] %/.red/
			]
			3 [											;-- Windows
				either lib?: find system/components 'Library [
					sys-path: to-rebol-file get-env "SystemRoot"
					shell32: load/library sys-path/System32/shell32.dll
					libc:  	 load/library sys-path/System32/msvcrt.dll

					CSIDL_COMMON_APPDATA: to integer! #{00000023}

					SHGetFolderPath: make routine! [
							hwndOwner 	[integer!]
							nFolder		[integer!]
							hToken		[integer!]
							dwFlags		[integer!]
							pszPath		[string!]
							return: 	[integer!]
					] shell32 "SHGetFolderPathA"

					ShellExecute: make routine! [
							hwnd 		 [integer!]
							lpOperation  [string!]
							lpFile		 [string!]
							lpParameters [string!]
							lpDirectory  [integer!]
							nShowCmd	 [integer!]
							return:		 [integer!]
					] shell32 "ShellExecuteA"

					sys-call: make routine! [cmd [string!] return: [integer!]] libc "system"

					gui-sys-call: func [cmd [string!] args [string!]][
						ShellExecute 0 "open" cmd args 0 1
					]

					path: head insert/dup make string! 255 null 255
					unless zero? SHGetFolderPath 0 CSIDL_COMMON_APPDATA 0 0 path [
						fail "SHGetFolderPath failed: can't determine temp folder path"
					]
					append dirize to-rebol-file trim path %Red/
				][
					sys-call: func [cmd][call/wait cmd]
					append to-rebol-file get-env "ALLUSERSPROFILE" %/Red/
				]
			]
		][												;-- Linux (default)
			any [
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
			sys-call: make routine! [cmd [string!]] libc "system"
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
        			attempt [load copy/part back remove pos 2]
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

	fail: func [value] [
		print value
		if system/options/args [quit/return 1]
		halt
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

	load-filename: func [filename /local result] [
		unless any [
			all [
				#"%" = first filename
				attempt [result: load filename]
				file? result
			]
			attempt [result: to-rebol-file filename]
		] [
			fail ["Invalid filename:" filename]
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

	red-system?: func [file [file!] /local ws rs?][
		ws: charset " ^-^/^M"
		parse/all/case read file [
			some [
				thru "Red"
				opt ["/System" (rs?: yes)]
				any ws
				#"[" (return to logic! rs?)
				to end
			]
		]
		no
	]

	safe-to-local-file: func [file [file! string!]][
		if all [
			find file: to-local-file file #" "
			Windows?
		][
			file: rejoin [{"} file {"}]					;-- avoid issues with blanks in path
		]
		file
	]

	add-legacy-flags: func [opts [object!] /local out ver][
		if all [Windows? win-version <= 60][
			either opts/legacy [						;-- do not compile gesture support code for XP, Vista, Windows Server 2003/2008(R1)
				append opts/legacy 'no-touch
			][
				opts/legacy: copy [no-touch]
			]
		]
		if system/version/4 = 2 [						;-- macOS version extraction
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
		filename: append temp-dir/:basename case [
			Windows? 			 [%.dll]
			system/version/4 = 2 [%.dylib]
			'else 				 [%.so]
		]

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

	run-console: func [
		gui? [logic!] /with file [string!]
		/local opts result script filename exe console files source con-engine gui-target
	][
		script: temp-dir/red-console.red
		filename: decorate-name pick [%gui-console %console] gui?
		exe: temp-dir/:filename

		if Windows? [append exe %.exe]

		unless exists? temp-dir [make-dir temp-dir]
		unless exists? exe [
			console: %environment/console/
			con-engine: pick [%gui-console.red %console.red] gui?
			if gui? [
				gui-target: select [
					;"Darwin"	OSX
					"MSDOS"		Windows
					;"Linux"		Linux-GTK
				] default-target
			]
			source: copy read-cache console/:con-engine
			if all [Windows? not gui?][insert find/tail source #"[" "Needs: 'View^/"]
			write script source

			files: [
				%auto-complete.red %engine.red %help.red %input.red
				%wcwidth.reds %win32.reds %POSIX.reds %terminal.reds
				%windows.reds
			]
			foreach file files [write temp-dir/:file read-cache console/:file]

			opts: make system-dialect/options-class [	;-- minimal set of compilation options
				link?: yes
				unicode?: yes
				config-name: any [gui-target to word! default-target]
				build-basename: filename
				build-prefix: temp-dir
				red-help?: yes							;-- include doc-strings
				gui-console?: gui?
			]
			opts: make opts select load-targets opts/config-name
			add-legacy-flags opts

			print replace "Compiling Red $console..." "$" pick ["GUI " ""] gui?
			result: red/compile script opts
			system-dialect/compile/options/loaded script opts result

			delete script
			foreach file files [delete temp-dir/:file]

			if all [Windows? not lib?][
				print "Please run red.exe again to access the console."
				quit/return 1
			]
		]
		exe: safe-to-local-file exe

		either gui? [
			gui-sys-call exe any [file make string! 1]
		][
			if with [
				repend exe [{ "} file {"}]
				exe: safe-to-local-file exe
			]
			sys-call exe								;-- replace the buggy CALL native
		]
		quit/return 0
	]

	parse-options: func [
		args [string! none!]
		/local src opts output target verbose filename config config-name base-path type
		mode target? gui?
	][
		args: any [
			all [args parse args none]
			system/options/args
			parse any [system/script/args ""] none
		]
		target: default-target
		opts: make system-dialect/options-class [link?: yes]
		gui?: Windows?									;-- use GUI console by default on Windows

		parse/case args [
			any [
				  ["-c"	| "--compile"]		(type: 'exe)
				| ["-r" | "--no-runtime"]   (opts/runtime?: no)		;@@ overridable by config!
				| ["-d" | "--debug" | "--debug-stabs"]	(opts/debug?: yes)
				| ["-o" | "--output"]  		set output skip
				| ["-t" | "--target"]  		set target skip (target?: yes)
				| ["-v" | "--verbose"] 		set verbose skip	;-- 1-3: Red, >3: Red/System
				| ["-h" | "--help"]			(mode: 'help)
				| ["-V" | "--version"]		(mode: 'version)
				| "--red-only"				(opts/red-only?: yes)
				| "--cli"					(gui?: no)
				| "--catch"								;-- just pass-thru
				| ["-dlib" | "--dynamic-lib"] (type: 'dll)
				;| ["-slib" | "--static-lib"] (type 'lib)
			]
			set filename skip (src: load-filename filename)
		]

		if mode [
			switch mode [
				help	[print read-cache %usage.txt]
				version [print load-cache %version.r]
			]
			quit/return 0
		]

		;; Process -t/--target first, so that all other command-line options
		;; can potentially override the target config settings.
		unless config: select load-targets config-name: to word! trim target [
			fail ["Unknown target:" target]
		]
		base-path: either encap? [
			system/options/path
		][
			system/script/parent/path
		]
		opts: make opts config
		opts/config-name: config-name
		opts/build-prefix: base-path

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
				fail ["Invalid verbosity:" verbose]
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
			fail "Source file is missing"
		]
		if all [output output/1 = #"-"][				;-- -o (not followed by option)
			fail "Missing output file or path"
		]

		;; Process input sources.
		unless src [
			either encap? [
				if load-lib? [build-compress-lib]
				run-console gui?
			][
				fail "No source files specified."
			]
		]

		if all [encap? none? output none? type][
			if load-lib? [build-compress-lib]
			run-console/with gui? filename
		]

		if slash <> first src [							;-- if relative path
			src: clean-path join base-path src			;-- add working dir path
		]
		unless exists? src [
			fail ["Cannot access source file:" to-local-file src]
		]

		add-legacy-flags opts

		reduce [src opts]
	]

	main: func [/with cmd [string!] /local src opts build-dir result saved rs? prefix] [
		set [src opts] parse-options cmd

		rs?: red-system? src

		;; If we use a build directory, ensure it exists.
		if all [prefix: opts/build-prefix find prefix %/] [
			build-dir: copy/part prefix find/last prefix %/
			unless attempt [make-dir/deep build-dir] [
				fail ["Cannot access build dir:" to-local-file build-dir]
			]
		]

		print [
			newline
			"-=== Red Compiler" read-cache %version.r "===-" newline newline
			"Compiling" to-local-file src "..."
		]

		unless rs? [
	;--- 1st pass: Red compiler ---
			if load-lib? [build-compress-lib]

			fail-try "Red Compiler" [
				result: red/compile src opts
			]
			print ["...compilation time :" format-time result/2 "ms"]
			if opts/red-only? [exit]
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
		print ["...compilation time :" format-time result/1 "ms"]

		if result/2 [
			print [
				"...linking time     :" format-time result/2 "ms^/"
				"...output file size :" result/3 "bytes^/"
				"...output file      :" to-local-file result/4 lf
			]
		]
		unless Windows? [print ""]						;-- extra LF for more readable output
	]

	set 'rc func [cmd [file! string! block!]][
		fail-try "Driver" [redc/main/with reform cmd]
		()												;-- return unset value
	]
]

redc/fail-try "Driver" [redc/main]
if encap? [quit/return 0]
