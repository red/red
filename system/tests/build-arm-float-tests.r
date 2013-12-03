REBOL [
  Title:   "Builds a set of Red/System Float Tests to run on an ARM host"
	File: 	 %build-arm-float-tests.r
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

;; make the Arm-Float dir if needed
arm-dir: %runnable/arm-float-tests/
make-dir arm-dir

;; empty the Arm dir
foreach file read arm-dir [delete join arm-dir file]

;; get the list of test source files
test-files: copy []
all-tests: read %run-float.r
parse/all all-tests [any [a-test-file (append test-files to file! file) | skip] end]

;; compile the tests and move the executables to runnable/arm-tests
change-dir %../
foreach test-file test-files [
  insert next test-file "tests/"
  do/args %rsc.r join "-t Linux-ARM " test-file
  exe: copy find/last/tail test-file "/"
  exe: replace exe ".reds" ""
  write/binary join %tests/runnable/arm-float-tests/ exe read/binary join %builds/ exe
]
change-dir %tests/

;; copy the bash script and mark it as executable
write/binary %runnable/arm-float-tests/run-all.sh read/binary %run-all.sh
runner: open %runnable/arm-float-tests/run-all.sh
set-modes runner [
  owner-execute: true
  group-execute: true
  world-execute: true
]
close runner

;; tidy up
system/options/quiet: store-quiet-mode

print "ARM Float tests built"
  
  

