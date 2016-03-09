Red [
	Title:   "Red strict equal test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 strict-equal-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red
~~~start-file~~~ "strict-equal"
===start-group=== "same-datatype"
	--test-- "same-datatype-1"		--assert 0 == 0
	--test-- "same-datatype-2"		--assert 1 == 1
	--test-- "same-datatype-3"		--assert FFFFFFFFh == -1
	--test-- "same-datatype-4"		--assert [] == []
	--test-- "same-datatype-5"		--assert [a] == [a]
	--test-- "same-datatype-6"		--assert not [A] == [a]
	--test-- "same-datatype-7"		--assert not ['a] == [a]
	--test-- "same-datatype-8"		--assert not [a:] == [a]
	--test-- "same-datatype-9"		--assert not [:a] == [a]
	--test-- "same-datatype-10"		--assert not [:a] == [a:]
	--test-- "same-datatype-11"		--assert [abcde] == [abcde]
	--test-- "same-datatype-12"		--assert [a b c d] == [a b c d]
	--test-- "same-datatype-13"		--assert [b c d] == next [a b c d]
	--test-- "same-datatype-14"		--assert [b c d] == (next [a b c d])
	--test-- "same-datatype-15"		--assert "a" == "a"
	--test-- "same-datatype-16"		--assert not "a" == "A"
	--test-- "same-datatype-17"		--assert "abcdeè" == "abcdeè"
	--test-- "same-datatype-18"		--assert (next "abcdeè") == next "abcdeè"
	--test-- "same-datatype-19"		--assert (first "abcdeè") == first "abcdeè"
	--test-- "same-datatype-20"		--assert (last "abcdeè") == last "abcdeè"
	--test-- "same-datatype-21"
		--assert "abcde^(2710)é^(010000)" == "abcde^(2710)é^(010000)"
	--test-- "same-datatype-22"		--assert [d] == back tail [a b c d]
	--test-- "same-datatype-23"		--assert "2345" == next "12345"
	--test-- "same-datatype-24"		--assert #"z" == #"z"
	--test-- "same-datatype-25"		--assert not #"z" == #"Z"
	--test-- "same-datatype-26"		--assert not #"e" == #"è"
	--test-- "same-datatype-27"		--assert #"^(010000)" == #"^(010000)"
	--test-- "same-datatype-28"		--assert true == true
	--test-- "same-datatype-29"		--assert false == false
	--test-- "same-datatype-30"		--assert not false == true
	--test-- "same-datatype-31"		--assert not true == false
	--test-- "same-datatype-32"		--assert none == none
	--test-- "same-datatype-33"		--assert 'a == 'a
	--test-- "same-datatype-34"		--assert not 'a == 'A
	--test-- "same-datatype-34a"	--assert not 'test == 'Test
	--test-- "same-datatype-35"		--assert (first [a]) == first [a]
	--test-- "same-datatype-36"		--assert not 'a == first [A]
	--test-- "same-datatype-37"		--assert 'a == first [a]
	--test-- "same-datatype-38"		--assert not 'a == first [:a]
	--test-- "same-datatype-39"		--assert not 'a == first [a:]
	--test-- "same-datatype-40"		--assert (first [a:]) == first [a:]
	--test-- "same-datatype-41"		--assert (first [:a]) == first [:a]
	--test-- "same-datatype-42"		--assert [a b c d e] == first [[a b c d e]]
	--test-- "same-datatype-43"		
		ea-result: 1 == 1
		--assert ea-result = true
	--test-- "same-datatype-44"
		ea-result: 1 == 0
		--assert ea-result = false
===end-group===
===start-group=== "implcit-cast"
	--test-- "same-implcit-cast-1"	--assert not #"0" == 48
	--test-- "same-implcit-cast-2"	--assert not 48 == #"0"
	--test-- "same-implcit-cast-3"	--assert not #"^(2710)" == 10000
	--test-- "same-implcit-cast-4"	--assert not #"^(010000)" == 65536
	--test-- "same-implcit-cast-5"
		ea-result: #"1" == 49
		--assert ea-result = false
	--test-- "same-implcit-cast-6"
		ea-result: #"^(010000)" == 10000
		--assert ea-result = false
===end-group===
~~~end-file~~~
