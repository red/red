REBOL [
	Title:   "Red/System compiler wrapper"
	Author:  "Nenad Rakocevic"
	File: 	 %rsc.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
	Usage:   {
		do/args %rsc.r "[-vvvv] [-f PE|ELF] %path/source.reds"
	}
]

unless value? 'system-dialect [
	do %compiler.r
]

unless exists? %builds/ [make-dir %builds/]

verbosity: 0
opts: make system-dialect/options-class [link?: yes]

;-- Load preconfigured compilation targets --
targets: load %config.r
if exists? %custom-targets.r [
	append targets load %custom-targets.r
]

unless system/script/args [
	print "Missing command-line arguments!"
	halt
]

unless parse system/script/args [
	any [
		#"-" [
			some [#"v" (verbosity: verbosity + 1)] (opts/verbosity: verbosity)
			| #"t" copy v to #" " (
				value: attempt [to word! trim v]
				either find targets value [
					opts: make opts targets/:value
					opts/config-name: value
				][
					print ["*** Command-line Error: unknown target" v]
					halt
				]
			)
			| #"f" copy fmt to #" " (opts/format: to-word trim fmt)		; to be removed
			| "-" [														; to be removed
				"no-runtime" (opts/with-runtime: false)
			]
		]
	]
	file: to end
][
	print "Invalid command line"
	halt
]

unless all [
	file? file: attempt [load file]
	exists? file	
][
	print ["Can't access file" mold file]
	halt
]

print [
	newline
	"-= Red/System Compiler =-" newline
	"Compiling" file "..."
]

if error? set/any 'err try [
	result: system-dialect/compile/options file opts
][
	err: disarm err
	foreach w [arg1 arg2 arg3][
		set w either unset? get/any in err w [none][
			get/any in err w
		]
	]
	print [
		"*** Compiler Internal Error:" 
		system/error/(err/type)/type #":"
		reduce system/error/(err/type)/(err/id) newline
		"*** Where:" mold/flat err/where newline
		"*** Near: " mold/flat err/near newline
	]
	halt
]

print ["^/...compilation time:" tab round result/1/second * 1000 "ms"]
if result/2 [
	print [
		"...linking time:" tab tab round result/2/second * 1000 "ms^/"
		"...output file size:" tab result/3 "bytes"
	]
]


