REBOL [
	Title:   "Red call tests"
	Author:  "Peter W A Wood"
	File: 	 %call-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Bruno Anselme & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "Red call test"

	--test-- "call-1"
		if exists? %call-test [delete %call-test]
		if exists? %call-test.exe [delete %call-test.exe]
		--compile-this {
			Red[]
			#include %../../system/library/call/call.red
			call/wait join [to-local-file system/options/boot " -qs tests/source/library/call-test.red"
	    }
	    --assert exists? any [%call-test %call-test.exe]
	    
	--test-- "call-2"
		--compile %tests/source/library/call-test.red
		output: ""
	    exe: either qt/windows-os? ["call-test.exe"] ["./call-test"]
	    call/output exe output
	    --assert "1^/" = output
	    
~~~end-file~~~
