Red/System [
	Title:   "Red/System datatype casting test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %cast-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "cast"

===start-group=== "cast from byte!"

	--test-- "byte-cast-1"
	--assert 65 = as integer! #"A"
	
	--test-- "byte-cast-2"
		cast-b: #"A"
		cast-i: 65
		--assert cast-i = as integer! cast-b
	
	--test-- "byte-cast-3"
		--assert false = as logic! #"^(00)"

	--test-- "byte-cast-4"
		cast-b: #"^(00)"
		l: false
		--assert l = as logic! cast-b

	--test-- "byte-cast-5"
		--assert true = as logic! #"A"
	
	--test-- "byte-cast-6"
		  cast-b: #"A"
		  l: true
		  --assert l = as logic! cast-b
	
	--test-- "byte-cast-7"
		--assert true = as logic! #"^(FF)"

	--test-- "byte-cast-8"
		  cast-b: #"^(FF)"
		  l: true
		  --assert l = as logic! cast-b
	
	--test-- "byte-cast-9"							;-- issue #158
		  a: as-byte 10h
		  b: as-byte 80h
	  --assert 10h = as-integer a
	
	--test-- "byte-cast-10"							;-- issue #159
		  a: as-byte 10h
		  b: as-byte 80h
		  c: as-integer a
		  --assert 10h = c
	
	--test-- "byte-cast-11"							;-- issue #160
		  a: as-byte 1
		  b: as-byte 2
		  --assert (as byte-ptr! (as-integer a) * 2) = (as byte-ptr! 2)
		  --assert (as byte-ptr! (as-integer a) << 2) = (as byte-ptr! 4)
	  
	--test-- "byte-cast-12"							;-- issue #161
		  a: as-byte 1
		  b: as-byte 2
		  c: (as-integer b) << 16 or as-integer a
		  --assert 00020001h = c
	  
	--test-- "byte-cast-13"							;-- issue #162
		sb: declare struct! [
			a   [byte!]
			b   [byte!]
		]
		sb/a: as-byte 0
		sb/b: as-byte 1
		--assert not as-logic sb/a
	  
	--test-- "byte-cast-13"							;-- issue #150
		s!: alias struct! [
			a   [byte!]
			b   [byte!]
			c   [byte!]
			d   [byte!]
		]
		t: declare s!
		t/a: as-byte 1
		t/b: as-byte 1
		t/c: as-byte 0
		t/d: as-byte 0
		h: as-integer t/a
		--assert h = 1
	 
	--test-- "byte-cast-14"              ;-- issue 317
		bc14-a: as byte! 1
		bc14-b: as byte! 2
		bc14-c: as byte! 3
		bc14-d: as byte! 4
		bc14-e: as byte! 5
		bc14-a: as byte! 0
		--assert #"^(00)" = bc14-a
		--assert #"^(02)" = bc14-b
		--assert #"^(03)" = bc14-c
		--assert #"^(04)" = bc14-d
		--assert #"^(05)" = bc14-e
	
===end-group===

===start-group=== "cast from integer!"

	--test-- "int-cast-1"
		--assert #"^(00)" = as byte! 0

	--test-- "int-cast-2"
		i: 0
		cast-test-b: #"^(00)"
		--assert cast-test-b = as byte! i

	--test-- "int-cast-3"
		--assert #"^(01)" = as byte! 1
	
	--test-- "int-cast-4"
		i: 1
		cast-test-b: #"^(01)"
		--assert cast-test-b = as byte! i
		
	--test-- "int-cast-5"
		--assert #"^(FF)" = as byte! 255
	
	--test-- "int-cast-6"
		i: 255
		cast-test-b: #"^(FF)"
		--assert cast-test-b = as byte! i
	
	--test-- "int-cast-7"
		--assert #"^(00)" = as byte! 256
	
	--test-- "int-cast-8"
		i: 256
		cast-test-b: #"^(00)"
		--assert cast-test-b = as byte! i
	
	--test-- "int-cast-9"
	--assert false = as logic! 0
	
	--test-- "int-cast-10"
		i: 0
		l: false
		--assert l = as logic! i
	
	--test-- "int-cast-11"
		--assert true = as logic! FFFFFFFFh
	
	--test-- "int-cast-12"
		i: FFFFFFFFh
		l: true
		--assert l = as logic! i
	
	--test-- "int-cast-13"
		--assert true = as logic! 1
	
	--test-- "int-cast-14"
		i: 1
		l: true
		--assert l = as logic! i
	
	--test-- "int-cast-15"
		cs: "Hello"
		cs2: ""
		i: as integer! cs
		i: i + 1
		cs2: as c-string! i
		--assert cs2/1 = #"e"
		--assert 4 = length? cs2
	
	--test-- "int-cast-16"           ;; This test assumes 32-bit target
		i: 1
		p: declare pointer! [integer!]
		p: as [pointer! [integer!]] i
		p: p + 1
		i2: as integer! p
		--assert i2 = 5
	
	--test-- "int-cast-17"           ;; This test assumes 32-bit target
		i: 1
		p-int-cast-17: as [pointer! [integer!]] i
		p-int-cast-17: p-int-cast-17 + 1
		i2: as integer! p-int-cast-17
		--assert i2 = 5
	
	--test-- "int-cast-18"            
		i: 1
		s: declare struct! [
			a [integer!]
			b [integer!]
		]
		s: as [struct! [a [integer!] b [integer!]]] i
		s: s + 1
		i2: as integer! s
		--assert i2 = 9
	
	--test-- "int-cast-19"
		ic19-logic: either as-logic 0 [
			false
		][
			true
		]
		--assert ic19-logic
	
	--test-- "int-cast-20"
		ic20-dummy: func [return: [integer!]][0]
		ic20-logic: either as-logic ic20-dummy [
			false
		][
			true
		]
		--assert ic20-logic

	--test-- "int-cast-30"
		--assertf~= 1.0 as float! 1 1E-13
	
	--test-- "int-cast-31"
		f: as float! 2
		--assert f = 2.0

	--test-- "int-cast-32"
		to-fl-32: func [n [integer!] return: [float!]][as float! n]
		--assert 42.0 = to-fl-32 42

	--test-- "int-cast-33"
		to-fl-33: func [n [integer!] return: [float!] /local f][f: as float! n f]
		--assert 123.0 = to-fl-33 123

	--test-- "int-cast-34"
		i: 42
		--assert 42.0 = to-fl-32 i

	--test-- "int-cast-35"
		i: 123
		--assert 123.0 = to-fl-33 i

	--test-- "int-cast-36"
		to-fl-36: func [n [integer!] return: [integer!]][n]
		--assert 456.0 = as float! to-fl-36 456

	--test-- "int-cast-37"
		f: as float! to-fl-36 789
		--assert f = 789.0


	--test-- "int-cast-40"
		--assertf32~= 1.0 as float32! 1 1E-13
	
	--test-- "int-cast-41"
		f32: as float32! 2
		--assert f32 = as float32! 2.0

	--test-- "int-cast-42"
		to-fl-42: func [n [integer!] return: [float32!]][as float32! n]
		--assert (as float32! 42.0) = to-fl-42 42

	--test-- "int-cast-43"
		to-fl-43: func [n [integer!] return: [float32!] /local f][f: as float32! n f]
		--assert (as float32! 123.0) = to-fl-43 123

	--test-- "int-cast-44"
		i: 42
		--assert (as float32! 42.0) = to-fl-42 i

	--test-- "int-cast-45"
		i: 123
		--assert (as float32! 123.0) = to-fl-43 i

	--test-- "int-cast-46"
		to-fl-46: func [n [integer!] return: [integer!]][n]
		--assert (as float32! 456.0) = as float32! to-fl-36 456

	--test-- "int-cast-47"
		f32: as float32! to-fl-36 789
		--assert f32 = as float32! 789.0

	--test-- "int-cast-50"
		h: 5
		m: 6
		time50: context [nano: 1E-9]
		--assert 18000.0 = (3600.0 * as-float h)

	--test-- "int-cast-51"
		--assert 18000.0 = ((as-float h) * 3600.0)

	--test-- "int-cast-52"
		--assert 18360.0 = ((as-float h) * 3600.0 + ((as-float m) * 60.0))

	--test-- "int-cast-53"
		--assertf~= 1.836E13 (((as-float h) * 3600.0 + ((as-float m) * 60.0) / time50/nano)) 1E-12

	--test-- "int-cast-54"
		bar1: func [h [int-ptr!] f [float32!]][	--assert f = as float32! 3.0 ]
		modes: declare struct! [pen-width [integer!]]
		modes/pen-width: 3
		
		--assertf32~= (as float32! 3.0) as float32! modes/pen-width 1E-6
		bar1 null as float32! modes/pen-width

	--test-- "int-cast-55"
		rc: declare struct! [x [float32!] y [float32!]]
		i: 450
		rc/x: as float32! i
		rc/y: as float32! i + 150
		--assertf32~= (as float32! 450.0) rc/x 1E-6
		--assertf32~= (as float32! 600.0) rc/y 1E-6

	--test-- "int-cast-56"
		r: as float32! 1.0
		angle: declare struct! [value [integer!]]
		angle/value: 90
		ab: r * as float32! angle/value
		--assert ab = as float32! 90.0
		ab: (as float32! 1.0) * as float32! angle/value
		--assert ab = as float32! 90.0
		ab: as float32! (as-float angle/value) * 3.14 / 180.0
		--assert ab = as float32! 1.57

===end-group===

===start-group=== "cast from float!"

	--test-- "fl-cast-1"
		--assert 1 = as integer! 1.0

	--test-- "fl-cast-2"
		g: 2.0
		--assert 2 = as integer! g

	--test-- "fl-cast-3"
		c: as integer! 3.0
		--assert c = 3

	--test-- "fl-cast-4"
		foo33: func [f [float!] return: [integer!]][as integer! f]
		--assert 42 = foo33 42.13

	--test-- "fl-cast-5"
		foo34: func [f [float!] return: [integer!] /local n][n: as integer! f n]
		--assert 123 = foo34 123.8

	--test-- "fl-cast-6"
		c: foo33 42.13
		--assert c = 42

	--test-- "fl-cast-7"
		c: foo34 123.8
		--assert c = 123

	--test-- "fl-cast-8"
		foo37: func [f [float!] return: [float!]][f]
		c: as integer! foo37 456.7
		--assert c = 456

	--test-- "fl-cast-9"
		c: as integer! foo37 789.0
		--assert c = 789

===end-group===


===start-group=== "cast from float32!"

	--test-- "fl32-cast-1"
		f32: as float32! 1.0
		--assert 1 = as integer! f32

	--test-- "fl32-cast-2"
		f32: as float32! 2.0
		--assert 2 = as integer! f32

	--test-- "fl32-cast-3"
		f32: as float32! 3.0
		c: as integer! f32
		--assert c = 3

	--test-- "fl32-cast-4"
		foo43: func [f [float32!] return: [integer!]][as integer! f]
		--assert 42 = foo43 as float32! 42.13

	--test-- "fl32-cast-5"
		foo44: func [f [float32!] return: [integer!] /local n][n: as integer! f n]
		--assert 123 = foo44 as float32! 123.8

	--test-- "fl32-cast-6"
		c: foo43 as float32! 42.13
		--assert c = 42

	--test-- "fl32-cast-7"
		c: foo44 as float32! 123.8
		--assert c = 123

	--test-- "fl32-cast-8"
		foo47: func [f [float32!] return: [float32!]][f]
		c: as integer! foo47 as float32! 456.7
		--assert c = 456

	--test-- "fl32-cast-9"
		c: as integer! foo47 as float32! 789.0
		--assert c = 789

===end-group===

===start-group=== "cast from logic!"
  
	--test-- "logic-cast-1"
		--assert #"^(01)" = as byte! true 
  
	--test-- "logic-cast-2"
		cast-test-b: #"^(01)"
		l: true
		--assert cast-test-b = as byte! l
 
	--test-- "logic-cast-3"
		--assert #"^(00)" = as byte! false

	--test-- "logic-cast-4"
		cast-test-b: #"^(00)"
		l: false
		--assert cast-test-b = as byte! l
  
	--test-- "logic-cast-5"
		--assert 1 = as integer! true 

	--test-- "logic-cast-6"
		i: 1
		l: true
		--assert i = as integer! l
  
	--test-- "logic-cast-7"
		--assert 0 = as integer! false

	--test-- "logic-cast-8"
		i: 0
		l: false
		--assert i = as integer! l
  
===end-group===

===start-group=== "cast c-string! tests"
  
	--test-- "c-string-cast-1"
		csc1-str: "Hello, Nenad"
		i: 0
		i: as integer! csc1-str
		i: i + 7
		csc1-str: as c-string! i
		--assert csc1-str/1 = #"N"
		--assert csc1-str/2 = #"e"
		--assert csc1-str/3 = #"n"
		--assert csc1-str/4 = #"a"
		--assert csc1-str/5 = #"d"
		
		--test-- "c-string-cast-2"
			--assert true = as logic! ""

	--test-- "c-string-cast-3"
		csc3-str: ""
		--assert true = as logic! csc3-str
  
	--test-- "c-string-cast-4"
		--assert true = as logic! "Any old iron, any old iron"
  
	--test-- "c-string-cast-5"
		csc5-str: "Why not?"
		--assert true = as logic! csc5-str
  
	--test-- "c-string-cast-6"
		csc6-str: "Tour de France"
		csc6-p: declare pointer! [integer!]
		csc6-p: as [pointer! [integer!]] csc6-str
		csc6-p: csc6-p + 2
		csc6-str2: as c-string! csc6-p
		--assert csc6-str2/1 = #"F"
		--assert csc6-str2/2 = #"r"
		--assert csc6-str2/3 = #"a"
		--assert csc6-str2/4 = #"n"
		--assert csc6-str2/5 = #"c"
		--assert csc6-str2/6 = #"e"
  
	--test-- "C-string-cast-7"
		csc7-struct: declare struct! [
			c1 [byte!]
			c2 [byte!]
			c3 [byte!]
			c4 [byte!]
			c5 [byte!]
		]
		csc7-str: "Peter"
		csc7-struct: as [struct! [
			c1 [byte!] c2 [byte!] c3 [byte!] c4 [byte!] c5 [byte!]
		]] csc7-str
		--assert csc7-struct/c1 = #"P"
		--assert csc7-struct/c2 = #"e"
		--assert csc7-struct/c3 = #"t"
		--assert csc7-struct/c4 = #"e"
		--assert csc7-struct/c5 = #"r"
		
	--test-- "C-string-cast-8"
		csc8-p: declare byte-ptr!
		csc8-p: null
		csc8-s: as c-string! csc8-p
		--assert false = as logic! csc8-s
  
===end-group===

===start-group=== "cast from pointer!"

	--test-- "csp-1"
		csp1-p: declare pointer! [integer!]
		csp1-p: as [pointer! [integer!]] 256
		i: 0
		i: as integer! csp1-p
		--assert i = 256

	--test-- "csp-2"
		csp2-p: declare pointer! [integer!]
		csp2-p: as [pointer! [integer!]] 0
		--assert false = as logic! csp2-p
 
	--test-- "csp-3"
		csp3-p: declare pointer! [integer!]
		csp3-p: as [pointer! [integer!]] 1
		--assert true = as logic! csp3-p
  
	--test-- "csp-4"
		csp4-p: declare pointer! [integer!]
		csp4-p: as [pointer! [integer!]] FFFFFFFFh
		--assert true = as logic! csp4-p
  
	--test-- "csp-5"
		csp5-p: declare pointer! [integer!]
		csp5-p: as [pointer! [integer!]] 7FFFFFFFh
		--assert true = as logic! csp5-p
  
  ;; No test for pointer! to c-string! as it would simply
  ;;  duplicate the one of c-string! to pointer!
  
	--test-- "csp-6"
		csp6-p: declare pointer! [integer!]
		csp6-s: declare struct! [
			a [integer!]
			b [integer!]
		]
		csp6-s/a: 1
		csp6-s/b: 2
		csp6-p: as [pointer! [integer!]] csp6-s
		--assert csp6-p/value = 1
		csp6-p: csp6-p + 1
		--assert csp6-p/value = 2
		csp6-p: csp6-p - 1
		csp6-s: as [struct! [a [integer!] b [integer!]]] csp6-p
		--assert csp6-s/a = 1
		csp6-p: csp6-p + 1
		csp6-s: as [struct! [a [integer!] b [integer!]]] csp6-p
		--assert csp6-s/a = 2
  
===end-group===

===start-group=== "cast from struct!" 
    
  ;; no test for cast to integer as it would simply
  ;;  duplicate the test from integer! to struct!
   
	--test-- "cfstruc-1"
		cfs1-struct: declare struct! [
			a [integer!]
			b [integer!]
		]
		cfs1-struct: as [struct! [a [integer!] b [integer!]]] 0
		--assert false = as logic! cfs1-struct

	--test-- "cfstruc-2"
		cfs2-struct: declare struct! [
			a [integer!]
			b [integer!]
		]
		--assert true = as logic! cfs2-struct
  
  ;; no test for cast to c-string! as it would simply
  ;;  duplicate the test from c-string! to struct!
  
  ;; no test for cast to pointer! as it would simply
  ;;  duplicate the test from pointer! to struct!

===end-group===

===start-group=== "byte-integer-cast"

	--test-- "bic-1"
		bic-a: as-byte 1
		--assert 1 = as-integer bic-a
  
	--test-- "bic-2"
		bic-a: as-byte 1
		--assert 65536 = ((as-integer bic-a) << 16)
  
	--test-- "bic-3"
		bic-a: as-byte 2
		--assert 131072 = ((as-integer bic-a) << 16)
  
	--test-- "bic-4"
		bic-a: #"^(01)"
		--assert 65537 = (65536 or (as-integer bic-a))
  
	--test-- "bic-5"
		bic-a: #"^(01)"
		bic-b: #"^(02)"
		--assert 131073 = ((as-integer bic-b) << 16 or as-integer bic-a)
  
	--test-- "bic-6"
		bic-a: #"^(01)"
		bic-b: #"^(02)"
		--assert 131073 = ((as-integer bic-b) << 16 or as-integer bic-a)
  
	--test-- "bic-7"
		bic-a: #"^(01)"
		bic-b: #"^(02)"
		--assert (as byte-ptr! 131073) = as byte-ptr! ((as-integer bic-b) << 16 or as-integer bic-a)
  
	--test-- "bic-8"
		bic-a: as-byte 1
		bic-b: as-byte 2
		--assert 131073 = ((as-integer bic-b) << 16 or as-integer bic-a)
  
	--test-- "bic-9"
		bic-a: as-byte 1
		bic-b: as-byte 2
		--assert (as byte-ptr! 131073) = as byte-ptr! ((as-integer bic-b) << 16 or as-integer bic-a)
  
	--test-- "bic-10"
		bic-s: declare struct! [
			bic-a [byte!]
			bic-b [byte!]
			bic-c [integer!]
			bic-d [byte!]
			bic-e [byte!]
			bic-f [integer!]
		]
		bic-s/bic-a: as-byte 0
		bic-s/bic-b: as-byte 1
		bic-s/bic-c: 2
		bic-s/bic-d: as-byte 3
		bic-s/bic-e: as-byte 255
		bic-s/bic-f: 255
		--assert false = as-logic bic-s/bic-a
		--assert true = as-logic bic-s/bic-b
		--assert bic-s/bic-e = as-byte bic-s/bic-f
		--assert bic-s/bic-f = as-integer bic-s/bic-e
  
===end-group===

===start-group=== "Cast in conditional tests"
		cic-r: false
	--test-- "cic-1"
		cic-d: as-byte 0
		either as-logic cic-d [cic-r: false] [cic-r: true]
		--assert cic-r
  
	--test-- "cic-2"
		cic-s: declare struct! [
			a   [byte!]
			b   [byte!]
		]
		cic-s/a: as-byte 0
		cic-s/b: as-byte 1
		either as-logic cic-s/a [cic-r: false] [cic-r: true]
		--assert cic-r

===end-group===

~~~end-file~~~
