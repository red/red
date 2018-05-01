Red [
	Title:   "Red extract test script"
	Author:  "heroide@protonmail.com"
	File:    %extract-test.red
	Tabs:    4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "extract"

===start-group=== "forskip"
	--test-- "forskip-1"
	heroide: "heroide"
	allstars: copy ""
	forskip heroide 2 [append allstars "*"]
	--assert "****" = allstars
===end-group===

===start-group=== "extract"
	--test-- "extract-1"
	--assert [1] = extract [1 2 3 4 5] 6
	--test-- "extract-2"
	--assert "12345" = extract "1 2 3 4 5 " 2
===end-group===

===start-group=== "extract/index"
	--test-- "extract/index1"
	--assert "??" = extract/index "Hwhoearmi?ociangdueess!?" 14 10
	--test-- "extract/index2"
	--assert "Heroide!" = extract/index "Hwhoearmi?ociangdueess!?" 6 [1 5]
===end-group===

~~~end-file~~~
