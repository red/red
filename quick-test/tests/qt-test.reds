Red/System [
	Title:   "Red/System simple testing framework tests"
	Author:  "Peter W A Wood"
	File: 	 %qt-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#include %../quick-test.reds

***start-run*** "Test Run 1"

~~~start-file~~~  "First Test Set"

===start-group=== "My First Group"

  --test-- "Test 1"
  --assert (true)                                      ;; pass
  
  --test-- "Test 2"
  --assert (true)                                      ;; pass
  --assert (true)                                      ;; pass
  
  --test-- "Test 3"
  --assert (false)                                     ;; fail
  
  --test-- "Test 4"
  --assert 1 = 1                                       ;; pass
  
  --test-- "Test 5"
  --assert 1 = 2                                       ;; fail

  --test-- "Test 6"                              ;; a longer test
    step1: 1
    step2: 2
    step3: 3
    step4: step1 + step2 + step3
  --assert step4 = 6                                    ;;pass
  
===end-group===

===start-group=== "My second group"

  --test-- "msg-1"
  --assert true
  
  --test-- "msg-2"
  --assert true

===end-group===

===start-group=== "My third group"

  --test-- "mtg-1"
  --assert false
  
  --test-- "mtg-2"
  --assert true
  
===end-group===

~~~end-file~~~ 

~~~start-file~~~ "Second Test Set"
  
  --test-- "Test 7"
  --assert true
  
  --test-- "Test 8"
  --assert false

~~~end-file~~~ 

***end-run***

