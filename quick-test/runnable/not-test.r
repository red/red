REBOL [
	Title:   "Red/System infix functions test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %not-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "not-compile"

===start-group=== "not compile and run tests"

	--test-- "not-comp-run-1 #issue 104"
	--compile-and-run-this {
	  Red/System [] 
	  dummy: func [return: [integer!]] [0]
	  print "starting"
	  prin-hex as-integer not as-logic dummy
	  print ""
	  print "finished"
	}
	--assert none <> find qt/output"finished"

===end-group===
		
~~~end-file~~~


