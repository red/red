Red/System [
	Title:		"Red/System integer! datatype tests"
	Author:		"Peter W A Wood"
	File:		%integer-test.reds
	Version:	0.1.1
	Tabs:		4
	Rights:		"Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License:	"BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "integer"

===start-group=== "integer overflow"
	--test-- "intoverflow!" --assert 0 = (FFFFFFFFh + 1)
===end-group===

~~~end-file~~~
