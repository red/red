REBOL [
  Title:   "Red compile error test script"
	Author:  "Peter W A Wood"
	File: 	 %compile-error-test.r
	Rights:  "Copyright (C) 2013-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "Red compile errors"

===start-group=== "issue #608"

	--test-- "ce-1 issue #608"
		--compile-this-red {s: "open ended string}
		--assert-msg? "*** Syntax Error: Invalid string! value"

===end-group===	

===start-group=== "issue #3268"
	
	--test-- "ce-2a"
		--compile-this-red {try [continue]}
		--assert-msg? "*** Compilation Error: CONTINUE used with no loop"

	--test-- "ce-2b"
		--compile-this-red {try [break]}
		--assert-msg? "*** Compilation Error: BREAK used with no loop"

	--test-- "ce-2c"
		--compile-this-red {try [exit]}
		--assert-msg? "*** Compilation Error: EXIT used outside of a function"

	--test-- "ce-2d"
		--compile-this-red {try [return 1]}
		--assert-msg? "*** Compilation Error: RETURN used outside of a function"

	--test-- "ce-2e"
		--compile-this-red {try [while [continue][]]}
		--assert-msg? "*** Compilation Error: CONTINUE used with no loop"
		
	--test-- "ce-2f"
		--compile-this-red {try [while [break][]]}
		--assert-msg? "*** Compilation Error: BREAK used with no loop"

===end-group===	
  
~~~end-file~~~ 
