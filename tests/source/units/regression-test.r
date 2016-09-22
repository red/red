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
crashed?: does [true? find qt/output "*** Runtime Error"]
compiled?: does [true? not find qt/comp-output "Error"]
script-error?: does [true? find qt/output "Script Error"]

;--separate-log-file

~~~start-file~~~ "Red regressions"

	--test-- probe "#946"
		--compile-this {
f: function [
	a [object!]
][
	a/b
]
}
		--assert compiled?

	--test-- probe "#947"
		--compile-this {
f: func [
	o [object!]
][
	if o/a [o/a]
]
}
		--assert compiled?

	--test-- probe "#956"
		--compile-this {
f: function [
	o [object!]
][
	if o/a [
		all [o]
	]
]
}
		--assert compiled?	

	--test-- probe "#957"
		--compile-this {
f: function [
	o [object!]
] [
	switch o/a [
		0 [
			switch 0 [
				0 [
				]
			]
		]
	]
]
}
		--assert compiled?

	--test-- probe "#959"
		--compile-this {
c: context [
	x: none

	f: func [
		o [object!]
	] [
		x: o/a
	]
]
}
		--assert compiled?

	--test-- probe "#960"
		--compile-this {
c: object [
	d: object [
	]
]

f: func [
][
	c/d
]
}
		--assert compiled?

	--test-- probe "#962"
		--compile-this {
f: function [
    o [object!]
][
	v: none

	case [
		all [
			o/a = o/a
			o/a = o/a
		][
		]
	]
]
}
		--assert compiled?

	--test-- probe "#965"
		--compile-this {
f: func [
    o [object!]
][
    if yes [
        append o/a o/b
    ]
]
}
		--assert compiled?

	--test-- probe "#969"
		--compile-this {
r2: routine [
	i [integer!]
	j [integer!]
][
]

f: function [
    s
][
	s/x = r2 0  any [0 0]
]
}
		--assert compiled?

	--test-- probe "#970"
		--compile-this {
Red [
    Type: 'library
]
}
		--assert compiled?

	--test-- probe "#1022"
		--compile-and-run-this {parse [%file] [#"."]}
		--assert not crashed?

	--test-- probe "#1031"
		--compile-and-run-this {
f: routine [] [print "Why are all my spaces disappearing"]
f
}
	--assert "Why are all my spaces disappearing" = qt/output

	--test-- probe "#1035"
		--compile-and-run-this {
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

	--test-- probe "#1042"
		--compile-and-run-this {
varia: 0
print power -1 varia

varia: 1
print power -1 varia
}
	--assert compiled?

	--test-- probe "#1050"
		--compile-and-run-this {add: func [ a b /local ] [ a + b ]}
		--assert not crashed?

	--test-- probe "#1054"
		--compile-and-run-this {
do [
	book: object [list-fields: does [words-of self]]
	try [print a]
	print words-of book			
]
}
	--assert not script-error?

	--test-- probe "#1071"
		--compile-and-run-this {do load {(x)}}
			--assert not crashed?

; 	--test-- probe "#1075"
; 		--compile-and-run-this {
; #system [
; 	integer/to-float 1 print-line 1
; 	integer/to-float 1 print-line 2
; 	integer/to-float 1 print-line 3
; 	integer/to-float 1 print-line 4
; 	integer/to-float 1 print-line 5
; 	integer/to-float 1 print-line 6
; 	integer/to-float 1 print-line 7
; 	integer/to-float 1 print-line 8
; ]
; }
		--assert not crashed?

	--test-- probe "#1080"
		--compile-and-run-this {do load "x:"}
		--assert script-error?

	--test-- probe "#1083"
		--compile-and-run-this {do [load {œ∑´®†}]}
		--assert not crashed?

	--test-- probe "#1117"
		--compile-and-run-this {
do [
	foo: :append/only 
	foo/dup [a b c] [d e] 2
]
}
		--assert not crashed?

	 --test-- probe "#1135"
		--compile-and-run-this {
do [
	a: func [v [block!]][error? try v]
	a [unset-word]
]
}
		--assert not crashed?

	--test-- probe "#1141"
		--compile-and-run-this {
o: object [
	A: 1
]
s: 'A
print o/:s
}
		--assert not crashed?

	--test-- probe "#1159"
		--compile-and-run-this {
f: function [
	/a
	/b
][
	if a [b: true]
]
}
		--assert not crashed?

	--test-- probe "#1168"
		--compile-and-run-this {do [case [1 > 2 [print "math is broken"] 1 < 2]]}
		--assert not crashed?

	--test-- probe "#1171"
		--compile-and-run-this {load {]}}
		--assert not crashed?

	--test-- probe "#1176"
		--compile-and-run-this {
do load {
	blk: reduce [does [asdf]]
	blk/1
}
}
		--assert not crashed?

	--test-- probe "#1195"
		--compile-and-run-this {			
m: make map! [a: 1 b: 2]
m/b: none
}
		--assert not crashed?

	--test-- probe "#1207"
		--compile-and-run-this {
do [
	o: make object! [a: 1 b: 2]
	try [o/c]
	try [o/c: 3]
	o
]
}
		--assert not crashed?
		--compile-and-run-this {
do [
	o: make object! [a: 1 b: 2]
	try [o/c]
	try [o/c: 3]
	o/c
]			
}
		--assert not crashed?

	--test-- probe "#1230"
		--compile-and-run-this {
do [
	o: make object! [a: 1 b: 7 c: 13]
	set [o/b o/c] [2 3]
]			
		}
		--assert not crashed?

	--test-- probe "#1293"
		--compile-and-run-this {
o1: context [
	val: 1
]

o2: context [
	v: o1/val
]
}
		--assert not crashed?

	; --test-- probe "#1400"
	;	FIXME: Internal compiler error
	; 	--compile-and-run-this {make op! 'x}
	; 	--assert not crashed?

	--test-- probe "#1416"
		--compile-and-run-this {do [a: "1234" b: skip a 2 copy/part b a]}
		--assert not crashed?

	--test-- probe "#1490"
		--compile-and-run-this {
o: make object! [f: 5]
do load {set [o/f] 10}
}
	--assert not crashed?

	; --test-- probe "#1679"
	;	OPEN
	;	--compile-and-run-this {switch 1 []}

	--test-- probe "#1524"
		--compile-and-run-this {parse [x][keep 1]}
		--assert not crashed?

	--test-- probe "#1589"
		--compile-and-run-this {power -1 0.5}
		--assert not crashed?

	--test-- probe "#1694"
		--compile-and-run-this {
do  [
	f: func [x] [x]
	probe try [f/only 3]
]
		}
		--assert true? find qt/output "arg2: 'only"

	;--test-- probe "#1720"
	; OPEN
	;	--compile-and-run-this {write http://abc.com compose [ {} {} ]}
	;	--assert not crashed?

	--test-- probe "#1730"
		--compile-and-run-this {reduce does ["ok"]}
		--assert not crashed?
		--compile-and-run-this {do [reduce does ["ok"]]}
		--assert not crashed?

	--test-- probe "#1758"
		--compile-and-run-this {do [system/options/path: none]}
		--assert not crashed?

	--test-- probe "#1831"
		--compile-and-run-this {do [function [a] [repeat a/1]]}
		--assert not crashed?

	--test-- probe "#1836"
		--compile-and-run-this {
do [
	content: [a [b] c]
	rule: [any [
		set item word! (print item) 
	|	mark: () into [rule] stop: (prin "STOP: " probe stop)]
	]
	parse content rule
]
}
		--assert not crashed?

	--test-- probe "#1842"
		--compile-and-run-this {do [throw 10]}
		--assert not crashed?

	--test-- probe "#1866"
		--compile-and-run-this {do [parse "abc" [(return 1)]]}
		--assert not crashed?
		probe qt/output

	--test-- probe "#1868"
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

	--test-- probe "#1895"
		--compile-and-run-this {
fn: func [body [block!]] [collect [do body]]
fn [x: 1]
}
	 	--assert not crashed?

	--test-- probe "#1907"
		--compile-and-run-this {do [set: 1]}
		--assert not crashed?

	; --test-- probe "#2133"
	;	OPEN
	; 	--compile-and-run/pgm %tests/source/units/issue-2133.red
	; 	--assert not crashed?

	--test-- probe "#2143"
		--compile-and-run-this {
do [
	ts: [test: 10]
	t-o: object []
	make t-o ts		
]
}
		--assert not crashed?

	--test-- probe "#2162"
		--compile-and-run-this {write/info https://api.github.com/user [GET [User-Agent: "me"]]}
		--assert not crashed?

	--test-- probe "#2173"
		--compile-and-run-this {not parse [] [help]}
		--assert not crashed?

	--test-- probe "#2179"
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

	--test-- probe "#2182"
		--compile-and-run-this {sym: 10 forall sym []}
		--assert not crashed?

	--test-- probe "#2214"
		--compile-and-run-this {make image! []}
		--assert not crashed?

;	print mold qt/output
;	print mold qt/comp-output

~~~end-file~~~ 