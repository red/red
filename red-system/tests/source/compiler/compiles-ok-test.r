REBOL [
  Title: "Test successful compilations from Red/System programs"
  File:  %compiles-ok-test.r
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                        ;; revert to tests/ directory from runnable/
  
~~~start-file~~~ "compiles-ok"

===start-group=== "reported issues"

  --test-- "issue #417"
  --assert --compiled? {
      Red/System[]
      {
        REBOL []
      }
    }
    
===end-group===
  
~~~end-file~~~
