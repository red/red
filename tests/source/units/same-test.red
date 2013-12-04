Red [
	Title:   "Red same test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 same-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]
   
#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "same"

===start-group=== "same-datatype"
	--test-- "same-datatype-1"
		--assert same? 0 0
	--test-- "same-datatype-2"
		--assert not same? 1 1
	--test-- "same-datatype-3"
		--assert not same? FFFFFFFFh -1
	--test-- "same-datatype-4"
		--assert not same? [] []
	--test-- "same-datatype-5"
		--assert not same? [a] [a]
	--test-- "same-datatype-6"
		--assert not same? [A] [a]
	--test-- "same-datatype-7"
		--assert not same? ['a] [a]
	--test-- "same-datatype-8"
		--assert not same? [a:] [a]
	--test-- "same-datatype-9"
		--assert not same? [:a] [a]
	--test-- "same-datatype-10"
		--assert not same? [:a] [a:]
	--test-- "same-datatype-11"
		--assert not same? [abcde] [abcde]
	--test-- "same-datatype-12"
		--assert not same? [a b c d] [a b c d]
	--test-- "same-datatype-13"
		--assert not same? [b c d] next [a b c d]
	--test-- "same-datatype-14"
		--assert not same? [b c d] (next [a b c d])
	--test-- "same-datatype-15"
		--assert not same? "a" "a"
	--test-- "same-datatype-16"
		--assert not same? "a" "A"
	--test-- "same-datatype-17"
		--assert not same? "abcdeè" "abcdeè"
	--test-- "same-datatype-18"
		--assert not same? (next "abcdeè") next "abcdeè"
	--test-- "same-datatype-19"
		--assert not same? (first "abcdeè") first "abcdeè"
	--test-- "same-datatype-20"
		--assert not same? (last "abcdeè") last "abcdeè"
	--test-- "same-datatype-21"
		--assert not same? "abcde^(2710)é^(010000)" "abcde^(2710)é^(010000)"
	--test-- "same-datatype-22"
		--assert not same? [d] back tail [a b c d]
	--test-- "same-datatype-23"
		--assert not same? "2345" next "12345"
	--test-- "same-datatype-24"
		--assert not same? #"z" #"z"
	--test-- "same-datatype-25"
		--assert not same? #"z" #"Z"
	--test-- "same-datatype-26"
		--assert not same? #"e" #"è"
	--test-- "same-datatype-27"
		--assert same? #"^(010000)" #"^(010000)"
	--test-- "same-datatype-28"
		--assert same? true true
	--test-- "same-datatype-29"
		--assert same? false false
	--test-- "same-datatype-30"
		--assert not same? false true
	--test-- "same-datatype-31"
		--assert not same? true false
	--test-- "same-datatype-32"
		--assert not same? none none
	--test-- "same-datatype-33"
		--assert not same? 'a 'a
	--test-- "same-datatype-34"
		--assert not same? 'a 'A
	--test-- "same-datatype-35"
		--assert not same? (first [a]) first [a]
	--test-- "same-datatype-36"
		--assert not same? 'a first [A]
	--test-- "same-datatype-37"
		--assert not same? 'a first ['a]
	--test-- "same-datatype-38"
		--assert not same? 'a first [:a]
	--test-- "same-datatype-39"
		--assert not same? 'a first [a:]
	--test-- "same-datatype-40"
		--assert not same? (first [a:]) first [a:]
	--test-- "same-datatype-41"
		--assert not same? (first [:a]) first [:a]
	--test-- "same-datatype-42"
		--assert not same? [a b c d e] first [[a b c d e]]
	--test-- "same-datatype-43"
		ea-result: same? 1 1
		--assert ea-result = false
	--test-- "same-datatype-44"
		ea-result: same? 1 0
		--assert ea-result = false
	--test-- "same-datatype-45"
		a: b: 1
		--assert same? a b
	--test-- "same-dataytpe-46"
		a: b: "abcde"
		--assert same? a b
	--test-- "same-datatype-47"
		a: "abcde"
		b: "abcde"
		--assert not same? a b
	--test-- "same-datatype-48"
		a: "abcde"
		b: copy a
		--assert not same? a b
	
===end-group===
===start-group=== "implcit-cast"
	--test-- "same-implcit-cast-1"
		--assert not same? #"0" 48
	--test-- "same-implcit-cast-2"
		--assert not same? 48 #"0"
	--test-- "same-implcit-cast-3"
	 	--assert not same? #"^(2710)" 10000
	--test-- "same-implcit-cast-4"
		--assert not same? #"^(010000)" 65536
	--test-- "same-implcit-cast-5"
		ea-result: same? #"1" 49
		--assert ea-result = false
	--test-- "same-implcit-cast-6"
		ea-result: same? #"^(010000)" 10000
		--assert ea-result = false
===end-group===
~~~end-file~~~
