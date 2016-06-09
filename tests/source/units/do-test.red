Red [
	Title:   "Red do test script"
	Author:  "Peter W A Wood"
	File: 	 %do-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "do"

===start-group=== "do function"
	
	--test-- "do-func-1"
		df1-f: func[][1]
		--assert 1 = do [df1-f] 
		
	--test-- "do-func-2"
		df2-f: func[i][2 * i]
		--assert 4 = do [df2-f 2]
		
	--test-- "do-func-3"
		df3-f: func[][3]
		--assert 3 = do df3-f
		
	--test-- "do-func-4"
		df4-i: 4
		df4-f: [func[i][df4-i * i] 4]
		--assert 16 = do reduce df4-f
		
	--test-- "do-func-5"
		df5-f: func[i][5 * i]
		--assert 25 = do [df5-f 5]
		
	--test-- "do-func-6"
		df6-i: 6
		df6-f: func[i][df6-i * i]
		--assert 36 = do [df6-f 6]
		
===end-group=== 

===start-group=== "do object"

	--test-- "do-object-1"
		do1-blk: load {
			o: make object! [
				oo: make object! [
					ooo: make object! [
						a: 1
					]
				]
			]
		}
		do do1-blk
		--assert 1 == o/oo/ooo/a

===end-group===

~~~end-file~~~
