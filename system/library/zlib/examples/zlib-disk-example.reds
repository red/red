Red/System [
  Title:   "ZLib, gzip example"
  Author:  "Bruno Anselme"
  EMail:   "be.red@free.fr"
  File:    %zlib-disk-example.reds
  Rights:  "Copyright (c) 2013-2015 Bruno Anselme"
  License: {
    Distributed under the Boost Software License, Version 1.0.
    See https://github.com/red/red/blob/master/BSL-License.txt
  }
  Needs: {
    Red/System >= 0.3.2
    zlib       >= 1.2.6
  }
]


#include %../zlib.reds

print [ "Gzip example" lf ]
print [ "Zlib version : " zlib/version lf ]

file-to-zip: "red.r"
zipped-file: "red.r.gz"
unzipped-file: "unzipped-red.r"

print [ "Gzip " file-to-zip " into " zipped-file lf ]
retval: zlib/gzip file-to-zip zipped-file

if retval = Z_OK [
  print [ "Gunzip " zipped-file " into " unzipped-file lf ]
  zlib/gunzip zipped-file unzipped-file
]