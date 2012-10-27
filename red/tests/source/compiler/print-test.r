REBOL [
  Title:   "Red print test script"
	Author:  "Peter W A Wood"
	File: 	 %print-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "Red print"

 --test-- "Red print 1"
   --compile-and-run-red %source/compiler/print-test.red
  --assert-printed? 1
  
  --test-- "Red print 2"
    --compile-and-run-this-red {print 2}
  --assert-printed? 2  

~~~end-file~~~ 
