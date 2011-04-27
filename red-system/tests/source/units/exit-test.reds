Red/System [
	Title:   "Red/System EXIT keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %exit-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

qt-start-file "exit"

i: 0
ex-test99: func [] [
	exit
	i: 1
]
ex-test99
qt-assert "exit-1" i = 0

i: 0
ex-test2: func [] [
	i: 1
	exit
	i: 2
]
ex-test2
qt-assert "exit-2" i = 1


i: 0
ex-test3: func [] [
	i: 1
	if true [exit]
	i: 2
]
ex-test3
qt-assert "exit-3" i = 1

i: 0
ex-test4: func [] [
	i: 1
	if false [exit]
	i: 2
]
ex-test4
qt-assert "exit-4" i = 2

i: 0
ex-test5: func [] [
	i: 1
	either true [exit][i: 2]
	i: 3
]
ex-test5
qt-assert "exit-5" i = 1

i: 0
ex-test6: func [] [
	i: 0
	either false [exit][i: 1 exit]
	i: 2
]
ex-test6
qt-assert "exit-6" i = 1

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
qt-assert "exit-7" i = 1

;; ex-test "exit-8" moved to exit-test.r

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
qt-assert "exit-9" i = 1

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
qt-assert "exit-10" i = 1

qt-end-file
