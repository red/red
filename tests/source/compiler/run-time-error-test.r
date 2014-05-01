REBOL [
  Title:   "Red run time error test script"
	Author:  "Peter W A Wood"
	File: 	 %run-time-error-test.r
	Rights:  "Copyright (C) 2011-2012 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "Red run time errors"

	--test-- "rte-1"
		--compile-and-run-this/error {Red[] i: 1 j: 0 k: i / j}
    	--assert-red-printed? "*** Runtime Error 13: integer divide by zero"
    	
    --test-- "rte-2"
    	--compile-and-run-this/error {Red[] absolute -2147483648}
    	--assert-red-printed? "*** Math Error: integer overflow on ABSOLUTE"
  
~~~end-file~~~ 
