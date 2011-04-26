REBOL [
	Title:   "Red/System EXIT keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %exit-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

qt/start-file "exit-compile"

;; simple test of complie and run
write %runnable/exit.reds "Red/System[]^/test: does [exit]^/test" 
either exe: qt/compile src: %runnable/exit.reds [
  qt/run exe
  qt/assert "exit-compile-1" qt/output = ""
][
  qt/compile-error src 
]
if exists? %runnable/exit.reds [delete %runnable/exit.reds]
if all [
  exe
  exists? exe
][
  delete exe
]

;; test of exit as last statement in until block
write %runnable/exit.reds 
  {Red/System[]
    until [exit]
  }
exe: qt/compile src: %runnable/exit.reds
qt/assert "exit-compile-2" none <> find qt/comp-output "*** datatype not allowed"
if exists? %runnable/exit.reds [delete %runnable/exit.reds]
if all
[
  exe
  exists? exe
][
  delete exe
]

qt/end-file


