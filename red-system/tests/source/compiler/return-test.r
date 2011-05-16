REBOL [
	Title:   "Red/System RETURN keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %return-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

qt/start-file "return-compile"

;; test of return as last statement in until block
write %runnable/return.reds 
  {Red/System[]
    until [return]
  }
exe: qt/compile src: %runnable/return.reds
qt/assert "return-compile-2" none <> find qt/comp-output "*** Compilation Error: datatype not allowed"
if exists? %runnable/return.reds [delete %runnable/return.reds]
if all [
  exe
  exists? exe
][
  delete exe
]

qt/end-file


