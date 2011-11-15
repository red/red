REBOL [
	Title:   "Red simple testing framework"
	Author:  "Peter W A Wood"
	File: 	 %quick-test.red
	Version: 0.1.0
	Rights:  "Copyright (C) 2011 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
	Note: {
	  I wrote this initial version in REBOL and intend to convert it to Red
	  once the bootstrap phase has been completed.  
	}
]

qtr: make object! [
  ;; text fields
  run-name:     copy ""
  file-name:    copy ""
  group-name:   copy ""
  test-name:    copy ""
  
  ;; counters
  data: make object! [
    tests:    0
    asserts:  0
    passes:   0 
    failures: 0
  ]
  run: make data []
  file: make data []
  
  ;; group switches
  group-name-not-prined: true
  group?: false
  
  init-group: does [
    group-name-not-prined: true
    group?: false
    group-name: ""
  ]
  
  init-data: func [
    data [object!]
  ][
    data/tests: 0
    data/asserts: 0
    data/passes: 0
    data/failures: 0
  ]
  
  init-run: does [
    init-data run
    init-group
  ]
  
  init-file: does [
    init-data file
    init-group
  ]
  
  start-run: func[
      title [string!]
  ][
    init-run
    run-name: title
    prin ["***Starting*** " title lf lf]
  ]
  
  start-file: func [
    title [string!]
  ][
    init-file
    prin ["~~~started test~~~ " title lf]
    file-name: title
    group?: false
  ]
  
  start-group: func [
    title [string!]
  ][
    group-name: title
    group?: true
  ]
  
  start-test: func [
    title [string!]
  ][
    test-name: title
    file/tests: file/tests + 1
  ]
  
  assert: func [
    assertion [logic!]
  ][
    file/asserts: file/asserts + 1
    
    either assertion [
       file/passes: file/passes + 1
    ][
      file/failures: file/failures + 1
      if group? [  
        if group-name-not-prined [
          prin [lf "===group=== " group-name lf]
          group-name-not-prined: false
        ]
      ]
      prin ["--test-- " test-name " FAILED**************" lf]
    ]
  ]
  
  end-group: func [] [
    init-group
  ]
  
  end-file: func [] [
    prin [lf "~~~finished test~~~ " file-name lf]
    print-totals file
    prin lf
    
    ;; update run totals
    run/passes: run/passes + file/passes
    run/asserts: run/asserts + file/asserts
    run/failures: run/failures + file/failures
    run/tests: run/tests + file/tests
  ]
  
  end-run: func [][
    prin ["***Finished*** " run-name lf]
    print-totals run
  ]
  
  print-totals: func [
    data [object!]
  ][
    prin ["  Number of Tests Performed:      " data/tests lf]
    prin ["  Number of Assertions Performed: " data/asserts lf]
    prin ["  Number of Assertions Passed:    " data/passes lf]
    prin ["  Number of Assertions Failed:    " data/failures lf]
    if data/failures <> 0 [
      prin ["****************TEST FAILURES****************" lf]
    ]
  ]
  
  ;; create the test "dialect"
  set '***start-run***        :start-run
  set '~~~start-file~~~       :start-file
  set '===start-group===      :start-group
  set '--test--               :start-test
  set '--assert               :assert
  set '===end-group===        :end-group
  set '~~~end-file~~~         :end-file
  set '***end-run***          :end-run
  
]
