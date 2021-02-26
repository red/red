REBOL [
	Title:   "Regression tests script for Red/System Compiler"
	Author:  "Boleslav Březovský"
	File: 	%regression-test-rsc.r
	Rights:  "Copyright (C) 2016 Boleslav Březovský. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]


;cd %../
;--separate-log-file

~~~start-file~~~ "Red/System Compiler Regression tests"

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
; -test-: :--test--
; --test--: func [value] [probe value -test- value]

===start-group=== "Red/System regressions #1 - #1000"

	--test-- "#28"
		--compile-this {
Red/System []
i: 1 * 0
}
		--assert compiled?

	--test-- "#32"
		--compile-this {
Red/System []

f: func [
	result: [integer!]
] []
}
		--assert not compiled?

	--test-- "#55"
		--compile-this {
Red/System []
i: 0 
i: "A"
}
		--assert not compiled?

	--test-- "#59"
		--compile-this {
Red/System []
exit
}
		--assert not compiled?
		--compile-this {
Red/System []
return
}
		--assert not compiled?

	--test-- "#76"
		--compile-and-run-this {
Red/System []
a: "0"
a/1: a/1 + (2 * 2)
print a
}
		--assert equal? "4" qt/output

	--test-- "#88"
		--compile-this {
Red/System []
s: declare struct! []
}
		--assert not compiled?

	--test-- "#89"
		--compile-this {
Red/System []
OemToChar: 123
}
		--assert compiled?

	--test-- "#136"
		--compile-and-run-this {
Red/System []
a: declare struct! [x [byte!] y [logic!]]
prin-int size? a
}
		--assert equal? "8" qt/output

	--test-- "#138"
		--compile-this {
Red/System []
(1 + 2) and 3
}
		--assert compiled?

	--test-- "#139"
		--compile-this {
Red/System []
assert all [1 = 2]
}
		--assert compiled?

	--test-- "#146"
		--compile-and-run-this {
Red/System []
s: declare struct! [
	a [byte!]
	b [byte!]
	c [byte!]
	d [byte!]
]
s/a: as-byte 1
s/b: as-byte 1
s/c: as-byte 0
s/d: as-byte 0
print as-integer s/a
}
		--assert equal? "1" qt/output

	--test-- "#148"
		--compile-this {
Red/System []
i: declare pointer! [integer!]
b: declare pointer! [byte!]
i: (as pointer! [integer!] b) + 1 + 1
}
		--assert compiled?

	--test-- "#149"
		--compile-and-run-this {
Red/System []
a: declare struct! [value [integer!]]
a/value: 0
p: as pointer! [byte!] a
p/1: as-byte 1
p/2: as-byte 2
print a/value
}
		--assert equal? "513" qt/output

	--test-- "#150"
		--compile-and-run-this {
Red/System []
s!: alias struct! [
	a	[byte!]
	b	[byte!]
	c	[byte!]
	d	[byte!]
]
t: declare s!
t/a: as-byte 1
t/b: as-byte 1
t/c: as-byte 0
t/d: as-byte 0
h: as-integer t/a
print h
}
		--assert equal? "1" qt/output

	--test-- "#151"
		--compile-and-run-this {
Red/System []
a: declare struct! [value [integer!]]
a/value: 0
p: as pointer! [byte!] a
print as-integer p
print newline
print as-integer p +
    1 +
    (1 * 3)
}
		--assert not equal? #"3" last qt/output

	--test-- "#158"
		--compile-and-run-this {
Red/System []
a: as-byte 10h
b: as-byte 80h
print as-integer a
}
		--assert equal? "16" qt/output

	--test-- "#159"
		--compile-and-run-this {
Red/System []
a: as-byte 10h
b: as-byte 80h
c: as-integer a
print c
}
		--assert equal? "16" qt/output

	--test-- "#160"
		--compile-and-run-this {
Red/System []
#define as-binary [as pointer! [byte!]]
a: as-byte 1
b: as-byte 2
print [as-binary (as-integer a) * 2 " "]
print [as-binary (as-integer a) << 2]
}
		--assert equal? "00000002 00000004" qt/output

	--test-- "#161"
		--compile-and-run-this {
Red/System []
a: as-byte 1
b: as-byte 2
print as byte-ptr! (as-integer b) << 16 or as-integer a
}
		--assert equal? "00020001" qt/output

	--test-- "#162"
		--compile-and-run-this {
Red/System []
s: declare struct! [
	a	[byte!]
	b	[byte!]
]
s/a: as-byte 0
s/b: as-byte 1
print as-logic s/a
}
		--assert equal? "false" qt/output

	--test-- "#164"
		--compile-and-run-this {
Red/System []
s: declare struct! [
	a	[byte!]
	b	[byte!]
]
s/a: as-byte 0
s/b: as-byte 1
print either as-logic s/a ["bogus"] [""]
}
		--assert empty? qt/output

	--test-- "#169"
		--compile-this {
Red/System []
s!: alias struct! [x [integer!]]

x: function [
	return: [s!]
][
	either true [
		as s! 0
	][
		null
	]
]
}
		--assert compiled?

	--test-- "#171"
		--compile-and-run-this {
Red/System []
x: as struct! [x [integer!]] 0
if as-logic x [
	print "not null"
]
y: as pointer! [byte!] 0
if as-logic y [
	print "not null"
]
}
		--assert empty? qt/output

	--test-- "#173"
		--compile-and-run-this {
Red/System []
x: as struct! [x [integer!]] 1
if as-logic x [
	print "not null "
]
y: as pointer! [byte!] 1
if as-logic y [
	print "not null"
]
}
		--assert equal? "not null not null" qt/output

	--test-- "#175"
		--compile-and-run-this {
Red/System []
s!: alias struct! [x [integer!]]
p: declare s!
unless as-logic p [
	print "true = as-logic not non-null"
]
}
		--assert empty? qt/output

	--test-- "#198"
		--compile-and-run-this {
Red/System []
print ["started"]

f: func [
	i               [integer!]
	s               [c-string!]
	return:         [integer!]
	/local
	divisor         [integer!]
] [
	divisor: 0

	switch i [
		0 [
			return 0
		]
		-2147483648 [
			return 0
		]
		default [
			until [
				divisor = 0
			]
		]
	]
	0
]
s: " "
f 1 s
print [s]
print ["finished"]
}
		--assert compiled?
		--assert equal? "started finished" qt/output

	--test-- "#205"
		--compile-and-run-this {
Red/System []
f1: function [
    return: [float!]
][
    1.0
]
f2: function [
    return: [float!]
][
    2.0
]

print [
    1.0 / 2.0 " "
    f1 / f2
]
}
		--assert equal? "0.5 0.5" qt/output

	--test-- "#207"
		--compile-this {
Red/System []
#define x 0
comment [
	#define x 0
]
}
		--assert compiled?

	--test-- "#208"
		--compile-and-run-this {
Red/System []
test: function [
	a	[float!]
	b	[float!]
][
	print-wide [a b " "]
	print-wide [as-float32 a as-float32 b]
]
print-wide [as-float32 0.0 as-float32 1.0 " "]
test 0.0 1.0
}
		--assert equal? "0.0 1.0  0.0 1.0  0.0 1.0" qt/output

	--test-- "#209"
		--compile-and-run-this {
Red/System []
print [as-float32 0.0  lf]
}
		--assert not crashed?

	--test-- "#210"
		--compile-and-run-this {
Red/System []
print [as-float32 0.0  lf]
print-wide [as-float32 0.0  as-float32 1.0  lf]

test: function [
	a	[float!]
	b	[float!]
][
	print-wide [a b lf]
	print-wide [as-float32 a  as-float32 b  lf]
]
print-wide [as-float32 0.0  as-float32 1.0  lf]
test 0.0 1.0
}
		--assert not crashed?

	--test-- "#216"
		--compile-and-run-this {
Red/System []
i: 2.0
print i / (i - 1.0) 
}
		--assert equal? "2.0" qt/output		

	--test-- "#217"
		--compile-and-run-this {
Red/System []
i: 1
f: 0.0
arr: as pointer! [float!] allocate 10 * size? float!

while [i <= 10] [
	arr/i: f
	f: f + 0.1
	i: i + 1
]
}
		--assert not crashed?

	--test-- "#220"
		--compile-and-run-this {
Red/System []
i: 1
f: 0.0
arr: as pointer! [float!] allocate 10 * size? float!

while [i <= 10] [
	arr/i: f
	f: f + 0.1
	print [i ":" as-float32 arr/i lf]
	i: i + 1
]
}
		--assert not crashed?

	--test-- "#221"
		--compile-and-run-this {
Red/System []
x: -1.0
y: either x < 0.0 [0.0 - x][x]
print [y lf]
}
		--assert not crashed?
		--compile-and-run-this {
Red/System []
_fabs: func [x [float!] return: [float!] ][
	either x < 0.0 [0.0 - x][x]
]
print [_fabs -3.14 lf]
}
		--assert not crashed?		

	--test-- "#222"
		--compile-and-run-this {
Red/System []
s: declare struct! [value [float!]]
s/value: 1.0
a: as pointer! [float!] allocate 100 * size? float!
a/1: s/value
a/1: s/value
1 + 1
}
		--assert not crashed?
		--compile-and-run-this {
Red/System []
s: declare struct! [value [float!]]
s/value: 1.0
a: as pointer! [float!] allocate 100 * size? float!
a/1: s/value
a/1: s/value
if true [a/1: s/value]
}
		--assert not crashed?

	--test-- "#223"
		--compile-and-run-this {
Red/System []
i: 1
while [i <= 10][
	0.0
	i: i + 1
]
}
		--assert not crashed?
		--compile-and-run-this {
Red/System []
a: as pointer! [float!] allocate 10 * size? float!
i: 1
f: 1.0
while [i <= 7][
	f: f * 0.8
	print [f lf]
	a/i: f 
	i: i + 1
]
}
		--assert not crashed?
		--compile-and-run-this {
Red/System []
a: as pointer! [float!] allocate 10 * size? float!
i: 1
f: 1.0
while [i <= 10][
	f: f * 0.8
	print [f lf]
	a/i: f 
	i: i + 1
]
}
		--assert not crashed?

	--test-- "#224"
		--compile-this {
Red/System []
n: 1
n: not n
}
		--assert compiled?

	--test-- "#225"
		--compile-and-run-this {
Red/System []
i: 1.0
f: 1.0
data: declare pointer! [float!]
data: :f
while [i < 10.0][
	data/value: i
	i
	i: i + 1.0
]
}
		--assert not crashed?

	--test-- "#226"
		--compile-and-run-this {
Red/System []
number: 10
array: declare pointer! [byte!]
array: as byte-ptr! :number
value: as integer! array/value
print [10 * as integer! array/value lf]
}
		--assert not crashed?

	--test-- "#227"	
		--compile-and-run-this {
Red/System []
t: 2.2
s: declare struct! [v [float!]]
s/v: 2.0
print [t - s/v]
}
		--assert equal? "0.2" copy/part qt/output 3 ; prevent rounding errors
	
	--test-- "#229"
		--compile-this {
Red/System []
not as byte! 0
}
		--assert compiled?

	--test-- "#231"
		--compile-this {
Red/System []
f: func [
	[typed]
	count	[integer!]
	list	[typed-value!]
][
	pi: declare pointer! [integer!]
	pi: as pointer! [integer!] list/value
]

f [:i]
}
		--assert not compiler-error?

	--test-- "#233"
		--compile-this {
Red/System []
#enum type! [
	x
]

f: function [
	a [type!]
][
]

g: function [
	a [type!]
][
	f a
]
}
		--assert compiled?

	--test-- "#235"
		--compile-this {
Red/System []
a!: alias struct! [a [byte!]]
system/alias/a!
}
		--assert compiled?

	--test-- "#238"
		--compile-this {
Red/System []

c: context [
	s!: alias struct! [dummy [integer!]]
]

with c [
	f: function [
		p [s!]
	][
	]
]
}
		--assert compiled?

	--test-- "#241"
		--compile-this {
Red/System []
c: context [
    #enum e! [i]
]

with c [
	f: function [
		return: [e!]
	][
		i
	]
]
}
		--assert compiled?

	--test-- "#243"
		--compile-this {
Red/System []
c: context [
	#enum e! [x]
]

with c [
	f: function [
		p [float!]
	][
	]

	x: 0.0
	f x
]
}
		--assert compilation-error?

	--test-- "#244"
		--compile-this {
Red/System []
a: "REBOL []"
b: {REBOL []}
c: {
	REBOL
}
d: {
	REBOL []
}
}
		--assert compiled?

	--test-- "#245"
		--compile-this {
Red/System []
a: declare struct! [
	b [integer!]
	b [byte!]
]

a/b: 123
print a/b
}
		--assert compilation-error?

	--test-- "#253"
		--compile-this {
Red/System []
context []
}
		--assert true? find qt/comp-output "*** Compilation Error: context's name setting is missing"

	--test-- "#254" 
		--compile-this {
Red/System []
c: context [
	#enum e! [
		x
	]

	f: function [
		a [e!]
	][
	]
]
}
		--assert compiled?
	
	--test-- "#257"
		--compile-this {
Red/System []
s!: alias struct! [a [integer!]]
c: context [
	a: declare s!
]
}
		--assert compiled?

	--test-- "#261"
		--compile-this {
Red/System []
prin "123"
}
		--assert compiled?

	--test-- "#263"
		--compile-this {
Red/System []
p1: as byte-ptr! "test"
a: (as-integer p1/value) << 8
print a
}
		--assert compiled?

	--test-- "#272"
		--compile-and-run-this {
Red/System []
foo: func [return: [logic!]][
	either true [
		1 = 3
	][
		false
	]
]
print foo
}
		--assert equal? "false" qt/output

