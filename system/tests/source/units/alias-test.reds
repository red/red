Red/System [
	Title:   "Red/System alias test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %alias-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "alias"

	--test-- "alias-1"
		a1-str!: alias struct! [i [integer!]]
		a1-s: declare a1-str!
		a1-s/i: 123
		--assert a1-s/i = 123
  
	--test-- "alias-2"
		a2-str!: alias struct! [i [integer!]]
		a2-s: declare a2-str!
		a2-s/i: 123
		a2-str2!: alias struct! [a [a2-str!] b [a2-str!]]
		a2-s2: declare a2-str2!
		a2-s2/b: a2-s
		a2-s2/b/i: 987
		--assert a2-S/i = 987

	--test-- "alias-3"
		a3-alias!: alias struct! [s [c-string!]]
		a3-struct: declare a3-alias!
		a3-struct/s: "abcde"
		a3-struct-1: declare a3-alias!
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
		a4-struct: declare a4-alias!
		a4-struct/a: 1
		a4-struct/b: 2
		a4-struct-1: declare a4-alias!
		a4-struct-1/a: 3
		a4-struct-1/b: 4
		--assert a4-struct/a = 1
		--assert a4-struct/b = 2
		--assert a4-struct-1/a = 3
		--assert a4-struct-1/b = 4
	
	--test-- "alias-5"
		a5-alias!: alias struct! [a [integer!] b [integer!]]
		a5-struc: declare a5-alias!
		a5-pointer: declare pointer! [integer!]
		a5-struc/a: 1
		a5-struc/b: 2
		a5-pointer: as [pointer! [integer!]] a5-struc
		a5-struc: as a5-alias! a5-pointer
		--assert a5-struc/a = 1
		--assert a5-struc/b = 2
	
	--test-- "alias-6"
		a6-alias!: alias struct! [a [byte!] b [byte!]]
		a6-struct: declare struct! [
			s1 [a6-alias!]
			s2 [a6-alias!]
		]
		a6-struct/s1: declare a6-alias!
		a6-struct/s1/a: #"a"
		a6-struct/s1/b: #"b"
		a6-struct/s2: declare a6-alias!    
		a6-struct/s2/a: #"x"
		a6-struct/s2/b: #"y"
		--assert a6-struct/s1/a = #"a"
		--assert a6-struct/s1/b = #"b"
		--assert a6-struct/s2/a = #"x"
		--assert a6-struct/s2/b = #"y"

	--test-- "alias-7"						;-- regression test from issue #235
		a!: alias struct! [a [byte!]]
		--assert system/alias/a! = system/alias/a!
  
~~~end-file~~~

