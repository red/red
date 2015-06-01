Red [
	Title:   "Red words-of function test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %words-of-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "words-of"

===start-group=== "words-of-basic"

	--test-- "wob1"
		wob1-o: make object! [
		    b: [a b c d]
		    c: #"a"
		    f: 1.0
		    o: make object! [a: 1 b: 2 c: 3]
		    i: 1
		    n: none
		    s: "abcde"
		]
		--assert [b c f o i n s] = words-of wob1-o
	
===end-group===

===start-group=== "words-of-self"

	--test-- "wos1"
		wos1-o: make object! [
		    b: [a b c d]
		    c: #"a"
		    f: 1.0
		    o: make object! [a: 1 b: 2 c: 3]
		    i: 1
		    n: none
		    s: "abcde"
		    wos: words-of self
		]
		--assert [b c f o i n s wos] = wos1-o/wos
		
	--test-- "wos2"
		wos2-o: make object! [
		    b: [a b c d]
		    c: #"a"
		    f: 1.0
		    o: make object! [a: 1 b: 2 c: 3]
		    i: 1
		    n: none
		    s: "abcde"
		    do-wos: does [words-of self]
		]
		--assert [b c f o i n s do-wos] = wos2-o/do-wos
	
===end-group===

~~~end-file~~~