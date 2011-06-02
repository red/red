REBOL [
	Title:   "Red/System conditional expressions test script"
	Author:  "Nenad Rakocevic"
	File: 	 %cond-expr-test.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

;==== Helper functions ====
test-file: %runnable/cond-expr.reds

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



~~~start-file~~~ "conditions-required-err"

  --test-- "IF takes a condition expression as first argument"
		compile "if 123 []"
		--assert-error? "*** Compilation Error: IF requires a conditional expression"
  		--clean
  	
		compile "if as integer! true []"
		--assert-error? "*** Compilation Error: IF requires a conditional expression"
		--clean
		
		compile {
			foo: func [return: [integer!]][123]
			if foo []
		}
		--assert-error? "*** Compilation Error: IF requires a conditional expression"
  		--clean
  		
		compile {
			foo: func [][a: 1]
			if foo []
		}
		--assert-error? "*** Compilation Error: return type missing in function: foo"
  		--clean
  	
		compile "foo: func [][if exit []]"
		--assert-error? "*** Compilation Error: IF requires a conditional expression"
		--clean
  	
  --test-- "EITHER takes a condition expression as first argument"
		compile "either 123 [][]"
		--assert-error? "*** Compilation Error: EITHER requires a conditional expression"
		--clean
		
		compile {
			foo: func [return: [integer!]][123]
			either foo [][]
		}
		--assert-error? "*** Compilation Error: EITHER requires a conditional expression"
  		--clean

		compile "foo: func [][either exit [][]]"
		--assert-error? "*** Compilation Error: EITHER requires a conditional expression"
		--clean
  	
  --test-- "UNTIL takes a condition expression as first argument"
		compile "until [123]"
		--assert-error? "*** Compilation Error: UNTIL requires a conditional expression"
		--clean
		
		compile {
			foo: func [return: [integer!]][123]
			until [foo]
		}
		--assert-error? "*** Compilation Error: UNTIL requires a conditional expression"
  		--clean

		compile "foo: func [][until [exit]]"
		--assert-error? "*** Compilation Error: UNTIL requires a conditional expression"
		--clean
  	
  --test-- "WHILE takes a condition expression as first argument"
		compile "while [123][a: 1]"
		--assert-error? "*** Compilation Error: WHILE requires a conditional expression"
		--clean
		
		compile {
			foo: func [return: [integer!]][123]
			while [foo][a: 1]
		}
		--assert-error? "*** Compilation Error: WHILE requires a conditional expression"
  		--clean

		compile "foo: func [][while [exit][a: 1]]"
		--assert-error? "*** Compilation Error: WHILE requires a conditional expression"
		--clean

  --test-- "ALL takes only condition expressions in argument block"
		compile "all [123]"
		--assert-error? "*** Compilation Error: ALL requires a conditional expression"
		--clean
		
		compile {
			foo: func [return: [integer!]][123]
			all [foo]
		}
		--assert-error? "*** Compilation Error: ALL requires a conditional expression"
  		--clean

		compile "foo: func [][all [exit]]"
		--assert-error? "*** Compilation Error: ALL requires a conditional expression"
		--clean
		
		compile "all [true 123]"
		--assert-error? "*** Compilation Error: ALL requires a conditional expression"
		--clean

  --test-- "ANY takes only condition expressions in argument block"
		compile "any [123]"
		--assert-error? "*** Compilation Error: ANY requires a conditional expression"
		--clean
		
		compile {
			foo: func [return: [integer!]][123]
			any [foo]
		}
		--assert-error? "*** Compilation Error: ANY requires a conditional expression"
  		--clean

		compile "foo: func [][any [exit]]"
		--assert-error? "*** Compilation Error: ANY requires a conditional expression"
		--clean
		
		compile "any [true 123]"
		--assert-error? "*** Compilation Error: ANY requires a conditional expression"
		--clean

~~~end-file~~~


