Red/System [
	Title:   "Red/System simple testing framework"
	Author:  "Peter W A Wood"
	File: 	 %quick-test.reds
	Version: 0.1.0
	Rights:  "Copyright (C) 2011 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#include %prin-int.reds

;; counters
qt-file-no-tests: 0
qt-file-passes: 0 
qt-file-failures: 0 

 
qt-init-file: func [] [
  qt-file-no-tests: 0
  qt-file-passes: 0
  qt-file-failures: 0
]

qt-start-file: func [
  title [c-string!]
][
  qt-init-file
  prin "Tests Started - "
  print title
]

qt-assert: func [
  name [c-string!]
  assertion [logic!]
][
  qt-file-no-tests: qt-file-no-tests + 1
  
  either assertion [
     qt-file-passes: qt-file-passes + 1
  ][
    qt-file-failures: qt-file-failures + 1
    prin "Test "
    prin name
    print " FAILED**************"
  ]
]

qt-end-file: func [] [
  print "Test File Finished"
  _qt-print-totals qt-file-no-tests qt-file-passes qt-file-failures
  print ""
]

_qt-print-totals: func [
  tests     [integer!]
  passes    [integer!]
  failures  [integer!]
][
  prin "Number of Tests Performed: "
  prin-int tests
  print ""
  prin "Number of Tests Passed:    "
  prin-int passes
  print ""
  prin "Number of Tests Failed:    "
  prin-int failures
  print ""
  if failures <> 0 [
    print "****************TEST FAILURES****************"
  ]
]


