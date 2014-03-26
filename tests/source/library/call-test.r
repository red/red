REBOL [
	Title:   "Red call tests"
	Author:  "Bruno Anselme & Peter W A Wood"
	File: 	 %call-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Bruno Anselme & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "Red call test"
	--compile %tests/source/library/call-test.red
    exe: either qt/windows-os? ["call-test.exe"] ["./call-test"]

	--test-- "call-1"
		if exists? %call-test [delete %call-test]
		if exists? %call-test.exe [delete %call-test.exe]
		path-to-rebol: to-local-file system/options/boot
		if qt/windows-os? [
			path-to-rebol: join {^"} [path-to-rebol {^"}]
		]
		path-to-red: to-local-file clean-path %../../red.r
		path-to-source: to-local-file clean-path %../../tests/source/library/call-test.red
		src: join {Red[] } compose [
			" #include %../../system/library/call/call.red "
			"call/wait {" (path-to-rebol)
			" -qs " (path-to-red) " "
			" -o " (qt/runnable-dir) " "
			(path-to-source) "}"
		]
		--compile-and-run-this src
		--assert any [
	    	exists? %call-test
	    	exists? %call-test.exe
	    ]

	--test-- "call-2"
		if exists? %call-test [delete %call-test]
		if exists? %call-test.exe [delete %call-test.exe]
		path-to-rebol: to-local-file system/options/boot
		if qt/windows-os? [
			path-to-rebol: join {^"} [path-to-rebol {^"}]
		]
		path-to-red: to-local-file clean-path %../../red.r
		path-to-source: to-local-file clean-path %../../tests/source/library/call-test.red
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

	--test-- "call-3"
		--compile %tests/source/library/call-test.red
		output: copy ""
	    exe: either qt/windows-os? ["call-test.exe"] ["./call-test"]
	    exe: join exe " call-1"
	    call/output exe output
	    --assert "1^/" = output

	--test-- "call-4"
		error: copy ""
		output: copy ""
	    exe: either qt/windows-os? ["not-call-test.exe"] ["./not-call-test"]
	    exe: join exe
	    call/output/error exe output error
	    --assert "" <> error
	    --assert "" = output

~~~end-file~~~
