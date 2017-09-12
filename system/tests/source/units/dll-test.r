Rebol [
	Title:   "Red/System dynamic link library test script"
	Author:  "Peter W A Wood"
	File: 	 %dll-test.reds
	Rights:  "Copyright (C) 2012-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

~~~start-file~~~ "dll-test"

runnable-dir: what-dir

change-dir %../                        ;; to tests dir

src: {
Red/System []

#include %../../../quick-test/quick-test.reds

#import [
  "***pre***test-dll1***post***" cdecl [
    dll1-add-one: "add-one" [
      i       [integer!]
      return: [integer!]
    ]
  ]
]

~~~start-file~~~ "dll"
  
===start-group=== "functions"
  --test-- "dllf1"
  --assert 2 = dll1-add-one 1
  
  --test-- "dllf2"    
  --assert -2147483647 = dll1-add-one -2147483648
  
  --test-- "dllf3"
  --assert -2147483648 = dll1-add-one 2147483647
 
===end-group===
  
~~~end-file~~~
}

;; compile dll1-test.reds
--compile-dll clean-path join runnable-dir %../source/units/test-dll1.reds

either qt/compile-ok? [
  ;; insert the full-path of the dll1-test lib into the source and write to runnable
  switch/default fourth system/version [
    3 [
      replace src "***pre***" ""
      replace src "***post***" ".dll"
    ]
    2 [
      replace src "***pre***" "lib"
      replace src "***post***" ".dylib"
    ]
  ][
    replace src "***pre***" "lib"
    replace src "***post***" ".so"
  ]
  write runnable-dir/src.reds src
  
  ;; compile and run the test
  --compile-run-print runnable-dir/src.reds
][
  print ["Compilation error in dll" qt/comp-output]
]

~~~end-file~~~
