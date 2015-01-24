REBOL [
	Title:   "Builds and Runs the Red Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.5.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; should we run non-interactively?
batch-mode: all [system/options/args find system/options/args "--batch"]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

do %../quick-test/quick-test.r
qt/tests-dir: system/script/path

;; set the default script header
qt/script-header: "Red []"

;; make auto files if needed
do %source/units/make-red-auto-tests.r
do %source/units/make-interpreter-auto-tests.r 

;; run the tests
print rejoin ["Quick-Test v" qt/version]
print rejoin ["REBOL " system/version]

start-time: now/precise

--setup-temp-files

***start-run-quiet*** "Red Test Suite"

===start-group=== "Red compiler unit tests"
	--run-unit-test-quiet %source/compiler/lexer-test.r
===end-group===

===start-group=== "Red/System runtime tests"
  	--run-test-file-quiet %source/runtime/tools-test.reds
  	--run-test-file-quiet %source/runtime/unicode-test.red
===end-group===

===start-group=== "Red Compiler tests"
  	--run-script-quiet %source/compiler/print-test.r
  	--run-script-quiet %source/compiler/regression-tests.r
  	--run-script-quiet %source/compiler/run-time-error-test.r
  	--run-script-quiet %source/compiler/compile-error-test.r
===end-group===

===start-group=== "Red Units tests"
    --run-test-file-quiet %source/units/object-test.red
  	--run-test-file-quiet %source/units/logic-test.red
  	--run-test-file-quiet %source/units/conditional-test.red
  	--run-test-file-quiet %source/units/series-test.red
  	--run-test-file-quiet %source/units/path-test.red
  	--run-test-file-quiet %source/units/serialization-test.red
  	--run-test-file-quiet %source/units/function-test.red
  	--run-test-file-quiet %source/units/loop-test.red
  	--run-test-file-quiet %source/units/type-test.red
  	--run-test-file-quiet %source/units/find-test.red
  	--run-test-file-quiet %source/units/select-test.red
  	--run-test-file-quiet %source/units/binding-test.red
  	--run-test-file-quiet %source/units/evaluation-test.red
  	--run-test-file-quiet %source/units/load-test.red
  	--run-test-file-quiet %source/units/switch-test.red
  	--run-test-file-quiet %source/units/case-test.red
  	--run-test-file-quiet %source/units/routine-test.red
  	--run-test-file-quiet %source/units/append-test.red
  	--run-test-file-quiet %source/units/insert-test.red
  	--run-test-file-quiet %source/units/make-test.red
  	--run-test-file-quiet %source/units/system-test.red
  	--run-test-file-quiet %source/units/parse-test.red
  	--run-test-file-quiet %source/units/bitset-test.red
  	--run-test-file-quiet %source/units/same-test.red
  	--run-test-file-quiet %source/units/strict-equal-test.red
  	--run-test-file-quiet %source/units/integer-test.red
  	--run-test-file-quiet %source/units/char-test.red
  	--run-test-file-quiet %source/units/float-test.red
===end-group===

===start-group=== "Red Library tests"
	
===end-group===

===start-group=== "Auto-tests"
  	--run-test-file-quiet %source/units/auto-tests/integer-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/infix-equal-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/equal-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/infix-not-equal-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/not-equal-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/infix-lesser-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/lesser-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/infix-lesser-equal-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/lesser-equal-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/infix-greater-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/greater-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/infix-greater-equal-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/greater-equal-auto-test.red
===end-group===

===start-group=== "Interpreter Auto-tests"
  	--run-test-file-quiet %source/units/auto-tests/interp-binding-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-case-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-conditional-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-evaluation-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-find-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-function-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-load-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-logic-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-loop-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-select-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-serialization-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-series-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-type-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-switch-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-append-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-insert-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-system-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-parse-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-bitset-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-integer-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-float-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-char-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-object-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-equal-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-same-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-greater-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-inf-equal-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-strict-equal-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-inf-greater-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-inf-lesser-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-inf-lesser-equal-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-inf-not-equal-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-integer-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-float-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-lesser-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-lesser-equal-auto-test.red
  	--run-test-file-quiet %source/units/auto-tests/interp-not-equal-auto-test.red
  	
===end-group===

***end-run-quiet***

--delete-temp-files

end-time: now/precise
print ["       in" difference end-time start-time newline]
system/options/quiet: store-quiet-mode
either batch-mode [
	quit/return either qt/test-run/failures > 0 [1] [0]
][
	print ["The test output was logged to" qt/log-file]
	ask "hit enter to finish"
	print ""
	qt/test-run/failures
]
