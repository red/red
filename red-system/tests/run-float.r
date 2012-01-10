REBOL [
  Title:   "Builds and Runs the Red/System Tests for Float-Partial"
	File: 	 %run-float.r
	Author:  "Peter W A Wood"
	Version: 0.1.0
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; supress script messages
store-quiet-mode: system/options/quiet
system/options/quiet: true

do %../../quick-test/quick-test.r
qt/tests-dir: system/script/path

;; make lib-test file if needed
flib-test-len: length? read %source/units/float-lib-test-source.reds
save-len: either exists? %source/units/len-flib-test.dat [
  load %source/units/len-flib-test.dat
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

;; run the tests
print rejoin ["Quick-Test v" qt/version]
print rejoin ["REBOL " system/version]

start-time: now/precise

***start-run-quiet*** "Red/System - Float Partial Tests"

===start-group=== "Datatype tests"
  --run-test-file-quiet %source/units/float-test.reds
 
===end-group===

===start-group=== "Auto-tests"
  --run-test-file-quiet  %source/units/auto-tests/float-lib-auto-test.reds 
===end-group===


***end-run-quiet***

end-time: now/precise
print ["       in" difference end-time start-time newline]
system/options/quiet: store-quiet-mode
ask "hit enter to finish"
print ""


