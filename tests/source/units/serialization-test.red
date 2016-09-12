Red [
	Title:   "Red serialization (MOLD/FORM) test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %serialization-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "serialization"

ser-blk: [1 #[none] #[true] #[false] #"c" "red" Red a/b 'a/b :a/b a/b: (1 + 2) [a] [[[]]] [[[a]]] [c [d [b] e] f] :w 'w w: /w :word 'word word: /word]

ser-molded: {[1 none true false #"c" "red" Red a/b 'a/b :a/b a/b: (1 + 2) [a] [[[]]] [[[a]]] [c [d [b] e] f] :w 'w w: /w :word 'word word: /word]}
ser-formed: {1 none true false c red Red a/b 'a/b :a/b a/b: 1 + 2 a  a c d b e f w w w w word word word word}

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
	--assert ser-molded = mold ser-blk
	
	--test-- "mold-6"
		repeat i 24 [
			--assert (copy/part ser-molded i) = mold/part ser-blk i
		]
	
	--test-- "mold-7"
	--assert "[a [b] c]" = mold [a [b] c]	
	
===end-group===

===start-group=== "Basic FORM tests"

	--test-- "form-1"
	--assert "" = form []
	
	--test-- "form-2"
	--assert "1 2 3" = form [1 2 3]

	--test-- "form-3"
	--assert ser-formed	= form ser-blk
	
	--test-- "form-4"
	repeat i 24 [
		--assert (copy/part ser-formed i) = form/part ser-blk i
	]
	
	--test-- "form-5"
	--assert " a  a " = form [[""] [a] [] [a] [[[]]]]
	
===end-group===

===start-group=== "mold strings"
	--test-- "mold-string-1"
	--assert {"abcde"} = mold {abcde}
	
	--test-- "mold-string-2"
	--assert {"^^(3A7)^^(3B1)^^(1FD6)^^(3C1)^^(3B5), ^^(3BA)^^(3CC)^^(3C3)^^(3BC)^^(3B5)"} = mold/all "Χαῖρε, κόσμε"
	
	--test-- "mold-string3 #issue 498"
	--assert {{""}} = mold mold {}
	
	--test-- "mold-string4"
	--assert {"abcde"} = mold "abcde"
	
	--test-- "mold-string5"
	--assert {"abc^^(2710)def"} = mold/all "abc✐def"
	
	--test-- "mold-string6"
	--assert {"abc^^(10000)def"} = mold/all "abc^(010000)def"
	
	--test-- "mold-string6"
		--assert {"目录1"} = mold "目录1"
		
	--test-- "mold-string7"
		--assert {"%e录1"} = mold "%e录1"
 
===end-group===

===start-group=== "logic"
	
	--test-- "mold-logic1"
	--assert "true" = mold true
	--assert "false" = mold false
	--assert "none" = mold none

===end-group===

===start-group=== "block"

	--test-- "mold-block1"
	--assert "[a b c d e]" = mold [a b c d e]
	--assert "[b c d e]" = mold next [a b c d e]
	--assert "[c d e]" = mold at [a b c d e ] 3
	--assert "[]" = mold tail [a b c d e]
	
===end-group===

===start-group=== "integer"

	--test-- "mold-integer1"
	--assert "1" = mold 1
	--assert "-1" = mold FFFFFFFFh
	--assert "2147483647" = mold 7FFFFFFFh
	--assert "-2147483648" = mold 80000000h
	--assert "0" = mold 00h
 
===end-group===

===start-group=== "file"

	--test-- "mold-file1"
		--assert "%目录1" = mold %目录1
		
	--test-- "mold-file2"
		--assert "%^^(76EE)^^(5F55)1" = mold/all %目录1

	--test-- "mold-file3"
		--assert "%a%20b" = mold %a%20b

===end-group===

===start-group=== "mold/only"
	--test-- "mold/only-1 issue #458"
	--assert "a [b] c" = mold/only [a [b] c]
	--test-- "mold/only-2"
	--assert {"a"} = mold/only "a"
	--test-- "mold/only-3"
		a: 1
		b: 2
		c: 3
	--assert {3} = mold/only (a (b) c)
	--test-- "mold/only-4"
	--assert "a" = mold/only [a]
	--test-- "mold/only-5"
	--assert "a [b] c [d [e] f] g" = mold/only [a [b] c [d [e] f] g]
===end-group===

===start-group=== "mold/all"
	--test-- "mold/all-1"
		--assert  {"^^(76EE)^^(5F55)1"} = mold/all "目录1"
===end-group===

===start-group=== "dehex"
	--test-- "dehex-1"
		--assert  "a b" = dehex "a%20b"
	--test-- "dehex-2"
		--assert  "a%2目b" = dehex "a%2目b"
	--test-- "dehex-3"
		--assert  "a^@b" = dehex "a%00b"
	--test-- "dehex-4"
		--assert  "a%~b" = dehex "a%~b"
	--test-- "dehex-5"
		--assert  "aβc" = dehex "a%ce%b2c"
	--test-- "dehex-6"
		--assert  "a乱码b" = dehex "a%e4%b9%b1%e7%a0%81b"
	--test-- "dehex-7"
		--assert  "a%ceb2b" = dehex "a%ceb2b"
===end-group===

===start-group=== "to-hex"
	--test-- "to-hex-1"
		--assert  #00000000 = to-hex 0
	--test-- "to-hex-2"
		--assert  #FFFFFFFE = to-hex -2
	--test-- "to-hex-3"
		--assert  #0F = to-hex/size 15 2
===end-group===

~~~end-file~~~
