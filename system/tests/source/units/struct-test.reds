Red/System [
	Title:   "Red/System struct! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %struct-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2017 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "struct!"

===start-group=== "Struct members simple read/write tests"

	--test-- "s-rw-1"
	struct1: declare struct! [b [integer!]]
	struct1/b: 12345
	--assert struct1/b = 12345
	
	--test-- "s-rw-2"
	struct2: declare struct! [b [byte!] c [c-string!] d [integer!]]
	struct2/c: "a"
	struct2/d: 9876
	struct2/b: #"R"				;-- intentionnaly put there to test not overlapping memory storage
	--assert struct2/b   = #"R"
	--assert struct2/c/1 = #"a"
	--assert struct2/d   = 9876
	
	--test-- "s-rw-3"
	--assert struct2/c/1 = #"a"
	
	--test-- "s-rw-4"
	--assert struct2/d   = 9876
	
	--test-- "s-rw-5"
	struct2/c/1: #"x"
	--assert struct2/c/1 = #"x"
	
	--test-- "s-rw-6"
	struct2-b: struct2/b
	struct2-c: struct2/c
	struct2-d: struct2/d
	--assert struct2-b   = #"R"
	
	--test-- "s-rw-7"
	--assert struct2-c/1 = #"x"
	
	--test-- "s-rw-8"
	--assert struct2-d   = 9876
	
	--test-- "s-rw-9"
	struct2-c/1: #"y"
	--assert struct2-c/1 = #"y"
	
	--test-- "s-rw-10"
	struct2-foo-int:  func [a [integer!] return: [integer!]][a]
	struct2-foo-byte: func [a [byte!] return: [byte!]][a]
	--assert 9876 = struct2-foo-int struct2/d
	
	--test-- "s-rw-11"
	--assert #"R" = struct2-foo-byte struct2/b

===end-group===

===start-group=== "Nested structs read/write tests"

	--test-- "s-nested-1"
	struct3: declare struct! [
		d [byte!]
		b [integer!]
		c [c-string!]
		sub [					;-- this is a reference to a struct! not a struct value
			struct! [
				e [integer!]
				f [c-string!]
			]
		]
		g [integer!]
	]
	struct3/sub: declare struct! [
		e [integer!]
		f [c-string!]
	]
	struct3/d: #"A"
	struct3/b: 123
	struct3/c: "test"
	struct3/g: 123456798
	struct3/sub/e: 987
	struct3/sub/f: "hello"
	
	--assert struct3/b = 123
	--assert struct3/g = 123456798
	
	--test-- "s-nested-2"
	--assert struct3/d = #"A"
	
	--test-- "s-nested-3"
	--assert struct3/c/1 = #"t"
	
	--test-- "s-nested-4"
	--assert all [
		struct3/c/1 = #"t"
		struct3/c/2 = #"e"
		struct3/c/3 = #"s"
		struct3/c/4 = #"t"
	]
	
	--test-- "s-nested-5"
	--assert struct3/sub/e = 987
	
	--test-- "s-nested-6"
	struct3-e: struct3/sub/e
	--assert struct3-e = 987
	
	--test-- "s-nested-7"
	--assert all [
		struct3/sub/f/1 = #"h"
		struct3/sub/f/2 = #"e"
		struct3/sub/f/3 = #"l"
		struct3/sub/f/4 = #"l"
		struct3/sub/f/5 = #"o"
	]
	
	--test-- "s-nested-8"
	struct3-f: struct3/sub/f
	--assert struct3-f/1 = #"h"
	
	--test-- "s-nested-9"
	struct3-byte: struct3/sub/f/2
	--assert struct3-byte = #"e"

===end-group===

===start-group=== "Local struct variables read/write tests"

struct-local-foo: func [
	/local
		struct1   [struct! [b [integer!]]]
		struct2   [struct! [b [byte!] c [c-string!] d [integer!]]]
		struct2-b [byte!]
		struct2-c [c-string!]
		struct2-d [integer!]
		struct3   [struct! [d [byte!] b [integer!] c [c-string!] sub [struct! [e [integer!] f [c-string!]]] g [integer!]]]
		struct3-e [integer!]
		struct3-f [c-string!]
		struct3-byte [byte!]
][
	--test-- "ls-rw-1"
	struct1: declare struct! [b [integer!]]
	struct1/b: 12345
	--assert struct1/b = 12345

	--test-- "ls-rw-2"
	struct2: declare struct! [b [byte!] c [c-string!] d [integer!]]
	struct2/c: "a"
	struct2/d: 9876
	struct2/b: #"R"				;-- intentionnaly put there to test not overlapping memory storage
	--assert struct2/b   = #"R"
	--assert struct2/c/1 = #"a"
	--assert struct2/d   = 9876
	
	--test-- "ls-rw-3"
	--assert struct2/c/1 = #"a"
	
	--test-- "ls-rw-4"
	--assert struct2/d   = 9876
	
	--test-- "ls-rw-5"
	struct2/c/1: #"x"
	--assert struct2/c/1 = #"x"
	
	--test-- "ls-rw-6"
	struct2-b: struct2/b
	struct2-c: struct2/c
	struct2-d: struct2/d
	--assert struct2-b   = #"R"
	
	--test-- "ls-rw-7"
	--assert struct2-c/1 = #"x"
	
	--test-- "ls-rw-8"
	--assert struct2-d   = 9876
	
	--test-- "ls-rw-9"
	struct2-c/1: #"y"
	--assert struct2-c/1 = #"y"
		
	--test-- "ls-rw-10"
	--assert 9876 = struct2-foo-int struct2/d

	--test-- "ls-rw-11"
	--assert #"R" = struct2-foo-byte struct2/b
	
	--test-- "ls-nested-1"
	struct3: declare struct! [
		d [byte!]
		b [integer!]
		c [c-string!]
		sub [					;-- this is a reference to a struct! not a struct value
			struct! [
				e [integer!]
				f [c-string!]
			]
		]
		g [integer!]
	]
	struct3/sub: declare struct! [
		e [integer!]
		f [c-string!]
	]
	struct3/d: #"A"
	struct3/b: 123
	struct3/c: "test"
	struct3/g: 123456798
	struct3/sub/e: 987
	struct3/sub/f: "hello"
	
	--assert struct3/b = 123
	--assert struct3/g = 123456798

	--test-- "ls-nested-2"
	--assert struct3/d = #"A"

	--test-- "ls-nested-3"
	--assert struct3/c/1 = #"t"

	--test-- "ls-nested-4"
	--assert all [
		struct3/c/1 = #"t"
		struct3/c/2 = #"e"
		struct3/c/3 = #"s"
		struct3/c/4 = #"t"
	]

	--test-- "ls-nested-5"
	--assert struct3/sub/e = 987

	--test-- "ls-nested-6"
	struct3-e: struct3/sub/e
	--assert struct3-e = 987

	--test-- "ls-nested-7"
	--assert all [
		struct3/sub/f/1 = #"h"
		struct3/sub/f/2 = #"e"
		struct3/sub/f/3 = #"l"
		struct3/sub/f/4 = #"l"
		struct3/sub/f/5 = #"o"
	]

	--test-- "ls-nested-8"
	struct3-f: struct3/sub/f
	--assert struct3-f/1 = #"h"

	--test-- "ls-nested-9"
	struct3-byte: struct3/sub/f/2
	--assert struct3-byte = #"e"
]
struct-local-foo

===end-group===


===start-group=== "Struct variables arithmetic"

	--test-- "struct-math-1"
	struct4: declare struct! [
		a [struct! [value [integer!]]]
		b [struct! [value [integer!]]]
		c [struct! [value [integer!]]]
	]
	struct5: declare struct! [value [integer!]]

	struct4/a: declare struct! [value [integer!]]
	struct4/b: declare struct! [value [integer!]]
	struct4/c: declare struct! [value [integer!]]

	struct4/a/value: 123
	struct4/b/value: 456
	struct4/c/value: 789
	
	--assert struct4/a/value = 123
	--assert struct4/b/value = 456
	--assert struct4/c/value = 789
	
	struct5: struct4/a
	--assert struct5/value = 123
	
	--test-- "struct-math-2"
	struct5: struct5 + 1
	--assert struct5/value = 456

	--test-- "struct-math-3"
	struct5: struct4/c
	--assert struct5/value = 789
	struct5: struct5 - 2
	--assert struct5/value = 123
	
	--test-- "struct-math-4"
	struct-idx: 2
	struct5: struct5 + struct-idx
	--assert struct5/value = 789
	
	--test-- "struct-math-5"
	struct-idx: -2
	struct5: struct5 + struct-idx
	--assert struct5/value = 123

	--test-- "struct-math-6"
	struct-idx: -2
	struct5: struct5 - struct-idx
	--assert struct5/value = 789
	
	
	--test-- "struct-math-7"
	struct6: declare struct! [
		a [struct! [value [byte!]]]
		b [struct! [value [byte!]]]
		c [struct! [value [byte!]]]
	]
	struct7: declare struct! [value [byte!]]

	struct6/a: declare struct! [value [byte!]]
	struct6/b: declare struct! [value [byte!]]
	struct6/c: declare struct! [value [byte!]]

	struct6/a/value: #"a"
	struct6/b/value: #"b"
	struct6/c/value: #"c"

	--assert struct6/a/value = #"a"
	--assert struct6/b/value = #"b"
	--assert struct6/c/value = #"c"

	struct7: struct6/a
	--assert struct7/value = #"a"

	--test-- "struct-math-8"
	struct7: struct7 + 1
	--assert struct7/value = #"b"

	--test-- "struct-math-9"
	struct7: struct6/c
	--assert struct7/value = #"c"
	struct7: struct7 - 2
	--assert struct7/value = #"a"

	--test-- "struct-math-10"
	struct-idx: 2
	struct7: struct7 + struct-idx
	--assert struct7/value = #"c"

	--test-- "struct-math-11"
	struct-idx: -2
	struct7: struct7 + struct-idx
	--assert struct7/value = #"a"

	--test-- "struct-math-12"
	struct-idx: -2
	struct7: struct7 - struct-idx
	--assert struct7/value = #"c"
	
	--test-- "struct-math-13"
	struct8: declare struct! [
		a [struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]]
		b [struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]]
		c [struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]]
	]
	struct9: declare struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]

	struct8/a: declare struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]
	struct8/b: declare struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]
	struct8/c: declare struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]

	struct8/a/v1: 123
	struct8/b/v1: 456
	struct8/c/v1: 789
	
	struct8/a/v2: #"a"
	struct8/b/v2: #"b"
	struct8/c/v2: #"c"
	
	struct8/a/v3: "A"
	struct8/b/v3: "B"
	struct8/c/v3: "C"

	--assert struct8/a/v1 = 123
	--assert struct8/b/v1 = 456
	--assert struct8/c/v1 = 789
	
	--assert struct8/a/v2 = #"a"
	--assert struct8/b/v2 = #"b"
	--assert struct8/c/v2 = #"c"
	
	--assert struct8/a/v3/1 = #"A"
	--assert struct8/b/v3/1 = #"B"
	--assert struct8/c/v3/1 = #"C"

	struct9: struct8/a
	--assert struct9/v1 = 123
	--assert struct9/v2 = #"a"
	--assert struct9/v3/1 = #"A"

	--test-- "struct-math-14"
	struct9: struct9 + 1
	--assert struct9/v1 = 456
	--assert struct9/v2 = #"b"
	--assert struct9/v3/1 = #"B"

