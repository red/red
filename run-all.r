REBOL [
  Title:   "Builds and Runs All Red and Red/System Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.2.1
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]


;; function to find and run-tests and to build auto tests if needed
run-all-script: func [
	dir [file!]
	/auto-tests
][
  qt/tests-dir: system/script/path/:dir
  foreach line read/lines dir/run-all.r [
  	  either auto-tests [
  	  	  if any [
  	  	  	  find line "qt/make-if-needed?"
  	  	  ][
  	  	  	  do line
  	  	  ]
  	  ][
  	  	  if any [
  	  	  	  find line "===start-group"
  	  	  	  find line "--run-"
  	  	  ][
  	  	  	  do line
  	  	  ]
  	  ]
  ]
]

;; should we run non-interactively?
batch-mode: all [system/options/args find system/options/args "--batch"]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true
store-current-dir: what-dir

change-dir %quick-test/

do %quick-test.r

;; run the tests
print rejoin ["Quick-Test v" qt/version]
print rejoin ["REBOL " system/version]

start-time: now/precise

***start-run-quiet*** "Complete Red Test Suite"

run-all-script/auto-tests %../red/tests/
run-all-script/auto-tests %../red-system/tests/
do %../red/tests/source/units/make-interpreter-auto-test.r
qt/script-header: "Red []"
run-all-script %../red/tests/
qt/script-header: "Red/System []"
run-all-script %../red-system/tests/

***end-run-quiet***

end-time: now/precise
print ["       in" difference end-time start-time newline]
system/options/quiet: store-quiet-mode
change-dir store-current-dir
either batch-mode [
  quit/return either qt/test-run/failures > 0 [1] [0]
] [
  ask "hit enter to finish"
  print ""
  qt/test-run/failures
]
