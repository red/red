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
  show-calls: func [
    ][
      print [ "--- Call examples ---" lf ]
      #switch OS [
        Windows   [
          call "dir"
          print [ "---------------------" lf ]
          call "dir C:\"
          print [ "---------------------" lf ]
          call "msconfig"
          print [ "---------------------" lf ]
        ]
        #default  [
          call "cat /proc/version"
          print [ "---------------------" lf ]
          call "uptime"
          print [ "---------------------" lf ]
          call "ps a"
          print [ "---------------------" lf ]
          call "ls -l"
          print [ "---------------------" lf ]
        ]
      ]
    ]

  ; show-calls
  str2array "dir .."
  print [ "That's all folks..." lf ]
]