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

ser-blk: [1 #(none) #(true) #(false) #"c" "red" Red a/b 'a/b :a/b a/b: (1 + 2) [a] [[[]]] [[[a]]] [c [d [b] e] f] :w 'w w: /w :word 'word word: /word]

ser-molded: {[1 none true false #"c" "red" Red a/b 'a/b :a/b a/b: (1 + 2) [a] [[[]]] [[[a]]] [c [d [b] e] f] :w 'w w: /w :word 'word word: /word]}
ser-formed: {1 none true false c red Red a/b a/b a/b a/b 1 + 2 a  a c d b e f w w w w word word word word}

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

===start-group=== "mold/part tests"

	do-mold-part: function [seed][
		list: clear []
		log:  clear []
		blk: loop 2 [append/only list seed]
		limit: length? mold blk
		repeat i limit [append log mold/part blk i]
		new-line/all log yes
	]

	--test-- "mp-1"
		--assert (do-mold-part #{AB12}) == [
		    "["
		    "[#"
		    "[#{"
		    "[#{A"
		    "[#{AB"
		    "[#{AB1"
		    "[#{AB12"
		    "[#{AB12}"
		    "[#{AB12} "
		    "[#{AB12} #"
		    "[#{AB12} #{"
		    "[#{AB12} #{A"
		    "[#{AB12} #{AB"
		    "[#{AB12} #{AB1"
		    "[#{AB12} #{AB12"
		    "[#{AB12} #{AB12}"
		    "[#{AB12} #{AB12}]"
		]
	--test-- "mp-2"
		--assert (do-mold-part [a b c]) == [
		    "["
		    "[["
		    "[[a"
		    "[[a "
		    "[[a b"
		    "[[a b "
		    "[[a b c"
		    "[[a b c]"
		    "[[a b c] "
		    "[[a b c] ["
		    "[[a b c] [a"
		    "[[a b c] [a "
		    "[[a b c] [a b"
		    "[[a b c] [a b "
		    "[[a b c] [a b c"
		    "[[a b c] [a b c]"
		    "[[a b c] [a b c]]"
		]
	--test-- "mp-3"
		--assert (do-mold-part #"A") == [
		    "["
		    "[#"
		    {[#"}
		    {[#"A}
		    {[#"A"}
		    {[#"A" }
		    {[#"A" #}
		    {[#"A" #"}
		    {[#"A" #"A}
		    {[#"A" #"A"}
		    {[#"A" #"A"]}
		]
	--test-- "mp-4"
		--assert (do-mold-part #"^(20AC)") == [
		    "["
		    "[#"
		    {[#"}
		    {[#"€}
		    {[#"€"}
		    {[#"€" }
		    {[#"€" #}
		    {[#"€" #"}
		    {[#"€" #"€}
		    {[#"€" #"€"}
		    {[#"€" #"€"]}
		]
	--test-- "mp-5"
		--assert (do-mold-part 17/02/2022) == [
		    "["
		    "[1"
		    "[17"
		    "[17-"
		    "[17-F"
		    "[17-Fe"
		    "[17-Feb"
		    "[17-Feb-"
		    "[17-Feb-2"
		    "[17-Feb-20"
		    "[17-Feb-202"
		    "[17-Feb-2022"
		    "[17-Feb-2022 "
		    "[17-Feb-2022 1"
		    "[17-Feb-2022 17"
		    "[17-Feb-2022 17-"
		    "[17-Feb-2022 17-F"
		    "[17-Feb-2022 17-Fe"
		    "[17-Feb-2022 17-Feb"
		    "[17-Feb-2022 17-Feb-"
		    "[17-Feb-2022 17-Feb-2"
		    "[17-Feb-2022 17-Feb-20"
		    "[17-Feb-2022 17-Feb-202"
		    "[17-Feb-2022 17-Feb-2022"
		    "[17-Feb-2022 17-Feb-2022]"
		]
	--test-- "mp-6"
		--assert (do-mold-part 17/02/2022/1:2:3) == [
		    "["
		    "[1"
		    "[17"
		    "[17-"
		    "[17-F"
		    "[17-Fe"
		    "[17-Feb"
		    "[17-Feb-"
		    "[17-Feb-2"
		    "[17-Feb-20"
		    "[17-Feb-202"
		    "[17-Feb-2022"
		    "[17-Feb-2022/"
		    "[17-Feb-2022/1"
		    "[17-Feb-2022/1:"
		    "[17-Feb-2022/1:0"
		    "[17-Feb-2022/1:02"
		    "[17-Feb-2022/1:02:"
		    "[17-Feb-2022/1:02:0"
		    "[17-Feb-2022/1:02:03"
		    "[17-Feb-2022/1:02:03 "
		    "[17-Feb-2022/1:02:03 1"
		    "[17-Feb-2022/1:02:03 17"
		    "[17-Feb-2022/1:02:03 17-"
		    "[17-Feb-2022/1:02:03 17-F"
		    "[17-Feb-2022/1:02:03 17-Fe"
		    "[17-Feb-2022/1:02:03 17-Feb"
		    "[17-Feb-2022/1:02:03 17-Feb-"
		    "[17-Feb-2022/1:02:03 17-Feb-2"
		    "[17-Feb-2022/1:02:03 17-Feb-20"
		    "[17-Feb-2022/1:02:03 17-Feb-202"
		    "[17-Feb-2022/1:02:03 17-Feb-2022"
		    "[17-Feb-2022/1:02:03 17-Feb-2022/"
		    "[17-Feb-2022/1:02:03 17-Feb-2022/1"
		    "[17-Feb-2022/1:02:03 17-Feb-2022/1:"
		    "[17-Feb-2022/1:02:03 17-Feb-2022/1:0"
		    "[17-Feb-2022/1:02:03 17-Feb-2022/1:02"
		    "[17-Feb-2022/1:02:03 17-Feb-2022/1:02:"
		    "[17-Feb-2022/1:02:03 17-Feb-2022/1:02:0"
		    "[17-Feb-2022/1:02:03 17-Feb-2022/1:02:03"
		    "[17-Feb-2022/1:02:03 17-Feb-2022/1:02:03]"
		]
	--test-- "mp-7"
		--assert (do-mold-part 17/02/2022/1:2:3.4) == [
		    "["
		    "[1"
		    "[17"
		    "[17-"
		    "[17-F"
		    "[17-Fe"
		    "[17-Feb"
		    "[17-Feb-"
		    "[17-Feb-2"
		    "[17-Feb-20"
		    "[17-Feb-202"
		    "[17-Feb-2022"
		    "[17-Feb-2022/"
		    "[17-Feb-2022/1"
		    "[17-Feb-2022/1:"
		    "[17-Feb-2022/1:0"
		    "[17-Feb-2022/1:02"
		    "[17-Feb-2022/1:02:"
		    "[17-Feb-2022/1:02:0"
		    "[17-Feb-2022/1:02:03"
		    "[17-Feb-2022/1:02:03."
		    "[17-Feb-2022/1:02:03.4"
		    "[17-Feb-2022/1:02:03.4 "
		    "[17-Feb-2022/1:02:03.4 1"
		    "[17-Feb-2022/1:02:03.4 17"
		    "[17-Feb-2022/1:02:03.4 17-"
		    "[17-Feb-2022/1:02:03.4 17-F"
		    "[17-Feb-2022/1:02:03.4 17-Fe"
		    "[17-Feb-2022/1:02:03.4 17-Feb"
		    "[17-Feb-2022/1:02:03.4 17-Feb-"
		    "[17-Feb-2022/1:02:03.4 17-Feb-2"
		    "[17-Feb-2022/1:02:03.4 17-Feb-20"
		    "[17-Feb-2022/1:02:03.4 17-Feb-202"
		    "[17-Feb-2022/1:02:03.4 17-Feb-2022"
		    "[17-Feb-2022/1:02:03.4 17-Feb-2022/"
		    "[17-Feb-2022/1:02:03.4 17-Feb-2022/1"
		    "[17-Feb-2022/1:02:03.4 17-Feb-2022/1:"
		    "[17-Feb-2022/1:02:03.4 17-Feb-2022/1:0"
		    "[17-Feb-2022/1:02:03.4 17-Feb-2022/1:02"
		    "[17-Feb-2022/1:02:03.4 17-Feb-2022/1:02:"
		    "[17-Feb-2022/1:02:03.4 17-Feb-2022/1:02:0"
		    "[17-Feb-2022/1:02:03.4 17-Feb-2022/1:02:03"
		    "[17-Feb-2022/1:02:03.4 17-Feb-2022/1:02:03."
		    "[17-Feb-2022/1:02:03.4 17-Feb-2022/1:02:03.4"
		    "[17-Feb-2022/1:02:03.4 17-Feb-2022/1:02:03.4]"
		]
	--test-- "mp-8"
		--assert (do-mold-part 17/02/2022/1:2:3+01:00) == [
		    "["
		    "[1"
		    "[17"
		    "[17-"
		    "[17-F"
		    "[17-Fe"
		    "[17-Feb"
		    "[17-Feb-"
		    "[17-Feb-2"
		    "[17-Feb-20"
		    "[17-Feb-202"
		    "[17-Feb-2022"
		    "[17-Feb-2022/"
		    "[17-Feb-2022/1"
		    "[17-Feb-2022/1:"
		    "[17-Feb-2022/1:0"
		    "[17-Feb-2022/1:02"
		    "[17-Feb-2022/1:02:"
		    "[17-Feb-2022/1:02:0"
		    "[17-Feb-2022/1:02:03"
		    "[17-Feb-2022/1:02:03+"
		    "[17-Feb-2022/1:02:03+0"
		    "[17-Feb-2022/1:02:03+01"
		    "[17-Feb-2022/1:02:03+01:"
		    "[17-Feb-2022/1:02:03+01:0"
		    "[17-Feb-2022/1:02:03+01:00"
		    "[17-Feb-2022/1:02:03+01:00 "
		    "[17-Feb-2022/1:02:03+01:00 1"
		    "[17-Feb-2022/1:02:03+01:00 17"
		    "[17-Feb-2022/1:02:03+01:00 17-"
		    "[17-Feb-2022/1:02:03+01:00 17-F"
		    "[17-Feb-2022/1:02:03+01:00 17-Fe"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-20"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-202"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2022"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2022/"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:0"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:02"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:02:"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:02:0"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:02:03"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:02:03+"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:02:03+0"
		    "[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:02:03+01"
		    {[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:02:03+01:}
		    {[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:02:03+01:0}
		    {[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:02:03+01:00}
		    {[17-Feb-2022/1:02:03+01:00 17-Feb-2022/1:02:03+01:00]}
		]
	--test-- "mp-9"
		--assert (do-mold-part hello@world) == [
		    "["
		    "[h"
		    "[he"
		    "[hel"
		    "[hell"
		    "[hello"
		    "[hello@"
		    "[hello@w"
		    "[hello@wo"
		    "[hello@wor"
		    "[hello@worl"
		    "[hello@world"
		    "[hello@world "
		    "[hello@world h"
		    "[hello@world he"
		    "[hello@world hel"
		    "[hello@world hell"
		    "[hello@world hello"
		    "[hello@world hello@"
		    "[hello@world hello@w"
		    "[hello@world hello@wo"
		    "[hello@world hello@wor"
		    "[hello@world hello@worl"
		    "[hello@world hello@world"
		    "[hello@world hello@world]"
		]
	--test-- "mp-10"
		--assert (do-mold-part %dir/) == [
		    "["
		    "[%"
		    "[%d"
		    "[%di"
		    "[%dir"
		    "[%dir/"
		    "[%dir/ "
		    "[%dir/ %"
		    "[%dir/ %d"
		    "[%dir/ %di"
		    "[%dir/ %dir"
		    "[%dir/ %dir/"
		    "[%dir/ %dir/]"
		]
	--test-- "mp-11"
		--assert (do-mold-part %dir/file.ext) == [
		    "["
		    "[%"
		    "[%d"
		    "[%di"
		    "[%dir"
		    "[%dir/"
		    "[%dir/f"
		    "[%dir/fi"
		    "[%dir/fil"
		    "[%dir/file"
		    "[%dir/file."
		    "[%dir/file.e"
		    "[%dir/file.ex"
		    "[%dir/file.ext"
		    "[%dir/file.ext "
		    "[%dir/file.ext %"
		    "[%dir/file.ext %d"
		    "[%dir/file.ext %di"
		    "[%dir/file.ext %dir"
		    "[%dir/file.ext %dir/"
		    "[%dir/file.ext %dir/f"
		    "[%dir/file.ext %dir/fi"
		    "[%dir/file.ext %dir/fil"
		    "[%dir/file.ext %dir/file"
		    "[%dir/file.ext %dir/file."
		    "[%dir/file.ext %dir/file.e"
		    "[%dir/file.ext %dir/file.ex"
		    "[%dir/file.ext %dir/file.ext"
		    "[%dir/file.ext %dir/file.ext]"
		]
	--test-- "mp-12"
		--assert (do-mold-part pi) == [
		    "["
		    "[3"
		    "[3."
		    "[3.1"
		    "[3.14"
		    "[3.141"
		    "[3.1415"
		    "[3.14159"
		    "[3.141592"
		    "[3.1415926"
		    "[3.14159265"
		    "[3.141592653"
		    "[3.1415926535"
		    "[3.14159265358"
		    "[3.141592653589"
		    "[3.1415926535897"
		    "[3.14159265358979"
		    "[3.141592653589793"
		    "[3.141592653589793 "
		    "[3.141592653589793 3"
		    "[3.141592653589793 3."
		    "[3.141592653589793 3.1"
		    "[3.141592653589793 3.14"
		    "[3.141592653589793 3.141"
		    "[3.141592653589793 3.1415"
		    "[3.141592653589793 3.14159"
		    "[3.141592653589793 3.141592"
		    "[3.141592653589793 3.1415926"
		    "[3.141592653589793 3.14159265"
		    "[3.141592653589793 3.141592653"
		    "[3.141592653589793 3.1415926535"
		    "[3.141592653589793 3.14159265358"
		    "[3.141592653589793 3.141592653589"
		    "[3.141592653589793 3.1415926535897"
		    "[3.141592653589793 3.14159265358979"
		    "[3.141592653589793 3.141592653589793"
		    "[3.141592653589793 3.141592653589793]"
		]
	--test-- "mp-13"
		--assert (do-mold-part 'a/b/c) == [
		    "["
		    "[a"
		    "[a/"
		    "[a/b"
		    "[a/b/"
		    "[a/b/c"
		    "[a/b/c "
		    "[a/b/c a"
		    "[a/b/c a/"
		    "[a/b/c a/b"
		    "[a/b/c a/b/"
		    "[a/b/c a/b/c"
		    "[a/b/c a/b/c]"
		]
	--test-- "mp-14"
		--assert (do-mold-part quote 'a/b/c) == [
		    "["
		    "['"
		    "['a"
		    "['a/"
		    "['a/b"
		    "['a/b/"
		    "['a/b/c"
		    "['a/b/c "
		    "['a/b/c '"
		    "['a/b/c 'a"
		    "['a/b/c 'a/"
		    "['a/b/c 'a/b"
		    "['a/b/c 'a/b/"
		    "['a/b/c 'a/b/c"
		    "['a/b/c 'a/b/c]"
		]
	--test-- "mp-15"
		--assert (do-mold-part to-get-path 'a/b/c) == [
		    "["
		    "[:"
		    "[:a"
		    "[:a/"
		    "[:a/b"
		    "[:a/b/"
		    "[:a/b/c"
		    "[:a/b/c "
		    "[:a/b/c :"
		    "[:a/b/c :a"
		    "[:a/b/c :a/"
		    "[:a/b/c :a/b"
		    "[:a/b/c :a/b/"
		    "[:a/b/c :a/b/c"
		    "[:a/b/c :a/b/c]"
		]
	--test-- "mp-16"
		--assert (do-mold-part to-set-path 'a/b/c) == [
		    "["
		    "[a"
		    "[a/"
		    "[a/b"
		    "[a/b/"
		    "[a/b/c"
		    "[a/b/c:"
		    "[a/b/c: "
		    "[a/b/c: a"
		    "[a/b/c: a/"
		    "[a/b/c: a/b"
		    "[a/b/c: a/b/"
		    "[a/b/c: a/b/c"
		    "[a/b/c: a/b/c:"
		    "[a/b/c: a/b/c:]"
		]
	--test-- "mp-17"
		--assert (do-mold-part make hash! [a b c]) == [
		    "["
		    "[m"
		    "[ma"
		    "[mak"
		    "[make"
		    "[make "
		    "[make h"
		    "[make ha"
		    "[make has"
		    "[make hash"
		    "[make hash!"
		    "[make hash! "
		    "[make hash! ["
		    "[make hash! [a"
		    "[make hash! [a "
		    "[make hash! [a b"
		    "[make hash! [a b "
		    "[make hash! [a b c"
		    "[make hash! [a b c]"
		    "[make hash! [a b c] "
		    "[make hash! [a b c] m"
		    "[make hash! [a b c] ma"
		    "[make hash! [a b c] mak"
		    "[make hash! [a b c] make"
		    "[make hash! [a b c] make "
		    "[make hash! [a b c] make h"
		    "[make hash! [a b c] make ha"
		    "[make hash! [a b c] make has"
		    "[make hash! [a b c] make hash"
		    "[make hash! [a b c] make hash!"
		    "[make hash! [a b c] make hash! "
		    "[make hash! [a b c] make hash! ["
		    "[make hash! [a b c] make hash! [a"
		    "[make hash! [a b c] make hash! [a "
		    "[make hash! [a b c] make hash! [a b"
		    "[make hash! [a b c] make hash! [a b "
		    "[make hash! [a b c] make hash! [a b c"
		    "[make hash! [a b c] make hash! [a b c]"
		    "[make hash! [a b c] make hash! [a b c]]"
		]
	--test-- "mp-18"
		--assert (do-mold-part 123) == [
		    "["
		    "[1"
		    "[12"
		    "[123"
		    "[123 "
		    "[123 1"
		    "[123 12"
		    "[123 123"
		    "[123 123]"
		]
	--test-- "mp-19"
		--assert (do-mold-part #issue) == [
		    "["
		    "[#"
		    "[#i"
		    "[#is"
		    "[#iss"
		    "[#issu"
		    "[#issue"
		    "[#issue "
		    "[#issue #"
		    "[#issue #i"
		    "[#issue #is"
		    "[#issue #iss"
		    "[#issue #issu"
		    "[#issue #issue"
		    "[#issue #issue]"
		]
	--test-- "mp-20"
		--assert (do-mold-part 'abc) == [
		    "["
		    "[a"
		    "[ab"
		    "[abc"
		    "[abc "
		    "[abc a"
		    "[abc ab"
		    "[abc abc"
		    "[abc abc]"
		]
	--test-- "mp-21"
		--assert (do-mold-part /abc) == [
		    "["
		    "[/"
		    "[/a"
		    "[/ab"
		    "[/abc"
		    "[/abc "
		    "[/abc /"
		    "[/abc /a"
		    "[/abc /ab"
		    "[/abc /abc"
		    "[/abc /abc]"
		]
	--test-- "mp-22"
		--assert (do-mold-part quote 'abc) == [
		    "["
		    "['"
		    "['a"
		    "['ab"
		    "['abc"
		    "['abc "
		    "['abc '"
		    "['abc 'a"
		    "['abc 'ab"
		    "['abc 'abc"
		    "['abc 'abc]"
		]
	--test-- "mp-23"
		--assert (do-mold-part to-set-word 'abc) == [
		    "["
		    "[a"
		    "[ab"
		    "[abc"
		    "[abc:"
		    "[abc: "
		    "[abc: a"
		    "[abc: ab"
		    "[abc: abc"
		    "[abc: abc:"
		    "[abc: abc:]"
		]
	--test-- "mp-24"
		--assert (do-mold-part to-get-word 'abc) == [
		    "["
		    "[:"
		    "[:a"
		    "[:ab"
		    "[:abc"
		    "[:abc "
		    "[:abc :"
		    "[:abc :a"
		    "[:abc :ab"
		    "[:abc :abc"
		    "[:abc :abc]"
    	]
	--test-- "mp-25"
		--assert (do-mold-part $123) == [
		    "["
		    "[$"
		    "[$1"
		    "[$12"
		    "[$123"
		    "[$123."
		    "[$123.0"
		    "[$123.00"
		    "[$123.00 "
		    "[$123.00 $"
		    "[$123.00 $1"
		    "[$123.00 $12"
		    "[$123.00 $123"
		    "[$123.00 $123."
		    "[$123.00 $123.0"
		    "[$123.00 $123.00"
		    "[$123.00 $123.00]"
		]
	--test-- "mp-26"
		--assert (do-mold-part USD$123) == [
		    "["
		    "[U"
		    "[US"
		    "[USD"
		    "[USD$"
		    "[USD$1"
		    "[USD$12"
		    "[USD$123"
		    "[USD$123."
		    "[USD$123.0"
		    "[USD$123.00"
		    "[USD$123.00 "
		    "[USD$123.00 U"
		    "[USD$123.00 US"
		    "[USD$123.00 USD"
		    "[USD$123.00 USD$"
		    "[USD$123.00 USD$1"
		    "[USD$123.00 USD$12"
		    "[USD$123.00 USD$123"
		    "[USD$123.00 USD$123."
		    "[USD$123.00 USD$123.0"
		    "[USD$123.00 USD$123.00"
		    "[USD$123.00 USD$123.00]"
		]
	--test-- "mp-27"
		--assert (do-mold-part none) == [
		    "["
		    "[n"
		    "[no"
		    "[non"
		    "[none"
		    "[none "
		    "[none n"
		    "[none no"
		    "[none non"
		    "[none none"
		    "[none none]"
		]
	--test-- "mp-28"
		--assert (do-mold-part true) == [
		    "["
		    "[t"
		    "[tr"
		    "[tru"
		    "[true"
		    "[true "
		    "[true t"
		    "[true tr"
		    "[true tru"
		    "[true true"
		    "[true true]"
		]
	--test-- "mp-29"
		--assert (do-mold-part 123x4) == [
		    "["
		    "[1"
		    "[12"
		    "[123"
		    "[123x"
		    "[123x4"
		    "[123x4 "
		    "[123x4 1"
		    "[123x4 12"
		    "[123x4 123"
		    "[123x4 123x"
		    "[123x4 123x4"
		    "[123x4 123x4]"
		]
	--test-- "mp-30"
		--assert (do-mold-part quote (a b c)) == [
		    "["
		    "[("
		    "[(a"
		    "[(a "
		    "[(a b"
		    "[(a b "
		    "[(a b c"
		    "[(a b c)"
		    "[(a b c) "
		    "[(a b c) ("
		    "[(a b c) (a"
		    "[(a b c) (a "
		    "[(a b c) (a b"
		    "[(a b c) (a b "
		    "[(a b c) (a b c"
		    "[(a b c) (a b c)"
		    "[(a b c) (a b c)]"
		]
	--test-- "mp-31"
		--assert (do-mold-part %1.23) == [
		    "["
		    "[%"
		    "[%1"
		    "[%1."
		    "[%1.2"
		    "[%1.23"
		    "[%1.23 "
		    "[%1.23 %"
		    "[%1.23 %1"
		    "[%1.23 %1."
		    "[%1.23 %1.2"
		    "[%1.23 %1.23"
		    "[%1.23 %1.23]"
		]
	--test-- "mp-32"
		--assert (do-mold-part @abc) == [
		    "["
		    "[@"
		    "[@a"
		    "[@ab"
		    "[@abc"
		    "[@abc "
		    "[@abc @"
		    "[@abc @a"
		    "[@abc @ab"
		    "[@abc @abc"
		    "[@abc @abc]"
		]
	--test-- "mp-33"
		--assert (do-mold-part "aBc") == [
		    "["
		    {["}
		    {["a}
		    {["aB}
		    {["aBc}
		    {["aBc"}
		    {["aBc" }
		    {["aBc" "}
		    {["aBc" "a}
		    {["aBc" "aB}
		    {["aBc" "aBc}
		    {["aBc" "aBc"}
		    {["aBc" "aBc"]}
		]
	--test-- "mp-34"
		--assert (do-mold-part <abc>) == [
		    "["
		    "[<"
		    "[<a"
		    "[<ab"
		    "[<abc"
		    "[<abc>"
		    "[<abc> "
		    "[<abc> <"
		    "[<abc> <a"
		    "[<abc> <ab"
		    "[<abc> <abc"
		    "[<abc> <abc>"
		    "[<abc> <abc>]"
		]
	--test-- "mp-35"
		--assert (do-mold-part 1:2:3) == [
		    "["
		    "[1"
		    "[1:"
		    "[1:0"
		    "[1:02"
		    "[1:02:"
		    "[1:02:0"
		    "[1:02:03"
		    "[1:02:03 "
		    "[1:02:03 1"
		    "[1:02:03 1:"
		    "[1:02:03 1:0"
		    "[1:02:03 1:02"
		    "[1:02:03 1:02:"
		    "[1:02:03 1:02:0"
		    "[1:02:03 1:02:03"
		    "[1:02:03 1:02:03]"
		]
	--test-- "mp-36"
		--assert (do-mold-part 1:2:3.456) == [
		    "["
		    "[1"
		    "[1:"
		    "[1:0"
		    "[1:02"
		    "[1:02:"
		    "[1:02:0"
		    "[1:02:03"
		    "[1:02:03."
		    "[1:02:03.4"
		    "[1:02:03.45"
		    "[1:02:03.456"
		    "[1:02:03.456 "
		    "[1:02:03.456 1"
		    "[1:02:03.456 1:"
		    "[1:02:03.456 1:0"
		    "[1:02:03.456 1:02"
		    "[1:02:03.456 1:02:"
		    "[1:02:03.456 1:02:0"
		    "[1:02:03.456 1:02:03"
		    "[1:02:03.456 1:02:03."
		    "[1:02:03.456 1:02:03.4"
		    "[1:02:03.456 1:02:03.45"
		    "[1:02:03.456 1:02:03.456"
		    "[1:02:03.456 1:02:03.456]"
		]
	--test-- "mp-37"
		--assert (do-mold-part red) == [
		    "["
		    "[2"
		    "[25"
		    "[255"
		    "[255."
		    "[255.0"
		    "[255.0."
		    "[255.0.0"
		    "[255.0.0 "
		    "[255.0.0 2"
		    "[255.0.0 25"
		    "[255.0.0 255"
		    "[255.0.0 255."
		    "[255.0.0 255.0"
		    "[255.0.0 255.0."
		    "[255.0.0 255.0.0"
		    "[255.0.0 255.0.0]"
		]
	--test-- "mp-38"
		--assert (do-mold-part 127.0.0.1) == [
		    "["
		    "[1"
		    "[12"
		    "[127"
		    "[127."
		    "[127.0"
		    "[127.0."
		    "[127.0.0"
		    "[127.0.0."
		    "[127.0.0.1"
		    "[127.0.0.1 "
		    "[127.0.0.1 1"
		    "[127.0.0.1 12"
		    "[127.0.0.1 127"
		    "[127.0.0.1 127."
		    "[127.0.0.1 127.0"
		    "[127.0.0.1 127.0."
		    "[127.0.0.1 127.0.0"
		    "[127.0.0.1 127.0.0."
		    "[127.0.0.1 127.0.0.1"
		    "[127.0.0.1 127.0.0.1]"
		]
	--test-- "mp-39"
		--assert (do-mold-part abc://) == [
		    "["
		    "[a"
		    "[ab"
		    "[abc"
		    "[abc:"
		    "[abc:/"
		    "[abc://"
		    "[abc:// "
		    "[abc:// a"
		    "[abc:// ab"
		    "[abc:// abc"
		    "[abc:// abc:"
		    "[abc:// abc:/"
		    "[abc:// abc://"
		    "[abc:// abc://]"
		]
	--test-- "mp-40"
		--assert (do-mold-part abc://def) == [
		    "["
		    "[a"
		    "[ab"
		    "[abc"
		    "[abc:"
		    "[abc:/"
		    "[abc://"
		    "[abc://d"
		    "[abc://de"
		    "[abc://def"
		    "[abc://def "
		    "[abc://def a"
		    "[abc://def ab"
		    "[abc://def abc"
		    "[abc://def abc:"
		    "[abc://def abc:/"
		    "[abc://def abc://"
		    "[abc://def abc://d"
		    "[abc://def abc://de"
		    "[abc://def abc://def"
		    "[abc://def abc://def]"
		]

===end-group===


~~~end-file~~~
