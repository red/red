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
#switch OS [
  Windows   [ #include %../windows.reds ]
  #default  [ #include %../unistd.reds  ]
]

#define READ-BUFFER-SIZE 4096

p-buffer!: alias struct! [
  count  [integer!]
  buffer [byte-ptr!]
]

f-desc!: alias struct! [
  reading  [integer!]
  writing  [integer!]
]

syscalls: context [


  free-str-array: func [args [str-array!] /local n][ ; free str-array! created by word-expand
    n: 0
    while [ args/item <> null ][
      free as byte-ptr! args/item
      args: args + 1
      n: n + 1
    ]
    args: args  - n
    free as byte-ptr! args
  ] ; free-str-array

  print-str-array: func [ args [str-array!]][        ; used for debug
    while [ args/item <> null ][
      print [ "- " args/item lf ]
      args: args + 1
    ]
  ] ; print-str-array

  word-expand: func [
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
    args-list: as str-array! allocate (100 * size? c-string!)          ; FIX: Should test memory allocation
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
          str/s: cmd/c                                                 ; add char to current string index
          s: s + 1
        ]
      ]
      c: c + 1
      c > s-length
    ]
    args-list/item: null
    args-list: args-list - n    ; reset string array
    args-list: as str-array! re-allocate as byte-ptr! args-list ((n + 1) * size? c-string!)  ; FIX: Should test memory allocation
    free as byte-ptr! str
;    print-str-array args-list  ; Debug: Print expanded values
    return args-list
  ] ; word-expand

  resize-buffer: func [
    buffer       [byte-ptr!]
    newsize      [integer!]
    return:      [byte-ptr!]
  ][
    if buffer = null [ print [ "Resize empty buffer" lf ] ]
    tmp: re-allocate buffer newsize                 ; Resize output buffer to new size
    either tmp = null [                             ; reallocation failed, uses current output buffer
      print [ "Red/System resize-buffer : Memory allocation failed." lf ]
      halt
    ][                                              ; reallocation succeeded, uses reallocated buffer
      buffer: tmp
    ]
    return buffer
  ] ; resize-buffer

  read-from-pipe: func [      "Read data from pipe fd into buffer"
    fd           [integer!]   "File descriptor"
    buffer       [byte-ptr!]
    count-ptr    [int-ptr!]
    return:      [byte-ptr!]
    /local
    cpt          [integer!]
    total        [integer!]
  ][
    cpt: count-ptr/value
    total: 0
    while [cpt = count-ptr/value ][
      cpt: ioread fd (buffer + total) cpt
      total: total + cpt
      if cpt = count-ptr/value [                    ; buffer must be expanded
        buffer: resize-buffer buffer (total + count-ptr/value)
      ]
    ]
    buffer: resize-buffer buffer (total + 1)        ; Resize output buffer to minimum size
    count-ptr/value: total
    return buffer
  ] ; read-from-pipe

  #switch OS [
    Windows   [      ; Windows, use minimal home made parsing
      call: func [                   "Executes a DOS command to run another process."
        cmd          [c-string!]       "Command line"
        waitend      [logic!]
        return:      [integer!]
        /local
        status       [integer!]
        args         [str-array!]
        pid          [integer!]
      ][
        args: word-expand cmd
        pid: 0
        either waitend [
          pid: spawnvp P_WAIT   args/item args      ; Windows : wait until end of process
        ][
          pid: spawnvp P_NOWAIT args/item args      ; Windows : continues to execute the calling process
        ]
        free-str-array args
        return pid
      ] ; call
    ] ; Windows
    #default  [      ; POSIX
      expand-and-exec: func[         "Use wordexp to parse command and run it. Halt if error. Should never return"
        cmd          [c-string!]       "The shell command"
        return:      [integer!]
        /local
        status       [integer!]
      ][
        wexp: as wordexp-type! allocate size? wordexp-type!      ; Create wordexp struct
        status: wordexp cmd wexp WRDE_SHOWERR                              ; Parse cmd into str-array
        either status = 0 [                           ; Parsing ok
;          print-str-array wexp/we_wordv                         ; Debug: Print expanded values
          execvp wexp/we_wordv/item wexp/we_wordv                ; Call execvp with str-array parameters
          print [ "Error while calling execvp : {" cmd "}" lf ]  ; Should never occur
          quit 1
        ][                                            ; Parsing nok
          print [ "Error wordexp parsing command : " cmd lf ]
          switch status [
            WRDE_NOSPACE [ print [ "Attempt to allocate memory failed" lf ] ]
            WRDE_BADCHAR [ print [ "Use of the unquoted characters- <newline>, '|', '&', ';', '<', '>', '(', ')', '{', '}'" lf ] ]
            WRDE_BADVAL  [ print [ "Reference to undefined shell variable" lf ] ]
            WRDE_CMDSUB  [ print [ "Command substitution requested" lf ] ]
            WRDE_SYNTAX  [ print [ "Shell syntax error, such as unbalanced parentheses or unterminated string" lf ] ]
          ]
          quit status
        ]
        return -1
      ] ; expand-and-exec

      call: func [                   "Executes a shell command, IO redirections to buffers."
        cmd          [c-string!]       "The shell command"
        waitend      [logic!]          "Wait for end of command, implicit if out-buf is set"
        in-buf       [p-buffer!]       "Pointer to input data or null"
        out-buf      [p-buffer!]       "Pointer to output data or null"
        return:      [integer!]
        /local
        pid          [integer!]
        status       [integer!]
        err          [integer!]
        cpt          [integer!]
        fd-in fd-out
      ][
        if in-buf <> null [
          fd-in: declare f-desc!
          if (pipe as int-ptr! fd-in) = -1 [     ; Create a pipe for child's input
            print "Red/System call : Input pipe creation failed^/"  halt
          ]
        ]
        if out-buf <> null [
          out-buf/count: 0
          out-buf/buffer: allocate READ-BUFFER-SIZE
          fd-out: declare f-desc!
          if (pipe as int-ptr! fd-out) = -1 [    ; Create a pipe for child's output
            print "Red/System call : Output pipe creation failed^/"  halt
          ]
        ]
        pid: fork
        either pid = 0 [                        ;----- Child process -----
          if in-buf <> null [ ; redirect stdin to the pipe
            close fd-in/writing
            err: dup2 fd-in/reading stdin
            if err = -1 [ print "Red/System call : Error dup2 stdin^/" halt ]
            close fd-in/reading
          ]
          if out-buf <> null [ ; redirect stdout to the pipe
            close fd-out/reading
            err: dup2 fd-out/writing stdout
            if err = -1 [ print "Red/System call : Error dup2 stdout^/" halt ]
            close fd-out/writing
          ]
          expand-and-exec cmd
        ][                                      ;----- Parent process -----
          if in-buf <> null [                                                   ; write input buffer to child process' stdin
            close fd-in/reading
            iowrite fd-in/writing in-buf/buffer in-buf/count
            close fd-in/writing
            waitend: true
          ]
          if out-buf <> null [
            close fd-out/writing
            cpt: READ-BUFFER-SIZE                                               ; initial buffer size and grow step
            out-buf/buffer: read-from-pipe fd-out/reading out-buf/buffer :cpt   ; read output buffer from child process' stdout
            out-buf/count: cpt
            close fd-out/reading
            waitend: false
          ]
          if waitend [
            status: 0
            waitpid pid :status 0   ; Wait child process terminate
            pid: 0                  ; Process is completed, return 0
          ]
        ] ; either pid
        return pid
      ] ; call
    ] ; #default
  ] ; #switch
] ; context