Red [
	Title:   "Red/System object! datatype test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %object-test.red
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2014 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "object"

===start-group=== "simple object tests"
	
	--test-- "simple object 1"
		so1-a: 0
		so1-o: make object! [so1-a: 1]
		--assert so1-a = 0
		--assert so1-o/so1-a = 1
		
	--test-- "simple object 2"
		so2-s: "0"
		so2-o: make object! [so2-s: "1"]
		--assert so2-s = "0"
		--assert so2-o/so2-s = "1"
		
	--test-- "simple object 3"
		so3-s: "0"
		so3-i: 0
		so3-l: true
		so3-c: #"a"
		so3-b: [a b c]
		so3-f: func [][0]
		so3-bs: charset #"^(00)"
		so3-o: make object! [
			so3-s: "1"
			so3-i: 1
			so3-l: false
			so3-c: #"b"
			so3-b: [a b d]
			so3-f: func [][1]
			so3-bs: charset #"^(01)"
		]
		--assert so3-s = "0"
		--assert so3-o/so3-s = "1"
		--assert so3-i = 0
		--assert so3-o/so3-i = 1
		--assert so3-l = true
		--assert so3-o/so3-l = false
		--assert so3-c = #"a"
		--assert so3-o/so3-c = #"b"
		--assert so3-b = [a b c]
		--assert so3-o/so3-b = [a b d]
		--assert so3-f = 0
		--assert so3-o/so3-f = 1
		--assert "make bitset! #{80}" = mold so3-bs
		--assert "make bitset! #{40}" = mold so3-o/so3-bs
		
===end-group===

===start-group=== "nested objects"

	--test-- "no1"
		no1-o: make object! [o: make object! [i: 1] ]
		--assert no1-o/o/i = 1
		
	--test-- "no2"
		no2-o1: make object! [
			o2: make object! [
				i: 1
			]
		]
		--assert no2-o1/o2/i = 1
		
	--test-- "no3"
		no3-o1: make object! [
			o2: make object! [
			o3: make object! [
			o4: make object! [
				i: 1
			]]]
		]
		--assert no3-o1/o2/o3/o4/i = 1

	--test-- "no4"
		no4-o1: make object! [
			o2: make object! [
			o3: make object! [
			o4: make object! [
			o5: make object! [
			o6: make object! [
			o7: make object! [
				i: 1
			]]]]]]
		]
		--assert no4-o1/o2/o3/o4/o5/o6/o7/i = 1
	
	--test-- "no5"
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
		
	--test-- "no6"
		no6-o1: make object! [
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
			o16: make object! [
				i: 1
			]]]]]]]]]]]]]]]
		]
		--assert no6-o1/o2/o3/o4/o5/o6/o7/o8/o9/o10/o11/o12/o13/o14/o15/o16/i = 1
		
	--test-- "no7"
		no7-o1: make object! [
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
			o16: make object! [
			o17: make object! [	
				i: 1
			]]]]]]]]]]]]]]]]
		]
		--assert no7-o1/o2/o3/o4/o5/o6/o7/o8/o9/o10/o11/o12/o13/o14/o15/o16/o17/i = 1
		
===end-group===

===start-group=== "object prototype tests"

	--test-- "op1"
		op1-o1: make object! [i: 1]
		op1-o2: make op1-o1 []
		--assert op1-o2/i = 1
		
	--test-- "op2"
		op2-o1: make object! [i: 1]
		op2-o2: make op2-o1 [i: 2]
		--assert op2-o2/i = 2
		--assert op2-o1/i = 1

	--test-- "op3"
		op3-o1: make object! [i: 1]
		op3-o2: make op3-o1 [i: 2 j: 3]
		--assert op3-o2/i = 2
		--assert op3-o2/j = 3
		
===end-group===

~~~end-file~~~

