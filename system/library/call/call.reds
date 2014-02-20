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
  ]
  print-str-array: func [ args [str-array!]][        ; used for debug
    while [ args/item <> null ][
      print [ "- " args/item lf ]
      args: args + 1
    ]
  ]
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
  ]

  resize-buffer: func [
    buffer       [byte-ptr!]
    newsize      [integer!]
    return:      [byte-ptr!]
  ][
    tmp: re-allocate buffer newsize                 ; Resize output buffer to new size
    either tmp = NULL [                             ; reallocation failed, uses current output buffer
      print [ "Red/System resize-buffer : Memory allocation failed." lf ]
      halt
    ][                                              ; reallocation succeeded, uses reallocated buffer
      buffer: tmp
    ]
    return buffer
  ]

  read-from-pipe: func [      "Read data from pipe fd into buffer"
    fd           [integer!]   "File descriptor"
    buffer       [byte-ptr!]
    ptr-count    [int-ptr!]
    return:      [byte-ptr!]
    /local
    cpt          [integer!]
    tmp          [byte-ptr!]
    total        [integer!]
  ][
    cpt: ptr-count/value
    total: 0
    while [cpt = ptr-count/value ][
      cpt: ioread fd (buffer + total) cpt
      total: total + cpt
      if cpt = ptr-count/value [                    ; buffer must be expanded
        buffer: resize-buffer buffer (total + ptr-count/value)
      ]
    ]
    buffer: resize-buffer buffer (total + 1)        ; Resize output buffer to minimum size
    ptr-count/value: total
    return buffer
  ] ; read-from-pipe

  #switch OS [
    Windows   [      ; Windows, use minimal home made parsing
      call: func [                     "Executes a DOS command to run another process."
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
      expand-exec: func[               "Use wordexp to parse command and run it. Halt if error. Should never return"
        cmd          [c-string!]       "The shell command"
        return:      [integer!]
        /local
        status       [integer!]
      ][
        wexp: as wordexp-type! allocate size? wordexp-type!      ; Create wordexp struct
        status: wordexp cmd wexp __WRDE_FLAGS                    ; Parse cmd into str-array
        either status = 0 [ ; Parsing ok
;          print-str-array wexp/we_wordv                         ; Debug: Print expanded values
          execvp wexp/we_wordv/item wexp/we_wordv                ; Call execvp with str-array parameters
          print [ "Error while calling execvp : {" cmd "}" lf ]  ; Should never occur
          quit 1
        ][                 ; Parsing nok
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
      ] ; expand-exec

      call: func [                     "Executes a shell command to run another process."
        cmd          [c-string!]       "The shell command"
        waitend      [logic!]          "Wait for end of command"
        return:      [integer!]        "Returns a pid"
        /local
        pid          [integer!]
        wexp         [wordexp-type!]
        status       [integer!]
      ][
        pid: fork
        either pid = 0 [    ; Child process
          expand-exec cmd
        ][                  ; Parent process
          status: 0
          if waitend [
            wait :status    ; Wait child process terminate
            pid: 0          ; Process is completed, return 0
          ]
        ] ; either pid
        return pid
      ] ; call

      call-io: func [              "Executes a shell command, IO redirections to buffers."
        cmd          [c-string!]       "The shell command"
        in-buf       [byte-ptr!]       "Pointer to input data, no stdin redirection if null"
        in-count     [integer!]        "in-buf size"
        out-count    [int-ptr!]        "Pointer to output buffer count (integer!), no stdout redirection if null"
        return:      [byte-ptr!]       "Returns an output buffer"
        /local
        pid          [integer!]
        wexp         [wordexp-type!]
        out-buf      [byte-ptr!]
        status       [integer!]
        err          [integer!]
        fdesc        [int-ptr!]
        flags        [integer!]
        redirected   [logic!]
      ][
        out-buf: null
        out-count/value: 0
        if out-count <> null [
          out-buf: as byte-ptr! allocate READ-BUFFER-SIZE
        ]
        redirected: any [ (out-buf <> null) (out-buf <> null) ]
        if redirected [
          fdesc: as int-ptr! allocate (2 * size? integer!)        ; Files descriptors for redirection
          if (pipe fdesc) = -1 [ print "Red/System call-io : Error creating pipe"  halt ]
        ]
        pid: fork
        either pid = 0 [                                ; Child process
          if in-buf <> null [                                   ; redirect stdin to input buffer
            err: dup2 fdesc/1 stdin
            if err = -1 [ print "Red/System call-io : Error dup2 stdin"  halt ]
          ]
          if out-buf <> null [                                  ; redirect stdout to output buffer
            err: dup2 fdesc/2 stdout
            if err = -1 [ print "Red/System call-io : Error dup2 stdout"  halt ]
          ]
          if redirected [
            close fdesc/1
            close fdesc/2
          ]
          expand-exec cmd
        ][                                              ; Parent process
          status: 0
          if in-buf <> null [                                   ; write input buffer to child process' stdin
            iowrite fdesc/2 in-buf in-count
          ]
          either out-buf = null [
            wait :status                                        ; Wait child process terminate
          ][
            out-count/value: READ-BUFFER-SIZE
            out-buf: read-from-pipe fdesc/1 out-buf out-count   ; read output buffer from child process' stdout
          ]
        ] ; either pid
        if redirected [
          free as byte-ptr! fdesc
        ]
        return out-buf
      ] ; call-io
    ] ; #default
  ] ; #switch
] ; context