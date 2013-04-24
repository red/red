REBOL [
	Title:   "Red/System EXIT keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %exit-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "exit-err"

  --test-- "simple test of compile and run"
    --compile-and-run-this "test: does [exit] test" 
    --assert qt/output = ""
    --clean

  --test-- "exit as last statement in until block"
	--compile-this "until [exit]"
  --assert-msg? "*** Compilation Error: exit is not allowed outside of a function"
	--clean
	
  --test-- "exit-err-3"
	--compile-this "foo: does [until [exit]]"
  --assert-msg? "*** Compilation Error: UNTIL requires a conditional expression as last expression"
	--clean

~~~end-file~~~


