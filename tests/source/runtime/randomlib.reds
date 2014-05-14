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
		Then run the REBOL testprogram %random-tester.r
	}
]

#include %../../../runtime/random.reds

generate-red-random: func [n [integer!] return: [integer!]][
	1 + _random/rand // n 
] 

#export [generate-red-random]

seed-red-random: func [n [integer!]][
	_random/srand n
] 

#export [seed-red-random]
