Red/System [
	Title:   "Red/System lib test script"
	Author:  "Peter W A Wood"
	File: 	 %float32-lib-test-source.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

;; This script needs to be processed by make-lib-auto-test.r which sets the
;;  absolute path for the test libraries. It creates a file called
;;  lib-auto-test.reds in the auto-tests sub-directory.

#include %../../../../../quick-test/quick-test.reds

#define LIB1	"***abs-path***###prefix###f32testlib1@@@extension@@@"
#define LIB2	"***abs-path***###prefix###f32testlib2@@@extension@@@"
#define LIB3	"***abs-path***###prefix###f32testlib3@@@extension@@@"

;; library declarations
#import [
	LIB1 cdecl [
		addone: "addone" [
			f       [float32!]
			return: [float32!]
		]
		subtractone: "subtractone" [
			f       [float32!]
			return: [float32!]
		]
	]
]

#import [
	LIB2 cdecl [
		twice: "twice" [
			f       [float32!]
			return: [float32!]
		]
	]
]

#import [
	LIB3 cdecl [
		halve: "halve" [
			f       [float32!]
			return: [float32!]
		]
	]
]

~~~start-file~~~ "library - float32"

		f: as float32! 0.0
  
	--test-- "f32lib1"
		--assert (as float32! 2.0) = addone as float32! 1.0
  
	--test-- "f32lib2"
		f: addone as float32! 1.0
		--assert f = as float32! 2.0
  
	--test-- "f32lib3"
		f: subtractone as float32! 2.0
		--assert f = as float32! 1.0
	
	--test-- "f32lib4"
		--assert (as float32! 1.0) = subtractone as float32! 2.0
	
	--test-- "f32lib5"    
		  f: twice as float32! 1.0
		--assert f = as float32! 2.0
	
	--test-- "f32lib6"
		--assert (as float32! 2.0) = twice as float32! 1.0
	
	--test-- "f32lib7"
		--assert (as float32! 1.0) = halve as float32! 2.0
	  
	--test-- "f32lib8"
		--assert (as float32! 0.5) = halve as float32! 1.0
  
~~~end-file~~~

