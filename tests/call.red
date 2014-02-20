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
    syscalls/call as-c-string string/rs-head cmd waitend
  ]

  call-io: routine [  "Executes a shell command to run another process"
    cmd      [string!]
    in-str   [string!]
;    return:  [string!]
    /local
    out-str
    count
  ][
    count: 0
    out-str: syscalls/call-io as-c-string string/rs-head cmd
                              as byte-ptr! string/rs-head in-str
                              length? as-c-string string/rs-head in-str
                              :count
    SET_RETURN ((string/load as-c-string out-str count))
  ]

  call: func [
    cmd           [string!]
    /wait
    /input   sin  [string!]
    /output  sout [string!]
  ][
    either any [ input output ] [
      print sin
      sout: syscalls/call-io cmd sin
    ][
      call-basic cmd wait
    ]
  ]