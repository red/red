Red/System [
	Title:   "Red/System struct! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %struct-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

~~~start-file~~~ "struct!"

===start-group=== "Struct members simple read/write tests"

	--test-- "s-rw-1"
	struct1: struct [b [integer!]]
	struct1/b: 12345
	--assert struct1/b = 12345
	
	--test-- "s-rw-2"
	struct2: struct [b [byte!] c [c-string!] d [integer!]]
	struct2/c: "a"
	struct2/d: 9876
	struct2/b: #"R"				;-- intentionnaly put there to test not overlapping memory storage
	--assert struct2/b   = #"R"
	
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
	struct3: struct [
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
	struct3/sub: struct [
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
	struct1: struct [b [integer!]]
	struct1/b: 12345
	--assert struct1/b = 12345

	--test-- "ls-rw-2"
	struct2: struct [b [byte!] c [c-string!] d [integer!]]
	struct2/c: "a"
	struct2/d: 9876
	struct2/b: #"R"				;-- intentionnaly put there to test not overlapping memory storage
	--assert struct2/b   = #"R"
	
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
	struct2-foo-int:  func [a [integer!] return: [integer!]][a]
	struct2-foo-byte: func [a [byte!] return: [byte!]][a]
	--assert 9876 = struct2-foo-int struct2/d

	--test-- "ls-rw-11"
	--assert #"R" = struct2-foo-byte struct2/b
	
	--test-- "ls-nested-1"
	struct3: struct [
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
	struct3/sub: struct [
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

~~~end-file~~~