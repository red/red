Red/System [
	Title:   "Red/System logic! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %test-logic.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]


foo: func [a [logic!] return: [logic!]][a]


;-- literal logic! value tests
prin "1: "
if true [print "OK"]
prin "2: "
either false [print "KO"][print "OK"]

;-- logic variable tests
prin "3: "
a: true
either a [print "OK"][print "KO"]
prin "4: "
a: false
either a [print "KO"][print "OK"]

;-- conditional expression assignment tests
prin "5: "
a: 3 < 5
either a [print "OK"][print "KO"]
prin "6: "
a: 1 = 2
either a [print "KO"][print "OK"]

;-- logic value as last conditional expression in UNTIL tests
prin "7: "
a: true
until [
	prin "one pass only"
	a
]
prin newline

prin "8: "
c: 3
stop?: false
until [
	prin "."
	c: c - 1
	if zero? c [stop?: true]
	stop?
]
prin newline

;-- logic value as conditional expression in WHILE tests
prin "9: "
a: false
while [a][print "KO"]

prin newline
prin "10: "

c: 3
run?: true
while [run?][
	prin "."
	c: c - 1
	if zero? c [run?: false]
]
prin newline


;-- function returning a logic value tests
prin "11: "
test?: func [return: [logic!]][
	either 1 < 2 [true][false]
]
either test? [print "OK"][print "KO"]

prin "12: "
a: test?
either a [print "OK"][print "KO"]

prin "13: "
test2?: func [return: [logic!]][
	either 1 = 2 [true][false]
]
either test2? [print "KO"][print "OK"]

prin "14: "
a: test2?
either a [print "KO"][print "OK"]


;-- passing logic! as function's argument tests
prin "15: "
either foo true  [print "OK"][print "KO"]

prin "16: "
either foo false [print "KO"][print "OK"]

prin "17: "
a: foo 1 < 2
either a [print "OK"][print "KO"]

prin "18: "
a: foo 3 = 4
either a [print "KO"][print "OK"]

prin "19: "
a: foo 1 + 1 < 3
either a [print "OK"][print "KO"]

prin "20: "
a: foo 2 + 2 = 5
either a [print "KO"][print "OK"]



;-- ALL test

prin "21: "
a: all [true]
either a [print "OK"][print "KO"]

prin "22: "
a: all [false]
either a [print "KO"][print "OK"]

prin "23: "
a: all [true true]
either a [print "OK"][print "KO"]

prin "24: "
a: all [false false]
either a [print "KO"][print "OK"]

prin "25: "
a: all [true false]
either a [print "KO"][print "OK"]

prin "26: "
a: all [false true]
either a [print "KO"][print "OK"]

prin "27: "
a: all [1 < 2 false]
either a [print "KO"][print "OK"]

prin "28: "
a: all [false 1 < 2]
either a [print "KO"][print "OK"]

prin "29: "
a: all [true 1 = 2]
either a [print "KO"][print "OK"]

prin "30: "
a: all [1 = 2 true]
either a [print "KO"][print "OK"]


prin "31: "
either all [1 < 2][print "OK"][print "KO"]

prin "32: "
a: all [1 < 2]
either a [print "OK"][print "KO"]

prin "33: "
a: all [1 = 2]
either a [print "KO"][print "OK"]

prin "34: "
a: all [1 < 2 3 <> 4]
either a [print "OK"][print "KO"]

prin "35: "
a: all [1 = 2 3 <> 4]
either a [print "KO"][print "OK"]

prin "36: "
either foo all [1 = 2][print "KO"][print "OK"]
prin "37: "
either foo all [1 < 2 3 <> 4][print "OK"][print "KO"]
prin "38: "
either foo all [1 = 2 3 <> 4][print "KO"][print "OK"]

prin "39: "
a: foo all [1 < 2]
either a [print "OK"][print "KO"]

prin "40: "
a: foo all [1 = 2]
either a [print "KO"][print "OK"]

prin "41: "
a: foo all [1 < 2 3 <> 4]
either a [print "OK"][print "KO"]

;a: all [foo true]
;either a [print "OK"][print "KO"]



;-- ANY test

prin "42: "
a: any [true]
either a [print "OK"][print "KO"]

prin "43: "
a: any [false]
either a [print "KO"][print "OK"]

prin "44: "
a: any [true true]
either a [print "OK"][print "KO"]

;prin "45: "								;-- works OK, but would hit CODE max size (bug)
;a: any [false false]
;either a [print "KO"][print "OK"]

;prin "46: "								;-- works OK, but would hit CODE max size (bug)
;a: any [true false]
;either a [print "OK"][print "KO"]

;prin "47: "								;-- works OK, but would hit CODE max size (bug)
;a: any [false true]
;either a [print "OK"][print "KO"]

;prin "48: "								;-- works OK, but would hit CODE max size (bug)
;a: any [1 < 2 false]
;either a [print "OK"][print "KO"]

;prin "49: "								;-- works OK, but would hit CODE max size (bug)
;a: any [false 1 < 2]
;either a [print "OK"][print "KO"]

;prin "50: "								;-- works OK, but would hit CODE max size (bug)
;a: any [true 1 = 2]
;either a [print "OK"][print "KO"]

;prin "51: "								;-- works OK, but would hit CODE max size (bug)
;a: any [1 = 2 true]
;either a [print "OK"][print "KO"]


prin "52: "
either any [1 < 2][print "OK"][print "KO"]

prin "53: "
a: any [1 < 2]
either a [print "OK"][print "KO"]

prin "54: "
a: any [1 = 2]
either a [print "KO"][print "OK"]

prin "55: "
a: any [1 = 2 3 <> 4]
either a [print "OK"][print "KO"]

prin "56: "
a: any [1 = 2 3 = 4]
either a [print "KO"][print "OK"]

prin "57: "
either foo any [1 < 2][print "OK"][print "KO"]

prin "58: "
either foo any [1 = 2][print "KO"][print "OK"]

prin "59: "
either foo any [1 = 2 3 < 4][print "OK"][print "KO"]

prin "60: "
a: foo any [1 < 2]
either a [print "OK"][print "KO"]

prin "61: "
a: foo any [1 = 2]
either a [print "KO"][print "OK"]

prin "62: "
a: foo any [1 = 2 3 < 4]
either a [print "OK"][print "KO"]

