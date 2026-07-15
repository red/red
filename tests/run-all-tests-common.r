REBOL [
	Title:   "Shared Red and Red/System all-tests driver"
	File:    %run-all-tests-common.r
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

root-dir: all-tests-config/root-dir
store-current-dir: what-dir
change-dir root-dir

run-all-script: func [
	dir  [file!]
	file [file!]
	/local source
][
	qt/tests-dir: dir
	source: join dir file
	foreach line read/lines source [
		if any [
			find line "===start-group"
			find line "===end-group"
			find line "--run-"
		][
			do line
		]
	]
]

run-external-phase: func [
	label   [string!]
	command [string!]
	/local output status
][
	print ["Running" label]
	output: make string! 65536
	status: call/wait/output command output
	prin output
	if exists? qt/log-file [
		write/append qt/log-file rejoin [
			newline "*** External phase: " label " ***" newline
			output
			"Exit code: " status newline
		]
	]
	status
]

batch-mode: false
each-mode: false
binary-compiler?: false
args: all-tests-args
if args [
	batch-mode: find args "--batch"
	each-mode: find args "--each"

	parsed-args: parse args " "
	if find args "--binary" [
		binary-compiler?: true
		bin-compiler: select parsed-args "--binary"
		if any [
			bin-compiler = "--batch"
			bin-compiler = "--each"
		][
			bin-compiler: none
		]
		if all [bin-compiler not attempt [exists? to file! bin-compiler]][
			either batch-mode [
				write %quick-test/quick-test.log "Invalid compiler path"
				quit/return 1
			][
				print ["Invalid compiler path supplied:" bin-compiler]
				change-dir store-current-dir
				halt
			]
		]
	]
]

store-quiet-mode: system/options/quiet
system/options/quiet: true

do join root-dir %quick-test/quick-test.r
qt/compile-target: all-tests-config/compile-target
qt/library-target: all-tests-config/library-target
qt/target-platform: all-tests-config/target-platform
qt/dependency-dir: all-tests-config/dependency-dir
if all-tests-config/log-file [qt/log-file: all-tests-config/log-file]
if in all-tests-config 'compile-flag [
	qt/compile-flag: all-tests-config/compile-flag
]

if binary-compiler? [
	qt/binary-compiler?: binary-compiler?
	if bin-compiler [qt/bin-compiler: bin-compiler]
]

qt/setup-temp-files

external-failures: 0
target-label: any [all-tests-config/compile-target "Host"]
if all-tests-config/prepare-command [
	if 0 <> run-external-phase (rejoin [target-label " preparation"]) all-tests-config/prepare-command [
		external-failures: external-failures + 1
		unless exists? qt/log-file [write qt/log-file ""]
		write/append qt/log-file rejoin [target-label " preparation failed.^/"]
		system/options/quiet: store-quiet-mode
		change-dir store-current-dir
		quit/return 1
	]
]

qt/tests-dir: clean-path join root-dir %system/tests/
do join root-dir %system/tests/source/units/make-red-system-auto-tests.r
do join root-dir %system/tests/source/units/prepare-dependencies.r

qt/tests-dir: clean-path join root-dir %tests/
do join root-dir %tests/source/units/run-all-init.r

print ["Quick-Test v" qt/version]
print ["REBOL " system/version]
print ["Suite target:" any [all-tests-config/compile-target "host default"]]
start-time: now/precise
print ["This test started at" start-time]

***start-run-quiet*** all-tests-config/title
qt/script-header: "Red []"
do join root-dir %tests/source/units/run-pre-extra-tests.r
either each-mode [
	do join root-dir %tests/source/units/auto-tests/run-each-comp.r
	do join root-dir %tests/source/units/auto-tests/run-each-interp.r
][
	--run-test-file-quiet %source/units/auto-tests/run-all-comp1.red
	--run-test-file-quiet %source/units/auto-tests/run-all-comp2.red
	--run-test-file-quiet %source/units/auto-tests/run-all-interp.red
]
do join root-dir %tests/source/units/run-post-extra-tests.r

if all-tests-config/include-regression? [
	run-all-script clean-path join root-dir %tests/ %run-regression-tests.r
]

if all-tests-config/include-view? [
	===start-group=== "View Engine Tests"
		--run-test-file-quiet %source/view/base-self-test.red
	===end-group===
]

qt/script-header: "Red/System []"
run-all-script clean-path join root-dir %system/tests/ %run-all.r
***end-run-quiet***

if all-tests-config/native-command [
	if 0 <> run-external-phase (rejoin [target-label " native tests"]) all-tests-config/native-command [
		external-failures: external-failures + 1
	]
]

end-time: now/precise
print ["       in" difference end-time start-time newline]
print ["The test finished at" end-time]
print ["External phase failures:" external-failures]
system/options/quiet: store-quiet-mode
change-dir store-current-dir

failures: qt/test-run/failures + external-failures
either batch-mode [
	quit/return either failures > 0 [1][0]
][
	print ["The test output was logged to" qt/log-file]
	ask "hit enter to finish"
	print ""
	failures
]
