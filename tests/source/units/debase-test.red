Red [
	Title:   "Red debase test script"
	Author:  "Peter W A Wood"
	File: 	 %debase-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2016 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "debase"

===start-group=== "debase 64"

	--test-- "debase 64 1"          
		--assert strict-equal? "A simple string" to string! debase "QSBzaW1wbGUgc3RyaW5n"
	--test-- "debase 64 2"          
		--assert strict-equal? "A multi-line\nstring" to string! debase "QSBtdWx0aS1saW5lXG5zdHJpbmc="
	--test-- "debase 64 3"          
		--assert strict-equal? "A simple string" to string! debase/base "QSBzaW1wbGUgc3RyaW5n" 64
	--test-- "debase 64 4"          
		--assert strict-equal? "A multi-line\nstring" to string! debase/base "QSBtdWx0aS1saW5lXG5zdHJpbmc=" 64   
    
===end-group===

===start-group=== "debase 16"

	--test-- "debase 16 1"          
		--assert strict-equal? 
			"A simple string" 
			to string! debase/base "412073696d706c6520737472696e67" 16
	--test-- "debase 16 2"          
		--assert strict-equal? 
			"A multi-line\nstring" 
			to string! debase/base "41206d756c74692d6c696e655c6e737472696e67" 16

===end-group===

===start-group=== "debase 2"

	--test-- "debase 2 1"          
		--assert strict-equal? 
			"^(04)^(01)" 
			to string! debase/base "0000010000000001" 2

===end-group===

~~~end-file~~~