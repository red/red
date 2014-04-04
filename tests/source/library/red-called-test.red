Red [
	Title:   "Red call test program"
	Author:  "Bruno Anselme & Peter W A Wood"
	File: 	 %red-called-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Bruno Anselme & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../system/library/call/call.red

read-argument: routine [
	/local
		args [str-array!]
		str	 [red-string!]
][
	if system/args-count <> 2 [
		SET_RETURN(none-value)
		exit
	]
	args: system/args-list + 1							;-- skip binary filename
	str: string/load args/item (1 + length? args/item) UTF-8
	SET_RETURN(str)
]

test-name: read-argument

;-- PIDs
if test-name = "pid-1" [								;-- Don't wait for end, pid <> 0
	pid: call "ls"
	prin pid
	quit
]
if test-name = "pid-2" [								;-- Wait for end, pid = 0
	pid: call/wait "ls"
	prin pid
	quit
]
if test-name = "pid-3" [								;-- Wait for end, pid = 2, error
	pid: call/wait "ls theNotExistingFile.red"
	prin pid
	quit
]
if test-name = "pid-4" [								;-- Start process, and kill spid, pid =0
	spid: call "sleep 30"
	pid: call/wait reduce ["kill" spid ]
	prin pid
	quit
]

;-- Output
if test-name = "out-1" [								;-- Output redirection
	out: ""
	call/output "echo Hello Red world" out
	prin out

	quit
]

;-- Input
if test-name = "in-1" [									;-- Input redirection
	out: ""
	inp: "Hello Red World^/"
	call/input/output "cat" inp out
	prin out
	quit
]

;-- Error
if test-name = "err-1" [								;-- Error redirection
	err: ""
	call/error "ls -" err
	prin err
	quit
]
print "Error : unknown test name"
