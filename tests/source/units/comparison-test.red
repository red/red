Red [
	Title:   "Red comparison tests"
	Author:  "Peter W A Wood"
	File: 	 %comparison-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2016 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "comparison tests"

===start-group=== "prefix equal same datatype"
	--test-- "prefix-equal-same-datatype-1"		--assert equal? 0 0
	--test-- "prefix-equal-same-datatype-2"		--assert equal? 1 1
	--test-- "prefix-equal-same-datatype-3"		--assert equal? FFFFFFFFh -1
	--test-- "prefix-equal-same-datatype-4"		--assert equal? [] []
	--test-- "prefix-equal-same-datatype-5"		--assert equal? [a] [a]
	--test-- "prefix-equal-same-datatype-6"		--assert equal? [A] [a]
	--test-- "prefix-equal-same-datatype-7"		--assert equal? ['a] [a]
	--test-- "prefix-equal-same-datatype-8"		--assert equal? [a:] [a]
	--test-- "prefix-equal-same-datatype-9"		--assert equal? [:a] [a]
	--test-- "prefix-equal-same-datatype-10"	--assert equal? [:a] [a:]
	--test-- "prefix-equal-same-datatype-11"	--assert equal? [abcde] [abcde]
	--test-- "prefix-equal-same-datatype-12"	--assert equal? [a b c d] [a b c d]
	--test-- "prefix-equal-same-datatype-13"	--assert equal? [b c d] next [a b c d]
	--test-- "prefix-equal-same-datatype-14"	--assert equal? [b c d] (next [a b c d])
	--test-- "prefix-equal-same-datatype-15"	--assert equal? "a" "a"
	--test-- "prefix-equal-same-datatype-16"	--assert equal? "a" "A"
	--test-- "prefix-equal-same-datatype-17"	--assert equal? "abcdeè" "abcdeè"
	--test-- "prefix-equal-same-datatype-18"	--assert equal? (next "abcdeè") next "abcdeè"
	--test-- "prefix-equal-same-datatype-19"	--assert equal? (first "abcdeè") first "abcdeè"
	--test-- "prefix-equal-same-datatype-20"	--assert equal? (last "abcdeè") last "abcdeè"
	--test-- "prefix-equal-same-datatype-21"
		--assert equal? "abcde^(2710)é^(010000)" "abcde^(2710)é^(010000)"
	--test-- "prefix-equal-same-datatype-22"	--assert equal? [d] back tail [a b c d]
	--test-- "prefix-equal-same-datatype-23"	--assert equal? "2345" next "12345"
	--test-- "prefix-equal-same-datatype-24"	--assert equal? #"z" #"z"
	--test-- "prefix-equal-same-datatype-25"	--assert not equal? #"z" #"Z"
	--test-- "prefix-equal-same-datatype-26"	--assert not equal? #"e" #"è"
	--test-- "prefix-equal-same-datatype-27"	--assert equal? #"^(010000)" #"^(010000)"
	--test-- "prefix-equal-same-datatype-28"	--assert equal? true true
	--test-- "prefix-equal-same-datatype-29"	--assert equal? false false
	--test-- "prefix-equal-same-datatype-30"	--assert not equal? false true
	--test-- "prefix-equal-same-datatype-31"	--assert not equal? true false
	--test-- "prefix-equal-same-datatype-32"	--assert equal? none none
	--test-- "prefix-equal-same-datatype-33"	--assert equal? 'a 'a
	--test-- "prefix-equal-same-datatype-34"	--assert equal? 'a 'A
	--test-- "prefix-equal-same-datatype-35"	--assert equal? (first [a]) first [a]
	--test-- "prefix-equal-same-datatype-36"	--assert equal? 'a first [A]
	--test-- "prefix-equal-same-datatype-37"	--assert equal? 'a first ['a]
	--test-- "prefix-equal-same-datatype-38"	--assert equal? 'a first [:a]
	--test-- "prefix-equal-same-datatype-39"	--assert equal? 'a first [a:]
	--test-- "prefix-equal-same-datatype-40"	--assert equal? (first [a:]) first [a:]
	--test-- "prefix-equal-same-datatype-41"	--assert equal? (first [:a]) first [:a]
	--test-- "prefix-equal-same-datatype-42"	--assert equal? [a b c d e] first [[a b c d e]]
	--test-- "prefix-equal-same-datatype-43"
		ea-result: 1 = 1
		--assert ea-result = true
	--test-- "prefix-equal-same-datatype-44"
		ea-result: 1 = 0
		--assert ea-result = false
	--test-- "prefix-equal-same-datatype-45"
		ea-result: equal? 1 1
		--assert ea-result = true
	--test-- "prefix-equal-same-datatype-46"
		ea-result: equal? 1 0
		--assert ea-result = false
===end-group===
	
===start-group=== "prefix equal implcit cast"
	--test-- "prefix-equal-implcit-cast-1"		--assert equal? #"0" 48
	--test-- "prefix-equal-implcit-cast-2"		--assert equal? 48 #"0"
	--test-- "prefix-equal-implcit-cast-3"		--assert equal? #"^(2710)" 10000
	--test-- "prefix-equal-implcit-cast-4"		--assert equal? #"^(010000)" 65536
	--test-- "prefix-equal-implcit-cast-5"	
		ea-result: #"1" = 49
		--assert ea-result = true
	--test-- "prefix-equal-implcit-cast-6"
		ea-result: equal? #"^(010000)" 10000
		--assert ea-result = false
===end-group===

===start-group=== "= same datatype"
	--test-- "infix-equal-same-datatype-1"		--assert 0 = 0
	--test-- "infix-equal-same-datatype-2"		--assert 1 = 1
	--test-- "infix-equal-same-datatype-3"		--assert FFFFFFFFh = -1
	--test-- "infix-equal-same-datatype-4"		--assert [] = []
	--test-- "infix-equal-same-datatype-5"		--assert [a] = [a]
	--test-- "infix-equal-same-datatype-6"		--assert [A] = [a]
	--test-- "infix-equal-same-datatype-7"		--assert ['a] = [a]
	--test-- "infix-equal-same-datatype-8"		--assert [a:] = [a]
	--test-- "infix-equal-same-datatype-9"		--assert [:a] = [a]
	--test-- "infix-equal-same-datatype-10"		--assert [:a] = [a:]
	--test-- "infix-equal-same-datatype-11"		--assert [abcde] = [abcde]
	--test-- "infix-equal-same-datatype-12"		--assert [a b c d] = [a b c d]
	--test-- "infix-equal-same-datatype-13"		--assert [b c d] = next [a b c d]
	--test-- "infix-equal-same-datatype-14"		--assert [b c d] = (next [a b c d])
	--test-- "infix-equal-same-datatype-15"		--assert "a" = "a"
	--test-- "infix-equal-same-datatype-16"		--assert "a" = "A"
	--test-- "infix-equal-same-datatype-17"		--assert "abcdeè" = "abcdeè"
	--test-- "infix-equal-same-datatype-18"		--assert (next "abcdeè") = next "abcdeè"
	--test-- "infix-equal-same-datatype-19"		--assert (first "abcdeè") = first "abcdeè"
	--test-- "infix-equal-same-datatype-20"		--assert (last "abcdeè") = last "abcdeè"
	--test-- "infix-equal-same-datatype-21"
		--assert "abcde^(2710)é^(010000)" = "abcde^(2710)é^(010000)"
	--test-- "infix-equal-same-datatype-22"		--assert [d] = back tail [a b c d]
	--test-- "infix-equal-same-datatype-23"		--assert "2345" = next "12345"
	--test-- "infix-equal-same-datatype-24"		--assert #"z" = #"z"
	--test-- "infix-equal-same-datatype-25"		--assert not #"z" = #"Z"
	--test-- "infix-equal-same-datatype-26"		--assert not #"e" = #"è"
	--test-- "infix-equal-same-datatype-27"		--assert #"^(010000)" = #"^(010000)"
	--test-- "infix-equal-same-datatype-28"		--assert true = true
	--test-- "infix-equal-same-datatype-29"		--assert false = false
	--test-- "infix-equal-same-datatype-30"		--assert not false = true
	--test-- "infix-equal-same-datatype-31"		--assert not true = false
	--test-- "infix-equal-same-datatype-32"		--assert none = none
	--test-- "infix-equal-same-datatype-33"		--assert 'a = 'a
	--test-- "infix-equal-same-datatype-34"		--assert 'a = 'A
	--test-- "infix-equal-same-datatype-35"		--assert (first [a]) = first [a]
	--test-- "infix-equal-same-datatype-36"		--assert 'a = first [A]
	--test-- "infix-equal-same-datatype-37"		--assert 'a = first ['a]
	--test-- "infix-equal-same-datatype-38"		--assert 'a = first [:a]
	--test-- "infix-equal-same-datatype-39"		--assert 'a = first [a:]
	--test-- "infix-equal-same-datatype-40"		--assert (first [a:]) = first [a:]
	--test-- "infix-equal-same-datatype-41"		--assert (first [:a]) = first [:a]
	--test-- "infix-equal-same-datatype-42"		--assert [a b c d e] = first [[a b c d e]]
	--test-- "infix-equal-same-datatype-43"
		ea-result: 1 = 1
		--assert ea-result = true
	--test-- "infix-equal-same-datatype-44"
		ea-result: 1 = 0
		--assert ea-result = false
	--test-- "infix-equal-same-datatype-45"
		ea-result: equal? 1 1
		--assert ea-result = true
	--test-- "infix-equal-same-datatype-46"
		ea-result: equal? 1 0
		--assert ea-result = false
===end-group===
	
===start-group=== "= implcit cast"
	--test-- "infix-equal-implcit-cast-1"		--assert #"0" = 48
	--test-- "infix-equal-implcit-cast-2"		--assert 48 = #"0"
	--test-- "infix-equal-implcit-cast-3"		--assert #"^(2710)" = 10000
	--test-- "infix-equal-implcit-cast-4"		--assert #"^(010000)" = 65536
	--test-- "infix-equal-implcit-cast-5"
		ea-result: #"1" = 49
		--assert ea-result = true
	--test-- "infix-equal-implcit-cast-6"
		ea-result: equal? #"^(010000)" 10000
		--assert ea-result = false
===end-group===

===start-group=== "prefix-greater-same-datatype"
	--test-- "prefix-greater-same-datatype-1"	--assert not greater? 0 0
	--test-- "prefix-greater-same-datatype-2"	--assert  greater? 1 0
	--test-- "prefix-greater-same-datatype-3"	--assert not greater? 1 1
	--test-- "prefix-greater-same-datatype-4"	--assert not greater? FFFFFFFFh -1
	--test-- "prefix-greater-same-datatype-5"	--assert  greater? -1 FFFFFFFEh
	--test-- "prefix-greater-same-datatype-6"	--assert not greater? -2 FFFFFFFFh
	--test-- "prefix-greater-same-datatype-7"	--assert not greater? "a" "a"
	--test-- "prefix-greater-same-datatype-8"	--assert  greater? "b" "a"
	--test-- "prefix-greater-same-datatype-9"	--assert  greater? "è" "f"
	--test-- "prefix-greater-same-datatype-10"	--assert not greater? "A" "a"
	--test-- "prefix-greater-same-datatype-11"	--assert not greater? "a" "A"
	--test-- "prefix-greater-same-datatype-12"	--assert not greater? "abcdeè" "abcdeè"
	--test-- "prefix-greater-same-datatype-13"	--assert not greater? (next "abcdeè") next "abcdeè"
	--test-- "prefix-greater-same-datatype-14"	--assert not greater? (first "abcdeè") first "abcdeè"
	--test-- "prefix-greater-same-datatype-15"	--assert not greater? (last "abcdeè") last "abcdeè"
	--test-- "prefix-greater-same-datatype-16"	--assert not greater? "abcde^(2710)é^(010000)" "abcde^(2710)é^(010000)"
	--test-- "prefix-greater-same-datatype-17"	--assert not greater? "2345" next "12345"
	--test-- "prefix-greater-same-datatype-18"	--assert not greater? #"z" #"z"
	--test-- "prefix-greater-same-datatype-19"	--assert  greater? #"z" #"Z"
	--test-- "prefix-greater-same-datatype-20"	--assert  greater? #"è" #"e"
	--test-- "prefix-greater-same-datatype-21"	--assert not greater? #"^(010000)" #"^(010000)"
===end-group===
	
===start-group=== "prefix-greater-implcit-cast"
	--test-- "prefix-greater-implcit-cast-1"	--assert not greater? #"0" 48
	--test-- "prefix-greater-implcit-cast-2"	--assert not greater? 48 #"0"
	--test-- "prefix-greater-implcit-cast-3"	--assert not greater? #"^(2710)" 10000
	--test-- "prefix-greater-implcit-cast-4"	--assert not greater? #"^(010000)" 65536
===end-group===
	
===start-group=== "prefix-greater-equal-same-datatype"
	--test-- "prefix-greater-equal-same-datatype-1"		--assert  greater-or-equal? 0 0
	--test-- "prefix-greater-equal-same-datatype-2"		--assert  greater-or-equal? 1 0
	--test-- "prefix-greater-equal-same-datatype-3"		--assert  greater-or-equal? 1 1
	--test-- "prefix-greater-equal-same-datatype-4"		--assert  greater-or-equal? FFFFFFFFh -1
	--test-- "prefix-greater-equal-same-datatype-5"		--assert  greater-or-equal? -1 FFFFFFFEh
	--test-- "prefix-greater-equal-same-datatype-6"		--assert not greater-or-equal? -2 FFFFFFFFh
	--test-- "prefix-greater-equal-same-datatype-7"		--assert  greater-or-equal? "a" "a"
	--test-- "prefix-greater-equal-same-datatype-8"		--assert  greater-or-equal? "b" "a"
	--test-- "prefix-greater-equal-same-datatype-9"		--assert  greater-or-equal? "è" "f"
	--test-- "prefix-greater-equal-same-datatype-10"	--assert  greater-or-equal? "A" "a"
	--test-- "prefix-greater-equal-same-datatype-11"	--assert  greater-or-equal? "a" "A"
	--test-- "prefix-greater-equal-same-datatype-12"	--assert  greater-or-equal? "abcdeè" "abcdeè"
	--test-- "prefix-greater-equal-same-datatype-13"	--assert  greater-or-equal? (next "abcdeè") next "abcdeè"
	--test-- "prefix-greater-equal-same-datatype-14"	--assert  greater-or-equal? (first "abcdeè") first "abcdeè"
	--test-- "prefix-greater-equal-same-datatype-15"	--assert  greater-or-equal? (last "abcdeè") last "abcdeè"
	--test-- "prefix-greater-equal-same-datatype-16"	--assert  greater-or-equal? "abcde^(2710)é^(010000)" "abcde^(2710)é^(010000)"
	--test-- "prefix-greater-equal-same-datatype-17"	--assert  greater-or-equal? "2345" next "12345"
	--test-- "prefix-greater-equal-same-datatype-18"	--assert  greater-or-equal? #"z" #"z"
	--test-- "prefix-greater-equal-same-datatype-19"	--assert  greater-or-equal? #"z" #"Z"
	--test-- "prefix-greater-equal-same-datatype-20"	--assert  greater-or-equal? #"è" #"e"
	--test-- "prefix-greater-equal-same-datatype-21"	--assert  greater-or-equal? #"^(010000)" #"^(010000)"
===end-group===
	
===start-group=== "prefix-greater-implcit-cast"
	--test-- "prefix-greater-equal-implcit-cast-1"	--assert  greater-or-equal? #"0" 48
	--test-- "prefix-greater-equal-implcit-cast-2"	--assert  greater-or-equal? 48 #"0"
	--test-- "prefix-greater-equal-implcit-cast-3"	--assert  greater-or-equal? #"^(2710)" 10000
	--test-- "prefix-greater-equal-implcit-cast-4"	--assert  greater-or-equal? #"^(010000)" 65536
===end-group===
	
===start-group=== "infix-greater-same-datatype"
	--test-- "infix-greater-same-datatype-1"	--assert not 0 > 0
	--test-- "infix-greater-same-datatype-2"	--assert 1 > 0
	--test-- "infix-greater-same-datatype-3"	--assert not 1 > 1
	--test-- "infix-greater-same-datatype-4"	--assert not FFFFFFFFh > -1
	--test-- "infix-greater-same-datatype-5"	--assert -1 > FFFFFFFEh
	--test-- "infix-greater-same-datatype-6"	--assert not -2 > FFFFFFFFh
	--test-- "infix-greater-same-datatype-7"	--assert not "a" > "a"
	--test-- "infix-greater-same-datatype-8"	--assert "b" > "a"
	--test-- "infix-greater-same-datatype-9"	--assert "è" > "f"
	--test-- "infix-greater-same-datatype-10"	--assert not "A" > "a"
	--test-- "infix-greater-same-datatype-11"	--assert not "a" > "A"
	--test-- "infix-greater-same-datatype-12"	--assert not "abcdeè" > "abcdeè"
	--test-- "infix-greater-same-datatype-13"	--assert not (next "abcdeè") > next "abcdeè"
	--test-- "infix-greater-same-datatype-14"	--assert not (first "abcdeè") > first "abcdeè"
	--test-- "infix-greater-same-datatype-15"	--assert not (last "abcdeè") > last "abcdeè"
	--test-- "infix-greater-same-datatype-16"	--assert not "abcde^(2710)é^(010000)" > "abcde^(2710)é^(010000)"
	--test-- "infix-greater-same-datatype-17"	--assert not "2345" > next "12345"
	--test-- "infix-greater-same-datatype-18"	--assert not #"z" > #"z"
	--test-- "infix-greater-same-datatype-19"	--assert #"z" > #"Z"
	--test-- "infix-greater-same-datatype-20"	--assert #"è" > #"e"
	--test-- "infix-greater-same-datatype-21"	--assert not #"^(010000)" > #"^(010000)"
===end-group===
	
===start-group=== "infix-greater-implcit-cast"
	--test-- "infix-greater-implcit-cast-1"		--assert not #"0" > 48
	--test-- "infix-greater-implcit-cast-2"		--assert not 48 > #"0"
	--test-- "infix-greater-implcit-cast-3"		--assert not #"^(2710)" > 10000
	--test-- "infix-greater-implcit-cast-4"		--assert not #"^(010000)" > 65536
===end-group===
	
===start-group=== "infix-greater-equal-same-datatype"
	--test-- "infix-greater-equal-same-datatype-1"	--assert 0 >= 0
	--test-- "infix-greater-equal-same-datatype-2"	--assert 1 >= 0
	--test-- "infix-greater-equal-same-datatype-3"	--assert 1 >= 1
	--test-- "infix-greater-equal-same-datatype-4"	--assert FFFFFFFFh >= -1
	--test-- "infix-greater-equal-same-datatype-5"	--assert -1 >= FFFFFFFEh
	--test-- "infix-greater-equal-same-datatype-6"	--assert not -2 >= FFFFFFFFh
	--test-- "infix-greater-equal-same-datatype-7"	--assert "a" >= "a"
	--test-- "infix-greater-equal-same-datatype-8"	--assert "b" >= "a"
	--test-- "infix-greater-equal-same-datatype-9"	--assert "è" >= "f"
	--test-- "infix-greater-equal-same-datatype-10"	--assert "A" >= "a"
	--test-- "infix-greater-equal-same-datatype-11"	--assert "a" >= "A"
	--test-- "infix-greater-equal-same-datatype-12"	--assert "abcdeè" >= "abcdeè"
	--test-- "infix-greater-equal-same-datatype-13"	--assert (next "abcdeè") >= next "abcdeè"
	--test-- "infix-greater-equal-same-datatype-14"	--assert (first "abcdeè") >= first "abcdeè"
	--test-- "infix-greater-equal-same-datatype-15"	--assert (last "abcdeè") >= last "abcdeè"
	--test-- "infix-greater-equal-same-datatype-16"	--assert "abcde^(2710)é^(010000)" >= "abcde^(2710)é^(010000)"
	--test-- "infix-greater-equal-same-datatype-17"	--assert "2345" >= next "12345"
	--test-- "infix-greater-equal-same-datatype-18"	--assert #"z" >= #"z"
	--test-- "infix-greater-equal-same-datatype-19"	--assert #"z" >= #"Z"
	--test-- "infix-greater-equal-same-datatype-20"	--assert #"è" >= #"e"
	--test-- "infix-greater-equal-same-datatype-21"	--assert #"^(010000)" >= #"^(010000)"
===end-group===
	
===start-group=== "infix-greater-equal-implcit-cast"
	--test-- "infix-greater-equal-implcit-cast-1"	--assert #"0" >= 48
	--test-- "infix-greater-equal-implcit-cast-2"	--assert 48 >= #"0"
	--test-- "infix-greater-equal-implcit-cast-3"	--assert #"^(2710)" >= 10000
	--test-- "infix-greater-equal-implcit-cast-4"	--assert #"^(010000)" >= 65536
===end-group===
	
===start-group=== "infix-lesser-same-datatype"
	--test-- "infix-lesser-same-datatype-1"		--assert not 0 < 0
	--test-- "infix-lesser-same-datatype-2"		--assert 0 < 1
	--test-- "infix-lesser-same-datatype-3"		--assert not 1 < 1
	--test-- "infix-lesser-same-datatype-4"		--assert not FFFFFFFFh < -1
	--test-- "infix-lesser-same-datatype-5"		--assert FFFFFFFEh < -1
	--test-- "infix-lesser-same-datatype-6"		--assert not FFFFFFFFh < -2
	--test-- "infix-lesser-same-datatype-7"		--assert not "a" < "a"
	--test-- "infix-lesser-same-datatype-8"		--assert "a" < "b"
	--test-- "infix-lesser-same-datatype-9"		--assert "f" < "è"
	--test-- "infix-lesser-same-datatype-10"	--assert not "A" < "a"
	--test-- "infix-lesser-same-datatype-11"	--assert not "a" < "A"
	--test-- "infix-lesser-same-datatype-12"	--assert not "abcdeè" < "abcdeè"
	--test-- "infix-lesser-same-datatype-13"	--assert not (next "abcdeè") < next "abcdeè"
	--test-- "infix-lesser-same-datatype-14"	--assert not (first "abcdeè") < first "abcdeè"
	--test-- "infix-lesser-same-datatype-15"	--assert not (last "abcdeè") < last "abcdeè"
	--test-- "infix-lesser-same-datatype-16"	--assert not "abcde^(2710)é^(010000)" < "abcde^(2710)é^(010000)"
	--test-- "infix-lesser-same-datatype-17"	--assert not "2345" < next "12345"
	--test-- "infix-lesser-same-datatype-18"	--assert not #"z" < #"z"
	--test-- "infix-lesser-same-datatype-19"	--assert #"Z" < #"z"
	--test-- "infix-lesser-same-datatype-20"	--assert #"e" < #"è"
	--test-- "infix-lesser-same-datatype-21"	--assert not #"^(010000)" < #"^(010000)"
===end-group===
	
===start-group=== "infix-lesser-implcit-cast"
	--test-- "infix-lesser-implcit-cast-1"		--assert not #"0" < 48
	--test-- "infix-lesser-implcit-cast-2"		--assert not 48 < #"0"
	--test-- "infix-lesser-implcit-cast-3"		--assert not #"^(2710)" < 10000
	--test-- "infix-lesser-implcit-cast-4"		--assert not #"^(010000)" < 65536
===end-group===
	
===start-group=== "infix-lesser-equal-same-datatype"
	--test-- "infix-lesser-equal-same-datatype-1"	--assert 0 <= 0
	--test-- "infix-lesser-equal-same-datatype-2"	--assert 0 <= 1
	--test-- "infix-lesser-equal-same-datatype-3"	--assert 1 <= 1
	--test-- "infix-lesser-equal-same-datatype-4"	--assert FFFFFFFFh <= -1
	--test-- "infix-lesser-equal-same-datatype-5"	--assert FFFFFFFEh <= -1
	--test-- "infix-lesser-equal-same-datatype-6"	--assert not FFFFFFFFh <= -2
	--test-- "infix-lesser-equal-same-datatype-7"	--assert "a" <= "a"
	--test-- "infix-lesser-equal-same-datatype-8"	--assert "a" <= "b"
	--test-- "infix-lesser-equal-same-datatype-9"	--assert "f" <= "è"
	--test-- "infix-lesser-equal-same-datatype-10"	--assert "A" <= "a"
	--test-- "infix-lesser-equal-same-datatype-11"	--assert "a" <= "A"
	--test-- "infix-lesser-equal-same-datatype-12"	--assert "abcdeè" <= "abcdeè"
	--test-- "infix-lesser-equal-same-datatype-13"	--assert (next "abcdeè") <= next "abcdeè"
	--test-- "infix-lesser-equal-same-datatype-14"	--assert (first "abcdeè") <= first "abcdeè"
	--test-- "infix-lesser-equal-same-datatype-15"	--assert (last "abcdeè") <= last "abcdeè"
	--test-- "infix-lesser-equal-same-datatype-16"	--assert "abcde^(2710)é^(010000)" <= "abcde^(2710)é^(010000)"
	--test-- "infix-lesser-equal-same-datatype-17"	--assert "2345" <= next "12345"
	--test-- "infix-lesser-equal-same-datatype-18"	--assert #"z" <= #"z"
	--test-- "infix-lesser-equal-same-datatype-19"	--assert #"Z" <= #"z"
	--test-- "infix-lesser-equal-same-datatype-20"	--assert #"e" <= #"è"
	--test-- "infix-lesser-equal-same-datatype-21"	--assert #"^(010000)" <= #"^(010000)"	
===end-group===
	
===start-group=== "infix-lesser-equal-implcit-cast"
	--test-- "infix-lesser-equal-implcit-cast-1"	--assert #"0" <= 48
	--test-- "infix-lesser-equal-implcit-cast-2"	--assert 48 <= #"0"
	--test-- "infix-lesser-equal-implcit-cast-3"	--assert #"^(2710)" <= 10000
	--test-- "infix-lesser-equal-implcit-cast-4"	--assert #"^(010000)" <= 65536
===end-group===
	
===start-group=== "prefix-lesser-same-datatype"
	--test-- "prefix-lesser-same-datatype-1"	--assert not lesser? 0 0
	--test-- "prefix-lesser-same-datatype-2"	--assert  lesser? 0 1
	--test-- "prefix-lesser-same-datatype-3"	--assert not lesser? 1 1
	--test-- "prefix-lesser-same-datatype-4"	--assert not lesser? FFFFFFFFh -1
	--test-- "prefix-lesser-same-datatype-5"	--assert  lesser? FFFFFFFEh -1
	--test-- "prefix-lesser-same-datatype-6"	--assert not lesser? FFFFFFFFh -2
	--test-- "prefix-lesser-same-datatype-7"	--assert not lesser? "a" "a"
	--test-- "prefix-lesser-same-datatype-8"	--assert  lesser? "a" "b"
	--test-- "prefix-lesser-same-datatype-9"	--assert  lesser? "f" "è"
	--test-- "prefix-lesser-same-datatype-10"	--assert not lesser? "A" "a"
	--test-- "prefix-lesser-same-datatype-11"	--assert not lesser? "a" "A"
	--test-- "prefix-lesser-same-datatype-12"	--assert not lesser? "abcdeè" "abcdeè"
	--test-- "prefix-lesser-same-datatype-13"	--assert not lesser? (next "abcdeè") next "abcdeè"
	--test-- "prefix-lesser-same-datatype-14"	--assert not lesser? (first "abcdeè") first "abcdeè"
	--test-- "prefix-lesser-same-datatype-15"	--assert not lesser? (last "abcdeè") last "abcdeè"
	--test-- "prefix-lesser-same-datatype-16"	--assert not lesser? "abcde^(2710)é^(010000)" "abcde^(2710)é^(010000)"
	--test-- "prefix-lesser-same-datatype-17"	--assert not lesser? "2345" next "12345"
	--test-- "prefix-lesser-same-datatype-18"	--assert not lesser? #"z" #"z"
	--test-- "prefix-lesser-same-datatype-19"	--assert  lesser? #"Z" #"z"
	--test-- "prefix-lesser-same-datatype-20"	--assert  lesser? #"e" #"è"
	--test-- "prefix-lesser-same-datatype-21"	--assert not lesser? #"^(010000)" #"^(010000)"
===end-group===
	
===start-group=== "prefix-lesser-implcit-cast"
	--test-- "prefix-lesser-implcit-cast-1"		--assert not lesser? #"0" 48
	--test-- "prefix-lesser-implcit-cast-2"		--assert not lesser? 48 #"0"
	--test-- "prefix-lesser-implcit-cast-3"		--assert not lesser? #"^(2710)" 10000
	--test-- "prefix-lesser-implcit-cast-4"		--assert not lesser? #"^(010000)" 65536
===end-group===
	
===start-group=== "prefix-lesser-same-datatype"
	--test-- "prefix-lesser-equal-same-datatype-1"	--assert  lesser-or-equal? 0 0
	--test-- "prefix-lesser-equal-same-datatype-2"	--assert  lesser-or-equal? 0 1
	--test-- "prefix-lesser-equal-same-datatype-3"	--assert  lesser-or-equal? 1 1
	--test-- "prefix-lesser-equal-same-datatype-4"	--assert  lesser-or-equal? FFFFFFFFh -1
	--test-- "prefix-lesser-equal-same-datatype-5"	--assert  lesser-or-equal? FFFFFFFEh -1
	--test-- "prefix-lesser-equal-same-datatype-6"	--assert not lesser-or-equal? FFFFFFFFh -2
	--test-- "prefix-lesser-equal-same-datatype-7"	--assert  lesser-or-equal? "a" "a"
	--test-- "prefix-lesser-equal-same-datatype-8"	--assert  lesser-or-equal? "a" "b"
	--test-- "prefix-lesser-equal-same-datatype-9"	--assert  lesser-or-equal? "f" "è"
	--test-- "prefix-lesser-equal-same-datatype-10"	--assert  lesser-or-equal? "A" "a"
	--test-- "prefix-lesser-equal-same-datatype-11"	--assert  lesser-or-equal? "a" "A"
	--test-- "prefix-lesser-equal-same-datatype-12"	--assert  lesser-or-equal? "abcdeè" "abcdeè"
	--test-- "prefix-lesser-equal-same-datatype-13"	--assert  lesser-or-equal? (next "abcdeè") next "abcdeè"
	--test-- "prefix-lesser-equal-same-datatype-14"	--assert  lesser-or-equal? (first "abcdeè") first "abcdeè"
	--test-- "prefix-lesser-equal-same-datatype-15"	--assert  lesser-or-equal? (last "abcdeè") last "abcdeè"
	--test-- "prefix-lesser-equal-same-datatype-16"	--assert  lesser-or-equal? "abcde^(2710)é^(010000)" "abcde^(2710)é^(010000)"
	--test-- "prefix-lesser-equal-same-datatype-17"	--assert  lesser-or-equal? "2345" next "12345"
	--test-- "prefix-lesser-equal-same-datatype-18"	--assert  lesser-or-equal? #"z" #"z"
	--test-- "prefix-lesser-equal-same-datatype-19"	--assert  lesser-or-equal? #"Z" #"z"
	--test-- "prefix-lesser-equal-same-datatype-20"	--assert  lesser-or-equal? #"e" #"è"
	--test-- "prefix-lesser-equal-same-datatype-21"	--assert  lesser-or-equal? #"^(010000)" #"^(010000)"
===end-group===
		
===start-group=== "prefix-lesser-implcit-cast"
	--test-- "prefix-lesser-equal-implcit-cast-1"	--assert  lesser-or-equal? #"0" 48
	--test-- "prefix-lesser-equal-implcit-cast-2"	--assert  lesser-or-equal? 48 #"0"
	--test-- "prefix-lesser-equal-implcit-cast-3"	--assert  lesser-or-equal? #"^(2710)" 10000
	--test-- "prefix-lesser-equal-implcit-cast-4"	--assert  lesser-or-equal? #"^(010000)" 65536
===end-group===
	
===start-group=== "prefix-not-equal-same-datatype"
	--test-- "prefix-not-equal-same-datatype-1"		--assert not-equal? 0 1
	--test-- "prefix-not-equal-same-datatype-2"		--assert not-equal? 1 0
	--test-- "prefix-not-equal-same-datatype-3"		--assert not-equal? FFFFFFFEh -1
	--test-- "prefix-not-equal-same-datatype-4"		--assert not-equal? [] [[]]
	--test-- "prefix-not-equal-same-datatype-5"		--assert not-equal? [a] [b]
	--test-- "prefix-not-equal-same-datatype-6"		--assert not-equal? [A] [b]
	--test-- "prefix-not-equal-same-datatype-7"		--assert not-equal? ['a] ['b]
	--test-- "prefix-not-equal-same-datatype-8"		--assert not-equal? [a:] [b:]
	--test-- "prefix-not-equal-same-datatype-9"		--assert not-equal? [:a] [b:]
	--test-- "prefix-not-equal-same-datatype-10"	--assert not-equal? [abcde] [abcdef]
	--test-- "prefix-not-equal-same-datatype-11"	--assert not-equal? [a b c d] [a c d]
	--test-- "prefix-not-equal-same-datatype-12"	--assert not-equal? [b c d] next [a b c d e]
	--test-- "prefix-not-equal-same-datatype-13"	--assert not-equal? [b c d] (next [a b c d e])
	--test-- "prefix-not-equal-same-datatype-14"	--assert not-equal? "a" "b"
	--test-- "prefix-not-equal-same-datatype-15"	--assert not-equal? "a" "B"
	--test-- "prefix-not-equal-same-datatype-16"	--assert not-equal? "abcdeè" "abcdeèf"
	--test-- "prefix-not-equal-same-datatype-17"	--assert not-equal? (next "abcdeè") next "abcdeèf"
	--test-- "prefix-not-equal-same-datatype-18"	--assert not-equal? (first "abcdeè") first "bcdeè"
	--test-- "prefix-not-equal-same-datatype-19"	--assert not-equal? (last "abcdeè") last "abcdeèf"
	--test-- "prefix-not-equal-same-datatype-20"	--assert not-equal? "abcde^(2710)é^(010000)" "abcde^(2711)é^(010000)"
	--test-- "prefix-not-equal-same-datatype-21"	--assert not-equal? [d] back tail [a b c d e]
	--test-- "prefix-not-equal-same-datatype-22"	--assert not-equal? "2345" next "123456"
	--test-- "prefix-not-equal-same-datatype-23"	--assert not-equal? #"z" #"Z"
	--test-- "prefix-not-equal-same-datatype-24"	--assert not not-equal? #"z" #"z"
	--test-- "prefix-not-equal-same-datatype-25"	--assert not not-equal? #"e" #"e"
	--test-- "prefix-not-equal-same-datatype-26"	--assert not-equal? #"^(010000)" #"^(010001)"
	--test-- "prefix-not-equal-same-datatype-27"	--assert not-equal? true false
	--test-- "prefix-not-equal-same-datatype-28"	--assert not-equal? false true
	--test-- "prefix-not-equal-same-datatype-29"	--assert not not-equal? false false
	--test-- "prefix-not-equal-same-datatype-30"	--assert not not-equal? true true
	--test-- "prefix-not-equal-same-datatype-31"	--assert not-equal? none "a"
	--test-- "prefix-not-equal-same-datatype-32"	--assert not-equal? 'a 'b
	--test-- "prefix-not-equal-same-datatype-33"	--assert not-equal? 'a 'B
	--test-- "prefix-not-equal-same-datatype-34"	--assert not-equal? (first [a]) first [b]
	--test-- "prefix-not-equal-same-datatype-35"	--assert not-equal? 'a first [B]
	--test-- "prefix-not-equal-same-datatype-36"	--assert not-equal? 'a first ['b]
	--test-- "prefix-not-equal-same-datatype-37"	--assert not-equal? 'a first [:b]
	--test-- "prefix-not-equal-same-datatype-38"	--assert not-equal? 'a first [b:]
	--test-- "prefix-not-equal-same-datatype-39"	--assert not-equal? (first [a:]) first [z:]
	--test-- "prefix-not-equal-same-datatype-40"	--assert not-equal? (first [:a]) first [:z]
	--test-- "prefix-not-equal-same-datatype-41"	--assert not-equal? [a b c d e] first [[b c d e]]
	--test-- "prefix-not-equal-same-datatype-42"
		ea-result: 1 <> 1
		--assert ea-result = false
	--test-- "prefix-not-equal-same-datatype-43"
		ea-result: 1 <> 0
		--assert ea-result = true
	--test-- "prefix-not-equal-same-datatype-44"
		ea-result: not-equal? 1 1
		--assert ea-result = false
	--test-- "prefix-not-equal-same-datatype-45"
		ea-result: not-equal? 1 0
		--assert ea-result = true
