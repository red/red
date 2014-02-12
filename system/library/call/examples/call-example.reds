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
  print [ "--- Call examples ---" lf ]
  call "cat /proc/version"
  print [ "---------------------" lf ]
  call "uptime"
  print [ "---------------------" lf ]
  call "ps a"
  print [ "---------------------" lf ]
  call "ls -l"
  print [ "---------------------" lf ]
  print [ "That's all folks..." lf ]
]