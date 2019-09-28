Red/System [
	Title:   "Red/System lib test script"
	Author:  "Peter W A Wood"
	File: 	 %lib-test-source.reds
	Rights:  "Copyright (C) 2012-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

;; library declarations
#import [
	LIBM-file cdecl [
		test-abs-float: "fabs" [
			f		[float!]
			return:	[float!]
		]
		test-abs-int: "abs" [
			i		[integer!]
			return:	[integer!]
		]
	]
]

lt-array!: alias struct! [
	a			[integer!]
	b			[integer!]
	c			[integer!]
	d			[integer!]
]

lt-int!: alias struct! [
	i			[integer!]
]

#import [
	LIBC-file cdecl [
		test-memcpy: "memcpy" [
			to		[c-string!]
			from	[c-string!]
			len		[integer!]
		]
		test-qsort: "qsort" [
			array   [lt-array!]
			count   [integer!]
			size    [integer!]
			compare [function! [
				first   [lt-int!]
				second  [lt-int!] 
				return: [integer!]
			]]
		]
		test-strlen: "strlen" [
			str		[c-string!]
			return:	[integer!]
		]
	]
]


~~~start-file~~~ "library"
  
===start-group=== "calls"

	--test-- "lib1"
		--assert 2 = test-abs-int 2
	--test-- "lib2"
		--assert 2.0 = test-abs-float -2.0
	--test-- "lib3"
		s: "hello, world"
		--assert 12 = test-strlen s
	--test-- "lib4"
		new: "123456789012"
		old: "HW"
		test-memcpy new old 12
		--assert new/1 = #"H"
		--assert new/2 = #"W"
		--assert 2 = length? new
		--assert old/1 = #"H"
		--assert old/2 = #"W"
		--assert 2 = length? old
		
===end-group===

===start-group=== "callbacks"

	--test-- "libcallback1"
		lib-array: declare lt-array!
		lib-array/a: 4
		lib-array/b: 3
		lib-array/c: 2
		lib-array/d: 1
		lib-compare: func [
			[cdecl]
			first     [lt-int!]
			second    [lt-int!]
			return:   [integer!]
		][
			first/i - second/i
		]
		test-qsort lib-array 4 4 :lib-compare
		--assert 1 = lib-array/a
		--assert 2 = lib-array/b
		--assert 3 = lib-array/c
		--assert 4 = lib-array/d
    
===end-group===

#switch OS [
	Windows [
		#include %lib-win32-test.reds   
	]
	macOS [
		#include %lib-macOS-test.reds
	]
]
  
~~~end-file~~~

