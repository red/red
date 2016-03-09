REBOL [
	Title:   "Red/System callback compilation test script"
	Author:  "Nenad Rakocevic"
	File: 	 %callback-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../


;=== Test only callback compilation, not execution ===


~~~start-file~~~ "callback-compile"

	--test-- "simple callback 1"
		--compile-this {
			Red/System []
			#import [
				"foo.dll" cdecl [
					foo: "foo" [
						fun 	[function! [a [integer!] b [integer!] return: [logic!]]]
						return: [integer!]
					]
				]
			]
			
			compare: func [
				[cdecl]
				left [integer!] right [integer!]
				return: [logic!]
			][
				left <= right
			]
			
			foo :compare
			compare 4 5
		}
		--assert qt/compile-ok?
		
~~~end-file~~~


~~~start-file~~~ "callback-err"

	--test-- "inference error 1"
		--compile-this {
			Red/System []
			#import [
				"foo.dll" cdecl [
					foo: "foo" [
						fun 	[function! [a [integer!] b [integer!] return: [logic!]]]
						return: [integer!]
					]
				]
			]
			
			compare: func [
				[cdecl]
				left [integer!]
				return: [logic!]
			][
				left <= right
			]
			
			foo :compare
		}
		--assert-msg? "*** Compilation Error: argument type mismatch on calling: foo"
		--clean
		
	--test-- "inference error 2"
		--compile-this {
			Red/System []
			#import [
				"foo.dll" cdecl [
					foo: "foo" [
						fun 	[function! [a [integer!] b [integer!] return: [logic!]]]
						return: [integer!]
					]
				]
			]
			
			compare: func [
				[cdecl]
				left [integer!] right [byte!]
				return: [logic!]
			][
				left <= right
			]
			
			foo :compare
		}
		--assert-msg? "*** Compilation Error: argument type mismatch on calling: foo"
		--clean
	
~~~end-file~~~


