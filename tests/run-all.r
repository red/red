REBOL [
	Title:   "Builds and Runs the Red Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.5.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; should we run non-interactively?
batch-mode: all [system/options/args find system/options/args "--batch"]
fast-mode: all [system/options/args find system/options/args "--fast"]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

do %../quick-test/quick-test.r
qt/tests-dir: system/script/path

do %source/units/run-all-init.r

--setup-temp-files

***start-run-quiet*** "Red Test Suite"

do %source/units/run-all-extra-tests.r

===start-group=== "Main Red Tests"
    either fast-mode [
        --run-test-file-quiet %source/units/auto-tests/run-all-comp1.red
        --run-test-file-quiet %source/units/auto-tests/run-all-comp2.red
        --run-test-file-quiet %source/units/auto-tests/run-all-interp.red
        
    ][
        do %source/units/auto-tests/run-each-comp.r
        do %source/units/auto-tests/run-each-interp.r
    ]
===end-group===

***end-run-quiet***

--delete-temp-files

do %source/units/run-all-final.r
