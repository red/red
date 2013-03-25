REBOL [
  Title:   "Builds a set of Red Tests to run on an ARM host"
	File: 	 %build-arm-tests.r
	Author:  "Peter W A Wood"
	Version: 0.1.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; This script must be run from the Red/red/tests dir

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

;; init
file-chars: charset [#"a" - #"z" #"A" - #"Z" #"0" - #"9" "-" "/"]
a-file-name: ["%" some file-chars ".red" ] 
a-test-file: ["--run-test-file-quiet-red " copy file a-file-name]

;; make the Arm dir if needed
arm-dir: %runnable/arm-tests/
make-dir arm-dir

;; empty the Arm dir
foreach file read arm-dir [delete join arm-dir file]

;; get the list of test source files
test-files: copy []
all-tests: read %run-all.r
parse/all all-tests [any [a-test-file (append test-files to file! file) | skip] end]

;; compile the tests into to runnable/arm-tests
 
foreach test-file test-files [
  do/args %../../red.r join "-t Linux-ARM " test-file
  exe: copy find/last/tail test-file "/"
  exe: replace exe ".red" ""
  write/binary join %runnable/arm-tests/ exe read/binary exe
  delete exe
]

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
  
  

