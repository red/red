Red/System [
	Title:   "Red/System struct! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %struct-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
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


~~~end-file~~~