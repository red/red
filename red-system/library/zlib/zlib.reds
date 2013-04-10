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

  #define opaque!  integer!
  #define Z_NULL  0             ; for initializing zalloc, zfree, opaque
  #define ZLIB_VERSION "1.2.6"

  ; Allowed flush values.
  #define Z_NO_FLUSH       0
  #define Z_PARTIAL_FLUSH  1
  #define Z_SYNC_FLUSH     2
  #define Z_FULL_FLUSH     3
  #define Z_FINISH         4
  #define Z_BLOCK          5
  #define Z_TREES          6

  ; Return codes for the compression/decompression functions. Negative values
  ;  are errors, positive values are used for special but normal events.
  #define Z_OK             0
  #define Z_STREAM_END     1
  #define Z_NEED_DICT      2
  #define Z_ERRNO         -1
  #define Z_STREAM_ERROR  -2
  #define Z_DATA_ERROR    -3
  #define Z_MEM_ERROR     -4
  #define Z_BUF_ERROR     -5
  #define Z_VERSION_ERROR -6

  ; Compression levels
  #define Z_NO_COMPRESSION         0
  #define Z_BEST_SPEED             1
  #define Z_BEST_COMPRESSION       9
  #define Z_DEFAULT_COMPRESSION   -1

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

    zalloc         [opaque!]       ; used to allocate the internal state (function pointer)
    zfree          [opaque!]       ; used to free the internal state (function pointer)
    opaque         [opaque!]       ; private data object passed to zalloc and zfree (function pointer)

    data_type      [integer!]      ; best guess about the data type: binary or text
    adler          [integer!]      ; adler32 value of the uncompressed data
    reserved       [integer!]      ; reserved for future use
  ]


  #import [z-library cdecl [
    version: "zlibVersion" [       ; Return zlib library version.
      return:   [c-string!]
    ]

    deflateInit_: "deflateInit_" [
      strm         [z_stream!]
      level        [integer!]
      version      [c-string!]
      stream_size  [integer!]
      return:      [integer!]
    ]

    deflateEnd: "deflateEnd" [
      strm         [z_stream!]
      return:      [integer!]
    ]

    deflate: "deflate" [
      strm         [z_stream!]
      flush        [integer!]
      return:      [integer!]
    ]

  ] ; cdecl
  ] ; #import [z-library

  ; Higher level interface --------------------------------------------------------------------
;  #define CHUNK 16384

  with zlib [

    deflateInit: function [
      strm         [z_stream!]
      level        [integer!]
      return:      [integer!]
    ][
      deflateInit_ strm level ZLIB_VERSION size? z_stream!
    ]

    compress: func [
      buf-in   [byte-ptr!]
      count    [integer!]
      buf-out  [byte-ptr!]
      level    [integer!]
      return:  [integer!]
      /local ret flush have nbytes
             strm     [z_stream!]
    ][
      strm: as z_stream! allocate (size? z_stream!)
      strm/zalloc: Z_NULL
      strm/zfree: Z_NULL
      strm/opaque: Z_NULL
      ret: deflateInit strm level
      if ret <> Z_OK [
        print "Error deflateInit"
      ]
      flush: Z_FINISH
      strm/avail_in: count
      strm/next_in: buf-in
      strm/avail_out: count
      strm/next_out: buf-out
      ret: deflate strm flush
      have: count - strm/avail_out
      deflateEnd strm
      free as byte-ptr! strm
      return have
    ]

  ] ; with zlib
] ; context zlib
