Red/System [
	Title:   "Red/System lib test script"
	Author:  "Peter W A Wood"
	File: 	 %float-lib-test-source.reds
	Rights:  "Copyright (C) 2011 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;; This script needs to be processed by make-lib-auto-test.r which sets the
;;  absolute path for the test libraries. It creates a file called
;;  lib-auto-test.reds in the auto-tests sub-directory. It also generates the
;;  correct name for the library under the os it is running

#include %../../../../../quick-test/quick-test.reds

;; library declarations
#import [
  "***abs-path***###prefix###testlib1@@@extension@@@" cdecl [
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
  "***abs-path***###prefix###testlib2@@@extension@@@" cdecl [
    twice: "twice" [
      f       [float!]
      return: [float!]
    ]
  ]
]

#import [
  "***abs-path***###prefix###testlib3@@@extension@@@" cdecl [
    halve: "halve" [
      f       [float!]
      return: [float!]
    ]
  ]
]

~~~start-file~~~ "library"

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

