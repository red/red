REBOL [
	Title:   "Red/System cast test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %alias-test.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

compiled?: func [
  source [string!]
][
  write %runnable/alias.reds source 
  exe: --compile src: %runnable/alias.reds
  if exists? %runnable/alias.reds [delete %runnable/alias.reds]
  if all [
    exe
    exists? exe
  ][
    delete exe
  ]
  qt/compile-ok?
]
  

~~~start-file~~~ "alias-compile"

===start-group=== "compiler checks"

  --test-- "alias 1"
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; I guess creating an alias from an existing struc! alllowed? :-)
      ;; perhaps it will be in Red ?? ;-)
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  --assert compiled? {
    Red/System []
    a3-struct: struct [a [integer!] b [integer!]]
    a3-struct/a: 1
    a3-struct/b: 2
    a3-alias!: alias a3-struct
    a3-struct-1: struct a3-alias!
    a3-struct-1/a: 3
    a3-struct-1/b: 4
  }
  
  --test-- "alias 2"
  ;; I'm not sure if this use of alias is supported, it would be good if it was
  --assert compiled? {
      Red/System []
      a5-alias!: alias struct! [a [integer!] b [integer!]]
      a5-struc: struct a5-alias!
      a5-pointer: pointer [integer!]
      a5-struc/a: 1
      a5-struc/b: 2
      a5-pointer: as pointer! a5-struc
      a5-struc: as [struct! [a5-alias-1]] a5-pointer
    }
    
  --test-- "alias 2"
      ;; This is bascially the book/gift example from the spec
  --assert compiled? {
    Red/System []  
    a5-alias!: alias struct! [a [byte!] b [byte!]]
    a5-struc: struct [
      s1 [a5-alias!]
      s2 [a5-alias!]
    ]
    a5-struct/s1: struct a5-alias!
  }
  
===end-group=== 
       
~~~end-file~~~


