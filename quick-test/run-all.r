REBOL [
  Title:   "Builds and Runs All Red and Red/System Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.1.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]
;; function to find and run-tests
run: func [dir [file!]][
  qt/tests-dir: dir
  foreach line read/lines dir/run-all.r [
    if any [
      find line "===start-group"
      find line "--run-"
    ][
      do line
    ]
  ]
]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

do %quick-test.r

;; run the tests
print rejoin ["Quick-Test v" system/script/header/version]
print rejoin ["REBOL " system/version]

start-time: now/precise

***start-run-quiet*** "Complete Red Test Suite"

run %../red/tests/
run %../red-system/tests/

***end-run-quiet***

end-time: now/precise
print ["       in" difference end-time start-time newline]
system/options/quiet: store-quiet-mode
ask "hit enter to finish"
print ""


