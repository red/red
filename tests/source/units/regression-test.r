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
compiler-error?: does [true? find qt/comp-output "*** Compiler Internal Error"]
compilation-error?: does [true? find qt/comp-output "*** Compilation Error"]
loading-error: func [value] [found? find qt/comp-output join "*** Loading Error: " value]
compilation-error: func [value] [found? find qt/comp-output join "*** Compilation Error: " value]
-test-: :--test--
--test--: func [value] [probe value -test- value]

;--separate-log-file

~~~start-file~~~ "Regression tests"

===start-group=== "Red/System regressions"

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

;	FIXME: output from separately compiled test is "513"
;			output here is "1" - looks like Quick Test problem			
; 	--test-- "#149"
; 		--compile-this {
; Red/System []
; a: declare struct! [value [integer!]]
; a/value: 0
; p: as pointer! [byte!] a
; p/1: as-byte 1
; p/2: as-byte 2
; print a/value
; }
; 		--assert equal? "513" qt/output

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
fabs: func [x [float!] return: [float!] ][
	either x < 0.0 [0.0 - x][x]
]
print [fabs -3.14 lf]
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

	--test-- "#273"
		--compile-this {
Red/System []
4.0 // 2.0
}
		--assert compiled?

	--test-- "#275"
		--compile-and-run-this {
Red/System []
a: 600851475143.0 ;prime number
i: 2.0
while [i * i <= a] [
	if a // i = 0.0 [
		a: a / i
	]
	i: i + 1.0
]
print a
}
		--assert not crashed?

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
		--assert compilation-error "missing argument"

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

===end-group===

;-----------------------------------------------------------------------------
;
;   *****   ****** *****
;   * **    ****   *   **
;   *   **  ****** *****
;
;-----------------------------------------------------------------------------

===start-group=== "Red regressions"

; FIXME: There is some strange problem with Quick Test. print integer! from R/S
;		returns some strange values, but when printed to console, it’s fine.
; 	--test-- "#274"
; 		--compile-and-run-this {
; #system-global [
; 	print ["Symptom of the universe: " 42]
; ]
; }
; 		print mold qt/output

	--test-- "#276"
		--compile-this {
#system-global [
	c: #" "
]
}
		--assert compiled?

	--test-- "#304"
		--compile-this {c: #"^^(0A)"} ; double ^^ to prevent escape mangling when moving code from Rebol to Red
		--assert compiled?

	--test-- "#312"
		--compile-this {f: func[/local f][]}
		--assert compiled?

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

	--test-- "#468"
		--compile-this {
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
		--compile-and-run-this {
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
		print mold qt/output

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

	--test-- "#523"
		--compile-this {unset? :x}
		--assert compilation-error "undefined word"
		--compile-this {unset? get/any 'x}
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

===end-group===

~~~end-file~~~ 