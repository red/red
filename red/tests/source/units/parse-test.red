Red [
	Title:   "Red PARSE test script"
	Author:  "Nenad Rakocevic"
	File: 	 %parse-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

~~~start-file~~~ "parse"

===start-group=== "Block"

	--test-- "blk-1" 	--assert parse 		[]			[]
	--test-- "blk-2" 	--assert parse 		[a]			['a]
	--test-- "blk-3" 	--assert not parse 	[a]			['b]
	--test-- "blk-4" 	--assert parse 		[a b]		['a 'b]
	--test-- "blk-5" 	--assert parse 		[a #"b"]	['a #"b"]
	--test-- "blk-6" 	--assert parse 		[a]			[['a]]
	--test-- "blk-7" 	--assert parse 		[a b]		[['a] 'b]
	--test-- "blk-8" 	--assert parse 		[a b]		['a ['b]]
	--test-- "blk-9" 	--assert parse 		[a b]		[['a]['b]]
	--test-- "blk-10"	--assert parse 		["hello"]	["hello"]

	--test-- "blk-11"	--assert parse 		[#"a"] 		[#"b" | #"a"]
	--test-- "blk-12"	--assert not parse 	[a b]		['b | 'a]
	--test-- "blk-13"	--assert parse 		[#"a"]		[[#"b" | #"a"]]
	--test-- "blk-14"	--assert not parse 	[a b]		[['b | 'a]]
	--test-- "blk-15"	--assert parse 		[a b]		[['a | 'b]['b | 'a]]
	
	--test-- "blk-16"	--assert parse		[a 123]		['a integer!]
	--test-- "blk-17"	--assert not parse	[a 123]		['a char!]
	--test-- "blk-18"	--assert parse		[a 123]		[['a][integer!]]
	--test-- "blk-19"	--assert not parse	[a 123]		['a [char!]]
	
	--test-- "blk-20"
		res: 0	
	--assert parse [] [(res: 1)]
	--assert res = 1
		
	--test-- "blk-21"
		res: 0	
		--assert parse [a] ['a (res: 1)]
		--assert res = 1
		
	--test-- "blk-22"
		res: 0	
		--assert not parse [a] ['b (res: 1)]
		--assert res = 0
		
	--test-- "blk-23"
		res: 0	
		--assert parse [] [[(res: 1)]]
		--assert res = 1

	--test-- "blk-24"
		res: 0	
		--assert parse [a] [['a (res: 1)]]
		--assert res = 1

	--test-- "blk-25"
		res: 0	
		--assert not parse [a] [['b (res: 1)]]
		--assert res = 0
		
	--test-- "blk-26"
		res: 0	
		--assert parse [a 123] ['a (res: 1) [char! (res: 2) | integer! (res: 3)]]
		--assert res = 3
		
	--test-- "blk-27"
		res: 0	
		--assert not parse [a 123] ['a (res: 1) [char! (res: 2) | string! (res: 3)]]
		--assert res = 1

	--test-- "blk-28"	--assert not parse		[a a]		[1 ['a]]
   	--test-- "blk-29"	--assert parse			[a a]		[2 ['a]]
   	--test-- "blk-30"	--assert not parse		[a a]		[3 ['a]]
   	--test-- "blk-31"	--assert not parse		[a a]		[1 1 ['a]]
   	--test-- "blk-32"	--assert parse			[a a]		[1 2 ['a]]
   	--test-- "blk-33"	--assert parse			[a a]		[2 2 ['a]]
   	--test-- "blk-34"	--assert parse			[a a]		[2 3 ['a]]
   	--test-- "blk-35"	--assert not parse		[a a]		[3 4 ['a]]
   	
	--test-- "blk-36"	--assert not parse		[a a]		[1 'a]
	--test-- "blk-37"	--assert parse			[a a]		[2 'a]
	--test-- "blk-38"	--assert not parse		[a a]		[3 'a]
	--test-- "blk-39"	--assert not parse		[a a]		[1 1 'a]
	--test-- "blk-40"	--assert parse			[a a]		[1 2 'a]
	--test-- "blk-41"	--assert parse			[a a]		[2 2 'a]
	--test-- "blk-42"	--assert parse			[a a]		[2 3 'a]
   	--test-- "blk-43"	--assert not parse		[a a]		[3 4 'a]
   
    --test-- "blk-44"	--assert parse			[a]			[skip]
    --test-- "blk-45"	--assert parse			[a b]		[skip skip]
    --test-- "blk-46"	--assert parse			[a b]		[skip [skip]]
    --test-- "blk-47"	--assert parse			[a b]		[[skip] [skip]]
   
   	--test-- "blk-48"	--assert parse			[a a]		[some ['a]]
   	--test-- "blk-49"	--assert not parse		[a a]		[some ['a] 'b]
   	
   	--test-- "blk-50"	--assert parse			[a a b a b b b a]	[some [skip]]
   	--test-- "blk-51"	--assert parse			[a a b a b b b a]	[some ['a | 'b]]
   	--test-- "blk-52"	--assert not parse 		[a a b a b b b a]	[some ['a | 'c]]
   
	--test-- "blk-53"	--assert parse 			[a a]		[any ['a]]
	--test-- "blk-54"	--assert parse			[a a]		[some ['a] any ['b]]
	--test-- "blk-55"	--assert parse			[a a b b]	[2 'a 2 'b]
	--test-- "blk-56"	--assert not parse		[a a b b]	[2 'a 3 'b]
	--test-- "blk-57"	--assert parse			[a a b b]	[some 'a some 'b]
   	--test-- "blk-58"	--assert not parse		[a a b b]	[some 'a some 'c]

	--test-- "blk-59"
		p: none
		--assert parse [] [p:]
		--assert tail? p
	
	--test-- "blk-60"
		p: none
		--assert parse [] [[[p:]]]
		--assert tail? p

		
	--test-- "blk-61"
		p: none
		--assert parse [a] [p: 'a]
		--assert p = [a]
		
	--test-- "blk-62"
		p: none
		--assert parse [a] ['a p:]
		--assert tail? p
		
	--test-- "blk-63"
		p: none
		--assert parse [a] ['a [p:]]
		--assert tail? p
		
	--test-- "blk-64"
		p: none
		--assert not parse [a b] ['a p:]
		--assert p = [b]
	
	--test-- "blk-65"
		p: none
		--assert parse [a b] ['a [p:]['b | 'c]]
		--assert p = [b]
		
	--test-- "blk-66"
		p: none
		--assert parse [a a a b b] [3 'a p: 2 'b :p [2 'b]]
		--assert p = [b b]
	
===end-group===

===start-group=== "block-end"

	--test-- "blk-end-1" --assert parse 		[a] 	['a end]
	--test-- "blk-end-2" --assert not parse 	[a b] 	['a end]
	--test-- "blk-end-3" --assert parse 		[a] 	[skip end]
	--test-- "blk-end-4" --assert not parse 	[a b]	[skip end]
	--test-- "blk-end-5" --assert parse 		[]		[end]
	
	--test-- "blk-end-6"
		be6: 0
		--assert parse [] [end (be6: 1)]
		--assert be6 = 1		

===end-group===

===start-group=== "String"

	--test-- "str-1" 	--assert parse		""			[]
	--test-- "str-2" 	--assert parse		"a"			[#"a"]
	--test-- "str-3" 	--assert parse		"a"			["a"]
	--test-- "str-4" 	--assert not parse	"a"			[#"b"]
	--test-- "str-5" 	--assert parse		"ab"		[#"a" #"b"]
	--test-- "str-6" 	--assert parse		"ab"		["ab"]
	--test-- "str-7" 	--assert parse		"a"			[[#"a"]]
	--test-- "str-8" 	--assert parse		"ab"		[[#"a"] "b"]
	--test-- "str-9" 	--assert parse		"ab"		[#"a" [#"b"]]
	--test-- "str-10" 	--assert parse		"ab"		[[#"a"][#"b"]]

	--test-- "str-11"	--assert parse		"a"			[#"b" | #"a"]
	--test-- "str-12"	--assert not parse	"ab"		[#"b" | "a"]
	--test-- "str-13"	--assert parse		"a"			[[#"b" | #"a"]]
	--test-- "str-14"	--assert not parse	"ab"		[[#"b" | "a"]]
	--test-- "str-15"	--assert parse		"ab"		[["a" | #"b"][#"b" | "a"]]
	
	;--test-- "str-16"	--assert parse		"123"		[integer!]
	
	
	--test-- "str-20"
		res: 0	
		--assert parse "" [(res: 1)]
		--assert res = 1
		
	--test-- "str-21"
		res: 0	
		--assert parse "a" [#"a" (res: 1)]
		--assert res = 1
		
	--test-- "str-22"
		res: 0	
		--assert not parse "a" [#"b" (res: 1)]
		--assert res = 0
		
	--test-- "str-23"
		res: 0	
		--assert parse "" [[(res: 1)]]
		--assert res = 1

	--test-- "str-24"
		res: 0	
		--assert parse "a" [[#"a" (res: 1)]]
		--assert res = 1

	--test-- "str-25"
		res: 0	
		--assert not parse "a" [[#"b" (res: 1)]]
		--assert res = 0
		
	--test-- "str-26"
		res: 0	
		--assert parse "ab" [#"a" (res: 1) [#"c" (res: 2) | #"b" (res: 3)]]
		--assert res = 3
		
	--test-- "str-27"
		res: 0	
		--assert not parse "ab" [#"a" (res: 1) [#"c" (res: 2) | #"d" (res: 3)]]
		--assert res = 1

	--test-- "str-28"	--assert not parse		"aa"		[1 [#"a"]]
   	--test-- "str-29"	--assert parse			"aa"		[2 [#"a"]]
   	--test-- "str-30"	--assert not parse		"aa"		[3 [#"a"]]
   	--test-- "str-31"	--assert not parse		"aa"		[1 1 [#"a"]]
   	--test-- "str-32"	--assert parse			"aa"		[1 2 [#"a"]]
   	--test-- "str-33"	--assert parse			"aa"		[2 2 [#"a"]]
   	--test-- "str-34"	--assert parse			"aa"		[2 3 [#"a"]]
   	--test-- "str-35"	--assert not parse		"aa"		[3 4 [#"a"]]
   
   	--test-- "str-36"	--assert not parse		"aa"		[1 #"a"]
	--test-- "str-37"	--assert parse			"aa"		[2 #"a"]
	--test-- "str-38"	--assert not parse		"aa"		[3 #"a"]
	--test-- "str-39"	--assert not parse		"aa"		[1 1 #"a"]
	--test-- "str-40"	--assert parse			"aa"		[1 2 #"a"]
	--test-- "str-41"	--assert parse			"aa"		[2 2 #"a"]
	--test-- "str-42"	--assert parse			"aa"		[2 3 #"a"]
	--test-- "str-43"	--assert not parse		"aa"		[3 4 #"a"]

   
    --test-- "str-44"	--assert parse			"a"			[skip]
    --test-- "str-45"	--assert parse			"ab"		[skip skip]
    --test-- "str-46"	--assert parse			"ab"		[skip [skip]]
    --test-- "str-47"	--assert parse			"ab"		[[skip] [skip]]
   
   	--test-- "str-48"	--assert parse			"aa"		[some [#"a"]]
   	--test-- "str-49"	--assert not parse		"aa"		[some [#"a"] #"b"]
   	
   	--test-- "str-50"	--assert parse			"aababbba"	[some [skip]]
   	--test-- "str-51"	--assert parse			"aababbba"	[some ["a" | "b"]]
   	--test-- "str-52"	--assert not parse 		"aababbba"	[some ["a" | #"c"]]
   
	--test-- "str-53"	--assert parse 			"aa"		[any [#"a"]]
	--test-- "str-54"	--assert parse			"aa"		[some [#"a"] any [#"b"]]
	--test-- "str-55"	--assert parse			"aabb"		[2 #"a" 2 "b"]
	--test-- "str-56"	--assert not parse		"aabb"		[2 "a" 3 #"b"]
	--test-- "str-57"	--assert parse			"aabb"		[some #"a" some "b"]
   	--test-- "str-58"	--assert not parse		"aabb"		[some "a" some #"c"]

	--test-- "str-59"
		p: none
		--assert parse "" [p:]
		--assert tail? p
	
	--test-- "str-60"
		p: none
		--assert parse "" [[[p:]]]
		--assert tail? p

		
	--test-- "str-61"
		p: none
		--assert parse "a" [p: #"a"]
		--assert p = "a"
		
	--test-- "str-62"
		p: none
		--assert parse "a" [#"a" p:]
		--assert tail? p
		
	--test-- "str-63"
		p: none
		--assert parse "a" [#"a" [p:]]
		--assert tail? p
		
	--test-- "str-64"
		p: none
		--assert not parse "ab" [#"a" p:]
		--assert p = "b"
	
	--test-- "str-65"
		p: none
		--assert parse "ab" [#"a" [p:][#"b" | #"c"]]
		--assert p = "b"
		
	--test-- "str-66"
		p: none
		--assert parse "aaabb" [3 #"a" p: 2 #"b" :p [2 "b"]]
		--assert p = "bb"
	
===end-group===

===start-group=== "string-end"

	--test-- "str-end-1" --assert parse 		"a" 	[#"a" end]
	--test-- "str-end-2" --assert not parse 	"ab" 	[#"a" end]
	--test-- "str-end-3" --assert parse 		"a" 	[skip end]
	--test-- "str-end-4" --assert not parse 	"ab"	[skip end]
	--test-- "str-end-5" --assert parse 		""		[end]
	
	--test-- "str-end-6"
		be6: 0
		--assert parse "" [end (be6: 1)]
		--assert be6 = 1

===end-group===
    
~~~end-file~~~

