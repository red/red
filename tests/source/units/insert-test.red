Red [
	Title:   "Red insert test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %insert-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "insert"

===start-group=== "insert"
	--test-- "insert-1"
	--assert 6 = first head insert [1 2 3 4 5] 6
	--assert [1 2 3 4 5] = insert [1 2 3 4 5] 6
	--test-- "insert-2"
	--assert 5 = first head insert [1 2 3 4] [5 6]
	--assert [1 2 3 4] = insert [1 2 3 4] [5 6]
	--assert [5 6 1 2 3 4] = head insert [1 2 3 4] [5 6]
	--test-- "insert-3"
	--assert "12345" = insert "12345" "67"
	--assert "6712345" = head insert "12345" "67"
	--test-- "insert-4"
	--assert "abcdeé" = head insert tail "abcde" "é"   	;; utf-8 C3 A9
	--assert "é" = back insert tail "abcde" "é" 			;; utf-8 C3 A9
	--assert #"é" = first back insert tail "abcde" "é"
	--test-- "insert-5"
	--assert 49 = first head insert "abcdeé" "1" ;; utf-8 C3 A9
	--test-- "insert-6"
	--assert 10000 = first head insert "abcde" "✐"
	--assert 10000 = first head insert "abcde" #"✐"
	--test-- "insert-7"
	--assert #"0" = first head insert "abcde^(2710)" "0"
	--assert #"0" = first head insert "abcde^(2710)" #"0"
	--assert #"^(2710)" = last insert "abcde^(2710)" "0"
	--test-- "insert-8"
	--assert 10000 = first head insert "abcdeé" "^(2710)"
	--assert 10000 = first head insert "abcdeé" #"^(2710)"
	--test-- "insert-9"
	--assert 233 = first head insert "abcde^(2710)" "é"
	--assert 233 = first head insert "abcde^(2710)" #"é"
	--test-- "insert-10"
	--assert 65536 = first head insert "abcde" "^(010000)"
	--assert 65536 = first head insert "abcde" #"^(010000)" 
	--test-- "insert-11"
	--assert 48 = first head insert "abcde^(010000)" "0"
	--assert 48 = first head insert "abcde^(010000)" #"0"
	--test-- "insert-12"
	--assert 65536 = first head insert "abcde^(2710)é" "^(010000)" 
	--assert 65536 = first head insert "abcde^(2710)é" #"^(010000)"
	--test-- "insert-13"
		blk: make block! 1
		insert blk 'x/y
		insert/only blk 'r/s
	--assert "[r/s x y]" = mold blk
	--test-- "insert-14"
		blk: [1 2]
		insert/dup/part blk [4 5 6] 3 2
	--assert "[4 5 4 5 4 5 1 2]" = mold blk
	--test-- "insert-15"
		blk: [1 2]
		insert/dup/part blk [4 5 6] 2 3
	--assert "[4 5 6 4 5 6 1 2]" = mold blk	
	--test-- "insert-16"
		str: "12"
		insert/dup/part str "456" 3 2 
	--assert str = "45454512"
	--test-- "insert-17"
		str: "12"
		insert/part/dup str "456" 3 2 
	--assert str = "45645612"
	--test-- "insert-18"
		hash: make hash! [a b c 1 2 3]
		insert hash [x y]
	--assert 'y = select hash 'x
	--assert 2  = select hash 1
	--test-- "insert-19"
		b: next a: [1 2 3]
		insert/part c: [] a b
	--assert [1] = c
	--test-- "insert-20"
		b: next a: "123"
		insert/part c: "" a b
	--assert "1" = c
===end-group===

===start-group=== "insert/dup"

	--test-- "insert/dup1"
		id1-s: copy ""
		insert/dup id1-s #" " 10
	--assert 10 = length? id1-s
	--assert "          " = id1-s
	
	--test-- "insert/dup2"
		id2-s: copy ""
		insert/dup id2-s #"1" 9
	--assert 9 = length? id2-s
	--assert "111111111" = id2-s
	
	--test-- "insert/dup3"
		id3-b: copy []
		insert/dup id3-b 1 8
	--assert 8 = length? id3-b
	--assert [1 1 1 1 1 1 1 1] = id3-b
	
	--test-- "insert/dup4"
		id4-s: copy " "
		insert/dup id4-s #" " 10
	--assert 11 = length? id4-s
	--assert "           " = id4-s

	--test-- "insert/dup5"
		hash: make hash! [a b c 1 2 3]
		insert/dup hash [x y] 2
	--assert 'y = select hash 'x
	--assert 2  = select hash 1
===end-group===

===start-group=== "insert not at head"

	--test-- "insert-not-at-head1"
		inah1-b: copy [1 2 3 4]
		insert next next inah1-b 'two&half 
	--assert [1 2 two&half 3 4] = head inah1-b
	
	--test-- "insert-not-at-head2"
		inah2-s: copy "1234"
		insert next next inah2-s "2.5" 
	--assert "122.534" = head inah2-s
	
	--test-- "insert-not-at-head3"
		inah3-s: copy "1234"
		insert next next inah3-s "^(2345)" 
	--assert "12^(2345)34" = head inah3-s
	
	--test-- "insert-not-at-head4"
		inah4-s: copy "1234^(2345)"
		insert next next inah4-s "2.5" 
	--assert "122.534^(2345)" = head inah4-s
	
	--test-- "insert-not-at-head5"
		inah5-s: copy "1234"
		insert next next inah5-s "^(010000)" 
	--assert "12^(010000)34" = head inah5-s
	
	--test-- "insert-not-at-head6"
		inah6-s: copy "1234^(010000)"
		insert next next inah6-s "2.5" 
	--assert "122.534^(010000)" = head inah6-s
	
	--test-- "insert-not-at-head7"
		inah7-s: copy "1234^(010000)"
		insert next next inah7-s "^(2345)" 
	--assert "12^(2345)34^(010000)" = head inah7-s
	
	--test-- "insert-not-at-head8"
		inah8-s: copy "1234^(2345)"
		insert next next inah8-s "^(010000)" 
	--assert "12^(10000)34^(02345)" = head inah8-s
	
	--test-- "insert-not-at-head9"
		inah9-s: copy "1234"
		insert next next inah9-s #"5" 
	--assert "12534" = head inah9-s
	
	--test-- "insert-not-at-head10"
		inah10-s: copy "1234"
		insert next next inah10-s #"^(2345)" 
	--assert "12^(2345)34" = head inah10-s
	
	--test-- "insert-not-at-head11"
		inah11-s: copy "1234^(2345)"
		insert next next inah11-s #"5" 
	--assert "12534^(2345)" = head inah11-s
	
	--test-- "insert-not-at-head12"
		inah12-s: copy "1234"
		insert next next inah12-s #"^(010000)" 
	--assert "12^(010000)34" = head inah12-s
	
	--test-- "insert-not-at-head13"
		inah13-s: copy "1234^(010000)"
		insert next next inah13-s #"5" 
	--assert "12534^(010000)" = head inah13-s
	
	--test-- "insert-not-at-head14"
		inah14-s: copy "1234^(010000)"
		insert next next inah14-s #"^(2345)" 
	--assert "12^(2345)34^(010000)" = head inah14-s
	
	--test-- "insert-not-at-head15"
		inah15-s: copy "1234^(2345)"
		insert next next inah15-s #"^(010000)" 
	--assert "12^(10000)34^(02345)" = head inah15-s

	--test-- "insert/insert-not-at-head16"
		hash: make hash! [a b c 1 2 3]
		insert skip hash 3 [x y]
	--assert 'b = select hash 'a
	--assert 'y = select hash 'x
	--assert 2  = select hash 1	
===end-group===

===start-group=== "insert at tail"

	--test-- "insert-at-tail1"
		inat1-b: copy [1 2 3 4]
		insert tail inat1-b 'two&half 
	--assert [1 2 3 4 two&half] = head inat1-b
	
	--test-- "insert-at-tail2"
		inat2-s: copy "1234"
		insert tail inat2-s "2.5" 
	--assert "12342.5" = head inat2-s
	
	--test-- "insert-at-tail3"
		inat3-s: copy "1234"
		insert tail inat3-s "^(2345)" 
	--assert "1234^(2345)" = head inat3-s
	
	--test-- "insert-at-tail4"
		inat4-s: copy "1234^(2345)"
		insert tail inat4-s "2.5" 
	--assert "1234^(2345)2.5" = head inat4-s
	
	--test-- "insert-at-tail5"
		inat5-s: copy "1234"
		insert tail inat5-s "^(010000)" 
	--assert "1234^(010000)" = head inat5-s
	
	--test-- "insert-at-tail6"
		inat6-s: copy "1234^(010000)"
		insert tail inat6-s "2.5" 
	--assert "1234^(010000)2.5" = head inat6-s
	
	--test-- "insert-at-tail7"
		inat7-s: copy "1234^(010000)"
		insert tail inat7-s "^(2345)" 
	--assert "1234^(010000)^(2345)" = head inat7-s
	
	--test-- "insert-at-tail8"
		inat8-s: copy "1234^(2345)"
		insert tail inat8-s "^(010000)" 
	--assert "1234^(02345)^(10000)" = head inat8-s
	
	--test-- "insert-at-tail9"
		inat9-s: copy "1234"
		insert tail inat9-s #"5" 
	--assert "12345" = head inat9-s
	
	--test-- "insert-at-tail10"
		inat10-s: copy "1234"
		insert tail inat10-s #"^(2345)" 
	--assert "1234^(2345)" = head inat10-s
	
	--test-- "insert-at-tail11"
		inat11-s: copy "1234^(2345)"
		insert tail inat11-s #"5" 
	--assert "1234^(2345)5" = head inat11-s
	
	--test-- "insert-at-tail12"
		inat12-s: copy "1234"
		insert tail inat12-s #"^(010000)" 
	--assert "1234^(010000)" = head inat12-s
	
	--test-- "insert-at-tail13"
		inat13-s: copy "1234^(010000)"
		insert tail inat13-s #"5" 
	--assert "1234^(010000)5" = head inat13-s
	
	--test-- "insert-at-tail14"
		inat14-s: copy "1234^(010000)"
		insert tail inat14-s #"^(2345)" 
	--assert "1234^(010000)^(2345)" = head inat14-s
	
	--test-- "insert-at-tail15"
		inat15-s: copy "1234^(2345)"
		insert tail inat15-s #"^(010000)" 
	--assert "1234^(02345)^(10000)" = head inat15-s

	--test-- "insert/insert-not-at-head16"
		hash: make hash! [a b c 1 2 3]
		insert skip hash 3 [x y]
	--assert 'b = select hash 'a
	--assert 'y = select hash 'x
	--assert 2  = select hash 1	
===end-group===

===start-group=== "insert reported issues"

	--test-- "iri1 - issue #460"
	--assert "1" = head insert "" 1
	
	--test-- "iri2 - issue #460"
	--assert "a" = head insert "" 'a
	
	--test-- "iri3 - issue #460"
	--assert "abc" = head insert "" #abc
	
	--test-- "iri4 - issue #599"
	--assert "<56a<56aI" = head insert/part/dup "I" ["<" #"5" #"6" a x] 4 2

===end-group===

~~~end-file~~~

