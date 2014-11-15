REBOL [
	Title:   "Generates Red/System dylib tests"
	Author:  "Peter W A Wood"
	File: 	 %make-dylib-auto-test.r
	Version: 0.2.0
	Rights:  "Copyright (C) 2012-2014 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

do %create-dylib-auto-test.r
make-dir %auto-tests/

file-out: %auto-tests/dylib-auto-test.reds
dll-target: switch/default fourth system/version [
	2 ["Darwin"]
	3 ["Windows"]
	7 ["FreeBSD"]
][
	"Linux"
]

create-dylib-auto-test dll-target file-out