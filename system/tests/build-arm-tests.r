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

;; process arguments (if any)
target: none
if system/script/args  [
    target: second parse system/script/args " "
	if not any [
	    target = "Linux"
	    target = "Android"
	    target = "RPi"
		target = "Linux-ARM"
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
        => }
    target: pick ["Linux-ARM" "Android" "RPi"] to-integer target
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
    call/output cmd output
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
structlib-version: switch target [
	"Linux-ARM" [%libstructlib-armsf.so]
	"Android" [%libstructlib-android.so]
	"RPi" [%libstructlib-armhf.so]
]
write/binary arm-dir/libstructlib.so read/binary join %source/units/libs/ structlib-version

;; get the list of test source files
test-files: copy []
all-tests: read %run-all.r
parse/all all-tests [any [a-test-file (append test-files to file! file) | skip] end]
;; compile the tests and move the executables to runnable/arm-tests
foreach test-file test-files [
	if none = find test-file "dylib" [      		;; ignore any dylibs tests
		compile-test replace clean-path test-file "%" ""
	]
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
