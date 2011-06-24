Red/System [
	Title:   "Red/System EXIT keyword test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %function-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

~~~start-file~~~ "function"

  --test-- "func-1 issue #103"
    f1-f: func [
      /local
      f1-f1 [integer!]
    ][
      f1-f1: 3 
      --assert f1-f1 = 3
    ]

    f1-f1: func [
      return: [integer!]
    ][
      5
    ]
  --assert f1-f1 = 5
  f1-f

~~~end-file~~~
