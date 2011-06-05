Red/System [
	Title:   "Red/System conditonal test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %conditional-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

~~~start-file~~~ "conditional"

  --test-- "this code exposes a bug in opcode generation"
    ;; before the bug was fixed this code caused a segmentation error
    scan-utf-8: func [
      str [c-string!]
      return: [integer!]
      /local
        i [integer!]
    ][
      i: 1
      until [
        if str/1 > #"^(7F)" [                       
          if #"^(C0)" = str/1 [return i]
          if #"^(C1)" = str/1 [return i]
          if #"^(F4)" < str/1 [return i]
          if str/1 < #"^(E0)" [
             if str/2 < #"^(80)" [return i]
          ]
        ]
        i: i + 1
        str: str + 1
        str/1 = null-char
      ]
      0
    ]
  --assert 0 = scan-utf-8 "a" 
  
~~~end-file~~~

