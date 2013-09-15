REBOL [
  Title: "Red/System compilation error test"
  File:  %int-literals-test.r
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                   ;; revert to tests/ dir (from runnable)
  
~~~start-file~~~ "int-literals-err"

  --test-- "int-literals-1"
  --compile-this {
      Red/System [] 
      i: FFFFFFFFh
    }
  --assert qt/compile-ok?
  --clean
  
~~~end-file~~~

