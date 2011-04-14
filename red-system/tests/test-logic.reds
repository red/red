Red/System [
	Title:   "Red/System logic! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %test-logic.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

ok: func [][print "OK"]
ko: func [][print "KO"]


foo: func [a [logic!] return: [logic!]][a]

;-- literal logic! value tests
prin "1: "
if true [ok]
prin "2: "
either false [ko][ok]

;-- logic variable tests
prin "3: "
a: true
either a [ok][ko]
prin "4: "
a: false
either a [ko][ok]

;-- conditional expression assignment tests
prin "5: "
a: 3 < 5
either a [ok][ko]
prin "6: "
a: 1 = 2
either a [ko][ok]

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
while [a][ko]

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
either test? [ok][ko]

prin "12: "
a: test?
either a [ok][ko]

prin "13: "
test2?: func [return: [logic!]][
	either 1 = 2 [true][false]
]
either test2? [ko][ok]

prin "14: "
a: test2?
either a [ko][ok]


;-- passing logic! as function's argument tests
prin "15: "
either foo true  [ok][ko]

prin "16: "
either foo false [ko][ok]

prin "17: "
a: foo 1 < 2
either a [ok][ko]

prin "18: "
a: foo 3 = 4
either a [ko][ok]

prin "19: "
a: foo 1 + 1 < 3
either a [ok][ko]

prin "20: "
a: foo 2 + 2 = 5
either a [ko][ok]



;-- ALL test

prin "21: "
a: all [true]
either a [ok][ko]

prin "22: "
a: all [false]
either a [ko][ok]

prin "23: "
a: all [true true]
either a [ok][ko]

prin "24: "
a: all [false false]
either a [ko][ok]

prin "25: "
a: all [true false]
either a [ko][ok]

prin "26: "
a: all [false true]
either a [ko][ok]

prin "27: "
a: all [1 < 2 false]
either a [ko][ok]

prin "28: "
a: all [false 1 < 2]
either a [ko][ok]

prin "29: "
a: all [true 1 = 2]
either a [ko][ok]

prin "30: "
a: all [1 = 2 true]
either a [ko][ok]


prin "31: "
either all [1 < 2][ok][ko]

prin "32: "
a: all [1 < 2]
either a [ok][ko]

prin "33: "
a: all [1 = 2]
either a [ko][ok]

prin "34: "
a: all [1 < 2 3 <> 4]
either a [ok][ko]

prin "35: "
a: all [1 = 2 3 <> 4]
either a [ko][ok]

prin "36: "
either foo all [1 = 2][ko][ok]
prin "37: "
either foo all [1 < 2 3 <> 4][ok][ko]
prin "38: "
either foo all [1 = 2 3 <> 4][ko][ok]

prin "39: "
a: foo all [1 < 2]
either a [ok][ko]

prin "40: "
a: foo all [1 = 2]
either a [ko][ok]

prin "41: "
a: foo all [1 < 2 3 <> 4]
either a [ok][ko]

;a: all [foo true]
;either a [ok][ko]



;-- ANY test

prin "42: "
a: any [true]
either a [ok][ko]

prin "43: "
a: any [false]
either a [ko][ok]

prin "44: "
a: any [true true]
either a [ok][ko]

prin "45: "
a: any [false false]
either a [ko][ok]

prin "46: "
a: any [true false]
either a [ok][ko]

prin "47: "
a: any [false true]
either a [ok][ko]

prin "48: "
a: any [1 < 2 false]
either a [ok][ko]

prin "49: "
a: any [false 1 < 2]
either a [ok][ko]

prin "50: "
a: any [true 1 = 2]
either a [ok][ko]

prin "51: "
a: any [1 = 2 true]
either a [ok][ko]


prin "52: "
either any [1 < 2][ok][ko]

prin "53: "
a: any [1 < 2]
either a [ok][ko]

prin "54: "
a: any [1 = 2]
either a [ko][ok]

prin "55: "
a: any [1 = 2 3 <> 4]
either a [ok][ko]

prin "56: "
a: any [1 = 2 3 = 4]
either a [ko][ok]

prin "57: "
either foo any [1 < 2][ok][ko]

prin "58: "
either foo any [1 = 2][ko][ok]

prin "59: "
either foo any [1 = 2 3 < 4][ok][ko]

prin "60: "
a: foo any [1 < 2]
either a [ok][ko]

prin "61: "
a: foo any [1 = 2]
either a [ko][ok]

prin "62: "
a: foo any [1 = 2 3 < 4]
either a [ok][ko]

