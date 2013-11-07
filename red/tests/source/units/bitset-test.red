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
	
	--test-- "basic-1"	--assert "make bitset! #{00}" = mold make bitset! 1
	--test-- "basic-2"	--assert "make bitset! #{00}" = mold charset ""
	--test-- "basic-3"	--assert "make bitset! #{00}" = mold charset []
	--test-- "basic-4"	--assert "make bitset! #{80}" = mold charset #"^(00)"
	--test-- "basic-5"	--assert "make bitset! #{40}" = mold charset #"^(01)"
	--test-- "basic-6"	--assert "make bitset! #{000000000000FFC0}" = mold charset "0123456789"
	--test-- "basic-7"	--assert "make bitset! #{F0}" = mold charset [0 1 2 3]

	--test-- "basic-8"	
		--assert "make bitset! #{FF800000FFFF8000048900007FFFFFE0}"
			 = mold charset [#"a" - #"z" 0 - 8 32 - #"0" "HELLO"]

	--test-- "basic-9"
		bs: make bitset! [0 1 2 3]
		--assert true  = pick bs 0
		--assert true  = pick bs 1
		--assert true  = pick bs 2
		--assert true  = pick bs 3
		--assert false = pick bs 4
		--assert false = pick bs 256
		--assert false = pick bs 257
		--assert false = pick bs 2147483647
		--assert false = pick bs -2147483648

	--test-- "basic-10"
		bs: make bitset! [0 1 2 3]
		--assert true  = bs/0
		--assert true  = bs/1
		--assert true  = bs/2
		--assert true  = bs/3
		--assert false = bs/4
		--assert false = bs/256
		--assert false = bs/257
		--assert false = bs/2147483647
		--assert false = bs/-2147483648

	--test-- "basic-11"
		bs: make bitset! [0 1 2 3]
		--assert true  = pick bs #"^(00)"
		--assert true  = pick bs #"^(01)"
		--assert true  = pick bs #"^(02)"
		--assert true  = pick bs #"^(03)"
		--assert false = pick bs #"^(04)"
		--assert false = pick bs #"^(0100)"
		--assert false = pick bs #"^(0101)"

	--test-- "basic-12"
		bs: make bitset! [0100h 0102h]
		--assert true  = pick bs 0100h
		--assert false = pick bs 0101h
		--assert true  = pick bs 0102h
		
	--test-- "basic-13"
		bs: make bitset! [255 257]
		--assert true  = pick bs 255
		--assert false = pick bs 256
		--assert true  = pick bs 257
		
	--test-- "basic-14"
		bs: make bitset! [255 256]
		--assert true = pick bs 255
		--assert true = pick bs 256
		
	--test-- "basic-15"
		bs: make bitset! [00010000h]
		--assert true = pick bs 00010000h
	
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

	--test-- "poke-2"
		bs: make bitset! [0 1 2 3]
		--assert true = pick bs 0
		poke bs 0 false
		--assert false = pick bs 0
		poke bs 0 true
		--assert true = pick bs 0
		poke bs 0 none
		--assert false = pick bs 0

===end-group===

~~~end-file~~~

