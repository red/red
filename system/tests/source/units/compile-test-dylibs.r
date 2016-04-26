REBOL [
	Title:   "Compiles Red/System test dylibs"
	Author:  "Peter W A Wood"
	Version: 0.1.0
	Rights:  "Copyright (C) 2014-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

compile-test-dylibs: func [
	target [string!]
	dir-out [file!]
][

	;; use win-call if running Rebol 2.7.8 under Windows
	if all [
		not value? 'win-call
    	system/version/4 = 3
    	system/version/3 = 8
	][
		do %../../utils/call.r
		set 'call :win-call
	]	

	dlls: [
		%libtest-dll1.reds
		%libtest-dll2.reds
	]
	
	output: copy ""
	foreach dll dlls [
		lib: copy dll
		lib: to file! replace lib ".reds" ""
		lib: dir-out/:lib
		cmd: join "" [
			to-local-file system/options/boot " -sc "
            to-local-file clean-path %../../red.r
            " -dlib  -t " target " -o " lib " "
    		to-local-file clean-path join %source/units/ dll
    	]
		clear output
		call/output cmd output
	]	
]
