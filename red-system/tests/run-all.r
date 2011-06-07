REBOL [
  Title:   "Builds and Runs the Red/System Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.1.1
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; make runnable/ directory if needed 
make-dir %runnable/
;; include quick-test.r
if not value? 'qt [do %quick-test/quick-test.r]

print rejoin ["Quick-Test v" system/script/header/version]

;; compile & run rs-test-suite.reds
print "Compiling rs-test-suite.reds..."
t0: now/time/precise

either exe: qt/compile %source/rs-test-suite.reds [
  print ["...done in" now/time/precise - t0]
  print "Running rs-test-suite..."
  t0: now/time/precise
  qt/run exe
  print ["...done in" now/time/precise - t0 newline]
  print qt/output
  part1-failures?: either find qt/output "TEST FAILURES" [true] [false]
][
  qt/start-test "Test Suite Compile Error!!!!!!"
  qt/assert false
  print qt/comp-output
  part1-failures?: true
]

;; copy and run rs-test-suite.r
write %runnable/rs-test-suite.r read %source/rs-test-suite.r
do %runnable/rs-test-suite.r

if part1-failures? [print "^/****** FAILURES IN PART I ABOVE ******"]

print ""

halt


