REBOL [
  Title:   "Red Unicode test script"
	Author:  "Peter W A Wood"
	File: 	 %unicode-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../runtime/unicode.reds

~~~start-file~~~ "Unicode"

===start-group=== "load utf8"

  --test-- "lutf8-1"
    --compile-and-run-this {
      lutf8-1-s: "abcd"
      lutf8-1-node: unicode/load-utf8 lutf8-1-s 4
      print "abcd -> "
      print-hex lutf8-1-node/value
      print lf
    }
  --assert-printed? "abcd -> 61626364h"
  
===end-group===

~~~end-file~~~ 
