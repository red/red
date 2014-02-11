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

wordexp-type!: alias struct! [
  we_wordc  [integer!]
  we_wordv  [str-array!]
  we_offs  [integer!]
]

syscalls: context [
  #import [ LIBC-file cdecl [
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
      execlp: "execlp" [
        [variadic]
        ; cmd            [c-string!]   "Command to run"
        ; arg1           [c-string!]
        ; arg2           [c-string!]
        ; arg3           [c-string!]
        ; ...            null
        return:        [integer!]
      ]  ; Example : execlp [ "ls" "ls" "-l" "-a" null ]
      wordexp: "wordexp" [           "Perform word expansions"
        words          [c-string!]
        pwordexp       [wordexp-type!]
        flags          [integer!]
        return:        [integer!]
      ]
      wordfree: "wordfree" [         "Free string array"
        pwordexp       [wordexp-type!]
        return:        [integer!]
      ]
      wait: "wait" [                 "Wait for a child process to stop or terminate"
        status         [int-ptr!]
        return:        [integer!]
      ]
    ] ; cdecl
  ] ; #import
]

  #enum wrde-flags [
    WRDE_DOOFFS:     1
    WRDE_APPEND:     2
    WRDE_NOCMD:      4
    WRDE_REUSE:      8
    WRDE_SHOWERR:    16
    WRDE_UNDEF:      32
    __WRDE_FLAGS:    63
  ]
