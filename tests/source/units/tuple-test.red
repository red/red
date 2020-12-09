Red [
	Title:   "Red tuple! datatype test script"
	Author:  "Vladimir Vasilyev"
	File: 	 %tuple-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "tuple"

===start-group=== "reverse"
	--test-- "reverse-1"
		--assert 3.2.1 == reverse 1.2.3

	--test-- "reverse-2"
		tuple: 1.2.3
		reverse tuple
		--assert 1.2.3 == tuple						;-- not reversed in-place
	
	--test-- "reverse-3"
		tuple: reverse reverse 1.2.3.4.5.6.7.8.9.10.11.12
		--assert 1.2.3.4.5.6.7.8.9.10.11.12 == tuple
	
	--test-- "reverse-4"
		--assert 4.3.2.1 == reverse/part 1.2.3.4 4
		--assert 3.2.1.4 == reverse/part 1.2.3.4 3
		--assert 2.1.3.4 == reverse/part 1.2.3.4 2
		--assert 1.2.3.4 == reverse/part 1.2.3.4 1
		--assert 1.2.3.4 == reverse/part 1.2.3.4 0	;@@ should rather be forbidden?
	
	--test-- "reverse-5"
		--assert error? try [reverse/part 1.2.3 -1]
	
	--test-- "reverse-6"
		--assert error? try [reverse/skip/part 1.2.3.4.5.6 4 2]
		--assert error? try [reverse/skip/part 1.2.3.4.5.6 3 4]
	
	--test-- "reverse-7"
		--assert error? try [reverse/skip 1.2.3 0]
		--assert error? try [reverse/skip 1.2.3 -1]
		--assert error? try [reverse/skip 1.2.3 "4"]
	
	--test-- "reverse-8"
		--assert error? try [reverse/skip 1.2.3 4]
	
	--test-- "reverse-9"
		--assert 3.4.1.2.5.6 == reverse/skip/part 1.2.3.4.5.6 2 4
		--assert 2.1.3.4.5.6 == reverse/skip/part 1.2.3.4.5.6 1 2
	
	--test-- "reverse-10"
		--assert 4.5.6.1.2.3 == reverse/skip 1.2.3.4.5.6 3
		--assert 5.6.3.4.1.2 == reverse/skip 1.2.3.4.5.6 2
		--assert 6.5.4.3.2.1 == reverse/skip 1.2.3.4.5.6 1
	
	--test-- "reverse-11"
		--assert 5.6.3.4.1.2.7.8.9.10.11.12 == reverse/skip/part 1.2.3.4.5.6.7.8.9.10.11.12 2 6
		--assert 1.2.3.4.5.6.7.8.9.10.11.12 == reverse/skip/part 1.2.3.4.5.6.7.8.9.10.11.12 4 4
		--assert 7.8.9.10.11.12.1.2.3.4.5.6 == reverse/skip/part 1.2.3.4.5.6.7.8.9.10.11.12 6 12
		--assert 4.5.6.1.2.3.7.8.9.10.11.12 == reverse/skip/part 1.2.3.4.5.6.7.8.9.10.11.12 3 6
		--assert 3.2.1.4.5.6.7.8.9.10.11.12 == reverse/skip/part 1.2.3.4.5.6.7.8.9.10.11.12 1 3
	
===end-group===

~~~end-file~~~