Red/System [
	Title:   "Red/System getting variable pointer test script"
	Author:  "Nenad Rakocevic"
	File: 	 %get-pointer-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "get-pointer"

	--test-- "get-var-1"
		s: declare int-ptr!
		a: 123
		s: :a
		--assert s/value = 123
		
	--test-- "get-var-2"
		s2: declare byte-ptr!
		b: #"R"
		s2: :b
		--assert s2/value = #"R"
		
	--test-- "get-var-3"
		s3: declare pointer! [float!]
		c: 3.14
		s3: :c
		--assert s3/value = 3.14
		
	--test-- "get-var-4"
		s4: declare pointer! [float32!]
		d: as-float32 3.14
		s4: :d
		--assert s4/value = as float32! 3.14
		
	--test-- "get-var-local-1"
		s5: declare int-ptr!
		
		foo: func [/local a [integer!]][
			a: 456
			s5: :a
			--assert s5/value = 456
		]
		foo

	--test-- "get-path-1"
		s1: declare struct! [
			a	[integer!]
			b	[byte!]
			c	[integer!]
			d	[byte!]
		]
		
		s1/a: 123
		s1/b: #"b"
		s1/c: 456
		s1/d: #"d"
		
		gp1: :s1/a
		--assert gp1/value = 123
		--assert s1/a = 123
		
		gp1/value: 789
		--assert gp1/value = 789
		--assert s1/a = 789
		--assert s1/b = #"b"		;-- checks eventual overflow
		
		gp1: :s1/c
		gp1/value: 42
		--assert gp1/value = 42
		--assert s1/a = 789
		--assert s1/b = #"b"		;-- checks eventual overflow
		--assert s1/c = 42
		--assert s1/d = #"d"		;-- checks eventual overflow
		
	--test-- "get-path-2"
		gp2-fun: func [return: [int-ptr!]][:s1/c]
		
		gp2: gp2-fun
		gp2/value: -1
		--assert s1/a = 789
		--assert s1/b = #"b"		;-- checks eventual overflow
		--assert s1/c = -1
		--assert s1/d = #"d"		;-- checks eventual overflow
		
	--test-- "get-path-3"
		gp3!: alias struct! [z [integer!]]
		gp3-fun: func [return: [int-ptr!] /local ls [gp3!]][
			ls: declare gp3!
			ls/z: 147
			--assert true			;-- resets accumulator register
			:ls/z
		]
		p3: gp3-fun
		--assert p3/value = 147

	--test-- "get-path-4"
		gp4-fun: func [p [int-ptr!]][
			--assert p/value = 654
			p/value: 321
		]

		s1/c: 654
		gp4-fun :s1/c
		--assert s1/a = 789
		--assert s1/b = #"b"		;-- checks eventual overflow
		--assert s1/c = 321
		--assert s1/d = #"d"		;-- checks eventual overflow
		
	--test-- "get-path-5"
	
	b!: alias struct! [
		b1  [byte!]
		b2  [integer!]
	]
	gp5: declare struct! [
		x   [byte!]
		bb  [b!]
		val [integer!]
	]
	
	gp5/bb: as b! allocate size? b!
	gp5/bb/b1: #"A"
	p-bb-b1: :gp5/bb/b1
	--assert gp5/bb/b1 = #"A"
	--assert #"A" = as byte! p-bb-b1/value
		
~~~end-file~~~
