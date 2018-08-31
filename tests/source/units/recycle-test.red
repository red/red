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
		rb1-b: make block! [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20] 
		rb1-b: none
		recycle
		rb1-mem2: stats
		--assert rb1-mem-2 <= rb1-mem
		
	--test-- "recycle-block-2"
		rb2-b: copy [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
		recycle
		rb2-mem: stats
		loop 2000 [rb2-b: copy rb2-b]
		recycle
		rb2-mem2: stats
		--assert rb2-mem2 <= rb2-mem
		
	--test-- "recycle-block-3"
		rb3-b: copy [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
		recycle
		rb3-mem: stats
		loop 2000 [
			rb3-b: copy [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
		]
		recycle
		rb3-mem2: stats
		--assert rb3-mem2 <= rb3-mem
	
	--test-- "recycle-block-4"
		rb4-bb: copy [1 2 3 4 5 6 7 8 9 10]
		loop 12 [append rb4-bb rb4-bb]
		rb4-b: copy rb4-bb
		recycle
		rb4-mem: stats
		loop 2000 [
			rb4-b: copy rb4-bb
			recycle
		]
		rb4-mem2: stats
		--assert rb4-mem2 <= rb4-mem

	--test-- "recycle-block-5"
		rb5-m: #(b: [1 2 3 4 5 6 7 8 9 10])
		recycle
		rb5-mem: stats
		loop 2000 [ rb5-m/b: copy [1 2 3 4 5 6 7 8 9 10] ]
		recycle
		rb5-mem2: stats
		--assert rb5-mem2 <= rb5-mem
	
	--test-- "recycle-block-6"
		rb6-o: make object! [ b: copy [1 2 3 4 5 6 7 8 9 10] ]
		recycle
		rb6-mem: stats
		loop 2000 [ rb6-o/b: copy [1 2 3 4 5 6 7 8 9 20] ]
		recycle
		rb6-mem2: stats
		--assert rb6-mem2 <= rb6-mem
		
		--test-- "recycle-block-7"
		rb7-b: copy [1 2 3 4 5 6 7 8 9 10]
		loop 12 [append rb7-b rb7-b]
		rb7-bbbbb: compose [bbbb [bbb [bb [b (copy rb7-b)]]]]
		recycle
		rb7-mem: stats
		rb7-bbbbb/bbbb/bbb/bb/b: none
		recycle
		rb7-mem2: stats
		--assert rb7-mem2 <= rb7-mem
		
===end-group===

===start-group=== "recycle map"

	--test-- "recycle-map-1"
		rm1-map: none
		recycle
		rm1-mem: stats
		rm1-map: #(a: 1 b: 2 c: 3 d: 4)
		rm1-map: none
		recycle
		rm1-mem2: stats
		--assert rm1-mem2 <= rm1-mem
	--test-- "recycle-map-2"
		rm2-map: none
		recycle
		rm2-mem: stats
		rm2-map: make map! [ a: 1 b: [ 1 2 3 4 5 6 7 8 9 10 ] ]
		rm2-map: none
		recycle
		rm2-mem2: stats
		--assert rm2-mem2 <= rm2-mem

===end-group===

	
~~~end-file~~~