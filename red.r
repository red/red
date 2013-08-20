REBOL [
	Title:   "Red command-line front-end"
	Author:  "Nenad Rakocevic, Andreas Bolka"
	File: 	 %red.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic, Andreas Bolka. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
	Usage:   {
		do/args %red.r "-o path/source.red"
	}
	Encap: [quiet secure none title "Red" no-window] 
]

unless value? 'encap-fs [do %red-system/utils/encap-fs.r]

unless all [value? 'red object? :red][
	do-cache %red/compiler.r
]

redc: context [

	Windows?: system/version/4 = 3
	
	if encap? [
		temp-dir: switch/default system/version/4 [
			2 [											;-- MacOS X
				libc: load/library %libc.dylib
				sys-call: make routine! [cmd [string!]] libc "system"
				%/tmp/red/
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

					sys-call: make routine! [cmd [string!] return: [integer!]] libc "system"

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
				exists? libc: %/lib/libc.so.6
				exists? libc: %/System/Index/lib/libc.so.6  	; GoboLinux package
				exists? libc: %/system/index/framework/libraries/libc.so.6  ; Syllable
				exists? libc: %/lib/libc.so.5
			]
			libc: load/library libc
			sys-call: make routine! [cmd [string!]] libc "system"
			%/tmp/red/
		]
	]
	
	;; Select a default target based on the REBOL version.
	default-target: does [
		any [
			select [
				2 "Darwin"
				3 "MSDOS"
				4 "Linux"
			] system/version/4
			"MSDOS"
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
		targets: load-cache %red-system/config.r
		if exists? %red-system/custom-targets.r [
			insert targets load %red-system/custom-targets.r
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
	
	run-console: has [opts result script exe][
		script: temp-dir/red-console.red
		exe: temp-dir/console
		if Windows? [append exe %.exe]
		
		unless exists? temp-dir [make-dir temp-dir]
		
		unless exists? exe [
			write script read-cache %red/tests/console.red

			opts: make system-dialect/options-class [
				link?: yes
				unicode?: yes
				config-name: to word! default-target
				build-basename: %console
				build-prefix: temp-dir
			]
			opts: make opts select load-targets opts/config-name

			print "Pre-compiling Red console..."
			result: red/compile script opts
			system-dialect/compile/options/loaded script opts result/1
			
			delete script
			
			if all [Windows? not lib?][
				print "Please run red.exe again to access the console."
				quit/return 1
			]
		]
		
		sys-call to-local-file exe						;-- replace the buggy CALL native
		quit/return 0
	]

	parse-options: has [
		args srcs opts output target verbose filename config config-name base-path type
		mode
	] [
		args: any [system/options/args parse any [system/script/args ""] none]

		target: default-target

		srcs: copy []
		opts: make system-dialect/options-class [link?: yes]

		parse args [
			any [
				  ["-r" | "--no-runtime"]   (opts/runtime?: no)		;@@ overridable by config!
				| ["-d" | "--debug" | "--debug-stabs"]	(opts/debug?: yes)
				| ["-o" | "--output"]  		set output skip
				| ["-t" | "--target"]  		set target skip
				| ["-v" | "--verbose"] 		set verbose skip	;-- 1-3: Red, >3: Red/System
				| ["-h" | "--help"]			(mode: 'help)
				| ["-V" | "--version"]		(mode: 'version)
				| "--red-only"				(opts/red-only?: yes)
				| ["-dlib" | "--dynamic-lib"] (type: 'dll)
				;| ["-slib" | "--static-lib"] (type 'lib)
				| set filename skip (append srcs load-filename filename)
			]
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
		;base-path: system/script/parent/path
		base-path: system/options/path

		opts: make opts config
		opts/config-name: config-name
		opts/build-prefix: base-path

		;; Process -o/--output (if any).
		if output [
			opts/build-basename: load-filename output
			if slash = first opts/build-basename [
				opts/build-prefix: %""
			]
		]

		;; Process -v/--verbose (if any).
		if verbose [
			unless attempt [opts/verbosity: to integer! trim verbose] [
				fail ["Invalid verbosity:" verbose]
			]
		]
		
		;; Process -dlib/--dynamic-lib (if any).
		if type = 'dll [
			opts/type: type
			if opts/OS <> 'Windows [opts/PIC?: yes]
		]
		
		;; Process input sources.
		if empty? srcs [
			either encap? [
				run-console
			][
				fail "No source files specified."
			]
		]
		
		forall srcs [
			if slash <> first srcs/1 [								;-- if relative path
				srcs/1: clean-path join base-path srcs/1			;-- add working dir path
			]
			unless exists? srcs/1 [
				fail ["Cannot access source file:" srcs/1]
			]
		]

		reduce [srcs opts]
	]

	main: has [srcs opts build-dir result saved rs? prefix] [
		set [srcs opts] parse-options
		
		rs?: red-system? srcs/1

		;; If we use a build directory, ensure it exists.
		if all [prefix: opts/build-prefix find prefix %/] [
			build-dir: copy/part prefix find/last prefix %/
			unless attempt [make-dir/deep build-dir] [
				fail ["Cannot access build dir:" build-dir]
			]
		]
		
		print [
			newline
			"-=== Red Compiler" read-cache %version.r "===-" newline newline
			"Compiling" srcs "..."
		]
		
		unless rs? [
	;--- 1st pass: Red compiler ---
			
			fail-try "Red Compiler" [
				result: red/compile srcs/1 opts
			]
			print ["...compilation time:" tab round result/2/second * 1000 "ms"]
			if opts/red-only? [exit]
		]
		
	;--- 2nd pass: Red/System compiler ---
		
		print [
			newline
			"Compiling to native code..."
		]
		fail-try "Red/System Compiler" [
			unless encap? [change-dir %red-system/]
			result: either rs? [
				system-dialect/compile/options srcs opts
			][
				opts/unicode?: yes							;-- force Red/System to use Red's Unicode API
				opts/verbosity: max 0 opts/verbosity - 3	;-- Red/System verbosity levels upped by 3
				system-dialect/compile/options/loaded srcs opts result/1
			]
			unless encap? [change-dir %../]
		]
		print ["...compilation time :" round result/1/second * 1000 "ms"]
		
		if result/2 [
			print [
				"...linking time     :" round result/2/second * 1000 "ms^/"
				"...output file size :" result/3 "bytes^/"
				"...output file      :" to-local-file result/4
			]
		]
	]

	fail-try "Driver" [main]
]
