Red [
	Title:   "Red function test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %function-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

~~~start-file~~~ "function"

===start-group=== "Basic function tests"

	--test-- "fun-1"
		foo1: func [][1]
		--assert 1 = foo1
	
	--test-- "fun-2"
		foo2: func [a][a]
		--assert 5 = foo2 5
		--assert "a" = foo2 "a"
		--assert [123] = foo2 [123]
	
	--test-- "fun-3"
		foo3: func [a /local c][c: 1 a + c]
		--assert 3 = foo3 2
	
	--test-- "fun-4"
		foo4: func [a /ref][either ref [a][0]]
		--assert 0 = foo4 5
		--assert 5 = foo4/ref 5
	
	--test-- "fun-5"
		foo5: func [a /ref b][if ref [a: a + b] a * 2]
		--assert 10 = foo5 5
		--assert 16 = foo5/ref 5 3
	
	--test-- "fun-6"
		z: 10
		foo6: func [a [integer!] b [integer!] /ref d /local c][
			c: 2
			unless ref [d: 0]
			a + b * c + z + d
		]

		--assert 16 = foo6 1 2
		--assert 21 = foo6/ref 1 2 5
	
	--test-- "fun-7"
		bar:  func [] [foo7]
		foo7: func [] [42]
		--assert 42 = bar
	
	--test-- "fun-8"
		foo8: func ['a :b][
			--assert a = 'test
			--assert "(1 + 2)" = mold b
		]
		foo8 test (1 + 2)
		
	--test-- "fun-9"
		foo9: func [/local cnt][
			cnt: [0]
			cnt/1: cnt/1 + 1
		]
		--assert 1 = foo9
		--assert 2 = foo9
		--assert 3 = foo9
	
	--test-- "fun-10"
		foo10: func [a][a + 0]
		foo10: func [][1]
		--assert 1 = foo10 "dummy"						;-- make it crash if wrong function referenced
	
===end-group===

===start-group=== "Alternate constructor tests"
	
	--test-- "fun-alt-1"
		z: 0
		alt1: function [a][
			z: 2
			a + z
		]
		--assert 10 = alt1 8
		--assert z = 0
	
	--test-- "fun-alt-2"
		alt2: does [123]
		--assert 123 = alt2
		
	--test-- "fun-alt-3"
		alt3: has [c][c: 1 c]
		--assert 1 = alt3

===end-group===


===start-group=== "Exit and Return tests"
	
	--test-- "fun-exit-1"
		ex1: does [123 exit 0]
		--assert unset! = type? ex1
		
	--test-- "fun-exit-2"
		ex2: does [if true [exit] 0]
		--assert unset! = type? ex2
		
	--test-- "fun-exit-3"
		ex3: does [until [if true [if true [exit]] true] 0]
		--assert unset! = type? ex3
		
	--test-- "fun-ret-1"
		ret1: does [return true]
		--assert ret1
		
	--test-- "fun-ret-2"
		ret2: does [return 123]
		--assert 123 = ret2
		
	--test-- "fun-ret-3"
		ret3: does [if true [return 3]]
		--assert 3 = ret3
	
	--test-- "fun-ret-4"
		ret4: does [return 1 + 1]
		--assert 2 = ret4
		
	--test-- "fun-ret-5"
		ret5: does [return either false [12][34]]
		--assert 34 = ret5
		
	--test-- "fun-ret-6"
		ret6: func [i [integer!]][
			until [
				if true [
					if i = 0 [
						if true [return 0]
						return 1
					]
					return 2
				]
				return 3
				true
			]
		]
		--assert 0 = ret6 0
		--assert 2 = ret6 1
		

===end-group===

===start-group=== "Reflection"
	clean-strings: func [blk [block!]][
		blk: copy blk
		forall blk [if string? blk/1 [remove blk blk: back blk]]
		blk
	]
	
	--test-- "fun-ref-1"
		ref1: func [a b][a + b]
		--assert [a b] = spec-of :ref1
		--assert [a + b] = body-of :ref1
	 
	--test-- "fun-ref-2"
		blk: clean-strings spec-of :append	
		--assert blk = [
			series [series!] value [any-type!] /part length [number! series!]
			/only /dup count [number!] return: [series!]
		]
	
	--test-- "fun-ref-3"
		blk: clean-strings spec-of :set	
		--assert blk = [word [any-word! block!] value [any-type!] /any return: [any-type!]]
		
	--test-- "fun-ref-4"
		blk: clean-strings spec-of :<
		--assert blk = [value1 [any-type!] value2 [any-type!]]

===end-group===

===start-group=== "Reported issues"
  --test-- "issue #415"
    i415-f: func [] [
      g: func [] [1]
      g
    ]
  --assert 1 = i415-f

===end-group===

~~~end-file~~~