;;-- removed due to // and % operators made obsolete
; 	--test-- "#273"
; 		--compile-this {
; Red/System []
; 4.0 // 2.0
; }
; 		--assert compiled?

;;-- removed due to // and % operators made obsolete
; 	--test-- "#275"
; 		--compile-and-run-this {
; Red/System []
; a: 600851475143.0 ;prime number
; i: 2.0
; while [i * i <= a] [
; 	if a // i = 0.0 [
; 		a: a / i
; 	]
; 	i: i + 1.0
; ]
; print a
; }
; 		--assert not crashed?

	--test-- "#281"
		--compile-this {
Red/System []
if false [c: context [d: 1]]
}
		--assert found? find
			qt/comp-output
			"*** Compilation Error: context has to be declared at root level"

	--test-- "#282"
		--compile-this {
Red/System []
c: "HELLO"
c: context [b: 2]
b: 1
print c/b
}
		--assert found? find
			qt/comp-output
			"*** Compilation Error: context name is already taken"

	--test-- "#284"
		--compile-this {
Red/System []
c: context [
	f: func [[infix] a [integer!] b[integer!] return: [integer!]][a + b]
]
print 1 c/f 2
}
		--assert found? find
			qt/comp-output
			"*** Compilation Error: infix functions cannot be called using a path"

	--test-- "#285"
		--compile-this {
Red/System []
c: context [
	f: func [[infix] a [integer!] b [integer!] return: [integer!]][a + b]
	print 1 f 2
]
}
		--assert compiled?

	--test-- "#288"
		--compile-this {
Red/System []
#define a(b not) [b + not] print a(1 2)
}
		--assert loading-error "keywords cannot be used as macro parameters"
		--compile-this {
Red/System []
#define a(b 5) [b + 5] print a(1 2)
}
		--assert loading-error "only words can be used as macro parameters"
		--compile-this {
Red/System []
#define a(b "c") [b + "c"] print a(1 2)
}
		--assert loading-error "only words can be used as macro parameters"

	--test-- "#289"
		--compile-this {
Red/System []
print 1 + "c"
		}
		--assert compilation-error "a literal string cannot be used with a math operator"

	--test-- "#290"
		--compile-this {
Red/System []
#enum color! [a b c]
print #"^^(0A)"
}
		--assert compiled?

	--test-- "#291"
		--compile-this {
Red/System []
f: func[a [integer!]][a: context [b: 1]]
}
		--assert compilation-error "context name is already taken"

	--test-- "#293"
		--compile-this {
Red/System []
c: context [
	#enum e! [x]
	f: function [
		a		[e!]
		return: [logic!]
	][
		zero? a
	]
]
}
		--assert compiled?

	--test-- "#298"
		--compile-this {
Red/System []
#enum color! [a b c] print size? color!
}
		--assert compiled?

	--test-- "#300"
		--compile-this {
Red/System []
v: declare pointer![float64!] d: 1.0 v: :d
}
		--assert compiled?

	--test-- "#317"
		--compile-and-run-this {
Red/System []
a: as-byte 1
b: as-byte 2
c: as-byte 3
d: as-byte 4
a: as-byte 0
print-wide [as-integer a as-integer b as-integer c as-integer d]
}
		--assert equal? "0 2 3 4" qt/output

	--test-- "#334"
		--compile-this {
Red/System []

#define def (a) [
	v: a
]
b: true
def ((not b))
}
		--assert compiled?

	--test-- "#338"
		--compile-this {
Red/System []
a: as pointer! [integer!] allocate 10 * size? integer!
c: context [
	i: 1
	a/i: i
]
}
		--assert compiled?

	--test-- "#344"
		--compile-and-run-this {
Red/System []
b: as-byte 0
print as-integer not as-logic b
b: as-byte 1
print as-integer not as-logic b
b: as-byte 2
print as-integer not as-logic b
}
		--assert equal? "100" qt/output

	--test-- "#346"
		--compile-this {
Red/System []
#import [LIBC-file cdecl [
    to-float: "atof" ["Parse string to floating point."
        string      [c-string!]
        return:     [float!]
    ]
]]
print (to-float "1")
}
		--assert compiled?

	--test-- "#348"
		--compile-this {
Red/System []
c1: context [
	c2: context [
		x: 0
	]
	with c2 [
		x: 1
	]
]
}
		--assert compiled?

	--test-- "#379"
		--compile-this {
Red/System []
c: context [
	#import [LIBC-file cdecl [
		print-error: "perror" [  ; Print error to stderr.
			string	[c-string!]
		]
	]]
]
c/print-error "."
with c [
    print-error "!"
]
}
		--assert compiled?

	--test-- "#393"
		--compile-this {
Red/System []

d: does [
]
x: either yes [:d] [:d]
print-line :x
}
		--assert compiled?

	--test-- "#417"
		--compile-this {
Red/System []
{
	REBOL []
}
}
		--assert compiled?

	--test-- "#419"
		--compile-and-run-this {
Red/System []

str: "123"
p: as byte-ptr! str
print-line as-integer p/1
either (as integer! str) = (as integer! p) [print ["ok" lf]] [print ["ko" lf]]

s: as struct! [a [integer!]] str
print-line s/a
either (as integer! str) = (as integer! s) [print ["ok" lf]] [print ["ko" lf]]
}
		--assert not found? find qt/output "ko"

