Red [
	Title:   "Red function test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %routine-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

#either all [
	in system 'state
	system/state/interpreted?	
][
	rr1-r: func [] [
		1
	]
	ry1-r: func [
		i			[integer!]
	][
		i
	]
	ry4-r: func [
		l				[logic!]
	][
		l	
	]
	rrl1-r: func [
		/local i			
	][
		i: 1
	]	
	rr4-r: func [][
		true
	]
	rrl4-r: func [
		/local
		l				[logic!]
	][
		l: true
	]
	rs1-r: func [
		i			[integer!]
	][
		i + 1
	]
	rs4-r: func [
		l				[logic!]
	][	
		not l	
	]
	rri1-r: func [
		/local
			cp          [integer!]
	][
		cp: 0
	]

	rtc1: func [p [string!] series [series!] x [float!] return: [integer!]][123]
	rtc2: func [p [any-string!] series [series!] x [float!] return: [integer!]][123]
	rtc3: func [p [any-path!] series [series!] x [float!] return: [integer!]][123]

][
	rr1-r: routine [
		return:		[integer!]
	][
		1
	]
	ry1-r: routine [
		i			[integer!]
		return:		[integer!]
	][
		i
	]
	ry4-r: routine [
		l				[logic!]
		return:			[logic!]
	][
		l	
	]
	rrl1-r: routine [
		return:		[integer!]
		/local
		i			[integer!]
	][
		i: 1
		i
	]	
	rr4-r: routine [
		return:			[logic!]
	][
		true
	]
	rrl4-r: routine [
		return:			[logic!]
		/local
		l				[logic!]
	][
		l: true
		l
	]
	rs1-r: routine [
		i			[integer!]
		return:		[integer!]
	][
		i + 1
	]
	rs4-r: routine [
		l				[logic!]
		return:			[logic!]
	][	
		not l	
	]
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

	rtc1: routine [p [string!] series [series!] x [float!] return: [integer!]][123]
	rtc2: routine [p [any-string!] series [series!] x [float!] return: [integer!]][123]
	rtc3: routine [p [any-path!] series [series!] x [float!] return: [integer!]][123]
]

~~~start-file~~~ "routine"

===start-group=== "routine return tests"

	--test-- "rr1"
	--assert 1 = rr1-r

	--test-- "rr4"
	--assert rr4-r
	
===end-group===

===start-group=== "routine yo-yo tests"
	
	--test-- "ry1"
	--assert 1 = ry1-r 1
	
	--test-- "ry4"
	--assert ry4-r true 
	--assert not ry4-r false
	
===end-group===	

===start-group=== "routine return local tests"
	
	--test-- "rrl1"
	--assert 1 = rrl1-r
	
	--test-- "rrl4"
	--assert rrl4-r true 
	
===end-group===	

===start-group=== "routine simple tests"
	
	--test-- "rs1"
	--assert 2 = rs1-r 1
	
	--test-- "rs4"
	--assert rs4-r false 
	--assert not rs4-r true
	
===end-group===	

===start-group=== "routine arguments typechecking tests"
	
	--test-- "rtc1"	--assert error? try [rtc1 %fi/le [2 3] 1.5]
	--test-- "rtc2"	--assert 123 = rtc1 "string" [2 3] 1.5
	--test-- "rtc3"	--assert 123 = rtc2 %fi/le [2 3] 1.5
	--test-- "rtc4"	--assert error? try [rtc3 [] [2 3] 1.5]
	--test-- "rtc5"	--assert 123 = rtc3 'pa/th [2 3] 1.5

	do [
	--test-- "rtc11" --assert error? try [rtc1 %fi/le [2 3] 1.5]
	--test-- "rtc12" --assert 123 = rtc1 "string" [2 3] 1.5
	--test-- "rtc13" --assert 123 = rtc2 %fi/le [2 3] 1.5
	--test-- "rtc14" --assert error? try [rtc3 [] [2 3] 1.5]
	--test-- "rtc15" --assert 123 = rtc3 'pa/th [2 3] 1.5
	]

===end-group===	

===start-group=== "routine reported issues"

	--test-- "rri1 - issue #468"
	--assert 0 = rri1-r

	--test-- "rri2 - issue #5145"
	--assert 1 = set-quiet 'x 1

===end-group===
	
~~~end-file~~~
