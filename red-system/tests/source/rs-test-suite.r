REBOL [
  Title:   "Part of a basic test suite for Red/System"
	File: 	 %rs-test-suite.r
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                          ;; revert to tests/ directory (from runable)
if not value? 'qt [do %quick-test-quick-test.r]
       
qt/start-test-run "Red/System Test Suite - Part II"

qt/run-script %source/compiler/output-test.r
qt/run-script %source/compiler/comp-err-test.r

qt/end-test-run
