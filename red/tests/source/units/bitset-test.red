Red [
	Title:   "Red local contexts binding test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %bitset-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

~~~start-file~~~ "bitset"

===start-group=== "basic tests"

	--test-- "basic-bitset-1"
		bs: make bitset! [0 1 2 3]
		--assert true = pick bs 0
		--assert true = pick bs 1
		--assert true = pick bs 2
		--assert true = pick bs 3
		--assert false = pick bs 4
		--assert false = pick bs 256
		--assert false = pick bs 257
		--assert false = pick bs 2147483647
		--assert false = pick bs -2147483648

===end-group===

===start-group=== "poke"
	
	--test-- "poke-1"
		bs: make bitset! [0 1 2 3]
		poke bs 4 true
		--assert true = pick bs 0
		--assert true = pick bs 1
		--assert true = pick bs 2
		--assert true = pick bs 3
		--assert true = pick bs 4
		--assert false = pick bs 5

===end-group===

~~~end-file~~~

