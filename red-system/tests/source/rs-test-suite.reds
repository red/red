Red/System [
	Title:   "Part of a basic test suite for Red/System"
	File: 	 %rs-test-suite.reds
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#include %../quick-test/quick-test.reds

***start-run*** "Red/System Test Suite - Part I"

;-- Datatype tests
#include %units/logic-test.reds
#include %units/integer-test.reds
#include %units/byte-test.reds
#include %units/c-string-test.reds
#include %units/struct-test.reds
#include %units/pointer-test.reds
 
;-- Native functions tests
#include %units/not-test.reds
 
;-- Special natives tests
#include %units/exit-test.reds
#include %units/return-test.reds
 
;-- Math operators tests
#include %units/modulo-test.reds
 
;-- Infix syntax for functions
#include %units/infix-test.reds
 
***end-run***

