REBOL [
    Title:  "Testprogram for the random function for the Red Programming Language"
    Author: "Arnold van Hofwegen"
    File:   %random-test.r
    Tabs:   4
	Rights: "Copyright (C) 2014 Arnold van Hofwegen. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
	Notes: {
		The random generator file needs to be compiled to a library file using
			do/args %red.r "-dlib %tests/source/runtime/randomlib.reds"
		The library will be placed in the root directory from where the test can be run
			do %tests/source/units/random-test.r
	}
	file:
]

switch/default system/version/4 [
	2	[											;-- MacOS X
		randomlib: load/library %../../../randomlib.dylib 
		]
	3	[											;-- Windows
		randomlib: load/library %../../../randomlib.dll
		]
][
	randomlib: load/library %randomlib
]

random-value: "generate-red-random"

red-random: make routine! [n [integer!] return: [integer!]] randomlib random-value

img: make image! 512x512 
repeat i 512 [
	repeat j 512 [
		either i < 256 [
			if 2 = random 2 [
				img/(as-pair i - 1 j - 1): 255.255.255
			]			
		][  
			if 2 = red-random 2 [
				img/(as-pair i - 1 j - 1): 255.255.255
			]
		]
	]
]

view layout [image img across text "RANDOM" tab tab tab text "Red-RANDOM"]
