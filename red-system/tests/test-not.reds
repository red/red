Red/System [
	Title:   "Red/System NOT function test script"
	Author:  "Nenad Rakocevic"
	File: 	 %test-not.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

ok: func [][print "OK"]
ko: func [][print "KO"]

foo: func [a [logic!] return: [logic!]][a]
nfoo: func [a [logic!] return: [logic!]][not a]



either not true  [ko][ok]
either not false [ok][ko]

either not not true  [ok][ko]
either not not false [ko][ok]

a: true
either not a [ko][ok]

a: false
either not a [ok][ko]

either not foo true  [ko][ok]
either not foo false [ok][ko]

either foo not true  [ko][ok]
either foo not false [ok][ko]

a: true
either not foo a [ko][ok]
either foo not a [ko][ok]

a: false
either not foo a [ok][ko]
either not foo a [ok][ko]

either nfoo true  [ko][ok]
either nfoo false [ok][ko]

either nfoo true  [ko][ok]
either nfoo false [ok][ko]

;TBD: write unit tests for bitwise NOT on integer
