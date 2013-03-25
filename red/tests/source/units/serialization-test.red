Red [
	Title:   "Red serialization (MOLD/FORM) test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %serialization-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

~~~start-file~~~ "serialization"

blk: [
	1 #[none] #[true] #[false] #"c" "red" Red a/b 'a/b :a/b a/b: (1 + 2)
	[a] [[[]]] [[[a]]] [c [d [b] e] f] :w 'w w: /w :word 'word word: /word
]

molded: {[1 none true false #"c" "red" Red a/b 'a/b :a/b a/b: (1 + 2) [a] [[[]]] [[[a]]] [c [d [b] e] f] :w 'w w: /w :word 'word word: /word]}
formed: {1 none true false c red Red a/b 'a/b :a/b a/b: 1 + 2 a a c d b e f w w w w word word word word}

===start-group=== "Basic MOLD tests"

	--test-- "mold-1"
	--assert "[]" = mold []
	
	--test-- "mold-2"
	--assert "" = mold/only []
	
	--test-- "mold-3"
	--assert "[1 2 3]" = mold [1 2 3]

	--test-- "mold-4"
	--assert "1 2 3" = mold/only [1 2 3]

	--test-- "mold-5"
	--assert molded = mold blk
	
	--test-- "mold-6"
	repeat i 132 [
		--assert (copy/part molded i) = mold/part blk i
	]
	
===end-group===

===start-group=== "Basic FORM tests"

	--test-- "form-1"
	--assert "" = form []
	
	--test-- "form-2"
	--assert "1 2 3" = form [1 2 3]

	--test-- "form-3"
	--assert formed	= form blk
	
	--test-- "form-4"
	repeat i 132 [
		--assert (copy/part formed i) = form/part blk i
	]
	
	--test-- "form-5"
	--assert "a a" = form [[""] [a] [] [a] [[[]]]]
	
===end-group===

===start-group=== "mold strings"
	--test-- "mold-string-1"
	--assert {"abcde"} = mold {abcde}
	--test-- "mold-string-2"
	--assert {"^^(3A7)^^(3B1)^^(1FD6)^^(3C1)^^(3B5), ^^(3BA)^^(3CC)^^(3C3)^^(3BC)^^(3B5)"} = mold "Χαῖρε, κόσμε"
===end-group===

~~~end-file~~~

