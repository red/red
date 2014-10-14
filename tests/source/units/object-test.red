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

===end-group===

===start-group=== "SELF test"

	--test-- "self-1"
		obj: context [
			--assert "make object! []" = mold/flat self
		]

	--test-- "self-2"
		obj: context [
			a: 123
			--assert "make object! [a: 123 b: unset]" = mold/flat self
			b: 456
		]

	--test-- "self-3"
		result: {make object! [b: 123 c: "hello" show: func [][--assert object? self] foo: unset]}
		
		obj: object [
			b: 123
			c: "hello"
			show: does [--assert object? self]
			--assert result = mold/flat self
			foo: does [--assert object? self c: none]
			foo
		]
		obj/show
		--assert none? obj/c

	--test-- "self-4"
		p1: object [
		    a: 1
		    b: 2
		    e: does [self/b]
		    f: does [self/b: 789 self/e]
		    --assert self/e = 2
		]
		--assert p1/e = 2
		--assert p1/f = 789

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
		
	--test-- "no6 issue #928"
		no6-o: make object! [
			a: 1
			o: make object! [
				b: 2
				f: does [a]
				]
			]
		--assert 1 = no6-o/o/f
		
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
		
	--test-- "inherit-10"
		base10: make object! [
			oo: make object! [
				a: 1
			]
		]
		new10: make base10 []
		base10/oo/a: 9
		--assert 9 = new10/oo/a
		
	--test-- "inherit-11"
		base11: make object! [
			a: 1
			oo: make object! [
				f: func [][a]
			]
		]
		new11: make base11 [a: 2]
		--assert 1 = new11/oo/f

===end-group===

===start-group=== "external deep setting"

	--test-- "ext-1"
		p1: object [
		    a: 1
		    b: 2
		]

		p1/a: context [
			t: 99
			z: 128
			q: object [zz: 345 show: does [zz]]
		]
		--assert object? p1/a
		--assert p1/a/z = 128
		--assert p1/a/q/show = 345

	--test-- "ext-2"
		p1/a/t: does [123]
		--assert p1/a/t = 123

===end-group===

===start-group=== "dynamic invocation"

	--test-- "dyn-1"
		d: context [
			value: 998
		    f: does [value]
		]
		h: :d/f
		--assert h = 998
		d/value: 123
		--assert 123 = do [h]


	--test-- "dyn-2"
		f: func [/local z][
		    z: object [
		        a: 1
		        g: func [/with b /local c][c: 10 either with [a + b + 10][a * 2]]
		        j: func [i][i + 1]
		    ]
	    	z
		]
		o: make f [a: 3]
		--assert 46 = o/j 45
		--assert 101 = o/j 100

	--test-- "dyn-3"
		--assert 52 = o/j o/j 50

	--test-- "dyn-4"
		--assert 33 = o/g/with 20
		--assert 59 = o/g/with o/j 45

	--test-- "dyn-5"
		--assert 12 = o/j z: 5 + 6
		--assert  z = 11

	--test-- "dyn-6"
		--assert [17] = reduce [o/j o/j z: 5 + 10]
		--assert z = 15

	--test-- "dyn-7"
		repeat c 1 [
			if yes [
				--assert 52 = o/j o/j 50
				--assert 59 = o/g/with o/j 45
				--assert [22] = reduce [o/j o/j z: 5 + 15]
				--assert z = 20
			]
		]

	--test-- "dyn-8"
		o2: context [zz: none]				;-- test renaming a statically compiled object

		f: func [/alt][
			either alt [
				make object! [
					a: 10
					g: 123
				]
			][
				make object! [
					a: 1
					g: does [a]
				]
			]
		]
		o2: f
		--assert 1 = o2/g

	--test-- "dyn-9"
		o2: f/alt
		--assert 123 = o2/g

===end-group===

