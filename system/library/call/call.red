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
    Red/System >= 0.4.1
    %curses.reds
  }
]

#system-global [ #include %call.reds ]

; Routines definitions
redsys-call: routine [       "Set IO buffers if needed, execute call"
  cmd        [string!]         "Command"
  waitend    [logic!]          "Wait for end of child process"
  redirin    [logic!]          "Input redirection"
  in-str     [string!]         "Input data"
  redirout   [logic!]          "Output redirection"
  redirerr   [logic!]          "Error redirection"
  return:    [integer!]
  /local
  inp out err
][
  either redirin [
    inp: declare p-buffer!
    inp/buffer: string/rs-head in-str
    inp/count:  1 + length? (as-c-string string/rs-head in-str)
  ][
    inp: null
  ]
  either redirout [
    out:  declare p-buffer!
    out/buffer: null
    out/count:  0
  ][
    out: null
  ]
  either redirerr [
    err:  declare p-buffer!
    err/buffer: null
    err/count:  0
  ][
    err: null
  ]
  system-call/call (as-c-string string/rs-head cmd) waitend inp out err
]

get-out: routine [           "Returns redirected stdout stored in outputs"
  /local sout
][
  sout: string/load as-c-string system-call/outputs/out/buffer (1 + system-call/outputs/out/count)
  free system-call/outputs/out/buffer
  SET_RETURN(sout)
]

get-err: routine [           "Returns redirected stderr stored in outputs"
  /local serr
][
  serr: string/load as-c-string system-call/outputs/err/buffer (1 + system-call/outputs/err/count)
  free system-call/outputs/err/buffer
  SET_RETURN(serr)
]

call: func [                 "Executes a shell command to run another process."
  cmd           [string!]    "The shell command or file"
  /wait                      "Runs command and waits for exit"
  /input                     "Redirects in to stdin"
  in            [string!]
  /output                    "Redirects stdout to out"
  out           [string!]
  /error                     "Redirects stderr to err"
  err           [string!]
  /local
  pid           [integer!]
  str           [string!]
][
  pid: 0
  either input  [ str:    in   ][ str:    ""    ]
  either input  [ do-in:  true ][ do-in:  false ]
  either output [ do-out: true ][ do-out: false ]
  either error  [ do-err: true ][ do-err: false ]
  pid: redsys-call cmd wait do-in str do-out do-err
  if do-out [
    str: get-out
    insert out str
    out: head out
  ]
  if do-err [
    str: get-err
    insert err str
    err: head err
  ]
  pid
]
