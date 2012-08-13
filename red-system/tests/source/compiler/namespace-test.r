REBOL [
	Title:   "Red/System namespace compiler test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %namespace-test.r
	Rights:  "Copyright (C) 2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../
  

~~~start-file~~~ "namespace compiler tests"

===start-group=== "with"

  --test-- "nscw1"
  
  --compile-and-run-this {
	  nscw1-nsp1: context [b: 123]
    nscw1-nsp2: context [b: 456]
    with [nscw1-nsp1 nscw1-nsp2] [
      b: 789
    ]
	}
	
	--assert-msg? "*** Warning: contexts are using identical word: b"
 
===end-group=== 
       
~~~end-file~~~


