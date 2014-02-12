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
]

#include %../stdio.reds
#include %../unistd.reds

call: func [                     "Executes a shell command to run another process."
  cmd          [c-string!]       "The shell command"
  return:      [integer!]
  /local
  pid          [integer!]
  wexp         [wordexp-type!]
  status       [integer!]
][

  pid: syscalls/fork
  either pid = 0 [ ; Child process
    wexp: as wordexp-type! allocate size? wordexp-type!    ; Create wordexp struct
    status: syscalls/wordexp cmd wexp __WRDE_FLAGS         ; Parse cmd into str-array
    either status = 0 [  ; Parsing ok
      syscalls/execvp wexp/we_wordv/item wexp/we_wordv     ; Call execvp with str-array parameters
      print [ "Error while calling execvp" lf ]            ; Should never occur
      quit 1
    ][                   ; Parsing nok
      print [ "Error parsing command : " cmd lf ]
      case [
        status = WRDE_NOSPACE    [ print [ "Attempt to allocate memory failed" lf ] ]
        status = WRDE_BADCHAR    [ print [ "Use of the unquoted characters- <newline>, '|', '&', ';', '<', '>', '(', ')', '{', '}'" lf ] ]
        status = WRDE_BADVAL     [ print [ "Reference to undefined shell variable" lf ] ]
        status = WRDE_CMDSUB     [ print [ "Command substitution requested" lf ] ]
        status = WRDE_SYNTAX     [ print [ "Shell syntax error, such as unbalanced parentheses or unterminated string" lf ] ]
      ]
      quit status
    ]
  ][               ; Parent process
    status: 0
    syscalls/wait :status                                  ; Wait child process terminate
  ]
  return pid
] ; call
