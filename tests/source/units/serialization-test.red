Red [
	Title:   "Red serialization (MOLD/FORM) test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %serialization-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Red Foundation. All rights reserved."
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

===start-group=== "binary"
	--test-- "binary-1"  --assert "#{}" = mold #{}
	--test-- "binary-2"  --assert "#{}" = form #{}
	--test-- "binary-3"  --assert "#{ABCD}" = mold #{abcd}
	--test-- "binary-4"  --assert "#{ABCD}" = form #{abcd}
	--test-- "binary-5"  --assert "" = mold/part #{deadbeef} -1
	--test-- "binary-6"  --assert "" = mold/part #{deadbeef} 0
	--test-- "binary-7"  --assert "#" = mold/part #{deadbeef} 1
	--test-- "binary-8"  --assert "#{DEADBEEF}" = mold/part #{deadbeef} 11
	--test-- "binary-9"  --assert "#{DEADBEEF}" = mold/part #{deadbeef} 100
	--test-- "binary-10" --assert "" = form/part #{deadbeef} -1
	--test-- "binary-11" --assert "" = form/part #{deadbeef} 0
	--test-- "binary-12" --assert "#" = form/part #{deadbeef} 1
	--test-- "binary-13" --assert "#{DEADBEEF}" = form/part #{deadbeef} 11
	--test-- "binary-14" --assert "#{DEADBEEF}" = form/part #{deadbeef} 100
	--test-- "binary-15"
		--assert equal?
			rejoin ["#{" newline append/dup "" "DEADBEEF" 8 newline "DEADBEEF" newline "}"]
			mold append/dup #{} #{deadbeef} 9
	--test-- "binary-16"
		--assert equal?
			rejoin ["#{" append/dup "" "DEADBEEF" 10 "}"]
			mold/flat append/dup #{} #{deadbeef} 10
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
		--assert "%^(76EE)^(5F55)1" = mold/all %目录1

	--test-- "mold-file3"
		--assert {%"a b"} = mold %"a b"

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
	--test-- "dehex-8"
		--assert  "a^(80)b" = dehex "a%C2%80b"
===end-group===

===start-group=== "enhex"
	--test-- "enhex-1"
		--assert  "a%20b" = enhex "a b"
	--test-- "enhex-2"
		--assert  "a%252%E7%9B%AEb" = enhex "a%2目b"
	--test-- "enhex-3"
		--assert  "a%00b" = enhex "a^@b"
	--test-- "enhex-4"
		--assert  "a%25~b" = enhex "a%~b"
	--test-- "enhex-5"
		--assert  "a%CE%B2c" = enhex "aβc"
	--test-- "enhex-6"
		--assert  "a%e4%b9%b1%e7%a0%81b" = enhex "a乱码b"
	--test-- "enhex-7"
		--assert  "a%25ceb2b" = enhex "a%ceb2b"
	--test-- "enhex-8"
		--assert  "a%C2%80b" = enhex "a^(80)b"
	--test-- "enhex-9"
		--assert  "https%3A%2F%2Fwww.red-lang.org%2F" = enhex "https://www.red-lang.org/"
	--test-- "enhex-10"
		--assert  "https://www.red-lang.org/%E4%B8%AD%20%E6%96%87" = enhex https://www.red-lang.org/中%20文
		--assert  (mold https://www.red-lang.org/中%20文) = enhex https://www.red-lang.org/中%20文
	--test-- "enhex-11"
		--assert  "/d/%E4%B8%AD%20%E6%96%87" = enhex %/d/中%20文

===end-group===

===start-group=== "to-hex"
	--test-- "to-hex-1"
		--assert  #00000000 = to-hex 0
	--test-- "to-hex-2"
		--assert  #FFFFFFFE = to-hex -2
	--test-- "to-hex-3"
		--assert  #0F = to-hex/size 15 2
	--test-- "to-hex-4"
		--assert #F = to-hex/size 15 1
		--assert error? try [to-hex/size 15 0]
		--assert error? try [to-hex/size 15 -1]
===end-group===

~~~end-file~~~
