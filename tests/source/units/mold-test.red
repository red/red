Red [
	Title:   "Red mold test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %mold-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

~~~start-file~~~ "mold"

===start-group=== "string"

	--test-- "mold-string1 #issue 498"
	--assert {{""}} = mold mold {}
	
	--test-- "mold-string2"
	--assert {"abcde"} = mold "abcde"
	
	--test-- "mold-string3"
	--assert {"abc^(2710)def"} = mold "abc✐def"
	
	--test-- "mold-string4"
	--assert {"abc^(10000)def"} = mold "abc^(010000)def"
	  
===end-group===

===start-group=== "char"

	--test-- "mold-char1"
	--assert {#"a"} = mold #"a"
	
	--test-- "mold-char2"
	--assert {#"^(2710)"} = mold #"✐"
	
	--test-- "mold-char3"
	--assert {#"^(10000)"} = mold #"^(010000)"
	
===end-group===

===start-group=== "logic"
	
	--test-- "mold-logic1"
	--assert "true" = mold true
	--assert "false" = mold false

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


~~~end-file~~~

