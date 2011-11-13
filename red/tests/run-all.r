REBOL [
  Title:   "Builds and Runs the Red Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.1.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

do %../../quick-test/quick-test.r
qt/tests-dir: what-dir

;; run the tests
print rejoin ["Quick-Test v" system/script/header/version]
print rejoin ["REBOL " system/version]

start-time: now/precise

***start-run-quiet*** "Red Test Suite"

===start-group=== "Red/System runtime tests"
  --run-test-file-quiet %source/runtime/utils-test.reds
===end-group===

***end-run-quiet***

end-time: now/precise
print ["       in" difference end-time start-time newline]
system/options/quiet: store-quiet-mode
ask "hit enter to finish"
print ""


