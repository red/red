Red/System [
	Title:   "Red/System RETURN keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %test-return.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

ok: does [print "OK"]
ko: does [print "KO"]



test: func [return: [integer!]][return 1]
either test = 1 [ok][ko]

test98: func [return: [logic!]][
	return true
	ko
]
either test98 [ok][ko]

test99: func [return: [logic!]][
	return false
	ko
]
either test99 [ko][ok]


test2: func [return: [logic!]][
	ok
	return true
	ko
]
either test2 [ok][ko]


test3: func [return: [logic!]][
	ok
	if true [return true ko]
	ko
]
either test2 [ok][ko]


test97: func [a [logic!] return: [logic!]][
	ok
	if true [return a ko]
	ko
]
either test97 true [ok][ko]


test4: func [return: [logic!]][
	prin "result: "
	if false [return false ko]
	ok
	true
]
either test4 [ok][ko]


test5: func [return: [logic!]][
	ok
	either true [return 1 < 2 ko][ko]
	ko
]
either test5 [ok][ko]


test6: func [return: [logic!]][
	ok
	either false [return false][ok return true ko]
	ko
]
either test6 [ok][ko]


test7: func [return: [logic!]][
	ok
	either 1 < 2 [
		either 3 < 4 [
			return true
			ko
		][
			ko
		]
	][
		ko
	]
	ko
]
either test7 [ok][ko]


;test8: func [return: [logic!]][	;-- crashes the compiler
;	ok								;-- UNTIL needs to check if last expression is conditional
;	until [return true]				;-- and raise and error if not conforming
;	ko
;]
;test8


test9: func [return: [logic!]][
	ok
	until [
		return false
		true
	]
	ko
]
either test9 [ko][ok]

test10: func [return: [integer!]][
	ok
	until [
		if true [return 42]
		ko
		true
	]
	ko
]
either test10 = 42 [ok][ko]

