REBOL [
	Title:   "Red/System EXIT keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %exit-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

;==== Helper functions ====
test-file: %runnable/exit.reds

--clean: does [
    if exists? test-file [delete test-file]
    if all [exe exists? exe][delete exe]
]

compile: func [src /full][
	unless full [insert src "Red/System []^/"]		;-- add a default header if not provided
	write test-file src
	exe: --compile test-file
]

--assert-error?: func [msg][
	--assert found? find qt/comp-output msg
]
;==== end of helper functions ===


~~~start-file~~~ "exit-err"

  --test-- "simple test of compile and run"
    compile "test: does [exit] test" 
    either exe [
      --run exe
      --assert qt/output = ""
    ][
      qt/compile-error src 
    ]
    --clean

  --test-- "exit as last statement in until block"
	compile "until [exit]"
	--assert-error? "*** Compilation Error: exit is not allowed outside of a function"
	--clean
	
	compile "foo: does [until [exit]]"
	--assert-error? "*** Compilation Error: UNTIL requires a conditional expression"
	--clean

~~~end-file~~~


