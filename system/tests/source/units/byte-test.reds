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

===start-group=== "Arithmetic, Bit Shifting & Comparison"

  --test-- "byte-auto-1"
  --assert #"^(00)"  = ( #"^(00)" + #"^(00)" )
  --test-- "byte-auto-2"
      ba-b1: #"^(00)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" + #"^(00)" ))
  --test-- "byte-auto-4"
  --assert #"^(FF)"  = ( #"^(00)" + #"^(FF)" )
  --test-- "byte-auto-5"
      ba-b1: #"^(00)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-6"
  --assert #"^(60)"  = ( #"a" + ( #"^(00)" + #"^(FF)" ))
  --test-- "byte-auto-7"
  --assert #"^(01)"  = ( #"^(00)" + #"^(01)" )
  --test-- "byte-auto-8"
      ba-b1: #"^(00)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-9"
  --assert #"^(62)"  = ( #"a" + ( #"^(00)" + #"^(01)" ))
  --test-- "byte-auto-10"
  --assert #"^(02)"  = ( #"^(00)" + #"^(02)" )
  --test-- "byte-auto-11"
      ba-b1: #"^(00)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-12"
  --assert #"^(63)"  = ( #"a" + ( #"^(00)" + #"^(02)" ))
  --test-- "byte-auto-13"
  --assert #"^(03)"  = ( #"^(00)" + #"^(03)" )
  --test-- "byte-auto-14"
      ba-b1: #"^(00)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-15"
  --assert #"^(64)"  = ( #"a" + ( #"^(00)" + #"^(03)" ))
  --test-- "byte-auto-16"
  --assert #"^(05)"  = ( #"^(00)" + #"^(05)" )
  --test-- "byte-auto-17"
      ba-b1: #"^(00)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-18"
  --assert #"^(66)"  = ( #"a" + ( #"^(00)" + #"^(05)" ))
  --test-- "byte-auto-19"
  --assert #"^(F0)"  = ( #"^(00)" + #"^(F0)" )
  --test-- "byte-auto-20"
      ba-b1: #"^(00)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-21"
  --assert #"^(51)"  = ( #"a" + ( #"^(00)" + #"^(F0)" ))
  --test-- "byte-auto-22"
  --assert #"^(FD)"  = ( #"^(00)" + #"^(FD)" )
  --test-- "byte-auto-23"
      ba-b1: #"^(00)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-24"
  --assert #"^(5E)"  = ( #"a" + ( #"^(00)" + #"^(FD)" ))
  --test-- "byte-auto-25"
  --assert #"^(FE)"  = ( #"^(00)" + #"^(FE)" )
  --test-- "byte-auto-26"
      ba-b1: #"^(00)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-27"
  --assert #"^(5F)"  = ( #"a" + ( #"^(00)" + #"^(FE)" ))
  --test-- "byte-auto-28"
  --assert #"^(7E)"  = ( #"^(00)" + #"^(7E)" )
  --test-- "byte-auto-29"
      ba-b1: #"^(00)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-30"
  --assert #"^(DF)"  = ( #"a" + ( #"^(00)" + #"^(7E)" ))
  --test-- "byte-auto-31"
  --assert #"^(6B)"  = ( #"^(00)" + #"^(6B)" )
  --test-- "byte-auto-32"
      ba-b1: #"^(00)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-33"
  --assert #"^(CC)"  = ( #"a" + ( #"^(00)" + #"^(6B)" ))
  --test-- "byte-auto-34"
  --assert #"^(FB)"  = ( #"^(00)" + #"^(FB)" )
  --test-- "byte-auto-35"
      ba-b1: #"^(00)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-36"
  --assert #"^(5C)"  = ( #"a" + ( #"^(00)" + #"^(FB)" ))
  --test-- "byte-auto-37"
  --assert #"^(FF)"  = ( #"^(FF)" + #"^(00)" )
  --test-- "byte-auto-38"
      ba-b1: #"^(FF)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-39"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" + #"^(00)" ))
  --test-- "byte-auto-40"
  --assert #"^(FE)"  = ( #"^(FF)" + #"^(FF)" )
  --test-- "byte-auto-41"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-42"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FF)" + #"^(FF)" ))
  --test-- "byte-auto-43"
  --assert #"^(00)"  = ( #"^(FF)" + #"^(01)" )
  --test-- "byte-auto-44"
      ba-b1: #"^(FF)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-45"
  --assert #"^(61)"  = ( #"a" + ( #"^(FF)" + #"^(01)" ))
  --test-- "byte-auto-46"
  --assert #"^(01)"  = ( #"^(FF)" + #"^(02)" )
  --test-- "byte-auto-47"
      ba-b1: #"^(FF)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-48"
  --assert #"^(62)"  = ( #"a" + ( #"^(FF)" + #"^(02)" ))
  --test-- "byte-auto-49"
  --assert #"^(02)"  = ( #"^(FF)" + #"^(03)" )
  --test-- "byte-auto-50"
      ba-b1: #"^(FF)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-51"
  --assert #"^(63)"  = ( #"a" + ( #"^(FF)" + #"^(03)" ))
  --test-- "byte-auto-52"
  --assert #"^(04)"  = ( #"^(FF)" + #"^(05)" )
  --test-- "byte-auto-53"
      ba-b1: #"^(FF)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-54"
  --assert #"^(65)"  = ( #"a" + ( #"^(FF)" + #"^(05)" ))
  --test-- "byte-auto-55"
  --assert #"^(EF)"  = ( #"^(FF)" + #"^(F0)" )
  --test-- "byte-auto-56"
      ba-b1: #"^(FF)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(EF)"  = ba-b3 
  --test-- "byte-auto-57"
  --assert #"^(50)"  = ( #"a" + ( #"^(FF)" + #"^(F0)" ))
  --test-- "byte-auto-58"
  --assert #"^(FC)"  = ( #"^(FF)" + #"^(FD)" )
  --test-- "byte-auto-59"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-60"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FF)" + #"^(FD)" ))
  --test-- "byte-auto-61"
  --assert #"^(FD)"  = ( #"^(FF)" + #"^(FE)" )
  --test-- "byte-auto-62"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-63"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FF)" + #"^(FE)" ))
  --test-- "byte-auto-64"
  --assert #"^(7D)"  = ( #"^(FF)" + #"^(7E)" )
  --test-- "byte-auto-65"
      ba-b1: #"^(FF)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(7D)"  = ba-b3 
  --test-- "byte-auto-66"
  --assert #"^(DE)"  = ( #"a" + ( #"^(FF)" + #"^(7E)" ))
  --test-- "byte-auto-67"
  --assert #"^(6A)"  = ( #"^(FF)" + #"^(6B)" )
  --test-- "byte-auto-68"
      ba-b1: #"^(FF)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(6A)"  = ba-b3 
  --test-- "byte-auto-69"
  --assert #"^(CB)"  = ( #"a" + ( #"^(FF)" + #"^(6B)" ))
  --test-- "byte-auto-70"
  --assert #"^(FA)"  = ( #"^(FF)" + #"^(FB)" )
  --test-- "byte-auto-71"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-72"
  --assert #"^(5B)"  = ( #"a" + ( #"^(FF)" + #"^(FB)" ))
  --test-- "byte-auto-73"
  --assert #"^(01)"  = ( #"^(01)" + #"^(00)" )
  --test-- "byte-auto-74"
      ba-b1: #"^(01)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-75"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" + #"^(00)" ))
  --test-- "byte-auto-76"
  --assert #"^(00)"  = ( #"^(01)" + #"^(FF)" )
  --test-- "byte-auto-77"
      ba-b1: #"^(01)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-78"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" + #"^(FF)" ))
  --test-- "byte-auto-79"
  --assert #"^(02)"  = ( #"^(01)" + #"^(01)" )
  --test-- "byte-auto-80"
      ba-b1: #"^(01)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-81"
  --assert #"^(63)"  = ( #"a" + ( #"^(01)" + #"^(01)" ))
  --test-- "byte-auto-82"
  --assert #"^(03)"  = ( #"^(01)" + #"^(02)" )
  --test-- "byte-auto-83"
      ba-b1: #"^(01)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-84"
  --assert #"^(64)"  = ( #"a" + ( #"^(01)" + #"^(02)" ))
  --test-- "byte-auto-85"
  --assert #"^(04)"  = ( #"^(01)" + #"^(03)" )
  --test-- "byte-auto-86"
      ba-b1: #"^(01)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-87"
  --assert #"^(65)"  = ( #"a" + ( #"^(01)" + #"^(03)" ))
  --test-- "byte-auto-88"
  --assert #"^(06)"  = ( #"^(01)" + #"^(05)" )
  --test-- "byte-auto-89"
      ba-b1: #"^(01)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-90"
  --assert #"^(67)"  = ( #"a" + ( #"^(01)" + #"^(05)" ))
  --test-- "byte-auto-91"
  --assert #"^(F1)"  = ( #"^(01)" + #"^(F0)" )
  --test-- "byte-auto-92"
      ba-b1: #"^(01)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F1)"  = ba-b3 
  --test-- "byte-auto-93"
  --assert #"^(52)"  = ( #"a" + ( #"^(01)" + #"^(F0)" ))
  --test-- "byte-auto-94"
  --assert #"^(FE)"  = ( #"^(01)" + #"^(FD)" )
  --test-- "byte-auto-95"
      ba-b1: #"^(01)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-96"
  --assert #"^(5F)"  = ( #"a" + ( #"^(01)" + #"^(FD)" ))
  --test-- "byte-auto-97"
  --assert #"^(FF)"  = ( #"^(01)" + #"^(FE)" )
  --test-- "byte-auto-98"
      ba-b1: #"^(01)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-99"
  --assert #"^(60)"  = ( #"a" + ( #"^(01)" + #"^(FE)" ))
  --test-- "byte-auto-100"
  --assert #"^(7F)"  = ( #"^(01)" + #"^(7E)" )
  --test-- "byte-auto-101"
      ba-b1: #"^(01)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-102"
  --assert #"^(E0)"  = ( #"a" + ( #"^(01)" + #"^(7E)" ))
  --test-- "byte-auto-103"
  --assert #"^(6C)"  = ( #"^(01)" + #"^(6B)" )
  --test-- "byte-auto-104"
      ba-b1: #"^(01)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(6C)"  = ba-b3 
  --test-- "byte-auto-105"
  --assert #"^(CD)"  = ( #"a" + ( #"^(01)" + #"^(6B)" ))
  --test-- "byte-auto-106"
  --assert #"^(FC)"  = ( #"^(01)" + #"^(FB)" )
  --test-- "byte-auto-107"
      ba-b1: #"^(01)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-108"
  --assert #"^(5D)"  = ( #"a" + ( #"^(01)" + #"^(FB)" ))
  --test-- "byte-auto-109"
  --assert #"^(02)"  = ( #"^(02)" + #"^(00)" )
  --test-- "byte-auto-110"
      ba-b1: #"^(02)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-111"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" + #"^(00)" ))
  --test-- "byte-auto-112"
  --assert #"^(01)"  = ( #"^(02)" + #"^(FF)" )
  --test-- "byte-auto-113"
      ba-b1: #"^(02)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-114"
  --assert #"^(62)"  = ( #"a" + ( #"^(02)" + #"^(FF)" ))
  --test-- "byte-auto-115"
  --assert #"^(03)"  = ( #"^(02)" + #"^(01)" )
  --test-- "byte-auto-116"
      ba-b1: #"^(02)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-117"
  --assert #"^(64)"  = ( #"a" + ( #"^(02)" + #"^(01)" ))
  --test-- "byte-auto-118"
  --assert #"^(04)"  = ( #"^(02)" + #"^(02)" )
  --test-- "byte-auto-119"
      ba-b1: #"^(02)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-120"
  --assert #"^(65)"  = ( #"a" + ( #"^(02)" + #"^(02)" ))
  --test-- "byte-auto-121"
  --assert #"^(05)"  = ( #"^(02)" + #"^(03)" )
  --test-- "byte-auto-122"
      ba-b1: #"^(02)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-123"
  --assert #"^(66)"  = ( #"a" + ( #"^(02)" + #"^(03)" ))
  --test-- "byte-auto-124"
  --assert #"^(07)"  = ( #"^(02)" + #"^(05)" )
  --test-- "byte-auto-125"
      ba-b1: #"^(02)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(07)"  = ba-b3 
  --test-- "byte-auto-126"
  --assert #"^(68)"  = ( #"a" + ( #"^(02)" + #"^(05)" ))
  --test-- "byte-auto-127"
  --assert #"^(F2)"  = ( #"^(02)" + #"^(F0)" )
  --test-- "byte-auto-128"
      ba-b1: #"^(02)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F2)"  = ba-b3 
  --test-- "byte-auto-129"
  --assert #"^(53)"  = ( #"a" + ( #"^(02)" + #"^(F0)" ))
  --test-- "byte-auto-130"
  --assert #"^(FF)"  = ( #"^(02)" + #"^(FD)" )
  --test-- "byte-auto-131"
      ba-b1: #"^(02)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-132"
  --assert #"^(60)"  = ( #"a" + ( #"^(02)" + #"^(FD)" ))
  --test-- "byte-auto-133"
  --assert #"^(00)"  = ( #"^(02)" + #"^(FE)" )
  --test-- "byte-auto-134"
      ba-b1: #"^(02)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-135"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" + #"^(FE)" ))
  --test-- "byte-auto-136"
  --assert #"^(80)"  = ( #"^(02)" + #"^(7E)" )
  --test-- "byte-auto-137"
      ba-b1: #"^(02)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(80)"  = ba-b3 
  --test-- "byte-auto-138"
  --assert #"^(E1)"  = ( #"a" + ( #"^(02)" + #"^(7E)" ))
  --test-- "byte-auto-139"
  --assert #"^(6D)"  = ( #"^(02)" + #"^(6B)" )
  --test-- "byte-auto-140"
      ba-b1: #"^(02)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(6D)"  = ba-b3 
  --test-- "byte-auto-141"
  --assert #"^(CE)"  = ( #"a" + ( #"^(02)" + #"^(6B)" ))
  --test-- "byte-auto-142"
  --assert #"^(FD)"  = ( #"^(02)" + #"^(FB)" )
  --test-- "byte-auto-143"
      ba-b1: #"^(02)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-144"
  --assert #"^(5E)"  = ( #"a" + ( #"^(02)" + #"^(FB)" ))
  --test-- "byte-auto-145"
  --assert #"^(03)"  = ( #"^(03)" + #"^(00)" )
  --test-- "byte-auto-146"
      ba-b1: #"^(03)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-147"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" + #"^(00)" ))
  --test-- "byte-auto-148"
  --assert #"^(02)"  = ( #"^(03)" + #"^(FF)" )
  --test-- "byte-auto-149"
      ba-b1: #"^(03)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-150"
  --assert #"^(63)"  = ( #"a" + ( #"^(03)" + #"^(FF)" ))
  --test-- "byte-auto-151"
  --assert #"^(04)"  = ( #"^(03)" + #"^(01)" )
  --test-- "byte-auto-152"
      ba-b1: #"^(03)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-153"
  --assert #"^(65)"  = ( #"a" + ( #"^(03)" + #"^(01)" ))
  --test-- "byte-auto-154"
  --assert #"^(05)"  = ( #"^(03)" + #"^(02)" )
  --test-- "byte-auto-155"
      ba-b1: #"^(03)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-156"
  --assert #"^(66)"  = ( #"a" + ( #"^(03)" + #"^(02)" ))
  --test-- "byte-auto-157"
  --assert #"^(06)"  = ( #"^(03)" + #"^(03)" )
  --test-- "byte-auto-158"
      ba-b1: #"^(03)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-159"
  --assert #"^(67)"  = ( #"a" + ( #"^(03)" + #"^(03)" ))
  --test-- "byte-auto-160"
  --assert #"^(08)"  = ( #"^(03)" + #"^(05)" )
  --test-- "byte-auto-161"
      ba-b1: #"^(03)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(08)"  = ba-b3 
  --test-- "byte-auto-162"
  --assert #"^(69)"  = ( #"a" + ( #"^(03)" + #"^(05)" ))
  --test-- "byte-auto-163"
  --assert #"^(F3)"  = ( #"^(03)" + #"^(F0)" )
  --test-- "byte-auto-164"
      ba-b1: #"^(03)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F3)"  = ba-b3 
  --test-- "byte-auto-165"
  --assert #"^(54)"  = ( #"a" + ( #"^(03)" + #"^(F0)" ))
  --test-- "byte-auto-166"
  --assert #"^(00)"  = ( #"^(03)" + #"^(FD)" )
  --test-- "byte-auto-167"
      ba-b1: #"^(03)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-168"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" + #"^(FD)" ))
  --test-- "byte-auto-169"
  --assert #"^(01)"  = ( #"^(03)" + #"^(FE)" )
  --test-- "byte-auto-170"
      ba-b1: #"^(03)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-171"
  --assert #"^(62)"  = ( #"a" + ( #"^(03)" + #"^(FE)" ))
  --test-- "byte-auto-172"
  --assert #"^(81)"  = ( #"^(03)" + #"^(7E)" )
  --test-- "byte-auto-173"
      ba-b1: #"^(03)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(81)"  = ba-b3 
  --test-- "byte-auto-174"
  --assert #"^(E2)"  = ( #"a" + ( #"^(03)" + #"^(7E)" ))
  --test-- "byte-auto-175"
  --assert #"^(6E)"  = ( #"^(03)" + #"^(6B)" )
  --test-- "byte-auto-176"
      ba-b1: #"^(03)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(6E)"  = ba-b3 
  --test-- "byte-auto-177"
  --assert #"^(CF)"  = ( #"a" + ( #"^(03)" + #"^(6B)" ))
  --test-- "byte-auto-178"
  --assert #"^(FE)"  = ( #"^(03)" + #"^(FB)" )
  --test-- "byte-auto-179"
      ba-b1: #"^(03)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-180"
  --assert #"^(5F)"  = ( #"a" + ( #"^(03)" + #"^(FB)" ))
  --test-- "byte-auto-181"
  --assert #"^(05)"  = ( #"^(05)" + #"^(00)" )
  --test-- "byte-auto-182"
      ba-b1: #"^(05)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-183"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" + #"^(00)" ))
  --test-- "byte-auto-184"
  --assert #"^(04)"  = ( #"^(05)" + #"^(FF)" )
  --test-- "byte-auto-185"
      ba-b1: #"^(05)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-186"
  --assert #"^(65)"  = ( #"a" + ( #"^(05)" + #"^(FF)" ))
  --test-- "byte-auto-187"
  --assert #"^(06)"  = ( #"^(05)" + #"^(01)" )
  --test-- "byte-auto-188"
      ba-b1: #"^(05)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-189"
  --assert #"^(67)"  = ( #"a" + ( #"^(05)" + #"^(01)" ))
  --test-- "byte-auto-190"
  --assert #"^(07)"  = ( #"^(05)" + #"^(02)" )
  --test-- "byte-auto-191"
      ba-b1: #"^(05)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(07)"  = ba-b3 
  --test-- "byte-auto-192"
  --assert #"^(68)"  = ( #"a" + ( #"^(05)" + #"^(02)" ))
  --test-- "byte-auto-193"
  --assert #"^(08)"  = ( #"^(05)" + #"^(03)" )
  --test-- "byte-auto-194"
      ba-b1: #"^(05)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(08)"  = ba-b3 
  --test-- "byte-auto-195"
  --assert #"^(69)"  = ( #"a" + ( #"^(05)" + #"^(03)" ))
  --test-- "byte-auto-196"
  --assert #"^(0A)"  = ( #"^(05)" + #"^(05)" )
  --test-- "byte-auto-197"
      ba-b1: #"^(05)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(0A)"  = ba-b3 
  --test-- "byte-auto-198"
  --assert #"^(6B)"  = ( #"a" + ( #"^(05)" + #"^(05)" ))
  --test-- "byte-auto-199"
  --assert #"^(F5)"  = ( #"^(05)" + #"^(F0)" )
  --test-- "byte-auto-200"
      ba-b1: #"^(05)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F5)"  = ba-b3 
  --test-- "byte-auto-201"
  --assert #"^(56)"  = ( #"a" + ( #"^(05)" + #"^(F0)" ))
  --test-- "byte-auto-202"
  --assert #"^(02)"  = ( #"^(05)" + #"^(FD)" )
  --test-- "byte-auto-203"
      ba-b1: #"^(05)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-204"
  --assert #"^(63)"  = ( #"a" + ( #"^(05)" + #"^(FD)" ))
  --test-- "byte-auto-205"
  --assert #"^(03)"  = ( #"^(05)" + #"^(FE)" )
  --test-- "byte-auto-206"
      ba-b1: #"^(05)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-207"
  --assert #"^(64)"  = ( #"a" + ( #"^(05)" + #"^(FE)" ))
  --test-- "byte-auto-208"
  --assert #"^(83)"  = ( #"^(05)" + #"^(7E)" )
  --test-- "byte-auto-209"
      ba-b1: #"^(05)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(83)"  = ba-b3 
  --test-- "byte-auto-210"
  --assert #"^(E4)"  = ( #"a" + ( #"^(05)" + #"^(7E)" ))
  --test-- "byte-auto-211"
  --assert #"^(70)"  = ( #"^(05)" + #"^(6B)" )
  --test-- "byte-auto-212"
      ba-b1: #"^(05)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(70)"  = ba-b3 
  --test-- "byte-auto-213"
  --assert #"^(D1)"  = ( #"a" + ( #"^(05)" + #"^(6B)" ))
  --test-- "byte-auto-214"
  --assert #"^(00)"  = ( #"^(05)" + #"^(FB)" )
  --test-- "byte-auto-215"
      ba-b1: #"^(05)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-216"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" + #"^(FB)" ))
  --test-- "byte-auto-217"
  --assert #"^(F0)"  = ( #"^(F0)" + #"^(00)" )
  --test-- "byte-auto-218"
      ba-b1: #"^(F0)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-219"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" + #"^(00)" ))
  --test-- "byte-auto-220"
  --assert #"^(EF)"  = ( #"^(F0)" + #"^(FF)" )
  --test-- "byte-auto-221"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(EF)"  = ba-b3 
  --test-- "byte-auto-222"
  --assert #"^(50)"  = ( #"a" + ( #"^(F0)" + #"^(FF)" ))
  --test-- "byte-auto-223"
  --assert #"^(F1)"  = ( #"^(F0)" + #"^(01)" )
  --test-- "byte-auto-224"
      ba-b1: #"^(F0)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F1)"  = ba-b3 
  --test-- "byte-auto-225"
  --assert #"^(52)"  = ( #"a" + ( #"^(F0)" + #"^(01)" ))
  --test-- "byte-auto-226"
  --assert #"^(F2)"  = ( #"^(F0)" + #"^(02)" )
  --test-- "byte-auto-227"
      ba-b1: #"^(F0)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F2)"  = ba-b3 
  --test-- "byte-auto-228"
  --assert #"^(53)"  = ( #"a" + ( #"^(F0)" + #"^(02)" ))
  --test-- "byte-auto-229"
  --assert #"^(F3)"  = ( #"^(F0)" + #"^(03)" )
  --test-- "byte-auto-230"
      ba-b1: #"^(F0)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F3)"  = ba-b3 
  --test-- "byte-auto-231"
  --assert #"^(54)"  = ( #"a" + ( #"^(F0)" + #"^(03)" ))
  --test-- "byte-auto-232"
  --assert #"^(F5)"  = ( #"^(F0)" + #"^(05)" )
  --test-- "byte-auto-233"
      ba-b1: #"^(F0)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F5)"  = ba-b3 
  --test-- "byte-auto-234"
  --assert #"^(56)"  = ( #"a" + ( #"^(F0)" + #"^(05)" ))
  --test-- "byte-auto-235"
  --assert #"^(E0)"  = ( #"^(F0)" + #"^(F0)" )
  --test-- "byte-auto-236"
      ba-b1: #"^(F0)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(E0)"  = ba-b3 
  --test-- "byte-auto-237"
  --assert #"^(41)"  = ( #"a" + ( #"^(F0)" + #"^(F0)" ))
  --test-- "byte-auto-238"
  --assert #"^(ED)"  = ( #"^(F0)" + #"^(FD)" )
  --test-- "byte-auto-239"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(ED)"  = ba-b3 
  --test-- "byte-auto-240"
  --assert #"^(4E)"  = ( #"a" + ( #"^(F0)" + #"^(FD)" ))
  --test-- "byte-auto-241"
  --assert #"^(EE)"  = ( #"^(F0)" + #"^(FE)" )
  --test-- "byte-auto-242"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(EE)"  = ba-b3 
  --test-- "byte-auto-243"
  --assert #"^(4F)"  = ( #"a" + ( #"^(F0)" + #"^(FE)" ))
  --test-- "byte-auto-244"
  --assert #"^(6E)"  = ( #"^(F0)" + #"^(7E)" )
  --test-- "byte-auto-245"
      ba-b1: #"^(F0)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(6E)"  = ba-b3 
  --test-- "byte-auto-246"
  --assert #"^(CF)"  = ( #"a" + ( #"^(F0)" + #"^(7E)" ))
  --test-- "byte-auto-247"
  --assert #"^(5B)"  = ( #"^(F0)" + #"^(6B)" )
  --test-- "byte-auto-248"
      ba-b1: #"^(F0)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(5B)"  = ba-b3 
  --test-- "byte-auto-249"
  --assert #"^(BC)"  = ( #"a" + ( #"^(F0)" + #"^(6B)" ))
  --test-- "byte-auto-250"
  --assert #"^(EB)"  = ( #"^(F0)" + #"^(FB)" )
  --test-- "byte-auto-251"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(EB)"  = ba-b3 
  --test-- "byte-auto-252"
  --assert #"^(4C)"  = ( #"a" + ( #"^(F0)" + #"^(FB)" ))
  --test-- "byte-auto-253"
  --assert #"^(FD)"  = ( #"^(FD)" + #"^(00)" )
  --test-- "byte-auto-254"
      ba-b1: #"^(FD)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-255"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" + #"^(00)" ))
  --test-- "byte-auto-256"
  --assert #"^(FC)"  = ( #"^(FD)" + #"^(FF)" )
  --test-- "byte-auto-257"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-258"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FD)" + #"^(FF)" ))
  --test-- "byte-auto-259"
  --assert #"^(FE)"  = ( #"^(FD)" + #"^(01)" )
  --test-- "byte-auto-260"
      ba-b1: #"^(FD)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-261"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FD)" + #"^(01)" ))
  --test-- "byte-auto-262"
  --assert #"^(FF)"  = ( #"^(FD)" + #"^(02)" )
  --test-- "byte-auto-263"
      ba-b1: #"^(FD)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-264"
  --assert #"^(60)"  = ( #"a" + ( #"^(FD)" + #"^(02)" ))
  --test-- "byte-auto-265"
  --assert #"^(00)"  = ( #"^(FD)" + #"^(03)" )
  --test-- "byte-auto-266"
      ba-b1: #"^(FD)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-267"
  --assert #"^(61)"  = ( #"a" + ( #"^(FD)" + #"^(03)" ))
  --test-- "byte-auto-268"
  --assert #"^(02)"  = ( #"^(FD)" + #"^(05)" )
  --test-- "byte-auto-269"
      ba-b1: #"^(FD)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-270"
  --assert #"^(63)"  = ( #"a" + ( #"^(FD)" + #"^(05)" ))
  --test-- "byte-auto-271"
  --assert #"^(ED)"  = ( #"^(FD)" + #"^(F0)" )
  --test-- "byte-auto-272"
      ba-b1: #"^(FD)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(ED)"  = ba-b3 
  --test-- "byte-auto-273"
  --assert #"^(4E)"  = ( #"a" + ( #"^(FD)" + #"^(F0)" ))
  --test-- "byte-auto-274"
  --assert #"^(FA)"  = ( #"^(FD)" + #"^(FD)" )
  --test-- "byte-auto-275"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-276"
  --assert #"^(5B)"  = ( #"a" + ( #"^(FD)" + #"^(FD)" ))
  --test-- "byte-auto-277"
  --assert #"^(FB)"  = ( #"^(FD)" + #"^(FE)" )
  --test-- "byte-auto-278"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-279"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FD)" + #"^(FE)" ))
  --test-- "byte-auto-280"
  --assert #"^(7B)"  = ( #"^(FD)" + #"^(7E)" )
  --test-- "byte-auto-281"
      ba-b1: #"^(FD)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(7B)"  = ba-b3 
  --test-- "byte-auto-282"
  --assert #"^(DC)"  = ( #"a" + ( #"^(FD)" + #"^(7E)" ))
  --test-- "byte-auto-283"
  --assert #"^(68)"  = ( #"^(FD)" + #"^(6B)" )
  --test-- "byte-auto-284"
      ba-b1: #"^(FD)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(68)"  = ba-b3 
  --test-- "byte-auto-285"
  --assert #"^(C9)"  = ( #"a" + ( #"^(FD)" + #"^(6B)" ))
  --test-- "byte-auto-286"
  --assert #"^(F8)"  = ( #"^(FD)" + #"^(FB)" )
  --test-- "byte-auto-287"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F8)"  = ba-b3 
  --test-- "byte-auto-288"
  --assert #"^(59)"  = ( #"a" + ( #"^(FD)" + #"^(FB)" ))
  --test-- "byte-auto-289"
  --assert #"^(FE)"  = ( #"^(FE)" + #"^(00)" )
  --test-- "byte-auto-290"
      ba-b1: #"^(FE)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-291"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" + #"^(00)" ))
  --test-- "byte-auto-292"
  --assert #"^(FD)"  = ( #"^(FE)" + #"^(FF)" )
  --test-- "byte-auto-293"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-294"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FE)" + #"^(FF)" ))
  --test-- "byte-auto-295"
  --assert #"^(FF)"  = ( #"^(FE)" + #"^(01)" )
  --test-- "byte-auto-296"
      ba-b1: #"^(FE)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-297"
  --assert #"^(60)"  = ( #"a" + ( #"^(FE)" + #"^(01)" ))
  --test-- "byte-auto-298"
  --assert #"^(00)"  = ( #"^(FE)" + #"^(02)" )
  --test-- "byte-auto-299"
      ba-b1: #"^(FE)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-300"
  --assert #"^(61)"  = ( #"a" + ( #"^(FE)" + #"^(02)" ))
  --test-- "byte-auto-301"
  --assert #"^(01)"  = ( #"^(FE)" + #"^(03)" )
  --test-- "byte-auto-302"
      ba-b1: #"^(FE)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-303"
  --assert #"^(62)"  = ( #"a" + ( #"^(FE)" + #"^(03)" ))
  --test-- "byte-auto-304"
  --assert #"^(03)"  = ( #"^(FE)" + #"^(05)" )
  --test-- "byte-auto-305"
      ba-b1: #"^(FE)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-306"
  --assert #"^(64)"  = ( #"a" + ( #"^(FE)" + #"^(05)" ))
  --test-- "byte-auto-307"
  --assert #"^(EE)"  = ( #"^(FE)" + #"^(F0)" )
  --test-- "byte-auto-308"
      ba-b1: #"^(FE)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(EE)"  = ba-b3 
  --test-- "byte-auto-309"
  --assert #"^(4F)"  = ( #"a" + ( #"^(FE)" + #"^(F0)" ))
  --test-- "byte-auto-310"
  --assert #"^(FB)"  = ( #"^(FE)" + #"^(FD)" )
  --test-- "byte-auto-311"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-312"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FE)" + #"^(FD)" ))
  --test-- "byte-auto-313"
  --assert #"^(FC)"  = ( #"^(FE)" + #"^(FE)" )
  --test-- "byte-auto-314"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-315"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FE)" + #"^(FE)" ))
  --test-- "byte-auto-316"
  --assert #"^(7C)"  = ( #"^(FE)" + #"^(7E)" )
  --test-- "byte-auto-317"
      ba-b1: #"^(FE)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(7C)"  = ba-b3 
  --test-- "byte-auto-318"
  --assert #"^(DD)"  = ( #"a" + ( #"^(FE)" + #"^(7E)" ))
  --test-- "byte-auto-319"
  --assert #"^(69)"  = ( #"^(FE)" + #"^(6B)" )
  --test-- "byte-auto-320"
      ba-b1: #"^(FE)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(69)"  = ba-b3 
  --test-- "byte-auto-321"
  --assert #"^(CA)"  = ( #"a" + ( #"^(FE)" + #"^(6B)" ))
  --test-- "byte-auto-322"
  --assert #"^(F9)"  = ( #"^(FE)" + #"^(FB)" )
  --test-- "byte-auto-323"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F9)"  = ba-b3 
  --test-- "byte-auto-324"
  --assert #"^(5A)"  = ( #"a" + ( #"^(FE)" + #"^(FB)" ))
  --test-- "byte-auto-325"
  --assert #"^(7E)"  = ( #"^(7E)" + #"^(00)" )
  --test-- "byte-auto-326"
      ba-b1: #"^(7E)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-327"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" + #"^(00)" ))
  --test-- "byte-auto-328"
  --assert #"^(7D)"  = ( #"^(7E)" + #"^(FF)" )
  --test-- "byte-auto-329"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(7D)"  = ba-b3 
  --test-- "byte-auto-330"
  --assert #"^(DE)"  = ( #"a" + ( #"^(7E)" + #"^(FF)" ))
  --test-- "byte-auto-331"
  --assert #"^(7F)"  = ( #"^(7E)" + #"^(01)" )
  --test-- "byte-auto-332"
      ba-b1: #"^(7E)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-333"
  --assert #"^(E0)"  = ( #"a" + ( #"^(7E)" + #"^(01)" ))
  --test-- "byte-auto-334"
  --assert #"^(80)"  = ( #"^(7E)" + #"^(02)" )
  --test-- "byte-auto-335"
      ba-b1: #"^(7E)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(80)"  = ba-b3 
  --test-- "byte-auto-336"
  --assert #"^(E1)"  = ( #"a" + ( #"^(7E)" + #"^(02)" ))
  --test-- "byte-auto-337"
  --assert #"^(81)"  = ( #"^(7E)" + #"^(03)" )
  --test-- "byte-auto-338"
      ba-b1: #"^(7E)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(81)"  = ba-b3 
  --test-- "byte-auto-339"
  --assert #"^(E2)"  = ( #"a" + ( #"^(7E)" + #"^(03)" ))
  --test-- "byte-auto-340"
  --assert #"^(83)"  = ( #"^(7E)" + #"^(05)" )
  --test-- "byte-auto-341"
      ba-b1: #"^(7E)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(83)"  = ba-b3 
  --test-- "byte-auto-342"
  --assert #"^(E4)"  = ( #"a" + ( #"^(7E)" + #"^(05)" ))
  --test-- "byte-auto-343"
  --assert #"^(6E)"  = ( #"^(7E)" + #"^(F0)" )
  --test-- "byte-auto-344"
      ba-b1: #"^(7E)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(6E)"  = ba-b3 
  --test-- "byte-auto-345"
  --assert #"^(CF)"  = ( #"a" + ( #"^(7E)" + #"^(F0)" ))
  --test-- "byte-auto-346"
  --assert #"^(7B)"  = ( #"^(7E)" + #"^(FD)" )
  --test-- "byte-auto-347"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(7B)"  = ba-b3 
  --test-- "byte-auto-348"
  --assert #"^(DC)"  = ( #"a" + ( #"^(7E)" + #"^(FD)" ))
  --test-- "byte-auto-349"
  --assert #"^(7C)"  = ( #"^(7E)" + #"^(FE)" )
  --test-- "byte-auto-350"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(7C)"  = ba-b3 
  --test-- "byte-auto-351"
  --assert #"^(DD)"  = ( #"a" + ( #"^(7E)" + #"^(FE)" ))
  --test-- "byte-auto-352"
  --assert #"^(FC)"  = ( #"^(7E)" + #"^(7E)" )
  --test-- "byte-auto-353"
      ba-b1: #"^(7E)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-354"
  --assert #"^(5D)"  = ( #"a" + ( #"^(7E)" + #"^(7E)" ))
  --test-- "byte-auto-355"
  --assert #"^(E9)"  = ( #"^(7E)" + #"^(6B)" )
  --test-- "byte-auto-356"
      ba-b1: #"^(7E)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(E9)"  = ba-b3 
  --test-- "byte-auto-357"
  --assert #"^(4A)"  = ( #"a" + ( #"^(7E)" + #"^(6B)" ))
  --test-- "byte-auto-358"
  --assert #"^(79)"  = ( #"^(7E)" + #"^(FB)" )
  --test-- "byte-auto-359"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(79)"  = ba-b3 
  --test-- "byte-auto-360"
  --assert #"^(DA)"  = ( #"a" + ( #"^(7E)" + #"^(FB)" ))
  --test-- "byte-auto-361"
  --assert #"^(6B)"  = ( #"^(6B)" + #"^(00)" )
  --test-- "byte-auto-362"
      ba-b1: #"^(6B)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-363"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" + #"^(00)" ))
  --test-- "byte-auto-364"
  --assert #"^(6A)"  = ( #"^(6B)" + #"^(FF)" )
  --test-- "byte-auto-365"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(6A)"  = ba-b3 
  --test-- "byte-auto-366"
  --assert #"^(CB)"  = ( #"a" + ( #"^(6B)" + #"^(FF)" ))
  --test-- "byte-auto-367"
  --assert #"^(6C)"  = ( #"^(6B)" + #"^(01)" )
  --test-- "byte-auto-368"
      ba-b1: #"^(6B)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(6C)"  = ba-b3 
  --test-- "byte-auto-369"
  --assert #"^(CD)"  = ( #"a" + ( #"^(6B)" + #"^(01)" ))
  --test-- "byte-auto-370"
  --assert #"^(6D)"  = ( #"^(6B)" + #"^(02)" )
  --test-- "byte-auto-371"
      ba-b1: #"^(6B)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(6D)"  = ba-b3 
  --test-- "byte-auto-372"
  --assert #"^(CE)"  = ( #"a" + ( #"^(6B)" + #"^(02)" ))
  --test-- "byte-auto-373"
  --assert #"^(6E)"  = ( #"^(6B)" + #"^(03)" )
  --test-- "byte-auto-374"
      ba-b1: #"^(6B)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(6E)"  = ba-b3 
  --test-- "byte-auto-375"
  --assert #"^(CF)"  = ( #"a" + ( #"^(6B)" + #"^(03)" ))
  --test-- "byte-auto-376"
  --assert #"^(70)"  = ( #"^(6B)" + #"^(05)" )
  --test-- "byte-auto-377"
      ba-b1: #"^(6B)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(70)"  = ba-b3 
  --test-- "byte-auto-378"
  --assert #"^(D1)"  = ( #"a" + ( #"^(6B)" + #"^(05)" ))
  --test-- "byte-auto-379"
  --assert #"^(5B)"  = ( #"^(6B)" + #"^(F0)" )
  --test-- "byte-auto-380"
      ba-b1: #"^(6B)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(5B)"  = ba-b3 
  --test-- "byte-auto-381"
  --assert #"^(BC)"  = ( #"a" + ( #"^(6B)" + #"^(F0)" ))
  --test-- "byte-auto-382"
  --assert #"^(68)"  = ( #"^(6B)" + #"^(FD)" )
  --test-- "byte-auto-383"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(68)"  = ba-b3 
  --test-- "byte-auto-384"
  --assert #"^(C9)"  = ( #"a" + ( #"^(6B)" + #"^(FD)" ))
  --test-- "byte-auto-385"
  --assert #"^(69)"  = ( #"^(6B)" + #"^(FE)" )
  --test-- "byte-auto-386"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(69)"  = ba-b3 
  --test-- "byte-auto-387"
  --assert #"^(CA)"  = ( #"a" + ( #"^(6B)" + #"^(FE)" ))
  --test-- "byte-auto-388"
  --assert #"^(E9)"  = ( #"^(6B)" + #"^(7E)" )
  --test-- "byte-auto-389"
      ba-b1: #"^(6B)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(E9)"  = ba-b3 
  --test-- "byte-auto-390"
  --assert #"^(4A)"  = ( #"a" + ( #"^(6B)" + #"^(7E)" ))
  --test-- "byte-auto-391"
  --assert #"^(D6)"  = ( #"^(6B)" + #"^(6B)" )
  --test-- "byte-auto-392"
      ba-b1: #"^(6B)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(D6)"  = ba-b3 
  --test-- "byte-auto-393"
  --assert #"^(37)"  = ( #"a" + ( #"^(6B)" + #"^(6B)" ))
  --test-- "byte-auto-394"
  --assert #"^(66)"  = ( #"^(6B)" + #"^(FB)" )
  --test-- "byte-auto-395"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(66)"  = ba-b3 
  --test-- "byte-auto-396"
  --assert #"^(C7)"  = ( #"a" + ( #"^(6B)" + #"^(FB)" ))
  --test-- "byte-auto-397"
  --assert #"^(FB)"  = ( #"^(FB)" + #"^(00)" )
  --test-- "byte-auto-398"
      ba-b1: #"^(FB)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-399"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" + #"^(00)" ))
  --test-- "byte-auto-400"
  --assert #"^(FA)"  = ( #"^(FB)" + #"^(FF)" )
  --test-- "byte-auto-401"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-402"
  --assert #"^(5B)"  = ( #"a" + ( #"^(FB)" + #"^(FF)" ))
  --test-- "byte-auto-403"
  --assert #"^(FC)"  = ( #"^(FB)" + #"^(01)" )
  --test-- "byte-auto-404"
      ba-b1: #"^(FB)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-405"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FB)" + #"^(01)" ))
  --test-- "byte-auto-406"
  --assert #"^(FD)"  = ( #"^(FB)" + #"^(02)" )
  --test-- "byte-auto-407"
      ba-b1: #"^(FB)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-408"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FB)" + #"^(02)" ))
  --test-- "byte-auto-409"
  --assert #"^(FE)"  = ( #"^(FB)" + #"^(03)" )
  --test-- "byte-auto-410"
      ba-b1: #"^(FB)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-411"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FB)" + #"^(03)" ))
  --test-- "byte-auto-412"
  --assert #"^(00)"  = ( #"^(FB)" + #"^(05)" )
  --test-- "byte-auto-413"
      ba-b1: #"^(FB)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-414"
  --assert #"^(61)"  = ( #"a" + ( #"^(FB)" + #"^(05)" ))
  --test-- "byte-auto-415"
  --assert #"^(EB)"  = ( #"^(FB)" + #"^(F0)" )
  --test-- "byte-auto-416"
      ba-b1: #"^(FB)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(EB)"  = ba-b3 
  --test-- "byte-auto-417"
  --assert #"^(4C)"  = ( #"a" + ( #"^(FB)" + #"^(F0)" ))
  --test-- "byte-auto-418"
  --assert #"^(F8)"  = ( #"^(FB)" + #"^(FD)" )
  --test-- "byte-auto-419"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F8)"  = ba-b3 
  --test-- "byte-auto-420"
  --assert #"^(59)"  = ( #"a" + ( #"^(FB)" + #"^(FD)" ))
  --test-- "byte-auto-421"
  --assert #"^(F9)"  = ( #"^(FB)" + #"^(FE)" )
  --test-- "byte-auto-422"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F9)"  = ba-b3 
  --test-- "byte-auto-423"
  --assert #"^(5A)"  = ( #"a" + ( #"^(FB)" + #"^(FE)" ))
  --test-- "byte-auto-424"
  --assert #"^(79)"  = ( #"^(FB)" + #"^(7E)" )
  --test-- "byte-auto-425"
      ba-b1: #"^(FB)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(79)"  = ba-b3 
  --test-- "byte-auto-426"
  --assert #"^(DA)"  = ( #"a" + ( #"^(FB)" + #"^(7E)" ))
  --test-- "byte-auto-427"
  --assert #"^(66)"  = ( #"^(FB)" + #"^(6B)" )
  --test-- "byte-auto-428"
      ba-b1: #"^(FB)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(66)"  = ba-b3 
  --test-- "byte-auto-429"
  --assert #"^(C7)"  = ( #"a" + ( #"^(FB)" + #"^(6B)" ))
  --test-- "byte-auto-430"
  --assert #"^(F6)"  = ( #"^(FB)" + #"^(FB)" )
  --test-- "byte-auto-431"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 + ba-b2
  --assert #"^(F6)"  = ba-b3 
  --test-- "byte-auto-432"
  --assert #"^(57)"  = ( #"a" + ( #"^(FB)" + #"^(FB)" ))
  --test-- "byte-auto-433"
  --assert #"^(00)"  = ( #"^(00)" - #"^(00)" )
  --test-- "byte-auto-434"
      ba-b1: #"^(00)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-435"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" - #"^(00)" ))
  --test-- "byte-auto-436"
  --assert #"^(01)"  = ( #"^(00)" - #"^(FF)" )
  --test-- "byte-auto-437"
      ba-b1: #"^(00)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-438"
  --assert #"^(62)"  = ( #"a" + ( #"^(00)" - #"^(FF)" ))
  --test-- "byte-auto-439"
  --assert #"^(FF)"  = ( #"^(00)" - #"^(01)" )
  --test-- "byte-auto-440"
      ba-b1: #"^(00)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-441"
  --assert #"^(60)"  = ( #"a" + ( #"^(00)" - #"^(01)" ))
  --test-- "byte-auto-442"
  --assert #"^(FE)"  = ( #"^(00)" - #"^(02)" )
  --test-- "byte-auto-443"
      ba-b1: #"^(00)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-444"
  --assert #"^(5F)"  = ( #"a" + ( #"^(00)" - #"^(02)" ))
  --test-- "byte-auto-445"
  --assert #"^(FD)"  = ( #"^(00)" - #"^(03)" )
  --test-- "byte-auto-446"
      ba-b1: #"^(00)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-447"
  --assert #"^(5E)"  = ( #"a" + ( #"^(00)" - #"^(03)" ))
  --test-- "byte-auto-448"
  --assert #"^(FB)"  = ( #"^(00)" - #"^(05)" )
  --test-- "byte-auto-449"
      ba-b1: #"^(00)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-450"
  --assert #"^(5C)"  = ( #"a" + ( #"^(00)" - #"^(05)" ))
  --test-- "byte-auto-451"
  --assert #"^(10)"  = ( #"^(00)" - #"^(F0)" )
  --test-- "byte-auto-452"
      ba-b1: #"^(00)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(10)"  = ba-b3 
  --test-- "byte-auto-453"
  --assert #"^(71)"  = ( #"a" + ( #"^(00)" - #"^(F0)" ))
  --test-- "byte-auto-454"
  --assert #"^(03)"  = ( #"^(00)" - #"^(FD)" )
  --test-- "byte-auto-455"
      ba-b1: #"^(00)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-456"
  --assert #"^(64)"  = ( #"a" + ( #"^(00)" - #"^(FD)" ))
  --test-- "byte-auto-457"
  --assert #"^(02)"  = ( #"^(00)" - #"^(FE)" )
  --test-- "byte-auto-458"
      ba-b1: #"^(00)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-459"
  --assert #"^(63)"  = ( #"a" + ( #"^(00)" - #"^(FE)" ))
  --test-- "byte-auto-460"
  --assert #"^(82)"  = ( #"^(00)" - #"^(7E)" )
  --test-- "byte-auto-461"
      ba-b1: #"^(00)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(82)"  = ba-b3 
  --test-- "byte-auto-462"
  --assert #"^(E3)"  = ( #"a" + ( #"^(00)" - #"^(7E)" ))
  --test-- "byte-auto-463"
  --assert #"^(95)"  = ( #"^(00)" - #"^(6B)" )
  --test-- "byte-auto-464"
      ba-b1: #"^(00)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(95)"  = ba-b3 
  --test-- "byte-auto-465"
  --assert #"^(F6)"  = ( #"a" + ( #"^(00)" - #"^(6B)" ))
  --test-- "byte-auto-466"
  --assert #"^(05)"  = ( #"^(00)" - #"^(FB)" )
  --test-- "byte-auto-467"
      ba-b1: #"^(00)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-468"
  --assert #"^(66)"  = ( #"a" + ( #"^(00)" - #"^(FB)" ))
  --test-- "byte-auto-469"
  --assert #"^(FF)"  = ( #"^(FF)" - #"^(00)" )
  --test-- "byte-auto-470"
      ba-b1: #"^(FF)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-471"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" - #"^(00)" ))
  --test-- "byte-auto-472"
  --assert #"^(00)"  = ( #"^(FF)" - #"^(FF)" )
  --test-- "byte-auto-473"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-474"
  --assert #"^(61)"  = ( #"a" + ( #"^(FF)" - #"^(FF)" ))
  --test-- "byte-auto-475"
  --assert #"^(FE)"  = ( #"^(FF)" - #"^(01)" )
  --test-- "byte-auto-476"
      ba-b1: #"^(FF)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-477"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FF)" - #"^(01)" ))
  --test-- "byte-auto-478"
  --assert #"^(FD)"  = ( #"^(FF)" - #"^(02)" )
  --test-- "byte-auto-479"
      ba-b1: #"^(FF)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-480"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FF)" - #"^(02)" ))
  --test-- "byte-auto-481"
  --assert #"^(FC)"  = ( #"^(FF)" - #"^(03)" )
  --test-- "byte-auto-482"
      ba-b1: #"^(FF)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-483"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FF)" - #"^(03)" ))
  --test-- "byte-auto-484"
  --assert #"^(FA)"  = ( #"^(FF)" - #"^(05)" )
  --test-- "byte-auto-485"
      ba-b1: #"^(FF)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-486"
  --assert #"^(5B)"  = ( #"a" + ( #"^(FF)" - #"^(05)" ))
  --test-- "byte-auto-487"
  --assert #"^(0F)"  = ( #"^(FF)" - #"^(F0)" )
  --test-- "byte-auto-488"
      ba-b1: #"^(FF)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(0F)"  = ba-b3 
  --test-- "byte-auto-489"
  --assert #"^(70)"  = ( #"a" + ( #"^(FF)" - #"^(F0)" ))
  --test-- "byte-auto-490"
  --assert #"^(02)"  = ( #"^(FF)" - #"^(FD)" )
  --test-- "byte-auto-491"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-492"
  --assert #"^(63)"  = ( #"a" + ( #"^(FF)" - #"^(FD)" ))
  --test-- "byte-auto-493"
  --assert #"^(01)"  = ( #"^(FF)" - #"^(FE)" )
  --test-- "byte-auto-494"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-495"
  --assert #"^(62)"  = ( #"a" + ( #"^(FF)" - #"^(FE)" ))
  --test-- "byte-auto-496"
  --assert #"^(81)"  = ( #"^(FF)" - #"^(7E)" )
  --test-- "byte-auto-497"
      ba-b1: #"^(FF)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(81)"  = ba-b3 
  --test-- "byte-auto-498"
  --assert #"^(E2)"  = ( #"a" + ( #"^(FF)" - #"^(7E)" ))
  --test-- "byte-auto-499"
  --assert #"^(94)"  = ( #"^(FF)" - #"^(6B)" )
  --test-- "byte-auto-500"
      ba-b1: #"^(FF)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(94)"  = ba-b3 
  --test-- "byte-auto-501"
  --assert #"^(F5)"  = ( #"a" + ( #"^(FF)" - #"^(6B)" ))
  --test-- "byte-auto-502"
  --assert #"^(04)"  = ( #"^(FF)" - #"^(FB)" )
  --test-- "byte-auto-503"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-504"
  --assert #"^(65)"  = ( #"a" + ( #"^(FF)" - #"^(FB)" ))
  --test-- "byte-auto-505"
  --assert #"^(01)"  = ( #"^(01)" - #"^(00)" )
  --test-- "byte-auto-506"
      ba-b1: #"^(01)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-507"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" - #"^(00)" ))
  --test-- "byte-auto-508"
  --assert #"^(02)"  = ( #"^(01)" - #"^(FF)" )
  --test-- "byte-auto-509"
      ba-b1: #"^(01)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-510"
  --assert #"^(63)"  = ( #"a" + ( #"^(01)" - #"^(FF)" ))
  --test-- "byte-auto-511"
  --assert #"^(00)"  = ( #"^(01)" - #"^(01)" )
  --test-- "byte-auto-512"
      ba-b1: #"^(01)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-513"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" - #"^(01)" ))
  --test-- "byte-auto-514"
  --assert #"^(FF)"  = ( #"^(01)" - #"^(02)" )
  --test-- "byte-auto-515"
      ba-b1: #"^(01)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-516"
  --assert #"^(60)"  = ( #"a" + ( #"^(01)" - #"^(02)" ))
  --test-- "byte-auto-517"
  --assert #"^(FE)"  = ( #"^(01)" - #"^(03)" )
  --test-- "byte-auto-518"
      ba-b1: #"^(01)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-519"
  --assert #"^(5F)"  = ( #"a" + ( #"^(01)" - #"^(03)" ))
  --test-- "byte-auto-520"
  --assert #"^(FC)"  = ( #"^(01)" - #"^(05)" )
  --test-- "byte-auto-521"
      ba-b1: #"^(01)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-522"
  --assert #"^(5D)"  = ( #"a" + ( #"^(01)" - #"^(05)" ))
  --test-- "byte-auto-523"
  --assert #"^(11)"  = ( #"^(01)" - #"^(F0)" )
  --test-- "byte-auto-524"
      ba-b1: #"^(01)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(11)"  = ba-b3 
  --test-- "byte-auto-525"
  --assert #"^(72)"  = ( #"a" + ( #"^(01)" - #"^(F0)" ))
  --test-- "byte-auto-526"
  --assert #"^(04)"  = ( #"^(01)" - #"^(FD)" )
  --test-- "byte-auto-527"
      ba-b1: #"^(01)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-528"
  --assert #"^(65)"  = ( #"a" + ( #"^(01)" - #"^(FD)" ))
  --test-- "byte-auto-529"
  --assert #"^(03)"  = ( #"^(01)" - #"^(FE)" )
  --test-- "byte-auto-530"
      ba-b1: #"^(01)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-531"
  --assert #"^(64)"  = ( #"a" + ( #"^(01)" - #"^(FE)" ))
  --test-- "byte-auto-532"
  --assert #"^(83)"  = ( #"^(01)" - #"^(7E)" )
  --test-- "byte-auto-533"
      ba-b1: #"^(01)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(83)"  = ba-b3 
  --test-- "byte-auto-534"
  --assert #"^(E4)"  = ( #"a" + ( #"^(01)" - #"^(7E)" ))
  --test-- "byte-auto-535"
  --assert #"^(96)"  = ( #"^(01)" - #"^(6B)" )
  --test-- "byte-auto-536"
      ba-b1: #"^(01)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(96)"  = ba-b3 
  --test-- "byte-auto-537"
  --assert #"^(F7)"  = ( #"a" + ( #"^(01)" - #"^(6B)" ))
  --test-- "byte-auto-538"
  --assert #"^(06)"  = ( #"^(01)" - #"^(FB)" )
  --test-- "byte-auto-539"
      ba-b1: #"^(01)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-540"
  --assert #"^(67)"  = ( #"a" + ( #"^(01)" - #"^(FB)" ))
  --test-- "byte-auto-541"
  --assert #"^(02)"  = ( #"^(02)" - #"^(00)" )
  --test-- "byte-auto-542"
      ba-b1: #"^(02)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-543"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" - #"^(00)" ))
  --test-- "byte-auto-544"
  --assert #"^(03)"  = ( #"^(02)" - #"^(FF)" )
  --test-- "byte-auto-545"
      ba-b1: #"^(02)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-546"
  --assert #"^(64)"  = ( #"a" + ( #"^(02)" - #"^(FF)" ))
  --test-- "byte-auto-547"
  --assert #"^(01)"  = ( #"^(02)" - #"^(01)" )
  --test-- "byte-auto-548"
      ba-b1: #"^(02)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-549"
  --assert #"^(62)"  = ( #"a" + ( #"^(02)" - #"^(01)" ))
  --test-- "byte-auto-550"
  --assert #"^(00)"  = ( #"^(02)" - #"^(02)" )
  --test-- "byte-auto-551"
      ba-b1: #"^(02)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-552"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" - #"^(02)" ))
  --test-- "byte-auto-553"
  --assert #"^(FF)"  = ( #"^(02)" - #"^(03)" )
  --test-- "byte-auto-554"
      ba-b1: #"^(02)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-555"
  --assert #"^(60)"  = ( #"a" + ( #"^(02)" - #"^(03)" ))
  --test-- "byte-auto-556"
  --assert #"^(FD)"  = ( #"^(02)" - #"^(05)" )
  --test-- "byte-auto-557"
      ba-b1: #"^(02)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-558"
  --assert #"^(5E)"  = ( #"a" + ( #"^(02)" - #"^(05)" ))
  --test-- "byte-auto-559"
  --assert #"^(12)"  = ( #"^(02)" - #"^(F0)" )
  --test-- "byte-auto-560"
      ba-b1: #"^(02)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(12)"  = ba-b3 
  --test-- "byte-auto-561"
  --assert #"^(73)"  = ( #"a" + ( #"^(02)" - #"^(F0)" ))
  --test-- "byte-auto-562"
  --assert #"^(05)"  = ( #"^(02)" - #"^(FD)" )
  --test-- "byte-auto-563"
      ba-b1: #"^(02)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-564"
  --assert #"^(66)"  = ( #"a" + ( #"^(02)" - #"^(FD)" ))
  --test-- "byte-auto-565"
  --assert #"^(04)"  = ( #"^(02)" - #"^(FE)" )
  --test-- "byte-auto-566"
      ba-b1: #"^(02)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-567"
  --assert #"^(65)"  = ( #"a" + ( #"^(02)" - #"^(FE)" ))
  --test-- "byte-auto-568"
  --assert #"^(84)"  = ( #"^(02)" - #"^(7E)" )
  --test-- "byte-auto-569"
      ba-b1: #"^(02)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(84)"  = ba-b3 
  --test-- "byte-auto-570"
  --assert #"^(E5)"  = ( #"a" + ( #"^(02)" - #"^(7E)" ))
  --test-- "byte-auto-571"
  --assert #"^(97)"  = ( #"^(02)" - #"^(6B)" )
  --test-- "byte-auto-572"
      ba-b1: #"^(02)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(97)"  = ba-b3 
  --test-- "byte-auto-573"
  --assert #"^(F8)"  = ( #"a" + ( #"^(02)" - #"^(6B)" ))
  --test-- "byte-auto-574"
  --assert #"^(07)"  = ( #"^(02)" - #"^(FB)" )
  --test-- "byte-auto-575"
      ba-b1: #"^(02)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(07)"  = ba-b3 
  --test-- "byte-auto-576"
  --assert #"^(68)"  = ( #"a" + ( #"^(02)" - #"^(FB)" ))
  --test-- "byte-auto-577"
  --assert #"^(03)"  = ( #"^(03)" - #"^(00)" )
  --test-- "byte-auto-578"
      ba-b1: #"^(03)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-579"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" - #"^(00)" ))
  --test-- "byte-auto-580"
  --assert #"^(04)"  = ( #"^(03)" - #"^(FF)" )
  --test-- "byte-auto-581"
      ba-b1: #"^(03)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-582"
  --assert #"^(65)"  = ( #"a" + ( #"^(03)" - #"^(FF)" ))
  --test-- "byte-auto-583"
  --assert #"^(02)"  = ( #"^(03)" - #"^(01)" )
  --test-- "byte-auto-584"
      ba-b1: #"^(03)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-585"
  --assert #"^(63)"  = ( #"a" + ( #"^(03)" - #"^(01)" ))
  --test-- "byte-auto-586"
  --assert #"^(01)"  = ( #"^(03)" - #"^(02)" )
  --test-- "byte-auto-587"
      ba-b1: #"^(03)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-588"
  --assert #"^(62)"  = ( #"a" + ( #"^(03)" - #"^(02)" ))
  --test-- "byte-auto-589"
  --assert #"^(00)"  = ( #"^(03)" - #"^(03)" )
  --test-- "byte-auto-590"
      ba-b1: #"^(03)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-591"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" - #"^(03)" ))
  --test-- "byte-auto-592"
  --assert #"^(FE)"  = ( #"^(03)" - #"^(05)" )
  --test-- "byte-auto-593"
      ba-b1: #"^(03)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-594"
  --assert #"^(5F)"  = ( #"a" + ( #"^(03)" - #"^(05)" ))
  --test-- "byte-auto-595"
  --assert #"^(13)"  = ( #"^(03)" - #"^(F0)" )
  --test-- "byte-auto-596"
      ba-b1: #"^(03)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(13)"  = ba-b3 
  --test-- "byte-auto-597"
  --assert #"^(74)"  = ( #"a" + ( #"^(03)" - #"^(F0)" ))
  --test-- "byte-auto-598"
  --assert #"^(06)"  = ( #"^(03)" - #"^(FD)" )
  --test-- "byte-auto-599"
      ba-b1: #"^(03)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-600"
  --assert #"^(67)"  = ( #"a" + ( #"^(03)" - #"^(FD)" ))
  --test-- "byte-auto-601"
  --assert #"^(05)"  = ( #"^(03)" - #"^(FE)" )
  --test-- "byte-auto-602"
      ba-b1: #"^(03)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-603"
  --assert #"^(66)"  = ( #"a" + ( #"^(03)" - #"^(FE)" ))
  --test-- "byte-auto-604"
  --assert #"^(85)"  = ( #"^(03)" - #"^(7E)" )
  --test-- "byte-auto-605"
      ba-b1: #"^(03)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(85)"  = ba-b3 
  --test-- "byte-auto-606"
  --assert #"^(E6)"  = ( #"a" + ( #"^(03)" - #"^(7E)" ))
  --test-- "byte-auto-607"
  --assert #"^(98)"  = ( #"^(03)" - #"^(6B)" )
  --test-- "byte-auto-608"
      ba-b1: #"^(03)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(98)"  = ba-b3 
  --test-- "byte-auto-609"
  --assert #"^(F9)"  = ( #"a" + ( #"^(03)" - #"^(6B)" ))
  --test-- "byte-auto-610"
  --assert #"^(08)"  = ( #"^(03)" - #"^(FB)" )
  --test-- "byte-auto-611"
      ba-b1: #"^(03)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(08)"  = ba-b3 
  --test-- "byte-auto-612"
  --assert #"^(69)"  = ( #"a" + ( #"^(03)" - #"^(FB)" ))
  --test-- "byte-auto-613"
  --assert #"^(05)"  = ( #"^(05)" - #"^(00)" )
  --test-- "byte-auto-614"
      ba-b1: #"^(05)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-615"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" - #"^(00)" ))
  --test-- "byte-auto-616"
  --assert #"^(06)"  = ( #"^(05)" - #"^(FF)" )
  --test-- "byte-auto-617"
      ba-b1: #"^(05)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-618"
  --assert #"^(67)"  = ( #"a" + ( #"^(05)" - #"^(FF)" ))
  --test-- "byte-auto-619"
  --assert #"^(04)"  = ( #"^(05)" - #"^(01)" )
  --test-- "byte-auto-620"
      ba-b1: #"^(05)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-621"
  --assert #"^(65)"  = ( #"a" + ( #"^(05)" - #"^(01)" ))
  --test-- "byte-auto-622"
  --assert #"^(03)"  = ( #"^(05)" - #"^(02)" )
  --test-- "byte-auto-623"
      ba-b1: #"^(05)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-624"
  --assert #"^(64)"  = ( #"a" + ( #"^(05)" - #"^(02)" ))
  --test-- "byte-auto-625"
  --assert #"^(02)"  = ( #"^(05)" - #"^(03)" )
  --test-- "byte-auto-626"
      ba-b1: #"^(05)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-627"
  --assert #"^(63)"  = ( #"a" + ( #"^(05)" - #"^(03)" ))
  --test-- "byte-auto-628"
  --assert #"^(00)"  = ( #"^(05)" - #"^(05)" )
  --test-- "byte-auto-629"
      ba-b1: #"^(05)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-630"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" - #"^(05)" ))
  --test-- "byte-auto-631"
  --assert #"^(15)"  = ( #"^(05)" - #"^(F0)" )
  --test-- "byte-auto-632"
      ba-b1: #"^(05)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(15)"  = ba-b3 
  --test-- "byte-auto-633"
  --assert #"^(76)"  = ( #"a" + ( #"^(05)" - #"^(F0)" ))
  --test-- "byte-auto-634"
  --assert #"^(08)"  = ( #"^(05)" - #"^(FD)" )
  --test-- "byte-auto-635"
      ba-b1: #"^(05)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(08)"  = ba-b3 
  --test-- "byte-auto-636"
  --assert #"^(69)"  = ( #"a" + ( #"^(05)" - #"^(FD)" ))
  --test-- "byte-auto-637"
  --assert #"^(07)"  = ( #"^(05)" - #"^(FE)" )
  --test-- "byte-auto-638"
      ba-b1: #"^(05)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(07)"  = ba-b3 
  --test-- "byte-auto-639"
  --assert #"^(68)"  = ( #"a" + ( #"^(05)" - #"^(FE)" ))
  --test-- "byte-auto-640"
  --assert #"^(87)"  = ( #"^(05)" - #"^(7E)" )
  --test-- "byte-auto-641"
      ba-b1: #"^(05)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(87)"  = ba-b3 
  --test-- "byte-auto-642"
  --assert #"^(E8)"  = ( #"a" + ( #"^(05)" - #"^(7E)" ))
  --test-- "byte-auto-643"
  --assert #"^(9A)"  = ( #"^(05)" - #"^(6B)" )
  --test-- "byte-auto-644"
      ba-b1: #"^(05)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(9A)"  = ba-b3 
  --test-- "byte-auto-645"
  --assert #"^(FB)"  = ( #"a" + ( #"^(05)" - #"^(6B)" ))
  --test-- "byte-auto-646"
  --assert #"^(0A)"  = ( #"^(05)" - #"^(FB)" )
  --test-- "byte-auto-647"
      ba-b1: #"^(05)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(0A)"  = ba-b3 
  --test-- "byte-auto-648"
  --assert #"^(6B)"  = ( #"a" + ( #"^(05)" - #"^(FB)" ))
  --test-- "byte-auto-649"
  --assert #"^(F0)"  = ( #"^(F0)" - #"^(00)" )
  --test-- "byte-auto-650"
      ba-b1: #"^(F0)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-651"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" - #"^(00)" ))
  --test-- "byte-auto-652"
  --assert #"^(F1)"  = ( #"^(F0)" - #"^(FF)" )
  --test-- "byte-auto-653"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(F1)"  = ba-b3 
  --test-- "byte-auto-654"
  --assert #"^(52)"  = ( #"a" + ( #"^(F0)" - #"^(FF)" ))
  --test-- "byte-auto-655"
  --assert #"^(EF)"  = ( #"^(F0)" - #"^(01)" )
  --test-- "byte-auto-656"
      ba-b1: #"^(F0)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(EF)"  = ba-b3 
  --test-- "byte-auto-657"
  --assert #"^(50)"  = ( #"a" + ( #"^(F0)" - #"^(01)" ))
  --test-- "byte-auto-658"
  --assert #"^(EE)"  = ( #"^(F0)" - #"^(02)" )
  --test-- "byte-auto-659"
      ba-b1: #"^(F0)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(EE)"  = ba-b3 
  --test-- "byte-auto-660"
  --assert #"^(4F)"  = ( #"a" + ( #"^(F0)" - #"^(02)" ))
  --test-- "byte-auto-661"
  --assert #"^(ED)"  = ( #"^(F0)" - #"^(03)" )
  --test-- "byte-auto-662"
      ba-b1: #"^(F0)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(ED)"  = ba-b3 
  --test-- "byte-auto-663"
  --assert #"^(4E)"  = ( #"a" + ( #"^(F0)" - #"^(03)" ))
  --test-- "byte-auto-664"
  --assert #"^(EB)"  = ( #"^(F0)" - #"^(05)" )
  --test-- "byte-auto-665"
      ba-b1: #"^(F0)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(EB)"  = ba-b3 
  --test-- "byte-auto-666"
  --assert #"^(4C)"  = ( #"a" + ( #"^(F0)" - #"^(05)" ))
  --test-- "byte-auto-667"
  --assert #"^(00)"  = ( #"^(F0)" - #"^(F0)" )
  --test-- "byte-auto-668"
      ba-b1: #"^(F0)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-669"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" - #"^(F0)" ))
  --test-- "byte-auto-670"
  --assert #"^(F3)"  = ( #"^(F0)" - #"^(FD)" )
  --test-- "byte-auto-671"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(F3)"  = ba-b3 
  --test-- "byte-auto-672"
  --assert #"^(54)"  = ( #"a" + ( #"^(F0)" - #"^(FD)" ))
  --test-- "byte-auto-673"
  --assert #"^(F2)"  = ( #"^(F0)" - #"^(FE)" )
  --test-- "byte-auto-674"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(F2)"  = ba-b3 
  --test-- "byte-auto-675"
  --assert #"^(53)"  = ( #"a" + ( #"^(F0)" - #"^(FE)" ))
  --test-- "byte-auto-676"
  --assert #"^(72)"  = ( #"^(F0)" - #"^(7E)" )
  --test-- "byte-auto-677"
      ba-b1: #"^(F0)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(72)"  = ba-b3 
  --test-- "byte-auto-678"
  --assert #"^(D3)"  = ( #"a" + ( #"^(F0)" - #"^(7E)" ))
  --test-- "byte-auto-679"
  --assert #"^(85)"  = ( #"^(F0)" - #"^(6B)" )
  --test-- "byte-auto-680"
      ba-b1: #"^(F0)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(85)"  = ba-b3 
  --test-- "byte-auto-681"
  --assert #"^(E6)"  = ( #"a" + ( #"^(F0)" - #"^(6B)" ))
  --test-- "byte-auto-682"
  --assert #"^(F5)"  = ( #"^(F0)" - #"^(FB)" )
  --test-- "byte-auto-683"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(F5)"  = ba-b3 
  --test-- "byte-auto-684"
  --assert #"^(56)"  = ( #"a" + ( #"^(F0)" - #"^(FB)" ))
  --test-- "byte-auto-685"
  --assert #"^(FD)"  = ( #"^(FD)" - #"^(00)" )
  --test-- "byte-auto-686"
      ba-b1: #"^(FD)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-687"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" - #"^(00)" ))
  --test-- "byte-auto-688"
  --assert #"^(FE)"  = ( #"^(FD)" - #"^(FF)" )
  --test-- "byte-auto-689"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-690"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FD)" - #"^(FF)" ))
  --test-- "byte-auto-691"
  --assert #"^(FC)"  = ( #"^(FD)" - #"^(01)" )
  --test-- "byte-auto-692"
      ba-b1: #"^(FD)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-693"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FD)" - #"^(01)" ))
  --test-- "byte-auto-694"
  --assert #"^(FB)"  = ( #"^(FD)" - #"^(02)" )
  --test-- "byte-auto-695"
      ba-b1: #"^(FD)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-696"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FD)" - #"^(02)" ))
  --test-- "byte-auto-697"
  --assert #"^(FA)"  = ( #"^(FD)" - #"^(03)" )
  --test-- "byte-auto-698"
      ba-b1: #"^(FD)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-699"
  --assert #"^(5B)"  = ( #"a" + ( #"^(FD)" - #"^(03)" ))
  --test-- "byte-auto-700"
  --assert #"^(F8)"  = ( #"^(FD)" - #"^(05)" )
  --test-- "byte-auto-701"
      ba-b1: #"^(FD)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(F8)"  = ba-b3 
  --test-- "byte-auto-702"
  --assert #"^(59)"  = ( #"a" + ( #"^(FD)" - #"^(05)" ))
  --test-- "byte-auto-703"
  --assert #"^(0D)"  = ( #"^(FD)" - #"^(F0)" )
  --test-- "byte-auto-704"
      ba-b1: #"^(FD)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(0D)"  = ba-b3 
  --test-- "byte-auto-705"
  --assert #"^(6E)"  = ( #"a" + ( #"^(FD)" - #"^(F0)" ))
  --test-- "byte-auto-706"
  --assert #"^(00)"  = ( #"^(FD)" - #"^(FD)" )
  --test-- "byte-auto-707"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-708"
  --assert #"^(61)"  = ( #"a" + ( #"^(FD)" - #"^(FD)" ))
  --test-- "byte-auto-709"
  --assert #"^(FF)"  = ( #"^(FD)" - #"^(FE)" )
  --test-- "byte-auto-710"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-711"
  --assert #"^(60)"  = ( #"a" + ( #"^(FD)" - #"^(FE)" ))
  --test-- "byte-auto-712"
  --assert #"^(7F)"  = ( #"^(FD)" - #"^(7E)" )
  --test-- "byte-auto-713"
      ba-b1: #"^(FD)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-714"
  --assert #"^(E0)"  = ( #"a" + ( #"^(FD)" - #"^(7E)" ))
  --test-- "byte-auto-715"
  --assert #"^(92)"  = ( #"^(FD)" - #"^(6B)" )
  --test-- "byte-auto-716"
      ba-b1: #"^(FD)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(92)"  = ba-b3 
  --test-- "byte-auto-717"
  --assert #"^(F3)"  = ( #"a" + ( #"^(FD)" - #"^(6B)" ))
  --test-- "byte-auto-718"
  --assert #"^(02)"  = ( #"^(FD)" - #"^(FB)" )
  --test-- "byte-auto-719"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-720"
  --assert #"^(63)"  = ( #"a" + ( #"^(FD)" - #"^(FB)" ))
  --test-- "byte-auto-721"
  --assert #"^(FE)"  = ( #"^(FE)" - #"^(00)" )
  --test-- "byte-auto-722"
      ba-b1: #"^(FE)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-723"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" - #"^(00)" ))
  --test-- "byte-auto-724"
  --assert #"^(FF)"  = ( #"^(FE)" - #"^(FF)" )
  --test-- "byte-auto-725"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-726"
  --assert #"^(60)"  = ( #"a" + ( #"^(FE)" - #"^(FF)" ))
  --test-- "byte-auto-727"
  --assert #"^(FD)"  = ( #"^(FE)" - #"^(01)" )
  --test-- "byte-auto-728"
      ba-b1: #"^(FE)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-729"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FE)" - #"^(01)" ))
  --test-- "byte-auto-730"
  --assert #"^(FC)"  = ( #"^(FE)" - #"^(02)" )
  --test-- "byte-auto-731"
      ba-b1: #"^(FE)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-732"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FE)" - #"^(02)" ))
  --test-- "byte-auto-733"
  --assert #"^(FB)"  = ( #"^(FE)" - #"^(03)" )
  --test-- "byte-auto-734"
      ba-b1: #"^(FE)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-735"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FE)" - #"^(03)" ))
  --test-- "byte-auto-736"
  --assert #"^(F9)"  = ( #"^(FE)" - #"^(05)" )
  --test-- "byte-auto-737"
      ba-b1: #"^(FE)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(F9)"  = ba-b3 
  --test-- "byte-auto-738"
  --assert #"^(5A)"  = ( #"a" + ( #"^(FE)" - #"^(05)" ))
  --test-- "byte-auto-739"
  --assert #"^(0E)"  = ( #"^(FE)" - #"^(F0)" )
  --test-- "byte-auto-740"
      ba-b1: #"^(FE)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(0E)"  = ba-b3 
  --test-- "byte-auto-741"
  --assert #"^(6F)"  = ( #"a" + ( #"^(FE)" - #"^(F0)" ))
  --test-- "byte-auto-742"
  --assert #"^(01)"  = ( #"^(FE)" - #"^(FD)" )
  --test-- "byte-auto-743"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-744"
  --assert #"^(62)"  = ( #"a" + ( #"^(FE)" - #"^(FD)" ))
  --test-- "byte-auto-745"
  --assert #"^(00)"  = ( #"^(FE)" - #"^(FE)" )
  --test-- "byte-auto-746"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-747"
  --assert #"^(61)"  = ( #"a" + ( #"^(FE)" - #"^(FE)" ))
  --test-- "byte-auto-748"
  --assert #"^(80)"  = ( #"^(FE)" - #"^(7E)" )
  --test-- "byte-auto-749"
      ba-b1: #"^(FE)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(80)"  = ba-b3 
  --test-- "byte-auto-750"
  --assert #"^(E1)"  = ( #"a" + ( #"^(FE)" - #"^(7E)" ))
  --test-- "byte-auto-751"
  --assert #"^(93)"  = ( #"^(FE)" - #"^(6B)" )
  --test-- "byte-auto-752"
      ba-b1: #"^(FE)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(93)"  = ba-b3 
  --test-- "byte-auto-753"
  --assert #"^(F4)"  = ( #"a" + ( #"^(FE)" - #"^(6B)" ))
  --test-- "byte-auto-754"
  --assert #"^(03)"  = ( #"^(FE)" - #"^(FB)" )
  --test-- "byte-auto-755"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-756"
  --assert #"^(64)"  = ( #"a" + ( #"^(FE)" - #"^(FB)" ))
  --test-- "byte-auto-757"
  --assert #"^(7E)"  = ( #"^(7E)" - #"^(00)" )
  --test-- "byte-auto-758"
      ba-b1: #"^(7E)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-759"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" - #"^(00)" ))
  --test-- "byte-auto-760"
  --assert #"^(7F)"  = ( #"^(7E)" - #"^(FF)" )
  --test-- "byte-auto-761"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-762"
  --assert #"^(E0)"  = ( #"a" + ( #"^(7E)" - #"^(FF)" ))
  --test-- "byte-auto-763"
  --assert #"^(7D)"  = ( #"^(7E)" - #"^(01)" )
  --test-- "byte-auto-764"
      ba-b1: #"^(7E)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(7D)"  = ba-b3 
  --test-- "byte-auto-765"
  --assert #"^(DE)"  = ( #"a" + ( #"^(7E)" - #"^(01)" ))
  --test-- "byte-auto-766"
  --assert #"^(7C)"  = ( #"^(7E)" - #"^(02)" )
  --test-- "byte-auto-767"
      ba-b1: #"^(7E)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(7C)"  = ba-b3 
  --test-- "byte-auto-768"
  --assert #"^(DD)"  = ( #"a" + ( #"^(7E)" - #"^(02)" ))
  --test-- "byte-auto-769"
  --assert #"^(7B)"  = ( #"^(7E)" - #"^(03)" )
  --test-- "byte-auto-770"
      ba-b1: #"^(7E)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(7B)"  = ba-b3 
  --test-- "byte-auto-771"
  --assert #"^(DC)"  = ( #"a" + ( #"^(7E)" - #"^(03)" ))
  --test-- "byte-auto-772"
  --assert #"^(79)"  = ( #"^(7E)" - #"^(05)" )
  --test-- "byte-auto-773"
      ba-b1: #"^(7E)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(79)"  = ba-b3 
  --test-- "byte-auto-774"
  --assert #"^(DA)"  = ( #"a" + ( #"^(7E)" - #"^(05)" ))
  --test-- "byte-auto-775"
  --assert #"^(8E)"  = ( #"^(7E)" - #"^(F0)" )
  --test-- "byte-auto-776"
      ba-b1: #"^(7E)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(8E)"  = ba-b3 
  --test-- "byte-auto-777"
  --assert #"^(EF)"  = ( #"a" + ( #"^(7E)" - #"^(F0)" ))
  --test-- "byte-auto-778"
  --assert #"^(81)"  = ( #"^(7E)" - #"^(FD)" )
  --test-- "byte-auto-779"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(81)"  = ba-b3 
  --test-- "byte-auto-780"
  --assert #"^(E2)"  = ( #"a" + ( #"^(7E)" - #"^(FD)" ))
  --test-- "byte-auto-781"
  --assert #"^(80)"  = ( #"^(7E)" - #"^(FE)" )
  --test-- "byte-auto-782"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(80)"  = ba-b3 
  --test-- "byte-auto-783"
  --assert #"^(E1)"  = ( #"a" + ( #"^(7E)" - #"^(FE)" ))
  --test-- "byte-auto-784"
  --assert #"^(00)"  = ( #"^(7E)" - #"^(7E)" )
  --test-- "byte-auto-785"
      ba-b1: #"^(7E)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-786"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" - #"^(7E)" ))
  --test-- "byte-auto-787"
  --assert #"^(13)"  = ( #"^(7E)" - #"^(6B)" )
  --test-- "byte-auto-788"
      ba-b1: #"^(7E)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(13)"  = ba-b3 
  --test-- "byte-auto-789"
  --assert #"^(74)"  = ( #"a" + ( #"^(7E)" - #"^(6B)" ))
  --test-- "byte-auto-790"
  --assert #"^(83)"  = ( #"^(7E)" - #"^(FB)" )
  --test-- "byte-auto-791"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(83)"  = ba-b3 
  --test-- "byte-auto-792"
  --assert #"^(E4)"  = ( #"a" + ( #"^(7E)" - #"^(FB)" ))
  --test-- "byte-auto-793"
  --assert #"^(6B)"  = ( #"^(6B)" - #"^(00)" )
  --test-- "byte-auto-794"
      ba-b1: #"^(6B)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-795"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" - #"^(00)" ))
  --test-- "byte-auto-796"
  --assert #"^(6C)"  = ( #"^(6B)" - #"^(FF)" )
  --test-- "byte-auto-797"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(6C)"  = ba-b3 
  --test-- "byte-auto-798"
  --assert #"^(CD)"  = ( #"a" + ( #"^(6B)" - #"^(FF)" ))
  --test-- "byte-auto-799"
  --assert #"^(6A)"  = ( #"^(6B)" - #"^(01)" )
  --test-- "byte-auto-800"
      ba-b1: #"^(6B)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(6A)"  = ba-b3 
  --test-- "byte-auto-801"
  --assert #"^(CB)"  = ( #"a" + ( #"^(6B)" - #"^(01)" ))
  --test-- "byte-auto-802"
  --assert #"^(69)"  = ( #"^(6B)" - #"^(02)" )
  --test-- "byte-auto-803"
      ba-b1: #"^(6B)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(69)"  = ba-b3 
  --test-- "byte-auto-804"
  --assert #"^(CA)"  = ( #"a" + ( #"^(6B)" - #"^(02)" ))
  --test-- "byte-auto-805"
  --assert #"^(68)"  = ( #"^(6B)" - #"^(03)" )
  --test-- "byte-auto-806"
      ba-b1: #"^(6B)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(68)"  = ba-b3 
  --test-- "byte-auto-807"
  --assert #"^(C9)"  = ( #"a" + ( #"^(6B)" - #"^(03)" ))
  --test-- "byte-auto-808"
  --assert #"^(66)"  = ( #"^(6B)" - #"^(05)" )
  --test-- "byte-auto-809"
      ba-b1: #"^(6B)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(66)"  = ba-b3 
  --test-- "byte-auto-810"
  --assert #"^(C7)"  = ( #"a" + ( #"^(6B)" - #"^(05)" ))
  --test-- "byte-auto-811"
  --assert #"^(7B)"  = ( #"^(6B)" - #"^(F0)" )
  --test-- "byte-auto-812"
      ba-b1: #"^(6B)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(7B)"  = ba-b3 
  --test-- "byte-auto-813"
  --assert #"^(DC)"  = ( #"a" + ( #"^(6B)" - #"^(F0)" ))
  --test-- "byte-auto-814"
  --assert #"^(6E)"  = ( #"^(6B)" - #"^(FD)" )
  --test-- "byte-auto-815"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(6E)"  = ba-b3 
  --test-- "byte-auto-816"
  --assert #"^(CF)"  = ( #"a" + ( #"^(6B)" - #"^(FD)" ))
  --test-- "byte-auto-817"
  --assert #"^(6D)"  = ( #"^(6B)" - #"^(FE)" )
  --test-- "byte-auto-818"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(6D)"  = ba-b3 
  --test-- "byte-auto-819"
  --assert #"^(CE)"  = ( #"a" + ( #"^(6B)" - #"^(FE)" ))
  --test-- "byte-auto-820"
  --assert #"^(ED)"  = ( #"^(6B)" - #"^(7E)" )
  --test-- "byte-auto-821"
      ba-b1: #"^(6B)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(ED)"  = ba-b3 
  --test-- "byte-auto-822"
  --assert #"^(4E)"  = ( #"a" + ( #"^(6B)" - #"^(7E)" ))
  --test-- "byte-auto-823"
  --assert #"^(00)"  = ( #"^(6B)" - #"^(6B)" )
  --test-- "byte-auto-824"
      ba-b1: #"^(6B)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-825"
  --assert #"^(61)"  = ( #"a" + ( #"^(6B)" - #"^(6B)" ))
  --test-- "byte-auto-826"
  --assert #"^(70)"  = ( #"^(6B)" - #"^(FB)" )
  --test-- "byte-auto-827"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(70)"  = ba-b3 
  --test-- "byte-auto-828"
  --assert #"^(D1)"  = ( #"a" + ( #"^(6B)" - #"^(FB)" ))
  --test-- "byte-auto-829"
  --assert #"^(FB)"  = ( #"^(FB)" - #"^(00)" )
  --test-- "byte-auto-830"
      ba-b1: #"^(FB)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-831"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" - #"^(00)" ))
  --test-- "byte-auto-832"
  --assert #"^(FC)"  = ( #"^(FB)" - #"^(FF)" )
  --test-- "byte-auto-833"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-834"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FB)" - #"^(FF)" ))
  --test-- "byte-auto-835"
  --assert #"^(FA)"  = ( #"^(FB)" - #"^(01)" )
  --test-- "byte-auto-836"
      ba-b1: #"^(FB)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-837"
  --assert #"^(5B)"  = ( #"a" + ( #"^(FB)" - #"^(01)" ))
  --test-- "byte-auto-838"
  --assert #"^(F9)"  = ( #"^(FB)" - #"^(02)" )
  --test-- "byte-auto-839"
      ba-b1: #"^(FB)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(F9)"  = ba-b3 
  --test-- "byte-auto-840"
  --assert #"^(5A)"  = ( #"a" + ( #"^(FB)" - #"^(02)" ))
  --test-- "byte-auto-841"
  --assert #"^(F8)"  = ( #"^(FB)" - #"^(03)" )
  --test-- "byte-auto-842"
      ba-b1: #"^(FB)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(F8)"  = ba-b3 
  --test-- "byte-auto-843"
  --assert #"^(59)"  = ( #"a" + ( #"^(FB)" - #"^(03)" ))
  --test-- "byte-auto-844"
  --assert #"^(F6)"  = ( #"^(FB)" - #"^(05)" )
  --test-- "byte-auto-845"
      ba-b1: #"^(FB)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(F6)"  = ba-b3 
  --test-- "byte-auto-846"
  --assert #"^(57)"  = ( #"a" + ( #"^(FB)" - #"^(05)" ))
  --test-- "byte-auto-847"
  --assert #"^(0B)"  = ( #"^(FB)" - #"^(F0)" )
  --test-- "byte-auto-848"
      ba-b1: #"^(FB)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(0B)"  = ba-b3 
  --test-- "byte-auto-849"
  --assert #"^(6C)"  = ( #"a" + ( #"^(FB)" - #"^(F0)" ))
  --test-- "byte-auto-850"
  --assert #"^(FE)"  = ( #"^(FB)" - #"^(FD)" )
  --test-- "byte-auto-851"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-852"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FB)" - #"^(FD)" ))
  --test-- "byte-auto-853"
  --assert #"^(FD)"  = ( #"^(FB)" - #"^(FE)" )
  --test-- "byte-auto-854"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-855"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FB)" - #"^(FE)" ))
  --test-- "byte-auto-856"
  --assert #"^(7D)"  = ( #"^(FB)" - #"^(7E)" )
  --test-- "byte-auto-857"
      ba-b1: #"^(FB)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(7D)"  = ba-b3 
  --test-- "byte-auto-858"
  --assert #"^(DE)"  = ( #"a" + ( #"^(FB)" - #"^(7E)" ))
  --test-- "byte-auto-859"
  --assert #"^(90)"  = ( #"^(FB)" - #"^(6B)" )
  --test-- "byte-auto-860"
      ba-b1: #"^(FB)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(90)"  = ba-b3 
  --test-- "byte-auto-861"
  --assert #"^(F1)"  = ( #"a" + ( #"^(FB)" - #"^(6B)" ))
  --test-- "byte-auto-862"
  --assert #"^(00)"  = ( #"^(FB)" - #"^(FB)" )
  --test-- "byte-auto-863"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 - ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-864"
  --assert #"^(61)"  = ( #"a" + ( #"^(FB)" - #"^(FB)" ))
  --test-- "byte-auto-865"
  --assert #"^(00)"  = ( #"^(00)" * #"^(00)" )
  --test-- "byte-auto-866"
      ba-b1: #"^(00)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-867"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" * #"^(00)" ))
  --test-- "byte-auto-868"
  --assert #"^(00)"  = ( #"^(00)" * #"^(FF)" )
  --test-- "byte-auto-869"
      ba-b1: #"^(00)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-870"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" * #"^(FF)" ))
  --test-- "byte-auto-871"
  --assert #"^(00)"  = ( #"^(00)" * #"^(01)" )
  --test-- "byte-auto-872"
      ba-b1: #"^(00)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-873"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" * #"^(01)" ))
  --test-- "byte-auto-874"
  --assert #"^(00)"  = ( #"^(00)" * #"^(02)" )
  --test-- "byte-auto-875"
      ba-b1: #"^(00)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-876"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" * #"^(02)" ))
  --test-- "byte-auto-877"
  --assert #"^(00)"  = ( #"^(00)" * #"^(03)" )
  --test-- "byte-auto-878"
      ba-b1: #"^(00)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-879"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" * #"^(03)" ))
  --test-- "byte-auto-880"
  --assert #"^(00)"  = ( #"^(00)" * #"^(05)" )
  --test-- "byte-auto-881"
      ba-b1: #"^(00)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-882"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" * #"^(05)" ))
  --test-- "byte-auto-883"
  --assert #"^(00)"  = ( #"^(00)" * #"^(F0)" )
  --test-- "byte-auto-884"
      ba-b1: #"^(00)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-885"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" * #"^(F0)" ))
  --test-- "byte-auto-886"
  --assert #"^(00)"  = ( #"^(00)" * #"^(FD)" )
  --test-- "byte-auto-887"
      ba-b1: #"^(00)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-888"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" * #"^(FD)" ))
  --test-- "byte-auto-889"
  --assert #"^(00)"  = ( #"^(00)" * #"^(FE)" )
  --test-- "byte-auto-890"
      ba-b1: #"^(00)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-891"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" * #"^(FE)" ))
  --test-- "byte-auto-892"
  --assert #"^(00)"  = ( #"^(00)" * #"^(7E)" )
  --test-- "byte-auto-893"
      ba-b1: #"^(00)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-894"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" * #"^(7E)" ))
  --test-- "byte-auto-895"
  --assert #"^(00)"  = ( #"^(00)" * #"^(6B)" )
  --test-- "byte-auto-896"
      ba-b1: #"^(00)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-897"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" * #"^(6B)" ))
  --test-- "byte-auto-898"
  --assert #"^(00)"  = ( #"^(00)" * #"^(FB)" )
  --test-- "byte-auto-899"
      ba-b1: #"^(00)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-900"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" * #"^(FB)" ))
  --test-- "byte-auto-901"
  --assert #"^(00)"  = ( #"^(FF)" * #"^(00)" )
  --test-- "byte-auto-902"
      ba-b1: #"^(FF)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-903"
  --assert #"^(61)"  = ( #"a" + ( #"^(FF)" * #"^(00)" ))
  --test-- "byte-auto-904"
  --assert #"^(01)"  = ( #"^(FF)" * #"^(FF)" )
  --test-- "byte-auto-905"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-906"
  --assert #"^(62)"  = ( #"a" + ( #"^(FF)" * #"^(FF)" ))
  --test-- "byte-auto-907"
  --assert #"^(FF)"  = ( #"^(FF)" * #"^(01)" )
  --test-- "byte-auto-908"
      ba-b1: #"^(FF)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-909"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" * #"^(01)" ))
  --test-- "byte-auto-910"
  --assert #"^(FE)"  = ( #"^(FF)" * #"^(02)" )
  --test-- "byte-auto-911"
      ba-b1: #"^(FF)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-912"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FF)" * #"^(02)" ))
  --test-- "byte-auto-913"
  --assert #"^(FD)"  = ( #"^(FF)" * #"^(03)" )
  --test-- "byte-auto-914"
      ba-b1: #"^(FF)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-915"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FF)" * #"^(03)" ))
  --test-- "byte-auto-916"
  --assert #"^(FB)"  = ( #"^(FF)" * #"^(05)" )
  --test-- "byte-auto-917"
      ba-b1: #"^(FF)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-918"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FF)" * #"^(05)" ))
  --test-- "byte-auto-919"
  --assert #"^(10)"  = ( #"^(FF)" * #"^(F0)" )
  --test-- "byte-auto-920"
      ba-b1: #"^(FF)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(10)"  = ba-b3 
  --test-- "byte-auto-921"
  --assert #"^(71)"  = ( #"a" + ( #"^(FF)" * #"^(F0)" ))
  --test-- "byte-auto-922"
  --assert #"^(03)"  = ( #"^(FF)" * #"^(FD)" )
  --test-- "byte-auto-923"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-924"
  --assert #"^(64)"  = ( #"a" + ( #"^(FF)" * #"^(FD)" ))
  --test-- "byte-auto-925"
  --assert #"^(02)"  = ( #"^(FF)" * #"^(FE)" )
  --test-- "byte-auto-926"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-927"
  --assert #"^(63)"  = ( #"a" + ( #"^(FF)" * #"^(FE)" ))
  --test-- "byte-auto-928"
  --assert #"^(82)"  = ( #"^(FF)" * #"^(7E)" )
  --test-- "byte-auto-929"
      ba-b1: #"^(FF)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(82)"  = ba-b3 
  --test-- "byte-auto-930"
  --assert #"^(E3)"  = ( #"a" + ( #"^(FF)" * #"^(7E)" ))
  --test-- "byte-auto-931"
  --assert #"^(95)"  = ( #"^(FF)" * #"^(6B)" )
  --test-- "byte-auto-932"
      ba-b1: #"^(FF)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(95)"  = ba-b3 
  --test-- "byte-auto-933"
  --assert #"^(F6)"  = ( #"a" + ( #"^(FF)" * #"^(6B)" ))
  --test-- "byte-auto-934"
  --assert #"^(05)"  = ( #"^(FF)" * #"^(FB)" )
  --test-- "byte-auto-935"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-936"
  --assert #"^(66)"  = ( #"a" + ( #"^(FF)" * #"^(FB)" ))
  --test-- "byte-auto-937"
  --assert #"^(00)"  = ( #"^(01)" * #"^(00)" )
  --test-- "byte-auto-938"
      ba-b1: #"^(01)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-939"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" * #"^(00)" ))
  --test-- "byte-auto-940"
  --assert #"^(FF)"  = ( #"^(01)" * #"^(FF)" )
  --test-- "byte-auto-941"
      ba-b1: #"^(01)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-942"
  --assert #"^(60)"  = ( #"a" + ( #"^(01)" * #"^(FF)" ))
  --test-- "byte-auto-943"
  --assert #"^(01)"  = ( #"^(01)" * #"^(01)" )
  --test-- "byte-auto-944"
      ba-b1: #"^(01)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-945"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" * #"^(01)" ))
  --test-- "byte-auto-946"
  --assert #"^(02)"  = ( #"^(01)" * #"^(02)" )
  --test-- "byte-auto-947"
      ba-b1: #"^(01)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-948"
  --assert #"^(63)"  = ( #"a" + ( #"^(01)" * #"^(02)" ))
  --test-- "byte-auto-949"
  --assert #"^(03)"  = ( #"^(01)" * #"^(03)" )
  --test-- "byte-auto-950"
      ba-b1: #"^(01)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-951"
  --assert #"^(64)"  = ( #"a" + ( #"^(01)" * #"^(03)" ))
  --test-- "byte-auto-952"
  --assert #"^(05)"  = ( #"^(01)" * #"^(05)" )
  --test-- "byte-auto-953"
      ba-b1: #"^(01)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-954"
  --assert #"^(66)"  = ( #"a" + ( #"^(01)" * #"^(05)" ))
  --test-- "byte-auto-955"
  --assert #"^(F0)"  = ( #"^(01)" * #"^(F0)" )
  --test-- "byte-auto-956"
      ba-b1: #"^(01)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-957"
  --assert #"^(51)"  = ( #"a" + ( #"^(01)" * #"^(F0)" ))
  --test-- "byte-auto-958"
  --assert #"^(FD)"  = ( #"^(01)" * #"^(FD)" )
  --test-- "byte-auto-959"
      ba-b1: #"^(01)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-960"
  --assert #"^(5E)"  = ( #"a" + ( #"^(01)" * #"^(FD)" ))
  --test-- "byte-auto-961"
  --assert #"^(FE)"  = ( #"^(01)" * #"^(FE)" )
  --test-- "byte-auto-962"
      ba-b1: #"^(01)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-963"
  --assert #"^(5F)"  = ( #"a" + ( #"^(01)" * #"^(FE)" ))
  --test-- "byte-auto-964"
  --assert #"^(7E)"  = ( #"^(01)" * #"^(7E)" )
  --test-- "byte-auto-965"
      ba-b1: #"^(01)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-966"
  --assert #"^(DF)"  = ( #"a" + ( #"^(01)" * #"^(7E)" ))
  --test-- "byte-auto-967"
  --assert #"^(6B)"  = ( #"^(01)" * #"^(6B)" )
  --test-- "byte-auto-968"
      ba-b1: #"^(01)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-969"
  --assert #"^(CC)"  = ( #"a" + ( #"^(01)" * #"^(6B)" ))
  --test-- "byte-auto-970"
  --assert #"^(FB)"  = ( #"^(01)" * #"^(FB)" )
  --test-- "byte-auto-971"
      ba-b1: #"^(01)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-972"
  --assert #"^(5C)"  = ( #"a" + ( #"^(01)" * #"^(FB)" ))
  --test-- "byte-auto-973"
  --assert #"^(00)"  = ( #"^(02)" * #"^(00)" )
  --test-- "byte-auto-974"
      ba-b1: #"^(02)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-975"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" * #"^(00)" ))
  --test-- "byte-auto-976"
  --assert #"^(FE)"  = ( #"^(02)" * #"^(FF)" )
  --test-- "byte-auto-977"
      ba-b1: #"^(02)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-978"
  --assert #"^(5F)"  = ( #"a" + ( #"^(02)" * #"^(FF)" ))
  --test-- "byte-auto-979"
  --assert #"^(02)"  = ( #"^(02)" * #"^(01)" )
  --test-- "byte-auto-980"
      ba-b1: #"^(02)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-981"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" * #"^(01)" ))
  --test-- "byte-auto-982"
  --assert #"^(04)"  = ( #"^(02)" * #"^(02)" )
  --test-- "byte-auto-983"
      ba-b1: #"^(02)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-984"
  --assert #"^(65)"  = ( #"a" + ( #"^(02)" * #"^(02)" ))
  --test-- "byte-auto-985"
  --assert #"^(06)"  = ( #"^(02)" * #"^(03)" )
  --test-- "byte-auto-986"
      ba-b1: #"^(02)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-987"
  --assert #"^(67)"  = ( #"a" + ( #"^(02)" * #"^(03)" ))
  --test-- "byte-auto-988"
  --assert #"^(0A)"  = ( #"^(02)" * #"^(05)" )
  --test-- "byte-auto-989"
      ba-b1: #"^(02)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(0A)"  = ba-b3 
  --test-- "byte-auto-990"
  --assert #"^(6B)"  = ( #"a" + ( #"^(02)" * #"^(05)" ))
  --test-- "byte-auto-991"
  --assert #"^(E0)"  = ( #"^(02)" * #"^(F0)" )
  --test-- "byte-auto-992"
      ba-b1: #"^(02)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(E0)"  = ba-b3 
  --test-- "byte-auto-993"
  --assert #"^(41)"  = ( #"a" + ( #"^(02)" * #"^(F0)" ))
  --test-- "byte-auto-994"
  --assert #"^(FA)"  = ( #"^(02)" * #"^(FD)" )
  --test-- "byte-auto-995"
      ba-b1: #"^(02)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-996"
  --assert #"^(5B)"  = ( #"a" + ( #"^(02)" * #"^(FD)" ))
  --test-- "byte-auto-997"
  --assert #"^(FC)"  = ( #"^(02)" * #"^(FE)" )
  --test-- "byte-auto-998"
      ba-b1: #"^(02)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-999"
  --assert #"^(5D)"  = ( #"a" + ( #"^(02)" * #"^(FE)" ))
  --test-- "byte-auto-1000"
  --assert #"^(FC)"  = ( #"^(02)" * #"^(7E)" )
  --test-- "byte-auto-1001"
      ba-b1: #"^(02)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-1002"
  --assert #"^(5D)"  = ( #"a" + ( #"^(02)" * #"^(7E)" ))
  --test-- "byte-auto-1003"
  --assert #"^(D6)"  = ( #"^(02)" * #"^(6B)" )
  --test-- "byte-auto-1004"
      ba-b1: #"^(02)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(D6)"  = ba-b3 
  --test-- "byte-auto-1005"
  --assert #"^(37)"  = ( #"a" + ( #"^(02)" * #"^(6B)" ))
  --test-- "byte-auto-1006"
  --assert #"^(F6)"  = ( #"^(02)" * #"^(FB)" )
  --test-- "byte-auto-1007"
      ba-b1: #"^(02)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(F6)"  = ba-b3 
  --test-- "byte-auto-1008"
  --assert #"^(57)"  = ( #"a" + ( #"^(02)" * #"^(FB)" ))
  --test-- "byte-auto-1009"
  --assert #"^(00)"  = ( #"^(03)" * #"^(00)" )
  --test-- "byte-auto-1010"
      ba-b1: #"^(03)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1011"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" * #"^(00)" ))
  --test-- "byte-auto-1012"
  --assert #"^(FD)"  = ( #"^(03)" * #"^(FF)" )
  --test-- "byte-auto-1013"
      ba-b1: #"^(03)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-1014"
  --assert #"^(5E)"  = ( #"a" + ( #"^(03)" * #"^(FF)" ))
  --test-- "byte-auto-1015"
  --assert #"^(03)"  = ( #"^(03)" * #"^(01)" )
  --test-- "byte-auto-1016"
      ba-b1: #"^(03)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1017"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" * #"^(01)" ))
  --test-- "byte-auto-1018"
  --assert #"^(06)"  = ( #"^(03)" * #"^(02)" )
  --test-- "byte-auto-1019"
      ba-b1: #"^(03)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-1020"
  --assert #"^(67)"  = ( #"a" + ( #"^(03)" * #"^(02)" ))
  --test-- "byte-auto-1021"
  --assert #"^(09)"  = ( #"^(03)" * #"^(03)" )
  --test-- "byte-auto-1022"
      ba-b1: #"^(03)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(09)"  = ba-b3 
  --test-- "byte-auto-1023"
  --assert #"^(6A)"  = ( #"a" + ( #"^(03)" * #"^(03)" ))
  --test-- "byte-auto-1024"
  --assert #"^(0F)"  = ( #"^(03)" * #"^(05)" )
  --test-- "byte-auto-1025"
      ba-b1: #"^(03)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(0F)"  = ba-b3 
  --test-- "byte-auto-1026"
  --assert #"^(70)"  = ( #"a" + ( #"^(03)" * #"^(05)" ))
  --test-- "byte-auto-1027"
  --assert #"^(D0)"  = ( #"^(03)" * #"^(F0)" )
  --test-- "byte-auto-1028"
      ba-b1: #"^(03)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(D0)"  = ba-b3 
  --test-- "byte-auto-1029"
  --assert #"^(31)"  = ( #"a" + ( #"^(03)" * #"^(F0)" ))
  --test-- "byte-auto-1030"
  --assert #"^(F7)"  = ( #"^(03)" * #"^(FD)" )
  --test-- "byte-auto-1031"
      ba-b1: #"^(03)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(F7)"  = ba-b3 
  --test-- "byte-auto-1032"
  --assert #"^(58)"  = ( #"a" + ( #"^(03)" * #"^(FD)" ))
  --test-- "byte-auto-1033"
  --assert #"^(FA)"  = ( #"^(03)" * #"^(FE)" )
  --test-- "byte-auto-1034"
      ba-b1: #"^(03)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-1035"
  --assert #"^(5B)"  = ( #"a" + ( #"^(03)" * #"^(FE)" ))
  --test-- "byte-auto-1036"
  --assert #"^(7A)"  = ( #"^(03)" * #"^(7E)" )
  --test-- "byte-auto-1037"
      ba-b1: #"^(03)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(7A)"  = ba-b3 
  --test-- "byte-auto-1038"
  --assert #"^(DB)"  = ( #"a" + ( #"^(03)" * #"^(7E)" ))
  --test-- "byte-auto-1039"
  --assert #"^(41)"  = ( #"^(03)" * #"^(6B)" )
  --test-- "byte-auto-1040"
      ba-b1: #"^(03)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(41)"  = ba-b3 
  --test-- "byte-auto-1041"
  --assert #"^(A2)"  = ( #"a" + ( #"^(03)" * #"^(6B)" ))
  --test-- "byte-auto-1042"
  --assert #"^(F1)"  = ( #"^(03)" * #"^(FB)" )
  --test-- "byte-auto-1043"
      ba-b1: #"^(03)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(F1)"  = ba-b3 
  --test-- "byte-auto-1044"
  --assert #"^(52)"  = ( #"a" + ( #"^(03)" * #"^(FB)" ))
  --test-- "byte-auto-1045"
  --assert #"^(00)"  = ( #"^(05)" * #"^(00)" )
  --test-- "byte-auto-1046"
      ba-b1: #"^(05)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1047"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" * #"^(00)" ))
  --test-- "byte-auto-1048"
  --assert #"^(FB)"  = ( #"^(05)" * #"^(FF)" )
  --test-- "byte-auto-1049"
      ba-b1: #"^(05)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-1050"
  --assert #"^(5C)"  = ( #"a" + ( #"^(05)" * #"^(FF)" ))
  --test-- "byte-auto-1051"
  --assert #"^(05)"  = ( #"^(05)" * #"^(01)" )
  --test-- "byte-auto-1052"
      ba-b1: #"^(05)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-1053"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" * #"^(01)" ))
  --test-- "byte-auto-1054"
  --assert #"^(0A)"  = ( #"^(05)" * #"^(02)" )
  --test-- "byte-auto-1055"
      ba-b1: #"^(05)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(0A)"  = ba-b3 
  --test-- "byte-auto-1056"
  --assert #"^(6B)"  = ( #"a" + ( #"^(05)" * #"^(02)" ))
  --test-- "byte-auto-1057"
  --assert #"^(0F)"  = ( #"^(05)" * #"^(03)" )
  --test-- "byte-auto-1058"
      ba-b1: #"^(05)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(0F)"  = ba-b3 
  --test-- "byte-auto-1059"
  --assert #"^(70)"  = ( #"a" + ( #"^(05)" * #"^(03)" ))
  --test-- "byte-auto-1060"
  --assert #"^(19)"  = ( #"^(05)" * #"^(05)" )
  --test-- "byte-auto-1061"
      ba-b1: #"^(05)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(19)"  = ba-b3 
  --test-- "byte-auto-1062"
  --assert #"^(7A)"  = ( #"a" + ( #"^(05)" * #"^(05)" ))
  --test-- "byte-auto-1063"
  --assert #"^(B0)"  = ( #"^(05)" * #"^(F0)" )
  --test-- "byte-auto-1064"
      ba-b1: #"^(05)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(B0)"  = ba-b3 
  --test-- "byte-auto-1065"
  --assert #"^(11)"  = ( #"a" + ( #"^(05)" * #"^(F0)" ))
  --test-- "byte-auto-1066"
  --assert #"^(F1)"  = ( #"^(05)" * #"^(FD)" )
  --test-- "byte-auto-1067"
      ba-b1: #"^(05)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(F1)"  = ba-b3 
  --test-- "byte-auto-1068"
  --assert #"^(52)"  = ( #"a" + ( #"^(05)" * #"^(FD)" ))
  --test-- "byte-auto-1069"
  --assert #"^(F6)"  = ( #"^(05)" * #"^(FE)" )
  --test-- "byte-auto-1070"
      ba-b1: #"^(05)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(F6)"  = ba-b3 
  --test-- "byte-auto-1071"
  --assert #"^(57)"  = ( #"a" + ( #"^(05)" * #"^(FE)" ))
  --test-- "byte-auto-1072"
  --assert #"^(76)"  = ( #"^(05)" * #"^(7E)" )
  --test-- "byte-auto-1073"
      ba-b1: #"^(05)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(76)"  = ba-b3 
  --test-- "byte-auto-1074"
  --assert #"^(D7)"  = ( #"a" + ( #"^(05)" * #"^(7E)" ))
  --test-- "byte-auto-1075"
  --assert #"^(17)"  = ( #"^(05)" * #"^(6B)" )
  --test-- "byte-auto-1076"
      ba-b1: #"^(05)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(17)"  = ba-b3 
  --test-- "byte-auto-1077"
  --assert #"^(78)"  = ( #"a" + ( #"^(05)" * #"^(6B)" ))
  --test-- "byte-auto-1078"
  --assert #"^(E7)"  = ( #"^(05)" * #"^(FB)" )
  --test-- "byte-auto-1079"
      ba-b1: #"^(05)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(E7)"  = ba-b3 
  --test-- "byte-auto-1080"
  --assert #"^(48)"  = ( #"a" + ( #"^(05)" * #"^(FB)" ))
  --test-- "byte-auto-1081"
  --assert #"^(00)"  = ( #"^(F0)" * #"^(00)" )
  --test-- "byte-auto-1082"
      ba-b1: #"^(F0)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1083"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" * #"^(00)" ))
  --test-- "byte-auto-1084"
  --assert #"^(10)"  = ( #"^(F0)" * #"^(FF)" )
  --test-- "byte-auto-1085"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(10)"  = ba-b3 
  --test-- "byte-auto-1086"
  --assert #"^(71)"  = ( #"a" + ( #"^(F0)" * #"^(FF)" ))
  --test-- "byte-auto-1087"
  --assert #"^(F0)"  = ( #"^(F0)" * #"^(01)" )
  --test-- "byte-auto-1088"
      ba-b1: #"^(F0)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-1089"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" * #"^(01)" ))
  --test-- "byte-auto-1090"
  --assert #"^(E0)"  = ( #"^(F0)" * #"^(02)" )
  --test-- "byte-auto-1091"
      ba-b1: #"^(F0)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(E0)"  = ba-b3 
  --test-- "byte-auto-1092"
  --assert #"^(41)"  = ( #"a" + ( #"^(F0)" * #"^(02)" ))
  --test-- "byte-auto-1093"
  --assert #"^(D0)"  = ( #"^(F0)" * #"^(03)" )
  --test-- "byte-auto-1094"
      ba-b1: #"^(F0)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(D0)"  = ba-b3 
  --test-- "byte-auto-1095"
  --assert #"^(31)"  = ( #"a" + ( #"^(F0)" * #"^(03)" ))
  --test-- "byte-auto-1096"
  --assert #"^(B0)"  = ( #"^(F0)" * #"^(05)" )
  --test-- "byte-auto-1097"
      ba-b1: #"^(F0)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(B0)"  = ba-b3 
  --test-- "byte-auto-1098"
  --assert #"^(11)"  = ( #"a" + ( #"^(F0)" * #"^(05)" ))
  --test-- "byte-auto-1099"
  --assert #"^(00)"  = ( #"^(F0)" * #"^(F0)" )
  --test-- "byte-auto-1100"
      ba-b1: #"^(F0)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1101"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" * #"^(F0)" ))
  --test-- "byte-auto-1102"
  --assert #"^(30)"  = ( #"^(F0)" * #"^(FD)" )
  --test-- "byte-auto-1103"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(30)"  = ba-b3 
  --test-- "byte-auto-1104"
  --assert #"^(91)"  = ( #"a" + ( #"^(F0)" * #"^(FD)" ))
  --test-- "byte-auto-1105"
  --assert #"^(20)"  = ( #"^(F0)" * #"^(FE)" )
  --test-- "byte-auto-1106"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(20)"  = ba-b3 
  --test-- "byte-auto-1107"
  --assert #"^(81)"  = ( #"a" + ( #"^(F0)" * #"^(FE)" ))
  --test-- "byte-auto-1108"
  --assert #"^(20)"  = ( #"^(F0)" * #"^(7E)" )
  --test-- "byte-auto-1109"
      ba-b1: #"^(F0)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(20)"  = ba-b3 
  --test-- "byte-auto-1110"
  --assert #"^(81)"  = ( #"a" + ( #"^(F0)" * #"^(7E)" ))
  --test-- "byte-auto-1111"
  --assert #"^(50)"  = ( #"^(F0)" * #"^(6B)" )
  --test-- "byte-auto-1112"
      ba-b1: #"^(F0)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(50)"  = ba-b3 
  --test-- "byte-auto-1113"
  --assert #"^(B1)"  = ( #"a" + ( #"^(F0)" * #"^(6B)" ))
  --test-- "byte-auto-1114"
  --assert #"^(50)"  = ( #"^(F0)" * #"^(FB)" )
  --test-- "byte-auto-1115"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(50)"  = ba-b3 
  --test-- "byte-auto-1116"
  --assert #"^(B1)"  = ( #"a" + ( #"^(F0)" * #"^(FB)" ))
  --test-- "byte-auto-1117"
  --assert #"^(00)"  = ( #"^(FD)" * #"^(00)" )
  --test-- "byte-auto-1118"
      ba-b1: #"^(FD)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1119"
  --assert #"^(61)"  = ( #"a" + ( #"^(FD)" * #"^(00)" ))
  --test-- "byte-auto-1120"
  --assert #"^(03)"  = ( #"^(FD)" * #"^(FF)" )
  --test-- "byte-auto-1121"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1122"
  --assert #"^(64)"  = ( #"a" + ( #"^(FD)" * #"^(FF)" ))
  --test-- "byte-auto-1123"
  --assert #"^(FD)"  = ( #"^(FD)" * #"^(01)" )
  --test-- "byte-auto-1124"
      ba-b1: #"^(FD)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-1125"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" * #"^(01)" ))
  --test-- "byte-auto-1126"
  --assert #"^(FA)"  = ( #"^(FD)" * #"^(02)" )
  --test-- "byte-auto-1127"
      ba-b1: #"^(FD)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-1128"
  --assert #"^(5B)"  = ( #"a" + ( #"^(FD)" * #"^(02)" ))
  --test-- "byte-auto-1129"
  --assert #"^(F7)"  = ( #"^(FD)" * #"^(03)" )
  --test-- "byte-auto-1130"
      ba-b1: #"^(FD)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(F7)"  = ba-b3 
  --test-- "byte-auto-1131"
  --assert #"^(58)"  = ( #"a" + ( #"^(FD)" * #"^(03)" ))
  --test-- "byte-auto-1132"
  --assert #"^(F1)"  = ( #"^(FD)" * #"^(05)" )
  --test-- "byte-auto-1133"
      ba-b1: #"^(FD)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(F1)"  = ba-b3 
  --test-- "byte-auto-1134"
  --assert #"^(52)"  = ( #"a" + ( #"^(FD)" * #"^(05)" ))
  --test-- "byte-auto-1135"
  --assert #"^(30)"  = ( #"^(FD)" * #"^(F0)" )
  --test-- "byte-auto-1136"
      ba-b1: #"^(FD)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(30)"  = ba-b3 
  --test-- "byte-auto-1137"
  --assert #"^(91)"  = ( #"a" + ( #"^(FD)" * #"^(F0)" ))
  --test-- "byte-auto-1138"
  --assert #"^(09)"  = ( #"^(FD)" * #"^(FD)" )
  --test-- "byte-auto-1139"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(09)"  = ba-b3 
  --test-- "byte-auto-1140"
  --assert #"^(6A)"  = ( #"a" + ( #"^(FD)" * #"^(FD)" ))
  --test-- "byte-auto-1141"
  --assert #"^(06)"  = ( #"^(FD)" * #"^(FE)" )
  --test-- "byte-auto-1142"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-1143"
  --assert #"^(67)"  = ( #"a" + ( #"^(FD)" * #"^(FE)" ))
  --test-- "byte-auto-1144"
  --assert #"^(86)"  = ( #"^(FD)" * #"^(7E)" )
  --test-- "byte-auto-1145"
      ba-b1: #"^(FD)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(86)"  = ba-b3 
  --test-- "byte-auto-1146"
  --assert #"^(E7)"  = ( #"a" + ( #"^(FD)" * #"^(7E)" ))
  --test-- "byte-auto-1147"
  --assert #"^(BF)"  = ( #"^(FD)" * #"^(6B)" )
  --test-- "byte-auto-1148"
      ba-b1: #"^(FD)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(BF)"  = ba-b3 
  --test-- "byte-auto-1149"
  --assert #"^(20)"  = ( #"a" + ( #"^(FD)" * #"^(6B)" ))
  --test-- "byte-auto-1150"
  --assert #"^(0F)"  = ( #"^(FD)" * #"^(FB)" )
  --test-- "byte-auto-1151"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(0F)"  = ba-b3 
  --test-- "byte-auto-1152"
  --assert #"^(70)"  = ( #"a" + ( #"^(FD)" * #"^(FB)" ))
  --test-- "byte-auto-1153"
  --assert #"^(00)"  = ( #"^(FE)" * #"^(00)" )
  --test-- "byte-auto-1154"
      ba-b1: #"^(FE)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1155"
  --assert #"^(61)"  = ( #"a" + ( #"^(FE)" * #"^(00)" ))
  --test-- "byte-auto-1156"
  --assert #"^(02)"  = ( #"^(FE)" * #"^(FF)" )
  --test-- "byte-auto-1157"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1158"
  --assert #"^(63)"  = ( #"a" + ( #"^(FE)" * #"^(FF)" ))
  --test-- "byte-auto-1159"
  --assert #"^(FE)"  = ( #"^(FE)" * #"^(01)" )
  --test-- "byte-auto-1160"
      ba-b1: #"^(FE)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-1161"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" * #"^(01)" ))
  --test-- "byte-auto-1162"
  --assert #"^(FC)"  = ( #"^(FE)" * #"^(02)" )
  --test-- "byte-auto-1163"
      ba-b1: #"^(FE)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-1164"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FE)" * #"^(02)" ))
  --test-- "byte-auto-1165"
  --assert #"^(FA)"  = ( #"^(FE)" * #"^(03)" )
  --test-- "byte-auto-1166"
      ba-b1: #"^(FE)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-1167"
  --assert #"^(5B)"  = ( #"a" + ( #"^(FE)" * #"^(03)" ))
  --test-- "byte-auto-1168"
  --assert #"^(F6)"  = ( #"^(FE)" * #"^(05)" )
  --test-- "byte-auto-1169"
      ba-b1: #"^(FE)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(F6)"  = ba-b3 
  --test-- "byte-auto-1170"
  --assert #"^(57)"  = ( #"a" + ( #"^(FE)" * #"^(05)" ))
  --test-- "byte-auto-1171"
  --assert #"^(20)"  = ( #"^(FE)" * #"^(F0)" )
  --test-- "byte-auto-1172"
      ba-b1: #"^(FE)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(20)"  = ba-b3 
  --test-- "byte-auto-1173"
  --assert #"^(81)"  = ( #"a" + ( #"^(FE)" * #"^(F0)" ))
  --test-- "byte-auto-1174"
  --assert #"^(06)"  = ( #"^(FE)" * #"^(FD)" )
  --test-- "byte-auto-1175"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-1176"
  --assert #"^(67)"  = ( #"a" + ( #"^(FE)" * #"^(FD)" ))
  --test-- "byte-auto-1177"
  --assert #"^(04)"  = ( #"^(FE)" * #"^(FE)" )
  --test-- "byte-auto-1178"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-1179"
  --assert #"^(65)"  = ( #"a" + ( #"^(FE)" * #"^(FE)" ))
  --test-- "byte-auto-1180"
  --assert #"^(04)"  = ( #"^(FE)" * #"^(7E)" )
  --test-- "byte-auto-1181"
      ba-b1: #"^(FE)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-1182"
  --assert #"^(65)"  = ( #"a" + ( #"^(FE)" * #"^(7E)" ))
  --test-- "byte-auto-1183"
  --assert #"^(2A)"  = ( #"^(FE)" * #"^(6B)" )
  --test-- "byte-auto-1184"
      ba-b1: #"^(FE)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(2A)"  = ba-b3 
  --test-- "byte-auto-1185"
  --assert #"^(8B)"  = ( #"a" + ( #"^(FE)" * #"^(6B)" ))
  --test-- "byte-auto-1186"
  --assert #"^(0A)"  = ( #"^(FE)" * #"^(FB)" )
  --test-- "byte-auto-1187"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(0A)"  = ba-b3 
  --test-- "byte-auto-1188"
  --assert #"^(6B)"  = ( #"a" + ( #"^(FE)" * #"^(FB)" ))
  --test-- "byte-auto-1189"
  --assert #"^(00)"  = ( #"^(7E)" * #"^(00)" )
  --test-- "byte-auto-1190"
      ba-b1: #"^(7E)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1191"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" * #"^(00)" ))
  --test-- "byte-auto-1192"
  --assert #"^(82)"  = ( #"^(7E)" * #"^(FF)" )
  --test-- "byte-auto-1193"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(82)"  = ba-b3 
  --test-- "byte-auto-1194"
  --assert #"^(E3)"  = ( #"a" + ( #"^(7E)" * #"^(FF)" ))
  --test-- "byte-auto-1195"
  --assert #"^(7E)"  = ( #"^(7E)" * #"^(01)" )
  --test-- "byte-auto-1196"
      ba-b1: #"^(7E)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-1197"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" * #"^(01)" ))
  --test-- "byte-auto-1198"
  --assert #"^(FC)"  = ( #"^(7E)" * #"^(02)" )
  --test-- "byte-auto-1199"
      ba-b1: #"^(7E)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-1200"
  --assert #"^(5D)"  = ( #"a" + ( #"^(7E)" * #"^(02)" ))
  --test-- "byte-auto-1201"
  --assert #"^(7A)"  = ( #"^(7E)" * #"^(03)" )
  --test-- "byte-auto-1202"
      ba-b1: #"^(7E)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(7A)"  = ba-b3 
  --test-- "byte-auto-1203"
  --assert #"^(DB)"  = ( #"a" + ( #"^(7E)" * #"^(03)" ))
  --test-- "byte-auto-1204"
  --assert #"^(76)"  = ( #"^(7E)" * #"^(05)" )
  --test-- "byte-auto-1205"
      ba-b1: #"^(7E)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(76)"  = ba-b3 
  --test-- "byte-auto-1206"
  --assert #"^(D7)"  = ( #"a" + ( #"^(7E)" * #"^(05)" ))
  --test-- "byte-auto-1207"
  --assert #"^(20)"  = ( #"^(7E)" * #"^(F0)" )
  --test-- "byte-auto-1208"
      ba-b1: #"^(7E)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(20)"  = ba-b3 
  --test-- "byte-auto-1209"
  --assert #"^(81)"  = ( #"a" + ( #"^(7E)" * #"^(F0)" ))
  --test-- "byte-auto-1210"
  --assert #"^(86)"  = ( #"^(7E)" * #"^(FD)" )
  --test-- "byte-auto-1211"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(86)"  = ba-b3 
  --test-- "byte-auto-1212"
  --assert #"^(E7)"  = ( #"a" + ( #"^(7E)" * #"^(FD)" ))
  --test-- "byte-auto-1213"
  --assert #"^(04)"  = ( #"^(7E)" * #"^(FE)" )
  --test-- "byte-auto-1214"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-1215"
  --assert #"^(65)"  = ( #"a" + ( #"^(7E)" * #"^(FE)" ))
  --test-- "byte-auto-1216"
  --assert #"^(04)"  = ( #"^(7E)" * #"^(7E)" )
  --test-- "byte-auto-1217"
      ba-b1: #"^(7E)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-1218"
  --assert #"^(65)"  = ( #"a" + ( #"^(7E)" * #"^(7E)" ))
  --test-- "byte-auto-1219"
  --assert #"^(AA)"  = ( #"^(7E)" * #"^(6B)" )
  --test-- "byte-auto-1220"
      ba-b1: #"^(7E)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(AA)"  = ba-b3 
  --test-- "byte-auto-1221"
  --assert #"^(0B)"  = ( #"a" + ( #"^(7E)" * #"^(6B)" ))
  --test-- "byte-auto-1222"
  --assert #"^(8A)"  = ( #"^(7E)" * #"^(FB)" )
  --test-- "byte-auto-1223"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(8A)"  = ba-b3 
  --test-- "byte-auto-1224"
  --assert #"^(EB)"  = ( #"a" + ( #"^(7E)" * #"^(FB)" ))
  --test-- "byte-auto-1225"
  --assert #"^(00)"  = ( #"^(6B)" * #"^(00)" )
  --test-- "byte-auto-1226"
      ba-b1: #"^(6B)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1227"
  --assert #"^(61)"  = ( #"a" + ( #"^(6B)" * #"^(00)" ))
  --test-- "byte-auto-1228"
  --assert #"^(95)"  = ( #"^(6B)" * #"^(FF)" )
  --test-- "byte-auto-1229"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(95)"  = ba-b3 
  --test-- "byte-auto-1230"
  --assert #"^(F6)"  = ( #"a" + ( #"^(6B)" * #"^(FF)" ))
  --test-- "byte-auto-1231"
  --assert #"^(6B)"  = ( #"^(6B)" * #"^(01)" )
  --test-- "byte-auto-1232"
      ba-b1: #"^(6B)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-1233"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" * #"^(01)" ))
  --test-- "byte-auto-1234"
  --assert #"^(D6)"  = ( #"^(6B)" * #"^(02)" )
  --test-- "byte-auto-1235"
      ba-b1: #"^(6B)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(D6)"  = ba-b3 
  --test-- "byte-auto-1236"
  --assert #"^(37)"  = ( #"a" + ( #"^(6B)" * #"^(02)" ))
  --test-- "byte-auto-1237"
  --assert #"^(41)"  = ( #"^(6B)" * #"^(03)" )
  --test-- "byte-auto-1238"
      ba-b1: #"^(6B)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(41)"  = ba-b3 
  --test-- "byte-auto-1239"
  --assert #"^(A2)"  = ( #"a" + ( #"^(6B)" * #"^(03)" ))
  --test-- "byte-auto-1240"
  --assert #"^(17)"  = ( #"^(6B)" * #"^(05)" )
  --test-- "byte-auto-1241"
      ba-b1: #"^(6B)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(17)"  = ba-b3 
  --test-- "byte-auto-1242"
  --assert #"^(78)"  = ( #"a" + ( #"^(6B)" * #"^(05)" ))
  --test-- "byte-auto-1243"
  --assert #"^(50)"  = ( #"^(6B)" * #"^(F0)" )
  --test-- "byte-auto-1244"
      ba-b1: #"^(6B)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(50)"  = ba-b3 
  --test-- "byte-auto-1245"
  --assert #"^(B1)"  = ( #"a" + ( #"^(6B)" * #"^(F0)" ))
  --test-- "byte-auto-1246"
  --assert #"^(BF)"  = ( #"^(6B)" * #"^(FD)" )
  --test-- "byte-auto-1247"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(BF)"  = ba-b3 
  --test-- "byte-auto-1248"
  --assert #"^(20)"  = ( #"a" + ( #"^(6B)" * #"^(FD)" ))
  --test-- "byte-auto-1249"
  --assert #"^(2A)"  = ( #"^(6B)" * #"^(FE)" )
  --test-- "byte-auto-1250"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(2A)"  = ba-b3 
  --test-- "byte-auto-1251"
  --assert #"^(8B)"  = ( #"a" + ( #"^(6B)" * #"^(FE)" ))
  --test-- "byte-auto-1252"
  --assert #"^(AA)"  = ( #"^(6B)" * #"^(7E)" )
  --test-- "byte-auto-1253"
      ba-b1: #"^(6B)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(AA)"  = ba-b3 
  --test-- "byte-auto-1254"
  --assert #"^(0B)"  = ( #"a" + ( #"^(6B)" * #"^(7E)" ))
  --test-- "byte-auto-1255"
  --assert #"^(B9)"  = ( #"^(6B)" * #"^(6B)" )
  --test-- "byte-auto-1256"
      ba-b1: #"^(6B)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(B9)"  = ba-b3 
  --test-- "byte-auto-1257"
  --assert #"^(1A)"  = ( #"a" + ( #"^(6B)" * #"^(6B)" ))
  --test-- "byte-auto-1258"
  --assert #"^(E9)"  = ( #"^(6B)" * #"^(FB)" )
  --test-- "byte-auto-1259"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(E9)"  = ba-b3 
  --test-- "byte-auto-1260"
  --assert #"^(4A)"  = ( #"a" + ( #"^(6B)" * #"^(FB)" ))
  --test-- "byte-auto-1261"
  --assert #"^(00)"  = ( #"^(FB)" * #"^(00)" )
  --test-- "byte-auto-1262"
      ba-b1: #"^(FB)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1263"
  --assert #"^(61)"  = ( #"a" + ( #"^(FB)" * #"^(00)" ))
  --test-- "byte-auto-1264"
  --assert #"^(05)"  = ( #"^(FB)" * #"^(FF)" )
  --test-- "byte-auto-1265"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-1266"
  --assert #"^(66)"  = ( #"a" + ( #"^(FB)" * #"^(FF)" ))
  --test-- "byte-auto-1267"
  --assert #"^(FB)"  = ( #"^(FB)" * #"^(01)" )
  --test-- "byte-auto-1268"
      ba-b1: #"^(FB)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-1269"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" * #"^(01)" ))
  --test-- "byte-auto-1270"
  --assert #"^(F6)"  = ( #"^(FB)" * #"^(02)" )
  --test-- "byte-auto-1271"
      ba-b1: #"^(FB)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(F6)"  = ba-b3 
  --test-- "byte-auto-1272"
  --assert #"^(57)"  = ( #"a" + ( #"^(FB)" * #"^(02)" ))
  --test-- "byte-auto-1273"
  --assert #"^(F1)"  = ( #"^(FB)" * #"^(03)" )
  --test-- "byte-auto-1274"
      ba-b1: #"^(FB)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(F1)"  = ba-b3 
  --test-- "byte-auto-1275"
  --assert #"^(52)"  = ( #"a" + ( #"^(FB)" * #"^(03)" ))
  --test-- "byte-auto-1276"
  --assert #"^(E7)"  = ( #"^(FB)" * #"^(05)" )
  --test-- "byte-auto-1277"
      ba-b1: #"^(FB)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(E7)"  = ba-b3 
  --test-- "byte-auto-1278"
  --assert #"^(48)"  = ( #"a" + ( #"^(FB)" * #"^(05)" ))
  --test-- "byte-auto-1279"
  --assert #"^(50)"  = ( #"^(FB)" * #"^(F0)" )
  --test-- "byte-auto-1280"
      ba-b1: #"^(FB)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(50)"  = ba-b3 
  --test-- "byte-auto-1281"
  --assert #"^(B1)"  = ( #"a" + ( #"^(FB)" * #"^(F0)" ))
  --test-- "byte-auto-1282"
  --assert #"^(0F)"  = ( #"^(FB)" * #"^(FD)" )
  --test-- "byte-auto-1283"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(0F)"  = ba-b3 
  --test-- "byte-auto-1284"
  --assert #"^(70)"  = ( #"a" + ( #"^(FB)" * #"^(FD)" ))
  --test-- "byte-auto-1285"
  --assert #"^(0A)"  = ( #"^(FB)" * #"^(FE)" )
  --test-- "byte-auto-1286"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(0A)"  = ba-b3 
  --test-- "byte-auto-1287"
  --assert #"^(6B)"  = ( #"a" + ( #"^(FB)" * #"^(FE)" ))
  --test-- "byte-auto-1288"
  --assert #"^(8A)"  = ( #"^(FB)" * #"^(7E)" )
  --test-- "byte-auto-1289"
      ba-b1: #"^(FB)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(8A)"  = ba-b3 
  --test-- "byte-auto-1290"
  --assert #"^(EB)"  = ( #"a" + ( #"^(FB)" * #"^(7E)" ))
  --test-- "byte-auto-1291"
  --assert #"^(E9)"  = ( #"^(FB)" * #"^(6B)" )
  --test-- "byte-auto-1292"
      ba-b1: #"^(FB)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(E9)"  = ba-b3 
  --test-- "byte-auto-1293"
  --assert #"^(4A)"  = ( #"a" + ( #"^(FB)" * #"^(6B)" ))
  --test-- "byte-auto-1294"
  --assert #"^(19)"  = ( #"^(FB)" * #"^(FB)" )
  --test-- "byte-auto-1295"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 * ba-b2
  --assert #"^(19)"  = ba-b3 
  --test-- "byte-auto-1296"
  --assert #"^(7A)"  = ( #"a" + ( #"^(FB)" * #"^(FB)" ))
  --test-- "byte-auto-1297"
  --assert #"^(00)"  = ( #"^(00)" / #"^(FF)" )
  --test-- "byte-auto-1298"
      ba-b1: #"^(00)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1299"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" / #"^(FF)" ))
  --test-- "byte-auto-1300"
  --assert #"^(00)"  = ( #"^(00)" / #"^(01)" )
  --test-- "byte-auto-1301"
      ba-b1: #"^(00)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1302"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" / #"^(01)" ))
  --test-- "byte-auto-1303"
  --assert #"^(00)"  = ( #"^(00)" / #"^(02)" )
  --test-- "byte-auto-1304"
      ba-b1: #"^(00)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1305"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" / #"^(02)" ))
  --test-- "byte-auto-1306"
  --assert #"^(00)"  = ( #"^(00)" / #"^(03)" )
  --test-- "byte-auto-1307"
      ba-b1: #"^(00)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1308"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" / #"^(03)" ))
  --test-- "byte-auto-1309"
  --assert #"^(00)"  = ( #"^(00)" / #"^(05)" )
  --test-- "byte-auto-1310"
      ba-b1: #"^(00)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1311"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" / #"^(05)" ))
  --test-- "byte-auto-1312"
  --assert #"^(00)"  = ( #"^(00)" / #"^(F0)" )
  --test-- "byte-auto-1313"
      ba-b1: #"^(00)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1314"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" / #"^(F0)" ))
  --test-- "byte-auto-1315"
  --assert #"^(00)"  = ( #"^(00)" / #"^(FD)" )
  --test-- "byte-auto-1316"
      ba-b1: #"^(00)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1317"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" / #"^(FD)" ))
  --test-- "byte-auto-1318"
  --assert #"^(00)"  = ( #"^(00)" / #"^(FE)" )
  --test-- "byte-auto-1319"
      ba-b1: #"^(00)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1320"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" / #"^(FE)" ))
  --test-- "byte-auto-1321"
  --assert #"^(00)"  = ( #"^(00)" / #"^(7E)" )
  --test-- "byte-auto-1322"
      ba-b1: #"^(00)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1323"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" / #"^(7E)" ))
  --test-- "byte-auto-1324"
  --assert #"^(00)"  = ( #"^(00)" / #"^(6B)" )
  --test-- "byte-auto-1325"
      ba-b1: #"^(00)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1326"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" / #"^(6B)" ))
  --test-- "byte-auto-1327"
  --assert #"^(00)"  = ( #"^(00)" / #"^(FB)" )
  --test-- "byte-auto-1328"
      ba-b1: #"^(00)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1329"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" / #"^(FB)" ))
  --test-- "byte-auto-1330"
  --assert #"^(01)"  = ( #"^(FF)" / #"^(FF)" )
  --test-- "byte-auto-1331"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1332"
  --assert #"^(62)"  = ( #"a" + ( #"^(FF)" / #"^(FF)" ))
  --test-- "byte-auto-1333"
  --assert #"^(FF)"  = ( #"^(FF)" / #"^(01)" )
  --test-- "byte-auto-1334"
      ba-b1: #"^(FF)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-1335"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" / #"^(01)" ))
  --test-- "byte-auto-1336"
  --assert #"^(7F)"  = ( #"^(FF)" / #"^(02)" )
  --test-- "byte-auto-1337"
      ba-b1: #"^(FF)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-1338"
  --assert #"^(E0)"  = ( #"a" + ( #"^(FF)" / #"^(02)" ))
  --test-- "byte-auto-1339"
  --assert #"^(55)"  = ( #"^(FF)" / #"^(03)" )
  --test-- "byte-auto-1340"
      ba-b1: #"^(FF)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(55)"  = ba-b3 
  --test-- "byte-auto-1341"
  --assert #"^(B6)"  = ( #"a" + ( #"^(FF)" / #"^(03)" ))
  --test-- "byte-auto-1342"
  --assert #"^(33)"  = ( #"^(FF)" / #"^(05)" )
  --test-- "byte-auto-1343"
      ba-b1: #"^(FF)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(33)"  = ba-b3 
  --test-- "byte-auto-1344"
  --assert #"^(94)"  = ( #"a" + ( #"^(FF)" / #"^(05)" ))
  --test-- "byte-auto-1345"
  --assert #"^(01)"  = ( #"^(FF)" / #"^(F0)" )
  --test-- "byte-auto-1346"
      ba-b1: #"^(FF)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1347"
  --assert #"^(62)"  = ( #"a" + ( #"^(FF)" / #"^(F0)" ))
  --test-- "byte-auto-1348"
  --assert #"^(01)"  = ( #"^(FF)" / #"^(FD)" )
  --test-- "byte-auto-1349"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1350"
  --assert #"^(62)"  = ( #"a" + ( #"^(FF)" / #"^(FD)" ))
  --test-- "byte-auto-1351"
  --assert #"^(01)"  = ( #"^(FF)" / #"^(FE)" )
  --test-- "byte-auto-1352"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1353"
  --assert #"^(62)"  = ( #"a" + ( #"^(FF)" / #"^(FE)" ))
  --test-- "byte-auto-1354"
  --assert #"^(02)"  = ( #"^(FF)" / #"^(7E)" )
  --test-- "byte-auto-1355"
      ba-b1: #"^(FF)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1356"
  --assert #"^(63)"  = ( #"a" + ( #"^(FF)" / #"^(7E)" ))
  --test-- "byte-auto-1357"
  --assert #"^(02)"  = ( #"^(FF)" / #"^(6B)" )
  --test-- "byte-auto-1358"
      ba-b1: #"^(FF)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1359"
  --assert #"^(63)"  = ( #"a" + ( #"^(FF)" / #"^(6B)" ))
  --test-- "byte-auto-1360"
  --assert #"^(01)"  = ( #"^(FF)" / #"^(FB)" )
  --test-- "byte-auto-1361"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1362"
  --assert #"^(62)"  = ( #"a" + ( #"^(FF)" / #"^(FB)" ))
  --test-- "byte-auto-1363"
  --assert #"^(00)"  = ( #"^(01)" / #"^(FF)" )
  --test-- "byte-auto-1364"
      ba-b1: #"^(01)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1365"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" / #"^(FF)" ))
  --test-- "byte-auto-1366"
  --assert #"^(01)"  = ( #"^(01)" / #"^(01)" )
  --test-- "byte-auto-1367"
      ba-b1: #"^(01)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1368"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" / #"^(01)" ))
  --test-- "byte-auto-1369"
  --assert #"^(00)"  = ( #"^(01)" / #"^(02)" )
  --test-- "byte-auto-1370"
      ba-b1: #"^(01)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1371"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" / #"^(02)" ))
  --test-- "byte-auto-1372"
  --assert #"^(00)"  = ( #"^(01)" / #"^(03)" )
  --test-- "byte-auto-1373"
      ba-b1: #"^(01)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1374"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" / #"^(03)" ))
  --test-- "byte-auto-1375"
  --assert #"^(00)"  = ( #"^(01)" / #"^(05)" )
  --test-- "byte-auto-1376"
      ba-b1: #"^(01)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1377"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" / #"^(05)" ))
  --test-- "byte-auto-1378"
  --assert #"^(00)"  = ( #"^(01)" / #"^(F0)" )
  --test-- "byte-auto-1379"
      ba-b1: #"^(01)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1380"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" / #"^(F0)" ))
  --test-- "byte-auto-1381"
  --assert #"^(00)"  = ( #"^(01)" / #"^(FD)" )
  --test-- "byte-auto-1382"
      ba-b1: #"^(01)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1383"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" / #"^(FD)" ))
  --test-- "byte-auto-1384"
  --assert #"^(00)"  = ( #"^(01)" / #"^(FE)" )
  --test-- "byte-auto-1385"
      ba-b1: #"^(01)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1386"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" / #"^(FE)" ))
  --test-- "byte-auto-1387"
  --assert #"^(00)"  = ( #"^(01)" / #"^(7E)" )
  --test-- "byte-auto-1388"
      ba-b1: #"^(01)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1389"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" / #"^(7E)" ))
  --test-- "byte-auto-1390"
  --assert #"^(00)"  = ( #"^(01)" / #"^(6B)" )
  --test-- "byte-auto-1391"
      ba-b1: #"^(01)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1392"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" / #"^(6B)" ))
  --test-- "byte-auto-1393"
  --assert #"^(00)"  = ( #"^(01)" / #"^(FB)" )
  --test-- "byte-auto-1394"
      ba-b1: #"^(01)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1395"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" / #"^(FB)" ))
  --test-- "byte-auto-1396"
  --assert #"^(00)"  = ( #"^(02)" / #"^(FF)" )
  --test-- "byte-auto-1397"
      ba-b1: #"^(02)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1398"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" / #"^(FF)" ))
  --test-- "byte-auto-1399"
  --assert #"^(02)"  = ( #"^(02)" / #"^(01)" )
  --test-- "byte-auto-1400"
      ba-b1: #"^(02)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1401"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" / #"^(01)" ))
  --test-- "byte-auto-1402"
  --assert #"^(01)"  = ( #"^(02)" / #"^(02)" )
  --test-- "byte-auto-1403"
      ba-b1: #"^(02)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1404"
  --assert #"^(62)"  = ( #"a" + ( #"^(02)" / #"^(02)" ))
  --test-- "byte-auto-1405"
  --assert #"^(00)"  = ( #"^(02)" / #"^(03)" )
  --test-- "byte-auto-1406"
      ba-b1: #"^(02)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1407"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" / #"^(03)" ))
  --test-- "byte-auto-1408"
  --assert #"^(00)"  = ( #"^(02)" / #"^(05)" )
  --test-- "byte-auto-1409"
      ba-b1: #"^(02)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1410"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" / #"^(05)" ))
  --test-- "byte-auto-1411"
  --assert #"^(00)"  = ( #"^(02)" / #"^(F0)" )
  --test-- "byte-auto-1412"
      ba-b1: #"^(02)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1413"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" / #"^(F0)" ))
  --test-- "byte-auto-1414"
  --assert #"^(00)"  = ( #"^(02)" / #"^(FD)" )
  --test-- "byte-auto-1415"
      ba-b1: #"^(02)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1416"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" / #"^(FD)" ))
  --test-- "byte-auto-1417"
  --assert #"^(00)"  = ( #"^(02)" / #"^(FE)" )
  --test-- "byte-auto-1418"
      ba-b1: #"^(02)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1419"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" / #"^(FE)" ))
  --test-- "byte-auto-1420"
  --assert #"^(00)"  = ( #"^(02)" / #"^(7E)" )
  --test-- "byte-auto-1421"
      ba-b1: #"^(02)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1422"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" / #"^(7E)" ))
  --test-- "byte-auto-1423"
  --assert #"^(00)"  = ( #"^(02)" / #"^(6B)" )
  --test-- "byte-auto-1424"
      ba-b1: #"^(02)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1425"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" / #"^(6B)" ))
  --test-- "byte-auto-1426"
  --assert #"^(00)"  = ( #"^(02)" / #"^(FB)" )
  --test-- "byte-auto-1427"
      ba-b1: #"^(02)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1428"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" / #"^(FB)" ))
  --test-- "byte-auto-1429"
  --assert #"^(00)"  = ( #"^(03)" / #"^(FF)" )
  --test-- "byte-auto-1430"
      ba-b1: #"^(03)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1431"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" / #"^(FF)" ))
  --test-- "byte-auto-1432"
  --assert #"^(03)"  = ( #"^(03)" / #"^(01)" )
  --test-- "byte-auto-1433"
      ba-b1: #"^(03)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1434"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" / #"^(01)" ))
  --test-- "byte-auto-1435"
  --assert #"^(01)"  = ( #"^(03)" / #"^(02)" )
  --test-- "byte-auto-1436"
      ba-b1: #"^(03)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1437"
  --assert #"^(62)"  = ( #"a" + ( #"^(03)" / #"^(02)" ))
  --test-- "byte-auto-1438"
  --assert #"^(01)"  = ( #"^(03)" / #"^(03)" )
  --test-- "byte-auto-1439"
      ba-b1: #"^(03)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1440"
  --assert #"^(62)"  = ( #"a" + ( #"^(03)" / #"^(03)" ))
  --test-- "byte-auto-1441"
  --assert #"^(00)"  = ( #"^(03)" / #"^(05)" )
  --test-- "byte-auto-1442"
      ba-b1: #"^(03)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1443"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" / #"^(05)" ))
  --test-- "byte-auto-1444"
  --assert #"^(00)"  = ( #"^(03)" / #"^(F0)" )
  --test-- "byte-auto-1445"
      ba-b1: #"^(03)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1446"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" / #"^(F0)" ))
  --test-- "byte-auto-1447"
  --assert #"^(00)"  = ( #"^(03)" / #"^(FD)" )
  --test-- "byte-auto-1448"
      ba-b1: #"^(03)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1449"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" / #"^(FD)" ))
  --test-- "byte-auto-1450"
  --assert #"^(00)"  = ( #"^(03)" / #"^(FE)" )
  --test-- "byte-auto-1451"
      ba-b1: #"^(03)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1452"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" / #"^(FE)" ))
  --test-- "byte-auto-1453"
  --assert #"^(00)"  = ( #"^(03)" / #"^(7E)" )
  --test-- "byte-auto-1454"
      ba-b1: #"^(03)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1455"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" / #"^(7E)" ))
  --test-- "byte-auto-1456"
  --assert #"^(00)"  = ( #"^(03)" / #"^(6B)" )
  --test-- "byte-auto-1457"
      ba-b1: #"^(03)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1458"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" / #"^(6B)" ))
  --test-- "byte-auto-1459"
  --assert #"^(00)"  = ( #"^(03)" / #"^(FB)" )
  --test-- "byte-auto-1460"
      ba-b1: #"^(03)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1461"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" / #"^(FB)" ))
  --test-- "byte-auto-1462"
  --assert #"^(00)"  = ( #"^(05)" / #"^(FF)" )
  --test-- "byte-auto-1463"
      ba-b1: #"^(05)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1464"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" / #"^(FF)" ))
  --test-- "byte-auto-1465"
  --assert #"^(05)"  = ( #"^(05)" / #"^(01)" )
  --test-- "byte-auto-1466"
      ba-b1: #"^(05)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-1467"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" / #"^(01)" ))
  --test-- "byte-auto-1468"
  --assert #"^(02)"  = ( #"^(05)" / #"^(02)" )
  --test-- "byte-auto-1469"
      ba-b1: #"^(05)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1470"
  --assert #"^(63)"  = ( #"a" + ( #"^(05)" / #"^(02)" ))
  --test-- "byte-auto-1471"
  --assert #"^(01)"  = ( #"^(05)" / #"^(03)" )
  --test-- "byte-auto-1472"
      ba-b1: #"^(05)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1473"
  --assert #"^(62)"  = ( #"a" + ( #"^(05)" / #"^(03)" ))
  --test-- "byte-auto-1474"
  --assert #"^(01)"  = ( #"^(05)" / #"^(05)" )
  --test-- "byte-auto-1475"
      ba-b1: #"^(05)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1476"
  --assert #"^(62)"  = ( #"a" + ( #"^(05)" / #"^(05)" ))
  --test-- "byte-auto-1477"
  --assert #"^(00)"  = ( #"^(05)" / #"^(F0)" )
  --test-- "byte-auto-1478"
      ba-b1: #"^(05)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1479"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" / #"^(F0)" ))
  --test-- "byte-auto-1480"
  --assert #"^(00)"  = ( #"^(05)" / #"^(FD)" )
  --test-- "byte-auto-1481"
      ba-b1: #"^(05)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1482"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" / #"^(FD)" ))
  --test-- "byte-auto-1483"
  --assert #"^(00)"  = ( #"^(05)" / #"^(FE)" )
  --test-- "byte-auto-1484"
      ba-b1: #"^(05)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1485"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" / #"^(FE)" ))
  --test-- "byte-auto-1486"
  --assert #"^(00)"  = ( #"^(05)" / #"^(7E)" )
  --test-- "byte-auto-1487"
      ba-b1: #"^(05)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1488"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" / #"^(7E)" ))
  --test-- "byte-auto-1489"
  --assert #"^(00)"  = ( #"^(05)" / #"^(6B)" )
  --test-- "byte-auto-1490"
      ba-b1: #"^(05)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1491"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" / #"^(6B)" ))
  --test-- "byte-auto-1492"
  --assert #"^(00)"  = ( #"^(05)" / #"^(FB)" )
  --test-- "byte-auto-1493"
      ba-b1: #"^(05)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1494"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" / #"^(FB)" ))
  --test-- "byte-auto-1495"
  --assert #"^(00)"  = ( #"^(F0)" / #"^(FF)" )
  --test-- "byte-auto-1496"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1497"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" / #"^(FF)" ))
  --test-- "byte-auto-1498"
  --assert #"^(F0)"  = ( #"^(F0)" / #"^(01)" )
  --test-- "byte-auto-1499"
      ba-b1: #"^(F0)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-1500"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" / #"^(01)" ))
  --test-- "byte-auto-1501"
  --assert #"^(78)"  = ( #"^(F0)" / #"^(02)" )
  --test-- "byte-auto-1502"
      ba-b1: #"^(F0)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(78)"  = ba-b3 
  --test-- "byte-auto-1503"
  --assert #"^(D9)"  = ( #"a" + ( #"^(F0)" / #"^(02)" ))
  --test-- "byte-auto-1504"
  --assert #"^(50)"  = ( #"^(F0)" / #"^(03)" )
  --test-- "byte-auto-1505"
      ba-b1: #"^(F0)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(50)"  = ba-b3 
  --test-- "byte-auto-1506"
  --assert #"^(B1)"  = ( #"a" + ( #"^(F0)" / #"^(03)" ))
  --test-- "byte-auto-1507"
  --assert #"^(30)"  = ( #"^(F0)" / #"^(05)" )
  --test-- "byte-auto-1508"
      ba-b1: #"^(F0)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(30)"  = ba-b3 
  --test-- "byte-auto-1509"
  --assert #"^(91)"  = ( #"a" + ( #"^(F0)" / #"^(05)" ))
  --test-- "byte-auto-1510"
  --assert #"^(01)"  = ( #"^(F0)" / #"^(F0)" )
  --test-- "byte-auto-1511"
      ba-b1: #"^(F0)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1512"
  --assert #"^(62)"  = ( #"a" + ( #"^(F0)" / #"^(F0)" ))
  --test-- "byte-auto-1513"
  --assert #"^(00)"  = ( #"^(F0)" / #"^(FD)" )
  --test-- "byte-auto-1514"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1515"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" / #"^(FD)" ))
  --test-- "byte-auto-1516"
  --assert #"^(00)"  = ( #"^(F0)" / #"^(FE)" )
  --test-- "byte-auto-1517"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1518"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" / #"^(FE)" ))
  --test-- "byte-auto-1519"
  --assert #"^(01)"  = ( #"^(F0)" / #"^(7E)" )
  --test-- "byte-auto-1520"
      ba-b1: #"^(F0)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1521"
  --assert #"^(62)"  = ( #"a" + ( #"^(F0)" / #"^(7E)" ))
  --test-- "byte-auto-1522"
  --assert #"^(02)"  = ( #"^(F0)" / #"^(6B)" )
  --test-- "byte-auto-1523"
      ba-b1: #"^(F0)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1524"
  --assert #"^(63)"  = ( #"a" + ( #"^(F0)" / #"^(6B)" ))
  --test-- "byte-auto-1525"
  --assert #"^(00)"  = ( #"^(F0)" / #"^(FB)" )
  --test-- "byte-auto-1526"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1527"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" / #"^(FB)" ))
  --test-- "byte-auto-1528"
  --assert #"^(00)"  = ( #"^(FD)" / #"^(FF)" )
  --test-- "byte-auto-1529"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1530"
  --assert #"^(61)"  = ( #"a" + ( #"^(FD)" / #"^(FF)" ))
  --test-- "byte-auto-1531"
  --assert #"^(FD)"  = ( #"^(FD)" / #"^(01)" )
  --test-- "byte-auto-1532"
      ba-b1: #"^(FD)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-1533"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" / #"^(01)" ))
  --test-- "byte-auto-1534"
  --assert #"^(7E)"  = ( #"^(FD)" / #"^(02)" )
  --test-- "byte-auto-1535"
      ba-b1: #"^(FD)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-1536"
  --assert #"^(DF)"  = ( #"a" + ( #"^(FD)" / #"^(02)" ))
  --test-- "byte-auto-1537"
  --assert #"^(54)"  = ( #"^(FD)" / #"^(03)" )
  --test-- "byte-auto-1538"
      ba-b1: #"^(FD)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(54)"  = ba-b3 
  --test-- "byte-auto-1539"
  --assert #"^(B5)"  = ( #"a" + ( #"^(FD)" / #"^(03)" ))
  --test-- "byte-auto-1540"
  --assert #"^(32)"  = ( #"^(FD)" / #"^(05)" )
  --test-- "byte-auto-1541"
      ba-b1: #"^(FD)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(32)"  = ba-b3 
  --test-- "byte-auto-1542"
  --assert #"^(93)"  = ( #"a" + ( #"^(FD)" / #"^(05)" ))
  --test-- "byte-auto-1543"
  --assert #"^(01)"  = ( #"^(FD)" / #"^(F0)" )
  --test-- "byte-auto-1544"
      ba-b1: #"^(FD)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1545"
  --assert #"^(62)"  = ( #"a" + ( #"^(FD)" / #"^(F0)" ))
  --test-- "byte-auto-1546"
  --assert #"^(01)"  = ( #"^(FD)" / #"^(FD)" )
  --test-- "byte-auto-1547"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1548"
  --assert #"^(62)"  = ( #"a" + ( #"^(FD)" / #"^(FD)" ))
  --test-- "byte-auto-1549"
  --assert #"^(00)"  = ( #"^(FD)" / #"^(FE)" )
  --test-- "byte-auto-1550"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1551"
  --assert #"^(61)"  = ( #"a" + ( #"^(FD)" / #"^(FE)" ))
  --test-- "byte-auto-1552"
  --assert #"^(02)"  = ( #"^(FD)" / #"^(7E)" )
  --test-- "byte-auto-1553"
      ba-b1: #"^(FD)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1554"
  --assert #"^(63)"  = ( #"a" + ( #"^(FD)" / #"^(7E)" ))
  --test-- "byte-auto-1555"
  --assert #"^(02)"  = ( #"^(FD)" / #"^(6B)" )
  --test-- "byte-auto-1556"
      ba-b1: #"^(FD)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1557"
  --assert #"^(63)"  = ( #"a" + ( #"^(FD)" / #"^(6B)" ))
  --test-- "byte-auto-1558"
  --assert #"^(01)"  = ( #"^(FD)" / #"^(FB)" )
  --test-- "byte-auto-1559"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1560"
  --assert #"^(62)"  = ( #"a" + ( #"^(FD)" / #"^(FB)" ))
  --test-- "byte-auto-1561"
  --assert #"^(00)"  = ( #"^(FE)" / #"^(FF)" )
  --test-- "byte-auto-1562"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1563"
  --assert #"^(61)"  = ( #"a" + ( #"^(FE)" / #"^(FF)" ))
  --test-- "byte-auto-1564"
  --assert #"^(FE)"  = ( #"^(FE)" / #"^(01)" )
  --test-- "byte-auto-1565"
      ba-b1: #"^(FE)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-1566"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" / #"^(01)" ))
  --test-- "byte-auto-1567"
  --assert #"^(7F)"  = ( #"^(FE)" / #"^(02)" )
  --test-- "byte-auto-1568"
      ba-b1: #"^(FE)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-1569"
  --assert #"^(E0)"  = ( #"a" + ( #"^(FE)" / #"^(02)" ))
  --test-- "byte-auto-1570"
  --assert #"^(54)"  = ( #"^(FE)" / #"^(03)" )
  --test-- "byte-auto-1571"
      ba-b1: #"^(FE)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(54)"  = ba-b3 
  --test-- "byte-auto-1572"
  --assert #"^(B5)"  = ( #"a" + ( #"^(FE)" / #"^(03)" ))
  --test-- "byte-auto-1573"
  --assert #"^(32)"  = ( #"^(FE)" / #"^(05)" )
  --test-- "byte-auto-1574"
      ba-b1: #"^(FE)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(32)"  = ba-b3 
  --test-- "byte-auto-1575"
  --assert #"^(93)"  = ( #"a" + ( #"^(FE)" / #"^(05)" ))
  --test-- "byte-auto-1576"
  --assert #"^(01)"  = ( #"^(FE)" / #"^(F0)" )
  --test-- "byte-auto-1577"
      ba-b1: #"^(FE)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1578"
  --assert #"^(62)"  = ( #"a" + ( #"^(FE)" / #"^(F0)" ))
  --test-- "byte-auto-1579"
  --assert #"^(01)"  = ( #"^(FE)" / #"^(FD)" )
  --test-- "byte-auto-1580"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1581"
  --assert #"^(62)"  = ( #"a" + ( #"^(FE)" / #"^(FD)" ))
  --test-- "byte-auto-1582"
  --assert #"^(01)"  = ( #"^(FE)" / #"^(FE)" )
  --test-- "byte-auto-1583"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1584"
  --assert #"^(62)"  = ( #"a" + ( #"^(FE)" / #"^(FE)" ))
  --test-- "byte-auto-1585"
  --assert #"^(02)"  = ( #"^(FE)" / #"^(7E)" )
  --test-- "byte-auto-1586"
      ba-b1: #"^(FE)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1587"
  --assert #"^(63)"  = ( #"a" + ( #"^(FE)" / #"^(7E)" ))
  --test-- "byte-auto-1588"
  --assert #"^(02)"  = ( #"^(FE)" / #"^(6B)" )
  --test-- "byte-auto-1589"
      ba-b1: #"^(FE)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1590"
  --assert #"^(63)"  = ( #"a" + ( #"^(FE)" / #"^(6B)" ))
  --test-- "byte-auto-1591"
  --assert #"^(01)"  = ( #"^(FE)" / #"^(FB)" )
  --test-- "byte-auto-1592"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1593"
  --assert #"^(62)"  = ( #"a" + ( #"^(FE)" / #"^(FB)" ))
  --test-- "byte-auto-1594"
  --assert #"^(00)"  = ( #"^(7E)" / #"^(FF)" )
  --test-- "byte-auto-1595"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1596"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" / #"^(FF)" ))
  --test-- "byte-auto-1597"
  --assert #"^(7E)"  = ( #"^(7E)" / #"^(01)" )
  --test-- "byte-auto-1598"
      ba-b1: #"^(7E)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-1599"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" / #"^(01)" ))
  --test-- "byte-auto-1600"
  --assert #"^(3F)"  = ( #"^(7E)" / #"^(02)" )
  --test-- "byte-auto-1601"
      ba-b1: #"^(7E)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(3F)"  = ba-b3 
  --test-- "byte-auto-1602"
  --assert #"^(A0)"  = ( #"a" + ( #"^(7E)" / #"^(02)" ))
  --test-- "byte-auto-1603"
  --assert #"^(2A)"  = ( #"^(7E)" / #"^(03)" )
  --test-- "byte-auto-1604"
      ba-b1: #"^(7E)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(2A)"  = ba-b3 
  --test-- "byte-auto-1605"
  --assert #"^(8B)"  = ( #"a" + ( #"^(7E)" / #"^(03)" ))
  --test-- "byte-auto-1606"
  --assert #"^(19)"  = ( #"^(7E)" / #"^(05)" )
  --test-- "byte-auto-1607"
      ba-b1: #"^(7E)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(19)"  = ba-b3 
  --test-- "byte-auto-1608"
  --assert #"^(7A)"  = ( #"a" + ( #"^(7E)" / #"^(05)" ))
  --test-- "byte-auto-1609"
  --assert #"^(00)"  = ( #"^(7E)" / #"^(F0)" )
  --test-- "byte-auto-1610"
      ba-b1: #"^(7E)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1611"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" / #"^(F0)" ))
  --test-- "byte-auto-1612"
  --assert #"^(00)"  = ( #"^(7E)" / #"^(FD)" )
  --test-- "byte-auto-1613"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1614"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" / #"^(FD)" ))
  --test-- "byte-auto-1615"
  --assert #"^(00)"  = ( #"^(7E)" / #"^(FE)" )
  --test-- "byte-auto-1616"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1617"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" / #"^(FE)" ))
  --test-- "byte-auto-1618"
  --assert #"^(01)"  = ( #"^(7E)" / #"^(7E)" )
  --test-- "byte-auto-1619"
      ba-b1: #"^(7E)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1620"
  --assert #"^(62)"  = ( #"a" + ( #"^(7E)" / #"^(7E)" ))
  --test-- "byte-auto-1621"
  --assert #"^(01)"  = ( #"^(7E)" / #"^(6B)" )
  --test-- "byte-auto-1622"
      ba-b1: #"^(7E)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1623"
  --assert #"^(62)"  = ( #"a" + ( #"^(7E)" / #"^(6B)" ))
  --test-- "byte-auto-1624"
  --assert #"^(00)"  = ( #"^(7E)" / #"^(FB)" )
  --test-- "byte-auto-1625"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1626"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" / #"^(FB)" ))
  --test-- "byte-auto-1627"
  --assert #"^(00)"  = ( #"^(6B)" / #"^(FF)" )
  --test-- "byte-auto-1628"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1629"
  --assert #"^(61)"  = ( #"a" + ( #"^(6B)" / #"^(FF)" ))
  --test-- "byte-auto-1630"
  --assert #"^(6B)"  = ( #"^(6B)" / #"^(01)" )
  --test-- "byte-auto-1631"
      ba-b1: #"^(6B)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-1632"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" / #"^(01)" ))
  --test-- "byte-auto-1633"
  --assert #"^(35)"  = ( #"^(6B)" / #"^(02)" )
  --test-- "byte-auto-1634"
      ba-b1: #"^(6B)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(35)"  = ba-b3 
  --test-- "byte-auto-1635"
  --assert #"^(96)"  = ( #"a" + ( #"^(6B)" / #"^(02)" ))
  --test-- "byte-auto-1636"
  --assert #"^(23)"  = ( #"^(6B)" / #"^(03)" )
  --test-- "byte-auto-1637"
      ba-b1: #"^(6B)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(23)"  = ba-b3 
  --test-- "byte-auto-1638"
  --assert #"^(84)"  = ( #"a" + ( #"^(6B)" / #"^(03)" ))
  --test-- "byte-auto-1639"
  --assert #"^(15)"  = ( #"^(6B)" / #"^(05)" )
  --test-- "byte-auto-1640"
      ba-b1: #"^(6B)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(15)"  = ba-b3 
  --test-- "byte-auto-1641"
  --assert #"^(76)"  = ( #"a" + ( #"^(6B)" / #"^(05)" ))
  --test-- "byte-auto-1642"
  --assert #"^(00)"  = ( #"^(6B)" / #"^(F0)" )
  --test-- "byte-auto-1643"
      ba-b1: #"^(6B)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1644"
  --assert #"^(61)"  = ( #"a" + ( #"^(6B)" / #"^(F0)" ))
  --test-- "byte-auto-1645"
  --assert #"^(00)"  = ( #"^(6B)" / #"^(FD)" )
  --test-- "byte-auto-1646"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1647"
  --assert #"^(61)"  = ( #"a" + ( #"^(6B)" / #"^(FD)" ))
  --test-- "byte-auto-1648"
  --assert #"^(00)"  = ( #"^(6B)" / #"^(FE)" )
  --test-- "byte-auto-1649"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1650"
  --assert #"^(61)"  = ( #"a" + ( #"^(6B)" / #"^(FE)" ))
  --test-- "byte-auto-1651"
  --assert #"^(00)"  = ( #"^(6B)" / #"^(7E)" )
  --test-- "byte-auto-1652"
      ba-b1: #"^(6B)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1653"
  --assert #"^(61)"  = ( #"a" + ( #"^(6B)" / #"^(7E)" ))
  --test-- "byte-auto-1654"
  --assert #"^(01)"  = ( #"^(6B)" / #"^(6B)" )
  --test-- "byte-auto-1655"
      ba-b1: #"^(6B)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1656"
  --assert #"^(62)"  = ( #"a" + ( #"^(6B)" / #"^(6B)" ))
  --test-- "byte-auto-1657"
  --assert #"^(00)"  = ( #"^(6B)" / #"^(FB)" )
  --test-- "byte-auto-1658"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1659"
  --assert #"^(61)"  = ( #"a" + ( #"^(6B)" / #"^(FB)" ))
  --test-- "byte-auto-1660"
  --assert #"^(00)"  = ( #"^(FB)" / #"^(FF)" )
  --test-- "byte-auto-1661"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1662"
  --assert #"^(61)"  = ( #"a" + ( #"^(FB)" / #"^(FF)" ))
  --test-- "byte-auto-1663"
  --assert #"^(FB)"  = ( #"^(FB)" / #"^(01)" )
  --test-- "byte-auto-1664"
      ba-b1: #"^(FB)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-1665"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" / #"^(01)" ))
  --test-- "byte-auto-1666"
  --assert #"^(7D)"  = ( #"^(FB)" / #"^(02)" )
  --test-- "byte-auto-1667"
      ba-b1: #"^(FB)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(7D)"  = ba-b3 
  --test-- "byte-auto-1668"
  --assert #"^(DE)"  = ( #"a" + ( #"^(FB)" / #"^(02)" ))
  --test-- "byte-auto-1669"
  --assert #"^(53)"  = ( #"^(FB)" / #"^(03)" )
  --test-- "byte-auto-1670"
      ba-b1: #"^(FB)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(53)"  = ba-b3 
  --test-- "byte-auto-1671"
  --assert #"^(B4)"  = ( #"a" + ( #"^(FB)" / #"^(03)" ))
  --test-- "byte-auto-1672"
  --assert #"^(32)"  = ( #"^(FB)" / #"^(05)" )
  --test-- "byte-auto-1673"
      ba-b1: #"^(FB)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(32)"  = ba-b3 
  --test-- "byte-auto-1674"
  --assert #"^(93)"  = ( #"a" + ( #"^(FB)" / #"^(05)" ))
  --test-- "byte-auto-1675"
  --assert #"^(01)"  = ( #"^(FB)" / #"^(F0)" )
  --test-- "byte-auto-1676"
      ba-b1: #"^(FB)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1677"
  --assert #"^(62)"  = ( #"a" + ( #"^(FB)" / #"^(F0)" ))
  --test-- "byte-auto-1678"
  --assert #"^(00)"  = ( #"^(FB)" / #"^(FD)" )
  --test-- "byte-auto-1679"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1680"
  --assert #"^(61)"  = ( #"a" + ( #"^(FB)" / #"^(FD)" ))
  --test-- "byte-auto-1681"
  --assert #"^(00)"  = ( #"^(FB)" / #"^(FE)" )
  --test-- "byte-auto-1682"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1683"
  --assert #"^(61)"  = ( #"a" + ( #"^(FB)" / #"^(FE)" ))
  --test-- "byte-auto-1684"
  --assert #"^(01)"  = ( #"^(FB)" / #"^(7E)" )
  --test-- "byte-auto-1685"
      ba-b1: #"^(FB)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1686"
  --assert #"^(62)"  = ( #"a" + ( #"^(FB)" / #"^(7E)" ))
  --test-- "byte-auto-1687"
  --assert #"^(02)"  = ( #"^(FB)" / #"^(6B)" )
  --test-- "byte-auto-1688"
      ba-b1: #"^(FB)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1689"
  --assert #"^(63)"  = ( #"a" + ( #"^(FB)" / #"^(6B)" ))
  --test-- "byte-auto-1690"
  --assert #"^(01)"  = ( #"^(FB)" / #"^(FB)" )
  --test-- "byte-auto-1691"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 / ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1692"
  --assert #"^(62)"  = ( #"a" + ( #"^(FB)" / #"^(FB)" ))
  --test-- "byte-auto-1693"
  --assert #"^(00)"  = ( #"^(00)" // #"^(FF)" )
  --test-- "byte-auto-1694"
      ba-b1: #"^(00)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1695"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" // #"^(FF)" ))
  --test-- "byte-auto-1696"
  --assert #"^(00)"  = ( #"^(00)" // #"^(01)" )
  --test-- "byte-auto-1697"
      ba-b1: #"^(00)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1698"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" // #"^(01)" ))
  --test-- "byte-auto-1699"
  --assert #"^(00)"  = ( #"^(00)" // #"^(02)" )
  --test-- "byte-auto-1700"
      ba-b1: #"^(00)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1701"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" // #"^(02)" ))
  --test-- "byte-auto-1702"
  --assert #"^(00)"  = ( #"^(00)" // #"^(03)" )
  --test-- "byte-auto-1703"
      ba-b1: #"^(00)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1704"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" // #"^(03)" ))
  --test-- "byte-auto-1705"
  --assert #"^(00)"  = ( #"^(00)" // #"^(05)" )
  --test-- "byte-auto-1706"
      ba-b1: #"^(00)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1707"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" // #"^(05)" ))
  --test-- "byte-auto-1708"
  --assert #"^(00)"  = ( #"^(00)" // #"^(F0)" )
  --test-- "byte-auto-1709"
      ba-b1: #"^(00)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1710"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" // #"^(F0)" ))
  --test-- "byte-auto-1711"
  --assert #"^(00)"  = ( #"^(00)" // #"^(FD)" )
  --test-- "byte-auto-1712"
      ba-b1: #"^(00)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1713"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" // #"^(FD)" ))
  --test-- "byte-auto-1714"
  --assert #"^(00)"  = ( #"^(00)" // #"^(FE)" )
  --test-- "byte-auto-1715"
      ba-b1: #"^(00)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1716"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" // #"^(FE)" ))
  --test-- "byte-auto-1717"
  --assert #"^(00)"  = ( #"^(00)" // #"^(7E)" )
  --test-- "byte-auto-1718"
      ba-b1: #"^(00)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1719"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" // #"^(7E)" ))
  --test-- "byte-auto-1720"
  --assert #"^(00)"  = ( #"^(00)" // #"^(6B)" )
  --test-- "byte-auto-1721"
      ba-b1: #"^(00)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1722"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" // #"^(6B)" ))
  --test-- "byte-auto-1723"
  --assert #"^(00)"  = ( #"^(00)" // #"^(FB)" )
  --test-- "byte-auto-1724"
      ba-b1: #"^(00)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1725"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" // #"^(FB)" ))
  --test-- "byte-auto-1726"
  --assert #"^(00)"  = ( #"^(FF)" // #"^(FF)" )
  --test-- "byte-auto-1727"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1728"
  --assert #"^(61)"  = ( #"a" + ( #"^(FF)" // #"^(FF)" ))
  --test-- "byte-auto-1729"
  --assert #"^(00)"  = ( #"^(FF)" // #"^(01)" )
  --test-- "byte-auto-1730"
      ba-b1: #"^(FF)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1731"
  --assert #"^(61)"  = ( #"a" + ( #"^(FF)" // #"^(01)" ))
  --test-- "byte-auto-1732"
  --assert #"^(01)"  = ( #"^(FF)" // #"^(02)" )
  --test-- "byte-auto-1733"
      ba-b1: #"^(FF)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1734"
  --assert #"^(62)"  = ( #"a" + ( #"^(FF)" // #"^(02)" ))
  --test-- "byte-auto-1735"
  --assert #"^(00)"  = ( #"^(FF)" // #"^(03)" )
  --test-- "byte-auto-1736"
      ba-b1: #"^(FF)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1737"
  --assert #"^(61)"  = ( #"a" + ( #"^(FF)" // #"^(03)" ))
  --test-- "byte-auto-1738"
  --assert #"^(00)"  = ( #"^(FF)" // #"^(05)" )
  --test-- "byte-auto-1739"
      ba-b1: #"^(FF)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1740"
  --assert #"^(61)"  = ( #"a" + ( #"^(FF)" // #"^(05)" ))
  --test-- "byte-auto-1741"
  --assert #"^(0F)"  = ( #"^(FF)" // #"^(F0)" )
  --test-- "byte-auto-1742"
      ba-b1: #"^(FF)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(0F)"  = ba-b3 
  --test-- "byte-auto-1743"
  --assert #"^(70)"  = ( #"a" + ( #"^(FF)" // #"^(F0)" ))
  --test-- "byte-auto-1744"
  --assert #"^(02)"  = ( #"^(FF)" // #"^(FD)" )
  --test-- "byte-auto-1745"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1746"
  --assert #"^(63)"  = ( #"a" + ( #"^(FF)" // #"^(FD)" ))
  --test-- "byte-auto-1747"
  --assert #"^(01)"  = ( #"^(FF)" // #"^(FE)" )
  --test-- "byte-auto-1748"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1749"
  --assert #"^(62)"  = ( #"a" + ( #"^(FF)" // #"^(FE)" ))
  --test-- "byte-auto-1750"
  --assert #"^(03)"  = ( #"^(FF)" // #"^(7E)" )
  --test-- "byte-auto-1751"
      ba-b1: #"^(FF)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1752"
  --assert #"^(64)"  = ( #"a" + ( #"^(FF)" // #"^(7E)" ))
  --test-- "byte-auto-1753"
  --assert #"^(29)"  = ( #"^(FF)" // #"^(6B)" )
  --test-- "byte-auto-1754"
      ba-b1: #"^(FF)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(29)"  = ba-b3 
  --test-- "byte-auto-1755"
  --assert #"^(8A)"  = ( #"a" + ( #"^(FF)" // #"^(6B)" ))
  --test-- "byte-auto-1756"
  --assert #"^(04)"  = ( #"^(FF)" // #"^(FB)" )
  --test-- "byte-auto-1757"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-1758"
  --assert #"^(65)"  = ( #"a" + ( #"^(FF)" // #"^(FB)" ))
  --test-- "byte-auto-1759"
  --assert #"^(01)"  = ( #"^(01)" // #"^(FF)" )
  --test-- "byte-auto-1760"
      ba-b1: #"^(01)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1761"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" // #"^(FF)" ))
  --test-- "byte-auto-1762"
  --assert #"^(00)"  = ( #"^(01)" // #"^(01)" )
  --test-- "byte-auto-1763"
      ba-b1: #"^(01)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1764"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" // #"^(01)" ))
  --test-- "byte-auto-1765"
  --assert #"^(01)"  = ( #"^(01)" // #"^(02)" )
  --test-- "byte-auto-1766"
      ba-b1: #"^(01)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1767"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" // #"^(02)" ))
  --test-- "byte-auto-1768"
  --assert #"^(01)"  = ( #"^(01)" // #"^(03)" )
  --test-- "byte-auto-1769"
      ba-b1: #"^(01)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1770"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" // #"^(03)" ))
  --test-- "byte-auto-1771"
  --assert #"^(01)"  = ( #"^(01)" // #"^(05)" )
  --test-- "byte-auto-1772"
      ba-b1: #"^(01)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1773"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" // #"^(05)" ))
  --test-- "byte-auto-1774"
  --assert #"^(01)"  = ( #"^(01)" // #"^(F0)" )
  --test-- "byte-auto-1775"
      ba-b1: #"^(01)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1776"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" // #"^(F0)" ))
  --test-- "byte-auto-1777"
  --assert #"^(01)"  = ( #"^(01)" // #"^(FD)" )
  --test-- "byte-auto-1778"
      ba-b1: #"^(01)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1779"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" // #"^(FD)" ))
  --test-- "byte-auto-1780"
  --assert #"^(01)"  = ( #"^(01)" // #"^(FE)" )
  --test-- "byte-auto-1781"
      ba-b1: #"^(01)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1782"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" // #"^(FE)" ))
  --test-- "byte-auto-1783"
  --assert #"^(01)"  = ( #"^(01)" // #"^(7E)" )
  --test-- "byte-auto-1784"
      ba-b1: #"^(01)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1785"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" // #"^(7E)" ))
  --test-- "byte-auto-1786"
  --assert #"^(01)"  = ( #"^(01)" // #"^(6B)" )
  --test-- "byte-auto-1787"
      ba-b1: #"^(01)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1788"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" // #"^(6B)" ))
  --test-- "byte-auto-1789"
  --assert #"^(01)"  = ( #"^(01)" // #"^(FB)" )
  --test-- "byte-auto-1790"
      ba-b1: #"^(01)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1791"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" // #"^(FB)" ))
  --test-- "byte-auto-1792"
  --assert #"^(02)"  = ( #"^(02)" // #"^(FF)" )
  --test-- "byte-auto-1793"
      ba-b1: #"^(02)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1794"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" // #"^(FF)" ))
  --test-- "byte-auto-1795"
  --assert #"^(00)"  = ( #"^(02)" // #"^(01)" )
  --test-- "byte-auto-1796"
      ba-b1: #"^(02)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1797"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" // #"^(01)" ))
  --test-- "byte-auto-1798"
  --assert #"^(00)"  = ( #"^(02)" // #"^(02)" )
  --test-- "byte-auto-1799"
      ba-b1: #"^(02)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1800"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" // #"^(02)" ))
  --test-- "byte-auto-1801"
  --assert #"^(02)"  = ( #"^(02)" // #"^(03)" )
  --test-- "byte-auto-1802"
      ba-b1: #"^(02)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1803"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" // #"^(03)" ))
  --test-- "byte-auto-1804"
  --assert #"^(02)"  = ( #"^(02)" // #"^(05)" )
  --test-- "byte-auto-1805"
      ba-b1: #"^(02)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1806"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" // #"^(05)" ))
  --test-- "byte-auto-1807"
  --assert #"^(02)"  = ( #"^(02)" // #"^(F0)" )
  --test-- "byte-auto-1808"
      ba-b1: #"^(02)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1809"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" // #"^(F0)" ))
  --test-- "byte-auto-1810"
  --assert #"^(02)"  = ( #"^(02)" // #"^(FD)" )
  --test-- "byte-auto-1811"
      ba-b1: #"^(02)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1812"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" // #"^(FD)" ))
  --test-- "byte-auto-1813"
  --assert #"^(02)"  = ( #"^(02)" // #"^(FE)" )
  --test-- "byte-auto-1814"
      ba-b1: #"^(02)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1815"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" // #"^(FE)" ))
  --test-- "byte-auto-1816"
  --assert #"^(02)"  = ( #"^(02)" // #"^(7E)" )
  --test-- "byte-auto-1817"
      ba-b1: #"^(02)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1818"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" // #"^(7E)" ))
  --test-- "byte-auto-1819"
  --assert #"^(02)"  = ( #"^(02)" // #"^(6B)" )
  --test-- "byte-auto-1820"
      ba-b1: #"^(02)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1821"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" // #"^(6B)" ))
  --test-- "byte-auto-1822"
  --assert #"^(02)"  = ( #"^(02)" // #"^(FB)" )
  --test-- "byte-auto-1823"
      ba-b1: #"^(02)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1824"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" // #"^(FB)" ))
  --test-- "byte-auto-1825"
  --assert #"^(03)"  = ( #"^(03)" // #"^(FF)" )
  --test-- "byte-auto-1826"
      ba-b1: #"^(03)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1827"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" // #"^(FF)" ))
  --test-- "byte-auto-1828"
  --assert #"^(00)"  = ( #"^(03)" // #"^(01)" )
  --test-- "byte-auto-1829"
      ba-b1: #"^(03)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1830"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" // #"^(01)" ))
  --test-- "byte-auto-1831"
  --assert #"^(01)"  = ( #"^(03)" // #"^(02)" )
  --test-- "byte-auto-1832"
      ba-b1: #"^(03)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1833"
  --assert #"^(62)"  = ( #"a" + ( #"^(03)" // #"^(02)" ))
  --test-- "byte-auto-1834"
  --assert #"^(00)"  = ( #"^(03)" // #"^(03)" )
  --test-- "byte-auto-1835"
      ba-b1: #"^(03)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1836"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" // #"^(03)" ))
  --test-- "byte-auto-1837"
  --assert #"^(03)"  = ( #"^(03)" // #"^(05)" )
  --test-- "byte-auto-1838"
      ba-b1: #"^(03)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1839"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" // #"^(05)" ))
  --test-- "byte-auto-1840"
  --assert #"^(03)"  = ( #"^(03)" // #"^(F0)" )
  --test-- "byte-auto-1841"
      ba-b1: #"^(03)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1842"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" // #"^(F0)" ))
  --test-- "byte-auto-1843"
  --assert #"^(03)"  = ( #"^(03)" // #"^(FD)" )
  --test-- "byte-auto-1844"
      ba-b1: #"^(03)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1845"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" // #"^(FD)" ))
  --test-- "byte-auto-1846"
  --assert #"^(03)"  = ( #"^(03)" // #"^(FE)" )
  --test-- "byte-auto-1847"
      ba-b1: #"^(03)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1848"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" // #"^(FE)" ))
  --test-- "byte-auto-1849"
  --assert #"^(03)"  = ( #"^(03)" // #"^(7E)" )
  --test-- "byte-auto-1850"
      ba-b1: #"^(03)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1851"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" // #"^(7E)" ))
  --test-- "byte-auto-1852"
  --assert #"^(03)"  = ( #"^(03)" // #"^(6B)" )
  --test-- "byte-auto-1853"
      ba-b1: #"^(03)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1854"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" // #"^(6B)" ))
  --test-- "byte-auto-1855"
  --assert #"^(03)"  = ( #"^(03)" // #"^(FB)" )
  --test-- "byte-auto-1856"
      ba-b1: #"^(03)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1857"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" // #"^(FB)" ))
  --test-- "byte-auto-1858"
  --assert #"^(05)"  = ( #"^(05)" // #"^(FF)" )
  --test-- "byte-auto-1859"
      ba-b1: #"^(05)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-1860"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" // #"^(FF)" ))
  --test-- "byte-auto-1861"
  --assert #"^(00)"  = ( #"^(05)" // #"^(01)" )
  --test-- "byte-auto-1862"
      ba-b1: #"^(05)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1863"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" // #"^(01)" ))
  --test-- "byte-auto-1864"
  --assert #"^(01)"  = ( #"^(05)" // #"^(02)" )
  --test-- "byte-auto-1865"
      ba-b1: #"^(05)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1866"
  --assert #"^(62)"  = ( #"a" + ( #"^(05)" // #"^(02)" ))
  --test-- "byte-auto-1867"
  --assert #"^(02)"  = ( #"^(05)" // #"^(03)" )
  --test-- "byte-auto-1868"
      ba-b1: #"^(05)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1869"
  --assert #"^(63)"  = ( #"a" + ( #"^(05)" // #"^(03)" ))
  --test-- "byte-auto-1870"
  --assert #"^(00)"  = ( #"^(05)" // #"^(05)" )
  --test-- "byte-auto-1871"
      ba-b1: #"^(05)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1872"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" // #"^(05)" ))
  --test-- "byte-auto-1873"
  --assert #"^(05)"  = ( #"^(05)" // #"^(F0)" )
  --test-- "byte-auto-1874"
      ba-b1: #"^(05)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-1875"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" // #"^(F0)" ))
  --test-- "byte-auto-1876"
  --assert #"^(05)"  = ( #"^(05)" // #"^(FD)" )
  --test-- "byte-auto-1877"
      ba-b1: #"^(05)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-1878"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" // #"^(FD)" ))
  --test-- "byte-auto-1879"
  --assert #"^(05)"  = ( #"^(05)" // #"^(FE)" )
  --test-- "byte-auto-1880"
      ba-b1: #"^(05)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-1881"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" // #"^(FE)" ))
  --test-- "byte-auto-1882"
  --assert #"^(05)"  = ( #"^(05)" // #"^(7E)" )
  --test-- "byte-auto-1883"
      ba-b1: #"^(05)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-1884"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" // #"^(7E)" ))
  --test-- "byte-auto-1885"
  --assert #"^(05)"  = ( #"^(05)" // #"^(6B)" )
  --test-- "byte-auto-1886"
      ba-b1: #"^(05)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-1887"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" // #"^(6B)" ))
  --test-- "byte-auto-1888"
  --assert #"^(05)"  = ( #"^(05)" // #"^(FB)" )
  --test-- "byte-auto-1889"
      ba-b1: #"^(05)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-1890"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" // #"^(FB)" ))
  --test-- "byte-auto-1891"
  --assert #"^(F0)"  = ( #"^(F0)" // #"^(FF)" )
  --test-- "byte-auto-1892"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-1893"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" // #"^(FF)" ))
  --test-- "byte-auto-1894"
  --assert #"^(00)"  = ( #"^(F0)" // #"^(01)" )
  --test-- "byte-auto-1895"
      ba-b1: #"^(F0)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1896"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" // #"^(01)" ))
  --test-- "byte-auto-1897"
  --assert #"^(00)"  = ( #"^(F0)" // #"^(02)" )
  --test-- "byte-auto-1898"
      ba-b1: #"^(F0)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1899"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" // #"^(02)" ))
  --test-- "byte-auto-1900"
  --assert #"^(00)"  = ( #"^(F0)" // #"^(03)" )
  --test-- "byte-auto-1901"
      ba-b1: #"^(F0)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1902"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" // #"^(03)" ))
  --test-- "byte-auto-1903"
  --assert #"^(00)"  = ( #"^(F0)" // #"^(05)" )
  --test-- "byte-auto-1904"
      ba-b1: #"^(F0)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1905"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" // #"^(05)" ))
  --test-- "byte-auto-1906"
  --assert #"^(00)"  = ( #"^(F0)" // #"^(F0)" )
  --test-- "byte-auto-1907"
      ba-b1: #"^(F0)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1908"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" // #"^(F0)" ))
  --test-- "byte-auto-1909"
  --assert #"^(F0)"  = ( #"^(F0)" // #"^(FD)" )
  --test-- "byte-auto-1910"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-1911"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" // #"^(FD)" ))
  --test-- "byte-auto-1912"
  --assert #"^(F0)"  = ( #"^(F0)" // #"^(FE)" )
  --test-- "byte-auto-1913"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-1914"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" // #"^(FE)" ))
  --test-- "byte-auto-1915"
  --assert #"^(72)"  = ( #"^(F0)" // #"^(7E)" )
  --test-- "byte-auto-1916"
      ba-b1: #"^(F0)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(72)"  = ba-b3 
  --test-- "byte-auto-1917"
  --assert #"^(D3)"  = ( #"a" + ( #"^(F0)" // #"^(7E)" ))
  --test-- "byte-auto-1918"
  --assert #"^(1A)"  = ( #"^(F0)" // #"^(6B)" )
  --test-- "byte-auto-1919"
      ba-b1: #"^(F0)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(1A)"  = ba-b3 
  --test-- "byte-auto-1920"
  --assert #"^(7B)"  = ( #"a" + ( #"^(F0)" // #"^(6B)" ))
  --test-- "byte-auto-1921"
  --assert #"^(F0)"  = ( #"^(F0)" // #"^(FB)" )
  --test-- "byte-auto-1922"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-1923"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" // #"^(FB)" ))
  --test-- "byte-auto-1924"
  --assert #"^(FD)"  = ( #"^(FD)" // #"^(FF)" )
  --test-- "byte-auto-1925"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-1926"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" // #"^(FF)" ))
  --test-- "byte-auto-1927"
  --assert #"^(00)"  = ( #"^(FD)" // #"^(01)" )
  --test-- "byte-auto-1928"
      ba-b1: #"^(FD)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1929"
  --assert #"^(61)"  = ( #"a" + ( #"^(FD)" // #"^(01)" ))
  --test-- "byte-auto-1930"
  --assert #"^(01)"  = ( #"^(FD)" // #"^(02)" )
  --test-- "byte-auto-1931"
      ba-b1: #"^(FD)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1932"
  --assert #"^(62)"  = ( #"a" + ( #"^(FD)" // #"^(02)" ))
  --test-- "byte-auto-1933"
  --assert #"^(01)"  = ( #"^(FD)" // #"^(03)" )
  --test-- "byte-auto-1934"
      ba-b1: #"^(FD)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1935"
  --assert #"^(62)"  = ( #"a" + ( #"^(FD)" // #"^(03)" ))
  --test-- "byte-auto-1936"
  --assert #"^(03)"  = ( #"^(FD)" // #"^(05)" )
  --test-- "byte-auto-1937"
      ba-b1: #"^(FD)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1938"
  --assert #"^(64)"  = ( #"a" + ( #"^(FD)" // #"^(05)" ))
  --test-- "byte-auto-1939"
  --assert #"^(0D)"  = ( #"^(FD)" // #"^(F0)" )
  --test-- "byte-auto-1940"
      ba-b1: #"^(FD)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(0D)"  = ba-b3 
  --test-- "byte-auto-1941"
  --assert #"^(6E)"  = ( #"a" + ( #"^(FD)" // #"^(F0)" ))
  --test-- "byte-auto-1942"
  --assert #"^(00)"  = ( #"^(FD)" // #"^(FD)" )
  --test-- "byte-auto-1943"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1944"
  --assert #"^(61)"  = ( #"a" + ( #"^(FD)" // #"^(FD)" ))
  --test-- "byte-auto-1945"
  --assert #"^(FD)"  = ( #"^(FD)" // #"^(FE)" )
  --test-- "byte-auto-1946"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-1947"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" // #"^(FE)" ))
  --test-- "byte-auto-1948"
  --assert #"^(01)"  = ( #"^(FD)" // #"^(7E)" )
  --test-- "byte-auto-1949"
      ba-b1: #"^(FD)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1950"
  --assert #"^(62)"  = ( #"a" + ( #"^(FD)" // #"^(7E)" ))
  --test-- "byte-auto-1951"
  --assert #"^(27)"  = ( #"^(FD)" // #"^(6B)" )
  --test-- "byte-auto-1952"
      ba-b1: #"^(FD)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(27)"  = ba-b3 
  --test-- "byte-auto-1953"
  --assert #"^(88)"  = ( #"a" + ( #"^(FD)" // #"^(6B)" ))
  --test-- "byte-auto-1954"
  --assert #"^(02)"  = ( #"^(FD)" // #"^(FB)" )
  --test-- "byte-auto-1955"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1956"
  --assert #"^(63)"  = ( #"a" + ( #"^(FD)" // #"^(FB)" ))
  --test-- "byte-auto-1957"
  --assert #"^(FE)"  = ( #"^(FE)" // #"^(FF)" )
  --test-- "byte-auto-1958"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-1959"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" // #"^(FF)" ))
  --test-- "byte-auto-1960"
  --assert #"^(00)"  = ( #"^(FE)" // #"^(01)" )
  --test-- "byte-auto-1961"
      ba-b1: #"^(FE)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1962"
  --assert #"^(61)"  = ( #"a" + ( #"^(FE)" // #"^(01)" ))
  --test-- "byte-auto-1963"
  --assert #"^(00)"  = ( #"^(FE)" // #"^(02)" )
  --test-- "byte-auto-1964"
      ba-b1: #"^(FE)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1965"
  --assert #"^(61)"  = ( #"a" + ( #"^(FE)" // #"^(02)" ))
  --test-- "byte-auto-1966"
  --assert #"^(02)"  = ( #"^(FE)" // #"^(03)" )
  --test-- "byte-auto-1967"
      ba-b1: #"^(FE)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1968"
  --assert #"^(63)"  = ( #"a" + ( #"^(FE)" // #"^(03)" ))
  --test-- "byte-auto-1969"
  --assert #"^(04)"  = ( #"^(FE)" // #"^(05)" )
  --test-- "byte-auto-1970"
      ba-b1: #"^(FE)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-1971"
  --assert #"^(65)"  = ( #"a" + ( #"^(FE)" // #"^(05)" ))
  --test-- "byte-auto-1972"
  --assert #"^(0E)"  = ( #"^(FE)" // #"^(F0)" )
  --test-- "byte-auto-1973"
      ba-b1: #"^(FE)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(0E)"  = ba-b3 
  --test-- "byte-auto-1974"
  --assert #"^(6F)"  = ( #"a" + ( #"^(FE)" // #"^(F0)" ))
  --test-- "byte-auto-1975"
  --assert #"^(01)"  = ( #"^(FE)" // #"^(FD)" )
  --test-- "byte-auto-1976"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-1977"
  --assert #"^(62)"  = ( #"a" + ( #"^(FE)" // #"^(FD)" ))
  --test-- "byte-auto-1978"
  --assert #"^(00)"  = ( #"^(FE)" // #"^(FE)" )
  --test-- "byte-auto-1979"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1980"
  --assert #"^(61)"  = ( #"a" + ( #"^(FE)" // #"^(FE)" ))
  --test-- "byte-auto-1981"
  --assert #"^(02)"  = ( #"^(FE)" // #"^(7E)" )
  --test-- "byte-auto-1982"
      ba-b1: #"^(FE)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-1983"
  --assert #"^(63)"  = ( #"a" + ( #"^(FE)" // #"^(7E)" ))
  --test-- "byte-auto-1984"
  --assert #"^(28)"  = ( #"^(FE)" // #"^(6B)" )
  --test-- "byte-auto-1985"
      ba-b1: #"^(FE)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(28)"  = ba-b3 
  --test-- "byte-auto-1986"
  --assert #"^(89)"  = ( #"a" + ( #"^(FE)" // #"^(6B)" ))
  --test-- "byte-auto-1987"
  --assert #"^(03)"  = ( #"^(FE)" // #"^(FB)" )
  --test-- "byte-auto-1988"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-1989"
  --assert #"^(64)"  = ( #"a" + ( #"^(FE)" // #"^(FB)" ))
  --test-- "byte-auto-1990"
  --assert #"^(7E)"  = ( #"^(7E)" // #"^(FF)" )
  --test-- "byte-auto-1991"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-1992"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" // #"^(FF)" ))
  --test-- "byte-auto-1993"
  --assert #"^(00)"  = ( #"^(7E)" // #"^(01)" )
  --test-- "byte-auto-1994"
      ba-b1: #"^(7E)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1995"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" // #"^(01)" ))
  --test-- "byte-auto-1996"
  --assert #"^(00)"  = ( #"^(7E)" // #"^(02)" )
  --test-- "byte-auto-1997"
      ba-b1: #"^(7E)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-1998"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" // #"^(02)" ))
  --test-- "byte-auto-1999"
  --assert #"^(00)"  = ( #"^(7E)" // #"^(03)" )
  --test-- "byte-auto-2000"
      ba-b1: #"^(7E)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2001"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" // #"^(03)" ))
  --test-- "byte-auto-2002"
  --assert #"^(01)"  = ( #"^(7E)" // #"^(05)" )
  --test-- "byte-auto-2003"
      ba-b1: #"^(7E)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2004"
  --assert #"^(62)"  = ( #"a" + ( #"^(7E)" // #"^(05)" ))
  --test-- "byte-auto-2005"
  --assert #"^(7E)"  = ( #"^(7E)" // #"^(F0)" )
  --test-- "byte-auto-2006"
      ba-b1: #"^(7E)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-2007"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" // #"^(F0)" ))
  --test-- "byte-auto-2008"
  --assert #"^(7E)"  = ( #"^(7E)" // #"^(FD)" )
  --test-- "byte-auto-2009"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-2010"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" // #"^(FD)" ))
  --test-- "byte-auto-2011"
  --assert #"^(7E)"  = ( #"^(7E)" // #"^(FE)" )
  --test-- "byte-auto-2012"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-2013"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" // #"^(FE)" ))
  --test-- "byte-auto-2014"
  --assert #"^(00)"  = ( #"^(7E)" // #"^(7E)" )
  --test-- "byte-auto-2015"
      ba-b1: #"^(7E)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2016"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" // #"^(7E)" ))
  --test-- "byte-auto-2017"
  --assert #"^(13)"  = ( #"^(7E)" // #"^(6B)" )
  --test-- "byte-auto-2018"
      ba-b1: #"^(7E)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(13)"  = ba-b3 
  --test-- "byte-auto-2019"
  --assert #"^(74)"  = ( #"a" + ( #"^(7E)" // #"^(6B)" ))
  --test-- "byte-auto-2020"
  --assert #"^(7E)"  = ( #"^(7E)" // #"^(FB)" )
  --test-- "byte-auto-2021"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-2022"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" // #"^(FB)" ))
  --test-- "byte-auto-2023"
  --assert #"^(6B)"  = ( #"^(6B)" // #"^(FF)" )
  --test-- "byte-auto-2024"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2025"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" // #"^(FF)" ))
  --test-- "byte-auto-2026"
  --assert #"^(00)"  = ( #"^(6B)" // #"^(01)" )
  --test-- "byte-auto-2027"
      ba-b1: #"^(6B)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2028"
  --assert #"^(61)"  = ( #"a" + ( #"^(6B)" // #"^(01)" ))
  --test-- "byte-auto-2029"
  --assert #"^(01)"  = ( #"^(6B)" // #"^(02)" )
  --test-- "byte-auto-2030"
      ba-b1: #"^(6B)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2031"
  --assert #"^(62)"  = ( #"a" + ( #"^(6B)" // #"^(02)" ))
  --test-- "byte-auto-2032"
  --assert #"^(02)"  = ( #"^(6B)" // #"^(03)" )
  --test-- "byte-auto-2033"
      ba-b1: #"^(6B)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-2034"
  --assert #"^(63)"  = ( #"a" + ( #"^(6B)" // #"^(03)" ))
  --test-- "byte-auto-2035"
  --assert #"^(02)"  = ( #"^(6B)" // #"^(05)" )
  --test-- "byte-auto-2036"
      ba-b1: #"^(6B)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-2037"
  --assert #"^(63)"  = ( #"a" + ( #"^(6B)" // #"^(05)" ))
  --test-- "byte-auto-2038"
  --assert #"^(6B)"  = ( #"^(6B)" // #"^(F0)" )
  --test-- "byte-auto-2039"
      ba-b1: #"^(6B)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2040"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" // #"^(F0)" ))
  --test-- "byte-auto-2041"
  --assert #"^(6B)"  = ( #"^(6B)" // #"^(FD)" )
  --test-- "byte-auto-2042"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2043"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" // #"^(FD)" ))
  --test-- "byte-auto-2044"
  --assert #"^(6B)"  = ( #"^(6B)" // #"^(FE)" )
  --test-- "byte-auto-2045"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2046"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" // #"^(FE)" ))
  --test-- "byte-auto-2047"
  --assert #"^(6B)"  = ( #"^(6B)" // #"^(7E)" )
  --test-- "byte-auto-2048"
      ba-b1: #"^(6B)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2049"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" // #"^(7E)" ))
  --test-- "byte-auto-2050"
  --assert #"^(00)"  = ( #"^(6B)" // #"^(6B)" )
  --test-- "byte-auto-2051"
      ba-b1: #"^(6B)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2052"
  --assert #"^(61)"  = ( #"a" + ( #"^(6B)" // #"^(6B)" ))
  --test-- "byte-auto-2053"
  --assert #"^(6B)"  = ( #"^(6B)" // #"^(FB)" )
  --test-- "byte-auto-2054"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2055"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" // #"^(FB)" ))
  --test-- "byte-auto-2056"
  --assert #"^(FB)"  = ( #"^(FB)" // #"^(FF)" )
  --test-- "byte-auto-2057"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2058"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" // #"^(FF)" ))
  --test-- "byte-auto-2059"
  --assert #"^(00)"  = ( #"^(FB)" // #"^(01)" )
  --test-- "byte-auto-2060"
      ba-b1: #"^(FB)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2061"
  --assert #"^(61)"  = ( #"a" + ( #"^(FB)" // #"^(01)" ))
  --test-- "byte-auto-2062"
  --assert #"^(01)"  = ( #"^(FB)" // #"^(02)" )
  --test-- "byte-auto-2063"
      ba-b1: #"^(FB)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2064"
  --assert #"^(62)"  = ( #"a" + ( #"^(FB)" // #"^(02)" ))
  --test-- "byte-auto-2065"
  --assert #"^(02)"  = ( #"^(FB)" // #"^(03)" )
  --test-- "byte-auto-2066"
      ba-b1: #"^(FB)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-2067"
  --assert #"^(63)"  = ( #"a" + ( #"^(FB)" // #"^(03)" ))
  --test-- "byte-auto-2068"
  --assert #"^(01)"  = ( #"^(FB)" // #"^(05)" )
  --test-- "byte-auto-2069"
      ba-b1: #"^(FB)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2070"
  --assert #"^(62)"  = ( #"a" + ( #"^(FB)" // #"^(05)" ))
  --test-- "byte-auto-2071"
  --assert #"^(0B)"  = ( #"^(FB)" // #"^(F0)" )
  --test-- "byte-auto-2072"
      ba-b1: #"^(FB)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(0B)"  = ba-b3 
  --test-- "byte-auto-2073"
  --assert #"^(6C)"  = ( #"a" + ( #"^(FB)" // #"^(F0)" ))
  --test-- "byte-auto-2074"
  --assert #"^(FB)"  = ( #"^(FB)" // #"^(FD)" )
  --test-- "byte-auto-2075"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2076"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" // #"^(FD)" ))
  --test-- "byte-auto-2077"
  --assert #"^(FB)"  = ( #"^(FB)" // #"^(FE)" )
  --test-- "byte-auto-2078"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2079"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" // #"^(FE)" ))
  --test-- "byte-auto-2080"
  --assert #"^(7D)"  = ( #"^(FB)" // #"^(7E)" )
  --test-- "byte-auto-2081"
      ba-b1: #"^(FB)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(7D)"  = ba-b3 
  --test-- "byte-auto-2082"
  --assert #"^(DE)"  = ( #"a" + ( #"^(FB)" // #"^(7E)" ))
  --test-- "byte-auto-2083"
  --assert #"^(25)"  = ( #"^(FB)" // #"^(6B)" )
  --test-- "byte-auto-2084"
      ba-b1: #"^(FB)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(25)"  = ba-b3 
  --test-- "byte-auto-2085"
  --assert #"^(86)"  = ( #"a" + ( #"^(FB)" // #"^(6B)" ))
  --test-- "byte-auto-2086"
  --assert #"^(00)"  = ( #"^(FB)" // #"^(FB)" )
  --test-- "byte-auto-2087"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 // ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2088"
  --assert #"^(61)"  = ( #"a" + ( #"^(FB)" // #"^(FB)" ))
  --test-- "byte-auto-2089"
  --assert #"^(00)"  = ( #"^(00)" or #"^(00)" )
  --test-- "byte-auto-2090"
      ba-b1: #"^(00)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2091"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" or #"^(00)" ))
  --test-- "byte-auto-2092"
  --assert #"^(FF)"  = ( #"^(00)" or #"^(FF)" )
  --test-- "byte-auto-2093"
      ba-b1: #"^(00)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2094"
  --assert #"^(60)"  = ( #"a" + ( #"^(00)" or #"^(FF)" ))
  --test-- "byte-auto-2095"
  --assert #"^(01)"  = ( #"^(00)" or #"^(01)" )
  --test-- "byte-auto-2096"
      ba-b1: #"^(00)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2097"
  --assert #"^(62)"  = ( #"a" + ( #"^(00)" or #"^(01)" ))
  --test-- "byte-auto-2098"
  --assert #"^(02)"  = ( #"^(00)" or #"^(02)" )
  --test-- "byte-auto-2099"
      ba-b1: #"^(00)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-2100"
  --assert #"^(63)"  = ( #"a" + ( #"^(00)" or #"^(02)" ))
  --test-- "byte-auto-2101"
  --assert #"^(03)"  = ( #"^(00)" or #"^(03)" )
  --test-- "byte-auto-2102"
      ba-b1: #"^(00)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2103"
  --assert #"^(64)"  = ( #"a" + ( #"^(00)" or #"^(03)" ))
  --test-- "byte-auto-2104"
  --assert #"^(05)"  = ( #"^(00)" or #"^(05)" )
  --test-- "byte-auto-2105"
      ba-b1: #"^(00)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-2106"
  --assert #"^(66)"  = ( #"a" + ( #"^(00)" or #"^(05)" ))
  --test-- "byte-auto-2107"
  --assert #"^(F0)"  = ( #"^(00)" or #"^(F0)" )
  --test-- "byte-auto-2108"
      ba-b1: #"^(00)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-2109"
  --assert #"^(51)"  = ( #"a" + ( #"^(00)" or #"^(F0)" ))
  --test-- "byte-auto-2110"
  --assert #"^(FD)"  = ( #"^(00)" or #"^(FD)" )
  --test-- "byte-auto-2111"
      ba-b1: #"^(00)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2112"
  --assert #"^(5E)"  = ( #"a" + ( #"^(00)" or #"^(FD)" ))
  --test-- "byte-auto-2113"
  --assert #"^(FE)"  = ( #"^(00)" or #"^(FE)" )
  --test-- "byte-auto-2114"
      ba-b1: #"^(00)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2115"
  --assert #"^(5F)"  = ( #"a" + ( #"^(00)" or #"^(FE)" ))
  --test-- "byte-auto-2116"
  --assert #"^(7E)"  = ( #"^(00)" or #"^(7E)" )
  --test-- "byte-auto-2117"
      ba-b1: #"^(00)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-2118"
  --assert #"^(DF)"  = ( #"a" + ( #"^(00)" or #"^(7E)" ))
  --test-- "byte-auto-2119"
  --assert #"^(6B)"  = ( #"^(00)" or #"^(6B)" )
  --test-- "byte-auto-2120"
      ba-b1: #"^(00)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2121"
  --assert #"^(CC)"  = ( #"a" + ( #"^(00)" or #"^(6B)" ))
  --test-- "byte-auto-2122"
  --assert #"^(FB)"  = ( #"^(00)" or #"^(FB)" )
  --test-- "byte-auto-2123"
      ba-b1: #"^(00)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2124"
  --assert #"^(5C)"  = ( #"a" + ( #"^(00)" or #"^(FB)" ))
  --test-- "byte-auto-2125"
  --assert #"^(FF)"  = ( #"^(FF)" or #"^(00)" )
  --test-- "byte-auto-2126"
      ba-b1: #"^(FF)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2127"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" or #"^(00)" ))
  --test-- "byte-auto-2128"
  --assert #"^(FF)"  = ( #"^(FF)" or #"^(FF)" )
  --test-- "byte-auto-2129"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2130"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" or #"^(FF)" ))
  --test-- "byte-auto-2131"
  --assert #"^(FF)"  = ( #"^(FF)" or #"^(01)" )
  --test-- "byte-auto-2132"
      ba-b1: #"^(FF)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2133"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" or #"^(01)" ))
  --test-- "byte-auto-2134"
  --assert #"^(FF)"  = ( #"^(FF)" or #"^(02)" )
  --test-- "byte-auto-2135"
      ba-b1: #"^(FF)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2136"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" or #"^(02)" ))
  --test-- "byte-auto-2137"
  --assert #"^(FF)"  = ( #"^(FF)" or #"^(03)" )
  --test-- "byte-auto-2138"
      ba-b1: #"^(FF)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2139"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" or #"^(03)" ))
  --test-- "byte-auto-2140"
  --assert #"^(FF)"  = ( #"^(FF)" or #"^(05)" )
  --test-- "byte-auto-2141"
      ba-b1: #"^(FF)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2142"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" or #"^(05)" ))
  --test-- "byte-auto-2143"
  --assert #"^(FF)"  = ( #"^(FF)" or #"^(F0)" )
  --test-- "byte-auto-2144"
      ba-b1: #"^(FF)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2145"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" or #"^(F0)" ))
  --test-- "byte-auto-2146"
  --assert #"^(FF)"  = ( #"^(FF)" or #"^(FD)" )
  --test-- "byte-auto-2147"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2148"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" or #"^(FD)" ))
  --test-- "byte-auto-2149"
  --assert #"^(FF)"  = ( #"^(FF)" or #"^(FE)" )
  --test-- "byte-auto-2150"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2151"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" or #"^(FE)" ))
  --test-- "byte-auto-2152"
  --assert #"^(FF)"  = ( #"^(FF)" or #"^(7E)" )
  --test-- "byte-auto-2153"
      ba-b1: #"^(FF)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2154"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" or #"^(7E)" ))
  --test-- "byte-auto-2155"
  --assert #"^(FF)"  = ( #"^(FF)" or #"^(6B)" )
  --test-- "byte-auto-2156"
      ba-b1: #"^(FF)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2157"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" or #"^(6B)" ))
  --test-- "byte-auto-2158"
  --assert #"^(FF)"  = ( #"^(FF)" or #"^(FB)" )
  --test-- "byte-auto-2159"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2160"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" or #"^(FB)" ))
  --test-- "byte-auto-2161"
  --assert #"^(01)"  = ( #"^(01)" or #"^(00)" )
  --test-- "byte-auto-2162"
      ba-b1: #"^(01)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2163"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" or #"^(00)" ))
  --test-- "byte-auto-2164"
  --assert #"^(FF)"  = ( #"^(01)" or #"^(FF)" )
  --test-- "byte-auto-2165"
      ba-b1: #"^(01)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2166"
  --assert #"^(60)"  = ( #"a" + ( #"^(01)" or #"^(FF)" ))
  --test-- "byte-auto-2167"
  --assert #"^(01)"  = ( #"^(01)" or #"^(01)" )
  --test-- "byte-auto-2168"
      ba-b1: #"^(01)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2169"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" or #"^(01)" ))
  --test-- "byte-auto-2170"
  --assert #"^(03)"  = ( #"^(01)" or #"^(02)" )
  --test-- "byte-auto-2171"
      ba-b1: #"^(01)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2172"
  --assert #"^(64)"  = ( #"a" + ( #"^(01)" or #"^(02)" ))
  --test-- "byte-auto-2173"
  --assert #"^(03)"  = ( #"^(01)" or #"^(03)" )
  --test-- "byte-auto-2174"
      ba-b1: #"^(01)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2175"
  --assert #"^(64)"  = ( #"a" + ( #"^(01)" or #"^(03)" ))
  --test-- "byte-auto-2176"
  --assert #"^(05)"  = ( #"^(01)" or #"^(05)" )
  --test-- "byte-auto-2177"
      ba-b1: #"^(01)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-2178"
  --assert #"^(66)"  = ( #"a" + ( #"^(01)" or #"^(05)" ))
  --test-- "byte-auto-2179"
  --assert #"^(F1)"  = ( #"^(01)" or #"^(F0)" )
  --test-- "byte-auto-2180"
      ba-b1: #"^(01)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(F1)"  = ba-b3 
  --test-- "byte-auto-2181"
  --assert #"^(52)"  = ( #"a" + ( #"^(01)" or #"^(F0)" ))
  --test-- "byte-auto-2182"
  --assert #"^(FD)"  = ( #"^(01)" or #"^(FD)" )
  --test-- "byte-auto-2183"
      ba-b1: #"^(01)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2184"
  --assert #"^(5E)"  = ( #"a" + ( #"^(01)" or #"^(FD)" ))
  --test-- "byte-auto-2185"
  --assert #"^(FF)"  = ( #"^(01)" or #"^(FE)" )
  --test-- "byte-auto-2186"
      ba-b1: #"^(01)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2187"
  --assert #"^(60)"  = ( #"a" + ( #"^(01)" or #"^(FE)" ))
  --test-- "byte-auto-2188"
  --assert #"^(7F)"  = ( #"^(01)" or #"^(7E)" )
  --test-- "byte-auto-2189"
      ba-b1: #"^(01)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-2190"
  --assert #"^(E0)"  = ( #"a" + ( #"^(01)" or #"^(7E)" ))
  --test-- "byte-auto-2191"
  --assert #"^(6B)"  = ( #"^(01)" or #"^(6B)" )
  --test-- "byte-auto-2192"
      ba-b1: #"^(01)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2193"
  --assert #"^(CC)"  = ( #"a" + ( #"^(01)" or #"^(6B)" ))
  --test-- "byte-auto-2194"
  --assert #"^(FB)"  = ( #"^(01)" or #"^(FB)" )
  --test-- "byte-auto-2195"
      ba-b1: #"^(01)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2196"
  --assert #"^(5C)"  = ( #"a" + ( #"^(01)" or #"^(FB)" ))
  --test-- "byte-auto-2197"
  --assert #"^(02)"  = ( #"^(02)" or #"^(00)" )
  --test-- "byte-auto-2198"
      ba-b1: #"^(02)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-2199"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" or #"^(00)" ))
  --test-- "byte-auto-2200"
  --assert #"^(FF)"  = ( #"^(02)" or #"^(FF)" )
  --test-- "byte-auto-2201"
      ba-b1: #"^(02)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2202"
  --assert #"^(60)"  = ( #"a" + ( #"^(02)" or #"^(FF)" ))
  --test-- "byte-auto-2203"
  --assert #"^(03)"  = ( #"^(02)" or #"^(01)" )
  --test-- "byte-auto-2204"
      ba-b1: #"^(02)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2205"
  --assert #"^(64)"  = ( #"a" + ( #"^(02)" or #"^(01)" ))
  --test-- "byte-auto-2206"
  --assert #"^(02)"  = ( #"^(02)" or #"^(02)" )
  --test-- "byte-auto-2207"
      ba-b1: #"^(02)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-2208"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" or #"^(02)" ))
  --test-- "byte-auto-2209"
  --assert #"^(03)"  = ( #"^(02)" or #"^(03)" )
  --test-- "byte-auto-2210"
      ba-b1: #"^(02)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2211"
  --assert #"^(64)"  = ( #"a" + ( #"^(02)" or #"^(03)" ))
  --test-- "byte-auto-2212"
  --assert #"^(07)"  = ( #"^(02)" or #"^(05)" )
  --test-- "byte-auto-2213"
      ba-b1: #"^(02)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(07)"  = ba-b3 
  --test-- "byte-auto-2214"
  --assert #"^(68)"  = ( #"a" + ( #"^(02)" or #"^(05)" ))
  --test-- "byte-auto-2215"
  --assert #"^(F2)"  = ( #"^(02)" or #"^(F0)" )
  --test-- "byte-auto-2216"
      ba-b1: #"^(02)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(F2)"  = ba-b3 
  --test-- "byte-auto-2217"
  --assert #"^(53)"  = ( #"a" + ( #"^(02)" or #"^(F0)" ))
  --test-- "byte-auto-2218"
  --assert #"^(FF)"  = ( #"^(02)" or #"^(FD)" )
  --test-- "byte-auto-2219"
      ba-b1: #"^(02)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2220"
  --assert #"^(60)"  = ( #"a" + ( #"^(02)" or #"^(FD)" ))
  --test-- "byte-auto-2221"
  --assert #"^(FE)"  = ( #"^(02)" or #"^(FE)" )
  --test-- "byte-auto-2222"
      ba-b1: #"^(02)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2223"
  --assert #"^(5F)"  = ( #"a" + ( #"^(02)" or #"^(FE)" ))
  --test-- "byte-auto-2224"
  --assert #"^(7E)"  = ( #"^(02)" or #"^(7E)" )
  --test-- "byte-auto-2225"
      ba-b1: #"^(02)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-2226"
  --assert #"^(DF)"  = ( #"a" + ( #"^(02)" or #"^(7E)" ))
  --test-- "byte-auto-2227"
  --assert #"^(6B)"  = ( #"^(02)" or #"^(6B)" )
  --test-- "byte-auto-2228"
      ba-b1: #"^(02)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2229"
  --assert #"^(CC)"  = ( #"a" + ( #"^(02)" or #"^(6B)" ))
  --test-- "byte-auto-2230"
  --assert #"^(FB)"  = ( #"^(02)" or #"^(FB)" )
  --test-- "byte-auto-2231"
      ba-b1: #"^(02)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2232"
  --assert #"^(5C)"  = ( #"a" + ( #"^(02)" or #"^(FB)" ))
  --test-- "byte-auto-2233"
  --assert #"^(03)"  = ( #"^(03)" or #"^(00)" )
  --test-- "byte-auto-2234"
      ba-b1: #"^(03)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2235"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" or #"^(00)" ))
  --test-- "byte-auto-2236"
  --assert #"^(FF)"  = ( #"^(03)" or #"^(FF)" )
  --test-- "byte-auto-2237"
      ba-b1: #"^(03)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2238"
  --assert #"^(60)"  = ( #"a" + ( #"^(03)" or #"^(FF)" ))
  --test-- "byte-auto-2239"
  --assert #"^(03)"  = ( #"^(03)" or #"^(01)" )
  --test-- "byte-auto-2240"
      ba-b1: #"^(03)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2241"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" or #"^(01)" ))
  --test-- "byte-auto-2242"
  --assert #"^(03)"  = ( #"^(03)" or #"^(02)" )
  --test-- "byte-auto-2243"
      ba-b1: #"^(03)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2244"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" or #"^(02)" ))
  --test-- "byte-auto-2245"
  --assert #"^(03)"  = ( #"^(03)" or #"^(03)" )
  --test-- "byte-auto-2246"
      ba-b1: #"^(03)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2247"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" or #"^(03)" ))
  --test-- "byte-auto-2248"
  --assert #"^(07)"  = ( #"^(03)" or #"^(05)" )
  --test-- "byte-auto-2249"
      ba-b1: #"^(03)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(07)"  = ba-b3 
  --test-- "byte-auto-2250"
  --assert #"^(68)"  = ( #"a" + ( #"^(03)" or #"^(05)" ))
  --test-- "byte-auto-2251"
  --assert #"^(F3)"  = ( #"^(03)" or #"^(F0)" )
  --test-- "byte-auto-2252"
      ba-b1: #"^(03)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(F3)"  = ba-b3 
  --test-- "byte-auto-2253"
  --assert #"^(54)"  = ( #"a" + ( #"^(03)" or #"^(F0)" ))
  --test-- "byte-auto-2254"
  --assert #"^(FF)"  = ( #"^(03)" or #"^(FD)" )
  --test-- "byte-auto-2255"
      ba-b1: #"^(03)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2256"
  --assert #"^(60)"  = ( #"a" + ( #"^(03)" or #"^(FD)" ))
  --test-- "byte-auto-2257"
  --assert #"^(FF)"  = ( #"^(03)" or #"^(FE)" )
  --test-- "byte-auto-2258"
      ba-b1: #"^(03)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2259"
  --assert #"^(60)"  = ( #"a" + ( #"^(03)" or #"^(FE)" ))
  --test-- "byte-auto-2260"
  --assert #"^(7F)"  = ( #"^(03)" or #"^(7E)" )
  --test-- "byte-auto-2261"
      ba-b1: #"^(03)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-2262"
  --assert #"^(E0)"  = ( #"a" + ( #"^(03)" or #"^(7E)" ))
  --test-- "byte-auto-2263"
  --assert #"^(6B)"  = ( #"^(03)" or #"^(6B)" )
  --test-- "byte-auto-2264"
      ba-b1: #"^(03)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2265"
  --assert #"^(CC)"  = ( #"a" + ( #"^(03)" or #"^(6B)" ))
  --test-- "byte-auto-2266"
  --assert #"^(FB)"  = ( #"^(03)" or #"^(FB)" )
  --test-- "byte-auto-2267"
      ba-b1: #"^(03)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2268"
  --assert #"^(5C)"  = ( #"a" + ( #"^(03)" or #"^(FB)" ))
  --test-- "byte-auto-2269"
  --assert #"^(05)"  = ( #"^(05)" or #"^(00)" )
  --test-- "byte-auto-2270"
      ba-b1: #"^(05)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-2271"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" or #"^(00)" ))
  --test-- "byte-auto-2272"
  --assert #"^(FF)"  = ( #"^(05)" or #"^(FF)" )
  --test-- "byte-auto-2273"
      ba-b1: #"^(05)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2274"
  --assert #"^(60)"  = ( #"a" + ( #"^(05)" or #"^(FF)" ))
  --test-- "byte-auto-2275"
  --assert #"^(05)"  = ( #"^(05)" or #"^(01)" )
  --test-- "byte-auto-2276"
      ba-b1: #"^(05)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-2277"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" or #"^(01)" ))
  --test-- "byte-auto-2278"
  --assert #"^(07)"  = ( #"^(05)" or #"^(02)" )
  --test-- "byte-auto-2279"
      ba-b1: #"^(05)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(07)"  = ba-b3 
  --test-- "byte-auto-2280"
  --assert #"^(68)"  = ( #"a" + ( #"^(05)" or #"^(02)" ))
  --test-- "byte-auto-2281"
  --assert #"^(07)"  = ( #"^(05)" or #"^(03)" )
  --test-- "byte-auto-2282"
      ba-b1: #"^(05)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(07)"  = ba-b3 
  --test-- "byte-auto-2283"
  --assert #"^(68)"  = ( #"a" + ( #"^(05)" or #"^(03)" ))
  --test-- "byte-auto-2284"
  --assert #"^(05)"  = ( #"^(05)" or #"^(05)" )
  --test-- "byte-auto-2285"
      ba-b1: #"^(05)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-2286"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" or #"^(05)" ))
  --test-- "byte-auto-2287"
  --assert #"^(F5)"  = ( #"^(05)" or #"^(F0)" )
  --test-- "byte-auto-2288"
      ba-b1: #"^(05)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(F5)"  = ba-b3 
  --test-- "byte-auto-2289"
  --assert #"^(56)"  = ( #"a" + ( #"^(05)" or #"^(F0)" ))
  --test-- "byte-auto-2290"
  --assert #"^(FD)"  = ( #"^(05)" or #"^(FD)" )
  --test-- "byte-auto-2291"
      ba-b1: #"^(05)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2292"
  --assert #"^(5E)"  = ( #"a" + ( #"^(05)" or #"^(FD)" ))
  --test-- "byte-auto-2293"
  --assert #"^(FF)"  = ( #"^(05)" or #"^(FE)" )
  --test-- "byte-auto-2294"
      ba-b1: #"^(05)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2295"
  --assert #"^(60)"  = ( #"a" + ( #"^(05)" or #"^(FE)" ))
  --test-- "byte-auto-2296"
  --assert #"^(7F)"  = ( #"^(05)" or #"^(7E)" )
  --test-- "byte-auto-2297"
      ba-b1: #"^(05)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-2298"
  --assert #"^(E0)"  = ( #"a" + ( #"^(05)" or #"^(7E)" ))
  --test-- "byte-auto-2299"
  --assert #"^(6F)"  = ( #"^(05)" or #"^(6B)" )
  --test-- "byte-auto-2300"
      ba-b1: #"^(05)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(6F)"  = ba-b3 
  --test-- "byte-auto-2301"
  --assert #"^(D0)"  = ( #"a" + ( #"^(05)" or #"^(6B)" ))
  --test-- "byte-auto-2302"
  --assert #"^(FF)"  = ( #"^(05)" or #"^(FB)" )
  --test-- "byte-auto-2303"
      ba-b1: #"^(05)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2304"
  --assert #"^(60)"  = ( #"a" + ( #"^(05)" or #"^(FB)" ))
  --test-- "byte-auto-2305"
  --assert #"^(F0)"  = ( #"^(F0)" or #"^(00)" )
  --test-- "byte-auto-2306"
      ba-b1: #"^(F0)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-2307"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" or #"^(00)" ))
  --test-- "byte-auto-2308"
  --assert #"^(FF)"  = ( #"^(F0)" or #"^(FF)" )
  --test-- "byte-auto-2309"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2310"
  --assert #"^(60)"  = ( #"a" + ( #"^(F0)" or #"^(FF)" ))
  --test-- "byte-auto-2311"
  --assert #"^(F1)"  = ( #"^(F0)" or #"^(01)" )
  --test-- "byte-auto-2312"
      ba-b1: #"^(F0)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(F1)"  = ba-b3 
  --test-- "byte-auto-2313"
  --assert #"^(52)"  = ( #"a" + ( #"^(F0)" or #"^(01)" ))
  --test-- "byte-auto-2314"
  --assert #"^(F2)"  = ( #"^(F0)" or #"^(02)" )
  --test-- "byte-auto-2315"
      ba-b1: #"^(F0)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(F2)"  = ba-b3 
  --test-- "byte-auto-2316"
  --assert #"^(53)"  = ( #"a" + ( #"^(F0)" or #"^(02)" ))
  --test-- "byte-auto-2317"
  --assert #"^(F3)"  = ( #"^(F0)" or #"^(03)" )
  --test-- "byte-auto-2318"
      ba-b1: #"^(F0)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(F3)"  = ba-b3 
  --test-- "byte-auto-2319"
  --assert #"^(54)"  = ( #"a" + ( #"^(F0)" or #"^(03)" ))
  --test-- "byte-auto-2320"
  --assert #"^(F5)"  = ( #"^(F0)" or #"^(05)" )
  --test-- "byte-auto-2321"
      ba-b1: #"^(F0)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(F5)"  = ba-b3 
  --test-- "byte-auto-2322"
  --assert #"^(56)"  = ( #"a" + ( #"^(F0)" or #"^(05)" ))
  --test-- "byte-auto-2323"
  --assert #"^(F0)"  = ( #"^(F0)" or #"^(F0)" )
  --test-- "byte-auto-2324"
      ba-b1: #"^(F0)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-2325"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" or #"^(F0)" ))
  --test-- "byte-auto-2326"
  --assert #"^(FD)"  = ( #"^(F0)" or #"^(FD)" )
  --test-- "byte-auto-2327"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2328"
  --assert #"^(5E)"  = ( #"a" + ( #"^(F0)" or #"^(FD)" ))
  --test-- "byte-auto-2329"
  --assert #"^(FE)"  = ( #"^(F0)" or #"^(FE)" )
  --test-- "byte-auto-2330"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2331"
  --assert #"^(5F)"  = ( #"a" + ( #"^(F0)" or #"^(FE)" ))
  --test-- "byte-auto-2332"
  --assert #"^(FE)"  = ( #"^(F0)" or #"^(7E)" )
  --test-- "byte-auto-2333"
      ba-b1: #"^(F0)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2334"
  --assert #"^(5F)"  = ( #"a" + ( #"^(F0)" or #"^(7E)" ))
  --test-- "byte-auto-2335"
  --assert #"^(FB)"  = ( #"^(F0)" or #"^(6B)" )
  --test-- "byte-auto-2336"
      ba-b1: #"^(F0)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2337"
  --assert #"^(5C)"  = ( #"a" + ( #"^(F0)" or #"^(6B)" ))
  --test-- "byte-auto-2338"
  --assert #"^(FB)"  = ( #"^(F0)" or #"^(FB)" )
  --test-- "byte-auto-2339"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2340"
  --assert #"^(5C)"  = ( #"a" + ( #"^(F0)" or #"^(FB)" ))
  --test-- "byte-auto-2341"
  --assert #"^(FD)"  = ( #"^(FD)" or #"^(00)" )
  --test-- "byte-auto-2342"
      ba-b1: #"^(FD)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2343"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" or #"^(00)" ))
  --test-- "byte-auto-2344"
  --assert #"^(FF)"  = ( #"^(FD)" or #"^(FF)" )
  --test-- "byte-auto-2345"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2346"
  --assert #"^(60)"  = ( #"a" + ( #"^(FD)" or #"^(FF)" ))
  --test-- "byte-auto-2347"
  --assert #"^(FD)"  = ( #"^(FD)" or #"^(01)" )
  --test-- "byte-auto-2348"
      ba-b1: #"^(FD)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2349"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" or #"^(01)" ))
  --test-- "byte-auto-2350"
  --assert #"^(FF)"  = ( #"^(FD)" or #"^(02)" )
  --test-- "byte-auto-2351"
      ba-b1: #"^(FD)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2352"
  --assert #"^(60)"  = ( #"a" + ( #"^(FD)" or #"^(02)" ))
  --test-- "byte-auto-2353"
  --assert #"^(FF)"  = ( #"^(FD)" or #"^(03)" )
  --test-- "byte-auto-2354"
      ba-b1: #"^(FD)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2355"
  --assert #"^(60)"  = ( #"a" + ( #"^(FD)" or #"^(03)" ))
  --test-- "byte-auto-2356"
  --assert #"^(FD)"  = ( #"^(FD)" or #"^(05)" )
  --test-- "byte-auto-2357"
      ba-b1: #"^(FD)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2358"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" or #"^(05)" ))
  --test-- "byte-auto-2359"
  --assert #"^(FD)"  = ( #"^(FD)" or #"^(F0)" )
  --test-- "byte-auto-2360"
      ba-b1: #"^(FD)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2361"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" or #"^(F0)" ))
  --test-- "byte-auto-2362"
  --assert #"^(FD)"  = ( #"^(FD)" or #"^(FD)" )
  --test-- "byte-auto-2363"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2364"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" or #"^(FD)" ))
  --test-- "byte-auto-2365"
  --assert #"^(FF)"  = ( #"^(FD)" or #"^(FE)" )
  --test-- "byte-auto-2366"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2367"
  --assert #"^(60)"  = ( #"a" + ( #"^(FD)" or #"^(FE)" ))
  --test-- "byte-auto-2368"
  --assert #"^(FF)"  = ( #"^(FD)" or #"^(7E)" )
  --test-- "byte-auto-2369"
      ba-b1: #"^(FD)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2370"
  --assert #"^(60)"  = ( #"a" + ( #"^(FD)" or #"^(7E)" ))
  --test-- "byte-auto-2371"
  --assert #"^(FF)"  = ( #"^(FD)" or #"^(6B)" )
  --test-- "byte-auto-2372"
      ba-b1: #"^(FD)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2373"
  --assert #"^(60)"  = ( #"a" + ( #"^(FD)" or #"^(6B)" ))
  --test-- "byte-auto-2374"
  --assert #"^(FF)"  = ( #"^(FD)" or #"^(FB)" )
  --test-- "byte-auto-2375"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2376"
  --assert #"^(60)"  = ( #"a" + ( #"^(FD)" or #"^(FB)" ))
  --test-- "byte-auto-2377"
  --assert #"^(FE)"  = ( #"^(FE)" or #"^(00)" )
  --test-- "byte-auto-2378"
      ba-b1: #"^(FE)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2379"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" or #"^(00)" ))
  --test-- "byte-auto-2380"
  --assert #"^(FF)"  = ( #"^(FE)" or #"^(FF)" )
  --test-- "byte-auto-2381"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2382"
  --assert #"^(60)"  = ( #"a" + ( #"^(FE)" or #"^(FF)" ))
  --test-- "byte-auto-2383"
  --assert #"^(FF)"  = ( #"^(FE)" or #"^(01)" )
  --test-- "byte-auto-2384"
      ba-b1: #"^(FE)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2385"
  --assert #"^(60)"  = ( #"a" + ( #"^(FE)" or #"^(01)" ))
  --test-- "byte-auto-2386"
  --assert #"^(FE)"  = ( #"^(FE)" or #"^(02)" )
  --test-- "byte-auto-2387"
      ba-b1: #"^(FE)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2388"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" or #"^(02)" ))
  --test-- "byte-auto-2389"
  --assert #"^(FF)"  = ( #"^(FE)" or #"^(03)" )
  --test-- "byte-auto-2390"
      ba-b1: #"^(FE)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2391"
  --assert #"^(60)"  = ( #"a" + ( #"^(FE)" or #"^(03)" ))
  --test-- "byte-auto-2392"
  --assert #"^(FF)"  = ( #"^(FE)" or #"^(05)" )
  --test-- "byte-auto-2393"
      ba-b1: #"^(FE)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2394"
  --assert #"^(60)"  = ( #"a" + ( #"^(FE)" or #"^(05)" ))
  --test-- "byte-auto-2395"
  --assert #"^(FE)"  = ( #"^(FE)" or #"^(F0)" )
  --test-- "byte-auto-2396"
      ba-b1: #"^(FE)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2397"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" or #"^(F0)" ))
  --test-- "byte-auto-2398"
  --assert #"^(FF)"  = ( #"^(FE)" or #"^(FD)" )
  --test-- "byte-auto-2399"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2400"
  --assert #"^(60)"  = ( #"a" + ( #"^(FE)" or #"^(FD)" ))
  --test-- "byte-auto-2401"
  --assert #"^(FE)"  = ( #"^(FE)" or #"^(FE)" )
  --test-- "byte-auto-2402"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2403"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" or #"^(FE)" ))
  --test-- "byte-auto-2404"
  --assert #"^(FE)"  = ( #"^(FE)" or #"^(7E)" )
  --test-- "byte-auto-2405"
      ba-b1: #"^(FE)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2406"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" or #"^(7E)" ))
  --test-- "byte-auto-2407"
  --assert #"^(FF)"  = ( #"^(FE)" or #"^(6B)" )
  --test-- "byte-auto-2408"
      ba-b1: #"^(FE)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2409"
  --assert #"^(60)"  = ( #"a" + ( #"^(FE)" or #"^(6B)" ))
  --test-- "byte-auto-2410"
  --assert #"^(FF)"  = ( #"^(FE)" or #"^(FB)" )
  --test-- "byte-auto-2411"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2412"
  --assert #"^(60)"  = ( #"a" + ( #"^(FE)" or #"^(FB)" ))
  --test-- "byte-auto-2413"
  --assert #"^(7E)"  = ( #"^(7E)" or #"^(00)" )
  --test-- "byte-auto-2414"
      ba-b1: #"^(7E)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-2415"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" or #"^(00)" ))
  --test-- "byte-auto-2416"
  --assert #"^(FF)"  = ( #"^(7E)" or #"^(FF)" )
  --test-- "byte-auto-2417"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2418"
  --assert #"^(60)"  = ( #"a" + ( #"^(7E)" or #"^(FF)" ))
  --test-- "byte-auto-2419"
  --assert #"^(7F)"  = ( #"^(7E)" or #"^(01)" )
  --test-- "byte-auto-2420"
      ba-b1: #"^(7E)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-2421"
  --assert #"^(E0)"  = ( #"a" + ( #"^(7E)" or #"^(01)" ))
  --test-- "byte-auto-2422"
  --assert #"^(7E)"  = ( #"^(7E)" or #"^(02)" )
  --test-- "byte-auto-2423"
      ba-b1: #"^(7E)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-2424"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" or #"^(02)" ))
  --test-- "byte-auto-2425"
  --assert #"^(7F)"  = ( #"^(7E)" or #"^(03)" )
  --test-- "byte-auto-2426"
      ba-b1: #"^(7E)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-2427"
  --assert #"^(E0)"  = ( #"a" + ( #"^(7E)" or #"^(03)" ))
  --test-- "byte-auto-2428"
  --assert #"^(7F)"  = ( #"^(7E)" or #"^(05)" )
  --test-- "byte-auto-2429"
      ba-b1: #"^(7E)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-2430"
  --assert #"^(E0)"  = ( #"a" + ( #"^(7E)" or #"^(05)" ))
  --test-- "byte-auto-2431"
  --assert #"^(FE)"  = ( #"^(7E)" or #"^(F0)" )
  --test-- "byte-auto-2432"
      ba-b1: #"^(7E)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2433"
  --assert #"^(5F)"  = ( #"a" + ( #"^(7E)" or #"^(F0)" ))
  --test-- "byte-auto-2434"
  --assert #"^(FF)"  = ( #"^(7E)" or #"^(FD)" )
  --test-- "byte-auto-2435"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2436"
  --assert #"^(60)"  = ( #"a" + ( #"^(7E)" or #"^(FD)" ))
  --test-- "byte-auto-2437"
  --assert #"^(FE)"  = ( #"^(7E)" or #"^(FE)" )
  --test-- "byte-auto-2438"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2439"
  --assert #"^(5F)"  = ( #"a" + ( #"^(7E)" or #"^(FE)" ))
  --test-- "byte-auto-2440"
  --assert #"^(7E)"  = ( #"^(7E)" or #"^(7E)" )
  --test-- "byte-auto-2441"
      ba-b1: #"^(7E)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-2442"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" or #"^(7E)" ))
  --test-- "byte-auto-2443"
  --assert #"^(7F)"  = ( #"^(7E)" or #"^(6B)" )
  --test-- "byte-auto-2444"
      ba-b1: #"^(7E)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-2445"
  --assert #"^(E0)"  = ( #"a" + ( #"^(7E)" or #"^(6B)" ))
  --test-- "byte-auto-2446"
  --assert #"^(FF)"  = ( #"^(7E)" or #"^(FB)" )
  --test-- "byte-auto-2447"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2448"
  --assert #"^(60)"  = ( #"a" + ( #"^(7E)" or #"^(FB)" ))
  --test-- "byte-auto-2449"
  --assert #"^(6B)"  = ( #"^(6B)" or #"^(00)" )
  --test-- "byte-auto-2450"
      ba-b1: #"^(6B)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2451"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" or #"^(00)" ))
  --test-- "byte-auto-2452"
  --assert #"^(FF)"  = ( #"^(6B)" or #"^(FF)" )
  --test-- "byte-auto-2453"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2454"
  --assert #"^(60)"  = ( #"a" + ( #"^(6B)" or #"^(FF)" ))
  --test-- "byte-auto-2455"
  --assert #"^(6B)"  = ( #"^(6B)" or #"^(01)" )
  --test-- "byte-auto-2456"
      ba-b1: #"^(6B)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2457"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" or #"^(01)" ))
  --test-- "byte-auto-2458"
  --assert #"^(6B)"  = ( #"^(6B)" or #"^(02)" )
  --test-- "byte-auto-2459"
      ba-b1: #"^(6B)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2460"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" or #"^(02)" ))
  --test-- "byte-auto-2461"
  --assert #"^(6B)"  = ( #"^(6B)" or #"^(03)" )
  --test-- "byte-auto-2462"
      ba-b1: #"^(6B)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2463"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" or #"^(03)" ))
  --test-- "byte-auto-2464"
  --assert #"^(6F)"  = ( #"^(6B)" or #"^(05)" )
  --test-- "byte-auto-2465"
      ba-b1: #"^(6B)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(6F)"  = ba-b3 
  --test-- "byte-auto-2466"
  --assert #"^(D0)"  = ( #"a" + ( #"^(6B)" or #"^(05)" ))
  --test-- "byte-auto-2467"
  --assert #"^(FB)"  = ( #"^(6B)" or #"^(F0)" )
  --test-- "byte-auto-2468"
      ba-b1: #"^(6B)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2469"
  --assert #"^(5C)"  = ( #"a" + ( #"^(6B)" or #"^(F0)" ))
  --test-- "byte-auto-2470"
  --assert #"^(FF)"  = ( #"^(6B)" or #"^(FD)" )
  --test-- "byte-auto-2471"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2472"
  --assert #"^(60)"  = ( #"a" + ( #"^(6B)" or #"^(FD)" ))
  --test-- "byte-auto-2473"
  --assert #"^(FF)"  = ( #"^(6B)" or #"^(FE)" )
  --test-- "byte-auto-2474"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2475"
  --assert #"^(60)"  = ( #"a" + ( #"^(6B)" or #"^(FE)" ))
  --test-- "byte-auto-2476"
  --assert #"^(7F)"  = ( #"^(6B)" or #"^(7E)" )
  --test-- "byte-auto-2477"
      ba-b1: #"^(6B)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-2478"
  --assert #"^(E0)"  = ( #"a" + ( #"^(6B)" or #"^(7E)" ))
  --test-- "byte-auto-2479"
  --assert #"^(6B)"  = ( #"^(6B)" or #"^(6B)" )
  --test-- "byte-auto-2480"
      ba-b1: #"^(6B)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2481"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" or #"^(6B)" ))
  --test-- "byte-auto-2482"
  --assert #"^(FB)"  = ( #"^(6B)" or #"^(FB)" )
  --test-- "byte-auto-2483"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2484"
  --assert #"^(5C)"  = ( #"a" + ( #"^(6B)" or #"^(FB)" ))
  --test-- "byte-auto-2485"
  --assert #"^(FB)"  = ( #"^(FB)" or #"^(00)" )
  --test-- "byte-auto-2486"
      ba-b1: #"^(FB)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2487"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" or #"^(00)" ))
  --test-- "byte-auto-2488"
  --assert #"^(FF)"  = ( #"^(FB)" or #"^(FF)" )
  --test-- "byte-auto-2489"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2490"
  --assert #"^(60)"  = ( #"a" + ( #"^(FB)" or #"^(FF)" ))
  --test-- "byte-auto-2491"
  --assert #"^(FB)"  = ( #"^(FB)" or #"^(01)" )
  --test-- "byte-auto-2492"
      ba-b1: #"^(FB)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2493"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" or #"^(01)" ))
  --test-- "byte-auto-2494"
  --assert #"^(FB)"  = ( #"^(FB)" or #"^(02)" )
  --test-- "byte-auto-2495"
      ba-b1: #"^(FB)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2496"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" or #"^(02)" ))
  --test-- "byte-auto-2497"
  --assert #"^(FB)"  = ( #"^(FB)" or #"^(03)" )
  --test-- "byte-auto-2498"
      ba-b1: #"^(FB)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2499"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" or #"^(03)" ))
  --test-- "byte-auto-2500"
  --assert #"^(FF)"  = ( #"^(FB)" or #"^(05)" )
  --test-- "byte-auto-2501"
      ba-b1: #"^(FB)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2502"
  --assert #"^(60)"  = ( #"a" + ( #"^(FB)" or #"^(05)" ))
  --test-- "byte-auto-2503"
  --assert #"^(FB)"  = ( #"^(FB)" or #"^(F0)" )
  --test-- "byte-auto-2504"
      ba-b1: #"^(FB)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2505"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" or #"^(F0)" ))
  --test-- "byte-auto-2506"
  --assert #"^(FF)"  = ( #"^(FB)" or #"^(FD)" )
  --test-- "byte-auto-2507"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2508"
  --assert #"^(60)"  = ( #"a" + ( #"^(FB)" or #"^(FD)" ))
  --test-- "byte-auto-2509"
  --assert #"^(FF)"  = ( #"^(FB)" or #"^(FE)" )
  --test-- "byte-auto-2510"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2511"
  --assert #"^(60)"  = ( #"a" + ( #"^(FB)" or #"^(FE)" ))
  --test-- "byte-auto-2512"
  --assert #"^(FF)"  = ( #"^(FB)" or #"^(7E)" )
  --test-- "byte-auto-2513"
      ba-b1: #"^(FB)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2514"
  --assert #"^(60)"  = ( #"a" + ( #"^(FB)" or #"^(7E)" ))
  --test-- "byte-auto-2515"
  --assert #"^(FB)"  = ( #"^(FB)" or #"^(6B)" )
  --test-- "byte-auto-2516"
      ba-b1: #"^(FB)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2517"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" or #"^(6B)" ))
  --test-- "byte-auto-2518"
  --assert #"^(FB)"  = ( #"^(FB)" or #"^(FB)" )
  --test-- "byte-auto-2519"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 or ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2520"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" or #"^(FB)" ))
  --test-- "byte-auto-2521"
  --assert #"^(00)"  = ( #"^(00)" xor #"^(00)" )
  --test-- "byte-auto-2522"
      ba-b1: #"^(00)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2523"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" xor #"^(00)" ))
  --test-- "byte-auto-2524"
  --assert #"^(FF)"  = ( #"^(00)" xor #"^(FF)" )
  --test-- "byte-auto-2525"
      ba-b1: #"^(00)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2526"
  --assert #"^(60)"  = ( #"a" + ( #"^(00)" xor #"^(FF)" ))
  --test-- "byte-auto-2527"
  --assert #"^(01)"  = ( #"^(00)" xor #"^(01)" )
  --test-- "byte-auto-2528"
      ba-b1: #"^(00)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2529"
  --assert #"^(62)"  = ( #"a" + ( #"^(00)" xor #"^(01)" ))
  --test-- "byte-auto-2530"
  --assert #"^(02)"  = ( #"^(00)" xor #"^(02)" )
  --test-- "byte-auto-2531"
      ba-b1: #"^(00)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-2532"
  --assert #"^(63)"  = ( #"a" + ( #"^(00)" xor #"^(02)" ))
  --test-- "byte-auto-2533"
  --assert #"^(03)"  = ( #"^(00)" xor #"^(03)" )
  --test-- "byte-auto-2534"
      ba-b1: #"^(00)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2535"
  --assert #"^(64)"  = ( #"a" + ( #"^(00)" xor #"^(03)" ))
  --test-- "byte-auto-2536"
  --assert #"^(05)"  = ( #"^(00)" xor #"^(05)" )
  --test-- "byte-auto-2537"
      ba-b1: #"^(00)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-2538"
  --assert #"^(66)"  = ( #"a" + ( #"^(00)" xor #"^(05)" ))
  --test-- "byte-auto-2539"
  --assert #"^(F0)"  = ( #"^(00)" xor #"^(F0)" )
  --test-- "byte-auto-2540"
      ba-b1: #"^(00)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-2541"
  --assert #"^(51)"  = ( #"a" + ( #"^(00)" xor #"^(F0)" ))
  --test-- "byte-auto-2542"
  --assert #"^(FD)"  = ( #"^(00)" xor #"^(FD)" )
  --test-- "byte-auto-2543"
      ba-b1: #"^(00)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2544"
  --assert #"^(5E)"  = ( #"a" + ( #"^(00)" xor #"^(FD)" ))
  --test-- "byte-auto-2545"
  --assert #"^(FE)"  = ( #"^(00)" xor #"^(FE)" )
  --test-- "byte-auto-2546"
      ba-b1: #"^(00)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2547"
  --assert #"^(5F)"  = ( #"a" + ( #"^(00)" xor #"^(FE)" ))
  --test-- "byte-auto-2548"
  --assert #"^(7E)"  = ( #"^(00)" xor #"^(7E)" )
  --test-- "byte-auto-2549"
      ba-b1: #"^(00)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-2550"
  --assert #"^(DF)"  = ( #"a" + ( #"^(00)" xor #"^(7E)" ))
  --test-- "byte-auto-2551"
  --assert #"^(6B)"  = ( #"^(00)" xor #"^(6B)" )
  --test-- "byte-auto-2552"
      ba-b1: #"^(00)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2553"
  --assert #"^(CC)"  = ( #"a" + ( #"^(00)" xor #"^(6B)" ))
  --test-- "byte-auto-2554"
  --assert #"^(FB)"  = ( #"^(00)" xor #"^(FB)" )
  --test-- "byte-auto-2555"
      ba-b1: #"^(00)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2556"
  --assert #"^(5C)"  = ( #"a" + ( #"^(00)" xor #"^(FB)" ))
  --test-- "byte-auto-2557"
  --assert #"^(FF)"  = ( #"^(FF)" xor #"^(00)" )
  --test-- "byte-auto-2558"
      ba-b1: #"^(FF)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2559"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" xor #"^(00)" ))
  --test-- "byte-auto-2560"
  --assert #"^(00)"  = ( #"^(FF)" xor #"^(FF)" )
  --test-- "byte-auto-2561"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2562"
  --assert #"^(61)"  = ( #"a" + ( #"^(FF)" xor #"^(FF)" ))
  --test-- "byte-auto-2563"
  --assert #"^(FE)"  = ( #"^(FF)" xor #"^(01)" )
  --test-- "byte-auto-2564"
      ba-b1: #"^(FF)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2565"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FF)" xor #"^(01)" ))
  --test-- "byte-auto-2566"
  --assert #"^(FD)"  = ( #"^(FF)" xor #"^(02)" )
  --test-- "byte-auto-2567"
      ba-b1: #"^(FF)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2568"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FF)" xor #"^(02)" ))
  --test-- "byte-auto-2569"
  --assert #"^(FC)"  = ( #"^(FF)" xor #"^(03)" )
  --test-- "byte-auto-2570"
      ba-b1: #"^(FF)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-2571"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FF)" xor #"^(03)" ))
  --test-- "byte-auto-2572"
  --assert #"^(FA)"  = ( #"^(FF)" xor #"^(05)" )
  --test-- "byte-auto-2573"
      ba-b1: #"^(FF)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-2574"
  --assert #"^(5B)"  = ( #"a" + ( #"^(FF)" xor #"^(05)" ))
  --test-- "byte-auto-2575"
  --assert #"^(0F)"  = ( #"^(FF)" xor #"^(F0)" )
  --test-- "byte-auto-2576"
      ba-b1: #"^(FF)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(0F)"  = ba-b3 
  --test-- "byte-auto-2577"
  --assert #"^(70)"  = ( #"a" + ( #"^(FF)" xor #"^(F0)" ))
  --test-- "byte-auto-2578"
  --assert #"^(02)"  = ( #"^(FF)" xor #"^(FD)" )
  --test-- "byte-auto-2579"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-2580"
  --assert #"^(63)"  = ( #"a" + ( #"^(FF)" xor #"^(FD)" ))
  --test-- "byte-auto-2581"
  --assert #"^(01)"  = ( #"^(FF)" xor #"^(FE)" )
  --test-- "byte-auto-2582"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2583"
  --assert #"^(62)"  = ( #"a" + ( #"^(FF)" xor #"^(FE)" ))
  --test-- "byte-auto-2584"
  --assert #"^(81)"  = ( #"^(FF)" xor #"^(7E)" )
  --test-- "byte-auto-2585"
      ba-b1: #"^(FF)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(81)"  = ba-b3 
  --test-- "byte-auto-2586"
  --assert #"^(E2)"  = ( #"a" + ( #"^(FF)" xor #"^(7E)" ))
  --test-- "byte-auto-2587"
  --assert #"^(94)"  = ( #"^(FF)" xor #"^(6B)" )
  --test-- "byte-auto-2588"
      ba-b1: #"^(FF)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(94)"  = ba-b3 
  --test-- "byte-auto-2589"
  --assert #"^(F5)"  = ( #"a" + ( #"^(FF)" xor #"^(6B)" ))
  --test-- "byte-auto-2590"
  --assert #"^(04)"  = ( #"^(FF)" xor #"^(FB)" )
  --test-- "byte-auto-2591"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-2592"
  --assert #"^(65)"  = ( #"a" + ( #"^(FF)" xor #"^(FB)" ))
  --test-- "byte-auto-2593"
  --assert #"^(01)"  = ( #"^(01)" xor #"^(00)" )
  --test-- "byte-auto-2594"
      ba-b1: #"^(01)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2595"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" xor #"^(00)" ))
  --test-- "byte-auto-2596"
  --assert #"^(FE)"  = ( #"^(01)" xor #"^(FF)" )
  --test-- "byte-auto-2597"
      ba-b1: #"^(01)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2598"
  --assert #"^(5F)"  = ( #"a" + ( #"^(01)" xor #"^(FF)" ))
  --test-- "byte-auto-2599"
  --assert #"^(00)"  = ( #"^(01)" xor #"^(01)" )
  --test-- "byte-auto-2600"
      ba-b1: #"^(01)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2601"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" xor #"^(01)" ))
  --test-- "byte-auto-2602"
  --assert #"^(03)"  = ( #"^(01)" xor #"^(02)" )
  --test-- "byte-auto-2603"
      ba-b1: #"^(01)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2604"
  --assert #"^(64)"  = ( #"a" + ( #"^(01)" xor #"^(02)" ))
  --test-- "byte-auto-2605"
  --assert #"^(02)"  = ( #"^(01)" xor #"^(03)" )
  --test-- "byte-auto-2606"
      ba-b1: #"^(01)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-2607"
  --assert #"^(63)"  = ( #"a" + ( #"^(01)" xor #"^(03)" ))
  --test-- "byte-auto-2608"
  --assert #"^(04)"  = ( #"^(01)" xor #"^(05)" )
  --test-- "byte-auto-2609"
      ba-b1: #"^(01)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-2610"
  --assert #"^(65)"  = ( #"a" + ( #"^(01)" xor #"^(05)" ))
  --test-- "byte-auto-2611"
  --assert #"^(F1)"  = ( #"^(01)" xor #"^(F0)" )
  --test-- "byte-auto-2612"
      ba-b1: #"^(01)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F1)"  = ba-b3 
  --test-- "byte-auto-2613"
  --assert #"^(52)"  = ( #"a" + ( #"^(01)" xor #"^(F0)" ))
  --test-- "byte-auto-2614"
  --assert #"^(FC)"  = ( #"^(01)" xor #"^(FD)" )
  --test-- "byte-auto-2615"
      ba-b1: #"^(01)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-2616"
  --assert #"^(5D)"  = ( #"a" + ( #"^(01)" xor #"^(FD)" ))
  --test-- "byte-auto-2617"
  --assert #"^(FF)"  = ( #"^(01)" xor #"^(FE)" )
  --test-- "byte-auto-2618"
      ba-b1: #"^(01)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2619"
  --assert #"^(60)"  = ( #"a" + ( #"^(01)" xor #"^(FE)" ))
  --test-- "byte-auto-2620"
  --assert #"^(7F)"  = ( #"^(01)" xor #"^(7E)" )
  --test-- "byte-auto-2621"
      ba-b1: #"^(01)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-2622"
  --assert #"^(E0)"  = ( #"a" + ( #"^(01)" xor #"^(7E)" ))
  --test-- "byte-auto-2623"
  --assert #"^(6A)"  = ( #"^(01)" xor #"^(6B)" )
  --test-- "byte-auto-2624"
      ba-b1: #"^(01)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(6A)"  = ba-b3 
  --test-- "byte-auto-2625"
  --assert #"^(CB)"  = ( #"a" + ( #"^(01)" xor #"^(6B)" ))
  --test-- "byte-auto-2626"
  --assert #"^(FA)"  = ( #"^(01)" xor #"^(FB)" )
  --test-- "byte-auto-2627"
      ba-b1: #"^(01)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-2628"
  --assert #"^(5B)"  = ( #"a" + ( #"^(01)" xor #"^(FB)" ))
  --test-- "byte-auto-2629"
  --assert #"^(02)"  = ( #"^(02)" xor #"^(00)" )
  --test-- "byte-auto-2630"
      ba-b1: #"^(02)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-2631"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" xor #"^(00)" ))
  --test-- "byte-auto-2632"
  --assert #"^(FD)"  = ( #"^(02)" xor #"^(FF)" )
  --test-- "byte-auto-2633"
      ba-b1: #"^(02)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2634"
  --assert #"^(5E)"  = ( #"a" + ( #"^(02)" xor #"^(FF)" ))
  --test-- "byte-auto-2635"
  --assert #"^(03)"  = ( #"^(02)" xor #"^(01)" )
  --test-- "byte-auto-2636"
      ba-b1: #"^(02)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2637"
  --assert #"^(64)"  = ( #"a" + ( #"^(02)" xor #"^(01)" ))
  --test-- "byte-auto-2638"
  --assert #"^(00)"  = ( #"^(02)" xor #"^(02)" )
  --test-- "byte-auto-2639"
      ba-b1: #"^(02)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2640"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" xor #"^(02)" ))
  --test-- "byte-auto-2641"
  --assert #"^(01)"  = ( #"^(02)" xor #"^(03)" )
  --test-- "byte-auto-2642"
      ba-b1: #"^(02)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2643"
  --assert #"^(62)"  = ( #"a" + ( #"^(02)" xor #"^(03)" ))
  --test-- "byte-auto-2644"
  --assert #"^(07)"  = ( #"^(02)" xor #"^(05)" )
  --test-- "byte-auto-2645"
      ba-b1: #"^(02)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(07)"  = ba-b3 
  --test-- "byte-auto-2646"
  --assert #"^(68)"  = ( #"a" + ( #"^(02)" xor #"^(05)" ))
  --test-- "byte-auto-2647"
  --assert #"^(F2)"  = ( #"^(02)" xor #"^(F0)" )
  --test-- "byte-auto-2648"
      ba-b1: #"^(02)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F2)"  = ba-b3 
  --test-- "byte-auto-2649"
  --assert #"^(53)"  = ( #"a" + ( #"^(02)" xor #"^(F0)" ))
  --test-- "byte-auto-2650"
  --assert #"^(FF)"  = ( #"^(02)" xor #"^(FD)" )
  --test-- "byte-auto-2651"
      ba-b1: #"^(02)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2652"
  --assert #"^(60)"  = ( #"a" + ( #"^(02)" xor #"^(FD)" ))
  --test-- "byte-auto-2653"
  --assert #"^(FC)"  = ( #"^(02)" xor #"^(FE)" )
  --test-- "byte-auto-2654"
      ba-b1: #"^(02)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-2655"
  --assert #"^(5D)"  = ( #"a" + ( #"^(02)" xor #"^(FE)" ))
  --test-- "byte-auto-2656"
  --assert #"^(7C)"  = ( #"^(02)" xor #"^(7E)" )
  --test-- "byte-auto-2657"
      ba-b1: #"^(02)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(7C)"  = ba-b3 
  --test-- "byte-auto-2658"
  --assert #"^(DD)"  = ( #"a" + ( #"^(02)" xor #"^(7E)" ))
  --test-- "byte-auto-2659"
  --assert #"^(69)"  = ( #"^(02)" xor #"^(6B)" )
  --test-- "byte-auto-2660"
      ba-b1: #"^(02)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(69)"  = ba-b3 
  --test-- "byte-auto-2661"
  --assert #"^(CA)"  = ( #"a" + ( #"^(02)" xor #"^(6B)" ))
  --test-- "byte-auto-2662"
  --assert #"^(F9)"  = ( #"^(02)" xor #"^(FB)" )
  --test-- "byte-auto-2663"
      ba-b1: #"^(02)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F9)"  = ba-b3 
  --test-- "byte-auto-2664"
  --assert #"^(5A)"  = ( #"a" + ( #"^(02)" xor #"^(FB)" ))
  --test-- "byte-auto-2665"
  --assert #"^(03)"  = ( #"^(03)" xor #"^(00)" )
  --test-- "byte-auto-2666"
      ba-b1: #"^(03)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2667"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" xor #"^(00)" ))
  --test-- "byte-auto-2668"
  --assert #"^(FC)"  = ( #"^(03)" xor #"^(FF)" )
  --test-- "byte-auto-2669"
      ba-b1: #"^(03)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-2670"
  --assert #"^(5D)"  = ( #"a" + ( #"^(03)" xor #"^(FF)" ))
  --test-- "byte-auto-2671"
  --assert #"^(02)"  = ( #"^(03)" xor #"^(01)" )
  --test-- "byte-auto-2672"
      ba-b1: #"^(03)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-2673"
  --assert #"^(63)"  = ( #"a" + ( #"^(03)" xor #"^(01)" ))
  --test-- "byte-auto-2674"
  --assert #"^(01)"  = ( #"^(03)" xor #"^(02)" )
  --test-- "byte-auto-2675"
      ba-b1: #"^(03)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2676"
  --assert #"^(62)"  = ( #"a" + ( #"^(03)" xor #"^(02)" ))
  --test-- "byte-auto-2677"
  --assert #"^(00)"  = ( #"^(03)" xor #"^(03)" )
  --test-- "byte-auto-2678"
      ba-b1: #"^(03)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2679"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" xor #"^(03)" ))
  --test-- "byte-auto-2680"
  --assert #"^(06)"  = ( #"^(03)" xor #"^(05)" )
  --test-- "byte-auto-2681"
      ba-b1: #"^(03)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-2682"
  --assert #"^(67)"  = ( #"a" + ( #"^(03)" xor #"^(05)" ))
  --test-- "byte-auto-2683"
  --assert #"^(F3)"  = ( #"^(03)" xor #"^(F0)" )
  --test-- "byte-auto-2684"
      ba-b1: #"^(03)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F3)"  = ba-b3 
  --test-- "byte-auto-2685"
  --assert #"^(54)"  = ( #"a" + ( #"^(03)" xor #"^(F0)" ))
  --test-- "byte-auto-2686"
  --assert #"^(FE)"  = ( #"^(03)" xor #"^(FD)" )
  --test-- "byte-auto-2687"
      ba-b1: #"^(03)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2688"
  --assert #"^(5F)"  = ( #"a" + ( #"^(03)" xor #"^(FD)" ))
  --test-- "byte-auto-2689"
  --assert #"^(FD)"  = ( #"^(03)" xor #"^(FE)" )
  --test-- "byte-auto-2690"
      ba-b1: #"^(03)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2691"
  --assert #"^(5E)"  = ( #"a" + ( #"^(03)" xor #"^(FE)" ))
  --test-- "byte-auto-2692"
  --assert #"^(7D)"  = ( #"^(03)" xor #"^(7E)" )
  --test-- "byte-auto-2693"
      ba-b1: #"^(03)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(7D)"  = ba-b3 
  --test-- "byte-auto-2694"
  --assert #"^(DE)"  = ( #"a" + ( #"^(03)" xor #"^(7E)" ))
  --test-- "byte-auto-2695"
  --assert #"^(68)"  = ( #"^(03)" xor #"^(6B)" )
  --test-- "byte-auto-2696"
      ba-b1: #"^(03)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(68)"  = ba-b3 
  --test-- "byte-auto-2697"
  --assert #"^(C9)"  = ( #"a" + ( #"^(03)" xor #"^(6B)" ))
  --test-- "byte-auto-2698"
  --assert #"^(F8)"  = ( #"^(03)" xor #"^(FB)" )
  --test-- "byte-auto-2699"
      ba-b1: #"^(03)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F8)"  = ba-b3 
  --test-- "byte-auto-2700"
  --assert #"^(59)"  = ( #"a" + ( #"^(03)" xor #"^(FB)" ))
  --test-- "byte-auto-2701"
  --assert #"^(05)"  = ( #"^(05)" xor #"^(00)" )
  --test-- "byte-auto-2702"
      ba-b1: #"^(05)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-2703"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" xor #"^(00)" ))
  --test-- "byte-auto-2704"
  --assert #"^(FA)"  = ( #"^(05)" xor #"^(FF)" )
  --test-- "byte-auto-2705"
      ba-b1: #"^(05)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-2706"
  --assert #"^(5B)"  = ( #"a" + ( #"^(05)" xor #"^(FF)" ))
  --test-- "byte-auto-2707"
  --assert #"^(04)"  = ( #"^(05)" xor #"^(01)" )
  --test-- "byte-auto-2708"
      ba-b1: #"^(05)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-2709"
  --assert #"^(65)"  = ( #"a" + ( #"^(05)" xor #"^(01)" ))
  --test-- "byte-auto-2710"
  --assert #"^(07)"  = ( #"^(05)" xor #"^(02)" )
  --test-- "byte-auto-2711"
      ba-b1: #"^(05)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(07)"  = ba-b3 
  --test-- "byte-auto-2712"
  --assert #"^(68)"  = ( #"a" + ( #"^(05)" xor #"^(02)" ))
  --test-- "byte-auto-2713"
  --assert #"^(06)"  = ( #"^(05)" xor #"^(03)" )
  --test-- "byte-auto-2714"
      ba-b1: #"^(05)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-2715"
  --assert #"^(67)"  = ( #"a" + ( #"^(05)" xor #"^(03)" ))
  --test-- "byte-auto-2716"
  --assert #"^(00)"  = ( #"^(05)" xor #"^(05)" )
  --test-- "byte-auto-2717"
      ba-b1: #"^(05)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2718"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" xor #"^(05)" ))
  --test-- "byte-auto-2719"
  --assert #"^(F5)"  = ( #"^(05)" xor #"^(F0)" )
  --test-- "byte-auto-2720"
      ba-b1: #"^(05)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F5)"  = ba-b3 
  --test-- "byte-auto-2721"
  --assert #"^(56)"  = ( #"a" + ( #"^(05)" xor #"^(F0)" ))
  --test-- "byte-auto-2722"
  --assert #"^(F8)"  = ( #"^(05)" xor #"^(FD)" )
  --test-- "byte-auto-2723"
      ba-b1: #"^(05)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F8)"  = ba-b3 
  --test-- "byte-auto-2724"
  --assert #"^(59)"  = ( #"a" + ( #"^(05)" xor #"^(FD)" ))
  --test-- "byte-auto-2725"
  --assert #"^(FB)"  = ( #"^(05)" xor #"^(FE)" )
  --test-- "byte-auto-2726"
      ba-b1: #"^(05)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2727"
  --assert #"^(5C)"  = ( #"a" + ( #"^(05)" xor #"^(FE)" ))
  --test-- "byte-auto-2728"
  --assert #"^(7B)"  = ( #"^(05)" xor #"^(7E)" )
  --test-- "byte-auto-2729"
      ba-b1: #"^(05)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(7B)"  = ba-b3 
  --test-- "byte-auto-2730"
  --assert #"^(DC)"  = ( #"a" + ( #"^(05)" xor #"^(7E)" ))
  --test-- "byte-auto-2731"
  --assert #"^(6E)"  = ( #"^(05)" xor #"^(6B)" )
  --test-- "byte-auto-2732"
      ba-b1: #"^(05)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(6E)"  = ba-b3 
  --test-- "byte-auto-2733"
  --assert #"^(CF)"  = ( #"a" + ( #"^(05)" xor #"^(6B)" ))
  --test-- "byte-auto-2734"
  --assert #"^(FE)"  = ( #"^(05)" xor #"^(FB)" )
  --test-- "byte-auto-2735"
      ba-b1: #"^(05)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2736"
  --assert #"^(5F)"  = ( #"a" + ( #"^(05)" xor #"^(FB)" ))
  --test-- "byte-auto-2737"
  --assert #"^(F0)"  = ( #"^(F0)" xor #"^(00)" )
  --test-- "byte-auto-2738"
      ba-b1: #"^(F0)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-2739"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" xor #"^(00)" ))
  --test-- "byte-auto-2740"
  --assert #"^(0F)"  = ( #"^(F0)" xor #"^(FF)" )
  --test-- "byte-auto-2741"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(0F)"  = ba-b3 
  --test-- "byte-auto-2742"
  --assert #"^(70)"  = ( #"a" + ( #"^(F0)" xor #"^(FF)" ))
  --test-- "byte-auto-2743"
  --assert #"^(F1)"  = ( #"^(F0)" xor #"^(01)" )
  --test-- "byte-auto-2744"
      ba-b1: #"^(F0)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F1)"  = ba-b3 
  --test-- "byte-auto-2745"
  --assert #"^(52)"  = ( #"a" + ( #"^(F0)" xor #"^(01)" ))
  --test-- "byte-auto-2746"
  --assert #"^(F2)"  = ( #"^(F0)" xor #"^(02)" )
  --test-- "byte-auto-2747"
      ba-b1: #"^(F0)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F2)"  = ba-b3 
  --test-- "byte-auto-2748"
  --assert #"^(53)"  = ( #"a" + ( #"^(F0)" xor #"^(02)" ))
  --test-- "byte-auto-2749"
  --assert #"^(F3)"  = ( #"^(F0)" xor #"^(03)" )
  --test-- "byte-auto-2750"
      ba-b1: #"^(F0)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F3)"  = ba-b3 
  --test-- "byte-auto-2751"
  --assert #"^(54)"  = ( #"a" + ( #"^(F0)" xor #"^(03)" ))
  --test-- "byte-auto-2752"
  --assert #"^(F5)"  = ( #"^(F0)" xor #"^(05)" )
  --test-- "byte-auto-2753"
      ba-b1: #"^(F0)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F5)"  = ba-b3 
  --test-- "byte-auto-2754"
  --assert #"^(56)"  = ( #"a" + ( #"^(F0)" xor #"^(05)" ))
  --test-- "byte-auto-2755"
  --assert #"^(00)"  = ( #"^(F0)" xor #"^(F0)" )
  --test-- "byte-auto-2756"
      ba-b1: #"^(F0)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2757"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" xor #"^(F0)" ))
  --test-- "byte-auto-2758"
  --assert #"^(0D)"  = ( #"^(F0)" xor #"^(FD)" )
  --test-- "byte-auto-2759"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(0D)"  = ba-b3 
  --test-- "byte-auto-2760"
  --assert #"^(6E)"  = ( #"a" + ( #"^(F0)" xor #"^(FD)" ))
  --test-- "byte-auto-2761"
  --assert #"^(0E)"  = ( #"^(F0)" xor #"^(FE)" )
  --test-- "byte-auto-2762"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(0E)"  = ba-b3 
  --test-- "byte-auto-2763"
  --assert #"^(6F)"  = ( #"a" + ( #"^(F0)" xor #"^(FE)" ))
  --test-- "byte-auto-2764"
  --assert #"^(8E)"  = ( #"^(F0)" xor #"^(7E)" )
  --test-- "byte-auto-2765"
      ba-b1: #"^(F0)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(8E)"  = ba-b3 
  --test-- "byte-auto-2766"
  --assert #"^(EF)"  = ( #"a" + ( #"^(F0)" xor #"^(7E)" ))
  --test-- "byte-auto-2767"
  --assert #"^(9B)"  = ( #"^(F0)" xor #"^(6B)" )
  --test-- "byte-auto-2768"
      ba-b1: #"^(F0)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(9B)"  = ba-b3 
  --test-- "byte-auto-2769"
  --assert #"^(FC)"  = ( #"a" + ( #"^(F0)" xor #"^(6B)" ))
  --test-- "byte-auto-2770"
  --assert #"^(0B)"  = ( #"^(F0)" xor #"^(FB)" )
  --test-- "byte-auto-2771"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(0B)"  = ba-b3 
  --test-- "byte-auto-2772"
  --assert #"^(6C)"  = ( #"a" + ( #"^(F0)" xor #"^(FB)" ))
  --test-- "byte-auto-2773"
  --assert #"^(FD)"  = ( #"^(FD)" xor #"^(00)" )
  --test-- "byte-auto-2774"
      ba-b1: #"^(FD)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2775"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" xor #"^(00)" ))
  --test-- "byte-auto-2776"
  --assert #"^(02)"  = ( #"^(FD)" xor #"^(FF)" )
  --test-- "byte-auto-2777"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-2778"
  --assert #"^(63)"  = ( #"a" + ( #"^(FD)" xor #"^(FF)" ))
  --test-- "byte-auto-2779"
  --assert #"^(FC)"  = ( #"^(FD)" xor #"^(01)" )
  --test-- "byte-auto-2780"
      ba-b1: #"^(FD)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-2781"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FD)" xor #"^(01)" ))
  --test-- "byte-auto-2782"
  --assert #"^(FF)"  = ( #"^(FD)" xor #"^(02)" )
  --test-- "byte-auto-2783"
      ba-b1: #"^(FD)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2784"
  --assert #"^(60)"  = ( #"a" + ( #"^(FD)" xor #"^(02)" ))
  --test-- "byte-auto-2785"
  --assert #"^(FE)"  = ( #"^(FD)" xor #"^(03)" )
  --test-- "byte-auto-2786"
      ba-b1: #"^(FD)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2787"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FD)" xor #"^(03)" ))
  --test-- "byte-auto-2788"
  --assert #"^(F8)"  = ( #"^(FD)" xor #"^(05)" )
  --test-- "byte-auto-2789"
      ba-b1: #"^(FD)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F8)"  = ba-b3 
  --test-- "byte-auto-2790"
  --assert #"^(59)"  = ( #"a" + ( #"^(FD)" xor #"^(05)" ))
  --test-- "byte-auto-2791"
  --assert #"^(0D)"  = ( #"^(FD)" xor #"^(F0)" )
  --test-- "byte-auto-2792"
      ba-b1: #"^(FD)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(0D)"  = ba-b3 
  --test-- "byte-auto-2793"
  --assert #"^(6E)"  = ( #"a" + ( #"^(FD)" xor #"^(F0)" ))
  --test-- "byte-auto-2794"
  --assert #"^(00)"  = ( #"^(FD)" xor #"^(FD)" )
  --test-- "byte-auto-2795"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2796"
  --assert #"^(61)"  = ( #"a" + ( #"^(FD)" xor #"^(FD)" ))
  --test-- "byte-auto-2797"
  --assert #"^(03)"  = ( #"^(FD)" xor #"^(FE)" )
  --test-- "byte-auto-2798"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2799"
  --assert #"^(64)"  = ( #"a" + ( #"^(FD)" xor #"^(FE)" ))
  --test-- "byte-auto-2800"
  --assert #"^(83)"  = ( #"^(FD)" xor #"^(7E)" )
  --test-- "byte-auto-2801"
      ba-b1: #"^(FD)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(83)"  = ba-b3 
  --test-- "byte-auto-2802"
  --assert #"^(E4)"  = ( #"a" + ( #"^(FD)" xor #"^(7E)" ))
  --test-- "byte-auto-2803"
  --assert #"^(96)"  = ( #"^(FD)" xor #"^(6B)" )
  --test-- "byte-auto-2804"
      ba-b1: #"^(FD)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(96)"  = ba-b3 
  --test-- "byte-auto-2805"
  --assert #"^(F7)"  = ( #"a" + ( #"^(FD)" xor #"^(6B)" ))
  --test-- "byte-auto-2806"
  --assert #"^(06)"  = ( #"^(FD)" xor #"^(FB)" )
  --test-- "byte-auto-2807"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-2808"
  --assert #"^(67)"  = ( #"a" + ( #"^(FD)" xor #"^(FB)" ))
  --test-- "byte-auto-2809"
  --assert #"^(FE)"  = ( #"^(FE)" xor #"^(00)" )
  --test-- "byte-auto-2810"
      ba-b1: #"^(FE)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2811"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" xor #"^(00)" ))
  --test-- "byte-auto-2812"
  --assert #"^(01)"  = ( #"^(FE)" xor #"^(FF)" )
  --test-- "byte-auto-2813"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2814"
  --assert #"^(62)"  = ( #"a" + ( #"^(FE)" xor #"^(FF)" ))
  --test-- "byte-auto-2815"
  --assert #"^(FF)"  = ( #"^(FE)" xor #"^(01)" )
  --test-- "byte-auto-2816"
      ba-b1: #"^(FE)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2817"
  --assert #"^(60)"  = ( #"a" + ( #"^(FE)" xor #"^(01)" ))
  --test-- "byte-auto-2818"
  --assert #"^(FC)"  = ( #"^(FE)" xor #"^(02)" )
  --test-- "byte-auto-2819"
      ba-b1: #"^(FE)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-2820"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FE)" xor #"^(02)" ))
  --test-- "byte-auto-2821"
  --assert #"^(FD)"  = ( #"^(FE)" xor #"^(03)" )
  --test-- "byte-auto-2822"
      ba-b1: #"^(FE)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-2823"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FE)" xor #"^(03)" ))
  --test-- "byte-auto-2824"
  --assert #"^(FB)"  = ( #"^(FE)" xor #"^(05)" )
  --test-- "byte-auto-2825"
      ba-b1: #"^(FE)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2826"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FE)" xor #"^(05)" ))
  --test-- "byte-auto-2827"
  --assert #"^(0E)"  = ( #"^(FE)" xor #"^(F0)" )
  --test-- "byte-auto-2828"
      ba-b1: #"^(FE)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(0E)"  = ba-b3 
  --test-- "byte-auto-2829"
  --assert #"^(6F)"  = ( #"a" + ( #"^(FE)" xor #"^(F0)" ))
  --test-- "byte-auto-2830"
  --assert #"^(03)"  = ( #"^(FE)" xor #"^(FD)" )
  --test-- "byte-auto-2831"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-2832"
  --assert #"^(64)"  = ( #"a" + ( #"^(FE)" xor #"^(FD)" ))
  --test-- "byte-auto-2833"
  --assert #"^(00)"  = ( #"^(FE)" xor #"^(FE)" )
  --test-- "byte-auto-2834"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2835"
  --assert #"^(61)"  = ( #"a" + ( #"^(FE)" xor #"^(FE)" ))
  --test-- "byte-auto-2836"
  --assert #"^(80)"  = ( #"^(FE)" xor #"^(7E)" )
  --test-- "byte-auto-2837"
      ba-b1: #"^(FE)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(80)"  = ba-b3 
  --test-- "byte-auto-2838"
  --assert #"^(E1)"  = ( #"a" + ( #"^(FE)" xor #"^(7E)" ))
  --test-- "byte-auto-2839"
  --assert #"^(95)"  = ( #"^(FE)" xor #"^(6B)" )
  --test-- "byte-auto-2840"
      ba-b1: #"^(FE)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(95)"  = ba-b3 
  --test-- "byte-auto-2841"
  --assert #"^(F6)"  = ( #"a" + ( #"^(FE)" xor #"^(6B)" ))
  --test-- "byte-auto-2842"
  --assert #"^(05)"  = ( #"^(FE)" xor #"^(FB)" )
  --test-- "byte-auto-2843"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-2844"
  --assert #"^(66)"  = ( #"a" + ( #"^(FE)" xor #"^(FB)" ))
  --test-- "byte-auto-2845"
  --assert #"^(7E)"  = ( #"^(7E)" xor #"^(00)" )
  --test-- "byte-auto-2846"
      ba-b1: #"^(7E)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-2847"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" xor #"^(00)" ))
  --test-- "byte-auto-2848"
  --assert #"^(81)"  = ( #"^(7E)" xor #"^(FF)" )
  --test-- "byte-auto-2849"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(81)"  = ba-b3 
  --test-- "byte-auto-2850"
  --assert #"^(E2)"  = ( #"a" + ( #"^(7E)" xor #"^(FF)" ))
  --test-- "byte-auto-2851"
  --assert #"^(7F)"  = ( #"^(7E)" xor #"^(01)" )
  --test-- "byte-auto-2852"
      ba-b1: #"^(7E)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(7F)"  = ba-b3 
  --test-- "byte-auto-2853"
  --assert #"^(E0)"  = ( #"a" + ( #"^(7E)" xor #"^(01)" ))
  --test-- "byte-auto-2854"
  --assert #"^(7C)"  = ( #"^(7E)" xor #"^(02)" )
  --test-- "byte-auto-2855"
      ba-b1: #"^(7E)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(7C)"  = ba-b3 
  --test-- "byte-auto-2856"
  --assert #"^(DD)"  = ( #"a" + ( #"^(7E)" xor #"^(02)" ))
  --test-- "byte-auto-2857"
  --assert #"^(7D)"  = ( #"^(7E)" xor #"^(03)" )
  --test-- "byte-auto-2858"
      ba-b1: #"^(7E)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(7D)"  = ba-b3 
  --test-- "byte-auto-2859"
  --assert #"^(DE)"  = ( #"a" + ( #"^(7E)" xor #"^(03)" ))
  --test-- "byte-auto-2860"
  --assert #"^(7B)"  = ( #"^(7E)" xor #"^(05)" )
  --test-- "byte-auto-2861"
      ba-b1: #"^(7E)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(7B)"  = ba-b3 
  --test-- "byte-auto-2862"
  --assert #"^(DC)"  = ( #"a" + ( #"^(7E)" xor #"^(05)" ))
  --test-- "byte-auto-2863"
  --assert #"^(8E)"  = ( #"^(7E)" xor #"^(F0)" )
  --test-- "byte-auto-2864"
      ba-b1: #"^(7E)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(8E)"  = ba-b3 
  --test-- "byte-auto-2865"
  --assert #"^(EF)"  = ( #"a" + ( #"^(7E)" xor #"^(F0)" ))
  --test-- "byte-auto-2866"
  --assert #"^(83)"  = ( #"^(7E)" xor #"^(FD)" )
  --test-- "byte-auto-2867"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(83)"  = ba-b3 
  --test-- "byte-auto-2868"
  --assert #"^(E4)"  = ( #"a" + ( #"^(7E)" xor #"^(FD)" ))
  --test-- "byte-auto-2869"
  --assert #"^(80)"  = ( #"^(7E)" xor #"^(FE)" )
  --test-- "byte-auto-2870"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(80)"  = ba-b3 
  --test-- "byte-auto-2871"
  --assert #"^(E1)"  = ( #"a" + ( #"^(7E)" xor #"^(FE)" ))
  --test-- "byte-auto-2872"
  --assert #"^(00)"  = ( #"^(7E)" xor #"^(7E)" )
  --test-- "byte-auto-2873"
      ba-b1: #"^(7E)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2874"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" xor #"^(7E)" ))
  --test-- "byte-auto-2875"
  --assert #"^(15)"  = ( #"^(7E)" xor #"^(6B)" )
  --test-- "byte-auto-2876"
      ba-b1: #"^(7E)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(15)"  = ba-b3 
  --test-- "byte-auto-2877"
  --assert #"^(76)"  = ( #"a" + ( #"^(7E)" xor #"^(6B)" ))
  --test-- "byte-auto-2878"
  --assert #"^(85)"  = ( #"^(7E)" xor #"^(FB)" )
  --test-- "byte-auto-2879"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(85)"  = ba-b3 
  --test-- "byte-auto-2880"
  --assert #"^(E6)"  = ( #"a" + ( #"^(7E)" xor #"^(FB)" ))
  --test-- "byte-auto-2881"
  --assert #"^(6B)"  = ( #"^(6B)" xor #"^(00)" )
  --test-- "byte-auto-2882"
      ba-b1: #"^(6B)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-2883"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" xor #"^(00)" ))
  --test-- "byte-auto-2884"
  --assert #"^(94)"  = ( #"^(6B)" xor #"^(FF)" )
  --test-- "byte-auto-2885"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(94)"  = ba-b3 
  --test-- "byte-auto-2886"
  --assert #"^(F5)"  = ( #"a" + ( #"^(6B)" xor #"^(FF)" ))
  --test-- "byte-auto-2887"
  --assert #"^(6A)"  = ( #"^(6B)" xor #"^(01)" )
  --test-- "byte-auto-2888"
      ba-b1: #"^(6B)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(6A)"  = ba-b3 
  --test-- "byte-auto-2889"
  --assert #"^(CB)"  = ( #"a" + ( #"^(6B)" xor #"^(01)" ))
  --test-- "byte-auto-2890"
  --assert #"^(69)"  = ( #"^(6B)" xor #"^(02)" )
  --test-- "byte-auto-2891"
      ba-b1: #"^(6B)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(69)"  = ba-b3 
  --test-- "byte-auto-2892"
  --assert #"^(CA)"  = ( #"a" + ( #"^(6B)" xor #"^(02)" ))
  --test-- "byte-auto-2893"
  --assert #"^(68)"  = ( #"^(6B)" xor #"^(03)" )
  --test-- "byte-auto-2894"
      ba-b1: #"^(6B)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(68)"  = ba-b3 
  --test-- "byte-auto-2895"
  --assert #"^(C9)"  = ( #"a" + ( #"^(6B)" xor #"^(03)" ))
  --test-- "byte-auto-2896"
  --assert #"^(6E)"  = ( #"^(6B)" xor #"^(05)" )
  --test-- "byte-auto-2897"
      ba-b1: #"^(6B)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(6E)"  = ba-b3 
  --test-- "byte-auto-2898"
  --assert #"^(CF)"  = ( #"a" + ( #"^(6B)" xor #"^(05)" ))
  --test-- "byte-auto-2899"
  --assert #"^(9B)"  = ( #"^(6B)" xor #"^(F0)" )
  --test-- "byte-auto-2900"
      ba-b1: #"^(6B)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(9B)"  = ba-b3 
  --test-- "byte-auto-2901"
  --assert #"^(FC)"  = ( #"a" + ( #"^(6B)" xor #"^(F0)" ))
  --test-- "byte-auto-2902"
  --assert #"^(96)"  = ( #"^(6B)" xor #"^(FD)" )
  --test-- "byte-auto-2903"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(96)"  = ba-b3 
  --test-- "byte-auto-2904"
  --assert #"^(F7)"  = ( #"a" + ( #"^(6B)" xor #"^(FD)" ))
  --test-- "byte-auto-2905"
  --assert #"^(95)"  = ( #"^(6B)" xor #"^(FE)" )
  --test-- "byte-auto-2906"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(95)"  = ba-b3 
  --test-- "byte-auto-2907"
  --assert #"^(F6)"  = ( #"a" + ( #"^(6B)" xor #"^(FE)" ))
  --test-- "byte-auto-2908"
  --assert #"^(15)"  = ( #"^(6B)" xor #"^(7E)" )
  --test-- "byte-auto-2909"
      ba-b1: #"^(6B)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(15)"  = ba-b3 
  --test-- "byte-auto-2910"
  --assert #"^(76)"  = ( #"a" + ( #"^(6B)" xor #"^(7E)" ))
  --test-- "byte-auto-2911"
  --assert #"^(00)"  = ( #"^(6B)" xor #"^(6B)" )
  --test-- "byte-auto-2912"
      ba-b1: #"^(6B)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2913"
  --assert #"^(61)"  = ( #"a" + ( #"^(6B)" xor #"^(6B)" ))
  --test-- "byte-auto-2914"
  --assert #"^(90)"  = ( #"^(6B)" xor #"^(FB)" )
  --test-- "byte-auto-2915"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(90)"  = ba-b3 
  --test-- "byte-auto-2916"
  --assert #"^(F1)"  = ( #"a" + ( #"^(6B)" xor #"^(FB)" ))
  --test-- "byte-auto-2917"
  --assert #"^(FB)"  = ( #"^(FB)" xor #"^(00)" )
  --test-- "byte-auto-2918"
      ba-b1: #"^(FB)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-2919"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" xor #"^(00)" ))
  --test-- "byte-auto-2920"
  --assert #"^(04)"  = ( #"^(FB)" xor #"^(FF)" )
  --test-- "byte-auto-2921"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-2922"
  --assert #"^(65)"  = ( #"a" + ( #"^(FB)" xor #"^(FF)" ))
  --test-- "byte-auto-2923"
  --assert #"^(FA)"  = ( #"^(FB)" xor #"^(01)" )
  --test-- "byte-auto-2924"
      ba-b1: #"^(FB)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-2925"
  --assert #"^(5B)"  = ( #"a" + ( #"^(FB)" xor #"^(01)" ))
  --test-- "byte-auto-2926"
  --assert #"^(F9)"  = ( #"^(FB)" xor #"^(02)" )
  --test-- "byte-auto-2927"
      ba-b1: #"^(FB)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F9)"  = ba-b3 
  --test-- "byte-auto-2928"
  --assert #"^(5A)"  = ( #"a" + ( #"^(FB)" xor #"^(02)" ))
  --test-- "byte-auto-2929"
  --assert #"^(F8)"  = ( #"^(FB)" xor #"^(03)" )
  --test-- "byte-auto-2930"
      ba-b1: #"^(FB)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(F8)"  = ba-b3 
  --test-- "byte-auto-2931"
  --assert #"^(59)"  = ( #"a" + ( #"^(FB)" xor #"^(03)" ))
  --test-- "byte-auto-2932"
  --assert #"^(FE)"  = ( #"^(FB)" xor #"^(05)" )
  --test-- "byte-auto-2933"
      ba-b1: #"^(FB)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-2934"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FB)" xor #"^(05)" ))
  --test-- "byte-auto-2935"
  --assert #"^(0B)"  = ( #"^(FB)" xor #"^(F0)" )
  --test-- "byte-auto-2936"
      ba-b1: #"^(FB)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(0B)"  = ba-b3 
  --test-- "byte-auto-2937"
  --assert #"^(6C)"  = ( #"a" + ( #"^(FB)" xor #"^(F0)" ))
  --test-- "byte-auto-2938"
  --assert #"^(06)"  = ( #"^(FB)" xor #"^(FD)" )
  --test-- "byte-auto-2939"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(06)"  = ba-b3 
  --test-- "byte-auto-2940"
  --assert #"^(67)"  = ( #"a" + ( #"^(FB)" xor #"^(FD)" ))
  --test-- "byte-auto-2941"
  --assert #"^(05)"  = ( #"^(FB)" xor #"^(FE)" )
  --test-- "byte-auto-2942"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-2943"
  --assert #"^(66)"  = ( #"a" + ( #"^(FB)" xor #"^(FE)" ))
  --test-- "byte-auto-2944"
  --assert #"^(85)"  = ( #"^(FB)" xor #"^(7E)" )
  --test-- "byte-auto-2945"
      ba-b1: #"^(FB)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(85)"  = ba-b3 
  --test-- "byte-auto-2946"
  --assert #"^(E6)"  = ( #"a" + ( #"^(FB)" xor #"^(7E)" ))
  --test-- "byte-auto-2947"
  --assert #"^(90)"  = ( #"^(FB)" xor #"^(6B)" )
  --test-- "byte-auto-2948"
      ba-b1: #"^(FB)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(90)"  = ba-b3 
  --test-- "byte-auto-2949"
  --assert #"^(F1)"  = ( #"a" + ( #"^(FB)" xor #"^(6B)" ))
  --test-- "byte-auto-2950"
  --assert #"^(00)"  = ( #"^(FB)" xor #"^(FB)" )
  --test-- "byte-auto-2951"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 xor ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2952"
  --assert #"^(61)"  = ( #"a" + ( #"^(FB)" xor #"^(FB)" ))
  --test-- "byte-auto-2953"
  --assert #"^(00)"  = ( #"^(00)" and #"^(00)" )
  --test-- "byte-auto-2954"
      ba-b1: #"^(00)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2955"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" and #"^(00)" ))
  --test-- "byte-auto-2956"
  --assert #"^(00)"  = ( #"^(00)" and #"^(FF)" )
  --test-- "byte-auto-2957"
      ba-b1: #"^(00)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2958"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" and #"^(FF)" ))
  --test-- "byte-auto-2959"
  --assert #"^(00)"  = ( #"^(00)" and #"^(01)" )
  --test-- "byte-auto-2960"
      ba-b1: #"^(00)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2961"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" and #"^(01)" ))
  --test-- "byte-auto-2962"
  --assert #"^(00)"  = ( #"^(00)" and #"^(02)" )
  --test-- "byte-auto-2963"
      ba-b1: #"^(00)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2964"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" and #"^(02)" ))
  --test-- "byte-auto-2965"
  --assert #"^(00)"  = ( #"^(00)" and #"^(03)" )
  --test-- "byte-auto-2966"
      ba-b1: #"^(00)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2967"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" and #"^(03)" ))
  --test-- "byte-auto-2968"
  --assert #"^(00)"  = ( #"^(00)" and #"^(05)" )
  --test-- "byte-auto-2969"
      ba-b1: #"^(00)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2970"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" and #"^(05)" ))
  --test-- "byte-auto-2971"
  --assert #"^(00)"  = ( #"^(00)" and #"^(F0)" )
  --test-- "byte-auto-2972"
      ba-b1: #"^(00)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2973"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" and #"^(F0)" ))
  --test-- "byte-auto-2974"
  --assert #"^(00)"  = ( #"^(00)" and #"^(FD)" )
  --test-- "byte-auto-2975"
      ba-b1: #"^(00)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2976"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" and #"^(FD)" ))
  --test-- "byte-auto-2977"
  --assert #"^(00)"  = ( #"^(00)" and #"^(FE)" )
  --test-- "byte-auto-2978"
      ba-b1: #"^(00)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2979"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" and #"^(FE)" ))
  --test-- "byte-auto-2980"
  --assert #"^(00)"  = ( #"^(00)" and #"^(7E)" )
  --test-- "byte-auto-2981"
      ba-b1: #"^(00)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2982"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" and #"^(7E)" ))
  --test-- "byte-auto-2983"
  --assert #"^(00)"  = ( #"^(00)" and #"^(6B)" )
  --test-- "byte-auto-2984"
      ba-b1: #"^(00)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2985"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" and #"^(6B)" ))
  --test-- "byte-auto-2986"
  --assert #"^(00)"  = ( #"^(00)" and #"^(FB)" )
  --test-- "byte-auto-2987"
      ba-b1: #"^(00)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2988"
  --assert #"^(61)"  = ( #"a" + ( #"^(00)" and #"^(FB)" ))
  --test-- "byte-auto-2989"
  --assert #"^(00)"  = ( #"^(FF)" and #"^(00)" )
  --test-- "byte-auto-2990"
      ba-b1: #"^(FF)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-2991"
  --assert #"^(61)"  = ( #"a" + ( #"^(FF)" and #"^(00)" ))
  --test-- "byte-auto-2992"
  --assert #"^(FF)"  = ( #"^(FF)" and #"^(FF)" )
  --test-- "byte-auto-2993"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FF)"  = ba-b3 
  --test-- "byte-auto-2994"
  --assert #"^(60)"  = ( #"a" + ( #"^(FF)" and #"^(FF)" ))
  --test-- "byte-auto-2995"
  --assert #"^(01)"  = ( #"^(FF)" and #"^(01)" )
  --test-- "byte-auto-2996"
      ba-b1: #"^(FF)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-2997"
  --assert #"^(62)"  = ( #"a" + ( #"^(FF)" and #"^(01)" ))
  --test-- "byte-auto-2998"
  --assert #"^(02)"  = ( #"^(FF)" and #"^(02)" )
  --test-- "byte-auto-2999"
      ba-b1: #"^(FF)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3000"
  --assert #"^(63)"  = ( #"a" + ( #"^(FF)" and #"^(02)" ))
  --test-- "byte-auto-3001"
  --assert #"^(03)"  = ( #"^(FF)" and #"^(03)" )
  --test-- "byte-auto-3002"
      ba-b1: #"^(FF)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-3003"
  --assert #"^(64)"  = ( #"a" + ( #"^(FF)" and #"^(03)" ))
  --test-- "byte-auto-3004"
  --assert #"^(05)"  = ( #"^(FF)" and #"^(05)" )
  --test-- "byte-auto-3005"
      ba-b1: #"^(FF)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-3006"
  --assert #"^(66)"  = ( #"a" + ( #"^(FF)" and #"^(05)" ))
  --test-- "byte-auto-3007"
  --assert #"^(F0)"  = ( #"^(FF)" and #"^(F0)" )
  --test-- "byte-auto-3008"
      ba-b1: #"^(FF)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-3009"
  --assert #"^(51)"  = ( #"a" + ( #"^(FF)" and #"^(F0)" ))
  --test-- "byte-auto-3010"
  --assert #"^(FD)"  = ( #"^(FF)" and #"^(FD)" )
  --test-- "byte-auto-3011"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-3012"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FF)" and #"^(FD)" ))
  --test-- "byte-auto-3013"
  --assert #"^(FE)"  = ( #"^(FF)" and #"^(FE)" )
  --test-- "byte-auto-3014"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-3015"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FF)" and #"^(FE)" ))
  --test-- "byte-auto-3016"
  --assert #"^(7E)"  = ( #"^(FF)" and #"^(7E)" )
  --test-- "byte-auto-3017"
      ba-b1: #"^(FF)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-3018"
  --assert #"^(DF)"  = ( #"a" + ( #"^(FF)" and #"^(7E)" ))
  --test-- "byte-auto-3019"
  --assert #"^(6B)"  = ( #"^(FF)" and #"^(6B)" )
  --test-- "byte-auto-3020"
      ba-b1: #"^(FF)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-3021"
  --assert #"^(CC)"  = ( #"a" + ( #"^(FF)" and #"^(6B)" ))
  --test-- "byte-auto-3022"
  --assert #"^(FB)"  = ( #"^(FF)" and #"^(FB)" )
  --test-- "byte-auto-3023"
      ba-b1: #"^(FF)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-3024"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FF)" and #"^(FB)" ))
  --test-- "byte-auto-3025"
  --assert #"^(00)"  = ( #"^(01)" and #"^(00)" )
  --test-- "byte-auto-3026"
      ba-b1: #"^(01)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3027"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" and #"^(00)" ))
  --test-- "byte-auto-3028"
  --assert #"^(01)"  = ( #"^(01)" and #"^(FF)" )
  --test-- "byte-auto-3029"
      ba-b1: #"^(01)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3030"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" and #"^(FF)" ))
  --test-- "byte-auto-3031"
  --assert #"^(01)"  = ( #"^(01)" and #"^(01)" )
  --test-- "byte-auto-3032"
      ba-b1: #"^(01)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3033"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" and #"^(01)" ))
  --test-- "byte-auto-3034"
  --assert #"^(00)"  = ( #"^(01)" and #"^(02)" )
  --test-- "byte-auto-3035"
      ba-b1: #"^(01)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3036"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" and #"^(02)" ))
  --test-- "byte-auto-3037"
  --assert #"^(01)"  = ( #"^(01)" and #"^(03)" )
  --test-- "byte-auto-3038"
      ba-b1: #"^(01)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3039"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" and #"^(03)" ))
  --test-- "byte-auto-3040"
  --assert #"^(01)"  = ( #"^(01)" and #"^(05)" )
  --test-- "byte-auto-3041"
      ba-b1: #"^(01)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3042"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" and #"^(05)" ))
  --test-- "byte-auto-3043"
  --assert #"^(00)"  = ( #"^(01)" and #"^(F0)" )
  --test-- "byte-auto-3044"
      ba-b1: #"^(01)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3045"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" and #"^(F0)" ))
  --test-- "byte-auto-3046"
  --assert #"^(01)"  = ( #"^(01)" and #"^(FD)" )
  --test-- "byte-auto-3047"
      ba-b1: #"^(01)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3048"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" and #"^(FD)" ))
  --test-- "byte-auto-3049"
  --assert #"^(00)"  = ( #"^(01)" and #"^(FE)" )
  --test-- "byte-auto-3050"
      ba-b1: #"^(01)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3051"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" and #"^(FE)" ))
  --test-- "byte-auto-3052"
  --assert #"^(00)"  = ( #"^(01)" and #"^(7E)" )
  --test-- "byte-auto-3053"
      ba-b1: #"^(01)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3054"
  --assert #"^(61)"  = ( #"a" + ( #"^(01)" and #"^(7E)" ))
  --test-- "byte-auto-3055"
  --assert #"^(01)"  = ( #"^(01)" and #"^(6B)" )
  --test-- "byte-auto-3056"
      ba-b1: #"^(01)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3057"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" and #"^(6B)" ))
  --test-- "byte-auto-3058"
  --assert #"^(01)"  = ( #"^(01)" and #"^(FB)" )
  --test-- "byte-auto-3059"
      ba-b1: #"^(01)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3060"
  --assert #"^(62)"  = ( #"a" + ( #"^(01)" and #"^(FB)" ))
  --test-- "byte-auto-3061"
  --assert #"^(00)"  = ( #"^(02)" and #"^(00)" )
  --test-- "byte-auto-3062"
      ba-b1: #"^(02)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3063"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" and #"^(00)" ))
  --test-- "byte-auto-3064"
  --assert #"^(02)"  = ( #"^(02)" and #"^(FF)" )
  --test-- "byte-auto-3065"
      ba-b1: #"^(02)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3066"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" and #"^(FF)" ))
  --test-- "byte-auto-3067"
  --assert #"^(00)"  = ( #"^(02)" and #"^(01)" )
  --test-- "byte-auto-3068"
      ba-b1: #"^(02)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3069"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" and #"^(01)" ))
  --test-- "byte-auto-3070"
  --assert #"^(02)"  = ( #"^(02)" and #"^(02)" )
  --test-- "byte-auto-3071"
      ba-b1: #"^(02)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3072"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" and #"^(02)" ))
  --test-- "byte-auto-3073"
  --assert #"^(02)"  = ( #"^(02)" and #"^(03)" )
  --test-- "byte-auto-3074"
      ba-b1: #"^(02)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3075"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" and #"^(03)" ))
  --test-- "byte-auto-3076"
  --assert #"^(00)"  = ( #"^(02)" and #"^(05)" )
  --test-- "byte-auto-3077"
      ba-b1: #"^(02)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3078"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" and #"^(05)" ))
  --test-- "byte-auto-3079"
  --assert #"^(00)"  = ( #"^(02)" and #"^(F0)" )
  --test-- "byte-auto-3080"
      ba-b1: #"^(02)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3081"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" and #"^(F0)" ))
  --test-- "byte-auto-3082"
  --assert #"^(00)"  = ( #"^(02)" and #"^(FD)" )
  --test-- "byte-auto-3083"
      ba-b1: #"^(02)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3084"
  --assert #"^(61)"  = ( #"a" + ( #"^(02)" and #"^(FD)" ))
  --test-- "byte-auto-3085"
  --assert #"^(02)"  = ( #"^(02)" and #"^(FE)" )
  --test-- "byte-auto-3086"
      ba-b1: #"^(02)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3087"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" and #"^(FE)" ))
  --test-- "byte-auto-3088"
  --assert #"^(02)"  = ( #"^(02)" and #"^(7E)" )
  --test-- "byte-auto-3089"
      ba-b1: #"^(02)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3090"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" and #"^(7E)" ))
  --test-- "byte-auto-3091"
  --assert #"^(02)"  = ( #"^(02)" and #"^(6B)" )
  --test-- "byte-auto-3092"
      ba-b1: #"^(02)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3093"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" and #"^(6B)" ))
  --test-- "byte-auto-3094"
  --assert #"^(02)"  = ( #"^(02)" and #"^(FB)" )
  --test-- "byte-auto-3095"
      ba-b1: #"^(02)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3096"
  --assert #"^(63)"  = ( #"a" + ( #"^(02)" and #"^(FB)" ))
  --test-- "byte-auto-3097"
  --assert #"^(00)"  = ( #"^(03)" and #"^(00)" )
  --test-- "byte-auto-3098"
      ba-b1: #"^(03)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3099"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" and #"^(00)" ))
  --test-- "byte-auto-3100"
  --assert #"^(03)"  = ( #"^(03)" and #"^(FF)" )
  --test-- "byte-auto-3101"
      ba-b1: #"^(03)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-3102"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" and #"^(FF)" ))
  --test-- "byte-auto-3103"
  --assert #"^(01)"  = ( #"^(03)" and #"^(01)" )
  --test-- "byte-auto-3104"
      ba-b1: #"^(03)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3105"
  --assert #"^(62)"  = ( #"a" + ( #"^(03)" and #"^(01)" ))
  --test-- "byte-auto-3106"
  --assert #"^(02)"  = ( #"^(03)" and #"^(02)" )
  --test-- "byte-auto-3107"
      ba-b1: #"^(03)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3108"
  --assert #"^(63)"  = ( #"a" + ( #"^(03)" and #"^(02)" ))
  --test-- "byte-auto-3109"
  --assert #"^(03)"  = ( #"^(03)" and #"^(03)" )
  --test-- "byte-auto-3110"
      ba-b1: #"^(03)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-3111"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" and #"^(03)" ))
  --test-- "byte-auto-3112"
  --assert #"^(01)"  = ( #"^(03)" and #"^(05)" )
  --test-- "byte-auto-3113"
      ba-b1: #"^(03)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3114"
  --assert #"^(62)"  = ( #"a" + ( #"^(03)" and #"^(05)" ))
  --test-- "byte-auto-3115"
  --assert #"^(00)"  = ( #"^(03)" and #"^(F0)" )
  --test-- "byte-auto-3116"
      ba-b1: #"^(03)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3117"
  --assert #"^(61)"  = ( #"a" + ( #"^(03)" and #"^(F0)" ))
  --test-- "byte-auto-3118"
  --assert #"^(01)"  = ( #"^(03)" and #"^(FD)" )
  --test-- "byte-auto-3119"
      ba-b1: #"^(03)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3120"
  --assert #"^(62)"  = ( #"a" + ( #"^(03)" and #"^(FD)" ))
  --test-- "byte-auto-3121"
  --assert #"^(02)"  = ( #"^(03)" and #"^(FE)" )
  --test-- "byte-auto-3122"
      ba-b1: #"^(03)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3123"
  --assert #"^(63)"  = ( #"a" + ( #"^(03)" and #"^(FE)" ))
  --test-- "byte-auto-3124"
  --assert #"^(02)"  = ( #"^(03)" and #"^(7E)" )
  --test-- "byte-auto-3125"
      ba-b1: #"^(03)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3126"
  --assert #"^(63)"  = ( #"a" + ( #"^(03)" and #"^(7E)" ))
  --test-- "byte-auto-3127"
  --assert #"^(03)"  = ( #"^(03)" and #"^(6B)" )
  --test-- "byte-auto-3128"
      ba-b1: #"^(03)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-3129"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" and #"^(6B)" ))
  --test-- "byte-auto-3130"
  --assert #"^(03)"  = ( #"^(03)" and #"^(FB)" )
  --test-- "byte-auto-3131"
      ba-b1: #"^(03)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-3132"
  --assert #"^(64)"  = ( #"a" + ( #"^(03)" and #"^(FB)" ))
  --test-- "byte-auto-3133"
  --assert #"^(00)"  = ( #"^(05)" and #"^(00)" )
  --test-- "byte-auto-3134"
      ba-b1: #"^(05)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3135"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" and #"^(00)" ))
  --test-- "byte-auto-3136"
  --assert #"^(05)"  = ( #"^(05)" and #"^(FF)" )
  --test-- "byte-auto-3137"
      ba-b1: #"^(05)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-3138"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" and #"^(FF)" ))
  --test-- "byte-auto-3139"
  --assert #"^(01)"  = ( #"^(05)" and #"^(01)" )
  --test-- "byte-auto-3140"
      ba-b1: #"^(05)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3141"
  --assert #"^(62)"  = ( #"a" + ( #"^(05)" and #"^(01)" ))
  --test-- "byte-auto-3142"
  --assert #"^(00)"  = ( #"^(05)" and #"^(02)" )
  --test-- "byte-auto-3143"
      ba-b1: #"^(05)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3144"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" and #"^(02)" ))
  --test-- "byte-auto-3145"
  --assert #"^(01)"  = ( #"^(05)" and #"^(03)" )
  --test-- "byte-auto-3146"
      ba-b1: #"^(05)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3147"
  --assert #"^(62)"  = ( #"a" + ( #"^(05)" and #"^(03)" ))
  --test-- "byte-auto-3148"
  --assert #"^(05)"  = ( #"^(05)" and #"^(05)" )
  --test-- "byte-auto-3149"
      ba-b1: #"^(05)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-3150"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" and #"^(05)" ))
  --test-- "byte-auto-3151"
  --assert #"^(00)"  = ( #"^(05)" and #"^(F0)" )
  --test-- "byte-auto-3152"
      ba-b1: #"^(05)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3153"
  --assert #"^(61)"  = ( #"a" + ( #"^(05)" and #"^(F0)" ))
  --test-- "byte-auto-3154"
  --assert #"^(05)"  = ( #"^(05)" and #"^(FD)" )
  --test-- "byte-auto-3155"
      ba-b1: #"^(05)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-3156"
  --assert #"^(66)"  = ( #"a" + ( #"^(05)" and #"^(FD)" ))
  --test-- "byte-auto-3157"
  --assert #"^(04)"  = ( #"^(05)" and #"^(FE)" )
  --test-- "byte-auto-3158"
      ba-b1: #"^(05)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-3159"
  --assert #"^(65)"  = ( #"a" + ( #"^(05)" and #"^(FE)" ))
  --test-- "byte-auto-3160"
  --assert #"^(04)"  = ( #"^(05)" and #"^(7E)" )
  --test-- "byte-auto-3161"
      ba-b1: #"^(05)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-3162"
  --assert #"^(65)"  = ( #"a" + ( #"^(05)" and #"^(7E)" ))
  --test-- "byte-auto-3163"
  --assert #"^(01)"  = ( #"^(05)" and #"^(6B)" )
  --test-- "byte-auto-3164"
      ba-b1: #"^(05)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3165"
  --assert #"^(62)"  = ( #"a" + ( #"^(05)" and #"^(6B)" ))
  --test-- "byte-auto-3166"
  --assert #"^(01)"  = ( #"^(05)" and #"^(FB)" )
  --test-- "byte-auto-3167"
      ba-b1: #"^(05)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3168"
  --assert #"^(62)"  = ( #"a" + ( #"^(05)" and #"^(FB)" ))
  --test-- "byte-auto-3169"
  --assert #"^(00)"  = ( #"^(F0)" and #"^(00)" )
  --test-- "byte-auto-3170"
      ba-b1: #"^(F0)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3171"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" and #"^(00)" ))
  --test-- "byte-auto-3172"
  --assert #"^(F0)"  = ( #"^(F0)" and #"^(FF)" )
  --test-- "byte-auto-3173"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-3174"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" and #"^(FF)" ))
  --test-- "byte-auto-3175"
  --assert #"^(00)"  = ( #"^(F0)" and #"^(01)" )
  --test-- "byte-auto-3176"
      ba-b1: #"^(F0)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3177"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" and #"^(01)" ))
  --test-- "byte-auto-3178"
  --assert #"^(00)"  = ( #"^(F0)" and #"^(02)" )
  --test-- "byte-auto-3179"
      ba-b1: #"^(F0)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3180"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" and #"^(02)" ))
  --test-- "byte-auto-3181"
  --assert #"^(00)"  = ( #"^(F0)" and #"^(03)" )
  --test-- "byte-auto-3182"
      ba-b1: #"^(F0)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3183"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" and #"^(03)" ))
  --test-- "byte-auto-3184"
  --assert #"^(00)"  = ( #"^(F0)" and #"^(05)" )
  --test-- "byte-auto-3185"
      ba-b1: #"^(F0)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3186"
  --assert #"^(61)"  = ( #"a" + ( #"^(F0)" and #"^(05)" ))
  --test-- "byte-auto-3187"
  --assert #"^(F0)"  = ( #"^(F0)" and #"^(F0)" )
  --test-- "byte-auto-3188"
      ba-b1: #"^(F0)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-3189"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" and #"^(F0)" ))
  --test-- "byte-auto-3190"
  --assert #"^(F0)"  = ( #"^(F0)" and #"^(FD)" )
  --test-- "byte-auto-3191"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-3192"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" and #"^(FD)" ))
  --test-- "byte-auto-3193"
  --assert #"^(F0)"  = ( #"^(F0)" and #"^(FE)" )
  --test-- "byte-auto-3194"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-3195"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" and #"^(FE)" ))
  --test-- "byte-auto-3196"
  --assert #"^(70)"  = ( #"^(F0)" and #"^(7E)" )
  --test-- "byte-auto-3197"
      ba-b1: #"^(F0)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(70)"  = ba-b3 
  --test-- "byte-auto-3198"
  --assert #"^(D1)"  = ( #"a" + ( #"^(F0)" and #"^(7E)" ))
  --test-- "byte-auto-3199"
  --assert #"^(60)"  = ( #"^(F0)" and #"^(6B)" )
  --test-- "byte-auto-3200"
      ba-b1: #"^(F0)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(60)"  = ba-b3 
  --test-- "byte-auto-3201"
  --assert #"^(C1)"  = ( #"a" + ( #"^(F0)" and #"^(6B)" ))
  --test-- "byte-auto-3202"
  --assert #"^(F0)"  = ( #"^(F0)" and #"^(FB)" )
  --test-- "byte-auto-3203"
      ba-b1: #"^(F0)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-3204"
  --assert #"^(51)"  = ( #"a" + ( #"^(F0)" and #"^(FB)" ))
  --test-- "byte-auto-3205"
  --assert #"^(00)"  = ( #"^(FD)" and #"^(00)" )
  --test-- "byte-auto-3206"
      ba-b1: #"^(FD)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3207"
  --assert #"^(61)"  = ( #"a" + ( #"^(FD)" and #"^(00)" ))
  --test-- "byte-auto-3208"
  --assert #"^(FD)"  = ( #"^(FD)" and #"^(FF)" )
  --test-- "byte-auto-3209"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-3210"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" and #"^(FF)" ))
  --test-- "byte-auto-3211"
  --assert #"^(01)"  = ( #"^(FD)" and #"^(01)" )
  --test-- "byte-auto-3212"
      ba-b1: #"^(FD)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3213"
  --assert #"^(62)"  = ( #"a" + ( #"^(FD)" and #"^(01)" ))
  --test-- "byte-auto-3214"
  --assert #"^(00)"  = ( #"^(FD)" and #"^(02)" )
  --test-- "byte-auto-3215"
      ba-b1: #"^(FD)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3216"
  --assert #"^(61)"  = ( #"a" + ( #"^(FD)" and #"^(02)" ))
  --test-- "byte-auto-3217"
  --assert #"^(01)"  = ( #"^(FD)" and #"^(03)" )
  --test-- "byte-auto-3218"
      ba-b1: #"^(FD)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3219"
  --assert #"^(62)"  = ( #"a" + ( #"^(FD)" and #"^(03)" ))
  --test-- "byte-auto-3220"
  --assert #"^(05)"  = ( #"^(FD)" and #"^(05)" )
  --test-- "byte-auto-3221"
      ba-b1: #"^(FD)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(05)"  = ba-b3 
  --test-- "byte-auto-3222"
  --assert #"^(66)"  = ( #"a" + ( #"^(FD)" and #"^(05)" ))
  --test-- "byte-auto-3223"
  --assert #"^(F0)"  = ( #"^(FD)" and #"^(F0)" )
  --test-- "byte-auto-3224"
      ba-b1: #"^(FD)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-3225"
  --assert #"^(51)"  = ( #"a" + ( #"^(FD)" and #"^(F0)" ))
  --test-- "byte-auto-3226"
  --assert #"^(FD)"  = ( #"^(FD)" and #"^(FD)" )
  --test-- "byte-auto-3227"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FD)"  = ba-b3 
  --test-- "byte-auto-3228"
  --assert #"^(5E)"  = ( #"a" + ( #"^(FD)" and #"^(FD)" ))
  --test-- "byte-auto-3229"
  --assert #"^(FC)"  = ( #"^(FD)" and #"^(FE)" )
  --test-- "byte-auto-3230"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-3231"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FD)" and #"^(FE)" ))
  --test-- "byte-auto-3232"
  --assert #"^(7C)"  = ( #"^(FD)" and #"^(7E)" )
  --test-- "byte-auto-3233"
      ba-b1: #"^(FD)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(7C)"  = ba-b3 
  --test-- "byte-auto-3234"
  --assert #"^(DD)"  = ( #"a" + ( #"^(FD)" and #"^(7E)" ))
  --test-- "byte-auto-3235"
  --assert #"^(69)"  = ( #"^(FD)" and #"^(6B)" )
  --test-- "byte-auto-3236"
      ba-b1: #"^(FD)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(69)"  = ba-b3 
  --test-- "byte-auto-3237"
  --assert #"^(CA)"  = ( #"a" + ( #"^(FD)" and #"^(6B)" ))
  --test-- "byte-auto-3238"
  --assert #"^(F9)"  = ( #"^(FD)" and #"^(FB)" )
  --test-- "byte-auto-3239"
      ba-b1: #"^(FD)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(F9)"  = ba-b3 
  --test-- "byte-auto-3240"
  --assert #"^(5A)"  = ( #"a" + ( #"^(FD)" and #"^(FB)" ))
  --test-- "byte-auto-3241"
  --assert #"^(00)"  = ( #"^(FE)" and #"^(00)" )
  --test-- "byte-auto-3242"
      ba-b1: #"^(FE)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3243"
  --assert #"^(61)"  = ( #"a" + ( #"^(FE)" and #"^(00)" ))
  --test-- "byte-auto-3244"
  --assert #"^(FE)"  = ( #"^(FE)" and #"^(FF)" )
  --test-- "byte-auto-3245"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-3246"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" and #"^(FF)" ))
  --test-- "byte-auto-3247"
  --assert #"^(00)"  = ( #"^(FE)" and #"^(01)" )
  --test-- "byte-auto-3248"
      ba-b1: #"^(FE)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3249"
  --assert #"^(61)"  = ( #"a" + ( #"^(FE)" and #"^(01)" ))
  --test-- "byte-auto-3250"
  --assert #"^(02)"  = ( #"^(FE)" and #"^(02)" )
  --test-- "byte-auto-3251"
      ba-b1: #"^(FE)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3252"
  --assert #"^(63)"  = ( #"a" + ( #"^(FE)" and #"^(02)" ))
  --test-- "byte-auto-3253"
  --assert #"^(02)"  = ( #"^(FE)" and #"^(03)" )
  --test-- "byte-auto-3254"
      ba-b1: #"^(FE)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3255"
  --assert #"^(63)"  = ( #"a" + ( #"^(FE)" and #"^(03)" ))
  --test-- "byte-auto-3256"
  --assert #"^(04)"  = ( #"^(FE)" and #"^(05)" )
  --test-- "byte-auto-3257"
      ba-b1: #"^(FE)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-3258"
  --assert #"^(65)"  = ( #"a" + ( #"^(FE)" and #"^(05)" ))
  --test-- "byte-auto-3259"
  --assert #"^(F0)"  = ( #"^(FE)" and #"^(F0)" )
  --test-- "byte-auto-3260"
      ba-b1: #"^(FE)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-3261"
  --assert #"^(51)"  = ( #"a" + ( #"^(FE)" and #"^(F0)" ))
  --test-- "byte-auto-3262"
  --assert #"^(FC)"  = ( #"^(FE)" and #"^(FD)" )
  --test-- "byte-auto-3263"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FC)"  = ba-b3 
  --test-- "byte-auto-3264"
  --assert #"^(5D)"  = ( #"a" + ( #"^(FE)" and #"^(FD)" ))
  --test-- "byte-auto-3265"
  --assert #"^(FE)"  = ( #"^(FE)" and #"^(FE)" )
  --test-- "byte-auto-3266"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FE)"  = ba-b3 
  --test-- "byte-auto-3267"
  --assert #"^(5F)"  = ( #"a" + ( #"^(FE)" and #"^(FE)" ))
  --test-- "byte-auto-3268"
  --assert #"^(7E)"  = ( #"^(FE)" and #"^(7E)" )
  --test-- "byte-auto-3269"
      ba-b1: #"^(FE)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-3270"
  --assert #"^(DF)"  = ( #"a" + ( #"^(FE)" and #"^(7E)" ))
  --test-- "byte-auto-3271"
  --assert #"^(6A)"  = ( #"^(FE)" and #"^(6B)" )
  --test-- "byte-auto-3272"
      ba-b1: #"^(FE)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(6A)"  = ba-b3 
  --test-- "byte-auto-3273"
  --assert #"^(CB)"  = ( #"a" + ( #"^(FE)" and #"^(6B)" ))
  --test-- "byte-auto-3274"
  --assert #"^(FA)"  = ( #"^(FE)" and #"^(FB)" )
  --test-- "byte-auto-3275"
      ba-b1: #"^(FE)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-3276"
  --assert #"^(5B)"  = ( #"a" + ( #"^(FE)" and #"^(FB)" ))
  --test-- "byte-auto-3277"
  --assert #"^(00)"  = ( #"^(7E)" and #"^(00)" )
  --test-- "byte-auto-3278"
      ba-b1: #"^(7E)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3279"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" and #"^(00)" ))
  --test-- "byte-auto-3280"
  --assert #"^(7E)"  = ( #"^(7E)" and #"^(FF)" )
  --test-- "byte-auto-3281"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-3282"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" and #"^(FF)" ))
  --test-- "byte-auto-3283"
  --assert #"^(00)"  = ( #"^(7E)" and #"^(01)" )
  --test-- "byte-auto-3284"
      ba-b1: #"^(7E)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3285"
  --assert #"^(61)"  = ( #"a" + ( #"^(7E)" and #"^(01)" ))
  --test-- "byte-auto-3286"
  --assert #"^(02)"  = ( #"^(7E)" and #"^(02)" )
  --test-- "byte-auto-3287"
      ba-b1: #"^(7E)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3288"
  --assert #"^(63)"  = ( #"a" + ( #"^(7E)" and #"^(02)" ))
  --test-- "byte-auto-3289"
  --assert #"^(02)"  = ( #"^(7E)" and #"^(03)" )
  --test-- "byte-auto-3290"
      ba-b1: #"^(7E)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3291"
  --assert #"^(63)"  = ( #"a" + ( #"^(7E)" and #"^(03)" ))
  --test-- "byte-auto-3292"
  --assert #"^(04)"  = ( #"^(7E)" and #"^(05)" )
  --test-- "byte-auto-3293"
      ba-b1: #"^(7E)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(04)"  = ba-b3 
  --test-- "byte-auto-3294"
  --assert #"^(65)"  = ( #"a" + ( #"^(7E)" and #"^(05)" ))
  --test-- "byte-auto-3295"
  --assert #"^(70)"  = ( #"^(7E)" and #"^(F0)" )
  --test-- "byte-auto-3296"
      ba-b1: #"^(7E)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(70)"  = ba-b3 
  --test-- "byte-auto-3297"
  --assert #"^(D1)"  = ( #"a" + ( #"^(7E)" and #"^(F0)" ))
  --test-- "byte-auto-3298"
  --assert #"^(7C)"  = ( #"^(7E)" and #"^(FD)" )
  --test-- "byte-auto-3299"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(7C)"  = ba-b3 
  --test-- "byte-auto-3300"
  --assert #"^(DD)"  = ( #"a" + ( #"^(7E)" and #"^(FD)" ))
  --test-- "byte-auto-3301"
  --assert #"^(7E)"  = ( #"^(7E)" and #"^(FE)" )
  --test-- "byte-auto-3302"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-3303"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" and #"^(FE)" ))
  --test-- "byte-auto-3304"
  --assert #"^(7E)"  = ( #"^(7E)" and #"^(7E)" )
  --test-- "byte-auto-3305"
      ba-b1: #"^(7E)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(7E)"  = ba-b3 
  --test-- "byte-auto-3306"
  --assert #"^(DF)"  = ( #"a" + ( #"^(7E)" and #"^(7E)" ))
  --test-- "byte-auto-3307"
  --assert #"^(6A)"  = ( #"^(7E)" and #"^(6B)" )
  --test-- "byte-auto-3308"
      ba-b1: #"^(7E)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(6A)"  = ba-b3 
  --test-- "byte-auto-3309"
  --assert #"^(CB)"  = ( #"a" + ( #"^(7E)" and #"^(6B)" ))
  --test-- "byte-auto-3310"
  --assert #"^(7A)"  = ( #"^(7E)" and #"^(FB)" )
  --test-- "byte-auto-3311"
      ba-b1: #"^(7E)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(7A)"  = ba-b3 
  --test-- "byte-auto-3312"
  --assert #"^(DB)"  = ( #"a" + ( #"^(7E)" and #"^(FB)" ))
  --test-- "byte-auto-3313"
  --assert #"^(00)"  = ( #"^(6B)" and #"^(00)" )
  --test-- "byte-auto-3314"
      ba-b1: #"^(6B)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3315"
  --assert #"^(61)"  = ( #"a" + ( #"^(6B)" and #"^(00)" ))
  --test-- "byte-auto-3316"
  --assert #"^(6B)"  = ( #"^(6B)" and #"^(FF)" )
  --test-- "byte-auto-3317"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-3318"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" and #"^(FF)" ))
  --test-- "byte-auto-3319"
  --assert #"^(01)"  = ( #"^(6B)" and #"^(01)" )
  --test-- "byte-auto-3320"
      ba-b1: #"^(6B)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3321"
  --assert #"^(62)"  = ( #"a" + ( #"^(6B)" and #"^(01)" ))
  --test-- "byte-auto-3322"
  --assert #"^(02)"  = ( #"^(6B)" and #"^(02)" )
  --test-- "byte-auto-3323"
      ba-b1: #"^(6B)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3324"
  --assert #"^(63)"  = ( #"a" + ( #"^(6B)" and #"^(02)" ))
  --test-- "byte-auto-3325"
  --assert #"^(03)"  = ( #"^(6B)" and #"^(03)" )
  --test-- "byte-auto-3326"
      ba-b1: #"^(6B)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-3327"
  --assert #"^(64)"  = ( #"a" + ( #"^(6B)" and #"^(03)" ))
  --test-- "byte-auto-3328"
  --assert #"^(01)"  = ( #"^(6B)" and #"^(05)" )
  --test-- "byte-auto-3329"
      ba-b1: #"^(6B)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3330"
  --assert #"^(62)"  = ( #"a" + ( #"^(6B)" and #"^(05)" ))
  --test-- "byte-auto-3331"
  --assert #"^(60)"  = ( #"^(6B)" and #"^(F0)" )
  --test-- "byte-auto-3332"
      ba-b1: #"^(6B)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(60)"  = ba-b3 
  --test-- "byte-auto-3333"
  --assert #"^(C1)"  = ( #"a" + ( #"^(6B)" and #"^(F0)" ))
  --test-- "byte-auto-3334"
  --assert #"^(69)"  = ( #"^(6B)" and #"^(FD)" )
  --test-- "byte-auto-3335"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(69)"  = ba-b3 
  --test-- "byte-auto-3336"
  --assert #"^(CA)"  = ( #"a" + ( #"^(6B)" and #"^(FD)" ))
  --test-- "byte-auto-3337"
  --assert #"^(6A)"  = ( #"^(6B)" and #"^(FE)" )
  --test-- "byte-auto-3338"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(6A)"  = ba-b3 
  --test-- "byte-auto-3339"
  --assert #"^(CB)"  = ( #"a" + ( #"^(6B)" and #"^(FE)" ))
  --test-- "byte-auto-3340"
  --assert #"^(6A)"  = ( #"^(6B)" and #"^(7E)" )
  --test-- "byte-auto-3341"
      ba-b1: #"^(6B)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(6A)"  = ba-b3 
  --test-- "byte-auto-3342"
  --assert #"^(CB)"  = ( #"a" + ( #"^(6B)" and #"^(7E)" ))
  --test-- "byte-auto-3343"
  --assert #"^(6B)"  = ( #"^(6B)" and #"^(6B)" )
  --test-- "byte-auto-3344"
      ba-b1: #"^(6B)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-3345"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" and #"^(6B)" ))
  --test-- "byte-auto-3346"
  --assert #"^(6B)"  = ( #"^(6B)" and #"^(FB)" )
  --test-- "byte-auto-3347"
      ba-b1: #"^(6B)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-3348"
  --assert #"^(CC)"  = ( #"a" + ( #"^(6B)" and #"^(FB)" ))
  --test-- "byte-auto-3349"
  --assert #"^(00)"  = ( #"^(FB)" and #"^(00)" )
  --test-- "byte-auto-3350"
      ba-b1: #"^(FB)"
      ba-b2: #"^(00)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(00)"  = ba-b3 
  --test-- "byte-auto-3351"
  --assert #"^(61)"  = ( #"a" + ( #"^(FB)" and #"^(00)" ))
  --test-- "byte-auto-3352"
  --assert #"^(FB)"  = ( #"^(FB)" and #"^(FF)" )
  --test-- "byte-auto-3353"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FF)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-3354"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" and #"^(FF)" ))
  --test-- "byte-auto-3355"
  --assert #"^(01)"  = ( #"^(FB)" and #"^(01)" )
  --test-- "byte-auto-3356"
      ba-b1: #"^(FB)"
      ba-b2: #"^(01)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3357"
  --assert #"^(62)"  = ( #"a" + ( #"^(FB)" and #"^(01)" ))
  --test-- "byte-auto-3358"
  --assert #"^(02)"  = ( #"^(FB)" and #"^(02)" )
  --test-- "byte-auto-3359"
      ba-b1: #"^(FB)"
      ba-b2: #"^(02)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(02)"  = ba-b3 
  --test-- "byte-auto-3360"
  --assert #"^(63)"  = ( #"a" + ( #"^(FB)" and #"^(02)" ))
  --test-- "byte-auto-3361"
  --assert #"^(03)"  = ( #"^(FB)" and #"^(03)" )
  --test-- "byte-auto-3362"
      ba-b1: #"^(FB)"
      ba-b2: #"^(03)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(03)"  = ba-b3 
  --test-- "byte-auto-3363"
  --assert #"^(64)"  = ( #"a" + ( #"^(FB)" and #"^(03)" ))
  --test-- "byte-auto-3364"
  --assert #"^(01)"  = ( #"^(FB)" and #"^(05)" )
  --test-- "byte-auto-3365"
      ba-b1: #"^(FB)"
      ba-b2: #"^(05)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(01)"  = ba-b3 
  --test-- "byte-auto-3366"
  --assert #"^(62)"  = ( #"a" + ( #"^(FB)" and #"^(05)" ))
  --test-- "byte-auto-3367"
  --assert #"^(F0)"  = ( #"^(FB)" and #"^(F0)" )
  --test-- "byte-auto-3368"
      ba-b1: #"^(FB)"
      ba-b2: #"^(F0)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(F0)"  = ba-b3 
  --test-- "byte-auto-3369"
  --assert #"^(51)"  = ( #"a" + ( #"^(FB)" and #"^(F0)" ))
  --test-- "byte-auto-3370"
  --assert #"^(F9)"  = ( #"^(FB)" and #"^(FD)" )
  --test-- "byte-auto-3371"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FD)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(F9)"  = ba-b3 
  --test-- "byte-auto-3372"
  --assert #"^(5A)"  = ( #"a" + ( #"^(FB)" and #"^(FD)" ))
  --test-- "byte-auto-3373"
  --assert #"^(FA)"  = ( #"^(FB)" and #"^(FE)" )
  --test-- "byte-auto-3374"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FE)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FA)"  = ba-b3 
  --test-- "byte-auto-3375"
  --assert #"^(5B)"  = ( #"a" + ( #"^(FB)" and #"^(FE)" ))
  --test-- "byte-auto-3376"
  --assert #"^(7A)"  = ( #"^(FB)" and #"^(7E)" )
  --test-- "byte-auto-3377"
      ba-b1: #"^(FB)"
      ba-b2: #"^(7E)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(7A)"  = ba-b3 
  --test-- "byte-auto-3378"
  --assert #"^(DB)"  = ( #"a" + ( #"^(FB)" and #"^(7E)" ))
  --test-- "byte-auto-3379"
  --assert #"^(6B)"  = ( #"^(FB)" and #"^(6B)" )
  --test-- "byte-auto-3380"
      ba-b1: #"^(FB)"
      ba-b2: #"^(6B)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(6B)"  = ba-b3 
  --test-- "byte-auto-3381"
  --assert #"^(CC)"  = ( #"a" + ( #"^(FB)" and #"^(6B)" ))
  --test-- "byte-auto-3382"
  --assert #"^(FB)"  = ( #"^(FB)" and #"^(FB)" )
  --test-- "byte-auto-3383"
      ba-b1: #"^(FB)"
      ba-b2: #"^(FB)"
      ba-b3:  ba-b1 and ba-b2
  --assert #"^(FB)"  = ba-b3 
  --test-- "byte-auto-3384"
  --assert #"^(5C)"  = ( #"a" + ( #"^(FB)" and #"^(FB)" ))
  --test-- "byte-auto-3385"
  --assert false  = ( #"^(00)" = #"^(FF)" )
  --test-- "byte-auto-3386"
  --assert true  = ( #"^(00)" = #"^(00)" )
  --test-- "byte-auto-3387"
  --assert false  = ( #"^(00)" = #"^(01)" )
  --test-- "byte-auto-3388"
  --assert false  = ( #"^(FF)" = #"^(FE)" )
  --test-- "byte-auto-3389"
  --assert true  = ( #"^(FF)" = #"^(FF)" )
  --test-- "byte-auto-3390"
  --assert false  = ( #"^(FF)" = #"^(00)" )
  --test-- "byte-auto-3391"
  --assert false  = ( #"^(01)" = #"^(00)" )
  --test-- "byte-auto-3392"
  --assert true  = ( #"^(01)" = #"^(01)" )
  --test-- "byte-auto-3393"
  --assert false  = ( #"^(01)" = #"^(02)" )
  --test-- "byte-auto-3394"
  --assert false  = ( #"^(02)" = #"^(01)" )
  --test-- "byte-auto-3395"
  --assert true  = ( #"^(02)" = #"^(02)" )
  --test-- "byte-auto-3396"
  --assert false  = ( #"^(02)" = #"^(03)" )
  --test-- "byte-auto-3397"
  --assert false  = ( #"^(03)" = #"^(02)" )
  --test-- "byte-auto-3398"
  --assert true  = ( #"^(03)" = #"^(03)" )
  --test-- "byte-auto-3399"
  --assert false  = ( #"^(03)" = #"^(04)" )
  --test-- "byte-auto-3400"
  --assert false  = ( #"^(05)" = #"^(04)" )
  --test-- "byte-auto-3401"
  --assert true  = ( #"^(05)" = #"^(05)" )
  --test-- "byte-auto-3402"
  --assert false  = ( #"^(05)" = #"^(06)" )
  --test-- "byte-auto-3403"
  --assert false  = ( #"^(F0)" = #"^(EF)" )
  --test-- "byte-auto-3404"
  --assert true  = ( #"^(F0)" = #"^(F0)" )
  --test-- "byte-auto-3405"
  --assert false  = ( #"^(F0)" = #"^(F1)" )
  --test-- "byte-auto-3406"
  --assert false  = ( #"^(FD)" = #"^(FC)" )
  --test-- "byte-auto-3407"
  --assert true  = ( #"^(FD)" = #"^(FD)" )
  --test-- "byte-auto-3408"
  --assert false  = ( #"^(FD)" = #"^(FE)" )
  --test-- "byte-auto-3409"
  --assert false  = ( #"^(FE)" = #"^(FD)" )
  --test-- "byte-auto-3410"
  --assert true  = ( #"^(FE)" = #"^(FE)" )
  --test-- "byte-auto-3411"
  --assert false  = ( #"^(FE)" = #"^(FF)" )
  --test-- "byte-auto-3412"
  --assert false  = ( #"^(7E)" = #"^(7D)" )
  --test-- "byte-auto-3413"
  --assert true  = ( #"^(7E)" = #"^(7E)" )
  --test-- "byte-auto-3414"
  --assert false  = ( #"^(7E)" = #"^(7F)" )
  --test-- "byte-auto-3415"
  --assert false  = ( #"^(6B)" = #"^(6A)" )
  --test-- "byte-auto-3416"
  --assert true  = ( #"^(6B)" = #"^(6B)" )
  --test-- "byte-auto-3417"
  --assert false  = ( #"^(6B)" = #"^(6C)" )
  --test-- "byte-auto-3418"
  --assert false  = ( #"^(FB)" = #"^(FA)" )
  --test-- "byte-auto-3419"
  --assert true  = ( #"^(FB)" = #"^(FB)" )
  --test-- "byte-auto-3420"
  --assert false  = ( #"^(FB)" = #"^(FC)" )
  --test-- "byte-auto-3421"
  --assert true  = ( #"^(00)" <> #"^(FF)" )
  --test-- "byte-auto-3422"
  --assert false  = ( #"^(00)" <> #"^(00)" )
  --test-- "byte-auto-3423"
  --assert true  = ( #"^(00)" <> #"^(01)" )
  --test-- "byte-auto-3424"
  --assert true  = ( #"^(FF)" <> #"^(FE)" )
  --test-- "byte-auto-3425"
  --assert false  = ( #"^(FF)" <> #"^(FF)" )
  --test-- "byte-auto-3426"
  --assert true  = ( #"^(FF)" <> #"^(00)" )
  --test-- "byte-auto-3427"
  --assert true  = ( #"^(01)" <> #"^(00)" )
  --test-- "byte-auto-3428"
  --assert false  = ( #"^(01)" <> #"^(01)" )
  --test-- "byte-auto-3429"
  --assert true  = ( #"^(01)" <> #"^(02)" )
  --test-- "byte-auto-3430"
  --assert true  = ( #"^(02)" <> #"^(01)" )
  --test-- "byte-auto-3431"
  --assert false  = ( #"^(02)" <> #"^(02)" )
  --test-- "byte-auto-3432"
  --assert true  = ( #"^(02)" <> #"^(03)" )
  --test-- "byte-auto-3433"
  --assert true  = ( #"^(03)" <> #"^(02)" )
  --test-- "byte-auto-3434"
  --assert false  = ( #"^(03)" <> #"^(03)" )
  --test-- "byte-auto-3435"
  --assert true  = ( #"^(03)" <> #"^(04)" )
  --test-- "byte-auto-3436"
  --assert true  = ( #"^(05)" <> #"^(04)" )
  --test-- "byte-auto-3437"
  --assert false  = ( #"^(05)" <> #"^(05)" )
  --test-- "byte-auto-3438"
  --assert true  = ( #"^(05)" <> #"^(06)" )
  --test-- "byte-auto-3439"
  --assert true  = ( #"^(F0)" <> #"^(EF)" )
  --test-- "byte-auto-3440"
  --assert false  = ( #"^(F0)" <> #"^(F0)" )
  --test-- "byte-auto-3441"
  --assert true  = ( #"^(F0)" <> #"^(F1)" )
  --test-- "byte-auto-3442"
  --assert true  = ( #"^(FD)" <> #"^(FC)" )
  --test-- "byte-auto-3443"
  --assert false  = ( #"^(FD)" <> #"^(FD)" )
  --test-- "byte-auto-3444"
  --assert true  = ( #"^(FD)" <> #"^(FE)" )
  --test-- "byte-auto-3445"
  --assert true  = ( #"^(FE)" <> #"^(FD)" )
  --test-- "byte-auto-3446"
  --assert false  = ( #"^(FE)" <> #"^(FE)" )
  --test-- "byte-auto-3447"
  --assert true  = ( #"^(FE)" <> #"^(FF)" )
  --test-- "byte-auto-3448"
  --assert true  = ( #"^(7E)" <> #"^(7D)" )
  --test-- "byte-auto-3449"
  --assert false  = ( #"^(7E)" <> #"^(7E)" )
  --test-- "byte-auto-3450"
  --assert true  = ( #"^(7E)" <> #"^(7F)" )
  --test-- "byte-auto-3451"
  --assert true  = ( #"^(6B)" <> #"^(6A)" )
  --test-- "byte-auto-3452"
  --assert false  = ( #"^(6B)" <> #"^(6B)" )
  --test-- "byte-auto-3453"
  --assert true  = ( #"^(6B)" <> #"^(6C)" )
  --test-- "byte-auto-3454"
  --assert true  = ( #"^(FB)" <> #"^(FA)" )
  --test-- "byte-auto-3455"
  --assert false  = ( #"^(FB)" <> #"^(FB)" )
  --test-- "byte-auto-3456"
  --assert true  = ( #"^(FB)" <> #"^(FC)" )
  --test-- "byte-auto-3457"
  --assert true  = ( #"^(00)" < #"^(FF)" )
  --test-- "byte-auto-3458"
  --assert false  = ( #"^(00)" < #"^(00)" )
  --test-- "byte-auto-3459"
  --assert true  = ( #"^(00)" < #"^(01)" )
  --test-- "byte-auto-3460"
  --assert false  = ( #"^(FF)" < #"^(FE)" )
  --test-- "byte-auto-3461"
  --assert false  = ( #"^(FF)" < #"^(FF)" )
  --test-- "byte-auto-3462"
  --assert false  = ( #"^(FF)" < #"^(00)" )
  --test-- "byte-auto-3463"
  --assert false  = ( #"^(01)" < #"^(00)" )
  --test-- "byte-auto-3464"
  --assert false  = ( #"^(01)" < #"^(01)" )
  --test-- "byte-auto-3465"
  --assert true  = ( #"^(01)" < #"^(02)" )
  --test-- "byte-auto-3466"
  --assert false  = ( #"^(02)" < #"^(01)" )
  --test-- "byte-auto-3467"
  --assert false  = ( #"^(02)" < #"^(02)" )
  --test-- "byte-auto-3468"
  --assert true  = ( #"^(02)" < #"^(03)" )
  --test-- "byte-auto-3469"
  --assert false  = ( #"^(03)" < #"^(02)" )
  --test-- "byte-auto-3470"
  --assert false  = ( #"^(03)" < #"^(03)" )
  --test-- "byte-auto-3471"
  --assert true  = ( #"^(03)" < #"^(04)" )
  --test-- "byte-auto-3472"
  --assert false  = ( #"^(05)" < #"^(04)" )
  --test-- "byte-auto-3473"
  --assert false  = ( #"^(05)" < #"^(05)" )
  --test-- "byte-auto-3474"
  --assert true  = ( #"^(05)" < #"^(06)" )
  --test-- "byte-auto-3475"
  --assert false  = ( #"^(F0)" < #"^(EF)" )
  --test-- "byte-auto-3476"
  --assert false  = ( #"^(F0)" < #"^(F0)" )
  --test-- "byte-auto-3477"
  --assert true  = ( #"^(F0)" < #"^(F1)" )
  --test-- "byte-auto-3478"
  --assert false  = ( #"^(FD)" < #"^(FC)" )
  --test-- "byte-auto-3479"
  --assert false  = ( #"^(FD)" < #"^(FD)" )
  --test-- "byte-auto-3480"
  --assert true  = ( #"^(FD)" < #"^(FE)" )
  --test-- "byte-auto-3481"
  --assert false  = ( #"^(FE)" < #"^(FD)" )
  --test-- "byte-auto-3482"
  --assert false  = ( #"^(FE)" < #"^(FE)" )
  --test-- "byte-auto-3483"
  --assert true  = ( #"^(FE)" < #"^(FF)" )
  --test-- "byte-auto-3484"
  --assert false  = ( #"^(7E)" < #"^(7D)" )
  --test-- "byte-auto-3485"
  --assert false  = ( #"^(7E)" < #"^(7E)" )
  --test-- "byte-auto-3486"
  --assert true  = ( #"^(7E)" < #"^(7F)" )
  --test-- "byte-auto-3487"
  --assert false  = ( #"^(6B)" < #"^(6A)" )
  --test-- "byte-auto-3488"
  --assert false  = ( #"^(6B)" < #"^(6B)" )
  --test-- "byte-auto-3489"
  --assert true  = ( #"^(6B)" < #"^(6C)" )
  --test-- "byte-auto-3490"
  --assert false  = ( #"^(FB)" < #"^(FA)" )
  --test-- "byte-auto-3491"
  --assert false  = ( #"^(FB)" < #"^(FB)" )
  --test-- "byte-auto-3492"
  --assert true  = ( #"^(FB)" < #"^(FC)" )
  --test-- "byte-auto-3493"
  --assert false  = ( #"^(00)" > #"^(FF)" )
  --test-- "byte-auto-3494"
  --assert false  = ( #"^(00)" > #"^(00)" )
  --test-- "byte-auto-3495"
  --assert false  = ( #"^(00)" > #"^(01)" )
  --test-- "byte-auto-3496"
  --assert true  = ( #"^(FF)" > #"^(FE)" )
  --test-- "byte-auto-3497"
  --assert false  = ( #"^(FF)" > #"^(FF)" )
  --test-- "byte-auto-3498"
  --assert true  = ( #"^(FF)" > #"^(00)" )
  --test-- "byte-auto-3499"
  --assert true  = ( #"^(01)" > #"^(00)" )
  --test-- "byte-auto-3500"
  --assert false  = ( #"^(01)" > #"^(01)" )
  --test-- "byte-auto-3501"
  --assert false  = ( #"^(01)" > #"^(02)" )
  --test-- "byte-auto-3502"
  --assert true  = ( #"^(02)" > #"^(01)" )
  --test-- "byte-auto-3503"
  --assert false  = ( #"^(02)" > #"^(02)" )
  --test-- "byte-auto-3504"
  --assert false  = ( #"^(02)" > #"^(03)" )
  --test-- "byte-auto-3505"
  --assert true  = ( #"^(03)" > #"^(02)" )
  --test-- "byte-auto-3506"
  --assert false  = ( #"^(03)" > #"^(03)" )
  --test-- "byte-auto-3507"
  --assert false  = ( #"^(03)" > #"^(04)" )
  --test-- "byte-auto-3508"
  --assert true  = ( #"^(05)" > #"^(04)" )
  --test-- "byte-auto-3509"
  --assert false  = ( #"^(05)" > #"^(05)" )
  --test-- "byte-auto-3510"
  --assert false  = ( #"^(05)" > #"^(06)" )
  --test-- "byte-auto-3511"
  --assert true  = ( #"^(F0)" > #"^(EF)" )
  --test-- "byte-auto-3512"
  --assert false  = ( #"^(F0)" > #"^(F0)" )
  --test-- "byte-auto-3513"
  --assert false  = ( #"^(F0)" > #"^(F1)" )
  --test-- "byte-auto-3514"
  --assert true  = ( #"^(FD)" > #"^(FC)" )
  --test-- "byte-auto-3515"
  --assert false  = ( #"^(FD)" > #"^(FD)" )
  --test-- "byte-auto-3516"
  --assert false  = ( #"^(FD)" > #"^(FE)" )
  --test-- "byte-auto-3517"
  --assert true  = ( #"^(FE)" > #"^(FD)" )
  --test-- "byte-auto-3518"
  --assert false  = ( #"^(FE)" > #"^(FE)" )
  --test-- "byte-auto-3519"
  --assert false  = ( #"^(FE)" > #"^(FF)" )
  --test-- "byte-auto-3520"
  --assert true  = ( #"^(7E)" > #"^(7D)" )
  --test-- "byte-auto-3521"
  --assert false  = ( #"^(7E)" > #"^(7E)" )
  --test-- "byte-auto-3522"
  --assert false  = ( #"^(7E)" > #"^(7F)" )
  --test-- "byte-auto-3523"
  --assert true  = ( #"^(6B)" > #"^(6A)" )
  --test-- "byte-auto-3524"
  --assert false  = ( #"^(6B)" > #"^(6B)" )
  --test-- "byte-auto-3525"
  --assert false  = ( #"^(6B)" > #"^(6C)" )
  --test-- "byte-auto-3526"
  --assert true  = ( #"^(FB)" > #"^(FA)" )
  --test-- "byte-auto-3527"
  --assert false  = ( #"^(FB)" > #"^(FB)" )
  --test-- "byte-auto-3528"
  --assert false  = ( #"^(FB)" > #"^(FC)" )
  --test-- "byte-auto-3529"
  --assert false  = ( #"^(00)" >= #"^(FF)" )
  --test-- "byte-auto-3530"
  --assert true  = ( #"^(00)" >= #"^(00)" )
  --test-- "byte-auto-3531"
  --assert false  = ( #"^(00)" >= #"^(01)" )
  --test-- "byte-auto-3532"
  --assert true  = ( #"^(FF)" >= #"^(FE)" )
  --test-- "byte-auto-3533"
  --assert true  = ( #"^(FF)" >= #"^(FF)" )
  --test-- "byte-auto-3534"
  --assert true  = ( #"^(FF)" >= #"^(00)" )
  --test-- "byte-auto-3535"
  --assert true  = ( #"^(01)" >= #"^(00)" )
  --test-- "byte-auto-3536"
  --assert true  = ( #"^(01)" >= #"^(01)" )
  --test-- "byte-auto-3537"
  --assert false  = ( #"^(01)" >= #"^(02)" )
  --test-- "byte-auto-3538"
  --assert true  = ( #"^(02)" >= #"^(01)" )
  --test-- "byte-auto-3539"
  --assert true  = ( #"^(02)" >= #"^(02)" )
  --test-- "byte-auto-3540"
  --assert false  = ( #"^(02)" >= #"^(03)" )
  --test-- "byte-auto-3541"
  --assert true  = ( #"^(03)" >= #"^(02)" )
  --test-- "byte-auto-3542"
  --assert true  = ( #"^(03)" >= #"^(03)" )
  --test-- "byte-auto-3543"
  --assert false  = ( #"^(03)" >= #"^(04)" )
  --test-- "byte-auto-3544"
  --assert true  = ( #"^(05)" >= #"^(04)" )
  --test-- "byte-auto-3545"
  --assert true  = ( #"^(05)" >= #"^(05)" )
  --test-- "byte-auto-3546"
  --assert false  = ( #"^(05)" >= #"^(06)" )
  --test-- "byte-auto-3547"
  --assert true  = ( #"^(F0)" >= #"^(EF)" )
  --test-- "byte-auto-3548"
  --assert true  = ( #"^(F0)" >= #"^(F0)" )
  --test-- "byte-auto-3549"
  --assert false  = ( #"^(F0)" >= #"^(F1)" )
  --test-- "byte-auto-3550"
  --assert true  = ( #"^(FD)" >= #"^(FC)" )
  --test-- "byte-auto-3551"
  --assert true  = ( #"^(FD)" >= #"^(FD)" )
  --test-- "byte-auto-3552"
  --assert false  = ( #"^(FD)" >= #"^(FE)" )
  --test-- "byte-auto-3553"
  --assert true  = ( #"^(FE)" >= #"^(FD)" )
  --test-- "byte-auto-3554"
  --assert true  = ( #"^(FE)" >= #"^(FE)" )
  --test-- "byte-auto-3555"
  --assert false  = ( #"^(FE)" >= #"^(FF)" )
  --test-- "byte-auto-3556"
  --assert true  = ( #"^(7E)" >= #"^(7D)" )
  --test-- "byte-auto-3557"
  --assert true  = ( #"^(7E)" >= #"^(7E)" )
  --test-- "byte-auto-3558"
  --assert false  = ( #"^(7E)" >= #"^(7F)" )
  --test-- "byte-auto-3559"
  --assert true  = ( #"^(6B)" >= #"^(6A)" )
  --test-- "byte-auto-3560"
  --assert true  = ( #"^(6B)" >= #"^(6B)" )
  --test-- "byte-auto-3561"
  --assert false  = ( #"^(6B)" >= #"^(6C)" )
  --test-- "byte-auto-3562"
  --assert true  = ( #"^(FB)" >= #"^(FA)" )
  --test-- "byte-auto-3563"
  --assert true  = ( #"^(FB)" >= #"^(FB)" )
  --test-- "byte-auto-3564"
  --assert false  = ( #"^(FB)" >= #"^(FC)" )
  --test-- "byte-auto-3565"
  --assert false  = ( #"^(00)" = #"^(FF)" )
  --test-- "byte-auto-3566"
  --assert true  = ( #"^(00)" = #"^(00)" )
  --test-- "byte-auto-3567"
  --assert false  = ( #"^(00)" = #"^(01)" )
  --test-- "byte-auto-3568"
  --assert false  = ( #"^(FF)" = #"^(FE)" )
  --test-- "byte-auto-3569"
  --assert true  = ( #"^(FF)" = #"^(FF)" )
  --test-- "byte-auto-3570"
  --assert false  = ( #"^(FF)" = #"^(00)" )
  --test-- "byte-auto-3571"
  --assert false  = ( #"^(01)" = #"^(00)" )
  --test-- "byte-auto-3572"
  --assert true  = ( #"^(01)" = #"^(01)" )
  --test-- "byte-auto-3573"
  --assert false  = ( #"^(01)" = #"^(02)" )
  --test-- "byte-auto-3574"
  --assert false  = ( #"^(02)" = #"^(01)" )
  --test-- "byte-auto-3575"
  --assert true  = ( #"^(02)" = #"^(02)" )
  --test-- "byte-auto-3576"
  --assert false  = ( #"^(02)" = #"^(03)" )
  --test-- "byte-auto-3577"
  --assert false  = ( #"^(03)" = #"^(02)" )
  --test-- "byte-auto-3578"
  --assert true  = ( #"^(03)" = #"^(03)" )
  --test-- "byte-auto-3579"
  --assert false  = ( #"^(03)" = #"^(04)" )
  --test-- "byte-auto-3580"
  --assert false  = ( #"^(05)" = #"^(04)" )
  --test-- "byte-auto-3581"
  --assert true  = ( #"^(05)" = #"^(05)" )
  --test-- "byte-auto-3582"
  --assert false  = ( #"^(05)" = #"^(06)" )
  --test-- "byte-auto-3583"
  --assert false  = ( #"^(F0)" = #"^(EF)" )
  --test-- "byte-auto-3584"
  --assert true  = ( #"^(F0)" = #"^(F0)" )
  --test-- "byte-auto-3585"
  --assert false  = ( #"^(F0)" = #"^(F1)" )
  --test-- "byte-auto-3586"
  --assert false  = ( #"^(FD)" = #"^(FC)" )
  --test-- "byte-auto-3587"
  --assert true  = ( #"^(FD)" = #"^(FD)" )
  --test-- "byte-auto-3588"
  --assert false  = ( #"^(FD)" = #"^(FE)" )
  --test-- "byte-auto-3589"
  --assert false  = ( #"^(FE)" = #"^(FD)" )
  --test-- "byte-auto-3590"
  --assert true  = ( #"^(FE)" = #"^(FE)" )
  --test-- "byte-auto-3591"
  --assert false  = ( #"^(FE)" = #"^(FF)" )
  --test-- "byte-auto-3592"
  --assert false  = ( #"^(7E)" = #"^(7D)" )
  --test-- "byte-auto-3593"
  --assert true  = ( #"^(7E)" = #"^(7E)" )
  --test-- "byte-auto-3594"
  --assert false  = ( #"^(7E)" = #"^(7F)" )
  --test-- "byte-auto-3595"
  --assert false  = ( #"^(6B)" = #"^(6A)" )
  --test-- "byte-auto-3596"
  --assert true  = ( #"^(6B)" = #"^(6B)" )
  --test-- "byte-auto-3597"
  --assert false  = ( #"^(6B)" = #"^(6C)" )
  --test-- "byte-auto-3598"
  --assert false  = ( #"^(FB)" = #"^(FA)" )
  --test-- "byte-auto-3599"
  --assert true  = ( #"^(FB)" = #"^(FB)" )
  --test-- "byte-auto-3600"
  --assert false  = ( #"^(FB)" = #"^(FC)" )
  --test-- "byte-auto-3601"
  --assert true  = ( #"^(00)" < #"^(FF)" )
  --test-- "byte-auto-3602"
  --assert false  = ( #"^(00)" < #"^(00)" )
  --test-- "byte-auto-3603"
  --assert true  = ( #"^(00)" < #"^(01)" )
  --test-- "byte-auto-3604"
  --assert false  = ( #"^(FF)" < #"^(FE)" )
  --test-- "byte-auto-3605"
  --assert false  = ( #"^(FF)" < #"^(FF)" )
  --test-- "byte-auto-3606"
  --assert false  = ( #"^(FF)" < #"^(00)" )
  --test-- "byte-auto-3607"
  --assert false  = ( #"^(01)" < #"^(00)" )
  --test-- "byte-auto-3608"
  --assert false  = ( #"^(01)" < #"^(01)" )
  --test-- "byte-auto-3609"
  --assert true  = ( #"^(01)" < #"^(02)" )
  --test-- "byte-auto-3610"
  --assert false  = ( #"^(02)" < #"^(01)" )
  --test-- "byte-auto-3611"
  --assert false  = ( #"^(02)" < #"^(02)" )
  --test-- "byte-auto-3612"
  --assert true  = ( #"^(02)" < #"^(03)" )
  --test-- "byte-auto-3613"
  --assert false  = ( #"^(03)" < #"^(02)" )
  --test-- "byte-auto-3614"
  --assert false  = ( #"^(03)" < #"^(03)" )
  --test-- "byte-auto-3615"
  --assert true  = ( #"^(03)" < #"^(04)" )
  --test-- "byte-auto-3616"
  --assert false  = ( #"^(05)" < #"^(04)" )
  --test-- "byte-auto-3617"
  --assert false  = ( #"^(05)" < #"^(05)" )
  --test-- "byte-auto-3618"
  --assert true  = ( #"^(05)" < #"^(06)" )
  --test-- "byte-auto-3619"
  --assert false  = ( #"^(F0)" < #"^(EF)" )
  --test-- "byte-auto-3620"
  --assert false  = ( #"^(F0)" < #"^(F0)" )
  --test-- "byte-auto-3621"
  --assert true  = ( #"^(F0)" < #"^(F1)" )
  --test-- "byte-auto-3622"
  --assert false  = ( #"^(FD)" < #"^(FC)" )
  --test-- "byte-auto-3623"
  --assert false  = ( #"^(FD)" < #"^(FD)" )
  --test-- "byte-auto-3624"
  --assert true  = ( #"^(FD)" < #"^(FE)" )
  --test-- "byte-auto-3625"
  --assert false  = ( #"^(FE)" < #"^(FD)" )
  --test-- "byte-auto-3626"
  --assert false  = ( #"^(FE)" < #"^(FE)" )
  --test-- "byte-auto-3627"
  --assert true  = ( #"^(FE)" < #"^(FF)" )
  --test-- "byte-auto-3628"
  --assert false  = ( #"^(7E)" < #"^(7D)" )
  --test-- "byte-auto-3629"
  --assert false  = ( #"^(7E)" < #"^(7E)" )
  --test-- "byte-auto-3630"
  --assert true  = ( #"^(7E)" < #"^(7F)" )
  --test-- "byte-auto-3631"
  --assert false  = ( #"^(6B)" < #"^(6A)" )
  --test-- "byte-auto-3632"
  --assert false  = ( #"^(6B)" < #"^(6B)" )
  --test-- "byte-auto-3633"
  --assert true  = ( #"^(6B)" < #"^(6C)" )
  --test-- "byte-auto-3634"
  --assert false  = ( #"^(FB)" < #"^(FA)" )
  --test-- "byte-auto-3635"
  --assert false  = ( #"^(FB)" < #"^(FB)" )
  --test-- "byte-auto-3636"
  --assert true  = ( #"^(FB)" < #"^(FC)" )

===end-group===

~~~end-file~~~
