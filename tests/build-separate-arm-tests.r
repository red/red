REBOL [
    Title:   "Builds a set of Red & Red/System Tests to run on an ARM host"
	File: 	 %build-arm-tests.r
	Author:  "Peter W A Wood"
	Version: 0.2.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; This script must be run from the Red/red/tests dir

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

;; use win-call if running Rebol 2.7.8 under Windows
if all [
    system/version/4 = 3
    system/version/3 = 8
][
		do %../utils/call.r
		set 'call :win-call
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
	    target = "Darwin"
	][
	    target: none
	]
]

;; if no target supplied, ask the user
unless target [
    target: ask {
        Choose ARM target:
        1) Linux
        2) Android
        3) Linux armhf
        => }
    target: pick ["Linux-ARM" "Android" "RPi"] to-integer target
]

;; make the Arm dir if needed
arm-dir: clean-path %../quick-test/runnable/arm-tests/red/
make-dir/deep arm-dir

;; empty the Arm dir
foreach file read arm-dir [delete join arm-dir file]

;; build the test files
do %source/units/run-all-init.r

;; compile the tests into to runnable/arm-tests/red
output: copy ""

;; make the file lists from all-tests.txt & add auto-tests
file-list: copy []
all-tests: read/lines %source/units/all-tests.txt
foreach file read %source/units/auto-tests/ [
	if all [
		%.red = suffix? file
		none = find file "run-all"
	] [
		append all-tests  join %auto-tests/ file	
	]
]

foreach file all-tests [
    print ["Compiling" file] "..." 
    test-file: clean-path join %source/units/ file
    exe: replace file ".red" ""
    replace exe "auto-tests/" "auto-tests-"
    exe: to-local-file join arm-dir second split-path to file! exe
    cmd: join "" [  to-local-file system/options/boot " -sc "
        to-local-file clean-path %../red.r
        " -r -t " target " -o " exe " "
    	to-local-file test-file	
    ]
    clear output
    call/output cmd output
    print output
]

;; copy the bash script and mark it as executable
runner: arm-dir/run-all.sh
write/binary runner trim/with read/binary %run-all.sh "^M"
if system/version/4 <> 3 [
	set-modes runner [
	  owner-execute: true
	  group-execute: true
	  world-execute: true
	]
]

;; tidy up
system/options/quiet: store-quiet-mode

print ["Red ARM tests built in" arm-dir]  
