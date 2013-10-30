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
		bb-1-bs: make bitset! [0 1 2 3]
		--assert true = pick bb-1-bs 1
		--assert true = pick bb-1-bs 2
		--assert true = pick bb-1-bs 3
		--assert true = pick bb-1-bs 4
		--assert false = pick bb-1-bs 5
		--assert false = pick bb-1-bs 256
		--assert false = pick bb-1-bs 257
		--assert false = pick bb-1-bs 2147483647
		--assert false = pick bb-1-bs 2147483648

===end-group===

===start-group=== "poke"
	
	--test "poke-1"
		p-1-bs: make bitset! [0 1 2 3]
		poke p-1-bs 5 true
		--assert true = pick p-1-bs 1
		--assert true = pick p-1-bs 2
		--assert true = pick p-1-bs 3
		--assert true = pick p-1-bs 4
		--assert true = pick p-1-bs 5
		--assert false = pick p-1-bs 6

===end-group===

~~~end-file~~~

