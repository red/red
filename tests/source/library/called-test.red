Red [
	Title:   "Program called by Red call tests"
	Author:  "Bruno Anselme & Peter W A Wood"
	File: 	 %called-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2015 Bruno Anselme & Peter W A Wood. All rights reserved."
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

if test-name = "option-1" [
	prin "Hello World"
	quit
]


