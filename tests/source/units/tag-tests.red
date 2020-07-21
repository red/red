Red [
	Title:   "Red tag! test script"
	Author:  "Adam Sherwood"
	File:    %tag-test.red
	Tabs:    4
	Rights:  "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "tag"

===start-group=== "tag with caret"

	--test-- "tc-1"
		--assert not equal? <a> <a^>
		--assert equal?     <a> load {<a^>}

===end-group===

~~~end-file~~~