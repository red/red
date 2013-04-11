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


#include %../zlib.reds

  #switch OS [
    Windows   [ op-sys: "Windows" ]
    MacOSX    [ op-sys: "MacOSX"  ]
    #default  [ op-sys: "Linux"   ]
  ]

with [ zlib ] [
  print [ "Zlib version : " version lf ]

  text: {Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.}

  byte-count: 0
  buffer: compress (as byte-ptr! text) (length? text) :byte-count Z_DEFAULT_COMPRESSION

  either buffer = NULL [
    print [ "Error compressing..." lf ]
  ][
    print [ "Original text     : " lf text lf ]
  ;  hex-dump buffer byte-count
    print [ "Compressed data   : " lf bin-to-str buffer byte-count lf ]
    print [ "Text size         : " length? text " bytes" lf ]
    print [ "Compressed size   : " byte-count " bytes" lf ]
    print [ "Compression ratio : " (100 * byte-count / (length? text)) "%" lf ]
  ]

  print [ lf lf ]
  dec: as c-string! decompress buffer byte-count
  print [ dec lf ]
  free buffer
]
