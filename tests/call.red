Red [
  Title: "Red Curses Binding"
  Author: "Bruno Anselme"
  EMail: "be.red@free.fr"
  File: %curses.red
  Rights: "Copyright (c) 2013 Bruno Anselme"
  License: {
    Distributed under the Boost Software License, Version 1.0.
    See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
  }
  Needs: {
    Red/System >= 0.3.1
    %curses.reds
  }
]

#system-global [
  #include %../system/library/call/call.reds
]

; Routines definitions

call-basic: routine [  "Executes a shell command to run another process"
  cmd      [string!]
  waitend  [logic!]
  return:  [integer!]
][
  print [ "call-basic" lf ]
  syscalls/call as-c-string string/rs-head cmd waitend
]

call-io: routine [  "Executes a shell command to run another process"
  cmd      [string!]
  in-str   [string!]
  out-str  [string!]
;    return:  [string!]
  /local
  count
  out
;  out-str
][
;  print [ "call-io"  lf ]
;  if not null? in-str  [ print [ "In  : " as-c-string string/rs-head in-str   lf ] ]
;  if not null? out-str [ print [ "Out : " as-c-string string/rs-head out-str  lf ] ]
  count: 0

  ; output, no input
  if all [(null? in-str) (not null? out-str)][
    print [ "Ici ---------------" lf ]
    out: syscalls/call-io as-c-string string/rs-head cmd null 0 :count
  ]

  ; output, input
  if all [(not null? in-str) (not null? out-str)][
    out: syscalls/call-io as-c-string string/rs-head cmd
                          string/rs-head in-str
                          (1 + length? as-c-string string/rs-head in-str)
                          :count
  ]

  ; Bugged
  ; no output, input
  if all [(null? in-str) (not null? out-str)][
    out: syscalls/call-io as-c-string string/rs-head cmd
                          string/rs-head in-str
                          (1 + length? as-c-string string/rs-head in-str)
                          null
  ]

;  if not null? out-str [
    SET_RETURN ((string/load as-c-string out count))
;  ]
]

call: func [
  cmd           [string!]
  /wait
  /input   sin  [string!]
  /output  sout [string!]
][
  either any [ input output ] [
    print [ "Command : " cmd ]
    print [ "Input   : " sin ]
    print [ "Output  : " sout ]
    if all [ input output ]     [ sout: call-io cmd sin sout  ]
    if all [ input not output ] [       call-io cmd sin none  ]
    if all [ not input output ] [ sout: call-io cmd null sout ]
    if output [ print [ "Output  : " sout ] ]
  ][
    call-basic cmd wait
  ]
]
