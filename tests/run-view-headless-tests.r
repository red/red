REBOL [
	Title:   "Builds and runs the headless View/VID tests (test GUI backend)"
	File: 	 %run-view-headless-tests.r
	Author:  "Red test suite"
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Purpose: {
		Compiles and runs the View/VID unit tests that target the headless
		`test` GUI backend (Config: [GUI-engine: 'test]). No display required,
		so these run on any platform / CI without a windowing system.
	}
]

;; should we run non-interactively?
each-mode: batch-mode: no

if args: any [system/script/args system/options/args][
	batch-mode: find args "--batch"
	each-mode:  find args "--each"
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

***start-run-quiet*** "Red/View headless (test backend) Test Suite"

===start-group=== "VID dialect"
	--run-test-file-quiet %source/view/vid-positioning-test.red
	--run-test-file-quiet %source/view/vid-styles-test.red
	--run-test-file-quiet %source/view/vid-facets-test.red
	--run-test-file-quiet %source/view/vid-containers-test.red
	--run-test-file-quiet %source/view/vid-actors-test.red
	--run-test-file-quiet %source/view/vid-errors-test.red
	--run-test-file-quiet %source/view/vid-window-test.red
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
