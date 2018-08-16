Red [
	Title:   "Red recycle test script"
	Author:  "Peter W A Wood"
	File: 	 %recycle-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "recycle test"

===start-group=== "recyle block"
	
	--test-- "recycle-block-1"
		recycle				
		rb1-mem: stats
		rb1-b: make block! 1e10
		rb1-b: none
		recycle
		--assert stats <= rb1-mem
		
	--test-- "recycle-block-2"
		recycle
		rb2-b: copy [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
		rb2-mem: stats
		loop 2000 [rb2-b: copy rb2-b]
		recycle
		--assert stats <= rb2-mem
		
	--test-- "recycle-block-3"
		recycle
		rb3-b: copy [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
		rb3-mem: stats
		loop 2000 [
			rb3-b: copy [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
		]
		recycle
		--assert stats <= rb3-mem
			
	--test-- "recycle-block-4"
		rb4-bb: copy [1 2 3 4 5 6 7 8 9 10]
		loop 12 [append rb4-bb rb4-bb]
		recycle
		rb4-b: copy rb4-bb
		rb4-mem: stats
		loop 2000 [
			rb4-b: copy rb4-bb
			recycle
		]
		--assert stats <= rb4-mem
		
	--test-- "recycle-block-5"
		rb5-m: #(b: [1 2 3 4 5 6 7 8 9 10])
		rb5-mem: stats
		loop 2000 [ rb5-m/b: copy [1 2 3 4 5 6 7 8 9 10] ]
		recycle
		--assert rb5-mem <= stats
	
	--test-- "recycle-block-6"
		rb6-o: make object! [ b: copy [1 2 3 4 5 6 7 8 9 10] ]
		rb6-mem: stats
		loop 2000 [ rb6-o/b: copy [1 2 3 4 5 6 7 8 9 20] ]
		recycle
		--assert rb6-mem <= stats
		
===end-group===
	
~~~end-file~~~