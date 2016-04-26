REBOL [
	Title:   "Red/System dynamic linbary compiler test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %dylib-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "dylib compiler"

===start-group=== "dylib compiles"

		dll-target: switch/default fourth system/version [
			2 ["Darwin"]
			3 ["Windows"]
			7 ["FreeBSD"]
		][
			"Linux"
		]
										;; source should be relative to 
										;; runnable dir
	--test-- "compile dll1"
	--compile-dll join qt/base-dir 
				  %system/tests/source/units/libtest-dll1.reds dll-target
	--assert qt/compile-ok?
	
	--test-- "compile dll2"
	--compile-dll join qt/base-dir 
				  %system/tests/source/units/libtest-dll2.reds dll-target
	--assert qt/compile-ok?
	
===end-group===
  
~~~end-file~~~
