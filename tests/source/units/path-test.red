Red [
	Title:   "Red/System path! datatype test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %char-test.red
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "path"

===start-group=== "block access"
	blk: [a b c [d] e]
	
	--test-- "blk-1"
		--assert blk/1 = 'a
		--assert blk/2 = 'b
		--assert blk/3 = 'c
		--assert blk/4 = [d]
		--assert blk/4/1 = 'd
	
	--test-- "blk-2"
		blk/1: 99
		--assert blk/1 = 99
		blk/2: 'z
		--assert blk/2 = 'z
		blk/4/1: -1
		--assert blk/4 = [-1]
		--assert blk = [99 z c [-1] e]

	--test-- "blk-3"
		idx: 1
		--assert blk/:idx = 99
		--assert blk/4/:idx = -1
		idx: 4
		--assert blk/:idx/1 = -1
		idx: 1
		blk/:idx: 0
		--assert blk/:idx = 0
		--assert blk/1 = 0

	--test-- "blk-4"
	idx: 'z
	--assert blk/:idx = 'c

	--test-- "blk-5"
	--assert blk/z = 'c

	--test-- "blk-6"
		blk: [4 5 6 ["o"]]
		idx: 2
		--assert blk/(1) = 4
		--assert blk/(1 + 2) = 6
		--assert blk/(idx) = 5
    	
		--test-- "blk-7"
		--assert blk/(idx + 2)/(1) = "o"
		--assert blk/(idx + 2)/(1)/(idx - 1) = #"o"

	--test-- "blk-8"
		blk/(1): 99
		idx: 2
		--assert blk/1 = 99
		blk/(idx + 2)/(1)/(idx - 1): #"z"	
		--assert blk/4/1/1 = #"z"
    	
		--test-- "blk-9"
		inc: func [a][a + 1]
		--assert blk/(inc 1) = 5

===end-group===

===start-group=== "string access"
	str: "abcde"
	
	--test-- "str-1"
		--assert str/1 = #"a"
		--assert str/2 = #"b"
		--assert str/3 = #"c"
		--assert str/4 = #"d"
	
	--test-- "str-2"
		str/1: #"9"
		--assert str/1 = #"9"
		str/2: #"z"
		--assert str/2 = #"z"
		--assert str = "9zcde"

	--test-- "str-3"
		idx: 1
		--assert str/:idx = #"9"
		idx: 4
		--assert str/:idx = #"d"
		idx: 1
		str/:idx: #"0"
		--assert str/:idx = #"0"
		--assert str/1 = #"0"

	--test-- "str-4"
		str: "456o"
		idx: 2
		--assert str/(1) = #"4"
		--assert str/(1 + 2) = #"6"
		--assert str/(idx) = #"5"

	--test-- "str-5"
		str/(1): #"9"
		--assert str/1 = #"9"
		idx: 2
		str/(idx + 2): #"z"	
		--assert str/4 = #"z"

	--test-- "str-6"
		inc: func [a][a + 1]
		--assert str/(inc 1) = #"5"
	
	--test-- "str-7 - issue #1113"
		s7-a: "abcz"
		s7-b: 5
		--assert none = s7-a/5
		--assert none = s7-a/:s7-b

===end-group===


===start-group=== "issues"

	--test-- "issue #1993"
		s: object [v: object [a: none]]
		live?: s/v/a: no
		--assert live? == false
		--assert s/v/a == false

		do [
			range: [0 0]
			a: range/2: 1
			--assert range = [0 1]
			--assert a = 1
		]

	--test-- "issue #2525"
		
		u: %a/b
		--assert %a/b/1 = u/1
		--assert %a/b/c/1 = u/c/1

		u: %a/b
		--assert %a/b/c/d = u/c/d
		--assert error? try [u/c/d: 123]

		face2525: object [size: 80x24]
		min-size: 345x50
		--assert min-size/x + 10 = 355
		face2525/size/y: min-size/y + 10
		--assert face2525/size/y = 60


===end-group===

~~~end-file~~~
