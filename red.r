REBOL [
	Title:   "Red command-line front-end"
	Author:  "Nenad Rakocevic, Andreas Bolka"
	File: 	 %red.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic, Andreas Bolka. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
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

	temp-dir: %/tmp/red/
	
	Windows?: system/version/4 = 3
	
	either encap? [
		switch/default system/version/4 [
			2 [											;-- MacOS X
				libc: load/library %libc.dylib
				sys-call: make routine! [cmd [string!]] libc "system"
			]
			3 [											;-- Windows
				temp-dir: either lib?: find system/components 'Library [
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
		]
	][
		sys-call: func [cmd][call/wait cmd]
		if Windows? [
			temp-dir: append to-rebol-file get-env "ALLUSERSPROFILE" %/Red/
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
	
	safe-to-local-file: func [file [file!]][
		if all [
			find file: to-local-file file #" "
			Windows?
		][
			file: rejoin [{"} file {"}]					;-- avoid issues with blanks in path
		]
		file
	]
	
	run-console: func [/with file [string!] /local opts result script exe .exe sob][
		script: temp-dir/red-console.red
		exe: temp-dir/console
		.exe: %.exe
		sob: system/options/boot
		
		if Windows? [
			append exe .exe
			if .exe <> skip tail sob -4 [append sob .exe]
		]
		
		unless exists? temp-dir [make-dir temp-dir]
		
		if any [
			not exists? exe 
			(modified? exe) < modified? sob					;-- check that console is up to date.
		][
			write script read-cache %tests/console.red

			opts: make system-dialect/options-class [		;-- minimal set of compilation options
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
		exe: safe-to-local-file exe
		if with [repend exe [#" " file]]
		sys-call exe									;-- replace the buggy CALL native
		quit/return 0
	]

	parse-options: has [
		args src opts output target verbose filename config config-name base-path type
		mode target?
	] [
		args: any [
			system/options/args
			parse any [system/script/args ""] none
		]
		target: default-target
		opts: make system-dialect/options-class [link?: yes]

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
				run-console
			][
				fail "No source files specified."
			]
		]
		
		if all [encap? none? output none? type][
			run-console/with filename
		]
		
		if slash <> first src [							;-- if relative path
			src: clean-path join base-path src			;-- add working dir path
		]
		unless exists? src [
			fail ["Cannot access source file:" src]
		]

		reduce [src opts]
	]

	main: has [src opts build-dir result saved rs? prefix] [
		set [src opts] parse-options
		
		rs?: red-system? src

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
			"Compiling" src "..."
		]
		
		unless rs? [
	;--- 1st pass: Red compiler ---
			
			fail-try "Red Compiler" [
				result: red/compile src opts
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
			unless encap? [change-dir %system/]
			result: either rs? [
				system-dialect/compile/options src opts
			][
				opts/unicode?: yes							;-- force Red/System to use Red's Unicode API
				opts/verbosity: max 0 opts/verbosity - 3	;-- Red/System verbosity levels upped by 3
				system-dialect/compile/options/loaded src opts result/1
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
		unless Windows? [print ""]							;-- extra LF for more readable output
		
		if all [word: in opts 'packager get word][
			file: join %system/formats/ [opts/packager %.r]
			unless exists? file [fail ["Packager:" opts/packager "not found!"]]
			do bind load file 'self
			packager/process opts src result/4
		]
	]

	fail-try "Driver" [main]
	if encap? [quit/return 0]
]
