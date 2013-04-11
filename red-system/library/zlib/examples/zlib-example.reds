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

print [ "Zlib version : " zlib/version lf ]

test-functions: func [
  text      [c-string!]
  /local byte-count buffer dec-text
][
  print [ lf "----------------------------------------" lf ]
  byte-count: 0
  buffer: zlib/compress (as byte-ptr! text) (length? text) :byte-count Z_DEFAULT_COMPRESSION

  either buffer = NULL [
    print [ "Error compressing..." lf ]
  ][
    dec-text: as c-string! zlib/decompress buffer byte-count
    print [ "Original text     : " lf text lf ]
    print [ "Compressed data   : " lf zlib/bin-to-str buffer byte-count lf ]
    print [ "Text size         : " length? text " bytes" lf ]
    print [ "Compressed size   : " byte-count " bytes" lf ]
    print [ "Compression ratio : " (100 * byte-count / (length? text)) "%" lf ]
    print [ "Decompressed text : " lf dec-text lf ]
    free as byte-ptr! dec-text
    free buffer
  ]
]

  test-functions {Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.}

  ; Repeating string, highly compressible
  test-functions {Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world,
Hello Red world, Hello Red world, Hello Red world, Hello Red world.}
