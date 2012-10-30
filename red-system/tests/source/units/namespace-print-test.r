REBOL [
	Title:   "Red/System namespace print test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %namespace-print-test.r
	Rights:  "Copyright (C) 2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../
  

~~~start-file~~~ "namespace print tests"

===start-group=== "inline functions"

  --test-- "nsif1 issue #285"
  
  --compile-and-run-this {
	  c: context [
      f: func [[infix] a [integer!] b [integer!] return: [integer!]][a + b]
      print "The answer is "
      print 1 f 2
      print lf
    ]
	}
	--assert-printed? "The answer is 3"
 
===end-group===
       
~~~end-file~~~


