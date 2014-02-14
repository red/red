Red/System [
  Title:   "Red/System call example"
  Author:  "Bruno Anselme"
  EMail:   "be.red@free.fr"
  File:    %call-example.reds
  Rights:  "Copyright (c) 2014 Bruno Anselme"
  License: {
    Distributed under the Boost Software License, Version 1.0.
    See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
  }
  Needs: {
    Red/System >= 0.4.1
  }
]

#include %../call.reds

print-cmd: func [ cmd [c-string!] /local err [integer!]][
  print [ "Command    : " cmd lf ]
  print [ "------------------------------------" lf ]
  err: syscalls/call cmd false
  if err <> 0 [
    print [ "Error code : " err lf ]
  ]
  print [ "------------------------------------" lf ]
]

show-calls: func [
][
  print [ "--- Call examples ---" lf ]
  #switch OS [
    Windows   [
      print-cmd "notepad"
      print-cmd "mspaint"
      print-cmd "explorer"
      print-cmd "dir"
    ]
    #default  [
      print-cmd "uptime"
      print-cmd "ls"
      print-cmd "cat /proc/version"
      print-cmd "ps a"
      print-cmd "ls -l *.r"
      print-cmd "echo $UNDEFINED_VAR"
      print-cmd "top"
      print-cmd "ls &"         ; should fail
      print-cmd {ls "*.r}      ; should fail
    ]
  ]
]

show-calls
;syscalls/print-str-array system/env-vars  ; Only Linux

print [ "That's all folks..." lf ]
