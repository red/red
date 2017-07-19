Red/System [
	Title:   "Red/System lib test script"
	Author:  "Peter W A Wood"
	File: 	 %float-lib-test-source.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

;; This script needs to be processed by make-lib-auto-test.r which sets the
;;  absolute path for the test libraries. It creates a file called
;;  lib-auto-test.reds in the auto-tests sub-directory.

#include %../../../../../quick-test/quick-test.reds

#define LIB1	"***abs-path***###prefix###ftestlib1@@@extension@@@"
#define LIB2	"***abs-path***###prefix###ftestlib2@@@extension@@@"
#define LIB3	"***abs-path***###prefix###ftestlib3@@@extension@@@"

;; library declarations
#import [
	LIB1 cdecl [
		addone: "addone" [
			f       [float!]
			return: [float!]
		]
		subtractone: "subtractone" [
			f       [float!]
			return: [float!]
		]
	]
]

#import [
	LIB2 cdecl [
		twice: "twice" [
			f       [float!]
			return: [float!]
		]
	]
]

#import [
	LIB3 cdecl [
		halve: "halve" [
			f       [float!]
			return: [float!]
		]
	]
]

~~~start-file~~~ "library - float"

		f: 0.0
  
	--test-- "flib1"
		--assert 2.0 = addone 1.0
  
	--test-- "flib2"
		f: addone 1.0
		--assert f = 2.0
  
	--test-- "flib3"
		f: subtractone 2.0
		--assert f = 1.0
  
	--test-- "flib4"
		--assert 1.0 = subtractone 2.0
  
	--test-- "flib5"    
		f: twice 1.0
		--assert f = 2.0
  
	--test-- "flib6"
		--assert 2.0 = twice 1.0
  
	--test-- "flib7"
		--assert 1.0 = halve 2.0
    
	--test-- "flib8"
		--assert 0.5 = halve 1.0
  
~~~end-file~~~
