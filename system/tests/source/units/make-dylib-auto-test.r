REBOL [
  Title:   "Generates Red/System dylib tests"
	Author:  "Peter W A Wood"
	File: 	 %make-dylib-auto-test.r
	Version: 0.1.0
	Rights:  "Copyright (C) 2012-2013 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

;;; Initialisations
make-dir %auto-tests/
file-out: %auto-tests/dylib-auto-test.reds

;; test script header including the lib definitions
test-script-header: read %dylib-test-script-header.txt

;; the libs
libs: read %dylib-libs.txt

;; the tests
tests: read %dylib-tests.txt

;; test script footer
test-script-footer: read %dylib-test-script-footer.txt

;; dll target
dll-target: switch/default fourth system/version [
	2 ["Darwin"]
	3 ["Windows"]
][
	"Linux"
]

;; workout dll names
suffix: switch/default fourth system/version [
	2 [".dylib"]
	3 [".dll"]
][
	".so"
]

;;; Processing

;; update the test header with the current make file length and write it
replace test-script-header "###make-length###" length? read %make-dylib-auto-test.r
write file-out test-script-header

;; update the #include statements, write them and the tests
if dll-target [
	dll1-name: join %libtest-dll1 suffix
	dll2-name: join %libtest-dll2 suffix
	either dll-target = "Windows" [
		replace libs "***test-dll1***" dll1-name
		replace libs "***test-dll2***" dll2-name
	][
		replace libs "***test-dll1***" qt/runnable-dir/:dll1-name
		replace libs "***test-dll2***" qt/runnable-dir/:dll2-name
	]
	write/append file-out libs
	write/append file-out tests
]

;; write the test footer
write/append file-out test-script-footer