===start-group=== "copy"
	
	--test-- "copy-1"
		co1: make object! [a: 1]
		co2: copy co1
		co1/a: 2
		--assert 2 = co1/a
		--assert 1 = co2/a
	
	--test-- "copy-2"
		co1: make object! [
			a: 1
			f: func[][a]
		]
		co2: copy co1
		co1/a: 2
		--assert 2 = co1/f
		--assert 2 = co2/f
		
	--test-- "copy-3"
		co1: make object! [
			a: 1
			b: 2
			blk: [1 2 3 4]
		]
		co2: copy co1
		co1/blk/1: 5
		--assert 5 = co1/blk/1 
		--assert 5 = co2/blk/1
		
	--test-- "copy-4"
		co1: make object! [
			a: 1
			b: 2
			blk: [1 2 3 4]
		]
		co2: copy/deep co1
		co1/blk/1: 5
		--assert 5 = co1/blk/1 
		--assert 1 = co2/blk/1
		
	--test-- "copy-5"
		co1: make object! [
			a: 1
			s: "Silly old string"
			f: func [][
				[s a]
			]
		]
		co2: copy co1
		co1/a: 5
		co1/s/2: #"h"
		co1/s/3: #"i"
		co1/s/4: #"n"
		--assert "Shiny old string" = co1/s
		--assert "Shiny old string" = co2/s
		
	--test-- "copy-6"
		co1: make object! [
			a: 1
			s: "Silly old string"
		]
		co2: copy co1
		co1/a: 5
		co1/s/2: #"h"
		co1/s/3: #"i"
		co1/s/4: #"n"
		replace co1/s "old" "new"
		--assert "Shiny new string" = co1/s
		--assert "Shiny new string" = co2/s
		
	--test-- "copy-7"
		co5: make object! [
			a: 1
			s: ["Silly old string"]
		]
		co6: copy/deep co5
		co5/a: 5
		co5/s/2: #"h"
		co5/s/3: #"i"
		co5/s/4: #"n"
		replace co5/s "old" "new"
		--assert "Shiny new string" = co5/s
		--assert "Silly old string" = co6/s
		
	--test-- "copy-8"
		co1: make object! [
			s: "Silly old string"
			f: func[][s]
		]
		co2: copy co1
		co1/s/2: #"h"
		co1/s/3: #"i"
		co1/s/4: #"n"
		replace co1/s "old" "new"
		--assert "Shiny new string" = co1/f
		--assert "Shiny new string" = co2/f
		
	--test-- "copy-9"
		co1: make object! [
			s: "Silly old string"
			f: func[][s]
		]
		co2: copy/deep co1
		co1/s/2: #"h"
		co1/s/3: #"i"
		co1/s/4: #"n"
		replace co1/s "old" "new"
		--assert "Shiny new string" = co1/f
		--assert "Silly old string" = co2/f
	
	--test-- "copy-10"
		co1: make object! [
			a: 1
			f: func[][a]
		]
		co2: copy/deep co1
		co1/a: 2
		--assert 2 = co1/f
		--assert 1 = co2/f
		
	--test-- "copy-11"
		co1: make object! [
			a: 1
			oo: make object! [
				f: func[][a]
			]
		]
		co2: copy/deep co1
		co1/a: 2
		--assert 2 = co1/oo/f
		--assert 2 = co2/oo/f
		
	--test-- "copy-12"
		co1: make object! [
			a: 1
			oo: make object! [
				f: func[][a]
			]
		]
		co2: copy/deep co1
		co1/a: 2
		--assert 2 = co1/oo/f
		--assert 2 = co2/oo/f
		
===end-group===

