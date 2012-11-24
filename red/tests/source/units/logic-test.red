Red [
	Title:   "Red/System logic! datatype test script"
	Author:  "Nenad Rakocevic & Peter W A Wood"
	File: 	 %logic-test.red
	Version: "0.1.0"
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic & Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;; start of quick-test.red
;; counters
qt-run-tests: 0 
qt-run-asserts: 0
qt-run-passes: 0
qt-run-failures: 0
qt-file-tests: 0 
qt-file-asserts: 0 
qt-file-passes: 0 
qt-file-failures: 0

;; group switches
qt-group-name-not-printed: true
qt-group?: false

_qt-init-group: func [] [
  qt-group-name-not-printed: true
  qt-group?: false
  qt-group-name: ""
]

qt-init-run: func [] [
  qt-run-tests: 0 
  qt-run-asserts: 0
  qt-run-passes: 0
  qt-run-failures: 0
  _qt-init-group
]

qt-init-file: func [] [
  qt-file-tests: 0 
  qt-file-asserts: 0 
  qt-file-passes: 0 
  qt-file-failures: 0
  _qt-init-group
]

***start-run***: func[
    title [string!]
][
  qt-init-run
  qt-run-name: title
  prin "***Starting*** " 
  print title
]

~~~start-file~~~: func [
  title [string!]
][
  qt-init-file
  prin "~~~started test~~~ "
  print title
  qt-file-name: title
  qt-group?: false
]

===start-group===: func [
  title [string!]
][
  qt-group-name: title
  qt-group?: true
]

--test--: func [
  title [string!]
][
  qt-test-name: title
  qt-file-tests: qt-file-tests + 1
]

--assert: func [
  assertion [logic!]
][

  qt-file-asserts: qt-file-asserts + 1
  
  either assertion [
     qt-file-passes: qt-file-passes + 1
  ][
    qt-file-failures: qt-file-failures + 1
    if qt-group? [  
      if qt-group-name-not-printed [
        prin "===group=== "
        print qt-group-name
        qt-group-name-not-printed: false
      ]
    ]
    prin "--test-- " 
    prin qt-test-name
    print " FAILED**************"
  ]
]
 
===end-group===: func [] [
  _qt-init-group
]

qt-print-totals: func [
  tests     [integer!]
  asserts   [integer!]
  passes    [integer!]
  failures  [integer!]
][
  prin  "  Number of Tests Performed:      " 
  print tests 
  prin  "  Number of Assertions Performed: "
  print asserts
  prin  "  Number of Assertions Passed:    "
  print passes
  prin  "  Number of Assertions Failed:    "
  print failures
  if failures <> 0 [
    print "****************TEST FAILURES****************"
  ]
]

~~~end-file~~~: func [] [
  print ""
  prin "~~~finished test~~~ " 
  print qt-file-name
  qt-print-totals qt-file-tests qt-file-asserts qt-file-passes qt-file-failures
  print ""
  
  ;; update run totals
  qt-run-passes: qt-run-passes + qt-file-passes
  qt-run-asserts: qt-run-asserts + qt-file-asserts
  qt-run-failures: qt-run-failures + qt-file-failures
  qt-run-tests: qt-run-tests + qt-file-tests
]

***end-run***: func [][
  prin "***Finished*** "
  print qt-run-name
  qt-print-totals qt-run-tests
                  qt-run-asserts
                  qt-run-passes
                  qt-run-failures
]

;; End of quick-test.red


~~~start-file~~~ "logic"

===start-group=== "literal logic! value tests"

  --test-- "llv-1"
  --assert true
  
  --test-- "llv-2"
  --assert not false
===end-group===
  
===start-group=== "logic variable tests"
  --test-- "lv-1"
    a: true
  --assert a
  
  --test-- "lv-2"
    a: false
  --assert not a
===end-group===

===start-group=== "conditional expression assignment tests"
  --test-- "lce-1"
    a: 3 < 5
  --assert a
  
  --test-- "lce-2"
    a: 1 = 2
  --assert not a
===end-group===
  
===start-group=== "logic value as last conditional expression in UNTIL tests"
  --test-- "lu-1"
    a: true
    i: 0
    until [
      i: i + 1
      a
    ]
  --assert i = 1
  
  --test-- "lu-2"
    i: 0
    c: 3
    stop?: false
    until [
      i: i + 1
      c: c - 1
      if 0 = c [stop?: true]
      stop?
    ]
  --assert c = 0
  --assert i = 3
===end-group===

===start-group=== "logic value as conditional expression in WHILE tests"
  --test-- "lw-1"
    a: false
    i: 0 
    while [a][i: i + 1]
  --assert i = 0

  --test-- "lw-2"
    i: 0
    c: 3
    run?: true
    while [run?][
      i: i + 1
      c: c - 1
      if 0 = c [run?: false]
    ]
  --assert c = 0
  --assert i = 3
===end-group===

===start-group=== "passing logic! as function's argument tests"
    log-foo: func [a [logic!] return: [logic!]][a]

  --test-- "logic-arg-1"    
  --assert log-foo true

  --test-- "logic-arg-2" 
  --assert not log-foo false

  --test-- "logic-arg-3" 
  --assert log-foo 1 < 2
  
  --test-- "logic-arg-4"
  --assert log-foo 3 <> 4
  
  --test-- "logic-arg-5"
  --assert log-foo (1 + 1 < 3)
  
  --test-- "logic-arg-6"
    a: false
    if false = log-foo (2 + 2 = 5) [a: true]
  --assert a
  
  --test-- "logic-arg-7"
  --assert not log-foo 3 = 4

===end-group===

===start-group=== "all with logic!"

  --test-- "logic-all-1"
    result:  all [
      true
      true
    ]
  --assert result

  --test-- "logic-all-2"
    result: all [
      false
      true
    ]
  --assert not result

  --test-- "logic-all-3"
    result all [
      true
      false
    ]
  --assert not result

  --test-- "logic-all-4"
    result: all [
      false
      false
    ]
  --assert not result
  
  --test-- "logic-all-5"
    a: all [true]
  --assert a

  --test-- "logic-all-6"
    a: all [false]
  --assert not a

  --test-- "logic-all-7"
    a: all [1 < 2 false]
  --assert not a

  --test-- "logic-all-8"
    a: all [false 1 < 2]
  --assert not a

  --test-- "logic-all-9"
    a: all [true 1 = 2]
  --assert not a

  --test-- "logic-all-10"
    a: all [1 = 2 true]
  --assert not a
  
  --test-- "logic-all-11"
    a: all [1 < 2]
  --assert a
  
  --test-- "logic-all-12"
    a: all [1 = 2]
  --assert not a
  
  --test-- "logic-all-13"
    a: all [1 < 2 3 <> 4]
  --assert a

  --test-- "logic-all-14"
    a: all [1 = 2 3 <> 4]
  --assert not a
  
  --test-- "logic-all-15"
  --assert not log-foo all [1 = 2]
   
  --test-- "logic-all-16"
  --assert log-foo all [1 < 2 3 <> 4]
  
  --test-- "logic-all-17"
  --assert not log-foo all [1 = 2 3 <> 4]

  --test-- "logic-all-18"
    a: log-foo all [1 < 2]
  --assert a 
 
  --test-- "logic-all-19"
    a: log-foo all [1 = 2]
  --assert not a
  
  --test-- "logic-all-20"
    a: log-foo all [1 < 2 3 <> 4]
  --assert a

  --test-- "logic-all-21"
      a: all [log-foo true]
  --assert a
  
===end-group===

===start-group=== "any with logic!"

  --test-- "logic-any-1"
    result: any [
      true
      true
    ]
  --assert result
  
  --test-- "logic-any-2"
    result: any [
      false
      true
    ]
  --assert result

  --test-- "logic-any-3"
    result: any [
      true
      false
    ]
  --assert result
  
  --test-- "logic-any-4"
    result: any [
      false
      false
    ]
  --assert not result
  
  --test-- "logic-any-5"
    a: any [true]
  --assert a

  --test-- "logic-any-6"
    a: any [false]
  --assert not a

  --test-- "logic-any-7"
    a: any [1 < 2 false]
  --assert a

  --test-- "logic-any-8"
    a: any [false 1 < 2]
  --assert a
   comment { 
  --test-- "logic-any-9"
    a: any [true 1 = 2]
  --assert a

  --test-- "logic-any-10"
    a: any [1 = 2 true]
  --assert a

  --test-- "logic-any-11"
  a: any [1 < 2]
  --assert a

  --test-- "logic-any-12"
    a: any [1 = 2]
  --assert not a
  
  --test-- "logic-any-13"
    a: any [1 < 2 3 <> 4]
  --assert a
 
  --test-- "logic-any-14"
    a: any [1 = 2 3 <> 4]
  --assert a
  
  --test-- "logic-any-15"
  --assert not log-foo any [1 = 2]
  
  --test-- "logic-any-16"
  --assert log-foo any [1 < 2 3 <> 4]
  
  --test-- "logic-any-17"
  --assert log-foo any [1 = 2 3 <> 4]
  
  --test-- "logic-any-18"
    a: log-foo any [1 < 2]
  --assert a 

  --test-- "logic-any-19"
    a: log-foo any [1 = 2]
  --assert not a 

  --test-- "logic-any-20"
    a: log-foo any [1 < 2 3 <> 4]
  --assert a
}
  --test-- "logic-any-21"
    a: any [log-foo true]
  --assert a

===end-group===

===start-group=== "function returning a logic value"
    lgc-test?: func [
      return: [logic!]
    ][
      either 1 < 2 [true] [false]
    ]

  --test-- "logic-return-1" 
  --assert lgc-test?

  --test-- "logic-return-2"
    a: lgc-test?
  --assert a

    lgc-test2?: func [
      return: [logic!]
    ][
      either 1 = 2 [true] [false]
    ]

  --test-- "logic-return-3"
  --assert not lgc-test2?

  --test-- "logic-return-4"
    a: lgc-test2?
  --assert not a
  
	lgc-test3?: func [return: [logic!]][
		either true [
			1 = 3
		][
			false
		]
	]
	
 --test-- "logic-return-5"
 --assert not lgc-test3?
 
	lgc-test4?: func [return: [logic!]][
		either false [
			1 = 3
		][
			false
		]
	]
	
 --test-- "logic-return-6"
 --assert not lgc-test4?
 
	lgc-test5?: func [return: [logic!]][
		either 1 < 2 [true] [false]
	]

 --test-- "logic-return-7"
 --assert lgc-test5?

===end-group===

===start-group=== "equality lgc-tests"

  --test-- "logic-=-1"
    a: false
  --assert a = false

  --test-- "logic-=-2"
    a: true
  --assert not a = false

  --test-- "logic-=-3"
    a: false
  --assert not a <> false

  --test-- "logic-=-4"
    a: true
  --assert a <> false

  --test-- "logic-=-5"
    a: false
    b: a = false
  --assert b
  
  --test-- "logic-=-6"
    a: true
    b: a = false
  --assert not b

  --test-- "logic-=-7"
    a: false
    b: false <> a
  --assert not b

  --test-- "logic-=-8"
    a: true
    b: false <> a
  --assert b
  
  --test-- "logic-=-9"
    a: false
  --assert log-foo a = false
  
  --test-- "logic-=-10"
    a: false
  --assert log-foo a = false
  
  --test-- "logic-=-11"
    a: true
  --assert not log-foo a = false
  
===end-group===

===start-group=== "logic value returned by function"

	fooT: func [return: [logic!]][1 < 2]
	fooF: func [return: [logic!]][1 = 2]

	--test-- "logic-ret-1" --assert fooT
	--test-- "logic-ret-2" --assert not fooF

===end-group===

~~~end-file~~~
