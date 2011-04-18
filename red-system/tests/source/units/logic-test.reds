Red/System [
	Title:   "Red/System logic! datatype test script"
	Author:  "Nenad Rakocevic"
	File: 	 %logic-test.reds
	Version: 0.1.0
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

qt-start-file "logic"

;-- literal logic! value tests
qt-assert "logic-value-1" true
qt-assert "logic-value-2" not false

;-- logic variable tests
a: true
qt-assert "logic-variable-1" a
a: false
qt-assert "logic-variable-2" not a

;-- conditional expression assignment tests
a: 3 < 5
qt-assert "logic-conditional-1" a
a: 1 = 2
qt-assert "logic-conditional-2" not a

;-- logic value as last conditional expression in UNTIL tests
a: true
i: 0
until [
	i: i + 1
	a
]
qt-assert "logic-until-1" i = 1

i: 0
c: 3
stop?: false
until [
	i: i + 1
	c: c - 1
	if zero? c [stop?: true]
	stop?
]
qt-assert "logic-until-2" c = 0
qt-assert "logic-until-3" i = 3

;-- logic value as conditional expression in WHILE tests
a: false
i: 0 
while [a][i: i + 1]
qt-assert "logic-while-1" i = 0

i: 0
c: 3
run?: true
while [run?][
	i: i + 1
	c: c - 1
	if zero? c [run?: false]
]
qt-assert "logic-while-2" c = 0
qt-assert "logic-while-3" i = 3

;-- passing logic! as function's argument tests
foo: func [a [logic!] return: [logic!]][a]

qt-assert "logic-arg-1" foo true
qt-assert "logic-arg-2" not foo false
qt-assert "logic-arg-3" foo 1 < 2
qt-assert "logic-arg-4" foo 3 <> 4
qt-assert "logic-arg-5" foo (1 + 1 < 3)
a: false
if false = foo (2 + 2 = 5) [a: true]
qt-assert "logic-arg-7" a
qt-assert "logic-arg-8" not foo 3 = 4

;-- all with logic!
result:  all [
  true
  true
]
qt-assert "logic-all-1" result

result: all [
  false
  true
]
qt-assert "logic-all-2" not result

result all [
  true
  false
]
qt-assert "logic-all-3" not result

result: all [
  false
  false
]
qt-assert "logic-all-4" not result

a: all [true]
qt-assert "logic-all-5" a

a: all [false]
qt-assert "logic-all-6" not a

a: all [1 < 2 false]
qt-assert "logic-all-7" not a

a: all [false 1 < 2]
qt-assert "logic-all-8" not a

a: all [true 1 = 2]
qt-assert "logic-all-9" not a

a: all [1 = 2 true]
qt-assert "logic-all-10" not a

a: all [1 < 2]
qt-assert "logic-all-11" a

a: all [1 = 2]
qt-assert "logic-all-12" not a

a: all [1 < 2 3 <> 4]
qt-assert "logic-all-12" a

a: all [1 = 2 3 <> 4]
qt-assert "logic-all-13" not a

qt-assert "logic-all-14" not foo all [1 = 2]
qt-assert "logic-all-15" foo all [1 < 2 3 <> 4]
qt-assert "logic-all-16" not foo all [1 = 2 3 <> 4]

a: foo all [1 < 2]
qt-assert "logic-all-17" a 

a: foo all [1 = 2]
qt-assert "logic-all-18" not a 

a: foo all [1 < 2 3 <> 4]
qt-assert "logic-all-19" a

a: all [foo true]
qt-assert "logic-all-20" a

;-- any with logic!

result: any [
  true
  true
]
qt-assert "logic-any-1" result

result: any [
  false
  true
]
qt-assert "logic-any-2" result

result: any [
  true
  false
]
qt-assert "logic-any-3" result

result: any [
  false
  false
]
qt-assert "logic-any-4" not result

a: any [true]
qt-assert "logic-any-5" a

a: any [false]
qt-assert "logic-any-6" not a

a: any [1 < 2 false]
qt-assert "logic-any-7" a

a: any [false 1 < 2]
qt-assert "logic-any-8" a

a: any [true 1 = 2]
qt-assert "logic-any-9" a

a: any [1 = 2 true]
qt-assert "logic-any-10" a

a: any [1 < 2]
qt-assert "logic-any-11" a

a: any [1 = 2]
qt-assert "logic-any-12" not a

a: any [1 < 2 3 <> 4]
qt-assert "logic-any-13" a

a: any [1 = 2 3 <> 4]
qt-assert "logic-any-14" a

qt-assert "logic-any-15" not foo any [1 = 2]
qt-assert "logic-any-16" foo any [1 < 2 3 <> 4]
qt-assert "logic-any-17" foo any [1 = 2 3 <> 4]

a: foo any [1 < 2]
qt-assert "logic-any-18" a 

a: foo any [1 = 2]
qt-assert "logic-any-19" not a 

a: foo any [1 < 2 3 <> 4]
qt-assert "logic-any-20" a

a: any [foo true]
qt-assert "logic-any-21" a


;-- function returning a logic value
test?: func [
  return: [logic!]
][
  either 1 < 2 [true] [false]
]

qt-assert "logic-return-1" test?

a: test?
qt-assert "logic-return-2" a

test2?: func [
  return: [logic!]
][
  either 1 = 2 [true] [false]
]

qt-assert "logic-return-3" not test2?

a: test2?
qt-assert "logic-return-4" not a

;-- equality tests
a: false
qt-assert "logic-=-1" a = false

a: true
qt-assert "logic-=-2" not a = false

a: false
qt-assert "logic-=-3" not a <> false

a: true
qt-assert "logic-=-4" a <> false

a: false
b: a = false
qt-assert "logic-=-5" b

a: true
b: a = false
qt-assert "logic-=-6" not b

a: false
b: false <> a
qt-assert "logic-=-7" not b

a: true
b: false <> a
qt-assert "logic-=-8" b

a: false
qt-assert "logic-=-9" foo a = false

a: false
qt-assert "logic-=-10" foo a = false

a: true
qt-assert "logic-=-11" not foo a = false

qt-end-file
