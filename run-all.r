REBOL [
	Title:   "Builds and Runs All Red and Red/System Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.2.1
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; function to find and run-tests
run-all-script: func [
	dir [file!]
][
	qt/tests-dir: system/script/path/:dir
  	foreach line read/lines dir/run-all.r [
  		if any [
			find line "===start-group"
  	  		find line "--run-"
  		][
  			do line
  		]
  	]
]

batch-mode: false
binary?: false
if system/script/args  [
	;; should we run non-interactively?
	batch-mode: find system/script/args "--batch"

	;; should we use the binary compiler?
	args: parse system/script/args " "
	if find system/script/args "--binary" [
		binary?: true
		bin-compiler: select args "--binary"
		if bin-compiler = "--batch" [
			bin-compiler: none								;; use default
		]
		if bin-compiler [						
			if not attempt [exists? to file! bin-compiler] [
				either batch-mode [
					write %quick-test/quick-test.log "Invalid compiler path"
					quit/return 1
				][
					print "Invalid compiler path supplied"
					print args
					print ""
					halt
				]
			]
		]
	
	]
]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true
store-current-dir: what-dir

do %quick-test/quick-test.r
if binary? [
	qt/binary?: binary?
	if bin-compiler [qt/bin-compiler: bin-compiler]
]

;; run the tests
print rejoin ["Quick-Test v" qt/version]
print rejoin ["REBOL " system/version]

start-time: now/precise

***start-run-quiet*** "Complete Red Test Suite"
qt/tests-dir: clean-path %system/tests/
do %system/tests/source/units/make-red-system-auto-tests.r
qt/tests-dir: clean-path %tests/
do %tests/source/units/make-red-auto-tests.r
do %tests/source/units/make-interpreter-auto-tests.r
qt/script-header: "Red []"
run-all-script %tests/
qt/script-header: "Red/System []"
qt/tests-dir: clean-path %system/tests/
run-all-script %system/tests/

***end-run-quiet***

end-time: now/precise
print ["       in" difference end-time start-time newline]
system/options/quiet: store-quiet-mode
change-dir store-current-dir
either batch-mode [
	quit/return either qt/test-run/failures > 0 [1] [0]
][
	print ["The test output was logged to" qt/log-file]
	ask "hit enter to finish"
	print ""
	qt/test-run/failures
]
