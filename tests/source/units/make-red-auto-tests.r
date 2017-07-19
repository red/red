REBOL [
  Title:   "Generate Red auto-tests"
	Author:  "Peter W A Wood"
	File: 	 %make-red-auto-tests.r
	Version: 0.1.0
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
	Purpose: {Generates Red auto-tests as needed.}
]
unless value? 'qt [
    do %../../../quick-test/quick-test.r
    qt/tests-dir: clean-path %../../
]

make-dir qt/tests-dir/source/units/auto-tests
qt/make-if-needed?  %source/units/auto-tests/lexer-auto-test.red 
                    %source/units/make-lexer-auto-tests.r