Red [
	Title:   "Red find test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %find-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

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
	--assert "12345" = find "12345" 1
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
	--assert "✐" = "abcde✐" "✐"            ;; code point 10000 (decimal)
	--test-- "find-23"
	--assert none = "abcde✐" "ed✐"
	--test-- "find-24"
	--assert "^(010000)" = find "abcde^(010000)" "^(010000)"   
===end-group===

~~~end-file~~~

