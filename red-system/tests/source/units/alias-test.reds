Red/System [
	Title:   "Red/System alias test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %alias-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

~~~start-file~~~ "alias"

  --test-- "alias-1"
    a1-str!: alias struct! [i [integer!]]
    a1-s: struct a1-str!
    a1-s/i: 123
  --assert a1-s/i = 123
  
  --test-- "alias-2"
    a2-str!: alias struct! [i [integer!]]
    a2-s: struct a2-str!
    a2-s/i: 123
    a2-str2!: alias struct! [a [a2-str!] b [a2-str!]]
    a2-s2: struct a2-str2!
    a2-s2/b: a2-s
    a2-s2/b/i: 987
  --assert a2-S/i = 987

  --test-- "alias-3"
    a3-alias!: alias struct! [s [c-string!]]
    a3-struct: struct a3-alias!
    a3-struct/s: "abcde"
    a3-struct-1: struct a3-alias!
    a3-struct-1/s: "fghij"
  --assert a3-struct/s/1 = #"a"
  --assert a3-struct/s/2 = #"b"
  --assert a3-struct/s/3 = #"c"
  --assert a3-struct/s/4 = #"d"
  --assert a3-struct/s/5 = #"e"
  --assert a3-struct-1/s/1 = #"f"
  --assert a3-struct-1/s/2 = #"g"
  --assert a3-struct-1/s/3 = #"h"
  --assert a3-struct-1/s/4 = #"i"
  --assert a3-struct-1/s/5 = #"j"

  --test-- "alias-4"
    a4-alias!: alias struct! [a [integer!] b [integer!]]
    a4-struct: struct a4-alias!
    a4-struct/a: 1
    a4-struct/b: 2
    a4-struct-1: struct a4-alias!
    a4-struct-1/a: 3
    a4-struct-1/b: 4
  --assert a4-struct/a = 1
  --assert a4-struct/b = 2
  --assert a4-struct-1/a = 3
  --assert a4-struct-1/b = 4

comment {
  --test-- "alias-5"
    a5-alias!: alias struct! [a [byte!] b [byte!]]
    a5-struc: struct [
      s1 [a5-alias!]
      s2 [a5-alias!]
    ]
    a5-struct/s1: struct a5-alias!
    a5-struct/s1/a: #"a"
    a5-struct/s1/b: #"b"
    a5-struct/s2: struct a5-alias!    
    a5-struct/s2/a: #"c"
    a5-struct/s2/b: #"d"
  --assert a5-struct/s1/a = #"a"
  --assert a5-struct/s1/b = #"b"
  --assert a5-struct/s2/a = #"c"
  --assert a5-struct/s2/b = #"d"
}    
~~~end-file~~~

