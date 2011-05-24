REBOL [
	Title:   "Red/System cast test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %cast-test.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

compiled?: func [
  source [string!]
][
  write %runnable/cast.reds source 
  exe: --compile src: %runnable/cast.reds
  if exists? %runnable/cast.reds [delete %runnable/cast.reds]
  if all [
    exe
    exists? exe
  ][
    delete exe
  ]
  qt/compile-ok?
]
  

~~~start-file~~~ "cast-compile"

  --test-- "cast integer! 1"
  --assert compiled? {
      Red/System[]
      #"^^(00)" = as byte! 0
    }
    
  --test-- "cast logic! 1"
  --assert compiled? {
      Red/System[]
      #"^^(01)" = as byte! true
    }
    
  --test-- "cast logic! 2"
  --assert compiled? {
      Red/System[]
      #"^^(00)" = as byte! false
    }
    
  --test-- "cast c-string! 1"
  --assert compiled? {
      Red/System[]
      false = as logic! ""
   }
   
   --test-- "cast c-string! 2"
   --assert compiled? {
      Red/System[]
      csc7-struct: struct [
        c1 [byte!]
        c2 [byte!]
        c3 [byte!]
        c4 [byte!]
        c5 [byte!]
      ]
      csc7-str: "Peter"
      csc7-struct: as struct! [
        c1 [byte!] c2 [byte!] c3 [byte!] c4 [byte!] c5 [byte!]
      ] csc7-str
    }
~~~end-file~~~


