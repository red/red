REBOL [
  Title:   "Red print test script"
	Author:  "Peter W A Wood"
	File: 	 %print-test.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "Red print"

 	--test-- "Red print 1"
 		--compile-and-run-this {
 			Red[] 
 			print ["*test1*" 1]
 			print ["*test2*" 1 2 3]
 			prin "*test3* "
 			s: "12345"
    		forall s [prin s]
    		print ""
    		prin "*test4* "
    		s: "12345"
    		prin "***"
    		prin next s
    		print "***"
    		print "*test5* abcde✐"
    		;; issue #748
    		prin "*test6* "
    		txt: "Hello world"
    		parse txt [ while any [ remove "l" | skip ] ]
    		print txt
    		;; issue #796
    		prin "*test7* "
    		print "开会"
    		
    		str: "str123"
    		remove back tail str
    		prin "*test8* "
    		print head str
 		}
 		
 		--assert-printed? "*test1* 1"
 		--assert-printed? "*test2* 1 2 3"
    	--assert-printed? "*test3* 123452345345455"
    	--assert-printed? "*test4* ***2345***"
    	--assert-printed? "*test5* abcde✐"
    	--assert-printed? "*test6* Heo word"
    	--assert-printed? "*test7* 开会"
    	--assert-printed? "*test8* str12"
    	--assert none = find qt/output "*test6* Heo wordd"
  
~~~end-file~~~ 
