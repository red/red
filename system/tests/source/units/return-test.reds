Red/System [
	Title:   "Red/System RETURN keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %test-return.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "return"
  
  --test-- "return-1"
    ret-test: func [return: [integer!]][return 1]
  --assert ret-test = 1
  	ret-test1-1: func [s [c-string!] return: [c-string!]][return s]
  --assert 5 = length? ret-test1-1 "hello"

  --test-- "return-2"
    i: 0
    ret-test98: func [return: [logic!]][
      return true
      i: 1
      false
    ]
  --assert ret-test98
  --assert i = 0

  --test-- "return-3"
    i: 0
    ret-test99: func [return: [logic!]][
      return false
      i: 1
      true
    ]
  --assert not ret-test99
  --assert i = 0

  --test-- "return-4"
    i: 0
    ret-test2: func [return: [logic!]][
      i: 1
      return true
      i: 2
      false
    ]
  --assert ret-test2
  --assert i = 1

  --test-- "return-5"
    i: 0
    ret-test3: func [return: [logic!]][
      i: 1
      if true [return true i: 2]
      i: 3
      false
    ]
  --assert ret-test3
  --assert i = 1

  --test-- "return-6"
    i: 0
    ret-test97: func [a [logic!] return: [logic!]][
      i: 1
      if true [return a i: 2]
      i: 3
      false
    ]
  --assert ret-test97 true
  --assert i = 1

  --test-- "return-7"
    i: 0
    ret-test4: func [return: [logic!]][
      i: 1
      if false [return false i: 2]
      i: 1
      true
    ]
  --assert ret-test4
  --assert i = 1

  --test-- "return-8"
    i: 0
    ret-test5: func [return: [logic!]][
      i: 1
      either true [return 1 < 2 i: 2][i: 3]
      i: 4
      false
    ]
  --assert ret-test5
  --assert i = 1

  --test-- "return-9"
    i: 0
    ret-test6: func [return: [logic!]][
      i: 1
      either false [return false][i: 1 return true i: 2]
      i: 3
      false
    ]
  --assert ret-test6
  --assert i = 1

  --test-- "return-10"
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
      false
    ]
  --assert ret-test7
  --assert i = 1

;; ret-test8 moved to return-test.r

  --test-- "return-11"
    i: 0
    ret-test9: func [return: [logic!]][
      i: 1
      until [
        return false
        true
      ]
      i: 2
      true
    ]
  --assert not ret-test9
  --assert i = 1

  --test-- "return-12"
    i: 0
    ret-test10: func [return: [integer!]][
      i: 1
      until [
        if true [return 42]
        i: 2
        true
      ]
      i: 3
      i
    ]
  --assert ret-test10 = 42
  --assert i = 1
  
  --test-- "return-13"
	ret-test13: func [
		i [integer!]
		n [integer!]
		return: [integer!]
		/local s
	][
		if 0 = i [return i]	
		i
	]
	--assert 0 = ret-test13 0 2

~~~end-file~~~

