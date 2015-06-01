Red [
	Title:   "Red same test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 same-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "same"

===start-group=== "same-datatype"
	--test-- "same-integer-1"		--assert same? 0 0
	--test-- "same-integer-2"		--assert same? first [1] first [1]
	--test-- "same-integer-3"		--assert same? FFFFFFFFh -1
	--test-- "same-integer-4"	 	--assert not same? 1 -1
	--test-- "same-float-1"			--assert same? 0.0 0.0
	--test-- "same-float-2"			--assert same? first [1.0] first [1.0]
	--test-- "same-float-3"			--assert not same? 1.0 -1.0
	--test-- "same=float-5"			--assert same? (2.0 / 3.0) (4.0 / 6.0)
	--test-- "same=float-6"			--assert same? (2.0 / 3) (4.0 / 6)
	--test-- "same=float-7"			--assert same? (2 / 3.0) (4 / 6.0)
	
	--test-- "same-float-5"
		sf5-a: 2.0
		sf5-b: 3.0
		sf5-c: 4.0
		sf5-d: 6.0
		--assert same? (sf5-a / sf5-b) (sf5-c / sf5-d)
		
	--test-- "same-char-1"			--assert same? #"a" #"a"
	--test-- "same-char-2"			--assert not same? #"a" #"b"
	--test-- "same-logic-1"			--assert same? true true
	--test-- "same-logic-2"			--assert not same? false true
	--test-- "same-block-1"			--assert not same? [] []
	--test-- "same-block-2"			--assert not same? [a] [a]
	
	--test-- "same-block-3"			
		x: y: [a]
		--assert same? x y
		
	--test-- "same-block-4"
		x: y: [a b c]
		--assert not same? x next y
		
	--test-- "same-block-5"
		x: y: [a]
		--assert not same? mold x mold y

	--test-- "same-string-1"		--assert not same? "" ""
	--test-- "same-string-2"		--assert not same? "abc" "abc"
	
	--test-- "same-string-3"
		s1: s2: "abc"
		--assert same? s1 s2
	
	--test-- "same-string-4"
		s1: s2: "abc"
		--assert not same? next s1 s2

	--test-- "same-file-1"			--assert not same? %abc %abc
	
	--test-- "same-file-2"
		s1: s2: %abc/de
		--assert not same? next s1 s2

	--test-- "same-datatype-1"		--assert not same? type? 1 type? #"1"
	--test-- "same-datatype-2"		--assert same? type? "abc" type? "cba"

	--test-- "same-word-1"			--assert same? 'a 'a
	--test-- "same-word-2"			--assert not same? 'a 'A
	--test-- "same-word-3"			--assert same? 'a first [a]
	--test-- "same-word-4"			--assert not same? 'a first ['a]
	--test-- "same-word-5"			--assert not same? first [:a] first [a:]
	--test-- "same-action-1"		--assert same? :swap :swap
	--test-- "same-action-2"		--assert not same? :swap :take
	--test-- "same-op-1"			--assert same? :+ :+
	--test-- "same-op-2"			--assert not same? :+ :-
	--test-- "same-native-1"		--assert same? :print :print
	--test-- "same-native-2"		--assert not same? :print :bind
	--test-- "same-function-1"		--assert same? :probe :probe
	--test-- "same-function-2"		--assert not same? :probe :quote
	--test-- "same-routine-1"		--assert same? :quit-return :quit-return
	--test-- "same-object-1"		--assert not same? make object! [a: 1] make object! [a: 1]
	
	--test-- "same-object-2"
		so2-o1: make object! [a: 1]
		so2-o2: make object! [a: 1]
		--assert not same? so2-o1 so2-o2
		
	--test-- "same-object-3"
		so3-o: make object! [a: 1]
		so3-o1: make so3-o []
		--assert not same? so3-o so3-o1		

===end-group===

===start-group=== "implcit-cast"
	--test-- "same-implcit-cast-1"	--assert not same? #"0" 48
	--test-- "same-implcit-cast-2"	--assert not same? 48 #"0"
	--test-- "same-implcit-cast-3"	--assert not same? #"^(2710)" 10000
	--test-- "same-implcit-cast-4"	--assert not same? #"^(010000)" 65536
	
	--test-- "same-implcit-cast-5"
		ea-result: same? #"1" 49
		--assert ea-result = false
	
	--test-- "same-implcit-cast-6"
		ea-result: same? #"^(010000)" 10000
		--assert ea-result = false
		
===end-group===

~~~end-file~~~
