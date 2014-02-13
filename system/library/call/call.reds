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
    Windows version performs home made string parsing (no expansion nor substitution).
    Any proposal to improve this parsing (with native Windows functions) is welcome.
  }
  Reference: {
    POSIX's wordexp :
      http://pubs.opengroup.org/onlinepubs/9699919799/functions/wordexp.html
  }
]

#include %../stdio.reds
#include %../unistd.reds

syscalls: context [

  free-str-array: func [args [str-array!] /local n][ ; free str-array! created by str2array
    n: 0
    while [ args/item <> null ][
      free as byte-ptr! args/item
      args: args + 1
      n: n + 1
    ]
    args: args  - n
    free as byte-ptr! args
  ]
  print-str-array: func [ args [str-array!]][
    while [ args/item <> null ][
      print [ args/item lf ]
      args: args + 1
    ]
  ]
  str2array: func [
    cmd          [c-string!]
    return:      [str-array!]
    /local
    args-list    [str-array!]
    s-length     [integer!]     ; command length
    n s c        [integer!]     ; number of strings
    str          [c-string!]
  ][
    s-length: length? cmd
    str: make-c-string length? cmd
    args-list: as str-array! allocate (100 * size? c-string!)  ; FIX: Should test memory allocation
;    print [ "Command        : " cmd       lf ]
;    print [ "Command length : " s-length  lf ]
;    print [ "args-list      : " args-list  lf ]
    s-length: s-length + 1
    c: 1  ; reset command index
    s: 1  ; reset string index
    n: 0  ; string count
    until [
      switch cmd/c [
        #" "
        null-byte [
          if s > 1 [
            str/s: null-byte                                           ; add termination null-byte to current string
            args-list/item: make-c-string s
            copy-memory as byte-ptr! args-list/item as byte-ptr! str s ; copy string into args-list
            args-list: args-list + 1
            n: n + 1
            s: 1
          ]
        ]
        default  [
          str/s: cmd/c          ; add char to current string index
          s: s + 1
        ]
      ]
      c: c + 1
      c > s-length
    ]
    args-list/item: null
    args-list: args-list - n  ; reset string array
    args-list: as str-array! re-allocate as byte-ptr! args-list ((n + 1) * size? c-string!)  ; FIX: Should test memory allocation
    free as byte-ptr! str
    print-str-array args-list  ; comment here
    return args-list
  ]

  #switch OS [
    Windows   [      ; Windows, use home made parsing
      call: func [                     "Executes a DOS command to run another process."
        cmd          [c-string!]       "The shell command"
        return:      [integer!]
        /local
        status       [integer!]
        args         [str-array!]
        ret          [integer!]
      ][
        args: str2array cmd
        print-str-array args
        ret: 0
;        ret: spawnvp 0 args/item args
        free-str-array args
        return ret
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
 ;       args         [str-array!]
      ][
        pid: fork
        either pid = 0 [    ; Child process
          wexp: as wordexp-type! allocate size? wordexp-type!   ; Create wordexp struct
          status: wordexp cmd wexp __WRDE_FLAGS                 ; Parse cmd into str-array
          either status = 0 [ ; Parsing ok
            ;-- start of debug ---
  ;          args: str2array cmd
  ;          print-str-array args
  ;          free as byte-ptr! args
            ;-- end of debug --
;            print-str-array wexp/we_wordv
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
          wait :status      ; Wait child process terminate
        ]
        return pid
      ] ; call
    ] ; #default
  ] ; #switch
] ; context