REBOL [
	Title:   "Red/System EXIT keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %exit-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "exit-err"

  --test-- "simple test of compile and run"
    --compile-and-run-this "Red/System [] test: does [exit] test" 
    --assert qt/output = ""
    --clean

  --test-- "exit as last statement in until block"
	--compile-this "Red/System [] until [exit]"
  --assert-msg? "*** Compilation Error: exit is not allowed outside of a function"
	--clean
	
  --test-- "exit-err-3"
	--compile-this "Red/System [] foo: does [until [exit]]"
  --assert-msg? "*** Compilation Error: UNTIL requires a conditional expression as last expression"
	--clean

~~~end-file~~~


