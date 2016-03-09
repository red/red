Red/System [
	Title:   "Red/System EXIT keyword test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %function-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "function"

===start-group=== "Issue #103"

	--test-- "func-1 issue #103"
		f1-f: func [
			/local
			f1-f1 [integer!]
		][
			f1-f1: 3 
			--assert f1-f1 = 3
		]

		f1-f1: func [
			return: [integer!]
		][
			5
		]
	--assert f1-f1 = 5
	f1-f
  
===end-group===

===start-group=== "function return values"

	--test-- "frv1 - issue #272"
		frv1-func: func [return: [logic!]][
			either true [
				1 = 3
			][
				false
			]
		]
	
		--assert false = frv1-func
	
	--test-- "frv2"
		frv2-func: func [
			return: [logic!]
			/local ret [logic!]
		][	
			either true [
				ret: 1 = 3
			][
				ret: false
			]
		]
	
		--assert false = frv2-func
	
	--test-- "frv3"
		frv3-func: func [
			return: [logic!]
			/local ret [logic!]
		][
			either true [
				ret: 1 = 3
			][
				ret: false
			]
			ret
		]
		--assert false = frv3-func
  
===end-group===

===start-group=== "does"

	--test-- "d1"
		d1-a: 1
		d1-b: 0
		d1-d: does [d1-b: d1-a]
		d1-d
		--assert d1-a = d1-b
  
===end-group===

~~~end-file~~~
