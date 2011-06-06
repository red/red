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
  
  --test-- "simple if"
    i: 0
    if true [i: 1]
  --assert i = 1
  
  --test-- "nested if"
    i: 0
    if true [
      if true [
        i: 1
      ]
    ]
  --assert i = 1
  
  --test-- "double nested if"
    i: 0
    if true [
      if true [
        if true [
          i: 1
        ]
      ]
    ]
  --assert i = 1
  
  --test-- "triple nested if"
    i: 0
    if true [
      if true [
        if true [
          if true [
            i: 1
          ]
        ]
      ]
    ]
  --assert i = 1
  
  --test-- "byte nested if"
    ct-byte: #"^(C0)"
    i: 0
    if #"^(7F)" < ct-byte [
      if ct-byte < #"^(FE)" [
        if #"^(A5)" < ct-byte [
          if ct-byte = #"^(C0)" [
            i: 1
          ]
        ]
      ]
    ]
  --assert i = 1
  
  --test-- "byte nested if inside function"
    ct-byte-nested: func [
      b [byte!]
      return: [integer!]
    ][
      if b > #"^(7F)" [                                 
        if #"^(C0)" = b [return 1]
        if #"^(C1)" = b [return 2]
        if #"^(F4)" < b [return 3]
        if b < #"^(E0)" [
          if b < #"^(D0)" [return 4]   
          if b > #"^(CF)" [return 5]
        ]
      ]
      0
    ]
  --assert 0 = ct-byte-nested #"^(00)"
  --assert 1 = ct-byte-nested #"^(C0)"  
  --assert 2 = ct-byte-nested #"^(C1)"  
  --assert 3 = ct-byte-nested #"^(F9)"  
  --assert 4 = ct-byte-nested #"^(C5)"  
  --assert 5 = ct-byte-nested #"^(D1)"  
    
~~~end-file~~~

