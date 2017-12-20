REBOL [
  Title:   "Red compile error test script"
	Author:  "Peter W A Wood"
	File: 	 %compile-error-test.r
	Rights:  "Copyright (C) 2013-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "Red compile errors"

	--test-- "ce-1 issue #608"
		--compile-this-red {s: "open ended string}
		--assert-msg? "*** Syntax Error: Invalid string! value"
  
~~~end-file~~~ 
