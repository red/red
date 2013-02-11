Red [
	Title:   "Red local contexts binding test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %binding-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include  %../../../../quick-test/quick-test.red

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
			y: 1
			--assert  x = 'y
			--assert 'y = get 'x
			--assert  1 = get x
			--assert  1 = do [get x]
		]
		fun-bind-2
	
	--test-- "def-bind-3"	
		fun-bind-3: func [/local x][			;-- indirect global word setting test
			x: 'z
			set x 1
			--assert 1 = get 'z
			--assert 1 = do [z]
		]
		fun-bind-3
	
===end-group===


~~~end-file~~~

