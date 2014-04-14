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
  
~~~end-file~~~
