REBOL [
	Title:   "Regression tests script for Red Compiler"
	Author:  "Boleslav Březovský"
	File: 	 %regression-test-redc-2.r
	Rights:  "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]


; cd %../
;--separate-log-file

~~~start-file~~~ "Red Compiler Regression tests part 2"

===start-group=== "Red regressions #501 - #1000"

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

	--test-- "#506"
		--compile-this-red {
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

	--test-- "#523"
		--compile-this-red {unset? :x}
		--assert compilation-error "undefined word"
		--compile-this-red {unset? get/any 'x}
		--assert compiled?


	--test-- "#530"
		--compile-and-run-this-red {
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
		--assert equal? "unset unset unset unset" trim/lines qt/output

	--test-- "#537"
		--compile-this-red {
#system-global [
	series!: alias struct! [i [integer!]]
	s!: alias struct! [s [series!]]
]
}
		--assert compiled?

	--test-- "#538" 
		--compile-this-red {Red/System []}
		--assert compiled?

	--test-- "#540" 
		--compile-this-red {
#system-global []
#system-global []
}
		--assert compiled?

	--test-- "#553"
		--compile-and-run-this-red {
b: 23
probe quote b
probe quote :b
}
		--assert not crashed?

	--test-- "#563"
		--compile-and-run-this-red {
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
		--compile-and-run-this-red {
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
		--compile-and-run-this-red {
b: []
parse [1] [
	collect into b [
		collect [keep integer!]
	]
]
}
		--assert not crashed?

	--test-- "#574"
		--compile-and-run-this-red {probe do [switch 'a [a b [1] b [2]]]}
		--assert not crashed?

	--test-- "#587"
		--compile-and-run-this-red {probe :zero?}
		--assert not crashed?

	--test-- "#589"
		--compile-and-run-this-red {a: 1;}
		--assert not crashed?

	--test-- "#606"
		--compile-this-red {print ["No error"}
		--assert not compiled?

	--test-- "#608"
		--compile-this-red {a: "hello}
		--assert not compiled?

	--test-- "#620"
		--compile-and-run-this-red {
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
		--compile-and-run-this-red {
st1: "<id"
delimiter: charset "<"
rule: [some [delimiter | copy c skip]]
print parse-trace st1 rule
}
		--assert not crashed?

	--test-- "#633"
		; double ^^ to prevent escape mangling when moving code from Rebol to Red
		--compile-this-red {#"^^(back)"}
		;print mold qt/comp-output
		--assert compiled?

	--test-- "#634"
		--compile-and-run-this-red {make block! 0 none}
		--assert not crashed?

	--test-- "#637"
		--compile-this-red {
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

	--test-- "#650"
		--compile-this-red {f: func [/1][] f/1}
		--assert not compiled?

	--test-- "#659"
		--compile-and-run-this-red {
f: does [parse [] []]
r: [
	ahead block! into [r]
|	skip (f)
]
parse [[0]] r
}
	--assert not crashed?

	--test-- "#667"
		--compile-and-run-this-red {
code: [print "Hello"]
replace code "Hello" "Cheers"
}
	--assert not crashed?


; NOTE: Output of these tests is probably messed by Rebol
;		so I leave it commented out for now

	; --test-- "#740"
	; 	--compile-and-run-this-red {print "%e中b"}
	; 	--assert equal? "%e中b" qt/output

	; --test-- "#745"
	; 	--compile-and-run-this-red {print mold %目录1}
	; 	--assert equal? "%目录1" qt/output

	--test-- "#748"
		--compile-and-run-this-red {
txt: "foo"
remove txt
print txt
}
		--assert 2 = length? trim/all qt/output

	--test-- "#765"
		--compile-and-run-this-red {
board: [ 'a 'a 'a ]
while [ board: find board 'a ] [
	print index? board 
	board: next board
]
}
		--assert not script-error?

	--test-- "#778"
		--compile-and-run-this-red {
f: function[] [return 1]
t: (f)
f
t: f
}
		--assert not crashed?

	--test-- "#820"
	; also see #430
		--compile-and-run-this-red {		
print [1 2 3]
print [1 space 3]
print [1 space space 3]
}
		--assert equal? qt/output {1 2 3^/1   3^/1     3^/}

	--test-- "#829"
		--compile-and-run-this-red {print "a^^@b"}
		--assert equal? "a^@b" trim/tail qt/output

 	--test-- "#832"
		--compile-and-run-this-red {
r: routine [
	/local expected [c-string!]
][
	expected: {^^(F0)^^(9D)^^(84)^^(A2)}
	print [length? expected]
]
r
}
	--assert equal? qt/output "4"

	--test-- "#837"
		--compile-and-run-this-red {
s: "123"
load {s/"1"}
}
		--assert not crashed?

	--test-- "#839"
		--compile-and-run-this-red {
take/part "as" 4
}
		--assert not crashed?


	;--test-- "#847"
	; FIXME: still not fixed in 0.6.4

	--test-- "#877"
		--compile-and-run-this-red {
#system [
    print-line ["In Red/System 1.23 = " 1.23]
]			
}
		--assert equal? "In Red/System 1.23 = 1.23" trim/tail qt/output

	--test-- "#902"
		--compile-and-run-this-red {
parse http://rebol.info/foo [
	"http" opt "s" "://rebol.info" to end
]
}
		--assert not crashed?

	--test-- "#916"
		--compile-and-run-this-red {do [round/x 1]}
		--assert not crashed?

	--test-- "#917"
		--compile-and-run-this-red {
o: context [a: b: none]
}
		--assert not crashed?

	--test-- "#918"
		--compile-this-red {
f: func [o [object!]] [
	o/a: 1
]
o: object [a: 0]
}
		--assert compiled?

	--test-- "#923"
		--compile-this-red {
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
		--compile-this-red {
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
		--compile-this-red {
print*: :print
print: does []
}
		--assert compiled?

	--test-- "#946"
		--compile-this-red {
f: function [
	a [object!]
][
	a/b
]
}
		--assert compiled?

	--test-- "#947"
		--compile-this-red {
f: func [
	o [object!]
][
	if o/a [o/a]
]
}
		--assert compiled?

	--test-- "#956"
		--compile-this-red {
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
		--compile-this-red {
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
		--compile-this-red {
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
		--compile-this-red {
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
		--compile-this-red {
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
		--compile-this-red {
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
		--compile-this-red {
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
		--compile-this-red {
Red [
    Type: 'library
]
}
		--assert compiled?

===end-group===

~~~end-file~~~ 