===start-group=== "in"

	--test-- "in1"
		ino1: make object! [
			i: 1
			c: #"a"
			f: 1.0
			b: [1 2 3 4]
			s: "abcdef"
			o: make object! [
			]
		]
		--assert 'i = in ino1 'i
		--assert 'c = in ino1 'c
		--assert 'b = in ino1 'b
		--assert 'f = in ino1 'f
		--assert 's = in ino1 's
		--assert 'o = in ino1 'o
		

	--test-- "in2"
		ino1: make object! [
			i: 1
			c: #"a"
			f: 1.0
			b: [1 2 3 4]
			s: "abcdef"
			o: make object! [
				c: #"b"
				i: 2
				f: 2.0
				b: [5 6 7 8]
				s: "ghijkl"
				o: make object! [
				]
			]
		]
		--assert 'i = in ino1 'i
		--assert 'c = in ino1 'c
		--assert 'b = in ino1 'b
		--assert 'f = in ino1 'f
		--assert 's = in ino1 's
		--assert 'o = in ino1 'o
		--assert 'i = in ino1/o 'i
		--assert 'c = in ino1/o 'c
		--assert 'b = in ino1/o 'b
		--assert 'f = in ino1/o 'f
		--assert 's = in ino1/o 's
		--assert 'o = in ino1/o 'o


	--test-- "in3"
		ino1: make object! [
			i: 1
			c: #"a"
			f: 1.0
			b: [1 2 3 4]
			s: "abcdef"
			o: make object! [
				c: #"b"
				i: 2
				f: 2.0
				b: [5 6 7 8]
				s: "ghijkl"
				o: make object! [
					c: #"c"
					i: 3
					f: 3.0
					b: [9 10 11 12]
					s; "mnopqr"
					o: make object! [
					]
				]
			]
		]
		--assert 'i = in ino1 'i
		--assert 'c = in ino1 'c
		--assert 'b = in ino1 'b
		--assert 'f = in ino1 'f
		--assert 's = in ino1 's
		--assert 'o = in ino1 'o
		--assert 'i = in ino1/o 'i
		--assert 'c = in ino1/o 'c
		--assert 'b = in ino1/o 'b
		--assert 'f = in ino1/o 'f
		--assert 's = in ino1/o 's
		--assert 'o = in ino1/o 'o
		--assert 'i = in ino1/o/o 'i
		--assert 'c = in ino1/o/o 'c
		--assert 'b = in ino1/o/o 'b
		--assert 'f = in ino1/o/o 'f
		--assert 's = in ino1/o/o 's
		--assert 'o = in ino1/o/o 'o

		--test-- "in4"
		ino1: make object! [
			i: 1
			c: #"a"
			f: 1.0
			b: [1 2 3 4]
			s: "abcdef"
			o: make object! [
				c: #"b"
				i: 2
				f: 2.0
				b: [5 6 7 8]
				s: "ghijkl"
				o: make object! [
					c: #"c"
					i: 3
					f: 3.0
					b: [9 10 11 12]
					s; "mnopqr"
					o: make object! [
						c: #"d"
						f: 4.0
						i: 4
						b: [13 14 15 16]
						s: "stuvwx"
					]
				]
			]
		]
		--assert 'i = in ino1 'i
		--assert 'c = in ino1 'c
		--assert 'b = in ino1 'b
		--assert 'f = in ino1 'f
		--assert 's = in ino1 's
		--assert 'o = in ino1 'o
		--assert 'i = in ino1/o 'i
		--assert 'c = in ino1/o 'c
		--assert 'b = in ino1/o 'b
		--assert 'f = in ino1/o 'f
		--assert 's = in ino1/o 's
		--assert 'o = in ino1/o 'o
		--assert 'i = in ino1/o/o 'i
		--assert 'c = in ino1/o/o 'c
		--assert 'b = in ino1/o/o 'b
		--assert 'f = in ino1/o/o 'f
		--assert 's = in ino1/o/o 's
		--assert 'o = in ino1/o/o 'o
		--assert 'i = in ino1/o/o/o 'i
		--assert 'c = in ino1/o/o/o 'c
		--assert 'b = in ino1/o/o/o 'b
		--assert 'f = in ino1/o/o/o 'f
		--assert 's = in ino1/o/o/o 's
	
===end-group===


