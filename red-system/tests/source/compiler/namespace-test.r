REBOL [
	Title:   "Red/System namespace compiler test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %namespace-test.r
	Rights:  "Copyright (C) 2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../
  

~~~start-file~~~ "namespace compiler tests"

===start-group=== "with"

  --test-- "nscw1"
  
  --compile-and-run-this {
	  nscw1-nsp1: context [b: 123]
    nscw1-nsp2: context [b: 456]
    with [nscw1-nsp1 nscw1-nsp2] [
      b: 789
    ]
	}
	
	--assert-msg? "*** Warning: contexts are using identical word: b"
 
===end-group===

===start-group=== "pointers"
  --test-- "nmcp1"
  --compile-this {
    pi: declare pointer! [integer!]
    nmcp1-ctx: context [
      i: 12345
    ]
    pi: :mmcp1-ctx/i                  ;-- getting a pointer to a varibale using
                                      ;--  path notation is not supported
                                      ;-- use a local function to get such
                                      ;--  a pointer                              
  }
  --assert-msg? "Currently compiler crashes - need error message"
===end-group===

===start-group=== "context as local variable"
  --test-- "nmclv1"
  --compile-this {
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
    nmcaa1-ctx: context [
      s!: alias struct! [val [integer!]]
      s: declare s!
      s/val: 100
    ]
    p: declare s!               
  }
  --assert-msg? "*** Compilation Error: unknown type: none"
  
===end-group===
       
~~~end-file~~~


