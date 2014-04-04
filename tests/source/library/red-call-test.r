REBOL [
	Title:   "Red call tests"
	Author:  "Bruno Anselme & Peter W A Wood"
	File: 	 %red-call-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2014 Bruno Anselme & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;-- Launch from Rebol or Rebol/View (windows) :
;-- do/args %quick-test/run-test.r %tests/source/library/red-call-test.r

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

	qt/tests-dir: clean-path %../../tests/
	--compile %source/library/red-called-test.red		;-- red-called-test.red is compiled only once
	exe: either qt/windows-os? ["red-called-test.exe"] ["./red-called-test"]

	--test-- "pid-1"									;-- Don't wait for end, pid <> 0
		output: copy ""
	    call/output join exe " pid-1" output
	    --assert "0" <> output

	--test-- "pid-2"									;-- Wait for end, pid = 0
		output: copy ""
	    call/output join exe " pid-2" output
	    --assert "0" = output

	--test-- "pid-3"									;-- Wait for end, create error, pid = 2
		output: copy ""
	    call/output join exe " pid-3" output
	    --assert "2" = output

	--test-- "pid-4"									;-- Wait for end, pid = 0
		output: copy ""
	    call/output join exe " pid-4" output
	    --assert "0" = output

	--test-- "out-1"									;-- Output redirection
		output: copy ""
	    call/output join exe " out-1" output
	    --assert "Hello Red World^/" = output

	--test-- "in-1"										;-- Input redirection
		output: copy ""
	    call/output join exe " in-1" output
	    --assert "Hello Red World^/" = output

	--test-- "err-1"									;-- Error redirection
		output: copy ""
	    call/output join exe " err-1" output
	    --assert "" <> output


~~~end-file~~~
