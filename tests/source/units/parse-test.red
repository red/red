Red [
	Title:	"Red PARSE test script"
	Author:	"Nenad Rakocevic"
	File:	%parse-test.reds
	Tabs:	4
	Rights:	"Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

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

	--test-- "blk-19-1"	--assert parse		[123]		[number!]
	--test-- "blk-19-2"	--assert not parse	[123]		[any-string!]
	--test-- "blk-19-3"	--assert parse		[123]		[[number!]]
	--test-- "blk-19-4"	--assert not parse	[123]		[[any-string!]]	
	
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
		--assert parse [a a][copy res 2 'a]
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
		--assert parse [a a][set res 2 'a]
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

	--test-- "blk-ext40"
		res: parse [] [collect []]
		--assert res = []

	--test-- "blk-ext41"
		res: parse [1] [collect []]
		--assert res = []

	--test-- "blk-ext42"
		res: parse [1] [collect [keep skip]]
		--assert res = [1]

	--test-- "blk-ext43"
		res: parse [1 2 3] [collect [some [keep integer!]]]
		--assert res = [1 2 3]

	--test-- "blk-ext44"
		res: parse [1 2 3] [collect [some [keep [set v integer! if (even? v)] | skip]]]
		--assert res = [2]

	--test-- "blk-ext45"
		res: parse [a 3 4 t "test" 8][collect [any [keep integer! | skip]]]
		--assert res = [3 4 8]

	--test-- "blk-ext46"
		a: none
		--assert parse [] [collect set a []]
		--assert a = []

	--test-- "blk-ext47"
		a: none
		--assert parse [1] [collect set a [keep skip]]
		--assert a = [1]

	--test-- "blk-ext48"
		list: none
		--assert parse [a 3 4 t "test" 8][collect set list [any [keep integer! | skip]]]
		--assert list = [3 4 8]

	--test-- "blk-ext49"
		a: []
		--assert parse [] [collect into a []]
		--assert a = []

	--test-- "blk-ext50"
		a: []
		--assert parse [1] [collect into a [keep skip]]
		--assert a = [1]
		--assert [1] = head a

	--test-- "blk-ext51"
		list: next [1 2 3]
		--assert parse [a 4 b 5 c] [collect into list [some [keep word! | skip]]]
		--assert list = [a b c 2 3]
		--assert [1 a b c 2 3] = head list

	--test-- "blk-ext52"
		res: parse [a b b b] [collect [skip keep some 'b]]
		--assert res = [[b b b]]

	--test-- "blk-ext53"
		a: []
		--assert parse [1] [collect after a [keep skip]]
		--assert a = []
		--assert [1] = head a

	--test-- "blk-ext54"
		list: next [1 2 3]
		--assert parse [a 4 b 5 c] [collect after list [some [keep word! | skip]]]
		--assert list = [2 3]
		--assert [1 a b c 2 3] = head list
		
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
	
	--test-- "blk-rem1" --assert error? try [parse [] [remove]]

	--test-- "blk-rem2"	--assert not parse	[]			[remove skip]

	--test-- "blk-rem3"	
		blk: [a]
		--assert parse blk [remove skip]
		--assert blk = []

	--test-- "blk-rem4"	
		blk: [a b a]
		--assert parse blk [some ['a | remove 'b]]
		--assert blk = [a a]

	--test-- "blk-ins1"	
		--assert parse blk: [] [insert 1]
		--assert blk = [1]

	--test-- "blk-ins2"	
		--assert parse blk: [a a] [skip insert 'b skip]
		--assert blk = [a b a]

	--test-- "blk-ins3"	
		--assert parse blk: [] [p: insert 'a :p remove 'a]
		--assert blk = []

	--test-- "blk-ins4"	
		--assert parse blk: [] [insert [a b]]
		--assert blk = [a b]

	--test-- "blk-ins5"	
		--assert parse blk: [] [insert only [a b]]
		--assert blk = [[a b]]

	--test-- "blk-chg1"
		--assert parse blk: [1][change integer! 'a]
		--assert blk = [a]

	--test-- "blk-chg2"
		--assert parse blk: [1 2 3][change [some integer!] 'a]
		--assert blk = [a]

	--test-- "blk-chg3"
		--assert parse blk: [1 a 2 b 3][some [change word! dot | integer!]]
		--assert blk = [1 #"." 2 #"." 3]

	--test-- "blk-chg4"
		--assert parse blk: [1 2 3][change [some integer!] (99)]
		--assert blk = [99]

	--test-- "blk-chg5"
		--assert parse blk: [1 2 3][change only [some integer!] [a]]
		--assert blk = [[a]]

	--test-- "blk-chg6"
		--assert parse blk: [1 2 3][change only [some integer!] (reduce [1 + 2])]
		--assert blk = [[3]]

	--test-- "blk-chg11"
		--assert parse blk: [1][b: integer! change b 'a]
		--assert blk = [a]

	--test-- "blk-chg12"
		--assert parse blk: [1 2 3][b: some integer! change b 'a]
		--assert blk = [a]

	--test-- "blk-chg13"
		--assert parse blk: [1 a 2 b 3][some [b: word! change b dot | integer!]]
		--assert blk = [1 #"." 2 #"." 3]

	--test-- "blk-chg14"
		--assert parse blk: [1 2 3][b: some integer! change b (99)]
		--assert blk = [99]

	--test-- "blk-chg15"
		--assert parse blk: [1 2 3][b: some integer! change only b [a]]
		--assert blk = [[a]]

	--test-- "blk-chg16"
		--assert parse blk: [1 2 3][b: some integer! change only b (reduce [1 + 2])]
		--assert blk = [[3]]


===end-group===

===start-group=== "block-recurse"

	--test-- "blk-rec1"
		--assert parse [a "test"]['a set s string! (--assert parse s [4 skip])]

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

	--test-- "blk-m130"	--assert error? try [parse [] [ahead]]
	--test-- "blk-m131"	--assert parse		[a]			[ahead 'a 'a]
	--test-- "blk-m132"	--assert parse		[1]			[ahead [block! | integer!] skip]

===end-group===

===start-group=== "block-part"
	input: [h 5 #"l" "l" o]
	input2: [a a a b b]

	--test-- "blk-part-1"
		v: none
		--assert not parse/part input [copy v 3 skip] 2
		--assert none? v

	--test-- "blk-part-2"
		v: none
		--assert parse/part input [copy v 3 skip] 3
		--assert v = [h 5 #"l"]

	--test-- "blk-part-3"
		v: none
		--assert not parse/part input [copy v 3 skip] 4
		--assert v = [h 5 #"l"]

	--test-- "blk-part-4"
		v: none
		--assert parse/part input [copy v 3 skip skip] 4
		--assert v = [h 5 #"l"]

	--test-- "blk-part-5"
		v: none
		--assert parse/part next input [copy v 3 skip] 3
		--assert v = [5 #"l" "l"]

	--test-- "blk-part-6"
		v: none
		--assert not parse/part input [copy v to 'o skip] 3
		--assert none? v

	--test-- "blk-part-7"
		v: none
		--assert parse/part input [copy v to 'o skip] 5
		--assert v = [h 5 #"l" "l"]

	--test-- "blk-part-8"
		v: none
		--assert not parse/part input2 [copy v 3 'a] 2
		--assert none? v

	--test-- "blk-part-9"
		v: none
		--assert parse/part input2 [copy v 3 'a] 3
		--assert v = [a a a]


	--test-- "blk-part-10"
		v: none
		--assert not parse/part input [copy v 3 skip] skip input 2
		--assert none? v

	--test-- "blk-part-21"
		v: none
		--assert parse/part input [copy v 3 skip] skip input 3
		--assert v = [h 5 #"l"]

	--test-- "blk-part-22"
		v: none
		--assert not parse/part input [copy v 3 skip] skip input 4
		--assert v = [h 5 #"l"]

	--test-- "blk-part-23"
		v: none
		--assert parse/part input [copy v 3 skip skip] skip input 4
		--assert v = [h 5 #"l"]

	--test-- "blk-part-24"
		v: none
		--assert parse/part next input [copy v 3 skip] skip input 4
		--assert v = [5 #"l" "l"]

	--test-- "blk-part-25"
		v: none
		--assert not parse/part input [copy v to 'o skip] skip input 3
		--assert none? v

	--test-- "blk-part-26"
		v: none
		--assert parse/part input [copy v to 'o skip] skip input 5
		--assert v = [h 5 #"l" "l"]

	--test-- "blk-part-27"
		v: none
		--assert not parse/part input2 [copy v 3 'a] skip input2 2
		--assert none? v

	--test-- "blk-part-28"
		v: none
		--assert parse/part input2 [copy v 3 'a] skip input2 3
		--assert v = [a a a]

===end-group===

===start-group=== "block-bugs"

	--test-- "#562" 	--assert not parse 	[+] 		[any ['+ if (no)]]
	--test-- "#564-1"	--assert not parse  [a] 		[0 skip]
	--test-- "#564-2"	--assert parse 		[a] 		[0 skip 'a]

	--test-- "#564-3"
		z: none
		--assert not parse 	[a] [copy z 0 skip]
		--assert z = []

	--test-- "blk-integer-bug" parse 		[1 2]		[1 2 integer!]

	--test-- "#566"
		b: next [0 9]
		--assert parse [1 [2]] [collect into b [keep integer! keep block!]]
		--assert b = [1 [2] 9]
		--assert [0 1 [2] 9] = head b

	--test-- "#565"
		b: []
		--assert parse [1] [collect into b [collect [keep integer!]]]
		--assert b = [[1]]
		--assert [[1]] = head b

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

	--test-- "str-ext40"
		res: parse "" [collect []]
		--assert res = []

	--test-- "str-ext41"
		res: parse "1" [collect []]
		--assert res = []

	--test-- "str-ext42"
		res: parse "1" [collect [keep skip]]
		--assert res = [#"1"]

	--test-- "str-ext43"
		digit: charset "0123456789"
		res: parse "123" [collect [some [keep digit]]]
		--assert res = [#"1" #"2" #"3"]

	--test-- "str-ext44"
		res: parse "123" [collect [some [keep [copy v digit if (even? load v)] | skip]]]
		--assert res = [#"2"]

	--test-- "str-ext45"
		res: parse "123" [collect [some [copy d digit keep (load d)]]]
		--assert res = [1 2 3]

	--test-- "str-ext46"
		a: none
		--assert parse "" [collect set a []]
		--assert a = []

	--test-- "str-ext47"
		a: none
		--assert parse "1" [collect set a [keep skip]]
		--assert a = [#"1"]

	--test-- "str-ext49"
		a: []
		--assert parse "" [collect into a []]
		--assert a = []

	--test-- "str-ext50"
		a: []
		--assert parse "1" [collect into a [keep skip]]
		--assert a = [#"1"]
		--assert [#"1"] = head a

	--test-- "str-ext51"
		res: parse "aabbb" [collect [keep some "a" keep some #"b"]]
		--assert res = ["aa" "bbb"]

	--test-- "str-ext52"
		alpha: charset [#"a" - #"z"]
		res: parse "abc|def" [collect [any [keep some alpha | skip]]]
		--assert res = ["abc" "def"]
		
	--test-- "str-ext53 - issue #1093"
		se53-copied: copy ""
		--assert parse "abcde" ["xyz" | copy s to end (se53-copied: :s)]
		--assert "abcde" = se53-copied

		
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

===start-group=== "string-casing"

	--test-- "str-c1"	--assert parse 			"a"			["A"]
	--test-- "str-c2"	--assert parse 			"a"			[#"A"]
	--test-- "str-c3"	--assert not parse/case	"a"			["A"]
	--test-- "str-c4"	--assert not parse/case "a"			[#"A"]
	--test-- "str-c5"	--assert parse/case		"a"			["a"]
	--test-- "str-c6"	--assert parse/case 	"a"			[#"a"]
	--test-- "str-c7"	--assert parse/case		"A"			["A"]
	--test-- "str-c8"	--assert parse/case 	"A"			[#"A"]
	--test-- "str-c9"	--assert parse 		 	"TeSt"		["test"]
	--test-- "str-c10"	--assert not parse/case	"TeSt"		["test"]
	--test-- "str-c11"	--assert parse/case		"TeSt"		["TeSt"]

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
	--test-- "str-bs20" 	--assert not parse 		"abc" 		[some bs]
	--test-- "str-bs21" 	--assert parse 			"ABC" 		[some bs]
	--test-- "str-bs22" 	--assert not parse 		"123" 		[some bs]
	--test-- "str-bs23"		--assert parse 			"789" 		[some bs]
	--test-- "str-bs24" 	--assert not parse 		"abc" 		[bs bs bs]
	--test-- "str-bs25" 	--assert parse			"ABC" 		[bs bs bs]
	--test-- "str-bs26" 	--assert not parse 		"123" 		[bs bs bs]
	--test-- "str-bs27" 	--assert parse 			"789" 		[bs bs bs]


	--test-- "str-bs30"
		digit: charset "0123456789"
		--assert parse "hello 123" [to digit p: 3 skip]
		--assert p = "123"


===end-group===

===start-group=== "string-modify"
	ws: charset " ^- ^/^M"
	not-ws: complement ws

	--test-- "str-rem1"	--assert error? try [parse "" [remove]]
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
		--assert parse s: " t e s t " [any [remove ws | skip]]
		--assert s = "test"

	--test-- "str-rem8"
		--assert parse s: " t e s t " [while [remove ws | skip]]
		--assert s = "test"

	--test-- "str-rem9"
		str: "hello 123 world"
		digit: charset "0123456789"
		--assert parse str [any [remove [some digit #" "] | skip]]
		--assert str = "hello world"

	--test-- "str-ins1"	
		--assert parse str: "" [insert #"1"]
		--assert str = "1"

	--test-- "str-ins2"	
		--assert parse str: "aa" [skip insert #"b" skip]
		--assert str = "aba"

	--test-- "str-ins3"	
		--assert parse str: "" [p: insert #"a" :p remove #"a"]
		--assert str = ""

	--test-- "str-ins4"
		--assert parse str: "test" [some [skip p: insert #"_"] :p remove skip]
		--assert str = "t_e_s_t"

	--test-- "str-chg1"
		--assert parse str: "1" [change skip #"a"]
		--assert str = "a"

	--test-- "str-chg2"
		--assert parse str: "123" [change [3 skip] #"a"]
		--assert str = "a"

	--test-- "str-chg3"
		alpha: charset [#"a" - #"z"]
		--assert parse str: "1a2b3" [some [change alpha dot | skip]]
		--assert str = "1.2.3"

	--test-- "str-chg4"
		--assert parse str: "123" [change 3 skip (99)]
		--assert str = "99"

	--test-- "str-chg5"
		--assert parse str: "test" [some [change #"t" #"o" | skip]]
		--assert str = "oeso"

	--test-- "str-chg6"
		--assert parse str: "12abc34" [some [to alpha change [some alpha] "zzzz"] 2 skip]
		--assert str = "12zzzz34"

	--test-- "str-chg11"
		--assert parse str: "1" [b: skip change b #"a"]
		--assert str = "a"

	--test-- "str-chg12"
		--assert parse str: "123" [b: 3 skip change b #"a"]
		--assert str = "a"

	--test-- "str-chg13"
		alpha: charset [#"a" - #"z"]
		--assert parse str: "1a2b3" [some [b: alpha change b dot | skip]]
		--assert str = "1.2.3"

	--test-- "str-chg14"
		--assert parse str: "123" [b: 3 skip change b (99)]
		--assert str = "99"

	--test-- "str-chg15"
		--assert parse str: "test" [some [b: #"t" change b #"o" | skip]]
		--assert str = "oeso"

	--test-- "str-chg16"
		--assert parse str: "12abc34" [some [to alpha b: some alpha change b "zzzz"] 2 skip]
		--assert str = "12zzzz34"

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

	--test-- "str-m130"	--assert error? try [parse "" [ahead]]
	--test-- "str-m131"	--assert parse		"a"			[ahead #"a" #"a"]
	--test-- "str-m132"	--assert parse		"1"			[ahead [#"a" | #"1"] skip]

===end-group===

===start-group=== "string-part"
	input: "hello"
	input2: "aaabb"
	letters: charset [#"a" - #"o"]

	--test-- "str-part-1"
		v: none
		--assert not parse/part input [copy v 3 skip] 2
		--assert none? v

	--test-- "str-part-2"
		v: none
		--assert parse/part input [copy v 3 skip] 3
		--assert v = "hel"

	--test-- "str-part-3"
		v: none
		--assert not parse/part input [copy v 3 skip] 4
		--assert v = "hel"

	--test-- "str-part-4"
		v: none
		--assert parse/part input [copy v 3 skip skip] 4
		--assert v = "hel"

	--test-- "str-part-5"
		v: none
		--assert parse/part next input [copy v 3 skip] 3
		--assert v = "ell"

	--test-- "str-part-6"
		v: none
		--assert not parse/part input [copy v to #"o" skip] 3
		--assert none? v

	--test-- "str-part-7"
		v: none
		--assert parse/part input [copy v to #"o" skip] 5
		--assert v = "hell"

	--test-- "str-part-8"
		v: none
		--assert not parse/part input [copy v 3 letters] 2
		--assert none? v

	--test-- "str-part-9"
		v: none
		--assert parse/part input [copy v 3 letters] 3
		--assert v = "hel"

	--test-- "str-part-10"
		v: none
		--assert not parse/part input2 [copy v 3 #"a"] 2
		--assert none? v

	--test-- "str-part-11"
		v: none
		--assert parse/part input2 [copy v 3 #"a"] 3
		--assert v = "aaa"


	--test-- "str-part-20"
		v: none
		--assert not parse/part input [copy v 3 skip] skip input 2
		--assert none? v

	--test-- "str-part-21"
		v: none
		--assert parse/part input [copy v 3 skip] skip input 3
		--assert v = "hel"

	--test-- "str-part-22"
		v: none
		--assert not parse/part input [copy v 3 skip] skip input 4
		--assert v = "hel"

	--test-- "str-part-23"
		v: none
		--assert parse/part input [copy v 3 skip skip] skip input 4
		--assert v = "hel"

	--test-- "str-part-24"
		v: none
		--assert parse/part next input [copy v 3 skip] skip input 4
		--assert v = "ell"

	--test-- "str-part-25"
		v: none
		--assert not parse/part input [copy v to #"o" skip] skip input 3
		--assert none? v

	--test-- "str-part-26"
		v: none
		--assert parse/part input [copy v to #"o" skip] skip input 5
		--assert v = "hell"

	--test-- "str-part-27"
		v: none
		--assert not parse/part input [copy v 3 letters] skip input 2
		--assert none? v

	--test-- "str-part-28"
		v: none
		--assert parse/part input [copy v 3 letters] skip input 3
		--assert v = "hel"

	--test-- "str-part-29"
		v: none
		--assert not parse/part input2 [copy v 3 #"a"] skip input2 2
		--assert none? v

	--test-- "str-part-30"
		v: none
		--assert parse/part input2 [copy v 3 #"a"] skip input2 3
		--assert v = "aaa"

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

	--test-- "str-cplx2"
		html: {
			<html>
				<head><title>Test</title></head>
				<body><div><u>Hello</u> <b>World</b></div></body>
			</html>
		}	
		ws: charset " ^- ^/^M"
		res: parse html rule: [
			collect [any [
				ws
				| "</" thru ">" break
				| "<" copy name to ">" skip keep (load name) opt rule
				| copy str to "<" keep (str)
			]]
		]
		--assert res = [html [head [title ["Test"]] body [div [u ["Hello"] b ["World"]]]]]

	--test-- "str-cplx3"
		foo: func [value][value]
		res: parse [a 3 4 t [t 9] "test" 8][
			collect [
				any [
					keep integer!
					| p: block! :p into [
						collect [any [keep integer! keep ('+) | skip keep (foo '-)]]
					] 
					| skip
				]
			]
		]
		--assert res = [3 4 [- 9 +] 8]


	--test-- "str-cplx4"
		;-- test taken from http://www.rebol.net/wiki/Parse_Project#AND
		nanb: [#"a" opt nanb #"b"]
 		nbnc: [#"b" opt nbnc #"c"]
		nanbnc: [ahead [nanb #"c"] some #"a" nbnc]

		--assert parse 		"abc" 		nanbnc
		--assert parse 		"aabbcc" 	nanbnc
		--assert parse 		"aaabbbccc" nanbnc
		--assert not parse 	"abbc" 		nanbnc
		--assert not parse 	"abcc" 		nanbnc
		--assert not parse 	"aabbc"		nanbnc

	--test-- "str-cplx5"
		split: function [series [string!] dlm [string! char!] /local value][
		  rule: complement charset dlm
		  parse series [collect [any [keep copy value some rule | skip]]]
		]
		--assert ["Hello" "bright" "world!"]  = split "Hello bright world!" space
		--assert ["Hell" "bright" "w" "rld!"] = split "Hello bright world!" " o"

===end-group===

===start-group=== "string-bugs"

	--test-- "#562" 	--assert not parse 	"+"			[any [#"+" if (no)]]
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

	--test-- "#567"
		res: parse "12" [collect [keep copy value 2 skip]]
		--assert res = ["12"]

	--test-- "#569"
		size: 1
		res: parse "1" [collect [keep copy value size skip]]
		--assert res = ["1"]
		size: 2
		res: parse "12" [collect [keep copy value size skip]]
		--assert res = ["12"]
		
	--test-- "#678"
		--assert parse "cat" [1 "cat"]
		--assert not parse "cat" [2 "cat"]
		--assert not parse "cat" [3 "cat"]
		--assert not parse "cat" [4 "cat"]
		--assert parse "catcat" [2 "cat"]
		--assert parse "catcatcat" [3 "cat"]
		--assert parse "catcatcatcat" [4 "cat"]
		
	--test-- "#748"
		txt: "Hello world"
		parse txt [ while any [ remove "l" | skip ] ]
		--assert txt = "Heo word"
		--assert 8 = length? txt

===end-group===

===start-group=== "binary"

	--test-- "bin-1" 	--assert parse		#{}			[]
	--test-- "bin-2" 	--assert parse		#{0A}		[#{0A}]
	--test-- "bin-3" 	--assert parse		#{0A}		[#"^(0A)"]
	--test-- "bin-4" 	--assert not parse	#{0A}		[#{0B}]
	--test-- "bin-5" 	--assert parse		#{0A0B}		[#{0A} #{0B}]
	--test-- "bin-6" 	--assert parse		#{0A0B}		[#{0A0B}]
	--test-- "bin-7" 	--assert parse		#{0A}		[[#{0A}]]
	--test-- "bin-8" 	--assert parse		#{0A0B}		[[#{0A}] #{0B}]
	--test-- "bin-9" 	--assert parse		#{0A0B}		[#{0A} [#{0B}]]
	--test-- "bin-10"	--assert parse		#{0A0B}		[[#{0A}][#{0B}]]

	--test-- "bin-11"	--assert parse		#{0A}		[#{0B} | #{0A}]
	--test-- "bin-12"	--assert not parse	#{0A0B}		[#{0B} | #{0A}]
	--test-- "bin-13"	--assert parse		#{0A}		[[#{0B} | #{0A}]]
	--test-- "bin-14"	--assert not parse	#{0A0B}		[[#{0B} | #{0A}]]
	--test-- "bin-15"	--assert parse		#{0A0B}		[[#{0A} | #{0B}][#{0B} | #{0A}]]
		
	
	--test-- "bin-20"
		res: 0	
		--assert parse #{} [(res: 1)]
		--assert res = 1
		
	--test-- "bin-21"
		res: 0	
		--assert parse #{0A} [#{0A} (res: 1)]
		--assert res = 1
		
	--test-- "bin-22"
		res: 0	
		--assert not parse #{0A} [#{0B} (res: 1)]
		--assert res = 0
		
	--test-- "bin-23"
		res: 0	
		--assert parse #{} [[(res: 1)]]
		--assert res = 1

	--test-- "bin-24"
		res: 0	
		--assert parse #{0A} [[#{0A} (res: 1)]]
		--assert res = 1

	--test-- "bin-25"
		res: 0	
		--assert not parse #{0A} [[#{0B} (res: 1)]]
		--assert res = 0
		
	--test-- "bin-26"
		res: 0	
		--assert parse #{0A0B} [#{0A} (res: 1) [#"^(0C)" (res: 2) | #{0B} (res: 3)]]
		--assert res = 3
		
	--test-- "bin-27"
		res: 0	
		--assert not parse #{0A0B} [#{0A} (res: 1) [#{0C} (res: 2) | #{0D} (res: 3)]]
		--assert res = 1

	--test-- "bin-28"	--assert not parse		#{0A0A}		[1 [#{0A}]]
	--test-- "bin-29"	--assert parse			#{0A0A}		[2 [#{0A}]]
	--test-- "bin-30"	--assert not parse		#{0A0A}		[3 [#{0A}]]
	--test-- "bin-31"	--assert not parse		#{0A0A}		[1 1 [#{0A}]]
	--test-- "bin-32"	--assert parse			#{0A0A}		[1 2 [#{0A}]]
	--test-- "bin-33"	--assert parse			#{0A0A}		[2 2 [#{0A}]]
	--test-- "bin-34"	--assert parse			#{0A0A}		[2 3 [#{0A}]]
	--test-- "bin-35"	--assert not parse		#{0A0A}		[3 4 [#{0A}]]
   
	--test-- "bin-36"	--assert not parse		#{0A0A}		[1 #{0A}]
	--test-- "bin-37"	--assert parse			#{0A0A}		[2 #{0A}]
	--test-- "bin-38"	--assert not parse		#{0A0A}		[3 #{0A}]
	--test-- "bin-39"	--assert not parse		#{0A0A}		[1 1 #{0A}]
	--test-- "bin-40"	--assert parse			#{0A0A}		[1 2 #{0A}]
	--test-- "bin-41"	--assert parse			#{0A0A}		[2 2 #{0A}]
	--test-- "bin-42"	--assert parse			#{0A0A}		[2 3 #{0A}]
	--test-- "bin-43"	--assert not parse		#{0A0A}		[3 4 #{0A}]

	--test-- "bin-44"	--assert not parse		#{0A0A}		[1 skip]
	--test-- "bin-45"	--assert parse			#{0A0A}		[2 skip]
	--test-- "bin-46"	--assert not parse		#{0A0A}		[3 skip]
	--test-- "bin-47"	--assert not parse		#{0A0A}		[1 1 skip]
	--test-- "bin-48"	--assert parse			#{0A0A}		[1 2 skip]
	--test-- "bin-49"	--assert parse			#{0A0A}		[2 2 skip]
	--test-- "bin-50"	--assert parse			#{0A0A}		[2 3 skip]
	--test-- "bin-51"	--assert not parse		#{0A0A}		[3 4 skip]
   
	--test-- "bin-52"	--assert parse			#{0A}		[skip]
	--test-- "bin-53"	--assert parse			#{0A0B}		[skip skip]
	--test-- "bin-54"	--assert parse			#{0A0B}		[skip [skip]]
	--test-- "bin-55"	--assert parse			#{0A0B}		[[skip] [skip]]
   
	--test-- "bin-56"	--assert parse			#{0A0A}		[some [#{0A}]]
	--test-- "bin-57"	--assert not parse		#{0A0A}		[some [#{0A}] #{0B}]
	
	--test-- "bin-58"	--assert parse			#{0A0A0B0A0B0B0B0A} [some [skip]]
	--test-- "bin-59"	--assert parse			#{0A0A0B0A0B0B0B0A} [some [#{0A} | #{0B}]]
	--test-- "bin-60"	--assert not parse		#{0A0A0B0A0B0B0B0A} [some [#{0A} | #"^(0C)"]]
   
	--test-- "bin-61"	--assert parse			#{0A0A}		[any [#{0A}]]
	--test-- "bin-62"	--assert parse			#{0A0A}		[some [#{0A}] any [#{0B}]]
	--test-- "bin-63"	--assert parse			#{0A0A0B0B}	[2 #{0A} 2 #{0B}]
	--test-- "bin-64"	--assert not parse		#{0A0A0B0B}	[2 #{0A} 3 #{0B}]
	--test-- "bin-65"	--assert parse			#{0A0A0B0B}	[some #{0A} some #{0B}]
	--test-- "bin-66"	--assert not parse		#{0A0A0B0B}	[some #{0A} some #"^(0C)"]

	--test-- "bin-67"
		p: none
		--assert parse #{} [p:]
		--assert tail? p
	
	--test-- "bin-68"
		p: none
		--assert parse #{} [[[p:]]]
		--assert tail? p

		
	--test-- "bin-69"
		p: none
		--assert parse #{0A} [p: #{0A}]
		--assert p = #{0A}
		
	--test-- "bin-70"
		p: none
		--assert parse #{0A} [#{0A} p:]
		--assert tail? p
		
	--test-- "bin-71"
		p: none
		--assert parse #{0A} [#{0A} [p:]]
		--assert tail? p
		
	--test-- "bin-72"
		p: none
		--assert not parse #{0A0B} [#{0A} p:]
		--assert p = #{0B}
	
	--test-- "bin-73"
		p: none
		--assert parse #{0A0B} [#{0A} [p:][#{0B} | #"^(0C)"]]
		--assert p = #{0B}
		
	--test-- "bin-74"
		p: none
		--assert parse #{0A0A0A0B0B} [3 #{0A} p: 2 #{0B} :p [2 #{0B}]]
		--assert p = #{0B0B}
	
	--test-- "bin-75"
	--assert parse #{0B0A0A0A0C} [skip some [#{0A}] #"^(0C)"]
	
===end-group===

===start-group=== "binary-end"

	--test-- "bin-end-1" --assert parse 		#{0A} 	 [#{0A} end]
	--test-- "bin-end-2" --assert not parse 	#{0A0B}  [#{0A} end]
	--test-- "bin-end-3" --assert parse 		#{0A} 	 [skip end]
	--test-- "bin-end-4" --assert not parse 	#{0A0B}	 [skip end]
	--test-- "bin-end-5" --assert parse 		#{}		 [end]
	
	--test-- "bin-end-6"
		be6: 0
		--assert parse #{} [end (be6: 1)]
		--assert be6 = 1

===end-group===

===start-group=== "binary-words"
	
	wa: [#{0A}]
	wb: [#{0B}]
	wca: #{0A}
	wcb: #{0B}
	wra: [wa]
	wrb: [wb]
	wh: #{88031100}
	wrab: [#{0A} | #{0B}]
	wrba: [#{0B} | #{0A}]
	
	--test-- "bin-w1" 	--assert parse 		#{0A}		[wa]
	--test-- "bin-w2" 	--assert not parse 	#{0A}		[wb]
	--test-- "bin-w3" 	--assert parse 		#{0A0B}		[wa wb]
	--test-- "bin-w5" 	--assert parse 		#{0A}		[wra]
	--test-- "bin-w6" 	--assert parse 		#{0A0B}		[wra #{0B}]
	--test-- "bin-w7" 	--assert parse 		#{0A0B}		[#{0A} wrb]
	--test-- "bin-w8" 	--assert parse 		#{0A0B}		[wra wrb]
	--test-- "bin-w9" 	--assert parse 		#{88031100}	[wh]

	--test-- "bin-w10"	--assert parse 		#{0A} 		[wcb | wca]
	--test-- "bin-w11"	--assert not parse 	#{0A0B}		[wb | wa]
	--test-- "bin-w12"	--assert parse 		#{0A}		[[wcb | wca]]
	--test-- "bin-w13"	--assert not parse 	#{0A0B}		[wrba]
	--test-- "bin-w14"	--assert parse 		#{0A0B}		[wrab wrba]
	
	--test-- "bin-w19"
		res: 0	
		--assert parse #{0A} [wa (res: 1)]
		--assert res = 1
		
	--test-- "bin-w20"
		res: 0	
		--assert not parse #{0A} [wb (res: 1)]
		--assert res = 0
		
	--test-- "bin-w21"
		res: 0	
		wres: [(res: 1)]
		--assert parse #{} [wres]
		--assert res = 1

	--test-- "bin-w22"
		res: 0
		wres: [#{0A} (res: 1)]
		--assert parse #{0A} [wres]
		--assert res = 1

	--test-- "bin-w23"
		res: 0
		wres: [#{0B} (res: 1)]
		--assert not parse #{0A} [wres]
		--assert res = 0

===end-group===

===start-group=== "binary-extraction"

	wa: [#{0A}]
	--test-- "bin-ext1" 
		res: 0
		--assert parse #{0A} [copy res skip]
		--assert res = #{0A}
	
	--test-- "bin-ext2" 
		res: 0
		--assert parse #{0A} [copy res #{0A}]
		--assert res = #{0A}
		
	--test-- "bin-ext4" 
		res:  0
		res2: 0
		--assert parse #{0A} [copy res copy res2 #{0A}]
		--assert res  = #{0A}
		--assert res2 = #{0A}
		
	--test-- "bin-ext5" 
		res: 0
		--assert parse #{0A0A} [copy res 2 #{0A}]
		--assert res = #{0A0A}

	--test-- "bin-ext6" 
		res: 0
		--assert not parse #{0A0A} [copy res 3 #{0A}]
		--assert res = 0
		
	--test-- "bin-ext7" 
		res: 0
		--assert parse #{0A} [copy res [#{0A}]]
		--assert res = #{0A}

	--test-- "bin-ext8" 
		res: 0
		--assert parse #{0A} [copy res wa]
		--assert res = #{0A}
	
	--test-- "bin-ext9" 
		res: 0
		--assert parse #{0A0A} [copy res 2 wa]
		--assert res = #{0A0A}
	
	--test-- "bin-ext10" 
		res: 0
		--assert parse #{0A0A0B} [skip copy res #{0A} skip]
		--assert res = #{0A}
 
	--test-- "bin-ext11" 
		res: 0
		--assert parse #{0A0A0B} [skip copy res [#{0A} | #{0B}] skip]
		--assert res = #{0A}
		
	--test-- "bin-ext12" 
		res: 0
		--assert not parse #{0A} [copy res [#"^(0C)" | #{0B}]]
		--assert res = 0
		
	--test-- "bin-ext13" 
		res: 0
		--assert parse #{0A} [set res skip]
		--assert res = 10

	--test-- "bin-ext14" 
		res: 0
		--assert parse #{0A} [set res #{0A}]
		--assert res = 10

	--test-- "bin-ext16" 
		res:  0
		res2: 0
		--assert parse #{0A} [set res set res2 #{0A}]
		--assert res  = 10
		--assert res2 = 10

	--test-- "bin-ext17" 
		res: 0
		--assert parse #{0A0A} [set res 2 #{0A}]
		--assert res = 10

	--test-- "bin-ext18" 
		res: 0
		--assert not parse #{0A0A} [set res 3 #{0A}]
		--assert res = 0

	--test-- "bin-ext19" 
		res: 0
		--assert parse #{0A} [set res [#{0A}]]
		--assert res = 10

	--test-- "bin-ext20" 
		res: 0
		--assert parse #{0A} [set res wa]
		--assert res = 10

	--test-- "bin-ext21" 
		res: 0
		--assert parse #{0A0A} [set res 2 wa]
		--assert res = 10

	--test-- "bin-ext22" 
		res: 0
		--assert parse #{0A0A0B} [skip set res #{0A} skip]
		--assert res = 10

	--test-- "bin-ext23" 
		res: 0
		--assert parse #{0A0A0B} [skip set res [#{0A} | #{0B}] skip]
		--assert res = 10

	--test-- "bin-ext24" 
		res: 0
		--assert not parse #{0A} [set res [#"^(0C)" | #{0B}]]
		--assert res = 0
		
	--test-- "bin-ext25" 
		res: 0
		--assert parse #{0B0A0A0A0C} [skip set res some #{0A} #"^(0C)"]
		--assert res = 10

	--test-- "bin-ext26" 
		res: 0
		--assert parse #{0B0A0A0A0C} [skip set res some wa #"^(0C)"]
		--assert res = 10

	--test-- "bin-ext40"
		res: parse #{} [collect []]
		--assert res = []

	--test-- "bin-ext41"
		res: parse #{01} [collect []]
		--assert res = []

	--test-- "bin-ext42"
		res: parse #{01} [collect [keep skip]]
		--assert res = [1]

	--test-- "bin-ext43"
		digit: charset [0 - 9]
		res: parse #{010203} [collect [some [keep digit]]]
		--assert res = [1 2 3]

	--test-- "bin-ext44"
		res: parse #{010203} [collect [some [keep [copy v digit if (even? first v)] | skip]]]
		--assert res = [2]

	--test-- "bin-ext45"
		res: parse #{010203} [collect [some [copy d digit keep (1 + first d)]]]
		--assert res = [2 3 4]

	--test-- "bin-ext46"
		a: none
		--assert parse #{} [collect set a []]
		--assert a = []

	--test-- "bin-ext47"
		a: none
		--assert parse #{01} [collect set a [keep skip]]
		--assert a = [1]

	--test-- "bin-ext49"
		a: []
		--assert parse #{} [collect into a []]
		--assert a = []

	--test-- "bin-ext50"
		a: []
		--assert parse #{01} [collect into a [keep skip]]
		--assert a = [1]
		--assert [1] = head a

	--test-- "bin-ext51"
		res: parse #{0A0A0B0B0B} [collect [keep some #{0A} keep some #{0B}]]
		--assert res = [#{0A0A} #{0B0B0B}]

	--test-- "bin-ext52"
		digit: charset [0 - 9]
		res: parse #{01020311040506} [collect [any [keep some digit | skip]]]
		--assert res = [#{010203} #{040506}]
		
	--test-- "bin-ext53 - issue #1093"
		se53-copied: copy #{}
		--assert parse #{0102030405} [#{AABBCC} | copy s to end (se53-copied: :s)]
		--assert #{0102030405} = se53-copied

		
===end-group===

===start-group=== "binary-skipping"

	bin: #{0BAD00CAFE00BABE00DEADBEEF00}
	wa: [#{0A}]
	
	--test-- "bin-sk1" 	--assert parse		#{}			[to end]
	--test-- "bin-sk2" 	--assert parse		#{}			[thru end]
	--test-- "bin-sk3" 	--assert parse		#{0A}		[to end]
	--test-- "bin-sk4" 	--assert not parse	#{0A}		[to #{0A}]
	--test-- "bin-sk5" 	--assert not parse	#{0A}		[to #{0A} end]
	--test-- "bin-sk6" 	--assert parse		#{0A}		[to #{0A} skip]
	--test-- "bin-sk7" 	--assert parse		#{0A}		[thru #{0A}]
	--test-- "bin-sk8" 	--assert parse		#{0A}		[thru #{0A} end]
	--test-- "bin-sk9" 	--assert not parse	#{0A}		[thru #{0A}skip]
	--test-- "bin-sk10"	--assert parse		#{0A0B}		[to #{0A} 2 skip]
	--test-- "bin-sk11"	--assert parse		#{0A0B}		[thru #{0A} skip]
	--test-- "bin-sk12"	--assert parse		#{0A0A0A0B}	[to #{0A} to end]
	--test-- "bin-sk13"	--assert parse		#{0A0A0B0A}	[skip thru #{0A} 2 skip]
	
	--test-- "bin-sk14"	--assert not parse	#{0A}		[to [#{0A}]]
	--test-- "bin-sk15"	--assert not parse	#{0A}		[to [#{0A}] end]
	--test-- "bin-sk16"	--assert parse		#{0A}		[to [#{0A}] skip]
	--test-- "bin-sk17"	--assert parse		#{0A}		[thru [#{0A}]]
	--test-- "bin-sk18"	--assert parse		#{0A}		[thru [#{0A}] end]
	--test-- "bin-sk19"	--assert not parse	#{0A}		[thru [#{0A}] skip]
	--test-- "bin-sk20"	--assert parse		#{0A0B}		[to [#{0A}] 2 skip]
	--test-- "bin-sk21"	--assert parse		#{0A0B}		[thru [#{0A}] skip]
	--test-- "bin-sk22"	--assert parse		#{0A0A0A0B}	[to [#{0A}] to end]
	--test-- "bin-sk23"	--assert parse		#{0A0A0B0A}	[skip thru [#{0A}] 2 skip]
	
	--test-- "bin-sk24"	--assert parse		#{99990A0B0C} [to [#"^(0C)" | #{0B} | #{0A}] 3 skip]
	--test-- "bin-sk25"	--assert parse		#{99990A0B0C} [to [#{0A} | #{0B} | #"^(0C)"] 3 skip]

	--test-- "bin-sk26"	--assert parse		#{99990A0B0C} [thru [#"^(0C)" | #{0B} | #{0A}] 2 skip]
	--test-- "bin-sk27"	--assert parse		#{99990A0B0C} [thru [#{0A} | #{0B} | #"^(0C)"] 2 skip]
	--test-- "bin-sk28"	--assert parse		#{0B0B0A0A0A0C}	[thru 3 #{0A} #"^(0C)"]
	--test-- "bin-sk29"	--assert parse		#{0B0B0A0A0A0C}	[thru 3 #{0A} #{0C}]
	--test-- "bin-sk30"	--assert parse		#{0B0B0A0A0A0C}	[thru 3 wa #"^(0C)"]
	--test-- "bin-sk31"	--assert parse		#{0B0B0A0A0A0C}	[thru [3 #{0A}] #{0C}]
	--test-- "bin-sk32"	--assert parse		#{0B0B0A0A0A0C}	[thru some #{0A} #{0C}]
	--test-- "bin-sk33"	--assert parse		#{0B0B0A0A0A0C}	[thru [some #{0A}] #{0C}]
	--test-- "bin-sk34"	--assert parse		#{0B0B0A0A0A0C}	[thru [some #"x" | #{0A0A0A}] #{0C}]
	
	--test-- "bin-sk35"	--assert parse 		bin 		[thru #{DEADBEEF} skip]

	--test-- "bin-sk36"
		res: 0
		--assert parse bin [thru #{CAFE} skip copy res to #"^(00)" to end]
		--assert res = #{BABE}

	--test-- "bin-sk37"
		res: 0
		--assert parse bin [thru #{BABE} res: to end]
		--assert 9 = index? res 

	--test-- "bin-sk38" --assert not parse	#{}			[to #{0A}]
	--test-- "bin-sk39" --assert not parse	#{}			[to #"^(0A)"]
	--test-- "bin-sk40" --assert not parse	#{}			[to [#{0A}]]
	--test-- "bin-sk41" --assert not parse	#{}			[to [#"^(0A)"]]

	
===end-group===

===start-group=== "binary-bitsets"
	
	bs:	   charset [16 - 31 #"^(0A)" - #"^(0F)"]
	wbs: [bs]
	wbs2: reduce wbs
	--test-- "bin-bs1" 		--assert parse 			#{0A0B0C} [some bs]
	--test-- "bin-bs2" 		--assert not parse 		#{010203} [some bs]
	--test-- "bin-bs4" 		--assert parse 			#{0A0B0C} [some [bs]]
	--test-- "bin-bs5" 		--assert not parse 		#{010203} [some [bs]]
	--test-- "bin-bs6" 		--assert parse 			#{0A0B0C} [some wbs]
	--test-- "bin-bs7" 		--assert not parse 		#{010203} [some wbs]
	--test-- "bin-bs8" 		--assert parse 			#{0A0B0C} [some wbs2]
	--test-- "bin-bs9" 		--assert not parse 		#{010203} [some wbs2]

	--test-- "bin-bs10" 	--assert parse 			#{0A0B0C} [bs bs bs]
	--test-- "bin-bs11" 	--assert not parse 		#{010203} [bs bs bs]
	--test-- "bin-bs12" 	--assert parse 			#{0A0B0C} [[bs] [bs] [bs]]
	--test-- "bin-bs13" 	--assert not parse 		#{010203} [[bs] [bs] [bs]]
	--test-- "bin-bs14" 	--assert parse 			#{0A0B0C} [wbs wbs wbs]
	--test-- "bin-bs15" 	--assert not parse 		#{010203} [wbs wbs wbs]
	--test-- "bin-bs16" 	--assert parse 			#{0A0B0C} [wbs2 wbs2 wbs2]
	--test-- "bin-bs17" 	--assert not parse 		#{010203} [wbs2 wbs2 wbs2]


	bs: charset [not 1 - 3 #"^(0A)" - #"^(0F)"]
	wbs: [bs]
	wbs2: reduce wbs
	--test-- "bin-bs20" 	--assert not parse 		#{0A0B0C} [some bs]
	--test-- "bin-bs22" 	--assert not parse 		#{010203} [some bs]
	--test-- "bin-bs23"		--assert parse 			#{070809} [some bs]
	--test-- "bin-bs24" 	--assert not parse 		#{0A0B0C} [bs bs bs]
	--test-- "bin-bs26" 	--assert not parse 		#{010203} [bs bs bs]
	--test-- "bin-bs27" 	--assert parse 			#{070809} [bs bs bs]


	--test-- "bin-bs30"
		digit: charset [0 - 9]
		--assert parse #{0BADCAFE010203} [to digit p: 3 skip]
		--assert p = #{010203}


===end-group===

===start-group=== "binary-modify"
	ws: charset " ^- ^/^M^(00)"
	not-ws: complement ws

	--test-- "bin-rem1"	--assert error? try [parse #{} [remove]]
	--test-- "bin-rem2"	--assert not parse		#{}	   [remove skip]

	--test-- "bin-rem3"	
		bin: #{0A}
		--assert parse bin [remove skip]
		--assert bin = #{}

	--test-- "bin-rem4"	
		bin: #{0A0B0A}
		--assert parse bin [some [#{0A} | remove #{0B}]]
		--assert bin = #{0A0A}

	--test-- "bin-rem5"	
		bin: #{DEAD00BEEF}
		--assert parse bin [remove thru ws #{BEEF}]
		--assert bin = #{BEEF}

	--test-- "bin-rem6"	
		bin: #{DEAD00BEEF}
		--assert parse bin [remove #{DEAD} skip #{BEEF}]
		--assert bin = #{00BEEF}

	--test-- "bin-rem7"
		--assert parse s: #{00DE00AD00} [any [remove ws | skip]]
		--assert s = #{DEAD}

	--test-- "bin-rem8"
		--assert parse s: #{00DE00AD00} [while [remove ws | skip]]
		--assert s = #{DEAD}

	--test-- "bin-rem9"
		bin: #{DEAD0001020300BEEF}
		digit: charset [1 - 9]
		--assert parse bin [any [remove [some digit #"^(00)"] | skip]]
		--assert bin = #{DEAD00BEEF}

	--test-- "bin-ins1"	
		--assert parse bin: #{} [insert #"^(01)"]
		--assert bin = #{01}

	--test-- "bin-ins2"	
		--assert parse bin: #{0A0A} [skip insert #{0B} skip]
		--assert bin = #{0A0B0A}

	--test-- "bin-ins3"	
		--assert parse bin: #{} [p: insert #{0A} :p remove #{0A}]
		--assert bin = #{}

	--test-- "bin-ins4"
		--assert parse bin: #{DEADBEEF} [some [skip p: insert #"^(00)"] :p remove skip]
		--assert bin = #{DE00AD00BE00EF}

	--test-- "bin-chg1"
		--assert parse bin: #{01} [change skip #{0A}]
		--assert bin = #{0A}

	--test-- "bin-chg2"
		--assert parse bin: #{010203} [change [3 skip] #{0A}]
		--assert bin = #{0A}

	--test-- "bin-chg3"
		digit: charset [1 - 9]
		--assert parse bin: #{010a020b03} [some [change digit #{00} | skip]]
		--assert bin = #{000a000b00}

	--test-- "bin-chg4"
		--assert parse bin: #{010203} [change 3 skip (99)]
		--assert bin = #{63}

	--test-- "bin-chg5"
		--assert parse bin: #{BEADBEEF} [some [change #{BE} #{DE} | skip]]
		--assert bin = #{DEADDEEF}

	--test-- "bin-chg6"
		--assert parse bin: #{0a0b0c03040d0e} [some [to digit change [some digit] #{BEEF}] 2 skip]
		--assert bin = #{0a0b0cBEEF0d0e}

	--test-- "bin-chg11"
		--assert parse bin: #{01} [b: skip change b #{0A}]
		--assert bin = #{0A}

	--test-- "bin-chg12"
		--assert parse bin: #{010203} [b: 3 skip change b #{0A}]
		--assert bin = #{0A}

	--test-- "bin-chg13"
		digit: charset [1 - 9]
		--assert parse bin: #{010a020b03} [some [b: digit change b #{00} | skip]]
		--assert bin = #{000a000b00}

	--test-- "bin-chg14"
		--assert parse bin: #{010203} [b: 3 skip change b (99)]
		--assert bin = #{63}

	--test-- "bin-chg15"
		--assert parse bin: #{BEADBEEF} [some [b: #{BE} change b #{DE} | skip]]
		--assert bin = #{DEADDEEF}

	--test-- "bin-chg16"
		--assert parse bin: #{0a0b0c03040d0e} [some [to digit b: some digit change b #{BEEF}] 2 skip]
		--assert bin = #{0a0b0cBEEF0d0e}

===end-group===

===start-group=== "binary-misc"

	wa: [#{0A}]
	wb: [#{0B}]
	--test-- "bin-m1"	--assert parse 		#{}			[break]
	--test-- "bin-m2"	--assert not parse 	#{0A}		[break]
	--test-- "bin-m3"	--assert parse 		#{0A}		[[break #{0B}] #{0A}]
	--test-- "bin-m4"	--assert parse 		#{0A}		[[#{0B} | break] #{0A}]
	--test-- "bin-m5"	--assert parse 		#{0A0A}		[some [#{0B} | break] 2 #{0A}]
	--test-- "bin-m6"	--assert parse 		#{0A0A}		[some [#{0B} | [break]] 2 #{0A}]
	--test-- "bin-m7"	--assert not parse 	#{0A0A}		[some [#{0B} | 2 [#"^(0C)" | break]] 2 #{0A}]

	--test-- "bin-m20"	--assert not parse 	#{}			[fail]
	--test-- "bin-m21"	--assert not parse 	#{0A}		[#{0A} fail]
	--test-- "bin-m22"	--assert not parse 	#{0A}		[[fail]]
	--test-- "bin-m23"	--assert not parse 	#{0A}		[fail | fail]
	--test-- "bin-m24"	--assert not parse 	#{0A}		[[fail | fail]]
	--test-- "bin-m25"	--assert not parse 	#{0A}		[#{0B} | fail]

	--test-- "bin-m30"	--assert not parse 	#{}			[not end]
	--test-- "bin-m31"	--assert parse 		#{0A}		[not #{0B} #{0A}]
	--test-- "bin-m32"	--assert not parse 	#{0A}		[not skip]
	--test-- "bin-m33"	--assert not parse 	#{0A}		[not skip skip]
	--test-- "bin-m34"	--assert parse 		#{0A}		[not [#{0B}] #{0A}]
	--test-- "bin-m35"	--assert parse 		#{0A}		[not wb #{0A}]
	--test-- "bin-m36"	--assert not parse 	#{0A0A}		[not [#{0A} #{0A}] to end]
	--test-- "bin-m37"	--assert parse 		#{0A0A}		[not [some #{0B}] to end]
	--test-- "bin-m38"	--assert parse 		#{0A0A}		[some [#"^(0C)" | not #{0B}] 2 skip]

	--test-- "bin-m50"	--assert not parse 	#{}			[reject]
	--test-- "bin-m51"	--assert not parse 	#{0A}		[reject #{0A}]
	--test-- "bin-m52"	--assert not parse 	#{0A}		[reject wa]
	--test-- "bin-m53"	--assert not parse 	#{0A}		[[reject] #{0A}]
	--test-- "bin-m54"	--assert parse 		#{0A}		[[reject #{0B}] | #{0A}]
	--test-- "bin-m55"	--assert not parse 	#{0A}		[[#{0B} | reject] #{0A}]
	--test-- "bin-m56"	--assert parse 		#{0A}		[[#{0B} | reject] | #{0A}]
	--test-- "bin-m57"	--assert parse 		#{0A0A}		[some reject | 2 #{0A}]
	--test-- "bin-m58"	--assert parse 		#{0A0A}		[some [reject] | 2 #{0A}]
	
	--test-- "bin-m60"	--assert parse 		#{}			[none]
	--test-- "bin-m61"	--assert parse 		#{0A}		[skip none]
	--test-- "bin-m62"	--assert parse 		#{0A}		[none skip none]
	--test-- "bin-m63"	--assert parse 		#{0A}		[#{0A} none]
	--test-- "bin-m64"	--assert parse 		#{0A}		[none #{0A} none]
	--test-- "bin-m65"	--assert parse 		#{0A}		[wa none]
	--test-- "bin-m66"	--assert parse 		#{0A}		[none wa none]
	--test-- "bin-m67"	--assert parse 		#{0A}		[[#{0B} | none] #{0A}]
	--test-- "bin-m68"	--assert parse 		#{0A}		[[#{0B} | [none]] #{0A}]
	--test-- "bin-m69"	--assert parse 		#{0A}		[[[#{0B} | [none]]] #{0A}]

	--test-- "bin-m80"	--assert parse 		#{}			[opt none]
	--test-- "bin-m81"	--assert parse 		#{}			[opt #{0A}]
	--test-- "bin-m82"	--assert parse 		#{0A}		[opt #{0A}]
	--test-- "bin-m83"	--assert parse 		#{0A}		[opt #{0B} #{0A}]
	--test-- "bin-m84"	--assert parse 		#{0A}		[opt [#{0A}]]
	--test-- "bin-m85"	--assert parse 		#{0A}		[opt wa]
	--test-- "bin-m86"	--assert parse 		#{0A}		[opt skip]
	--test-- "bin-m87"	--assert parse 		#{0A0B0C}	[skip opt #{0B} skip]

	--test-- "bin-m90"	--assert not parse	#{}			[then skip]
	--test-- "blk-m91"	--assert parse		#{}			[then skip | end]
	--test-- "bin-m92"	--assert parse		#{0A}		[then #{0A} | #{0B}]
	--test-- "bin-m93"	--assert not parse	#{0c}		[then #{0A} | #{0B}]
	--test-- "bin-m94"	--assert parse		#{0B}		[then #{0A} | #{0B}]
	--test-- "bin-m95"	--assert parse		#{0F0a}		[#"^(0F)" then #{0A} | #{0B}]

	x: none
	--test-- "bin-m100"	--assert parse		#{020406}	[any [copy x skip if (even? first x)]]
	--test-- "bin-m101"	--assert not parse	#{01}		[copy x skip if (even? first x)]
	--test-- "bin-m102"	--assert not parse	#{0105}		[some [copy x skip if (even? first x)]]

	--test-- "bin-m120"	--assert parse		#{}			[while #{0A}]
	--test-- "bin-m121"	--assert parse		#{}			[while #{0B}]
	--test-- "bin-m122"	--assert parse		#{0A}		[while #{0A}]
	--test-- "bin-m123"	--assert not parse	#{0A}		[while #{0B}]
	--test-- "bin-m124"	--assert parse		#{0A}		[while #{0B} skip]
	--test-- "bin-m125"	--assert parse		#{0A0B0A0B}	[while [#{0B} | #{0A}]]

	--test-- "bin-m130"	--assert error? try [parse #{} [ahead]]
	--test-- "bin-m131"	--assert parse		#{0A}		[ahead #{0A} #{0A}]
	--test-- "bin-m132"	--assert parse		#{01}		[ahead [#{0A} | #"^(01)"] skip]

===end-group===

===start-group=== "binary-part"
	input: #{DEADBEEF}
	input2: #{0a0a0a0b0b}
	letters: charset [#"^(AD)" - #"^(DE)"]

	--test-- "bin-part-1"
		v: none
		--assert not parse/part input [copy v 3 skip] 2
		--assert none? v

	--test-- "bin-part-2"
		v: none
		--assert parse/part input [copy v 3 skip] 3
		--assert v = #{DEADBE}

	--test-- "bin-part-3"
		v: none
		--assert not parse/part input [copy v 3 skip] 4
		--assert v = #{DEADBE}

	--test-- "bin-part-4"
		v: none
		--assert parse/part input [copy v 3 skip skip] 4
		--assert v = #{DEADBE}

	--test-- "bin-part-5"
		v: none
		--assert parse/part next input [copy v 3 skip] 3
		--assert v = #{ADBEEF}

	--test-- "bin-part-6"
		v: none
		--assert not parse/part input [copy v to #"o" skip] 3
		--assert none? v

	--test-- "bin-part-7"
		v: none
		--assert parse/part input [copy v to #{EF} skip] 5
		--assert v = #{DEADBE}

	--test-- "bin-part-8"
		v: none
		--assert not parse/part input [copy v 3 letters] 2
		--assert none? v

	--test-- "bin-part-9"
		v: none
		--assert parse/part input [copy v 3 letters] 3
		--assert v = #{DEADBE}

	--test-- "bin-part-10"
		v: none
		--assert not parse/part input2 [copy v 3 #{0A}] 2
		--assert none? v

	--test-- "bin-part-11"
		v: none
		--assert parse/part input2 [copy v 3 #{0A}] 3
		--assert v = #{0a0a0a}

	--test-- "bin-part-20"
		v: none
		--assert not parse/part input [copy v 3 skip] skip input 2
		--assert none? v

	--test-- "bin-part-21"
		v: none
		--assert parse/part input [copy v 3 skip] skip input 3
		--assert v = #{DEADBE}

	--test-- "bin-part-22"
		v: none
		--assert not parse/part input [copy v 3 skip] skip input 4
		--assert v = #{DEADBE}

	--test-- "bin-part-23"
		v: none
		--assert parse/part input [copy v 3 skip skip] skip input 4
		--assert v = #{DEADBE}

	--test-- "bin-part-24"
		v: none
		--assert parse/part next input [copy v 3 skip] skip input 4
		--assert v = #{ADBEEF}

	--test-- "bin-part-25"
		v: none
		--assert not parse/part input [copy v to #"o" skip] skip input 3
		--assert none? v

	--test-- "bin-part-26"
		v: none
		--assert parse/part input [copy v to #{EF} skip] skip input 5
		--assert v = #{DEADBE}

	--test-- "bin-part-27"
		v: none
		--assert not parse/part input [copy v 3 letters] skip input 2
		--assert none? v

	--test-- "bin-part-28"
		v: none
		--assert parse/part input [copy v 3 letters] skip input 3
		--assert v = #{DEADBE}

	--test-- "bin-part-29"
		v: none
		--assert not parse/part input2 [copy v 3 #{0A}] skip input2 2
		--assert none? v

	--test-- "bin-part-30"
		v: none
		--assert parse/part input2 [copy v 3 #{0A}] skip input2 3
		--assert v = #{0a0a0a}

===end-group===

===start-group=== "Issues"

	--test-- "#2515"
		--assert parse "this one is" ["this" to "is" "is"]

	--test-- "#2561"
		--assert [] = parse "" [collect [keep to end]]
		--assert [] = parse "" [collect [keep pick to end]]

===end-group===
    
~~~end-file~~~

