REBOL [
	Title:   "Red/System type inference test script"
	Author:  "Nenad Rakocevic"
	File: 	 %inference-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../

;=== Helper functions ===
--assert-compiles?: func [src [string!] /local exe][
	exe: --compile-and-run-this src
 	--assert qt/output = ""
    --clean
]

;=== end of helper functions ===

~~~start-file~~~ "inference-compile"

	--test-- "simple inference 1"
		--assert-compiles? "Red/System [] foo: func [/local a][a: 1]"
		
	--test-- "simple inference 2"
		--assert-compiles? {Red/System [] foo: func [/local a b][a: true b: #"A"]}
	
	--test-- "simple inference 3"
		--assert-compiles? {Red/System [] foo: func [/local a][a: either true ["A"]["B"]]}
		
	--test-- "simple inference 4"
		--assert-compiles? "Red/System [] foo: func [/local a][while [true][a: 1]]"
		
	--test-- "simple inference 5"
		--assert-compiles? {
			Red/System [] 
			foo: func [return: [integer!] /local a][a: 123 a]
			bar: func [/local b][b: foo]
		}
		
~~~end-file~~~


~~~start-file~~~ "inference-err"

	--test-- "inference error"
		--compile-this "Red/System [] foo: func [/local a][a]"
		--assert-msg? "*** Compilation Error: local variable a used before being initialized!"
		--clean
	
~~~end-file~~~


