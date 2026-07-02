Red [
	Title:   "Red change test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %change-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

;-- Transposed from %insert-test.red. CHANGE differs from INSERT:
;--   * it OVERWRITES at the target position instead of shifting the original content right
;--   * /part applies to the FIRST argument (number of target elements replaced), not the value
;--   * a /part position must point into the FIRST argument (in INSERT it points into the value)
;-- All series datatypes are active: any-string!, any-block! (block!/hash!/paren!/path!),
;-- binary! and vector!. Insert-specific forms with no CHANGE analogue (a /part position in the
;-- VALUE series, parse-INSERT) have been removed; the only commented-out test is the documented
;-- self-slice straddle KNOWN LIMITATION near the end of the file.

~~~start-file~~~ "change"

===start-group=== "change"
	--test-- "change-1"
	--assert 6 = first head change [1 2 3 4 5] 6
	--assert [2 3 4 5] = change [1 2 3 4 5] 6
	--test-- "change-2"
	--assert 5 = first head change [1 2 3 4] [5 6]
	--assert [3 4] = change [1 2 3 4] [5 6]
	--assert [5 6 3 4] = head change [1 2 3 4] [5 6]
	--test-- "change-3"
	--assert "345" = change "12345" "67"
	--assert "67345" = head change "12345" "67"
	--test-- "change-4"
	--assert "abcdeé" = head change tail "abcde" "é"   	;; utf-8 C3 A9
	--assert "é" = back change tail "abcde" "é" 			;; utf-8 C3 A9
	--assert #"é" = first back change tail "abcde" "é"
	--test-- "change-5"
	--assert 49 = first head change "abcdeé" "1" ;; utf-8 C3 A9
	--test-- "change-6"
	--assert 10000 = first head change "abcde" "✐"
	--assert 10000 = first head change "abcde" #"✐"
	--test-- "change-7"
	--assert #"0" = first head change "abcde^(2710)" "0"
	--assert #"0" = first head change "abcde^(2710)" #"0"
	--assert #"^(2710)" = last change "abcde^(2710)" "0"
	--test-- "change-8"
	--assert 10000 = first head change "abcdeé" "^(2710)"
	--assert 10000 = first head change "abcdeé" #"^(2710)"
	--test-- "change-9"
	--assert 233 = first head change "abcde^(2710)" "é"
	--assert 233 = first head change "abcde^(2710)" #"é"
	--test-- "change-10"
	--assert 65536 = first head change "abcde" "^(010000)"
	--assert 65536 = first head change "abcde" #"^(010000)"
	--test-- "change-11"
	--assert 48 = first head change "abcde^(010000)" "0"
	--assert 48 = first head change "abcde^(010000)" #"0"
	--test-- "change-12"
	--assert 65536 = first head change "abcde^(2710)é" "^(010000)"
	--assert 65536 = first head change "abcde^(2710)é" #"^(010000)"
	--test-- "change-13"
		blk: make block! 1
		change blk 'x/y
		change/only blk 'r/s
	--assert "[r/s y]" = mold blk
	--test-- "change-14"
		blk: [1 2]
		change/dup/part blk [4 5 6] 3 2
	--assert "[4 5 6 4 5 6 4 5 6]" = mold blk
	--test-- "change-15"
		blk: [1 2]
		change/dup/part blk [4 5 6] 2 3
	--assert "[4 5 6 4 5 6]" = mold blk
	--test-- "change-16"
		str: "12"
		change/dup/part str "456" 3 2
	--assert str = "456456456"
	--test-- "change-17"
		str: "12"
		change/part/dup str "456" 3 2
	--assert str = "456456"
	--test-- "change-18"
		hash: make hash! [a b c 1 2 3]
		change hash [x y]
	--assert 'y = select hash 'x
	--assert 2  = select hash 1

	--test-- "change-29"
		str: next next "12é"
		--assert "" = change/part/dup str ["4" #"5" #"6" 7 a 'b x] 6 2
		--assert str = "4567abx4567abx"
		--assert (head str) = "124567abx4567abx"

	--test-- "change-30"
		str: "12"
		--assert "" = change/part/dup str ["4" #"5" #"6" 7 é 'b x] 6 2
		--assert str = "4567ébx4567ébx"

	--test-- "change-31"
		str: "12"
		--assert "" = change/part/dup str ["4" #"5" #"é" 7 a 'b x] 6 2
		--assert str = "45é7abx45é7abx"

	--test-- "change-32"
		str: "12"
		--assert "" = change/part/dup str ["4" #"5" #"^(010000)" 7 a 'b x] 6 2
		--assert str = "45^(010000)7abx45^(010000)7abx"

	--test-- "change-33"
		str: "12é"
		--assert "" = change/part/dup str ["4" #"5" #"^(010000)" 7 a 'b x] 6 2
		--assert str = "45^(010000)7abx45^(010000)7abx"

	--test-- "change-34"
		str: "12^(010000)"
		--assert "" = change/part/dup str ["4" #"5" #"6" 7 a 'b x] 6 2
		--assert str = "4567abx4567abx"

	--test-- "change-34.1"
		str: next next "12é"
		--assert "" = change/part/dup str next ["4" #"5" #"6" 7 a 'b x] 6 2
		--assert str = "567abx567abx"
		--assert (head str) = "12567abx567abx"

	--test-- "change-34.2"
		str: "12"
		--assert "" = change/part/dup str next next ["4" #"5" #"6" 7 é 'b x] 6 2
		--assert str = "67ébx67ébx"

	--test-- "change-34.3"
		str: "12"
		--assert "" = change/part/dup str next next ["4" #"5" #"é" 7 a 'b x] 4 2
		--assert str = "é7abxé7abx"

	--test-- "change-34.4"
		str: "12"
		--assert "" = change/part/dup str next next ["4" #"5" #"^(010000)" 7 a 'b x] 4 2
		--assert str = "^(010000)7abx^(010000)7abx"

	--test-- "change-34.5"
		str: "12é"
		--assert "" = change/part/dup str next next ["4" #"5" #"^(010000)" 7 a 'b x] 4 2
		--assert str = "^(010000)7abx^(010000)7abx"

	--test-- "change-34.6"
		str: "12^(010000)"
		--assert "" = change/part/dup str ["4" #"5" #"6" 7 a 'b x] 6 2
		--assert str = "4567abx4567abx"

	--test-- "change-35"
		str: "12"
		--assert "12" = change/part str "456" 0
		--assert str = "45612"

	--test-- "change-36"
		str: "12"
		--assert "12" = change/dup/part str "456" 3 0
		--assert str = "45645645612"

	--test-- "change-36.1"
		str: "12"
		--assert "12" = change/dup/part str "456" 0 0
		--assert str = "12"

	--test-- "change-37"
		str: "12"
		--assert "12" = change/part str "456" -1
		--assert str = "45612"

	--test-- "change-38"
		str: "12"
		--assert "12" = change/dup/part str "456" 3 -1
		--assert str = "45645645612"

	--test-- "change-39"
		str: "12"
		--assert "12" = change/dup str "456" -1
		--assert str = "12"

	--test-- "change-40"
		str: "12"
		--assert "12" = change/dup/part str "456" -1 -1
		--assert str = "12"

	--test-- "change-41"
		str: "12"
		--assert "2" = change/part str "456" 1
		--assert str = "4562"

	--test-- "change-42"
		str: "12"
		--assert "" = change/part str "456" 100000
		--assert str = "456"

	--test-- "change-43"
		str: "12"
		--assert "12" = change/part str <456> 0
		--assert str = "<456>12"

	--test-- "change-44"
		str: "12"
		--assert "2" = change/part str <456> 1
		--assert str = "<456>2"

	--test-- "change-45"
		str: "12"
		--assert "" = change/part str <456> 2
		--assert str = "<456>"

	--test-- "change-46"
		str: "12"
		--assert "" = change/part str <456> 4
		--assert str = "<456>"

	--test-- "change-47"
		str: "12"
		--assert "" = change/part str <456> 5
		--assert str = "<456>"

	--test-- "change-48"
		str: "12"
		--assert "" = change/part str <456> 10
		--assert str = "<456>"

	--test-- "change-49"
		str: "12"
		--assert "" = change/part str next <456> 10
		--assert str = "<56>"

	--test-- "change-49.1"
		str: "12"
		--assert "" = change/part str next <456> 2
		--assert str = "<56>"

	--test-- "change-49.2"
		str: "12"
		--assert "" = change/part/dup str next <456> 10 3
		--assert str = "<56><56><56>"

	--test-- "change-49.3"
		str: "12"
		--assert "" = change/part/dup str next <456> 2 3
		--assert str = "<56><56><56>"

	--test-- "change-49.4"
		str: copy "1234567890000"
		--assert "7890000" = change/dup str #"0" 6
		--assert str = "0000007890000"

	--test-- "change-np1"
		str: next next "1234"
		--assert "34" = change/part str next [9] -1
		--assert (head str) = "134"

	--test-- "change-np2"
		str: next next "1234"
		--assert "34" = change/part str next [9] -2
		--assert (head str) = "34"

	--test-- "change-np3"
		str: next next "1234"
		--assert "34" = change/part str next [9] -100000
		--assert (head str) = "34"

	--test-- "change-np4"
		str: next next "1234"
		--assert "34" = change/part str next [9 99] -2
		--assert (head str) = "9934"

	--test-- "change-np5"
		str: next next "1234"
		--assert "34" = change/part str tail [0 0 0 9 99] -2
		--assert (head str) = "34"

	--test-- "change-np5.3"
		str: next next "1234"
		--assert "34" = change/part/only str tail [0 0 0 9 99] -2
		--assert (head str) = "34"

	--test-- "change-np6"
		str: next next "1234"
		--assert "34" = change/part/dup str next next [5 6 7 8 9] -2 2
		--assert (head str) = "78978934"

;-- ------------------------------------------------------------------------
;-- vector! and binary! first-argument tests (transposed from insert-50..508)
;-- CHANGE results recomputed against the split binary/change & vector/change.
;-- Tests whose /part is a position in the VALUE series are commented out:
;-- CHANGE binds a /part position to the FIRST argument, so those forms error.
;-- ------------------------------------------------------------------------
	--test-- "change-50"
		v: make vector! [1 2 3]
		change v 4
		--assert v = (make vector! [4 2 3])

	--test-- "change-50.1"
		v: next make vector! [1 2 3]
		--assert (make vector! [3]) = change v 4
		--assert (head v) = (make vector! [1 4 3])

	--test-- "change-51"
		v: next next make vector! [1 2 3]
		--assert (make vector! []) = change v [4 5]
		--assert (head v) = (make vector! [1 2 4 5])

	 --test-- "change-52"
		v: next next make vector! []
		change v []
		--assert v = (make vector! [integer! 32 []])

	 --test-- "change-52.1"
		v: next next make vector! [1 2 3]
		--assert (make vector! [3]) = change/part v [] 0
		--assert (make vector! []) = change/part v [] 1
		--assert (make vector! []) = change/part v [] -1
		--assert (make vector! []) = change/dup v [] 0
		--assert (make vector! []) = change/dup v [] 1
		--assert (make vector! []) = change/dup v [] -1
		--assert (make vector! []) = change/dup/part v [] 1 1
		--assert (head v) = (make vector! [1])

	 --test-- "change-53"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change v [5 6]
		--assert (head v) = (make vector! [1 2 5 6])

	 --test-- "change-54"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [3 4]) = change/part v [5 6 7] 0
		--assert (head v) = (make vector! [1 2 5 6 7 3 4])

	 --test-- "change-55"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [3 4]) = change/part v [5 6 7] -1
		--assert (head v) = (make vector! [1 5 6 7 3 4])

	 --test-- "change-56"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [4]) = change/part v [5 6 7] 1
		--assert (head v) = (make vector! [1 2 5 6 7 4])

	 --test-- "change-56.1"
		v: make vector! [1 2 3 4]
		--assert (make vector! [2 3 4]) = change/part v [5 6 7] 1
		--assert (head v) = (make vector! [5 6 7 2 3 4])

	 --test-- "change-57"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/part v [5 6 7] 2
		--assert (head v) = (make vector! [1 2 5 6 7])

	 --test-- "change-58"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/part v [5 6 7] 3
		--assert (head v) = (make vector! [1 2 5 6 7])

	 --test-- "change-59"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/part v [5 6 7] 4
		--assert (head v) = (make vector! [1 2 5 6 7])

	 --test-- "change-60"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/part v [5 6 7] 1000000
		--assert (head v) = (make vector! [1 2 5 6 7])

	 --test-- "change-61"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/dup v -1 3
		--assert (head v) = (make vector! [1 2 -1 -1 -1])

	 --test-- "change-62"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [3 4]) = change/dup v -1 0
		--assert (head v) = (make vector! [1 2 3 4])

	 --test-- "change-63"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [3 4]) = change/dup v -1 -1
		--assert (head v) = (make vector! [1 2 3 4])

	 --test-- "change-64"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [3 4]) = change/dup v [5 6] 0
		--assert (head v) = (make vector! [1 2 3 4])

	 --test-- "change-65"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [3 4]) = change/dup v [5 6] -1
		--assert (head v) = (make vector! [1 2 3 4])

	 --test-- "change-66"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/dup v [5 6] 1
		--assert (head v) = (make vector! [1 2 5 6])

	 --test-- "change-67"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/dup v [5 6] 2
		--assert (head v) = (make vector! [1 2 5 6 5 6])

	 --test-- "change-68"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/dup v [5 6] 10
		--assert (head v) = (make vector! [1 2 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6])

	 --test-- "change-69"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [4]) = change/dup/part v [5 6 7 8 9] 1 1
		--assert (head v) = (make vector! [1 2 5 6 7 8 9 4])

	 --test-- "change-70"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/dup/part v [5 6 7 8 9] 2 2
		--assert (head v) = (make vector! [1 2 5 6 7 8 9 5 6 7 8 9])

	 --test-- "change-71"
		v: next next make vector! [1 2 3 4]
		change/dup/part v [5 6 7 8 9] 2 3
		--assert (head v) = (make vector! [1 2 5 6 7 8 9 5 6 7 8 9])

	 --test-- "change-72"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/dup/part v [5 6 7 8 9] 2 4
		--assert (head v) = (make vector! [1 2 5 6 7 8 9 5 6 7 8 9])

	 --test-- "change-73"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/dup/part v [5 6 7 8 9] 2 5
		--assert (head v) = (make vector! [1 2 5 6 7 8 9 5 6 7 8 9])

	 --test-- "change-74"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/dup/part v [5 6 7 8 9] 2 6
		--assert (head v) = (make vector! [1 2 5 6 7 8 9 5 6 7 8 9])

	 --test-- "change-75"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [4]) = change/part/dup v [5 6 7 8 9] 1 2
		--assert (head v) = (make vector! [1 2 5 6 7 8 9 5 6 7 8 9 4])

	  --test-- "change-76"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! []) = change/part/dup v [5 6 7 8 9] 2 2
		--assert (head v) = (make vector! [1 2 5 6 7 8 9 5 6 7 8 9])

	  --test-- "change-77"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [3 4]) = change/part v next [9] -1
		--assert (head v) = (make vector! [1 3 4])

	  --test-- "change-78"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [3 4]) = change/part v next [9] -2
		--assert (head v) = (make vector! [3 4])

	  --test-- "change-79"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [3 4]) = change/part v next [9] -100000
		--assert (head v) = (make vector! [3 4])

	  --test-- "change-80"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [3 4]) = change/part v next [9 99] -2
		--assert (head v) = (make vector! [99 3 4])

	  --test-- "change-81"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [3 4]) = change/part v tail [0 0 0 9 99] -2
		--assert (head v) = (make vector! [3 4])

	  --test-- "change-82"
		v: next next make vector! [1 2 3 4]
		--assert (make vector! [3 4]) = change/part/dup v next next [5 6 7 8 9] -2 2
		--assert (head v) = (make vector! [7 8 9 7 8 9 3 4])

	 --test-- "change-150"
		v: next next make vector! [integer! 8 [1 2 3]]
		--assert (make vector! [integer! 8 []]) = change v 4
		--assert (head v) = (make vector! [integer! 8 [1 2 4]])

	 --test-- "change-151"
		v: next next make vector! [integer! 8 [1 2 3]]
		--assert (make vector! [integer! 8 []]) = change v [4 5]
		--assert (head v) = (make vector! [integer! 8 [1 2 4 5]])

	 --test-- "change-152"
		v: next next make vector! [integer! 8 []]
		change v []
		--assert (head v) = (make vector! [integer! 8 []])

	 --test-- "change-153"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change v [5 6]
		--assert v = (make vector! [integer! 8 [5 6]])
		--assert (3) = index? v
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6]])

	 --test-- "change-154"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 [3 4]]) = change/part v [5 6 7] 0
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7 3 4]])

	 --test-- "change-155"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 [3 4]]) = change/part v [5 6 7] -1
		--assert (head v) = (make vector! [integer! 8 [1 5 6 7 3 4]])

	 --test-- "change-156"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 [4]]) = change/part v [5 6 7] 1
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7 4]])

	 --test-- "change-156.1"
		v: make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 [2 3 4]]) = change/part v [5 6 7] 1
		--assert (head v) = (make vector! [integer! 8 [5 6 7 2 3 4]])

	 --test-- "change-157"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/part v [5 6 7] 2
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7]])

	 --test-- "change-158"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/part v [5 6 7] 3
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7]])

	 --test-- "change-159"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/part v [5 6 7] 4
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7]])

	 --test-- "change-160"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/part v [5 6 7] 1000000
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7]])

	 --test-- "change-161"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/dup v -1 3
		--assert (head v) = (make vector! [integer! 8 [1 2 -1 -1 -1]])

	 --test-- "change-162"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 [3 4]]) = change/dup v -1 0
		--assert (head v) = (make vector! [integer! 8 [1 2 3 4]])

	 --test-- "change-163"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 [3 4]]) = change/dup v -1 -1
		--assert (head v) = (make vector! [integer! 8 [1 2 3 4]])

	 --test-- "change-164"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 [3 4]]) = change/dup v [5 6] 0
		--assert (head v) = (make vector! [integer! 8 [1 2 3 4]])

	 --test-- "change-165"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 [3 4]]) = change/dup v [5 6] -1
		--assert (head v) = (make vector! [integer! 8 [1 2 3 4]])

	 --test-- "change-166"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/dup v [5 6] 1
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6]])

	 --test-- "change-167"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/dup v [5 6] 2
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 5 6]])

	 --test-- "change-168"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/dup v [5 6] 10
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6]])

	 --test-- "change-169"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 [4]]) = change/dup/part v [5 6 7 8 9] 1 1
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7 8 9 4]])

	 --test-- "change-170"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/dup/part v [5 6 7 8 9] 2 2
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7 8 9 5 6 7 8 9]])

	 --test-- "change-171"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/dup/part v [5 6 7 8 9] 2 3
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7 8 9 5 6 7 8 9]])

	 --test-- "change-172"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/dup/part v [5 6 7 8 9] 2 4
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7 8 9 5 6 7 8 9]])

	 --test-- "change-173"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/dup/part v [5 6 7 8 9] 2 5
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7 8 9 5 6 7 8 9]])

	 --test-- "change-174"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/dup/part v [5 6 7 8 9] 2 6
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7 8 9 5 6 7 8 9]])

	 --test-- "change-175"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 [4]]) = change/part/dup v [5 6 7 8 9] 1 2
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7 8 9 5 6 7 8 9 4]])

	  --test-- "change-176"
		v: next next make vector! [integer! 8 [1 2 3 4]]
		--assert (make vector! [integer! 8 []]) = change/part/dup v [5 6 7 8 9] 2 2
		--assert (head v) = (make vector! [integer! 8 [1 2 5 6 7 8 9 5 6 7 8 9]])


	 --test-- "change-250"
		v: next next make vector! [integer! 16 [1 2 3]]
		--assert (make vector! [integer! 16 []]) = change v 4
		--assert (head v) = (make vector! [integer! 16 [1 2 4]])

	 --test-- "change-251"
		v: next next make vector! [integer! 16 [1 2 3]]
		--assert (make vector! [integer! 16 []]) = change v [4 5]
		--assert (head v) = (make vector! [integer! 16 [1 2 4 5]])

	 --test-- "change-252"
		v: next next make vector! [integer! 16 []]
		change v []
		--assert (head v) = (make vector! [integer! 16 []])

	 --test-- "change-253"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change v [5 6]
		--assert v = (make vector! [integer! 16 [5 6]])
		--assert (3) = index? v
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6]])

	 --test-- "change-254"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 [3 4]]) = change/part v [5 6 7] 0
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7 3 4]])

	 --test-- "change-255"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 [3 4]]) = change/part v [5 6 7] -1
		--assert (head v) = (make vector! [integer! 16 [1 5 6 7 3 4]])

	 --test-- "change-256"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 [4]]) = change/part v [5 6 7] 1
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7 4]])

	 --test-- "change-256.1"
		v: make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 [2 3 4]]) = change/part v [5 6 7] 1
		--assert (head v) = (make vector! [integer! 16 [5 6 7 2 3 4]])

	 --test-- "change-257"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/part v [5 6 7] 2
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7]])

	 --test-- "change-258"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/part v [5 6 7] 3
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7]])

	 --test-- "change-259"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/part v [5 6 7] 4
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7]])

	 --test-- "change-260"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/part v [5 6 7] 1000000
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7]])

	 --test-- "change-261"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/dup v -1 3
		--assert (head v) = (make vector! [integer! 16 [1 2 -1 -1 -1]])

	 --test-- "change-262"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 [3 4]]) = change/dup v -1 0
		--assert (head v) = (make vector! [integer! 16 [1 2 3 4]])

	 --test-- "change-263"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 [3 4]]) = change/dup v -1 -1
		--assert (head v) = (make vector! [integer! 16 [1 2 3 4]])

	 --test-- "change-264"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 [3 4]]) = change/dup v [5 6] 0
		--assert (head v) = (make vector! [integer! 16 [1 2 3 4]])

	 --test-- "change-265"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 [3 4]]) = change/dup v [5 6] -1
		--assert (head v) = (make vector! [integer! 16 [1 2 3 4]])

	 --test-- "change-266"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/dup v [5 6] 1
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6]])

	 --test-- "change-267"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/dup v [5 6] 2
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 5 6]])

	 --test-- "change-268"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/dup v [5 6] 10
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6 5 6]])

	 --test-- "change-269"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 [4]]) = change/dup/part v [5 6 7 8 9] 1 1
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7 8 9 4]])

	 --test-- "change-270"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/dup/part v [5 6 7 8 9] 2 2
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7 8 9 5 6 7 8 9]])

	 --test-- "change-271"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/dup/part v [5 6 7 8 9] 2 3
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7 8 9 5 6 7 8 9]])

	 --test-- "change-272"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/dup/part v [5 6 7 8 9] 2 4
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7 8 9 5 6 7 8 9]])

	 --test-- "change-273"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/dup/part v [5 6 7 8 9] 2 5
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7 8 9 5 6 7 8 9]])

	 --test-- "change-274"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/dup/part v [5 6 7 8 9] 2 6
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7 8 9 5 6 7 8 9]])

	 --test-- "change-275"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 [4]]) = change/part/dup v [5 6 7 8 9] 1 2
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7 8 9 5 6 7 8 9 4]])

	  --test-- "change-276"
		v: next next make vector! [integer! 16 [1 2 3 4]]
		--assert (make vector! [integer! 16 []]) = change/part/dup v [5 6 7 8 9] 2 2
		--assert (head v) = (make vector! [integer! 16 [1 2 5 6 7 8 9 5 6 7 8 9]])


	  --test-- "change-450"
		b: #{010203}
		change b 4
		change b #"A"
		change b #{1122334455}
		change b "A"
		change b "abc"
		change b red
		change b #"é"
		change b "é"
		change b "AéB"
		--assert b = (#{41C3A94255})

	  --test-- "change-450.1"
		b: #{010203}
		--assert (#{}) = change change change change change change change change change b 4 #"A" #{1122334455} "A" "abc" red #"é" "é" "AéB"
		--assert b = (#{0441112233445541616263FF0000C3A9C3A941C3A942})
		
		  --test-- "change-450.2"
		b: #{010203}
		 --assert (#{03}) = change b change b 4
		
	  --test-- "change-451"
		b: #{010203}
		change b [4 5]
		--assert b = (#{040503})

	  --test-- "change-451.1"
		b: next next #{010203}
		--assert (#{}) = change b [4 5]
		--assert (head b) = (#{01020405})

	  --test-- "change-452"
		b: #{}
		change b []
		--assert b = (#{})

	  --test-- "change-452.1"
		b: #{010203}
		change/part b []  0
		change/part b []  1
		change/part b [] -1
		change/dup  b []  0
		change/dup  b []  1
		change/dup  b [] -1
		change/dup/part b [] 1 1
		--assert b = (#{03})

	  --test-- "change-453"
		b: next next #{01020304}
		--assert (#{}) = change b [5 6]
		--assert b = (#{0506})
		--assert (3) = index? b
		--assert (head b) = (#{01020506})

	  --test-- "change-454"
		b: next next #{01020304}
		--assert (#{0304}) = change/part b [5 6 7] 0
		--assert (head b) = (#{01020506070304})

	  --test-- "change-455"
		b: next next #{01020304}
		--assert (#{0304}) = change/part b [5 6 7] -1
		--assert (head b) = (#{010506070304})

	  --test-- "change-456"
		b: next next #{01020304}
		--assert (#{04}) = change/part b [5 6 7] 1
		--assert (head b) = (#{010205060704})

	  --test-- "change-457"
		b: next next #{01020304}
		--assert (#{}) = change/part b [5 6 7] 2
		--assert (head b) = (#{0102050607})

	  --test-- "change-458"
		b: next next #{01020304}
		--assert (#{}) = change/part b [5 6 7] 3
		--assert (head b) = (#{0102050607})

	  --test-- "change-459"
		b: next next #{01020304}
		--assert (#{}) = change/part b [5 6 7] 4
		--assert (head b) = (#{0102050607})

	  --test-- "change-460"
		b: next next #{01020304}
		--assert (#{}) = change/part b [5 6 7] 1000000
		--assert (head b) = (#{0102050607})

	  --test-- "change-461"
		b: next next #{01020304}
		--assert (#{}) = change/dup b -1 3
		--assert (head b) = (#{0102FFFFFF})

	  --test-- "change-462"
		b: next next #{01020304}
		--assert (#{0304}) = change/dup b -1 0
		--assert (head b) = (#{01020304})

	  --test-- "change-463"
		b: next next #{01020304}
		--assert (#{0304}) = change/dup b -1 -1
		--assert (head b) = (#{01020304})

	  --test-- "change-464"
		b: next next #{01020304}
		--assert (#{0304}) = change/dup b [5 6] 0
		--assert (head b) = (#{01020304})

	  --test-- "change-465"
		b: next next #{01020304}
		--assert (#{0304}) = change/dup b [5 6] -1
		--assert (head b) = (#{01020304})

	  --test-- "change-466"
		b: next next #{01020304}
		--assert (#{}) = change/dup b [5 6] 1
		--assert (head b) = (#{01020506})

	  --test-- "change-467"
		b: next next #{01020304}
		--assert (#{}) = change/dup b [5 6] 2
		--assert (head b) = (#{010205060506})

	  --test-- "change-468"
		b: next next #{01020304}
		--assert (#{}) = change/dup b [5 6] 10
		--assert (head b) = (#{01020506050605060506050605060506050605060506})

	  --test-- "change-469"
		b: next next #{01020304}
		--assert (#{04}) = change/dup/part b [5 6 7 8 9] 1 1
		--assert (head b) = (#{0102050607080904})

	  --test-- "change-470"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part b [5 6 7 8 9] 2 2
		--assert (head b) = (#{010205060708090506070809})

	  --test-- "change-471"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part b [5 6 7 8 9] 2 3
		--assert (head b) = (#{010205060708090506070809})

	  --test-- "change-472"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part b [5 6 7 8 9] 2 4
		--assert (head b) = (#{010205060708090506070809})

	  --test-- "change-473"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part b [5 6 7 8 9] 2 5
		--assert (head b) = (#{010205060708090506070809})

	  --test-- "change-474"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part b [5 6 7 8 9] 2 6
		--assert (head b) = (#{010205060708090506070809})

	  --test-- "change-475"
		b: next next #{01020304}
		--assert (#{04}) = change/part/dup b [5 6 7 8 9] 1 2
		--assert (head b) = (#{01020506070809050607080904})

	  --test-- "change-476"
		b: next next #{01020304}
		--assert (#{}) = change/part/dup b [5 6 7 8 9] 2 2
		--assert (head b) = (#{010205060708090506070809})

	  --test-- "change-477"
		values: [#"A" #{1122334455} "A" "abc" 123 255.0.0 #"é" "é" "AéB"]
		;results: [#{41} #{1122334455} #{41} #{616263} #{7B} #{FF0000} #{C3A9} #{C3A9} #{41C3A942}]
		results: #{411122334455416162637BFF0000C3A9C3A941C3A942}

		b: next next #{01020304}
		--assert (#{0304}) = change/part b values 0
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A9420304})

	  --test-- "change-478"
		b: next next #{01020304}
		--assert (#{04}) = change/part b values 1
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A94204})

	  --test-- "change-479"
		b: next next #{01020304}
		--assert (#{}) = change b values
		--assert (3) = index? b
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A942})

	  --test-- "change-480"
		b: next next #{01020304}
		--assert (#{0304}) = change/part b values 0
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A9420304})

	  --test-- "change-481"
		b: next next #{01020304}
		--assert (#{0304}) = change/part b values -1
		--assert (head b) = (#{01411122334455416162637BFF0000C3A9C3A941C3A9420304})

	  --test-- "change-482"
		b: next next #{01020304}
		--assert (#{04}) = change/part b values 1
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A94204})

	  --test-- "change-483"
		b: next next #{01020304}
		--assert (#{}) = change/part b values 2
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A942})

	  --test-- "change-483.1"
		b: next next #{01020304}
		--assert (#{}) = change/part/only b values 2
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A942})

	  --test-- "change-484"
		b: next next #{01020304}
		--assert (#{}) = change/part b values 3
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A942})

	  --test-- "change-484.1"
		b: next next #{01020304}
		--assert (#{}) = change/part/only b values 3
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A942})

	  --test-- "change-485"
		b: next next #{01020304}
		--assert (#{}) = change/part b values 4
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A942})

	  --test-- "change-486"
		b: next next #{01020304}
		--assert (#{}) = change/part b values 1000000
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A942})

	  --test-- "change-487"
		b: next next #{01020304}
		--assert (#{0304}) = change/dup b values 0
		--assert (head b) = (#{01020304})

	  --test-- "change-488"
		b: next next #{01020304}
		--assert (#{0304}) = change/dup b values -1
		--assert (head b) = (#{01020304})

	  --test-- "change-489"
		b: next next #{01020304}
		--assert (#{}) = change/dup b values 1
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A942})

	  --test-- "change-490"
		b: next next #{01020304}
		--assert (#{}) = change/dup b values 2
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

	  --test-- "change-491"
		b: next next #{01020304}
		--assert (#{}) = change/dup b values 10
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000C3A9C3A9
    41C3A942411122334455416162637BFF0000C3A9C3A941C3A942411122334455
    416162637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000C3A9
    C3A941C3A942411122334455416162637BFF0000C3A9C3A941C3A94241112233
    4455416162637BFF0000C3A9C3A941C3A942411122334455416162637BFF0000
    C3A9C3A941C3A942411122334455416162637BFF0000C3A9C3A941C3A942
})

	  --test-- "change-492"
		b: next next #{01020304}
		--assert (#{04}) = change/dup/part b values 1 1
		--assert (head b) = (#{0102411122334455416162637BFF0000C3A9C3A941C3A94204})

	  --test-- "change-493"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part b values 2 2
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

	  --test-- "change-493.1"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part/only b values 2 2
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

	  --test-- "change-494"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part b values 2 3
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

	  --test-- "change-494.1"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part/only b values 2 3
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

	  --test-- "change-495"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part b values 2 4
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

	  --test-- "change-495.1"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part/only b values 2 4
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

	  --test-- "change-496"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part b values 2 5
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

	  --test-- "change-496.1"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part/only b values 2 5
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

	  --test-- "change-497"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part b values 2 6
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

	  --test-- "change-497.1"
		b: next next #{01020304}
		--assert (#{}) = change/dup/part/only b values 2 6
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

	  --test-- "change-498"
		b: next next #{01020304}
		--assert (#{04}) = change/part/dup b values 1 2
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A94204
})

	  --test-- "change-498.1"
		b: next next #{01020304}
		--assert (#{04}) = change/part/dup/only b values 1 2
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A94204
})

	  --test-- "change-499"
		b: next next #{01020304}
		--assert (#{}) = change/part/dup b values 2 2
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

	   --test-- "change-499.1"
		b: next next #{01020304}
		--assert (#{}) = change/part/dup/only b values 2 2
		--assert (head b) = (#{
    0102411122334455416162637BFF0000C3A9C3A941C3A9424111223344554161
    62637BFF0000C3A9C3A941C3A942
})

		--test-- "change-500"							;@@ undefined semantics, just checks that it doesn't crash
		b: next next #{01020304}
		change b b
		;--assert b == #{0102030401020304}

		--test-- "change-501"							;@@ undefined semantics, just checks that it doesn't crash
		b: next next #{01020304}
		change/part b b 1
		;--assert b == #{0102030401}

		--test-- "change-502"							;@@ undefined semantics, just checks that it doesn't crash
		b: next next #{01020304}
		change/part b b 2
		;--assert b == #{010203040102}

		--test-- "change-503"							;@@ undefined semantics, just checks that it doesn't crash
		b: next next #{01020304}
		change/part/dup b b 2 2 
		;--assert b == #{0102030401020102}

		--test-- "change-504"							;@@ undefined semantics, just checks that it doesn't crash
		b: next next #{01020304}
		change/part/dup b b 10 2
		;--assert b == #{010203040102030401020304}

		--test-- "change-505"							;@@ undefined semantics, just checks that it doesn't crash
		b: next next #{01020304}
		change/part/dup/only b b 2 2
		;--assert b == #{0102030401020102}

		--test-- "change-506"							;@@ undefined semantics, just checks that it doesn't crash
		b: next next #{01020304}
		change/part/dup/only b b 10 2
		;--assert b == #{010203040102030401020304}

		--test-- "change-507"							;@@ undefined semantics, just checks that it doesn't crash
		b: next next #{01020304}
		change/part/dup b reduce [b b b] 2 2
		;--assert b == #{010203040102030401020304}

		--test-- "change-508"							;@@ undefined semantics, just checks that it doesn't crash
		b: next next #{01020304}
		change/part/dup/only b reduce [b b b] 10 2
		;--assert b == #{010203040102030401020304}

===end-group===

===start-group=== "change/dup"

	--test-- "change/dup1"
		id1-s: copy ""
		change/dup id1-s #" " 10
		--assert 10 = length? id1-s
		--assert "          " = id1-s

	--test-- "change/dup2"
		id2-s: copy ""
		change/dup id2-s #"1" 9
		--assert 9 = length? id2-s
		--assert "111111111" = id2-s

	--test-- "change/dup3"
		id3-b: copy []
		change/dup id3-b 1 8
		--assert 8 = length? id3-b
		--assert [1 1 1 1 1 1 1 1] = id3-b

	--test-- "change/dup4"
		id4-s: copy " "
		change/dup id4-s #" " 10
		--assert 10 = length? id4-s
		--assert "          " = id4-s

	--test-- "change/dup5"
		hash: make hash! [a b c 1 2 3]
		change/dup hash [x y] 2
		--assert 'y = select hash 'x
		--assert 3  = select hash 2
===end-group===

===start-group=== "change not at head"

	--test-- "change-not-at-head1"
		inah1-b: copy [1 2 3 4]
		change next next inah1-b 'two&half
		--assert [1 2 two&half 4] = head inah1-b

	--test-- "change-not-at-head2"
		inah2-s: copy "1234"
		change next next inah2-s "2.5"
		--assert "122.5" = head inah2-s

	--test-- "change-not-at-head3"
		inah3-s: copy "1234"
		change next next inah3-s "^(2345)"
		--assert "12^(2345)4" = head inah3-s

	--test-- "change-not-at-head4"
		inah4-s: copy "1234^(2345)"
		change next next inah4-s "2.5"
		--assert "122.5" = head inah4-s

	--test-- "change-not-at-head5"
		inah5-s: copy "1234"
		change next next inah5-s "^(010000)"
		--assert "12^(010000)4" = head inah5-s

	--test-- "change-not-at-head6"
		inah6-s: copy "1234^(010000)"
		change next next inah6-s "2.5"
		--assert "122.5" = head inah6-s

	--test-- "change-not-at-head7"
		inah7-s: copy "1234^(010000)"
		change next next inah7-s "^(2345)"
		--assert "12^(2345)4^(010000)" = head inah7-s

	--test-- "change-not-at-head8"
		inah8-s: copy "1234^(2345)"
		change next next inah8-s "^(010000)"
		--assert "12^(010000)4^(2345)" = head inah8-s

	--test-- "change-not-at-head9"
		inah9-s: copy "1234"
		change next next inah9-s #"5"
		--assert "1254" = head inah9-s

	--test-- "change-not-at-head10"
		inah10-s: copy "1234"
		change next next inah10-s #"^(2345)"
		--assert "12^(2345)4" = head inah10-s

	--test-- "change-not-at-head11"
		inah11-s: copy "1234^(2345)"
		change next next inah11-s #"5"
		--assert "1254^(2345)" = head inah11-s

	--test-- "change-not-at-head12"
		inah12-s: copy "1234"
		change next next inah12-s #"^(010000)"
		--assert "12^(010000)4" = head inah12-s

	--test-- "change-not-at-head13"
		inah13-s: copy "1234^(010000)"
		change next next inah13-s #"5"
		--assert "1254^(010000)" = head inah13-s

	--test-- "change-not-at-head14"
		inah14-s: copy "1234^(010000)"
		change next next inah14-s #"^(2345)"
		--assert "12^(2345)4^(010000)" = head inah14-s

	--test-- "change-not-at-head15"
		inah15-s: copy "1234^(2345)"
		change next next inah15-s #"^(010000)"
		--assert "12^(010000)4^(2345)" = head inah15-s

	--test-- "change/change-not-at-head16"
		hash: make hash! [a b c 1 2 3]
		change skip hash 3 [x y]
		--assert 'b = select hash 'a
		--assert 'y = select hash 'x
===end-group===

===start-group=== "change at tail"

	--test-- "change-at-tail1"
		inat1-b: copy [1 2 3 4]
		change tail inat1-b 'two&half
		--assert [1 2 3 4 two&half] = head inat1-b

	--test-- "change-at-tail2"
		inat2-s: copy "1234"
		change tail inat2-s "2.5"
		--assert "12342.5" = head inat2-s

	--test-- "change-at-tail3"
		inat3-s: copy "1234"
		change tail inat3-s "^(2345)"
		--assert "1234^(2345)" = head inat3-s

	--test-- "change-at-tail4"
		inat4-s: copy "1234^(2345)"
		change tail inat4-s "2.5"
		--assert "1234^(2345)2.5" = head inat4-s

	--test-- "change-at-tail5"
		inat5-s: copy "1234"
		change tail inat5-s "^(010000)"
		--assert "1234^(010000)" = head inat5-s

	--test-- "change-at-tail6"
		inat6-s: copy "1234^(010000)"
		change tail inat6-s "2.5"
		--assert "1234^(010000)2.5" = head inat6-s

	--test-- "change-at-tail7"
		inat7-s: copy "1234^(010000)"
		change tail inat7-s "^(2345)"
		--assert "1234^(010000)^(2345)" = head inat7-s

	--test-- "change-at-tail8"
		inat8-s: copy "1234^(2345)"
		change tail inat8-s "^(010000)"
		--assert "1234^(2345)^(010000)" = head inat8-s

	--test-- "change-at-tail9"
		inat9-s: copy "1234"
		change tail inat9-s #"5"
		--assert "12345" = head inat9-s

	--test-- "change-at-tail10"
		inat10-s: copy "1234"
		change tail inat10-s #"^(2345)"
		--assert "1234^(2345)" = head inat10-s

	--test-- "change-at-tail11"
		inat11-s: copy "1234^(2345)"
		change tail inat11-s #"5"
		--assert "1234^(2345)5" = head inat11-s

	--test-- "change-at-tail12"
		inat12-s: copy "1234"
		change tail inat12-s #"^(010000)"
		--assert "1234^(010000)" = head inat12-s

	--test-- "change-at-tail13"
		inat13-s: copy "1234^(010000)"
		change tail inat13-s #"5"
		--assert "1234^(010000)5" = head inat13-s

	--test-- "change-at-tail14"
		inat14-s: copy "1234^(010000)"
		change tail inat14-s #"^(2345)"
		--assert "1234^(010000)^(2345)" = head inat14-s

	--test-- "change-at-tail15"
		inat15-s: copy "1234^(2345)"
		change tail inat15-s #"^(010000)"
		--assert "1234^(2345)^(010000)" = head inat15-s

	--test-- "change/change-not-at-head16"
		hash: make hash! [a b c 1 2 3]
		change skip hash 3 [x y]
		--assert 'b = select hash 'a
		--assert 'y = select hash 'x

===end-group===

===start-group=== "change reported issues"

	--test-- "cri1 - issue #460"
	--assert "1" = head change "" 1

	--test-- "cri2 - issue #460"
	--assert "a" = head change "" 'a

	--test-- "cri3 - issue #460"
	--assert "abc" = head change "" #abc

	--test-- "cri4 - issue #599"
	--assert "<56ax<56ax" = head change/part/dup "I" ["<" #"5" #"6" a x] 4 2

	--test-- "cri5 - issue #3705"
	--assert 5000 = length? head change/dup #{} #{20} 5000

===end-group===

===start-group=== "change self (value shares the target's buffer)"

	--test-- "change-self-str-1"
		s: copy "12345"
		--assert "12345" = head change s s
	--test-- "change-self-str-2"
		s: copy "12345"
		change/part s s 2
		--assert "12345345" = head s
	--test-- "change-self-str-3"
		s: copy "12345"
		change s next s
		--assert "23455" = head s
	--test-- "change-self-str-4"
		s: copy "12345"
		change/dup s s 2
		--assert "1234512345" = head s

	--test-- "change-self-blk-1"
		b: copy [1 2 3 4 5]
		--assert [1 2 3 4 5] = head change b b
	--test-- "change-self-blk-2"
		b: copy [1 2 3 4 5]
		change/part b b 2
		--assert [1 2 3 4 5 3 4 5] = head b
	--test-- "change-self-blk-3"
		b: copy [1 2 3 4 5]
		change b next b
		--assert [2 3 4 5 5] = head b
	--test-- "change-self-blk-4"
		b: copy [1 2 3 4 5]
		change/dup b b 2
		--assert [1 2 3 4 5 1 2 3 4 5] = head b

	--test-- "change-self-bin-1"
		n: copy #{0102030405}
		--assert #{0102030405} = head change n n
	--test-- "change-self-bin-2"
		n: copy #{0102030405}
		change/part n n 2
		--assert #{0102030405030405} = head n
	--test-- "change-self-bin-3"
		n: copy #{0102030405}
		change n next n
		--assert #{0203040505} = head n
	--test-- "change-self-bin-4"
		n: copy #{0102030405}
		change/dup n n 2
		--assert #{01020304050102030405} = head n

	--test-- "change-self-vec-1"
		v: make vector! [1 2 3 4 5]
		--assert (make vector! [1 2 3 4 5]) = head change v v
	--test-- "change-self-vec-2"
		v: make vector! [1 2 3 4 5]
		change/part v v 2
		--assert (make vector! [1 2 3 4 5 3 4 5]) = head v
	--test-- "change-self-vec-3"
		v: make vector! [1 2 3 4 5]
		change v next v
		--assert (make vector! [2 3 4 5 5]) = head v

	;-- reported bug: /part on a skipped target with the whole series as value (NUL corruption)
	--test-- "change-self-str-5"
		a: copy "[......]"
		change/part (skip a 2) a 2
		--assert "[.[......]...]" = head a
	--test-- "change-self-str-5b"
		a: make string! 20
		append a "12345678"
		change/part (skip a 2) a 2
		--assert "12123456785678" = head a
	--test-- "change-self-blk-5"
		b: copy [1 2 3 4 5 6 7 8]
		change/part (skip b 2) b 2
		--assert [1 2 1 2 3 4 5 6 7 8 5 6 7 8] = head b
	--test-- "change-self-bin-5"
		n: copy #{0102030405060708}
		change/part (skip n 2) n 2
		--assert #{0102010203040506070805060708} = head n
	--test-- "change-self-vec-5"
		v: make vector! [1 2 3 4 5 6 7 8]
		change/part (skip v 2) v 2
		--assert (make vector! [1 2 1 2 3 4 5 6 7 8 5 6 7 8]) = head v

	;-- self /dup forcing the expand path
	--test-- "change-self-str-6"
		s: copy "abc"
		change/dup s s 20
		--assert 60 = length? head s
		--assert (head s) = head insert/dup copy "" "abc" 20
	--test-- "change-self-bin-6"
		n: copy #{0102}
		change/dup n n 20
		--assert 40 = length? head n

	;-- reported case: value slice OVERLAPS the shift destination (value = next self, inserted at head)
	--test-- "change-self-str-7"
		a: copy "123"
		change/part a next a 0
		--assert "23123" = head a
	--test-- "change-self-str-7b"					;-- the exact reported form (/part range as a position)
		a: copy "123"
		change/part a next a a
		--assert "23123" = head a
	--test-- "change-self-blk-7"
		b: copy [1 2 3]
		change/part b next b 0
		--assert [2 3 1 2 3] = head b
	--test-- "change-self-bin-7"
		n: copy #{010203}
		change/part n next n 0
		--assert #{0203010203} = head n
	--test-- "change-self-vec-7"
		v: make vector! [1 2 3]
		change/part v next v 0
		--assert (make vector! [2 3 1 2 3]) = head v

	;-- KNOWN LIMITATION (in-place, no temp): when the value is a self PARTIAL slice that straddles the
	;-- removed-region boundary AND the target head precedes the value head, the value becomes non-contiguous
	;-- after the shift, so a single copy can't rebuild it (yields "acdeeef" instead of "acdefef").
	;-- Also wrong in the pre-split _series/change. Closing it needs a two-part copy or a targeted temp.
	;	--test-- "change-self-straddle"
	;		s: copy "abcdef"
	;		change/part (skip s 1) (at s 3) 3
	;		--assert "acdefef" = head s

===end-group===

~~~end-file~~~
