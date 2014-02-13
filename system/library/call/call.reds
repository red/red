Red/System [
  Title:   "Red/System syscall binding"
  Author:  "Bruno Anselme"
  EMail:   "be.red@free.fr"
  File:    %call.reds
  Rights:  "Copyright (c) 2014 Bruno Anselme"
  License: {
    Distributed under the Boost Software License, Version 1.0.
    See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
  }
  Needs: {
    Red/System >= 0.4.1
  }
  Purpose: {
    This binding implements a call function for Red/System (similar to rebol's call function).
    POSIX version uses "wordexp" function to perform word expansion.
      http://pubs.opengroup.org/onlinepubs/9699919799/functions/wordexp.html
    Windows version performs home made string parsing (no expansion nor substitution).
    Any proposal to improve this parsing (with native Windows functions) is welcome.
  }
]

#include %../stdio.reds
#include %../unistd.reds

syscalls: context [

  str2array: func [
    cmd          [c-string!]
    return:      [str-array!]
    /local
    tmp          [str-array!]
    len          [integer!]
    count        [integer!]
  ][
    print [ "Command        : " cmd lf ]
    len: 2
    tmp: as str-array! allocate (len * size? c-string!)
    print [ "Allocated size : " size? tmp lf ]
    count: 1
    while [ cmd/count <> #"^(00)" ][
      count: count + 1
    ]
    print [ "String length  : " count lf ]
    return tmp
  ]


  #switch OS [
    Windows   [
      call: func [                     "Executes a shell command to run another process."
        cmd          [c-string!]       "The shell command"
        return:      [integer!]
        /local
        status       [integer!]
      ][
  ;     spawnvp 0 wexp/we_wordv/item wexp/we_wordv
      ] ; call
    ] ; Windows
    #default  [      ; POSIX, use wordexp parsing
      call: func [                     "Executes a shell command to run another process."
        cmd          [c-string!]       "The shell command"
        return:      [integer!]
        /local
        pid          [integer!]
        wexp         [wordexp-type!]
        status       [integer!]
      ][
        pid: fork
        either pid = 0 [    ; Child process
          wexp: as wordexp-type! allocate size? wordexp-type!   ; Create wordexp struct
          status: wordexp cmd wexp __WRDE_FLAGS                 ; Parse cmd into str-array
          either status = 0 [ ; Parsing ok
            execvp wexp/we_wordv/item wexp/we_wordv             ; Call execvp with str-array parameters
            print [ "Error while calling execvp" lf ]           ; Should never occur
            quit 1
          ][                 ; Parsing nok
            print [ "Error parsing command : " cmd lf ]
            case [
              status = WRDE_NOSPACE [ print [ "Attempt to allocate memory failed" lf ] ]
              status = WRDE_BADCHAR [ print [ "Use of the unquoted characters- <newline>, '|', '&', ';', '<', '>', '(', ')', '{', '}'" lf ] ]
              status = WRDE_BADVAL  [ print [ "Reference to undefined shell variable" lf ] ]
              status = WRDE_CMDSUB  [ print [ "Command substitution requested" lf ] ]
              status = WRDE_SYNTAX  [ print [ "Shell syntax error, such as unbalanced parentheses or unterminated string" lf ] ]
            ]
            quit status
          ]
        ][                  ; Parent process
          status: 0
          wait :status                                 ; Wait child process terminate
        ]
        return pid
      ] ; call
    ] ; #default
  ] ; #switch
] ; context