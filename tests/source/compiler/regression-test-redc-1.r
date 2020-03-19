REBOL [
	Title:   "Regression tests script for Red Compiler"
	Author:  "Boleslav Březovský"
	File: 	 %regression-test-redc-1.r
	Rights:  "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]


; cd %../
;--separate-log-file

~~~start-file~~~ "Red Compiler Regression tests part 1"

===start-group=== "Red regressions #1 - #500"

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

	--test-- "#274"
		--compile-and-run-this-red {
#system-global [
	print ["Symptom of the universe: " 42]
]
}
		--assert "Symptom of the universe: 42" == qt/output

	--test-- "#276"
		--compile-this-red {
#system-global [
	c: #" "
]
}
		--assert compiled?

	--test-- "#304"
		--compile-this-red {c: #"^^(0A)"} ; double ^^ to prevent escape mangling when moving code from Rebol to Red
		--assert compiled?

	--test-- "#312"
		--compile-this-red {f: func[/local f][]}
		--assert compiled?

	--test-- "#323"
		--compile-this-red {loop []}
		--assert true? find qt/comp-output "expected a block for LOOP-BODY instead of none! value"

	--test-- "#326"
		--compile-this-red {f: func[:a [integer!]] []}
		--assert compiled?

	--test-- "#328"
		--compile-this-red {x}
		--assert not find qt/comp-output "%red/boot.red"

	--test-- "#332"
		--compile-this-red {exit}
		--assert not compiled?
		--compile-this-red {return}
		--assert not compiled?

	--test-- "#347"
		--compile-this-red {
#system-global [
	f: does [print-line "Error"]
]
}
		--assert compiled?

	--test-- "#355"
		--compile-and-run-this-red {do [unless true []]}
		--assert not crashed?

	--test-- "#358"
		--compile-and-run-this-red {do [reflect :first 'spec]}
		--assert not crashed?

	--test-- "#362"
		--compile-this-red {
f: routine [
	s [string!]
	return: [integer!]
][
	0
]
f ""
}
		--assert compiled?

	--test-- "#363"
		--compile-this-red {
f: routine [
	return: [integer!]
][
	#either OS = 'Windows [
		0
    ] [
		1
    ]
]
}
		--assert compiled?

	--test-- "#367"
		--compile-this-red {#1}
		--assert compiled?

	--test-- "#369"
		--compile-this-red {
f: routine [
	return: [integer!]
][
	0
]
if yes [print f]
}
		--assert compiled?

	--test-- "#370"
		--compile-this-red {
f: routine [
	"Test."
][
]
f
}
		--assert compiled?

	--test-- "#372"
		--compile-this-red {
switch/default 1 [
	1 []
][]
}
		--assert compiled?

	--test-- "#373"
		--compile-this-red {
zero?: routine [
	value [integer!]
	return: [logic!]
][
	value = 0
]
print zero? 0
}
		--assert compiled?

	--test-- "#374"
		--compile-this-red {
f: does [
	for i 1 10 1 [
		print i
	]
]
}
		--assert not compiled?

	--test-- "#376"
		--compile-this-red {
f: routine [
	"Test."
	n [integer!]
][
]
f 0
}
		--assert compiled?

	--test-- "#377"
		--compile-this-red {
#system-global [
	c: context [
	]
]
f: routine [
	a [integer!]
][
	with c [a]
]
}
		--assert compiled?

	--test-- "#383"
		--compile-and-run-this-red {
s: "!"
print s
}
		--assert not find qt/output {"}

	--test-- "#386"
		--compile-and-run-this-red {find/reverse tail [1 2 3 3 2 1] [3 3]}
		--assert not crashed?

	--test-- "#391"
		--compile-this-red {
f: function [
	a
][
	a: 1
]
}
		--assert compiled?

	--test-- "#392"
		--compile-this-red {
a: (
	1
)
}
		--assert compiled?

	--test-- "#394"
		--compile-and-run-this-red {
f: function [
	a [integer!]
	b [integer!]
][
	print a
	print b
]
x: 1
f x switch/default yes [
	yes [x: 2]
][
	x: 2
]

f: function [
	a [block!]
	b [block!]
][
	print a/1
	print b/1
]
x: [1 2]
f x switch/default yes [
	yes [x: next x]
][
	x: next x
]
}
		--assert equal? "1 2 1 2" trim/lines qt/output

	--test-- "#396"
		--compile-this-red {
f: function [
] [
	x: 1
	x: 1
]
}
		--assert compiled?

	--test-- "#398"
		--compile-this-red {
f: func [
	b [block!]
] [
	forall b [
	]
]
}
		--assert compiled?

	--test-- "#402"
		--compile-this-red {
f: func [
	/r
	/x a
] [
]
	f/x 0
}
		--assert compiled?

	--test-- "#405"
		--compile-this-red {
f: func [
	/local i
] [
	repeat i 10 [
	]
]
}
		--assert compiled?

	--test-- "#406"
		--compile-this-red {
Red []

f: func [
	/local y
] [
	x: 'y
]
}
		--assert compiled?

	--test-- "#407"
		--compile-and-run-this-red {
do [
	f: func [
		/local x
	] [
		x: 'y
		do [set x 1]
	]
	f
	probe y
]
}
		--assert not crashed?

	--test-- "#412"
		--compile-and-run-this-red {
f: func [
	/local x
][
	[x]
]
do f
}
		--assert not crashed?

	--test-- "#414"
		--compile-and-run-this-red {
r: routine [
	a [integer!]
	b [integer!]
] [
	?? a
	?? b
]
f: function [
	/p
		q
	return: [integer!]
] [
	a: 1
	b: 2
	r a b
]
do [f]
}
	--assert equal? "a: 1 b: 2" trim/lines qt/output

	--test-- "#420" ; and #415 also
		--compile-and-run-this-red {
f: function [
][
	g: func [
	][
	]
]
f
}
		--assert not crashed?

	--test-- "#426"
		--compile-and-run-this-red {
s: {
    x/
}
}
		--assert not crashed?

	--test-- "#428"
		--compile-and-run-this-red {
function [] [
	[text]
]			
}
		--assert not crashed?

	--test-- "#435"
		--compile-this-red {
f: function [] [
    x: 0
    if set 'x 0 [
    ]
]

f: has [x] [
    if set 'x 0 [
    ]
]
}
	--assert compiled?

