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

===start-group=== "basic tests"

	--test-- "basic-1"
		obj1: context []
		--assert "make object! []" = mold obj1

	--test-- "basic-2"
		obj2: object []
		--assert "make object! []" = mold obj2
		
	--test-- "basic-3"
		obj3: make object! []
		--assert "make object! []" = mold obj3
	
	--test-- "basic-4"
		blk: []
		obj4: object blk
		--assert "make object! []" = mold obj4
	
	--test-- "basic-5"
		obj5: object [
			a: 123
			show: does [a + 1]
			reset: does [a: none]
			--assert show = 124
			--assert a = 123
		]
		--assert obj5/show = 124
		obj5/reset
		--assert none? obj5/a

	--test-- "basic-6"
		obj5/a: 456
		--assert obj5/a = 456

	--test-- "basic-7"
		--assert find obj5 'a
		--assert not find obj5 'z
		--assert 456 = select obj5 'a
		--assert none? select obj5 'z

	--test-- "basic-8"
		obj8: context [
			b: 123
			a: object [
				b: 456
				double: does [b * 2]
				set-b: does [b: 'hello]
			]
		]
		--assert obj8/b = 123
		--assert obj8/a/b = 456
		--assert obj8/a/double = 912
		obj8/a/set-b
		--assert obj8/a/b = 'hello

	--test-- "basic-9"
		obj8/a/b: 'red
		--assert obj8/a/b = 'red

	--test-- "basic-10"
		obj10: object [
			a: 1
			b: 2
			inc: func [i /with a][b: i + either with [a][b]]
			sub: context [
				a: 3
				b: 4
				inc: func [i /with a][b: i + either with [a][b]]
			]
		]
		--assert 12 = obj10/inc 10
		--assert obj10/b = 12

		--assert 14 = obj10/sub/inc 10
		--assert obj10/sub/b = 14

	--test-- "basic-11"
		--assert 30 = obj10/inc/with 10 20
		--assert obj10/b = 30

		--assert 50 = obj10/sub/inc/with 10 40
		--assert obj10/sub/b = 50

	--test-- "basic-12"
		blk: [a: 99]
		obj12: object blk
		--assert obj12/a = 99

===end-group===


===start-group=== "Comparison tests"

	--test-- "comp-1"  --assert 	(context [])	 = (context [])
	--test-- "comp-2"  --assert not (context [a: 1]) = (context [])
	--test-- "comp-3"  --assert 	(context [a: 1]) = (context [a: 1])
	--test-- "comp-4"  --assert not (context [a: 1]) = (context [a: 2])
	--test-- "comp-5"  --assert 	(context [a: 1]) < (context [a: 2])
	--test-- "comp-6"  --assert not (context [a: 1]) >= (context [a: 2])
	--test-- "comp-7"  --assert 	(context [a: 2]) < (context [a: 1 b: none])

	--test-- "comp-8"
		obj:  context [a: 123]
		obj2: context [a: 123]
		--assert obj = obj2
		--assert not same? obj obj2
		--assert same? obj obj

===start-group=== "SELF test"


===end-group===

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

===start-group=== "object initialisation processing"

	--test-- "oip1"
		oip1-i: 1
		oip1-o: make object! [
			i: oip1-i
		]
		--assert 1 = oip1-o/i
		
	--test-- "oip2"
		oip2-i: 1
		oip2-o: make object! [
			i: either oip2-i = 1 [2] [3]
		]
		--assert 2 = oip2-o/i
	
	--test-- "oip3"
		oip3-i: 1
		oip3-o: make object! [
			i: 0
			set 'oip3-i 2
		]
		--assert 2 = oip3-i
		
	--test-- "oip4"
		oip4-o: make object! [
			i: 0
			set 'oip4-i 3
		]
		--assert 3 = oip4-i


===end-group===

===start-group=== "inheritance"

	--test-- "inherit-1"
		proto: context [
			a: 123
			get-a: does [a]
		]
		new: make proto [a: 99]
		--assert new/a = 99
		--assert new/get-a = 99
		--assert proto/a = 123
		--assert proto/get-a = 123

	--test-- "inherit-2"
		new/a: 456
		--assert new/get-a = 456
		proto/a: 759
		--assert proto/a = 759
		--assert new/get-a = 456

	--test-- "inherit-3"
		newnew: make new [
			reset: does [a: none]
		]
		--assert newnew/a = 456
		newnew/reset
		--assert none? newnew/a
		--assert new/a = 456
		--assert proto/a = 759

	--test-- "inherit-4"
		base: context [
			v: 0
			foo: does [v]
		]

		i: 0
		list: []
		loop 2 [
			bb: make base [v: i]
			--assert bb/foo = i
			append list bb
			i: i + 1
		]
		--assert object? list/1
		--assert list/1/v = 0
		--assert list/2/v = 1

	--test-- "inherit-5"
		base5: context [
			b: 123
			get-b: does [b]
			a: object [
				b: 456
				double: does [b * 2]
				set-b: func [/with v] [b: either with [v]['hello]]
			]
		]
		proto5: context [
			b: 999
			value: 71
			foo: does [b + value]
		]
		new: make base5 proto5
		--assert object? new
		--assert new/b = 999
		--assert new/value = 71
		--assert new/a/b = 456
		--assert base5/b = 123

	--test-- "inherit-6"
		--assert new/get-b = 999
		--assert new/a/double = 912
		--assert new/a/set-b/with 10
		--assert new/a/b = 10
		--assert new/b = 999
		--assert base5/b = 123
		--assert new/a/double = 20
		--assert base5/a/double = 20

	--test-- "inherit-7"
		--assert same? new/a base5/a

	--test-- "inherit-8"
		--assert new/foo = 1070

	--test-- "inherit-9"
		base9: context [
			v: 123456
			show: does [v]
		]
		i: 100
		list: []
		loop 3 [
			new9: make base9 [v: i]
			--assert new9/v = i
			--assert new9/show = i
			append list new9
			i: i + 1
		]
		--assert base9/v = 123456
		--assert list/1/v = 100
		--assert list/2/v = 101
		--assert list/3/v = 102

===end-group===

===start-group=== "dynamic invocation"

	d: context [
		value: 998
	    f: does [value]
	]
	h: :d/f
	--assert h = 998
	d/value: 123
	--assert 123 = do [h]

~~~end-file~~~

