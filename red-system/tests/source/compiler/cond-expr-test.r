REBOL [
	Title:   "Red/System conditional expressions test script"
	Author:  "Nenad Rakocevic"
	File: 	 %cond-expr-test.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "conditions-required-err"

  --test-- "IF takes a condition expression as first argument"
	  --compile-this "if 123 []"
	  --assert-msg? "*** Compilation Error: IF requires a conditional expression"
	  --clean
  	
	  --compile-this "if as integer! true []"
	  --assert-msg? "*** Compilation Error: IF requires a conditional expression"
	  --clean
		
	  --compile-this {
		  	foo: func [return: [integer!]][123]
		  	if foo []
		}
		--assert-msg? "*** Compilation Error: IF requires a conditional expression"
		--clean
  		
		--compile-this {
		  	foo: func [][a: 1]
		  	if foo []
		}
		--assert-msg? "*** Compilation Error: return type missing in function: foo"
		--clean
  	
		--compile-this "foo: func [][if exit []]"
		--assert-msg? "*** Compilation Error: IF requires a conditional expression"
		--clean
  	
  --test-- "EITHER takes a condition expression as first argument"
	  --compile-this "either 123 [][]"
	  --assert-msg? "*** Compilation Error: EITHER requires a conditional expression"
	  --clean
		
	  --compile-this {
			foo: func [return: [integer!]][123]
			either foo [][]
		}
		--assert-msg? "*** Compilation Error: EITHER requires a conditional expression"
		--clean

		--compile-this "foo: func [][either exit [][]]"
		--assert-msg? "*** Compilation Error: EITHER requires a conditional expression"
		--clean
  	
  --test-- "UNTIL takes a condition expression as first argument"
	  --compile-this "until [123]"
	  --assert-msg? "*** Compilation Error: UNTIL requires a conditional expression"
	  --clean
		
	  --compile-this {
			foo: func [return: [integer!]][123]
			until [foo]
		}
		--assert-msg? "*** Compilation Error: UNTIL requires a conditional expression"
		--clean

		--compile-this "foo: func [][until [exit]]"
		--assert-msg? "*** Compilation Error: UNTIL requires a conditional expression"
		--clean
  	
  --test-- "WHILE takes a condition expression as first argument"
	  --compile-this "while [123][a: 1]"
	  --assert-msg? "*** Compilation Error: WHILE requires a conditional expression"
	  --clean
		
	  --compile-this {
			foo: func [return: [integer!]][123]
			while [foo][a: 1]
		}
		--assert-msg? "*** Compilation Error: WHILE requires a conditional expression"
  	--clean

		--compile-this "foo: func [][while [exit][a: 1]]"
		--assert-msg? "*** Compilation Error: WHILE requires a conditional expression"
		--clean

  --test-- "ALL takes only condition expressions in argument block"
		--compile-this "all [123]"
		--assert-msg? "*** Compilation Error: ALL requires a conditional expression"
		--clean
		
		--compile-this {
			foo: func [return: [integer!]][123]
			all [foo]
		}
		--assert-msg? "*** Compilation Error: ALL requires a conditional expression"
  	--clean

		--compile-this "foo: func [][all [exit]]"
		--assert-msg? "*** Compilation Error: ALL requires a conditional expression"
		--clean
		
		--compile-this "all [true 123]"
		--assert-msg? "*** Compilation Error: ALL requires a conditional expression"
		--clean

  --test-- "ANY takes only condition expressions in argument block"
		--compile-this "any [123]"
		--assert-msg? "*** Compilation Error: ANY requires a conditional expression"
		--clean
		
		--compile-this {
			foo: func [return: [integer!]][123]
			any [foo]
		}
		--assert-msg? "*** Compilation Error: ANY requires a conditional expression"
  		--clean

		--compile-this "foo: func [][any [exit]]"
		--assert-msg? "*** Compilation Error: ANY requires a conditional expression"
		--clean
		
		--compile-this "any [true 123]"
		--assert-msg? "*** Compilation Error: ANY requires a conditional expression"
		--clean

~~~end-file~~~

