Red [
	Title:		"Red lexer test"
	Author:		"Peter W A Wood"
	File:		%print-test.red
	Tabs:		4
	Rights:		"Copyright (C) 2014 Peter W A Wood. All rights reserved."
	License:	"BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../../quick-test/quick-test.red
#include %../../../lexer.red

~~~start-file~~~ "lexer"

===start-group=== "transcode with none"

	--test-- "trans1"
		--assert [Red[] 1] = transcode {Red[] 1} none
		
	--test-- "trans2"
		--assert [Red[] a: 1] = transcode {Red[] a: 1} none
		
===end-group===

===start-group=== "literal values"

	--test-- "litval-integer1" --assert [1] = transcode {1} none
	--test-- "litval-integer2" --assert [+1] = transcode {+1} none
	--test-- "litval-integer3" --assert [-1] = transcode {-1} none
	--test-- "litval-integer4" --assert [0] = transcode {0} none
	--test-- "litval-integer5" --assert [+0] = transcode {+0} none
	--test-- "litval-integer6" --assert [0] = transcode {-0} none
	--test-- "litval-integer7" --assert 0 = -0
	--test-- "litval-integer8" 
		--assert [2147483647] = transcode {2147483647} none
	--test-- "litval-integer9" 
		--assert [-2147483648] = transcode {-2147483648} none
	--test-- "litval-integer10" --assert [01h] = transcode {01h} none
	--test-- "litval-integer11" --assert [00h] = transcode {00h} none
	--test-- "litval-integer12" --assert [-1] = transcode {FFFFFFFFh} none
	--test-- "litval-integer13" 
		--assert [2147483647] = transcode {7FFFFFFFh} none
	--test-- "litval-integer14" 
		--assert [-2147483648] = transcode {80000000h} none
	

===end-group===

	;print: :store-print

~~~end-file~~~
