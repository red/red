Red [
	Title:   "Red case series test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %sereis-test.red
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

~~~start-file~~~ "series"

===start-group=== "first, second, third, fourth, fifth"

	--test-- "series-fstff-1"
	  sf1-ser:  [1 2 3 4 5]
	--assert 1 = first sf1-ser
	--assert 2 = second sf1-ser
	--assert 3 = third sf1-ser
	--assert 4 = fourth sf1-ser
	--assert 5 = fifth sf1-ser

	--test-- "series-fstff-2"
	  sf2-ser:  [1 2 3 4 5]
	--assert 2 = first next sf2-ser
	
	--test-- "series-fstff-3"
	  sf3-ser:  "12345"
	--assert 49 = first sf3-ser
	
	--test-- "series-fstff-4"
	  sf4-ser:  [1 2 3 4 5]
	--assert none = fifth next sf4-ser
	
	--test-- "series-fstff-5"
	  sf5-ser:  "12345"
	--assert 53 = fifth sf5-ser
	
	--test-- "series-fstff-6"
	  stf6-ser: #{000102}
	;;--assert 0 = first stf6-ser
	  
===end-group===

~~~end-file~~~

