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
    ] ; cdecl
    ] ; #import
  ] ; OS = 'Windows
]