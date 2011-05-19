REBOL [
	Title:   "Red/System EXIT keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %exit-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "exit-compile"

  --test-- "simple test of compile and run"
    write %runnable/exit.reds "Red/System[]^/test: does [exit]^/test" 
    either exe: --compile src: %runnable/exit.reds [
      --run exe
      --assert qt/output = ""
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

  --test-- "exit as last statement in until block"
    write %runnable/exit.reds 
      {Red/System[]
        until [exit]
      }
    exe: --compile src: %runnable/exit.reds
    --assert none <> find qt/comp-output "*** Compilation Error: datatype not allowed"
      if exists? %runnable/exit.reds [delete %runnable/exit.reds]
      if all [
        exe
        exists? exe
      ][
        delete exe
      ]

~~~end-file~~~


