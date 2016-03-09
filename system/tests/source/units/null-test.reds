Red/System [
	Title:   "Red/System null test script"
	Author:  "Nenad Rakocevic"
	File: 	 %null-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "null"

===start-group=== "null first class tests"

	nt-struct: declare struct! [a [pointer! [integer!]]]

	nt-foo: func [
		p [pointer! [integer!]]
		return: [pointer! [integer!]]
	][
		p
	]
	foo-null: func [return: [pointer! [integer!]]][null]
	
	nt-p: declare pointer! [integer!]
	nt-p: null
	nt-q: declare struct! [a [integer!]]
	nt-r: nt-foo null
	nt-struct/a: null

	--test-- "null-1"  --assert nt-p = null
	--test-- "null-2"  --assert null = nt-p
	--test-- "null-3"  --assert nt-p + 1 <> null
	--test-- "null-4"  --assert nt-q <> null
	--test-- "null-5"  --assert nt-p = nt-foo null
	--test-- "null-6"  --assert nt-r = null
	--test-- "null-7"  --assert nt-p = nt-foo null
	--test-- "null-8"  --assert nt-struct/a = null
	--test-- "null-9"  --assert null = nt-struct/a
	--test-- "null-10" --assert nt-struct/a = null
	--test-- "null-11" --assert null = foo-null
	
===end-group===

  
~~~end-file~~~

