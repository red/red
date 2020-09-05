REBOL [
	Title:   "Builds and Runs the Red Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.5.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; should we run non-interactively?
each-mode: batch-mode: ci-each: debug-mode: no

if args: any [system/script/args system/options/args][
	batch-mode: find args "--batch"
	each-mode:  find args "--each"
	ci-each:  find args "--ci-each"
	debug-mode: find args "--debug"
]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

do %../quick-test/quick-test.r
qt/tests-dir: system/script/path

do %source/units/run-all-init.r

;; run the tests
print ["Quick-Test v" qt/version]
print ["REBOL " system/version]
start-time: now/precise
print ["This test started at" start-time]

if debug-mode [qt/compile-flag: " -d "]

qt/script-header: "Red []"

--setup-temp-files

***start-run-quiet*** "Red Test Suite"

do %source/units/run-pre-extra-tests.r

===start-group=== "Main Red Tests"
    either any [each-mode ci-each][
    	do %source/units/auto-tests/run-each-comp.r
        do %source/units/auto-tests/run-each-interp.r
    ][
        --run-test-file-quiet %source/units/auto-tests/run-all-comp1.red
        --run-test-file-quiet %source/units/auto-tests/run-all-comp2.red
        --run-test-file-quiet %source/units/auto-tests/run-all-interp.red
    ]
===end-group===
do %source/units/run-post-extra-tests.r

===start-group=== "Red Compiler Regression Tests"
	--run-script-quiet %source/compiler/regression-test-redc-1.r
	--run-script-quiet %source/compiler/regression-test-redc-2.r
	--run-script-quiet %source/compiler/regression-test-redc-3.r
	--run-script-quiet %source/compiler/regression-test-redc-4.r
	--run-script-quiet %source/compiler/regression-test-redc-5.r
===end-group===

;===start-group=== "View Engine Tests"
;	--run-test-file-quiet %source/view/base-self-test.red
;===end-group===

***end-run-quiet***

--delete-temp-files

end-time: now/precise
print ["       in" difference end-time start-time newline]
print ["The test finished at" end-time]
system/options/quiet: store-quiet-mode
either any [batch-mode ci-each][
	quit/return either qt/test-run/failures > 0 [1] [0]
][
	print ["The test output was logged to" qt/log-file]
	ask "hit enter to finish"
	print ""
	qt/test-run/failures
]
