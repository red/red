Red [
	Title:   "Red function test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %routine-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "routine"

===start-group=== "routine return tests"

	--test-- "rr1"
		rr1-r: routine [
			return:		[integer!]
		][
			1
		]
	--assert 1 = rr1-r

	--test-- "rr4"
		rr4-r: routine [
			return:			[logic!]
		][
			true
		]
	--assert rr4-r
	
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
	
	--test-- "ry4"
		ry4-r: routine [
			l				[logic!]
			return:			[logic!]
		][
			l	
		]
	--assert ry4-r true 
	--assert not ry4-r false
	
===end-group===	

===start-group=== "routine return local tests"
	
	--test-- "rrl1"
		rrl1-r: routine [
			return:		[integer!]
			/local
			i			[integer!]
		][
			i: 1
			i
		]
	--assert 1 = rrl1-r
	
	--test-- "rrl4"
		rrl4-r: routine [
			return:			[logic!]
			/local
			l				[logic!]
		][
			l: true
			l
		]
	--assert rrl4-r true 
	
===end-group===	

===start-group=== "routine simple tests"
	
	--test-- "rs1"
		rs1-r: routine [
			i			[integer!]
			return:		[integer!]
		][
			i + 1
		]
	--assert 2 = rs1-r 1
	
	--test-- "rs4"
		rs4-r: routine [
			l				[logic!]
			return:			[logic!]
		][	
			not l	
		]
	--assert rs4-r false 
	--assert not rs4-r true
	
===end-group===	

===start-group=== "routine reported issues"

	--test-- "rri1 - issue #468"
		rri1-r: routine [
			return:			[integer!]
			/local
				b			[byte!]
				cp          [integer!]
		][
			cp: 1
			b: as byte! (cp >>> 6)
			cp: as integer! b
			cp
		]
	--assert 0 = rri1-r

===end-group===
	
~~~end-file~~~

