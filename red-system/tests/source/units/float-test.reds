Red/System [
	Title:   "Red/System integer! datatype tests"
	Author:  "Peter W A Wood"
	File: 	 %float-test.reds
	Version: 0.1.0
	Rights:  "Copyright (C) 2012 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "float"

===start-group=== "float assginment"
  --test-- "float-1"
    f: 100.0
    f: 1.222090944E+33
    f: 9.99999E-45
    f: 1.0
    f1: f
  --assert 1 = 1
===end-group===

===start-group=== "float function arguments"
    ff: func [
      fff [float!]
      ffi [integer!]
      ffg [float!]
      return: integer!
      /local
      ffl [float!]
    ][
       ffl: fff
       ffl: ffg
       ffi
    ]
    
  --test-- "float-func-args-1"
  --assert 1 = ff 1.0 1 2.0
  
  --test-- "float-func-args-2"
  --assert 2 = ff 1.222090944E+33 2 9.99999E-45
  
===end-group===

===start-group=== "float function return"

  --test-- "float return"
    ff1: func [
      ff1i      [integer!]
      return:   [float!]
    ][
      switch ffli [
        1 [1.0]
        2 [1.222090944E+33]
        3 [9.99999E-45]
      ]
    ]
    f: ff1 1
    f: ff1 2
    f: ff1 3
  --assert 1 = 1

===end-group===

===start-group=== "float struct!"

  --test-- "float-struct-1"
    sf1: struct! [
      a   [float!]
    ]
    
    f: sf1/a
    sf1/a: 1.222090944E+33
    f: sf1/a
  --assert 1 = 1
  
  --test-- "float-struct-2"
    sf2: struct! [
      a   [float!]
      b   [float!]
    ]
    
    f: sf2/a
    f: sf2/b
    sf2/a: 1.222090944E+33
    sf2/b: 9.99999E-45
    f: sf2/a
    f: sf2/b
  --assert 1 = 1  
    
  --test-- "float-struct-3"
    sf2: struct! [
      c   [byte!]
      a   [float!]
      l   [logic!]
      b   [float!]
    ]
    
    f: sf2/a
    f: sf2/b
    sf2/a: 1.222090944E+33
    sf2/b: 9.99999E-45
    f: sf2/a
    f: sf2/b
  --assert 1 = 1  

===end-group===

~~~end-file~~~
