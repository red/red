REBOL [
	Title:   "Builds and runs the headless View/VID tests (test GUI backend)"
	File: 	 %run-view-headless-tests.r
	Author:  "Red test suite"
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Purpose: {
		Runs the View/VID unit tests that target the headless `test` GUI
		backend (Config: [GUI-engine: 'test]). No display required, so these
		run on any platform / CI without a windowing system.

		The tests are *interpreted*: %view-headless-interpreter.red is compiled
		once per run (so it always picks up the current sources), then every
		test file is run through that binary. This avoids the cost of a full
		per-test compilation.
	}
]

;; should we run non-interactively?
batch-mode: no

if args: any [system/script/args system/options/args][
	batch-mode: find args "--batch"
]

;; suppress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

do %../quick-test/quick-test.r
qt/tests-dir: system/script/path

;; Force a full standalone compile targeting the host (console subsystem on
;; Windows). The encapped compiler otherwise links against a prebuilt libRedRT
;; that is built with the *native* GUI backend, which is incompatible with
;; `Config: [GUI-engine: 'test]` (e.g. `undefined word do-event`, duplicate
;; draw-ctx! definitions). An explicit -t target forces a clean full compile.
;; -r (release) is essential: it forces a full standalone compile instead of
;; reusing the prebuilt libRedRT (which is built with the native backend).
qt/compile-flag: switch/default system/version/4 [
	3 [" -r -t MSDOS "]		;; Windows -> console subsystem so stdout is captured
	2 [" -r -t Darwin "]		;; macOS
][" -r -t Linux "]			;; Linux & others

print ["Quick-Test v" qt/version]
print ["REBOL " system/version]
start-time: now/precise
print ["This test started at" start-time]

;; compile the headless interpreter ONCE; every test below is run through it
prin ["compiling " %view-headless-interpreter.red " ..." #"^(0D)"]
interpreter: qt/compile %view-headless-interpreter.red
unless interpreter [
	print "** view-headless-interpreter.red - compiler error **"
	print qt/comp-output
	system/options/quiet: store-quiet-mode
	quit/return 1
]
interpreter: qt/runnable-dir/:interpreter

;; runs one test file through the compiled interpreter (quick-test quiet style)
--interpret-test-file-quiet: func [
	src [file!]
	/local cmd
][
	prin ["running " find/last/tail src "/" #"^(0D)"]
	qt/file/reset
	unless qt/file/title: find/last/tail to string! src "/" [
		qt/file/title: to string! src
	]
	replace qt/file/title "-test.red" ""
	clear qt/output
	cmd: rejoin [to-local-file interpreter " " to-local-file qt/tests-dir/:src]
	do qt/call* cmd qt/output
	if any [
		find qt/output "Runtime Error"			;; Red/System runtime error
		find qt/output "Error:"					;; interpreter error report (*** Script Error: ...)
		not find qt/output "Passed"				;; no summary -> died before ~~~end-file~~~
	][qt/_signify-failure]
	qt/add-to-run-totals
	write/append qt/log-file qt/output
	qt/_print-summary qt/file
]

***start-run-quiet*** "Red/View headless (test backend) Test Suite"

===start-group=== "VID dialect"
	--interpret-test-file-quiet %source/view/vid-positioning-test.red
	--interpret-test-file-quiet %source/view/vid-styles-test.red
	--interpret-test-file-quiet %source/view/vid-facets-test.red
	--interpret-test-file-quiet %source/view/vid-containers-test.red
	--interpret-test-file-quiet %source/view/vid-actors-test.red
	--interpret-test-file-quiet %source/view/vid-errors-test.red
	--interpret-test-file-quiet %source/view/vid-window-test.red
===end-group===

===start-group=== "View engine"
	--interpret-test-file-quiet %source/view/face-facets-test.red
	--interpret-test-file-quiet %source/view/face-types-test.red
	--interpret-test-file-quiet %source/view/show-sync-test.red
	--interpret-test-file-quiet %source/view/make-face-test.red
	--interpret-test-file-quiet %source/view/face-tree-test.red
===end-group===

===start-group=== "Events & reactivity"
	--interpret-test-file-quiet %source/view/events-actors-test.red
	--interpret-test-file-quiet %source/view/input-test.red
	--interpret-test-file-quiet %source/view/reactivity-test.red
===end-group===

===start-group=== "Draw dialect"
	--interpret-test-file-quiet %source/view/draw-parse-test.red
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
	qt/test-run/failures
]
