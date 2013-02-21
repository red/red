Red [
	Title:   "Red evaluation natives test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %eval-natives-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

~~~start-file~~~ "eval-natives"

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
		
	--test-- "do-6"
		--assert 7 = do [1 + 2 3 + 4]
		
	--test-- "do-7"
		--assert 9 = do [1 + length? mold append [1] #"t"]
		
	--test-- "do-8"
		--assert word! = do [type? first [a]]
		
===end-group===

;===start-group=== "reduce"

;===end-group===


~~~end-file~~~