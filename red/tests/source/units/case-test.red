Red [
	Title:   "Red case function test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %case-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012, 2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

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


~~~start-file~~~ "case"

===start-group=== "case basics"

	--test-- "case-basic-1"
	ci:  0
	cia: 1
	case [true [0]]
	--assert cia = 1
	
	--test-- "case-basic-2"
	ci:  1
	cia: 2
	case [ci = 1 [cia: 2]]
	--assert cia = 2
	
	--test-- "case-basic-3"
	ci:  1
	cia: 2
	case [true [cia: 3]]
	--assert cia = 3
	
	--test-- "case-basic-4"
	ci:  0
	cia: 2
	case [ci <> 0 [cia: 0] true [cia: 3]]
	--assert cia = 3
	
	--test-- "case-basic-5"
	ci:  99
	cia: 2
	case [ci = 1 [cia: 2] true [cia: 3]]
	--assert cia = 3
	
	--test-- "case-basic-6"
	ci:  0
	cia: 1
	cia: case [true [2]]
	--assert cia = 2
	
	--test-- "case-basic-7"
	ci:  0
	cia: 2
	cia: case [ci <> 0 [0] true [3]]
	--assert cia = 3
	
	--test-- "case-basic-8"
	ci:  1
	cia: 2
	cia: case [ci = 1 [3]]
	--assert cia = 3
	
	--test-- "case-basic-9"
	ci:  1
	cia: 2
	case [ci = 1 [case [ci <> 0 [cia: 3] true [cia: 4]]]]
	--assert cia = 3
	
	--test-- "case-basic-10"
	ci:  1
	cia: 2
	cia: case [ci = 1 [case [ci <> 0 [3] true [4]]]]
	--assert cia = 3
	
	--test-- "case-basic-11"
	ci:  1
	cia: 2
	cia: case [ci = 1 [switch ci [1 [3] default [4]]]]
	--assert cia = 3
	
===end-group===

===start-group=== "case basics local"

	case-fun: func [/local ci cia][
		--test-- "case-loc-1"
		ci:  0
		cia: 1
		case [true [0]]
		--assert cia = 1

		--test-- "case-loc-2"
		ci:  1
		cia: 2
		case [ci = 1 [cia: 2]]
		--assert cia = 2

		--test-- "case-loc-3"
		ci:  1
		cia: 2
		case [true [cia: 3]]
		--assert cia = 3

		--test-- "case-loc-4"
		ci:  0
		cia: 2
		case [ci <> 0 [cia: 0] true [cia: 3]]
		--assert cia = 3

		--test-- "case-loc-5"
		ci:  99
		cia: 2
		case [ci = 1 [cia: 2] true [cia: 3]]
		--assert cia = 3

		--test-- "case-loc-6"
		ci:  0
		cia: 1
		cia: case [true [2]]
		--assert cia = 2

		--test-- "case-loc-7"
		ci:  0
		cia: 2
		cia: case [ci <> 0 [0] true [3]]
		--assert cia = 3

		--test-- "case-loc-8"
		ci:  1
		cia: 2
		cia: case [ci = 1 [3]]
		--assert cia = 3

		--test-- "case-loc-9"
		ci:  1
		cia: 2
		case [ci = 1 [case [ci <> 0 [cia: 3] true [cia: 4]]]]
		--assert cia = 3

		--test-- "case-loc-10"
		ci:  1
		cia: 2
		cia: case [ci = 1 [case [ci <> 0 [3] true [4]]]]
		--assert cia = 3

		--test-- "case-loc-11"
		ci:  1
		cia: 2
		cia: case [ci = 1 [switch ci [1 [3] default [4]]]]
		--assert cia = 3
	]
	case-fun
	
===end-group===

===start-group=== "case integer!"
	
#define case-int-1 [case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]]

	--test-- "case-int-1"
	  ci: 1
	  cia: 0
	  case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 1 = cia
	
	--test-- "case-int-2"
	  ci: 2
	  cia: 0
	  case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 2 = cia
	
	--test-- "case-int-3"
	  ci: 3
	  cia: 0
	  case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 3 = cia
	
	--test-- "case-int-4"
	  ci: 9
	  cia: 0
	  case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	  --assert 3 = cia

	--test-- "case-int-5"
	  ci: 1
	--assert 1 = case [ ci = 1 [1] ci = 2 [2] true [3]]

	--test-- "case-int-6"
	  ci: 1
	  cres: case [ ci = 1 [1] ci = 2 [2] true [3]]
	--assert 1 = cres
	
	--test-- "case-int-7"
	  ci: 2
	--assert 2 = case [ ci = 1 [1] ci = 2 [2] true [3]]
		
	--test-- "case-int-8"
	  ci: 2
	  cres: case [ ci = 1 [1] ci = 2 [2] true [3]]
	--assert 2 = cres

	--test-- "case-int-9"
	  ci: 3
	--assert 3 = case [ ci = 1 [1] ci = 2 [2] true [3]]
	
	--test-- "case-int-10"
	  ci: 3
	  cres: case [ ci = 1 [1] ci = 2 [2] true [3]]
	--assert 3 = cres
	
	--test-- "case-int-11"
	  ci: 10
	--assert 3 = case [ ci = 1 [1] ci = 2 [2] true [3]]
	
	--test-- "case-int-12"
	  ci: 10
	  cres: case [ ci = 1 [1] ci = 2 [2] true [3]]
	--assert 3 = cres

	case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]

	--test-- "case-int-13"
	  ci: 1
	  cia: 0
	--assert 1 = case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	
	--test-- "case-int-14"
	  ci: 1
	  cia: 0
	  cres: case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 1 = cres
	
	--test-- "case-int-15"
	  ci: 2
	  cia: 0
	--assert 2 = case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	
	--test-- "case-int-16"
	  ci: 2
	  cia: 0
	  cres: case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 2 = cres
	
	--test-- "case-int-17"
	  ci: 3
	  cia: 0
	--assert 3 = case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	
	--test-- "case-int-18"
	  ci: 3
	  cia: 0
	  cres: case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 3 = cres
	
	--test-- "case-int-19"
	  ci: 9
	  cia: 0
	--assert 3 = case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	
	--test-- "case-int-20"
	  ci: 9
	  cia: 0
	  cres: case [ ci = 1 [cia: 1] ci = 2 [cia: 2] true [cia: 3]]
	--assert 3 = cres
	
===end-group===


===start-group=== "case logic!"

  --test-- "case-logic-1"
    cl: true
  --assert case [ cl = true [true] cl = false [false] true [false]]
  
  --test-- "case-logic-2"
    cl: false
  --assert false = case [ cl = true [true] cl = false [false] true [true]]

===end-group===
  

~~~end-file~~~

