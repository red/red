Red [
	Title:   "Red local contexts binding test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %binding-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include  %../../../quick-test/quick-test.red

~~~start-file~~~ "binding"

===start-group=== "Definitional binding"

	--test-- "def-bind-1"
		x: 'y
		y: 1
		--assert  x = 'y
		--assert 'y = get 'x
		--assert  1 = get x
		--assert  1 = do [get x]

	--test-- "def-bind-2"	
		fun-bind-2: func [/local x y][			;-- indirect local word setting test
			x: 'y
			y: 2
			--assert  x = 'y
			--assert 'y = get 'x
			--assert  2 = get x
			--assert  2 = do [get x]
		]
		fun-bind-2
	
	--test-- "def-bind-3"	
		fun-bind-3: func [/local x][			;-- indirect global word setting test
			x: 'z
			set x 3
			--assert 3 = get 'z
			--assert 3 = do [z]
		]
		fun-bind-3
	
===end-group===

===start-group=== "Dynamic binding"

	--test-- "dyn-bind-1"
		a: 0
		fun-bind-10: func [code /local a][
			a: 1
			do bind code 'a
		]
		--assert 3 = fun-bind-10 [a + 2]
		--assert a = 0

	--test-- "dyn-bind-2"
		a: 0
		fun-bind-11: func [code /local a][
			a: 1
			do bind/copy code 'a
		]
		z: [a + 2]
		--assert 3 = fun-bind-11 z
		--assert a = 0
		--assert 2 = do z
	
	--test-- "dyn-bind-3"
		a: 0
		fun-bind-12: func [code /local a][
			a: 1
			do bind code :fun-bind-12
		]
		--assert 3 = fun-bind-12 [a + 2]
		--assert a = 0


	--test-- "dyn-bind-4"
		a: 0
		fun-bind-13: func [word /local a][
			a: 1
			get bind word 'a
		]		
		--assert 1 = fun-bind-13 'a
		--assert a = 0
		
	--test-- "dyn-bind-5"
		a: 0
		fun-bind-14: func [word /local a][
			a: 1
			get bind word :fun-bind-14
		]
		--assert 1 = fun-bind-14 'a
		--assert a = 0

===end-group===


===start-group=== "Binding bugs"
	
	--test-- "#581"
		--assert 1 = do load {S: 1 S}

~~~end-file~~~

