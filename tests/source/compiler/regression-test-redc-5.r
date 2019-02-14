REBOL [
	Title:   "Regression tests script for Red Compiler"
	Author:  "Boleslav Březovský"
	File: 	 %regression-test-redc.r
	Rights:  "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]


; cd %../
;--separate-log-file

~~~start-file~~~ "Red Compiler Regression tests part 5"

===start-group=== "Red regressions #2001 - #2500"

	; help functions for crash and compiler-problem detection
	true?: func [value] [not not value]
	crashed?: does [true? find qt/output "*** Runtime Error"]
	compiled?: does [true? not find qt/comp-output "Error"]
	script-error?: does [true? find qt/output "Script Error"]
	compiler-error?: does [true? find qt/comp-output "*** Compiler Internal Error"]
	compilation-error?: does [true? find qt/comp-output "*** Compilation Error"]
	loading-error: func [value] [found? find qt/comp-output join "*** Loading Error: " value]
	compilation-error: func [value] [found? find qt/comp-output join "*** Compilation Error: " value]
	syntax-error: func [value] [found? find qt/comp-output join "*** Syntax Error: " value]
	script-error: func [value] [found? find qt/output join "*** Script Error: " value]
	; -test-: :--test--
	; --test--: func [value] [probe value -test- value]

	--test-- "#2007"
		; NOTE: without View support `make image!` produces a runtime error
		--compile-and-run-this-red {make image! 0x0}
		--assert not crashed?

	--test-- "#2027"
		--compile-and-run-this-red {do [a: func [b "b var" [integer!]][b]]}
		--assert script-error "invalid function definition"

	; --test-- "#2133"
	;	FIXME: still OPEN
	; 	--compile-and-run/pgm %tests/source/units/issue-2133.red
	; 	--assert not crashed?

	--test-- "#2137"
		--compile-and-run-this-red {repeat n 56 [to string! debase/base at form to-hex n + 191 7 16]}
		--assert not crashed?

	--test-- "#2143"
		--compile-and-run-this-red {
do [
	ts: [test: 10]
	t-o: object []
	make t-o ts		
]
}
		--assert not crashed?

	--test-- "#2159"
		--compile-and-run-this-red {append #{} to-hex 20}
		--assert not crashed?

	--test-- "#2162"
		--compile-and-run-this-red {write/info https://api.github.com/user [GET [User-Agent: "me"]]}
		--assert not crashed?

	--test-- "#2173"
		--compile-and-run-this-red {not parse [] [help]}
		--assert not crashed?

	--test-- "#2179"
		--compile-and-run-this-red {
test: none
parse ["hello" "world"] ["hello" set test opt "world"]
test
parse ["hello"] ["hello" set test opt "world"]
test
parse ["hello"] ["hello" set test any "world"]
test
}
		--assert not crashed?

	--test-- "#2182"
		--compile-and-run-this-red {sym: 10 forall sym []}
		--assert not crashed?

	--test-- "#2214"
		; NOTE: without View support `make image!` produces a runtime error
		--compile-and-run-this-red {make image! []}
		--assert not crashed?

===end-group===

~~~end-file~~~ 