REBOL [
	Title:   "Generate Red auto-tests"
	Author:  "Peter W A Wood"
	File: 	 %make-red-system-auto-tests.r
	Version: 0.1.0
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Purpose: {Generates Red/System auto-tests as needed.}
]

unless value? 'qt [
    do %../../../../quick-test/quick-test.r
    qt/tests-dir: clean-path %../../
]

make-dir qt/tests-dir/source/units/auto-tests
dll-target: any [
	qt/library-target
	switch/default fourth system/version [
		2 ["Darwin"]
		3 ["MSDOS"]
		7 ["FreeBSD"]
	][
		"Linux"
	]
]
qt/make-if-needed?/target
	%source/units/auto-tests/dylib-auto-test.reds
	%source/units/make-dylib-auto-test.r
	dll-target

dll-extension: switch/default dll-target [
	"Darwin"               [".dylib"]
	"MSDOS"                [".dll"]
	"Windows"              [".dll"]
	"Windows-X86-64-DLL"   [".dll"]
][
	".so"
]
dll1: to file! rejoin ["libtest-dll1" dll-extension]
dll2: to file! rejoin ["libtest-dll2" dll-extension]
unless all [
	exists? join qt/runnable-dir dll1
	exists? join qt/runnable-dir dll2
][
	do join qt/tests-dir %source/units/make-dylib-auto-test.r
]
