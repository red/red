Red/System [
	Title:   "Red/System byte! datatype test script"
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
	  b: #"A"
	  i: 65
	--assert i = as integer! b
	
	--test-- "byte-cast-3"
	--assert false = as logic! #"^(00)"
	
	--test-- "byte-cast-4"
	  b: #"^(00)"
	  l: false
	--assert l = as logic! b
	
	--test-- "byte-cast-5"
	--assert true = as logic! #"A"
	
	--test-- "byte-cast-6"
	  b: #"A"
	  l: true
	--assert l = as logic! b
	
	--test-- "byte-cast-7"
	--assert true = as logic! #"^(FF)"
	
	--test-- "byte-cast-8"
	  b: #"^(FF)"
	  l: true
	--assert l = as logic! b
	
===end-group===

===start-group=== "cast from integer!"
comment {
  --test-- "int-cast-1"
  --assert #"^(00)" = as byte! 0
}
  --test-- "int-cast-2"
    i: 0
    b: #"^(00)"
  --assert b = as byte! i

  --test-- "int-cast-3"
  --assert #"^(01)" = as byte! 1
  
  --test-- "int-cast-4"
    i: 1
    b: #"^(01)"
  --assert b = as byte! i
  
  --test-- "int-cast-5"
  --assert #"^(FF)" = as byte! 255
  
  --test-- "int-cast-6"
    i: 255
    b: #"^(FF)"
  --assert b = as byte! i
  
  --test-- "int-cast-7"
  --assert #"^(00)" = as byte! 256
  
  --test-- "int-cast-8"
    i: 256
    b: #"^(00)"
  --assert b = as byte! i
  
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
    p: pointer [integer!]
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
    s: struct [
      a [integer!]
      b [integer!]
    ]
    s: as [struct! [a [integer!] b [integer!]]] i
    s: s + 1
    i2: as integer! s
  --assert i2 = 9
  
===end-group===

===start-group=== "cast from logic!"
comment {  
  --test-- "logic-cast-1"
  --assert #"^(01)" = as byte! true 
}
  --test-- "logic-cast-2"
    b: #"^(01)"
    l: true
  --assert b = as byte! l
comment {  
  --test-- "logic-cast-3"
  --assert #"^(00)" = as byte! false
}
  --test-- "logic-cast-4"
    b: #"^(00)"
    l: false
  --assert b = as byte! l
  
    --test-- "logic-cast-5"
  --assert 1 = as integer! true 

  --test-- "logic-cast-6"
    i: 1
    l: true
  --assert b = as integer! l
  
  --test-- "logic-cast-7"
  --assert 0 = as integer! false

  --test-- "logic-cast-8"
    i: 0
    l: false
  --assert b = as integer! l
  
===end-group===

~~~end-file~~~

