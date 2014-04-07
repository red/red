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
do [								;-- temp until object! support in compiler
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

~~~end-file~~~

]								;-- temp until object! support in compiler
