Red [
	Title:   "REJOIN test script"
	Author:  @hiiamboris
	File: 	 %rejoin-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2022 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red


~~~start-file~~~ "rejoin"

===start-group=== "Block joining"

	--test-- "rejoin-block-1" --assert []        = rejoin []
	--test-- "rejoin-block-2" --assert [1 2]     = rejoin b: [[] 1 2]
	--test-- "rejoin-block-3" --assert [1 2]     = rejoin b
	--test-- "rejoin-block-4" --assert [3 [3 4]] = rejoin [[] 1 + 2 [3 4]]
	--test-- "rejoin-block-5" --assert (quote (1 2 [3 4])) == rejoin [quote () 1 2 [3 4]]
	
===end-group===

===start-group=== "String joining"

	--test-- "rejoin-string-1" --assert ""     == rejoin [""]
	--test-- "rejoin-string-2" --assert "12"   == rejoin b: [1 2]
	--test-- "rejoin-string-3" --assert <a127> == rejoin [<a> 1 2 3 + 4]
	--test-- "rejoin-string-4" --assert %"127" == rejoin [%"" 1 2 3 + 4]
	--test-- "rejoin-string-5" --assert %"a<b c>d e" == rejoin [%"a" <b c> [d e]]
	
===end-group===

===start-group=== "String interpolation"

	;; see also preprocessor test for more
	--test-- "rejoin-interp-1" --assert ""       == rejoin "()"
	--test-- "rejoin-interp-2" --assert ""       == rejoin "([])"
	--test-- "rejoin-interp-3" --assert "((\\))" == rejoin "(\(\\\))"
	--test-- "rejoin-interp-4"
		--assert <tag flag="3"/> == rejoin <tag flag=(mold to string! 1 + 2)/>
	--test-- "rejoin-interp-5"
		--assert %" - 3 - <abc)))> - func1" == rejoin %"()() - (1 + 2) - (<abc)))>) - ('func)(1)()()"
	--test-- "rejoin-interp-6"
		--assert "*ERROR*" == rejoin/trap "(1 / 0)" "*ERROR*"
	--test-- "rejoin-interp-7"
		--assert "zero-divide expect-arg" == rejoin/trap "(1 / 0) ({a} + 1)" func [e][e/id]
	--test-- "rejoin-interp-8"
		--assert "print" == rejoin/trap "(1 / 0)" func [e]['print]	;-- no second error from double evaluation
	--test-- "rejoin-interp-9"
		"9" == rejoin {(;-- comment
			1 + 2 * 3	;-- another
		)}
	--test-- "rejoin-interp-10"
		--assert "123" == rejoin "(append {1} rejoin {2(1 + 2)})"
	
	--test-- "rejoin-interp-11"
		c: context [x: 2 y: 3 z: 4]
		--assert " 5 12 " == rejoin/with " (x + y) (y * z) " [c]
	
	--test-- "rejoin-interp-12"
		c1: context [x: y: z: 2]
		c2: context [y: 3 z: 4]
		--assert " 5 12 " == rejoin/with " (x + y) (y * z) " [c1 c2]
	
	--test-- "rejoin-interp-13"
		c1: context [x: y: z: 2]
		c2: context [y: 3 z: 4]
		--assert " 5 12 " == rejoin/with " (x + y) (y * z) " [in c1 'x in c2 'y]
	
===end-group===

~~~end-file~~~
