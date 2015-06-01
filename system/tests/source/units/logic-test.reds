Red/System [
	Title:   "Red/System logic! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %logic-test.reds
	Version: 0.1.1
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "logic"

===start-group=== "literal logic! value tests"
	--test-- "llv-1"
		--assert true
  
	--test-- "llv-2"
		--assert not false
===end-group===
  
===start-group=== "logic variable tests"
	--test-- "lv-1"
	 	a: true
	 	--assert a
  
	--test-- "lv-2"
	 	a: false
	 	--assert not a
===end-group===

===start-group=== "conditional expression assignment tests"
	--test-- "lce-1"
		a: 3 < 5
		--assert a
  
	--test-- "lce-2"
		a: 1 = 2
		--assert not a
===end-group===
  
===start-group=== "logic value as last conditional expression in UNTIL tests"
  --test-- "lu-1"
    a: true
    i: 0
    until [
      i: i + 1
      a
    ]
  --assert i = 1
  
  --test-- "lu-2"
    i: 0
    c: 3
    stop?: false
    until [
      i: i + 1
      c: c - 1
      if zero? c [stop?: true]
      stop?
    ]
  --assert c = 0
  --assert i = 3
===end-group===

===start-group=== "logic value as conditional expression in WHILE tests"
	--test-- "lw-1"
		a: false
		i: 0 
		while [a][i: i + 1]
		--assert i = 0
	
	--test-- "lw-2"
		i: 0
		c: 3
		run?: true
		while [run?][
			i: i + 1
			c: c - 1
			if zero? c [run?: false]
		]
		--assert c = 0
		--assert i = 3
===end-group===

===start-group=== "passing logic! as function's argument tests"
	log-foo: func [a [logic!] return: [logic!]][a]
  
	--test-- "logic-arg-1"	--assert log-foo true
	--test-- "logic-arg-2"	--assert not log-foo false
	--test-- "logic-arg-3"	--assert log-foo 1 < 2
	--test-- "logic-arg-4"	--assert log-foo 3 <> 4
	--test-- "logic-arg-5"	--assert log-foo (1 + 1 < 3)
	--test-- "logic-arg-6"
		a: false
		if false = log-foo (2 + 2 = 5) [a: true]
		--assert a
	--test-- "logic-arg-7"
		--assert not log-foo 3 = 4

===end-group===
  
===start-group=== "all with logic!"

	--test-- "logic-all-1"
	 	result:  all [
	 		true
	 		true
	 	]
	 	--assert result
	
	--test-- "logic-all-2"
		result: all [
			false
			true
		]
		--assert not result
	
	--test-- "logic-all-3"
		result all [
			true
			false
		]
		--assert not result
	
	--test-- "logic-all-4"
		result: all [
			false
			false
		]
		--assert not result
	
	--test-- "logic-all-5"
		a: all [true]
		--assert a
	
	--test-- "logic-all-6"
		a: all [false]
		--assert not a
	
	--test-- "logic-all-7"
		a: all [1 < 2 false]
		--assert not a
	
	--test-- "logic-all-8"
		a: all [false 1 < 2]
		--assert not a
	
	--test-- "logic-all-9"
		a: all [true 1 = 2]
		--assert not a
	
	--test-- "logic-all-10"
		a: all [1 = 2 true]
		--assert not a
	
	--test-- "logic-all-11"
		a: all [1 < 2]
		--assert a
	
	--test-- "logic-all-12"
		a: all [1 = 2]
		--assert not a
	
	--test-- "logic-all-13"
		a: all [1 < 2 3 <> 4]
		--assert a
	
	--test-- "logic-all-14"
		a: all [1 = 2 3 <> 4]
		--assert not a
	
	--test-- "logic-all-15"
		--assert not log-foo all [1 = 2]
	
	--test-- "logic-all-16"
		--assert log-foo all [1 < 2 3 <> 4]
	
	--test-- "logic-all-17"
		--assert not log-foo all [1 = 2 3 <> 4]
	
	--test-- "logic-all-18"
		a: log-foo all [1 < 2]
		--assert a 
	
	--test-- "logic-all-19"
		a: log-foo all [1 = 2]
		--assert not a
	
	--test-- "logic-all-20"
		a: log-foo all [1 < 2 3 <> 4]
		--assert a
	
	--test-- "logic-all-21"
		a: all [log-foo true]
		--assert a
  
===end-group===

===start-group=== "any with logic!"

	--test-- "logic-any-1"
		result: any [
			true
			true
		]
		--assert result
	
	--test-- "logic-any-2"
		result: any [
			false
			true
		]
		--assert result
	
	--test-- "logic-any-3"
		result: any [
			true
			false
		]
		--assert result
	
	--test-- "logic-any-4"
		result: any [
			false
			false
		]
		--assert not result
	
	--test-- "logic-any-5"
		a: any [true]
		--assert a
	
	--test-- "logic-any-6"
		a: any [false]
		--assert not a
	
	--test-- "logic-any-7"
		a: any [1 < 2 false]
		--assert a
	
	--test-- "logic-any-8"
		a: any [false 1 < 2]
		--assert a
	
	--test-- "logic-any-9"
		a: any [true 1 = 2]
		--assert a
	
	--test-- "logic-any-10"
		a: any [1 = 2 true]
		--assert a
	
	--test-- "logic-any-11"
		a: any [1 < 2]
		--assert a
	
	--test-- "logic-any-12"
		a: any [1 = 2]
		--assert not a
	
	--test-- "logic-any-13"
		a: any [1 < 2 3 <> 4]
		--assert a
	
	--test-- "logic-any-14"
		a: any [1 = 2 3 <> 4]
		--assert a
	
	--test-- "logic-any-15"				
		--assert not log-foo any [1 = 2]
	
	--test-- "logic-any-16"
		--assert log-foo any [1 < 2 3 <> 4]
	
	--test-- "logic-any-17"
		--assert log-foo any [1 = 2 3 <> 4]
	
	--test-- "logic-any-18"
		a: log-foo any [1 < 2]
		--assert a 
	
	--test-- "logic-any-19"
		a: log-foo any [1 = 2]
		--assert not a 
	
	--test-- "logic-any-20"
		a: log-foo any [1 < 2 3 <> 4]
		--assert a
	
	--test-- "logic-any-21"
		a: any [log-foo true]
		--assert a

===end-group===

===start-group=== "function returning a logic value"
		lgc-test?: func [
			return: [logic!]
		][
			either 1 < 2 [true] [false]
		]

	--test-- "logic-return-1" 
		--assert lgc-test?
	
	--test-- "logic-return-2"
		a: lgc-test?
		--assert a
	
		lgc-test2?: func [
			return: [logic!]
		][
			either 1 = 2 [true] [false]
		]
	
	--test-- "logic-return-3"
		--assert not lgc-test2?
	
	--test-- "logic-return-4"
		a: lgc-test2?
		--assert not a
	
		lgc-test3?: func [return: [logic!]][
			either true [
				1 = 3
			][
				false
			]
		]
	
	--test-- "logic-return-5"
		--assert not lgc-test3?
 
		lgc-test4?: func [return: [logic!]][
			either false [
				1 = 3
			][
				false
			]
		]
	
	--test-- "logic-return-6"
		--assert not lgc-test4?
 
		lgc-test5?: func [return: [logic!]][
			either 1 < 2 [true] [false]
		]

	--test-- "logic-return-7"
		--assert lgc-test5?

===end-group===

===start-group=== "equality lgc-tests"

	--test-- "logic-=-1"
		a: false
		--assert a = false
	
	--test-- "logic-=-2"
		a: true
		--assert not a = false
	
	--test-- "logic-=-3"
		a: false
		--assert not a <> false
	
	--test-- "logic-=-4"
		a: true
		--assert a <> false
	
	--test-- "logic-=-5"
		a: false
		b: a = false
		--assert b
	
	--test-- "logic-=-6"
		a: true
		b: a = false
		--assert not b
	
	--test-- "logic-=-7"
		a: false
		b: false <> a
		--assert not b
	
	--test-- "logic-=-8"
		a: true
		b: false <> a
		--assert b
	
	--test-- "logic-=-9"
		a: false
		--assert log-foo a = false
	
	--test-- "logic-=-10"
		a: false
		--assert log-foo a = false
	
	--test-- "logic-=-11"
		a: true
		--assert not log-foo a = false
	
===end-group===

===start-group=== "logic value returned by function"

		fooT: func [return: [logic!]][1 < 2]
		fooF: func [return: [logic!]][1 = 2]

	--test-- "logic-ret-1" --assert fooT
	--test-- "logic-ret-2" --assert not fooF

===end-group===

===start-group=== "logic logical operators"
	--test-- "logic-and-1"	--assert true and true
	--test-- "logic-and-2"	--assert not (true and false)
	--test-- "logic-and-3"	--assert not (false and false)
	--test-- "logic-and-4"  --assert not (false and true)
	--test-- "logic-and-5"	
		la5-l1: true
		la5-l2: true
		--assert la5-l1 and la5-l2
	--test-- "logic-and-6"
		la6-l1: true
		la6-l2: false
		--assert not (la6-l1 and la6-l2)
	--test-- "logic-and-7"
		la7-l1: false
		la7-l2: false
		--assert not (la7-l1 and la7-l2)
	--test-- "logic-and-8"
		la8-l1: false
		la8-l2: true
		--assert not (la8-l1 and la8-l2)
	--test-- "logic-or-1"	--assert true or true
	--test-- "logic-or-2"	--assert true or false
	--test-- "logic-or-3"	--assert not (false or false)
	--test-- "logic-or-4"	--assert false or true
	--test-- "logic-or-5"	
		lo5-l1: true
		lo5-l2: true
		--assert lo5-l1 or lo5-l2
	--test-- "logic-or-6"
		lo6-l1: true
		lo6-l2: false
		--assert lo6-l1 or lo6-l2
	--test-- "logic-or-7"
		lo7-l1: false
		lo7-l2: false
		--assert not (lo7-l1 or lo7-l2)
	--test-- "logic-or-8"
		lo8-l1: false
		lo8-l2: true
		--assert lo8-l1 or lo8-l2
	--test-- "logic-xor-1"	--assert not (true xor true)
	--test-- "logic-xor-2"	--assert true xor false
	--test-- "logic-xor-3"	--assert not (false xor false)
	--test-- "logic-xor-4"  --assert false xor true
	--test-- "logic-xor-5"	
		lx5-l1: true
		lx5-l2: true
		--assert not (lx5-l1 xor lx5-l2)
	--test-- "logic-xor-6"
		lx6-l1: true
		lx6-l2: false
		--assert lx6-l1 xor lx6-l2
	--test-- "logic-xor-7"
		lx7-l1: false
		lx7-l2: false
		--assert not (lx7-l1 xor lx7-l2)
	--test-- "logic-xor-8"
		lx8-l1: false
		lx8-l2: true
		--assert lx8-l1 xor lx8-l2

===end-group===

~~~end-file~~~
