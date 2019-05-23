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
    		parse txt [ any [ remove "l" | skip ] ]
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

    --test-- "Red print 2 - unset values #901"
        --compile-and-run-this-red {
            print [1 () 2]
        }
        --assert qt/output = "1  2^/"

    --test-- "Red recursive print 1"
        --compile-and-run-this-red {
            print [1 print [2 print [3 3] 2] 1]
        }
        --assert qt/output = "3 3^/2  2^/1  1^/"

    --test-- "Red recursive print 2"
        --compile-and-run-this-red {
            prin [1 prin [2 prin [3 3] 2] 1]
        }
        --assert qt/output = "3 32  21  1"

    --test-- "Red recursive print 3"
        --compile-and-run-this-red {
            prin [1 print [2 prin [3 print 4 3] 2] 1]
        }
        --assert qt/output = "4^/3  32  2^/1  1"

    ;-- TODO: print from CLI and GUI console should be also tested somehow
  
~~~end-file~~~ 
