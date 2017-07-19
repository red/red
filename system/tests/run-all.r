REBOL [
  Title:   "Builds and Runs the Red/System Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.8.3
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; should we run non-interactively?
batch-mode: all [system/options/args find system/options/args "--batch"]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

do %../../quick-test/quick-test.r
qt/tests-dir: system/script/path

;; set the default script header
qt/script-header: "Red/System []"

;; make auto files if needed
do %source/units/make-red-system-auto-tests.r
do %source/units/prepare-dependencies.r

;; run the tests
print ["Run-All    v" system/script/header/version]
print ["Quick-Test v" qt/version]
print ["REBOL       " system/version]
start-time: now/precise
print ["This test started at" start-time]

;; any .reds test with more than one space between --run-test-file-quiet and 
;;  the filename will be excluded from the ARM tests

***start-run-quiet*** "Red/System Test Suite"

===start-group=== "Compiler Tests"
  --run-script-quiet %source/compiler/alias-test.r
  --run-script-quiet %source/compiler/cast-test.r
  --run-script-quiet %source/compiler/comp-err-test.r
  --run-script-quiet %source/compiler/exit-test.r
  --run-script-quiet %source/compiler/int-literals-test.r
  --run-script-quiet %source/compiler/output-test.r
  --run-script-quiet %source/compiler/return-test.r
  --run-script-quiet %source/compiler/cond-expr-test.r
  --run-script-quiet %source/compiler/inference-test.r
  --run-script-quiet %source/compiler/callback-test.r
  --run-script-quiet %source/compiler/infix-test.r
  --run-script-quiet %source/compiler/not-test.r
  --run-script-quiet %source/compiler/print-test.r
  --run-script-quiet %source/compiler/enum-test.r
  --run-script-quiet %source/compiler/pointer-test.r
  --run-script-quiet %source/compiler/namespace-test.r
  --run-script-quiet %source/compiler/compiles-ok-test.r
  --run-script-quiet %source/compiler/dylib-test.r
  --run-test-file-quiet %source/compiler/define-test.reds
===end-group===

===start-group=== "Datatype tests"
  --run-test-file-quiet %source/units/logic-test.reds       
  --run-test-file-quiet %source/units/byte-test.reds
  --run-test-file-quiet %source/units/c-string-test.reds
  --run-test-file-quiet %source/units/struct-test.reds
  --run-test-file-quiet %source/units/pointer-test.reds
  --run-test-file-quiet %source/units/cast-test.reds
  --run-test-file-quiet %source/units/alias-test.reds
  --run-test-file-quiet %source/units/length-test.reds
  --run-test-file-quiet %source/units/null-test.reds
  --run-test-file-quiet %source/units/enum-test.reds
  --run-test-file-quiet %source/units/float-test.reds
  --run-test-file-quiet %source/units/float32-test.reds
  --run-test-file-quiet %source/units/lib-test.reds
  --run-test-file-quiet %source/units/get-pointer-test.reds
  --run-test-file-quiet %source/units/float-pointer-test.reds
===end-group===

===start-group=== "Context tests"
  --run-test-file-quiet %source/units/namespace-test.reds
===end-group===

===start-group=== "Native functions tests"
  --run-test-file-quiet %source/units/not-test.reds
  --run-test-file-quiet %source/units/size-test.reds
  --run-test-file-quiet %source/units/function-test.reds
  --run-test-file-quiet %source/units/case-test.reds
  --run-test-file-quiet %source/units/switch-test.reds
===end-group===

===start-group=== "Exceptions tests"
  --run-test-file-quiet %source/units/exit-test.reds
  --run-test-file-quiet %source/units/return-test.reds
  --run-test-file-quiet %source/units/exceptions-test.reds
===end-group===

===start-group=== "Math operators tests"
  --run-test-file-quiet %source/units/modulo-test.reds
  --run-test-file-quiet %source/units/math-mixed-test.reds
===end-group===

===start-group=== "Infix syntax for functions"
  --run-test-file-quiet %source/units/infix-test.reds
===end-group===

===start-group=== "Conditional tests"
  --run-test-file-quiet %source/units/conditional-test.reds
===end-group===

===start-group=== "System tests"
  --run-test-file-quiet %source/units/system-test.reds
===end-group===

===start-group=== "Auto-tests"
  --run-test-file-quiet %source/units/auto-tests/dylib-auto-test.reds

===end-group===

***end-run-quiet***

end-time: now/precise
print ["       in" difference end-time start-time newline]
print ["The test finished at" end-time]
system/options/quiet: store-quiet-mode
either batch-mode [
	quit/return either qt/test-run/failures > 0 [1] [0]
][
	print ["The test output was logged to" qt/log-file]
	ask "hit enter to finish"
	print ""
	qt/test-run/failures
]