===end-group===


===start-group=== "Local struct variables arithmetic"

struct-local-foo2: func [
	/local
		struct4 [struct! [
			a [struct! [value [integer!]]]
			b [struct! [value [integer!]]]
			c [struct! [value [integer!]]]
		]]
		struct5 [struct! [value [integer!]]]
		struct6 [struct! [
			a [struct! [value [byte!]]]
			b [struct! [value [byte!]]]
			c [struct! [value [byte!]]]
		]]
		struct7 [struct! [value [byte!]]]
		struct8 [struct! [
			a [struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]]
			b [struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]]
			c [struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]]
		]]
		struct9 [struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]]
		struct-idx [integer!]
][
	--test-- "loc-struct-math-1"
	struct4: declare struct! [
		a [struct! [value [integer!]]]
		b [struct! [value [integer!]]]
		c [struct! [value [integer!]]]
	]
	struct5: declare struct! [value [integer!]]

	struct4/a: declare struct! [value [integer!]]
	struct4/b: declare struct! [value [integer!]]
	struct4/c: declare struct! [value [integer!]]

	struct4/a/value: 123
	struct4/b/value: 456
	struct4/c/value: 789
	
	--assert struct4/a/value = 123
	--assert struct4/b/value = 456
	--assert struct4/c/value = 789
	
	struct5: struct4/a
	--assert struct5/value = 123
	
	--test-- "loc-struct-math-2"
	struct5: struct5 + 1
	--assert struct5/value = 456

	--test-- "loc-struct-math-3"
	struct5: struct4/c
	--assert struct5/value = 789
	struct5: struct5 - 2
	--assert struct5/value = 123
	
	--test-- "loc-struct-math-4"
	struct-idx: 2
	struct5: struct5 + struct-idx
	--assert struct5/value = 789
	
	--test-- "loc-struct-math-5"
	struct-idx: -2
	struct5: struct5 + struct-idx
	--assert struct5/value = 123

	--test-- "loc-struct-math-6"
	struct-idx: -2
	struct5: struct5 - struct-idx
	--assert struct5/value = 789
	
	
	--test-- "loc-struct-math-7"
	struct6: declare struct! [
		a [struct! [value [byte!]]]
		b [struct! [value [byte!]]]
		c [struct! [value [byte!]]]
	]
	struct7: declare struct! [value [byte!]]

	struct6/a: declare struct! [value [byte!]]
	struct6/b: declare struct! [value [byte!]]
	struct6/c: declare struct! [value [byte!]]

	struct6/a/value: #"a"
	struct6/b/value: #"b"
	struct6/c/value: #"c"

	--assert struct6/a/value = #"a"
	--assert struct6/b/value = #"b"
	--assert struct6/c/value = #"c"

	struct7: struct6/a
	--assert struct7/value = #"a"

	--test-- "loc-struct-math-8"
	struct7: struct7 + 1
	--assert struct7/value = #"b"

	--test-- "loc-struct-math-9"
	struct7: struct6/c
	--assert struct7/value = #"c"
	struct7: struct7 - 2
	--assert struct7/value = #"a"

	--test-- "loc-struct-math-10"
	struct-idx: 2
	struct7: struct7 + struct-idx
	--assert struct7/value = #"c"

	--test-- "loc-struct-math-11"
	struct-idx: -2
	struct7: struct7 + struct-idx
	--assert struct7/value = #"a"

	--test-- "loc-struct-math-12"
	struct-idx: -2
	struct7: struct7 - struct-idx
	--assert struct7/value = #"c"
	
	--test-- "loc-struct-math-13"
	struct8: declare struct! [
		a [struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]]
		b [struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]]
		c [struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]]
	]
	struct9: declare struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]

	struct8/a: declare struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]
	struct8/b: declare struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]
	struct8/c: declare struct! [v1 [integer!] v2 [byte!] v3 [c-string!]]

	struct8/a/v1: 123
	struct8/b/v1: 456
	struct8/c/v1: 789
	
	struct8/a/v2: #"a"
	struct8/b/v2: #"b"
	struct8/c/v2: #"c"
	
	struct8/a/v3: "A"
	struct8/b/v3: "B"
	struct8/c/v3: "C"

	--assert struct8/a/v1 = 123
	--assert struct8/b/v1 = 456
	--assert struct8/c/v1 = 789
	
	--assert struct8/a/v2 = #"a"
	--assert struct8/b/v2 = #"b"
	--assert struct8/c/v2 = #"c"
	
	--assert struct8/a/v3/1 = #"A"
	--assert struct8/b/v3/1 = #"B"
	--assert struct8/c/v3/1 = #"C"

	struct9: struct8/a
	--assert struct9/v1 = 123
	--assert struct9/v2 = #"a"
	--assert struct9/v3/1 = #"A"

	--test-- "loc-struct-math-14"
	struct9: struct9 + 1
	--assert struct9/v1 = 456
	--assert struct9/v2 = #"b"
	--assert struct9/v3/1 = #"B"
]
struct-local-foo2

