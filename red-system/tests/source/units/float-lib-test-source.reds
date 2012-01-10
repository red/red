Red/System [
	Title:   "Red/System lib test script"
	Author:  "Peter W A Wood"
	File: 	 %float-lib-test-source.reds
	Rights:  "Copyright (C) 2011 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;; This script needs to be processed by make-lib-auto-test.r which sets the
;;  absolute path for the test libraries. It creates a file called
;;  lib-auto-test.reds in the auto-tests sub-directory.

#include %../../../../../quick-test/quick-test.reds

#switch OS [
	Windows  [
	  #define LIB1	"***abs-path***ftestlib1.dll"
	  #define LIB2	"***abs-path***ftestlib2.dll"
	  #define LIB3	"***abs-path***ftestlib3.dll"
	]
	MacOSX	 [
	  #define LIB1	"***abs-path***libftestlib1.dylib"
	  #define LIB2	"***abs-path***libftestlib2.dylib"
	  #define LIB3	"***abs-path***libftestlib3.dylib"
	]
	#default [
		#define LIB1	"***abs-path***libftestlib1.so"
	  #define LIB2	"***abs-path***libftestlib2.so"
	  #define LIB3	"***abs-path***libftestlib3.so"
	]
]

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
  
  --test-- "lib1"
    f: addone 1.0
    f: subtractone 2.0
  --assert 1 = 1
  
  --test-- "lib2"    
    f: twice 1.0
    f: twice 2.0
  --assert 2 = 2
  
  --test-- "lib3"
    f: halve 2.0
    f: halve 1.0
  --assert 3 = 3
  
~~~end-file~~~

