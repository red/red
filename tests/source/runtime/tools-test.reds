Red/System [
	Title:   "Red/System runtime tools test"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %utils-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../quick-test/quick-test.reds
#include %../../../runtime/tools.reds

~~~start-file~~~ "runtime tools"

===start-group=== "round to"

--test-- "rt-1"
--assert 16 = round-to 9 16

--test-- "rt-2"
--assert 0 = round-to 0 16

--test-- "rt-3"
--assert 16 = round-to 1 16

--test-- "rt-4"
--assert 16 = round-to 15 16

--test-- "rt-5"
--assert 16 = round-to 16 16

--test-- "rt-6"
--assert -2147483648 = round-to 2147483647 16

--test-- "rt-7"
--assert 32 = round-to 32 16
  
===end-group===
  
~~~end-file~~~

