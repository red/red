Red [
	Title:   "Red call test program"
	Author:  ["Peter W A Wood" "Bruno Anselme"]
	File: 	 %call-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2013 Bruno Anselme & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
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
;print test-name
if test-name = "call-1" [								;-- Wait for end, pid = 0
	pid: call/wait "ls"
	print pid
	quit
]
if test-name = "call-2" [								;-- Don't wait for end, pid <> 0
	pid: call "ls"
	print pid
	quit
]
if test-name = "call-3" [								;-- Output redirection
	out: ""
	call/output "echo Hello Red world" out
	prin out
	quit
]
if test-name = "call-4" [								;-- Input redirection
	out: ""
	inp: "Hello Red world^/"
	call/input/output "cat" inp out
	prin out
	quit
]
print "1"												;-- compliance with Peter's example
