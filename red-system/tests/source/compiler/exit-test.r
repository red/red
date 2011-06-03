REBOL [
	Title:   "Red/System EXIT keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %exit-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "exit-err"

  --test-- "simple test of compile and run"
    --compile-this "test: does [exit] test" 
    either exe [
      --run exe
      --assert qt/output = ""
    ][
      qt/compile-error src 
    ]
    --clean

  --test-- "exit as last statement in until block"
	--compile-this "until [exit]"
	--assert-msg? "*** Compilation Error: exit is not allowed outside of a function"
	--clean
	
	--compile-this "foo: does [until [exit]]"
	--assert-msg? "*** Compilation Error: UNTIL requires a conditional expression"
	--clean

~~~end-file~~~


