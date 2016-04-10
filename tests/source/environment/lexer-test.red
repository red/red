Red [
	Title:		"Red lexer test"
	Author:		"Peter W A Wood"
	File:		%print-test.red
	Tabs:		4
	Rights:		"Copyright (C) 2014-2015 Peter W A Wood. All rights reserved."
	License:	"BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../quick-test/quick-test.red
#include %../../../environment/lexer.red

~~~start-file~~~ "lexer"


===start-group=== "system/lexer/transcode with none"

	--test-- "trans1"
		--assert [Red[] 1] = system/lexer/transcode {Red[] 1} none
		
	--test-- "trans2"
		--assert [Red[] a: 1] = system/lexer/transcode {Red[] a: 1} none
		
===end-group===

===start-group=== "literal values - integer"

	--test-- "litval-integer1" --assert [1] = system/lexer/transcode {1} none
	--test-- "litval-integer2" --assert [+1] = system/lexer/transcode {+1} none
	--test-- "litval-integer3" --assert [-1] = system/lexer/transcode {-1} none
	--test-- "litval-integer4" --assert [0] = system/lexer/transcode {0} none
	--test-- "litval-integer5" --assert [+0] = system/lexer/transcode {+0} none
	--test-- "litval-integer6" --assert [0] = system/lexer/transcode {-0} none
	--test-- "litval-integer7" --assert 0 = -0
	--test-- "litval-integer8" 
		--assert [2147483647] = system/lexer/transcode {2147483647} none
	--test-- "litval-integer9" 
		--assert [-2147483648] = system/lexer/transcode {-2147483648} none
	--test-- "litval-integer10" ;--assert [01h] = system/lexer/transcode {01h} none
								--assert false
	--test-- "litval-integer11" ;--assert [00h] = system/lexer/transcode {00h} none
								--assert false	
===end-group===



===start-group=== "literal values - word"
		
	lvw-count: 0
	correct-word: func [word [string!]] [
		lvw-count: lvw-count + 1
		--test-- append "lvw-correct-word" mold lvw-count
		--assert (compose [(to word! word)]) = system/lexer/transcode word none
	]
	
	correct-word "w"
	correct-word "?"
	correct-word "!"
	correct-word "."
	correct-word "a'"
	correct-word "+"
	correct-word "-"
	correct-word "*"
	correct-word "&"
	correct-word "|"
	correct-word "="
	correct-word "_"
	correct-word "~"

	--test-- "lvw1"
		--assert [a []] = system/lexer/transcode {a[]} none
	--test-- "lvw2"
		--assert [a] = system/lexer/transcode {a;b} none
	--test-- "lvw3"
		--assert [a ()] = system/lexer/transcode {a()} none	
	--test-- "lvw4"
		--assert [a {}] = system/lexer/transcode {a{}} none
	--test-- "lvw5"
		--assert [a ""] = system/lexer/transcode {a""} none
	--test-- "lvw6"
		--assert [a/b] = system/lexer/transcode {a/b} none
	--test-- "lvw7"
		--assert [a:] = system/lexer/transcode {a:} none
	--test-- "lvw8"
		--assert [:a] = system/lexer/transcode {:a} none	
	--test-- "lvw9"
		--assert ['a] = system/lexer/transcode {'a} none
	
===end-group===

===start-group=== "words"
		
	--test-- "words1"
		--assert [œ∑´®†] = system/lexer/transcode {œ∑´®†} none

===end-group===

===start-group=== "/next"
		
	--test-- "next1"
		--assert [1 " 2 3"] = system/lexer/transcode "1 2 3" make block! 2

===end-group===

~~~end-file~~~
