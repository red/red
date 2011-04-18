REBOL [
  Title: "Test output from Red/System programs"
  File:  %output-test.r
  License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

change-dir %../                        ;; revert to tests/ directory from runnable/
  
qt/start-file "output"

either exe: qt/compile src: %source/compiler/hello.reds [
  qt/run exe
  qt/assert "hello 1" none <> find qt/output "hello"
  qt/assert "hello 2" none <> find qt/output "world"
][
  qt/compile-error src
]

either exe: qt/compile src: %source/compiler/empty.reds [
  qt/run exe
  qt/assert "empty" qt/output = ""
][
  qt/compile-error src
]

qt/end-file
