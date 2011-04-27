Red/System [
	Title:   "Part of a basic test suite for Red/System"
	File: 	 %rs-test-suite.reds
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#include %../quick-test/quick-test-all.reds

qt-start-run "Red/System Test Suite - Part I"

;-- Datatype tests
#include %units/logic-test.reds
qt-update-totals
#include %units/byte-test.reds
qt-update-totals

;-- Native functions tests
#include %units/not-test.reds
qt-update-totals

;-- Special natives tests
#include %units/exit-test.reds
qt-update-totals
#include %units/return-test.reds
qt-update-totals

;-- Math operators tests
#include %units/modulo-test.reds
qt-update-totals

;-- Infix syntax for functions
#include %units/infix-test.reds
qt-update-totals

qt-end-run

