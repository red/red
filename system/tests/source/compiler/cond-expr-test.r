REBOL [
	Title:   "Red/System conditional expressions test script"
	Author:  "Nenad Rakocevic"
	File: 	 %cond-expr-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "conditions-required-err"

  --test-- "IF takes a condition expression as first argument"
  	  --compile-this "Red/System [] if 123 []"
	  --assert-msg? "*** Compilation Error: IF requires a conditional expression"
	  --clean
  	
	  --compile-this "Red/System [] if as integer! true []"
	  --assert-msg? "*** Compilation Error: IF requires a conditional expression"
	  --clean
		
	  --compile-this {
	  		Red/System [] 
		  	foo: func [return: [integer!]][123]
		  	if foo []
		}
		--assert-msg? "*** Compilation Error: IF requires a conditional expression"
		--clean
  		
		--compile-this {
			Red/System [] 
		  	foo: func [][a: 1]
		  	if foo []
		}
		--assert-msg? "*** Compilation Error: IF requires a conditional expression"
		--clean
  	
		--compile-this "Red/System [] foo: func [][if exit []]"
		--assert-msg? "*** Compilation Error: IF requires a conditional expression"
		--clean
  	
  --test-- "EITHER takes a condition expression as first argument"
	  --compile-this "Red/System [] either 123 [][]"
	  --assert-msg? "*** Compilation Error: EITHER requires a conditional expression"
	  --clean
		
	  --compile-this {
	  		Red/System [] 
			foo: func [return: [integer!]][123]
			either foo [][]
		}
		--assert-msg? "*** Compilation Error: EITHER requires a conditional expression"
		--clean

		--compile-this "Red/System [] foo: func [][either exit [][]]"
		--assert-msg? "*** Compilation Error: EITHER requires a conditional expression"
		--clean
  	
  --test-- "UNTIL takes a condition expression as first argument"
	  --compile-this "Red/System [] until [123]"
	  --assert-msg? "*** Compilation Error: UNTIL requires a conditional expression"
	  --clean
		
	  --compile-this {
	  		Red/System [] 
			foo: func [return: [integer!]][123]
			until [foo]
		}
		--assert-msg? "*** Compilation Error: UNTIL requires a conditional expression"
		--clean

		--compile-this "Red/System [] foo: func [][until [exit]]"
		--assert-msg? "*** Compilation Error: UNTIL requires a conditional expression"
		--clean
  	
  --test-- "WHILE takes a condition expression as first argument"
	  --compile-this "Red/System [] while [123][a: 1]"
	  --assert-msg? "*** Compilation Error: WHILE requires a conditional expression"
	  --clean
		
	  --compile-this {
	  		Red/System [] 
			foo: func [return: [integer!]][123]
			while [foo][a: 1]
		}
		--assert-msg? "*** Compilation Error: WHILE requires a conditional expression"
  	--clean

		--compile-this "Red/System [] foo: func [][while [exit][a: 1]]"
		--assert-msg? "*** Compilation Error: WHILE requires a conditional expression"
		--clean

  --test-- "ALL takes only condition expressions in argument block"
		--compile-this "Red/System [] all [123]"
		--assert-msg? "*** Compilation Error: ALL requires a conditional expression"
		--clean
		
		--compile-this {
			Red/System [] 
			foo: func [return: [integer!]][123]
			all [foo]
		}
		--assert-msg? "*** Compilation Error: ALL requires a conditional expression"
  	--clean

		--compile-this "Red/System [] foo: func [][all [exit]]"
		--assert-msg? "*** Compilation Error: ALL requires a conditional expression"
		--clean
		
		--compile-this "Red/System [] all [true 123]"
		--assert-msg? "*** Compilation Error: ALL requires a conditional expression"
		--clean

  --test-- "ANY takes only condition expressions in argument block"
		--compile-this "Red/System [] any [123]"
		--assert-msg? "*** Compilation Error: ANY requires a conditional expression"
		--clean
		
		--compile-this {
			Red/System [] 
			foo: func [return: [integer!]][123]
			any [foo]
		}
		--assert-msg? "*** Compilation Error: ANY requires a conditional expression"
  		--clean

		--compile-this "Red/System [] foo: func [][any [exit]]"
		--assert-msg? "*** Compilation Error: ANY requires a conditional expression"
		--clean
		
		--compile-this "Red/System [] any [true 123]"
		--assert-msg? "*** Compilation Error: ANY requires a conditional expression"
		--clean
		
		--test-- {Either followed by a block containg a call to a funtion which 
		          doesn't return a value should compile}
		--compile-this {
		  Red/System [] 
		  x: does []
		  either true [x] [x]
		 }
		--assert qt/compile-ok? 
		
~~~end-file~~~

