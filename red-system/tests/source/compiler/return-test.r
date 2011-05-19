REBOL [
	Title:   "Red/System RETURN keyword test script"
	Author:  "Nenad Rakocevic"
	File: 	 %return-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

change-dir %../

~~~start-file~~~ "return-compile"

  --test-- "return as last statement in until block"
    write %runnable/return.reds 
      {Red/System[]
      until [return]
    }
    exe: --compile src: %runnable/return.reds
    --assert none <> find qt/comp-output "*** Compilation Error: datatype not allowed"
    if exists? %runnable/return.reds [delete %runnable/return.reds]
    if all [
      exe
      exists? exe
    ][
      delete exe
    ]

~~~end-file~~~


