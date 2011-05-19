REBOL [
  Title: "Red/System compilation error test"
  File:  %comp-err-test.r
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                   ;; revert to tests/ dir (from runnable)
  
~~~start-file~~~ "comp-err"

  --test-- "sample compilation error test"
    write %runnable/comp-err.reds {
      Red/System []
      i := 1;
    }

  --compile %runnable/comp-err.reds
    if exists? %runnable/comp-err.reds [delete %runnable/comp-err.reds]
  --assert none <> find qt/comp-output "*** Compilation Error: undefined symbol"
  --assert none <> find qt/comp-output "at:  ["
  --assert none <> find qt/comp-output "i := 1"
  --assert none <> find qt/comp-output "]"

~~~end-file~~~

