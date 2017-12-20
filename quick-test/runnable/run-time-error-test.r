REBOL [
    Title:   "Red run time error test script"
	Author:  "Peter W A Wood"
	File: 	 %run-time-error-test.r
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "Red run time errors"

	--test-- "rte-1"
		--compile-and-run-this/error {Red[] i: 1 j: 0 k: i / j}
    	--assert-red-printed? "*** Math error: attempt to divide by zero"
    	
    --test-- "rte-2"
    	--compile-and-run-this/error {Red[] absolute -2147483648}
    	--assert-red-printed? "*** Math error: math or number overflow"
    	
     --test-- "rte-3"
    	--compile-and-run-this/error {Red[] #"^^(01)" + #"^^(10FFFF)"}
    	--assert-red-printed? "*** Math Error: math or number overflow"
    	
    --test-- "rte-4"
    	--compile-and-run-this/error {Red[] do [#"^^(01)" + #"^^(10FFFF)"]}
    	--assert-red-printed? "*** Math Error: math or number overflow"
    	
    --test-- "rte-5"
    	--compile-and-run-this/error {Red[] #"^^(00)" - #"^^(01)"}
    	--assert-red-printed? "*** Math Error: math or number overflow"
    	
    --test-- "rte-6"
    	--compile-and-run-this/error {Red[] do [#"^^(00)" - #"^^(01)"]}
    	--assert-red-printed? "*** Math Error: math or number overflow"
    	
    --test-- "rte-7"
    	--compile-and-run-this/error {Red[] #"^^(010FFF)" * #"^^(11)"}
    	--assert-red-printed? "*** Math Error: math or number overflow"
    	
    --test-- "rte-8"
    	--compile-and-run-this/error {Red[] do [#"^^(010FFF)" * #"^^(11)" ]}
    	--assert-red-printed? "*** Math Error: math or number overflow"
  
~~~end-file~~~ 