;	--test-- "#473"
;		TODO: causes compiler problems, see #2240

	--test-- "#474"
		--compile-this {
Red/System []
c: context [
	s!: alias struct! [
		f [function! []]
	]

	r: declare struct! [s [s!]]
]
with c [
    r/s/f
]
}
		--assert compiled?

	--test-- "#475"
		--compile-this {
Red/System []
s: declare struct! [
	f [
		function! [
			""
	    	i       [integer!]
	    	return: [integer!]
		]
	]
]
print [s/f]
}
		--assert compilation-error "s/f is missing an argument"

	--test-- "#481"
		--compile-this {
Red/System []
c1: context [
	x: 1
	f: does []
]
with c1 [
	c2: context [
		x: 2
		f: does []
	]
]
with c2 [
	c2/f
	print-line c2/x
	print-line x
	f
]
}
		--assert compiled?

	--test-- "#483"
		--compile-this {
Red/System []
#define LTM-MP-zero-set(digit size) [
	LTM-MP-digit-counter: size
	until [
		digit/value: null-byte
		digit: digit + 1
		LTM-MP-digit-counter: LTM-MP-digit-counter - 1
		LTM-MP-digit-counter = 0
	]
]
LTM-mp-int!: alias struct! [
	used		[integer!]
	alloc		[integer!]
	sign		[integer!]
	mp-digit	[byte-ptr!]
]
mp-int: declare LTM-mp-int!
mp-int/used: 0
mp-int/alloc: 32
mp-int/sign: 0
mp-int/mp-digit: allocate 32
LTM-MP-zero-set(mp-int/mp-digit 32)
}
		--assert compiled?

	--test-- "#526"
		--compile-and-run-this {
Red/System []
print-wide [
	"A" newline
	"B"
]
}
		--assert equal? "A ^/B" qt/output

	--test-- "#528"
		--compile-and-run-this {
Red/System []
s: system/args-list + either yes [0] [1]
print-wide [system/args-list s]
}
		--assert equal? 
			copy/part qt/output 8 
			copy/part tail qt/output -8

	--test-- "#533"
		--compile-this {
Red/System []
f: function [
	/local x
][
	print :x
]
}
		--assert compilation-error "local variable x used before being initialized"

	--test-- "#535"
		--compile-this {
Red/System []
c: context [
	x: 0
	print :x
]
}
		--assert compiled?

	--test-- "#552"
		--compile-and-run-this {
Red/System []
pos: as byte-ptr! "test"
cp: 0
print pos/value
pos/value: pos/value + as-byte 1 << (cp and 7)
print pos/value
}
		--assert equal? "tu" qt/output

	--test-- "#554"
		--compile-and-run-this {
Red/System []
a: yes
b: yes
probe a xor b
}
		--assert not crashed?

	--test-- "#555"
		--compile-and-run-this {
Red/System []
true and true
}
		--assert not crashed?

	--test-- "#751"
		; FIXME: regressed, see the issue
