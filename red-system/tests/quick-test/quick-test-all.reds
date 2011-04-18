Red/System [
	Title:   "Red/System simple testing framework - test-run element"
	Author:  "Peter W A Wood"
	File: 	 %quick-test-all.reds
	Version: 0.1.0
	Rights:  "Copyright (C) 2011 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#include %prin-int.reds

;; counters
qt-run-no-tests: 0
qt-run-passes: 0  
qt-run-failures: 0

qt-init-run: func [] [
  qt-run-no-tests: 0
  qt-run-passes: 0
  qt-run-failures: 0
]

qt-start-run: func[
    title [c-string!]
][
  qt-init-run
  prin "Tests Started "
  print title
  print ""
]

qt-end-run: func [][
  print "Test Run Finished"
  prin "Number of Tests Performed: "
  prin-int qt-run-no-tests
  print ""
  prin "Number of Tests Passed:    "
  prin-int qt-run-passes
  print ""
  prin "Number of Tests Failed:    "
  prin-int qt-run-failures
  print ""
  if qt-run-failures <> 0 [
    print "****************TEST FAILURES****************"
  ]
]

qt-update-totals: func [] [
  ;; relies on qt-file- global variables being loaded in quick-test.reds
  qt-run-passes: qt-run-passes + qt-file-passes
  qt-run-failures: qt-run-failures + qt-file-failures
  qt-run-no-tests: qt-run-no-tests + qt-file-no-tests
]


