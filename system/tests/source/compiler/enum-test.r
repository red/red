REBOL [
	Title:   "Red/System enumerations test script"
	File: 	 %enum-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "enumerations compile"

===start-group=== "Enum redeclaration errors"

  --test-- "enum-redec-1"
	  --compile-this "Red/System [] #enum test! [print]"
	--assert-msg? "*** Compilation Error: attempt to redefine existing function name: print"
	  --clean

	--test-- "enum-redec-2"
	  --compile-this "Red/System [] #enum print [foo]"
	--assert-msg? "*** Compilation Error: attempt to redefine existing function name: print"
	  --clean

	--test-- "enum-redec-3"
    --compile-this "Red/System [] #enum test! [foo] foo: 3"
	--assert-msg? "*** Compilation Error: redeclaration of enumerator foo from test!"
	  --clean

	--test-- "enum-redec-4"
	  --compile-this "Red/System [] #enum test! [foo foo]"
	--assert-msg? "*** Compilation Error: redeclaration of enumerator: foo"
	  --clean

	--test-- "enum-redec-5"
	  --compile-this "Red/System [] #enum test! [a] #enum test! [b]"
	--assert-msg? "*** Compilation Error: redeclaration of enum identifier: test!"
	  --clean

	--test-- "enum-redec-6"
	  --compile-this {
	  	  Red/System [] 
		  #define foo 3
		  #enum test! [foo]
		}
	--assert-msg? "*** Compilation Error: attempt to redefine existing definition: foo"
	  --clean

	--test-- "enum-redec-7"
	  --compile-this {
	  	  Red/System [] 
		  #enum test! [foo]
		  #define foo 3
		  }
	--assert-msg? "*** Compilation Error: attempt to redefine existing definition: foo"
	  --clean

	--test-- "enum-redec-8"
	  --compile-this {
		  Red/System [] 
		  #enum test! [foo]
		  p: declare struct! [a [test!]]
		  p/a: "a"
		}
	--assert-msg? "*** Compilation Error: type mismatch on setting path: p/a"
	  --clean

	--test-- "enum-redec-9"
	  --compile-this {
		  Red/System [] 
		  #enum test! [foo]
		  p: declare pointer! [test!]}
	--assert-msg? "*** Compilation Error: invalid literal syntax: [test!]"
	  --clean

	--test-- "enum-redec-10"
	  --compile-this {
		  Red/System [] 
		  #enum test! [foo: 3]
		  f: func[foo [c-string!]][print foo]
		  f "bar"
		}
	--assert-msg? "*** Warning: function's argument redeclares enumeration: foo"
	  --clean
	  
	--test-- "enum-redec-11"
	  --compile-this {
		  Red/System []
		  #enum test! [foo]
		  foo/1: 3
		}
	--assert-msg? "*** Compilation Error: enumeration cannot be used as path root: foo"
	  --clean
	  
	--test-- "enum-redec-12"
	  --compile-this {
		  Red/System [] 
		  #enum test! [foo: bla]
		}
	--assert-msg? "*** Compilation Error: cannot resolve literal enum value for: foo"
	  --clean
===end-group===

~~~end-file~~~

