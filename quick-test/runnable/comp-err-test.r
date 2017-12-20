REBOL [
  Title: "Red/System compilation error test"
  File:  %comp-err-test.r
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                   ;; revert to tests/ dir (from runnable)
  
~~~start-file~~~ "comp-err"

  --test-- "sample compilation error test"
  --compile-this {
	  Red/System []
      i := 1;
    }
  --assert parse qt/comp-output [
  	  thru "*** Compilation Error: undefined symbol"
  	  thru "at line: 3"
  	  thru "near: [" thru "i := 1" thru "]"
  	  to end
  ]
  --clean


 --test-- "error line reporting test"
  --compile-this {
	  Red/System []
      foo: func [][
      	if true [
      		either true [
      			a
      		][
      			123
      		]
      	]
      ]
    }     
  --assert parse qt/comp-output [
  	  thru "*** Compilation Error: undefined symbol: a"
  	  thru "at line: 6"
  	  to end
  ]
  --clean

  
~~~end-file~~~

