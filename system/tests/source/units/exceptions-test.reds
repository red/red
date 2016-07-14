Red/System [
	Title:   "Red/System execeptions test script"
	Author:  "Nenad Rakocevic"
	File: 	 %exceptions-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "break/continue"

	--test-- "break-1"
		until [break true]
		--assert true
	
	--test-- "break-2"
		i: 5
		until [
			break
			i: i - 1
			i = 0
		]
		--assert i = 5
	  
	--test-- "break-3"
		i: 5
		until [
			i: i - 1
			break
			i = 0
		]
		--assert i = 4
	
	--test-- "break-4"
		i: 5
		until [
		  if i = 3 [break]
		  i: i - 1
		  i = 0
		]
		--assert i = 3
	
	--test-- "continue"
		i: 5
		until [
			i: i - 1
			if i > 2 [continue]
			if i > 2 [--assert false]     ;-- make it fail here
			i = 0
		]
		--assert i = 0
	
	--test-- "nested-1"
		levelA: 0
		levelB: 0
		i: 3
		j: 5
		until [
			levelA: levelA + 1
			i: i - 1
			j: 5
			until [
				levelB: levelB + 1
				j: j - 1
				either j = 4 [continue][break]
				j = 0
			]
			either i = 2 [continue][break]
			i = 0
		]
		--assert levelA = 2
		--assert levelB = 4
	
	--test-- "nested-2"
		levelA: 0
		levelB: 0
		i: 3
		j: 5
		while [i > 0][
			levelA: levelA + 1
			i: i - 1
			j: 5
			until [
				levelB: levelB + 1
				j: j - 1
				either j = 4 [continue][break]
				j = 0
			]
			either i = 2 [continue][break]
		]
		--assert levelA = 2
		--assert levelB = 4
		
	--test-- "nested-3"
		levelA: 0
		levelB: 0
		i: 3
		j: 5
		while [i > 0][
			levelA: levelA + 1
			i: i - 1
			j: 5
			while [j > 0][
				levelB: levelB + 1
				j: j - 1
				either j = 4 [continue][break]
			]
			either i = 2 [continue][break]
		]
		--assert levelA = 2
		--assert levelB = 4
	
~~~end-file~~~

