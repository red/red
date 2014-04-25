Red [
	Title:   "Red/System integer! datatype tests"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %integer-test.red
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;; These supplement the bulk of the integer tests which are automatically
;; generated.

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "integer"

===start-group=== "absolute"
	--test-- "abs1" --assert 0 = absolute 0
	--test-- "abs2" --assert 1 = absolute 1
	--test-- "abs3" --assert 1 = absolute -1
	--test-- "abs4" --assert 2147483647 = absolute -2147483647
	--test-- "abs5" --assert 2147483647 = absolute 2147483647
===end-group===

===start-group=== "power"
	--test-- "pow1" --assert 3 	 = power  3 1
	--test-- "pow2" --assert 9 	 = power -3 2
	--test-- "pow3" --assert -27 = power -3 3
	--test-- "pow4" --assert 0 	 = power -3 -1
	--test-- "pow5" --assert -1  = power -1 3
	--test-- "pow6" --assert 1	 = power -1 -4
	;--test-- "pow7" --assert 1 = power 0 -1		;@@ should return INF
	;--test-- "pow8" --assert 1 = power 0 -1		;@@ should return -INF
===end-group===

===start-group=== "max/min"
	--test-- "max1" --assert 3 	 = max  3 1
	--test-- "min1" --assert -3  = min -3 2
===end-group===

===start-group=== "negative?/positive?"
	--test-- "neg1" --assert true  = negative? -1
	--test-- "neg2" --assert false = negative? 0
	--test-- "neg3" --assert false = negative? 1
	--test-- "pos1" --assert true  = positive? 1
	--test-- "pos2" --assert false = positive? 0
	--test-- "pos3" --assert false = positive? -1
===end-group===

===start-group=== "complemented"
	--test-- "comp-1" --assert -2 = complement 1
	--test-- "comp-2" --assert -1 = complement 0
	--test-- "comp-3" --assert 0  = complement FFFFFFFFh
===end-group===

===start-group=== "shift"
	--test-- "shift-1" --assert 1  = shift 2 1
	--test-- "shift-2" --assert 16 = shift/left 2 3
	--test-- "shift-3" --assert FFFFFFFEh = shift FFFFFFFCh 1
	--test-- "shift-4" --assert 7FFFFFFEh = shift/logical FFFFFFFCh 1
===end-group===

===start-group=== "shift op!"
	--test-- "shift-op-1" --assert 2 >> 1 = 1
	--test-- "shift-op-2" --assert 2 << 3 = 16
	--test-- "shift-op-3" --assert FFFFFFFCh >> 1 = FFFFFFFEh
	--test-- "shift-op-4" --assert FFFFFFFCh >>> 1 = 7FFFFFFEh
===end-group===

===start-group=== "and"
	--test-- "and1" --assert 01h and 10h = 00h
	--test-- "and2" --assert 11h and 10h = 10h
	--test-- "and3" --assert 01h and 1Fh = 01h
===end-group===

===start-group=== "or"
	--test-- "or1" --assert  01h or 10h  = 11h
	--test-- "or2" --assert  11h or 10h  = 11h
	--test-- "or3" --assert  01h or 1Fh  = 1Fh
===end-group===

===start-group=== "xor"
	--test-- "xor1" --assert 01h xor 10h = 11h
	--test-- "xor2" --assert 11h xor 10h = 01h
	--test-- "xor3" --assert 01h xor 1Fh = 1Eh
===end-group===

~~~end-file~~~
