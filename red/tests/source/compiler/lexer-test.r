Rebol [
	Title:   "Red lexer test script"
	Author:  "Peter W A Wood"
	File: 	 %byte-test.reds
	Rights:  "Copyright (C) 2011 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;; setup
store-halt: :halt
halt: func [][]
store-print: :print
output: copy "" 
print: func [v] [append output v]
output-contains?: func [
    text [string!]
  ][
    either none <> find output text [
      true
    ][
    false]
]
store-quiet-mode: system/options/quiet
system/options/quiet: true

do %../../../../quick-test/quick-unit-test.r
do %../../../lexer.r

~~~start-file~~~ "lexer"

	--test-- "lexer-1"
	  src: {
	    Red[]
	    a: 1
	  }
	--assert [[] a: 1] = lexer/run src

	--test-- "lexer-2"
	  output: copy ""
	  src: {
	    Red[]
	    1: 1
	  }
	  lexer/run src
	--assert output-contains? "*** Syntax Error: Invalid word! value"
	--assert output-contains? "*** line: 2"
	--assert output-contains?  {*** at: "1: 1}
	  
	--test-- "lexer-3"
	  output: copy ""
	  src: {
	    Red/System[]
	    a: 1
	  }
	  lexer/run src
	--assert output-contains? "*** Syntax Error: Invalid Red program"
	--assert output-contains? "*** line: 1"
	--assert output-contains?  "*** at: {/System[]"
	  
~~~end-file~~~

;; tidy up
halt: :store-halt
print: :store-print
system/options/quiet: :store-quiet-mode
prin ""

