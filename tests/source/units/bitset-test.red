Red [
	Title:   "Red local contexts binding test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %bitset-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

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
			 = mold charset [#"a" - #"z" 0 - 8 32 - 48 "HELLO"]

	--test-- "basic-9"
		bs: make bitset! [0 1 2 3]
		--assert 8 = length? bs
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
		--assert 8 = length? bs
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
		--assert 8 = length? bs
		--assert true  = pick bs #"^(00)"
		--assert true  = pick bs #"^(01)"
		--assert true  = pick bs #"^(02)"
		--assert true  = pick bs #"^(03)"
		--assert false = pick bs #"^(04)"
		--assert false = pick bs #"^(0100)"
		--assert false = pick bs #"^(0101)"

	--test-- "basic-12"
		bs: make bitset! [0100h 0102h]
		--assert 264 = length? bs
		--assert true  = pick bs 0100h
		--assert false = pick bs 0101h
		--assert true  = pick bs 0102h
		
	--test-- "basic-13"
		bs: make bitset! [255 257]
		--assert 264 = length? bs
		--assert true  = pick bs 255
		--assert false = pick bs 256
		--assert true  = pick bs 257
		
	--test-- "basic-14"
		bs: make bitset! [255 256]
		--assert 264 = length? bs
		--assert true = pick bs 255
		--assert true = pick bs 256
		
	--test-- "basic-15"
		bs: make bitset! [00010000h]
		--assert 65544 = length? bs
		--assert true = pick bs 00010000h
	
	--test-- "basic-16"
		bs: make bitset! 9
		--assert 16 = length? bs
		bs/7: yes
		--assert bs/7 = true
		--assert bs/8 = false
		bs/8: yes
		--assert bs/8 = true
		--assert bs/9 = false
	
	--test-- "basic-17"
		bs: make bitset! 8
		--assert 8 = length? bs
		bs/7: yes
		--assert bs/7 = true
		--assert bs/8 = false
		bs/8: yes
		--assert 16 = length? bs
		--assert bs/8 = true
		--assert bs/9 = false

===end-group===

===start-group=== "modify"
	
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
		bs/0: yes
		--assert bs/0 = true
		bs/0: no
		--assert bs/0 = false
		bs/0: yes
		--assert bs/0 = true
		bs/0: none
		--assert bs/0 = false

	--test-- "append-1"
		bs: make bitset! 8
		--assert 8 = length? bs
		append bs ["hello" #"x" - #"z"]
		--assert "make bitset! #{000000000000000000000000048900E0}" = mold bs

	--test-- "clear-1"
		clear bs
		--assert "make bitset! #{00000000000000000000000000000000}" = mold bs

	--test-- "clear-2"
		bs: charset "^(00)^(01)^(02)^(03)^(04)^(05)^(06)^(07)"
		--assert 8 = length? bs
		--assert "make bitset! #{FF}" = mold bs
		clear bs
		--assert "make bitset! #{00}" = mold bs

	--test-- "remove-1"
		bs: charset "012345789"
		--assert 64 = length? bs
		--assert "make bitset! #{000000000000FDC0}" = mold bs
		--assert "make bitset! #{0000000000007DC0}" = mold remove/part bs #"0"
		--assert "make bitset! #{0000000000003DC0}" = mold remove/part bs 49
		--assert "make bitset! #{0000000000000000}" = mold remove/part bs [#"2" - #"7" "8" #"9"]

===end-group===

===start-group=== "union"
		
	--test-- "u-1"
		c1: charset "0123456789"
		c2: charset [#"a" - #"z"]
		u: "make bitset! #{000000000000FFC0000000007FFFFFE0}"
		--assert u = mold union c1 c2
		--assert u = mold union c2 c1

	--test-- "u-2"
		nd: charset [not #"0" - #"9"]
		zero: charset #"0"
		nd-zero: union nd zero
		--assert not find nd #"0"
		--assert not find nd #"1"
		--assert find nd #"B"
		--assert find nd #"}"

	--test-- "u-3"
		--assert find zero #"0"
		--assert not find zero #"1"
		--assert not find zero #"B"
		--assert not find zero #"}"

	--test-- "u-4"
		--assert find nd-zero #"0"
		--assert not find nd-zero #"1"
		--assert find nd-zero #"B"
		--assert find nd-zero #"}"
	
===end-group===

===start-group=== "and"

	--test-- "and-1"
		c1: charset "b"
		c2: charset "1"
		u: "make bitset! #{00000000000000}"
		--assert u = mold c1 and c2
		--assert u = mold c2 and c1

	--test-- "and-2"
		c1: charset "b"
		c2: charset "1"
		c3: complement c1
		u: "make bitset! [not #{FFFFFFFFFFFFBF}]"
		--assert u = mold c3 and c2
		--assert u = mold c2 and c3
		u: "make bitset! [not #{FFFFFFFFFFFFFFFFFFFFFFFFFF}]"
		--assert u = mold c1 and c3
		c4: complement c2
		--assert "make bitset! #{FFFFFFFFFFFFBF}" = mold c3 and c4

===end-group===

===start-group=== "xor"

	--test-- "xor-1"
		c1: charset "b"
		c2: charset "1"
		u: "make bitset! #{00000000000040000000000020}"
		--assert u = mold c1 xor c2
		--assert u = mold c2 xor c1

	--test-- "xor-2"
		c1: charset "b"
		c2: charset "1"
		c3: complement c1
		u: "make bitset! [not #{00000000000040000000000020}]"
		--assert u = mold c3 xor c2
		--assert u = mold c2 xor c3
		u: "make bitset! [not #{00000000000000000000000000}]"
		--assert u = mold c1 xor c3
		c4: complement c2
		--assert "make bitset! #{00000000000040FFFFFFFFFFDF}" = mold c3 xor c4

===end-group===

===start-group=== "complemented"
	
	--test-- "comp-1"	--assert "make bitset! [not #{}]"   = mold charset [not]
	--test-- "comp-2"	--assert "make bitset! [not #{80}]" = mold charset [not #"^(00)"]
	--test-- "comp-3"	--assert "make bitset! [not #{40}]" = mold charset [not #"^(01)"]
	--test-- "comp-4"	--assert "make bitset! [not #{000000000000FFC0}]" = mold charset [not "0123456789"]
	--test-- "comp-5"	--assert "make bitset! [not #{F0}]" = mold charset [not 0 1 2 3]

	--test-- "comp-6"
		bs: make bitset! 1
		--assert false = complement? bs
		--assert "make bitset! #{00}" = mold bs
		--assert 8 = length? bs
		bs: complement bs
		--assert true = complement? bs
		--assert 8 = length? bs
		--assert "make bitset! [not #{00}]" = mold bs

	--test-- "comp-7"
		bs: charset [not "hello123" #"a" - #"z"]
		--assert 128 = length? bs
		--assert "make bitset! [not #{0000000000007000000000007FFFFFE0}]" = mold bs
		clear bs
		--assert 128 = length? bs
		--assert "make bitset! [not #{00000000000000000000000000000000}]" = mold bs

	--test-- "comp-8"
		bs: complement charset " "
		--assert 40 = length? bs
		--assert bs/31 = true
		--assert bs/32 = false
		--assert bs/33 = true
		--assert bs/200 = true

	--test-- "comp-9"
		bs/32: true
		--assert bs/32 = true
		--assert "make bitset! [not #{0000000000}]" = mold bs

	--test-- "comp-10"
		poke bs #" " none
		--assert bs/32 = false
		--assert "make bitset! [not #{0000000080}]" = mold bs

	--test-- "comp-11"
		clear bs
		--assert "make bitset! [not #{0000000000}]" = mold bs

	--test-- "comp-12"
		poke bs [32 - 40] none
		--assert "make bitset! [not #{00000000FF80}]" = mold bs
		poke bs [32 - 40] true
		--assert "make bitset! [not #{000000000000}]" = mold bs

===end-group===

~~~end-file~~~

