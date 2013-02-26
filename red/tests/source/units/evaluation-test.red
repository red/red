Red [
	Title:   "Red evaluation test script"
	Author:  "Nenad Rakocevic"
	File: 	 %evaluation-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

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
		--assert [a b c 7 123] = reduce/into [3 + 4 a] blk
	
	--test-- "reduce-9"
		a: 123
		--assert [123 8 z] = do [reduce [a 3 + 5 'z]]
	
	;--test-- "reduce-10"
	;	blk: [a b c]
	;	--assert [a b c 7 123] = do [reduce/into [3 + 4 a] blk]		;; refinements not supported yet by DO
	
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
	
===end-group===

===start-group=== "compose"
	
	--test-- "compose-1"
	--assert  [] = compose []
	--assert  [] = compose/deep []
	--assert  [] = compose/deep/only []
	--assert  [] = do [compose []]
	;--assert [] = do [compose/deep []]						;; refinements not supported yet by DO
	;--assert [] = do [compose/deep/only []]
	
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
	;--assert [[]] = do [compose/only [([])]]				;; refinements not supported yet by DO
	
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
	;--assert [[1]] = do [compose/deep [[(7 - 6)]]]			;; refinements not supported yet by DO
	
	--test-- "compose-14"
	--assert [[]] = compose/deep [[([])]]
	;--assert [[]] = do [compose/deep [[([])]]]				;; refinements not supported yet by DO
	
	--test-- "compose-15"
	--assert [[[]]] = compose/deep/only [[([])]]
	;--assert [[[]]] = do [compose/deep/only [[([])]]]		;; refinements not supported yet by DO
	
	--test-- "compose-16"
	--assert [[8] x [9] y] = compose/deep [[(2 + 6)] x [(4 + 5)] y]
	;--assert [[8] x [9] y] = do [compose/deep [[(2 + 6)] x [(4 + 5)] y]]		;; refinements not supported yet by DO
	
	--test-- "compose-17"
	--assert [a 3 b 789 1 2 3] = compose [a (1 + 2) b () (print "") ([]) 789 ([1 2 3])]
	;--assert [a 3 b 789 1 2 3] = compose [a (1 + 2) b () (print "") ([]) 789 ([1 2 3])] 	;; refinements not supported yet by DO

	--test-- "compose-18"
	--assert [a 3 b [] 789 [1 2 3]] = compose/only [a (1 + 2) b () (print "") ([]) 789 ([1 2 3])]
	;--assert [a 3 b [] 789 [1 2 3]] = compose/only [a (1 + 2) b () (print "") ([]) 789 ([1 2 3])] 	;; refinements not supported yet by DO
	
	--test-- "compose-19"
	--assert [a [3] 8 b [2 3 [x "hello" x]]] = compose/deep [
		a [(1 + 2)] (9 - 1) b [
			2 3 [x (append "hell" #"o") x]
		]
	]
	;--assert [a [3] 8 b [2 3 [x "hello" x]]] = do [		;; refinements not supported yet by DO
	;	compose/deep [
	;		a [(1 + 2)] (9 - 1) b [
	;			2 3 [x (append "hell" #"o") x]
	;		]
	;	]
	;]

	--test-- "compose-20"
	a: [1 2 3]
	--assert [1 2 3 r 7] = compose/into [r (1 + 6)] a
	;--assert [1 2 3 r 7] = do [compose/into [r (1 + 6)] a] ;; refinements not supported yet by DO
	
	--test-- "compose-21"
	a: [(mold 2 + 3)]
	--assert ["5"] = compose a
	;--assert ["5"] = do [compose a]						;; refinements not supported yet by DO
	
	
===end-group===

~~~end-file~~~