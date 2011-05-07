Red/System [
	Title:   "Red/System NOT function test script"
	Author:  "Nenad Rakocevic"
	File: 	 %not-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

not-foo: func [a [logic!] return: [logic!]][a]
not-nfoo: func [a [logic!] return: [logic!]][not a]

~~~start-file~~~ "not"

  --test-- "not-1" --assert false = not true
  --test-- "not-2" --assert not false
  --test-- "not-3" --assert not not true
  --test-- "not-4" --assert false = not not false

  --test-- "not-5"
    n-logic-a: true
  --assert false = not n-logic-a

  --test-- "not-6"
    n-logic-a: false
  --assert not n-logic-a

  --test-- "not-7" --assert false = not not-foo true
  --test-- "not-8" --assert not not-foo false
  --test-- "not-9" --assert false = not-foo not true
  --test-- "not-10" --assert not-foo not false

  --test-- "not-11"
    n-logic-a: true
  --assert false = not not-foo n-logic-a
  
  --test-- "not-12"
    n-logic-a: true
  --assert false = not-foo not n-logic-a

  --test-- "not-13"
    n-logic-a: false
  --assert not not-foo n-logic-a 

  --test-- "not-14"
    n-logic-a: false
  --assert not not-foo n-logic-a

  --test-- "not-15" --assert false = not-nfoo true
  --test-- "not-16" --assert not-nfoo false

  --test-- "not-17" --assert false = not-nfoo true
  --test-- "not-18" --assert not-nfoo false

~~~end-file~~~

;TBD: write unit tests for bitwise NOT on integer
