REBOL [
	Title:   "Red/System compiler wrapper"
	Author:  "Nenad Rakocevic, Andreas Bolka"
	File: 	 %rsc.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic, Andreas Bolka. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Note:   {
		THIS SCRIPT HAS BEEN DEPRECATED, use %red.r to compile Red/System scripts.
		This wrapper script is been kept in the repo in case we need to integrate 
		only the Red/System compiler in another Rebol app.
	}
]

unless value? 'system-dialect [
	do %compiler.r
]

rsc: context [
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
		targets: load %config.r
		if exists? %custom-targets.r [
			insert targets load %custom-targets.r
		]
		targets
	]

	parse-options: has [
		args srcs opts output target verbose type filename config config-name
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
				  "--no-runtime"		    (opts/runtime?: no)		;@@ overridable by config!
				| ["-g" | "--debug-stabs"]  (opts/debug?: yes)		;@@ overridable by config!
				| ["-l" | "--literal-pool"] (opts/literal-pool?: yes)
				| ["-o" | "--output"]  		set output skip
				| ["-t" | "--target"]  		set target skip
				| ["-v" | "--verbose"] 		set verbose skip
				| ["-dlib" | "--dynamic-lib"] (type: 'dll)
				;| ["-slib" | "--static-lib"] (type 'lib)
				| set filename skip (append srcs load-filename filename)
			]
		]

		;; Process -t/--target first, so that all other command-line options
		;; can potentially override the target config settings.
		unless config: select load-targets config-name: to word! trim target [
			fail ["Unknown target:" target]
		]
		base-path: system/script/parent/path
		opts: make opts config
		opts/config-name: config-name

		;; Process -o/--output (if any).
		if output [
			opts/build-basename: load-filename output
			either slash = first opts/build-basename [
				opts/build-prefix: %""
			] [
				opts/build-prefix: base-path
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
		if empty? srcs [fail "No source files specified."]
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

	main: has [srcs opts build-dir result] [
		set [srcs opts] parse-options

		;; If we use a build directory, ensure it exists.
		if all [opts/build-prefix find opts/build-prefix %/] [
			build-dir: copy/part opts/build-prefix find/last opts/build-prefix %/
			unless attempt [make-dir/deep build-dir] [
				fail ["Cannot access build dir:" build-dir]
			]
		]

		print [
			newline
			"-= Red/System Compiler =-" newline
			"Compiling" srcs "..."
		]

		fail-try "Compiler" [
			result: system-dialect/compile/options srcs opts
		]

		print ["^/...compilation time:" tab round result/1/second * 1000 "ms"]
		if result/2 [
			print [
				"...linking time:" tab tab round result/2/second * 1000 "ms^/"
				"...output file size:" tab result/3 "bytes^/"
				"...output file name:" tab form result/4
			]
		]
	]

	fail-try "Driver" [main]
]
