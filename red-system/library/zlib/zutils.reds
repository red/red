Red/System [
  Title:   "Red/System ZLib Binding"
  Author:  "Bruno Anselme"
  EMail:   "be.red@free.fr"
  File:    %zutils.reds
  Rights:  "Copyright (c) 2013 Bruno Anselme"
  License: {
    Distributed under the Boost Software License, Version 1.0.
    See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
  }
  Purpose: "Debugging functions for zlib.reds development."
]

  ;-------------------------------------------
  ;-- Dump memory on screen in hex format  (Based on Nenad's dump-memory)
  ;-------------------------------------------
  hex-dump: func [
    address [byte-ptr!]           ;-- memory address where the dump starts
    limit   [integer!]            ;-- number of bytes to print
    return: [byte-ptr!]           ;-- return the pointer (pass-thru)
    /local offset ascii i byte int-ptr data-ptr
  ][
  ;  print ["^/Hex dump from: " address "h^/" lf]
    print lf
    offset: 0
    ascii: "                "

    data-ptr: address
    until [
  ;    print [address ": " ]
      prin-hex-chars offset 4
      prin ": "
      i: 0
      until [
        i: i + 1

        prin-hex-chars as-integer address/value 2
        address: address + 1
        prin either i = 8 ["  "][" "]

        byte: data-ptr/value
        ascii/i: either byte < as-byte 32 [
          either byte = null-byte [#"."][#"^(FE)"]
        ][
          byte
        ]

        data-ptr: data-ptr + 1
        i = 16
      ]
      print [space ascii lf]
      offset: offset + 16
      offset > limit
    ]
    address
  ]
  ;-------------------------------------------
  ;-- Convert a byte array into an hex string
  ;-------------------------------------------
  bin-to-str: func [
    address [byte-ptr!]           ;-- memory address where the dump starts
    limit   [integer!]            ;-- number of bytes to convert
    return: [c-string!]           ;-- return the c string
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