; 		--compile-this {
; Red/System []
; foo: 458724589764398757698437598437598347 
; print [foo lf]
; }
; 		--assert syntax-error "Invalid integer! value"

	--test-- "#810"
		; FIXME: not fixed, see the issue
; 		--compile-and-run-this {
; Red/System []
; res: case [
; 	true [1 = 0]
; ]
; print res
; }
; 		--assert equal? "false" qt/output

	--test-- "#858"
		--compile-and-run-this {
Red/System []
k: as pointer! [integer!] 1
print ["k: " as integer! k " "]
i: 1
m: as pointer! [integer!] i
print ["m: " as integer! m " "]
k: as pointer! [integer!] 10
print ["k: " as integer! k " "] 
k: as pointer! [integer!] -10
print ["k: " as integer! k " "]
k: as pointer! [integer!] 0
print ["k: " as integer! k]
}
		--assert equal? "k: 1 m: 1 k: 10 k: -10 k: 0" qt/output

	--test-- "#861"
		--compile-and-run-this {
Red/System []
int64!: alias struct! [int1 [integer!] int2 [integer!]]
print-float-hex: func [
	number  [float!]
	tmp     [integer!]
	/local
		f   [int64!]
][
	f: as int64! :number
	print [as byte-ptr! f/int2 as byte-ptr! f/int1]
]
foo-test: func [
	/local
		f   [float!]
		p   [pointer! [float!]]
		a   [int64!]
		tmp [integer!]
][
	f: 0.0
	a: as int64! :f
	p: as pointer! [float!] a
	tmp: 20
	print [as byte-ptr! a/int2 as byte-ptr! a/int1]
	print-float-hex p/value tmp 
	print [as byte-ptr! a/int2 as byte-ptr! a/int1]
]
foo-test
}
		--assert 1 = length? unique qt/output

	--test-- "#880"
		--compile-and-run-this {
Red/System []
print switch 1 [
	0 ["a"]
	1 ["b"]
	2 ["c"]
	3 ["d"]
]
}
		--assert not crashed?

	--test-- "#884"
		--compile-this {
red/system []
print "1"
}
		--assert not compiled?

		--compile-this {
Red/system []
print "1"
}
		--assert not compiled?

