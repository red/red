REBOL [
	Title:   "Creates Red/System dylib tests"
	Author:  "Peter W A Wood"
	File: 	 %create-dylib-auto-test.r
	Version: 0.1.0
	Rights:  "Copyright (C) 2014-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

create-dylib-auto-test: func [
	target [string!]
	dir-out [file!]
	exe-dir-out [file!]  
][
	;;; Initialisations
	file-out: dir-out/dylib-auto-test.reds
	

	;; test script header including the lib definitions
	test-script-header: read %dylib-test-script-header.txt

	;; the libs
	libs: read %dylib-libs.txt
	
	;; the tests
	tests: read %dylib-tests.txt

	;; test script footer
	test-script-footer: read %dylib-test-script-footer.txt

	;; workout dll names 
	suffix: switch/default target [
		"Darwin"	[".dylib"]
		"Windows"	[".dll"]
	][
		".so"	
	]
	
	;;; Processing
	
	;; update the test header with the current make file length and write it
	replace test-script-header "###make-length###" length? read %make-dylib-auto-test.r
	write file-out test-script-header
	
	;; update the #include statements, write them and the tests
	if target [
		dll1-name: join %libtest-dll1 suffix
		dll2-name: join %libtest-dll2 suffix 
		either any [
		    target = "Windows"
		    exe-dir-out = %./ 
		][
			replace libs "***test-dll1***" dll1-name
			replace libs "***test-dll2***" dll2-name
		][
			replace libs "***test-dll1***" to-local-file clean-path exe-dir-out/:dll1-name
			replace libs "***test-dll2***" to-local-file clean-path exe-dir-out/:dll2-name
		]
		write/append file-out libs
		write/append file-out tests	
	]

	;; write the test footer
	write/append file-out test-script-footer
	
]