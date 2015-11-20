Red/System [
	Title:   "Red/System EXIT keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %exit-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "exit"

	--test-- "exit-1"
		i: 0
		ex-test99: func [] [
			exit
			i: 1
		]
		ex-test99
		--assert i = 0
	
	--test-- "exit-2"
		i: 0
		ex-test2: func [] [
			i: 1
			exit
			i: 2
		]
		ex-test2
		--assert i = 1
	
	--test-- "exit-3"
		i: 0
		ex-test3: func [] [
			i: 1
			if true [exit]
			i: 2
		]
		ex-test3
		--assert i = 1
	
	--test-- "exit-4"
		i: 0
		ex-test4: func [] [
			i: 1
			if false [exit]
			i: 2
		]
		ex-test4
		--assert i = 2
	
	--test-- "exit-5"
		i: 0
		ex-test5: func [] [
			i: 1
			either true [exit][i: 2]
			i: 3
		]
		ex-test5
		--assert i = 1
	
	--test-- "exit-6"
		i: 0
		ex-test6: func [] [
			i: 0
			either false [exit][i: 1 exit]
			i: 2
		]
		ex-test6
		--assert i = 1
	
	--test-- "exit-7"
		i: 0
		ex-test7: func [] [
			i: 1
			either 1 < 2 [
			  exit
			][
			  i: 2
			]
			i: 3
		]
	  ex-test7
	  --assert i = 1
	
	  ;; ex-test "exit-8" moved to exit-test.r
	
	--test-- "exit-9"
		i: 0
		ex-test9: func [] [
			i: 1
			until [
			  exit
			  true
			]
			i: 2
		]
		ex-test9
		--assert i = 1
	
	--test-- "exit-10"
		i: 0
		ex-test10: func [] [
			i: 1
			until [
			  if true [exit]
			  i: 2
			  true
			]
			i: 3
		]
		ex-test10
		--assert i = 1

~~~end-file~~~
