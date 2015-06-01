Red/System [
	Title:   "Red/System NOT function test script"
	Author:  "Nenad Rakocevic"
	File: 	 %not-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

not-foo: func [a [logic!] return: [logic!]][a]
not-nfoo: func [a [logic!] return: [logic!]][not a]

~~~start-file~~~ "not"

===start-group=== "logical not"

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
  
  --test-- "not-19" --assert -1 = (not 4 and 3)
  --test-- "not-20" --assert -5 = not 4
  --test-- "not-21" --assert 3 = (-5 and 3)
  --test-- "not-22" --assert 3 = (3 and -5)
  --test-- "not-23" --assert 3 = (3 and not 4)
  --test-- "not-24" --assert 0 = (4 and 3)

===end-group===

===start-group=== "integer bitwise not"
  --test-- "ib-not-1"
  --assert -2 = not 1
   --test-- "ib-not-2"
    ibn1-i: 1
  --assert -2 = not ibn1-i
  --test-- "ib-not-3"
  --assert FFFFFFFFh = not 0
  --test-- "ib-not-3"
  --assert 0 = not FFFFFFFFh
  --test-- "ib-not-4"
  --assert F0F0F0F0h = not 0F0F0F0Fh
  --test-- "ib-not-5"
  --assert 0F0F0F0Fh = not F0F0F0F0h
  --test-- "ib-not-6"
  --assert AAAAAAAAh = not 55555555h
  --test-- "ib-not-7"
  --assert 55555555h = not AAAAAAAAh
  --test-- "ib-not-8"
  --assert A5A5A5A5h = not 5A5A5A5Ah
  --test-- "ib-not-9"
  --assert 5A5A5A5Ah = not A5A5A5A5h
  
===end-group===

===start-group=== "byte bitwise not"
  --test-- "bb-not-0"
  --assert (as byte! 255) = not as byte! 0
  --test-- "bb-not-1"
  --assert #"^(FF)" = not as byte! 0
  --test-- "bb-not-2"
  --assert #"^(FF)" = not #"^(00)"
  --test-- "bb-not-3"
  --assert #"^(00)" = not #"^(FF)"
  --test-- "bb-not-4"
  --assert #"^(FF)" = not #"^(00)"
  --test-- "bb-not-5"
  --assert #"^(F0)" = not #"^(0F)"
  --test-- "bb-not-6"
  --assert #"^(AA)" = not #"^(55)"
  --test-- "bb-not-7"
  --assert #"^(55)" = not #"^(AA)"
  --test-- "bb-not-8"
  --assert #"^(5A)" = not #"^(A5)"
  --test-- "bb-not-9"
  --assert #"^(A5)" = not #"^(5A)"

===end-group===

~~~end-file~~~



;TBD: write unit tests for bitwise NOT on integer
