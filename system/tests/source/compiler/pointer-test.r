REBOL [
	Title:   "Red/System infix functions test script"
	Author:  "Nenad Rakocevic"
	File: 	 %pointer-test.reds
	Rights:  "Copyright (C) 2012-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "pointer-compile"


===start-group=== "errors"

	--test-- "pointer error 1"
	--compile-this {
	    Red/System [] 
	    f: func [
	      [typed]
	      count           [integer!]
	      list            [typed-value!]
	    ][
	      pt: declare pointer! [integer!]
	      pt: as pointer! [integer!] list/value
	    ]
	    f [:i]
	  }
	--assert-msg? "*** Compilation Error: undefined symbol: i"
	  --clean
	
	--test-- "pointer error 2"
	--compile-this {
	    Red/System [] 
	    p-t: declare pointer! [integer!]
	    p-t: :i
	  }
	--assert-msg? "*** Compilation Error: undefined symbol: i"
	  --clean
===end-group===

~~~end-file~~~


