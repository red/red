REBOL [
	Title:   "Red/System enumerations test script"
	File: 	 %enum-test.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "enumerations test"

  --test-- "Enum results"
	  --compile-and-run-this {#enum test! [foo boo] print [foo boo]}
	  --assert found? find qt/output "01"
	  --clean
	  
	  --compile-and-run-this {#enum test! [foo: 11 boo] print [foo boo]}
	  --assert found? find qt/output "1112"
	  --clean
	  
	  --compile-and-run-this {#enum test! [
		foo: 11 boo] print [foo boo]}
	  --assert found? find qt/output "1112"
	  --clean
	  
  	  --compile-and-run-this {
		#enum test! [
		
			foo: 11
			boo: 10
		] print [foo boo]}
	  --assert found? find qt/output "1110"
	  --clean
	  
  	  --compile-and-run-this {
		#enum test! [foo: 3]
		p: declare pointer! [integer!]
		p/value: foo
		print [p/value]}
	  --assert found? find qt/output "3"
	  --clean
	  	  
   	  --compile-and-run-this {
		#enum test! [foo: 3]
		p: declare struct! [a [test!] b [integer!]]
		p/a: foo
		p/b: foo
		print [p/a p/b]}
	  --assert found? find qt/output "33"
	  --clean
	  
	  --compile-and-run-this {
		#enum test! [foo]
		p: declare struct! [foo [integer!]]
		p/foo: 3
		print [foo p/foo]}
	  --assert found? find qt/output "03"
	  --clean
	  
  --test-- "Enum redeclaration errors"
	  --compile-this "#enum test! [print]"
	  --assert-msg? "*** Loading Error: attempt to redefine existing function name: print"
	  --clean

	  --compile-this "#enum print [foo]"
	  --assert-msg? "*** Loading Error: attempt to redefine existing function name: print"
	  --clean
	  
	  --compile-this "#enum test! [foo] foo: 3"
	  --assert-msg? "*** Compilation Error: redeclaration of enumerator foo from test!"
	  --clean
	  
	  --compile-this "#enum test! [foo foo]"
	  --assert-msg? "*** Loading Error: redeclaration of enumerator: foo"
	  --clean
	  
	  --compile-this {
		#enum test! [foo]
		#define foo 3}
	  --assert-msg? "*** Loading Error: redeclaration of enumerator: foo"
	  --clean

  	  --compile-this {
		#enum test! [foo]
		p: declare struct! [a [test!]]
		p/a: "a"}
	  --assert-msg? "*** Compilation Error: type mismatch on setting path: p/a"
	  --clean
	  
	  --compile-this {
		#enum test! [foo]
		p: declare pointer! [test!]}
	  --assert-msg? "*** Compilation Error: invalid literal syntax: [test!]"
	  --clean
	  
	  --compile-this {
		#enum test! [foo: 3]
		f: func[foo [c-string!]][print foo]
		f "bar"}
	  --assert-msg? "*** Compilation Error: function's argument redeclares enumeration: foo"
	  --clean
~~~end-file~~~

