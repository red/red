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

;; use win-call if running Rebol 2.7.8 under Windows
if all [
    system/version/4 = 3
    system/version/3 = 8              
][
		do %../quick-test/call.r					               
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
	][
	    target: none
	]
]

;; init
file-chars: charset [#"a" - #"z" #"A" - #"Z" #"0" - #"9" "-" "/"]
a-file-name: ["%" some file-chars ".red" ] 
a-test-file: ["--run-test-file-quiet " copy file a-file-name]

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

;; get the list of test source files
test-files: copy []
all-tests: read %run-all.r
parse/all all-tests [
	thru "Red Units tests"
	any [a-test-file (append test-files to file! file) | skip]
]

;; compile the tests into to runnable/arm-tests/red
output: copy ""
foreach test-file test-files [
    exe: copy find/last/tail test-file "/"
    exe: replace exe ".red" ""
    exe: to-local-file join arm-dir exe
    cmd: join "" [  to-local-file system/options/boot " -sc "
                    to-local-file clean-path %../red.r
                    " -t " target " -o " exe " "
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

print ["Red/System ARM tests built in" arm-dir]  
