Red [
	Title:   "Red unset test script"
	Author:  "bitbegin"
	File: 	 %unset-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "unset"

===start-group=== "unset-word"

	--test-- "unset-word-1"
		a: 123
		unset 'a
		--assert error? try [a]

	--test-- "unset-word-2"
		unset 'a
		--assert error? try [a]

	--test-- "unset-word-3"
		unset 'b
		--assert error? try [get 'b]	;-- compiler will catch it if just: try [b]

===end-group===

===start-group=== "unset-block"

	--test-- "unset-block-1"
		a: 123
		unset [a]
		--assert error? try [a]

	--test-- "unset-block-2"
		a: 123
		unset [a 1]
		--assert error? try [a]

	--test-- "unset-block-3"
		unset [a 1]
		--assert error? try [a]

===end-group===

~~~end-file~~~
