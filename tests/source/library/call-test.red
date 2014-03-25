Red [
	Title:   "Red call test program"
	Author:  "Bruno Anselme & Peter W A Wood"
	File: 	 %call-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2013 Bruno Anselme & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]
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

if test-name = "call-1" [				
	print 1	
	quit
]

if test-name = "call-2" [				
	1 / 0
	quit
]

