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

===start-group=== "float assignment"
  --test-- "float-1"
    f: 100.0
  --assert f = 100.0
  --test-- "float-2"
    f: 1.222090944E+33
  --assert f = 1.222090944E+33
  --test-- "float-3"
    f: 9.99999E-45
  --assert f = 9.99999E-45
  --test-- "float-4"
    f: 1.0
    f1: f
  --assert f1 = 1.0
===end-group===

===start-group=== "float function arguments"
    ff: func [
      fff     [float!]
      ffg     [float!]
      return: [integer!]
      /local
      ffl [float!]
    ][
       ffl: fff
       if ffl <> fff [return 1]
       ffl: ffg
       if ffl <> ffg [return 2]
       1
    ]
    
  --test-- "float-func-args-1"
  --assert 1 = ff 1.0 2.0
  
  --test-- "float-func-args-2"
  --assert 1 = ff 1.222090944E+33 9.99999E-45
  
===end-group===

===start-group=== "float function return"

 
    ff1: func [
      ff1i      [integer!]
      return:   [float!]
    ][
      switch ff1i [
        1 [1.0]
        2 [1.222090944E+33]
        3 [9.99999E-45]
      ]
    ]
  --test-- "float return 1"
  --assert 1.0 = ff1 1
  --test-- "float return 2"
  --assert 1.222090944E+33 = ff1 2
  --test-- "float return 3"
  --assert 9.99999E-45 = ff1 3
  
===end-group===

===start-group=== "float struct!"

  --test-- "float-struct-1"
    sf1: declare struct! [
      a   [float!]
    ]
  --assert 0.0 = sf1/a
  
  --test-- "float-struct-2"
    sf2: declare struct! [
      a   [float!]
    ]
    sf1/a: 1.222090944E+33
  --assert 1.222090944E+33 = sf1/a

   
    sf3: declare struct! [
      a   [float!]
      b   [float!]
    ]
  
  --test-- "float-struct-3"
    sf3/a: 1.222090944E+33
    sf3/b: 9.99999E-45
    
  --assert 1.222090944E+33 = sf3/a
  --assert 9.99999E-45 = sf3/b
    
  --test-- "float-struct-4"
    sf4: declare struct! [
      c   [byte!]
      a   [float!]
      l   [logic!]
      b   [float!]
    ]
    sf4/a: 1.222090944E+33
    sf4/b: 9.99999E-45
  --assert 1.222090944E+33 = sf4/a
  --assert 9.99999E-45 = sf4/b

===end-group===

~~~end-file~~~
