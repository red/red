Red [
	Title:   "Red mold test"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %mold-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

~~~start-file~~~ "mold"

===start-group=== "strings"
	--test-- "mold-string-1"
	--assert {"abcde"} = mold {abcde}
	--test-- "mold-string-2"
	--assert {"^^(3A7)^^(3B1)^^(1FD6)^^(3C1)^^(3B5), ^^(3BA)^^(3CC)^^(3C3)^^(3BC)^^(3B5)"} = mold "Χαῖρε, κόσμε"
===end-group===

~~~end-file~~~

