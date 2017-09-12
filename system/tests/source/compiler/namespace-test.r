REBOL [
	Title:   "Red/System namespace compiler test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %namespace-test.r
	Rights:  "Copyright (C) 2012-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

change-dir %../
  

~~~start-file~~~ "namespace compiler tests"

===start-group=== "with"

  --test-- "nscw1"
  
  --compile-and-run-this {
	  Red/System [] 
	  nscw1-nsp1: context [b: 123]
	  nscw1-nsp2: context [b: 456]
	  with [nscw1-nsp1 nscw1-nsp2] [
      	b: 789
      ]
	}
	
	--assert-msg? "*** Warning: contexts are using identical word: b"
 
===end-group===

;; This feature is now supported and requires some unit tests
;;
;===start-group=== "pointers"
;  --test-- "nmcp1"
;  --compile-this {
;    Red/System [] 
;    p-i: declare pointer! [integer!]
;    nmcp1-ctx: context [
;      i: 12345
;    ]
;    p-i: :mmcp1-ctx/i                  ;-- getting a pointer to a varibale using
;                                      ;--  path notation is not supported
;                                      ;-- use a local function to get such
;                                      ;--  a pointer                              
;  }
;  --assert-msg? "get-path! syntax is not supported"
;===end-group===

===start-group=== "context as local variable"
  --test-- "nmclv1"
  --compile-this {
    Red/System [] 
    nmclv1-ctx: context [
      context: 1                      ;-- this is not allowed as contexts can be
                                      ;--  nested, so you can't redefine
                                      ;--  'context word inside a context only
                                      ;--  in a function body.
    ]
  }
  --assert-msg? "*** Compilation Error: attempt to redefine a protected keyword: context"
===end-group===

===start-group=== "accessing alias from context"
  --test-- "nmcaa1 - issue #237"
  --compile-this {
    Red/System []
    nmcaa1-ctx: context [
      s!: alias struct! [val [integer!]]
      s: declare s!
      s/val: 100
    ]
    nmcaa1-f: function [
      p [nmcaa1-ctx/s!]               ;-- path! in type specification are not
                                      ;--  supported
    ][
      p/val
    ]
  }
  --assert-msg? "Compilation Error: invalid definition for function nmcaa1-f"
  
  --test-- "nmcaa2 - issue #237"
  --compile-this {
    Red/System [] 
    nmcaa1-ctx: context [
      s!: alias struct! [val [integer!]]
      s: declare s!
      s/val: 100
    ]
    p: declare s!               
  }
  --assert-msg? "*** Compilation Error: unknown type: none"
  
===end-group===
       
===start-group=== "Invalid context definitions"

  --test-- "nmicd1 - Cannot define namespace in conditional block - issue #281"
  --compile-this {
    Red/System []
    if false [nmicd1-c: context [d: 1]]
  }  
  --assert-msg? "*** Compilation Error: context has to be declared at root level"

  --test-- "nmicd2 - name clash with previously delared word - issue #282"
  --compile-this {
    Red/System [] 
    nmicd2-c: "hello"
    nmicd2-c: context [b: 2]    
  }
  --assert-msg? "*** Compilation Error: context name is already taken"
  
===end-group===

===start-group=== "inline functions"

  --test-- "nsif1 issue #285"
  
  --compile-and-run-this {
	  Red/System [] 
	  c: context [
      f: func [[infix] a [integer!] b [integer!] return: [integer!]][a + b]
      print "The answer is "
      print 1 f 2
      print lf
    ]
	}
	--assert-printed? "The answer is 3"
 
===end-group===

===start-group=== "enum argument type in namespace"

	--test-- "eatn1 - issue #293"
	--compile-and-run-this {
		Red/System [] 
		c: context [
			#enum e! [x]
			f: function [a [e!] return: [logic!]][zero? a]
		]
		print c/f 0
	}
	--assert-printed? "true"
	
===end-group===

===start-group=== "enum value not taking precedence over local variable"

	--test-- "evntpolv - issue #290"
	--compile-and-run-this {
		Red/System []
		#enum color! [a b c]
		print #"a"
	}
	--assert-printed? "a"
	
===end-group===


~~~end-file~~~


