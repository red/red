REBOL [
	Title:   "Regression tests script for Red Compiler"
	Author:  "Boleslav Březovský"
	File: 	 %regression-test-redc-3.r
	Rights:  "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]


; cd %../
;--separate-log-file

~~~start-file~~~ "Red Compiler Regression tests part 3"

===start-group=== "Red regressions #1001 - #2000"

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
	script-error: func [value] [found? find qt/comp-output join "*** Script Error: " value]
	; -test-: :--test--
	; --test--: func [value] [probe value -test- value]

	--test-- "#1003"
		--compile-and-run-this-red {
master: make object! [
	v: 0
	on-change*: function[w o n][print [w 'changed]]
]
c: copy master
c/v: 5
}
		--assert found? find qt/output "changed"

	--test-- "#1022"
		--compile-and-run-this-red {parse [%file] [#"."]}
		--assert not crashed?

	--test-- "#1031"
		--compile-and-run-this-red {
f: routine [] [print "Why are all my spaces disappearing"]
f
}
	--assert "Why are all my spaces disappearing" = qt/output

	--test-- "#1035"
		--compile-and-run-this-red {
do [
global-count: 0

global-count-inc: function [
	condition [logic!]
][
	if condition [global-count: global-count + 1]
]
global-count-inc true
]
}
	--assert not crashed?

	--test-- "#1042"
		--compile-and-run-this-red {
varia: 0
print power -1 varia

varia: 1
print power -1 varia
}
	--assert compiled?

	--test-- "#1050"
		--compile-and-run-this-red {add: func [ a b /local ] [ a + b ]}
		--assert not crashed?

	--test-- "#1054"
		--compile-and-run-this-red {
do [
	book: object [list-fields: does [words-of self]]
	try [print a]
	print words-of book			
]
}
	--assert not script-error?

	--test-- "#1059"
		--compile-this-red {
log-error: function [
	"Log SQLite error."
	db [sqlite!]
][
	print ["Error:" form-error db]
]
}
		--assert compilation-error "invalid datatype name"

	--test-- "#1071"
		--compile-and-run-this-red {do load {(x)}}
			--assert not crashed?

	--test-- "#1075"
		--compile-and-run-this-red {
#system [
	as-float 1 print-line 1
	as-float 1 print-line 2
	as-float 1 print-line 3
	as-float 1 print-line 4
	as-float 1 print-line 5
	as-float 1 print-line 6
	as-float 1 print-line 7
	as-float 1 print-line 8
]
}
		--assert not crashed?

	--test-- "#1080"
		--compile-and-run-this-red {do load "x:"}
		--assert script-error?

	--test-- "#1083"
		--compile-and-run-this-red {do [load {œ∑´®†}]}
		--assert not crashed?

	--test-- "#1090"
		--compile-and-run-this-red {
			#system-global [
				data!: alias struct! [
					count [integer!]
				]
				data: declare data!
			]
			begin1090: routine [] [
				data/count: 0
			]
			;-- compiler cannot redefine used words to a routine, and `count` was used
			count1090: routine [
				return: [integer!]
			] [
				data/count
			]
			begin1090
			prin count1090 print " rows processed"
			print [count1090 "rows processed"]
		}
		--assert equal? qt/output "0 rows processed^/0 rows processed^/"

	--test-- "#1117"
		--compile-and-run-this-red {
do [
	foo: :append/only 
	foo/dup [a b c] [d e] 2
]
}
		--assert not crashed?

	--test-- "#1120"
		--compile-and-run-this-red {load {b: [] parse "1" [some [copy t to end (append b t)]])}}
		--assert not crashed?

	 --test-- "#1135"
		--compile-and-run-this-red {
do [
	a: func [v [block!]][error? try v]
	a [unset-word]
]
}
		--assert not crashed?

	--test-- "#1141"
		--compile-and-run-this-red {
o: object [
	A: 1
]
s: 'A
print o/:s
}
		--assert not crashed?

	--test-- "#1159"
		--compile-and-run-this-red {
f: function [
	/a
	/b
][
	if a [b: true]
]
}
		--assert not crashed?

	--test-- "#1168"
		--compile-and-run-this-red {do [case [1 > 2 [print "math is broken"] 1 < 2]]}
		--assert not crashed?

	--test-- "#1171"
		--compile-and-run-this-red {load {]}}
		--assert not crashed?

	--test-- "#1176"
		--compile-and-run-this-red {
do load {
	blk: reduce [does [asdf]]
	blk/1
}
}
		--assert not crashed?

	--test-- "#1195"
		--compile-and-run-this-red {			
m: make map! [a: 1 b: 2]
m/b: none
}
		--assert not crashed?

	--test-- "#1207"
		--compile-and-run-this-red {
do [
	o: make object! [a: 1 b: 2]
	try [o/c]
	try [o/c: 3]
	o
]
}
		--assert not crashed?
		--compile-and-run-this-red {
do [
	o: make object! [a: 1 b: 2]
	try [o/c]
	try [o/c: 3]
	o/c
]			
}
		--assert not crashed?

	--test-- "#1230"
		--compile-and-run-this-red {
do [
	o: make object! [a: 1 b: 7 c: 13]
	set [o/b o/c] [2 3]
]			
		}
		--assert not crashed?

	--test-- "#1293"
		--compile-and-run-this-red {
o1: context [
	val: 1
]

o2: context [
	v: o1/val
]
}
		--assert not crashed?

	; --test-- "#1345"
		; FIXME: this depends on a dubious external url
		; I'm removing it until a better solution is found 		-- hiiamboris
; 		--compile-and-run-this-red {
; url: http://autocomplete.wunderground.com/aq?format=JSON&lang=zh&query=Beijing
; json: read url		
; }
; 		--assert not crashed?

	--test-- "#1400"
		--compile-this-red {make op! 'x}
		--assert compilation-error "Non-compilable function definition"

	--test-- "#1416"
		--compile-and-run-this-red {do [a: "1234" b: skip a 2 copy/part b a]}
		--assert not crashed?

	--test-- "#1427"
		--compile-this-red {
Red []

obj1: object [
	make: function [return: [object!]] [
		temp: object []
		temp
	]
]
obj2: object [

]

make obj1/make obj2
}
		--assert compiled?

	--test-- "#1490"
		--compile-and-run-this-red {
o: make object! [f: 5]
do load {set [o/f] 10}
}
	--assert not crashed?

===end-group===

~~~end-file~~~ 
