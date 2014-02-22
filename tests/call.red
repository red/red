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
  syscalls/call as-c-string string/rs-head cmd waitend null null
]

call-in: routine [
  cmd        [string!]      "Command"
  in-str     [string!]      "Input data"
  /local
  ret        [integer!]
  inp
][
  inp: declare p-buffer!
  inp/buffer: string/rs-head in-str
  inp/count:  1 + length? (as-c-string string/rs-head in-str)
  ret: syscalls/call (as-c-string string/rs-head cmd) true inp null
]

call-out: routine [
  cmd        [string!]      "Command"
  /local
  ret        [integer!]
  out sout
][
  out:  declare p-buffer!
  out/buffer: as byte-ptr! 0
  out/count:  0
  ret: syscalls/call (as-c-string string/rs-head cmd) true null out
  sout: string/load as-c-string out/buffer (1 + out/count)
  free out/buffer
  SET_RETURN(sout)
]

call-in-out: routine [
  cmd        [string!]      "Command"
  in-str     [string!]      "Input data"
  /local
  ret        [integer!]
  inp out sout
][
  inp: declare p-buffer!
  inp/buffer: string/rs-head in-str
  inp/count:  1 + length? (as-c-string string/rs-head in-str)
  out:  declare p-buffer!
  out/buffer: null
  out/count:  0
  ret: syscalls/call (as-c-string string/rs-head cmd) true inp out
  sout: string/load as-c-string out/buffer (1 + out/count)
  free out/buffer
  SET_RETURN(sout)
]

call: func [
  cmd           [string!]
  /wait
  /input   sin  [string!]
  /output  sout [string!]
  /local
  waitend       [logic!]
  pid           [integer!]
  str           [string!]
  inp out
][
  either wait [ waitend: true ][ waitend: false ]

  pid: 0
  either input [
    either output [
      str: call-in-out cmd sin
      insert sout str
      sout: head sout
    ][
      call-in cmd sin
    ]
  ][
    either output [
      str: call-out cmd
      insert sout str
      sout: head sout
    ][
      pid: call-basic cmd waitend
    ]
  ]
  pid
]
