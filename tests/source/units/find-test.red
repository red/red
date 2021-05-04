Red [
	Title:   "Red find test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %find-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "find"

===start-group=== "find"
	--test-- "find-1"
		--assert [1 2 3 4] = find [1 2 3 4] 1
	--test-- "find-2"
		--assert [2 3 4] = find [1 2 3 4] 2
	--test-- "find-3"
		--assert [4] = find [1 2 3 4] 4
	--test-- "find-4"
		--assert none = find [1 2 3 4] 0
	--test-- "find-5"
		--assert none = find [1 2 3 4] 5
	--test-- "find-6"
		--assert none = find [1 2 3 4] "1"
	--test-- "find-7" 
		--assert "12345" = find "12345" #"1"
	--test-- "find-8" 							
		--assert none = find "12345" 1
	--test-- "find-9" 
		--assert "12345" = find "12345" "1"
	--test-- "find-10" 
		--assert "12345" = find "12345" "12"
	--test-- "find-11" 
		--assert "2345" = find "12345" #"2"
	--test-- "find-12" 
		--assert "5" = find "12345" #"5"
	--test-- "find-13" 
		--assert none = find "12345" #"0" 
	--test-- "find-14" 
		--assert none = find "12345" #"6"
	--test-- "find-15"
		--assert [2 3] = find [1 2 3] [2 3]
	--test-- "find-16"
		--assert none = find [1 2 3] [3 2]
	--test-- "find-17"
		--assert [2 3] = find [1 2 2 3] [2 3]
	--test-- "find-18"
		--assert none = find [1 2] [2 3]
	--test-- "find-19"
		--assert "é" = find "abcdeé" "é"
	--test-- "find-20"
		--assert "eé" = find "abcdeé" "eé"
	--test-- "find-21"
		--assert none = find "abcdeé" "ée"
	--test-- "find-22"
		--assert "✐" = find "abcde✐" "✐"            ;; code point 10000 (decimal)
	--test-- "find-23"
		--assert none = find "abcde✐" "ed✐"
	--test-- "find-24"
		--assert "^(010000)" = find "abcde^(010000)" "^(010000)" 
	--test-- "find-25"
		--assert none = find tail "123345" 1
	--test-- "find-26 -issue #765"
		--assert none = find tail [a b c d e] 'a	
		
===end-group===

===start-group=== "find/part"
	--test-- "find/part-1"
		--assert none = find/part "1234" "1" 0
	--test-- "find/part-2"
		--assert "1234" = find/part "1234" "1" 1
	--test-- "find/part-3"
		--assert "234" = find/part "1234" "2" 2
	--test-- "find/part-4"
		--assert "234" = find/part "1234" "2" 4
	--test-- "find/part-5"
		--assert "234" = find/part "1234" "2" 5
	--test-- "find/part-6"
		--assert none = find/part "1234" "3" 2
	--test-- "find/part-7"
		--assert none = find/part [1 2 3 4] 1 0
	--test-- "find/part-8"
		--assert [1 2 3 4] = find/part [1 2 3 4] 1 1
	--test-- "find/part-9"
		--assert [2 3 4] = find/part [1 2 3 4] 2 2
	--test-- "find/part-10"
		--assert [2 3 4] = find/part [1 2 3 4] [2 3] 4
	--test-- "find/part-11"
		--assert none = find/part [1 2 3 4] [2 3] 2
	--test-- "find/part-12"
		--assert none = find/part [1 2 3 4] 3 2
	--test-- "find/part-13"
		--assert none = find/part "Χαῖρε, κόσμε!" "Χαῖ" 2
===end-group===

===start-group=== "find/only"
	--test-- "find/only-1"
		--assert [[2 3] 4] = find/only [1 [2 3] 4] [2 3]
	--test-- "find/only-2"
		--assert none = find/only [1 2 3 4] [2 3]
===end-group===

===start-group=== "find/case"
	--test-- "find/case-1"
		--assert "abcde" = find/case "Aabcde" "a"
	--test-- "find/case-2"
		--assert "Abcde" = find/case "aAbcde" "A"
	--test-- "find/case-3"
		--assert none = find/case "è" "E"
===end-group===

===start-group=== "find/same"
	--test-- "find/same-1"
		--assert "Abcde" = find/same "aAbcde" "A"
	--test-- "find/same-2"
		obj1: context [a: 1 b: 2]
		obj2: context [a: 1 b: 2]
		blk: reduce [1 obj1 2 obj2 3]
		res: skip blk 3
		--assert res = find/same blk obj2
	--test-- "find/same-3"
		hs: make hash! blk
		res: skip hs 3
		--assert res = find/same hs obj2
===end-group===

===start-group=== "find/any"      ; not yet implemented
	--test-- "find/any-1"
		;--assert "12345" = find/any "12345" "*"
	--test-- "find/any-2"
		;--assert "12345" = find/any "12345" "?"
	--test-- "find/any-3"
		;--assert "2345" = find/any "12345" "2?4"
	--test-- "find/any-4"
		;--assert "2345" = find/any "12345" "2*"
	--test-- "find/any-5"
		;--assert "e✐" = find/any "abcde✐" "e?"        ;; code point 10000 (decimal)
	--test-- "find/any-6"
		;--assert "e✐f" = find/any "abcde✐f" "?f" 
	--test-- "find/any-7"
		;--assert "e✐" = find/any "abcde✐" "e*" 
	--test-- "find/any-8"
		;--assert "abcde✐f" = find/any "abcde✐f" "*f" 
	--test-- "find/any-9"
		;--assert "e^(010000)" = find/any "abcde^(010000)" "e?"        
	--test-- "find/any-10"
		;--assert "e^(010000)f" = find/any "abcde^(010000)f" "?f" 
	--test-- "find/any-11"
		;--assert "e^(010000)" = find/any "abcde^(010000)" "e*" 
	--test-- "find/any-12"
		;--assert "abcde^(010000)f" = find/any "abcde^(010000)f" "*f" 
===end-group===

===start-group=== "find/with"      ; not yet implemented
	--test-- "find/with-1"
		;--assert "12345" = find/with "12345" "^(FFFF)" "^(FFFE)^(FFFF)" 
	--test-- "find/with-2"
		;--assert "12345" = find/with "12345" "^(FFFE)" "^(FFFE)^(FFFF)" 
	--test-- "find/with-3"
		;--assert "2345" = find/with "12345" "2^(FFFE)3" "^(FFFE)^(FFFF)"
	--test-- "find/with-4"
		;--assert "2345" = find/with "12345" "2^(FFFF)" "^(FFFE)^(FFFF)"
	--test-- "find/with-5"
		;--assert "e✐" = find/with "abcde✐" "e^(FFFE)" "^(FFFE)^(FFFF)"
	--test-- "find/with-6"
		;--assert "e✐f" = find/with "abcde✐f" "^(FFFE)f" "^(FFFE)^(FFFF)"
	--test-- "find/with-7"
		;--assert "e✐" = find/with "abcde✐" "e^(FFFF)" "^(FFFE)^(FFFF)"
	--test-- "find/with-8"
		;--assert "abcde✐f" = find/with "abcde✐f" "^(FFFF)f" "^(FFFE)^(FFFF)" 
	--test-- "find/with-9"
		;--assert "e^(010000)" = find/with "abcde^(010000)" "e^(FFFE)" "^(FFFE)^(FFFF)"        
	--test-- "find/with-10"
		;--assert "e^(010000)f" = find/with "abcde^(010000)f" "^(FFFE)f" "^(FFFE)^(FFFF)"
	--test-- "find/with-11"
		;--assert "e^(010000)" = find/with "abcde^(010000)" "e^(FFFF)" "^(FFFE)^(FFFF)"
	--test-- "find/with-12"
		;--assert "abcde^(010000)f" = find/with "abcde^(010000)f" "^(FFFF)f" "^(FFFE)^(FFFF)"
===end-group===

===start-group=== "find/skip"
	--test-- "find/skip-1"
		--assert [6 7 8 9 0] = find/skip [1 2 3 4 5 1 6 6 6 6 1 2 3 4 5 6 7 8 9 0] 6 5
	--test-- "find/skip-2"
		--assert none = find/skip [1 2 3 4 5 1 6 6 6 6 1 2 3 4 5 1 2 3 4 5] 6 5
	--test-- "find/skip-3"
		--assert [6 7 8 9 0] = find/skip [1 2 3 4 5 6 6 6 6 6 1 2 3 4 5 6 7 8 9 0] [6 7] 5
	--test-- "find/skip-4"
		--assert none = find/skip [1 2 3 4 5 1 6 6 6 6 1 2 3 4 5 1 2 3 4 5] [6 7] 5
	--test-- "find/skip-5"
		--assert "67890" = find/skip "12345166661234567890" "6" 5
	--test-- "find/skip-6"
		--assert none = find/skip "12345166661234557890" "6" 5
===end-group===

===start-group=== "find/match"
	--test-- "find/match-1"
		--assert [and now] = find/match [here and now] 'here
	--test-- "find/match-2"
		--assert none = find/match [here and now] 'her
	--test-- "find/match-3"
		--assert none = find/match [her and now] 'here
	--test-- "find/match-4"
		--assert " and now" = find/match "here and now" "here"
	--test-- "find/match-5"
		--assert "andnow" = find/match "hereandnow" "here"
	--test-- "find/match-6"
		--assert none = find/match "her and now" "here"
	--test-- "find/match-7"
		--assert " and now" = find/match "here✐ and now" "here✐"
	--test-- "find/match-8"
		--assert "✐andnow" = find/match "here✐andnow" "here"
	--test-- "find/match-9"
		--assert none = find/match "her and now" "he✐r"
	--test-- "find/match-10"
		--assert none = find/match "here and now" "✐here"
	--test-- "find/match-11"
		--assert "^(010000)andnow" = find/match "here^(010000)andnow" "here"
	--test-- "find/match-12"
		--assert none = find/match "her and now" "here^(010000)"
	--test-- "find/match-13"
		--assert " and now" = find/match "here^(010000) and now" "here^(010000)"
	--test-- "find/match-14"
		--assert "andnow" = find/match "^(010000)hereandnow" "^(010000)here"
	--test-- "find/match-15"
		--assert none = find/match "her^(010000) and now" "here^(010000)"
	--test-- "find/match-16"
		--assert [and now] = find/match [he✐re and now] 'he✐re
===end-group===

===start-group=== "find/tail"
	--test-- "find/tail-1"
		--assert [and now] = find/tail [here and now] 'here
	--test-- "find/tail-2"
		--assert none = find/tail [here and now] 'her
	--test-- "find/tail-3"
		--assert none = find/tail [her and now] 'here
	--test-- "find/tail-4"
		--assert " and now" = find/tail "here and now" "here"
	--test-- "find/tail-5"
		--assert "andnow" = find/tail "hereandnow" "here"
	--test-- "find/tail-6"
		--assert none = find/tail "her and now" "here"
	--test-- "find/tail-7"
		--assert " and now" = find/tail "here✐ and now" "here✐"
	--test-- "find/tail-8"
		--assert "✐andnow" = find/tail "here✐andnow" "here"
	--test-- "find/tail-9"
		--assert none = find/tail "her and now" "he✐r"
	--test-- "find/tail-10"
		--assert none = find/tail "here and now" "✐here"
	--test-- "find/tail-11"
		--assert "^(010000)andnow" = find/tail "here^(010000)andnow" "here"
	--test-- "find/tail-12"
		--assert none = find/tail "her and now" "here^(010000)"
	--test-- "find/tail-13"
		--assert " and now" = find/tail "here^(010000) and now" "here^(010000)"
	--test-- "find/tail-14"
		--assert "andnow" = find/tail "^(010000)hereandnow" "^(010000)here"
	--test-- "find/tail-15"
		--assert none = find/tail "her^(010000) and now" "here^(010000)"
	--test-- "find/tail-16"
		--assert [and now] = find/tail [he✐re and now] 'he✐re
	--test-- "find/tail-17 issue #457"
		--assert "de" = find/tail "abcde" #"c"
	--test-- "find-tail-18"
		--assert "de" = find/tail "abc^^de" #"^^"
	
===end-group===

===start-group=== "find/last"
	--test-- "find/last-1"
		--assert [1] = find/last [1 1 1 1] 1
		--assert 4 = index? find/last [1 1 1 1] 1
	--test-- "find/last-2"
		--assert [2 1] = find/last [1 2 3 4 3 2 1] 2
	--test-- "find/last-3"
		--assert [3 3 2 1] = find/last [1 2 3 3 2 1] [3 3]
	--test-- "find/last-4"
		--assert "3321" = find/last "123321" "33"
	--test-- "find/last-5"
		--assert "321" = find/last "123321" "3"
	--test-- "find/last-6"
		--assert "1" = find/last "1111" "1"
	--test-- "find/last-7"
		--assert none = find/last "123" "34"
	--test-- "find/last-8" 
		--assert "✐5678" = find/last "1234✐5678" "✐"
	--test-- "find/last-9" 
		--assert "^(010000)5678" = find/last "1234^(010000)5678" "^(010000)"
===end-group===

===start-group=== "find/reverse"
	--test-- "find/reverse-1"
		--assert none = find/reverse [1 1 1 1] 1
	--test-- "find/reverse-2"
		--assert [2 1] = find/reverse tail [1 2 3 4 3 2 1] 2
	--test-- "find/reverse-3"
		--assert [3 3 2 1] = find/reverse tail [1 2 3 3 2 1] [3 3]
	--test-- "find/reverse-4"
		--assert "3321" = find/reverse back back tail "123321" "33"
	--test-- "find/reverse-5"
		--assert "3321" = find/reverse back back back tail"123321" "3"
	--test-- "find/reverse-6"
		--assert "1" = find/reverse tail "1111" "1"
	--test-- "find/reverse-7"
		--assert none = find/reverse tail "123" "34"
	--test-- "find/reverse-8" 
		--assert "✐5678" = find/reverse tail "1234✐5678" "✐"
	--test-- "find/reverse-9" 
		--assert "^(010000)5678" = find/reverse tail "1234^(010000)5678" "^(010000)"
	--test-- "find/reverse-10 issue #505" 
		--assert "ab" = find/reverse tail "ab" #"a"
		--assert "ab" = find/reverse tail "ab" "ab"
		--assert [a b] = find/reverse tail [a b] 'a
		--assert [a b] = find/reverse tail [a b] [a b]
===end-group===

===start-group=== "find/last/tail"
	--test-- "find/last/tail-1 issue #459"
		--assert [7 8] = find/last/tail [1 2 3 4 5 6 3 7 8] 3
	--test-- "find/last/tail-2 issue #459"
		--assert "78" = find/last/tail "123456378" #"3"
	--test-- "find/last/tail-3"
		--assert "78" = find/last/tail "123456378" "3"
===end-group===

===start-group=== "find datatype! / typeset!"
	--test-- "find-dt-1" --assert [1] = find [a 1] integer!
	--test-- "find-dt-2" --assert none = find [a] integer!
	--test-- "find-dt-3" --assert [3% 4.5.6 #c] = find [1 "a" 2.0 #"b" 3% 4.5.6 #c] percent!
	--test-- "find-dt-4" --assert ['b 4.5.6 c:] = find ["a" 2.0 'b 4.5.6 c: ] any-word!
	--test-- "find-dt-5" --assert ["b"] = find [a "b"] series!

	--test-- "find-dt-6"  --assert (make hash! [1]) = find make hash! [a 1] integer!
	--test-- "find-dt-7"  --assert none = find make hash! [a] integer!
	--test-- "find-dt-8"  --assert (make hash! [3% 4.5.6 #c]) = make hash! find [1 "a" 2.0 #"b" 3% 4.5.6 #c] percent!
	--test-- "find-dt-9"  --assert (make hash! ['b 4.5.6 c:]) = make hash! find ["a" 2.0 'b 4.5.6 c: ] any-word!
	--test-- "find-dt-10" --assert (make hash! ["b"]) = find make hash! [a "b"] series!

===end-group===

===start-group=== "find/reverse/match"
	--test-- "find/reverse/match-1"
		--assert none = find/reverse/match tail "abc" "abc"
	--test-- "find/reverse/match-2"
		--assert none = find/reverse/match tail "abcx" "abc"
===end-group===

===start-group=== "find/tail/skip"
	list: [a 6 7 c d e 8 7 b c d e f 6 4]
	list2: [c d e 8 7 b c d e f 6 4]
	res:  [8 7 b c d e f 6 4]
	pattern: [c d e]
	
	--test-- "fts-1"
		--assert res = find/tail/skip list pattern 3
	--test-- "fts-2"
		--assert res = find/skip/tail list pattern 3
	--test-- "fts-3"
		--assert res = find/tail/skip list2 pattern 3
	--test-- "fts-4"
		--assert [f 6 4] = find/tail/skip/last list2 pattern 3
		
===end-group===

===start-group=== "find/tail/skip/last"
	--test-- "ftsl-1"
		--assert [f 6 4] = find/tail/skip/last list2 pattern 3
		
===end-group===

===start-group=== "FIND issue #3687"

	--test-- "issue-3687-1"
		--assert [c d e f 6 4] = find/skip/last list2 pattern 3	
	--test-- "issue-3687-2"
		--assert [c d e f 6 4] = find/skip/reverse tail list2 pattern 3
	--test-- "issue-3687-3"
		--assert [c d e 8 7 b c d e f 6 4] = find/skip/reverse skip list2 6 pattern 3

	--test-- "issue-3687-4"
		--assert [f 6 4] = find/tail/skip/last list2 pattern 3
	--test-- "issue-3687-5"
		--assert [f 6 4] = find/tail/skip/reverse tail list2 pattern 3
	--test-- "issue-3687-6"
		--assert [8 7 b c d e f 6 4] = find/tail/skip/reverse skip list2 6 pattern 3

	s: "cde87bcdef64"
	pattern: "cde"

	--test-- "issue-3687-7"
		--assert "cdef64" = find/skip/last s pattern 3
	--test-- "issue-3687-8"
		--assert "cdef64" = find/skip/reverse tail s pattern 3
	--test-- "issue-3687-9"
		--assert "cde87bcdef64" = find/skip/reverse skip s 6 pattern 3

	--test-- "issue-3687-10"
		--assert "f64" = find/tail/skip/last s pattern 3
	--test-- "issue-3687-11"
		--assert "f64" = find/tail/skip/reverse tail s pattern 3
	--test-- "issue-3687-12"
		--assert "87bcdef64" = find/tail/skip/reverse skip s 6 pattern 3

===end-group===

===start-group=== "FIND issue #4165 (words)"

	a: object [x: 1]
	b: object [x: 2]
	xs: reduce ['x in a 'x in b 'x]

	--test-- "issue-4165-w1"
		--assert 2 = index? find/same xs in a 'x
	--test-- "issue-4165-w2"
		--assert 3 = index? find/same xs in b 'x
	--test-- "issue-4165-w3"
		--assert 2 = index? find/same xs next xs
	--test-- "issue-4165-w4"
		--assert to logic! find/match/same xs reduce ['x in a 'x]
	--test-- "issue-4165-w5"
		--assert same? xs/1 to word! to refinement! xs/2	;-- loses binding during conversion
	--test-- "issue-4165-w6"
		--assert same? xs/1 to word! to issue! xs/2			;-- loses binding during conversion

===end-group===

===start-group=== "FIND issue #4165 (floats)"

	nan1: 0.0 / 0.0
	nan2: 1.0 * 1.#inf
	b: reduce [1 1.0 nan1 nan2 to percent! nan1 to time! nan2]

	--test-- "issue-4165-f1"
		--assert 3 = index? find/same b nan1
	--test-- "issue-4165-f2"
		--assert 4 = index? find/same b nan2
	--test-- "issue-4165-f3"
		--assert 3 = index? find/same b reduce [nan1 nan2]
	--test-- "issue-4165-f4"
		--assert to logic! find/match/same next b reduce [1.0 nan1 nan2]
	--test-- "issue-4165-f5"
		--assert 5 = index? find/same b to percent! nan1
	--test-- "issue-4165-f6"
		--assert 6 = index? find/same b to time! nan2

	dt1: 2000-1-1 + to time! nan1
	dt2: 2000-1-1 + to time! nan2
	dts: reduce [dt1 dt2]

	--test-- "issue-4165-f7"
		--assert not same?  dt1 dt2
	; --test-- "issue-4165-f8"				;@@ FIXME: needs #4717 merged to work
	; 	--assert not equal? dt1 dt1
	; --test-- "issue-4165-f9"				;@@ FIXME: needs #4717 merged to work
	; 	--assert not strict-equal? dt1 dt1
	--test-- "issue-4165-f10"
		--assert 1 = index? find/same dts dt1
	--test-- "issue-4165-f11"
		--assert 2 = index? find/same dts dt2

===end-group===

===start-group=== "FIND issue #4165 (bitsets)"

	bs1: make bitset! [1 - 10]
	bs2: make bitset! [1 - 10]
	bss: reduce [bs1 bs2]

	--test-- "issue-4165-bs1"
		--assert equal? bs1 bs2
	--test-- "issue-4165-bs2"
		--assert not same? bs1 bs2
	--test-- "issue-4165-bs3"
		--assert 1 = index? find/same bss bs1
	--test-- "issue-4165-bs4"
		--assert 2 = index? find/same bss bs2

===end-group===

~~~end-file~~~
