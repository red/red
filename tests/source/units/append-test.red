Red [
	Title:   "Red append test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %append-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "append"

===start-group=== "append"
  --test-- "append-1"
  --assert 6 = last append [1 2 3 4 5] 6
  --test-- "append-2"
  --assert 6 = last append [1 2 3 4] [5 6]
  --assert 4 = fourth append [1 2 3 4] [5 6]
  --assert 5 = fifth append [1 2 3 4] [5 6]
  --test-- "append-3"
  --assert 55 = last append "12345" "67"
  --test-- "append-4"
  --assert 233 = last append "abcde" "é" ;; utf-8 C3 A9
  --test-- "append-5"
  --assert 49 = last append "abcdeé" "1" ;; utf-8 C3 A9
  --test-- "append-6"
  --assert 10000 = last append "abcde" "✐"
  --test-- "append-7"
  --assert 48 = last append "abcde^(2710)" "0"
  --test-- "append-8"
  --assert 10000 = last append "abcdeé" "^(2710)"
  --test-- "append-9"
  --assert 233 = last append "abcde^(2710)" "é"
  --test-- "append-10"
  --assert 65536 = last append "abcde" "^(010000)"   
  --test-- "append-11"
  --assert 48 = last append "abcde^(010000)" "0"
  --test-- "append-12"
  --assert 65536 = last append "abcde^(2710)é" "^(010000)" 
  
  --test-- "append-13"
	blk: make block! 1
	append blk 'x/y
	append/only blk  'r/s
	--assert "[x y r/s]" = mold blk

  --test-- "append-14"
	blk: [1 2]
	append/dup/part blk [4 5 6] 3 2
	--assert "[1 2 4 5 4 5 4 5]" = mold blk
	
  --test-- "append-15"
	blk: [1 2]
	append/dup/part blk [4 5 6] 2 3
	--assert "[1 2 4 5 6 4 5 6]" = mold blk	

  --test-- "append-16"
	str: "12"
	append/dup/part str "456" 3 2 
	--assert str = "12454545"

  --test-- "append-17"
	str: "12"
	append/part/dup str "456" 3 2 
	--assert str = "12456456"

  --test-- "append-18"
	str: "12"
	append/part/dup str ["4" #"5" #"6" 7 a 'b x] 6 2
	--assert str = "124567ab4567ab"
===end-group===

===start-group=== "append/dup"
	
	--test-- "append/dup1"
		ad1-s: copy ""
		append/dup ad1-s #" " 10
	--assert 10 = length? ad1-s
	--assert "          " = ad1-s
	
	--test-- "append/dup2"
		ad2-s: copy ""
		append/dup ad2-s #"1" 9

	--assert 9 = length? ad2-s
	--assert "111111111" = ad2-s
	
	--test-- "append/dup2"
		ad3-s: copy []
		append/dup ad3-s 1 8
	--assert 8 = length? ad3-s
	--assert [1 1 1 1 1 1 1 1] = ad3-s
	
	--test-- "append/dup4"
		ad4-s: copy " "
		append/dup ad4-s #" " 10
	--assert 11 = length? ad4-s
	--assert "           " = ad4-s
;; this test is premature before the introduction of a garbage collector
comment { 	
	--test-- "append/dup5"
		ad5-s: copy " "
		append/dup ad5-s #" " 2147483647
	--assert 2147483647 = length? ad5-s
}
===end-group===

;; these tests are premature before the introduction of a garbage collector
comment { 
===start-group=== "big strings" 
	
	--test-- "bg1"
		bg1-s: copy ""
		loop 2147483647 [
			append bg1-s #"a"
		]
	--assert 2147483647 = length? bg1-s
		clear bg1-s
	
	--test-- "bg2"
		bg2-s: copy ""
		loop 2147483647 [
			append bg2-s #"é"
		]
	--assert 2147483647 = length? bg2-s
		clear bg2-s
	
	--test-- "bg3"
		bg3-s: copy ""
		loop 2147483647 [
			append bg3-s #"✐"
		]
	--assert 2147483647 = length? bg3-s
		clear bg3-s
	
		--test-- "bg4"
		bg4-s: copy ""
		loop 2147483647 [
			append bg4-s #"^(2710)"
		]
	--assert 2147483647 = length? bg4-s
		clear bg4-s
		
===end-group===
}

~~~end-file~~~

