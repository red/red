Red/System [
  Title:   "Red/System unistd Binding"
  Author:  "Bruno Anselme"
  EMail:   "be.red@free.fr"
  File:    %unistd.reds
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

#if OS <> 'Windows [
  ; Wordexp enums
  #enum wrde-flag [
    WRDE_DOOFFS:     1
    WRDE_APPEND:     2
    WRDE_NOCMD:      4
    WRDE_REUSE:      8
    WRDE_SHOWERR:    16
    WRDE_UNDEF:      32
    __WRDE_FLAGS:    63
  ]
  #enum wrde-error [
    WRDE_NOSPACE:     1
    WRDE_BADCHAR:     2
    WRDE_BADVAL:      3
    WRDE_CMDSUB:      4
    WRDE_SYNTAX:      5
  ]
  ; Wordexp types
  wordexp-type!: alias struct! [
    we_wordc  [integer!]
    we_wordv  [str-array!]
    we_offs   [integer!]
  ]
]

#import [ LIBC-file cdecl [
  re-allocate:  "realloc" [
    base           [byte-ptr!]
    size           [integer!]
    return:        [byte-ptr!]
  ]
  #switch OS [
    Windows   [
      spawnvp: "_spawnvp" [
        mode           [integer!]
        cmd            [c-string!]   "Command to run"
        args-list      [str-array!]
        return:        [integer!]
      ]
    ]
    #default  [
      fork: "fork" [                 "Create a new process"
        return:        [integer!]
      ]
      sleep: "sleep" [               "Make the process sleep for nb seconds"
        nb             [integer!]
        return:        [integer!]
      ]
      execvp: "execvp" [
        cmd            [c-string!]   "Command to run"
        args-list      [str-array!]
        return:        [integer!]
      ]
      wordexp: "wordexp" [           "Perform word expansions"
        words          [c-string!]
        pwordexp       [wordexp-type!]
        flags          [integer!]
        return:        [integer!]
      ]
      wordfree: "wordfree" [         "Free strings array"
        pwordexp       [wordexp-type!]
        return:        [integer!]
      ]
      wait: "wait" [                 "Wait for a child process to stop or terminate"
        status         [int-ptr!]
        return:        [integer!]
      ]
    ]
  ] ; # switch
] ; cdecl
] ; #import

