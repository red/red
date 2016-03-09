Red/System [
	Title:   "Red/System getting variable pointer test script"
	Author:  "Nenad Rakocevic"
	File: 	 %get-pointer-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "get-pointer"

	--test-- "get-var-1"
		s: declare int-ptr!
		a: 123
		s: :a
		--assert s/value = 123
		
	--test-- "get-var-2"
		s2: declare byte-ptr!
		b: #"R"
		s2: :b
		--assert s2/value = #"R"
		
	--test-- "get-var-3"
		s3: declare pointer! [float!]
		c: 3.14
		s3: :c
		--assert s3/value = 3.14
		
	--test-- "get-var-4"
		s4: declare pointer! [float32!]
		d: as-float32 3.14
		s4: :d
		--assert s4/value = as float32! 3.14
		
	--test-- "get-var-local-1"
		s5: declare int-ptr!
		
		foo: func [/local a [integer!]][
			a: 456
			s5: :a
			--assert s5/value = 456
		]
		foo

~~~end-file~~~
