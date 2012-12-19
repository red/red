REBOL [
  Title:   "Builds and Runs the Red Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.4.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; should we run non-interactively?
batch-mode: all [system/options/args find system/options/args "--batch"]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

do %../../quick-test/quick-test.r
qt/tests-dir: system/script/path

;; make auto files if needed
;; do not split these statements over two lines
make-dir %source/units/auto-tests
qt/make-if-needed? %source/units/auto-tests/integer-auto-test.red %source/units/make-integer-auto-test.r
qt/make-if-needed? %source/units/auto-tests/infix-equal-auto-test.red %source/units/make-equal-auto-test.r
qt/make-if-needed? %source/units/auto-tests/equal-auto-test.red %source/units/make-equal-auto-test.r

;; run the tests
print rejoin ["Quick-Test v" qt/version]
print rejoin ["REBOL " system/version]

start-time: now/precise

***start-run-quiet*** "Red Test Suite"

===start-group=== "Red compiler unit tests"
  --run-unit-test-quiet %source/compiler/lexer-test.r
===end-group===

===start-group=== "Red/System runtime tests"
  --run-test-file-quiet %source/runtime/tools-test.reds
  --run-test-file-quiet %source/runtime/unicode-test.reds
===end-group===

===start-group=== "Red Compiler tests"
  --run-script-quiet %source/compiler/print-test.r
  --run-script-quiet %source/compiler/regression-tests.r
  --run-script-quiet %source/compiler/run-time-error-test.r
===end-group===

===start-group=== "Red Units tests"
  --run-test-file-quiet-red %source/units/logic-test.red
  --run-test-file-quiet-red %source/units/conditional-test.red
  --run-test-file-quiet-red %source/units/series-test.red
  --run-test-file-quiet-red %source/units/serialization-test.red
  --run-test-file-quiet-red %source/units/function-test.red
  
===end-group===

===start-group=== "Auto-tests"
  --run-test-file-quiet-red %source/units/auto-tests/integer-auto-test.red
  --run-test-file-quiet-red %source/units/auto-tests/infix-equal-auto-test.red
  --run-test-file-quiet-red %source/units/auto-tests/equal-auto-test.red
===end-group===

***end-run-quiet***

end-time: now/precise
print ["       in" difference end-time start-time newline]
system/options/quiet: store-quiet-mode
either batch-mode [
  quit/return either qt/test-run/failures > 0 [1] [0]
] [
  ask "hit enter to finish"
  print ""
  qt/test-run/failures
]
