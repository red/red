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

#define case-int-1-code "case [ ci = 1 [1] ci = 2 [2] true [3]]"

	--test-- "case-int-1"
	  ci: 1
	--assert 1 = case [ ci = 1 [1] ci = 2 [2] true [3]]
	
	--test-- "case-int-2"
	  ci: 1
	  cr: case [ 
	    ci = 1 [1]
	    ci = 2 [2]
	    true [3]
	  ]
	--assert 1 = cr
	
	--test-- "case-int-3"
	  ci: 2
	--assert 2 = case [ ci = 1 [1] ci = 2 [2] true [3]]
	
	--test-- "case-int-4"
	  ci: 2
	  cr: case [ 
	    ci = 1 [1]
	    ci = 2 [2]
	    true [3]
	  ]
	--assert 2 = cr
	
	--test-- "case-int-5"
	  ci: 3
	--assert 3 = case [ ci = 1 [1] ci = 2 [2] true [3]]
	
	--test-- "case-int-6"
	  ci: 3
	  cr: case [ 
	    ci = 1 [1]
	    ci = 2 [2]
	    true [3]
	  ]
	--assert 3 = cr
	
	--test-- "case-int-7"
	  ci: 10
	--assert 3 = case [ ci = 1 [1] ci = 2 [2] true [3]]
	
	--test-- "case-int-2"
	  ci: 10
	  cr: case [ 
	    ci = 1 [1]
	    ci = 2 [2]
	    true [3]
	  ]
	--assert 3 = cr

===end-group===
  
~~~end-file~~~

