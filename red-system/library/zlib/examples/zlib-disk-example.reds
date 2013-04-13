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

test-disk-deflate: func [
  f-in        [c-string!]
  f-out       [c-string!]
  return:     [integer!]
  /local fnum-in fnum-out ret
][
  print [ lf "----------------------------------------" lf ]
  print [ "From file : " f-in lf ]
  print [ "To file   : " f-out lf ]
  fnum-in:  open-file f-in  "r"
  if fnum-in = 0 [
    print [ "Error opening : " f-in lf ]
    return -1
  ]
  fnum-out: open-file f-out "w"
  if fnum-out = 0 [
    print [ "Error creating : " f-out lf ]
    return -1
  ]
  ret: zlib/deflate fnum-in fnum-out Z_DEFAULT_COMPRESSION
  if ret <> Z_OK [
    print [ "Error compressing file '" f-in "' to '" f-out "'" lf ]
  ]
  close-file fnum-in
  close-file fnum-out
  return 0
]

file-in:  "zlib-mem-example.reds"
file-out: "zlib-mem-example.reds.z"

test-disk-deflate file-in file-out
