Red [
	Title:	"Red PARSE test script"
	Author:	"Nenad Rakocevic"
	File:	%parse-test.reds
	Tabs:	4
	Rights:	"Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

~~~start-file~~~ "parse"

===start-group=== "block"

	--test-- "blk-1" 	--assert parse 		[]			[]
	--test-- "blk-2" 	--assert parse 		[a]			['a]
	--test-- "blk-3" 	--assert not parse	[a]			['b]
	--test-- "blk-4" 	--assert parse 		[a b]		['a 'b]
	--test-- "blk-5" 	--assert parse 		[a #"b"]	['a #"b"]
	--test-- "blk-6" 	--assert parse 		[a]			[['a]]
	--test-- "blk-7" 	--assert parse 		[a b]		[['a] 'b]
	--test-- "blk-8" 	--assert parse 		[a b]		['a ['b]]
	--test-- "blk-9" 	--assert parse 		[a b]		[['a]['b]]
	--test-- "blk-10"	--assert parse 		["hello"]	["hello"]

	--test-- "blk-11"	--assert parse 		[#"a"] 		[#"b" | #"a"]
	--test-- "blk-12"	--assert not parse	[a b]		['b | 'a]
	--test-- "blk-13"	--assert parse 		[#"a"]		[[#"b" | #"a"]]
	--test-- "blk-14"	--assert not parse	[a b]		[['b | 'a]]
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
	
	--test-- "blk-44"	--assert not parse		[a a]		[1 skip]
	--test-- "blk-45"	--assert parse			[a a]		[2 skip]
	--test-- "blk-46"	--assert not parse		[a a]		[3 skip]
	--test-- "blk-47"	--assert not parse		[a a]		[1 1 skip]
	--test-- "blk-48"	--assert parse			[a a]		[1 2 skip]
	--test-- "blk-49"	--assert parse			[a a]		[2 2 skip]
	--test-- "blk-50"	--assert parse			[a a]		[2 3 skip]
	--test-- "blk-51"	--assert not parse		[a a]		[3 4 skip]
   
	--test-- "blk-52"	--assert parse			[a]			[skip]
	--test-- "blk-53"	--assert parse			[a b]		[skip skip]
	--test-- "blk-54"	--assert parse			[a b]		[skip [skip]]
	--test-- "blk-55"	--assert parse			[a b]		[[skip] [skip]]
   
	--test-- "blk-56"	--assert parse			[a a]		[some ['a]]
	--test-- "blk-57"	--assert not parse		[a a]		[some ['a] 'b]
   	
	--test-- "blk-58"	--assert parse			[a a b a b b b a]	[some [skip]]
	--test-- "blk-59"	--assert parse			[a a b a b b b a]	[some ['a | 'b]]
	--test-- "blk-60"	--assert not parse 		[a a b a b b b a]	[some ['a | 'c]]
   
	--test-- "blk-61"	--assert parse 			[a a]		[any ['a]]
	--test-- "blk-62"	--assert parse			[a a]		[some ['a] any ['b]]
	--test-- "blk-63"	--assert parse			[a a b b]	[2 'a 2 'b]
	--test-- "blk-64"	--assert not parse		[a a b b]	[2 'a 3 'b]
	--test-- "blk-65"	--assert parse			[a a b b]	[some 'a some 'b]
	--test-- "blk-66"	--assert not parse		[a a b b]	[some 'a some 'c]

	--test-- "blk-67"
		p: none
		--assert parse [] [p:]
		--assert tail? p
	
	--test-- "blk-68"
		p: none
		--assert parse [] [[[p:]]]
		--assert tail? p

		
	--test-- "blk-69"
		p: none
		--assert parse [a] [p: 'a]
		--assert p = [a]
		
	--test-- "blk-70"
		p: none
		--assert parse [a] ['a p:]
		--assert tail? p
		
	--test-- "blk-71"
		p: none
		--assert parse [a] ['a [p:]]
		--assert tail? p
		
	--test-- "blk-72"
		p: none
		--assert not parse [a b] ['a p:]
		--assert p = [b]
	
	--test-- "blk-72"
		p: none
		--assert parse [a b] ['a [p:]['b | 'c]]
		--assert p = [b]
		
	--test-- "blk-73"
		p: none
		--assert parse [a a a b b] [3 'a p: 2 'b :p [2 'b]]
		--assert p = [b b]
		
	--test-- "blk-74"
	--assert parse [b a a a c][skip some ['a] 'c]
	
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

===start-group=== "block-words"
	
	wa: ['a]
	wb: ['b]
	wca: #"a"
	wcb: #"b"
	wra: [wa]
	wrb: [wb]
	wh: "hello"
	wrab: ['a | 'b]
	wrba: ['b | 'a]
	
	--test-- "blk-w1" 	--assert parse 		[a]			[wa]
	--test-- "blk-w2" 	--assert not parse 	[a]			[wb]
	--test-- "blk-w3" 	--assert parse 		[a b]		[wa wb]
	--test-- "blk-w4" 	--assert parse 		[a #"b"]	[wa wcb]
	--test-- "blk-w5" 	--assert parse 		[a]			[wra]
	--test-- "blk-w6" 	--assert parse 		[a b]		[wra 'b]
	--test-- "blk-w7" 	--assert parse 		[a b]		['a wrb]
	--test-- "blk-w8" 	--assert parse 		[a b]		[wra wrb]
	--test-- "blk-w9" 	--assert parse 		["hello"]	[wh]

	--test-- "blk-w10"	--assert parse 		[#"a"] 		[wcb | wca]
	--test-- "blk-w11"	--assert not parse 	[a b]		[wb | wa]
	--test-- "blk-w12"	--assert parse 		[#"a"]		[[wcb | wca]]
	--test-- "blk-w13"	--assert not parse 	[a b]		[wrba]
	--test-- "blk-w14"	--assert parse 		[a b]		[wrab wrba]
	
	--test-- "blk-w15"	--assert parse		[a 123]		[wa integer!]
	--test-- "blk-w16"	--assert not parse	[a 123]		[wa char!]
	--test-- "blk-w17"	--assert parse		[a 123]		[wra [integer!]]
	--test-- "blk-w18"	--assert not parse	[a 123]		[wa  [char!]]

	--test-- "blk-w19"
		res: 0	
		--assert parse [a] [wa (res: 1)]
		--assert res = 1
		
	--test-- "blk-w20"
		res: 0	
		--assert not parse [a] [wb (res: 1)]
		--assert res = 0
		
	--test-- "blk-w21"
		res: 0	
		wres: [(res: 1)]
		--assert parse [] [wres]
		--assert res = 1

	--test-- "blk-w22"
		res: 0
		wres: ['a (res: 1)]
		--assert parse [a] [wres]
		--assert res = 1

	--test-- "blk-w23"
		res: 0
		wres: ['b (res: 1)]
		--assert not parse [a] [wres]
		--assert res = 0
		
	--test-- "blk-w24"
		res: 0
		wres: [char! (res: 2) | integer! (res: 3)]
		--assert parse [a 123] [wa (res: 1) wres]
		--assert res = 3
		
	--test-- "blk-w25"
		res: 0
		wres: [char! (res: 2) | string! (res: 3)]
		--assert not parse [a 123] [wa (res: 1) wres]
		--assert res = 1

===end-group===

===start-group=== "block-extraction"

	wa: ['a]
	--test-- "blk-ext1" 
		res: 0
		--assert parse [a][copy res skip]
		--assert res = [a]
	
	--test-- "blk-ext2" 
		res: 0
		--assert parse [a][copy res 'a]
		--assert res = [a]
	
	--test-- "blk-ext3" 
		res: 0
		--assert parse [a][copy res word!]
		--assert res = [a]
		
	--test-- "blk-ext4" 
		res:  0
		res2: 0
		--assert parse [a][copy res copy res2 'a]
		--assert res  = [a]
		--assert res2 = [a]
		
	--test-- "blk-ext5" 
		res: 0
		--assert parse [a a][copy res 2 'a]				;@@ a instead of 'a will crash!
		--assert res = [a a]

	--test-- "blk-ext6" 
		res: 0
		--assert not parse [a a][copy res 3 'a]
		--assert res = 0
		
	--test-- "blk-ext7" 
		res: 0
		--assert parse [a][copy res ['a]]
		--assert res = [a]

	--test-- "blk-ext8" 
		res: 0
		--assert parse [a][copy res wa]
		--assert res = [a]
	
	--test-- "blk-ext9" 
		res: 0
		--assert parse [a a][copy res 2 wa]
		--assert res = [a a]
	
	--test-- "blk-ext10" 
		res: 0
		--assert parse [a a b][skip copy res 'a skip]
		--assert res = [a]
 
	--test-- "blk-ext11" 
		res: 0
		--assert parse [a a b][skip copy res ['a | 'b] skip]
		--assert res = [a]
		
	--test-- "blk-ext12" 
		res: 0
		--assert not parse [a][copy res ['c | 'b]]
		--assert res = 0
		
	--test-- "blk-ext13" 
		res: 0
		--assert parse [a][set res skip]
		--assert res = 'a

	--test-- "blk-ext14" 
		res: 0
		--assert parse [a][set res 'a]
		--assert res = 'a

	--test-- "blk-ext15" 
		res: 0
		--assert parse [a][set res word!]
		--assert res = 'a
		
	--test-- "blk-ext16" 
		res:  0
		res2: 0
		--assert parse [a][set res set res2 'a]
		--assert res  = 'a
		--assert res2 = 'a

	--test-- "blk-ext17" 
		res: 0
		--assert parse [a a][set res 2 'a]				;@@ a instead of 'a will crash!
		--assert res = 'a

	--test-- "blk-ext18" 
		res: 0
		--assert not parse [a a][set res 3 'a]
		--assert res = 0

	--test-- "blk-ext19" 
		res: 0
		--assert parse [a][set res ['a]]
		--assert res = 'a

	--test-- "blk-ext20" 
		res: 0
		--assert parse [a][set res wa]
		--assert res = 'a

	--test-- "blk-ext21" 
		res: 0
		--assert parse [a a][set res 2 wa]
		--assert res = 'a

	--test-- "blk-ext22" 
		res: 0
		--assert parse [a a b][skip set res 'a skip]
		--assert res = 'a

	--test-- "blk-ext23" 
		res: 0
		--assert parse [a a b][skip set res ['a | 'b] skip]
		--assert res = 'a

	--test-- "blk-ext24" 
		res: 0
		--assert not parse [a][set res ['c | 'b]]
		--assert res = 0
		
	--test-- "blk-ext25" 
		res: 0
		--assert parse [b a a a c][skip set res some 'a 'c]
		--assert res = 'a

	--test-- "blk-ext26" 
		res: 0
		--assert parse [b a a a c][skip set res some wa 'c]
		--assert res = 'a
		
===end-group===

===start-group=== "block-skipping"

	wa: ['a]
	
	--test-- "blk-sk1" 	--assert parse		[]			[to end]
	--test-- "blk-sk2" 	--assert parse		[]			[thru end]
	--test-- "blk-sk3" 	--assert parse		[a]			[to end]
	--test-- "blk-sk4" 	--assert not parse	[a]			[to 'a]
	--test-- "blk-sk5" 	--assert not parse	[a]			[to 'a end]
	--test-- "blk-sk6" 	--assert parse		[a]			[to 'a skip]
	--test-- "blk-sk7" 	--assert parse		[a]			[thru 'a]
	--test-- "blk-sk8" 	--assert parse		[a]			[thru 'a end]
	--test-- "blk-sk9" 	--assert not parse	[a]			[thru 'a skip]
	--test-- "blk-sk10"	--assert parse		[a b]		[to 'b skip]
	--test-- "blk-sk11"	--assert parse		[a b]		[thru 'b]
	--test-- "blk-sk12"	--assert parse		[a a a b]	[to 'b skip]
	--test-- "blk-sk13"	--assert parse		[a a b a]	[skip to 'b 2 skip]
	
	--test-- "blk-sk14"	--assert not parse	[a]			[to ['a]]
	--test-- "blk-sk15"	--assert not parse	[a]			[to ['a] end]
	--test-- "blk-sk16"	--assert parse		[a]			[to ['a] skip]
	--test-- "blk-sk17"	--assert parse		[a]			[thru ['a]]
	--test-- "blk-sk18"	--assert parse		[a]			[thru ['a] end]
	--test-- "blk-sk19"	--assert not parse	[a]			[thru ['a] skip]
	--test-- "blk-sk20"	--assert parse		[a b]		[to ['b] skip]
	--test-- "blk-sk21"	--assert parse		[a b]		[thru ['b]]
	--test-- "blk-sk22"	--assert parse		[a a a b]	[to ['b] skip]
	--test-- "blk-sk23"	--assert parse		[a a b a]	[skip to ['b] 2 skip]
	
	--test-- "blk-sk24"	--assert parse		[z z a b c]	[to ['c | 'b | 'a] 3 skip]
	--test-- "blk-sk25"	--assert parse		[z z a b c]	[to ['a | 'b | 'c] 3 skip]

	--test-- "blk-sk26"	--assert parse		[z z a b c]	[thru ['c | 'b | 'a] 2 skip]
	--test-- "blk-sk27"	--assert parse		[z z a b c]	[thru ['a | 'b | 'c] 2 skip]
	
	--test-- "blk-sk28"	--assert parse		[b b a a c]	[thru 2 'a 'c]
	--test-- "blk-sk29"	--assert parse		[b b a a c]	[thru 2 'a 'c]
	--test-- "blk-sk30"	--assert parse		[b b a a c]	[thru [2 'a] 'c]
	--test-- "blk-sk31"	--assert parse		[b b a a c]	[thru some 'a 'c]
	--test-- "blk-sk32"	--assert parse		[b b a a c]	[thru [some 'a] 'c]
	--test-- "blk-sk33"	--assert parse		[b b a a c]	[thru [some 'x | 2 'a] 'c]
	--test-- "blk-sk34"	--assert parse		[b b a a c]	[thru 2 wa 'c]
	--test-- "blk-sk35"	--assert parse		[b b a a c]	[thru some wa 'c]
	
	--test-- "blk-sk36"	--assert parse 		[1 "hello"]	[thru "hello"]

	--test-- "blk-sk37"
		res: 0
		--assert parse [1 "hello" a 1 2 3 b] [thru "hello" skip copy res to 'b skip]
		--assert res = [1 2 3]

===end-group===

===start-group=== "block-misc"

	--test-- "blk-m1"	--assert parse 		[]			[break]
	--test-- "blk-m2"	--assert not parse 	[a]			[break]
	--test-- "blk-m3"	--assert parse 		[a]			[[break 'b] 'a]
	--test-- "blk-m4"	--assert parse 		[a]			[['b | break] 'a]
	--test-- "blk-m5"	--assert parse 		[a a]		[some ['b | break] 2 'a]
	--test-- "blk-m6"	--assert parse 		[a a]		[some ['b | [break]] 2 'a]
	--test-- "blk-m7"	--assert not parse 	[a a]		[some ['b | 2 ['c | break]] 2 'a]

===end-group===

===start-group=== "string"

	--test-- "str-1" 	--assert parse		""			[]
	--test-- "str-2" 	--assert parse		"a"			[#"a"]
	--test-- "str-3" 	--assert parse		"a"			["a"]
	--test-- "str-4" 	--assert not parse	"a"			[#"b"]
	--test-- "str-5" 	--assert parse		"ab"		[#"a" #"b"]
	--test-- "str-6" 	--assert parse		"ab"		["ab"]
	--test-- "str-7" 	--assert parse		"a"			[[#"a"]]
	--test-- "str-8" 	--assert parse		"ab"		[[#"a"] "b"]
	--test-- "str-9" 	--assert parse		"ab"		[#"a" [#"b"]]
	--test-- "str-10"	--assert parse		"ab"		[[#"a"][#"b"]]

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

	--test-- "str-44"	--assert not parse		"aa"		[1 skip]
	--test-- "str-45"	--assert parse			"aa"		[2 skip]
	--test-- "str-46"	--assert not parse		"aa"		[3 skip]
	--test-- "str-47"	--assert not parse		"aa"		[1 1 skip]
	--test-- "str-48"	--assert parse			"aa"		[1 2 skip]
	--test-- "str-49"	--assert parse			"aa"		[2 2 skip]
	--test-- "str-50"	--assert parse			"aa"		[2 3 skip]
	--test-- "str-51"	--assert not parse		"aa"		[3 4 skip]
   
	--test-- "str-52"	--assert parse			"a"			[skip]
	--test-- "str-53"	--assert parse			"ab"		[skip skip]
	--test-- "str-54"	--assert parse			"ab"		[skip [skip]]
	--test-- "str-55"	--assert parse			"ab"		[[skip] [skip]]
   
	--test-- "str-56"	--assert parse			"aa"		[some [#"a"]]
	--test-- "str-57"	--assert not parse		"aa"		[some [#"a"] #"b"]
	
	--test-- "str-58"	--assert parse			"aababbba"	[some [skip]]
	--test-- "str-59"	--assert parse			"aababbba"	[some ["a" | "b"]]
	--test-- "str-60"	--assert not parse		"aababbba"	[some ["a" | #"c"]]
   
	--test-- "str-61"	--assert parse			"aa"		[any [#"a"]]
	--test-- "str-62"	--assert parse			"aa"		[some [#"a"] any [#"b"]]
	--test-- "str-63"	--assert parse			"aabb"		[2 #"a" 2 "b"]
	--test-- "str-64"	--assert not parse		"aabb"		[2 "a" 3 #"b"]
	--test-- "str-65"	--assert parse			"aabb"		[some #"a" some "b"]
	--test-- "str-66"	--assert not parse		"aabb"		[some "a" some #"c"]

	--test-- "str-67"
		p: none
		--assert parse "" [p:]
		--assert tail? p
	
	--test-- "str-68"
		p: none
		--assert parse "" [[[p:]]]
		--assert tail? p

		
	--test-- "str-69"
		p: none
		--assert parse "a" [p: #"a"]
		--assert p = "a"
		
	--test-- "str-70"
		p: none
		--assert parse "a" [#"a" p:]
		--assert tail? p
		
	--test-- "str-71"
		p: none
		--assert parse "a" [#"a" [p:]]
		--assert tail? p
		
	--test-- "str-72"
		p: none
		--assert not parse "ab" [#"a" p:]
		--assert p = "b"
	
	--test-- "str-73"
		p: none
		--assert parse "ab" [#"a" [p:][#"b" | #"c"]]
		--assert p = "b"
		
	--test-- "str-74"
		p: none
		--assert parse "aaabb" [3 #"a" p: 2 #"b" :p [2 "b"]]
		--assert p = "bb"
	
	--test-- "str-75"
	--assert parse "baaac" [skip some [#"a"] #"c"]
	
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

===start-group=== "string-words"
	
	wa: [#"a"]
	wb: [#"b"]
	wca: #"a"
	wcb: #"b"
	wra: [wa]
	wrb: [wb]
	wh: "hello"
	wrab: [#"a" | #"b"]
	wrba: [#"b" | #"a"]
	
	--test-- "str-w1" 	--assert parse 		"a"			[wa]
	--test-- "str-w2" 	--assert not parse 	"a"			[wb]
	--test-- "str-w3" 	--assert parse 		"ab"		[wa wb]
	--test-- "str-w5" 	--assert parse 		"a"			[wra]
	--test-- "str-w6" 	--assert parse 		"ab"		[wra #"b"]
	--test-- "str-w7" 	--assert parse 		"ab"		[#"a" wrb]
	--test-- "str-w8" 	--assert parse 		"ab"		[wra wrb]
	--test-- "str-w9" 	--assert parse 		"hello"		[wh]

	--test-- "str-w10"	--assert parse 		"a" 		[wcb | wca]
	--test-- "str-w11"	--assert not parse 	"ab"		[wb | wa]
	--test-- "str-w12"	--assert parse 		"a"			[[wcb | wca]]
	--test-- "str-w13"	--assert not parse 	"ab"		[wrba]
	--test-- "str-w14"	--assert parse 		"ab"		[wrab wrba]
	
	--test-- "str-w19"
		res: 0	
		--assert parse "a" [wa (res: 1)]
		--assert res = 1
		
	--test-- "str-w20"
		res: 0	
		--assert not parse "a" [wb (res: 1)]
		--assert res = 0
		
	--test-- "str-w21"
		res: 0	
		wres: [(res: 1)]
		--assert parse "" [wres]
		--assert res = 1

	--test-- "str-w22"
		res: 0
		wres: [#"a" (res: 1)]
		--assert parse "a" [wres]
		--assert res = 1

	--test-- "str-w23"
		res: 0
		wres: [#"b" (res: 1)]
		--assert not parse "a" [wres]
		--assert res = 0

===end-group===

===start-group=== "string-extraction"

	wa: [#"a"]
	--test-- "str-ext1" 
		res: 0
		--assert parse "a" [copy res skip]
		--assert res = "a"
	
	--test-- "str-ext2" 
		res: 0
		--assert parse "a" [copy res #"a"]
		--assert res = "a"
		
	--test-- "str-ext4" 
		res:  0
		res2: 0
		--assert parse "a" [copy res copy res2 #"a"]
		--assert res  = "a"
		--assert res2 = "a"
		
	--test-- "str-ext5" 
		res: 0
		--assert parse "aa" [copy res 2 #"a"]
		--assert res = "aa"

	--test-- "str-ext6" 
		res: 0
		--assert not parse "aa" [copy res 3 #"a"]
		--assert res = 0
		
	--test-- "str-ext7" 
		res: 0
		--assert parse "a" [copy res [#"a"]]
		--assert res = "a"

	--test-- "str-ext8" 
		res: 0
		--assert parse "a" [copy res wa]
		--assert res = "a"
	
	--test-- "str-ext9" 
		res: 0
		--assert parse "aa" [copy res 2 wa]
		--assert res = "aa"
	
	--test-- "str-ext10" 
		res: 0
		--assert parse "aab" [skip copy res #"a" skip]
		--assert res = "a"
 
	--test-- "str-ext11" 
		res: 0
		--assert parse "aab" [skip copy res [#"a" | #"b"] skip]
		--assert res = "a"
		
	--test-- "str-ext12" 
		res: 0
		--assert not parse "a" [copy res [#"c" | #"b"]]
		--assert res = 0
		
	--test-- "str-ext13" 
		res: 0
		--assert parse "a" [set res skip]
		--assert res = #"a"

	--test-- "str-ext14" 
		res: 0
		--assert parse "a" [set res #"a"]
		--assert res = #"a"

	--test-- "str-ext16" 
		res:  0
		res2: 0
		--assert parse "a" [set res set res2 #"a"]
		--assert res  = #"a"
		--assert res2 = #"a"

	--test-- "str-ext17" 
		res: 0
		--assert parse "aa" [set res 2 #"a"]
		--assert res = #"a"

	--test-- "str-ext18" 
		res: 0
		--assert not parse "aa" [set res 3 #"a"]
		--assert res = 0

	--test-- "str-ext19" 
		res: 0
		--assert parse "a" [set res [#"a"]]
		--assert res = #"a"

	--test-- "str-ext20" 
		res: 0
		--assert parse "a" [set res wa]
		--assert res = #"a"

	--test-- "str-ext21" 
		res: 0
		--assert parse "aa" [set res 2 wa]
		--assert res = #"a"

	--test-- "str-ext22" 
		res: 0
		--assert parse "aab" [skip set res #"a" skip]
		--assert res = #"a"

	--test-- "str-ext23" 
		res: 0
		--assert parse "aab" [skip set res [#"a" | #"b"] skip]
		--assert res = #"a"

	--test-- "str-ext24" 
		res: 0
		--assert not parse "a" [set res [#"c" | #"b"]]
		--assert res = 0
		
	--test-- "str-ext25" 
		res: 0
		--assert parse "baaac" [skip set res some #"a" #"c"]
		--assert res = #"a"

	--test-- "str-ext26" 
		res: 0
		--assert parse "baaac" [skip set res some wa #"c"]
		--assert res = #"a"
		
===end-group===

===start-group=== "string-skipping"

	str: "Lorem ipsum dolor sit amet."
	wa: [#"a"]
	
	--test-- "str-sk1" 	--assert parse		""			[to end]
	--test-- "str-sk2" 	--assert parse		""			[thru end]
	--test-- "str-sk3" 	--assert parse		"a"			[to end]
	--test-- "str-sk4" 	--assert not parse	"a"			[to #"a"]
	--test-- "str-sk5" 	--assert not parse	"a"			[to #"a" end]
	--test-- "str-sk6" 	--assert parse		"a"			[to #"a" skip]
	--test-- "str-sk7" 	--assert parse		"a"			[thru #"a"]
	--test-- "str-sk8" 	--assert parse		"a"			[thru #"a" end]
	--test-- "str-sk9" 	--assert not parse	"a"			[thru #"a"skip]
	--test-- "str-sk10"	--assert parse		"ab"		[to #"a" 2 skip]
	--test-- "str-sk11"	--assert parse		"ab"		[thru #"a" skip]
	--test-- "str-sk12"	--assert parse		"aaab"		[to #"a" to end]
	--test-- "str-sk13"	--assert parse		"aaba"		[skip thru #"a" 2 skip]
	
	--test-- "str-sk14"	--assert not parse	"a"			[to [#"a"]]
	--test-- "str-sk15"	--assert not parse	"a"			[to [#"a"] end]
	--test-- "str-sk16"	--assert parse		"a"			[to [#"a"] skip]
	--test-- "str-sk17"	--assert parse		"a"			[thru [#"a"]]
	--test-- "str-sk18"	--assert parse		"a"			[thru [#"a"] end]
	--test-- "str-sk19"	--assert not parse	"a"			[thru [#"a"] skip]
	--test-- "str-sk20"	--assert parse		"ab"		[to [#"a"] 2 skip]
	--test-- "str-sk21"	--assert parse		"ab"		[thru [#"a"] skip]
	--test-- "str-sk22"	--assert parse		"aaab"		[to [#"a"] to end]
	--test-- "str-sk23"	--assert parse		"aaba"		[skip thru [#"a"] 2 skip]
	
	--test-- "str-sk24"	--assert parse		"zzabc"		[to [#"c" | #"b" | #"a"] 3 skip]
	--test-- "str-sk25"	--assert parse		"zzabc"		[to [#"a" | #"b" | #"c"] 3 skip]

	--test-- "str-sk26"	--assert parse		"zzabc"		[thru [#"c" | #"b" | #"a"] 2 skip]
	--test-- "str-sk27"	--assert parse		"zzabc"		[thru [#"a" | #"b" | #"c"] 2 skip]
	--test-- "str-sk28"	--assert parse		"bbaaac"	[thru 3 #"a" #"c"]
	--test-- "str-sk29"	--assert parse		"bbaaac"	[thru 3 "a" "c"]
	--test-- "str-sk30"	--assert parse		"bbaaac"	[thru 3 wa #"c"]
	--test-- "str-sk31"	--assert parse		"bbaaac"	[thru [3 "a"] "c"]
	--test-- "str-sk32"	--assert parse		"bbaaac"	[thru some "a" "c"]
	--test-- "str-sk33"	--assert parse		"bbaaac"	[thru [some #"a"] "c"]
	--test-- "str-sk34"	--assert parse		"bbaaac"	[thru [some #"x" | "aaa"] "c"]
	
	--test-- "str-sk35"	--assert parse 		str 		[thru "amet" skip]

	--test-- "str-sk36"
		res: 0
		--assert parse str [thru "ipsum" skip copy res to #" " to end]
		--assert res = "dolor"

	--test-- "str-sk37"
		res: 0
		--assert parse str [thru #"p" res: to end]
		--assert 9 = index? res 
	
===end-group===

===start-group=== "string-misc"

	--test-- "str-m1"	--assert parse 		""			[break]
	--test-- "str-m2"	--assert not parse 	"a"			[break]
	--test-- "str-m3"	--assert parse 		"a"			[[break #"b"] #"a"]
	--test-- "str-m4"	--assert parse 		"a"			[[#"b" | break] #"a"]
	--test-- "str-m5"	--assert parse 		"aa"		[some [#"b" | break] 2 #"a"]
	--test-- "str-m6"	--assert parse 		"aa"		[some [#"b" | [break]] 2 #"a"]
	--test-- "str-m7"	--assert not parse 	"aa"		[some [#"b" | 2 [#"c" | break]] 2 #"a"]

===end-group===
    
~~~end-file~~~

