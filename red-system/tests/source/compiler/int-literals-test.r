REBOL [
  Title: "Red/System compilation error test"
  File:  %int-literals-test.r
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                   ;; revert to tests/ dir (from runnable)
  
qt/start-file "int-literals-err"

;; int-literals-1
write %runnable/int-literals.reds {
  Red/System []
  i: FFFFFFFFh
}
qt/compile %runnable/int-literals.reds
if exists? %runnable/int-literals.reds [delete %runnable/int-literals.reds]
qt/assert "int-literals-l" qt/compile-ok?

qt/end-file

