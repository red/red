Red [
	Title:   "Red reactivity test script"
	Author:  "Nenad Rakocevic"
	File: 	 %reactivity-test.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2016 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "reactivity"

===start-group=== "IS function"

	--test-- "is-1"
		a: make reactor! [x: 1 y: is [x + 1]]
		--assert a/x == 1
		--assert a/y == 2
		a/x: 5
		--assert a/y == 6

	--test-- "is-2"
		--assert [x + 1] = react? a 'x
		--assert 	 none? react?/target a 'x
		--assert [x + 1] = react?/target a 'y
		--assert     none? react? a 'y
	
	--test-- "is-3"
		b: make reactor! [x: 2 y: 3 z: is [x + y]]
		--assert b/x == 2
		--assert b/y == 3
		--assert b/z == 5
		b/x: 5
		--assert b/z == 8

	--test-- "is-4"
		--assert [x + y] = react? b 'x
		--assert [x + y] = react? b 'y
		--assert [x + y] = react?/target b 'z
    
    --test-- "is-5"
		c: make reactor! [x: 1 y: is [x + 1] z: is [y + 1]]
		--assert c/x == 1
		--assert c/y == 2
		--assert c/z == 3
		c/x: 4
		--assert c/y == 5
		--assert c/z == 6

	--test-- "is-6"
		--assert [x + 1] = react? c 'x
		--assert     none? react?/target c 'x
		--assert [x + 1] = react?/target c 'y
		--assert [y + 1] = react? c 'y
		--assert none? react? c 'z
		--assert [y + 1] = react?/target c 'z

 --test-- "is-7"
		;d: make reactor! [x: is [y + 1] y: is [x + 3]]
		;--assert none? d/x
		;--assert none? d/y
		;d/x: 1
		;--assert d/x = 5
		;--assert d/y = 4

===end-group===

~~~end-file~~~