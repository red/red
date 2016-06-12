Red [
	Title:   "Red evaluation test script"
	Author:  "Nenad Rakocevic"
	File: 	 %evaluation-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "evaluation"

===start-group=== "do"

	--test-- "do-1"
		--assert 123 = do [123]
		
	--test-- "do-2"
		--assert none = do [none]
		
	--test-- "do-3"
		--assert false = do [false]
		
	--test-- "do-4"
		--assert 'z = do ['z]
		
	--test-- "do-5"
		a: 123
		--assert 123 = do [a]
		
	--test-- "do-6"
		--assert 3 = do [1 + 2]
		
	--test-- "do-7"
		--assert 7 = do [1 + 2 3 + 4]
		
	--test-- "do-8"
		--assert 9 = do [1 + length? mold append [1] #"t"]
		
	--test-- "do-9"
		--assert word! = do [type? first [a]]

	--test-- "do/next-1"
		code: [3 4 + 5 length? mold 8 + 9 append copy "hel" form 'lo]
		--assert 3 		 = do/next code 'code
		--assert 9 		 = do/next code 'code
		--assert 2 		 = do/next code 'code
		--assert "hello" = do/next code 'code
		--assert unset? do/next code 'code
		--assert unset? do/next code 'code
		--assert tail? code
		--assert (head code) = [3 4 + 5 length? mold 8 + 9 append copy "hel" form 'lo]
		
===end-group===

===start-group=== "do function"
	
	--test-- "do-func-1"
		df1-f: func[][1]
		--assert 1 = do [df1-f] 
		
	--test-- "do-func-2"
		df2-f: func[i][2 * i]
		--assert 4 = do [df2-f 2]
		
	--test-- "do-func-3"
		df3-f: func[][3]
		--assert 3 = do df3-f
		
	--test-- "do-func-4"
		df4-i: 4
		df4-f: [func[i][df4-i * i] 4]
		--assert 16 = do reduce df4-f
		
	--test-- "do-func-5"
		df5-f: func[i][5 * i]
		--assert 25 = do [df5-f 5]
		
	--test-- "do-func-6"
		df6-i: 6
		df6-f: func[i][df6-i * i]
		--assert 36 = do [df6-f 6]
		
===end-group=== 

===start-group=== "do object"

	--test-- "do-object-1"
		do1-blk: load {
			o: make object! [
				oo: make object! [
					ooo: make object! [
						a: 1
					]
				]
			]
		}
		do do1-blk
		--assert 1 == o/oo/ooo/a

===end-group===

===start-group=== "reduce"

	--test-- "reduce-1"
		--assert [] = reduce []
		
	--test-- "reduce-2"
		--assert [] = do [reduce []]
		
	--test-- "reduce-3"
		--assert [123] = reduce [123]
		
	--test-- "reduce-4"
		--assert none = first reduce [none]
		
	--test-- "reduce-5"
		--assert false = first reduce [false]

	--test-- "reduce-6"
		--assert 'z = first reduce ['z]	
	
	--test-- "reduce-7"
		a: 123
		--assert [123 8 z] = reduce [a 3 + 5 'z]
	
	--test-- "reduce-8"
		blk: [a b c]
		--assert [a b c] = reduce/into [3 + 4 a] blk
		--assert blk = [7 123 a b c]
	
	--test-- "reduce-9"
		a: 123
		--assert [123 8 z] = do [reduce [a 3 + 5 'z]]
	
	--test-- "reduce-10"
		blk: [a b c]
		--assert [a b c] = do [reduce/into [3 + 4 a] blk]
		--assert blk = [7 123 a b c]

	--test-- "reduce-11"
		code: [1 + 3 a 'z append "hell" #"o"]
		--assert [4 123 z "hello"] = reduce code
	
	--test-- "reduce-11"
		code: [1 + 3 a 'z append "hell" #"o"]
		--assert [4 123 z "hello"] = do [reduce code]

	--test-- "reduce-12"
		--assert none = reduce none

	--test-- "reduce-13"
		--assert none = do [reduce none]
		
	--test-- "reduce-14"
		--assert [[]] = reduce [reduce []]
	
	--test-- "reduce-15"
		--assert [3 z] = reduce [
			1 + length? reduce [3 + 4 789] 'z
		]
	
	--test-- "reduce-16"
		--assert [[]] = do [reduce [reduce []]]
	
	--test-- "reduce-17"
		--assert [3 z] = do [
			reduce [
				1 + length? reduce [3 + 4 789] 'z
			]
		]
		
	--test-- "reduce-18"
		a: [3 + 4]
		--assert [7] = reduce a
		--assert [7] = do [reduce a]

	--test-- "reduce-19"
		b: next [1 2]
		--assert [2] = reduce/into [yes 3 4 5] b
		--assert [1 #[true] 3 4 5 2] = head b

	--test-- "reduce-20"
		b: 2
		--assert [2] = head reduce/into b []
		--assert ["a"] = head reduce/into "a" []

===end-group===

===start-group=== "compose"
	
	--test-- "compose-1"
	--assert  [] = compose []
	--assert  [] = compose/deep []
	--assert  [] = compose/deep/only []
	--assert  [] = do [compose []]
	--assert [] = do [compose/deep []]
	--assert [] = do [compose/deep/only []]
	
	--test-- "compose-2"
	--assert [1 [2] "3" a 'b c: :d] = compose [1 [2] "3" a 'b c: :d]
	--assert [1 [2] "3" a 'b c: :d] = do [compose [1 [2] "3" a 'b c: :d]]
	
	--test-- "compose-3"
	--assert [1] = compose [(1)]
	--assert [1] = do [compose [(1)]]
	
	--test-- "compose-4"
	--assert none == first compose [(none)]
	--assert none == first do [compose [(none)]]

	--test-- "compose-5"
	--assert true == first compose [(true)]
	--assert true == first do [compose [(true)]]
	
	--test-- "compose-6"
	--assert [3] = compose [(1 + 2)]
	--assert [3] = do [compose [(1 + 2)]]
	
	--test-- "compose-7"
	--assert [x 9 y] = compose [x (4 + 5) y]
	--assert [x 9 y] = do [compose [x (4 + 5) y]]
	
	--test-- "compose-8"
	--assert [] = compose [([])]
	--assert [] = do [compose [([])]]
	
	--test-- "compose-9"
	--assert [[]] = compose/only [([])]
	--assert [[]] = do [compose/only [([])]]
	
	--test-- "compose-10"
	--assert [1 2 3] = compose [([1 2 3])]
	--assert [1 2 3] = do [compose [([1 2 3])]]
	
	--test-- "compose-11"
	--assert [1 2 3] = compose [([1 2 3])]
	--assert [1 2 3] = do [compose [([1 2 3])]]
	
	--test-- "compose-12"
	--assert [[(5 + 6)]] = compose [[(5 + 6)]]
	--assert [[(5 + 6)]] = do [compose [[(5 + 6)]]]
	
	--test-- "compose-13"
	--assert [[1]] = compose/deep [[(7 - 6)]]
	--assert [[1]] = do [compose/deep [[(7 - 6)]]]
	
	--test-- "compose-14"
	--assert [[]] = compose/deep [[([])]]
	--assert [[]] = do [compose/deep [[([])]]]
	
	--test-- "compose-15"
	--assert [[[]]] = compose/deep/only [[([])]]
	--assert [[[]]] = do [compose/deep/only [[([])]]]
	
	--test-- "compose-16"
	--assert [[8] x [9] y] = compose/deep [[(2 + 6)] x [(4 + 5)] y]
	--assert [[8] x [9] y] = do [compose/deep [[(2 + 6)] x [(4 + 5)] y]]
	
	--test-- "compose-17"
	--assert [a 3 b 789 1 2 3] = compose [a (1 + 2) b () (print "") ([]) 789 ([1 2 3])]
	--assert [a 3 b 789 1 2 3] = compose [a (1 + 2) b () (print "") ([]) 789 ([1 2 3])]

	--test-- "compose-18"
	--assert [a 3 b [] 789 [1 2 3]] = compose/only [a (1 + 2) b () (print "") ([]) 789 ([1 2 3])]
	--assert [a 3 b [] 789 [1 2 3]] = compose/only [a (1 + 2) b () (print "") ([]) 789 ([1 2 3])]
	
	--test-- "compose-19"
	--assert [a [3] 8 b [2 3 [x "hello" x]]] = compose/deep [
		a [(1 + 2)] (9 - 1) b [
			2 3 [x (append "hell" #"o") x]
		]
	]
	--assert [a [3] 8 b [2 3 [x "hello" x]]] = do [		;; refinements not supported yet by DO
		compose/deep [
			a [(1 + 2)] (9 - 1) b [
				2 3 [x (append "hell" #"o") x]
			]
		]
	]

	--test-- "compose-20"
	a: [1 2 3]
	--assert [1 2 3] = compose/into [r (1 + 6)] a
	--assert a = [r 7 1 2 3]
	a: [1 2 3]
	--assert [1 2 3] = do [compose/into [r (1 + 6)] a]
	--assert a = [r 7 1 2 3]
	
	--test-- "compose-21"
	a: [(mold 2 + 3)]
	--assert ["5"] = compose a
	--assert ["5"] = do [compose a]

	--test-- "compose-22"
	b: next [1 2]
	--assert [2] = compose/into [no 7 8 9 (2 * 10) ([5 6])] b
	--assert [1 no 7 8 9 20 5 6 2] = head b

	--test-- "compose-23"
		b: 2
		--assert [2] = head compose/into b []
		--assert ["a"] = head compose/into "a" []

===end-group===

===start-group=== "unset value passing"

	--test-- "unset-1"
		--assert unset! = type? set/any 'xyz ()
		--assert unset! = type? get/any 'xyz
		--assert unset! = type? :xyz

	--test-- "unset-2"
		test-unset: has [zyx][
			--assert unset! = type? set/any 'zyx ()
			--assert unset! = type? get/any 'zyx
			--assert unset! = type? :zyx
		]
		test-unset

===end-group===

===start-group=== "SET tests"

	--test-- "set-1"
		--assert 123 = set 'value 123
		--assert value = 123
		
	--test-- "set-2"
		--assert 456 = set [A B] 456
		--assert a = 456
		--assert b = 456
		
	--test-- "set-3"
		--assert [7 8] = set [A B] [7 8]
		--assert a = 7
		--assert b = 8
		
	--test-- "set-4"
		--assert [4 5] = set/only [A B] [4 5]
		--assert a = [4 5]
		--assert b = [4 5]
		
	--test-- "set-5"
		--assert [4 #[none]] = set [A B] reduce [4 none]
		--assert a = 4
		--assert b = none
		
	--test-- "set-6"
		b: 789
		--assert [4 #[none]] = set/some [A B] reduce [4 none]
		--assert a = 4
		--assert b = 789

	--test-- "set-7"
		obj: object [a: 1 b: 2]
		--assert [4 5] = set obj [4 5]
		--assert obj/a = 4
		--assert obj/b = 5

	--test-- "set-8"
		obj:  object [a: 3 b: 4]
		obj2: object [z: 0 a: 6 b: 7 c: 9]
		--assert obj2 = set obj obj2
		--assert "make object! [a: 6 b: 7]" = mold/flat obj
		--assert "make object! [z: 0 a: 6 b: 7 c: 9]" = mold/flat obj2
		
	--test-- "set-9"
		obj:  object [a: 3 b: 4]
		obj2: object [z: 0]
		--assert obj2 = set/only obj obj2
		--assert obj/a = obj2
		--assert obj/b = obj2
		
	--test-- "set-10"
		obj:  object [a: 3 b: 4]
		obj2: object [z: 0 a: none b: 7]
		--assert obj2 = set obj obj2
		--assert "make object! [a: none b: 7]" = mold/flat obj
		--assert "make object! [z: 0 a: none b: 7]" = mold/flat obj2

	--test-- "set-11"
		obj:  object [a: 3 b: 4]
		obj2: object [z: 0 a: none b: 7]
		--assert obj2 = set/some obj obj2
		--assert "make object! [a: 3 b: 7]" = mold/flat obj
		--assert "make object! [z: 0 a: none b: 7]" = mold/flat obj2
		

===end-group===

~~~end-file~~~