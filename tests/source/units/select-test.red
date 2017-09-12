Red [
	Title:   "Red select test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %select-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "select"

===start-group=== "select"
	--test-- "select-1"
	--assert 2 = select [1 2 3 4] 1
	--test-- "select-2"
	--assert 3 = select [1 2 3 4] 2
	--test-- "select-3"
	--assert none = select [1 2 3 4] 4
	--test-- "select-4"
	--assert none = select [1 2 3 4] 0
	--test-- "select-5"
	--assert none = select [1 2 3 4] 5
	--test-- "select-6"
	--assert none = select [1 2 3 4] "1"
	--test-- "select-7" 
	--assert #"2" = select "12345" #"1"
	;--test-- "select-8" 								;; unsupported case, it is unsure if it will be implemented or not
	;--assert #"2" = select "12345" 1					;; keeping it here commented for further reference.
	--test-- "select-9" 
	--assert #"2" = select "12345" "1"
	--test-- "select-10" 
	--assert #"3" = select "12345" "12"
	--test-- "select-11" 
	--assert #"3" = select "12345" #"2"
	--test-- "select-12" 
	--assert none = select "12345" #"5"
	--test-- "select-13" 
	--assert none = select "12345" #"0" 
	--test-- "select-14" 
	--assert none = select "12345" #"6"
	--test-- "select-15"
	--assert 3 = select [1 2 3] [1 2]
	--test-- "select-16"
	--assert none = select [1 2 3] [3 2]
	--test-- "select-17"
	--assert 3 = select [1 2 2 3] [2 2]
	--test-- "select-18"
	--assert none = select [1 2] [2 3]
	--test-- "select-19"
	--assert #"f" = select "abcdeéf" "é"
	--test-- "select-20"
	--assert #"f" = select "abcdeéf" "eé"
	--test-- "select-21"
	--assert none = select "abcdeéf" "ée"
	--test-- "select-22"
	--assert #"✐" = select "abcde✐" "e"            ;; code point 10000 (decimal)
	--test-- "select-23"
	--assert none = select "abcde✐" "ed✐"
	--test-- "select-24"
	--assert #"f" = select "abcde^(010000)f" "^(010000)"   
===end-group===

===start-group=== "select/part"
	--test-- "select/part-1"
	--assert none = select/part "1234" "1" 0
	--test-- "select/part-2"
	--assert #"2" = select/part "1234" "1" 1
	--test-- "select/part-3"
	--assert #"3" = select/part "1234" "2" 2
	--test-- "select/part-4"
	--assert #"3" = select/part "1234" "2" 4
	--test-- "select/part-5"
	--assert #"3" = select/part "1234" "2" 5
	--test-- "select/part-6"
	--assert none = select/part "1234" "3" 2
	--test-- "select/part-7"
	--assert none = select/part [1 2 3 4] 1 0
	--test-- "select/part-8"
	--assert 2 = select/part [1 2 3 4] 1 1
	--test-- "select/part-9"
	--assert 3 = select/part [1 2 3 4] 2 2
	--test-- "select/part-10"
	--assert 4 = select/part [1 2 3 4] [2 3] 4
	--test-- "select/part-11"
	--assert none = select/part [1 2 3 4] [2 3] 2
	--test-- "select/part-12"
	--assert none = select/part [1 2 3 4] 3 2
===end-group===

===start-group=== "select/only"
	--test-- "select/only-1"
	--assert 4 = select/only [1 [2 3] 4] [2 3]
	--test-- "select/only-2"
	--assert none = select/only [1 2 3 4] [2 3]
===end-group===

===start-group=== "select/case"
	--test-- "select/case-1"
	--assert #"b" = select/case "Aabcde" "a"
	--test-- "select/case-2"
	--assert #"b" = select/case "aAbcde" "A"
	--test-- "select/case-3"
	--assert none = select/case "è" "E"
===end-group===

===start-group=== "select/any"      ; not yet implemented
	--test-- "select/any-1"
	;--assert none = select/any "12345" "*"
	--test-- "select/any-2"
	;--assert #"2" = select/any "12345" "?"
	--test-- "select/any-3"
	;--assert #"5" = select/any "12345" "2?4"
	--test-- "select/any-4"
	;assert none = select/any "12345" "2*"
	--test-- "select/any-5"
	;assert "" = select/any "abcde✐f" "e?"        ;; code point 10000 (decimal)
	--test-- "select/any-6"
	;assert "g" = select/any "abcde✐fg" "?f" 
	--test-- "select/any-7"
	;assert none = select/any "abcde✐" "e*" 
	--test-- "select/any-8"
	;assert "g" = select/any "abcde✐fg" "*f" 
	--test-- "select/any-9"
	;assert "f" = select/any "abcde^(010000)f" "e?"        
	--test-- "select/any-10"
	;assert "g" = select/any "abcde^(010000)fg" "?f" 
	--test-- "select/any-11"
	;assert none = select/any "abcde^(010000)" "e*" 
	--test-- "select/any-12"
	;assert "g" = select/any "abcde^(010000)fg" "*f" 
===end-group===

===start-group=== "select/with"      ; not yet implemented
	--test-- "select/with-1"
	;--assert #"2" = select/with "12345" "^(FFFF)" "^(FFFE)^(FFFF)" 
	--test-- "select/with-2"
	;--assert none = select/with "12345" "^(FFFE)" "^(FFFE)^(FFFF)" 
	--test-- "select/with-3"
	;--assert #"4" = select/with "12345" "2^(FFFE)3" "^(FFFE)^(FFFF)"
	--test-- "select/with-4"
	;assert #"3" = select/with "12345" "2^(FFFF)" "^(FFFE)^(FFFF)"
	--test-- "select/with-5"
	;assert none = select/with "abcde✐" "e^(FFFE)" "^(FFFE)^(FFFF)"
	--test-- "select/with-6"
	;assert #"g" = select/with "abcde✐fg" "^(FFFE)f" "^(FFFE)^(FFFF)"
	--test-- "select/with-7"
	;assert #"f" = select/with "abcde✐f" "e^(FFFF)" "^(FFFE)^(FFFF)"
	--test-- "select/with-8"
	;assert #"g" = select/with "abcde✐fg" "^(FFFF)f" "^(FFFE)^(FFFF)" 
	--test-- "select/with-9"
	;assert none = select/with "abcde^(010000)" "e^(FFFE)" "^(FFFE)^(FFFF)"        
	--test-- "select/with-10"
	;assert #"g" = select/with "abcde^(010000)f" "^(FFFE)f" "^(FFFE)^(FFFF)"
	--test-- "select/with-11"
	;assert #"f" = select/with "abcde^(010000)" "e^(FFFF)" "^(FFFE)^(FFFF)"
	--test-- "select/with-12"
	;assert #"g" = select/with "abcde^(010000)f" "^(FFFF)f" "^(FFFE)^(FFFF)"
===end-group===

===start-group=== "select/skip"
  --test-- "select/skip-1"
  --assert 7 = select/skip [1 2 3 4 5 1 6 6 6 6 1 2 3 4 5 6 7 8 9 0] 6 5
  --test-- "select/skip-2"
  --assert none = select/skip [1 2 3 4 5 1 6 6 6 6 1 2 3 4 5 1 2 3 4 5] 6 5
  --test-- "select/skip-3"
  --assert 8 = select/skip [1 2 3 4 5 6 6 6 6 6 1 2 3 4 5 6 7 8 9 0 ] [6 7] 5
  --test-- "select/skip-4"
  --assert none = select/skip [1 2 3 4 5 1 6 6 6 6 1 2 3 4 5 1 2 3 4 5] [6 7] 5
  --test-- "select/skip-5"
  --assert #"7" = select/skip "12345166661234567890" "6" 5
  --test-- "select/skip-6"
  --assert none = select/skip "12345166661234557890" "6" 5
===end-group===

~~~end-file~~~

