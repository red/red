REBOL [
  Title:   "Red print test script"
	Author:  "Peter W A Wood"
	File: 	 %print-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "Red print"

 --test-- "Red print 1"
   --compile-and-run-red %source/compiler/print-test.red 
  --assert-red-printed? 1
  
  --test-- "Red print 2"
    --compile-and-run-this-red {print 2}
  --assert-red-printed? 2
  
  --test-- "Red print 3"
    --compile-and-run-this-red {
      s: "12345"
      forall s [prin s]
    }
  --assert-red-printed? "123452345345455"
  
  --test-- "Red print 4"
    --compile-and-run-this-red {
      s: "12345"
      prin "***"
      prin next s
      print "***"
    }
  --assert-red-printed? "***2345***"
  
  --test-- "issue #427"
    --compile-and-run-this-red {
      issue427-f: func [
        /local count
      ][
        repeat count 5 [
          print count
        ]
      ]
      issue427-f
    }
  --assert-red-printed? "1^/2^/3^/4^/5^/"
  
~~~end-file~~~ 
