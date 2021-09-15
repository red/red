Red [
	Title:   "Red Stress testing script"
	Author:  "Xie Qingtian"
	File: 	 %stress-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "StressTesting"

===start-group=== "stress-test"

	--test-- "stress-deep-recursive"	;-- issue #3628
	k: 500

	add3628: func [x y][
		unique cache: [] ; <-- UNIQUE is the culprit
		last append cache x + y
	]

	--assert integer? do collect [
		repeat i k [keep reduce ['add3628 random i]]
		keep 0
	]

===end-group===

~~~end-file~~~
