Red/System [
	Title:   "Library for random functions"
	Author:  "Arnold van Hofwegen"
	File: 	 %randomlib.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Arnold van Hofwegen. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
	Comment: {
		Compile this program using
			do/args %red.r "-dlib %tests/source/runtime/randomlib.reds"
		Then run the REBOL testprogram %random-test.r
	}
]

#include %../../../runtime/random.reds

generate-red-random: func [n [integer!] return: [integer!]][
	_random/rand // n + 1		;-- // n will be processed first, then 1 is added.
] 

#export [generate-red-random]

seed-red-random: func [n [integer!]][
	_random/srand n
] 

#export [seed-red-random]
