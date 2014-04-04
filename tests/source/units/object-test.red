Red [
	Title:   "Red/System object! datatype test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %object-test.red
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2014 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red
do [								;-- temp until object! support in compiler
~~~start-file~~~ "object"

===start-group=== "simple object tests"
	
	--test-- "simple object 1"
		so1-a: 0
		so1-o: make object! [so1-a: 1]
		--assert so1-a = 0
		--assert so1-o/so1-a = 1
		
	--test-- "simple object 2"
		so2-s: "0"
		so2-o: make object! [so2-s: "1"]
		--assert so2-s = "0"
		--assert so2-o/so2-s = "1"

===end-group===

~~~end-file~~~

]								;-- temp until object! support in compiler
