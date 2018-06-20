REBOL [
	Title:   "Prepare dependencies for executing compiled Red/System unit test binaries"
	Author:  "Nenad Rakoceivc"
	File: 	 %prepare-dependencies.r
	Version: 0.1.0
	Tabs:	 4
	Rights:  "Copyright (C) 2017 --2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]


install-libs: has [lib][
	lib: switch/default system/version/4 [
		2 [%libstructlib.dylib]
		3 [%structlib.dll]
		7 [%libstruct.so]
	][
		%libstructlib.so
	]
	write/binary join qt/runnable-dir lib read/binary join %libs/ lib
]

install-libs