===end-group===

===start-group=== "Struct passed/returned by value"

	tiny!:  alias struct! [b1 [byte!]]
	small!: alias struct! [one [integer!] two [integer!]]
	big!:   alias struct! [one [integer!] two [integer!] three [float!]]
	huge!:  alias struct! [w1 [integer!] w2 [integer!] w3 [float!] w4 [integer!] w5 [integer!] w6 [float!]]
	super!: alias struct! [f1 [float!] f2 [float!] f3 [float!] f4 [float!] f5 [float!] f6 [float!]]

	nested1!: alias struct! [f1	[integer!] sub [tiny! value] f2	[integer!]]
	nested2!: alias struct! [f1	[integer!] sub [small! value] f2 [integer!]]
	nested3!: alias struct! [f1	[integer!] sub [big! value] f2 [integer!]]
	nested4!: alias struct! [g1	[integer!] sub [huge! value] g2	[integer!]]
	nested5!: alias struct! [g1	[integer!] sub [super! value] g2 [integer!]]
	
	#switch OS [
		Windows  [#define STRUCTLIB-file "structlib.dll"]
		MacOSX	 [#define STRUCTLIB-file "libstructlib.dylib"]
		#default [#define STRUCTLIB-file "libstructlib.so"]
	]

	#import [
		STRUCTLIB-file cdecl [
			returnTiny:  "returnTiny"  [return: [tiny! value]]
			returnSmall: "returnSmall" [return: [small! value]]
			returnBig:	 "returnBig"   [return: [big! value]]
			returnHuge:  "returnHuge"  [a [integer!] b [integer!] return: [huge! value]]
			returnHuge2: "returnHuge2" [h [huge! value] a [integer!] b [integer!] return: [huge! value]]
		]
	]
	s1: declare tiny!
	s2: declare small!
	s3: declare big!
	s4: declare huge!

	s1/b1: #"A"
	
	s2/one: 4
	s2/two: 5

	s3/one: 123
	s3/two: 456
	s3/three: 3.14

	s4/w1: 1
	s4/w2: 2
	s4/w3: 3.0
	s4/w4: 4
	s4/w5: 5
	s4/w6: 6.0

	sbvf1: func [s [tiny! value] v [integer!]][
		s/b1: #"x"
		--assert s/b1 = #"x"
		--assert v = 741
		s
	]

	sbvf2: func [s [tiny! value] v [integer!] return: [tiny! value] /local tmp [tiny! value]][
		--assert v = 123
		tmp/b1: s/b1
		--assert (as int-ptr! :tmp) = :tmp/b1
		--assert tmp/b1 = s/b1
		tmp
	]

	sbvf3: func [s [small! value] v [integer!] return: [small! value]][
		s/one: 9
		s/two: 10
		--assert v = 852
		--assert s/one = 9
		--assert s/two = 10
		s
	]

	sbvf4: func [s [small! value] v [integer!] return: [small! value] /local tmp [small! value]][
		--assert v = 123
		tmp/one: s/one + 1
		tmp/two: s/two + 1
		--assert (as int-ptr! :tmp) = :tmp/one
		tmp
	]

	sbvf5: func [s [big! value] v [integer!] return: [big! value]][
		s/one: 20
		s/two: 30
		s/three: 1.5
		--assert v = 963
		--assert s/one = 20
		--assert s/two = 30
		--assert s/three = 1.5
		s
	]

	sbvf6: func [s [big! value] v [integer!] return: [big! value] /local tmp [big! value]][
		--assert v = 123
		tmp/one: s/one
		tmp/two: s/two
		tmp/three: s/three
		--assert (as int-ptr! :tmp) = :tmp/one
		tmp
	]

	sbvf7: func [s [huge! value] v [integer!] return: [huge! value]][
		s/w1: 10
		s/w2: 20
		s/w3: 30.0
		s/w4: 40
		s/w5: 50
		s/w6: 60.0		
		--assert v = 159
		--assert s/w1 = 10
		--assert s/w2 = 20
		--assert s/w3 = 30.0
		--assert s/w4 = 40
		--assert s/w5 = 50
		--assert s/w6 = 60.0
		s
	]

	--test-- "svb1"
		sbvf1 s1 741
		--assert s1/b1 = #"A"

	--test-- "svb2"
		sv1: declare tiny!
		sv1: sbvf2 s1 123
		--assert sv1/b1 = #"A"

	--test-- "svb3"
		sbvf3 s2 852
		--assert s2/one = 4
		--assert s2/two = 5

	--test-- "svb4"
		sv2: declare small!
		sv2: sbvf4 s2 123
		--assert sv2/one = 5
		--assert sv2/two = 6

	--test-- "svb5"
		sbvf5 s3 963
		--assert s3/one = 123
		--assert s3/two = 456
		--assert s3/three = 3.14

	--test-- "svb6"
		sv3: declare big!
		sv3: sbvf6 s3 123
		--assert sv3/one = 123
		--assert sv3/two = 456
		--assert sv3/three = 3.14
		p-int: :sv3/two
		--assert p-int/value = 456
	
	--test-- "svb7"
		sbvf7 s4 159
		--assert s4/w1 = 1
		--assert s4/w2 = 2
		--assert s4/w3 = 3.0
		--assert s4/w4 = 4
		--assert s4/w5 = 5
		--assert s4/w6 = 6.0

	--test-- "svb8"
		n1!: alias struct! [g1 [integer!] s1 [tiny!] g2 [integer!]]
		n1: declare n1!
		n1/g1: 11111
		n1/g2: 22222
		n1/s1: declare tiny!

		n1/s1: sbvf2 s1 123
		--assert n1/s1/b1 = #"A"
		--assert n1/g1 = 11111
		--assert n1/g2 = 22222

	--test-- "svb9"
		n2!: alias struct! [g1 [integer!] s2 [small!] g2 [integer!]]
		n2: declare n2!
		n2/g1: 11111
		n2/g2: 22222
		n2/s2: declare small!

		n2/s2: sbvf3 s2 852
		--assert n2/s2/one = 9
		--assert n2/s2/two = 10
		--assert n1/g1 = 11111
		--assert n1/g2 = 22222

	--test-- "svb10"
		n3!: alias struct! [g1 [integer!] s3 [big!] g2 [integer!]]
		n3: declare n3!
		n3/g1: 11111
		n3/g2: 22222
		n3/s3: declare big!

		n3/s3: sbvf5 s3 963
		--assert n3/s3/one = 20
		--assert n3/s3/two = 30
		--assert n3/s3/three = 1.5
		--assert n1/g1 = 11111
		--assert n1/g2 = 22222

		--assert (as int-ptr! s3) <> :n3/s3
		p-int: :n3/s3/one
		--assert p-int/value = 20
		pf: as pointer! [float!] :n3/s3/three
		--assert pf/value = 1.5
		
	--test-- "svb11"
		sv1: returnTiny
		--assert sv1/b1 = #"z"
	
	--test-- "svb12"
		sv2: returnSmall
		--assert sv2/one = 111
		--assert sv2/two = 222
	
	--test-- "svb13"
		sv3: returnBig
		--assert sv3/one = 111
		--assert sv3/two = 222
		--assert sv3/three = 3.14159
	
	--test-- "svb14"
		sv4: declare huge!
		sv4: returnHuge as-integer #"0" as-integer #"1"
		--assert sv4/w1 = 48
		--assert sv4/w2 = 49
		--assert sv4/w3 = 3.5
		--assert sv4/w4 = 444
		--assert sv4/w5 = 555
		--assert sv4/w6 = 6.789
		
	--test-- "svb15"
		sv4: returnHuge2 sv4 as-integer #"0" as-integer #"1"
		--assert sv4/w1 = 48
		--assert sv4/w2 = 49
		--assert sv4/w3 = 3.5
		--assert sv4/w4 = 444
		--assert sv4/w5 = 555
		--assert sv4/w6 = 6.789
	
	--test-- "svb16"
		nest1: declare nested1!

		--assert 12 = size? nested1!

		nest1/f1: 121212
		nest1/f2: 343434
		nest1/sub/b1: #"B"

		--assert nest1/f1 = 121212
		--assert nest1/f2 = 343434
		--assert nest1/sub/b1 = #"B"
		
	--test-- "svb16.1"
		nest1/sub: sbvf2 nest1/sub 123
		--assert nest1/sub/b1 = #"B"
		
	--test-- "svb16.2"
		nest1/sub: sbvf2 s1 123
		--assert nest1/sub/b1 = #"A"
		
	--test-- "svb16.3"
		nest1/sub: returnTiny
		--assert nest1/sub/b1 = #"z"
		--assert nest1/f1 = 121212
		--assert nest1/f2 = 343434
		
	--test-- "svb17"
		nest2: declare nested2!

		--assert 16 = size? nested2!

		nest2/f1: 121212
		nest2/f2: 343434
		nest2/sub/one: 147
		nest2/sub/two: 258

		--assert nest2/f1 = 121212
		--assert nest2/f2 = 343434
		--assert nest2/sub/one = 147
		--assert nest2/sub/two = 258

	--test-- "svb17.1"
		nest2/sub: sbvf4 nest2/sub 123
		--assert nest2/sub/one = 148
		--assert nest2/sub/two = 259
		
	--test-- "svb17.2"
		nest2/sub: sbvf4 s2 123
		--assert nest2/sub/one = 5
		--assert nest2/sub/two = 6
		
	--test-- "svb17.3"
		nest2/sub: returnSmall
		--assert nest2/sub/one = 111
		--assert nest2/sub/two = 222
		--assert nest2/f1 = 121212
		--assert nest2/f2 = 343434
	
	--test-- "svb18"
		nest3: declare nested3!
		
		--assert 24 = size? nested3!
		
		nest3/f1: 121212
		nest3/f2: 343434
		nest3/sub/one: 666
		nest3/sub/two: 777
		nest3/sub/three: 8.88
				
		--assert nest3/f1 = 121212
		--assert nest3/f2 = 343434
		--assert nest3/sub/one = 666
		--assert nest3/sub/two = 777
		--assert nest3/sub/three = 8.88
		
		--assert (as int-ptr! nest3) + 1 = :nest3/sub
		--assert :nest3/sub     = :nest3/sub/one
		--assert :nest3/sub + 1 = :nest3/sub/two
		--assert :nest3/sub + 2 = :nest3/sub/three
		--assert :nest3/sub + 4 = :nest3/f2

	--test-- "svb18.1"
		nest3/sub: sbvf6 nest3/sub 123
		--assert nest3/sub/one = 666
		--assert nest3/sub/two = 777
		--assert nest3/sub/three = 8.88
		p-int: :nest3/sub/two
		--assert p-int/value = 777
		
	--test-- "svb18.2"
		nest3/sub: sbvf6 s3 123
		--assert nest3/sub/one = 123
		--assert nest3/sub/two = 456
		--assert nest3/sub/three = 3.14
		p-int: :nest3/sub/two
		--assert p-int/value = 456
		
	--test-- "svb18.3"
		nest3/sub: returnBig
		--assert nest3/sub/one = 111
		--assert nest3/sub/two = 222
		--assert nest3/sub/three = 3.14159
		--assert nest3/f1 = 121212
		--assert nest3/f2 = 343434

	--test-- "svb19"
		nest4: declare nested4!
		
		--assert 40 = size? nested4!
		
		nest4/g1: 121212
		nest4/g2: 343434
		nest4/sub/w1: 100
		nest4/sub/w2: 200
		nest4/sub/w3: 300.0
		nest4/sub/w4: 400
		nest4/sub/w5: 500
		nest4/sub/w6: 600.0		
				
		--assert nest4/g1 = 121212
		--assert nest4/g2 = 343434
		--assert nest4/sub/w1 = 100
		--assert nest4/sub/w2 = 200
		--assert nest4/sub/w3 = 300.0
		--assert nest4/sub/w4 = 400
		--assert nest4/sub/w5 = 500
		--assert nest4/sub/w6 = 600.0

		--assert (as int-ptr! nest4) + 1 = :nest4/sub
		--assert :nest4/sub     = :nest4/sub/w1
		--assert :nest4/sub + 1 = :nest4/sub/w2
		--assert :nest4/sub + 2 = :nest4/sub/w3
		--assert :nest4/sub + 4 = :nest4/sub/w4
		--assert :nest4/sub + 8 = :nest4/g2
		
	--test-- "svb19.1"
		nest4/sub: returnHuge as-integer #"0" as-integer #"1"
		--assert nest4/sub/w1 = 48
		--assert nest4/sub/w2 = 49
		--assert nest4/sub/w3 = 3.5
		--assert nest4/sub/w4 = 444
		--assert nest4/sub/w5 = 555
		--assert nest4/sub/w6 = 6.789
			
	--test-- "svb19.2"
		nest4/sub: returnHuge2 nest4/sub as-integer #"0" as-integer #"1"
		--assert nest4/sub/w1 = 48
		--assert nest4/sub/w2 = 49
		--assert nest4/sub/w3 = 3.5
		--assert nest4/sub/w4 = 444
		--assert nest4/sub/w5 = 555
		--assert nest4/sub/w6 = 6.789
		--assert nest4/g1 = 121212
		--assert nest4/g2 = 343434

	--test-- "svb20"
		nest5: declare nested5!
		
		--assert 56 = size? nested5!
		
		nest5/g1: 121212
		nest5/g2: 343434
		nest5/sub/f1: 1.0
		nest5/sub/f2: 2.0
		nest5/sub/f3: 3.0
		nest5/sub/f4: 4.0
		nest5/sub/f5: 5.0
		nest5/sub/f6: 6.0		
				
		--assert nest5/g1 = 121212
		--assert nest5/g2 = 343434
		--assert nest5/sub/f1 = 1.0
		--assert nest5/sub/f2 = 2.0
		--assert nest5/sub/f3 = 3.0
		--assert nest5/sub/f4 = 4.0
		--assert nest5/sub/f5 = 5.0
		--assert nest5/sub/f6 = 6.0

		--assert (as int-ptr! nest5) + 1 = :nest5/sub
		--assert :nest5/sub      = :nest5/sub/f1
		--assert :nest5/sub + 2  = :nest5/sub/f2
		--assert :nest5/sub + 4  = :nest5/sub/f3
		--assert :nest5/sub + 12 = :nest5/g2


	--test-- "svb50"
		localsbvf: func [
			/local 
				sv1   [tiny! value]
				sv2   [small! value]
				sv3   [big! value] 
				sv4   [huge! value]
				p-int [int-ptr!]
				n1 	  [n1!]
				n2	  [n2!]
				n3	  [n3!]
				pf	  [pointer! [float!]]
				nest1 [nested1! value]
				nest2 [nested2! value]
				nest3 [nested3! value]
				nest4 [nested4! value]
				nest5 [nested5! value]
				nest6 [nested1!]
				nest7 [nested2!]
				nest8 [nested3!]
		][
			--test-- "loc-svb1"
				sbvf1 s1 741
				--assert s1/b1 = #"A"

			--test-- "loc-svb2"
				sv1: declare tiny!
				sv1: sbvf2 s1 123
				--assert sv1/b1 = #"A"

			--test-- "loc-svb3"
				sbvf3 s2 852
				--assert s2/one = 4
				--assert s2/two = 5

			--test-- "loc-svb4"
				sv2: declare small!
				sv2: sbvf4 s2 123
				--assert sv2/one = 5
				--assert sv2/two = 6

			--test-- "loc-svb5"
				sbvf5 s3 963
				--assert s3/one = 123
				--assert s3/two = 456
				--assert s3/three = 3.14

			--test-- "loc-svb6"
				sv3: declare big!
				sv3: sbvf6 s3 123
				--assert sv3/one = 123
				--assert sv3/two = 456
				--assert sv3/three = 3.14
				p-int: :sv3/two
				--assert p-int/value = 456

			--test-- "loc-svb7"
				sbvf7 s4 159
				--assert s4/w1 = 1
				--assert s4/w2 = 2
				--assert s4/w3 = 3.0
				--assert s4/w4 = 4
				--assert s4/w5 = 5
				--assert s4/w6 = 6.0

			--test-- "loc-svb8"
				n1: declare n1!
				n1/g1: 11111
				n1/g2: 22222
				n1/s1: declare tiny!

				n1/s1: sbvf2 s1 123
				--assert n1/s1/b1 = #"A"
				--assert n1/g1 = 11111
				--assert n1/g2 = 22222

			--test-- "loc-svb9"
				n2: declare n2!
				n2/g1: 11111
				n2/g2: 22222
				n2/s2: declare small!

				n2/s2: sbvf3 s2 852
				--assert n2/s2/one = 9
				--assert n2/s2/two = 10
				--assert n1/g1 = 11111
				--assert n1/g2 = 22222

			--test-- "loc-svb10"
				n3: declare n3!
				n3/g1: 11111
				n3/g2: 22222
				n3/s3: declare big!

				n3/s3: sbvf5 s3 963
				--assert n3/s3/one = 20
				--assert n3/s3/two = 30
				--assert n3/s3/three = 1.5
				--assert n1/g1 = 11111
				--assert n1/g2 = 22222

				--assert (as int-ptr! s3) <> :n3/s3
				p-int: :n3/s3/one
				--assert p-int/value = 20
				pf: as pointer! [float!] :n3/s3/three
				--assert pf/value = 1.5
				
				
			--test-- "loc-svb11"
				sv1: returnTiny
				--assert sv1/b1 = #"z"

			--test-- "loc-svb12"
				sv2: returnSmall
				--assert sv2/one = 111
				--assert sv2/two = 222

			--test-- "loc-svb13"
				sv3: returnBig
				--assert sv3/one = 111
				--assert sv3/two = 222
				--assert sv3/three = 3.14159

			--test-- "loc-svb14"
				;sv4: declare huge!
				sv4: returnHuge as-integer #"0" as-integer #"1"
				--assert sv4/w1 = 48
				--assert sv4/w2 = 49
				--assert sv4/w3 = 3.5
				--assert sv4/w4 = 444
				--assert sv4/w5 = 555
				--assert sv4/w6 = 6.789

			--test-- "loc-svb15"
				sv4: returnHuge2 sv4 as-integer #"0" as-integer #"1"
				--assert sv4/w1 = 48
				--assert sv4/w2 = 49
				--assert sv4/w3 = 3.5
				--assert sv4/w4 = 444
				--assert sv4/w5 = 555
				--assert sv4/w6 = 6.789

			--test-- "loc-svb16"
				--assert 12 = size? nested1!

				nest1/f1: 121212
				nest1/f2: 343434
				nest1/sub/b1: #"B"

				--assert nest1/f1 = 121212
				--assert nest1/f2 = 343434
				--assert nest1/sub/b1 = #"B"

			--test-- "loc-svb16.1"
				nest1/sub: sbvf2 nest1/sub 123
				--assert nest1/sub/b1 = #"B"

			--test-- "loc-svb16.2"
				nest1/sub: sbvf2 s1 123
				--assert nest1/sub/b1 = #"A"

			--test-- "loc-svb16.3"
				nest1/sub: returnTiny
				--assert nest1/sub/b1 = #"z"
				--assert nest1/f1 = 121212
				--assert nest1/f2 = 343434

			--test-- "loc-svb17"
				--assert 16 = size? nested2!

				nest2/f1: 121212
				nest2/f2: 343434
				nest2/sub/one: 147
				nest2/sub/two: 258

				--assert nest2/f1 = 121212
				--assert nest2/f2 = 343434
				--assert nest2/sub/one = 147
				--assert nest2/sub/two = 258

			--test-- "loc-svb17.1"
				nest2/sub: sbvf4 nest2/sub 123
				--assert nest2/sub/one = 148
				--assert nest2/sub/two = 259

			--test-- "loc-svb17.2"
				nest2/sub: sbvf4 s2 123
				--assert nest2/sub/one = 5
				--assert nest2/sub/two = 6

			--test-- "loc-svb17.3"
				nest2/sub: returnSmall
				--assert nest2/sub/one = 111
				--assert nest2/sub/two = 222
				--assert nest2/f1 = 121212
				--assert nest2/f2 = 343434

			--test-- "loc-svb18"
				--assert 24 = size? nested3!

				nest3/f1: 121212
				nest3/f2: 343434
				nest3/sub/one: 666
				nest3/sub/two: 777
				nest3/sub/three: 8.88

				--assert nest3/f1 = 121212
				--assert nest3/f2 = 343434
				--assert nest3/sub/one = 666
				--assert nest3/sub/two = 777
				--assert nest3/sub/three = 8.88

				--assert (as int-ptr! nest3) + 1 = :nest3/sub
				--assert :nest3/sub     = :nest3/sub/one
				--assert :nest3/sub + 1 = :nest3/sub/two
				--assert :nest3/sub + 2 = :nest3/sub/three
				--assert :nest3/sub + 4 = :nest3/f2

			--test-- "loc-svb18.1"
				nest3/sub: sbvf6 nest3/sub 123
				--assert nest3/sub/one = 666
				--assert nest3/sub/two = 777
				--assert nest3/sub/three = 8.88
				p-int: :nest3/sub/two
				--assert p-int/value = 777

			--test-- "loc-svb18.2"
				nest3/sub: sbvf6 s3 123
				--assert nest3/sub/one = 123
				--assert nest3/sub/two = 456
				--assert nest3/sub/three = 3.14
				p-int: :nest3/sub/two
				--assert p-int/value = 456

			--test-- "loc-svb18.3"
				nest3/sub: returnBig
				--assert nest3/sub/one = 111
				--assert nest3/sub/two = 222
				--assert nest3/sub/three = 3.14159
				--assert nest3/f1 = 121212
				--assert nest3/f2 = 343434

			--test-- "loc-svb19"
				nest4: declare nested4!

				--assert 40 = size? nested4!

				nest4/g1: 121212
				nest4/g2: 343434
				nest4/sub/w1: 100
				nest4/sub/w2: 200
				nest4/sub/w3: 300.0
				nest4/sub/w4: 400
				nest4/sub/w5: 500
				nest4/sub/w6: 600.0		

				--assert nest4/g1 = 121212
				--assert nest4/g2 = 343434
				--assert nest4/sub/w1 = 100
				--assert nest4/sub/w2 = 200
				--assert nest4/sub/w3 = 300.0
				--assert nest4/sub/w4 = 400
				--assert nest4/sub/w5 = 500
				--assert nest4/sub/w6 = 600.0

				--assert (as int-ptr! nest4) + 1 = :nest4/sub
				--assert :nest4/sub     = :nest4/sub/w1
				--assert :nest4/sub + 1 = :nest4/sub/w2
				--assert :nest4/sub + 2 = :nest4/sub/w3
				--assert :nest4/sub + 4 = :nest4/sub/w4
				--assert :nest4/sub + 8 = :nest4/g2

			--test-- "loc-svb19.1"
				nest4/sub: returnHuge as-integer #"0" as-integer #"1"
				--assert nest4/sub/w1 = 48
				--assert nest4/sub/w2 = 49
				--assert nest4/sub/w3 = 3.5
				--assert nest4/sub/w4 = 444
				--assert nest4/sub/w5 = 555
				--assert nest4/sub/w6 = 6.789

			--test-- "loc-svb19.2"
				nest4/sub: returnHuge2 nest4/sub as-integer #"0" as-integer #"1"
				--assert nest4/sub/w1 = 48
				--assert nest4/sub/w2 = 49
				--assert nest4/sub/w3 = 3.5
				--assert nest4/sub/w4 = 444
				--assert nest4/sub/w5 = 555
				--assert nest4/sub/w6 = 6.789
				--assert nest4/g1 = 121212
				--assert nest4/g2 = 343434

			--test-- "loc-svb20"
				--assert 56 = size? nested5!

				nest5/g1: 121212
				nest5/g2: 343434
				nest5/sub/f1: 1.0
				nest5/sub/f2: 2.0
				nest5/sub/f3: 3.0
				nest5/sub/f4: 4.0
				nest5/sub/f5: 5.0
				nest5/sub/f6: 6.0		

				--assert nest5/g1 = 121212
				--assert nest5/g2 = 343434
				--assert nest5/sub/f1 = 1.0
				--assert nest5/sub/f2 = 2.0
				--assert nest5/sub/f3 = 3.0
				--assert nest5/sub/f4 = 4.0
				--assert nest5/sub/f5 = 5.0
				--assert nest5/sub/f6 = 6.0

				--assert (as int-ptr! nest5) + 1 = :nest5/sub
				--assert :nest5/sub      = :nest5/sub/f1
				--assert :nest5/sub + 2  = :nest5/sub/f2
				--assert :nest5/sub + 4  = :nest5/sub/f3
				--assert :nest5/sub + 12 = :nest5/g2
				
			--test-- "svb30"
				nest1: declare nested1!

				--assert 12 = size? nested1!

				nest1/f1: 121212
				nest1/f2: 343434
				nest1/sub/b1: #"B"

				--assert nest1/f1 = 121212
				--assert nest1/f2 = 343434
				--assert nest1/sub/b1 = #"B"

			--test-- "svb30.1"
				nest1/sub: sbvf2 nest1/sub 123
				--assert nest1/sub/b1 = #"B"

			--test-- "svb30.2"
				nest1/sub: sbvf2 s1 123
				--assert nest1/sub/b1 = #"A"

			--test-- "svb30.3"
				nest1/sub: returnTiny
				--assert nest1/sub/b1 = #"z"
				--assert nest1/f1 = 121212
				--assert nest1/f2 = 343434

			--test-- "svb31"
				nest2: declare nested2!

				--assert 16 = size? nested2!

				nest2/f1: 121212
				nest2/f2: 343434
				nest2/sub/one: 147
				nest2/sub/two: 258

				--assert nest2/f1 = 121212
				--assert nest2/f2 = 343434
				--assert nest2/sub/one = 147
				--assert nest2/sub/two = 258

			--test-- "svb31.1"
				nest2/sub: sbvf4 nest2/sub 123
				--assert nest2/sub/one = 148
				--assert nest2/sub/two = 259

			--test-- "svb31.2"
				nest2/sub: sbvf4 s2 123
				--assert nest2/sub/one = 5
				--assert nest2/sub/two = 6

			--test-- "svb31.3"
				nest2/sub: returnSmall
				--assert nest2/sub/one = 111
				--assert nest2/sub/two = 222
				--assert nest2/f1 = 121212
				--assert nest2/f2 = 343434

			--test-- "svb32"
				nest3: declare nested3!

				--assert 24 = size? nested3!

				nest3/f1: 121212
				nest3/f2: 343434
				nest3/sub/one: 666
				nest3/sub/two: 777
				nest3/sub/three: 8.88

				--assert nest3/f1 = 121212
				--assert nest3/f2 = 343434
				--assert nest3/sub/one = 666
				--assert nest3/sub/two = 777
				--assert nest3/sub/three = 8.88

				--assert (as int-ptr! nest3) + 1 = :nest3/sub
				--assert :nest3/sub     = :nest3/sub/one
				--assert :nest3/sub + 1 = :nest3/sub/two
				--assert :nest3/sub + 2 = :nest3/sub/three
				--assert :nest3/sub + 4 = :nest3/f2

			--test-- "svb32.1"
				nest3/sub: sbvf6 nest3/sub 123
				--assert nest3/sub/one = 666
				--assert nest3/sub/two = 777
				--assert nest3/sub/three = 8.88
				p-int: :nest3/sub/two
				--assert p-int/value = 777

			--test-- "svb32.2"
				nest3/sub: sbvf6 s3 123
				--assert nest3/sub/one = 123
				--assert nest3/sub/two = 456
				--assert nest3/sub/three = 3.14
				p-int: :nest3/sub/two
				--assert p-int/value = 456

			--test-- "svb32.3"
				nest3/sub: returnBig
				--assert nest3/sub/one = 111
				--assert nest3/sub/two = 222
				--assert nest3/sub/three = 3.14159
				--assert nest3/f1 = 121212
				--assert nest3/f2 = 343434

		]
		localsbvf

===end-group===

~~~end-file~~~