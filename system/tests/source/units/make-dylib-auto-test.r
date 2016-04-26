REBOL [
	Title:   "Generates Red/System dylib tests"
	Author:  "Peter W A Wood"
	File: 	 %make-dylib-auto-test.r
	Version: 0.2.0
	Rights:  "Copyright (C) 2012-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

do %create-dylib-auto-test.r
do %compile-test-dylibs.r
dir-out: %auto-tests
make-dir dir-out
exe-dir-out: clean-path %../../../../quick-test/runnable/
make-dir exe-dir-out

dll-target: switch/default fourth system/version [
	2 ["Darwin"]
	3 ["Windows"]
	7 ["FreeBSD"]
][
	"Linux"
]

compile-test-dylibs dll-target dir-out
create-dylib-auto-test dll-target dir-out exe-dir-out