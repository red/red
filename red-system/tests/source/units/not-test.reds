Red/System [
	Title:   "Red/System NOT function test script"
	Author:  "Nenad Rakocevic"
	File: 	 %not-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

foo: func [a [logic!] return: [logic!]][a]
nfoo: func [a [logic!] return: [logic!]][not a]

qt-start-file "not"

qt-assert "not-1" false = not true
qt-assert "not-2" not false
qt-assert "not-3" not not true
qt-assert "not-4" false = not not false

a: true
qt-assert "not-5" false = not a 

a: false
qt-assert "not-6" not a

qt-assert "not-7" false = not foo true
qt-assert "not-8" not foo false
qt-assert "not-9" false = foo not true
qt-assert "not-10" foo not false

a: true
qt-assert "not-11" false = not foo a

a: true
qt-assert "not-12" false = foo not a

a: false
qt-assert "not-13" not foo a 

a: false
qt-assert "not-14" not foo a

qt-assert "not-15" false = nfoo true
qt-assert "not-16" nfoo false

qt-assert "not-17" false = nfoo true
qt-assert "not-18" nfoo false

qt-end-file

;TBD: write unit tests for bitwise NOT on integer
