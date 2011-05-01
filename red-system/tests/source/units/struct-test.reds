Red/System [
	Title:   "Red/System struct! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %struct-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

~~~start-file~~~ "struct!"

===start-group=== "Byte literals & operators test"

	--test-- "struct-rw-1"
	struct1: struct [b [integer!]]
	struct1/b: 12345
	--assert struct1/b = 12345
	
	--test-- "struct-rw-2"
	struct2: struct [b [c-string!] c [integer!]]
	struct2/b: "a"
	struct2/c: 9876
	--assert struct2/c = 9876
	
===end-group===


~~~end-file~~~