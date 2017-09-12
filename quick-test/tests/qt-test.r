REBOL [
	Title:   "Red/System quick testing framework unit tests"
	Author:  "Peter W A Wood"
	File: 	 %qt-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

do %../quick-test.r

~~~start-file~~~  "quick-test.r unit tests"

===start-group=== "UTF-16LE to UTF-8"

  --test-- "u16u8-1"
  --assert "^(CE)^(A7)" = qt/utf-16le-to-utf-8 "^(A7)^(03)"
  
  --test-- "u16u8-2"
  --assert "^(CE)^(B1)" = qt/utf-16le-to-utf-8 "^(B1)^(03)"
  
  --test-- "u16u8-3"
  --assert "^(E1)^(BF)^(96)" = qt/utf-16le-to-utf-8 "^(D6)^(1F)"
  print to binary! qt/utf-16le-to-utf-8 "^(D6)^(1F)"
  
  --test-- "u16u8-4"
  --assert "^(CE)^(B5)" = qt/utf-16le-to-utf-8 "^(B5)^(03)"
  
  
===end-group===

~~~end-file~~~ 

