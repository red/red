Red [
	Title:   "Red map test script"
	Author:  "Peter W A Wood"
	File: 	 %map-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "map"

===start-group=== "make"
	
	--test-- "map-make-1"
		mm1-m: make map! [a none b 2 c 3]
		--assert 'none = mm1-m/a
		--assert 2 = mm1-m/b
		--assert 3 = mm1-m/c
	
===end-group=== 

===start-group=== "construction"
	
	--test-- "map-construction-1"
		mc1-m: #(a none b 2 c 3)
		--assert 'none = mc1-m/a
		--assert 2 = mc1-m/b
		--assert 3 = mc1-m/c
	
===end-group===

===start-group=== "find"

	--test-- "map-find-1"
		mf1-m: #(a: none b: 1 c: 2)
		--assert true = find mf1-m 'a
		--assert true = find mf1-m 'b
		--assert true = find mf1-m 'c
		--assert none = find mf1-m 'd
		
	--test-- "map-find-2"
		mf2-m: #(a: 1 b: 2 c: 3)
		mf2-m/a: 'none
		mf2-m/b: none
		--assert true = find mf2-m 'a
		--assert none = find mf2-m 'b
		--assert true = find mf2-m 'c

===end-group===

===start-group=== "copy"

	--test-- "map-copy-1"
		mcp1-m: #(a: 1 b: 2)
		mcp1-n: copy mcp1-m
		--assert 1 = mcp1-n/a
		--assert 2 = mcp1-n/a

===end-group===



~~~end-file~~~