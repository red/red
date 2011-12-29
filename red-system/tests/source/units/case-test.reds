Red/System [
	Title:   "Red/System case function test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %case-test.reds
	Rights:  "Copyright (C) 2011, 2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "case"

===start-group=== "case integer!"

	
#define case-int-1 [case [ ci = 1 [ca: 1] ci = 2 [ca: 2] true [ca: 3]]]

	--test-- "case-int-1"
	  ci: 1
	  ca: 0
	  case-int-1
	--assert 1 = ca
	
	--test-- "case-int-2"
	  ci: 2
	  ca: 0
	  case-int-1
	--assert 2 = ca
	
	--test-- "case-int-3"
	  ci: 3
	  ca: 0
	  case-int-1
	--assert 3 = ca
	
	--test-- "case-int-4"
	  ci: 3
	  ca: 0
	  case-int-1
	--assert 3 = ca
	
===end-group===
  
~~~end-file~~~

