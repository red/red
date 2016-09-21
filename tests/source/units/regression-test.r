REBOL [
	Title:   "Red regression errors test script"
	Author:  "Boleslav Březovský"
	File: 	 %regression-test.r
	Rights:  "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

cd %../

; help functions for crash and compiler-problem detection
true?: func [value] [not not value]
crashed?: does [true? find qt/output "*** Runtime Error 1: access violation"]
compiled?: does [true? not find qt/comp-output "Error"]
script-error?: does [true? find qt/output "Script Error"]

~~~start-file~~~ "Red regressions"

	--test-- "#1080"
		--compile-and-run-this {do load "x:"}
		--assert script-error?

	--test-- "#1866"
		--compile-and-run-this {do [parse "abc" [(return 1)]]}
		--assert not crashed?

	--test-- "#1868"
		--compile-and-run-this {
dot2d: func [a [pair!] b [pair!] return: [float!]][
	(to float! a/x * to float! b/x) + (to float! b/y * to float! b/y)
]

norm: func [a [pair!] return: [integer!] /local d2 ][
	d2: dot2d a a 
	res: to integer! (square-root d2) 
	return res 
]
distance: func [a [pair!] b [pair!] return: [integer!] /local res ][
	norm (a - b)
]
}
	--assert compiled?

	--test-- "#1895"
		--compile-and-run-this {
fn: func [body [block!]] [collect [do body]]
fn [x: 1]
}
	 	--assert not crashed?

	--test-- "#1907"
		--compile-and-run-this {do [set: 1]}
		--assert not crashed?

	; --test-- "#2133"
	;	OPEN
	; 	--compile-and-run/pgm %tests/source/units/issue-2133.red
	; 	--assert not crashed?

	--test-- "#2143"
		--compile-and-run-this {
do [
	ts: [test: 10]
	t-o: object []
	make t-o ts		
]
}
		--assert not crashed?

	--test-- "#2162"
		--compile-and-run-this {write/info https://api.github.com/user [GET [User-Agent: "me"]]}
		--assert not crashed?

	--test-- "#2173"
		--compile-and-run-this {not parse [] [help]}
		--assert not crashed?

	--test-- "#2179"
		--compile-and-run-this {
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
		--compile-and-run-this {sym: 10 forall sym []}
		--assert not crashed?

	--test-- "#2214"
		--compile-and-run-this {make image! []}
		--assert not crashed?

;	print mold qt/output
;	print mold qt/comp-output

~~~end-file~~~ 