REBOL [
  	Title:   "Red 'Extra' Tests"
	Author:  "Peter W A Wood"
	Version: 0.1.0
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
	Purpose: {Defines tests to be run in red/run-all.r and red/tests/run-all.r}
]


===start-group=== "Red compiler unit tests"
	--run-unit-test-quiet %source/compiler/lexer-test.r
===end-group===

===start-group=== "Red runtime tests"
  	--run-test-file-quiet %source/runtime/tools-test.reds
  	--run-test-file-quiet %source/runtime/unicode-test.red
===end-group===

===start-group=== "Red Compiler tests"
  	--run-script-quiet %source/compiler/print-test.r
  	--run-script-quiet %source/compiler/regression-tests.r
  	--run-script-quiet %source/compiler/run-time-error-test.r
  	--run-script-quiet %source/compiler/compile-error-test.r
===end-group===

===start-group=== "Red system directive tests"
  	--run-test-file-quiet %source/system/datatype.red
  	--run-test-file-quiet %source/system/context.red
  	--run-test-file-quiet %source/system/native-functions.red
  	--run-test-file-quiet %source/system/special-natives.red
  	--run-test-file-quiet %source/system/math-operators.red
    --run-test-file-quiet %source/system/auto.red
    --run-test-file-quiet %source/system/infix-syntax.red
    --run-test-file-quiet %source/system/runtime.red
===end-group===

===start-group=== "Red Library tests"
	
===end-group===