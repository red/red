REBOL [
	Title:   "Red call tests"
	Author:  ["Peter W A Wood" "Bruno Anselme"]
	File: 	 %call-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Bruno Anselme & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "Red call test"
	--compile %tests/source/library/call-test.red
    exe: either qt/windows-os? ["call-test.exe"] ["./call-test"]

	--test-- "call-1"
		output: ""
		cmd: reform [exe "call-1"]
		call/output cmd output
	    --assert "0^/" = output

	--test-- "call-2"
		output: ""
		cmd: reform [exe "call-2"]
		call/output cmd output
		--assert "0^/" <> output

	--test-- "call-3"
		output: ""
		cmd: reform [exe "call-3"]
		call/output cmd output
		probe output
		--assert "Hello Red world^/" = output

    --test-- "call-4"
		output: ""
		cmd: reform [exe "call-4"]
		call/output cmd output
		probe output
	    --assert "Hello Red world^/" = output

~~~end-file~~~
