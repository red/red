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

#include %../../../quick-test/quick-test.reds

~~~start-file~~~ "library"
  
  --test-- "lib1"
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
  --assert 2 = addone 1
  --assert 1 = subtractone 2
  
~~~end-file~~~

