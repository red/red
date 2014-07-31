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
a-test-file: ["--run-test-file-quiet " copy file a-file-name]

target: ask {
Choose ARM target:
1) Linux
2) Android
3) Linux armhf
=> }
target: pick ["Linux-ARM" "Android" "RPi"] to-integer target

;; make the Arm dir if needed
arm-dir: %runnable/arm-tests/
make-dir/deep arm-dir

;; empty the Arm dir
foreach file read arm-dir [delete join arm-dir file]

;; get the list of test source files
test-files: copy []
all-tests: read %run-all.r
parse/all all-tests [
	thru "Red Units tests"
	any [a-test-file (append test-files to file! file) | skip]
]

;; compile the tests into to runnable/arm-tests
 
foreach test-file test-files [
  do/args %../red.r rejoin ["-t " target " " test-file]
  exe: copy find/last/tail test-file "/"
  exe: replace exe ".red" ""
  write/binary join %runnable/arm-tests/ exe read/binary exe
  delete exe
]

;; copy the bash script and mark it as executable
runner: %runnable/arm-tests/run-all.sh
write/binary runner read/binary %run-all.sh
if system/version/4 <> 3 [
	set-modes runner [
	  owner-execute: true
	  group-execute: true
	  world-execute: true
	]
]

;; tidy up
system/options/quiet: store-quiet-mode

print "ARM tests built"
  
  

