REBOL [
  Title:   "Builds a set of Red/System Tests to run on an ARM host"
	File: 	 %build-arm-tests.r
	Author:  "Peter W A Wood"
	Version: 0.1.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; This script must be run from the Red/red-system/tests dir

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

;; init
file-chars: charset [#"a" - #"z" #"A" - #"Z" #"0" - #"9" "-" "/"]
a-file-name: ["%" some file-chars ".reds" ] 
a-test-file: ["--run-test-file-quiet " copy file a-file-name]
a-dll-file: ["--compile-dll " copy file a-file-name]

;; helper function
compile-test: func [test-file [file!]] [
		do/args %rsc.r join "-t Linux-ARM " test-file
		exe: copy find/last/tail test-file "/"
		exe: replace exe ".reds" ""
		write/binary join %tests/runnable/arm-tests/ exe read/binary join %builds/ exe	
]

;; make the Arm dir if needed
arm-dir: %runnable/arm-tests/
make-dir arm-dir

;; empty the Arm dir
foreach file read arm-dir [delete join arm-dir file]

;; compile any dlls
dlls: copy []
src: read %source/units/make-dylib-auto-test.r
parse/all src [any [a-dll-file (append dlls to file! file) | skip] end]
save-dir: what-dir
change-dir %../
foreach dll dlls [
	if none = find dll "dylib" [
	insert next dll "tests/"
	do/args %rsc.r join "-dlib -t Linux-ARM " dll
	lib: copy find/last/tail dll "/"
	lib: replace lib ".reds" ".so"
	write/binary join %tests/runnable/arm-tests/ lib read/binary join %builds/ lib	
	]
]
change-dir :save-dir

;; get the list of test source files
test-files: copy []
all-tests: read %run-all.r
parse/all all-tests [any [a-test-file (append test-files to file! file) | skip] end]

;; compile the tests and move the executables to runnable/arm-tests
save-dir: what-dir
change-dir %../
foreach test-file test-files [
	if none = find test-file "dylib" [      		;; ignore any dylibs tests
		insert next test-file "tests/"
		compile-test test-file
	]
]
change-dir :save-dir

;; generate and compile the dylib tests
save-dir: what-dir
change-dir %../

dylib-source: %tests/runnable/arm-tests/dylib-auto-test.reds
test-script-header: read %tests/source/units/dylib-test-script-header.txt
replace test-script-header "%../../../../../quick-test/quick-test.reds"
						   "%../../../../quick-test/quick-test.reds"
libs: read %tests/source/units/dylib-libs.txt
replace libs "***test-dll1***" clean-path %runnable/arm-tests/libtest-dll1.dylib
replace libs "***test-dll2***" clean-path %runnable/arm-tests/libtest-dll2.dylib
tests: read %tests/source/units/dylib-tests.txt
test-script-footer: read %tests/source/units/dylib-test-script-footer.txt
write dylib-source join test-script-header [
	libs tests test-script-footer
]
compile-test dylib-source
if exists? dylib-source [
	delete dylib-source
]

change-dir :save-dir

;; copy the bash script and mark it as executable
write/binary %runnable/arm-tests/run-all.sh read/binary %run-all.sh
runner: open %runnable/arm-tests/run-all.sh
set-modes runner [
  owner-execute: true
  group-execute: true
  world-execute: true
]
close runner

;; tidy up
system/options/quiet: store-quiet-mode

print "ARM tests built"
  
  