===end-group===
	
===start-group=== "prefix-not-equal-implcit-cast"
	--test-- "prefix-not-equal-implcit-cast-1"		--assert not-equal? #"0" 49
	--test-- "prefix-not-equal-implcit-cast-2"		--assert not-equal? 48 #"1"
	--test-- "prefix-not-equal-implcit-cast-3"		--assert not-equal? #"^(2711)" 10000
	--test-- "prefix-not-equal-implcit-cast-4"		--assert not-equal? #"^(010001)" 65536
	--test-- "prefix-not-equal-implcit-cast-5"
		ea-result: #"1" <> 49
		--assert ea-result = false
	--test-- "prefix-not-equal-implcit-cast-6"
		ea-result: not-equal? #"^(01000)" 10000
		--assert ea-result = true
===end-group===

===start-group=== "infix-not-equal-same-datatype"
	--test-- "infix-not-equal-same-datatype-1"		--assert 0 <> 1
	--test-- "infix-not-equal-same-datatype-2"		--assert 1 <> 0
	--test-- "infix-not-equal-same-datatype-3"		--assert FFFFFFFEh <> -1
	--test-- "infix-not-equal-same-datatype-4"		--assert [] <> [[]]
	--test-- "infix-not-equal-same-datatype-5"		--assert [a] <> [b]
	--test-- "infix-not-equal-same-datatype-6"		--assert [A] <> [b]
	--test-- "infix-not-equal-same-datatype-7"		--assert ['a] <> ['b]
	--test-- "infix-not-equal-same-datatype-8"		--assert [a:] <> [b:]
	--test-- "infix-not-equal-same-datatype-9"		--assert [:a] <> [b:]
	--test-- "infix-not-equal-same-datatype-10"		--assert [abcde] <> [abcdef]
	--test-- "infix-not-equal-same-datatype-11"		--assert [a b c d] <> [a c d]
	--test-- "infix-not-equal-same-datatype-12"		--assert [b c d] <> next [a b c d e]
	--test-- "infix-not-equal-same-datatype-13"		--assert [b c d] <> (next [a b c d e])
	--test-- "infix-not-equal-same-datatype-14"		--assert "a" <> "b"
	--test-- "infix-not-equal-same-datatype-15"		--assert "a" <> "B"
	--test-- "infix-not-equal-same-datatype-16"		--assert "abcdeè" <> "abcdeèf"
	--test-- "infix-not-equal-same-datatype-17"		--assert (next "abcdeè") <> next "abcdeèf"
	--test-- "infix-not-equal-same-datatype-18"		--assert (first "abcdeè") <> first "bcdeè"
	--test-- "infix-not-equal-same-datatype-19"		--assert (last "abcdeè") <> last "abcdeèf"
	--test-- "infix-not-equal-same-datatype-20"		--assert "abcde^(2710)é^(010000)" <> "abcde^(2711)é^(010000)"
	--test-- "infix-not-equal-same-datatype-21"		--assert [d] <> back tail [a b c d e]
	--test-- "infix-not-equal-same-datatype-22"		--assert "2345" <> next "123456"
	--test-- "infix-not-equal-same-datatype-23"		--assert #"z" <> #"Z"
	--test-- "infix-not-equal-same-datatype-24"		--assert not #"z" <> #"z"
	--test-- "infix-not-equal-same-datatype-25"		--assert not #"e" <> #"e"
	--test-- "infix-not-equal-same-datatype-26"		--assert #"^(010000)" <> #"^(010001)"
	--test-- "infix-not-equal-same-datatype-27"		--assert true <> false
	--test-- "infix-not-equal-same-datatype-28"		--assert false <> true
	--test-- "infix-not-equal-same-datatype-29"		--assert not false <> false
	--test-- "infix-not-equal-same-datatype-30"		--assert not true <> true
	--test-- "infix-not-equal-same-datatype-31"		--assert none <> "a"
	--test-- "infix-not-equal-same-datatype-32"		--assert 'a <> 'b
	--test-- "infix-not-equal-same-datatype-33"		--assert 'a <> 'B
	--test-- "infix-not-equal-same-datatype-34"		--assert (first [a]) <> first [b]
	--test-- "infix-not-equal-same-datatype-35"		--assert 'a <> first [B]
	--test-- "infix-not-equal-same-datatype-36"		--assert 'a <> first ['b]
	--test-- "infix-not-equal-same-datatype-37"		--assert 'a <> first [:b]
	--test-- "infix-not-equal-same-datatype-38"		--assert 'a <> first [b:]
	--test-- "infix-not-equal-same-datatype-39"		--assert (first [a:]) <> first [z:]
	--test-- "infix-not-equal-same-datatype-40"		--assert (first [:a]) <> first [:z]
	--test-- "infix-not-equal-same-datatype-41"		--assert [a b c d e] <> first [[b c d e]]
	--test-- "infix-not-equal-same-datatype-42"
		ea-result: 1 <> 1
		--assert ea-result = false
	--test-- "infix-not-equal-same-datatype-43"
		ea-result: 1 <> 0
		--assert ea-result = true
	--test-- "infix-not-equal-same-datatype-44"
		ea-result: not-equal? 1 1
		--assert ea-result = false
	--test-- "infix-not-equal-same-datatype-45"
		ea-result: not-equal? 1 0
		--assert ea-result = true
