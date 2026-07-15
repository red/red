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
	/local
		dlls output dll lib source compiler cmd status
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
	
	dir-out: clean-path dir-out
	compiler: clean-path join qt/base-dir %red.r
	output: make string! 4096
	foreach dll dlls [
		lib: copy dll
		lib: to file! replace lib ".reds" ""
		lib: dir-out/:lib
		source: clean-path join qt/tests-dir join %source/units/ dll
		cmd: join "" [
			to-local-file system/options/boot " -sc "
			to-local-file compiler
			" -dlib -t " target " -o " lib " "
			to-local-file source
		]
		clear output
		status: call/wait/output cmd output
		unless all [status = 0 find output "output file size :"] [
			print output
			do make error! rejoin ["Failed to compile test DLL: " source]
		]
	]	
]
