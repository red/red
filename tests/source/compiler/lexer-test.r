Rebol [
	Title:   "Red lexer test script"
	Author:  "Peter W A Wood"
	File: 	 %byte-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

;; setup
store-halt: :halt
halt: func [][]

store-quiet-mode: system/options/quiet
system/options/quiet: true

do %../../../system/utils/encap-fs.r
do %../../../quick-test/quick-unit-test.r
do %../../../lexer.r


~~~start-file~~~ "lexer"

===start-group=== "process"

	--test-- "lexer-1"
	src: {Red [] 123}
	--assert [[] 123] = lexer/process src
	
	--test-- "lexer-2"
	src: {Red [] aa}
	--assert [[] aa] = lexer/process src
	
	--test-- "lexer-3"
	src: {Red [] 'a}
	--assert [[] 'a] = lexer/process src
	
	--test-- "lexer-4"
	src: {Red [] a:}
	--assert [[] a:] = lexer/process src

	--test-- "lexer-5"
	src: {Red [] :a}
	--assert [[] :a] = lexer/process src

	--test-- "lexer-6"
	src: {Red [] /}
	--assert [[] /] = lexer/process src

	--test-- "lexer-7"
	src: {Red [] /test}
	--assert [[] /test] = lexer/process src

	--test-- "lexer-8"
	src: {Red [] (a)}
	--assert [[] (a)] = lexer/process src

	--test-- "lexer-9"
	src: {Red [] []}
	--assert [[] []] = lexer/process src

	--test-- "lexer-10"
	src: {Red [] "t"}
	--assert [[] "t"] = lexer/process src

	--test-- "lexer-11"
	src: {Red [] #"a"}
	--assert [[] #'00000061] = lexer/process src

	--test-- "lexer-12"
	src: {Red [] #a}
	--assert [[] #a] = lexer/process src

	--test-- "lexer-13"
	src: {Red [] #"^^(00)"}
	--assert [[] #'00000000] = lexer/process src

	--test-- "lexer-14"
	src: {Red [] foo/bar}
	--assert [[] foo/bar] = lexer/process src

	--test-- "lexer-15"
	src: {Red [] 'foo/bar}
	--assert [[] 'foo/bar] = lexer/process src

	--test-- "lexer-16"
	src: {Red [] foo/bar:}
	--assert [[] foo/bar:] = lexer/process src
	
	--test-- "lexer-17"
	src: {
		Red [title: "test"]

		+ - 
		test123
		4 ttt 5655 /4545
		/ // -123 +5
		print /a 'lit-word
		b: (r + 4) test /refinement
		4545 "foo bar" ;-- comment

		#issue
		#{1234}

		#{
		45788956 ;-- test binary comment
		AAFFEEFF
		}

		comment {test

		}
		%foo/bar.red "foo^@^^/bar"

		{
	
	test
	^^(45)
	^^(A2)
	^^(00A2)
	^^(20AC)
	^^(024B62)
	}

		either a = b [
			print [ok]
		][
			print [now]
		]

		foo/bar 'foo/bar foo/bar:
		#[none] #[true ] #[false ] 
	}
	
	result: [
		[title: "test"]
		+ -
		test123
		4 ttt 5655 /4545
		/ // -123 5
		print /a 'lit-word
		b: (r + 4) test /refinement
		4545 "foo bar"
		#issue
		#{1234}
		#{45788956AAFFEEFF}
		comment "test^/^/^-^-"
		%foo/bar.red "foo^@^/bar"
		{
^-
^-test
^-E
^-¢
^-¢
^-€
^-𤭢
^-}
		either a = b [
			print [ok]
		] [
			print [now]
		]
		foo/bar 'foo/bar foo/bar:
		#[none] #[true] #[false]
	]
	--assert result = lexer/process src


	--test-- "lexer-20"
	  src: {
	    Red[]
	    a: 1
	  }
	--assert [[] a: 1] = lexer/process src

	--test-- "lexer-21"
	  src: {
	    Red[]
	    1: 1
	  }
	  lexer/process src
	--assert-printed? "*** Syntax Error: Invalid integer! value"
	--assert-printed? "*** line: 2"
	--assert-printed? {*** at: "1: 1}
	  
	;--test-- "lexer-22"
	;  src: {
	;    Red/System[]
	;    a: 1
	;  }
	;  lexer/process src
	;--assert-printed? "*** Syntax Error: Invalid Red program"
	;--assert-printed? "*** line: 1"
	;--assert-printed?  "*** at: {/System[]"
	
	--test-- "lexer-23"
	  src: {Red [] #"^^/"}
	--assert "[[] #'0000000A]" = mold lexer/process src

	--test-- "lexer-30"
	src: {Red [] 123.0}
	--assert "123.0" = mold second lexer/process src

	--test-- "lexer-31"
	src: {Red [] 1.123}
	--assert "1.123" = mold second lexer/process src

	--test-- "lexer-32"
	src: {Red [] .123}
	--assert "0.123" = mold second lexer/process src

	--test-- "lexer-33"
	src: {Red [] 1E2}
	--assert "100.0" = mold second lexer/process src

	--test-- "lexer-34"
	src: {Red [] 1.2E3}
	--assert "1200.0" = mold second lexer/process src

	--test-- "lexer-35"
	src: {Red [] .1E2}
	--assert "10.0" = mold second lexer/process src

	--test-- "lexer-36"
	src: {Red [] .123E2}
	--assert "12.3" = mold second lexer/process src
	  
===end-group===
	
~~~end-file~~~

;; tidy up
halt: :store-halt
system/options/quiet: :store-quiet-mode
prin ""

;;; #"a" #"^^/"

