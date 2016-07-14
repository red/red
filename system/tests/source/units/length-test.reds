Red/System [
	Title:   "Red/System length? test script"
	Author:  "Peter W A Wood"
	File: 	 %length-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "length?"

===start-group=== "Simple length? tests"

	--test-- "length?-1"
		--assert 1 = length? "1"
	
	--test-- "length?-2"
		l?2-s: "123"
		--assert 3 = length? l?2-s
	
	--test-- "length?-3"
		l?3-s: "1^(0A)3"
		--assert 3 = length? l?3-s
	
	--test-- "length?-4"
		--assert 3 = length? "1^(0A)3"
	
	--test-- "length?-5"
		l?5-s: "1234567890"
		l?5-s/6: null-byte
		--assert 5 = length? l?5-s
	
	--test-- "length?-6"
		l?6-s: "1234567890"
		l?6-s/6: null-byte
		l?6-s/6: #"6"
		--assert 10 = length? l?6-s

===end-group===

===start-group=== "Chaining function calls"

	--test-- "len-chain-1"
		lc1-func: func [
			s [c-string!]
			return: [c-string!]
		][
			s
		]
	--assert 5 = length? lc1-func "Peter"
  
	--test-- "len-chain-2"
		lc2-func: func [
			s [c-string!]
			return: [c-string!]
		][
			s
		]
		--assert 5 = length? lc1-func lc1-func "Nenad"

===end-group===

===start-group=== "Allocated strings"
	
	--test-- "len-alloc-1"
		la1-s1: make-c-string 128
		la1-s1/128: null-byte
		--assert 128 > length? la1-s1
  
	--test-- "len-alloc-2"
		la2-s1: make-c-string 128
		la2-s1/1: null-byte
		--assert 0 = length? la2-s1
  
	--test-- "len-alloc-3"
		la2-s1: make-c-string 128
		la2-s1: "Nenad"
		--assert 5 = length? la2-s1

~~~end-file~~~
