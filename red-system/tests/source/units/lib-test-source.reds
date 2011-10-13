Red/System [
	Title:   "Red/System lib test script"
	Author:  "Peter W A Wood"
	File: 	 %lib-test-source.reds
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
      i       [integer!]
      return: [integer!]
    ]
    subtractone: "subtractone" [
      i       [integer!]
      return: [integer!]
    ]
  ]
]

#import [
  "***abs-path***###prefix###testlib2@@@extension@@@" cdecl [
    twice: "twice" [
      i       [integer!]
      return: [integer!]
    ]
  ]
]

#import [
  "***abs-path***###prefix###testlib3@@@extension@@@" cdecl [
    halve: "halve" [
      i       [integer!]
      return: [integer!]
    ]
  ]
]

~~~start-file~~~ "library"
  
  --test-- "lib1"
  --assert 2 = addone 1
  --assert 1 = subtractone 2
  
  --test-- "lib2"    
  --assert 2 = twice 1
  --assert 4 = twice 2
  
  --test-- "lib3"
  --assert 1 = halve 2
  --assert 0 = halve 1
  
~~~end-file~~~

