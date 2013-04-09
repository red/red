Red/System [
  Title:   "Red/System ZLib Binding"
  Author:  "Bruno Anselme"
  EMail:   "be.red@free.fr"
  File:    %zlibs.reds
  Rights:  "Copyright (c) 2013 Bruno Anselme"
  License: {
    Distributed under the Boost Software License, Version 1.0.
    See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
  }
  Needs: {
    Red/System >= 0.3.2
    zlib       >= 1.2.6
  }
  References: {
    http://www.zlib.net/
  }
]

zlib: context [

  #switch OS [
    Windows   [
      #define z-library "zlib1.dll"
    ]
    MacOSX    [
      #define z-library "libz.1.dylib"  ; TODO: check this
    ]
    #default  [
      #define z-library "libz.so.1"
    ]
  ]

  z_stream!: alias struct! [
    next_in        [byte-ptr!]     ; next input byte
    avail_in       [integer!]      ; number of bytes available at next_in
    total_in       [integer!]      ; total number of input bytes read so far

    next_out       [byte-ptr!]     ; next output byte should be put there
    avail_out      [integer!]      ; remaining free space at next_out
    total_out      [integer!]      ; total number of bytes output so far

    msg            [c-string!]     ; last error message, NULL if no error
    state          [integer!]      ; not visible by applications

    zalloc         [integer!]      ; used to allocate the internal state (function pointer)
    zfree          [integer!]      ; used to free the internal state (function pointer)
    opaque         [integer!]      ; private data object passed to zalloc and zfree (function pointer)

    data_type      [integer!]      ; best guess about the data type: binary or text
    adler          [integer!]      ; adler32 value of the uncompressed data
    reserved       [integer!]      ; reserved for future use
  ]

  #import [z-library cdecl [
    version: "zlibVersion" [       ; Return zlib library version.
      return:   [c-string!]
    ]

  ] ; cdecl
  ] ; #import [z-library

  ; Higher level interface --------------------------------------------------------------------

  with zlib [

  ] ; with zlib
] ; context zlib
