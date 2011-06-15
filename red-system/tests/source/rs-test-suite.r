REBOL [
  Title:   "Part of a basic test suite for Red/System"
	File: 	 %rs-test-suite.r
	Version: 0.2
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                    ;; revert to tests/ directory (from runnable)
if not value? 'qt [do %quick-test-quick-test.r]
       
***start-run*** "Red/System Test Suite"

===start-group=== "Datatype tests"
  --run-test-file %source/units/logic-test.reds
  --run-test-file %source/units/integer-test.reds
  --run-test-file %source/units/byte-test.reds
  --run-test-file %source/units/c-string-test.reds
  --run-test-file %source/units/struct-test.reds
  --run-test-file %source/units/pointer-test.reds
  --run-test-file %source/units/cast-test.reds
  --run-test-file %source/units/alias-test.reds
===end-group===

===start-group=== "Native functions tests"
  --run-test-file %source/units/not-test.reds
  --run-test-file %source/units/size-test.reds
===end-group===

===start-group=== "Special natives tests"
  --run-test-file %source/units/exit-test.reds
  --run-test-file %source/units/return-test.reds
===end-group===

===start-group=== "Math operators tests"
  --run-test-file %source/units/modulo-test.reds
===end-group===

===start-group=== "Infix syntax for functions"
  --run-test-file %source/units/infix-test.reds
===end-group===

===start-group=== "Conditional tests"
  --run-test-file %source/units/conditional-test.reds
===end-group===

===start-group=== "Compiler Tests"
  --run-script %source/compiler/alias-test.r
  --run-script %source/compiler/cast-test.r
  --run-script %source/compiler/comp-err-test.r
  --run-script %source/compiler/exit-test.r
  --run-script %source/compiler/int-literals-test.r
  --run-script %source/compiler/output-test.r
  --run-script %source/compiler/return-test.r
  --run-script %source/compiler/cond-expr-test.r
  --run-script %source/compiler/inference-test.r
  --run-script %source/compiler/callback-test.r
  --run-script %source/compiler/infix-test.r
===end-group===

***end-run***
