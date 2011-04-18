Red/System [
	Title:   "Red/System EXIT keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %test-exit.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

ok: does [print "OK"]
ko: does [print "KO"]



test: does [exit]		;-- compilation passing test
test					;-- execution passing test

test99: does [
	exit
	ko
]
test99


test2: does [
	ok
	exit
	ko
]
test2


test3: does [
	ok
	if true [exit]
	ko
]
test3


test4: does [
	prin "result: "
	if false [exit]
	ok
]
test4


test5: does [
	ok
	either true [exit][ko]
	ko
]
test5


test6: does [
	ok
	either false [exit][ok exit]
	ko
]
test6


test7: does [
	ok
	either 1 < 2 [
		exit
	][
		ko
	]
	ko
]
test7


;test8: does [				;-- crashes the compiler
;	ok							;-- UNTIL needs to check if last expression is conditional
;	until [exit]				;-- and raise and error if not conforming
;	ko
;]
;test8


test9: does [
	ok
	until [
		exit
		true
	]
	ko
]
test9

test10: does [
	ok
	until [
		if true [exit]
		ko
		true
	]
	ko
]
test10

