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

#include %../stdio.reds

zlib: context [

  #import [
    LIBC-file cdecl [
      re-allocate:  "realloc" [
        base       [byte-ptr!]
        size       [integer!]
        return:    [byte-ptr!]
      ]
    ]
  ]

  #define opaque!  integer!
  #define gzfile!  integer!
  #define Z_NULL  0             ; for initializing zalloc, zfree, opaque

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

  ; Possible values of the data_type field
  #define Z_BINARY     0
  #define Z_TEXT       1
  #define Z_ASCII      1                ; For compatibility with 1.2.2 and earlier
  #define Z_UNKNOWN    2

  ; The deflate compression method (the only one supported in this version)
  #define Z_DEFLATED   8

  ; Compression strategy
  #define Z_FILTERED            1
  #define Z_HUFFMAN_ONLY        2
  #define Z_RLE                 3
  #define Z_FIXED               4
  #define Z_DEFAULT_STRATEGY    0

  #define WINDOW_BITS      15
  #define ENABLE_ZLIB_GZIP 32

  #define CHUNK 16384                   ; Buffer size for file (de)compression

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

  #import [z-library cdecl [
    version: "zlibVersion" [       ; Return zlib library version.
      return:   [c-string!]
    ]

    z-compressBound: "compressBound" [
      sourceLen    [integer!]
      return:      [integer!]
    ]

    z-compress: "compress2" [
      out-buf      [byte-ptr!]           "Pointer to destination data"
      out-count    [int-ptr!]            "Pointer to destination size, returns output buffer size"
      in-buf       [byte-ptr!]           "Pointer to source data"
      in-count     [integer!]            "Source data count (bytes)"
      level        [integer!]            "Compression level"
      return:      [integer!]
    ]

    z-uncompress: "uncompress" [
      out-buf      [byte-ptr!]           "Pointer to destination data"
      out-count    [int-ptr!]            "Pointer to destination size, returns output buffer size"
      in-buf       [byte-ptr!]           "Pointer to source data"
      in-count     [integer!]            "Source data count (bytes)"
      return:      [integer!]
    ]

    gzopen: "gzopen" [
      filename     [c-string!]
      mode         [c-string!]
      return:      [gzfile!]
    ]

    gzclose: "gzclose" [
      file         [gzfile!]
      return:      [integer!]
    ]

    gzread: "gzread" [
      file         [gzfile!]
      buffer       [byte-ptr!]
      length       [integer!]
      return:      [integer!]
    ]

    gzwrite: "gzwrite" [
      file         [gzfile!]
      buffer       [byte-ptr!]
      length       [integer!]
      return:      [integer!]
    ]

    gzeof: "gzeof" [
      file         [gzfile!]
      return:      [integer!]
    ]

    gzerror: "gzerror" [
      file         [gzfile!]
      errnum       [int-ptr!]
      return:      [c-string!]
    ]

  ] ; cdecl
  ] ; #import [z-library

  ; Higher level interface ---------------------------- ---------------------------------------

  with zlib [

    gunzip: function [             "Gunzip a file into another file"
      file-in      [c-string!]     "A gzipped file"
      file-out     [c-string!]
      return:      [integer!]
      /local
        file       [file!]
        zfile      [gzfile!]
        error      [integer!]
        buffer     [byte-ptr!]
        bytes-read [integer!]

    ][
      zfile: gzopen file-in "rb"
      if zfile = 0 [
        print [ "gunzip: gzopen of " file-in " failed." lf ]
        return Z_ERRNO
      ]
      file: open-file file-out "wb"
      if file = 0 [
        print [ "gunzip: Error opening " file-out lf ]
        return Z_ERRNO
      ]
      buffer: allocate CHUNK
      if buffer = NULL [
        print [ "gunzip: Buffer allocation error." lf ]
        return Z_ERRNO
      ]
      until [
        bytes-read: gzread zfile buffer (CHUNK - 1)
        write-file buffer bytes-read 1 file
        0 <> (gzeof zfile)
      ]
      close-file file
      gzclose zfile
      free buffer
      return Z_OK
    ]

    gzip: function [               "Gzip a file into another file"
      file-in      [c-string!]
      file-out     [c-string!]     "A gzipped file"
      return:      [integer!]
      /local
        file       [file!]
        zfile      [gzfile!]
        error      [integer!]
        buffer     [byte-ptr!]
        bytes-read [integer!]
    ][
      file: open-file file-in "rb"
      if file = 0 [
        print [ "gzip: Error opening " file-in lf ]
        return Z_ERRNO
      ]
      zfile: gzopen file-out "wb"
      if zfile = 0 [
        print [ "gzip: Error opening " file-out lf ]
        return Z_ERRNO
      ]
      buffer: allocate CHUNK
      if buffer = NULL [
        print [ "gzip: Buffer allocation error." lf ]
        return Z_ERRNO
      ]
      until [
        bytes-read: read-file buffer 1 CHUNK file
        gzwrite zfile buffer bytes-read
        file-tail? file
      ]
      close-file file
      gzclose zfile
      free buffer
      return Z_OK
    ]

    compress: func [                     "Compress a byte array"
      in-buf       [byte-ptr!]           "Pointer to source data"
      in-count     [integer!]            "Source data count (bytes)"
      out-count    [int-ptr!]            "Pointer to integer, returns output buffer size"
      level        [integer!]            "Compression level"
      return:      [byte-ptr!]           "Returns a pointer to compressed data"
      /local ret out-buf tmp
    ][
      out-count/value: z-compressBound in-count
      out-buf: allocate out-count/value         ; allocate the size of original buffer
      if out-buf = NULL [
        print [ "Compress Error : Output buffer allocation error." lf ]
        return NULL
      ]
      ret: z-compress out-buf out-count in-buf in-count level
      either ret = Z_OK [
        tmp: re-allocate out-buf out-count/value        ; Resize output buffer to minimum size
        either tmp = NULL [                             ; reallocation failed, uses current output buffer
          print [ "Compress Warning : Impossible to reallocate output buffer." lf ]
        ][                                              ; reallocation succeeded, uses reallocated buffer
          out-buf: tmp
        ]
        return out-buf
      ][
        case [
          ret = Z_MEM_ERROR    [ print [ "Compress Error : not enough memory." lf ] ]
          ret = Z_BUF_ERROR    [ print [ "Compress Error : not enough room in the output buffer." lf ] ]
          ret = Z_STREAM_ERROR [ print [ "Compress Error : invalid compression level parameter." lf ] ]
        ]
        free out-buf
        return NULL
      ]
    ] ; compress

    decompress: func [                   "Decompress a byte array"
      in-buf       [byte-ptr!]           "Pointer to source data"
      in-count     [integer!]            "Source data count (bytes)"
      return:      [byte-ptr!]           "Return a pointer to decompressed data"
      /local ret out-buf tmp
      out-count    [integer!]
    ][
      out-count: 2 * in-count                             ; allocate twice the size of original buffer
      out-buf: allocate out-count
      if out-buf = NULL [
        print [ "Decompress Error : Output buffer allocation error." lf ]
        return NULL
      ]
      until [
        ret: z-uncompress out-buf :out-count in-buf in-count
        if ret = Z_BUF_ERROR [                            ; need to expand output buffer
          out-count: 2 * out-count                        ; double buffer size
          tmp: re-allocate out-buf out-count              ; Resize output buffer to minimum size
          either tmp = NULL [                             ; reallocation failed, uses current output buffer
            print [ "Decompress Error : Impossible to reallocate output buffer." lf ]
            ret: Z_MEM_ERROR
          ][                                              ; reallocation succeeded, uses reallocated buffer
            out-buf: tmp
          ]
        ]
        any [ (ret = Z_OK) (ret = Z_MEM_ERROR) (ret = Z_STREAM_ERROR) ]
      ]
      either ret = Z_OK [
        tmp: re-allocate out-buf out-count              ; Resize output buffer to minimum size
        either tmp = NULL [                             ; reallocation failed, uses current output buffer
          print [ "Decompress Warning : Impossible to reallocate output buffer." lf ]
        ][                                              ; reallocation succeeded, uses reallocated buffer
          out-buf: tmp
        ]
        return out-buf
      ][
        case [
          ret = Z_MEM_ERROR    [ print [ "Decompress Error : not enough memory." lf ] ]
          ret = Z_BUF_ERROR    [ print [ "Decompress Error : not enough room in the output buffer." lf ] ]
          ret = Z_STREAM_ERROR [ print [ "Decompress Error : invalid compression level parameter." lf ] ]
        ]
      ]
      return out-buf
    ]

    bin-to-str: func [             "Convert a byte array into an hex string."
      address [byte-ptr!]          "Memory address where the conversion starts"
      limit   [integer!]           "Number of bytes to convert"
      return: [c-string!]          "Return a c string"
      /local i str cnum byte major minor
    ][
      str: make-c-string (1 + (2 * limit))
      i: 0
      cnum: 0
      until [
        byte: as integer! address/value
        minor: byte // 16
        if minor > 9 [minor: minor + 7]         ;-- 7 = (#"A" - 1) - #"9"
        byte: byte >>> 4
        major: byte // 16
        if major > 9 [major: major + 7]         ;-- 7 = (#"A" - 1) - #"9"

        cnum: cnum + 1
        str/cnum: #"0" + major
        cnum: cnum + 1
        str/cnum: #"0" + minor

        address: address + 1
        i: i + 1
        i = limit
      ]
      cnum: cnum + 1
      str/cnum: #"^(00)"  ; c string ending char
      str
    ]
  ] ; with zlib
] ; context zlib
