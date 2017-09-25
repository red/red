Red [
	Title:   "Red functions test script"
	Author:  "mahengyang"
	File: 	 %functions-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood & mahengyang. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "functions"

===start-group=== "routine tests"

	--test-- "routine-1" 
		rt-1: try [routine [1] [2]]
		--assert error? rt-1
		--assert none <> find (to string! rt-1) "*** Internal Error: routines require compilation"

===end-group===

===start-group=== "also tests"

	--test-- "also-1" 
		at1-1: 2
		at1-2: also 1 reduce [at1-1: 3]
		--assert 1 = at1-2
		--assert 3 = at1-1
	
	--test-- "also-2" --assert [1] = also [1] 2
	--test-- "also-3" --assert none = also none 2 
	--test-- "also-4" --assert #"^(00)" = also #"^(00)" 2 
	
===end-group===

===start-group=== "attempt tests"

	--test-- "attempt-1" --assert 2 = attempt [1 + 1]
	--test-- "attempt-2" --assert none = attempt [1 / 0]
	--test-- "attempt-3" --assert none = attempt [1 * "abc"]

===end-group===

===start-group=== "quit tests"

===end-group===

===start-group=== "empty tests"

	--test-- "empty-1" --assert true = empty? []
	--test-- "empty-2" --assert true = empty? none
	--test-- "empty-3" --assert false = empty? [1]
	--test-- "empty-4" --assert false = empty? [[]]
	--test-- "empty-5" --assert true = empty? ""
	--test-- "empty-6" --assert false = empty? "a"
	--test-- "empty-7" --assert false = empty? [red blue]
	--test-- "empty-8" --assert false = empty? %functions-test.red

===end-group===

===start-group=== "?? tests"

	--test-- "??-1" --assert none <> find (?? ??) "??: func ["
===end-group===

~~~end-file~~~

