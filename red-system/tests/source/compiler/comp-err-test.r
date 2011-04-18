REBOL [
  Title: "Red/System compilation error test"
  File:  %comp-err-test.r
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                   ;; revert to tests/ dir (from runnable)
  
qt/start-file "comp-err"

write %runnable/comp-err.reds {
  Red/System []
  i := 1;
}

qt/compile %runnable/comp-err.reds
if exists? %runnable/comp-err.reds [delete %runnable/comp-err.reds]
qt/assert "ce1-l1" none <> find qt/comp-output "*** undefined symbol"
qt/assert "ce1-l2" none <> find qt/comp-output "at:  ["
qt/assert "ce1-l3" none <> find qt/comp-output "i := 1"
qt/assert "ce1-l4" none <> find qt/comp-output "]"

qt/end-file

