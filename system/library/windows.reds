Red/System [
  Title:   "Red/System windows Binding"
  Author:  "Bruno Anselme"
  EMail:   "be.red@free.fr"
  File:    %window.reds
  Rights:  "Copyright (c) 2014 Bruno Anselme"
  License: {
    Distributed under the Boost Software License, Version 1.0.
    See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
  }
]

#if target = 'IA-32 [
  system/fpu/mask/overflow: on
  system/fpu/mask/underflow: on
  system/fpu/mask/zero-divide: on
  system/fpu/mask/invalid-op: on
  system/fpu/update
]

stdcalls: context [
  #if OS = 'Windows [
    ; Spawn enums
    #enum spawn-mode [
      P_WAIT:          0
      P_NOWAIT:        1
      P_OVERLAY:       2
      P_NOWAITO:       3
      P_DETACH:        4
    ]

    #import [ LIBC-file cdecl [
      re-allocate:  "realloc" [
        base           [byte-ptr!]
        size           [integer!]
        return:        [byte-ptr!]
      ]
      spawnvp: "_spawnvp" [
        mode           [integer!]
        cmd            [c-string!]   "Command to run"
        args-list      [str-array!]
        return:        [integer!]
      ]
      close: "close" [               "Close the file descriptor"
        fd             [integer!]    "File descriptor"
        return:        [integer!]
      ]
      pipe: "_pipe" [                "Creates a pipe for reading and writing"
        pipedes        [int-ptr!]    "Pointer to a 2 integers array"
        psize          [integer!]    "Amount of memory to reserve"
        textmode       [integer!]    "File mode"
        return:        [integer!]
      ]
      dup2: "_dup2" [                "Reassigns a file descriptor"
        fd             [integer!]    "File descriptor"
        fd2            [integer!]    "File descriptor"
        return:        [integer!]
      ]
      ioread: "_read" [              "Reads data from a file"
        fd             [integer!]    "File descriptor referring to the open file"
        buf            [byte-ptr!]   "Storage location for data"
        nbytes         [integer!]    "Maximum number of bytes"
        return:        [integer!]    "Number of bytes read or error"
      ]
      iowrite: "_write" [            "Writes data to a file"
        fd             [integer!]    "File descriptor of file into which data is written"
        buf            [byte-ptr!]   "Data to be written"
        nbytes         [integer!]    "Number of bytes"
        return:        [integer!]    "Number of bytes written or error"
      ]
    ] ; cdecl
    ] ; #import
  ] ; OS = 'Windows
]