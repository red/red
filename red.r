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
]

unless all [value? 'red object? :red][
	do %red/compiler.r
]

redc: context [
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
		targets: load %red-system/config.r
		if exists? %red-system/custom-targets.r [
			insert targets load %red-system/custom-targets.r
		]
		targets
	]

	parse-options: has [
		args srcs opts output target verbose filename config config-name
	] [
		args: any [system/options/args parse any [system/script/args ""] none]

		;; Select a default target based on the REBOL version.
		target: any [
			select [
				2 "Darwin"
				3 "MSDOS"
				4 "Linux"
			] system/version/4
			"MSDOS"
		]

		srcs: copy []
		opts: make system-dialect/options-class [link?: yes]

		parse args [
			any [
				["-d" | "--debug"]  		(opts/debug?: yes)
				| ["-o" | "--output"]  		set output skip
				| ["-t" | "--target"]  		set target skip
				| ["-v" | "--verbose"] 		set verbose skip	;-- 1-3: Red, >3: Red/System
				| "--red-only"				(opts/red-only?: yes)
				;| "--custom"				;@@ pass-thru for Red/System specific arguments
				| set filename skip (append srcs load-filename filename)
			]
		]

		;; Process -t/--target first, so that all other command-line options
		;; can potentially override the target config settings.
		unless config: select load-targets config-name: to word! trim target [
			fail ["Unknown target:" target]
		]
		opts: make opts config
		opts/config-name: config-name
		opts/build-prefix: system/options/path

		;; Process -o/--output (if any).
		if output [
			opts/build-prefix: %""
			opts/build-basename: load-filename output
		]

		;; Process -v/--verbose (if any).
		if verbose [
			unless attempt [opts/verbosity: to integer! trim verbose] [
				fail ["Invalid verbosity:" verbose]
			]
		]
		
		;; Process input sources.
		if empty? srcs [fail "No source files specified."]
		
		foreach src srcs [		
			unless exists? src [
				fail ["Cannot access source file:" src]
			]
		]

		reduce [srcs opts]
	]

	main: has [srcs opts build-dir result saved] [
		set [srcs opts] parse-options

		;; If we use a build directory, ensure it exists.
		if all [opts/build-prefix find opts/build-prefix %/] [
			build-dir: copy/part opts/build-prefix find/last opts/build-prefix %/
			unless attempt [make-dir/deep build-dir] [
				fail ["Cannot access build dir:" build-dir]
			]
		]
		
	;--- 1st pass: Red compiler ---
		
		print [
			newline
			"-= Red Compiler =-" newline
			"Compiling" srcs "..."
		]
		fail-try "Red Compiler" [
			result: red/compile srcs/1 opts
		]
		print ["^/...compilation time:" tab round result/2/second * 1000 "ms"]
		if opts/red-only? [exit]
	;--- 2nd pass: Red/System compiler ---
		
		print [
			newline
			"Compiling to native code..." newline
		]
		fail-try "Red/System Compiler" [
			change-dir %red-system/
			opts/unicode?: yes							;-- force Red/System to use Red's Unicode API
			opts/verbosity: max 0 opts/verbosity - 3	;-- Red/System verbosity levels upped by 3
			result: system-dialect/compile/options/loaded srcs opts result/1
			change-dir %../
		]
		print ["...compilation time:" tab round result/1/second * 1000 "ms"]
		
		if result/2 [
			print [
				"...linking time:    " tab round result/2/second * 1000 "ms^/"
				"...output file size:" tab result/3 "bytes"
			]
		]
	]

	fail-try "Driver" [main]
]
