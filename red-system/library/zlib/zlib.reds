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

    deflateInit2_: "deflateInit2_" [
      strm         [z_stream!]
      level        [integer!]
      method       [integer!]
      windowBits   [integer!]
      memlevel     [integer!]
      strategy     [integer!]
      return:      [integer!]
    ]

    z-deflateEnd: "deflateEnd" [
      strm         [z_stream!]
      return:      [integer!]
    ]

    z-deflate: "deflate" [
      strm         [z_stream!]
      flush        [integer!]
      return:      [integer!]
    ]

    inflateInit_: "inflateInit_" [
      strm         [z_stream!]
      version      [c-string!]
      stream_size  [integer!]
      return:      [integer!]
    ]

    inflateInit2_: "inflateInit2_" [
      strm         [z_stream!]
      windowBits   [integer!]
      version      [c-string!]
      stream_size  [integer!]
      return:      [integer!]
    ]

    z-inflateEnd: "inflateEnd" [
      strm         [z_stream!]
      return:      [integer!]
    ]

    z-inflate: "inflate" [
      strm         [z_stream!]
      flush        [integer!]
      return:      [integer!]
    ]

    compressBound: "compressBound" [
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

     z-inflateInit: function [
      strm         [z_stream!]
      return:      [integer!]
    ][
      inflateInit_ strm version size? z_stream!
    ]

     z-inflateInit2: function [
      strm         [z_stream!]
      windowBits   [integer!]
      return:      [integer!]
    ][
      inflateInit2_ strm windowBits version size? z_stream!
    ]

    z-deflateInit: function [
      strm         [z_stream!]
      level        [integer!]
      return:      [integer!]
    ][
      deflateInit_ strm level version size? z_stream!
    ]

    z-deflateInit2: function [
      strm         [z_stream!]
      level        [integer!]
      method       [integer!]
      windowBits   [integer!]
      memlevel     [integer!]
      strategy     [integer!]
      return:      [integer!]
    ][
      deflateInit2_ strm level Z_DEFLATED (WINDOW_BITS or ENABLE_ZLIB_GZIP) 8 Z_DEFAULT_STRATEGY
    ]



; Macros freeing allocated structures and buffers
#define END_Z_DEFLATE   [z-deflateEnd strm  free buf-out  free buf-in  free as byte-ptr! strm]
#define END_Z_INFLATE   [z-inflateEnd strm  free buf-out  free buf-in  free as byte-ptr! strm]

    gunzip: function [
      filename     [c-string!]
      return:      [integer!]
      /local file  [gzfile!]
        error      [integer!]
        buffer     [byte-ptr!]
        bytes-read [integer!]

    ][
      file: gzopen filename "rb"
      if file = 0 [
        print [ "gzopen of " filename " failed." lf ]
        quit 1
      ]
      buffer: allocate CHUNK
      if buffer = NULL [
        print [ "Ungzip: Buffer allocation error." lf ]
        return Z_ERRNO
      ]
      until [
        bytes-read: gzread file buffer (CHUNK - 1)
        buffer/bytes-read: #"^(00)"
        print as c-string! buffer
        0 <> (gzeof file)
      ]
      gzclose file
      return 0
    ]

    deflate: function [
      src          [file!]
      dest         [file!]
      level        [integer!]
      return:      [integer!]
      /local ret have flush buf-in buf-out
             strm     [z_stream!]
    ][
      strm: as z_stream! allocate (size? z_stream!)
      if strm = NULL [
        print [ "Deflate: Memory allocation error." lf ]
        return Z_ERRNO
      ]
      buf-in: allocate CHUNK
      if buf-in = NULL [
        print [ "Deflate: Input buffer allocation error." lf ]
        free as byte-ptr! strm
        return Z_ERRNO
      ]
      buf-out: allocate CHUNK
      if buf-out = NULL [
        print [ "Deflate: Output buffer allocation error." lf ]
        free buf-in
        free as byte-ptr! strm
        return Z_ERRNO
      ]
      strm/zalloc: Z_NULL
      strm/zfree: Z_NULL
      strm/opaque: Z_NULL
      ret: z-deflateInit strm level
      if ret <> Z_OK [
        print [ "Deflate: Error deflateInit : " ret lf ]
        END_Z_DEFLATE
        return Z_ERRNO
      ]
      until [
        strm/avail_in: read-file buf-in 1 CHUNK src
        if file-error? src [
          print [ "Deflate: Input file error : " ret lf ]
          END_Z_DEFLATE
          return Z_ERRNO ; FIXME: find best error number
        ]
        either file-tail? src [ flush: Z_FINISH ][ flush: Z_NO_FLUSH ]
        strm/next_in: buf-in
        until [
          strm/avail_out: CHUNK
          strm/next_out: buf-out
          ret: z-deflate strm flush
          if ret = Z_STREAM_ERROR [
            print [ "Deflate: Data stream error" lf ]
            END_Z_DEFLATE
            return Z_ERRNO
          ]
          have: CHUNK - strm/avail_out
          ret: write-file buf-out 1 have dest
          if any [ (ret <> have) (file-error?  dest) ][
            END_Z_DEFLATE
            return Z_ERRNO
          ]
          strm/avail_out <> 0
        ]
        flush = Z_FINISH
      ]
      END_Z_DEFLATE
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
      out-count/value: compressBound in-count
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
