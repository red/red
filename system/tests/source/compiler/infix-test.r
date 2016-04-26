REBOL [
	Title:   "Red/System infix functions test script"
	Author:  "Nenad Rakocevic"
	File: 	 %callback-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../

;=== Test only infix compilation, not execution ===


~~~start-file~~~ "infix-compile"

===start-group=== "compile"

	--test-- "simple infix 1"
		--compile-this "Red/System [] foo: func [[infix] a [integer!] b [integer!]][a]"
		--assert qt/compile-ok?
		
===end-group===


===start-group=== "errors"

	--test-- "infix error 1"
		--compile-this "Red/System [] foo: func [[infix] a [integer!]][a]"
		--assert-msg? "*** Compilation Error: infix function requires 2 arguments, found 1 for foo"
		--clean
		
	--test-- "infix error 2"
		--compile-this "Red/System [] foo: func [[infix] a [integer!] b [integer!] c [integer!]][a]"
		--assert-msg? "*** Compilation Error: infix function requires 2 arguments, found 3 for foo"
		--clean	
		
===end-group===

~~~end-file~~~


