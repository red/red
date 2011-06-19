Red/System [
	Title:   "Red/System null test script"
	Author:  "Nenad Rakocevic"
	File: 	 %null-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

~~~start-file~~~ "null"

===start-group=== "null first class tests"

	nt-struct: struct [a [pointer! [integer!]]]

	nt-foo: func [
		p [pointer! [integer!]]
		return: [pointer! [integer!]]
	][
		p
	]
	nt-p: pointer [integer!]
	nt-p: null
	nt-q: struct [a [integer!]]
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
	
===end-group===

  
~~~end-file~~~

