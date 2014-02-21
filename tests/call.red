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
  print [ "call-io"  lf ]
;  if none? out-str [ print "_-_-_-_-_-_-_-_-_-_-" ]
  print [ "In  : " as-c-string string/rs-head in-str  lf ]
  print [ "Out : " as-c-string string/rs-head out-str lf ]
  count: 0
;  if in-str <> null [
;    either out-str <> null [
      out: syscalls/call-io as-c-string string/rs-head cmd
                            string/rs-head in-str
                            (1 + length? as-c-string string/rs-head in-str)
                            :count
;    ][
;      syscalls/call-io as-c-string string/rs-head cmd
;                       string/rs-head in-str
;                       (1 + length? as-c-string string/rs-head in-str)
;                       null
;    ]
;  ]
  SET_RETURN ((string/load as-c-string out count))
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
    sout: call-io cmd sin none
    print [ "Output  : " sout ]
  ][
    call-basic cmd wait
  ]
]
