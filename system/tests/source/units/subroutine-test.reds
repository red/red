Red/System [
	Title:   "Red/System system test script"
	Author:  "Nenad Rakocevic"
	File: 	 %subroutine-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2016-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "subroutine"

===start-group=== "Subroutine basics"

	--test-- "sub-1"
		foo-sub1: func [/local s [subroutine!]][
			s: []
			s
			--assert true
		]
		foo-sub1

	--test-- "sub-2"
		foo-sub2: func [/local s [subroutine!]][
			s: [--assert true]
			s
			--assert true
		]
		foo-sub2
		
	--test-- "sub-3"
		foo-sub3: func [/local a [integer!] s [subroutine!]][
			a: 1 + 2
			s
			--assert true
			s: []
		]
		foo-sub3

	--test-- "sub-4"
		foo-sub4: func [/local a [integer!] s [subroutine!]][
			a: 1 + 2
			s: [a: a * 2]
			s
			--assert a = 6
		]
		foo-sub4

	--test-- "sub-5"
		foo-sub5: func [/local a [integer!] s s2 [subroutine!]][
			a: 1 + 2
			s2: [a: 0 - a]
			s: [a: a * 2]
			s
			s2
			--assert a = -6
		]
		foo-sub5

	--test-- "sub-6"
		foo-sub6: func [/local a [integer!] s s2 [subroutine!]][
			s2: [a: 0 - a]
			a: 1 + 2
			s:  [
				a: a * 2
				s2
			]
			s
			--assert a = -6
		]
		foo-sub6

	--test-- "sub-7"
		foo-sub7: func [/local a [integer!] s s2 [subroutine!]][
			a: 1 + 2
			s2: [a: 0 - a]
			s:  [
				a: a * 2
				s2
			]
			s
			--assert a = -6
		]
		foo-sub7

	--test-- "sub-8"
		foo-sub8: func [/local a [integer!] s s2 s3 s4 [subroutine!]][
			a: 1 + 2
			s4: [a: a + 4]
			s3: [a: a + 3 s4]
			s2: [a: 0 - a s3]
			s:  [
				a: a * 2
				s2
			]
			s
			--assert a = 1
		]
		foo-sub8
		
	--test-- "sub-9"
		foo-sub9: func [a [integer!] return: [integer!]
		   /local
			   do-error [subroutine!]
			   err 		[integer!]
		][
		   do-error: [return err]
		   switch a [
			   0  [err: 10 do-error]
			   5  [err: 20 do-error]
			   10 [err: 30 do-error]
			   default [a]
		   ]
		]
		--assert 1 = foo-sub9 1
		--assert 10 = foo-sub9 0
		--assert 3 = foo-sub9 3
		--assert 20 = foo-sub9 5
		
		
===end-group===

~~~end-file~~~
