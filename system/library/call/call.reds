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
][

  pid: syscalls/fork
  either pid = 0 [ ; Child process
    print [ "Child" lf ]
    print [ "Taille : " size? wordexp-type! lf ]
    wexp: as wordexp-type! allocate size? wordexp-type!
    syscalls/wordexp cmd wexp __WRDE_FLAGS
    syscalls/execvp wexp/we_wordv/item wexp/we_wordv
    syscalls/wordfree wexp
;    syscalls/execlp [ "ls" "ls" "-l" "-a" null ]  ; example with execlp
  ][               ; Parent process
    print [ "Parent, need to wait" lf ]
  ]
  return pid
] ; call

