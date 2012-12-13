REBOL [
  Title:   "Generates Red equal? tests"
	Author:  "Peter W A Wood"
	File: 	 %make-equal-auto-test.r
	Version: 0.1.0
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;; This first version assumes that all = tests are in the form
;;  --assert value = value

;; initialisations 

make-dir %auto-tests/
file-out: %auto-tests/equal-auto-test.red


;; read = test file 
test-src: read %infix-equal-test.red

replace test-src {***makelength***} length? read %make-equal-auto-test.r
replace/all test-src {--test-- "ie-} {--test-- "equal-}
replace/all test-src "--assert " "--assert equal? "
replace/all test-src " = " " "
write file-out test-src
      
print "Equal auto test file generated"






