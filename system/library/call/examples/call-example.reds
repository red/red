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

with syscalls [
;  print [ "Sleep one second" lf ]
;  sleep 1
  print [ "--- Call examples ---" lf ]
  pid: call "ls -l"
  pid: call "ps a"
  print [ "That's all folks..." lf ]
]