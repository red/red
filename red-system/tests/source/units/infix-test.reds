Red/System [
	Title:   "Red/System infix syntax test script"
	Author:  "Nenad Rakocevic"
	File: 	 %infix-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

qt-start-file "infix syntax"

;-- Simple infix syntax test
inf-test: func [[infix] a [integer!] b [integer!] return: [integer!]][
	a + b
]
inf-value: 2 inf-test 3
qt-assert "infix-1" inf-value = 5

;-- Test infix call with an additional infix operator
inf-assert?: func [[infix] s [c-string!] t [logic!]][
	qt-assert "infix-2" t
]
"test-id" inf-assert? (inf-value = 5)	;-- paren are mandatory to force evaluation priority

qt-end-file
