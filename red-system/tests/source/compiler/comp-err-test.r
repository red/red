REBOL [
  Title: "Red/System compilation error test"
  File:  %comp-err-test.r
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                   ;; revert to tests/ dir (from runnable)
  
~~~start-file~~~ "comp-err"

  --test-- "sample compilation error test"
  --compile-this {
      i := 1;
    }     
  --assert none <> find qt/comp-output "*** Compilation Error: undefined symbol"
  --assert none <> find qt/comp-output "line: 3"
  --assert none <> find qt/comp-output "at: [i := 1]"
  --clean
  
~~~end-file~~~

