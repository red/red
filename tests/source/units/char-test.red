Red [
	Title:   "Red/System char! datatype test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %char-test.red
	Version: "0.2.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "char"

===start-group=== "+ tests"
	--test-- "char+1" --assert #"^(01)" + #"^(00)" = #"^(01)"
	--test-- "char+2" --assert #"^(FF)" + #"^(01)" = #"^(0100)"
===end-group===
  
===start-group=== "- tests"
	--test-- "char-1" --assert #"^(01)" - #"^(00)" = #"^(01)"
	--test-- "char-2" --assert #"^(0100)" - #"^(01)" = #"^(FF)"
===end-group===

===start-group=== "* tests"
    --test-- "char*1" --assert #"^(01)" * #"^(00)" = #"^(00)"
    --test-- "char*2" --assert #"^(01)" * #"^(01)" = #"^(01)"
    --test-- "char*3" --assert #"^(01)" * #"^(02)" = #"^(02)"
    --test-- "char*4" --assert #"^(010FFF)" * #"^(10)" = #"^(10FFF0)"
===end-group===
  
===start-group=== "/ tests"
    --test-- "char/1" --assert #"^(01)" / #"^(01)" = #"^(01)"
    --test-- "char/2" --assert #"^(01)" / #"^(02)" = #"^(00)"
    --test-- "char/3" --assert #"^(10FFFF)" / #"^(10)" = #"^(010FFF)"
    
===end-group===

===start-group=== "mod tests"
    --test-- "char%1" --assert #"^(010FFF)" % #"^(10)" = #"^(0F)"
    --test-- "char%2" --assert #"^(01)" % #"^(02)" = #"^(01)"
===end-group===

===start-group=== "even?"
	--test-- "even1" --assert true	= even? #"^(00)"
	--test-- "even2" --assert false = even? #"^(01)"
	--test-- "even3" --assert false	= even? #"^(10FFFF)"
	--test-- "even4" --assert true	= even? #"^(FE)"
===end-group===

===start-group=== "odd?"
	--test-- "odd1" --assert false	= odd? #"^(00)"
	--test-- "odd2" --assert true	= odd? #"^(01)"
	--test-- "odd3" --assert true	= odd? #"^(10FFFF)"
	--test-- "odd4" --assert false	= odd? #"^(FE)"
===end-group===

===start-group=== "min/max"
	--test-- "max1" --assert #"b" = max #"a" #"b"
	--test-- "min1" --assert #"a" = min #"a" #"大"
===end-group===

===start-group=== "and"
	--test-- "and1" --assert #"^(01)" and #"^(10)" = #"^(00)"
	--test-- "and2" --assert #"^(11)" and #"^(10)" = #"^(10)"
	--test-- "and3" --assert #"^(01)" and #"^(1F)" = #"^(01)"
===end-group===

===start-group=== "or"
	--test-- "or1" --assert #"^(01)" or #"^(10)"  = #"^(11)"
	--test-- "or2" --assert #"^(11)" or #"^(10)"  = #"^(11)"
	--test-- "or3" --assert #"^(01)" or #"^(1F)"  = #"^(1F)"
===end-group===

===start-group=== "xor"
	--test-- "xor1" --assert #"^(01)" xor #"^(10)" = #"^(11)"
	--test-- "xor2" --assert #"^(11)" xor #"^(10)" = #"^(01)"
	--test-- "xor3" --assert #"^(01)" xor #"^(1F)" = #"^(1E)"
===end-group===

~~~end-file~~~
