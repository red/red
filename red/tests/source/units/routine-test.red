Red [
	Title:   "Red function test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %routine-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

~~~start-file~~~ "routine"

===start-group=== "routine return tests"

	--test-- "rr1"
		rr1-r: routine [
			return:		[integer!]
		][
			1
		]
	--assert 1 = rr1-r
comment { ***access violation***
	--test-- "rr2"
		rr2-r: routine [
			return:		[block!]
		][
			blk: declare red-block!
			blk: red/block/make-at blk 3
			blk: red/block/rs-append blk as red-value! as red-integer! 1
			blk: red/block/rs-append blk as red-value! as red-integer! 2
			blk: red/block/rs-append blk as red-value! as red-integer! 3
			blk
		]
	--assert [1 2 3] = rr2-r
}
	--test-- "rr3"
		rr3-r: routine [
			return:			[char!]
		][
			as red-char! 10000h
		]
	--assert #"^(10000)" = rr3-r
	
	--test-- "rr4"
		rr4-r: routine [
			return:			[logic!]
		][
			true
		]
	--assert rr4-r
	
	--test-- "rr5"
		rr5-r: routine [
			return:			[none!]
		][
			n: declare red-none!
			n
		]
	--assert none = rr5-r
	
comment { ***access violation***	
	--test-- "rr6"
		rr6-r: routine [
			return:			[string!]
		][
			s: red/string/load "abcde^(E2)^(9C)^(90)é^(F0)^(90)^(80)^(80)" 20
			s
		]
	--assert "abcde^(2710)é^(010000)" = rr6-r
}

	--test-- "rr7"
		rr7-r: routine [
			return:			[unset!]
		][
			u: declare red-unset!
			u
		]
		--assert (prin "") = rr5-r
	
===end-group===

===start-group=== "routine yo-yo tests"
	
	--test-- "ry1"
		ry1-r: routine [
			i			[integer!]
			return:		[integer!]
		][
			i
		]
	--assert 1 = ry1-r 1
	
	--test-- "ry2"
		ry2-r: routine [
			b			[block!]
			return:		[block!]
		][
			b
		]
	--assert [1 2 3] = ry2-r [1 2 3]
	
	--test-- "ry3"
		ry3-r: routine [
			c				[char!]
			return:			[char!]
		][
			c	
		]
	--assert #"^(10000)" = ry3-r #"^(10000)"
	
	--test-- "ry4"
		ry4-r: routine [
			l				[logic!]
			return:			[logic!]
		][
			l	
		]
	--assert ry4-r true 
	--assert not ry4-r false
	
	--test-- "ry5"
		ry5-r: routine [
			n				[none!]
			return:			[none!]
		][
			n	
		]
	--assert none = ry5-r none
	
	--test-- "ry6"
		ry6-r: routine [
			s				[string!]
			return:			[string!]
		][
			s
		]
	--assert "abcde^(2710)é^(010000)" = ry6-r "abcde^(2710)é^(010000)" 
	
	--test-- "ry7"
		ry7-r: routine [
			u				[unset!]
			return:			[unset!]
		][
			u
		]
		--assert (prin "") = ry7-r prin "" 
	

===end-group===	
	
~~~end-file~~~

