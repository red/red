REBOL [
  Title:   "Part of a basic test suite for Red/System"
	File: 	 %rs-test-suite.r
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                          ;; revert to tests/ directory (from runable)
if not value? 'qt [do %quick-test-quick-test.r]
       
***start-run*** "Red/System Test Suite - Part II"

  --run-script %source/compiler/alias-test.r
  --run-script %source/compiler/cast-test.r
  --run-script %source/compiler/comp-err-test.r
  --run-script %source/compiler/exit-test.r
  --run-script %source/compiler/int-literals-test.r
  --run-script %source/compiler/output-test.r
  --run-script %source/compiler/return-test.r
  --run-script %source/compiler/cond-expr-test.r
  --run-script %source/compiler/inference-test.r

***end-run***
