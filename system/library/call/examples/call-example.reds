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
          call "msconfig 1 2 3 4 5"
          print [ "---------------------" lf ]
          call "msconfig 1 2 3 4 5"
          print [ "---------------------" lf ]
          call "msconfig 1 2 3 4 5"
          print [ "---------------------" lf ]
          call "dir"
          print [ "---------------------" lf ]
          call "dir C:\"
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
  free-str-array str2array "ls"
  free-str-array str2array "cat /proc/version"
  free-str-array str2array "dir .. \w"
  free-str-array str2array "msconfig 1 2 3 4 5 6 7 8"
  print [ "That's all folks..." lf ]
]