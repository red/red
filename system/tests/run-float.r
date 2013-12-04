REBOL [
  Title:   "Builds and Runs the Red/System Tests for Float-Partial"
	File: 	 %run-float.r
	Author:  "Peter W A Wood"
	Version: 0.2.0
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

;; make auto tests if needed
make-if-needed? %source/units/auto-tests/float-auto-test.reds
                %source/units/make-float-auto-test.r
make-if-needed? %source/units/auto-tests/float32-auto-test.reds
                %source/units/make-float32-auto-test.r
                
;; make lib-test files if needed
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
print rejoin ["Quick-Test v" qt/version]
print rejoin ["REBOL " system/version]

start-time: now/precise

***start-run-quiet*** "Red/System - Float Partial"

===start-group=== "Datatype tests"
  --run-test-file-quiet %source/units/float-test.reds
  --run-test-file-quiet %source/units/float32-test.reds
===end-group===

===start-group=== "Auto-tests"
  --run-test-file-quiet  %source/units/auto-tests/float-lib-auto-test.reds   ; not in Arm tests   
  --run-test-file-quiet  %source/units/auto-tests/float32-lib-auto-test.reds ; not in Arm tests
  --run-test-file-quiet %source/units/auto-tests/float-auto-test.reds
  --run-test-file-quiet %source/units/auto-tests/float32-auto-test.reds
===end-group===

***end-run-quiet***

end-time: now/precise
print ["       in" difference end-time start-time newline]
system/options/quiet: store-quiet-mode
ask "hit enter to finish"
print ""


