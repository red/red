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
  err: syscalls/call cmd waitend null null
  if err <> 0 [
    print [ "Pid returned : " err lf ]
  ]
  print [ "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~" lf ]
]


call-in: func [
  cmd        [c-string!]      "Command"
  in-str     [c-string!]      "Stdin value ou null"
  /local
  ret        [integer!]
  inp
][
  inp: declare p-buffer!
  inp/buffer: as byte-ptr! in-str
  inp/count:  1 + length? in-str
  ret: syscalls/call cmd true inp null
]

call-out: func [
  cmd        [c-string!]      "Command"
  /local
  ret        [integer!]
  out
][
  out: declare p-buffer!
  out/buffer: null
  out/count:  0
  ret: syscalls/call cmd true null out
  print [ "Out   : " lf as-c-string out/buffer lf ]
  free out/buffer
]

call-in-out: func [
  cmd        [c-string!]      "Command"
  in-str     [c-string!]      "Stdin data ou null"
  /local
  ret        [integer!]
  inp out
][
  inp: declare p-buffer!
  inp/buffer: as byte-ptr! in-str
  inp/count:  1 + length? in-str
  out:  declare p-buffer!
  out/buffer: null
  out/count:  0
;  print [ "--- " inp " " out lf ]
;  print [ "--- " inp/buffer " " out/buffer lf ]
  print [ "In   : " as-c-string inp/buffer lf ]
  ret: syscalls/call cmd true inp out
  print [ "Out   : " as-c-string out/buffer lf ]
  free out/buffer
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
      print-cmd true  "echo $UNDEFINED_VAR"  ; Print nothing
      print-cmd true  "ls &"                 ; Word expansion should fail
      print-cmd true  {ls "*.r}              ; Word expansion should fail
;      print-cmd "top"
;      print-cmd false "firefox"
    ]
  ]
]

;show-calls
;syscalls/print-str-array system/env-vars  ; Only Linux
txt: {
  This is blue world
  This is green world
  This is Red world
  This is yellow world
}


print "------------ call-in --------------^/"
call-in  "cat" "This is a Red world...^/"
call-in  "grep Red" txt

print "------------ call-out -------------^/"
call-out "date"
call-out "uptime"
;call-out "ls -l"

print "------------ call-in-out ----------^/"
call-in-out "grep Red" txt

;show-cmd "cat" "This is a Red World..."
;show-cmd "cat /proc/cpuinfo" null
;show-cmd "cat" "This is a Red World..."

print [ lf "That's all folks..." lf ]
