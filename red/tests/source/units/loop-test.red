Red [
	Title:   "Red loops test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %loop-test.reds
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

~~~start-file~~~ "loop"

===start-group=== "basic repeat tests"

  --test-- "br1"                      ;; Documenting non-local index counter
    br1-i: 0
    repeat br1-i 100 [ ]
  --assert 101 = br1-i                
  
  --test-- "br2"                      ;; Documenting non-local index counter
    br2-i: -99
    repeat br2-i 100 [ ]
  --assert 101 = br2-i 
  
  --test-- "br3"                      ;; Documenting non-local index counter
    repeat br3-i 100 [ ]
  --assert 101 = br3-i
  
  --test-- "br4"
    br4-i: 0
    repeat br4-counter 0 [br4-i: br4-i + 1]
  --assert 0 = br4-i

  --test-- "br5"
    br5-i: 0
    repeat br5-counter 0 [br5-i: br5-i + 1]
  --assert 0 = br5-i
  
===end-group===

===start-group=== "basic until tests"

  --test-- "bu1"
    bul-i: 0
    until [
      bu1-i: bu1-i + 1
      bul-i > 10
    ]
  --assert bu1-i = 11 
  
===end-group=== 

===start-group=== "basic loop tests"

  --test-- "bl1"                      ;; Documenting non-local index counter
    i: 10
    loop i [i: i - 1]
  --assert i = 0
  
  --test-- "bl2"                      ;; Documenting non-local index counter
    i: -1
    loop i [i: i + 1]
  --assert i = -1
  
  --test-- "bl3"                      ;; Documenting non-local index counter
    i: 0
    loop i [i: i + 1]
  --assert i = 0
  
  --test-- "b14"
    j: 0
    loop 0 [j: j + 1]
  --assert j = 0
  
  --test-- "b15"
    j: 0
    loop -1 [j: j + 1]
  --assert j = 0
  
===end-group===

===start-group=== "mixed tests"
        
    --test-- "ml1"                      ;; Documenting non-local index counter
    a: 0
    repeat c 4 [
		loop 5 [a: a + 1]
	]
    --assert a = 20 

===end-group===
    
~~~end-file~~~