===end-group===



===start-group=== "Red/System regressions #1001+"

	--test-- "#1322"
		--compile-and-run-this {
Red/System []
bad: context [
	pen: 123
	system-func: func [pen [int-ptr!]][
		pen/value: 33
	]
	change-pen: func [
		/local
			pen [integer!]
	][
		pen: 0
		system-func :pen
	]
	print pen
	change-pen
	print pen
]
}
		--assert equal? "123123" qt/output

	--test-- "#1324"
		--compile-this {
Red/System []
#import [
	LIBC-file cdecl [
		lol: "funny" [
			return [whoops!]
		]
	]
]
}
		--assert compilation-error "Cannot use `return` as argument name"

; 	TODO: how to check for infinite loop?
	--test-- "#1397"
		--compile-and-run-this {
Red/System []			
loop 0 [print 123]
}
	;-- no assertion here, if it didn't hang, it's good


	--test-- "#1545"
		--compile-and-run-this {
Red/System []
print [1 lf]
}
		--assert not crashed?

	--test-- "#1710"
		--compile-this {
Red/System []
bad-error-msg: func [/local a [logic!]][
	if a: true [0]
]
bad-error-msg
}
		--assert compilation-error "assignment not supported in conditional expression"

	--test-- "#2019"
		--compile-and-run-this {
Red/System []
s: declare struct! [time [float!]]
s/time: 3E9
print s/time / 1E6
}
		--assert equal? "3000.0" qt/output

	--test-- "#2135"
		--compile-and-run-this {
Red/System []
probe 1.836E13
}
		--assert not found? find qt/output "13.0"

	--test-- "#3662"
		--compile-this {Red/System [] 1h}				;@@ allow it?
		--assert loading-error "invalid hex literal"
		
		--compile-this {Red/System [] 100000000h}
		--assert loading-error "invalid hex literal"
		
		--compile-and-run-this {
			Red/System []
			probe 10h
			probe 100h
			probe 1000h
			probe 10000h
			probe 100000h
			probe 1000000h
			probe 10000000h
		}
		--assert equal?
			load qt/output
			[16 256 4096 65536 1048576 16777216 268435456]

	--test-- "#2671"
		--compile-and-run-this {
Red/System []

string: "^^(0)^^(1)^^(2)^^(3)^^(4)^^(5)^^(6)^^(7)^^(8)^^(9)^^(A)^^(B)^^(C)^^(D)^^(E)^^(F)"
binary: #{000102030405060708090A0B0C0D0E0F}
array:  [
	#"^^(0)" #"^^(1)" #"^^(2)" #"^^(3)"
	#"^^(4)" #"^^(5)" #"^^(6)" #"^^(7)"
	#"^^(8)" #"^^(9)" #"^^(A)" #"^^(B)"
	#"^^(C)" #"^^(D)" #"^^(E)" #"^^(F)"
]

this: compare-memory
	as byte-ptr! string
	binary
	length? string

that: compare-memory
	array
	binary
	length? string

probe [this that]
}
		
		--assert 0 = load qt/output
		
		--compile-this {Red/System [] #"^^(0000001)"}
		--assert syntax-error "Invalid char! value"

		--compile-this {Red/System [] "^^(0000001)"}
		--assert syntax-error "Invalid string! value"
		
		--compile-this {Red/System [] #"^^(skibadee-skibadanger)"}
		--assert syntax-error "Invalid char! value"
		
		--compile-this {Red/System [] "^^(skibadee-skibadanger)"}
		--assert syntax-error "Invalid string! value"
		
===end-group===



~~~end-file~~~ 
