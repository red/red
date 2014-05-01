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

    Help needed to check the right library name, and test. Contact me at be.red@free.fr


Running the Red/System zlib examples
------------------------

1. This binding is provided with two examples for in-memory (compress) and on-disk compression (gzip).

1. Compile with Red
    `$ red -c system/library/curses/examples/zlib-mem-example.reds`

    `$ red -c system/library/curses/examples/zlib-disk-example.reds`

1. From the REBOL console type :

    `do/args %red.r "%system/library/zlib/examples/zlib-mem-example.reds"`, the compilation process should finish with a `...output file size` message.

    `do/args %red.r "%system/library/zlib/examples/zlib-disk-example.reds"`, the compilation process should finish with a `...output file size` message.

1. The resulting binaries are in Red main directory, go try them!

    Linux users run `zlib-mem-example` or `zlib-disk-example` from command line.

    Windows users need to open a DOS console and run `zlib-mem-example.exe` or `zlib-disk-example.exe` from there.

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
*Example*
<pre>
    with zlib [
      text: "Hello Red world"
      count: 0
      buffer: <b>compress</b> (as byte-ptr! text) ((length? text) + 1) :count Z_DEFAULT_COMPRESSION    ; length + 1 to include ending null char
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
*Example*
<pre>
    with zlib [
      decompressed-text: as c-string! <b>decompress</b> buffer count
      print decompressed-text
    ]
</pre>

3. On disk compression :
<pre>
    <b>gzip</b>: function [
      file-in      [c-string!]     "Name of the file to be zipped"
      file-out     [c-string!]     "Name of the output zipped file"
      return:      [integer!]
    ]
</pre>
*Example*
<pre>
    with zlib [
      <b>gzip</b> "filename.txt" "filename.gz"
    ]
</pre>

4. On disk decompression :
<pre>
    <b>gunzip</b>: function [             "Gunzip a file into another file"
      file-in      [c-string!]     "Name of the file to be unzipped"
      file-out     [c-string!]     "Name of the output unzipped file"
      return:      [integer!]
    ]
</pre>
*Example*
<pre>
    with zlib [
      <b>gunzip</b> "filename.gz" "filename.txt"
    ]
</pre>

