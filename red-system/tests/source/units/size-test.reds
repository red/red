Red/System [
	Title:   "Red/System SIZE? function test script"
	Author:  "Nenad Rakocevic"
	File: 	 %size-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

~~~start-file~~~ "size"
  
===start-group=== "Size of literals and global variables"

	--test-- "sz-1"
	--assert 4 = size? 123
	
	--test-- "sz-2"	
	--assert 1 = size? #"a"
	
	--test-- "sz-3"
	--assert 4 = size? true
	
	--test-- "sz-4"
	--assert 4 = size? "A"

	--test-- "sz-5"
	sz-a: 123
	--assert 4 = size? sz-a
	
	--test-- "sz-6"
	sz-b: #"a"
	--assert 1 = size? sz-b
	
	--test-- "sz-7"
	sz-c: true
	--assert 4 = size? sz-c
	
	--test-- "sz-8"
	sz-d: "A"
	--assert 4 = size? sz-d

	--test-- "sz-9"
	sz-struct: struct [a [byte!]]
	--assert 4 = size? sz-struct
	--assert 1 = size? sz-struct/a

	--test-- "sz-10"
	sz-pointer: pointer [integer!]
	--assert 4 = size? sz-pointer
	--assert 4 = size? sz-pointer/value

===end-group===

===start-group=== "Size of literals and global variables"

sz-foo: func [
	/local
	sz-a 	[integer!]
	sz-b	[byte!]
	sz-c 	[logic!]
	sz-d	[c-string!]
	sz-struct [struct! [a [byte!]]]
	sz-pointer [pointer!]			;-- should be [pointer! [integer!]] (validation not fully implemented yet)
][
	--test-- "loc-sz-1"
	sz-a: 123
	--assert 4 = size? sz-a
	
	--test-- "loc-sz-2"
	sz-b: #"a"
	--assert 1 = size? sz-b
	
	--test-- "loc-sz-3"
	sz-c: true
	--assert 4 = size? sz-c
	
	--test-- "loc-sz-4"
	sz-d: "A"
	--assert 4 = size? sz-d

	--test-- "loc-sz-5"
	sz-struct: struct [a [byte!]]
	--assert 4 = size? sz-struct
	--assert 1 = size? sz-struct/a

	--test-- "loc-sz-6"
	sz-pointer: pointer [integer!]
	--assert 4 = size? sz-pointer
	--assert 4 = size? sz-pointer/value
]
sz-foo

===end-group===

~~~end-file~~~

