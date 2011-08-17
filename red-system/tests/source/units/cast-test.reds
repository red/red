Red/System [
	Title:   "Red/System datatype casting test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %cast-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

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
	
	--test-- "byte-cast-9"
		a: as-byte 10h
		b: as-byte 80h
	--assert 10h = as-integer a
	
===end-group===

===start-group=== "cast from integer!"
comment {
  --test-- "int-cast-1"
  --assert #"^(00)" = as byte! 0
}
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
    P: P + 1
    i2: as integer! p
  --assert i2 = 5
  
  --test-- "int-cast-17"           ;; This test assumes 32-bit target
    ;; currently fails as p-int-cast is not declared
    i: 1
    p-int-cast-17: as [pointer! [integer!]] i
    P-int-cast-17: P-int-cast-17 + 1
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
  comment { 
  --test-- "c-string-cast-2"
  --assert false = as logic! ""
  }
    --test-- "c-string-cast-3"
    csc3-str: ""
  --assert false = as logic! csc3-str
  
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
  
~~~end-file~~~

