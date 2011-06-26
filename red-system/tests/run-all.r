REBOL [
  Title:   "Builds and Runs the Red/System Tests"
	File: 	 %run-all.r
	Author:  "Peter W A Wood"
	Version: 0.4.1
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

;; make runnable/ directory if needed 
make-dir %runnable/
;; include quick-test.r
if not value? 'qt [do %quick-test/quick-test.r]

print rejoin ["Quick-Test v" system/script/header/version]
print rejoin ["Running under REBOL " system/version]

print "Running rs-test-suite.r..."
t0: now/time/precise

;; copy and run rs-test-suite.r
write %runnable/rs-test-suite.r read %source/rs-test-suite.r
do %runnable/rs-test-suite.r

print ["...done in" now/time/precise - t0 newline]

halt


