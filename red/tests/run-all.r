REBOL [
  Title:   "Builds and Runs the Red Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.3.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

do %../../quick-test/quick-test.r
qt/tests-dir: system/script/path

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
===end-group===

***end-run-quiet***

end-time: now/precise
print ["       in" difference end-time start-time newline]
system/options/quiet: store-quiet-mode
ask "hit enter to finish"
print ""


