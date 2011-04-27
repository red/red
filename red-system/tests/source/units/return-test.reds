Red/System [
	Title:   "Red/System RETURN keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %test-return.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds

qt-start-file "return"

ret-test: func [return: [integer!]][return 1]
qt-assert "return-1" ret-test = 1

i: 0
ret-test98: func [return: [logic!]][
	return true
	i: 1
]
qt-assert "return-2" ret-test98
qt-assert "return-3" i = 0

i: 0
ret-test99: func [return: [logic!]][
	return false
	i: 1
]
qt-assert "return-4" not ret-test99
qt-assert "return-5" i = 0

i: 0
ret-test2: func [return: [logic!]][
	i: 1
	return true
	i: 2
]
qt-assert "return-6" ret-test2
qt-assert "return-7" i = 1

i: 0
ret-test3: func [return: [logic!]][
	i: 1
	if true [return true i: 2]
	i: 3
]
qt-assert "return-8" ret-test3
qt-assert "return-9" i = 1

i: 0
ret-test97: func [a [logic!] return: [logic!]][
	i: 1
	if true [return a i: 2]
	i: 3
]
qt-assert "return-10" ret-test97 true
qt-assert "return-11" i = 1

i: 0
ret-test4: func [return: [logic!]][
	i: 1
	if false [return false i: 2]
	i: 1
	true
]
qt-assert "return-12" ret-test4
qt-assert "return-13" i = 1

i: 0
ret-test5: func [return: [logic!]][
	i: 1
	either true [return 1 < 2 i: 2][i: 3]
	i: 4
]
qt-assert "return-14" ret-test5
qt-assert "return-15" i = 1

i: 0
ret-test6: func [return: [logic!]][
	i: 1
	either false [return false][i: 1 return true i: 2]
	i: 3
]
qt-assert "return-16" ret-test6
qt-assert "return-17" i = 1

i: 0
ret-test7: func [return: [logic!]][
	i: 1
	either 1 < 2 [
		either 3 < 4 [
			return true
			i: 2
		][
			i: 3
		]
	][
		i: 4
	]
	i: 5
]
qt-assert "return-18" ret-test7
qt-assert "return-19" i = 1

;; ret-test8 moved to return-test.r

i: 0
ret-test9: func [return: [logic!]][
	i: 1
	until [
		return false
		true
	]
	i: 2
]
qt-assert "return-20" not ret-test9
qt-assert "return-21" i = 1

i: 0
ret-test10: func [return: [integer!]][
	i: 1
	until [
		if true [return 42]
		i: 2
		true
	]
	i: 3
]
qt-assert "return-22" ret-test10 = 42
qt-assert "return-23" i = 1

qt-end-file

