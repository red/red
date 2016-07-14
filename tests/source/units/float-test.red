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
	--test-- "special-arithmetic-2"  --assert error? try [to string! 1.0 / 0.0]
	--test-- "special-arithmetic-3"  --assert error? try [to string! -1.0 / 0.0]
	--test-- "special-arithmetic-4"  --assert error? try [to string! 0.0 / 0.0]
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

~~~end-file~~~
