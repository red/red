Red/System [
	Title:   "Red/System logic! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %test-logic.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;-- literal logic! value tests
if true [print "OK"]
either false [print "KO"][print "OK"]

;-- logic variable tests
a: true
either a [print "OK"][print "KO"]
a: false
either a [print "KO"][print "OK"]

;-- conditional expression assignment tests
a: 3 < 5
either a [print "OK"][print "KO"]
a: 1 = 2
either a [print "KO"][print "OK"]

;-- logic value as last conditional expression in UNTIL tests
a: true
until [
	prin "one pass only"
	a
]
prin newline

c: 3
stop?: false
until [
	prin "."
	c: c - 1
	if zero? c [stop?: true]
	stop?
]

;-- logic value as conditional expression in WHILE tests
a: false
while [a][print "KO"]

prin newline

c: 3
run?: true
while [run?][
	prin "."
	c: c - 1
	if zero? c [run?: false]
]
prin newline


;-- function returning a logic value tests

test?: func [return: [logic!]][
	either 1 < 2 [true][false]
]
either test? [print "OK"][print "KO"]

a: test?
either a [print "OK"][print "KO"]


test2?: func [return: [logic!]][
	either 1 = 2 [true][false]
]
either test2? [print "KO"][print "OK"]

a: test2?
either a [print "KO"][print "OK"]


;-- passing logic! as function's argument tests

foo: func [a [logic!] return: [logic!]][a]

either foo true  [print "OK"][print "KO"]
either foo false [print "KO"][print "OK"]

a: foo 1 < 2
either a [print "OK"][print "KO"]

a: foo 3 = 4
either a [print "KO"][print "OK"]

a: foo 1 + 1 < 3
either a [print "OK"][print "KO"]

a: foo 2 + 2 = 5
either a [print "KO"][print "OK"]