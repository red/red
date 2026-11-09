Red/System [
	Title:   "Red/System EXIT keyword test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %function-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
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

===start-group=== "cdecl functions"

	cdecl-int5!: alias function! [[cdecl] a [integer!] b [integer!] c [integer!] d [integer!] e [integer!] return: [integer!]]
	cdecl-mix!: alias function! [[cdecl] a [integer!] b [integer!] f [float!] return: [float!]]
	cdecl-int2: func [[cdecl] a [integer!] b [integer!] return: [integer!]][a * 10 + b]
	cdecl-int5: func [[cdecl] a [integer!] b [integer!] c [integer!] d [integer!] e [integer!] return: [integer!]][
		(((a * 10 + b) * 10 + c) * 10 + d) * 10 + e
	]
	cdecl-mix: func [[cdecl] a [integer!] b [integer!] f [float!] return: [float!]][
		(as float! a * 10 + b) * 10.0 + f
	]
	
	--test-- "cdecl-1"
		--assert 12 = cdecl-int2 1 2
	
	--test-- "cdecl-2"
		cdecl-2-sp: system/stack/top
		--assert 12345 = cdecl-int5 1 2 3 4 5
		--assert cdecl-2-sp = system/stack/top
	
	--test-- "cdecl-3"
		--assert 123.5 = cdecl-mix 1 2 3.5
	
	--test-- "cdecl-4"
		cdecl-4-s: declare struct! [int5 [cdecl-int5!] mix [cdecl-mix!]]
		cdecl-4-s/int5: as cdecl-int5! :cdecl-int5
		--assert 12345 = cdecl-4-s/int5 1 2 3 4 5
	
	--test-- "cdecl-5"
		cdecl-4-s/mix: as cdecl-mix! :cdecl-mix
		--assert 123.5 = cdecl-4-s/mix 1 2 3.5
  
===end-group===

===start-group=== "function pointer in a global variable"

	gfp-fn!: alias function! [a [integer!] return: [integer!]]
	gfp-cfn!: alias function! [[cdecl] a [integer!] b [integer!] return: [integer!]]
	gfp-inc: func [a [integer!] return: [integer!]][a + 1]
	gfp-sub: func [[cdecl] a [integer!] b [integer!] return: [integer!]][a - b]
	
	--test-- "gfp1"
		gfp1-ptr: as gfp-fn! :gfp-inc
		--assert 42 = gfp1-ptr 41
	
	--test-- "gfp2"
		gfp2-call: func [a [integer!] return: [integer!]][gfp1-ptr a]
		--assert 42 = gfp2-call 41
	
	--test-- "gfp3"
		gfp3-ptr: as gfp-cfn! :gfp-sub
		--assert 2 = gfp3-ptr 5 3
	
	--test-- "gfp4"
		gfp4-ctx: context [
			ptr: as gfp-fn! :gfp-inc
			val: ptr 1
		]
		--assert 2 = gfp4-ctx/val
		--assert 3 = gfp4-ctx/ptr 2
  
===end-group===

~~~end-file~~~
