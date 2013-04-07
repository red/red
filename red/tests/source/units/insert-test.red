Red [
	Title:   "Red insert test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %insert-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

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
	--assert 10000 = first insert insert "abcde" "✐"
	--assert 10000 = first insert insert "abcde" #"✐"
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

===end-group===

~~~end-file~~~

