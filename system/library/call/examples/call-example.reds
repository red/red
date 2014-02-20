Red/System [
  Title:   "Red/System call example"
  Author:  "Bruno Anselme"
  EMail:   "be.red@free.fr"
  File:    %call-example.reds
  Rights:  "Copyright (c) 2014 Bruno Anselme"
  License: {
    Distributed under the Boost Software License, Version 1.0.
    See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
  }
  Needs: {
    Red/System >= 0.4.1
  }
]

#include %../call.reds

print-cmd: func [
  waitend    [logic!]
  cmd        [c-string!]
  /local err [integer!]
][
  print [ "Command    : " cmd lf ]
  print [ "------------------------------------" lf ]
  err: syscalls/call cmd waitend
  if err <> 0 [
    print [ "Pid returned : " err lf ]
  ]
  print [ "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" lf ]
]

read-cmd-str: func [          "Execute cmd, in-str redirected to process' stdin, returns stdout"
  cmd        [c-string!]      "Command"
  in-str     [c-string!]      "Stdin value ou null"
  return:    [c-string!]
  /local
  str        [c-string!]
  count      [integer!]
  endstr     [integer!]
][
  str: null
  count: 0
  either in-str <> null [
    str: as c-string! syscalls/call-io cmd as byte-ptr! in-str length? in-str :count
  ][
    str: as c-string! syscalls/call-io cmd  null 0 :count
  ]
  endstr: count + 1
  str/endstr: null-byte            ; Put a c-string end marker
  return str
] ; read-cmd-str

show-cmd: func [              "Execute cmd, in-str redirected to process' stdin"
  cmd        [c-string!]      "Command"
  in-str     [c-string!]      "Stdin value ou null"
  /local
  str        [c-string!]
  count      [integer!]
  endstr     [integer!]
][
  print [ "Command    : " cmd ]
  if in-str <> null [ print [ " < ^"" in-str "^"" ] ]
  print lf
  print [ "------------------------------------" lf ]
  str: read-cmd-str cmd in-str
  print [ str lf ]
;  print [ "Output count  : " count lf ]
;  print [ "Output length : " length? str lf ]
  print [ "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" lf ]
  free as byte-ptr! str
]

show-calls: func [
][
  print [ "--- Call examples ---" lf ]
  #switch OS [
    Windows   [
      print-cmd false "notepad"
      print-cmd false "mspaint"
      print-cmd false "explorer"
      print-cmd true  "dir"
    ]
    #default  [
      print-cmd true  "uptime"
      print-cmd true  "cat /proc/version"
      print-cmd true  "ps a"
      print-cmd true  "ls"
      print-cmd true  "ls -l *.r"
      print-cmd true  "echo $UNDEFINED_VAR"  ; Word expansion should fail
      print-cmd true  "ls &"                 ; Word expansion should fail
      print-cmd true  {ls "*.r}              ; Word expansion should fail
;      print-cmd "top"
;      print-cmd false "firefox"
    ]
  ]
]

show-calls
;syscalls/print-str-array system/env-vars  ; Only Linux

;show-cmd "ls -l" null
;show-cmd "cat" "This is a Red World..."
;show-cmd "cat /proc/cpuinfo" null
;show-cmd "cat" "This is a Red World..."

print [ "That's all folks..." lf ]
