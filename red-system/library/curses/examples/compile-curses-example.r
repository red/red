REBOL [
  Title:   "Compilation script for curses-example.reds"
  Author:  "Bruno Anselme"
  EMail:   "be.red@free.fr"
  File:    %compile-curses-example.r
  Rights:  "Copyright (c) 2013 Bruno Anselme"
  License: {
    Distributed under the Boost Software License, Version 1.0.
    See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
  }
  Usage:   {
    from command line : pathtorebol/rebol -s compile-curses-example.r
  }
]

windows: all [(system/version/4 = 3) (system/version/5 = 1)]

appname: "curses-example"
wdir: what-dir
change-dir %../../../                ; locate here your red-system directory
print [ "------ Compiling" appname "------" ]
do/args %rsc.r rejoin [ wdir  %curses-example.reds ]

either windows [
  print rejoin [ "Destination file :  ../../builds/" appname ".exe" ]
][
  print rejoin [ "Destination file : ../../../builds/" appname ]
]