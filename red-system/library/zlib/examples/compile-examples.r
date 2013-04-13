REBOL [
  Title:   "Compilation script for Red/System examples"
  Author:  "Bruno Anselme"
  EMail:   "be.red@free.fr"
  File:    %compile-examples.r
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

compile: func [
  appname [string!]
][
  print [ "------ Compiling" appname "------" ]
  do/args %rsc.r rejoin [ wdir appname %.reds ]

  either windows [
    print rejoin [ "Destination file :  ../../../builds/" appname ".exe" ]
  ][
    print rejoin [ "Destination file : ../../../builds/" appname ]
  ]
]

wdir: what-dir
change-dir %../../../                ; locate here your red-system directory
;compile "zlib-mem-example"
compile "zlib-disk-example"

