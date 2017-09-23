Red [
	Title:   "Red power function test script"
	Author:  "mahengyang"
	File: 	 %power-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2017, Nenad Rakocevic & Peter W A Wood & mahengyang. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "power"

===start-group=== "power normal"
	--test-- "power-normal-1"	--assert 1 = power 1 1
	--test-- "power-normal-2"	--assertf~= (power 3 -2)  0.1111 0.0001
	--test-- "power-normal-3"	--assert 1 = power 3 0
	--test-- "power-normal-4"	--assert 1 = power 0 0
	--test-- "power-normal-5"	--assert 0 = power 0 3
	--test-- "power-normal-6"	--assertf~= (power 3.5 1.4) 5.7769 0.0001
	--test-- "power-normal-7"	--assert 1.#INF = power 2147483647 2147483647
	--test-- "power-normal-8"	--assert -1.#INF = power -2147483647 2147483647
===end-group===

===start-group=== "power error"
	--test-- "power-error-1" 
		pe-1: try [power "a" 1]
		--assert error? pe-1
		--assert none <> find (to string! pe-1) "*** Script Error"
	
	--test-- "power-error-2" 
		pe-2: try [power 2 "a"]
		--assert error? pe-2
		--assert none <> find (to string! pe-2) "*** Script Error"
===end-group===

~~~end-file~~~