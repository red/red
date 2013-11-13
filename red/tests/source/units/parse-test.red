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

	--test-- "blk-sk38" --assert not parse	[]			[to 'a]
	--test-- "blk-sk39" --assert not parse	[]			[to ['a]]

===end-group===

===start-group=== "block-modify"
	--test-- "blk-mod1"	--assert not parse	[]			[remove]
	--test-- "blk-mod2"	--assert not parse	[]			[remove skip]

	--test-- "blk-mod3"	
		blk: [a]
		--assert parse blk [remove skip]
		--assert blk = []

	--test-- "blk-mod4"	
		blk: [a b a]
		--assert parse blk [some ['a | remove 'b]]
		--assert blk = [a a]


===end-group===

===start-group=== "block-misc"

	wa: ['a]
	wb: ['b]
	--test-- "blk-m1"	--assert parse 		[]			[break]
	--test-- "blk-m2"	--assert not parse 	[a]			[break]
	--test-- "blk-m3"	--assert parse 		[a]			[[break 'b] 'a]
	--test-- "blk-m4"	--assert parse 		[a]			[['b | break] 'a]
	--test-- "blk-m5"	--assert parse 		[a a]		[some ['b | break] 2 'a]
	--test-- "blk-m6"	--assert parse 		[a a]		[some ['b | [break]] 2 'a]
	--test-- "blk-m7"	--assert not parse 	[a a]		[some ['b | 2 ['c | break]] 2 'a]

	--test-- "blk-m20"	--assert not parse 	[]			[fail]
	--test-- "blk-m21"	--assert not parse 	[a]			['a fail]
	--test-- "blk-m22"	--assert not parse 	[a]			[[fail]]
	--test-- "blk-m23"	--assert not parse 	[a]			[fail | fail]
	--test-- "blk-m24"	--assert not parse 	[a]			[[fail | fail]]
	--test-- "blk-m25"	--assert not parse 	[a]			['b | fail]

	--test-- "blk-m30"	--assert not parse 	[]			[not end]
	--test-- "blk-m31"	--assert parse 		[a]			[not 'b 'a]
	--test-- "blk-m32"	--assert not parse 	[a]			[not skip]
	--test-- "blk-m33"	--assert not parse 	[a]			[not skip skip]
	--test-- "blk-m34"	--assert parse 		[a]			[not ['b] 'a]
	--test-- "blk-m35"	--assert parse 		[a]			[not wb 'a]
	--test-- "blk-m36"	--assert not parse 	[a a]		[not ['a 'a] to end]
	--test-- "blk-m37"	--assert parse 		[a a]		[not [some 'b] to end]
	--test-- "blk-m38"	--assert parse 		[a a]		[some ['c | not 'b] 2 skip]

	--test-- "blk-m40"	--assert parse 		[wb]		[quote wb]
	--test-- "blk-m41"	--assert parse 		[123]		[quote 123]
	--test-- "blk-m42"	--assert parse 		[3 3]		[2 quote 3]
	--test-- "blk-m43"	--assert parse 		[none]		[quote none]
	--test-- "blk-m44"	--assert parse 		[some]		[quote some]

	--test-- "blk-m50"	--assert not parse 	[]			[reject]
	--test-- "blk-m51"	--assert not parse 	[a]			[reject 'a]
	--test-- "blk-m52"	--assert not parse 	[a]			[reject wa]
	--test-- "blk-m53"	--assert not parse 	[a]			[[reject] 'a]
	--test-- "blk-m54"	--assert parse 		[a]			[[reject 'b] | 'a]
	--test-- "blk-m55"	--assert not parse 	[a]			[['b | reject] 'a]
	--test-- "blk-m56"	--assert parse 		[a]			[['b | reject] | 'a]
	--test-- "blk-m57"	--assert parse 		[a a]		[some reject | 2 'a]
	--test-- "blk-m58"	--assert parse 		[a a]		[some [reject] | 2 'a]
	
	--test-- "blk-m60"	--assert parse 		[]			[none]
	--test-- "blk-m61"	--assert parse 		[a]			[skip none]
	--test-- "blk-m62"	--assert parse 		[a]			[none skip none]
	--test-- "blk-m63"	--assert parse 		[a]			['a none]
	--test-- "blk-m64"	--assert parse 		[a]			[none 'a none]
	--test-- "blk-m65"	--assert parse 		[a]			[wa none]
	--test-- "blk-m66"	--assert parse 		[a]			[none wa none]
	--test-- "blk-m67"	--assert parse 		[a]			[['b | none] 'a]
	--test-- "blk-m68"	--assert parse 		[a]			[['b | [none]] 'a]
	--test-- "blk-m69"	--assert parse 		[a]			[[['b | [none]]] 'a]

	--test-- "blk-m80"	--assert parse 		[]			[opt none]
	--test-- "blk-m81"	--assert parse 		[]			[opt 'a]
	--test-- "blk-m82"	--assert parse 		[a]			[opt 'a]
	--test-- "blk-m83"	--assert parse 		[a]			[opt 'b 'a]
	--test-- "blk-m84"	--assert parse 		[a]			[opt ['a]]
	--test-- "blk-m85"	--assert parse 		[a]			[opt wa]
	--test-- "blk-m86"	--assert parse 		[a]			[opt skip]
	--test-- "blk-m87"	--assert parse 		[a b c]		[skip opt 'b skip]

	--test-- "blk-m90"	--assert parse 		[[]]		[into []]
	--test-- "blk-m91"	--assert parse 		[[a]]		[into ['a]]
	--test-- "blk-m92"	--assert parse 		[b [a] c]	['b into ['a] 'c]
	--test-- "blk-m93"	--assert parse 		["a"]		[into [#"a"]]
	--test-- "blk-m94"	--assert parse 		[b "a" c]	['b into ["a"] 'c]
	--test-- "blk-m95"	--assert parse 		[["a"]]		[into [into [#"a"]]]
	--test-- "blk-m96"	--assert not parse 	[[a]]		[into ['a 'b]]
	--test-- "blk-m97"	--assert not parse 	[[a]]		[into [some 'b]]
	--test-- "blk-m98"	--assert parse 		[[a]]		[into ['a 'b] | block!]

	--test-- "blk-m100"	--assert not parse	[]			[then skip]
	--test-- "blk-m101"	--assert parse		[]			[then skip | end]
	--test-- "blk-m102"	--assert parse		[a]			[then 'a | 'b]
	--test-- "blk-m103"	--assert not parse	[c]			[then 'a | 'b]
	--test-- "blk-m104"	--assert parse		[b]			[then 'a | 'b]
	--test-- "blk-m105"	--assert parse		[z a]		['z then 'a | 'b]

	x: none
	--test-- "blk-m110"	--assert parse		[2 4 6]		[any [set x integer! if (even? x)]]
	--test-- "blk-m111"	--assert not parse	[1]			[set x integer! if (even? x)]
	--test-- "blk-m112"	--assert not parse	[1 5]		[some [set x integer! if (even? x)]]

	--test-- "blk-m120"	--assert parse		[]			[while 'a]
	--test-- "blk-m121"	--assert parse		[]			[while 'b]
	--test-- "blk-m122"	--assert parse		[a]			[while 'a]
	--test-- "blk-m123"	--assert not parse	[a]			[while 'b]
	--test-- "blk-m124"	--assert parse		[a]			[while 'b skip]
	--test-- "blk-m125"	--assert parse		[a b a b]	[while ['b | 'a]]

===end-group===

===start-group=== "block-bugs"

	--test-- "#562" 	--assert not parse 	[+] 		[any ['+ if (no)]]
	--test-- "#564-1"	--assert not parse  [a] 		[0 skip]
	--test-- "#564-2"	--assert parse 		[a] 		[0 skip 'a]

	--test-- "#564-3"
		z: none
		--assert not parse 	[a] [copy z 0 skip]
		--assert z = []

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

	--test-- "str-sk38" --assert not parse	""			[to "a"]
	--test-- "str-sk39" --assert not parse	""			[to #"a"]
	--test-- "str-sk40" --assert not parse	""			[to ["a"]]
	--test-- "str-sk41" --assert not parse	""			[to [#"a"]]

	
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

===start-group=== "string-unicode"
	
	--test-- "str-uni1"		--assert parse		"abcdé" 	[#"a" #"b" #"c" #"d" #"é"]
	--test-- "str-uni2"		--assert parse		"abcdé" 	["abcdé"]
	--test-- "str-uni3"		--assert not parse	"abcde" 	[#"a" #"b" #"c" #"d" #"é"]
	--test-- "str-uni4"		--assert parse 		"abcdé" 	[#"a" #"b" #"c" #"d" #"é"]

	--test-- "str-uni5" 
		--assert parse "abcdé✐" [#"a" #"b" #"c" #"d" #"é" #"✐"]

	--test-- "str-uni6"		--assert parse		"abcdé✐"	["abcdé✐"]
	--test-- "str-uni7"		--assert not parse	"abcdé"		["abcdé✐"]
	--test-- "str-uni8"		--assert not parse	"ab✐cdé"	["abcdé✐"]
	--test-- "str-uni9"		--assert not parse	"abcdé✐"	["abcdé"]
	--test-- "str-uni10"	--assert parse		"✐abcdé"	["✐abcdé"]

	--test-- "str-uni11" 
		--assert parse "abcdé✐^(010000)" [#"a" #"b" #"c" #"d" #"é" #"✐" #"^(010000)"]

	--test-- "str-uni12"	--assert parse		"ab^(010000)cdé✐"	["ab^(010000)cdé✐"]
	--test-- "str-uni13"	--assert not parse	"abcdé" 			["abc^(010000)dé"]
	--test-- "str-uni14"	--assert not parse	"^(010000)abcdé"	["a^(010000)bcdé"]
	--test-- "str-uni15"	--assert not parse	"abcdé^(010000)"	["abcdé"]
	--test-- "str-uni16"	--assert parse		"^(010000)abcdé"	["^(010000)abcdé"]
	
===end-group=== 

===start-group=== "string-bitsets"
	
	bs:	   charset ["hello" #"a" - #"z"]
	wbs: [bs]
	wbs2: reduce wbs
	--test-- "str-bs1" 		--assert parse 			"abc" 		[some bs]
	--test-- "str-bs2" 		--assert not parse 		"123" 		[some bs]
	--test-- "str-bs3" 		--assert not parse 		"ABC" 		[some bs]
	--test-- "str-bs4" 		--assert parse 			"abc" 		[some [bs]]
	--test-- "str-bs5" 		--assert not parse 		"123" 		[some [bs]]
	--test-- "str-bs6" 		--assert parse 			"abc" 		[some wbs]
	--test-- "str-bs7" 		--assert not parse 		"123" 		[some wbs]
	--test-- "str-bs8" 		--assert parse 			"abc" 		[some wbs2]
	--test-- "str-bs9" 		--assert not parse 		"123" 		[some wbs2]

	--test-- "str-bs10" 	--assert parse 			"abc" 		[bs bs bs]
	--test-- "str-bs11" 	--assert not parse 		"123" 		[bs bs bs]
	--test-- "str-bs12" 	--assert parse 			"abc" 		[[bs] [bs] [bs]]
	--test-- "str-bs13" 	--assert not parse 		"123" 		[[bs] [bs] [bs]]
	--test-- "str-bs14" 	--assert parse 			"abc" 		[wbs wbs wbs]
	--test-- "str-bs15" 	--assert not parse 		"123" 		[wbs wbs wbs]
	--test-- "str-bs16" 	--assert parse 			"abc" 		[wbs2 wbs2 wbs2]
	--test-- "str-bs17" 	--assert not parse 		"123" 		[wbs2 wbs2 wbs2]


	bs: charset [not "hello123" #"a" - #"z"]
	wbs: [bs]
	wbs2: reduce wbs
	--test-- "str-bs6" 		--assert not parse 		"abc" 		[some bs]
	--test-- "str-bs7" 		--assert parse 			"ABC" 		[some bs]
	--test-- "str-bs8" 		--assert not parse 		"123" 		[some bs]
	--test-- "str-bs9"		--assert parse 			"789" 		[some bs]
	--test-- "str-bs10" 	--assert not parse 		"abc" 		[bs bs bs]
	--test-- "str-bs11" 	--assert parse			"ABC" 		[bs bs bs]
	--test-- "str-bs12" 	--assert not parse 		"123" 		[bs bs bs]
	--test-- "str-bs13" 	--assert parse 			"789" 		[bs bs bs]


	--test-- "str-bs20"
		digit: charset "0123456789"
		--assert parse "hello 123" [to digit p: 3 skip]
		--assert p = "123"


===end-group===

===start-group=== "string-modify"
	ws: charset " ^- ^/^M"
	not-ws: complement ws

	--test-- "str-rem1"		--assert not parse		""			[remove]
	--test-- "str-rem2"		--assert not parse		""			[remove skip]

	--test-- "str-rem3"	
		str: "a"
		--assert parse str [remove skip]
		--assert str = ""

	--test-- "str-rem4"	
		str: "aba"
		--assert parse str [some [#"a" | remove #"b"]]
		--assert str = "aa"

	--test-- "str-rem5"	
		str: "hello world"
		--assert parse str [remove thru ws "world"]
		--assert str = "world"

	--test-- "str-rem6"	
		str: "hello world"
		--assert parse str [remove "hello" skip "world"]
		--assert str = " world"

	--test-- "str-rem7"
		--assert not parse s: " t e s t " [any [remove ws | skip]]
		--assert s = "t e s t "

	--test-- "str-rem8"
		--assert parse s: " t e s t " [while [remove ws | skip]]
		--assert s = "test"

	--test-- "str-rem9"
		str: "hello 123 world"
		digit: charset "0123456789"
		--assert parse str [any [remove [some digit #" "] | skip]]
		--assert str = "hello world"

===end-group===

===start-group=== "string-misc"

	wa: [#"a"]
	wb: [#"b"]
	--test-- "str-m1"	--assert parse 		""			[break]
	--test-- "str-m2"	--assert not parse 	"a"			[break]
	--test-- "str-m3"	--assert parse 		"a"			[[break #"b"] #"a"]
	--test-- "str-m4"	--assert parse 		"a"			[[#"b" | break] #"a"]
	--test-- "str-m5"	--assert parse 		"aa"		[some [#"b" | break] 2 #"a"]
	--test-- "str-m6"	--assert parse 		"aa"		[some [#"b" | [break]] 2 #"a"]
	--test-- "str-m7"	--assert not parse 	"aa"		[some [#"b" | 2 [#"c" | break]] 2 #"a"]

	--test-- "str-m20"	--assert not parse 	""			[fail]
	--test-- "str-m21"	--assert not parse 	"a"			[#"a" fail]
	--test-- "str-m22"	--assert not parse 	"a"			[[fail]]
	--test-- "str-m23"	--assert not parse 	"a"			[fail | fail]
	--test-- "str-m24"	--assert not parse 	"a"			[[fail | fail]]
	--test-- "str-m25"	--assert not parse 	"a"			[#"b" | fail]

	--test-- "str-m30"	--assert not parse 	""			[not end]
	--test-- "str-m31"	--assert parse 		"a"			[not #"b" #"a"]
	--test-- "str-m32"	--assert not parse 	"a"			[not skip]
	--test-- "str-m33"	--assert not parse 	"a"			[not skip skip]
	--test-- "str-m34"	--assert parse 		"a"			[not [#"b"] #"a"]
	--test-- "str-m35"	--assert parse 		"a"			[not wb #"a"]
	--test-- "str-m36"	--assert not parse 	"aa"		[not [#"a" #"a"] to end]
	--test-- "str-m37"	--assert parse 		"aa"		[not [some #"b"] to end]
	--test-- "str-m38"	--assert parse 		"aa"		[some [#"c" | not #"b"] 2 skip]

	--test-- "str-m50"	--assert not parse 	""			[reject]
	--test-- "str-m51"	--assert not parse 	"a"			[reject #"a"]
	--test-- "str-m52"	--assert not parse 	"a"			[reject wa]
	--test-- "str-m53"	--assert not parse 	"a"			[[reject] #"a"]
	--test-- "str-m54"	--assert parse 		"a"			[[reject #"b"] | #"a"]
	--test-- "str-m55"	--assert not parse 	"a"			[[#"b" | reject] #"a"]
	--test-- "str-m56"	--assert parse 		"a"			[[#"b" | reject] | #"a"]
	--test-- "str-m57"	--assert parse 		"aa"		[some reject | 2 #"a"]
	--test-- "str-m58"	--assert parse 		"aa"		[some [reject] | 2 #"a"]
	
	--test-- "str-m60"	--assert parse 		""			[none]
	--test-- "str-m61"	--assert parse 		"a"			[skip none]
	--test-- "str-m62"	--assert parse 		"a"			[none skip none]
	--test-- "str-m63"	--assert parse 		"a"			[#"a" none]
	--test-- "str-m64"	--assert parse 		"a"			[none #"a" none]
	--test-- "str-m65"	--assert parse 		"a"			[wa none]
	--test-- "str-m66"	--assert parse 		"a"			[none wa none]
	--test-- "str-m67"	--assert parse 		"a"			[[#"b" | none] #"a"]
	--test-- "str-m68"	--assert parse 		"a"			[[#"b" | [none]] #"a"]
	--test-- "str-m69"	--assert parse 		"a"			[[[#"b" | [none]]] #"a"]

	--test-- "str-m80"	--assert parse 		""			[opt none]
	--test-- "str-m81"	--assert parse 		""			[opt #"a"]
	--test-- "str-m82"	--assert parse 		"a"			[opt #"a"]
	--test-- "str-m83"	--assert parse 		"a"			[opt #"b" #"a"]
	--test-- "str-m84"	--assert parse 		"a"			[opt [#"a"]]
	--test-- "str-m85"	--assert parse 		"a"			[opt wa]
	--test-- "str-m86"	--assert parse 		"a"			[opt skip]
	--test-- "str-m87"	--assert parse 		"abc"		[skip opt #"b" skip]

	--test-- "str-m90"	--assert not parse	""			[then skip]
	--test-- "blk-m91"	--assert parse		""			[then skip | end]
	--test-- "str-m92"	--assert parse		"a"			[then #"a" | #"b"]
	--test-- "str-m93"	--assert not parse	"c"			[then #"a" | #"b"]
	--test-- "str-m94"	--assert parse		"b"			[then #"a" | #"b"]
	--test-- "str-m95"	--assert parse		"za"		[#"z" then #"a" | #"b"]

	x: none
	--test-- "str-m100"	--assert parse		"246"		[any [copy x skip if (even? load x)]]
	--test-- "str-m101"	--assert not parse	"1"			[copy x skip if (even? load x)]
	--test-- "str-m102"	--assert not parse	"15"		[some [copy x skip if (even? load x)]]

	--test-- "str-m120"	--assert parse		""			[while #"a"]
	--test-- "str-m121"	--assert parse		""			[while #"b"]
	--test-- "str-m122"	--assert parse		"a"			[while #"a"]
	--test-- "str-m123"	--assert not parse	"a"			[while #"b"]
	--test-- "str-m124"	--assert parse		"a"			[while #"b" skip]
	--test-- "str-m125"	--assert parse		"abab"		[while [#"b" | #"a"]]

===end-group===


===start-group=== "string-complex"

	--test-- "str-cplx1"
		expr:    [term ["+" | "-"] expr | term]
		term:    [factor ["*" | "/"] term | factor]
		factor:  [primary "**" factor | primary]
		primary: [some digit | "(" expr ")"]
		digit:   charset "0123456789"

		--assert 	 parse "1" expr
		--assert not parse "1+" expr
		--assert 	 parse "1+2" expr
		--assert not parse "1+2*" expr
		--assert not parse "1+2*(" expr
		--assert not parse "1+2*(3" expr
		--assert not parse "1+2*(3-" expr
		--assert not parse "1+2*(3-2" expr
		--assert 	 parse "1+2*(3-2)" expr
		--assert not parse "1+2*(3-2)/" expr
		--assert 	 parse "1+2*(3-2)/4" expr

		--assert parse "(1)" expr
		--assert parse "(1*9)" expr
		--assert not parse "(+)" expr
		--assert parse "1+2*(3-2)/4" expr
		--assert parse "4/5+3**2-(5*6+1)" expr
		--assert not parse "a+b" expr
		--assert not parse "123a+2" expr

===end-group===

===start-group=== "string-bugs"

	--test-- "#562" 	--assert not parse 	"+"		[any [#"+" if (no)]]

	--test-- "#564-1"	--assert not parse  "a" 		[0 skip]
	--test-- "#564-2"	--assert parse 		"a" 		[0 skip #"a"]

	--test-- "#564-3"
		z: none
		--assert not parse "a" [copy z 0 skip]
		--assert z = ""

	--test-- "#564-4"
		f: func [
			s [string!]
		][
			r: [
				copy l  skip (l: load l)
				copy x  l skip
				[
					#","
					| #"]" if (f x)
				]
			]
			parse s [any r end]
		]
		--assert f "420,]]"

	--test-- "#563"
		r: [#"+" if (res: f563 "-" --assert not res res)]
		f563: func [t [string!]][parse t [any r]]
		--assert not f563 "-"
		--assert not f563 "+"

===end-group===
    
~~~end-file~~~

