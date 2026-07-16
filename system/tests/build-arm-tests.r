REBOL [
	Title:		"Builds a set of Red/System Tests to run on an ARM host"
	File:		%build-arm-tests.r
	Author:		"Peter W A Wood"
	Version:	0.2.0
	License:	"BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

;; use win-call if running Rebol 2.7.8 under Windows
if all [
    system/version/4 = 3
    system/version/3 = 8              
][
		do %../../utils/call.r
		set 'call :win-call
]

do %source/units/create-dylib-auto-test.r
do %source/units/compile-test-dylibs.r

;; compile-test-dylibs is also used by quick-test, where qt is pre-initialized.
unless value? 'qt [
	qt: make object! [
		base-dir: clean-path %../../
		tests-dir: clean-path %./
	]
]

;; process arguments (if any)
target: none
if system/script/args  [
    target: second parse system/script/args " "
	if not any [
	    target = "Linux"
	    target = "Android"
	    target = "RPi"
		target = "Linux-ARM"
		target = "Linux-ARM64"
	][
	    target: none
	]
]

;; init
file-chars: charset [#"a" - #"z" #"A" - #"Z" #"0" - #"9" "-" "/"]
a-file-name: ["%" some file-chars ".reds" ] 
a-test-file: ["--run-test-file-quiet " copy file a-file-name]
a-dll-file: ["--compile-dll " copy file a-file-name]

unless target [
    target: ask {
        Choose ARM target:
        1) Linux armel (ARMv5)
        2) Android
        3) Linux armhf (ARMv7+)
		4) Linux arm64 (AArch64)
        => }
	target: pick ["Linux-ARM" "Android" "RPi" "Linux-ARM64"] to-integer target
]

;; helper function
output: copy ""
compile-test: func [test-file [file!]] [
	exe: copy find/last/tail test-file "/"
	exe: to file! replace exe ".reds" ""
	exe: arm-dir/:exe
	cmd: join "" [  to-local-file system/options/boot " -sc "
                    to-local-file clean-path %../../red.r
                    " -r -t " target " -o " exe " "
    				to-local-file test-file	
    			]
    clear output
    compilation-status: call/output cmd output
    if compilation-status <> 0 [ quit/return compilation-status ]
    print output
]

;; make the Arm dir if needed
arm-dir: clean-path %../../quick-test/runnable/arm-tests/system/
make-dir/deep arm-dir

;; empty the Arm dir
foreach file read arm-dir [delete join arm-dir file]

;; generate the dylib tests
change-dir %source/units
compile-test-dylibs target arm-dir
create-dylib-auto-test target arm-dir %./
change-dir %../../
src: read arm-dir/dylib-auto-test.reds
replace src "../../../../../" "../../../../"
replace src {"libtest-dll1.dylib"} {"./libtest-dll1.dylib"}
write arm-dir/dylib-auto-test.reds src
compile-test arm-dir/dylib-auto-test.reds
if exists? arm-dir/dylib-auto-test.reds [delete arm-dir/dylib-auto-test.reds]

;; get the correct structlib
either target = "Linux-ARM64" [
	;; The checked-in libraries are 32-bit. Build this source on the ARM64 host.
	write/binary arm-dir/structlib.c read/binary %source/units/libs/structlib.c
][
	structlib-version: switch target [
		"Linux-ARM" [%libstructlib-armsf.so]
		"Android" [%libstructlib-android.so]
		"RPi" [%libstructlib-armhf.so]
	]
	write/binary arm-dir/libstructlib.so read/binary join %source/units/libs/ structlib-version
]

;; get the list of test source files
test-files: copy []
all-tests: read %run-all.r
parse/all all-tests [any [a-test-file (append test-files to file! file) | skip] end]

;; run-all.r contains both 32-bit and 64-bit variants behind runtime conditions.
filtered-tests: copy []
foreach test-file test-files [
	either target = "Linux-ARM64" [
		unless any [
			find test-file "/struct-test.reds"
			find test-file "/size-test.reds"
		][append filtered-tests test-file]
	][
		unless any [
			find test-file "/struct-x64-test.reds"
			find test-file "/size-x64-test.reds"
		][append filtered-tests test-file]
	]
]
test-files: filtered-tests
;; compile the tests and move the executables to runnable/arm-tests
foreach test-file test-files [
	if none = find test-file "dylib" [      		;; ignore any dylibs tests
		compile-test replace clean-path test-file "%" ""
	]
]

;; ARM64 backend smokes return a process status instead of a quick-test report.
;; Package them beside the regular suites; run-all.sh handles their contract.
if target = "Linux-ARM64" [
	smoke-files: copy []
	foreach file read %source/units/ [
		name: form file
		if all [
			find/match name "arm64-"
			find name ".reds"
		][append smoke-files join %source/units/ file]
	]
	foreach smoke-file sort smoke-files [compile-test clean-path smoke-file]
	generated-smoke: arm-dir/arm64-long-branch-smoke.reds
	do %source/units/generate-arm64-long-branch-smoke.r
	generate-arm64-long-branch-smoke generated-smoke
	compile-test generated-smoke
	if exists? generated-smoke [delete generated-smoke]
]

;; generate the dylib tests
change-dir %source/units
compile-test-dylibs target arm-dir
create-dylib-auto-test target arm-dir %./
change-dir %../../
src: read arm-dir/dylib-auto-test.reds
replace src "../../../../../" "../../../../"
replace/all src {"libtest-} {"./libtest-}
write arm-dir/dylib-auto-test.reds src
compile-test arm-dir/dylib-auto-test.reds
if exists? arm-dir/dylib-auto-test.reds [delete arm-dir/dylib-auto-test.reds]

;; complie the test libs
compile-test-dylibs target arm-dir

;; copy the bash script and mark it as executable
write/binary arm-dir/run-all.sh trim/with read/binary %run-all.sh "^M"
unless system/version/4 = 3 [
	runner: open arm-dir/run-all.sh
	set-modes runner [
		owner-execute: true
		group-execute: true
  		world-execute: true
	]
	close runner
]

;; tidy up
system/options/quiet: store-quiet-mode

print ["Red/System ARM tests built in" arm-dir]
