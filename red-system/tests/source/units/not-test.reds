Red/System [
	Title:   "Red/System NOT function test script"
	Author:  "Nenad Rakocevic"
	File: 	 %not-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

foo: func [a [logic!] return: [logic!]][a]
nfoo: func [a [logic!] return: [logic!]][not a]

~~~start-file~~~ "not"

  --test-- "not-1" --assert false = not true
  --test-- "not-2" --assert not false
  --test-- "not-3" --assert not not true
  --test-- "not-4" --assert false = not not false

  --test-- "not-5"
    a: true
  --assert false = not a 

  --test-- "not-6"
    a: false
  --assert not a

  --test-- "not-7" --assert false = not foo true
  --test-- "not-8" --assert not foo false
  --test-- "not-9" --assert false = foo not true
  --test-- "not-10" --assert foo not false

  --test-- "not-11"
    a: true
  --assert false = not foo a
  
  --test-- "not-12"
    a: true
  --assert false = foo not a

  --test-- "not-13"
    a: false
  --assert not foo a 

  --test-- "not-14"
    a: false
  --assert not foo a

  --test-- "not-15" --assert false = nfoo true
  --test-- "not-16" --assert nfoo false

  --test-- "not-17" --assert false = nfoo true
  --test-- "not-18" --assert nfoo false

~~~end-file~~~

;TBD: write unit tests for bitwise NOT on integer
