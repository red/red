REBOL [
  Title:   "Builds and Runs the Red/System Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.8.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

make-if-needed?: func [
  auto-test-file [file!]
  make-file [file!]
  /lib-test
  /local
    stored-length   ; the length of the make... .r file used to build auto tests
    stored-file-length
    digit
    number
    rule
][
  stored-file-length: does [
    parse/all read auto-test-file rule
    stored-length
  ]
  digit: charset [#"0" - #"9"]
  number: [some digit]
  rule: [
    thru ";make-length:" 
    copy stored-length number (stored-length: to integer! stored-length)
    to end
  ]
  
  if not exists? make-file [return]
 
  if any [
    not exists? auto-test-file
    stored-file-length <> length? read make-file
    (modified? make-file) > (modified? auto-test-file)
  ][
    print ["Making" auto-test-file " - it will take a while"]
    do make-file
  ]
]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

do %../../quick-test/quick-test.r
qt/tests-dir: system/script/path

;; make auto files if needed
make-if-needed? %source/units/auto-tests/byte-auto-test.reds
                %source/units/make-byte-auto-test.r
                      
make-if-needed? %source/units/auto-tests/integer-auto-test.reds
                %source/units/make-integer-auto-test.r
                
make-if-needed? %source/units/auto-tests/maths-auto-test.reds
                %source/units/make-maths-auto-test.r

make-if-needed? %source/units/auto-tests/float-auto-test.reds
                %source/units/make-float-auto-test.r
                
make-if-needed? %source/units/auto-tests/float32-auto-test.reds
                %source/units/make-float32-auto-test.r

;; make lib-test files if needed
lib-test-len: length? read %source/units/lib-test-source.reds
save-len: either exists? %source/units/len-lib-test.dat [
  load %source/units/len-lib-test.dat
][
  -1
]

if any [
  not exists? %source/units/auto-tests/lib-auto-test.reds
  lib-test-len <> save-len 
][
  save %source/units/len-lib-test.dat lib-test-len
  print "Making lib-test-auto.reds - shouldn't take long"
  do %source/units/make-lib-auto-test.r                         
]

flib-test-len: length? read %source/units/float-lib-test-source.reds
save-len: either exists? %source/units/len-flib-test.dat [
  load %source/units/len-flib-test.dat
][
  -1
]

f32lib-test-len: length? read %source/units/float32-lib-test-source.reds
f32-save-len: either exists? %source/units/len-f32lib-test.dat [
  load %source/units/len-f32lib-test.dat
][
  -1
]

if any [
  not exists? %source/units/auto-tests/float-lib-auto-test.reds
  flib-test-len <> save-len 
][
  save %source/units/len-flib-test.dat flib-test-len
  print "Making float-lib-test-auto.reds - shouldn't take long"
  do %source/units/make-float-lib-auto-test.r                         
]

if any [
  not exists? %source/units/auto-tests/float32-lib-auto-test.reds
  f32lib-test-len <> f32-save-len 
][
  save %source/units/len-f32lib-test.dat f32lib-test-len
  print "Making float32-lib-test-auto.reds - shouldn't take long"
  do %source/units/make-float32-lib-auto-test.r                         
]

;; run the tests
print rejoin ["Run-All    v" system/script/header/version]
print rejoin ["Quick-Test v" qt/version]
print rejoin ["REBOL       " system/version]

start-time: now/precise

;; any .reds test with more than one space between --run-test-file-quiet and 
;;  the filename will be excluded from the ARM tests

***start-run-quiet*** "Red/System Test Suite"

===start-group=== "Datatype tests"
  --run-test-file-quiet %source/units/logic-test.reds
 ; --run-test-file-quiet  %source/units/integer-test.reds   ;; excluded from ARM tests       
  --run-test-file-quiet %source/units/byte-test.reds
  --run-test-file-quiet %source/units/c-string-test.reds
  --run-test-file-quiet %source/units/struct-test.reds
  --run-test-file-quiet %source/units/pointer-test.reds
  --run-test-file-quiet %source/units/cast-test.reds
  --run-test-file-quiet %source/units/alias-test.reds
  --run-test-file-quiet %source/units/length-test.reds
  --run-test-file-quiet %source/units/null-test.reds
  --run-test-file-quiet %source/units/enum-test.reds
  --run-test-file-quiet %source/units/float-test.reds
  --run-test-file-quiet %source/units/float32-test.reds
===end-group===

===start-group=== "Native functions tests"
  --run-test-file-quiet %source/units/not-test.reds
  --run-test-file-quiet %source/units/size-test.reds
  --run-test-file-quiet %source/units/function-test.reds
  --run-test-file-quiet %source/units/case-test.reds
  --run-test-file-quiet %source/units/switch-test.reds
===end-group===

===start-group=== "Special natives tests"
  --run-test-file-quiet %source/units/exit-test.reds
  --run-test-file-quiet %source/units/return-test.reds
===end-group===

===start-group=== "Math operators tests"
  --run-test-file-quiet %source/units/modulo-test.reds
  --run-test-file-quiet %source/units/math-mixed-test.reds
===end-group===

===start-group=== "Infix syntax for functions"
  --run-test-file-quiet %source/units/infix-test.reds
===end-group===

===start-group=== "Conditional tests"
  --run-test-file-quiet %source/units/conditional-test.reds
===end-group===

===start-group=== "Auto-tests"
  --run-test-file-quiet %source/units/auto-tests/byte-auto-test.reds
  --run-test-file-quiet %source/units/auto-tests/integer-auto-test.reds
  --run-test-file-quiet %source/units/auto-tests/maths-auto-test.reds
  --run-test-file-quiet  %source/units/auto-tests/lib-auto-test.reds ;; excluded from ARM tests
  --run-test-file-quiet  %source/units/auto-tests/float-lib-auto-test.reds   ; not in Arm tests   
  --run-test-file-quiet  %source/units/auto-tests/float32-lib-auto-test.reds ; not in Arm tests
  --run-test-file-quiet %source/units/auto-tests/float-auto-test.reds
  --run-test-file-quiet %source/units/auto-tests/float32-auto-test.reds
===end-group===

===start-group=== "Compiler Tests"
  --run-script-quiet %source/compiler/alias-test.r
  --run-script-quiet %source/compiler/cast-test.r
  --run-script-quiet %source/compiler/comp-err-test.r
  --run-script-quiet %source/compiler/exit-test.r
  --run-script-quiet %source/compiler/int-literals-test.r
  --run-script-quiet %source/compiler/output-test.r
  --run-script-quiet %source/compiler/return-test.r
  --run-script-quiet %source/compiler/cond-expr-test.r
  --run-script-quiet %source/compiler/inference-test.r
  --run-script-quiet %source/compiler/callback-test.r
  --run-script-quiet %source/compiler/infix-test.r
  --run-script-quiet %source/compiler/not-test.r
  --run-script-quiet %source/compiler/print-test.r
  --run-script-quiet %source/compiler/enum-test.r
===end-group===

***end-run-quiet***

end-time: now/precise
print ["       in" difference end-time start-time newline]
system/options/quiet: store-quiet-mode
ask "hit enter to finish"
print ""