===end-group===

===start-group=== "infix-not-equal-implcit-cast"
	--test-- "infix-not-equal-implcit-cast-1"	--assert #"0" <> 49
	--test-- "infix-not-equal-implcit-cast-2"	--assert 48 <> #"1"
	--test-- "infix-not-equal-implcit-cast-3"	--assert #"^(2711)" <> 10000
	--test-- "infix-not-equal-implcit-cast-4"	--assert #"^(010001)" <> 65536
	--test-- "infix-not-equal-implcit-cast-5"
		ea-result: #"1" <> 49
		--assert ea-result = false
	--test-- "infix-not-equal-implcit-cast-6"
		ea-result: not-equal? #"^(01000)" 10000
		--assert ea-result = true
===end-group===

===start-group=== "same-datatype"
	--test-- "same-datatype-1"	--assert same? 0 0
	--test-- "same-datatype-2"	--assert same? 1 1
	--test-- "same-datatype-3"	--assert same? FFFFFFFFh -1
	--test-- "same-datatype-4"	--assert not same? [] []
	--test-- "same-datatype-5"	--assert not same? [a] [a]
	--test-- "same-datatype-6"	--assert not same? [A] [a]
	--test-- "same-datatype-7"	--assert not same? ['a] [a]
	--test-- "same-datatype-8"	--assert not same? [a:] [a]
	--test-- "same-datatype-9"	--assert not same? [:a] [a]
	--test-- "same-datatype-10"	--assert not same? [:a] [a:]
	--test-- "same-datatype-11"	--assert not same? [abcde] [abcde]
	--test-- "same-datatype-12"	--assert not same? [a b c d] [a b c d]
	--test-- "same-datatype-13"	--assert not same? [b c d] next [a b c d]
	--test-- "same-datatype-14"	--assert not same? [b c d] (next [a b c d])
	--test-- "same-datatype-15"	--assert not same? "a" "a"
	--test-- "same-datatype-16"	--assert not same? "a" "A"
	--test-- "same-datatype-17"	--assert not same? "abcdeè" "abcdeè"
	--test-- "same-datatype-18"	--assert not same? (next "abcdeè") next "abcdeè"
	--test-- "same-datatype-19"	--assert same? (first "abcdeè") first "abcdeè"
	--test-- "same-datatype-20"	--assert same? (last "abcdeè") last "abcdeè"
	--test-- "same-datatype-21"	--assert not same? "abcde^(2710)é^(010000)" "abcde^(2710)é^(010000)"
	--test-- "same-datatype-22"	--assert not same? [d] back tail [a b c d]
	--test-- "same-datatype-23"	--assert not same? "2345" next "12345"
	--test-- "same-datatype-24"	--assert same? #"z" #"z"
	--test-- "same-datatype-25"	--assert not same? #"z" #"Z"
	--test-- "same-datatype-26"	--assert not same? #"e" #"è"
	--test-- "same-datatype-27"	--assert same? #"^(010000)" #"^(010000)"
	--test-- "same-datatype-28"	--assert same? true true
	--test-- "same-datatype-29"	--assert same? true #[true]
	--test-- "same-datatype-30"	--assert same? none #[none]
	--test-- "same-datatype-31"	--assert same? none none
	--test-- "same-datatype-32"	--assert same? 'true first [true]
	--test-- "same-datatype-33"	--assert same? first [#[true]] #[true]
	--test-- "same-datatype-34"	--assert same? false false
	--test-- "same-datatype-35"	--assert not same? false true
	--test-- "same-datatype-36"	--assert not same? true false
	--test-- "same-datatype-37"	--assert same? 'a 'a
	--test-- "same-datatype-38"	--assert not same? 'a 'A
	--test-- "same-datatype-39"	--assert not same? [a b c d e] first [[a b c d e]]
	--test-- "same-datatype-40"	--assert not same? 0.0 -0.0
	--test-- "same-datatype-41"
		ea-result: same? 1 1
		--assert ea-result = true
	--test-- "same-datatype-42"
		ea-result: same? 1 0
		--assert ea-result = false
===end-group===

===start-group=== "same-implcit-cast"
	--test-- "same-implcit-cast-1"	--assert not same? #"0" 48
	--test-- "same-implcit-cast-2"	--assert not same? 48 #"0"
	--test-- "same-implcit-cast-3"	--assert not same? #"^(2710)" 10000
	--test-- "same-implcit-cast-4"	--assert not same? #"^(010000)" 65536
	--test-- "same-implcit-cast-5"
		ea-result: #"1" == 49
		--assert ea-result = false
	--test-- "same-implcit-cast-6"
		ea-result: same? #"^(010000)" 10000
		--assert ea-result = false
	--test-- "same-implcit-cast-7"
		a: b: 1
		--assert same? a b
	--test-- "same-implcit-cast-8"
		a: b: "abcde"
		--assert same? a b
===end-group===

===start-group=== "infix-strict-equal-same-datatype"
	--test-- "infix-strict-equal-same-datatype-1"	--assert 0 == 0
	--test-- "infix-strict-equal-same-datatype-2"	--assert 1 == 1
	--test-- "infix-strict-equal-same-datatype-3"	--assert FFFFFFFFh == -1
	--test-- "infix-strict-equal-same-datatype-4"	--assert [] == []
	--test-- "infix-strict-equal-same-datatype-5"	--assert [a] == [a]
	--test-- "infix-strict-equal-same-datatype-6"	--assert not [A] == [a]
	--test-- "infix-strict-equal-same-datatype-7"	--assert not ['a] == [a]
	--test-- "infix-strict-equal-same-datatype-8"	--assert not [a:] == [a]
	--test-- "infix-strict-equal-same-datatype-9"	--assert not [:a] == [a]
	--test-- "infix-strict-equal-same-datatype-10"	--assert not [:a] == [a:]
	--test-- "infix-strict-equal-same-datatype-11"	--assert [abcde] == [abcde]
	--test-- "infix-strict-equal-same-datatype-12"	--assert [a b c d] == [a b c d]
	--test-- "infix-strict-equal-same-datatype-13"	--assert [b c d] == next [a b c d]
	--test-- "infix-strict-equal-same-datatype-14"	--assert [b c d] == (next [a b c d])
	--test-- "infix-strict-equal-same-datatype-15"	--assert "a" == "a"
	--test-- "infix-strict-equal-same-datatype-16"	--assert not "a" == "A"
	--test-- "infix-strict-equal-same-datatype-17"	--assert "abcdeè" == "abcdeè"
	--test-- "infix-strict-equal-same-datatype-18"	--assert (next "abcdeè") == next "abcdeè"
	--test-- "infix-strict-equal-same-datatype-19"	--assert (first "abcdeè") == first "abcdeè"
	--test-- "infix-strict-equal-same-datatype-20"	--assert (last "abcdeè") == last "abcdeè"
	--test-- "infix-strict-equal-same-datatype-21"	--assert "abcde^(2710)é^(010000)" == "abcde^(2710)é^(010000)"
	--test-- "infix-strict-equal-same-datatype-22"	--assert [d] == back tail [a b c d]
	--test-- "infix-strict-equal-same-datatype-23"	--assert "2345" == next "12345"
	--test-- "infix-strict-equal-same-datatype-24"	--assert #"z" == #"z"
	--test-- "infix-strict-equal-same-datatype-25"	--assert not #"z" == #"Z"
	--test-- "infix-strict-equal-same-datatype-26"	--assert not #"e" == #"è"
	--test-- "infix-strict-equal-same-datatype-27"	--assert #"^(010000)" == #"^(010000)"
	--test-- "infix-strict-equal-same-datatype-28"	--assert true == true
	--test-- "infix-strict-equal-same-datatype-29"	--assert false == false
	--test-- "infix-strict-equal-same-datatype-30"	--assert not false == true
	--test-- "infix-strict-equal-same-datatype-31"	--assert not true == false
	--test-- "infix-strict-equal-same-datatype-32"	--assert none == none
	--test-- "infix-strict-equal-same-datatype-33"	--assert 'a == 'a
	--test-- "infix-strict-equal-same-datatype-34"	--assert [a b c d e] == first [[a b c d e]]
	--test-- "infix-strict-equal-same-datatype-35"
		ea-result: 1 == 1
		--assert ea-result = true
	--test-- "infix-strict-equal-same-datatype-36"
		ea-result: 1 == 0
		--assert ea-result = false
	--test-- "infix-strict-equal-same-datatype-37"
		ea-result: strict-equal? 1 1
		--assert ea-result = true
	--test-- "infix-strict-equal-same-datatype-38"
		ea-result: strict-equal? 1 0
		--assert ea-result = false
	--test-- "infix-strict-equal-same-datatype-39"	--assert 0.0 == -0.0
	--test-- "infix-strict-equal-same-datatype-40"	--assert not 1 == 1.0
===end-group===

===start-group=== "infix-strict-equal-implcit-cast"
	--test-- "infix-strict-equal-implcit-cast-1"	--assert not #"0" == 48
	--test-- "infix-strict-equal-implcit-cast-2"	--assert not 48 == #"0"
	--test-- "infix-strict-equal-implcit-cast-3"	--assert not #"^(2710)" == 10000
	--test-- "infix-strict-equal-implcit-cast-4"	--assert not #"^(010000)" == 65536
	--test-- "infix-strict-equal-implcit-cast-5"
		ea-result: #"1" == 49
		--assert ea-result = false
	--test-- "infix-strict-equal-implcit-cast-6"
		ea-result: strict-equal? #"^(010000)" 10000
		--assert ea-result = false
	--test-- "infix-strict-equal-implcit-cast-7"
		a: b: 1
		--assert a == b
	--test-- "infix-strict-equal-implcit-cast-8"
		a: b: "abcde"
		--assert a == b
===end-group===

===start-group=== "prefix-strict-equal-same-datatype"
	--test-- "prefix-strict-equal-same-datatype-1"	--assert strict-equal? 0 0
	--test-- "prefix-strict-equal-same-datatype-2"	--assert strict-equal? 1 1
	--test-- "prefix-strict-equal-same-datatype-3"	--assert strict-equal? FFFFFFFFh -1
	--test-- "prefix-strict-equal-same-datatype-4"	--assert strict-equal? [] []
	--test-- "prefix-strict-equal-same-datatype-5"	--assert strict-equal? [a] [a]
	--test-- "prefix-strict-equal-same-datatype-6"	--assert not strict-equal? [A] [a]
	--test-- "prefix-strict-equal-same-datatype-7"	--assert not strict-equal? ['a] [a]
	--test-- "prefix-strict-equal-same-datatype-8"	--assert not strict-equal? [a:] [a]
	--test-- "prefix-strict-equal-same-datatype-9"	--assert not strict-equal? [:a] [a]
	--test-- "prefix-strict-equal-same-datatype-10"	--assert not strict-equal? [:a] [a:]
	--test-- "prefix-strict-equal-same-datatype-11"	--assert strict-equal? [abcde] [abcde]
	--test-- "prefix-strict-equal-same-datatype-12"	--assert strict-equal? [a b c d] [a b c d]
	--test-- "prefix-strict-equal-same-datatype-13"	--assert strict-equal? [b c d] next [a b c d]
	--test-- "prefix-strict-equal-same-datatype-14"	--assert strict-equal? [b c d] (next [a b c d])
	--test-- "prefix-strict-equal-same-datatype-15"	--assert strict-equal? "a" "a"
	--test-- "prefix-strict-equal-same-datatype-16"	--assert not strict-equal? "a" "A"
	--test-- "prefix-strict-equal-same-datatype-17"	--assert strict-equal? "abcdeè" "abcdeè"
	--test-- "prefix-strict-equal-same-datatype-18"	--assert strict-equal? (next "abcdeè") next "abcdeè"
	--test-- "prefix-strict-equal-same-datatype-19"	--assert strict-equal? (first "abcdeè") first "abcdeè"
	--test-- "prefix-strict-equal-same-datatype-20"	--assert strict-equal? (last "abcdeè") last "abcdeè"
	--test-- "prefix-strict-equal-same-datatype-21"	--assert strict-equal? "abcde^(2710)é^(010000)" "abcde^(2710)é^(010000)"
	--test-- "prefix-strict-equal-same-datatype-22"	--assert strict-equal? [d] back tail [a b c d]
	--test-- "prefix-strict-equal-same-datatype-23"	--assert strict-equal? "2345" next "12345"
	--test-- "prefix-strict-equal-same-datatype-24"	--assert strict-equal? #"z" #"z"
	--test-- "prefix-strict-equal-same-datatype-25"	--assert not strict-equal? #"z" #"Z"
	--test-- "prefix-strict-equal-same-datatype-26"	--assert not strict-equal? #"e" #"è"
	--test-- "prefix-strict-equal-same-datatype-27"	--assert strict-equal? #"^(010000)" #"^(010000)"
	--test-- "prefix-strict-equal-same-datatype-28"	--assert strict-equal? true true
	--test-- "prefix-strict-equal-same-datatype-29"	--assert strict-equal? false false
	--test-- "prefix-strict-equal-same-datatype-30"	--assert not strict-equal? false true
	--test-- "prefix-strict-equal-same-datatype-31"	--assert not strict-equal? true false
	--test-- "prefix-strict-equal-same-datatype-32"	--assert strict-equal? none none
	--test-- "prefix-strict-equal-same-datatype-33"	--assert strict-equal? 'a 'a
	--test-- "prefix-strict-equal-same-datatype-34"	--assert strict-equal? [a b c d e] first [[a b c d e]]
	--test-- "prefix-strict-equal-same-datatype-35"
		ea-result: 1 == 1
		--assert ea-result = true
	--test-- "prefix-strict-equal-same-datatype-36"
		ea-result: 1 == 0
		--assert ea-result = false
	--test-- "prefix-strict-equal-same-datatype-37"
		ea-result: strict-equal? 1 1
		--assert ea-result = true
	--test-- "prefix-strict-equal-same-datatype-38"
		ea-result: strict-equal? 1 0
		--assert ea-result = false
	--test-- "prefix-strict-equal-same-datatype-39"	--assert strict-equal? 0.0 -0.0
	--test-- "prefix-strict-equal-same-datatype-40"	--assert not strict-equal? 1 1.0
===end-group===

===start-group=== "prefix-strict-equal-implcit-cast"
	--test-- "prefix-strict-equal-implcit-cast-1"	--assert not strict-equal? #"0" 48
	--test-- "prefix-strict-equal-implcit-cast-2"	--assert not strict-equal? 48 #"0"
	--test-- "prefix-strict-equal-implcit-cast-3"	--assert not strict-equal? #"^(2710)" 10000
	--test-- "prefix-strict-equal-implcit-cast-4"	--assert not strict-equal? #"^(010000)" 65536
	--test-- "prefix-strict-equal-implcit-cast-5"
		ea-result: #"1" == 49
		--assert ea-result = false
	--test-- "prefix-strict-equal-implcit-cast-6"
		ea-result: strict-equal? #"^(010000)" 10000
		--assert ea-result = false
	--test-- "prefix-strict-equal-implcit-cast-7"
		a: b: 1
		--assert strict-equal? a b
	--test-- "prefix-strict-equal-implcit-cast-8"
		a: b: "abcde"
		--assert strict-equal? a b
===end-group===

~~~end-file~~~
