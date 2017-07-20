Red [
	Title:	"Red Float! datatype tests"
	Author:	"Peter W A Wood, Nenad Rakocevic, Xie Qing Tian"
	File:	%float-test.red
	Version: 0.2.0
	Rights:	"Copyright (C) 2012-2015 Peter W A Wood, Nenad Rakocevic, Xie Qing Tian. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../quick-test/quick-test.red

~~~start-file~~~ "float"

===start-group=== "float assignment"
	--test-- "float-1"
		ff: 100.0
		--assert ff = 100.0
	--test-- "float-2"
		ff: 1.222090944E+33
		--assert ff = 1.222090944E+33
	--test-- "float-3"
		ff: 9.99999E-45
		--assert ff = 9.99999E-45
	--test-- "float-4"
		ff: 1.0
		f1: ff
		--assert f1 = 1.0
===end-group===

===start-group=== "trigonometric function"

	--test-- "float-cosine-1"
		--assert -1.0 = cosine/radians pi

	--test-- "float-cosine-2"
		--assert 0.0 = cosine 90

	--test-- "float-cosine-3"
		--assert 0.0 = cosine/radians pi / 2

	--test-- "float-sine-1"
		--assertf~= 0.0 sine/radians pi 1E-13

	--test-- "float-sine-2"
		--assert 1 = sine 90

	--test-- "float-tangent-1"
		--assert 0.0 = tangent/radians 0

	--test-- "float-tangent-2"
		--assert -1 = tangent 135

	--test-- "float-arcsine-1"
		--assertf~= -1.5707963267949 arcsine/radians -1 1E-13

	--test-- "float-arcsine-2"
		--assert 90 = arcsine 1

	--test-- "float-arccosine-1"
		--assertf~= 1.5707963267949 arccosine/radians 0 1E-13

	--test-- "float-arccosine-2"
		--assert 90 = arccosine 0

	--test-- "float-arctangent-1"
		--assertf~= -0.785398163397448 arctangent/radians -1 1E-13

	--test-- "float-arctangent-2"
		--assert 45 = arctangent 1

	--test-- "float-arctangent2"
		--assertf~=  3.1415926535898  arctangent2 0 -1 1E-13
		--assertf~=  3.1415926535898  arctangent2 0.0 -1.0 1E-13
		--assertf~= -1.5707963267949  arctangent2 -1 0 1E-13
		--assertf~= -0.78539816339745 arctangent2 -1 1 1E-13
		--assertf~= -0.78539816339745 arctangent2 -1.5 1.5 1E-13

===end-group===

===start-group=== "float function arguments"
	ff: func [
		fff		[float!]
		ffg		[float!]
		return: [integer!]
		/local
			ffl [float!]
	][
		ffl: fff
		if ffl <> fff [return 1]
		ffl: ffg
		if ffl <> ffg [return 2]
		1
	]

	--test-- "float-func-args-1"
		--assert 1 = ff 1.0 2.0

	--test-- "float-func-args-2"
		--assert 1 = ff 1.222090944E+33 9.99999E-45

===end-group===

===start-group=== "float locals"

	local-float: func [n [float!] return: [float!] /local p][p: n p]

	--test-- "float-loc-1"
		pi: local-float 3.14159265358979
		--assert pi = 3.14159265358979
		--assert -1.0 = cos pi
		--assert -1.0 = local-float cos pi

	--test-- "float-loc-2"
		ff: local-float pi
		--assert pi = local-float ff

	--test-- "float-loc-3"
		local-float2: func [n [float!] return: [float!] /local p][p: n local-float p]

		pi: local-float2 3.14159265358979
		--assert -1.0 = local-float2 cos pi
		ff: local-float2 pi
		--assert pi = local-float2 ff

	--test-- "float-loc-4"
		local-float3: func [n [float!] return: [float!] /local p [float!]][p: n local-float p]

		pi: local-float3 3.14159265358979
		--assert -1.0 = local-float3 cos pi
		ff: local-float3 pi
		--assert pi = local-float3 ff

	--test-- "float-loc-5"
		local-float4: func [n [float!] return: [float!] /local r p][p: n p]
		--assert -1.0 = local-float4 cos pi
		ff: local-float4 pi
		--assert pi = local-float4 ff

	--test-- "float-loc-6"
		local-float5: func [n [float!] return: [float!] /local r p][p: n local-float p]
		--assert -1.0 = local-float5 cos pi
		ff: local-float5 pi
		--assert pi = local-float5 ff

===end-group===

===start-group=== "float function return"

	ff1: func [
		ff1i	[integer!]
		return: [float!]
	][
		switch ff1i [
			1 [1.0]
			2 [1.222090944E+33]
			3 [9.99999E-45]
		]
	]
	--test-- "float return 1"
		--assert 1.0 = ff1 1
	--test-- "float return 2"
		--assert 1.222090944E+33 = ff1 2
	--test-- "float return 3"
		--assert 9.99999E-45 = ff1 3

===end-group===

===start-group=== "float members in object!"

	--test-- "float-object-1"
		sf1: make object! [
			a: 0.0
		]
		--assert 0.0 = sf1/a

	--test-- "float-object-2"
		sf2: make object! [
			a: 0.0
		]
		sf1/a: 1.222090944E+33
		--assert 1.222090944E+33 = sf1/a

	--test-- "float-object-3"
		sf3: make object! [
			a: 0.0
			b: 0.0
		]
		sf3/a: 1.222090944E+33
		sf3/b: 9.99999E-45

		--assert 1.222090944E+33 = sf3/a
		--assert 9.99999E-45 = sf3/b

	--test-- "float-object-4"
		sf4: make object! [
			c: none
			a: 0.0
			l: false
			b: 0.0
		]
		sf4/a: 1.222090944E+33
		sf4/b: 9.99999E-45
		--assert 1.222090944E+33 = sf4/a
		--assert 9.99999E-45 = sf4/b

	--test-- "float-object-5"
		sf5: make object! [f: 0.0 i: 0]

		sf5/i: 1234567890
		sf5/f: 3.14159265358979
		--assert sf5/i = 1234567890
		--assert sf5/f = pi

	--test-- "float-object-6"
		sf6: make object! [i: 0 f: 0.0]

		sf6/i: 1234567890
		sf6/f: 3.14159265358979
		--assert sf6/i = 1234567890
		--assert sf6/f = pi

===end-group===

===start-group=== "expressions with returned float values"

	fe1: function [
		return: [float!]
	][
		1.0
	]
	fe2: function [
		return: [float!]
	][
		2.0
	]

	--test-- "ewrfv0"
		--assert 1.0 = (fe1 * 1.0)

	--test-- "ewrfv1"
		--assert 1.0 = (1.0 * fe1)

	--test-- "ewrfv2"
		--assert 0.5 = (fe1 / fe2)

===end-group===

===start-group=== "calculations"

	fcfoo: func [a [float!] return: [float!]][a]

	fcobj: make object! [a: 3.0]

	fc2: 3.0

	--test-- "fc-1"
		fc1: 2.0
		fc1: fc1 / (fc1 - 1.0)
		--assert 2.0 = fc1

	--test-- "fc-2"
		--assert 5.0 - 3.0 = 2.0

	--test-- "fc-3"
		--assert 5.0 - fc2 = 2.0

	--test-- "fc-4"
		--assert 5.0 - (fcfoo 3.0) = 2.0

	--test-- "fc-5"
		--assertf~= 5.0 - fcobj/a 2.0 1E-10

	--test-- "fc-6"
		--assert fc2 - 5.0 = -2.0

	--test-- "fc-7"
		--assert fc2 - (fcfoo 5.0) = -2.0

	--test-- "fc-8"
		--assert fc2 - fcobj/a = 0.0						

	--test-- "fc-9"
		--assert (fcfoo 5.0) - 3.0 = 2.0

	--test-- "fc-10"
		--assert (fcfoo 5.0) - (fcfoo 3.0) = 2.0

	--test-- "fc-11"
		--assert (fcfoo 5.0) - fcobj/a = 2.0

	--test-- "fc-12"
		--assert fcobj/a - (fcfoo 5.0) = -2.0

===end-group===

===start-group=== "absolute"
	--test-- "abs1" --assert 0.0 = absolute -0.0
	--test-- "abs2" --assert 1.2 = absolute 1.2
	--test-- "abs3" --assert 1.2 = absolute -1.2
	--test-- "abs4" --assert 2.2E-308 = absolute -2.2E-308
	--test-- "abs5" --assert 2147483647 = absolute 2147483647.0
===end-group===

===start-group=== "power"
	--test-- "pow1" --assert 2.25 = power 1.5 2
	--test-- "pow2" --assert 9 	 = power -3.0 2.0
	--test-- "pow3" --assertf~= -0.3333333333333333 (power -3.0 -1) 1E-13
	--test-- "pow4" --assertf~= 11.211578456539659 (power 3 2.2) 1E-13
	;--test-- "pow5" --assert 0.0 = power 0.0 -1		;@@ return INF or 0.0 ?
	;--test-- "pow6" --assert 0.0 = power -0.0 -1		;@@ return -INF or 0.0 ?
===end-group===

===start-group=== "max/min"
	--test-- "max1"
		--assert 3 	 = max  3 1.0
		--assert integer! = type? max 3 1.0
	--test-- "max2"
		--assert 3.0 = max  1.0 3.0
		--assert float! = type? max 1.0 3.0

	--test-- "min1"
		--assert -3  = min -3 2
		--assert integer! = type? min -3 2.0
	--test-- "min2"
		--assert -2.0 = min 3.0 -2.0
		--assert float! = type? min 3.0 -2.0

===end-group===

===start-group=== "negative?/positive?"
	--test-- "neg1" --assert true  = negative? -1.0
	--test-- "neg2" --assert false = negative? 0.0
	--test-- "neg3" --assert false = negative? 1.0
	--test-- "pos1" --assert true  = positive? 1.0
	--test-- "pos2" --assert false = positive? 0.0
	--test-- "pos3" --assert false = positive? -1.0
===end-group===

===start-group=== "round"
	--test-- "round1"  --assert 1.375 = round/to 1.333 .125
	--test-- "round2"  --assert 1.33  = round/to 1.333 .01

	--test-- "round3"  --assert  1 = round/down  1.999
	--test-- "round4"  --assert -1 = round/down -1.999

	--test-- "round5"  --assert  2 = round/even  1.5
	--test-- "round6"  --assert -2 = round/even -1.5

	--test-- "round7"  --assert  1 = round/half-down  1.5
	--test-- "round8"  --assert -1 = round/half-down -1.5

	--test-- "round9"  --assert  1 = round/floor  1.999
	--test-- "round10" --assert -2 = round/floor -1.0000001

	--test-- "round11" --assert  2 = round/ceiling  1.0000001
	--test-- "round12" --assert -1 = round/ceiling -1.999

	--test-- "round13" --assert  2 = round/half-ceiling  1.5
	--test-- "round14" --assert -1 = round/half-ceiling -1.5

	--test-- "round15" --assert  1 = round  1.4999
	--test-- "round16" --assert  2 = round  1.5
	--test-- "round17" --assert -2 = round -1.5
	
	;-- for issue #2593 (ROUND rounds float down if scale is integer)
	--test-- "round18"  --assert 1 = round/to 0.5 1
	--test-- "round19"  --assert 0 = round/to 0.499 1
===end-group===

===start-group=== "various regression tests from bugtracker"

	;--test-- "issue #227 for Red/System"
	;	t: 2.2
	;	ss: make object! [v: [float!]]
	;	ss/v: 2.0
	;	--assertf~= t - ss/v 0.2 1E-10

	--test-- "issue #221"
		x: -1.0
		y: either x < 0.0 [0.0 - x][x]
		--assert y = 1.0

		fabs: func [x [float!] return: [float!] ][
			either x < 0.0 [0.0 - x][x]
		]
		--assert 3.14 = fabs -3.14

===end-group===

===start-group=== "almost equal"
	--test-- "almost-equal1"  --assert 1.000000000000001 = 1.000000000000002
	--test-- "almost-equal2"  --assert not 1.000000000000001 <> 1.000000000000003

	--test-- "almost-equal3"  --assert -1.999999999999999 = -1.999999999999999
	--test-- "almost-equal4"  --assert 1.732050807568876 = 1.732050807568877

	--test-- "almost-equal5"  --assert  0.4E-323 = -0.4E-323
	--test-- "almost-equal6"  --assert 1.7976931348623157e308 = 1.#INF
	--test-- "almost-equal7"  --assert 4.94065645841247E-324 = 0
===end-group===

===start-group=== "special value arithmetic (NaNs and INF)"

	--test-- "special-arithmetic-1"  --assert "0.0"     = to string! 1.0 / 1.#INF
	--test-- "special-arithmetic-5"  --assert "1.#INF"  = to string! 9999999.9 + 1.#INF
	--test-- "special-arithmetic-6"  --assert "-1.#INF" = to string! 9999999.9 - 1.#INF
	--test-- "special-arithmetic-7"  --assert "1.#INF"  = to string! 1.#INF + 1.#INF
	--test-- "special-arithmetic-8"  --assert "1.#INF"  = to string! 1.#INF * 1.#INF
	--test-- "special-arithmetic-2"  --assert "1.#INF"  = to string! 1.0 / 0.0
	--test-- "special-arithmetic-3"  --assert "-1.#INF" = to string! -1.0 / 0.0
	--test-- "special-arithmetic-4"  --assert "1.#INF"  = to string! 0.0 / 0.0
	--test-- "special-arithmetic-9"  --assert "1.#NaN"  = to string! 1.#INF - 1.#INF
	--test-- "special-arithmetic-10" --assert "1.#NaN"  = to string! 1.#INF / 1.#INF
	--test-- "special-arithmetic-11" --assert "1.#NaN"  = to string! 0.0 * 1.#INF
	--test-- "special-arithmetic-12" --assert "1.#INF"  = to string! 1e308 + 1e308
===end-group===

===start-group=== "special value equality (NaNs and INF)"

	--test-- "special-equality-1"  --assert NaN? 1.#NaN
	--test-- "special-equality-2"  --assert not NaN? 1.23
	--test-- "special-equality-3"  --assert 1.#INF = 1.#INF
	--test-- "special-equality-4"  --assert not 1.#INF = 1.23
	--test-- "special-equality-5"  --assert 1.#INF > 1e308
	--test-- "special-equality-6"  --assert -1.#INF < -1e308
	--test-- "special-equality-7"  --assert -1.#INF = -1.#INF
	--test-- "special-equality-8"  --assert -1.#INF < 1.#INF
	--test-- "special-equality-9"  --assert -0.0 = 0.0

	; Issue #2001
	;--test-- "special-equality-10"  --assert 1.#NaN = 1.#NaN			= false
	;--test-- "special-equality-11"  --assert 1.#NaN <> 1.#NaN			= true
	;--test-- "special-equality-12"  --assert [1 1.#NaN] = [1 1.#NaN]	= false
	;--test-- "special-equality-13"  --assert 1.#INF = 1.#NaN			= false
	;--test-- "special-equality-14"  --assert 1.23 = 1.#NaN				= false
===end-group===

===start-group=== "other math functions"

	--test-- "log-2-1"			--assert 5.0 = log-2 32
	--test-- "log-10-1"			--assert 2.0 = log-10 100
	--test-- "log-e-1"			--assert 4.812184355372417 = log-e 123
	--test-- "exp-1"			--assert 2.6195173187490456e53 = exp 123
	--test-- "square-root-1"	--assert 2.0 = square-root 4

===end-group===

===start-group=== "float-add"
	--test-- "float-add 1"
		i: 0.0
		j: 1.0
		--assert strict-equal? 1.0 0.0 + 1.0
		--assert strict-equal? 1.0 add 0.0 1.0
		--assert strict-equal? 1.0 i + j
		--assert strict-equal? 1.0 add i j

	--test-- "float-add 2"
		i: 0.0
		j: -1.0
		--assert strict-equal? -1.0 0.0 + -1.0
		--assert strict-equal? -1.0 add 0.0 -1.0
		--assert strict-equal? -1.0 i + j
		--assert strict-equal? -1.0 add i j

	--test-- "float-add 3"
		i: 0.0
		j: 2.2250738585072014e-308
		--assert strict-equal? 2.2250738585072014e-308 0.0 + 2.2250738585072014e-308
		--assert strict-equal? 2.2250738585072014e-308 add 0.0 2.2250738585072014e-308
		--assert strict-equal? 2.2250738585072014e-308 i + j
		--assert strict-equal? 2.2250738585072014e-308 add i j

	--test-- "float-add 4"
		i: 0.0
		j: -2.2250738585072014e-308
		--assert strict-equal? -2.2250738585072014e-308 0.0 + -2.2250738585072014e-308
		--assert strict-equal? -2.2250738585072014e-308 add 0.0 -2.2250738585072014e-308
		--assert strict-equal? -2.2250738585072014e-308 i + j
		--assert strict-equal? -2.2250738585072014e-308 add i j

	--test-- "float-add 5"
		i: 0.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 0.0 + 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 add 0.0 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 6"
		i: 0.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 0.0 + -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 add 0.0 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 7"
		i: 0.0
		j: 1.1
		--assert strict-equal? 1.1 0.0 + 1.1
		--assert strict-equal? 1.1 add 0.0 1.1
		--assert strict-equal? 1.1 i + j
		--assert strict-equal? 1.1 add i j

	--test-- "float-add 8"
		i: 0.0
		j: -1.1
		--assert strict-equal? -1.1 0.0 + -1.1
		--assert strict-equal? -1.1 add 0.0 -1.1
		--assert strict-equal? -1.1 i + j
		--assert strict-equal? -1.1 add i j

	--test-- "float-add 9"
		i: 0.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 0.0 + 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 add 0.0 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 10"
		i: 0.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 0.0 + -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 add 0.0 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 11"
		i: 1.0
		j: -1.0
		--assert strict-equal? 0.0 1.0 + -1.0
		--assert strict-equal? 0.0 add 1.0 -1.0
		--assert strict-equal? 0.0 i + j
		--assert strict-equal? 0.0 add i j

	--test-- "float-add 12"
		i: 1.0
		j: 2.2250738585072014e-308
		--assert strict-equal? 1.0 1.0 + 2.2250738585072014e-308
		--assert strict-equal? 1.0 add 1.0 2.2250738585072014e-308
		--assert strict-equal? 1.0 i + j
		--assert strict-equal? 1.0 add i j

	--test-- "float-add 13"
		i: 1.0
		j: -2.2250738585072014e-308
		--assert strict-equal? 1.0 1.0 + -2.2250738585072014e-308
		--assert strict-equal? 1.0 add 1.0 -2.2250738585072014e-308
		--assert strict-equal? 1.0 i + j
		--assert strict-equal? 1.0 add i j

	--test-- "float-add 14"
		i: 1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 1.0 + 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 add 1.0 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 15"
		i: 1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 1.0 + -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 add 1.0 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 16"
		i: 1.0
		j: 1.1
		--assert strict-equal? 2.1 1.0 + 1.1
		--assert strict-equal? 2.1 add 1.0 1.1
		--assert strict-equal? 2.1 i + j
		--assert strict-equal? 2.1 add i j

	--test-- "float-add 17"
		i: 1.0
		j: -1.1
		--assert strict-equal? -0.10000000000000009 1.0 + -1.1
		--assert strict-equal? -0.10000000000000009 add 1.0 -1.1
		--assert strict-equal? -0.10000000000000009 i + j
		--assert strict-equal? -0.10000000000000009 add i j

	--test-- "float-add 18"
		i: 1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 1.0 + 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 add 1.0 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 19"
		i: 1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 1.0 + -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 add 1.0 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 20"
		i: -1.0
		j: 2.2250738585072014e-308
		--assert strict-equal? -1.0 -1.0 + 2.2250738585072014e-308
		--assert strict-equal? -1.0 add -1.0 2.2250738585072014e-308
		--assert strict-equal? -1.0 i + j
		--assert strict-equal? -1.0 add i j

	--test-- "float-add 21"
		i: -1.0
		j: -2.2250738585072014e-308
		--assert strict-equal? -1.0 -1.0 + -2.2250738585072014e-308
		--assert strict-equal? -1.0 add -1.0 -2.2250738585072014e-308
		--assert strict-equal? -1.0 i + j
		--assert strict-equal? -1.0 add i j

	--test-- "float-add 22"
		i: -1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -1.0 + 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 add -1.0 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 23"
		i: -1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -1.0 + -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 add -1.0 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 24"
		i: -1.0
		j: 1.1
		--assert strict-equal? 0.10000000000000009 -1.0 + 1.1
		--assert strict-equal? 0.10000000000000009 add -1.0 1.1
		--assert strict-equal? 0.10000000000000009 i + j
		--assert strict-equal? 0.10000000000000009 add i j

	--test-- "float-add 25"
		i: -1.0
		j: -1.1
		--assert strict-equal? -2.1 -1.0 + -1.1
		--assert strict-equal? -2.1 add -1.0 -1.1
		--assert strict-equal? -2.1 i + j
		--assert strict-equal? -2.1 add i j

	--test-- "float-add 26"
		i: -1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -1.0 + 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 add -1.0 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 27"
		i: -1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -1.0 + -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 add -1.0 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 28"
		i: 2.2250738585072014e-308
		j: -2.2250738585072014e-308
		--assert strict-equal? 0.0 2.2250738585072014e-308 + -2.2250738585072014e-308
		--assert strict-equal? 0.0 add 2.2250738585072014e-308 -2.2250738585072014e-308
		--assert strict-equal? 0.0 i + j
		--assert strict-equal? 0.0 add i j

	--test-- "float-add 29"
		i: 2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 2.2250738585072014e-308 + 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 add 2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 30"
		i: 2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 2.2250738585072014e-308 + -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 add 2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 31"
		i: 2.2250738585072014e-308
		j: 1.1
		--assert strict-equal? 1.1 2.2250738585072014e-308 + 1.1
		--assert strict-equal? 1.1 add 2.2250738585072014e-308 1.1
		--assert strict-equal? 1.1 i + j
		--assert strict-equal? 1.1 add i j

	--test-- "float-add 32"
		i: 2.2250738585072014e-308
		j: -1.1
		--assert strict-equal? -1.1 2.2250738585072014e-308 + -1.1
		--assert strict-equal? -1.1 add 2.2250738585072014e-308 -1.1
		--assert strict-equal? -1.1 i + j
		--assert strict-equal? -1.1 add i j

	--test-- "float-add 33"
		i: 2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 2.2250738585072014e-308 + 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 add 2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 34"
		i: 2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 2.2250738585072014e-308 + -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 add 2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 35"
		i: -2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -2.2250738585072014e-308 + 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 add -2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 36"
		i: -2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -2.2250738585072014e-308 + -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 add -2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 37"
		i: -2.2250738585072014e-308
		j: 1.1
		--assert strict-equal? 1.1 -2.2250738585072014e-308 + 1.1
		--assert strict-equal? 1.1 add -2.2250738585072014e-308 1.1
		--assert strict-equal? 1.1 i + j
		--assert strict-equal? 1.1 add i j

	--test-- "float-add 38"
		i: -2.2250738585072014e-308
		j: -1.1
		--assert strict-equal? -1.1 -2.2250738585072014e-308 + -1.1
		--assert strict-equal? -1.1 add -2.2250738585072014e-308 -1.1
		--assert strict-equal? -1.1 i + j
		--assert strict-equal? -1.1 add i j

	--test-- "float-add 39"
		i: -2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -2.2250738585072014e-308 + 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 add -2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 40"
		i: -2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -2.2250738585072014e-308 + -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 add -2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 41"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 0.0 1.7976931348623157e+308 + -1.7976931348623157e+308
		--assert strict-equal? 0.0 add 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 0.0 i + j
		--assert strict-equal? 0.0 add i j

	--test-- "float-add 42"
		i: 1.7976931348623157e+308
		j: 1.1
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 + 1.1
		--assert strict-equal? 1.7976931348623157e+308 add 1.7976931348623157e+308 1.1
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 43"
		i: 1.7976931348623157e+308
		j: -1.1
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 + -1.1
		--assert strict-equal? 1.7976931348623157e+308 add 1.7976931348623157e+308 -1.1
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 44"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 + 1.7976931348623157e+308
		--assert strict-equal? 1.#INF add 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 1.#INF i + j
		--assert strict-equal? 1.#INF add i j

	--test-- "float-add 45"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 0.0 1.7976931348623157e+308 + -1.7976931348623157e+308
		--assert strict-equal? 0.0 add 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 0.0 i + j
		--assert strict-equal? 0.0 add i j

	--test-- "float-add 46"
		i: -1.7976931348623157e+308
		j: 1.1
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 + 1.1
		--assert strict-equal? -1.7976931348623157e+308 add -1.7976931348623157e+308 1.1
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 47"
		i: -1.7976931348623157e+308
		j: -1.1
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 + -1.1
		--assert strict-equal? -1.7976931348623157e+308 add -1.7976931348623157e+308 -1.1
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 48"
		i: -1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 0.0 -1.7976931348623157e+308 + 1.7976931348623157e+308
		--assert strict-equal? 0.0 add -1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 0.0 i + j
		--assert strict-equal? 0.0 add i j

	--test-- "float-add 49"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.#INF -1.7976931348623157e+308 + -1.7976931348623157e+308
		--assert strict-equal? -1.#INF add -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? -1.#INF i + j
		--assert strict-equal? -1.#INF add i j

	--test-- "float-add 50"
		i: 1.1
		j: -1.1
		--assert strict-equal? 0.0 1.1 + -1.1
		--assert strict-equal? 0.0 add 1.1 -1.1
		--assert strict-equal? 0.0 i + j
		--assert strict-equal? 0.0 add i j

	--test-- "float-add 51"
		i: 1.1
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 1.1 + 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 add 1.1 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 52"
		i: 1.1
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 1.1 + -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 add 1.1 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 53"
		i: -1.1
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -1.1 + 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 add -1.1 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i + j
		--assert strict-equal? 1.7976931348623157e+308 add i j

	--test-- "float-add 54"
		i: -1.1
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -1.1 + -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 add -1.1 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i + j
		--assert strict-equal? -1.7976931348623157e+308 add i j

	--test-- "float-add 55"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 0.0 1.7976931348623157e+308 + -1.7976931348623157e+308
		--assert strict-equal? 0.0 add 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 0.0 i + j
		--assert strict-equal? 0.0 add i j

	--test-- "float-add 56"
		i: 0.0
		j: 0.0
		--assert strict-equal? 0.0 0.0 + 0.0
		--assert strict-equal? 0.0 add 0.0 0.0
		--assert strict-equal? 0.0 i + j
		--assert strict-equal? 0.0 add i j

	--test-- "float-add 57"
		i: 1.0
		j: 1.0
		--assert strict-equal? 2.0 1.0 + 1.0
		--assert strict-equal? 2.0 add 1.0 1.0
		--assert strict-equal? 2.0 i + j
		--assert strict-equal? 2.0 add i j

	--test-- "float-add 58"
		i: -1.0
		j: -1.0
		--assert strict-equal? -2.0 -1.0 + -1.0
		--assert strict-equal? -2.0 add -1.0 -1.0
		--assert strict-equal? -2.0 i + j
		--assert strict-equal? -2.0 add i j

	--test-- "float-add 59"
		i: 2.2250738585072014e-308
		j: 2.2250738585072014e-308
		--assert strict-equal? 4.450147717014403e-308 2.2250738585072014e-308 + 2.2250738585072014e-308
		--assert strict-equal? 4.450147717014403e-308 add 2.2250738585072014e-308 2.2250738585072014e-308
		--assert strict-equal? 4.450147717014403e-308 i + j
		--assert strict-equal? 4.450147717014403e-308 add i j

	--test-- "float-add 60"
		i: -2.2250738585072014e-308
		j: -2.2250738585072014e-308
		--assert strict-equal? -4.450147717014403e-308 -2.2250738585072014e-308 + -2.2250738585072014e-308
		--assert strict-equal? -4.450147717014403e-308 add -2.2250738585072014e-308 -2.2250738585072014e-308
		--assert strict-equal? -4.450147717014403e-308 i + j
		--assert strict-equal? -4.450147717014403e-308 add i j

	--test-- "float-add 61"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 + 1.7976931348623157e+308
		--assert strict-equal? 1.#INF add 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 1.#INF i + j
		--assert strict-equal? 1.#INF add i j

	--test-- "float-add 62"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.#INF -1.7976931348623157e+308 + -1.7976931348623157e+308
		--assert strict-equal? -1.#INF add -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? -1.#INF i + j
		--assert strict-equal? -1.#INF add i j

	--test-- "float-add 63"
		i: 1.1
		j: 1.1
		--assert strict-equal? 2.2 1.1 + 1.1
		--assert strict-equal? 2.2 add 1.1 1.1
		--assert strict-equal? 2.2 i + j
		--assert strict-equal? 2.2 add i j

	--test-- "float-add 64"
		i: -1.1
		j: -1.1
		--assert strict-equal? -2.2 -1.1 + -1.1
		--assert strict-equal? -2.2 add -1.1 -1.1
		--assert strict-equal? -2.2 i + j
		--assert strict-equal? -2.2 add i j

	--test-- "float-add 65"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 + 1.7976931348623157e+308
		--assert strict-equal? 1.#INF add 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 1.#INF i + j
		--assert strict-equal? 1.#INF add i j

	--test-- "float-add 66"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.#INF -1.7976931348623157e+308 + -1.7976931348623157e+308
		--assert strict-equal? -1.#INF add -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? -1.#INF i + j
		--assert strict-equal? -1.#INF add i j

===end-group===
===start-group=== "float-subtract"
	--test-- "float-subtract 1"
		i: 0.0
		j: 1.0
		--assert strict-equal? -1.0 0.0 - 1.0
		--assert strict-equal? -1.0 subtract 0.0 1.0
		--assert strict-equal? -1.0 i - j
		--assert strict-equal? -1.0 subtract i j

	--test-- "float-subtract 2"
		i: 0.0
		j: -1.0
		--assert strict-equal? 1.0 0.0 - -1.0
		--assert strict-equal? 1.0 subtract 0.0 -1.0
		--assert strict-equal? 1.0 i - j
		--assert strict-equal? 1.0 subtract i j

	--test-- "float-subtract 3"
		i: 0.0
		j: 2.2250738585072014e-308
		--assert strict-equal? -2.2250738585072014e-308 0.0 - 2.2250738585072014e-308
		--assert strict-equal? -2.2250738585072014e-308 subtract 0.0 2.2250738585072014e-308
		--assert strict-equal? -2.2250738585072014e-308 i - j
		--assert strict-equal? -2.2250738585072014e-308 subtract i j

	--test-- "float-subtract 4"
		i: 0.0
		j: -2.2250738585072014e-308
		--assert strict-equal? 2.2250738585072014e-308 0.0 - -2.2250738585072014e-308
		--assert strict-equal? 2.2250738585072014e-308 subtract 0.0 -2.2250738585072014e-308
		--assert strict-equal? 2.2250738585072014e-308 i - j
		--assert strict-equal? 2.2250738585072014e-308 subtract i j

	--test-- "float-subtract 5"
		i: 0.0
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 0.0 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract 0.0 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 6"
		i: 0.0
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 0.0 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract 0.0 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 7"
		i: 0.0
		j: 1.1
		--assert strict-equal? -1.1 0.0 - 1.1
		--assert strict-equal? -1.1 subtract 0.0 1.1
		--assert strict-equal? -1.1 i - j
		--assert strict-equal? -1.1 subtract i j

	--test-- "float-subtract 8"
		i: 0.0
		j: -1.1
		--assert strict-equal? 1.1 0.0 - -1.1
		--assert strict-equal? 1.1 subtract 0.0 -1.1
		--assert strict-equal? 1.1 i - j
		--assert strict-equal? 1.1 subtract i j

	--test-- "float-subtract 9"
		i: 0.0
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 0.0 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract 0.0 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 10"
		i: 0.0
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 0.0 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract 0.0 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 11"
		i: 1.0
		j: 0.0
		--assert strict-equal? 1.0 1.0 - 0.0
		--assert strict-equal? 1.0 subtract 1.0 0.0
		--assert strict-equal? 1.0 i - j
		--assert strict-equal? 1.0 subtract i j

	--test-- "float-subtract 12"
		i: 1.0
		j: -1.0
		--assert strict-equal? 2.0 1.0 - -1.0
		--assert strict-equal? 2.0 subtract 1.0 -1.0
		--assert strict-equal? 2.0 i - j
		--assert strict-equal? 2.0 subtract i j

	--test-- "float-subtract 13"
		i: 1.0
		j: 2.2250738585072014e-308
		--assert strict-equal? 1.0 1.0 - 2.2250738585072014e-308
		--assert strict-equal? 1.0 subtract 1.0 2.2250738585072014e-308
		--assert strict-equal? 1.0 i - j
		--assert strict-equal? 1.0 subtract i j

	--test-- "float-subtract 14"
		i: 1.0
		j: -2.2250738585072014e-308
		--assert strict-equal? 1.0 1.0 - -2.2250738585072014e-308
		--assert strict-equal? 1.0 subtract 1.0 -2.2250738585072014e-308
		--assert strict-equal? 1.0 i - j
		--assert strict-equal? 1.0 subtract i j

	--test-- "float-subtract 15"
		i: 1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 1.0 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract 1.0 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 16"
		i: 1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 1.0 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.0 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 17"
		i: 1.0
		j: 1.1
		--assert strict-equal? -0.10000000000000009 1.0 - 1.1
		--assert strict-equal? -0.10000000000000009 subtract 1.0 1.1
		--assert strict-equal? -0.10000000000000009 i - j
		--assert strict-equal? -0.10000000000000009 subtract i j

	--test-- "float-subtract 18"
		i: 1.0
		j: -1.1
		--assert strict-equal? 2.1 1.0 - -1.1
		--assert strict-equal? 2.1 subtract 1.0 -1.1
		--assert strict-equal? 2.1 i - j
		--assert strict-equal? 2.1 subtract i j

	--test-- "float-subtract 19"
		i: 1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 1.0 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract 1.0 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 20"
		i: 1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 1.0 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.0 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 21"
		i: -1.0
		j: 0.0
		--assert strict-equal? -1.0 -1.0 - 0.0
		--assert strict-equal? -1.0 subtract -1.0 0.0
		--assert strict-equal? -1.0 i - j
		--assert strict-equal? -1.0 subtract i j

	--test-- "float-subtract 22"
		i: -1.0
		j: 1.0
		--assert strict-equal? -2.0 -1.0 - 1.0
		--assert strict-equal? -2.0 subtract -1.0 1.0
		--assert strict-equal? -2.0 i - j
		--assert strict-equal? -2.0 subtract i j

	--test-- "float-subtract 23"
		i: -1.0
		j: 2.2250738585072014e-308
		--assert strict-equal? -1.0 -1.0 - 2.2250738585072014e-308
		--assert strict-equal? -1.0 subtract -1.0 2.2250738585072014e-308
		--assert strict-equal? -1.0 i - j
		--assert strict-equal? -1.0 subtract i j

	--test-- "float-subtract 24"
		i: -1.0
		j: -2.2250738585072014e-308
		--assert strict-equal? -1.0 -1.0 - -2.2250738585072014e-308
		--assert strict-equal? -1.0 subtract -1.0 -2.2250738585072014e-308
		--assert strict-equal? -1.0 i - j
		--assert strict-equal? -1.0 subtract i j

	--test-- "float-subtract 25"
		i: -1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -1.0 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.0 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 26"
		i: -1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -1.0 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract -1.0 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 27"
		i: -1.0
		j: 1.1
		--assert strict-equal? -2.1 -1.0 - 1.1
		--assert strict-equal? -2.1 subtract -1.0 1.1
		--assert strict-equal? -2.1 i - j
		--assert strict-equal? -2.1 subtract i j

	--test-- "float-subtract 28"
		i: -1.0
		j: -1.1
		--assert strict-equal? 0.10000000000000009 -1.0 - -1.1
		--assert strict-equal? 0.10000000000000009 subtract -1.0 -1.1
		--assert strict-equal? 0.10000000000000009 i - j
		--assert strict-equal? 0.10000000000000009 subtract i j

	--test-- "float-subtract 29"
		i: -1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -1.0 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.0 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 30"
		i: -1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -1.0 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract -1.0 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 31"
		i: 2.2250738585072014e-308
		j: 0.0
		--assert strict-equal? 2.2250738585072014e-308 2.2250738585072014e-308 - 0.0
		--assert strict-equal? 2.2250738585072014e-308 subtract 2.2250738585072014e-308 0.0
		--assert strict-equal? 2.2250738585072014e-308 i - j
		--assert strict-equal? 2.2250738585072014e-308 subtract i j

	--test-- "float-subtract 32"
		i: 2.2250738585072014e-308
		j: 1.0
		--assert strict-equal? -1.0 2.2250738585072014e-308 - 1.0
		--assert strict-equal? -1.0 subtract 2.2250738585072014e-308 1.0
		--assert strict-equal? -1.0 i - j
		--assert strict-equal? -1.0 subtract i j

	--test-- "float-subtract 33"
		i: 2.2250738585072014e-308
		j: -1.0
		--assert strict-equal? 1.0 2.2250738585072014e-308 - -1.0
		--assert strict-equal? 1.0 subtract 2.2250738585072014e-308 -1.0
		--assert strict-equal? 1.0 i - j
		--assert strict-equal? 1.0 subtract i j

	--test-- "float-subtract 34"
		i: 2.2250738585072014e-308
		j: -2.2250738585072014e-308
		--assert strict-equal? 4.450147717014403e-308 2.2250738585072014e-308 - -2.2250738585072014e-308
		--assert strict-equal? 4.450147717014403e-308 subtract 2.2250738585072014e-308 -2.2250738585072014e-308
		--assert strict-equal? 4.450147717014403e-308 i - j
		--assert strict-equal? 4.450147717014403e-308 subtract i j

	--test-- "float-subtract 35"
		i: 2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 2.2250738585072014e-308 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract 2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 36"
		i: 2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 2.2250738585072014e-308 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract 2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 37"
		i: 2.2250738585072014e-308
		j: 1.1
		--assert strict-equal? -1.1 2.2250738585072014e-308 - 1.1
		--assert strict-equal? -1.1 subtract 2.2250738585072014e-308 1.1
		--assert strict-equal? -1.1 i - j
		--assert strict-equal? -1.1 subtract i j

	--test-- "float-subtract 38"
		i: 2.2250738585072014e-308
		j: -1.1
		--assert strict-equal? 1.1 2.2250738585072014e-308 - -1.1
		--assert strict-equal? 1.1 subtract 2.2250738585072014e-308 -1.1
		--assert strict-equal? 1.1 i - j
		--assert strict-equal? 1.1 subtract i j

	--test-- "float-subtract 39"
		i: 2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 2.2250738585072014e-308 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract 2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 40"
		i: 2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 2.2250738585072014e-308 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract 2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 41"
		i: -2.2250738585072014e-308
		j: 0.0
		--assert strict-equal? -2.2250738585072014e-308 -2.2250738585072014e-308 - 0.0
		--assert strict-equal? -2.2250738585072014e-308 subtract -2.2250738585072014e-308 0.0
		--assert strict-equal? -2.2250738585072014e-308 i - j
		--assert strict-equal? -2.2250738585072014e-308 subtract i j

	--test-- "float-subtract 42"
		i: -2.2250738585072014e-308
		j: 1.0
		--assert strict-equal? -1.0 -2.2250738585072014e-308 - 1.0
		--assert strict-equal? -1.0 subtract -2.2250738585072014e-308 1.0
		--assert strict-equal? -1.0 i - j
		--assert strict-equal? -1.0 subtract i j

	--test-- "float-subtract 43"
		i: -2.2250738585072014e-308
		j: -1.0
		--assert strict-equal? 1.0 -2.2250738585072014e-308 - -1.0
		--assert strict-equal? 1.0 subtract -2.2250738585072014e-308 -1.0
		--assert strict-equal? 1.0 i - j
		--assert strict-equal? 1.0 subtract i j

	--test-- "float-subtract 44"
		i: -2.2250738585072014e-308
		j: 2.2250738585072014e-308
		--assert strict-equal? -4.450147717014403e-308 -2.2250738585072014e-308 - 2.2250738585072014e-308
		--assert strict-equal? -4.450147717014403e-308 subtract -2.2250738585072014e-308 2.2250738585072014e-308
		--assert strict-equal? -4.450147717014403e-308 i - j
		--assert strict-equal? -4.450147717014403e-308 subtract i j

	--test-- "float-subtract 45"
		i: -2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -2.2250738585072014e-308 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract -2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 46"
		i: -2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -2.2250738585072014e-308 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract -2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 47"
		i: -2.2250738585072014e-308
		j: 1.1
		--assert strict-equal? -1.1 -2.2250738585072014e-308 - 1.1
		--assert strict-equal? -1.1 subtract -2.2250738585072014e-308 1.1
		--assert strict-equal? -1.1 i - j
		--assert strict-equal? -1.1 subtract i j

	--test-- "float-subtract 48"
		i: -2.2250738585072014e-308
		j: -1.1
		--assert strict-equal? 1.1 -2.2250738585072014e-308 - -1.1
		--assert strict-equal? 1.1 subtract -2.2250738585072014e-308 -1.1
		--assert strict-equal? 1.1 i - j
		--assert strict-equal? 1.1 subtract i j

	--test-- "float-subtract 49"
		i: -2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -2.2250738585072014e-308 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract -2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 50"
		i: -2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -2.2250738585072014e-308 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract -2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 51"
		i: 1.7976931348623157e+308
		j: 0.0
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - 0.0
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 0.0
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 52"
		i: 1.7976931348623157e+308
		j: 1.0
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - 1.0
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 1.0
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 53"
		i: 1.7976931348623157e+308
		j: -1.0
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - -1.0
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 -1.0
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 54"
		i: 1.7976931348623157e+308
		j: 2.2250738585072014e-308
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - 2.2250738585072014e-308
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 2.2250738585072014e-308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 55"
		i: 1.7976931348623157e+308
		j: -2.2250738585072014e-308
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - -2.2250738585072014e-308
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 -2.2250738585072014e-308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 56"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 - -1.7976931348623157e+308
		--assert strict-equal? 1.#INF subtract 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 1.#INF i - j
		--assert strict-equal? 1.#INF subtract i j

	--test-- "float-subtract 57"
		i: 1.7976931348623157e+308
		j: 1.1
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - 1.1
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 1.1
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 58"
		i: 1.7976931348623157e+308
		j: -1.1
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - -1.1
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 -1.1
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 59"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 0.0 1.7976931348623157e+308 - 1.7976931348623157e+308
		--assert strict-equal? 0.0 subtract 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 60"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 - -1.7976931348623157e+308
		--assert strict-equal? 1.#INF subtract 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 1.#INF i - j
		--assert strict-equal? 1.#INF subtract i j

	--test-- "float-subtract 61"
		i: -1.7976931348623157e+308
		j: 0.0
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - 0.0
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 0.0
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 62"
		i: -1.7976931348623157e+308
		j: 1.0
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - 1.0
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 1.0
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 63"
		i: -1.7976931348623157e+308
		j: -1.0
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - -1.0
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 -1.0
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 64"
		i: -1.7976931348623157e+308
		j: 2.2250738585072014e-308
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - 2.2250738585072014e-308
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 2.2250738585072014e-308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 65"
		i: -1.7976931348623157e+308
		j: -2.2250738585072014e-308
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - -2.2250738585072014e-308
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 -2.2250738585072014e-308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 66"
		i: -1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.#INF -1.7976931348623157e+308 - 1.7976931348623157e+308
		--assert strict-equal? -1.#INF subtract -1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? -1.#INF i - j
		--assert strict-equal? -1.#INF subtract i j

	--test-- "float-subtract 67"
		i: -1.7976931348623157e+308
		j: 1.1
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - 1.1
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 1.1
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 68"
		i: -1.7976931348623157e+308
		j: -1.1
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - -1.1
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 -1.1
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 69"
		i: -1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.#INF -1.7976931348623157e+308 - 1.7976931348623157e+308
		--assert strict-equal? -1.#INF subtract -1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? -1.#INF i - j
		--assert strict-equal? -1.#INF subtract i j

	--test-- "float-subtract 70"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 0.0 -1.7976931348623157e+308 - -1.7976931348623157e+308
		--assert strict-equal? 0.0 subtract -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 71"
		i: 1.1
		j: 0.0
		--assert strict-equal? 1.1 1.1 - 0.0
		--assert strict-equal? 1.1 subtract 1.1 0.0
		--assert strict-equal? 1.1 i - j
		--assert strict-equal? 1.1 subtract i j

	--test-- "float-subtract 72"
		i: 1.1
		j: 1.0
		--assert strict-equal? 0.10000000000000009 1.1 - 1.0
		--assert strict-equal? 0.10000000000000009 subtract 1.1 1.0
		--assert strict-equal? 0.10000000000000009 i - j
		--assert strict-equal? 0.10000000000000009 subtract i j

	--test-- "float-subtract 73"
		i: 1.1
		j: -1.0
		--assert strict-equal? 2.1 1.1 - -1.0
		--assert strict-equal? 2.1 subtract 1.1 -1.0
		--assert strict-equal? 2.1 i - j
		--assert strict-equal? 2.1 subtract i j

	--test-- "float-subtract 74"
		i: 1.1
		j: 2.2250738585072014e-308
		--assert strict-equal? 1.1 1.1 - 2.2250738585072014e-308
		--assert strict-equal? 1.1 subtract 1.1 2.2250738585072014e-308
		--assert strict-equal? 1.1 i - j
		--assert strict-equal? 1.1 subtract i j

	--test-- "float-subtract 75"
		i: 1.1
		j: -2.2250738585072014e-308
		--assert strict-equal? 1.1 1.1 - -2.2250738585072014e-308
		--assert strict-equal? 1.1 subtract 1.1 -2.2250738585072014e-308
		--assert strict-equal? 1.1 i - j
		--assert strict-equal? 1.1 subtract i j

	--test-- "float-subtract 76"
		i: 1.1
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 1.1 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract 1.1 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 77"
		i: 1.1
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 1.1 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.1 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 78"
		i: 1.1
		j: -1.1
		--assert strict-equal? 2.2 1.1 - -1.1
		--assert strict-equal? 2.2 subtract 1.1 -1.1
		--assert strict-equal? 2.2 i - j
		--assert strict-equal? 2.2 subtract i j

	--test-- "float-subtract 79"
		i: 1.1
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 1.1 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract 1.1 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 80"
		i: 1.1
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 1.1 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.1 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 81"
		i: -1.1
		j: 0.0
		--assert strict-equal? -1.1 -1.1 - 0.0
		--assert strict-equal? -1.1 subtract -1.1 0.0
		--assert strict-equal? -1.1 i - j
		--assert strict-equal? -1.1 subtract i j

	--test-- "float-subtract 82"
		i: -1.1
		j: 1.0
		--assert strict-equal? -2.1 -1.1 - 1.0
		--assert strict-equal? -2.1 subtract -1.1 1.0
		--assert strict-equal? -2.1 i - j
		--assert strict-equal? -2.1 subtract i j

	--test-- "float-subtract 83"
		i: -1.1
		j: -1.0
		--assert strict-equal? -0.10000000000000009 -1.1 - -1.0
		--assert strict-equal? -0.10000000000000009 subtract -1.1 -1.0
		--assert strict-equal? -0.10000000000000009 i - j
		--assert strict-equal? -0.10000000000000009 subtract i j

	--test-- "float-subtract 84"
		i: -1.1
		j: 2.2250738585072014e-308
		--assert strict-equal? -1.1 -1.1 - 2.2250738585072014e-308
		--assert strict-equal? -1.1 subtract -1.1 2.2250738585072014e-308
		--assert strict-equal? -1.1 i - j
		--assert strict-equal? -1.1 subtract i j

	--test-- "float-subtract 85"
		i: -1.1
		j: -2.2250738585072014e-308
		--assert strict-equal? -1.1 -1.1 - -2.2250738585072014e-308
		--assert strict-equal? -1.1 subtract -1.1 -2.2250738585072014e-308
		--assert strict-equal? -1.1 i - j
		--assert strict-equal? -1.1 subtract i j

	--test-- "float-subtract 86"
		i: -1.1
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -1.1 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.1 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 87"
		i: -1.1
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -1.1 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract -1.1 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 88"
		i: -1.1
		j: 1.1
		--assert strict-equal? -2.2 -1.1 - 1.1
		--assert strict-equal? -2.2 subtract -1.1 1.1
		--assert strict-equal? -2.2 i - j
		--assert strict-equal? -2.2 subtract i j

	--test-- "float-subtract 89"
		i: -1.1
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -1.1 - 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.1 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 90"
		i: -1.1
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -1.1 - -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 subtract -1.1 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 91"
		i: 1.7976931348623157e+308
		j: 0.0
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - 0.0
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 0.0
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 92"
		i: 1.7976931348623157e+308
		j: 1.0
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - 1.0
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 1.0
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 93"
		i: 1.7976931348623157e+308
		j: -1.0
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - -1.0
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 -1.0
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 94"
		i: 1.7976931348623157e+308
		j: 2.2250738585072014e-308
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - 2.2250738585072014e-308
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 2.2250738585072014e-308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 95"
		i: 1.7976931348623157e+308
		j: -2.2250738585072014e-308
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - -2.2250738585072014e-308
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 -2.2250738585072014e-308
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 96"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 0.0 1.7976931348623157e+308 - 1.7976931348623157e+308
		--assert strict-equal? 0.0 subtract 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 97"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 - -1.7976931348623157e+308
		--assert strict-equal? 1.#INF subtract 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 1.#INF i - j
		--assert strict-equal? 1.#INF subtract i j

	--test-- "float-subtract 98"
		i: 1.7976931348623157e+308
		j: 1.1
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - 1.1
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 1.1
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 99"
		i: 1.7976931348623157e+308
		j: -1.1
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 - -1.1
		--assert strict-equal? 1.7976931348623157e+308 subtract 1.7976931348623157e+308 -1.1
		--assert strict-equal? 1.7976931348623157e+308 i - j
		--assert strict-equal? 1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 100"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 - -1.7976931348623157e+308
		--assert strict-equal? 1.#INF subtract 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 1.#INF i - j
		--assert strict-equal? 1.#INF subtract i j

	--test-- "float-subtract 101"
		i: -1.7976931348623157e+308
		j: 0.0
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - 0.0
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 0.0
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 102"
		i: -1.7976931348623157e+308
		j: 1.0
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - 1.0
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 1.0
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 103"
		i: -1.7976931348623157e+308
		j: -1.0
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - -1.0
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 -1.0
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 104"
		i: -1.7976931348623157e+308
		j: 2.2250738585072014e-308
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - 2.2250738585072014e-308
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 2.2250738585072014e-308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 105"
		i: -1.7976931348623157e+308
		j: -2.2250738585072014e-308
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - -2.2250738585072014e-308
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 -2.2250738585072014e-308
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 106"
		i: -1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.#INF -1.7976931348623157e+308 - 1.7976931348623157e+308
		--assert strict-equal? -1.#INF subtract -1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? -1.#INF i - j
		--assert strict-equal? -1.#INF subtract i j

	--test-- "float-subtract 107"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 0.0 -1.7976931348623157e+308 - -1.7976931348623157e+308
		--assert strict-equal? 0.0 subtract -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 108"
		i: -1.7976931348623157e+308
		j: 1.1
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - 1.1
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 1.1
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 109"
		i: -1.7976931348623157e+308
		j: -1.1
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 - -1.1
		--assert strict-equal? -1.7976931348623157e+308 subtract -1.7976931348623157e+308 -1.1
		--assert strict-equal? -1.7976931348623157e+308 i - j
		--assert strict-equal? -1.7976931348623157e+308 subtract i j

	--test-- "float-subtract 110"
		i: -1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.#INF -1.7976931348623157e+308 - 1.7976931348623157e+308
		--assert strict-equal? -1.#INF subtract -1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? -1.#INF i - j
		--assert strict-equal? -1.#INF subtract i j

	--test-- "float-subtract 111"
		i: 0.0
		j: 0.0
		--assert strict-equal? 0.0 0.0 - 0.0
		--assert strict-equal? 0.0 subtract 0.0 0.0
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 112"
		i: 1.0
		j: 1.0
		--assert strict-equal? 0.0 1.0 - 1.0
		--assert strict-equal? 0.0 subtract 1.0 1.0
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 113"
		i: -1.0
		j: -1.0
		--assert strict-equal? 0.0 -1.0 - -1.0
		--assert strict-equal? 0.0 subtract -1.0 -1.0
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 114"
		i: 2.2250738585072014e-308
		j: 2.2250738585072014e-308
		--assert strict-equal? 0.0 2.2250738585072014e-308 - 2.2250738585072014e-308
		--assert strict-equal? 0.0 subtract 2.2250738585072014e-308 2.2250738585072014e-308
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 115"
		i: -2.2250738585072014e-308
		j: -2.2250738585072014e-308
		--assert strict-equal? 0.0 -2.2250738585072014e-308 - -2.2250738585072014e-308
		--assert strict-equal? 0.0 subtract -2.2250738585072014e-308 -2.2250738585072014e-308
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 116"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 0.0 1.7976931348623157e+308 - 1.7976931348623157e+308
		--assert strict-equal? 0.0 subtract 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 117"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 0.0 -1.7976931348623157e+308 - -1.7976931348623157e+308
		--assert strict-equal? 0.0 subtract -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 118"
		i: 1.1
		j: 1.1
		--assert strict-equal? 0.0 1.1 - 1.1
		--assert strict-equal? 0.0 subtract 1.1 1.1
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 119"
		i: -1.1
		j: -1.1
		--assert strict-equal? 0.0 -1.1 - -1.1
		--assert strict-equal? 0.0 subtract -1.1 -1.1
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 120"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 0.0 1.7976931348623157e+308 - 1.7976931348623157e+308
		--assert strict-equal? 0.0 subtract 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

	--test-- "float-subtract 121"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 0.0 -1.7976931348623157e+308 - -1.7976931348623157e+308
		--assert strict-equal? 0.0 subtract -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 0.0 i - j
		--assert strict-equal? 0.0 subtract i j

===end-group===
===start-group=== "float-multiply"
	--test-- "float-multiply 1"
		i: 0.0
		j: 1.0
		--assert strict-equal? 0.0 0.0 * 1.0
		--assert strict-equal? 0.0 multiply 0.0 1.0
		--assert strict-equal? 0.0 i * j
		--assert strict-equal? 0.0 multiply i j

	--test-- "float-multiply 2"
		i: 0.0
		j: -1.0
		--assert strict-equal? -0.0 0.0 * -1.0
		--assert strict-equal? -0.0 multiply 0.0 -1.0
		--assert strict-equal? -0.0 i * j
		--assert strict-equal? -0.0 multiply i j

	--test-- "float-multiply 3"
		i: 0.0
		j: 2.2250738585072014e-308
		--assert strict-equal? 0.0 0.0 * 2.2250738585072014e-308
		--assert strict-equal? 0.0 multiply 0.0 2.2250738585072014e-308
		--assert strict-equal? 0.0 i * j
		--assert strict-equal? 0.0 multiply i j

	--test-- "float-multiply 4"
		i: 0.0
		j: -2.2250738585072014e-308
		--assert strict-equal? -0.0 0.0 * -2.2250738585072014e-308
		--assert strict-equal? -0.0 multiply 0.0 -2.2250738585072014e-308
		--assert strict-equal? -0.0 i * j
		--assert strict-equal? -0.0 multiply i j

	--test-- "float-multiply 5"
		i: 0.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 0.0 0.0 * 1.7976931348623157e+308
		--assert strict-equal? 0.0 multiply 0.0 1.7976931348623157e+308
		--assert strict-equal? 0.0 i * j
		--assert strict-equal? 0.0 multiply i j

	--test-- "float-multiply 6"
		i: 0.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -0.0 0.0 * -1.7976931348623157e+308
		--assert strict-equal? -0.0 multiply 0.0 -1.7976931348623157e+308
		--assert strict-equal? -0.0 i * j
		--assert strict-equal? -0.0 multiply i j

	--test-- "float-multiply 7"
		i: 0.0
		j: 1.1
		--assert strict-equal? 0.0 0.0 * 1.1
		--assert strict-equal? 0.0 multiply 0.0 1.1
		--assert strict-equal? 0.0 i * j
		--assert strict-equal? 0.0 multiply i j

	--test-- "float-multiply 8"
		i: 0.0
		j: -1.1
		--assert strict-equal? -0.0 0.0 * -1.1
		--assert strict-equal? -0.0 multiply 0.0 -1.1
		--assert strict-equal? -0.0 i * j
		--assert strict-equal? -0.0 multiply i j

	--test-- "float-multiply 9"
		i: 0.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 0.0 0.0 * 1.7976931348623157e+308
		--assert strict-equal? 0.0 multiply 0.0 1.7976931348623157e+308
		--assert strict-equal? 0.0 i * j
		--assert strict-equal? 0.0 multiply i j

	--test-- "float-multiply 10"
		i: 0.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -0.0 0.0 * -1.7976931348623157e+308
		--assert strict-equal? -0.0 multiply 0.0 -1.7976931348623157e+308
		--assert strict-equal? -0.0 i * j
		--assert strict-equal? -0.0 multiply i j

	--test-- "float-multiply 11"
		i: 1.0
		j: -1.0
		--assert strict-equal? -1.0 1.0 * -1.0
		--assert strict-equal? -1.0 multiply 1.0 -1.0
		--assert strict-equal? -1.0 i * j
		--assert strict-equal? -1.0 multiply i j

	--test-- "float-multiply 12"
		i: 1.0
		j: 2.2250738585072014e-308
		--assert strict-equal? 2.2250738585072014e-308 1.0 * 2.2250738585072014e-308
		--assert strict-equal? 2.2250738585072014e-308 multiply 1.0 2.2250738585072014e-308
		--assert strict-equal? 2.2250738585072014e-308 i * j
		--assert strict-equal? 2.2250738585072014e-308 multiply i j

	--test-- "float-multiply 13"
		i: 1.0
		j: -2.2250738585072014e-308
		--assert strict-equal? -2.2250738585072014e-308 1.0 * -2.2250738585072014e-308
		--assert strict-equal? -2.2250738585072014e-308 multiply 1.0 -2.2250738585072014e-308
		--assert strict-equal? -2.2250738585072014e-308 i * j
		--assert strict-equal? -2.2250738585072014e-308 multiply i j

	--test-- "float-multiply 14"
		i: 1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 1.0 * 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 multiply 1.0 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i * j
		--assert strict-equal? 1.7976931348623157e+308 multiply i j

	--test-- "float-multiply 15"
		i: 1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 1.0 * -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 multiply 1.0 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i * j
		--assert strict-equal? -1.7976931348623157e+308 multiply i j

	--test-- "float-multiply 16"
		i: 1.0
		j: 1.1
		--assert strict-equal? 1.1 1.0 * 1.1
		--assert strict-equal? 1.1 multiply 1.0 1.1
		--assert strict-equal? 1.1 i * j
		--assert strict-equal? 1.1 multiply i j

	--test-- "float-multiply 17"
		i: 1.0
		j: -1.1
		--assert strict-equal? -1.1 1.0 * -1.1
		--assert strict-equal? -1.1 multiply 1.0 -1.1
		--assert strict-equal? -1.1 i * j
		--assert strict-equal? -1.1 multiply i j

	--test-- "float-multiply 18"
		i: 1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 1.0 * 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 multiply 1.0 1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i * j
		--assert strict-equal? 1.7976931348623157e+308 multiply i j

	--test-- "float-multiply 19"
		i: 1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 1.0 * -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 multiply 1.0 -1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i * j
		--assert strict-equal? -1.7976931348623157e+308 multiply i j

	--test-- "float-multiply 20"
		i: -1.0
		j: 2.2250738585072014e-308
		--assert strict-equal? -2.2250738585072014e-308 -1.0 * 2.2250738585072014e-308
		--assert strict-equal? -2.2250738585072014e-308 multiply -1.0 2.2250738585072014e-308
		--assert strict-equal? -2.2250738585072014e-308 i * j
		--assert strict-equal? -2.2250738585072014e-308 multiply i j

	--test-- "float-multiply 21"
		i: -1.0
		j: -2.2250738585072014e-308
		--assert strict-equal? 2.2250738585072014e-308 -1.0 * -2.2250738585072014e-308
		--assert strict-equal? 2.2250738585072014e-308 multiply -1.0 -2.2250738585072014e-308
		--assert strict-equal? 2.2250738585072014e-308 i * j
		--assert strict-equal? 2.2250738585072014e-308 multiply i j

	--test-- "float-multiply 22"
		i: -1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -1.0 * 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 multiply -1.0 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i * j
		--assert strict-equal? -1.7976931348623157e+308 multiply i j

	--test-- "float-multiply 23"
		i: -1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -1.0 * -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 multiply -1.0 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i * j
		--assert strict-equal? 1.7976931348623157e+308 multiply i j

	--test-- "float-multiply 24"
		i: -1.0
		j: 1.1
		--assert strict-equal? -1.1 -1.0 * 1.1
		--assert strict-equal? -1.1 multiply -1.0 1.1
		--assert strict-equal? -1.1 i * j
		--assert strict-equal? -1.1 multiply i j

	--test-- "float-multiply 25"
		i: -1.0
		j: -1.1
		--assert strict-equal? 1.1 -1.0 * -1.1
		--assert strict-equal? 1.1 multiply -1.0 -1.1
		--assert strict-equal? 1.1 i * j
		--assert strict-equal? 1.1 multiply i j

	--test-- "float-multiply 26"
		i: -1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 -1.0 * 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 multiply -1.0 1.7976931348623157e+308
		--assert strict-equal? -1.7976931348623157e+308 i * j
		--assert strict-equal? -1.7976931348623157e+308 multiply i j

	--test-- "float-multiply 27"
		i: -1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 -1.0 * -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 multiply -1.0 -1.7976931348623157e+308
		--assert strict-equal? 1.7976931348623157e+308 i * j
		--assert strict-equal? 1.7976931348623157e+308 multiply i j

	--test-- "float-multiply 28"
		i: 2.2250738585072014e-308
		j: -2.2250738585072014e-308
		--assert strict-equal? -0.0 2.2250738585072014e-308 * -2.2250738585072014e-308
		--assert strict-equal? -0.0 multiply 2.2250738585072014e-308 -2.2250738585072014e-308
		--assert strict-equal? -0.0 i * j
		--assert strict-equal? -0.0 multiply i j

	--test-- "float-multiply 29"
		i: 2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? 3.9999999999999996 2.2250738585072014e-308 * 1.7976931348623157e+308
		--assert strict-equal? 3.9999999999999996 multiply 2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? 3.9999999999999996 i * j
		--assert strict-equal? 3.9999999999999996 multiply i j

	--test-- "float-multiply 30"
		i: 2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? -3.9999999999999996 2.2250738585072014e-308 * -1.7976931348623157e+308
		--assert strict-equal? -3.9999999999999996 multiply 2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? -3.9999999999999996 i * j
		--assert strict-equal? -3.9999999999999996 multiply i j

	--test-- "float-multiply 31"
		i: 2.2250738585072014e-308
		j: 1.1
		--assert strict-equal? 2.4475812443579217e-308 2.2250738585072014e-308 * 1.1
		--assert strict-equal? 2.4475812443579217e-308 multiply 2.2250738585072014e-308 1.1
		--assert strict-equal? 2.4475812443579217e-308 i * j
		--assert strict-equal? 2.4475812443579217e-308 multiply i j

	--test-- "float-multiply 32"
		i: 2.2250738585072014e-308
		j: -1.1
		--assert strict-equal? -2.4475812443579217e-308 2.2250738585072014e-308 * -1.1
		--assert strict-equal? -2.4475812443579217e-308 multiply 2.2250738585072014e-308 -1.1
		--assert strict-equal? -2.4475812443579217e-308 i * j
		--assert strict-equal? -2.4475812443579217e-308 multiply i j

	--test-- "float-multiply 33"
		i: 2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? 3.9999999999999996 2.2250738585072014e-308 * 1.7976931348623157e+308
		--assert strict-equal? 3.9999999999999996 multiply 2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? 3.9999999999999996 i * j
		--assert strict-equal? 3.9999999999999996 multiply i j

	--test-- "float-multiply 34"
		i: 2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? -3.9999999999999996 2.2250738585072014e-308 * -1.7976931348623157e+308
		--assert strict-equal? -3.9999999999999996 multiply 2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? -3.9999999999999996 i * j
		--assert strict-equal? -3.9999999999999996 multiply i j

	--test-- "float-multiply 35"
		i: -2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? -3.9999999999999996 -2.2250738585072014e-308 * 1.7976931348623157e+308
		--assert strict-equal? -3.9999999999999996 multiply -2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? -3.9999999999999996 i * j
		--assert strict-equal? -3.9999999999999996 multiply i j

	--test-- "float-multiply 36"
		i: -2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? 3.9999999999999996 -2.2250738585072014e-308 * -1.7976931348623157e+308
		--assert strict-equal? 3.9999999999999996 multiply -2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? 3.9999999999999996 i * j
		--assert strict-equal? 3.9999999999999996 multiply i j

	--test-- "float-multiply 37"
		i: -2.2250738585072014e-308
		j: 1.1
		--assert strict-equal? -2.4475812443579217e-308 -2.2250738585072014e-308 * 1.1
		--assert strict-equal? -2.4475812443579217e-308 multiply -2.2250738585072014e-308 1.1
		--assert strict-equal? -2.4475812443579217e-308 i * j
		--assert strict-equal? -2.4475812443579217e-308 multiply i j

	--test-- "float-multiply 38"
		i: -2.2250738585072014e-308
		j: -1.1
		--assert strict-equal? 2.4475812443579217e-308 -2.2250738585072014e-308 * -1.1
		--assert strict-equal? 2.4475812443579217e-308 multiply -2.2250738585072014e-308 -1.1
		--assert strict-equal? 2.4475812443579217e-308 i * j
		--assert strict-equal? 2.4475812443579217e-308 multiply i j

	--test-- "float-multiply 39"
		i: -2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? -3.9999999999999996 -2.2250738585072014e-308 * 1.7976931348623157e+308
		--assert strict-equal? -3.9999999999999996 multiply -2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? -3.9999999999999996 i * j
		--assert strict-equal? -3.9999999999999996 multiply i j

	--test-- "float-multiply 40"
		i: -2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? 3.9999999999999996 -2.2250738585072014e-308 * -1.7976931348623157e+308
		--assert strict-equal? 3.9999999999999996 multiply -2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? 3.9999999999999996 i * j
		--assert strict-equal? 3.9999999999999996 multiply i j

	--test-- "float-multiply 41"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.#INF 1.7976931348623157e+308 * -1.7976931348623157e+308
		--assert strict-equal? -1.#INF multiply 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? -1.#INF i * j
		--assert strict-equal? -1.#INF multiply i j

	--test-- "float-multiply 42"
		i: 1.7976931348623157e+308
		j: 1.1
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 * 1.1
		--assert strict-equal? 1.#INF multiply 1.7976931348623157e+308 1.1
		--assert strict-equal? 1.#INF i * j
		--assert strict-equal? 1.#INF multiply i j

	--test-- "float-multiply 43"
		i: 1.7976931348623157e+308
		j: -1.1
		--assert strict-equal? -1.#INF 1.7976931348623157e+308 * -1.1
		--assert strict-equal? -1.#INF multiply 1.7976931348623157e+308 -1.1
		--assert strict-equal? -1.#INF i * j
		--assert strict-equal? -1.#INF multiply i j

	--test-- "float-multiply 44"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 * 1.7976931348623157e+308
		--assert strict-equal? 1.#INF multiply 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 1.#INF i * j
		--assert strict-equal? 1.#INF multiply i j

	--test-- "float-multiply 45"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.#INF 1.7976931348623157e+308 * -1.7976931348623157e+308
		--assert strict-equal? -1.#INF multiply 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? -1.#INF i * j
		--assert strict-equal? -1.#INF multiply i j

	--test-- "float-multiply 46"
		i: -1.7976931348623157e+308
		j: 1.1
		--assert strict-equal? -1.#INF -1.7976931348623157e+308 * 1.1
		--assert strict-equal? -1.#INF multiply -1.7976931348623157e+308 1.1
		--assert strict-equal? -1.#INF i * j
		--assert strict-equal? -1.#INF multiply i j

	--test-- "float-multiply 47"
		i: -1.7976931348623157e+308
		j: -1.1
		--assert strict-equal? 1.#INF -1.7976931348623157e+308 * -1.1
		--assert strict-equal? 1.#INF multiply -1.7976931348623157e+308 -1.1
		--assert strict-equal? 1.#INF i * j
		--assert strict-equal? 1.#INF multiply i j

	--test-- "float-multiply 48"
		i: -1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.#INF -1.7976931348623157e+308 * 1.7976931348623157e+308
		--assert strict-equal? -1.#INF multiply -1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? -1.#INF i * j
		--assert strict-equal? -1.#INF multiply i j

	--test-- "float-multiply 49"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.#INF -1.7976931348623157e+308 * -1.7976931348623157e+308
		--assert strict-equal? 1.#INF multiply -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 1.#INF i * j
		--assert strict-equal? 1.#INF multiply i j

	--test-- "float-multiply 50"
		i: 1.1
		j: -1.1
		--assert strict-equal? -1.2100000000000002 1.1 * -1.1
		--assert strict-equal? -1.2100000000000002 multiply 1.1 -1.1
		--assert strict-equal? -1.2100000000000002 i * j
		--assert strict-equal? -1.2100000000000002 multiply i j

	--test-- "float-multiply 51"
		i: 1.1
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.#INF 1.1 * 1.7976931348623157e+308
		--assert strict-equal? 1.#INF multiply 1.1 1.7976931348623157e+308
		--assert strict-equal? 1.#INF i * j
		--assert strict-equal? 1.#INF multiply i j

	--test-- "float-multiply 52"
		i: 1.1
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.#INF 1.1 * -1.7976931348623157e+308
		--assert strict-equal? -1.#INF multiply 1.1 -1.7976931348623157e+308
		--assert strict-equal? -1.#INF i * j
		--assert strict-equal? -1.#INF multiply i j

	--test-- "float-multiply 53"
		i: -1.1
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.#INF -1.1 * 1.7976931348623157e+308
		--assert strict-equal? -1.#INF multiply -1.1 1.7976931348623157e+308
		--assert strict-equal? -1.#INF i * j
		--assert strict-equal? -1.#INF multiply i j

	--test-- "float-multiply 54"
		i: -1.1
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.#INF -1.1 * -1.7976931348623157e+308
		--assert strict-equal? 1.#INF multiply -1.1 -1.7976931348623157e+308
		--assert strict-equal? 1.#INF i * j
		--assert strict-equal? 1.#INF multiply i j

	--test-- "float-multiply 55"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.#INF 1.7976931348623157e+308 * -1.7976931348623157e+308
		--assert strict-equal? -1.#INF multiply 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? -1.#INF i * j
		--assert strict-equal? -1.#INF multiply i j

	--test-- "float-multiply 56"
		i: 0.0
		j: 0.0
		--assert strict-equal? 0.0 0.0 * 0.0
		--assert strict-equal? 0.0 multiply 0.0 0.0
		--assert strict-equal? 0.0 i * j
		--assert strict-equal? 0.0 multiply i j

	--test-- "float-multiply 57"
		i: 1.0
		j: 1.0
		--assert strict-equal? 1.0 1.0 * 1.0
		--assert strict-equal? 1.0 multiply 1.0 1.0
		--assert strict-equal? 1.0 i * j
		--assert strict-equal? 1.0 multiply i j

	--test-- "float-multiply 58"
		i: -1.0
		j: -1.0
		--assert strict-equal? 1.0 -1.0 * -1.0
		--assert strict-equal? 1.0 multiply -1.0 -1.0
		--assert strict-equal? 1.0 i * j
		--assert strict-equal? 1.0 multiply i j

	--test-- "float-multiply 59"
		i: 2.2250738585072014e-308
		j: 2.2250738585072014e-308
		--assert strict-equal? 0.0 2.2250738585072014e-308 * 2.2250738585072014e-308
		--assert strict-equal? 0.0 multiply 2.2250738585072014e-308 2.2250738585072014e-308
		--assert strict-equal? 0.0 i * j
		--assert strict-equal? 0.0 multiply i j

	--test-- "float-multiply 60"
		i: -2.2250738585072014e-308
		j: -2.2250738585072014e-308
		--assert strict-equal? 0.0 -2.2250738585072014e-308 * -2.2250738585072014e-308
		--assert strict-equal? 0.0 multiply -2.2250738585072014e-308 -2.2250738585072014e-308
		--assert strict-equal? 0.0 i * j
		--assert strict-equal? 0.0 multiply i j

	--test-- "float-multiply 61"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 * 1.7976931348623157e+308
		--assert strict-equal? 1.#INF multiply 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 1.#INF i * j
		--assert strict-equal? 1.#INF multiply i j

	--test-- "float-multiply 62"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.#INF -1.7976931348623157e+308 * -1.7976931348623157e+308
		--assert strict-equal? 1.#INF multiply -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 1.#INF i * j
		--assert strict-equal? 1.#INF multiply i j

	--test-- "float-multiply 63"
		i: 1.1
		j: 1.1
		--assert strict-equal? 1.2100000000000002 1.1 * 1.1
		--assert strict-equal? 1.2100000000000002 multiply 1.1 1.1
		--assert strict-equal? 1.2100000000000002 i * j
		--assert strict-equal? 1.2100000000000002 multiply i j

	--test-- "float-multiply 64"
		i: -1.1
		j: -1.1
		--assert strict-equal? 1.2100000000000002 -1.1 * -1.1
		--assert strict-equal? 1.2100000000000002 multiply -1.1 -1.1
		--assert strict-equal? 1.2100000000000002 i * j
		--assert strict-equal? 1.2100000000000002 multiply i j

	--test-- "float-multiply 65"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 * 1.7976931348623157e+308
		--assert strict-equal? 1.#INF multiply 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 1.#INF i * j
		--assert strict-equal? 1.#INF multiply i j

	--test-- "float-multiply 66"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.#INF -1.7976931348623157e+308 * -1.7976931348623157e+308
		--assert strict-equal? 1.#INF multiply -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 1.#INF i * j
		--assert strict-equal? 1.#INF multiply i j

===end-group===
===start-group=== "float-divide"
	--test-- "float-divide 1"
		i: 0.0
		j: 1.0
		--assert strict-equal? 0.0 0.0 / 1.0
		--assert strict-equal? 0.0 divide 0.0 1.0
		--assert strict-equal? 0.0 i / j
		--assert strict-equal? 0.0 divide i j

	--test-- "float-divide 2"
		i: 0.0
		j: -1.0
		--assert strict-equal? -0.0 0.0 / -1.0
		--assert strict-equal? -0.0 divide 0.0 -1.0
		--assert strict-equal? -0.0 i / j
		--assert strict-equal? -0.0 divide i j

	--test-- "float-divide 3"
		i: 0.0
		j: 2.2250738585072014e-308
		--assert strict-equal? 0.0 0.0 / 2.2250738585072014e-308
		--assert strict-equal? 0.0 divide 0.0 2.2250738585072014e-308
		--assert strict-equal? 0.0 i / j
		--assert strict-equal? 0.0 divide i j

	--test-- "float-divide 4"
		i: 0.0
		j: -2.2250738585072014e-308
		--assert strict-equal? -0.0 0.0 / -2.2250738585072014e-308
		--assert strict-equal? -0.0 divide 0.0 -2.2250738585072014e-308
		--assert strict-equal? -0.0 i / j
		--assert strict-equal? -0.0 divide i j

	--test-- "float-divide 5"
		i: 0.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 0.0 0.0 / 1.7976931348623157e+308
		--assert strict-equal? 0.0 divide 0.0 1.7976931348623157e+308
		--assert strict-equal? 0.0 i / j
		--assert strict-equal? 0.0 divide i j

	--test-- "float-divide 6"
		i: 0.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -0.0 0.0 / -1.7976931348623157e+308
		--assert strict-equal? -0.0 divide 0.0 -1.7976931348623157e+308
		--assert strict-equal? -0.0 i / j
		--assert strict-equal? -0.0 divide i j

	--test-- "float-divide 7"
		i: 0.0
		j: 1.1
		--assert strict-equal? 0.0 0.0 / 1.1
		--assert strict-equal? 0.0 divide 0.0 1.1
		--assert strict-equal? 0.0 i / j
		--assert strict-equal? 0.0 divide i j

	--test-- "float-divide 8"
		i: 0.0
		j: -1.1
		--assert strict-equal? -0.0 0.0 / -1.1
		--assert strict-equal? -0.0 divide 0.0 -1.1
		--assert strict-equal? -0.0 i / j
		--assert strict-equal? -0.0 divide i j

	--test-- "float-divide 9"
		i: 0.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 0.0 0.0 / 1.7976931348623157e+308
		--assert strict-equal? 0.0 divide 0.0 1.7976931348623157e+308
		--assert strict-equal? 0.0 i / j
		--assert strict-equal? 0.0 divide i j

	--test-- "float-divide 10"
		i: 0.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -0.0 0.0 / -1.7976931348623157e+308
		--assert strict-equal? -0.0 divide 0.0 -1.7976931348623157e+308
		--assert strict-equal? -0.0 i / j
		--assert strict-equal? -0.0 divide i j

	--test-- "float-divide 11"
		i: 1.0
		j: 0.0
		;--assert strict-equal? 1.#INF 1.0 / 0.0
		;--assert strict-equal? 1.#INF divide 1.0 0.0
		;--assert strict-equal? 1.#INF i / j
		;--assert strict-equal? 1.#INF divide i j

	--test-- "float-divide 12"
		i: 1.0
		j: -1.0
		--assert strict-equal? -1.0 1.0 / -1.0
		--assert strict-equal? -1.0 divide 1.0 -1.0
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 13"
		i: 1.0
		j: 2.2250738585072014e-308
		--assert strict-equal? 4.49423283715579e+307 1.0 / 2.2250738585072014e-308
		--assert strict-equal? 4.49423283715579e+307 divide 1.0 2.2250738585072014e-308
		--assert strict-equal? 4.49423283715579e+307 i / j
		--assert strict-equal? 4.49423283715579e+307 divide i j

	--test-- "float-divide 14"
		i: 1.0
		j: -2.2250738585072014e-308
		--assert strict-equal? -4.49423283715579e+307 1.0 / -2.2250738585072014e-308
		--assert strict-equal? -4.49423283715579e+307 divide 1.0 -2.2250738585072014e-308
		--assert strict-equal? -4.49423283715579e+307 i / j
		--assert strict-equal? -4.49423283715579e+307 divide i j

	--test-- "float-divide 15"
		i: 1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 5.562684646268003e-309 1.0 / 1.7976931348623157e+308
		--assert strict-equal? 5.562684646268003e-309 divide 1.0 1.7976931348623157e+308
		--assert strict-equal? 5.562684646268003e-309 i / j
		--assert strict-equal? 5.562684646268003e-309 divide i j

	--test-- "float-divide 16"
		i: 1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -5.562684646268003e-309 1.0 / -1.7976931348623157e+308
		--assert strict-equal? -5.562684646268003e-309 divide 1.0 -1.7976931348623157e+308
		--assert strict-equal? -5.562684646268003e-309 i / j
		--assert strict-equal? -5.562684646268003e-309 divide i j

	--test-- "float-divide 17"
		i: 1.0
		j: 1.1
		--assert strict-equal? 0.9090909090909091 1.0 / 1.1
		--assert strict-equal? 0.9090909090909091 divide 1.0 1.1
		--assert strict-equal? 0.9090909090909091 i / j
		--assert strict-equal? 0.9090909090909091 divide i j

	--test-- "float-divide 18"
		i: 1.0
		j: -1.1
		--assert strict-equal? -0.9090909090909091 1.0 / -1.1
		--assert strict-equal? -0.9090909090909091 divide 1.0 -1.1
		--assert strict-equal? -0.9090909090909091 i / j
		--assert strict-equal? -0.9090909090909091 divide i j

	--test-- "float-divide 19"
		i: 1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? 5.562684646268003e-309 1.0 / 1.7976931348623157e+308
		--assert strict-equal? 5.562684646268003e-309 divide 1.0 1.7976931348623157e+308
		--assert strict-equal? 5.562684646268003e-309 i / j
		--assert strict-equal? 5.562684646268003e-309 divide i j

	--test-- "float-divide 20"
		i: 1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? -5.562684646268003e-309 1.0 / -1.7976931348623157e+308
		--assert strict-equal? -5.562684646268003e-309 divide 1.0 -1.7976931348623157e+308
		--assert strict-equal? -5.562684646268003e-309 i / j
		--assert strict-equal? -5.562684646268003e-309 divide i j

	--test-- "float-divide 21"
		i: -1.0
		j: 0.0
		;--assert strict-equal? -1.#INF -1.0 / 0.0
		;--assert strict-equal? -1.#INF divide -1.0 0.0
		;--assert strict-equal? -1.#INF i / j
		;--assert strict-equal? -1.#INF divide i j

	--test-- "float-divide 22"
		i: -1.0
		j: 1.0
		--assert strict-equal? -1.0 -1.0 / 1.0
		--assert strict-equal? -1.0 divide -1.0 1.0
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 23"
		i: -1.0
		j: 2.2250738585072014e-308
		--assert strict-equal? -4.49423283715579e+307 -1.0 / 2.2250738585072014e-308
		--assert strict-equal? -4.49423283715579e+307 divide -1.0 2.2250738585072014e-308
		--assert strict-equal? -4.49423283715579e+307 i / j
		--assert strict-equal? -4.49423283715579e+307 divide i j

	--test-- "float-divide 24"
		i: -1.0
		j: -2.2250738585072014e-308
		--assert strict-equal? 4.49423283715579e+307 -1.0 / -2.2250738585072014e-308
		--assert strict-equal? 4.49423283715579e+307 divide -1.0 -2.2250738585072014e-308
		--assert strict-equal? 4.49423283715579e+307 i / j
		--assert strict-equal? 4.49423283715579e+307 divide i j

	--test-- "float-divide 25"
		i: -1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? -5.562684646268003e-309 -1.0 / 1.7976931348623157e+308
		--assert strict-equal? -5.562684646268003e-309 divide -1.0 1.7976931348623157e+308
		--assert strict-equal? -5.562684646268003e-309 i / j
		--assert strict-equal? -5.562684646268003e-309 divide i j

	--test-- "float-divide 26"
		i: -1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? 5.562684646268003e-309 -1.0 / -1.7976931348623157e+308
		--assert strict-equal? 5.562684646268003e-309 divide -1.0 -1.7976931348623157e+308
		--assert strict-equal? 5.562684646268003e-309 i / j
		--assert strict-equal? 5.562684646268003e-309 divide i j

	--test-- "float-divide 27"
		i: -1.0
		j: 1.1
		--assert strict-equal? -0.9090909090909091 -1.0 / 1.1
		--assert strict-equal? -0.9090909090909091 divide -1.0 1.1
		--assert strict-equal? -0.9090909090909091 i / j
		--assert strict-equal? -0.9090909090909091 divide i j

	--test-- "float-divide 28"
		i: -1.0
		j: -1.1
		--assert strict-equal? 0.9090909090909091 -1.0 / -1.1
		--assert strict-equal? 0.9090909090909091 divide -1.0 -1.1
		--assert strict-equal? 0.9090909090909091 i / j
		--assert strict-equal? 0.9090909090909091 divide i j

	--test-- "float-divide 29"
		i: -1.0
		j: 1.7976931348623157e+308
		--assert strict-equal? -5.562684646268003e-309 -1.0 / 1.7976931348623157e+308
		--assert strict-equal? -5.562684646268003e-309 divide -1.0 1.7976931348623157e+308
		--assert strict-equal? -5.562684646268003e-309 i / j
		--assert strict-equal? -5.562684646268003e-309 divide i j

	--test-- "float-divide 30"
		i: -1.0
		j: -1.7976931348623157e+308
		--assert strict-equal? 5.562684646268003e-309 -1.0 / -1.7976931348623157e+308
		--assert strict-equal? 5.562684646268003e-309 divide -1.0 -1.7976931348623157e+308
		--assert strict-equal? 5.562684646268003e-309 i / j
		--assert strict-equal? 5.562684646268003e-309 divide i j

	--test-- "float-divide 31"
		i: 2.2250738585072014e-308
		j: 0.0
		;--assert strict-equal? 1.#INF 2.2250738585072014e-308 / 0.0
		;--assert strict-equal? 1.#INF divide 2.2250738585072014e-308 0.0
		;--assert strict-equal? 1.#INF i / j
		;--assert strict-equal? 1.#INF divide i j

	--test-- "float-divide 32"
		i: 2.2250738585072014e-308
		j: 1.0
		--assert strict-equal? 2.2250738585072014e-308 2.2250738585072014e-308 / 1.0
		--assert strict-equal? 2.2250738585072014e-308 divide 2.2250738585072014e-308 1.0
		--assert strict-equal? 2.2250738585072014e-308 i / j
		--assert strict-equal? 2.2250738585072014e-308 divide i j

	--test-- "float-divide 33"
		i: 2.2250738585072014e-308
		j: -1.0
		--assert strict-equal? -2.2250738585072014e-308 2.2250738585072014e-308 / -1.0
		--assert strict-equal? -2.2250738585072014e-308 divide 2.2250738585072014e-308 -1.0
		--assert strict-equal? -2.2250738585072014e-308 i / j
		--assert strict-equal? -2.2250738585072014e-308 divide i j

	--test-- "float-divide 34"
		i: 2.2250738585072014e-308
		j: -2.2250738585072014e-308
		--assert strict-equal? -1.0 2.2250738585072014e-308 / -2.2250738585072014e-308
		--assert strict-equal? -1.0 divide 2.2250738585072014e-308 -2.2250738585072014e-308
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 35"
		i: 2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? 0.0 2.2250738585072014e-308 / 1.7976931348623157e+308
		--assert strict-equal? 0.0 divide 2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? 0.0 i / j
		--assert strict-equal? 0.0 divide i j

	--test-- "float-divide 36"
		i: 2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? -0.0 2.2250738585072014e-308 / -1.7976931348623157e+308
		--assert strict-equal? -0.0 divide 2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? -0.0 i / j
		--assert strict-equal? -0.0 divide i j

	--test-- "float-divide 37"
		i: 2.2250738585072014e-308
		j: 1.1
		;--assert strict-equal? 2.022794416824728e-308 2.2250738585072014e-308 / 1.1
		;--assert strict-equal? 2.022794416824728e-308 divide 2.2250738585072014e-308 1.1
		;--assert strict-equal? 2.022794416824728e-308 i / j
		;--assert strict-equal? 2.022794416824728e-308 divide i j

	--test-- "float-divide 38"
		i: 2.2250738585072014e-308
		j: -1.1
		;--assert strict-equal? -2.022794416824728e-308 2.2250738585072014e-308 / -1.1
		;--assert strict-equal? -2.022794416824728e-308 divide 2.2250738585072014e-308 -1.1
		;--assert strict-equal? -2.022794416824728e-308 i / j
		;--assert strict-equal? -2.022794416824728e-308 divide i j

	--test-- "float-divide 39"
		i: 2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? 0.0 2.2250738585072014e-308 / 1.7976931348623157e+308
		--assert strict-equal? 0.0 divide 2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? 0.0 i / j
		--assert strict-equal? 0.0 divide i j

	--test-- "float-divide 40"
		i: 2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? -0.0 2.2250738585072014e-308 / -1.7976931348623157e+308
		--assert strict-equal? -0.0 divide 2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? -0.0 i / j
		--assert strict-equal? -0.0 divide i j

	--test-- "float-divide 41"
		i: -2.2250738585072014e-308
		j: 0.0
		;--assert strict-equal? -1.#INF -2.2250738585072014e-308 / 0.0
		;--assert strict-equal? -1.#INF divide -2.2250738585072014e-308 0.0
		;--assert strict-equal? -1.#INF i / j
		;--assert strict-equal? -1.#INF divide i j

	--test-- "float-divide 42"
		i: -2.2250738585072014e-308
		j: 1.0
		--assert strict-equal? -2.2250738585072014e-308 -2.2250738585072014e-308 / 1.0
		--assert strict-equal? -2.2250738585072014e-308 divide -2.2250738585072014e-308 1.0
		--assert strict-equal? -2.2250738585072014e-308 i / j
		--assert strict-equal? -2.2250738585072014e-308 divide i j

	--test-- "float-divide 43"
		i: -2.2250738585072014e-308
		j: -1.0
		--assert strict-equal? 2.2250738585072014e-308 -2.2250738585072014e-308 / -1.0
		--assert strict-equal? 2.2250738585072014e-308 divide -2.2250738585072014e-308 -1.0
		--assert strict-equal? 2.2250738585072014e-308 i / j
		--assert strict-equal? 2.2250738585072014e-308 divide i j

	--test-- "float-divide 44"
		i: -2.2250738585072014e-308
		j: 2.2250738585072014e-308
		--assert strict-equal? -1.0 -2.2250738585072014e-308 / 2.2250738585072014e-308
		--assert strict-equal? -1.0 divide -2.2250738585072014e-308 2.2250738585072014e-308
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 45"
		i: -2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? -0.0 -2.2250738585072014e-308 / 1.7976931348623157e+308
		--assert strict-equal? -0.0 divide -2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? -0.0 i / j
		--assert strict-equal? -0.0 divide i j

	--test-- "float-divide 46"
		i: -2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? 0.0 -2.2250738585072014e-308 / -1.7976931348623157e+308
		--assert strict-equal? 0.0 divide -2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? 0.0 i / j
		--assert strict-equal? 0.0 divide i j

	--test-- "float-divide 47"
		i: -2.2250738585072014e-308
		j: 1.1
		;--assert strict-equal? -2.022794416824728e-308 -2.2250738585072014e-308 / 1.1
		;--assert strict-equal? -2.022794416824728e-308 divide -2.2250738585072014e-308 1.1
		;--assert strict-equal? -2.022794416824728e-308 i / j
		;--assert strict-equal? -2.022794416824728e-308 divide i j

	--test-- "float-divide 48"
		i: -2.2250738585072014e-308
		j: -1.1
		;--assert strict-equal? 2.022794416824728e-308 -2.2250738585072014e-308 / -1.1
		;--assert strict-equal? 2.022794416824728e-308 divide -2.2250738585072014e-308 -1.1
		;--assert strict-equal? 2.022794416824728e-308 i / j
		;--assert strict-equal? 2.022794416824728e-308 divide i j

	--test-- "float-divide 49"
		i: -2.2250738585072014e-308
		j: 1.7976931348623157e+308
		--assert strict-equal? -0.0 -2.2250738585072014e-308 / 1.7976931348623157e+308
		--assert strict-equal? -0.0 divide -2.2250738585072014e-308 1.7976931348623157e+308
		--assert strict-equal? -0.0 i / j
		--assert strict-equal? -0.0 divide i j

	--test-- "float-divide 50"
		i: -2.2250738585072014e-308
		j: -1.7976931348623157e+308
		--assert strict-equal? 0.0 -2.2250738585072014e-308 / -1.7976931348623157e+308
		--assert strict-equal? 0.0 divide -2.2250738585072014e-308 -1.7976931348623157e+308
		--assert strict-equal? 0.0 i / j
		--assert strict-equal? 0.0 divide i j

	--test-- "float-divide 51"
		i: 1.7976931348623157e+308
		j: 0.0
		;--assert strict-equal? 1.#INF 1.7976931348623157e+308 / 0.0
		;--assert strict-equal? 1.#INF divide 1.7976931348623157e+308 0.0
		;--assert strict-equal? 1.#INF i / j
		;--assert strict-equal? 1.#INF divide i j

	--test-- "float-divide 52"
		i: 1.7976931348623157e+308
		j: 1.0
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 / 1.0
		--assert strict-equal? 1.7976931348623157e+308 divide 1.7976931348623157e+308 1.0
		--assert strict-equal? 1.7976931348623157e+308 i / j
		--assert strict-equal? 1.7976931348623157e+308 divide i j

	--test-- "float-divide 53"
		i: 1.7976931348623157e+308
		j: -1.0
		--assert strict-equal? -1.7976931348623157e+308 1.7976931348623157e+308 / -1.0
		--assert strict-equal? -1.7976931348623157e+308 divide 1.7976931348623157e+308 -1.0
		--assert strict-equal? -1.7976931348623157e+308 i / j
		--assert strict-equal? -1.7976931348623157e+308 divide i j

	--test-- "float-divide 54"
		i: 1.7976931348623157e+308
		j: 2.2250738585072014e-308
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 / 2.2250738585072014e-308
		--assert strict-equal? 1.#INF divide 1.7976931348623157e+308 2.2250738585072014e-308
		--assert strict-equal? 1.#INF i / j
		--assert strict-equal? 1.#INF divide i j

	--test-- "float-divide 55"
		i: 1.7976931348623157e+308
		j: -2.2250738585072014e-308
		--assert strict-equal? -1.#INF 1.7976931348623157e+308 / -2.2250738585072014e-308
		--assert strict-equal? -1.#INF divide 1.7976931348623157e+308 -2.2250738585072014e-308
		--assert strict-equal? -1.#INF i / j
		--assert strict-equal? -1.#INF divide i j

	--test-- "float-divide 56"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.0 1.7976931348623157e+308 / -1.7976931348623157e+308
		--assert strict-equal? -1.0 divide 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 57"
		i: 1.7976931348623157e+308
		j: 1.1
		--assert strict-equal? 1.6342664862384688e+308 1.7976931348623157e+308 / 1.1
		--assert strict-equal? 1.6342664862384688e+308 divide 1.7976931348623157e+308 1.1
		--assert strict-equal? 1.6342664862384688e+308 i / j
		--assert strict-equal? 1.6342664862384688e+308 divide i j

	--test-- "float-divide 58"
		i: 1.7976931348623157e+308
		j: -1.1
		--assert strict-equal? -1.6342664862384688e+308 1.7976931348623157e+308 / -1.1
		--assert strict-equal? -1.6342664862384688e+308 divide 1.7976931348623157e+308 -1.1
		--assert strict-equal? -1.6342664862384688e+308 i / j
		--assert strict-equal? -1.6342664862384688e+308 divide i j

	--test-- "float-divide 59"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.0 1.7976931348623157e+308 / 1.7976931348623157e+308
		--assert strict-equal? 1.0 divide 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 60"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.0 1.7976931348623157e+308 / -1.7976931348623157e+308
		--assert strict-equal? -1.0 divide 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 61"
		i: -1.7976931348623157e+308
		j: 0.0
		;--assert strict-equal? -1.#INF -1.7976931348623157e+308 / 0.0
		;--assert strict-equal? -1.#INF divide -1.7976931348623157e+308 0.0
		;--assert strict-equal? -1.#INF i / j
		;--assert strict-equal? -1.#INF divide i j

	--test-- "float-divide 62"
		i: -1.7976931348623157e+308
		j: 1.0
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 / 1.0
		--assert strict-equal? -1.7976931348623157e+308 divide -1.7976931348623157e+308 1.0
		--assert strict-equal? -1.7976931348623157e+308 i / j
		--assert strict-equal? -1.7976931348623157e+308 divide i j

	--test-- "float-divide 63"
		i: -1.7976931348623157e+308
		j: -1.0
		--assert strict-equal? 1.7976931348623157e+308 -1.7976931348623157e+308 / -1.0
		--assert strict-equal? 1.7976931348623157e+308 divide -1.7976931348623157e+308 -1.0
		--assert strict-equal? 1.7976931348623157e+308 i / j
		--assert strict-equal? 1.7976931348623157e+308 divide i j

	--test-- "float-divide 64"
		i: -1.7976931348623157e+308
		j: 2.2250738585072014e-308
		--assert strict-equal? -1.#INF -1.7976931348623157e+308 / 2.2250738585072014e-308
		--assert strict-equal? -1.#INF divide -1.7976931348623157e+308 2.2250738585072014e-308
		--assert strict-equal? -1.#INF i / j
		--assert strict-equal? -1.#INF divide i j

	--test-- "float-divide 65"
		i: -1.7976931348623157e+308
		j: -2.2250738585072014e-308
		--assert strict-equal? 1.#INF -1.7976931348623157e+308 / -2.2250738585072014e-308
		--assert strict-equal? 1.#INF divide -1.7976931348623157e+308 -2.2250738585072014e-308
		--assert strict-equal? 1.#INF i / j
		--assert strict-equal? 1.#INF divide i j

	--test-- "float-divide 66"
		i: -1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.0 -1.7976931348623157e+308 / 1.7976931348623157e+308
		--assert strict-equal? -1.0 divide -1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 67"
		i: -1.7976931348623157e+308
		j: 1.1
		--assert strict-equal? -1.6342664862384688e+308 -1.7976931348623157e+308 / 1.1
		--assert strict-equal? -1.6342664862384688e+308 divide -1.7976931348623157e+308 1.1
		--assert strict-equal? -1.6342664862384688e+308 i / j
		--assert strict-equal? -1.6342664862384688e+308 divide i j

	--test-- "float-divide 68"
		i: -1.7976931348623157e+308
		j: -1.1
		--assert strict-equal? 1.6342664862384688e+308 -1.7976931348623157e+308 / -1.1
		--assert strict-equal? 1.6342664862384688e+308 divide -1.7976931348623157e+308 -1.1
		--assert strict-equal? 1.6342664862384688e+308 i / j
		--assert strict-equal? 1.6342664862384688e+308 divide i j

	--test-- "float-divide 69"
		i: -1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.0 -1.7976931348623157e+308 / 1.7976931348623157e+308
		--assert strict-equal? -1.0 divide -1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 70"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.0 -1.7976931348623157e+308 / -1.7976931348623157e+308
		--assert strict-equal? 1.0 divide -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 71"
		i: 1.1
		j: 0.0
		;--assert strict-equal? 1.#INF 1.1 / 0.0
		;--assert strict-equal? 1.#INF divide 1.1 0.0
		;--assert strict-equal? 1.#INF i / j
		;--assert strict-equal? 1.#INF divide i j

	--test-- "float-divide 72"
		i: 1.1
		j: 1.0
		--assert strict-equal? 1.1 1.1 / 1.0
		--assert strict-equal? 1.1 divide 1.1 1.0
		--assert strict-equal? 1.1 i / j
		--assert strict-equal? 1.1 divide i j

	--test-- "float-divide 73"
		i: 1.1
		j: -1.0
		--assert strict-equal? -1.1 1.1 / -1.0
		--assert strict-equal? -1.1 divide 1.1 -1.0
		--assert strict-equal? -1.1 i / j
		--assert strict-equal? -1.1 divide i j

	--test-- "float-divide 74"
		i: 1.1
		j: 2.2250738585072014e-308
		--assert strict-equal? 4.943656120871369e+307 1.1 / 2.2250738585072014e-308
		--assert strict-equal? 4.943656120871369e+307 divide 1.1 2.2250738585072014e-308
		--assert strict-equal? 4.943656120871369e+307 i / j
		--assert strict-equal? 4.943656120871369e+307 divide i j

	--test-- "float-divide 75"
		i: 1.1
		j: -2.2250738585072014e-308
		--assert strict-equal? -4.943656120871369e+307 1.1 / -2.2250738585072014e-308
		--assert strict-equal? -4.943656120871369e+307 divide 1.1 -2.2250738585072014e-308
		--assert strict-equal? -4.943656120871369e+307 i / j
		--assert strict-equal? -4.943656120871369e+307 divide i j

	--test-- "float-divide 76"
		i: 1.1
		j: 1.7976931348623157e+308
		--assert strict-equal? 6.118953110894807e-309 1.1 / 1.7976931348623157e+308
		--assert strict-equal? 6.118953110894807e-309 divide 1.1 1.7976931348623157e+308
		--assert strict-equal? 6.118953110894807e-309 i / j
		--assert strict-equal? 6.118953110894807e-309 divide i j

	--test-- "float-divide 77"
		i: 1.1
		j: -1.7976931348623157e+308
		--assert strict-equal? -6.118953110894807e-309 1.1 / -1.7976931348623157e+308
		--assert strict-equal? -6.118953110894807e-309 divide 1.1 -1.7976931348623157e+308
		--assert strict-equal? -6.118953110894807e-309 i / j
		--assert strict-equal? -6.118953110894807e-309 divide i j

	--test-- "float-divide 78"
		i: 1.1
		j: -1.1
		--assert strict-equal? -1.0 1.1 / -1.1
		--assert strict-equal? -1.0 divide 1.1 -1.1
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 79"
		i: 1.1
		j: 1.7976931348623157e+308
		--assert strict-equal? 6.118953110894807e-309 1.1 / 1.7976931348623157e+308
		--assert strict-equal? 6.118953110894807e-309 divide 1.1 1.7976931348623157e+308
		--assert strict-equal? 6.118953110894807e-309 i / j
		--assert strict-equal? 6.118953110894807e-309 divide i j

	--test-- "float-divide 80"
		i: 1.1
		j: -1.7976931348623157e+308
		--assert strict-equal? -6.118953110894807e-309 1.1 / -1.7976931348623157e+308
		--assert strict-equal? -6.118953110894807e-309 divide 1.1 -1.7976931348623157e+308
		--assert strict-equal? -6.118953110894807e-309 i / j
		--assert strict-equal? -6.118953110894807e-309 divide i j

	--test-- "float-divide 81"
		i: -1.1
		j: 0.0
		;--assert strict-equal? -1.#INF -1.1 / 0.0
		;--assert strict-equal? -1.#INF divide -1.1 0.0
		;--assert strict-equal? -1.#INF i / j
		;--assert strict-equal? -1.#INF divide i j

	--test-- "float-divide 82"
		i: -1.1
		j: 1.0
		--assert strict-equal? -1.1 -1.1 / 1.0
		--assert strict-equal? -1.1 divide -1.1 1.0
		--assert strict-equal? -1.1 i / j
		--assert strict-equal? -1.1 divide i j

	--test-- "float-divide 83"
		i: -1.1
		j: -1.0
		--assert strict-equal? 1.1 -1.1 / -1.0
		--assert strict-equal? 1.1 divide -1.1 -1.0
		--assert strict-equal? 1.1 i / j
		--assert strict-equal? 1.1 divide i j

	--test-- "float-divide 84"
		i: -1.1
		j: 2.2250738585072014e-308
		--assert strict-equal? -4.943656120871369e+307 -1.1 / 2.2250738585072014e-308
		--assert strict-equal? -4.943656120871369e+307 divide -1.1 2.2250738585072014e-308
		--assert strict-equal? -4.943656120871369e+307 i / j
		--assert strict-equal? -4.943656120871369e+307 divide i j

	--test-- "float-divide 85"
		i: -1.1
		j: -2.2250738585072014e-308
		--assert strict-equal? 4.943656120871369e+307 -1.1 / -2.2250738585072014e-308
		--assert strict-equal? 4.943656120871369e+307 divide -1.1 -2.2250738585072014e-308
		--assert strict-equal? 4.943656120871369e+307 i / j
		--assert strict-equal? 4.943656120871369e+307 divide i j

	--test-- "float-divide 86"
		i: -1.1
		j: 1.7976931348623157e+308
		--assert strict-equal? -6.118953110894807e-309 -1.1 / 1.7976931348623157e+308
		--assert strict-equal? -6.118953110894807e-309 divide -1.1 1.7976931348623157e+308
		--assert strict-equal? -6.118953110894807e-309 i / j
		--assert strict-equal? -6.118953110894807e-309 divide i j

	--test-- "float-divide 87"
		i: -1.1
		j: -1.7976931348623157e+308
		--assert strict-equal? 6.118953110894807e-309 -1.1 / -1.7976931348623157e+308
		--assert strict-equal? 6.118953110894807e-309 divide -1.1 -1.7976931348623157e+308
		--assert strict-equal? 6.118953110894807e-309 i / j
		--assert strict-equal? 6.118953110894807e-309 divide i j

	--test-- "float-divide 88"
		i: -1.1
		j: 1.1
		--assert strict-equal? -1.0 -1.1 / 1.1
		--assert strict-equal? -1.0 divide -1.1 1.1
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 89"
		i: -1.1
		j: 1.7976931348623157e+308
		--assert strict-equal? -6.118953110894807e-309 -1.1 / 1.7976931348623157e+308
		--assert strict-equal? -6.118953110894807e-309 divide -1.1 1.7976931348623157e+308
		--assert strict-equal? -6.118953110894807e-309 i / j
		--assert strict-equal? -6.118953110894807e-309 divide i j

	--test-- "float-divide 90"
		i: -1.1
		j: -1.7976931348623157e+308
		--assert strict-equal? 6.118953110894807e-309 -1.1 / -1.7976931348623157e+308
		--assert strict-equal? 6.118953110894807e-309 divide -1.1 -1.7976931348623157e+308
		--assert strict-equal? 6.118953110894807e-309 i / j
		--assert strict-equal? 6.118953110894807e-309 divide i j

	--test-- "float-divide 91"
		i: 1.7976931348623157e+308
		j: 0.0
		;--assert strict-equal? 1.#INF 1.7976931348623157e+308 / 0.0
		;--assert strict-equal? 1.#INF divide 1.7976931348623157e+308 0.0
		;--assert strict-equal? 1.#INF i / j
		;--assert strict-equal? 1.#INF divide i j

	--test-- "float-divide 92"
		i: 1.7976931348623157e+308
		j: 1.0
		--assert strict-equal? 1.7976931348623157e+308 1.7976931348623157e+308 / 1.0
		--assert strict-equal? 1.7976931348623157e+308 divide 1.7976931348623157e+308 1.0
		--assert strict-equal? 1.7976931348623157e+308 i / j
		--assert strict-equal? 1.7976931348623157e+308 divide i j

	--test-- "float-divide 93"
		i: 1.7976931348623157e+308
		j: -1.0
		--assert strict-equal? -1.7976931348623157e+308 1.7976931348623157e+308 / -1.0
		--assert strict-equal? -1.7976931348623157e+308 divide 1.7976931348623157e+308 -1.0
		--assert strict-equal? -1.7976931348623157e+308 i / j
		--assert strict-equal? -1.7976931348623157e+308 divide i j

	--test-- "float-divide 94"
		i: 1.7976931348623157e+308
		j: 2.2250738585072014e-308
		--assert strict-equal? 1.#INF 1.7976931348623157e+308 / 2.2250738585072014e-308
		--assert strict-equal? 1.#INF divide 1.7976931348623157e+308 2.2250738585072014e-308
		--assert strict-equal? 1.#INF i / j
		--assert strict-equal? 1.#INF divide i j

	--test-- "float-divide 95"
		i: 1.7976931348623157e+308
		j: -2.2250738585072014e-308
		--assert strict-equal? -1.#INF 1.7976931348623157e+308 / -2.2250738585072014e-308
		--assert strict-equal? -1.#INF divide 1.7976931348623157e+308 -2.2250738585072014e-308
		--assert strict-equal? -1.#INF i / j
		--assert strict-equal? -1.#INF divide i j

	--test-- "float-divide 96"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.0 1.7976931348623157e+308 / 1.7976931348623157e+308
		--assert strict-equal? 1.0 divide 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 97"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.0 1.7976931348623157e+308 / -1.7976931348623157e+308
		--assert strict-equal? -1.0 divide 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 98"
		i: 1.7976931348623157e+308
		j: 1.1
		--assert strict-equal? 1.6342664862384688e+308 1.7976931348623157e+308 / 1.1
		--assert strict-equal? 1.6342664862384688e+308 divide 1.7976931348623157e+308 1.1
		--assert strict-equal? 1.6342664862384688e+308 i / j
		--assert strict-equal? 1.6342664862384688e+308 divide i j

	--test-- "float-divide 99"
		i: 1.7976931348623157e+308
		j: -1.1
		--assert strict-equal? -1.6342664862384688e+308 1.7976931348623157e+308 / -1.1
		--assert strict-equal? -1.6342664862384688e+308 divide 1.7976931348623157e+308 -1.1
		--assert strict-equal? -1.6342664862384688e+308 i / j
		--assert strict-equal? -1.6342664862384688e+308 divide i j

	--test-- "float-divide 100"
		i: 1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? -1.0 1.7976931348623157e+308 / -1.7976931348623157e+308
		--assert strict-equal? -1.0 divide 1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 101"
		i: -1.7976931348623157e+308
		j: 0.0
		;--assert strict-equal? -1.#INF -1.7976931348623157e+308 / 0.0
		;--assert strict-equal? -1.#INF divide -1.7976931348623157e+308 0.0
		;--assert strict-equal? -1.#INF i / j
		;--assert strict-equal? -1.#INF divide i j

	--test-- "float-divide 102"
		i: -1.7976931348623157e+308
		j: 1.0
		--assert strict-equal? -1.7976931348623157e+308 -1.7976931348623157e+308 / 1.0
		--assert strict-equal? -1.7976931348623157e+308 divide -1.7976931348623157e+308 1.0
		--assert strict-equal? -1.7976931348623157e+308 i / j
		--assert strict-equal? -1.7976931348623157e+308 divide i j

	--test-- "float-divide 103"
		i: -1.7976931348623157e+308
		j: -1.0
		--assert strict-equal? 1.7976931348623157e+308 -1.7976931348623157e+308 / -1.0
		--assert strict-equal? 1.7976931348623157e+308 divide -1.7976931348623157e+308 -1.0
		--assert strict-equal? 1.7976931348623157e+308 i / j
		--assert strict-equal? 1.7976931348623157e+308 divide i j

	--test-- "float-divide 104"
		i: -1.7976931348623157e+308
		j: 2.2250738585072014e-308
		--assert strict-equal? -1.#INF -1.7976931348623157e+308 / 2.2250738585072014e-308
		--assert strict-equal? -1.#INF divide -1.7976931348623157e+308 2.2250738585072014e-308
		--assert strict-equal? -1.#INF i / j
		--assert strict-equal? -1.#INF divide i j

	--test-- "float-divide 105"
		i: -1.7976931348623157e+308
		j: -2.2250738585072014e-308
		--assert strict-equal? 1.#INF -1.7976931348623157e+308 / -2.2250738585072014e-308
		--assert strict-equal? 1.#INF divide -1.7976931348623157e+308 -2.2250738585072014e-308
		--assert strict-equal? 1.#INF i / j
		--assert strict-equal? 1.#INF divide i j

	--test-- "float-divide 106"
		i: -1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.0 -1.7976931348623157e+308 / 1.7976931348623157e+308
		--assert strict-equal? -1.0 divide -1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 107"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.0 -1.7976931348623157e+308 / -1.7976931348623157e+308
		--assert strict-equal? 1.0 divide -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 108"
		i: -1.7976931348623157e+308
		j: 1.1
		--assert strict-equal? -1.6342664862384688e+308 -1.7976931348623157e+308 / 1.1
		--assert strict-equal? -1.6342664862384688e+308 divide -1.7976931348623157e+308 1.1
		--assert strict-equal? -1.6342664862384688e+308 i / j
		--assert strict-equal? -1.6342664862384688e+308 divide i j

	--test-- "float-divide 109"
		i: -1.7976931348623157e+308
		j: -1.1
		--assert strict-equal? 1.6342664862384688e+308 -1.7976931348623157e+308 / -1.1
		--assert strict-equal? 1.6342664862384688e+308 divide -1.7976931348623157e+308 -1.1
		--assert strict-equal? 1.6342664862384688e+308 i / j
		--assert strict-equal? 1.6342664862384688e+308 divide i j

	--test-- "float-divide 110"
		i: -1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? -1.0 -1.7976931348623157e+308 / 1.7976931348623157e+308
		--assert strict-equal? -1.0 divide -1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? -1.0 i / j
		--assert strict-equal? -1.0 divide i j

	--test-- "float-divide 111"
		i: 0.0
		j: 0.0
		;--assert strict-equal? 1.#NAN 0.0 / 0.0
		;--assert strict-equal? 1.#NAN divide 0.0 0.0
		;--assert strict-equal? 1.#NAN i / j
		;--assert strict-equal? 1.#NAN divide i j

	--test-- "float-divide 112"
		i: 1.0
		j: 1.0
		--assert strict-equal? 1.0 1.0 / 1.0
		--assert strict-equal? 1.0 divide 1.0 1.0
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 113"
		i: -1.0
		j: -1.0
		--assert strict-equal? 1.0 -1.0 / -1.0
		--assert strict-equal? 1.0 divide -1.0 -1.0
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 114"
		i: 2.2250738585072014e-308
		j: 2.2250738585072014e-308
		--assert strict-equal? 1.0 2.2250738585072014e-308 / 2.2250738585072014e-308
		--assert strict-equal? 1.0 divide 2.2250738585072014e-308 2.2250738585072014e-308
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 115"
		i: -2.2250738585072014e-308
		j: -2.2250738585072014e-308
		--assert strict-equal? 1.0 -2.2250738585072014e-308 / -2.2250738585072014e-308
		--assert strict-equal? 1.0 divide -2.2250738585072014e-308 -2.2250738585072014e-308
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 116"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.0 1.7976931348623157e+308 / 1.7976931348623157e+308
		--assert strict-equal? 1.0 divide 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 117"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.0 -1.7976931348623157e+308 / -1.7976931348623157e+308
		--assert strict-equal? 1.0 divide -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 118"
		i: 1.1
		j: 1.1
		--assert strict-equal? 1.0 1.1 / 1.1
		--assert strict-equal? 1.0 divide 1.1 1.1
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 119"
		i: -1.1
		j: -1.1
		--assert strict-equal? 1.0 -1.1 / -1.1
		--assert strict-equal? 1.0 divide -1.1 -1.1
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 120"
		i: 1.7976931348623157e+308
		j: 1.7976931348623157e+308
		--assert strict-equal? 1.0 1.7976931348623157e+308 / 1.7976931348623157e+308
		--assert strict-equal? 1.0 divide 1.7976931348623157e+308 1.7976931348623157e+308
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

	--test-- "float-divide 121"
		i: -1.7976931348623157e+308
		j: -1.7976931348623157e+308
		--assert strict-equal? 1.0 -1.7976931348623157e+308 / -1.7976931348623157e+308
		--assert strict-equal? 1.0 divide -1.7976931348623157e+308 -1.7976931348623157e+308
		--assert strict-equal? 1.0 i / j
		--assert strict-equal? 1.0 divide i j

===end-group===

===start-group=== "floatcomparisons"

	--test-- "= 1"					--assert 0.0 = 0.0
	--test-- "= 2"					--assert not 1.0 = 0.0
	--test-- "= 3"					--assert not -1.0 = 0.0
	--test-- "= 4"					--assert not 1.7976931348623157e+308 = -1.7976931348623157e+308
	--test-- "= 5"					--assert 1.7976931348623157e+308 = 1.7976931348623157e+308
	--test-- "= 6"					--assert 2.2250738585072014e-308 = 2.2250738585072014e-308
	--test-- "equal? 1"				--assert equal? 0.0 0.0
	--test-- "equal? 2"				--assert not equal? 1.0 0.0
	--test-- "equal? 3"				--assert equal? 2.2250738585072014e-308 -2.2250738585072014e-308
	--test-- "equal? 4"				--assert not equal? 1.7976931348623157e+308 -1.7976931348623157e+308
	--test-- "== 1"					--assert 0.0 == 0.0
	--test-- "== 2"					--assert not 1.0 == 0.0
	--test-- "== 3"					--assert not -1.0 == 0.0
	--test-- "== 4"					--assert not 1.7976931348623157e+308 == -1.7976931348623157e+308
	--test-- "== 5"					--assert 1.7976931348623157e+308 == 1.7976931348623157e+308
	--test-- "== 6"					--assert 2.2250738585072014e-308 == 2.2250738585072014e-308
	--test-- "strict-equal? 1"		--assert strict-equal? 0.0 0.0
	--test-- "strict-equal? 2"		--assert not strict-equal? 1.0 0.0
	--test-- "strict-equal? 3"		--assert not strict-equal? 2.2250738585072014e-308 -2.2250738585072014e-308
	--test-- "strict-equal? 4"		--assert not strict-equal? 1.7976931348623157e+308 -1.7976931348623157e+308
	--test-- "<> 1"					--assert not 0.0 <> 0.0
	--test-- "<> 2"					--assert 1.0 <> 0.0
	--test-- "<> 3"					--assert -1.0 <> 0.0
	--test-- "<> 4"					--assert not 2.2250738585072014e-308 <> -2.2250738585072014e-308
	--test-- "<> 5"					--assert 1.7976931348623157e+308 <> -1.7976931348623157e+308
	--test-- "not equal? 1"			--assert not not-equal? 0.0  0.0
	--test-- "not equal? 2"			--assert not-equal? 1.0 0.0
	--test-- "not equal? 3"			--assert not-equal? -1.0 0.0
	--test-- "not equal? 4"			--assert not not-equal? 2.2250738585072014e-308 -2.2250738585072014e-308
	--test-- "not equal? 5"			--assert not-equal? 1.7976931348623157e+308 -1.7976931348623157e+308
	--test-- "> 1"					--assert not 0.0 > 0.0
	--test-- "> 2"					--assert 2.2250738585072014e-308 > 0.0
	--test-- "> 3"					--assert 0.0 > -2.2250738585072014e-308
	--test-- "> 4"					--assert 2.2250738585072020e-308 > 2.2250738585072014e-308
	--test-- "greater? 1"			--assert not greater? 0.0 0.0
	--test-- "greater? 2"			--assert greater? 1.7976931348623157e+308 0.0
	--test-- "greater? 3"			--assert greater? 0.0 -2.2250738585072014e-308
	--test-- "greater? 4"			--assert greater? 1.7976931348623156e+308 1.7976931348623150e+308
	--test-- "< 1"					--assert not 0.0 < 0.0
	--test-- "< 2"					--assert 0.0 < 2.2250738585072014e-308
	--test-- "< 3"					--assert -2.2250738585072014e-308 < 0.0
	--test-- "< 4"					--assert 2.2250738585072014e-308 < 2.225073858507202e-308
	--test-- "lesser? 1"			--assert not lesser? 0.0 0.0
	--test-- "lesser? 2"			--assert lesser? 0.0 2.2250738585072014e-308
	--test-- "lesser? 3"			--assert lesser? -2.2250738585072014e-308 0.0
	--test-- "lesser? 4"			--assert lesser? 2.2250738585072014e-308 2.225073858507202e-308
	--test-- ">= 1"					--assert 0.0 >= 0.0
	--test-- ">= 2"					--assert 1.0 >= 0.0
	--test-- ">= 3"					--assert 0.0 >= -1.0
	--test-- ">= 4"					--assert 2.2250738585072014e-308 >= 2.2250738585072014e-308
	--test-- " greater-or-equal? 1"	--assert greater-or-equal? 0.0 0.0
	--test-- " greater-or-equal? 2"	--assert greater-or-equal? 1.0 0.0
	--test-- " greater-or-equal? 3"	--assert greater-or-equal? 0.0 -1.0
	--test-- " greater-or-equal? 4"	--assert greater-or-equal? 2.2250738585072014e-308 2.2250738585072014e-308
	--test-- "<= 1"					--assert 0.0 <= 0.0
	--test-- "<= 2"					--assert 0.0 <= 1.0
	--test-- "<= 3"					--assert -1.0 <= 0.0
	--test-- "<= 4"					--assert 1.7976931348623157e+308 <= 1.7976931348623157e+308
	--test-- " lesser-or-equal? 1"	--assert lesser-or-equal? 0.0 0.0
	--test-- " lesser-or-equal? 2"	--assert lesser-or-equal? 0.0 1.0
	--test-- " lesser-or-equal? 3"	--assert lesser-or-equal? -1.0 0.0
	--test-- " lesser-or-equal? 4"	--assert lesser-or-equal? 1.7976931348623157e+308 1.7976931348623157e+308
		
===end-group===

~~~end-file~~~
