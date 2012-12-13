Red [
	Title:   "Red case series test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %infix-equal-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012, 2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;make-length:***makelength***             ;; used to create equal-auto-test

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

~~~start-file~~~ "infix-equal"

===start-group=== "same datatype"

  --test-- "ie-same-datatype-1"
  --assert 0 = 0 
  
  --test-- "ie-same-datatype-2"
  --assert 1 = 1 
  
  --test-- "ie-same-datatype-3"
  --assert FFFFFFFFh = -1
  
  --test-- "ie-same-datatype-4"
  --assert [] = []
  
  --test-- "ie-same-datatype-5"
  --assert [a] = [a]
  
  --test-- "ie-same-datatype-6"
  --assert [A] = [a]
  
  --test-- "ie-same-datatype-7"
  --assert ['a] = [a]
  
  --test-- "ie-same-datatype-8"
  --assert [a:] = [a]
  
  --test-- "ie-same-datatype-9"
  --assert [:a] = [a]

  --test-- "ie-same-datatype-10"
  --assert [abcde] = [abcde]
  
  --test-- "ie-same-datatype-11"
  --assert [a b c d] = [a b c d]
  
  --test-- "ie-same-datatype-12"
  --assert [b c d] = next [a b c d]
  
  --test-- "ie-same-datatype-13"
  --assert [b c d] = (next [a b c d])
  
  --test-- "ie-same-datatype-14"
  --assert "a" = "A"
  
  --test-- "ie-same-datatype-15"
  --assert "abcdeè" = "abcdeè"
  
  --test-- "ie-same-datatype-16"
  --assert "abcdeè" = "abcdeè"
  
  --test-- "ie-same-datatype-17"
  --assert "abcde^(2710)é^(010000)" = "abcde^(2710)é^(010000)"
  
  --test-- "ie-same-datatype-18"
  --assert "a" = "a"
  
  --test-- "ie-same-datatype-19"
  --assert [d] = back tail [a b c d]
  
  --test-- "ie-same-datatype-20"
  --assert "2345" = next "12345"
  
  --test-- "ie-same-datatype-21"
  --assert "5" = back tail "12345"
  
  --test-- "ie-same-datatype-22"
  --assert #"z" = #"z"
  
  --test-- "ie-same-datatype-23"
  --assert  #"e" = #"è"
  
  --test-- "ie-same-datatype-24"
  --assert #"^(010000)" = #"^(010000)"
  
  --test-- "ie-same-datatype-25"
  --assert true = true
  
  --test-- "ie-same-datatype-26"
  --assert false = false
  
  --test-- "ie-same-datatype-27"
  --assert not false = true
  
  --test-- "ie-same-datatype-28"
  --assert none = none
  
  --test-- "ie-same-datatype-29"
  --assert 'a = 'a
  
  --test-- "ie-same-datatype-30"
  --assert 'a = 'A
  
  --test-- "ie-same-datatype-31"
  --assert (first [a]) = first [a]
  
  --test-- "ie-same-datatype-32"
  --assert 'a = first [A]
  
  --test-- "ie-same-datatype-33"
  --assert 'a = first ['a]
  
  --test-- "ie-same-datatype-34"
  --assert 'a = first [:a]
 
  --test-- "ie-same-datatype-33"
  --assert 'a = first [a:]
  
  --test-- "ie-same-datatype-34"
  --assert (first [a:]) = first [a:]
  
  --test-- "ie-same-datatype-33"
  --assert (first [:a]) = first [:a]
  
===end-group===

~~~end-file~~~

