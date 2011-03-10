REBOL [
	Title:   "Red/System compiler wrapper"
	Author:  "Nenad Rakocevic"
	File: 	 %rsc.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
	Usage:   {
		do/args %rsc.r "[-vvvv] %path/source.reds"
	}
]

unless value? 'system-dialect [
	do %compiler.r
]

verbosity: 0

unless parse system/script/args [
	opt [#"-" some [#"v" (verbosity: verbosity + 1)]]
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
	"-= Red/System Compiler =-" newline
	"Compiling" file "..."
]

builds: make-dir %builds/
result: system-dialect/compile/link/in/level file builds verbosity

print ["^/...compilation time:" tab round result/1/second * 1000 "ms"]
if result/2 [
	print [
		"...linking time:" tab tab round result/1/second * 1000 "ms^/"
		"...output file size:" tab result/3 "bytes"
	]
]


halt