;	--test-- "#437"
;	TODO: problems with source

	--test-- "#453"
		--compile-this-red {
words: [a b c d /local]
clear find words /local
}
		--assert compiled?

	--test-- "#460"
		--compile-and-run-this-red {head insert "" 1}
		--assert not crashed?

	--test-- "#461"
		--compile-and-run-this-red {
fn: func [
	'word
] [
	mold :word
] 
fn :+
fn '+
fn +
}
		--assert not crashed?

	--test-- "#468"
		--compile-this-red {
r: routine [
	/local
	b	[byte!]
	cp	[integer!]
][
	cp: 1
	b: as byte! (cp >>> 6)              
]
}
		--assert compiled?

	--test-- "#482"
		--compile-and-run-this-red {
prin: does [
	print "My prin"
]
prin newline
do [prin newline]
f: does [
	print "f1"
]
f: does [
	print "f2"
]
f
do [f]
}
		--assert not found? find qt/output "f1"

	--test-- "#486"
		--compile-and-run-this-red {
b: [x]
print b/1			
}
		--assert equal? "x" trim/lines qt/output
	
	--test-- "#492"
		--compile-this-red {
flexfun-s: function [
	s [string!] 
	return: [string!]
] [
	return s
]
flexfun-i: function [
	i [integer!] 
	return: [integer!] 
] [
	return i
]
flexfun: function [
	n [integer! float! string!] 
	return: [string! integer! logic!] 
	/local rv
] [
	rv: type? n
	either "string" = rv [uitstr: flexfun-s n] [uitint: flexfun-i n]
]
}
		--assert compiled?

===end-group===

~~~end-file~~~ 
