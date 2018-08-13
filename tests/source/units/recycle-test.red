Red [
	Title:   "Red recycle test script"
	Author:  "Peter W A Wood"
	File: 	 %recycle-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red
do 
~~~start-file~~~ "recycle test"

===start-group=== "recyle blocks"
	
	--test-- "recycle-blocks-1"
		recycle				
		rb1-mem: stats
		rb1-b: make block! 1e10
		rb1-b: none
		recycle
		--assert stats = rb1-mem
	--test-- "recycle-blocks-2"
		recycle
		print stats
		rb2-b: copy []
		rb2-mem: stats
		rb2-b: [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
		loop 2000 [rb2-b: copy rb2-b]
		recycle
		--assert stats <= rb2-mem
		print stats
	--test-- "recycle-blocks-3"
		recycle
		print stats
		rb3-b: copy []
		rb3-mem: stats
		rb3-b: copy [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]
		loop 2000 [rb3-b: copy [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20]]
		recycle
		--assert stats <= rb3-mem
		print stats	
	--test-- "recycle-blocks-4"
		rb4-bb: copy [1 2 3 4 5 6 7 8 9 10]
		loop 12 [append rb4-bb rb4-bb]
		recycle
		print stats
		rb4-b: copy []
		rb4-mem: stats
		loop 2000 [
			rb4-b: copy rb4-bb
			recycle
		]
		--assert stats <= rb4-mem
		print stats
===end-group===

===end-group===
	
~~~end-file~~~