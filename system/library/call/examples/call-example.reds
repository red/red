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

print-cmd: func [
  waitend    [logic!]
  cmd        [c-string!]
  /local err [integer!]
][
  print [ "Command    : " cmd lf ]
  print [ "------------------------------------" lf ]
  err: syscalls/call cmd waitend
  if err <> 0 [
    print [ "Pid returned : " err lf ]
  ]
  print [ "------------------------------------" lf ]
]

show-calls: func [
][
  print [ "--- Call examples ---" lf ]
  #switch OS [
    Windows   [
      print-cmd false "notepad"
      print-cmd false "mspaint"
      print-cmd false "explorer"
      print-cmd true  "dir"
    ]
    #default  [
      print-cmd true  "uptime"
      print-cmd true  "cat /proc/version"
      print-cmd true  "ps a"
      print-cmd true  "ls"
      print-cmd true  "ls -l *.r"
      print-cmd true  "echo $UNDEFINED_VAR"  ; Word expansion should fail
      print-cmd true  "ls &"                 ; Word expansion should fail
      print-cmd true  {ls "*.r}              ; Word expansion should fail
;      print-cmd "top"
;      print-cmd false "firefox"
    ]
  ]
]

show-calls
;syscalls/print-str-array system/env-vars  ; Only Linux

print [ "That's all folks..." lf ]
