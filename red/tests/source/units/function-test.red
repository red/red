Red [
	Title:   "Red function test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %function-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;; start of quick-test
;; counters
qt-run-tests: 0 
qt-run-asserts: 0
qt-run-passes: 0
qt-run-failures: 0
qt-file-tests: 0 
qt-file-asserts: 0 
qt-file-passes: 0 
qt-file-failures: 0

;; group switches
qt-group-name-not-printed: true
qt-group?: false

_qt-init-group: func [] [
  qt-group-name-not-printed: true
  qt-group?: false
  qt-group-name: ""
]

qt-init-run: func [] [
  qt-run-tests: 0 
  qt-run-asserts: 0
  qt-run-passes: 0
  qt-run-failures: 0
  _qt-init-group
]

qt-init-file: func [] [
  qt-file-tests: 0 
  qt-file-asserts: 0 
  qt-file-passes: 0 
  qt-file-failures: 0
  _qt-init-group
]

***start-run***: func[
    title [string!]
][
  qt-init-run
  qt-run-name: title
  prin "***Starting*** " 
  print title
]

~~~start-file~~~: func [
  title [string!]
][
  qt-init-file
  prin "~~~started test~~~ "
  print title
  qt-file-name: title
  qt-group?: false
]

===start-group===: func [
  title [string!]
][
  qt-group-name: title
  qt-group?: true
]

--test--: func [
  title [string!]
][
  qt-test-name: title
  qt-file-tests: qt-file-tests + 1
]

--assert: func [
  assertion [logic!]
][

  qt-file-asserts: qt-file-asserts + 1
  
  either assertion [
     qt-file-passes: qt-file-passes + 1
  ][
    qt-file-failures: qt-file-failures + 1
    if qt-group? [  
      if qt-group-name-not-printed [
        prin "===group=== "
        print qt-group-name
        qt-group-name-not-printed: false
      ]
    ]
    prin "--test-- " 
    prin qt-test-name
    print " FAILED**************"
  ]
]
 
===end-group===: func [] [
  _qt-init-group
]

qt-print-totals: func [
  tests     [integer!]
  asserts   [integer!]
  passes    [integer!]
  failures  [integer!]
][
  prin  "  Number of Tests Performed:      " 
  print tests 
  prin  "  Number of Assertions Performed: "
  print asserts
  prin  "  Number of Assertions Passed:    "
  print passes
  prin  "  Number of Assertions Failed:    "
  print failures
  if failures <> 0 [
    print "****************TEST FAILURES****************"
  ]
]

~~~end-file~~~: func [] [
  print ""
  prin "~~~finished test~~~ " 
  print qt-file-name
  qt-print-totals qt-file-tests qt-file-asserts qt-file-passes qt-file-failures
  print ""
  
  ;; update run totals
  qt-run-passes: qt-run-passes + qt-file-passes
  qt-run-asserts: qt-run-asserts + qt-file-asserts
  qt-run-failures: qt-run-failures + qt-file-failures
  qt-run-tests: qt-run-tests + qt-file-tests
]

***end-run***: func [][
  prin "***Finished*** "
  print qt-run-name
  qt-print-totals qt-run-tests
                  qt-run-asserts
                  qt-run-passes
                  qt-run-failures
]

;; end of quick test

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
	
	--test-- "fun-ref-1"
		ref1: func [a b][a + b]
		--assert [a b] = spec-of :ref1
		--assert [a + b] = body-of :ref1
	 
	--test-- "fun-ref-2"
		--assert (spec-of :append) = [
			series [series!] value [any-type!] /part length [number! series!]
			/only /dup count [number!] return: [series!]
		]
	
	--test-- "fun-ref-3"
		--assert (spec-of :set) = [word [lit-word!] value [any-type!] /any return: [any-type!]]
		
	--test-- "fun-ref-4"
		--assert (spec-of :<) = [value1 [any-type!] value2 [any-type!]]

===end-group===

~~~end-file~~~

