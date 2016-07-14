REBOL [
  	Title:   "Red 'Extra' Tests"
	Author:  "Peter W A Wood"
	Version: 0.1.0
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Purpose: {Defines tests to be run in red/run-all.r and red/tests/run-all.r}
]


===start-group=== "Red compiler unit tests"

===end-group===

===start-group=== "Red runtime tests"
  	--run-test-file-quiet %source/runtime/tools-test.reds
===end-group===

===start-group=== "Red Compiler tests"
  	--run-script-quiet %source/compiler/print-test.r
  	--run-script-quiet %source/compiler/run-time-error-test.r
  	--run-script-quiet %source/compiler/compile-error-test.r
===end-group===

===start-group=== "Red Library tests"
	
===end-group===