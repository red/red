Red/System [
	Title:		"Red natives tests"
	Author:		"Andreas Bolka"
	File:		%natives-test.reds
	Tabs:		4
	Rights:		"Copyright (C) 2012 Andreas Bolka. All rights reserved."
	License:	"BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "natives"

===start-group=== "either"

--test-- "either-true"
--assert 1 = either true [1] [0]

--test-- "either-false"
--assert 1 = either false [0] [1]

===end-group===

~~~end-file~~~
