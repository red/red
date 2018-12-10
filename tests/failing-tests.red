Red [
	Title:   "Failing Red Tests"
	Author:  "Peter W A Wood"
	File: 	 %failing-tests.red
	Version: 1.0.0
	Rights:  "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#include %../quick-test/quick-test.red

***start-run*** "failing tests"

~~~start-file~~~ "float"

===start-group=== "power"
	--test-- "pow5" --assert 0.0 = power 0.0 -1		;@@ return INF or 0.0 ?
	--test-- "pow6" --assert 0.0 = power -0.0 -1	;@@ return -INF or 0.0 ?
===end-group===

===start-group=== "float-cosine"
	--test-- "float-cosine-3"
		--assert 0.0 = cosine/radians pi / 2
===end-group===

===start-group=== "float-divide"

	--test-- "float-divide 37"          ;; only fails on Windows
		i: 2.2250738585072014e-308
		j: 1.1
		--assert strict-equal? 2.022794416824728e-308 2.2250738585072014e-308 / 1.1
		--assert strict-equal? 2.022794416824728e-308 divide 2.2250738585072014e-308 1.1
		--assert strict-equal? 2.022794416824728e-308 i / j
		--assert strict-equal? 2.022794416824728e-308 divide i j

	--test-- "float-divide 38"			;; only fails on Windows
		i: 2.2250738585072014e-308
		j: -1.1
		--assert strict-equal? -2.022794416824728e-308 2.2250738585072014e-308 / -1.1
		--assert strict-equal? -2.022794416824728e-308 divide 2.2250738585072014e-308 -1.1
		--assert strict-equal? -2.022794416824728e-308 i / j
		--assert strict-equal? -2.022794416824728e-308 divide i j
		
	--test-- "float-divide 47"			;; only fails on Windows
		i: -2.2250738585072014e-308
		j: 1.1
		--assert strict-equal? -2.022794416824728e-308 -2.2250738585072014e-308 / 1.1
		--assert strict-equal? -2.022794416824728e-308 divide -2.2250738585072014e-308 1.1
		--assert strict-equal? -2.022794416824728e-308 i / j
		--assert strict-equal? -2.022794416824728e-308 divide i j

	--test-- "float-divide 48"			;; only fails on Windows
		i: -2.2250738585072014e-308
		j: -1.1
		--assert strict-equal? 2.022794416824728e-308 -2.2250738585072014e-308 / -1.1
		--assert strict-equal? 2.022794416824728e-308 divide -2.2250738585072014e-308 -1.1
		--assert strict-equal? 2.022794416824728e-308 i / j
		--assert strict-equal? 2.022794416824728e-308 divide i j
		
	--test-- "float-divide 111"
		i: 0.0
		j: 0.0
		--assert strict-equal? 1.#NAN 0.0 / 0.0
		--assert strict-equal? 1.#NAN divide 0.0 0.0
		--assert strict-equal? 1.#NAN i / j
		--assert strict-equal? 1.#NAN divide i j
		
===end-group===

~~~end-file~~~

~~~start-file~~~ "integer"

===start-group=== "modulo"

	--test-- "1 // -2147483648"
		i: 1
		j: -2147483648
		--assert not error? try [ strict-equal? 1 1 // -2147483648 ]
		--assert not error? try [ strict-equal? 1 modulo 1 -2147483648 ]
		--assert not error? try [ strict-equal? 1 i // j ]
		--assert not error? try [ strict-equal? 1 modulo i j ]

	--test-- "1 // 2147483647"
		i: 1
		j: 2147483647
		--assert not error? try [ strict-equal? 1 1 // 2147483647 ]
		--assert not error? try [ strict-equal? 1 modulo 1 2147483647 ]
		--assert not error? try [ strict-equal? 1 i // j ]
		--assert not error? try [ strict-equal? 1 modulo i j ]

	--test-- "-2147483648 // 1"
		i: -2147483648
		j: 1
		--assert not error? try [ strict-equal? 0 -2147483648 // 1 ]
		--assert not error? try [ strict-equal? 0 modulo -2147483648 1 ]
		--assert not error? try [ strict-equal? 0 i // j ]
		--assert not error? try [ strict-equal? 0 modulo i j ]

	
	--test-- "-2147483648 // 2147483647"
		i: -2147483648
		j: 2147483647
		--assert not error? try [ strict-equal? 2147483646 -2147483648 // 2147483647 ]
		--assert not error? try [ strict-equal? 2147483646 modulo -2147483648 2147483647 ]
		--assert not error? try [ strict-equal? 2147483646 i // j ]
		--assert not error? try [ strict-equal? 2147483646 modulo i j ]

	--test-- "-2147483648 // -7"
		i: -2147483648
		j: -7
		--assert not error? try [ strict-equal? 5 -2147483648 // -7 ]
		--assert not error? try [ strict-equal? 5 modulo -2147483648 -7 ]
		--assert not error? try [ strict-equal? 5 i // j ]
		--assert not error? try [ strict-equal? 5 modulo i j ]

	--test-- "-2147483648 // -8"
		i: -2147483648
		j: -8
		--assert not error? try [ strict-equal? 0 -2147483648 // -8 ]
		--assert not error? try [ strict-equal? 0 modulo -2147483648 -8 ]
		--assert not error? try [ strict-equal? 0 i // j ]
		--assert not error? try [ strict-equal? 0 modulo i j ]

	--test-- "-2147483648 // -10"
		i: -2147483648
		j: -10
		--assert not error? try [ strict-equal? 2 -2147483648 // -10 ]
		--assert not error? try [ strict-equal? 2 modulo -2147483648 -10 ]
		--assert not error? try [ strict-equal? 2 i // j ]
		--assert not error? try [ strict-equal? 2 modulo i j ]

	--test-- "2147483647 // 1"
		i: 2147483647
		j: 1
		--assert not error? try [ strict-equal? 0 2147483647 // 1 ]
		--assert not error? try [ strict-equal? 0 modulo 2147483647 1 ]
		--assert not error? try [ strict-equal? 0 i // j ]
		--assert not error? try [ strict-equal? 0 modulo i j ]

	--test-- "2147483647 // -1"
		i: 2147483647
		j: -1
		--assert not error? try [ strict-equal? 0 2147483647 // -1 ]
		--assert not error? try [ strict-equal? 0 modulo 2147483647 -1 ]
		--assert not error? try [ strict-equal? 0 i // j ]
		--assert not error? try [ strict-equal? 0 modulo i j ]

	--test-- "2147483647 // -2147483648"
		i: 2147483647
		j: -2147483648
		--assert not error? try [ strict-equal? 2147483647 2147483647 // -2147483648 ]
		--assert not error? try [ strict-equal? 2147483647 modulo 2147483647 -2147483648 ]
		--assert not error? try [ strict-equal? 2147483647 i // j ]
		--assert not error? try [ strict-equal? 2147483647 modulo i j ]

	--test-- "2147483647 // -7"
		i: 2147483647
		j: -7
		--assert not error? try [ strict-equal? 1 2147483647 // -7 ]
		--assert not error? try [ strict-equal? 1 modulo 2147483647 -7 ]
		--assert not error? try [ strict-equal? 1 i // j ]
		--assert not error? try [ strict-equal? 1 modulo i j ]

	--test-- "2147483647 // -8"
		i: 2147483647
		j: -8
		--assert not error? try [ strict-equal? 7 2147483647 // -8 ]
		--assert not error? try [ strict-equal? 7 modulo 2147483647 -8 ]
		--assert not error? try [ strict-equal? 7 i // j ]
		--assert not error? try [ strict-equal? 7 modulo i j ]

	--test-- "2147483647 // -10"
		i: 2147483647
		j: -10
		--assert not error? try [ strict-equal? 7 2147483647 // -10 ]
		--assert not error? try [ strict-equal? 7 modulo 2147483647 -10 ]
		--assert not error? try [ strict-equal? 7 i // j ]
		--assert not error? try [ strict-equal? 7 modulo i j ]
		
	--test-- "-7 // -2147483648"
		i: -7
		j: -2147483648
		--assert not error? try [ strict-equal? 2147483641 -7 // -2147483648 ]
		--assert not error? try [ strict-equal? 2147483641 modulo -7 -2147483648 ]
		--assert not error? try [ strict-equal? 2147483641 i // j ]
		--assert not error? try [ strict-equal? 2147483641 modulo i j ]

	--test-- "-7 // 2147483647"
		i: -7
		j: 2147483647
		--assert not error? try [ strict-equal? 2147483640 -7 // 2147483647 ]
		--assert not error? try [ strict-equal? 2147483640 modulo -7 2147483647 ]
		--assert not error? try [ strict-equal? 2147483640 i // j ]
		--assert not error? try [ strict-equal? 2147483640 modulo i j ]
		
	--test-- "-8 // -2147483648"
		i: -8
		j: -2147483648
		--assert not error? try [ strict-equal? 2147483640 -8 // -2147483648 ]
		--assert not error? try [ strict-equal? 2147483640 modulo -8 -2147483648 ]
		--assert not error? try [ strict-equal? 2147483640 i // j ]
		--assert not error? try [ strict-equal? 2147483640 modulo i j ]

	--test-- "-8 // 2147483647"
		i: -8
		j: 2147483647
		--assert not error? try [ strict-equal? 2147483639 -8 // 2147483647 ]
		--assert not error? try [ strict-equal? 2147483639 modulo -8 2147483647 ]
		--assert not error? try [ strict-equal? 2147483639 i // j ]
		--assert not error? try [ strict-equal? 2147483639 modulo i j ]

	--test-- "-10 // -2147483648"
		i: -10
		j: -2147483648
		--assert error? try [ strict-equal? 2147483638 -10 // -2147483648 ]
		--assert error? try [ strict-equal? 2147483638 modulo -10 -2147483648 ]
		--assert error? try [ strict-equal? 2147483638 i // j ]
		--assert error? try [ strict-equal? 2147483638 modulo i j ]

	--test-- "-10 // 2147483647"
		i: -10
		j: 2147483647
		--assert error? try [ strict-equal? 2147483637 -10 // 2147483647 ]
		--assert error? try [ strict-equal? 2147483637 modulo -10 2147483647 ]
		--assert error? try [ strict-equal? 2147483637 i // j ]
		--assert error? try [ strict-equal? 2147483637 modulo i j ]

===end-group===

~~~end-file~~~

~~~start-file~~~ "lexer.test"

===start-group=== "lexer-time"

	;;red
	--test-- "lexer-time-1" 
		--assert [2147483645:59:59]	= load/all {2147483645:59:59}
	;;der
	
===end-group===

~~~end-file~~~

~~~start-file~~~ "object"

===start-group=== "nested objects"
	--test-- "no5"
		--assert false
		comment{
		no5-o1: make object! [
			o2: make object! [
			o3: make object! [
			o4: make object! [
			o5: make object! [
			o6: make object! [
			o7: make object! [
			o8: make object! [
			o9: make object! [
			o10: make object! [
			o11: make object! [
			o12: make object! [
			o13: make object! [
			o14: make object! [
			o15: make object! [
				i: 1
			]]]]]]]]]]]]]]
		]

		--assert no5-o1/o2/o3/o4/o5/o6/o7/o8/o9/o10/o11/o12/o13/o14/o15/i = 1 
		}
		
	
===end-group===

~~~end-file~~~

~~~start-file~~~ "reactivity"
===start-group=== "IS function"

 --test-- "is-7"
		--assert not error? try [
			d: make reactor! [x: is [y + 1] y: is [x + 3]]
			--assert none? d/x
			--assert none? d/y
			d/x: 1
			--assert d/x = 5
			--assert d/y = 4
		]

===end-group===

~~~end-file~~~

~~~start-file~~~ "Switch"

===start-group=== "switch-all"			;; not sure if it will be implemented.
	
	--test-- "switch-all-1" 
	--assert false
		comment {
		sa1-i: 1
		sa1-j: 0
		;switch/all sa1-i [
			0	[sa1-j: sa1-j + 1]
			1	[sa1-j: sa1-j + 2]
			2	[sa1-j: sa1-j + 4]
		]
	    --assert sa1-j = 6 
	    }
	
===end-group===

~~~end-file~~~

~~~start-file~~~ "Time"

===start-group=== "Time - basic"
	; Max empirical value
	--test-- "tb-3"
		tb3-t: 2147483645:59:59
		--assert equal? tb3-t/hour 2147483645
		--assert equal? tb3-t/minute 59
		--assert equal? tb3-t/second 59
		--assert equal? first tb3-t 2147483645
		--assert equal? second tb3-t 59
		--assert equal? third tb3-t 59
		--assert equal? tb3-t 2147483644:58:58 + 1:1:1
		--assert equal? pick tb3-t 1 2147483645
		--assert equal? pick tb3-t 2 59
		--assert equal? pick tb3-t 3 59
		
	--test-- "tb-7"
		tb7-t: 2147483647:2147483647
		--assert strict-equal? tb7-t/hour -2147483648
		--assert strict-equal? tb7-t/minute 7
		--assert strict-equal? tb7-t/second 0.0

===end-group===

===start-group=== "Time - assignment"

	--test-- "ta-10"
		ta10-t: 0:0:0
		ta10-t/second: 59.9999999
		--assert equal? ta10-t 0:00:59.9999999

	--test-- "ta-11"
		ta11-t: 0:0:0
		ta11-t/second: 59.99999999
		--assert strict-equal? ta11-t 0:00:59.99999999

===end-group===

===start-group=== "Rudolf Meijer's Test Cases"

	--test-- "time-RM make f" --assert 1:02:03.4 == make time! 3723.4
	
===end-group===

~~~end-file~~~

~~~start-file~~~ "replace"

===start-group=== "replace/case"

	--test-- "replace/case-15"	--assert (quote :x/b/A/x/B) = replace/case/all quote :a/b/A/a/B [a] 'x

===end-group===

~~~end-file~~~

***end-run***