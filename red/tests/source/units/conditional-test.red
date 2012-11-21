Red [
	Title:   "Red conditonal test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %conditional-test.reds
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

~~~start-file~~~ "conditional"

  --test-- "nested ifs inside a function with many return points"
    niff: func [
      i       [integer!]
      return: [integer!]
    ][
      if i > 127 [
        if 192 = i [return i]
        if 193 = i [return i]
        if 244 < i [return i]
        if i < 224 [
          if i = 208 [return i]
        ]
      ]
      return -1
    ]
  --assert 208 = niff 208
  --assert -1 = niff 1
  --assert -1 = niff 224
  
  --test-- "simple if"
    i: 0
    if true [i: 1]
  --assert i = 1
  
  --test-- "nested if"
    i: 0
    if true [
      if true [
        i: 1
      ]
    ]
  --assert i = 1
  
  --test-- "double nested if"
    i: 0
    if true [
      if true [
        if true [
          i: 1
        ]
      ]
    ]
  --assert i = 1
  
  --test-- "triple nested if"
    i: 0
    if true [
      if true [
        if true [
          if true [
            i: 1
          ]
        ]
      ]
    ]
  --assert i = 1
    
  --test-- "either basic 1"
  --assert 1 = either true [1] [2]
  
  --test-- "either basic 2"
  --assert 2 = either false [1] [2]
  
  --test-- "either basic 3"
  --assert 1 = either 42 [1] [2]
  
    
~~~end-file~~~

