Red/System [
	Title:   "Red/System simple testing framework"
	Author:  "Peter W A Wood"
	File: 	 %quick-test.reds
	Version: 0.4.2
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

;; allocate string memory
qt-run-name:    "123456789012345678901234567890"
qt-file-name:   "123456789012345678901234567890"
qt-group-name:  "123456789012345678901234567890"
qt-test-name:   "123456789012345678901234567890"

;; counters
qt-run: declare struct! [
  tests     [integer!]
  asserts   [integer!]
  passes    [integer!]
  failures  [integer!]
]
qt-file: declare struct! [
  tests     [integer!]
  asserts   [integer!]
  passes    [integer!]
  failures  [integer!]
]
;; group switches
qt-group-name-not-printed: true
qt-group?: false

_qt-init-group: does [
  
  qt-group-name-not-printed: true
  qt-group?: false
  qt-group-name: ""
]

qt-init-run: func [] [
  qt-run/tests:     0
  qt-run/asserts:   0
  qt-run/passes:    0
  qt-run/failures:  0
  _qt-init-group
]

qt-init-file: func [] [
  qt-file/tests:     0
  qt-file/asserts:   0
  qt-file/passes:    0
  qt-file/failures:  0
  _qt-init-group
]

***start-run***: func[
    title [c-string!]
][
  qt-init-run
  qt-run-name: title
  print ["***Starting*** " title lf lf]
]

~~~start-file~~~: func [
  title [c-string!]
][
  qt-init-file
  print ["~~~started test~~~ " title lf]
  qt-file-name: title
  qt-group?: false
]

===start-group===: func [
  title [c-string!]
][
  qt-group-name: title
  qt-group?: true
]

--test--: func [
  title [c-string!]
][
  qt-test-name: title
  qt-file/tests: qt-file/tests + 1
]

--assert: func [
  assertion [logic!]
][
  qt-file/asserts: qt-file/asserts + 1
  
  either assertion [
     qt-file/passes: qt-file/passes + 1
  ][
    qt-file/failures: qt-file/failures + 1
    if qt-group? [  
      if qt-group-name-not-printed [
        print [lf "===group=== " qt-group-name lf]
        qt-group-name-not-printed: false
      ]
    ]
    print ["--test-- " qt-test-name " FAILED**************" lf]
  ]
]

--assertf~=: func[
  x           [float!]
  y           [float!]
  e           [float!]
  /local
    diff      [float!]
    e1        [float!]
    e2        [float!]
][
  ;; calculate tolerance to use
  ;;    as e * max (1, x, y)
  either x > 0.0 [
    e1: x * e
  ][
    e1: -1.0 * x * e
  ]
  if e > e1 [e1: e]
  either y > 0.0 [
    e2: y * e
  ][
    e2: -1.0 * y * e
  ]
  if e1 > e2 [e2: e1]
  
  ;; perform almost equal check
  either x > y [
    diff: x - y
  ][
    diff: y - x
  ]
  either diff > e2 [
    --assert false
  ][
    --assert true
  ]
]

--assertf32~=: func[
  x           [float32!]
  y           [float32!]
  e           [float32!]
  /local
    diff      [float32!]
    e1        [float32!]
    e2        [float32!]
][
  ;; calculate tolerance to use
  ;;    as e * max (1, x, y)
  either x > as float32! 0.0 [
    e1: x * e
  ][
    e1: as float32! -1.0 * x * e
  ]
  if e > e1 [e1: e]
  either y > as float32! 0.0 [
    e2: y * e
  ][
    e2: as float32! -1.0 * y * e
  ]
  if e1 > e2 [e2: e1]
  
  ;; perform almost equal check
  either x > y [
    diff: x - y
  ][
    diff: y - x
  ]
  either diff > e2 [
    --assert false
  ][
    --assert true
  ]
]

 
===end-group===: func [] [
  _qt-init-group
]

~~~end-file~~~: func [] [
  print ["~~~finished test~~~ " qt-file-name lf]
  qt-print-totals qt-file/tests
                  qt-file/asserts
                  qt-file/passes 
                  qt-file/failures
  print lf
  
  ;; update run totals
  qt-run/passes: qt-run/passes + qt-file/passes
  qt-run/asserts: qt-run/asserts + qt-file/asserts
  qt-run/failures: qt-run/failures + qt-file/failures
  qt-run/tests: qt-run/tests + qt-file/tests
]

***end-run***: func [][
  print ["***Finished*** " qt-run-name lf]
  qt-print-totals qt-run/tests
                  qt-run/asserts
                  qt-run/passes
                  qt-run/failures
]

qt-print-totals: func [
  tests     [integer!]
  asserts   [integer!]
  passes    [integer!]
  failures  [integer!]
][
  print ["  Number of Tests Performed:      " tests lf]
  print ["  Number of Assertions Performed: " asserts lf]
  print ["  Number of Assertions Passed:    " passes lf]
  print ["  Number of Assertions Failed:    " failures lf]
  if failures <> 0 [
    print ["****************TEST FAILURES****************" lf]
  ]
]


