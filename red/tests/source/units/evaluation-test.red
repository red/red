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
	
===end-group===


~~~end-file~~~