===start-group=== "local objects"

	f-make-obj-1: func [/local z][
	    z: object [
	        a: 1
	        g: func [/with b /local q][q: 10 either with [a + b + 10][a * 2]]
	        j: func [i][i + 1]
	    ]
		z
	]

	f-make-obj-2: func [/alt][
		either alt [
			make object! [
				a: 10
				g: 123
			]
		][
			make object! [
				a: 1
				g: does [a]
			]
		]
	]

	so3-f: func [][0]

	local-obj-fun: function [][

		--test-- "loc-basic-1"
			obj1: context []
			--assert "make object! []" = mold obj1

		--test-- "loc-basic-2"
			obj2: object []
			--assert "make object! []" = mold obj2
			
		--test-- "loc-basic-3"
			obj3: make object! []
			--assert "make object! []" = mold obj3
		
		--test-- "loc-basic-4"
			blk: []
			obj4: object blk
			--assert "make object! []" = mold obj4
		
		--test-- "loc-basic-5"
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

		--test-- "loc-basic-6"
			obj5/a: 456
			--assert obj5/a = 456

		--test-- "loc-basic-7"
			--assert find obj5 'a
			--assert not find obj5 'z
			--assert 456 = select obj5 'a
			--assert none? select obj5 'z

		--test-- "loc-basic-8"
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

		--test-- "loc-basic-9"
			obj8/a/b: 'red
			--assert obj8/a/b = 'red

		--test-- "loc-basic-10"
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

		--test-- "loc-basic-11"
			--assert 30 = obj10/inc/with 10 20
			--assert obj10/b = 30

			--assert 50 = obj10/sub/inc/with 10 40
			--assert obj10/sub/b = 50

		--test-- "loc-basic-12"
			blk: [a: 99]
			obj12: object blk
			--assert obj12/a = 99


		--test-- "loc-comp-1"  --assert 	(context [])	 = (context [])
		--test-- "loc-comp-2"  --assert not (context [a: 1]) = (context [])
		--test-- "loc-comp-3"  --assert 	(context [a: 1]) = (context [a: 1])
		--test-- "loc-comp-4"  --assert not (context [a: 1]) = (context [a: 2])
		--test-- "loc-comp-5"  --assert 	(context [a: 1]) < (context [a: 2])
		--test-- "loc-comp-6"  --assert not (context [a: 1]) >= (context [a: 2])
		--test-- "loc-comp-7"  --assert 	(context [a: 2]) < (context [a: 1 b: none])

		--test-- "loc-comp-8"
			obj:  context [a: 123]
			obj2: context [a: 123]
			--assert obj = obj2
			--assert not same? obj obj2
			--assert same? obj obj


		--test-- "loc-self-1"
			obj: context [
				--assert "make object! []" = mold/flat self
			]

		--test-- "loc-self-2"
			obj: context [
				a: 123
				--assert "make object! [a: 123 b: unset]" = mold/flat self
				b: 456
			]

		--test-- "loc-self-3"
			result: {make object! [b: 123 c: "hello" show: func [][--assert object? self] foo: unset]}
			
			obj: object [
				b: 123
				c: "hello"
				show: does [--assert object? self]
				--assert result = mold/flat self
				foo: does [--assert object? self c: none]
				foo
			]
			obj/show
			--assert none? obj/c

		--test-- "loc-self-4"
			p1: object [
			    a: 1
			    b: 2
			    e: does [self/b]
			    f: does [self/b: 789 self/e]
			    --assert self/e = 2
			]
			--assert p1/e = 2
			--assert p1/f = 789

		
		--test-- "loc-simple object 1"
			so1-a: 0
			so1-o: make object! [so1-a: 1]
			--assert so1-a = 0
			--assert so1-o/so1-a = 1
			
		--test-- "loc-simple object 2"
			so2-s: "0"
			so2-o: make object! [so2-s: "1"]
			--assert so2-s = "0"
			--assert so2-o/so2-s = "1"
			
		--test-- "loc-simple object 3"
			so3-s: "0"
			so3-i: 0
			so3-l: true
			so3-c: #"a"
			so3-b: [a b c]
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
			

		--test-- "loc-no1"
			no1-o: make object! [o: make object! [i: 1] ]
			--assert no1-o/o/i = 1
			
		--test-- "loc-no2"
			no2-o1: make object! [
				o2: make object! [
					i: 1
				]
			]
			--assert no2-o1/o2/i = 1
			
		--test-- "loc-no3"
			no3-o1: make object! [
				o2: make object! [
				o3: make object! [
				o4: make object! [
					i: 1
				]]]
			]
			--assert no3-o1/o2/o3/o4/i = 1

		--test-- "loc-no4"
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
		
		--test-- "loc-no5"
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
			
		--test-- "loc-no6 issue #928"
			no6-o: make object! [
				a: 1
				o: make object! [
					b: 2
					f: does [a]
					]
				]
			--assert 1 = no6-o/o/f
		

		--test-- "loc-op1"
			op1-o1: make object! [i: 1]
			op1-o2: make op1-o1 []
			--assert op1-o2/i = 1
			
		--test-- "loc-op2"
			op2-o1: make object! [i: 1]
			op2-o2: make op2-o1 [i: 2]
			--assert op2-o2/i = 2
			--assert op2-o1/i = 1

		--test-- "loc-op3"
			op3-o1: make object! [i: 1]
			op3-o2: make op3-o1 [i: 2 j: 3]
			--assert op3-o2/i = 2
			--assert op3-o2/j = 3
			

		--test-- "loc-oip1"
			oip1-i: 1
			oip1-o: make object! [
				i: oip1-i
			]
			--assert 1 = oip1-o/i
			
		--test-- "loc-oip2"
			oip2-i: 1
			oip2-o: make object! [
				i: either oip2-i = 1 [2] [3]
			]
			--assert 2 = oip2-o/i
		
		--test-- "loc-oip3"
			oip3-i: 1
			oip3-o: make object! [
				i: 0
				set 'oip3-i 2
			]
			--assert 2 = oip3-i
			
		--test-- "loc-oip4"
			set 'oip4-i none
			oip4-o: make object! [
				i: 0
				set 'oip4-i 3
			]
			--assert 3 = oip4-i


		--test-- "loc-inherit-1"
			proto: context [
				a: 123
				get-a: does [a]
			]
			new: make proto [a: 99]
			--assert new/a = 99
			--assert new/get-a = 99
			--assert proto/a = 123
			--assert proto/get-a = 123

		--test-- "loc-inherit-2"
			new/a: 456
			--assert new/get-a = 456
			proto/a: 759
			--assert proto/a = 759
			--assert new/get-a = 456

		--test-- "loc-inherit-3"
			newnew: make new [
				reset: does [a: none]
			]
			--assert newnew/a = 456
			newnew/reset
			--assert none? newnew/a
			--assert new/a = 456
			--assert proto/a = 759

		--test-- "loc-inherit-4"
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

		--test-- "loc-inherit-5"
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

		--test-- "loc-inherit-6"
			--assert new/get-b = 999
			--assert new/a/double = 912
			--assert new/a/set-b/with 10
			--assert new/a/b = 10
			--assert new/b = 999
			--assert base5/b = 123
			--assert new/a/double = 20
			--assert base5/a/double = 20

		--test-- "loc-inherit-7"
			--assert same? new/a base5/a

		--test-- "loc-inherit-8"
			--assert new/foo = 1070

		--test-- "loc-inherit-9"
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


		--test-- "loc-ext-1"
			p1: object [
			    a: 1
			    b: 2
			]

			p1/a: context [
				t: 99
				z: 128
				q: object [zz: 345 show: does [zz]]
			]
			--assert object? p1/a
			--assert p1/a/z = 128
			--assert p1/a/q/show = 345

		--test-- "loc-ext-2"
			p1/a/t: does [123]
			--assert p1/a/t = 123

		--test-- "loc-dyn-1"
			d: context [
				value: 998
			    f: does [value]
			]
			;h: :d/f
			;--assert h = 998
			;d/value: 123
			;--assert 123 = do [h]

		--test-- "loc-dyn-2"

			o: make f-make-obj-1 [a: 3]
			--assert 46 = o/j 45
			--assert 101 = o/j 100

		--test-- "loc-dyn-3"
			--assert 52 = o/j o/j 50

		--test-- "loc-dyn-4"
			--assert 33 = o/g/with 20
			--assert 59 = o/g/with o/j 45

		--test-- "loc-dyn-5"
			--assert 12 = o/j z: 5 + 6
			--assert  z = 11

		--test-- "loc-dyn-6"
			--assert [17] = reduce [o/j o/j z: 5 + 10]
			--assert z = 15

		--test-- "loc-dyn-7"
			repeat c 1 [
				if yes [
					--assert 52 = o/j o/j 50
					--assert 59 = o/g/with o/j 45
					--assert [22] = reduce [o/j o/j z: 5 + 15]
					--assert z = 20
				]
			]

		--test-- "loc-dyn-8"
			o2: context [zz: none]				;-- test renaming a statically compiled object
			
			o2: f-make-obj-2
			--assert 1 = o2/g

		--test-- "loc-dyn-9"
			o2: f-make-obj-2/alt
			--assert 123 = o2/g

	]

	local-obj-fun

===end-group===



~~~end-file~~~

