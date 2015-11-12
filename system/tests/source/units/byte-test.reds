Red/System [
	Title:   "Red/System byte! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %byte-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "byte!"

===start-group=== "Byte literals & operators test"
	--test-- "byte-type-1"		--assert #"A" = #"A"
	--test-- "byte-type-2"		--assert #"A" <> #"B"
	--test-- "byte-type-3"		--assert #"A" < #"B"
	--test-- "byte-type-4"		--assert #"a" <> #"A"
	
	--test-- "byte-operator-1"
		bo1-c: #"^(10)"
		bo1-res: -1
		either (as byte! 17)  < bo1-c [bo1-res: 1][bo1-res: 0]
		--assert bo1-res = 0    
	
	--test-- "byte-operator-2"
		bo1-c: #"^(10)"
		either 17  < as integer! bo1-c [bo1-res: 1][bo1-res: 0]
		--assert bo1-res = 0    
	
	--test-- "byte-operator-3"
		bo1-c: #"^(10)"
		bol-res: 0
		if (as byte! 17)  < bo1-c [bo1-res: 1]
		--assert bo1-res = 0    
	
	--test-- "byte-operator-4"
		bo1-c: #"^(10)"
		bol-res: 0
		if 17  < as integer! bo1-c [bo1-res: 1]
		--assert bo1-res = 0  
	
	--test-- "byte-operator-5"
		bo1-c: #"^(10)" 
		--assert  not ((as byte! 17)  < bo1-c)     
	
	--test-- "byte-operator-6"
		bo1-c: #"^(10)"
		--assert not (17  < as integer! bo1-c)
	
	--test-- "byte-operator-7"		--assert not #"^(E1)" < as byte! 0
	  
===end-group===

===start-group=== "Byte literals assignment"

  	--test-- "byte-type-4"
		t: #"^(C6)"
		--assert t = #"^(C6)"
	
	--test-- "byte-type-5"
		u: #"^(C6)"
		--assert t = u

===end-group===

===start-group=== "Math operations"

	--test-- "byte-type-6"
		bt-b: #"A"
		bt-a: bt-b + 1
		--assert bt-a = #"B"

	--test--  "byte-type-7"
		bt-aa: t / 3
		--assert bt-aa = #"B"

===end-group===

===start-group=== "Passing byte! as argument and returning a byte!"

	  bt-foo: func [v [byte!] return: [byte!]][v]
	
	--test-- "byte-type-8"
		bt-b: bt-foo bt-a
		--assert (bt-b = #"B")
		
===end-group===

===start-group=== "Byte as c-string! element (READ access)"
	
	--test-- "byte-read-1"
    	byte-test-str: "Hello World!"
    	br-c: byte-test-str/1
    	--assert br-c = #"H"
    	--assert br-c = byte-test-str/1
    	--assert byte-test-str/1 = br-c

	--test-- "byte-read-2"
		d: 2
		br-c: byte-test-str/d
		--assert br-c = #"e"
		--assert byte-test-str/1 = #"H"
		--assert #"H" = bt-foo byte-test-str/1
	
	--test-- "byte-read-3"
		br-c: bt-foo byte-test-str/d
		--assert br-c = #"e"

===end-group===

===start-group=== "same tests but with local variables"

	byte-read: func [/local str [c-string!] c [byte!] d [integer!]][
		str: "Hello World!"
		
	--test-- "byte-read-local-1"
		c: str/1
		--assert c = #"H"
		--assert c = str/1
		--assert str/1 = c

	--test-- "byte-read-local-2"
		d: 2
		c: str/d
		--assert c = #"e"
		--assert str/1 = #"H"
		--assert #"H" = bt-foo str/1
		
	--test-- "byte-read-local-3"
		c: bt-foo str/d
		--assert c = #"e"
	]
	byte-read
	
===end-group===

===start-group=== "Byte as c-string! element (WRITE access)"

    byte-write-str: "Hello "  

    --test-- "byte-write-1"
    	byte-write-str/1: #"y"
    	--assert byte-write-str/1 = #"y"
	
    --test-- "byte-write-2"
    	c: 6
    	byte-write-str/c: #"w"
    	--assert byte-write-str/c = #"w"
    	--assert byte-write-str/1 = #"y"
    	--assert byte-write-str/2 = #"e"
    	--assert byte-write-str/3 = #"l"
    	--assert byte-write-str/4 = #"l"
    	--assert byte-write-str/5 = #"o"
    	--assert byte-write-str/6 = #"w"
    	--assert 6 = length? byte-write-str

	byte-write: func [/local str [c-string!] c [integer!]][
	  
		str: "Hello "
	   
	--test-- "byte-write-3" 
		str/1: #"y"
		--assert str/1 = #"y"
	
	--test-- "byte-write-4"
		c: 6
		str/c: #"w"
		--assert str/c = #"w"
	
	]
	byte-write

===end-group===

~~~end-file~~~
