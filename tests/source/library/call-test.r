REBOL [
	Title:   "Red call tests"
	Author:  "Bruno Anselme & Peter W A Wood"
	File: 	 %call-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2015 Bruno Anselme & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "Red call test"

		posix?: func[] [
			switch/default fourth system/version [
				2 [either 5 = fifth system/version [true] [false]]
				3 [false]
				15 [false]
			][
				true	
			]
		]
		
	--test-- "call-1"				;; test call/wait 
		if exists? %call-test [delete %call-test]
		if exists? %call-test.exe [delete %call-test.exe]
		path-to-rebol: to-local-file system/options/boot
		if qt/windows-os? [
			path-to-rebol: join {"} [path-to-rebol {"}]
		]
		path-to-red: to-local-file clean-path %../../red.r
		path-to-source: to-local-file clean-path %../../tests/source/library/call-test.red
		src: join "Red[] " compose [
			" #include %../../system/library/call/call.red "
			"call/wait {" (path-to-rebol)
			" -qs " (path-to-red) " "
			" -o " (qt/runnable-dir) " "
			(path-to-source) "}"
		]
		--compile-and-run-this src
		--assert none <> any [
	    	exists? %call-test
	    	exists? %call-test.exe
	    ]
	    
	--test-- "call-2"						;; test that call without /wait
											;; doesn't wait for the called 
											;; process to execute
	
		if exists? %call-test [delete %call-test]
		if exists? %call-test.exe [delete %call-test.exe]
		path-to-rebol: to-local-file system/options/boot
		if qt/windows-os? [
			path-to-rebol: join {^"} [path-to-rebol {^"}]
		]
		path-to-red: to-local-file clean-path %../../red.r
		path-to-source: to-local-file clean-path %../../source/library/call-test.red
		src: join {Red[] } compose [
			" #include %../../system/library/call/call.red "
			"call {" (path-to-rebol)
			" -qs " (path-to-red) " "
			" -o " (qt/runnable-dir) " "
			(path-to-source) "}"
		]
		--compile-and-run-this src
		--assert all [
	    	not exists? %call-test
	    	not exists? %call-test.exe
	    ]

		;;set up for remaining tests
		qt/tests-dir: clean-path %../../tests/
		--compile %source/library/call-test.red
		--compile %source/library/called-test.red
		exe: either qt/windows-os? ["call-test.exe"] ["./call-test"]	    
	    
	--test-- "call-3"						;; test of call/output 
		output: copy ""
	    exe: join exe " option-1"
	    call/output exe output
	    --assert "Hello World" = output
	       
	--test-- "call-4"						;; test of call/error
		output: copy ""
	    exe: join exe " option-2"
	    call/output exe output
	    --assert "" <> output
	
	    if posix? [
	--test-- "call-5"						;; test of call/shell 
	    		output: copy ""
	    		exe: join exe " option-1"
	    		call/output exe output
	    		--assert "Hello World" = output  
	    ]
	    
~~~end-file~~~
