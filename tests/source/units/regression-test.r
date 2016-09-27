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
-test-: :--test--
--test--: func [value] [probe value -test- value]

;--separate-log-file

~~~start-file~~~ "Red regressions"

	--test-- "#323"
		--compile-this {loop []}
		--assert true? find qt/comp-output "expected a block for LOOP-BODY instead of none! value"

	--test-- "#326"
		--compile-this {f: func[:a [integer!]] []}
		--assert compiled?

	--test-- "#328"
		--compile-this {x}
		--assert not find qt/comp-output "%red/boot.red"

	--test-- "#332"
		--compile-this {exit}
		--assert not compiled?
		--compile-this {return}
		--assert not compiled?

	--test-- "#347"
		--compile-this {
#system-global [
	f: does [print-line "Error"]
]
}
		--assert compiled?

	--test-- "#355"
		--compile-and-run-this {do [unless true []]}
		--assert not crashed?

	--test-- "#358"
		--compile-and-run-this {do [reflect :first 'spec]}
		--assert not crashed?

	--test-- "#362"
		--compile-this {
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
		--compile-this {
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
		--compile-this {#1}
		--assert compiled?

	--test-- "#369"
		--compile-this {
f: routine [
	return: [integer!]
][
	0
]
if yes [print f]
}
		--assert compiled?

	--test-- "#370"
		--compile-this {
f: routine [
	"Test."
][
]
f
}
		--assert compiled?

	--test-- "#372"
		--compile-this {
switch/default 1 [
	1 []
][]
}
		--assert compiled?

	--test-- "#373"
		--compile-this {
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
		--compile-this {
f: does [
	for i 1 10 1 [
		print i
	]
]
}
		--assert not compiled?

	--test-- "#376"
		--compile-this {
f: routine [
	"Test."
	n [integer!]
][
]
f 0
}
		--assert compiled?

	--test-- "#377"
		--compile-this {
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
		--compile-and-run-this {
s: "!"
print s
}
		--assert not find qt/output {"}

	--test-- "#386"
		--compile-and-run-this {find/reverse tail [1 2 3 3 2 1] [3 3]}
		--assert not crashed?

	--test-- "#391"
		--compile-this {
f: function [
	a
][
	a: 1
]
}
		--assert compiled?

	--test-- "#392"
		--compile-this {
a: (
	1
)
}
		--assert compiled?

	--test-- "#394"
		--compile-and-run-this {
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
		--compile-this {
f: function [
] [
	x: 1
	x: 1
]
}
		--assert compiled?

	--test-- "#398"
		--compile-this {
f: func [
	b [block!]
] [
	forall b [
	]
]
}
		--assert compiled?

	--test-- "#402"
		--compile-this {
f: func [
	/r
	/x a
] [
]
	f/x 0
}
		--assert compiled?

	--test-- "#405"
		--compile-this {
f: func [
	/local i
] [
	repeat i 10 [
	]
]
}
		--assert compiled?

	--test-- "#406"
		--compile-this {
Red []

f: func [
	/local y
] [
	x: 'y
]
}
		--assert compiled?

	--test-- "#407"
		--compile-and-run-this {
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
		--compile-and-run-this {
f: func [
	/local x
][
	[x]
]
do f
}
		--assert not crashed?

	--test-- "#414"
		--compile-and-run-this {
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
		--compile-and-run-this {
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
		--compile-and-run-this {
s: {
    x/
}
}
		--assert not crashed?

	--test-- "#428"
		--compile-and-run-this {
function [] [
	[text]
]			
}
		--assert not crashed?

	--test-- "#435"
		--compile-this {
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
		--compile-this {
words: [a b c d /local]
clear find words /local
}
		--assert compiled?

	--test-- "#460"
		--compile-and-run-this {head insert "" 1}
		--assert not crashed?

	--test-- "#461"
		--compile-and-run-this {
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

	--test-- "#486"
		--compile-and-run-this {
b: [x]
print b/1			
}
		--assert equal? "x" trim/lines qt/output
	
	--test-- "#492"
		--compile-this {
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

	--test-- "#506"
		--compile-this {
r: routine [
    i [integer!]
    s [string!]
][
]
r2: routine [
    return: [logic!]
][
]

if no [
    if no [
        if i: 0 [
            if no [
                if no [
                    while [yes] [
                        case [
                            no []
                            no []
                            yes [
                                s: skip "" 0
                                append clear "" ""

                                case [
                                    all [][]
                                    all [][]
                                    all [
                                        r i ""
                                    ][
                                    ]
                                    yes [
                                        if r2 []
                                    ]
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]
]
}
		--assert compiled?

	--test-- "#530"
		--compile-and-run-this {
f: function [
	s
][
	probe first reduce x: [do s]
]
g: function [
	s
][
	probe first reduce/into x: [do s] []
]
probe f [()]
probe g [()]
}
		--assert equal? "unset unset none none" trim/lines qt/output

	--test-- "#537"
		--compile-this {
#system-global [
	series!: alias struct! [i [integer!]]
	s!: alias struct! [s [series!]]
]
}
		--assert compiled?

	--test-- "#538" 
		--compile-this {Red/System []}
		--assert compiled?

	--test-- "#540" 
		--compile-this {
#system-global []
#system-global []
}
		--assert compiled?

	--test-- "#553"
		--compile-and-run-this {
b: 23
probe quote b
probe quote :b
}
		--assert not crashed?

	--test-- "#563"
		--compile-and-run-this {
r: [#"+" if (probe f "-")]
f: func [
	t [string!]
][
	parse t [any r]
]
print f "-"
print f "+"
}
		--assert equal? "false false false" trim/lines qt/output

	--test-- "#564"
		--compile-and-run-this {
f: func [
    s [string!]
][
	r: [
		copy l  skip (l: load l)
		copy x  l skip
		[
			#","
		| 	#"]" if (f probe x)
		]
	]
	parse s [any r end]
]
print f "420,]]"
}
		--assert not crashed?

	--test-- "#565"
		--compile-and-run-this {
b: []
parse [1] [
	collect into b [
		collect [keep integer!]
	]
]
}
		--assert not crashed?

	--test-- "#574"
		--compile-and-run-this {probe do [switch 'a [a b [1] b [2]]]}
		--assert not crashed?

	--test-- "#587"
		--compile-and-run-this {probe :zero?}
		--assert not crashed?

	--test-- "#589"
		--compile-and-run-this {a: 1;}
		--assert not crashed?

	--test-- "#606"
		--compile-this {print ["No error"}
		--assert not compiled?

	--test-- "#608"
		--compile-this {a: "hello}
		--assert not compiled?

	--test-- "#620"
		--compile-and-run-this {
str-16: "0123456789abcdef"
s: ""
ss: str-16
print ss
append s ss
print ss

cstr-16: "0123456789abcdef"
cs: copy ""
css: copy cstr-16
print css
append cs css
print css
}
		--assert not crashed?

	--test-- "#630"
		--compile-and-run-this {
st1: "<id"
delimiter: charset "<"
rule: [some [delimiter | copy c skip]]
print parse-trace st1 rule
}
		--assert not crashed?

; FIXME: problems with loading source: 
; *** Syntax Error: Invalid issue! value
; *** line: 2
; *** at: {#"^^H"}
	; --test-- "#633"
	; 	--compile-this {#"^(back)"}
	; 	print mold qt/comp-output
	; 	--assert compiled?

	--test-- "#634"
		--compile-and-run-this {make block! 0 none}
		--assert not crashed?

	--test-- "#637"
		--compile-this {
remain?: routine [
	m [integer!]
	n [integer!]
	return: [integer!]
][
	m % n
]

remain-value: remain? 12 5
print ["remainder of division of over 5 is: " remain-value]
}
		--assert compiled?

	--test-- "#659"
		--compile-and-run-this {
f: does [parse [] []]
r: [
	ahead block! into [r]
|	skip (f)
]
parse [[0]] r
}
	--assert not crashed?

	--test-- "#667"
		--compile-and-run-this {
code: [print "Hello"]
replace code "Hello" "Cheers"
}
	--assert not crashed?

	--test-- "#669"
		--compile-and-run-this {
a: #version 
print type? a 
}
		--assert equal? "string" trim/tail qt/output

	--test-- "#778"
		--compile-and-run-this {
f: function[] [return 1]
t: (f)
f
t: f
}
		--assert not crashed?

	--test-- "#820"
	; also see #430
		--compile-and-run-this {		
print [1 2 3]
print [1 space 3]
print [1 space space 3]
}
		--assert equal? qt/output {1 2 3

1   3

1     3

}

	--test-- "#829"
		--compile-and-run-this {print "a^@b"}
		--assert equal? "a^@b" trim/tail qt/output

; 	--test-- "#832"
; TODO: gives confusing results. "1" here in test, "4" when compiled separately
; 		--compile-and-run-this {
; r: routine [
; 	/local expected [c-string!]
; ][
; 	expected: {^(F0)^(9D)^(84)^(A2)}
; 	print [length? expected]
; ]
; r
; }
; 	print mold qt/output

	--test-- "#837"
		--compile-and-run-this {
s: "123"
load {s/"1"}
}
		--assert not crashed?

	--test-- "#839"
		--compile-and-run-this {
take/part "as" 4
}
		--assert not crashed?


	--test-- "#847"
	; NOTE: let’s hope this is right
		--compile-and-run-this {
foo-test: routine [
	return: [logic!]
	/local inf nan
][
	inf: 1e308 + 1e308
	nan: 0.0 * inf
	all [
		not (inf > nan)
		inf < nan
		not (inf <> nan)
		inf = nan
	]
]
probe foo-test
}
	--assert equal? "true" trim/tail qt/output

	--test-- "#877"
		--compile-and-run-this {
#system [
    print-line ["In Red/System 1.23 = " 1.23]
]			
}
		--assert equal? "In Red/System 1.23 = 1.23" trim/tail qt/output

	--test-- "#902"
		--compile-and-run-this {
parse http://rebol.info/foo [
	"http" opt "s" "://rebol.info" to end
]
}
		--assert not crashed?

	--test-- "#916"
		--compile-and-run-this {do [round/x 1]}
		--assert not crashed?

	--test-- "#917"
		--compile-and-run-this {
o: context [a: b: none]
}
		--assert not crashed?

	--test-- "#918"
		--compile-this {
f: func [o [object!]] [
	o/a: 1
]
o: object [a: 0]
}
		--assert compiled?

	--test-- "#923"
		--compile-this {
c: context [
	a: none
	?? a

	f: does [
		?? a
		print a
		print [a]
	]
]
c/f
}
		--assert compiled?

	--test-- "#930"
		--compile-this {
c: context [
	f: function [
		/extern x
		/local y
	][
		x: 1
		set 'y 2
	]
]
}
		--assert compiled?

	--test-- "#934"
		--compile-this {
print*: :print
print: does []
}
		--assert compiled?

	--test-- "#946"
		--compile-this {
f: function [
	a [object!]
][
	a/b
]
}
		--assert compiled?

	--test-- "#947"
		--compile-this {
f: func [
	o [object!]
][
	if o/a [o/a]
]
}
		--assert compiled?

	--test-- "#956"
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

	--test-- "#957"
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

	--test-- "#959"
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

	--test-- "#960"
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

	--test-- "#962"
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

	--test-- "#965"
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

	--test-- "#969"
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

	--test-- "#970"
		--compile-this {
Red [
    Type: 'library
]
}
		--assert compiled?

	--test-- "#1022"
		--compile-and-run-this {parse [%file] [#"."]}
		--assert not crashed?

	--test-- "#1031"
		--compile-and-run-this {
f: routine [] [print "Why are all my spaces disappearing"]
f
}
	--assert "Why are all my spaces disappearing" = qt/output

	--test-- "#1035"
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

	--test-- "#1042"
		--compile-and-run-this {
varia: 0
print power -1 varia

varia: 1
print power -1 varia
}
	--assert compiled?

	--test-- "#1050"
		--compile-and-run-this {add: func [ a b /local ] [ a + b ]}
		--assert not crashed?

	--test-- "#1054"
		--compile-and-run-this {
do [
	book: object [list-fields: does [words-of self]]
	try [print a]
	print words-of book			
]
}
	--assert not script-error?

	--test-- "#1071"
		--compile-and-run-this {do load {(x)}}
			--assert not crashed?

; 	--test-- "#1075"
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

	--test-- "#1080"
		--compile-and-run-this {do load "x:"}
		--assert script-error?

	--test-- "#1083"
		--compile-and-run-this {do [load {œ∑´®†}]}
		--assert not crashed?

	--test-- "#1117"
		--compile-and-run-this {
do [
	foo: :append/only 
	foo/dup [a b c] [d e] 2
]
}
		--assert not crashed?

	 --test-- "#1135"
		--compile-and-run-this {
do [
	a: func [v [block!]][error? try v]
	a [unset-word]
]
}
		--assert not crashed?

	--test-- "#1141"
		--compile-and-run-this {
o: object [
	A: 1
]
s: 'A
print o/:s
}
		--assert not crashed?

	--test-- "#1159"
		--compile-and-run-this {
f: function [
	/a
	/b
][
	if a [b: true]
]
}
		--assert not crashed?

	--test-- "#1168"
		--compile-and-run-this {do [case [1 > 2 [print "math is broken"] 1 < 2]]}
		--assert not crashed?

	--test-- "#1171"
		--compile-and-run-this {load {]}}
		--assert not crashed?

	--test-- "#1176"
		--compile-and-run-this {
do load {
	blk: reduce [does [asdf]]
	blk/1
}
}
		--assert not crashed?

	--test-- "#1195"
		--compile-and-run-this {			
m: make map! [a: 1 b: 2]
m/b: none
}
		--assert not crashed?

	--test-- "#1207"
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

	--test-- "#1230"
		--compile-and-run-this {
do [
	o: make object! [a: 1 b: 7 c: 13]
	set [o/b o/c] [2 3]
]			
		}
		--assert not crashed?

	--test-- "#1293"
		--compile-and-run-this {
o1: context [
	val: 1
]

o2: context [
	v: o1/val
]
}
		--assert not crashed?

	; --test-- "#1400"
	;	FIXME: Internal compiler error
	; 	--compile-and-run-this {make op! 'x}
	; 	--assert not crashed?

	--test-- "#1416"
		--compile-and-run-this {do [a: "1234" b: skip a 2 copy/part b a]}
		--assert not crashed?

	--test-- "#1490"
		--compile-and-run-this {
o: make object! [f: 5]
do load {set [o/f] 10}
}
	--assert not crashed?

	; --test-- "#1679"
	;	OPEN
	;	--compile-and-run-this {switch 1 []}

	--test-- "#1524"
		--compile-and-run-this {parse [x][keep 1]}
		--assert not crashed?

	--test-- "#1589"
		--compile-and-run-this {power -1 0.5}
		--assert not crashed?

	--test-- "#1694"
		--compile-and-run-this {
do  [
	f: func [x] [x]
	probe try [f/only 3]
]
		}
		--assert true? find qt/output "arg2: 'only"

	;--test-- "#1720"
	; OPEN
	;	--compile-and-run-this {write http://abc.com compose [ {} {} ]}
	;	--assert not crashed?

	--test-- "#1730"
		--compile-and-run-this {reduce does ["ok"]}
		--assert not crashed?
		--compile-and-run-this {do [reduce does ["ok"]]}
		--assert not crashed?

	--test-- "#1758"
		--compile-and-run-this {do [system/options/path: none]}
		--assert not crashed?

	--test-- "#1831"
		--compile-and-run-this {do [function [a] [repeat a/1]]}
		--assert not crashed?

	--test-- "#1836"
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

	--test-- "#1842"
		--compile-and-run-this {do [throw 10]}
		--assert not crashed?

	--test-- "#1866"
		--compile-and-run-this {do [parse "abc" [(return 1)]]}
		--assert not crashed?
		probe qt/output

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