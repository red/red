ZLib for Red/System
------------------------

This is a low level binding for ZLib.

Requirements
------------

*   **Linux**

    *libz.so.1* : avaliable with your favorite distro.

*   **Windows**

    *zlib1.dll* :  [ZLib](http://www.zlib.net/), version 1.2.7 : [zlib127-dll.zip](http://prdownloads.sourceforge.net/libpng/zlib127-dll.zip?download)

*   **MacOSX**

    Help needed to check the right library name, and test.


Running the Red/System curses examples
------------------------

1. This binding is provided with an example.

1. From the REBOL console type :

    `change-dir %red-system`

    `do/args %rsc.r "%library/zlib/examples/zlib-example.reds"`, the compilation process should finish with a `...output file size` message.

1. From command line, use the REBOL compilation script :

    `cd red-system/library/builds/zlib/examples`

    `rebol -s compile-examples.r`  (Linux)

    or

    `rebol.exe -s compile-examples.r`  (Windows)

    This script buid the example included in this directory.

1. The resulting binary is in `red-system/builds/`, go try it!

    Linux users run `zlib-example` from command line.

    Windows users need to open a DOS console and run `zlib-example.exe` from there.

ZLib binding usage
------------------
1. In memory compression :
<pre>
    <b>compress</b>: func [
      in-buf       [byte-ptr!]           "Pointer to source data"
      in-count     [integer!]            "Source data count (bytes)"
      out-count    [int-ptr!]            "Pointer to integer, returns output buffer size"
      level        [integer!]            "Compression level"
      return:      [byte-ptr!]           "Pointer to compressed data"
    ]
</pre>
* Example
<pre>
    with zlib [
      text: "Hello Red world"
      count: 0
      buffer: <b>compress</b> (as byte-ptr! text) (length? text) :count Z_DEFAULT_COMPRESSION
      print bin-to-str buffer count      ; Print buffer converted into string
    ]
</pre>

2. In memory decompression :
<pre>
    <b>decompress</b>: func [
      in-buf       [byte-ptr!]           "Pointer to source data"
      in-count     [integer!]            "Source data count (bytes)"
      return:      [byte-ptr!]           "Pointer to compressed data"
    ]
</pre>
* Example
<pre>
    with zlib [
      decompressed-text: as c-string! <b>decompress</b> buffer count
      print decompressed-text
    ]
</pre>

