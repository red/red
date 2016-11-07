REBOL [
  	Title:   "Red 'Pre Extra' Tests"
	Author:  "Peter W A Wood"
	Version: 0.1.0
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Purpose: {Defines tests to be run in red/run-all.r and red/tests/run-all.r}
]


===start-group=== "Red compiler unit tests"
	--run-unit-test-quiet %source/compiler/lexer-test.r
	--run-unit-test-quiet %source/units/auto-tests/lexer-auto-test.r
===end-group===

===start-group=== "Red runtime tests"
  	--run-test-file-quiet %source/runtime/unicode-test.red
===end-group===

===start-group=== "Red Compiler tests"
	--run-script-quiet %source/compiler/preprocessor-test.r
===end-group===

===start-group=== "Red Library tests"
	
===end-group===