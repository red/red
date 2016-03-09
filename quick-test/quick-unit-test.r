REBOL [
	Title:   "Red Bootstrap unit testing framework"
	Author:  "Peter W A Wood"
	File: 	 %quick-unit-test.r
	Version: 0.2.0
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

qut: make object! [
  
  test-print: :print
  test-prin: :prin
  output: copy ""
  set 'print func[v][append output rejoin [v lf]]
  set 'prin func[v][append output reduce v]
  
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
    test-prin ["***Starting*** " title lf lf]
  ]
  
  start-file: func [
    title [string!]
  ][
    init-file
    test-prin ["~~~started test~~~ " title lf]
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
    output: copy ""
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
          test-prin [lf "===group=== " group-name lf]
          group-name-not-prined: false
        ]
      ]
      test-prin ["--test-- " test-name " FAILED**************" lf]
    ]
  ]
  
  assert-printed?: func [msg] [
    assert found? find qut/output msg
  ]
  
  end-group: func [] [
    init-group
  ]
  
  end-file: func [] [
    test-prin ["~~~finished test~~~ " file-name lf]
    print-totals file
    test-prin lf
    
    ;; update run totals
    run/passes: run/passes + file/passes
    run/asserts: run/asserts + file/asserts
    run/failures: run/failures + file/failures
    run/tests: run/tests + file/tests
  ]
  
  end-run: func [][
    test-prin ["***Finished*** " run-name lf]
    print-totals run
    set 'print :test-print
    set 'prin :test-print
  ]
  
  print-totals: func [
    data [object!]
  ][
    test-prin ["  Number of Tests Performed:      " data/tests lf]
    test-prin ["  Number of Assertions Performed: " data/asserts lf]
    test-prin ["  Number of Assertions Passed:    " data/passes lf]
    test-prin ["  Number of Assertions Failed:    " data/failures lf]
    if data/failures <> 0 [
      test-prin ["****************TEST FAILURES****************" lf]
    ]
  ]
  
  ;; create the test "dialect"
  set '***start-run***        :start-run
  set '~~~start-file~~~       :start-file
  set '===start-group===      :start-group
  set '--test--               :start-test
  set '--assert               :assert
  set '--assert-printed?      :assert-printed?
  set '===end-group===        :end-group
  set '~~~end-file~~~         :end-file
  set '***end-run***          :end-run
  
]
