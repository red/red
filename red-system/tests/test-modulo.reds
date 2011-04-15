Red/System [
	Title:   "Red/System modulo operator (//) test script"
	Author:  "Nenad Rakocevic"
	File: 	 %test-modulo.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

dot: func [c [integer!]][
	print "^/new dot test"
	either zero? c [
		print "modulo=0"
	][
		if negative? c [c: 0 - c]
		until [
			prin "."
			c: c - 1
			c = 0
		]
	]
]

dot  10 //  7
dot   5 //  3
dot  15 //  8
dot   2 //  2
dot -10 // -7
dot -10 //  7
dot  10 // -7

