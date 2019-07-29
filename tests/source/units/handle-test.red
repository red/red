Red [
	Title:   "Red/System handle! datatype tests"
	Author:  "bitbegin"
	File: 	 %handle-test.red
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "handle"

===start-group=== "make handle"
	--test-- "make handle 1"
		--assert "make handle! 00001234h" = form make handle! 4660
	--test-- "make handle 2"
		--assert "make handle! 00001234h" = form make handle! #{1234}

===end-group===

===start-group=== "to handle"
	--test-- "to handle 1"
		--assert "make handle! 00001234h" = form to handle! 4660
	--test-- "to handle 2"
		--assert "make handle! 00001234h" = form to handle! #{1234}

===end-group===

===start-group=== "mold handle"
	--test-- "mold handle 1"
		--assert "make handle! 00001234h" = mold make handle! 4660
	--test-- "mold handle 2"
		--assert "make handle! 00001234h" = mold do mold make handle! 4660

===end-group===

~~~end-file~~~
