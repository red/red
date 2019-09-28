REBOL [
  Title:   "Generates Red interpreter tests"
	Author:  "Peter W A Wood"
	File: 	 %make-interpreter-auto-tests.r
	Version: 0.3.0
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

;;--------------- initialisations 
make-dir %auto-tests/
number-of-files: 0
tests: copy ""
quick-test-path: to file! clean-path %../../../quick-test/quick-test.red

;; make the file list from all-tests.txt
file-list: copy []
all-tests: read/lines %all-tests.txt
foreach test all-tests [
	unless any [
		find test "routine"
		find test "evaluation" 
	][
		append file-list to file! test
		append file-list join %auto-tests/interp- second split-path to file! test
	]
]

;;--------------- functions

;; write test file with header
write-test-header: func [file-out [file!]] [
	append tests "Red [^(0A)"
	append tests {  Title:   "Red auto-generated interpreter test"^(0A)}
	append tests {	Author:  "Peter W A Wood"^(0A)}
	append tests {  License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"^(0A)}
	append tests "]^(0A)^(0A)"
	append tests "^(0A)^(0A)comment {"
	append tests "  This file is generated by make-interpreter-auto-test.r^(0A)"
	append tests "  Do not edit this file directly.^(0A)"
	append tests "}^(0A)^(0A)"
	write file-out tests
]

write-test-footer: func [file-out [file!]] [
	write/append file-out "]"
]

read-write-test-body: func [
	file-in		[file!]
	file-out	[file!]
	/local
		body
][
	body: read file-in
	body: find/tail body "../../quick-test/quick-test.red"
	insert body join "#include %" [
		quick-test-path "^(0A) #do [interpreted?: true] ^(0A) do ["]
	replace body {~~~start-file~~~ "} {~~~start-file~~~ "interp-}				 
	write/append file-out body
]

;;--------------- Main Processing

print "checking to see if interpreter test files need generating"

foreach [file-in file-out] file-list [
	rebuild: false
	either not exists? file-out [
		rebuild: true
	][
		if 0:00 < difference modified? file-in modified? file-out [
			rebuild: true
		]
	]
	if rebuild [
		tests: copy ""
		write-test-header file-out
		read-write-test-body file-in file-out
		write-test-footer file-out
		number-of-files: number-of-files + 1
	]
]

print [number-of-files "files were generated"]

