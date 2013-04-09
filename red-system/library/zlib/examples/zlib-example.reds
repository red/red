Red/System [
  Title:   "ZLib example"
  Author:  "Bruno Anselme"
  EMail:   "be.red@free.fr"
  File:    %zlib-example.reds
  Rights:  "Copyright (c) 2013 Bruno Anselme"
  License: {
    Distributed under the Boost Software License, Version 1.0.
    See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
  }
  Needs: {
    Red/System >= 0.3.2
    zlib       >= 1.2.6
  }
]


;#include %../../../runtime/libc.reds
#include %../zlib.reds

  #switch OS [
    Windows   [ op-sys: "Windows" op-num: 1 ]
    MacOSX    [ op-sys: "MacOSX"  op-num: 2 ]
    #default  [ op-sys: "Linux"   op-num: 0 ]
  ]

with [ zlib ] [
  print [ "Zlib version : " version lf ]

  text: {Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.}

  print [ text lf ]

  ret: as c-string! compress as byte-ptr! text length? text Z_DEFAULT_COMPRESSION

  print [ ret lf ]
]