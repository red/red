Red [
	Title:   "Red to function test script"
	Author:  "Peter W A Wood"
	File: 	 %to-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2017, Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "to"

===start-group=== "to integer!"

	--test-- "to-integer!-1"
		--assert 1 == to integer! "1" 
		
	--test-- "to-integer!-2"
		--assert 1 == to integer! "1.0"
		
	--test-- "to-integer!-3"
		--assert 1 == to integer! #"^(01)" 
		
	--test-- "to-integer!-4"
		--assert 49 == to integer! #"1"		
 
	--test-- "to-integer!-5"
		--assert 128512 == to integer! #"😀"
		
	--test-- "to-integer!-6"
		--assert error? try [to integer! "😀"]	
		
	--test-- "to-integer!-7"
		--assert error? try [to integer! "a"]
		
	--test-- "to-integer!-8"
		--assert 1 == to integer! 1.00
		
	--test-- "to-integer!-9"
		--assert 1 == to integer! 1.999999999999999
		
	--test-- "to-integer!-10"
		--assert -1 == to integer! -1.9999999999
	
	--test-- "to-integer!-11"
		--assert 2147483647 == to integer! "2147483647"
		
	--test-- "to-integer!-12"
		--assert error? try [to integer! 2147483647.1]
	
	--test-- "to-integer!-13"
		--assert 2147483646 == to integer! 2147483646.999999
		
	--test-- "to-integer!-14"
		--assert 2147483647 == to integer! 2147483646.9999999
		
	--test-- "to-integer!-15"
		--assert -2147483648 == to integer! "-2147483648"
		
	--test-- "to-integer!-16"
		--assert error? try [to integer! -2147483648.1]
	
	--test-- "to-integer!-17"
		--assert -2147483647 == to integer! -2147483647.999999
		
	--test-- "to-integer!-18"
		--assert -2147483648 == to integer! -2147483647.9999999
		
	--test-- "to-integer!-19"
		--assert 2 == to integer! 1.9999999999999999
	
===end-group===

~~~end-file~~~
