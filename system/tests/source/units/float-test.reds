Red/System [
	Title:   "Red/System integer! datatype tests"
	Author:  "Peter W A Wood, Nenad Rakocevic"
	File: 	 %float-test.reds
	Version: 0.1.0
	Tabs:	 4
	Rights:  "Copyright (C) 2012-2015 Peter W A Wood, Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "float"

===start-group=== "float assignment"
	--test-- "float-1"
		f: 100.0
		--assert f = 100.0
	--test-- "float-2"
		f: 1.222090944E+33
		--assert f = 1.222090944E+33
	--test-- "float-3"
		f: 9.99999E-45
		--assert f = 9.99999E-45
	--test-- "float-4"
		f: 1.0
		f1: f
		--assert f1 = 1.0
===end-group===

===start-group=== "float argument to external function"
	
	--test-- "float-ext-1"
		--assert -1.0 = cos pi
	
	--test-- "float-ext-2"
		--assertf~= 0.0 sin pi 1E-12
	
	--test-- "float-ext-3"
		--assert -1.0 = cos 3.14159265358979
	
===end-group===

===start-group=== "float function arguments"
	ff: func [
		fff     [float!]
		ffg     [float!]
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
		f: local-float pi
		--assert pi = local-float f
	
	--test-- "float-loc-3"
		local-float2: func [
			n [float!] return: [float!] /local p
		][
			p: n local-float p
		]
	
		pi: local-float2 3.14159265358979
		--assert -1.0 = local-float2 cos pi
		f: local-float2 pi
		--assert pi = local-float2 f
	
	--test-- "float-loc-4"
		local-float3: func [
			n [float!] return: [float!] /local p [float!]
		][
			p: n local-float p
		]
	
		pi: local-float3 3.14159265358979
		--assert -1.0 = local-float3 cos pi
		f: local-float3 pi
		--assert pi = local-float3 f
	
	--test-- "float-loc-5"
		local-float4: func [n [float!] return: [float!] /local r p][p: n p]
		--assert -1.0 = local-float4 cos pi
		f: local-float4 pi
		--assert pi = local-float4 f
	
	--test-- "float-loc-6"
		local-float5: func [n [float!] return: [float!] /local r p][p: n local-float p]
		--assert -1.0 = local-float5 cos pi
		f: local-float5 pi
		--assert pi = local-float5 f

===end-group===

===start-group=== "float function return"

 
		ff1: func [
		  ff1i      [integer!]
		  return:   [float!]
		][
		  switch ff1i [
		    1 [1.0]
		    2 [1.222090944E+33]
		    3 [9.99999E-45]
		  ]
		]
	--test-- "float return 1" 		--assert 1.0 = ff1 1
	--test-- "float return 2"		--assert 1.222090944E+33 = ff1 2
	--test-- "float return 3"		--assert 9.99999E-45 = ff1 3

===end-group===

===start-group=== "float members in struct"

	--test-- "float-struct-1"
		  sf1: declare struct! [
		    a   [float!]
		  ]
		  
		--assert 0.0 = sf1/a
	
	--test-- "float-struct-2"
		  sf2: declare struct! [
		    a   [float!]
		  ]
		  
		  sf1/a: 1.222090944E+33
		--assert 1.222090944E+33 = sf1/a
	 
	--test-- "float-struct-3"
		sf3: declare struct! [
		  a   [float!]
		  b   [float!]
		]
		
		sf3/a: 1.222090944E+33
		sf3/b: 9.99999E-45
		--assert 1.222090944E+33 = sf3/a
		--assert 9.99999E-45 = sf3/b
	  
	--test-- "float-struct-4"
		sf4: declare struct! [
		  c   [byte!]
		  a   [float!]
		  l   [logic!]
		  b   [float!]
		]
		
		sf4/a: 1.222090944E+33
		sf4/b: 9.99999E-45
		--assert 1.222090944E+33 = sf4/a
		--assert 9.99999E-45 = sf4/b
	
	--test-- "float-struct-5"
			sf5: declare struct! [f [float!] i [integer!]]
			
			sf5/i: 1234567890
			sf5/f: 3.14159265358979
			--assert sf5/i = 1234567890
			--assert sf5/f = pi
			
	--test-- "float-struct-6"
	sf6: declare struct! [i [integer!] f [float!]]
	
	sf6/i: 1234567890
	sf6/f: 3.14159265358979
	--assert sf6/i = 1234567890
	--assert sf6/f = pi

===end-group===

===start-group=== "float pointers"

	--test-- "float-point-1"
		pi: 3.14159265358979
		p: declare pointer! [float!]
		p/value: 3.14159265358979
		--assert pi = p/value

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
  
	--test-- "ewrfv0"			--assertf~= 1.0 (fe1 * 1.0) 0.1E-13 
	--test-- "ewrfv1"			--assertf~= 1.0 (1.0 * fe1) 0.1E-13
	--test-- "ewrfv2"			 --assertf~= 0.5 (fe1 / fe2) 0.1E-13

===end-group===

 ===start-group=== "float arguments to typed functions"
		fatf1: function [
			[typed]
			count [integer!]
			list [typed-float!]
			return: [float!]
			/local
			  a [float!]
		][
			a: list/value
			a
		]
		
		fatf2: function [
			[typed]
			count [integer!]
			list [typed-float!]
			return: [float!]
			/local
			  a [float!]
			  b [float!]
		][
			a: list/value 
			list: list + 1
			b: list/value
			a + b
		]
		
	--test-- "fatf-1"			--assert 2.0 = fatf1 2.0
	--test-- "fatf-2"			--assert 2.0 = fatf1 1.0 + fatf1 1.0
	--test-- "fatf-3"			--assert 3.0 = fatf2 [1.0 2.0]
  
===end-group===

===start-group=== "calculations"

		fcfoo: func [a [float!] return: [float!]][a]
		
		fcptr: declare struct! [a [float!]]
		fcptr/a: 3.0 
		
		fc2: 3.0
		
	--test-- "fc-1"
		fc1: 2.0
		fc1: fc1 / (fc1 - 1.0)
		--assertf~= 2.0 fc1 0.1E-13
	
	--test-- "fc-2"
		--assert 5.0 - 3.0 = 2.0						;-- imm/imm
	
	--test-- "fc-3"
		--assert 5.0 - fc2 = 2.0						;-- imm/ref
	
	--test-- "fc-4"
		--assert 5.0 - (fcfoo 3.0) = 2.0				;-- imm/reg(block!)
	
	--test-- "fc-5"
		--assertf~= 5.0 - fcptr/a 2.0 1E-10				;-- imm/reg(path!)
	
	--test-- "fc-6"
		--assert fc2 - 5.0 = -2.0						;-- ref/imm
	
	--test-- "fc-7"
		--assert fc2 - (fcfoo 5.0) = -2.0				;-- ref/reg(block!)
	
	--test-- "fc-8"
		--assert fc2 - fcptr/a = 0.0					;-- ref/reg(path!)
	
	--test-- "fc-9"
		--assertf~= (fcfoo 5.0) - 3.0 2.0 1E-10			;-- reg(block!)/imm
	
	--test-- "fc-10"
		--assert (fcfoo 5.0) - (fcfoo 3.0) = 2.0		;-- reg(block!)/reg(block!)
	
	--test-- "fc-11"
		--assert (fcfoo 5.0) - fcptr/a = 2.0			;-- reg(block!)/reg(path!)
	
	--test-- "fc-12"
		--assert fcptr/a - (fcfoo 5.0) = -2.0			;-- reg(path!)/reg(block!)
	
===end-group===

===start-group=== "various regression tests from bugtracker"

	--test-- "issue #227"
		t: 2.2
		ss: declare struct! [v [float!]]
		ss/v: 2.0
		--assertf~= t - ss/v 0.2 1E-10

	--test-- "issue #226"
		number: 10
		array: declare pointer! [byte!]
		array: as byte-ptr! :number
		value: as integer! array/value
		--assert (10 * as integer! array/value) = 100

	--test-- "issue #225"
		j: 1.0
		f: 1.0
		data: declare pointer! [float!]
		data: :f
		while [j < 10.0][
			data/value: j
			j
			j: j + 1.0
		]
		--assertf~= j 10.0 1E-10

	--test-- "issue #223"
		a: as pointer! [float!] allocate 10 * size? float!
		i: 1
		f: 1.0
		while [i <= 10][
			f: f * 0.8
			;print [f lf]
			a/i: f 
			i: i + 1
		]
		--assert i = 11

	--test-- "issue #222"
		s: declare struct! [value [float!]]
		s/value: 1.0
		a: as pointer! [float!] allocate 100 * size? float!
		a/1: s/value    					; value must be in struct!
		a/1: s/value    					; must be done twice
		1.0 + 1.0       					; must be followed by an expression
		if true [a/1: s/value] 
		--assertf~= a/1 1.0 1E-10

	--test-- "issue #221"
		x: -1.0
		y: either x < 0.0 [0.0 - x][x]
		--assert y = 1.0
		
		fabs: func [x [float!] return: [float!] ][
		    either x < 0.0 [0.0 - x][x]
		]
		--assert 3.14 = fabs -3.14

===end-group===

===start-group=== "Arithmetic & Comparison"

  --test-- "float-auto-1"
  --assertf~= 0.0  ( 0.0 + 0.0 )  1E-4 
  --test-- "float-auto-2"
      fat-i: 0.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-3"
  --assertf~= -2147483648.0  ( 0.0 + -2147483648.0 )  1E-4 
  --test-- "float-auto-4"
      fat-i: 0.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
  --assertf~= -2147483648.0  fat-k  1E-4 
  --test-- "float-auto-5"
  --assertf~= 2147483647.0  ( 0.0 + 2147483647.0 )  1E-4 
  --test-- "float-auto-6"
      fat-i: 0.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
  --assertf~= 2147483647.0  fat-k  1E-4 
  --test-- "float-auto-7"
  --assertf~= -1.0  ( 0.0 + -1.0 )  1E-4 
  --test-- "float-auto-8"
      fat-i: 0.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
  --assertf~= -1.0  fat-k  1E-4 
  --test-- "float-auto-9"
  --assertf~= 3.0  ( 0.0 + 3.0 )  1E-4 
  --test-- "float-auto-10"
      fat-i: 0.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
  --assertf~= 3.0  fat-k  1E-4 
  --test-- "float-auto-11"
  --assertf~= -7.0  ( 0.0 + -7.0 )  1E-4 
  --test-- "float-auto-12"
      fat-i: 0.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
  --assertf~= -7.0  fat-k  1E-4 
  --test-- "float-auto-13"
  --assertf~= 5.0  ( 0.0 + 5.0 )  1E-4 
  --test-- "float-auto-14"
      fat-i: 0.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
  --assertf~= 5.0  fat-k  1E-4 
  --test-- "float-auto-15"
  --assertf~= 123456.789  ( 0.0 + 123456.789 )  1E-4 
  --test-- "float-auto-16"
      fat-i: 0.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
  --assertf~= 123456.789  fat-k  1E-4 
  --test-- "float-auto-17"
  --assertf~= 1.222090944E+33  ( 0.0 + 1.222090944E+33 )  1E-4 
  --test-- "float-auto-18"
      fat-i: 0.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-19"
  --assertf~= 9.99999E-45  ( 0.0 + 9.99999E-45 )  1E-4 
  --test-- "float-auto-20"
      fat-i: 0.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
  --assertf~= 9.99999E-45  fat-k  1E-4 
  --test-- "float-auto-21"
  --assertf~= 7.7E+18  ( 0.0 + 7.7E+18 )  1E-4 
  --test-- "float-auto-22"
      fat-i: 0.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-23"
  --assertf~= -2147483648.0  ( -2147483648.0 + 0.0 )  1E-4 
  --test-- "float-auto-24"
      fat-i: -2147483648.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
  --assertf~= -2147483648.0  fat-k  1E-4 
  --test-- "float-auto-25"
  --assertf~= -4294967296.0  ( -2147483648.0 + -2147483648.0 )  1E-4 
  --test-- "float-auto-26"
      fat-i: -2147483648.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
  --assertf~= -4294967296.0  fat-k  1E-4 
  --test-- "float-auto-27"
  --assertf~= -1.0  ( -2147483648.0 + 2147483647.0 )  1E-4 
  --test-- "float-auto-28"
      fat-i: -2147483648.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
  --assertf~= -1.0  fat-k  1E-4 
  --test-- "float-auto-29"
  --assertf~= -2147483649.0  ( -2147483648.0 + -1.0 )  1E-4 
  --test-- "float-auto-30"
      fat-i: -2147483648.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
  --assertf~= -2147483649.0  fat-k  1E-4 
  --test-- "float-auto-31"
  --assertf~= -2147483645.0  ( -2147483648.0 + 3.0 )  1E-4 
  --test-- "float-auto-32"
      fat-i: -2147483648.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
  --assertf~= -2147483645.0  fat-k  1E-4 
  --test-- "float-auto-33"
  --assertf~= -2147483655.0  ( -2147483648.0 + -7.0 )  1E-4 
  --test-- "float-auto-34"
      fat-i: -2147483648.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
  --assertf~= -2147483655.0  fat-k  1E-4 
  --test-- "float-auto-35"
  --assertf~= -2147483643.0  ( -2147483648.0 + 5.0 )  1E-4 
  --test-- "float-auto-36"
      fat-i: -2147483648.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
  --assertf~= -2147483643.0  fat-k  1E-4 
  --test-- "float-auto-37"
  --assertf~= -2147360191.211  ( -2147483648.0 + 123456.789 )  1E-4 
  --test-- "float-auto-38"
      fat-i: -2147483648.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
  --assertf~= -2147360191.211  fat-k  1E-4 
  --test-- "float-auto-39"
  --assertf~= 1.222090944E+33  ( -2147483648.0 + 1.222090944E+33 )  1E-4 
  --test-- "float-auto-40"
      fat-i: -2147483648.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-41"
  --assertf~= -2147483648.0  ( -2147483648.0 + 9.99999E-45 )  1E-4 
  --test-- "float-auto-42"
      fat-i: -2147483648.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
  --assertf~= -2147483648.0  fat-k  1E-4 
  --test-- "float-auto-43"
  --assertf~= 7.69999999785252E+18  ( -2147483648.0 + 7.7E+18 )  1E-4 
  --test-- "float-auto-44"
      fat-i: -2147483648.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
  --assertf~= 7.69999999785252E+18  fat-k  1E-4 
  --test-- "float-auto-45"
  --assertf~= 2147483647.0  ( 2147483647.0 + 0.0 )  1E-4 
  --test-- "float-auto-46"
      fat-i: 2147483647.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
  --assertf~= 2147483647.0  fat-k  1E-4 
  --test-- "float-auto-47"
  --assertf~= -1.0  ( 2147483647.0 + -2147483648.0 )  1E-4 
  --test-- "float-auto-48"
      fat-i: 2147483647.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
  --assertf~= -1.0  fat-k  1E-4 
  --test-- "float-auto-49"
  --assertf~= 4294967294.0  ( 2147483647.0 + 2147483647.0 )  1E-4 
  --test-- "float-auto-50"
      fat-i: 2147483647.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
  --assertf~= 4294967294.0  fat-k  1E-4 
  --test-- "float-auto-51"
  --assertf~= 2147483646.0  ( 2147483647.0 + -1.0 )  1E-4 
  --test-- "float-auto-52"
      fat-i: 2147483647.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
  --assertf~= 2147483646.0  fat-k  1E-4 
  --test-- "float-auto-53"
  --assertf~= 2147483650.0  ( 2147483647.0 + 3.0 )  1E-4 
  --test-- "float-auto-54"
      fat-i: 2147483647.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
  --assertf~= 2147483650.0  fat-k  1E-4 
  --test-- "float-auto-55"
  --assertf~= 2147483640.0  ( 2147483647.0 + -7.0 )  1E-4 
  --test-- "float-auto-56"
      fat-i: 2147483647.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
  --assertf~= 2147483640.0  fat-k  1E-4 
  --test-- "float-auto-57"
  --assertf~= 2147483652.0  ( 2147483647.0 + 5.0 )  1E-4 
  --test-- "float-auto-58"
      fat-i: 2147483647.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
  --assertf~= 2147483652.0  fat-k  1E-4 
  --test-- "float-auto-59"
  --assertf~= 2147607103.789  ( 2147483647.0 + 123456.789 )  1E-4 
  --test-- "float-auto-60"
      fat-i: 2147483647.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
  --assertf~= 2147607103.789  fat-k  1E-4 
  --test-- "float-auto-61"
  --assertf~= 1.222090944E+33  ( 2147483647.0 + 1.222090944E+33 )  1E-4 
  --test-- "float-auto-62"
      fat-i: 2147483647.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-63"
  --assertf~= 2147483647.0  ( 2147483647.0 + 9.99999E-45 )  1E-4 
  --test-- "float-auto-64"
      fat-i: 2147483647.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
  --assertf~= 2147483647.0  fat-k  1E-4 
  --test-- "float-auto-65"
  --assertf~= 7.70000000214748E+18  ( 2147483647.0 + 7.7E+18 )  1E-4 
  --test-- "float-auto-66"
      fat-i: 2147483647.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
  --assertf~= 7.70000000214748E+18  fat-k  1E-4 
  --test-- "float-auto-67"
  --assertf~= -1.0  ( -1.0 + 0.0 )  1E-4 
  --test-- "float-auto-68"
      fat-i: -1.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
  --assertf~= -1.0  fat-k  1E-4 
  --test-- "float-auto-69"
  --assertf~= -2147483649.0  ( -1.0 + -2147483648.0 )  1E-4 
  --test-- "float-auto-70"
      fat-i: -1.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
  --assertf~= -2147483649.0  fat-k  1E-4 
  --test-- "float-auto-71"
  --assertf~= 2147483646.0  ( -1.0 + 2147483647.0 )  1E-4 
  --test-- "float-auto-72"
      fat-i: -1.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
  --assertf~= 2147483646.0  fat-k  1E-4 
  --test-- "float-auto-73"
  --assertf~= -2.0  ( -1.0 + -1.0 )  1E-4 
  --test-- "float-auto-74"
      fat-i: -1.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
  --assertf~= -2.0  fat-k  1E-4 
  --test-- "float-auto-75"
  --assertf~= 2.0  ( -1.0 + 3.0 )  1E-4 
  --test-- "float-auto-76"
      fat-i: -1.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
  --assertf~= 2.0  fat-k  1E-4 
  --test-- "float-auto-77"
  --assertf~= -8.0  ( -1.0 + -7.0 )  1E-4 
  --test-- "float-auto-78"
      fat-i: -1.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
  --assertf~= -8.0  fat-k  1E-4 
  --test-- "float-auto-79"
  --assertf~= 4.0  ( -1.0 + 5.0 )  1E-4 
  --test-- "float-auto-80"
      fat-i: -1.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
  --assertf~= 4.0  fat-k  1E-4 
  --test-- "float-auto-81"
  --assertf~= 123455.789  ( -1.0 + 123456.789 )  1E-4 
  --test-- "float-auto-82"
      fat-i: -1.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
  --assertf~= 123455.789  fat-k  1E-4 
  --test-- "float-auto-83"
  --assertf~= 1.222090944E+33  ( -1.0 + 1.222090944E+33 )  1E-4 
  --test-- "float-auto-84"
      fat-i: -1.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-85"
  --assertf~= -1.0  ( -1.0 + 9.99999E-45 )  1E-4 
  --test-- "float-auto-86"
      fat-i: -1.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
  --assertf~= -1.0  fat-k  1E-4 
  --test-- "float-auto-87"
  --assertf~= 7.7E+18  ( -1.0 + 7.7E+18 )  1E-4 
  --test-- "float-auto-88"
      fat-i: -1.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-89"
  --assertf~= 3.0  ( 3.0 + 0.0 )  1E-4 
  --test-- "float-auto-90"
      fat-i: 3.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
  --assertf~= 3.0  fat-k  1E-4 
  --test-- "float-auto-91"
  --assertf~= -2147483645.0  ( 3.0 + -2147483648.0 )  1E-4 
  --test-- "float-auto-92"
      fat-i: 3.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
  --assertf~= -2147483645.0  fat-k  1E-4 
  --test-- "float-auto-93"
  --assertf~= 2147483650.0  ( 3.0 + 2147483647.0 )  1E-4 
  --test-- "float-auto-94"
      fat-i: 3.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
  --assertf~= 2147483650.0  fat-k  1E-4 
  --test-- "float-auto-95"
  --assertf~= 2.0  ( 3.0 + -1.0 )  1E-4 
  --test-- "float-auto-96"
      fat-i: 3.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
  --assertf~= 2.0  fat-k  1E-4 
  --test-- "float-auto-97"
  --assertf~= 6.0  ( 3.0 + 3.0 )  1E-4 
  --test-- "float-auto-98"
      fat-i: 3.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
  --assertf~= 6.0  fat-k  1E-4 
  --test-- "float-auto-99"
  --assertf~= -4.0  ( 3.0 + -7.0 )  1E-4 
  --test-- "float-auto-100"
      fat-i: 3.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
  --assertf~= -4.0  fat-k  1E-4 
  --test-- "float-auto-101"
  --assertf~= 8.0  ( 3.0 + 5.0 )  1E-4 
  --test-- "float-auto-102"
      fat-i: 3.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
  --assertf~= 8.0  fat-k  1E-4 
  --test-- "float-auto-103"
  --assertf~= 123459.789  ( 3.0 + 123456.789 )  1E-4 
  --test-- "float-auto-104"
      fat-i: 3.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
  --assertf~= 123459.789  fat-k  1E-4 
  --test-- "float-auto-105"
  --assertf~= 1.222090944E+33  ( 3.0 + 1.222090944E+33 )  1E-4 
  --test-- "float-auto-106"
      fat-i: 3.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-107"
  --assertf~= 3.0  ( 3.0 + 9.99999E-45 )  1E-4 
  --test-- "float-auto-108"
      fat-i: 3.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
  --assertf~= 3.0  fat-k  1E-4 
  --test-- "float-auto-109"
  --assertf~= 7.7E+18  ( 3.0 + 7.7E+18 )  1E-4 
  --test-- "float-auto-110"
      fat-i: 3.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-111"
  --assertf~= -7.0  ( -7.0 + 0.0 )  1E-4 
  --test-- "float-auto-112"
      fat-i: -7.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
  --assertf~= -7.0  fat-k  1E-4 
  --test-- "float-auto-113"
  --assertf~= -2147483655.0  ( -7.0 + -2147483648.0 )  1E-4 
  --test-- "float-auto-114"
      fat-i: -7.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
  --assertf~= -2147483655.0  fat-k  1E-4 
  --test-- "float-auto-115"
  --assertf~= 2147483640.0  ( -7.0 + 2147483647.0 )  1E-4 
  --test-- "float-auto-116"
      fat-i: -7.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
  --assertf~= 2147483640.0  fat-k  1E-4 
  --test-- "float-auto-117"
  --assertf~= -8.0  ( -7.0 + -1.0 )  1E-4 
  --test-- "float-auto-118"
      fat-i: -7.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
  --assertf~= -8.0  fat-k  1E-4 
  --test-- "float-auto-119"
  --assertf~= -4.0  ( -7.0 + 3.0 )  1E-4 
  --test-- "float-auto-120"
      fat-i: -7.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
  --assertf~= -4.0  fat-k  1E-4 
  --test-- "float-auto-121"
  --assertf~= -14.0  ( -7.0 + -7.0 )  1E-4 
  --test-- "float-auto-122"
      fat-i: -7.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
  --assertf~= -14.0  fat-k  1E-4 
  --test-- "float-auto-123"
  --assertf~= -2.0  ( -7.0 + 5.0 )  1E-4 
  --test-- "float-auto-124"
      fat-i: -7.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
  --assertf~= -2.0  fat-k  1E-4 
  --test-- "float-auto-125"
  --assertf~= 123449.789  ( -7.0 + 123456.789 )  1E-4 
  --test-- "float-auto-126"
      fat-i: -7.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
  --assertf~= 123449.789  fat-k  1E-4 
  --test-- "float-auto-127"
  --assertf~= 1.222090944E+33  ( -7.0 + 1.222090944E+33 )  1E-4 
  --test-- "float-auto-128"
      fat-i: -7.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-129"
  --assertf~= -7.0  ( -7.0 + 9.99999E-45 )  1E-4 
  --test-- "float-auto-130"
      fat-i: -7.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
  --assertf~= -7.0  fat-k  1E-4 
  --test-- "float-auto-131"
  --assertf~= 7.7E+18  ( -7.0 + 7.7E+18 )  1E-4 
  --test-- "float-auto-132"
      fat-i: -7.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-133"
  --assertf~= 5.0  ( 5.0 + 0.0 )  1E-4 
  --test-- "float-auto-134"
      fat-i: 5.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
  --assertf~= 5.0  fat-k  1E-4 
  --test-- "float-auto-135"
  --assertf~= -2147483643.0  ( 5.0 + -2147483648.0 )  1E-4 
  --test-- "float-auto-136"
      fat-i: 5.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
  --assertf~= -2147483643.0  fat-k  1E-4 
  --test-- "float-auto-137"
  --assertf~= 2147483652.0  ( 5.0 + 2147483647.0 )  1E-4 
  --test-- "float-auto-138"
      fat-i: 5.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
  --assertf~= 2147483652.0  fat-k  1E-4 
  --test-- "float-auto-139"
  --assertf~= 4.0  ( 5.0 + -1.0 )  1E-4 
  --test-- "float-auto-140"
      fat-i: 5.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
  --assertf~= 4.0  fat-k  1E-4 
  --test-- "float-auto-141"
  --assertf~= 8.0  ( 5.0 + 3.0 )  1E-4 
  --test-- "float-auto-142"
      fat-i: 5.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
  --assertf~= 8.0  fat-k  1E-4 
  --test-- "float-auto-143"
  --assertf~= -2.0  ( 5.0 + -7.0 )  1E-4 
  --test-- "float-auto-144"
      fat-i: 5.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
  --assertf~= -2.0  fat-k  1E-4 
  --test-- "float-auto-145"
  --assertf~= 10.0  ( 5.0 + 5.0 )  1E-4 
  --test-- "float-auto-146"
      fat-i: 5.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
  --assertf~= 10.0  fat-k  1E-4 
  --test-- "float-auto-147"
  --assertf~= 123461.789  ( 5.0 + 123456.789 )  1E-4 
  --test-- "float-auto-148"
      fat-i: 5.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
  --assertf~= 123461.789  fat-k  1E-4 
  --test-- "float-auto-149"
  --assertf~= 1.222090944E+33  ( 5.0 + 1.222090944E+33 )  1E-4 
  --test-- "float-auto-150"
      fat-i: 5.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-151"
  --assertf~= 5.0  ( 5.0 + 9.99999E-45 )  1E-4 
  --test-- "float-auto-152"
      fat-i: 5.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
  --assertf~= 5.0  fat-k  1E-4 
  --test-- "float-auto-153"
  --assertf~= 7.7E+18  ( 5.0 + 7.7E+18 )  1E-4 
  --test-- "float-auto-154"
      fat-i: 5.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-155"
  --assertf~= 123456.789  ( 123456.789 + 0.0 )  1E-4 
  --test-- "float-auto-156"
      fat-i: 123456.789
      fat-j: 0.0
      fat-k:  fat-i + fat-j
  --assertf~= 123456.789  fat-k  1E-4 
  --test-- "float-auto-157"
  --assertf~= -2147360191.211  ( 123456.789 + -2147483648.0 )  1E-4 
  --test-- "float-auto-158"
      fat-i: 123456.789
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
  --assertf~= -2147360191.211  fat-k  1E-4 
  --test-- "float-auto-159"
  --assertf~= 2147607103.789  ( 123456.789 + 2147483647.0 )  1E-4 
  --test-- "float-auto-160"
      fat-i: 123456.789
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
  --assertf~= 2147607103.789  fat-k  1E-4 
  --test-- "float-auto-161"
  --assertf~= 123455.789  ( 123456.789 + -1.0 )  1E-4 
  --test-- "float-auto-162"
      fat-i: 123456.789
      fat-j: -1.0
      fat-k:  fat-i + fat-j
  --assertf~= 123455.789  fat-k  1E-4 
  --test-- "float-auto-163"
  --assertf~= 123459.789  ( 123456.789 + 3.0 )  1E-4 
  --test-- "float-auto-164"
      fat-i: 123456.789
      fat-j: 3.0
      fat-k:  fat-i + fat-j
  --assertf~= 123459.789  fat-k  1E-4 
  --test-- "float-auto-165"
  --assertf~= 123449.789  ( 123456.789 + -7.0 )  1E-4 
  --test-- "float-auto-166"
      fat-i: 123456.789
      fat-j: -7.0
      fat-k:  fat-i + fat-j
  --assertf~= 123449.789  fat-k  1E-4 
  --test-- "float-auto-167"
  --assertf~= 123461.789  ( 123456.789 + 5.0 )  1E-4 
  --test-- "float-auto-168"
      fat-i: 123456.789
      fat-j: 5.0
      fat-k:  fat-i + fat-j
  --assertf~= 123461.789  fat-k  1E-4 
  --test-- "float-auto-169"
  --assertf~= 246913.578  ( 123456.789 + 123456.789 )  1E-4 
  --test-- "float-auto-170"
      fat-i: 123456.789
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
  --assertf~= 246913.578  fat-k  1E-4 
  --test-- "float-auto-171"
  --assertf~= 1.222090944E+33  ( 123456.789 + 1.222090944E+33 )  1E-4 
  --test-- "float-auto-172"
      fat-i: 123456.789
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-173"
  --assertf~= 123456.789  ( 123456.789 + 9.99999E-45 )  1E-4 
  --test-- "float-auto-174"
      fat-i: 123456.789
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
  --assertf~= 123456.789  fat-k  1E-4 
  --test-- "float-auto-175"
  --assertf~= 7.70000000000012E+18  ( 123456.789 + 7.7E+18 )  1E-4 
  --test-- "float-auto-176"
      fat-i: 123456.789
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
  --assertf~= 7.70000000000012E+18  fat-k  1E-4 
  --test-- "float-auto-177"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 + 0.0 )  1E-4 
  --test-- "float-auto-178"
      fat-i: 1.222090944E+33
      fat-j: 0.0
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-179"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 + -2147483648.0 )  1E-4 
  --test-- "float-auto-180"
      fat-i: 1.222090944E+33
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-181"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 + 2147483647.0 )  1E-4 
  --test-- "float-auto-182"
      fat-i: 1.222090944E+33
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-183"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 + -1.0 )  1E-4 
  --test-- "float-auto-184"
      fat-i: 1.222090944E+33
      fat-j: -1.0
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-185"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 + 3.0 )  1E-4 
  --test-- "float-auto-186"
      fat-i: 1.222090944E+33
      fat-j: 3.0
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-187"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 + -7.0 )  1E-4 
  --test-- "float-auto-188"
      fat-i: 1.222090944E+33
      fat-j: -7.0
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-189"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 + 5.0 )  1E-4 
  --test-- "float-auto-190"
      fat-i: 1.222090944E+33
      fat-j: 5.0
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-191"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 + 123456.789 )  1E-4 
  --test-- "float-auto-192"
      fat-i: 1.222090944E+33
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-193"
  --assertf~= 2.444181888E+33  ( 1.222090944E+33 + 1.222090944E+33 )  1E-4 
  --test-- "float-auto-194"
      fat-i: 1.222090944E+33
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
  --assertf~= 2.444181888E+33  fat-k  1E-4 
  --test-- "float-auto-195"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 + 9.99999E-45 )  1E-4 
  --test-- "float-auto-196"
      fat-i: 1.222090944E+33
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-197"
  --assertf~= 1.22209094400001E+33  ( 1.222090944E+33 + 7.7E+18 )  1E-4 
  --test-- "float-auto-198"
      fat-i: 1.222090944E+33
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
  --assertf~= 1.22209094400001E+33  fat-k  1E-4 
  --test-- "float-auto-199"
  --assertf~= 9.99999E-45  ( 9.99999E-45 + 0.0 )  1E-4 
  --test-- "float-auto-200"
      fat-i: 9.99999E-45
      fat-j: 0.0
      fat-k:  fat-i + fat-j
  --assertf~= 9.99999E-45  fat-k  1E-4 
  --test-- "float-auto-201"
  --assertf~= -2147483648.0  ( 9.99999E-45 + -2147483648.0 )  1E-4 
  --test-- "float-auto-202"
      fat-i: 9.99999E-45
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
  --assertf~= -2147483648.0  fat-k  1E-4 
  --test-- "float-auto-203"
  --assertf~= 2147483647.0  ( 9.99999E-45 + 2147483647.0 )  1E-4 
  --test-- "float-auto-204"
      fat-i: 9.99999E-45
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
  --assertf~= 2147483647.0  fat-k  1E-4 
  --test-- "float-auto-205"
  --assertf~= -1.0  ( 9.99999E-45 + -1.0 )  1E-4 
  --test-- "float-auto-206"
      fat-i: 9.99999E-45
      fat-j: -1.0
      fat-k:  fat-i + fat-j
  --assertf~= -1.0  fat-k  1E-4 
  --test-- "float-auto-207"
  --assertf~= 3.0  ( 9.99999E-45 + 3.0 )  1E-4 
  --test-- "float-auto-208"
      fat-i: 9.99999E-45
      fat-j: 3.0
      fat-k:  fat-i + fat-j
  --assertf~= 3.0  fat-k  1E-4 
  --test-- "float-auto-209"
  --assertf~= -7.0  ( 9.99999E-45 + -7.0 )  1E-4 
  --test-- "float-auto-210"
      fat-i: 9.99999E-45
      fat-j: -7.0
      fat-k:  fat-i + fat-j
  --assertf~= -7.0  fat-k  1E-4 
  --test-- "float-auto-211"
  --assertf~= 5.0  ( 9.99999E-45 + 5.0 )  1E-4 
  --test-- "float-auto-212"
      fat-i: 9.99999E-45
      fat-j: 5.0
      fat-k:  fat-i + fat-j
  --assertf~= 5.0  fat-k  1E-4 
  --test-- "float-auto-213"
  --assertf~= 123456.789  ( 9.99999E-45 + 123456.789 )  1E-4 
  --test-- "float-auto-214"
      fat-i: 9.99999E-45
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
  --assertf~= 123456.789  fat-k  1E-4 
  --test-- "float-auto-215"
  --assertf~= 1.222090944E+33  ( 9.99999E-45 + 1.222090944E+33 )  1E-4 
  --test-- "float-auto-216"
      fat-i: 9.99999E-45
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-217"
  --assertf~= 1.999998E-44  ( 9.99999E-45 + 9.99999E-45 )  1E-4 
  --test-- "float-auto-218"
      fat-i: 9.99999E-45
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
  --assertf~= 1.999998E-44  fat-k  1E-4 
  --test-- "float-auto-219"
  --assertf~= 7.7E+18  ( 9.99999E-45 + 7.7E+18 )  1E-4 
  --test-- "float-auto-220"
      fat-i: 9.99999E-45
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-221"
  --assertf~= 7.7E+18  ( 7.7E+18 + 0.0 )  1E-4 
  --test-- "float-auto-222"
      fat-i: 7.7E+18
      fat-j: 0.0
      fat-k:  fat-i + fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-223"
  --assertf~= 7.69999999785252E+18  ( 7.7E+18 + -2147483648.0 )  1E-4 
  --test-- "float-auto-224"
      fat-i: 7.7E+18
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
  --assertf~= 7.69999999785252E+18  fat-k  1E-4 
  --test-- "float-auto-225"
  --assertf~= 7.70000000214748E+18  ( 7.7E+18 + 2147483647.0 )  1E-4 
  --test-- "float-auto-226"
      fat-i: 7.7E+18
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
  --assertf~= 7.70000000214748E+18  fat-k  1E-4 
  --test-- "float-auto-227"
  --assertf~= 7.7E+18  ( 7.7E+18 + -1.0 )  1E-4 
  --test-- "float-auto-228"
      fat-i: 7.7E+18
      fat-j: -1.0
      fat-k:  fat-i + fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-229"
  --assertf~= 7.7E+18  ( 7.7E+18 + 3.0 )  1E-4 
  --test-- "float-auto-230"
      fat-i: 7.7E+18
      fat-j: 3.0
      fat-k:  fat-i + fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-231"
  --assertf~= 7.7E+18  ( 7.7E+18 + -7.0 )  1E-4 
  --test-- "float-auto-232"
      fat-i: 7.7E+18
      fat-j: -7.0
      fat-k:  fat-i + fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-233"
  --assertf~= 7.7E+18  ( 7.7E+18 + 5.0 )  1E-4 
  --test-- "float-auto-234"
      fat-i: 7.7E+18
      fat-j: 5.0
      fat-k:  fat-i + fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-235"
  --assertf~= 7.70000000000012E+18  ( 7.7E+18 + 123456.789 )  1E-4 
  --test-- "float-auto-236"
      fat-i: 7.7E+18
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
  --assertf~= 7.70000000000012E+18  fat-k  1E-4 
  --test-- "float-auto-237"
  --assertf~= 1.22209094400001E+33  ( 7.7E+18 + 1.222090944E+33 )  1E-4 
  --test-- "float-auto-238"
      fat-i: 7.7E+18
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
  --assertf~= 1.22209094400001E+33  fat-k  1E-4 
  --test-- "float-auto-239"
  --assertf~= 7.7E+18  ( 7.7E+18 + 9.99999E-45 )  1E-4 
  --test-- "float-auto-240"
      fat-i: 7.7E+18
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-241"
  --assertf~= 1.54E+19  ( 7.7E+18 + 7.7E+18 )  1E-4 
  --test-- "float-auto-242"
      fat-i: 7.7E+18
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
  --assertf~= 1.54E+19  fat-k  1E-4 
  --test-- "float-auto-243"
  --assertf~= 0.0  ( 0.0 - 0.0 )  1E-4 
  --test-- "float-auto-244"
      fat-i: 0.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-245"
  --assertf~= 2147483648.0  ( 0.0 - -2147483648.0 )  1E-4 
  --test-- "float-auto-246"
      fat-i: 0.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
  --assertf~= 2147483648.0  fat-k  1E-4 
  --test-- "float-auto-247"
  --assertf~= -2147483647.0  ( 0.0 - 2147483647.0 )  1E-4 
  --test-- "float-auto-248"
      fat-i: 0.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
  --assertf~= -2147483647.0  fat-k  1E-4 
  --test-- "float-auto-249"
  --assertf~= 1.0  ( 0.0 - -1.0 )  1E-4 
  --test-- "float-auto-250"
      fat-i: 0.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
  --assertf~= 1.0  fat-k  1E-4 
  --test-- "float-auto-251"
  --assertf~= -3.0  ( 0.0 - 3.0 )  1E-4 
  --test-- "float-auto-252"
      fat-i: 0.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
  --assertf~= -3.0  fat-k  1E-4 
  --test-- "float-auto-253"
  --assertf~= 7.0  ( 0.0 - -7.0 )  1E-4 
  --test-- "float-auto-254"
      fat-i: 0.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
  --assertf~= 7.0  fat-k  1E-4 
  --test-- "float-auto-255"
  --assertf~= -5.0  ( 0.0 - 5.0 )  1E-4 
  --test-- "float-auto-256"
      fat-i: 0.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
  --assertf~= -5.0  fat-k  1E-4 
  --test-- "float-auto-257"
  --assertf~= -123456.789  ( 0.0 - 123456.789 )  1E-4 
  --test-- "float-auto-258"
      fat-i: 0.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
  --assertf~= -123456.789  fat-k  1E-4 
  --test-- "float-auto-259"
  --assertf~= -1.222090944E+33  ( 0.0 - 1.222090944E+33 )  1E-4 
  --test-- "float-auto-260"
      fat-i: 0.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
  --assertf~= -1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-261"
  --assertf~= -9.99999E-45  ( 0.0 - 9.99999E-45 )  1E-4 
  --test-- "float-auto-262"
      fat-i: 0.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
  --assertf~= -9.99999E-45  fat-k  1E-4 
  --test-- "float-auto-263"
  --assertf~= -7.7E+18  ( 0.0 - 7.7E+18 )  1E-4 
  --test-- "float-auto-264"
      fat-i: 0.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
  --assertf~= -7.7E+18  fat-k  1E-4 
  --test-- "float-auto-265"
  --assertf~= -2147483648.0  ( -2147483648.0 - 0.0 )  1E-4 
  --test-- "float-auto-266"
      fat-i: -2147483648.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
  --assertf~= -2147483648.0  fat-k  1E-4 
  --test-- "float-auto-267"
  --assertf~= 0.0  ( -2147483648.0 - -2147483648.0 )  1E-4 
  --test-- "float-auto-268"
      fat-i: -2147483648.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-269"
  --assertf~= -4294967295.0  ( -2147483648.0 - 2147483647.0 )  1E-4 
  --test-- "float-auto-270"
      fat-i: -2147483648.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
  --assertf~= -4294967295.0  fat-k  1E-4 
  --test-- "float-auto-271"
  --assertf~= -2147483647.0  ( -2147483648.0 - -1.0 )  1E-4 
  --test-- "float-auto-272"
      fat-i: -2147483648.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
  --assertf~= -2147483647.0  fat-k  1E-4 
  --test-- "float-auto-273"
  --assertf~= -2147483651.0  ( -2147483648.0 - 3.0 )  1E-4 
  --test-- "float-auto-274"
      fat-i: -2147483648.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
  --assertf~= -2147483651.0  fat-k  1E-4 
  --test-- "float-auto-275"
  --assertf~= -2147483641.0  ( -2147483648.0 - -7.0 )  1E-4 
  --test-- "float-auto-276"
      fat-i: -2147483648.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
  --assertf~= -2147483641.0  fat-k  1E-4 
  --test-- "float-auto-277"
  --assertf~= -2147483653.0  ( -2147483648.0 - 5.0 )  1E-4 
  --test-- "float-auto-278"
      fat-i: -2147483648.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
  --assertf~= -2147483653.0  fat-k  1E-4 
  --test-- "float-auto-279"
  --assertf~= -2147607104.789  ( -2147483648.0 - 123456.789 )  1E-4 
  --test-- "float-auto-280"
      fat-i: -2147483648.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
  --assertf~= -2147607104.789  fat-k  1E-4 
  --test-- "float-auto-281"
  --assertf~= -1.222090944E+33  ( -2147483648.0 - 1.222090944E+33 )  1E-4 
  --test-- "float-auto-282"
      fat-i: -2147483648.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
  --assertf~= -1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-283"
  --assertf~= -2147483648.0  ( -2147483648.0 - 9.99999E-45 )  1E-4 
  --test-- "float-auto-284"
      fat-i: -2147483648.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
  --assertf~= -2147483648.0  fat-k  1E-4 
  --test-- "float-auto-285"
  --assertf~= -7.70000000214748E+18  ( -2147483648.0 - 7.7E+18 )  1E-4 
  --test-- "float-auto-286"
      fat-i: -2147483648.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
  --assertf~= -7.70000000214748E+18  fat-k  1E-4 
  --test-- "float-auto-287"
  --assertf~= 2147483647.0  ( 2147483647.0 - 0.0 )  1E-4 
  --test-- "float-auto-288"
      fat-i: 2147483647.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
  --assertf~= 2147483647.0  fat-k  1E-4 
  --test-- "float-auto-289"
  --assertf~= 4294967295.0  ( 2147483647.0 - -2147483648.0 )  1E-4 
  --test-- "float-auto-290"
      fat-i: 2147483647.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
  --assertf~= 4294967295.0  fat-k  1E-4 
  --test-- "float-auto-291"
  --assertf~= 0.0  ( 2147483647.0 - 2147483647.0 )  1E-4 
  --test-- "float-auto-292"
      fat-i: 2147483647.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-293"
  --assertf~= 2147483648.0  ( 2147483647.0 - -1.0 )  1E-4 
  --test-- "float-auto-294"
      fat-i: 2147483647.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
  --assertf~= 2147483648.0  fat-k  1E-4 
  --test-- "float-auto-295"
  --assertf~= 2147483644.0  ( 2147483647.0 - 3.0 )  1E-4 
  --test-- "float-auto-296"
      fat-i: 2147483647.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
  --assertf~= 2147483644.0  fat-k  1E-4 
  --test-- "float-auto-297"
  --assertf~= 2147483654.0  ( 2147483647.0 - -7.0 )  1E-4 
  --test-- "float-auto-298"
      fat-i: 2147483647.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
  --assertf~= 2147483654.0  fat-k  1E-4 
  --test-- "float-auto-299"
  --assertf~= 2147483642.0  ( 2147483647.0 - 5.0 )  1E-4 
  --test-- "float-auto-300"
      fat-i: 2147483647.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
  --assertf~= 2147483642.0  fat-k  1E-4 
  --test-- "float-auto-301"
  --assertf~= 2147360190.211  ( 2147483647.0 - 123456.789 )  1E-4 
  --test-- "float-auto-302"
      fat-i: 2147483647.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
  --assertf~= 2147360190.211  fat-k  1E-4 
  --test-- "float-auto-303"
  --assertf~= -1.222090944E+33  ( 2147483647.0 - 1.222090944E+33 )  1E-4 
  --test-- "float-auto-304"
      fat-i: 2147483647.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
  --assertf~= -1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-305"
  --assertf~= 2147483647.0  ( 2147483647.0 - 9.99999E-45 )  1E-4 
  --test-- "float-auto-306"
      fat-i: 2147483647.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
  --assertf~= 2147483647.0  fat-k  1E-4 
  --test-- "float-auto-307"
  --assertf~= -7.69999999785252E+18  ( 2147483647.0 - 7.7E+18 )  1E-4 
  --test-- "float-auto-308"
      fat-i: 2147483647.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
  --assertf~= -7.69999999785252E+18  fat-k  1E-4 
  --test-- "float-auto-309"
  --assertf~= -1.0  ( -1.0 - 0.0 )  1E-4 
  --test-- "float-auto-310"
      fat-i: -1.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
  --assertf~= -1.0  fat-k  1E-4 
  --test-- "float-auto-311"
  --assertf~= 2147483647.0  ( -1.0 - -2147483648.0 )  1E-4 
  --test-- "float-auto-312"
      fat-i: -1.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
  --assertf~= 2147483647.0  fat-k  1E-4 
  --test-- "float-auto-313"
  --assertf~= -2147483648.0  ( -1.0 - 2147483647.0 )  1E-4 
  --test-- "float-auto-314"
      fat-i: -1.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
  --assertf~= -2147483648.0  fat-k  1E-4 
  --test-- "float-auto-315"
  --assertf~= 0.0  ( -1.0 - -1.0 )  1E-4 
  --test-- "float-auto-316"
      fat-i: -1.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-317"
  --assertf~= -4.0  ( -1.0 - 3.0 )  1E-4 
  --test-- "float-auto-318"
      fat-i: -1.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
  --assertf~= -4.0  fat-k  1E-4 
  --test-- "float-auto-319"
  --assertf~= 6.0  ( -1.0 - -7.0 )  1E-4 
  --test-- "float-auto-320"
      fat-i: -1.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
  --assertf~= 6.0  fat-k  1E-4 
  --test-- "float-auto-321"
  --assertf~= -6.0  ( -1.0 - 5.0 )  1E-4 
  --test-- "float-auto-322"
      fat-i: -1.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
  --assertf~= -6.0  fat-k  1E-4 
  --test-- "float-auto-323"
  --assertf~= -123457.789  ( -1.0 - 123456.789 )  1E-4 
  --test-- "float-auto-324"
      fat-i: -1.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
  --assertf~= -123457.789  fat-k  1E-4 
  --test-- "float-auto-325"
  --assertf~= -1.222090944E+33  ( -1.0 - 1.222090944E+33 )  1E-4 
  --test-- "float-auto-326"
      fat-i: -1.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
  --assertf~= -1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-327"
  --assertf~= -1.0  ( -1.0 - 9.99999E-45 )  1E-4 
  --test-- "float-auto-328"
      fat-i: -1.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
  --assertf~= -1.0  fat-k  1E-4 
  --test-- "float-auto-329"
  --assertf~= -7.7E+18  ( -1.0 - 7.7E+18 )  1E-4 
  --test-- "float-auto-330"
      fat-i: -1.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
  --assertf~= -7.7E+18  fat-k  1E-4 
  --test-- "float-auto-331"
  --assertf~= 3.0  ( 3.0 - 0.0 )  1E-4 
  --test-- "float-auto-332"
      fat-i: 3.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
  --assertf~= 3.0  fat-k  1E-4 
  --test-- "float-auto-333"
  --assertf~= 2147483651.0  ( 3.0 - -2147483648.0 )  1E-4 
  --test-- "float-auto-334"
      fat-i: 3.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
  --assertf~= 2147483651.0  fat-k  1E-4 
  --test-- "float-auto-335"
  --assertf~= -2147483644.0  ( 3.0 - 2147483647.0 )  1E-4 
  --test-- "float-auto-336"
      fat-i: 3.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
  --assertf~= -2147483644.0  fat-k  1E-4 
  --test-- "float-auto-337"
  --assertf~= 4.0  ( 3.0 - -1.0 )  1E-4 
  --test-- "float-auto-338"
      fat-i: 3.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
  --assertf~= 4.0  fat-k  1E-4 
  --test-- "float-auto-339"
  --assertf~= 0.0  ( 3.0 - 3.0 )  1E-4 
  --test-- "float-auto-340"
      fat-i: 3.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-341"
  --assertf~= 10.0  ( 3.0 - -7.0 )  1E-4 
  --test-- "float-auto-342"
      fat-i: 3.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
  --assertf~= 10.0  fat-k  1E-4 
  --test-- "float-auto-343"
  --assertf~= -2.0  ( 3.0 - 5.0 )  1E-4 
  --test-- "float-auto-344"
      fat-i: 3.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
  --assertf~= -2.0  fat-k  1E-4 
  --test-- "float-auto-345"
  --assertf~= -123453.789  ( 3.0 - 123456.789 )  1E-4 
  --test-- "float-auto-346"
      fat-i: 3.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
  --assertf~= -123453.789  fat-k  1E-4 
  --test-- "float-auto-347"
  --assertf~= -1.222090944E+33  ( 3.0 - 1.222090944E+33 )  1E-4 
  --test-- "float-auto-348"
      fat-i: 3.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
  --assertf~= -1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-349"
  --assertf~= 3.0  ( 3.0 - 9.99999E-45 )  1E-4 
  --test-- "float-auto-350"
      fat-i: 3.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
  --assertf~= 3.0  fat-k  1E-4 
  --test-- "float-auto-351"
  --assertf~= -7.7E+18  ( 3.0 - 7.7E+18 )  1E-4 
  --test-- "float-auto-352"
      fat-i: 3.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
  --assertf~= -7.7E+18  fat-k  1E-4 
  --test-- "float-auto-353"
  --assertf~= -7.0  ( -7.0 - 0.0 )  1E-4 
  --test-- "float-auto-354"
      fat-i: -7.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
  --assertf~= -7.0  fat-k  1E-4 
  --test-- "float-auto-355"
  --assertf~= 2147483641.0  ( -7.0 - -2147483648.0 )  1E-4 
  --test-- "float-auto-356"
      fat-i: -7.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
  --assertf~= 2147483641.0  fat-k  1E-4 
  --test-- "float-auto-357"
  --assertf~= -2147483654.0  ( -7.0 - 2147483647.0 )  1E-4 
  --test-- "float-auto-358"
      fat-i: -7.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
  --assertf~= -2147483654.0  fat-k  1E-4 
  --test-- "float-auto-359"
  --assertf~= -6.0  ( -7.0 - -1.0 )  1E-4 
  --test-- "float-auto-360"
      fat-i: -7.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
  --assertf~= -6.0  fat-k  1E-4 
  --test-- "float-auto-361"
  --assertf~= -10.0  ( -7.0 - 3.0 )  1E-4 
  --test-- "float-auto-362"
      fat-i: -7.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
  --assertf~= -10.0  fat-k  1E-4 
  --test-- "float-auto-363"
  --assertf~= 0.0  ( -7.0 - -7.0 )  1E-4 
  --test-- "float-auto-364"
      fat-i: -7.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-365"
  --assertf~= -12.0  ( -7.0 - 5.0 )  1E-4 
  --test-- "float-auto-366"
      fat-i: -7.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
  --assertf~= -12.0  fat-k  1E-4 
  --test-- "float-auto-367"
  --assertf~= -123463.789  ( -7.0 - 123456.789 )  1E-4 
  --test-- "float-auto-368"
      fat-i: -7.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
  --assertf~= -123463.789  fat-k  1E-4 
  --test-- "float-auto-369"
  --assertf~= -1.222090944E+33  ( -7.0 - 1.222090944E+33 )  1E-4 
  --test-- "float-auto-370"
      fat-i: -7.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
  --assertf~= -1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-371"
  --assertf~= -7.0  ( -7.0 - 9.99999E-45 )  1E-4 
  --test-- "float-auto-372"
      fat-i: -7.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
  --assertf~= -7.0  fat-k  1E-4 
  --test-- "float-auto-373"
  --assertf~= -7.7E+18  ( -7.0 - 7.7E+18 )  1E-4 
  --test-- "float-auto-374"
      fat-i: -7.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
  --assertf~= -7.7E+18  fat-k  1E-4 
  --test-- "float-auto-375"
  --assertf~= 5.0  ( 5.0 - 0.0 )  1E-4 
  --test-- "float-auto-376"
      fat-i: 5.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
  --assertf~= 5.0  fat-k  1E-4 
  --test-- "float-auto-377"
  --assertf~= 2147483653.0  ( 5.0 - -2147483648.0 )  1E-4 
  --test-- "float-auto-378"
      fat-i: 5.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
  --assertf~= 2147483653.0  fat-k  1E-4 
  --test-- "float-auto-379"
  --assertf~= -2147483642.0  ( 5.0 - 2147483647.0 )  1E-4 
  --test-- "float-auto-380"
      fat-i: 5.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
  --assertf~= -2147483642.0  fat-k  1E-4 
  --test-- "float-auto-381"
  --assertf~= 6.0  ( 5.0 - -1.0 )  1E-4 
  --test-- "float-auto-382"
      fat-i: 5.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
  --assertf~= 6.0  fat-k  1E-4 
  --test-- "float-auto-383"
  --assertf~= 2.0  ( 5.0 - 3.0 )  1E-4 
  --test-- "float-auto-384"
      fat-i: 5.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
  --assertf~= 2.0  fat-k  1E-4 
  --test-- "float-auto-385"
  --assertf~= 12.0  ( 5.0 - -7.0 )  1E-4 
  --test-- "float-auto-386"
      fat-i: 5.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
  --assertf~= 12.0  fat-k  1E-4 
  --test-- "float-auto-387"
  --assertf~= 0.0  ( 5.0 - 5.0 )  1E-4 
  --test-- "float-auto-388"
      fat-i: 5.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-389"
  --assertf~= -123451.789  ( 5.0 - 123456.789 )  1E-4 
  --test-- "float-auto-390"
      fat-i: 5.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
  --assertf~= -123451.789  fat-k  1E-4 
  --test-- "float-auto-391"
  --assertf~= -1.222090944E+33  ( 5.0 - 1.222090944E+33 )  1E-4 
  --test-- "float-auto-392"
      fat-i: 5.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
  --assertf~= -1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-393"
  --assertf~= 5.0  ( 5.0 - 9.99999E-45 )  1E-4 
  --test-- "float-auto-394"
      fat-i: 5.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
  --assertf~= 5.0  fat-k  1E-4 
  --test-- "float-auto-395"
  --assertf~= -7.7E+18  ( 5.0 - 7.7E+18 )  1E-4 
  --test-- "float-auto-396"
      fat-i: 5.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
  --assertf~= -7.7E+18  fat-k  1E-4 
  --test-- "float-auto-397"
  --assertf~= 123456.789  ( 123456.789 - 0.0 )  1E-4 
  --test-- "float-auto-398"
      fat-i: 123456.789
      fat-j: 0.0
      fat-k:  fat-i - fat-j
  --assertf~= 123456.789  fat-k  1E-4 
  --test-- "float-auto-399"
  --assertf~= 2147607104.789  ( 123456.789 - -2147483648.0 )  1E-4 
  --test-- "float-auto-400"
      fat-i: 123456.789
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
  --assertf~= 2147607104.789  fat-k  1E-4 
  --test-- "float-auto-401"
  --assertf~= -2147360190.211  ( 123456.789 - 2147483647.0 )  1E-4 
  --test-- "float-auto-402"
      fat-i: 123456.789
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
  --assertf~= -2147360190.211  fat-k  1E-4 
  --test-- "float-auto-403"
  --assertf~= 123457.789  ( 123456.789 - -1.0 )  1E-4 
  --test-- "float-auto-404"
      fat-i: 123456.789
      fat-j: -1.0
      fat-k:  fat-i - fat-j
  --assertf~= 123457.789  fat-k  1E-4 
  --test-- "float-auto-405"
  --assertf~= 123453.789  ( 123456.789 - 3.0 )  1E-4 
  --test-- "float-auto-406"
      fat-i: 123456.789
      fat-j: 3.0
      fat-k:  fat-i - fat-j
  --assertf~= 123453.789  fat-k  1E-4 
  --test-- "float-auto-407"
  --assertf~= 123463.789  ( 123456.789 - -7.0 )  1E-4 
  --test-- "float-auto-408"
      fat-i: 123456.789
      fat-j: -7.0
      fat-k:  fat-i - fat-j
  --assertf~= 123463.789  fat-k  1E-4 
  --test-- "float-auto-409"
  --assertf~= 123451.789  ( 123456.789 - 5.0 )  1E-4 
  --test-- "float-auto-410"
      fat-i: 123456.789
      fat-j: 5.0
      fat-k:  fat-i - fat-j
  --assertf~= 123451.789  fat-k  1E-4 
  --test-- "float-auto-411"
  --assertf~= 0.0  ( 123456.789 - 123456.789 )  1E-4 
  --test-- "float-auto-412"
      fat-i: 123456.789
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-413"
  --assertf~= -1.222090944E+33  ( 123456.789 - 1.222090944E+33 )  1E-4 
  --test-- "float-auto-414"
      fat-i: 123456.789
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
  --assertf~= -1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-415"
  --assertf~= 123456.789  ( 123456.789 - 9.99999E-45 )  1E-4 
  --test-- "float-auto-416"
      fat-i: 123456.789
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
  --assertf~= 123456.789  fat-k  1E-4 
  --test-- "float-auto-417"
  --assertf~= -7.69999999999988E+18  ( 123456.789 - 7.7E+18 )  1E-4 
  --test-- "float-auto-418"
      fat-i: 123456.789
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
  --assertf~= -7.69999999999988E+18  fat-k  1E-4 
  --test-- "float-auto-419"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 - 0.0 )  1E-4 
  --test-- "float-auto-420"
      fat-i: 1.222090944E+33
      fat-j: 0.0
      fat-k:  fat-i - fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-421"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 - -2147483648.0 )  1E-4 
  --test-- "float-auto-422"
      fat-i: 1.222090944E+33
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-423"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 - 2147483647.0 )  1E-4 
  --test-- "float-auto-424"
      fat-i: 1.222090944E+33
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-425"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 - -1.0 )  1E-4 
  --test-- "float-auto-426"
      fat-i: 1.222090944E+33
      fat-j: -1.0
      fat-k:  fat-i - fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-427"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 - 3.0 )  1E-4 
  --test-- "float-auto-428"
      fat-i: 1.222090944E+33
      fat-j: 3.0
      fat-k:  fat-i - fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-429"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 - -7.0 )  1E-4 
  --test-- "float-auto-430"
      fat-i: 1.222090944E+33
      fat-j: -7.0
      fat-k:  fat-i - fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-431"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 - 5.0 )  1E-4 
  --test-- "float-auto-432"
      fat-i: 1.222090944E+33
      fat-j: 5.0
      fat-k:  fat-i - fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-433"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 - 123456.789 )  1E-4 
  --test-- "float-auto-434"
      fat-i: 1.222090944E+33
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-435"
  --assertf~= 0.0  ( 1.222090944E+33 - 1.222090944E+33 )  1E-4 
  --test-- "float-auto-436"
      fat-i: 1.222090944E+33
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-437"
  --assertf~= 1.222090944E+33  ( 1.222090944E+33 - 9.99999E-45 )  1E-4 
  --test-- "float-auto-438"
      fat-i: 1.222090944E+33
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
  --assertf~= 1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-439"
  --assertf~= 1.22209094399999E+33  ( 1.222090944E+33 - 7.7E+18 )  1E-4 
  --test-- "float-auto-440"
      fat-i: 1.222090944E+33
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
  --assertf~= 1.22209094399999E+33  fat-k  1E-4 
  --test-- "float-auto-441"
  --assertf~= 9.99999E-45  ( 9.99999E-45 - 0.0 )  1E-4 
  --test-- "float-auto-442"
      fat-i: 9.99999E-45
      fat-j: 0.0
      fat-k:  fat-i - fat-j
  --assertf~= 9.99999E-45  fat-k  1E-4 
  --test-- "float-auto-443"
  --assertf~= 2147483648.0  ( 9.99999E-45 - -2147483648.0 )  1E-4 
  --test-- "float-auto-444"
      fat-i: 9.99999E-45
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
  --assertf~= 2147483648.0  fat-k  1E-4 
  --test-- "float-auto-445"
  --assertf~= -2147483647.0  ( 9.99999E-45 - 2147483647.0 )  1E-4 
  --test-- "float-auto-446"
      fat-i: 9.99999E-45
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
  --assertf~= -2147483647.0  fat-k  1E-4 
  --test-- "float-auto-447"
  --assertf~= 1.0  ( 9.99999E-45 - -1.0 )  1E-4 
  --test-- "float-auto-448"
      fat-i: 9.99999E-45
      fat-j: -1.0
      fat-k:  fat-i - fat-j
  --assertf~= 1.0  fat-k  1E-4 
  --test-- "float-auto-449"
  --assertf~= -3.0  ( 9.99999E-45 - 3.0 )  1E-4 
  --test-- "float-auto-450"
      fat-i: 9.99999E-45
      fat-j: 3.0
      fat-k:  fat-i - fat-j
  --assertf~= -3.0  fat-k  1E-4 
  --test-- "float-auto-451"
  --assertf~= 7.0  ( 9.99999E-45 - -7.0 )  1E-4 
  --test-- "float-auto-452"
      fat-i: 9.99999E-45
      fat-j: -7.0
      fat-k:  fat-i - fat-j
  --assertf~= 7.0  fat-k  1E-4 
  --test-- "float-auto-453"
  --assertf~= -5.0  ( 9.99999E-45 - 5.0 )  1E-4 
  --test-- "float-auto-454"
      fat-i: 9.99999E-45
      fat-j: 5.0
      fat-k:  fat-i - fat-j
  --assertf~= -5.0  fat-k  1E-4 
  --test-- "float-auto-455"
  --assertf~= -123456.789  ( 9.99999E-45 - 123456.789 )  1E-4 
  --test-- "float-auto-456"
      fat-i: 9.99999E-45
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
  --assertf~= -123456.789  fat-k  1E-4 
  --test-- "float-auto-457"
  --assertf~= -1.222090944E+33  ( 9.99999E-45 - 1.222090944E+33 )  1E-4 
  --test-- "float-auto-458"
      fat-i: 9.99999E-45
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
  --assertf~= -1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-459"
  --assertf~= 0.0  ( 9.99999E-45 - 9.99999E-45 )  1E-4 
  --test-- "float-auto-460"
      fat-i: 9.99999E-45
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-461"
  --assertf~= -7.7E+18  ( 9.99999E-45 - 7.7E+18 )  1E-4 
  --test-- "float-auto-462"
      fat-i: 9.99999E-45
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
  --assertf~= -7.7E+18  fat-k  1E-4 
  --test-- "float-auto-463"
  --assertf~= 7.7E+18  ( 7.7E+18 - 0.0 )  1E-4 
  --test-- "float-auto-464"
      fat-i: 7.7E+18
      fat-j: 0.0
      fat-k:  fat-i - fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-465"
  --assertf~= 7.70000000214748E+18  ( 7.7E+18 - -2147483648.0 )  1E-4 
  --test-- "float-auto-466"
      fat-i: 7.7E+18
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
  --assertf~= 7.70000000214748E+18  fat-k  1E-4 
  --test-- "float-auto-467"
  --assertf~= 7.69999999785252E+18  ( 7.7E+18 - 2147483647.0 )  1E-4 
  --test-- "float-auto-468"
      fat-i: 7.7E+18
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
  --assertf~= 7.69999999785252E+18  fat-k  1E-4 
  --test-- "float-auto-469"
  --assertf~= 7.7E+18  ( 7.7E+18 - -1.0 )  1E-4 
  --test-- "float-auto-470"
      fat-i: 7.7E+18
      fat-j: -1.0
      fat-k:  fat-i - fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-471"
  --assertf~= 7.7E+18  ( 7.7E+18 - 3.0 )  1E-4 
  --test-- "float-auto-472"
      fat-i: 7.7E+18
      fat-j: 3.0
      fat-k:  fat-i - fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-473"
  --assertf~= 7.7E+18  ( 7.7E+18 - -7.0 )  1E-4 
  --test-- "float-auto-474"
      fat-i: 7.7E+18
      fat-j: -7.0
      fat-k:  fat-i - fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-475"
  --assertf~= 7.7E+18  ( 7.7E+18 - 5.0 )  1E-4 
  --test-- "float-auto-476"
      fat-i: 7.7E+18
      fat-j: 5.0
      fat-k:  fat-i - fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-477"
  --assertf~= 7.69999999999988E+18  ( 7.7E+18 - 123456.789 )  1E-4 
  --test-- "float-auto-478"
      fat-i: 7.7E+18
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
  --assertf~= 7.69999999999988E+18  fat-k  1E-4 
  --test-- "float-auto-479"
  --assertf~= -1.22209094399999E+33  ( 7.7E+18 - 1.222090944E+33 )  1E-4 
  --test-- "float-auto-480"
      fat-i: 7.7E+18
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
  --assertf~= -1.22209094399999E+33  fat-k  1E-4 
  --test-- "float-auto-481"
  --assertf~= 7.7E+18  ( 7.7E+18 - 9.99999E-45 )  1E-4 
  --test-- "float-auto-482"
      fat-i: 7.7E+18
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
  --assertf~= 7.7E+18  fat-k  1E-4 
  --test-- "float-auto-483"
  --assertf~= 0.0  ( 7.7E+18 - 7.7E+18 )  1E-4 
  --test-- "float-auto-484"
      fat-i: 7.7E+18
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-485"
  --assertf~= 0.0  ( 0.0 * 0.0 )  1E-4 
  --test-- "float-auto-486"
      fat-i: 0.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-487"
  --assertf~= 0.0  ( 0.0 * -2147483648.0 )  1E-4 
  --test-- "float-auto-488"
      fat-i: 0.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-489"
  --assertf~= 0.0  ( 0.0 * 2147483647.0 )  1E-4 
  --test-- "float-auto-490"
      fat-i: 0.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-491"
  --assertf~= 0.0  ( 0.0 * -1.0 )  1E-4 
  --test-- "float-auto-492"
      fat-i: 0.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-493"
  --assertf~= 0.0  ( 0.0 * 3.0 )  1E-4 
  --test-- "float-auto-494"
      fat-i: 0.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-495"
  --assertf~= 0.0  ( 0.0 * -7.0 )  1E-4 
  --test-- "float-auto-496"
      fat-i: 0.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-497"
  --assertf~= 0.0  ( 0.0 * 5.0 )  1E-4 
  --test-- "float-auto-498"
      fat-i: 0.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-499"
  --assertf~= 0.0  ( 0.0 * 123456.789 )  1E-4 
  --test-- "float-auto-500"
      fat-i: 0.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-501"
  --assertf~= 0.0  ( 0.0 * 1.222090944E+33 )  1E-4 
  --test-- "float-auto-502"
      fat-i: 0.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-503"
  --assertf~= 0.0  ( 0.0 * 9.99999E-45 )  1E-4 
  --test-- "float-auto-504"
      fat-i: 0.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-505"
  --assertf~= 0.0  ( 0.0 * 7.7E+18 )  1E-4 
  --test-- "float-auto-506"
      fat-i: 0.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-507"
  --assertf~= 0.0  ( -2147483648.0 * 0.0 )  1E-4 
  --test-- "float-auto-508"
      fat-i: -2147483648.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-509"
  --assertf~= 4.61168601842739E+18  ( -2147483648.0 * -2147483648.0 )  1E-4 
  --test-- "float-auto-510"
      fat-i: -2147483648.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
  --assertf~= 4.61168601842739E+18  fat-k  1E-4 
  --test-- "float-auto-511"
  --assertf~= -4.6116860162799E+18  ( -2147483648.0 * 2147483647.0 )  1E-4 
  --test-- "float-auto-512"
      fat-i: -2147483648.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
  --assertf~= -4.6116860162799E+18  fat-k  1E-4 
  --test-- "float-auto-513"
  --assertf~= 2147483648.0  ( -2147483648.0 * -1.0 )  1E-4 
  --test-- "float-auto-514"
      fat-i: -2147483648.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
  --assertf~= 2147483648.0  fat-k  1E-4 
  --test-- "float-auto-515"
  --assertf~= -6442450944.0  ( -2147483648.0 * 3.0 )  1E-4 
  --test-- "float-auto-516"
      fat-i: -2147483648.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
  --assertf~= -6442450944.0  fat-k  1E-4 
  --test-- "float-auto-517"
  --assertf~= 15032385536.0  ( -2147483648.0 * -7.0 )  1E-4 
  --test-- "float-auto-518"
      fat-i: -2147483648.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
  --assertf~= 15032385536.0  fat-k  1E-4 
  --test-- "float-auto-519"
  --assertf~= -10737418240.0  ( -2147483648.0 * 5.0 )  1E-4 
  --test-- "float-auto-520"
      fat-i: -2147483648.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
  --assertf~= -10737418240.0  fat-k  1E-4 
  --test-- "float-auto-521"
  --assertf~= -265121435612086.0  ( -2147483648.0 * 123456.789 )  1E-4 
  --test-- "float-auto-522"
      fat-i: -2147483648.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
  --assertf~= -265121435612086.0  fat-k  1E-4 
  --test-- "float-auto-523"
  --assertf~= -2.62442031860888E+42  ( -2147483648.0 * 1.222090944E+33 )  1E-4 
  --test-- "float-auto-524"
      fat-i: -2147483648.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
  --assertf~= -2.62442031860888E+42  fat-k  1E-4 
  --test-- "float-auto-525"
  --assertf~= -2.14748150051635E-35  ( -2147483648.0 * 9.99999E-45 )  1E-4 
  --test-- "float-auto-526"
      fat-i: -2147483648.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
  --assertf~= -2.14748150051635E-35  fat-k  1E-4 
  --test-- "float-auto-527"
  --assertf~= -1.65356240896E+28  ( -2147483648.0 * 7.7E+18 )  1E-4 
  --test-- "float-auto-528"
      fat-i: -2147483648.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
  --assertf~= -1.65356240896E+28  fat-k  1E-4 
  --test-- "float-auto-529"
  --assertf~= 0.0  ( 2147483647.0 * 0.0 )  1E-4 
  --test-- "float-auto-530"
      fat-i: 2147483647.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-531"
  --assertf~= -4.6116860162799E+18  ( 2147483647.0 * -2147483648.0 )  1E-4 
  --test-- "float-auto-532"
      fat-i: 2147483647.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
  --assertf~= -4.6116860162799E+18  fat-k  1E-4 
  --test-- "float-auto-533"
  --assertf~= 4.61168601413242E+18  ( 2147483647.0 * 2147483647.0 )  1E-4 
  --test-- "float-auto-534"
      fat-i: 2147483647.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
  --assertf~= 4.61168601413242E+18  fat-k  1E-4 
  --test-- "float-auto-535"
  --assertf~= -2147483647.0  ( 2147483647.0 * -1.0 )  1E-4 
  --test-- "float-auto-536"
      fat-i: 2147483647.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
  --assertf~= -2147483647.0  fat-k  1E-4 
  --test-- "float-auto-537"
  --assertf~= 6442450941.0  ( 2147483647.0 * 3.0 )  1E-4 
  --test-- "float-auto-538"
      fat-i: 2147483647.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
  --assertf~= 6442450941.0  fat-k  1E-4 
  --test-- "float-auto-539"
  --assertf~= -15032385529.0  ( 2147483647.0 * -7.0 )  1E-4 
  --test-- "float-auto-540"
      fat-i: 2147483647.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
  --assertf~= -15032385529.0  fat-k  1E-4 
  --test-- "float-auto-541"
  --assertf~= 10737418235.0  ( 2147483647.0 * 5.0 )  1E-4 
  --test-- "float-auto-542"
      fat-i: 2147483647.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
  --assertf~= 10737418235.0  fat-k  1E-4 
  --test-- "float-auto-543"
  --assertf~= 265121435488630.0  ( 2147483647.0 * 123456.789 )  1E-4 
  --test-- "float-auto-544"
      fat-i: 2147483647.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
  --assertf~= 265121435488630.0  fat-k  1E-4 
  --test-- "float-auto-545"
  --assertf~= 2.62442031738679E+42  ( 2147483647.0 * 1.222090944E+33 )  1E-4 
  --test-- "float-auto-546"
      fat-i: 2147483647.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
  --assertf~= 2.62442031738679E+42  fat-k  1E-4 
  --test-- "float-auto-547"
  --assertf~= 2.14748149951635E-35  ( 2147483647.0 * 9.99999E-45 )  1E-4 
  --test-- "float-auto-548"
      fat-i: 2147483647.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
  --assertf~= 2.14748149951635E-35  fat-k  1E-4 
  --test-- "float-auto-549"
  --assertf~= 1.65356240819E+28  ( 2147483647.0 * 7.7E+18 )  1E-4 
  --test-- "float-auto-550"
      fat-i: 2147483647.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
  --assertf~= 1.65356240819E+28  fat-k  1E-4 
  --test-- "float-auto-551"
  --assertf~= 0.0  ( -1.0 * 0.0 )  1E-4 
  --test-- "float-auto-552"
      fat-i: -1.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-553"
  --assertf~= 2147483648.0  ( -1.0 * -2147483648.0 )  1E-4 
  --test-- "float-auto-554"
      fat-i: -1.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
  --assertf~= 2147483648.0  fat-k  1E-4 
  --test-- "float-auto-555"
  --assertf~= -2147483647.0  ( -1.0 * 2147483647.0 )  1E-4 
  --test-- "float-auto-556"
      fat-i: -1.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
  --assertf~= -2147483647.0  fat-k  1E-4 
  --test-- "float-auto-557"
  --assertf~= 1.0  ( -1.0 * -1.0 )  1E-4 
  --test-- "float-auto-558"
      fat-i: -1.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
  --assertf~= 1.0  fat-k  1E-4 
  --test-- "float-auto-559"
  --assertf~= -3.0  ( -1.0 * 3.0 )  1E-4 
  --test-- "float-auto-560"
      fat-i: -1.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
  --assertf~= -3.0  fat-k  1E-4 
  --test-- "float-auto-561"
  --assertf~= 7.0  ( -1.0 * -7.0 )  1E-4 
  --test-- "float-auto-562"
      fat-i: -1.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
  --assertf~= 7.0  fat-k  1E-4 
  --test-- "float-auto-563"
  --assertf~= -5.0  ( -1.0 * 5.0 )  1E-4 
  --test-- "float-auto-564"
      fat-i: -1.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
  --assertf~= -5.0  fat-k  1E-4 
  --test-- "float-auto-565"
  --assertf~= -123456.789  ( -1.0 * 123456.789 )  1E-4 
  --test-- "float-auto-566"
      fat-i: -1.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
  --assertf~= -123456.789  fat-k  1E-4 
  --test-- "float-auto-567"
  --assertf~= -1.222090944E+33  ( -1.0 * 1.222090944E+33 )  1E-4 
  --test-- "float-auto-568"
      fat-i: -1.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
  --assertf~= -1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-569"
  --assertf~= -9.99999E-45  ( -1.0 * 9.99999E-45 )  1E-4 
  --test-- "float-auto-570"
      fat-i: -1.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
  --assertf~= -9.99999E-45  fat-k  1E-4 
  --test-- "float-auto-571"
  --assertf~= -7.7E+18  ( -1.0 * 7.7E+18 )  1E-4 
  --test-- "float-auto-572"
      fat-i: -1.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
  --assertf~= -7.7E+18  fat-k  1E-4 
  --test-- "float-auto-573"
  --assertf~= 0.0  ( 3.0 * 0.0 )  1E-4 
  --test-- "float-auto-574"
      fat-i: 3.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-575"
  --assertf~= -6442450944.0  ( 3.0 * -2147483648.0 )  1E-4 
  --test-- "float-auto-576"
      fat-i: 3.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
  --assertf~= -6442450944.0  fat-k  1E-4 
  --test-- "float-auto-577"
  --assertf~= 6442450941.0  ( 3.0 * 2147483647.0 )  1E-4 
  --test-- "float-auto-578"
      fat-i: 3.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
  --assertf~= 6442450941.0  fat-k  1E-4 
  --test-- "float-auto-579"
  --assertf~= -3.0  ( 3.0 * -1.0 )  1E-4 
  --test-- "float-auto-580"
      fat-i: 3.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
  --assertf~= -3.0  fat-k  1E-4 
  --test-- "float-auto-581"
  --assertf~= 9.0  ( 3.0 * 3.0 )  1E-4 
  --test-- "float-auto-582"
      fat-i: 3.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
  --assertf~= 9.0  fat-k  1E-4 
  --test-- "float-auto-583"
  --assertf~= -21.0  ( 3.0 * -7.0 )  1E-4 
  --test-- "float-auto-584"
      fat-i: 3.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
  --assertf~= -21.0  fat-k  1E-4 
  --test-- "float-auto-585"
  --assertf~= 15.0  ( 3.0 * 5.0 )  1E-4 
  --test-- "float-auto-586"
      fat-i: 3.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
  --assertf~= 15.0  fat-k  1E-4 
  --test-- "float-auto-587"
  --assertf~= 370370.367  ( 3.0 * 123456.789 )  1E-4 
  --test-- "float-auto-588"
      fat-i: 3.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
  --assertf~= 370370.367  fat-k  1E-4 
  --test-- "float-auto-589"
  --assertf~= 3.666272832E+33  ( 3.0 * 1.222090944E+33 )  1E-4 
  --test-- "float-auto-590"
      fat-i: 3.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
  --assertf~= 3.666272832E+33  fat-k  1E-4 
  --test-- "float-auto-591"
  --assertf~= 2.999997E-44  ( 3.0 * 9.99999E-45 )  1E-4 
  --test-- "float-auto-592"
      fat-i: 3.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
  --assertf~= 2.999997E-44  fat-k  1E-4 
  --test-- "float-auto-593"
  --assertf~= 2.31E+19  ( 3.0 * 7.7E+18 )  1E-4 
  --test-- "float-auto-594"
      fat-i: 3.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
  --assertf~= 2.31E+19  fat-k  1E-4 
  --test-- "float-auto-595"
  --assertf~= 0.0  ( -7.0 * 0.0 )  1E-4 
  --test-- "float-auto-596"
      fat-i: -7.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-597"
  --assertf~= 15032385536.0  ( -7.0 * -2147483648.0 )  1E-4 
  --test-- "float-auto-598"
      fat-i: -7.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
  --assertf~= 15032385536.0  fat-k  1E-4 
  --test-- "float-auto-599"
  --assertf~= -15032385529.0  ( -7.0 * 2147483647.0 )  1E-4 
  --test-- "float-auto-600"
      fat-i: -7.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
  --assertf~= -15032385529.0  fat-k  1E-4 
  --test-- "float-auto-601"
  --assertf~= 7.0  ( -7.0 * -1.0 )  1E-4 
  --test-- "float-auto-602"
      fat-i: -7.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
  --assertf~= 7.0  fat-k  1E-4 
  --test-- "float-auto-603"
  --assertf~= -21.0  ( -7.0 * 3.0 )  1E-4 
  --test-- "float-auto-604"
      fat-i: -7.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
  --assertf~= -21.0  fat-k  1E-4 
  --test-- "float-auto-605"
  --assertf~= 49.0  ( -7.0 * -7.0 )  1E-4 
  --test-- "float-auto-606"
      fat-i: -7.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
  --assertf~= 49.0  fat-k  1E-4 
  --test-- "float-auto-607"
  --assertf~= -35.0  ( -7.0 * 5.0 )  1E-4 
  --test-- "float-auto-608"
      fat-i: -7.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
  --assertf~= -35.0  fat-k  1E-4 
  --test-- "float-auto-609"
  --assertf~= -864197.523  ( -7.0 * 123456.789 )  1E-4 
  --test-- "float-auto-610"
      fat-i: -7.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
  --assertf~= -864197.523  fat-k  1E-4 
  --test-- "float-auto-611"
  --assertf~= -8.554636608E+33  ( -7.0 * 1.222090944E+33 )  1E-4 
  --test-- "float-auto-612"
      fat-i: -7.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
  --assertf~= -8.554636608E+33  fat-k  1E-4 
  --test-- "float-auto-613"
  --assertf~= -6.999993E-44  ( -7.0 * 9.99999E-45 )  1E-4 
  --test-- "float-auto-614"
      fat-i: -7.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
  --assertf~= -6.999993E-44  fat-k  1E-4 
  --test-- "float-auto-615"
  --assertf~= -5.39E+19  ( -7.0 * 7.7E+18 )  1E-4 
  --test-- "float-auto-616"
      fat-i: -7.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
  --assertf~= -5.39E+19  fat-k  1E-4 
  --test-- "float-auto-617"
  --assertf~= 0.0  ( 5.0 * 0.0 )  1E-4 
  --test-- "float-auto-618"
      fat-i: 5.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-619"
  --assertf~= -10737418240.0  ( 5.0 * -2147483648.0 )  1E-4 
  --test-- "float-auto-620"
      fat-i: 5.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
  --assertf~= -10737418240.0  fat-k  1E-4 
  --test-- "float-auto-621"
  --assertf~= 10737418235.0  ( 5.0 * 2147483647.0 )  1E-4 
  --test-- "float-auto-622"
      fat-i: 5.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
  --assertf~= 10737418235.0  fat-k  1E-4 
  --test-- "float-auto-623"
  --assertf~= -5.0  ( 5.0 * -1.0 )  1E-4 
  --test-- "float-auto-624"
      fat-i: 5.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
  --assertf~= -5.0  fat-k  1E-4 
  --test-- "float-auto-625"
  --assertf~= 15.0  ( 5.0 * 3.0 )  1E-4 
  --test-- "float-auto-626"
      fat-i: 5.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
  --assertf~= 15.0  fat-k  1E-4 
  --test-- "float-auto-627"
  --assertf~= -35.0  ( 5.0 * -7.0 )  1E-4 
  --test-- "float-auto-628"
      fat-i: 5.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
  --assertf~= -35.0  fat-k  1E-4 
  --test-- "float-auto-629"
  --assertf~= 25.0  ( 5.0 * 5.0 )  1E-4 
  --test-- "float-auto-630"
      fat-i: 5.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
  --assertf~= 25.0  fat-k  1E-4 
  --test-- "float-auto-631"
  --assertf~= 617283.945  ( 5.0 * 123456.789 )  1E-4 
  --test-- "float-auto-632"
      fat-i: 5.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
  --assertf~= 617283.945  fat-k  1E-4 
  --test-- "float-auto-633"
  --assertf~= 6.11045472E+33  ( 5.0 * 1.222090944E+33 )  1E-4 
  --test-- "float-auto-634"
      fat-i: 5.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
  --assertf~= 6.11045472E+33  fat-k  1E-4 
  --test-- "float-auto-635"
  --assertf~= 4.999995E-44  ( 5.0 * 9.99999E-45 )  1E-4 
  --test-- "float-auto-636"
      fat-i: 5.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
  --assertf~= 4.999995E-44  fat-k  1E-4 
  --test-- "float-auto-637"
  --assertf~= 3.85E+19  ( 5.0 * 7.7E+18 )  1E-4 
  --test-- "float-auto-638"
      fat-i: 5.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
  --assertf~= 3.85E+19  fat-k  1E-4 
  --test-- "float-auto-639"
  --assertf~= 0.0  ( 123456.789 * 0.0 )  1E-4 
  --test-- "float-auto-640"
      fat-i: 123456.789
      fat-j: 0.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-641"
  --assertf~= -265121435612086.0  ( 123456.789 * -2147483648.0 )  1E-4 
  --test-- "float-auto-642"
      fat-i: 123456.789
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
  --assertf~= -265121435612086.0  fat-k  1E-4 
  --test-- "float-auto-643"
  --assertf~= 265121435488630.0  ( 123456.789 * 2147483647.0 )  1E-4 
  --test-- "float-auto-644"
      fat-i: 123456.789
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
  --assertf~= 265121435488630.0  fat-k  1E-4 
  --test-- "float-auto-645"
  --assertf~= -123456.789  ( 123456.789 * -1.0 )  1E-4 
  --test-- "float-auto-646"
      fat-i: 123456.789
      fat-j: -1.0
      fat-k:  fat-i * fat-j
  --assertf~= -123456.789  fat-k  1E-4 
  --test-- "float-auto-647"
  --assertf~= 370370.367  ( 123456.789 * 3.0 )  1E-4 
  --test-- "float-auto-648"
      fat-i: 123456.789
      fat-j: 3.0
      fat-k:  fat-i * fat-j
  --assertf~= 370370.367  fat-k  1E-4 
  --test-- "float-auto-649"
  --assertf~= -864197.523  ( 123456.789 * -7.0 )  1E-4 
  --test-- "float-auto-650"
      fat-i: 123456.789
      fat-j: -7.0
      fat-k:  fat-i * fat-j
  --assertf~= -864197.523  fat-k  1E-4 
  --test-- "float-auto-651"
  --assertf~= 617283.945  ( 123456.789 * 5.0 )  1E-4 
  --test-- "float-auto-652"
      fat-i: 123456.789
      fat-j: 5.0
      fat-k:  fat-i * fat-j
  --assertf~= 617283.945  fat-k  1E-4 
  --test-- "float-auto-653"
  --assertf~= 15241578750.1905  ( 123456.789 * 123456.789 )  1E-4 
  --test-- "float-auto-654"
      fat-i: 123456.789
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
  --assertf~= 15241578750.1905  fat-k  1E-4 
  --test-- "float-auto-655"
  --assertf~= 1.50875423812219E+38  ( 123456.789 * 1.222090944E+33 )  1E-4 
  --test-- "float-auto-656"
      fat-i: 123456.789
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
  --assertf~= 1.50875423812219E+38  fat-k  1E-4 
  --test-- "float-auto-657"
  --assertf~= 1.23456665543211E-39  ( 123456.789 * 9.99999E-45 )  1E-4 
  --test-- "float-auto-658"
      fat-i: 123456.789
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
  --assertf~= 1.23456665543211E-39  fat-k  1E-4 
  --test-- "float-auto-659"
  --assertf~= 9.506172753E+23  ( 123456.789 * 7.7E+18 )  1E-4 
  --test-- "float-auto-660"
      fat-i: 123456.789
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
  --assertf~= 9.506172753E+23  fat-k  1E-4 
  --test-- "float-auto-661"
  --assertf~= 0.0  ( 1.222090944E+33 * 0.0 )  1E-4 
  --test-- "float-auto-662"
      fat-i: 1.222090944E+33
      fat-j: 0.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-663"
  --assertf~= -2.62442031860888E+42  ( 1.222090944E+33 * -2147483648.0 )  1E-4 
  --test-- "float-auto-664"
      fat-i: 1.222090944E+33
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
  --assertf~= -2.62442031860888E+42  fat-k  1E-4 
  --test-- "float-auto-665"
  --assertf~= 2.62442031738679E+42  ( 1.222090944E+33 * 2147483647.0 )  1E-4 
  --test-- "float-auto-666"
      fat-i: 1.222090944E+33
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
  --assertf~= 2.62442031738679E+42  fat-k  1E-4 
  --test-- "float-auto-667"
  --assertf~= -1.222090944E+33  ( 1.222090944E+33 * -1.0 )  1E-4 
  --test-- "float-auto-668"
      fat-i: 1.222090944E+33
      fat-j: -1.0
      fat-k:  fat-i * fat-j
  --assertf~= -1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-669"
  --assertf~= 3.666272832E+33  ( 1.222090944E+33 * 3.0 )  1E-4 
  --test-- "float-auto-670"
      fat-i: 1.222090944E+33
      fat-j: 3.0
      fat-k:  fat-i * fat-j
  --assertf~= 3.666272832E+33  fat-k  1E-4 
  --test-- "float-auto-671"
  --assertf~= -8.554636608E+33  ( 1.222090944E+33 * -7.0 )  1E-4 
  --test-- "float-auto-672"
      fat-i: 1.222090944E+33
      fat-j: -7.0
      fat-k:  fat-i * fat-j
  --assertf~= -8.554636608E+33  fat-k  1E-4 
  --test-- "float-auto-673"
  --assertf~= 6.11045472E+33  ( 1.222090944E+33 * 5.0 )  1E-4 
  --test-- "float-auto-674"
      fat-i: 1.222090944E+33
      fat-j: 5.0
      fat-k:  fat-i * fat-j
  --assertf~= 6.11045472E+33  fat-k  1E-4 
  --test-- "float-auto-675"
  --assertf~= 1.50875423812219E+38  ( 1.222090944E+33 * 123456.789 )  1E-4 
  --test-- "float-auto-676"
      fat-i: 1.222090944E+33
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
  --assertf~= 1.50875423812219E+38  fat-k  1E-4 
  --test-- "float-auto-677"
  --assertf~= 1.49350627540681E+66  ( 1.222090944E+33 * 1.222090944E+33 )  1E-4 
  --test-- "float-auto-678"
      fat-i: 1.222090944E+33
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
  --assertf~= 1.49350627540681E+66  fat-k  1E-4 
  --test-- "float-auto-679"
  --assertf~= 1.22208972190906E-11  ( 1.222090944E+33 * 9.99999E-45 )  1E-4 
  --test-- "float-auto-680"
      fat-i: 1.222090944E+33
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
  --assertf~= 1.22208972190906E-11  fat-k  1E-4 
  --test-- "float-auto-681"
  --assertf~= 9.4101002688E+51  ( 1.222090944E+33 * 7.7E+18 )  1E-4 
  --test-- "float-auto-682"
      fat-i: 1.222090944E+33
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
  --assertf~= 9.4101002688E+51  fat-k  1E-4 
  --test-- "float-auto-683"
  --assertf~= 0.0  ( 9.99999E-45 * 0.0 )  1E-4 
  --test-- "float-auto-684"
      fat-i: 9.99999E-45
      fat-j: 0.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-685"
  --assertf~= -2.14748150051635E-35  ( 9.99999E-45 * -2147483648.0 )  1E-4 
  --test-- "float-auto-686"
      fat-i: 9.99999E-45
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
  --assertf~= -2.14748150051635E-35  fat-k  1E-4 
  --test-- "float-auto-687"
  --assertf~= 2.14748149951635E-35  ( 9.99999E-45 * 2147483647.0 )  1E-4 
  --test-- "float-auto-688"
      fat-i: 9.99999E-45
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
  --assertf~= 2.14748149951635E-35  fat-k  1E-4 
  --test-- "float-auto-689"
  --assertf~= -9.99999E-45  ( 9.99999E-45 * -1.0 )  1E-4 
  --test-- "float-auto-690"
      fat-i: 9.99999E-45
      fat-j: -1.0
      fat-k:  fat-i * fat-j
  --assertf~= -9.99999E-45  fat-k  1E-4 
  --test-- "float-auto-691"
  --assertf~= 2.999997E-44  ( 9.99999E-45 * 3.0 )  1E-4 
  --test-- "float-auto-692"
      fat-i: 9.99999E-45
      fat-j: 3.0
      fat-k:  fat-i * fat-j
  --assertf~= 2.999997E-44  fat-k  1E-4 
  --test-- "float-auto-693"
  --assertf~= -6.999993E-44  ( 9.99999E-45 * -7.0 )  1E-4 
  --test-- "float-auto-694"
      fat-i: 9.99999E-45
      fat-j: -7.0
      fat-k:  fat-i * fat-j
  --assertf~= -6.999993E-44  fat-k  1E-4 
  --test-- "float-auto-695"
  --assertf~= 4.999995E-44  ( 9.99999E-45 * 5.0 )  1E-4 
  --test-- "float-auto-696"
      fat-i: 9.99999E-45
      fat-j: 5.0
      fat-k:  fat-i * fat-j
  --assertf~= 4.999995E-44  fat-k  1E-4 
  --test-- "float-auto-697"
  --assertf~= 1.23456665543211E-39  ( 9.99999E-45 * 123456.789 )  1E-4 
  --test-- "float-auto-698"
      fat-i: 9.99999E-45
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
  --assertf~= 1.23456665543211E-39  fat-k  1E-4 
  --test-- "float-auto-699"
  --assertf~= 1.22208972190906E-11  ( 9.99999E-45 * 1.222090944E+33 )  1E-4 
  --test-- "float-auto-700"
      fat-i: 9.99999E-45
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
  --assertf~= 1.22208972190906E-11  fat-k  1E-4 
  --test-- "float-auto-701"
  --assertf~= 9.99998000001E-89  ( 9.99999E-45 * 9.99999E-45 )  1E-4 
  --test-- "float-auto-702"
      fat-i: 9.99999E-45
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
  --assertf~= 9.99998000001E-89  fat-k  1E-4 
  --test-- "float-auto-703"
  --assertf~= 7.6999923E-26  ( 9.99999E-45 * 7.7E+18 )  1E-4 
  --test-- "float-auto-704"
      fat-i: 9.99999E-45
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
  --assertf~= 7.6999923E-26  fat-k  1E-4 
  --test-- "float-auto-705"
  --assertf~= 0.0  ( 7.7E+18 * 0.0 )  1E-4 
  --test-- "float-auto-706"
      fat-i: 7.7E+18
      fat-j: 0.0
      fat-k:  fat-i * fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-707"
  --assertf~= -1.65356240896E+28  ( 7.7E+18 * -2147483648.0 )  1E-4 
  --test-- "float-auto-708"
      fat-i: 7.7E+18
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
  --assertf~= -1.65356240896E+28  fat-k  1E-4 
  --test-- "float-auto-709"
  --assertf~= 1.65356240819E+28  ( 7.7E+18 * 2147483647.0 )  1E-4 
  --test-- "float-auto-710"
      fat-i: 7.7E+18
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
  --assertf~= 1.65356240819E+28  fat-k  1E-4 
  --test-- "float-auto-711"
  --assertf~= -7.7E+18  ( 7.7E+18 * -1.0 )  1E-4 
  --test-- "float-auto-712"
      fat-i: 7.7E+18
      fat-j: -1.0
      fat-k:  fat-i * fat-j
  --assertf~= -7.7E+18  fat-k  1E-4 
  --test-- "float-auto-713"
  --assertf~= 2.31E+19  ( 7.7E+18 * 3.0 )  1E-4 
  --test-- "float-auto-714"
      fat-i: 7.7E+18
      fat-j: 3.0
      fat-k:  fat-i * fat-j
  --assertf~= 2.31E+19  fat-k  1E-4 
  --test-- "float-auto-715"
  --assertf~= -5.39E+19  ( 7.7E+18 * -7.0 )  1E-4 
  --test-- "float-auto-716"
      fat-i: 7.7E+18
      fat-j: -7.0
      fat-k:  fat-i * fat-j
  --assertf~= -5.39E+19  fat-k  1E-4 
  --test-- "float-auto-717"
  --assertf~= 3.85E+19  ( 7.7E+18 * 5.0 )  1E-4 
  --test-- "float-auto-718"
      fat-i: 7.7E+18
      fat-j: 5.0
      fat-k:  fat-i * fat-j
  --assertf~= 3.85E+19  fat-k  1E-4 
  --test-- "float-auto-719"
  --assertf~= 9.506172753E+23  ( 7.7E+18 * 123456.789 )  1E-4 
  --test-- "float-auto-720"
      fat-i: 7.7E+18
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
  --assertf~= 9.506172753E+23  fat-k  1E-4 
  --test-- "float-auto-721"
  --assertf~= 9.4101002688E+51  ( 7.7E+18 * 1.222090944E+33 )  1E-4 
  --test-- "float-auto-722"
      fat-i: 7.7E+18
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
  --assertf~= 9.4101002688E+51  fat-k  1E-4 
  --test-- "float-auto-723"
  --assertf~= 7.6999923E-26  ( 7.7E+18 * 9.99999E-45 )  1E-4 
  --test-- "float-auto-724"
      fat-i: 7.7E+18
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
  --assertf~= 7.6999923E-26  fat-k  1E-4 
  --test-- "float-auto-725"
  --assertf~= 5.929E+37  ( 7.7E+18 * 7.7E+18 )  1E-4 
  --test-- "float-auto-726"
      fat-i: 7.7E+18
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
  --assertf~= 5.929E+37  fat-k  1E-4 
  --test-- "float-auto-727"
  --assertf~= 0.0  ( 0.0 / -2147483648.0 )  1E-4 
  --test-- "float-auto-728"
      fat-i: 0.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-729"
  --assertf~= 0.0  ( 0.0 / 2147483647.0 )  1E-4 
  --test-- "float-auto-730"
      fat-i: 0.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-731"
  --assertf~= 0.0  ( 0.0 / -1.0 )  1E-4 
  --test-- "float-auto-732"
      fat-i: 0.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-733"
  --assertf~= 0.0  ( 0.0 / 3.0 )  1E-4 
  --test-- "float-auto-734"
      fat-i: 0.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-735"
  --assertf~= 0.0  ( 0.0 / -7.0 )  1E-4 
  --test-- "float-auto-736"
      fat-i: 0.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-737"
  --assertf~= 0.0  ( 0.0 / 5.0 )  1E-4 
  --test-- "float-auto-738"
      fat-i: 0.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-739"
  --assertf~= 0.0  ( 0.0 / 123456.789 )  1E-4 
  --test-- "float-auto-740"
      fat-i: 0.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-741"
  --assertf~= 0.0  ( 0.0 / 1.222090944E+33 )  1E-4 
  --test-- "float-auto-742"
      fat-i: 0.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-743"
  --assertf~= 0.0  ( 0.0 / 9.99999E-45 )  1E-4 
  --test-- "float-auto-744"
      fat-i: 0.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-745"
  --assertf~= 0.0  ( 0.0 / 7.7E+18 )  1E-4 
  --test-- "float-auto-746"
      fat-i: 0.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
  --assertf~= 0.0  fat-k  1E-4 
  --test-- "float-auto-747"
  --assertf~= 1.0  ( -2147483648.0 / -2147483648.0 )  1E-4 
  --test-- "float-auto-748"
      fat-i: -2147483648.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
  --assertf~= 1.0  fat-k  1E-4 
  --test-- "float-auto-749"
  --assertf~= -1.00000000046566  ( -2147483648.0 / 2147483647.0 )  1E-4 
  --test-- "float-auto-750"
      fat-i: -2147483648.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
  --assertf~= -1.00000000046566  fat-k  1E-4 
  --test-- "float-auto-751"
  --assertf~= 2147483648.0  ( -2147483648.0 / -1.0 )  1E-4 
  --test-- "float-auto-752"
      fat-i: -2147483648.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
  --assertf~= 2147483648.0  fat-k  1E-4 
  --test-- "float-auto-753"
  --assertf~= -715827882.666667  ( -2147483648.0 / 3.0 )  1E-4 
  --test-- "float-auto-754"
      fat-i: -2147483648.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
  --assertf~= -715827882.666667  fat-k  1E-4 
  --test-- "float-auto-755"
  --assertf~= 306783378.285714  ( -2147483648.0 / -7.0 )  1E-4 
  --test-- "float-auto-756"
      fat-i: -2147483648.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
  --assertf~= 306783378.285714  fat-k  1E-4 
  --test-- "float-auto-757"
  --assertf~= -429496729.6  ( -2147483648.0 / 5.0 )  1E-4 
  --test-- "float-auto-758"
      fat-i: -2147483648.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
  --assertf~= -429496729.6  fat-k  1E-4 
  --test-- "float-auto-759"
  --assertf~= -17394.617707091  ( -2147483648.0 / 123456.789 )  1E-4 
  --test-- "float-auto-760"
      fat-i: -2147483648.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
  --assertf~= -17394.617707091  fat-k  1E-4 
  --test-- "float-auto-761"
  --assertf~= -1.75722081776592E-24  ( -2147483648.0 / 1.222090944E+33 )  1E-4 
  --test-- "float-auto-762"
      fat-i: -2147483648.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
  --assertf~= -1.75722081776592E-24  fat-k  1E-4 
  --test-- "float-auto-763"
  --assertf~= -2.1474857954858E+53  ( -2147483648.0 / 9.99999E-45 )  1E-4 
  --test-- "float-auto-764"
      fat-i: -2147483648.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
  --assertf~= -2.1474857954858E+53  fat-k  1E-4 
  --test-- "float-auto-765"
  --assertf~= -2.7889398025974E-10  ( -2147483648.0 / 7.7E+18 )  1E-4 
  --test-- "float-auto-766"
      fat-i: -2147483648.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
  --assertf~= -2.7889398025974E-10  fat-k  1E-4 
  --test-- "float-auto-767"
  --assertf~= -0.999999999534339  ( 2147483647.0 / -2147483648.0 )  1E-4 
  --test-- "float-auto-768"
      fat-i: 2147483647.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
  --assertf~= -0.999999999534339  fat-k  1E-4 
  --test-- "float-auto-769"
  --assertf~= 1.0  ( 2147483647.0 / 2147483647.0 )  1E-4 
  --test-- "float-auto-770"
      fat-i: 2147483647.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
  --assertf~= 1.0  fat-k  1E-4 
  --test-- "float-auto-771"
  --assertf~= -2147483647.0  ( 2147483647.0 / -1.0 )  1E-4 
  --test-- "float-auto-772"
      fat-i: 2147483647.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
  --assertf~= -2147483647.0  fat-k  1E-4 
  --test-- "float-auto-773"
  --assertf~= 715827882.333333  ( 2147483647.0 / 3.0 )  1E-4 
  --test-- "float-auto-774"
      fat-i: 2147483647.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
  --assertf~= 715827882.333333  fat-k  1E-4 
  --test-- "float-auto-775"
  --assertf~= -306783378.142857  ( 2147483647.0 / -7.0 )  1E-4 
  --test-- "float-auto-776"
      fat-i: 2147483647.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
  --assertf~= -306783378.142857  fat-k  1E-4 
  --test-- "float-auto-777"
  --assertf~= 429496729.4  ( 2147483647.0 / 5.0 )  1E-4 
  --test-- "float-auto-778"
      fat-i: 2147483647.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
  --assertf~= 429496729.4  fat-k  1E-4 
  --test-- "float-auto-779"
  --assertf~= 17394.617698991  ( 2147483647.0 / 123456.789 )  1E-4 
  --test-- "float-auto-780"
      fat-i: 2147483647.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
  --assertf~= 17394.617698991  fat-k  1E-4 
  --test-- "float-auto-781"
  --assertf~= 1.75722081694765E-24  ( 2147483647.0 / 1.222090944E+33 )  1E-4 
  --test-- "float-auto-782"
      fat-i: 2147483647.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
  --assertf~= 1.75722081694765E-24  fat-k  1E-4 
  --test-- "float-auto-783"
  --assertf~= 2.14748579448579E+53  ( 2147483647.0 / 9.99999E-45 )  1E-4 
  --test-- "float-auto-784"
      fat-i: 2147483647.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
  --assertf~= 2.14748579448579E+53  fat-k  1E-4 
  --test-- "float-auto-785"
  --assertf~= 2.7889398012987E-10  ( 2147483647.0 / 7.7E+18 )  1E-4 
  --test-- "float-auto-786"
      fat-i: 2147483647.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
  --assertf~= 2.7889398012987E-10  fat-k  1E-4 
  --test-- "float-auto-787"
  --assertf~= 4.65661287307739E-10  ( -1.0 / -2147483648.0 )  1E-4 
  --test-- "float-auto-788"
      fat-i: -1.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
  --assertf~= 4.65661287307739E-10  fat-k  1E-4 
  --test-- "float-auto-789"
  --assertf~= -4.6566128752458E-10  ( -1.0 / 2147483647.0 )  1E-4 
  --test-- "float-auto-790"
      fat-i: -1.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
  --assertf~= -4.6566128752458E-10  fat-k  1E-4 
  --test-- "float-auto-791"
  --assertf~= 1.0  ( -1.0 / -1.0 )  1E-4 
  --test-- "float-auto-792"
      fat-i: -1.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
  --assertf~= 1.0  fat-k  1E-4 
  --test-- "float-auto-793"
  --assertf~= -0.333333333333333  ( -1.0 / 3.0 )  1E-4 
  --test-- "float-auto-794"
      fat-i: -1.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
  --assertf~= -0.333333333333333  fat-k  1E-4 
  --test-- "float-auto-795"
  --assertf~= 0.142857142857143  ( -1.0 / -7.0 )  1E-4 
  --test-- "float-auto-796"
      fat-i: -1.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
  --assertf~= 0.142857142857143  fat-k  1E-4 
  --test-- "float-auto-797"
  --assertf~= -0.2  ( -1.0 / 5.0 )  1E-4 
  --test-- "float-auto-798"
      fat-i: -1.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
  --assertf~= -0.2  fat-k  1E-4 
  --test-- "float-auto-799"
  --assertf~= -8.10000007371E-6  ( -1.0 / 123456.789 )  1E-4 
  --test-- "float-auto-800"
      fat-i: -1.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
  --assertf~= -8.10000007371E-6  fat-k  1E-4 
  --test-- "float-auto-801"
  --assertf~= -8.18269708084835E-34  ( -1.0 / 1.222090944E+33 )  1E-4 
  --test-- "float-auto-802"
      fat-i: -1.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
  --assertf~= -8.18269708084835E-34  fat-k  1E-4 
  --test-- "float-auto-803"
  --assertf~= -1.000001000001E+44  ( -1.0 / 9.99999E-45 )  1E-4 
  --test-- "float-auto-804"
      fat-i: -1.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
  --assertf~= -1.000001000001E+44  fat-k  1E-4 
  --test-- "float-auto-805"
  --assertf~= -1.2987012987013E-19  ( -1.0 / 7.7E+18 )  1E-4 
  --test-- "float-auto-806"
      fat-i: -1.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
  --assertf~= -1.2987012987013E-19  fat-k  1E-4 
  --test-- "float-auto-807"
  --assertf~= -1.39698386192322E-9  ( 3.0 / -2147483648.0 )  1E-4 
  --test-- "float-auto-808"
      fat-i: 3.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
  --assertf~= -1.39698386192322E-9  fat-k  1E-4 
  --test-- "float-auto-809"
  --assertf~= 1.39698386257374E-9  ( 3.0 / 2147483647.0 )  1E-4 
  --test-- "float-auto-810"
      fat-i: 3.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
  --assertf~= 1.39698386257374E-9  fat-k  1E-4 
  --test-- "float-auto-811"
  --assertf~= -3.0  ( 3.0 / -1.0 )  1E-4 
  --test-- "float-auto-812"
      fat-i: 3.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
  --assertf~= -3.0  fat-k  1E-4 
  --test-- "float-auto-813"
  --assertf~= 1.0  ( 3.0 / 3.0 )  1E-4 
  --test-- "float-auto-814"
      fat-i: 3.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
  --assertf~= 1.0  fat-k  1E-4 
  --test-- "float-auto-815"
  --assertf~= -0.428571428571429  ( 3.0 / -7.0 )  1E-4 
  --test-- "float-auto-816"
      fat-i: 3.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
  --assertf~= -0.428571428571429  fat-k  1E-4 
  --test-- "float-auto-817"
  --assertf~= 0.6  ( 3.0 / 5.0 )  1E-4 
  --test-- "float-auto-818"
      fat-i: 3.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
  --assertf~= 0.6  fat-k  1E-4 
  --test-- "float-auto-819"
  --assertf~= 2.430000022113E-5  ( 3.0 / 123456.789 )  1E-4 
  --test-- "float-auto-820"
      fat-i: 3.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
  --assertf~= 2.430000022113E-5  fat-k  1E-4 
  --test-- "float-auto-821"
  --assertf~= 2.4548091242545E-33  ( 3.0 / 1.222090944E+33 )  1E-4 
  --test-- "float-auto-822"
      fat-i: 3.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
  --assertf~= 2.4548091242545E-33  fat-k  1E-4 
  --test-- "float-auto-823"
  --assertf~= 3.000003000003E+44  ( 3.0 / 9.99999E-45 )  1E-4 
  --test-- "float-auto-824"
      fat-i: 3.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
  --assertf~= 3.000003000003E+44  fat-k  1E-4 
  --test-- "float-auto-825"
  --assertf~= 3.8961038961039E-19  ( 3.0 / 7.7E+18 )  1E-4 
  --test-- "float-auto-826"
      fat-i: 3.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
  --assertf~= 3.8961038961039E-19  fat-k  1E-4 
  --test-- "float-auto-827"
  --assertf~= 3.25962901115417E-9  ( -7.0 / -2147483648.0 )  1E-4 
  --test-- "float-auto-828"
      fat-i: -7.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
  --assertf~= 3.25962901115417E-9  fat-k  1E-4 
  --test-- "float-auto-829"
  --assertf~= -3.25962901267206E-9  ( -7.0 / 2147483647.0 )  1E-4 
  --test-- "float-auto-830"
      fat-i: -7.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
  --assertf~= -3.25962901267206E-9  fat-k  1E-4 
  --test-- "float-auto-831"
  --assertf~= 7.0  ( -7.0 / -1.0 )  1E-4 
  --test-- "float-auto-832"
      fat-i: -7.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
  --assertf~= 7.0  fat-k  1E-4 
  --test-- "float-auto-833"
  --assertf~= -2.33333333333333  ( -7.0 / 3.0 )  1E-4 
  --test-- "float-auto-834"
      fat-i: -7.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
  --assertf~= -2.33333333333333  fat-k  1E-4 
  --test-- "float-auto-835"
  --assertf~= 1.0  ( -7.0 / -7.0 )  1E-4 
  --test-- "float-auto-836"
      fat-i: -7.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
  --assertf~= 1.0  fat-k  1E-4 
  --test-- "float-auto-837"
  --assertf~= -1.4  ( -7.0 / 5.0 )  1E-4 
  --test-- "float-auto-838"
      fat-i: -7.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
  --assertf~= -1.4  fat-k  1E-4 
  --test-- "float-auto-839"
  --assertf~= -5.670000051597E-5  ( -7.0 / 123456.789 )  1E-4 
  --test-- "float-auto-840"
      fat-i: -7.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
  --assertf~= -5.670000051597E-5  fat-k  1E-4 
  --test-- "float-auto-841"
  --assertf~= -5.72788795659384E-33  ( -7.0 / 1.222090944E+33 )  1E-4 
  --test-- "float-auto-842"
      fat-i: -7.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
  --assertf~= -5.72788795659384E-33  fat-k  1E-4 
  --test-- "float-auto-843"
  --assertf~= -7.000007000007E+44  ( -7.0 / 9.99999E-45 )  1E-4 
  --test-- "float-auto-844"
      fat-i: -7.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
  --assertf~= -7.000007000007E+44  fat-k  1E-4 
  --test-- "float-auto-845"
  --assertf~= -9.09090909090909E-19  ( -7.0 / 7.7E+18 )  1E-4 
  --test-- "float-auto-846"
      fat-i: -7.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
  --assertf~= -9.09090909090909E-19  fat-k  1E-4 
  --test-- "float-auto-847"
  --assertf~= -2.3283064365387E-9  ( 5.0 / -2147483648.0 )  1E-4 
  --test-- "float-auto-848"
      fat-i: 5.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
  --assertf~= -2.3283064365387E-9  fat-k  1E-4 
  --test-- "float-auto-849"
  --assertf~= 2.3283064376229E-9  ( 5.0 / 2147483647.0 )  1E-4 
  --test-- "float-auto-850"
      fat-i: 5.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
  --assertf~= 2.3283064376229E-9  fat-k  1E-4 
  --test-- "float-auto-851"
  --assertf~= -5.0  ( 5.0 / -1.0 )  1E-4 
  --test-- "float-auto-852"
      fat-i: 5.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
  --assertf~= -5.0  fat-k  1E-4 
  --test-- "float-auto-853"
  --assertf~= 1.66666666666667  ( 5.0 / 3.0 )  1E-4 
  --test-- "float-auto-854"
      fat-i: 5.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
  --assertf~= 1.66666666666667  fat-k  1E-4 
  --test-- "float-auto-855"
  --assertf~= -0.714285714285714  ( 5.0 / -7.0 )  1E-4 
  --test-- "float-auto-856"
      fat-i: 5.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
  --assertf~= -0.714285714285714  fat-k  1E-4 
  --test-- "float-auto-857"
  --assertf~= 1.0  ( 5.0 / 5.0 )  1E-4 
  --test-- "float-auto-858"
      fat-i: 5.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
  --assertf~= 1.0  fat-k  1E-4 
  --test-- "float-auto-859"
  --assertf~= 4.050000036855E-5  ( 5.0 / 123456.789 )  1E-4 
  --test-- "float-auto-860"
      fat-i: 5.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
  --assertf~= 4.050000036855E-5  fat-k  1E-4 
  --test-- "float-auto-861"
  --assertf~= 4.09134854042417E-33  ( 5.0 / 1.222090944E+33 )  1E-4 
  --test-- "float-auto-862"
      fat-i: 5.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
  --assertf~= 4.09134854042417E-33  fat-k  1E-4 
  --test-- "float-auto-863"
  --assertf~= 5.000005000005E+44  ( 5.0 / 9.99999E-45 )  1E-4 
  --test-- "float-auto-864"
      fat-i: 5.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
  --assertf~= 5.000005000005E+44  fat-k  1E-4 
  --test-- "float-auto-865"
  --assertf~= 6.49350649350649E-19  ( 5.0 / 7.7E+18 )  1E-4 
  --test-- "float-auto-866"
      fat-i: 5.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
  --assertf~= 6.49350649350649E-19  fat-k  1E-4 
  --test-- "float-auto-867"
  --assertf~= -5.74890472926199E-5  ( 123456.789 / -2147483648.0 )  1E-4 
  --test-- "float-auto-868"
      fat-i: 123456.789
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
  --assertf~= -5.74890472926199E-5  fat-k  1E-4 
  --test-- "float-auto-869"
  --assertf~= 5.74890473193904E-5  ( 123456.789 / 2147483647.0 )  1E-4 
  --test-- "float-auto-870"
      fat-i: 123456.789
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
  --assertf~= 5.74890473193904E-5  fat-k  1E-4 
  --test-- "float-auto-871"
  --assertf~= -123456.789  ( 123456.789 / -1.0 )  1E-4 
  --test-- "float-auto-872"
      fat-i: 123456.789
      fat-j: -1.0
      fat-k:  fat-i / fat-j
  --assertf~= -123456.789  fat-k  1E-4 
  --test-- "float-auto-873"
  --assertf~= 41152.263  ( 123456.789 / 3.0 )  1E-4 
  --test-- "float-auto-874"
      fat-i: 123456.789
      fat-j: 3.0
      fat-k:  fat-i / fat-j
  --assertf~= 41152.263  fat-k  1E-4 
  --test-- "float-auto-875"
  --assertf~= -17636.6841428571  ( 123456.789 / -7.0 )  1E-4 
  --test-- "float-auto-876"
      fat-i: 123456.789
      fat-j: -7.0
      fat-k:  fat-i / fat-j
  --assertf~= -17636.6841428571  fat-k  1E-4 
  --test-- "float-auto-877"
  --assertf~= 24691.3578  ( 123456.789 / 5.0 )  1E-4 
  --test-- "float-auto-878"
      fat-i: 123456.789
      fat-j: 5.0
      fat-k:  fat-i / fat-j
  --assertf~= 24691.3578  fat-k  1E-4 
  --test-- "float-auto-879"
  --assertf~= 1.0  ( 123456.789 / 123456.789 )  1E-4 
  --test-- "float-auto-880"
      fat-i: 123456.789
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
  --assertf~= 1.0  fat-k  1E-4 
  --test-- "float-auto-881"
  --assertf~= 1.01020950696121E-28  ( 123456.789 / 1.222090944E+33 )  1E-4 
  --test-- "float-auto-882"
      fat-i: 123456.789
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
  --assertf~= 1.01020950696121E-28  fat-k  1E-4 
  --test-- "float-auto-883"
  --assertf~= 1.23456912456912E+49  ( 123456.789 / 9.99999E-45 )  1E-4 
  --test-- "float-auto-884"
      fat-i: 123456.789
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
  --assertf~= 1.23456912456912E+49  fat-k  1E-4 
  --test-- "float-auto-885"
  --assertf~= 1.60333492207792E-14  ( 123456.789 / 7.7E+18 )  1E-4 
  --test-- "float-auto-886"
      fat-i: 123456.789
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
  --assertf~= 1.60333492207792E-14  fat-k  1E-4 
  --test-- "float-auto-887"
  --assertf~= -5.6908044219017E+23  ( 1.222090944E+33 / -2147483648.0 )  1E-4 
  --test-- "float-auto-888"
      fat-i: 1.222090944E+33
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
  --assertf~= -5.6908044219017E+23  fat-k  1E-4 
  --test-- "float-auto-889"
  --assertf~= 5.69080442455169E+23  ( 1.222090944E+33 / 2147483647.0 )  1E-4 
  --test-- "float-auto-890"
      fat-i: 1.222090944E+33
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
  --assertf~= 5.69080442455169E+23  fat-k  1E-4 
  --test-- "float-auto-891"
  --assertf~= -1.222090944E+33  ( 1.222090944E+33 / -1.0 )  1E-4 
  --test-- "float-auto-892"
      fat-i: 1.222090944E+33
      fat-j: -1.0
      fat-k:  fat-i / fat-j
  --assertf~= -1.222090944E+33  fat-k  1E-4 
  --test-- "float-auto-893"
  --assertf~= 4.07363648E+32  ( 1.222090944E+33 / 3.0 )  1E-4 
  --test-- "float-auto-894"
      fat-i: 1.222090944E+33
      fat-j: 3.0
      fat-k:  fat-i / fat-j
  --assertf~= 4.07363648E+32  fat-k  1E-4 
  --test-- "float-auto-895"
  --assertf~= -1.74584420571429E+32  ( 1.222090944E+33 / -7.0 )  1E-4 
  --test-- "float-auto-896"
      fat-i: 1.222090944E+33
      fat-j: -7.0
      fat-k:  fat-i / fat-j
  --assertf~= -1.74584420571429E+32  fat-k  1E-4 
  --test-- "float-auto-897"
  --assertf~= 2.444181888E+32  ( 1.222090944E+33 / 5.0 )  1E-4 
  --test-- "float-auto-898"
      fat-i: 1.222090944E+33
      fat-j: 5.0
      fat-k:  fat-i / fat-j
  --assertf~= 2.444181888E+32  fat-k  1E-4 
  --test-- "float-auto-899"
  --assertf~= 9.89893673648032E+27  ( 1.222090944E+33 / 123456.789 )  1E-4 
  --test-- "float-auto-900"
      fat-i: 1.222090944E+33
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
  --assertf~= 9.89893673648032E+27  fat-k  1E-4 
  --test-- "float-auto-901"
  --assertf~= 1.0  ( 1.222090944E+33 / 1.222090944E+33 )  1E-4 
  --test-- "float-auto-902"
      fat-i: 1.222090944E+33
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
  --assertf~= 1.0  fat-k  1E-4 
  --test-- "float-auto-903"
  --assertf~= 1.22209216609217E+77  ( 1.222090944E+33 / 9.99999E-45 )  1E-4 
  --test-- "float-auto-904"
      fat-i: 1.222090944E+33
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
  --assertf~= 1.22209216609217E+77  fat-k  1E-4 
  --test-- "float-auto-905"
  --assertf~= 158713109610390.0  ( 1.222090944E+33 / 7.7E+18 )  1E-4 
  --test-- "float-auto-906"
      fat-i: 1.222090944E+33
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
  --assertf~= 158713109610390.0  fat-k  1E-4 
  --test-- "float-auto-907"
  --assertf~= -4.65660821646452E-54  ( 9.99999E-45 / -2147483648.0 )  1E-4 
  --test-- "float-auto-908"
      fat-i: 9.99999E-45
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
  --assertf~= -4.65660821646452E-54  fat-k  1E-4 
  --test-- "float-auto-909"
  --assertf~= 4.65660821863292E-54  ( 9.99999E-45 / 2147483647.0 )  1E-4 
  --test-- "float-auto-910"
      fat-i: 9.99999E-45
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
  --assertf~= 4.65660821863292E-54  fat-k  1E-4 
  --test-- "float-auto-911"
  --assertf~= -9.99999E-45  ( 9.99999E-45 / -1.0 )  1E-4 
  --test-- "float-auto-912"
      fat-i: 9.99999E-45
      fat-j: -1.0
      fat-k:  fat-i / fat-j
  --assertf~= -9.99999E-45  fat-k  1E-4 
  --test-- "float-auto-913"
  --assertf~= 3.33333E-45  ( 9.99999E-45 / 3.0 )  1E-4 
  --test-- "float-auto-914"
      fat-i: 9.99999E-45
      fat-j: 3.0
      fat-k:  fat-i / fat-j
  --assertf~= 3.33333E-45  fat-k  1E-4 
  --test-- "float-auto-915"
  --assertf~= -1.42857E-45  ( 9.99999E-45 / -7.0 )  1E-4 
  --test-- "float-auto-916"
      fat-i: 9.99999E-45
      fat-j: -7.0
      fat-k:  fat-i / fat-j
  --assertf~= -1.42857E-45  fat-k  1E-4 
  --test-- "float-auto-917"
  --assertf~= 1.999998E-45  ( 9.99999E-45 / 5.0 )  1E-4 
  --test-- "float-auto-918"
      fat-i: 9.99999E-45
      fat-j: 5.0
      fat-k:  fat-i / fat-j
  --assertf~= 1.999998E-45  fat-k  1E-4 
  --test-- "float-auto-919"
  --assertf~= 8.09999197370993E-50  ( 9.99999E-45 / 123456.789 )  1E-4 
  --test-- "float-auto-920"
      fat-i: 9.99999E-45
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
  --assertf~= 8.09999197370993E-50  fat-k  1E-4 
  --test-- "float-auto-921"
  --assertf~= 8.18268889815127E-78  ( 9.99999E-45 / 1.222090944E+33 )  1E-4 
  --test-- "float-auto-922"
      fat-i: 9.99999E-45
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
  --assertf~= 8.18268889815127E-78  fat-k  1E-4 
  --test-- "float-auto-923"
  --assertf~= 1.0  ( 9.99999E-45 / 9.99999E-45 )  1E-4 
  --test-- "float-auto-924"
      fat-i: 9.99999E-45
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
  --assertf~= 1.0  fat-k  1E-4 
  --test-- "float-auto-925"
  --assertf~= 1.2987E-63  ( 9.99999E-45 / 7.7E+18 )  1E-4 
  --test-- "float-auto-926"
      fat-i: 9.99999E-45
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
  --assertf~= 1.2987E-63  fat-k  1E-4 
  --test-- "float-auto-927"
  --assertf~= -3585591912.26959  ( 7.7E+18 / -2147483648.0 )  1E-4 
  --test-- "float-auto-928"
      fat-i: 7.7E+18
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
  --assertf~= -3585591912.26959  fat-k  1E-4 
  --test-- "float-auto-929"
  --assertf~= 3585591913.93926  ( 7.7E+18 / 2147483647.0 )  1E-4 
  --test-- "float-auto-930"
      fat-i: 7.7E+18
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
  --assertf~= 3585591913.93926  fat-k  1E-4 
  --test-- "float-auto-931"
  --assertf~= -7.7E+18  ( 7.7E+18 / -1.0 )  1E-4 
  --test-- "float-auto-932"
      fat-i: 7.7E+18
      fat-j: -1.0
      fat-k:  fat-i / fat-j
  --assertf~= -7.7E+18  fat-k  1E-4 
  --test-- "float-auto-933"
  --assertf~= 2.56666666666667E+18  ( 7.7E+18 / 3.0 )  1E-4 
  --test-- "float-auto-934"
      fat-i: 7.7E+18
      fat-j: 3.0
      fat-k:  fat-i / fat-j
  --assertf~= 2.56666666666667E+18  fat-k  1E-4 
  --test-- "float-auto-935"
  --assertf~= -1.1E+18  ( 7.7E+18 / -7.0 )  1E-4 
  --test-- "float-auto-936"
      fat-i: 7.7E+18
      fat-j: -7.0
      fat-k:  fat-i / fat-j
  --assertf~= -1.1E+18  fat-k  1E-4 
  --test-- "float-auto-937"
  --assertf~= 1.54E+18  ( 7.7E+18 / 5.0 )  1E-4 
  --test-- "float-auto-938"
      fat-i: 7.7E+18
      fat-j: 5.0
      fat-k:  fat-i / fat-j
  --assertf~= 1.54E+18  fat-k  1E-4 
  --test-- "float-auto-939"
  --assertf~= 62370000567567.0  ( 7.7E+18 / 123456.789 )  1E-4 
  --test-- "float-auto-940"
      fat-i: 7.7E+18
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
  --assertf~= 62370000567567.0  fat-k  1E-4 
  --test-- "float-auto-941"
  --assertf~= 6.30067675225323E-15  ( 7.7E+18 / 1.222090944E+33 )  1E-4 
  --test-- "float-auto-942"
      fat-i: 7.7E+18
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
  --assertf~= 6.30067675225323E-15  fat-k  1E-4 
  --test-- "float-auto-943"
  --assertf~= 7.7000077000077E+62  ( 7.7E+18 / 9.99999E-45 )  1E-4 
  --test-- "float-auto-944"
      fat-i: 7.7E+18
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
  --assertf~= 7.7000077000077E+62  fat-k  1E-4 
  --test-- "float-auto-945"
  --assertf~= 1.0  ( 7.7E+18 / 7.7E+18 )  1E-4 
  --test-- "float-auto-946"
      fat-i: 7.7E+18
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
  --assertf~= 1.0  fat-k  1E-4 

float-auto-test-func: func [
	/local
		fat-i [float!]
		fat-j [float!]
		fat-k [float!]
][
    --test-- "float-auto-947"
      fat-i: 0.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-948"
      fat-i: 0.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
    --assertf~= -2147483648.0  fat-k  1E-4 
    --test-- "float-auto-949"
      fat-i: 0.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
    --assertf~= 2147483647.0  fat-k  1E-4 
    --test-- "float-auto-950"
      fat-i: 0.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
    --assertf~= -1.0  fat-k  1E-4 
    --test-- "float-auto-951"
      fat-i: 0.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
    --assertf~= 3.0  fat-k  1E-4 
    --test-- "float-auto-952"
      fat-i: 0.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
    --assertf~= -7.0  fat-k  1E-4 
    --test-- "float-auto-953"
      fat-i: 0.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
    --assertf~= 5.0  fat-k  1E-4 
    --test-- "float-auto-954"
      fat-i: 0.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
    --assertf~= 123456.789  fat-k  1E-4 
    --test-- "float-auto-955"
      fat-i: 0.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-956"
      fat-i: 0.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
    --assertf~= 9.99999E-45  fat-k  1E-4 
    --test-- "float-auto-957"
      fat-i: 0.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-958"
      fat-i: -2147483648.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
    --assertf~= -2147483648.0  fat-k  1E-4 
    --test-- "float-auto-959"
      fat-i: -2147483648.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
    --assertf~= -4294967296.0  fat-k  1E-4 
    --test-- "float-auto-960"
      fat-i: -2147483648.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
    --assertf~= -1.0  fat-k  1E-4 
    --test-- "float-auto-961"
      fat-i: -2147483648.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
    --assertf~= -2147483649.0  fat-k  1E-4 
    --test-- "float-auto-962"
      fat-i: -2147483648.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
    --assertf~= -2147483645.0  fat-k  1E-4 
    --test-- "float-auto-963"
      fat-i: -2147483648.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
    --assertf~= -2147483655.0  fat-k  1E-4 
    --test-- "float-auto-964"
      fat-i: -2147483648.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
    --assertf~= -2147483643.0  fat-k  1E-4 
    --test-- "float-auto-965"
      fat-i: -2147483648.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
    --assertf~= -2147360191.211  fat-k  1E-4 
    --test-- "float-auto-966"
      fat-i: -2147483648.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-967"
      fat-i: -2147483648.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
    --assertf~= -2147483648.0  fat-k  1E-4 
    --test-- "float-auto-968"
      fat-i: -2147483648.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
    --assertf~= 7.69999999785252E+18  fat-k  1E-4 
    --test-- "float-auto-969"
      fat-i: 2147483647.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
    --assertf~= 2147483647.0  fat-k  1E-4 
    --test-- "float-auto-970"
      fat-i: 2147483647.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
    --assertf~= -1.0  fat-k  1E-4 
    --test-- "float-auto-971"
      fat-i: 2147483647.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
    --assertf~= 4294967294.0  fat-k  1E-4 
    --test-- "float-auto-972"
      fat-i: 2147483647.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
    --assertf~= 2147483646.0  fat-k  1E-4 
    --test-- "float-auto-973"
      fat-i: 2147483647.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
    --assertf~= 2147483650.0  fat-k  1E-4 
    --test-- "float-auto-974"
      fat-i: 2147483647.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
    --assertf~= 2147483640.0  fat-k  1E-4 
    --test-- "float-auto-975"
      fat-i: 2147483647.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
    --assertf~= 2147483652.0  fat-k  1E-4 
    --test-- "float-auto-976"
      fat-i: 2147483647.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
    --assertf~= 2147607103.789  fat-k  1E-4 
    --test-- "float-auto-977"
      fat-i: 2147483647.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-978"
      fat-i: 2147483647.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
    --assertf~= 2147483647.0  fat-k  1E-4 
    --test-- "float-auto-979"
      fat-i: 2147483647.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
    --assertf~= 7.70000000214748E+18  fat-k  1E-4 
    --test-- "float-auto-980"
      fat-i: -1.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
    --assertf~= -1.0  fat-k  1E-4 
    --test-- "float-auto-981"
      fat-i: -1.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
    --assertf~= -2147483649.0  fat-k  1E-4 
    --test-- "float-auto-982"
      fat-i: -1.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
    --assertf~= 2147483646.0  fat-k  1E-4 
    --test-- "float-auto-983"
      fat-i: -1.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
    --assertf~= -2.0  fat-k  1E-4 
    --test-- "float-auto-984"
      fat-i: -1.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
    --assertf~= 2.0  fat-k  1E-4 
    --test-- "float-auto-985"
      fat-i: -1.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
    --assertf~= -8.0  fat-k  1E-4 
    --test-- "float-auto-986"
      fat-i: -1.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
    --assertf~= 4.0  fat-k  1E-4 
    --test-- "float-auto-987"
      fat-i: -1.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
    --assertf~= 123455.789  fat-k  1E-4 
    --test-- "float-auto-988"
      fat-i: -1.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-989"
      fat-i: -1.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
    --assertf~= -1.0  fat-k  1E-4 
    --test-- "float-auto-990"
      fat-i: -1.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-991"
      fat-i: 3.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
    --assertf~= 3.0  fat-k  1E-4 
    --test-- "float-auto-992"
      fat-i: 3.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
    --assertf~= -2147483645.0  fat-k  1E-4 
    --test-- "float-auto-993"
      fat-i: 3.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
    --assertf~= 2147483650.0  fat-k  1E-4 
    --test-- "float-auto-994"
      fat-i: 3.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
    --assertf~= 2.0  fat-k  1E-4 
    --test-- "float-auto-995"
      fat-i: 3.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
    --assertf~= 6.0  fat-k  1E-4 
    --test-- "float-auto-996"
      fat-i: 3.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
    --assertf~= -4.0  fat-k  1E-4 
    --test-- "float-auto-997"
      fat-i: 3.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
    --assertf~= 8.0  fat-k  1E-4 
    --test-- "float-auto-998"
      fat-i: 3.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
    --assertf~= 123459.789  fat-k  1E-4 
    --test-- "float-auto-999"
      fat-i: 3.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1000"
      fat-i: 3.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
    --assertf~= 3.0  fat-k  1E-4 
    --test-- "float-auto-1001"
      fat-i: 3.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1002"
      fat-i: -7.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
    --assertf~= -7.0  fat-k  1E-4 
    --test-- "float-auto-1003"
      fat-i: -7.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
    --assertf~= -2147483655.0  fat-k  1E-4 
    --test-- "float-auto-1004"
      fat-i: -7.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
    --assertf~= 2147483640.0  fat-k  1E-4 
    --test-- "float-auto-1005"
      fat-i: -7.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
    --assertf~= -8.0  fat-k  1E-4 
    --test-- "float-auto-1006"
      fat-i: -7.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
    --assertf~= -4.0  fat-k  1E-4 
    --test-- "float-auto-1007"
      fat-i: -7.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
    --assertf~= -14.0  fat-k  1E-4 
    --test-- "float-auto-1008"
      fat-i: -7.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
    --assertf~= -2.0  fat-k  1E-4 
    --test-- "float-auto-1009"
      fat-i: -7.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
    --assertf~= 123449.789  fat-k  1E-4 
    --test-- "float-auto-1010"
      fat-i: -7.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1011"
      fat-i: -7.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
    --assertf~= -7.0  fat-k  1E-4 
    --test-- "float-auto-1012"
      fat-i: -7.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1013"
      fat-i: 5.0
      fat-j: 0.0
      fat-k:  fat-i + fat-j
    --assertf~= 5.0  fat-k  1E-4 
    --test-- "float-auto-1014"
      fat-i: 5.0
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
    --assertf~= -2147483643.0  fat-k  1E-4 
    --test-- "float-auto-1015"
      fat-i: 5.0
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
    --assertf~= 2147483652.0  fat-k  1E-4 
    --test-- "float-auto-1016"
      fat-i: 5.0
      fat-j: -1.0
      fat-k:  fat-i + fat-j
    --assertf~= 4.0  fat-k  1E-4 
    --test-- "float-auto-1017"
      fat-i: 5.0
      fat-j: 3.0
      fat-k:  fat-i + fat-j
    --assertf~= 8.0  fat-k  1E-4 
    --test-- "float-auto-1018"
      fat-i: 5.0
      fat-j: -7.0
      fat-k:  fat-i + fat-j
    --assertf~= -2.0  fat-k  1E-4 
    --test-- "float-auto-1019"
      fat-i: 5.0
      fat-j: 5.0
      fat-k:  fat-i + fat-j
    --assertf~= 10.0  fat-k  1E-4 
    --test-- "float-auto-1020"
      fat-i: 5.0
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
    --assertf~= 123461.789  fat-k  1E-4 
    --test-- "float-auto-1021"
      fat-i: 5.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1022"
      fat-i: 5.0
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
    --assertf~= 5.0  fat-k  1E-4 
    --test-- "float-auto-1023"
      fat-i: 5.0
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1024"
      fat-i: 123456.789
      fat-j: 0.0
      fat-k:  fat-i + fat-j
    --assertf~= 123456.789  fat-k  1E-4 
    --test-- "float-auto-1025"
      fat-i: 123456.789
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
    --assertf~= -2147360191.211  fat-k  1E-4 
    --test-- "float-auto-1026"
      fat-i: 123456.789
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
    --assertf~= 2147607103.789  fat-k  1E-4 
    --test-- "float-auto-1027"
      fat-i: 123456.789
      fat-j: -1.0
      fat-k:  fat-i + fat-j
    --assertf~= 123455.789  fat-k  1E-4 
    --test-- "float-auto-1028"
      fat-i: 123456.789
      fat-j: 3.0
      fat-k:  fat-i + fat-j
    --assertf~= 123459.789  fat-k  1E-4 
    --test-- "float-auto-1029"
      fat-i: 123456.789
      fat-j: -7.0
      fat-k:  fat-i + fat-j
    --assertf~= 123449.789  fat-k  1E-4 
    --test-- "float-auto-1030"
      fat-i: 123456.789
      fat-j: 5.0
      fat-k:  fat-i + fat-j
    --assertf~= 123461.789  fat-k  1E-4 
    --test-- "float-auto-1031"
      fat-i: 123456.789
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
    --assertf~= 246913.578  fat-k  1E-4 
    --test-- "float-auto-1032"
      fat-i: 123456.789
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1033"
      fat-i: 123456.789
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
    --assertf~= 123456.789  fat-k  1E-4 
    --test-- "float-auto-1034"
      fat-i: 123456.789
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
    --assertf~= 7.70000000000012E+18  fat-k  1E-4 
    --test-- "float-auto-1035"
      fat-i: 1.222090944E+33
      fat-j: 0.0
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1036"
      fat-i: 1.222090944E+33
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1037"
      fat-i: 1.222090944E+33
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1038"
      fat-i: 1.222090944E+33
      fat-j: -1.0
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1039"
      fat-i: 1.222090944E+33
      fat-j: 3.0
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1040"
      fat-i: 1.222090944E+33
      fat-j: -7.0
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1041"
      fat-i: 1.222090944E+33
      fat-j: 5.0
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1042"
      fat-i: 1.222090944E+33
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1043"
      fat-i: 1.222090944E+33
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
    --assertf~= 2.444181888E+33  fat-k  1E-4 
    --test-- "float-auto-1044"
      fat-i: 1.222090944E+33
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1045"
      fat-i: 1.222090944E+33
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
    --assertf~= 1.22209094400001E+33  fat-k  1E-4 
    --test-- "float-auto-1046"
      fat-i: 9.99999E-45
      fat-j: 0.0
      fat-k:  fat-i + fat-j
    --assertf~= 9.99999E-45  fat-k  1E-4 
    --test-- "float-auto-1047"
      fat-i: 9.99999E-45
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
    --assertf~= -2147483648.0  fat-k  1E-4 
    --test-- "float-auto-1048"
      fat-i: 9.99999E-45
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
    --assertf~= 2147483647.0  fat-k  1E-4 
    --test-- "float-auto-1049"
      fat-i: 9.99999E-45
      fat-j: -1.0
      fat-k:  fat-i + fat-j
    --assertf~= -1.0  fat-k  1E-4 
    --test-- "float-auto-1050"
      fat-i: 9.99999E-45
      fat-j: 3.0
      fat-k:  fat-i + fat-j
    --assertf~= 3.0  fat-k  1E-4 
    --test-- "float-auto-1051"
      fat-i: 9.99999E-45
      fat-j: -7.0
      fat-k:  fat-i + fat-j
    --assertf~= -7.0  fat-k  1E-4 
    --test-- "float-auto-1052"
      fat-i: 9.99999E-45
      fat-j: 5.0
      fat-k:  fat-i + fat-j
    --assertf~= 5.0  fat-k  1E-4 
    --test-- "float-auto-1053"
      fat-i: 9.99999E-45
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
    --assertf~= 123456.789  fat-k  1E-4 
    --test-- "float-auto-1054"
      fat-i: 9.99999E-45
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1055"
      fat-i: 9.99999E-45
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
    --assertf~= 1.999998E-44  fat-k  1E-4 
    --test-- "float-auto-1056"
      fat-i: 9.99999E-45
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1057"
      fat-i: 7.7E+18
      fat-j: 0.0
      fat-k:  fat-i + fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1058"
      fat-i: 7.7E+18
      fat-j: -2147483648.0
      fat-k:  fat-i + fat-j
    --assertf~= 7.69999999785252E+18  fat-k  1E-4 
    --test-- "float-auto-1059"
      fat-i: 7.7E+18
      fat-j: 2147483647.0
      fat-k:  fat-i + fat-j
    --assertf~= 7.70000000214748E+18  fat-k  1E-4 
    --test-- "float-auto-1060"
      fat-i: 7.7E+18
      fat-j: -1.0
      fat-k:  fat-i + fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1061"
      fat-i: 7.7E+18
      fat-j: 3.0
      fat-k:  fat-i + fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1062"
      fat-i: 7.7E+18
      fat-j: -7.0
      fat-k:  fat-i + fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1063"
      fat-i: 7.7E+18
      fat-j: 5.0
      fat-k:  fat-i + fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1064"
      fat-i: 7.7E+18
      fat-j: 123456.789
      fat-k:  fat-i + fat-j
    --assertf~= 7.70000000000012E+18  fat-k  1E-4 
    --test-- "float-auto-1065"
      fat-i: 7.7E+18
      fat-j: 1.222090944E+33
      fat-k:  fat-i + fat-j
    --assertf~= 1.22209094400001E+33  fat-k  1E-4 
    --test-- "float-auto-1066"
      fat-i: 7.7E+18
      fat-j: 9.99999E-45
      fat-k:  fat-i + fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1067"
      fat-i: 7.7E+18
      fat-j: 7.7E+18
      fat-k:  fat-i + fat-j
    --assertf~= 1.54E+19  fat-k  1E-4 
    --test-- "float-auto-1068"
      fat-i: 0.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1069"
      fat-i: 0.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
    --assertf~= 2147483648.0  fat-k  1E-4 
    --test-- "float-auto-1070"
      fat-i: 0.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
    --assertf~= -2147483647.0  fat-k  1E-4 
    --test-- "float-auto-1071"
      fat-i: 0.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
    --assertf~= 1.0  fat-k  1E-4 
    --test-- "float-auto-1072"
      fat-i: 0.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
    --assertf~= -3.0  fat-k  1E-4 
    --test-- "float-auto-1073"
      fat-i: 0.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
    --assertf~= 7.0  fat-k  1E-4 
    --test-- "float-auto-1074"
      fat-i: 0.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
    --assertf~= -5.0  fat-k  1E-4 
    --test-- "float-auto-1075"
      fat-i: 0.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
    --assertf~= -123456.789  fat-k  1E-4 
    --test-- "float-auto-1076"
      fat-i: 0.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
    --assertf~= -1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1077"
      fat-i: 0.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
    --assertf~= -9.99999E-45  fat-k  1E-4 
    --test-- "float-auto-1078"
      fat-i: 0.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
    --assertf~= -7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1079"
      fat-i: -2147483648.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
    --assertf~= -2147483648.0  fat-k  1E-4 
    --test-- "float-auto-1080"
      fat-i: -2147483648.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1081"
      fat-i: -2147483648.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
    --assertf~= -4294967295.0  fat-k  1E-4 
    --test-- "float-auto-1082"
      fat-i: -2147483648.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
    --assertf~= -2147483647.0  fat-k  1E-4 
    --test-- "float-auto-1083"
      fat-i: -2147483648.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
    --assertf~= -2147483651.0  fat-k  1E-4 
    --test-- "float-auto-1084"
      fat-i: -2147483648.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
    --assertf~= -2147483641.0  fat-k  1E-4 
    --test-- "float-auto-1085"
      fat-i: -2147483648.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
    --assertf~= -2147483653.0  fat-k  1E-4 
    --test-- "float-auto-1086"
      fat-i: -2147483648.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
    --assertf~= -2147607104.789  fat-k  1E-4 
    --test-- "float-auto-1087"
      fat-i: -2147483648.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
    --assertf~= -1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1088"
      fat-i: -2147483648.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
    --assertf~= -2147483648.0  fat-k  1E-4 
    --test-- "float-auto-1089"
      fat-i: -2147483648.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
    --assertf~= -7.70000000214748E+18  fat-k  1E-4 
    --test-- "float-auto-1090"
      fat-i: 2147483647.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
    --assertf~= 2147483647.0  fat-k  1E-4 
    --test-- "float-auto-1091"
      fat-i: 2147483647.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
    --assertf~= 4294967295.0  fat-k  1E-4 
    --test-- "float-auto-1092"
      fat-i: 2147483647.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1093"
      fat-i: 2147483647.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
    --assertf~= 2147483648.0  fat-k  1E-4 
    --test-- "float-auto-1094"
      fat-i: 2147483647.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
    --assertf~= 2147483644.0  fat-k  1E-4 
    --test-- "float-auto-1095"
      fat-i: 2147483647.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
    --assertf~= 2147483654.0  fat-k  1E-4 
    --test-- "float-auto-1096"
      fat-i: 2147483647.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
    --assertf~= 2147483642.0  fat-k  1E-4 
    --test-- "float-auto-1097"
      fat-i: 2147483647.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
    --assertf~= 2147360190.211  fat-k  1E-4 
    --test-- "float-auto-1098"
      fat-i: 2147483647.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
    --assertf~= -1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1099"
      fat-i: 2147483647.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
    --assertf~= 2147483647.0  fat-k  1E-4 
    --test-- "float-auto-1100"
      fat-i: 2147483647.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
    --assertf~= -7.69999999785252E+18  fat-k  1E-4 
    --test-- "float-auto-1101"
      fat-i: -1.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
    --assertf~= -1.0  fat-k  1E-4 
    --test-- "float-auto-1102"
      fat-i: -1.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
    --assertf~= 2147483647.0  fat-k  1E-4 
    --test-- "float-auto-1103"
      fat-i: -1.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
    --assertf~= -2147483648.0  fat-k  1E-4 
    --test-- "float-auto-1104"
      fat-i: -1.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1105"
      fat-i: -1.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
    --assertf~= -4.0  fat-k  1E-4 
    --test-- "float-auto-1106"
      fat-i: -1.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
    --assertf~= 6.0  fat-k  1E-4 
    --test-- "float-auto-1107"
      fat-i: -1.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
    --assertf~= -6.0  fat-k  1E-4 
    --test-- "float-auto-1108"
      fat-i: -1.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
    --assertf~= -123457.789  fat-k  1E-4 
    --test-- "float-auto-1109"
      fat-i: -1.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
    --assertf~= -1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1110"
      fat-i: -1.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
    --assertf~= -1.0  fat-k  1E-4 
    --test-- "float-auto-1111"
      fat-i: -1.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
    --assertf~= -7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1112"
      fat-i: 3.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
    --assertf~= 3.0  fat-k  1E-4 
    --test-- "float-auto-1113"
      fat-i: 3.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
    --assertf~= 2147483651.0  fat-k  1E-4 
    --test-- "float-auto-1114"
      fat-i: 3.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
    --assertf~= -2147483644.0  fat-k  1E-4 
    --test-- "float-auto-1115"
      fat-i: 3.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
    --assertf~= 4.0  fat-k  1E-4 
    --test-- "float-auto-1116"
      fat-i: 3.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1117"
      fat-i: 3.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
    --assertf~= 10.0  fat-k  1E-4 
    --test-- "float-auto-1118"
      fat-i: 3.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
    --assertf~= -2.0  fat-k  1E-4 
    --test-- "float-auto-1119"
      fat-i: 3.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
    --assertf~= -123453.789  fat-k  1E-4 
    --test-- "float-auto-1120"
      fat-i: 3.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
    --assertf~= -1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1121"
      fat-i: 3.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
    --assertf~= 3.0  fat-k  1E-4 
    --test-- "float-auto-1122"
      fat-i: 3.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
    --assertf~= -7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1123"
      fat-i: -7.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
    --assertf~= -7.0  fat-k  1E-4 
    --test-- "float-auto-1124"
      fat-i: -7.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
    --assertf~= 2147483641.0  fat-k  1E-4 
    --test-- "float-auto-1125"
      fat-i: -7.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
    --assertf~= -2147483654.0  fat-k  1E-4 
    --test-- "float-auto-1126"
      fat-i: -7.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
    --assertf~= -6.0  fat-k  1E-4 
    --test-- "float-auto-1127"
      fat-i: -7.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
    --assertf~= -10.0  fat-k  1E-4 
    --test-- "float-auto-1128"
      fat-i: -7.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1129"
      fat-i: -7.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
    --assertf~= -12.0  fat-k  1E-4 
    --test-- "float-auto-1130"
      fat-i: -7.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
    --assertf~= -123463.789  fat-k  1E-4 
    --test-- "float-auto-1131"
      fat-i: -7.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
    --assertf~= -1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1132"
      fat-i: -7.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
    --assertf~= -7.0  fat-k  1E-4 
    --test-- "float-auto-1133"
      fat-i: -7.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
    --assertf~= -7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1134"
      fat-i: 5.0
      fat-j: 0.0
      fat-k:  fat-i - fat-j
    --assertf~= 5.0  fat-k  1E-4 
    --test-- "float-auto-1135"
      fat-i: 5.0
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
    --assertf~= 2147483653.0  fat-k  1E-4 
    --test-- "float-auto-1136"
      fat-i: 5.0
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
    --assertf~= -2147483642.0  fat-k  1E-4 
    --test-- "float-auto-1137"
      fat-i: 5.0
      fat-j: -1.0
      fat-k:  fat-i - fat-j
    --assertf~= 6.0  fat-k  1E-4 
    --test-- "float-auto-1138"
      fat-i: 5.0
      fat-j: 3.0
      fat-k:  fat-i - fat-j
    --assertf~= 2.0  fat-k  1E-4 
    --test-- "float-auto-1139"
      fat-i: 5.0
      fat-j: -7.0
      fat-k:  fat-i - fat-j
    --assertf~= 12.0  fat-k  1E-4 
    --test-- "float-auto-1140"
      fat-i: 5.0
      fat-j: 5.0
      fat-k:  fat-i - fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1141"
      fat-i: 5.0
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
    --assertf~= -123451.789  fat-k  1E-4 
    --test-- "float-auto-1142"
      fat-i: 5.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
    --assertf~= -1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1143"
      fat-i: 5.0
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
    --assertf~= 5.0  fat-k  1E-4 
    --test-- "float-auto-1144"
      fat-i: 5.0
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
    --assertf~= -7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1145"
      fat-i: 123456.789
      fat-j: 0.0
      fat-k:  fat-i - fat-j
    --assertf~= 123456.789  fat-k  1E-4 
    --test-- "float-auto-1146"
      fat-i: 123456.789
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
    --assertf~= 2147607104.789  fat-k  1E-4 
    --test-- "float-auto-1147"
      fat-i: 123456.789
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
    --assertf~= -2147360190.211  fat-k  1E-4 
    --test-- "float-auto-1148"
      fat-i: 123456.789
      fat-j: -1.0
      fat-k:  fat-i - fat-j
    --assertf~= 123457.789  fat-k  1E-4 
    --test-- "float-auto-1149"
      fat-i: 123456.789
      fat-j: 3.0
      fat-k:  fat-i - fat-j
    --assertf~= 123453.789  fat-k  1E-4 
    --test-- "float-auto-1150"
      fat-i: 123456.789
      fat-j: -7.0
      fat-k:  fat-i - fat-j
    --assertf~= 123463.789  fat-k  1E-4 
    --test-- "float-auto-1151"
      fat-i: 123456.789
      fat-j: 5.0
      fat-k:  fat-i - fat-j
    --assertf~= 123451.789  fat-k  1E-4 
    --test-- "float-auto-1152"
      fat-i: 123456.789
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1153"
      fat-i: 123456.789
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
    --assertf~= -1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1154"
      fat-i: 123456.789
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
    --assertf~= 123456.789  fat-k  1E-4 
    --test-- "float-auto-1155"
      fat-i: 123456.789
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
    --assertf~= -7.69999999999988E+18  fat-k  1E-4 
    --test-- "float-auto-1156"
      fat-i: 1.222090944E+33
      fat-j: 0.0
      fat-k:  fat-i - fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1157"
      fat-i: 1.222090944E+33
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1158"
      fat-i: 1.222090944E+33
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1159"
      fat-i: 1.222090944E+33
      fat-j: -1.0
      fat-k:  fat-i - fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1160"
      fat-i: 1.222090944E+33
      fat-j: 3.0
      fat-k:  fat-i - fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1161"
      fat-i: 1.222090944E+33
      fat-j: -7.0
      fat-k:  fat-i - fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1162"
      fat-i: 1.222090944E+33
      fat-j: 5.0
      fat-k:  fat-i - fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1163"
      fat-i: 1.222090944E+33
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1164"
      fat-i: 1.222090944E+33
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1165"
      fat-i: 1.222090944E+33
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
    --assertf~= 1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1166"
      fat-i: 1.222090944E+33
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
    --assertf~= 1.22209094399999E+33  fat-k  1E-4 
    --test-- "float-auto-1167"
      fat-i: 9.99999E-45
      fat-j: 0.0
      fat-k:  fat-i - fat-j
    --assertf~= 9.99999E-45  fat-k  1E-4 
    --test-- "float-auto-1168"
      fat-i: 9.99999E-45
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
    --assertf~= 2147483648.0  fat-k  1E-4 
    --test-- "float-auto-1169"
      fat-i: 9.99999E-45
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
    --assertf~= -2147483647.0  fat-k  1E-4 
    --test-- "float-auto-1170"
      fat-i: 9.99999E-45
      fat-j: -1.0
      fat-k:  fat-i - fat-j
    --assertf~= 1.0  fat-k  1E-4 
    --test-- "float-auto-1171"
      fat-i: 9.99999E-45
      fat-j: 3.0
      fat-k:  fat-i - fat-j
    --assertf~= -3.0  fat-k  1E-4 
    --test-- "float-auto-1172"
      fat-i: 9.99999E-45
      fat-j: -7.0
      fat-k:  fat-i - fat-j
    --assertf~= 7.0  fat-k  1E-4 
    --test-- "float-auto-1173"
      fat-i: 9.99999E-45
      fat-j: 5.0
      fat-k:  fat-i - fat-j
    --assertf~= -5.0  fat-k  1E-4 
    --test-- "float-auto-1174"
      fat-i: 9.99999E-45
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
    --assertf~= -123456.789  fat-k  1E-4 
    --test-- "float-auto-1175"
      fat-i: 9.99999E-45
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
    --assertf~= -1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1176"
      fat-i: 9.99999E-45
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1177"
      fat-i: 9.99999E-45
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
    --assertf~= -7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1178"
      fat-i: 7.7E+18
      fat-j: 0.0
      fat-k:  fat-i - fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1179"
      fat-i: 7.7E+18
      fat-j: -2147483648.0
      fat-k:  fat-i - fat-j
    --assertf~= 7.70000000214748E+18  fat-k  1E-4 
    --test-- "float-auto-1180"
      fat-i: 7.7E+18
      fat-j: 2147483647.0
      fat-k:  fat-i - fat-j
    --assertf~= 7.69999999785252E+18  fat-k  1E-4 
    --test-- "float-auto-1181"
      fat-i: 7.7E+18
      fat-j: -1.0
      fat-k:  fat-i - fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1182"
      fat-i: 7.7E+18
      fat-j: 3.0
      fat-k:  fat-i - fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1183"
      fat-i: 7.7E+18
      fat-j: -7.0
      fat-k:  fat-i - fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1184"
      fat-i: 7.7E+18
      fat-j: 5.0
      fat-k:  fat-i - fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1185"
      fat-i: 7.7E+18
      fat-j: 123456.789
      fat-k:  fat-i - fat-j
    --assertf~= 7.69999999999988E+18  fat-k  1E-4 
    --test-- "float-auto-1186"
      fat-i: 7.7E+18
      fat-j: 1.222090944E+33
      fat-k:  fat-i - fat-j
    --assertf~= -1.22209094399999E+33  fat-k  1E-4 
    --test-- "float-auto-1187"
      fat-i: 7.7E+18
      fat-j: 9.99999E-45
      fat-k:  fat-i - fat-j
    --assertf~= 7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1188"
      fat-i: 7.7E+18
      fat-j: 7.7E+18
      fat-k:  fat-i - fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1189"
      fat-i: 0.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1190"
      fat-i: 0.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1191"
      fat-i: 0.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1192"
      fat-i: 0.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1193"
      fat-i: 0.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1194"
      fat-i: 0.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1195"
      fat-i: 0.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1196"
      fat-i: 0.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1197"
      fat-i: 0.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1198"
      fat-i: 0.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1199"
      fat-i: 0.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1200"
      fat-i: -2147483648.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1201"
      fat-i: -2147483648.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
    --assertf~= 4.61168601842739E+18  fat-k  1E-4 
    --test-- "float-auto-1202"
      fat-i: -2147483648.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
    --assertf~= -4.6116860162799E+18  fat-k  1E-4 
    --test-- "float-auto-1203"
      fat-i: -2147483648.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
    --assertf~= 2147483648.0  fat-k  1E-4 
    --test-- "float-auto-1204"
      fat-i: -2147483648.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
    --assertf~= -6442450944.0  fat-k  1E-4 
    --test-- "float-auto-1205"
      fat-i: -2147483648.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
    --assertf~= 15032385536.0  fat-k  1E-4 
    --test-- "float-auto-1206"
      fat-i: -2147483648.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
    --assertf~= -10737418240.0  fat-k  1E-4 
    --test-- "float-auto-1207"
      fat-i: -2147483648.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
    --assertf~= -265121435612086.0  fat-k  1E-4 
    --test-- "float-auto-1208"
      fat-i: -2147483648.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
    --assertf~= -2.62442031860888E+42  fat-k  1E-4 
    --test-- "float-auto-1209"
      fat-i: -2147483648.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
    --assertf~= -2.14748150051635E-35  fat-k  1E-4 
    --test-- "float-auto-1210"
      fat-i: -2147483648.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
    --assertf~= -1.65356240896E+28  fat-k  1E-4 
    --test-- "float-auto-1211"
      fat-i: 2147483647.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1212"
      fat-i: 2147483647.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
    --assertf~= -4.6116860162799E+18  fat-k  1E-4 
    --test-- "float-auto-1213"
      fat-i: 2147483647.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
    --assertf~= 4.61168601413242E+18  fat-k  1E-4 
    --test-- "float-auto-1214"
      fat-i: 2147483647.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
    --assertf~= -2147483647.0  fat-k  1E-4 
    --test-- "float-auto-1215"
      fat-i: 2147483647.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
    --assertf~= 6442450941.0  fat-k  1E-4 
    --test-- "float-auto-1216"
      fat-i: 2147483647.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
    --assertf~= -15032385529.0  fat-k  1E-4 
    --test-- "float-auto-1217"
      fat-i: 2147483647.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
    --assertf~= 10737418235.0  fat-k  1E-4 
    --test-- "float-auto-1218"
      fat-i: 2147483647.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
    --assertf~= 265121435488630.0  fat-k  1E-4 
    --test-- "float-auto-1219"
      fat-i: 2147483647.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
    --assertf~= 2.62442031738679E+42  fat-k  1E-4 
    --test-- "float-auto-1220"
      fat-i: 2147483647.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
    --assertf~= 2.14748149951635E-35  fat-k  1E-4 
    --test-- "float-auto-1221"
      fat-i: 2147483647.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
    --assertf~= 1.65356240819E+28  fat-k  1E-4 
    --test-- "float-auto-1222"
      fat-i: -1.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1223"
      fat-i: -1.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
    --assertf~= 2147483648.0  fat-k  1E-4 
    --test-- "float-auto-1224"
      fat-i: -1.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
    --assertf~= -2147483647.0  fat-k  1E-4 
    --test-- "float-auto-1225"
      fat-i: -1.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
    --assertf~= 1.0  fat-k  1E-4 
    --test-- "float-auto-1226"
      fat-i: -1.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
    --assertf~= -3.0  fat-k  1E-4 
    --test-- "float-auto-1227"
      fat-i: -1.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
    --assertf~= 7.0  fat-k  1E-4 
    --test-- "float-auto-1228"
      fat-i: -1.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
    --assertf~= -5.0  fat-k  1E-4 
    --test-- "float-auto-1229"
      fat-i: -1.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
    --assertf~= -123456.789  fat-k  1E-4 
    --test-- "float-auto-1230"
      fat-i: -1.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
    --assertf~= -1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1231"
      fat-i: -1.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
    --assertf~= -9.99999E-45  fat-k  1E-4 
    --test-- "float-auto-1232"
      fat-i: -1.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
    --assertf~= -7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1233"
      fat-i: 3.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1234"
      fat-i: 3.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
    --assertf~= -6442450944.0  fat-k  1E-4 
    --test-- "float-auto-1235"
      fat-i: 3.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
    --assertf~= 6442450941.0  fat-k  1E-4 
    --test-- "float-auto-1236"
      fat-i: 3.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
    --assertf~= -3.0  fat-k  1E-4 
    --test-- "float-auto-1237"
      fat-i: 3.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
    --assertf~= 9.0  fat-k  1E-4 
    --test-- "float-auto-1238"
      fat-i: 3.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
    --assertf~= -21.0  fat-k  1E-4 
    --test-- "float-auto-1239"
      fat-i: 3.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
    --assertf~= 15.0  fat-k  1E-4 
    --test-- "float-auto-1240"
      fat-i: 3.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
    --assertf~= 370370.367  fat-k  1E-4 
    --test-- "float-auto-1241"
      fat-i: 3.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
    --assertf~= 3.666272832E+33  fat-k  1E-4 
    --test-- "float-auto-1242"
      fat-i: 3.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
    --assertf~= 2.999997E-44  fat-k  1E-4 
    --test-- "float-auto-1243"
      fat-i: 3.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
    --assertf~= 2.31E+19  fat-k  1E-4 
    --test-- "float-auto-1244"
      fat-i: -7.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1245"
      fat-i: -7.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
    --assertf~= 15032385536.0  fat-k  1E-4 
    --test-- "float-auto-1246"
      fat-i: -7.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
    --assertf~= -15032385529.0  fat-k  1E-4 
    --test-- "float-auto-1247"
      fat-i: -7.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
    --assertf~= 7.0  fat-k  1E-4 
    --test-- "float-auto-1248"
      fat-i: -7.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
    --assertf~= -21.0  fat-k  1E-4 
    --test-- "float-auto-1249"
      fat-i: -7.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
    --assertf~= 49.0  fat-k  1E-4 
    --test-- "float-auto-1250"
      fat-i: -7.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
    --assertf~= -35.0  fat-k  1E-4 
    --test-- "float-auto-1251"
      fat-i: -7.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
    --assertf~= -864197.523  fat-k  1E-4 
    --test-- "float-auto-1252"
      fat-i: -7.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
    --assertf~= -8.554636608E+33  fat-k  1E-4 
    --test-- "float-auto-1253"
      fat-i: -7.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
    --assertf~= -6.999993E-44  fat-k  1E-4 
    --test-- "float-auto-1254"
      fat-i: -7.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
    --assertf~= -5.39E+19  fat-k  1E-4 
    --test-- "float-auto-1255"
      fat-i: 5.0
      fat-j: 0.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1256"
      fat-i: 5.0
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
    --assertf~= -10737418240.0  fat-k  1E-4 
    --test-- "float-auto-1257"
      fat-i: 5.0
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
    --assertf~= 10737418235.0  fat-k  1E-4 
    --test-- "float-auto-1258"
      fat-i: 5.0
      fat-j: -1.0
      fat-k:  fat-i * fat-j
    --assertf~= -5.0  fat-k  1E-4 
    --test-- "float-auto-1259"
      fat-i: 5.0
      fat-j: 3.0
      fat-k:  fat-i * fat-j
    --assertf~= 15.0  fat-k  1E-4 
    --test-- "float-auto-1260"
      fat-i: 5.0
      fat-j: -7.0
      fat-k:  fat-i * fat-j
    --assertf~= -35.0  fat-k  1E-4 
    --test-- "float-auto-1261"
      fat-i: 5.0
      fat-j: 5.0
      fat-k:  fat-i * fat-j
    --assertf~= 25.0  fat-k  1E-4 
    --test-- "float-auto-1262"
      fat-i: 5.0
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
    --assertf~= 617283.945  fat-k  1E-4 
    --test-- "float-auto-1263"
      fat-i: 5.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
    --assertf~= 6.11045472E+33  fat-k  1E-4 
    --test-- "float-auto-1264"
      fat-i: 5.0
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
    --assertf~= 4.999995E-44  fat-k  1E-4 
    --test-- "float-auto-1265"
      fat-i: 5.0
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
    --assertf~= 3.85E+19  fat-k  1E-4 
    --test-- "float-auto-1266"
      fat-i: 123456.789
      fat-j: 0.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1267"
      fat-i: 123456.789
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
    --assertf~= -265121435612086.0  fat-k  1E-4 
    --test-- "float-auto-1268"
      fat-i: 123456.789
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
    --assertf~= 265121435488630.0  fat-k  1E-4 
    --test-- "float-auto-1269"
      fat-i: 123456.789
      fat-j: -1.0
      fat-k:  fat-i * fat-j
    --assertf~= -123456.789  fat-k  1E-4 
    --test-- "float-auto-1270"
      fat-i: 123456.789
      fat-j: 3.0
      fat-k:  fat-i * fat-j
    --assertf~= 370370.367  fat-k  1E-4 
    --test-- "float-auto-1271"
      fat-i: 123456.789
      fat-j: -7.0
      fat-k:  fat-i * fat-j
    --assertf~= -864197.523  fat-k  1E-4 
    --test-- "float-auto-1272"
      fat-i: 123456.789
      fat-j: 5.0
      fat-k:  fat-i * fat-j
    --assertf~= 617283.945  fat-k  1E-4 
    --test-- "float-auto-1273"
      fat-i: 123456.789
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
    --assertf~= 15241578750.1905  fat-k  1E-4 
    --test-- "float-auto-1274"
      fat-i: 123456.789
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
    --assertf~= 1.50875423812219E+38  fat-k  1E-4 
    --test-- "float-auto-1275"
      fat-i: 123456.789
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
    --assertf~= 1.23456665543211E-39  fat-k  1E-4 
    --test-- "float-auto-1276"
      fat-i: 123456.789
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
    --assertf~= 9.506172753E+23  fat-k  1E-4 
    --test-- "float-auto-1277"
      fat-i: 1.222090944E+33
      fat-j: 0.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1278"
      fat-i: 1.222090944E+33
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
    --assertf~= -2.62442031860888E+42  fat-k  1E-4 
    --test-- "float-auto-1279"
      fat-i: 1.222090944E+33
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
    --assertf~= 2.62442031738679E+42  fat-k  1E-4 
    --test-- "float-auto-1280"
      fat-i: 1.222090944E+33
      fat-j: -1.0
      fat-k:  fat-i * fat-j
    --assertf~= -1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1281"
      fat-i: 1.222090944E+33
      fat-j: 3.0
      fat-k:  fat-i * fat-j
    --assertf~= 3.666272832E+33  fat-k  1E-4 
    --test-- "float-auto-1282"
      fat-i: 1.222090944E+33
      fat-j: -7.0
      fat-k:  fat-i * fat-j
    --assertf~= -8.554636608E+33  fat-k  1E-4 
    --test-- "float-auto-1283"
      fat-i: 1.222090944E+33
      fat-j: 5.0
      fat-k:  fat-i * fat-j
    --assertf~= 6.11045472E+33  fat-k  1E-4 
    --test-- "float-auto-1284"
      fat-i: 1.222090944E+33
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
    --assertf~= 1.50875423812219E+38  fat-k  1E-4 
    --test-- "float-auto-1285"
      fat-i: 1.222090944E+33
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
    --assertf~= 1.49350627540681E+66  fat-k  1E-4 
    --test-- "float-auto-1286"
      fat-i: 1.222090944E+33
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
    --assertf~= 1.22208972190906E-11  fat-k  1E-4 
    --test-- "float-auto-1287"
      fat-i: 1.222090944E+33
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
    --assertf~= 9.4101002688E+51  fat-k  1E-4 
    --test-- "float-auto-1288"
      fat-i: 9.99999E-45
      fat-j: 0.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1289"
      fat-i: 9.99999E-45
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
    --assertf~= -2.14748150051635E-35  fat-k  1E-4 
    --test-- "float-auto-1290"
      fat-i: 9.99999E-45
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
    --assertf~= 2.14748149951635E-35  fat-k  1E-4 
    --test-- "float-auto-1291"
      fat-i: 9.99999E-45
      fat-j: -1.0
      fat-k:  fat-i * fat-j
    --assertf~= -9.99999E-45  fat-k  1E-4 
    --test-- "float-auto-1292"
      fat-i: 9.99999E-45
      fat-j: 3.0
      fat-k:  fat-i * fat-j
    --assertf~= 2.999997E-44  fat-k  1E-4 
    --test-- "float-auto-1293"
      fat-i: 9.99999E-45
      fat-j: -7.0
      fat-k:  fat-i * fat-j
    --assertf~= -6.999993E-44  fat-k  1E-4 
    --test-- "float-auto-1294"
      fat-i: 9.99999E-45
      fat-j: 5.0
      fat-k:  fat-i * fat-j
    --assertf~= 4.999995E-44  fat-k  1E-4 
    --test-- "float-auto-1295"
      fat-i: 9.99999E-45
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
    --assertf~= 1.23456665543211E-39  fat-k  1E-4 
    --test-- "float-auto-1296"
      fat-i: 9.99999E-45
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
    --assertf~= 1.22208972190906E-11  fat-k  1E-4 
    --test-- "float-auto-1297"
      fat-i: 9.99999E-45
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
    --assertf~= 9.99998000001E-89  fat-k  1E-4 
    --test-- "float-auto-1298"
      fat-i: 9.99999E-45
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
    --assertf~= 7.6999923E-26  fat-k  1E-4 
    --test-- "float-auto-1299"
      fat-i: 7.7E+18
      fat-j: 0.0
      fat-k:  fat-i * fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1300"
      fat-i: 7.7E+18
      fat-j: -2147483648.0
      fat-k:  fat-i * fat-j
    --assertf~= -1.65356240896E+28  fat-k  1E-4 
    --test-- "float-auto-1301"
      fat-i: 7.7E+18
      fat-j: 2147483647.0
      fat-k:  fat-i * fat-j
    --assertf~= 1.65356240819E+28  fat-k  1E-4 
    --test-- "float-auto-1302"
      fat-i: 7.7E+18
      fat-j: -1.0
      fat-k:  fat-i * fat-j
    --assertf~= -7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1303"
      fat-i: 7.7E+18
      fat-j: 3.0
      fat-k:  fat-i * fat-j
    --assertf~= 2.31E+19  fat-k  1E-4 
    --test-- "float-auto-1304"
      fat-i: 7.7E+18
      fat-j: -7.0
      fat-k:  fat-i * fat-j
    --assertf~= -5.39E+19  fat-k  1E-4 
    --test-- "float-auto-1305"
      fat-i: 7.7E+18
      fat-j: 5.0
      fat-k:  fat-i * fat-j
    --assertf~= 3.85E+19  fat-k  1E-4 
    --test-- "float-auto-1306"
      fat-i: 7.7E+18
      fat-j: 123456.789
      fat-k:  fat-i * fat-j
    --assertf~= 9.506172753E+23  fat-k  1E-4 
    --test-- "float-auto-1307"
      fat-i: 7.7E+18
      fat-j: 1.222090944E+33
      fat-k:  fat-i * fat-j
    --assertf~= 9.4101002688E+51  fat-k  1E-4 
    --test-- "float-auto-1308"
      fat-i: 7.7E+18
      fat-j: 9.99999E-45
      fat-k:  fat-i * fat-j
    --assertf~= 7.6999923E-26  fat-k  1E-4 
    --test-- "float-auto-1309"
      fat-i: 7.7E+18
      fat-j: 7.7E+18
      fat-k:  fat-i * fat-j
    --assertf~= 5.929E+37  fat-k  1E-4 
    --test-- "float-auto-1310"
      fat-i: 0.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1311"
      fat-i: 0.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1312"
      fat-i: 0.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1313"
      fat-i: 0.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1314"
      fat-i: 0.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1315"
      fat-i: 0.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1316"
      fat-i: 0.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1317"
      fat-i: 0.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1318"
      fat-i: 0.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1319"
      fat-i: 0.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
    --assertf~= 0.0  fat-k  1E-4 
    --test-- "float-auto-1320"
      fat-i: -2147483648.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
    --assertf~= 1.0  fat-k  1E-4 
    --test-- "float-auto-1321"
      fat-i: -2147483648.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
    --assertf~= -1.00000000046566  fat-k  1E-4 
    --test-- "float-auto-1322"
      fat-i: -2147483648.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
    --assertf~= 2147483648.0  fat-k  1E-4 
    --test-- "float-auto-1323"
      fat-i: -2147483648.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
    --assertf~= -715827882.666667  fat-k  1E-4 
    --test-- "float-auto-1324"
      fat-i: -2147483648.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
    --assertf~= 306783378.285714  fat-k  1E-4 
    --test-- "float-auto-1325"
      fat-i: -2147483648.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
    --assertf~= -429496729.6  fat-k  1E-4 
    --test-- "float-auto-1326"
      fat-i: -2147483648.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
    --assertf~= -17394.617707091  fat-k  1E-4 
    --test-- "float-auto-1327"
      fat-i: -2147483648.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
    --assertf~= -1.75722081776592E-24  fat-k  1E-4 
    --test-- "float-auto-1328"
      fat-i: -2147483648.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
    --assertf~= -2.1474857954858E+53  fat-k  1E-4 
    --test-- "float-auto-1329"
      fat-i: -2147483648.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
    --assertf~= -2.7889398025974E-10  fat-k  1E-4 
    --test-- "float-auto-1330"
      fat-i: 2147483647.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
    --assertf~= -0.999999999534339  fat-k  1E-4 
    --test-- "float-auto-1331"
      fat-i: 2147483647.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
    --assertf~= 1.0  fat-k  1E-4 
    --test-- "float-auto-1332"
      fat-i: 2147483647.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
    --assertf~= -2147483647.0  fat-k  1E-4 
    --test-- "float-auto-1333"
      fat-i: 2147483647.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
    --assertf~= 715827882.333333  fat-k  1E-4 
    --test-- "float-auto-1334"
      fat-i: 2147483647.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
    --assertf~= -306783378.142857  fat-k  1E-4 
    --test-- "float-auto-1335"
      fat-i: 2147483647.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
    --assertf~= 429496729.4  fat-k  1E-4 
    --test-- "float-auto-1336"
      fat-i: 2147483647.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
    --assertf~= 17394.617698991  fat-k  1E-4 
    --test-- "float-auto-1337"
      fat-i: 2147483647.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
    --assertf~= 1.75722081694765E-24  fat-k  1E-4 
    --test-- "float-auto-1338"
      fat-i: 2147483647.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
    --assertf~= 2.14748579448579E+53  fat-k  1E-4 
    --test-- "float-auto-1339"
      fat-i: 2147483647.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
    --assertf~= 2.7889398012987E-10  fat-k  1E-4 
    --test-- "float-auto-1340"
      fat-i: -1.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
    --assertf~= 4.65661287307739E-10  fat-k  1E-4 
    --test-- "float-auto-1341"
      fat-i: -1.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
    --assertf~= -4.6566128752458E-10  fat-k  1E-4 
    --test-- "float-auto-1342"
      fat-i: -1.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
    --assertf~= 1.0  fat-k  1E-4 
    --test-- "float-auto-1343"
      fat-i: -1.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
    --assertf~= -0.333333333333333  fat-k  1E-4 
    --test-- "float-auto-1344"
      fat-i: -1.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
    --assertf~= 0.142857142857143  fat-k  1E-4 
    --test-- "float-auto-1345"
      fat-i: -1.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
    --assertf~= -0.2  fat-k  1E-4 
    --test-- "float-auto-1346"
      fat-i: -1.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
    --assertf~= -8.10000007371E-6  fat-k  1E-4 
    --test-- "float-auto-1347"
      fat-i: -1.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
    --assertf~= -8.18269708084835E-34  fat-k  1E-4 
    --test-- "float-auto-1348"
      fat-i: -1.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
    --assertf~= -1.000001000001E+44  fat-k  1E-4 
    --test-- "float-auto-1349"
      fat-i: -1.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
    --assertf~= -1.2987012987013E-19  fat-k  1E-4 
    --test-- "float-auto-1350"
      fat-i: 3.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
    --assertf~= -1.39698386192322E-9  fat-k  1E-4 
    --test-- "float-auto-1351"
      fat-i: 3.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
    --assertf~= 1.39698386257374E-9  fat-k  1E-4 
    --test-- "float-auto-1352"
      fat-i: 3.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
    --assertf~= -3.0  fat-k  1E-4 
    --test-- "float-auto-1353"
      fat-i: 3.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
    --assertf~= 1.0  fat-k  1E-4 
    --test-- "float-auto-1354"
      fat-i: 3.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
    --assertf~= -0.428571428571429  fat-k  1E-4 
    --test-- "float-auto-1355"
      fat-i: 3.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
    --assertf~= 0.6  fat-k  1E-4 
    --test-- "float-auto-1356"
      fat-i: 3.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
    --assertf~= 2.430000022113E-5  fat-k  1E-4 
    --test-- "float-auto-1357"
      fat-i: 3.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
    --assertf~= 2.4548091242545E-33  fat-k  1E-4 
    --test-- "float-auto-1358"
      fat-i: 3.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
    --assertf~= 3.000003000003E+44  fat-k  1E-4 
    --test-- "float-auto-1359"
      fat-i: 3.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
    --assertf~= 3.8961038961039E-19  fat-k  1E-4 
    --test-- "float-auto-1360"
      fat-i: -7.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
    --assertf~= 3.25962901115417E-9  fat-k  1E-4 
    --test-- "float-auto-1361"
      fat-i: -7.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
    --assertf~= -3.25962901267206E-9  fat-k  1E-4 
    --test-- "float-auto-1362"
      fat-i: -7.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
    --assertf~= 7.0  fat-k  1E-4 
    --test-- "float-auto-1363"
      fat-i: -7.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
    --assertf~= -2.33333333333333  fat-k  1E-4 
    --test-- "float-auto-1364"
      fat-i: -7.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
    --assertf~= 1.0  fat-k  1E-4 
    --test-- "float-auto-1365"
      fat-i: -7.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
    --assertf~= -1.4  fat-k  1E-4 
    --test-- "float-auto-1366"
      fat-i: -7.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
    --assertf~= -5.670000051597E-5  fat-k  1E-4 
    --test-- "float-auto-1367"
      fat-i: -7.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
    --assertf~= -5.72788795659384E-33  fat-k  1E-4 
    --test-- "float-auto-1368"
      fat-i: -7.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
    --assertf~= -7.000007000007E+44  fat-k  1E-4 
    --test-- "float-auto-1369"
      fat-i: -7.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
    --assertf~= -9.09090909090909E-19  fat-k  1E-4 
    --test-- "float-auto-1370"
      fat-i: 5.0
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
    --assertf~= -2.3283064365387E-9  fat-k  1E-4 
    --test-- "float-auto-1371"
      fat-i: 5.0
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
    --assertf~= 2.3283064376229E-9  fat-k  1E-4 
    --test-- "float-auto-1372"
      fat-i: 5.0
      fat-j: -1.0
      fat-k:  fat-i / fat-j
    --assertf~= -5.0  fat-k  1E-4 
    --test-- "float-auto-1373"
      fat-i: 5.0
      fat-j: 3.0
      fat-k:  fat-i / fat-j
    --assertf~= 1.66666666666667  fat-k  1E-4 
    --test-- "float-auto-1374"
      fat-i: 5.0
      fat-j: -7.0
      fat-k:  fat-i / fat-j
    --assertf~= -0.714285714285714  fat-k  1E-4 
    --test-- "float-auto-1375"
      fat-i: 5.0
      fat-j: 5.0
      fat-k:  fat-i / fat-j
    --assertf~= 1.0  fat-k  1E-4 
    --test-- "float-auto-1376"
      fat-i: 5.0
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
    --assertf~= 4.050000036855E-5  fat-k  1E-4 
    --test-- "float-auto-1377"
      fat-i: 5.0
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
    --assertf~= 4.09134854042417E-33  fat-k  1E-4 
    --test-- "float-auto-1378"
      fat-i: 5.0
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
    --assertf~= 5.000005000005E+44  fat-k  1E-4 
    --test-- "float-auto-1379"
      fat-i: 5.0
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
    --assertf~= 6.49350649350649E-19  fat-k  1E-4 
    --test-- "float-auto-1380"
      fat-i: 123456.789
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
    --assertf~= -5.74890472926199E-5  fat-k  1E-4 
    --test-- "float-auto-1381"
      fat-i: 123456.789
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
    --assertf~= 5.74890473193904E-5  fat-k  1E-4 
    --test-- "float-auto-1382"
      fat-i: 123456.789
      fat-j: -1.0
      fat-k:  fat-i / fat-j
    --assertf~= -123456.789  fat-k  1E-4 
    --test-- "float-auto-1383"
      fat-i: 123456.789
      fat-j: 3.0
      fat-k:  fat-i / fat-j
    --assertf~= 41152.263  fat-k  1E-4 
    --test-- "float-auto-1384"
      fat-i: 123456.789
      fat-j: -7.0
      fat-k:  fat-i / fat-j
    --assertf~= -17636.6841428571  fat-k  1E-4 
    --test-- "float-auto-1385"
      fat-i: 123456.789
      fat-j: 5.0
      fat-k:  fat-i / fat-j
    --assertf~= 24691.3578  fat-k  1E-4 
    --test-- "float-auto-1386"
      fat-i: 123456.789
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
    --assertf~= 1.0  fat-k  1E-4 
    --test-- "float-auto-1387"
      fat-i: 123456.789
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
    --assertf~= 1.01020950696121E-28  fat-k  1E-4 
    --test-- "float-auto-1388"
      fat-i: 123456.789
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
    --assertf~= 1.23456912456912E+49  fat-k  1E-4 
    --test-- "float-auto-1389"
      fat-i: 123456.789
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
    --assertf~= 1.60333492207792E-14  fat-k  1E-4 
    --test-- "float-auto-1390"
      fat-i: 1.222090944E+33
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
    --assertf~= -5.6908044219017E+23  fat-k  1E-4 
    --test-- "float-auto-1391"
      fat-i: 1.222090944E+33
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
    --assertf~= 5.69080442455169E+23  fat-k  1E-4 
    --test-- "float-auto-1392"
      fat-i: 1.222090944E+33
      fat-j: -1.0
      fat-k:  fat-i / fat-j
    --assertf~= -1.222090944E+33  fat-k  1E-4 
    --test-- "float-auto-1393"
      fat-i: 1.222090944E+33
      fat-j: 3.0
      fat-k:  fat-i / fat-j
    --assertf~= 4.07363648E+32  fat-k  1E-4 
    --test-- "float-auto-1394"
      fat-i: 1.222090944E+33
      fat-j: -7.0
      fat-k:  fat-i / fat-j
    --assertf~= -1.74584420571429E+32  fat-k  1E-4 
    --test-- "float-auto-1395"
      fat-i: 1.222090944E+33
      fat-j: 5.0
      fat-k:  fat-i / fat-j
    --assertf~= 2.444181888E+32  fat-k  1E-4 
    --test-- "float-auto-1396"
      fat-i: 1.222090944E+33
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
    --assertf~= 9.89893673648032E+27  fat-k  1E-4 
    --test-- "float-auto-1397"
      fat-i: 1.222090944E+33
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
    --assertf~= 1.0  fat-k  1E-4 
    --test-- "float-auto-1398"
      fat-i: 1.222090944E+33
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
    --assertf~= 1.22209216609217E+77  fat-k  1E-4 
    --test-- "float-auto-1399"
      fat-i: 1.222090944E+33
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
    --assertf~= 158713109610390.0  fat-k  1E-4 
    --test-- "float-auto-1400"
      fat-i: 9.99999E-45
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
    --assertf~= -4.65660821646452E-54  fat-k  1E-4 
    --test-- "float-auto-1401"
      fat-i: 9.99999E-45
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
    --assertf~= 4.65660821863292E-54  fat-k  1E-4 
    --test-- "float-auto-1402"
      fat-i: 9.99999E-45
      fat-j: -1.0
      fat-k:  fat-i / fat-j
    --assertf~= -9.99999E-45  fat-k  1E-4 
    --test-- "float-auto-1403"
      fat-i: 9.99999E-45
      fat-j: 3.0
      fat-k:  fat-i / fat-j
    --assertf~= 3.33333E-45  fat-k  1E-4 
    --test-- "float-auto-1404"
      fat-i: 9.99999E-45
      fat-j: -7.0
      fat-k:  fat-i / fat-j
    --assertf~= -1.42857E-45  fat-k  1E-4 
    --test-- "float-auto-1405"
      fat-i: 9.99999E-45
      fat-j: 5.0
      fat-k:  fat-i / fat-j
    --assertf~= 1.999998E-45  fat-k  1E-4 
    --test-- "float-auto-1406"
      fat-i: 9.99999E-45
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
    --assertf~= 8.09999197370993E-50  fat-k  1E-4 
    --test-- "float-auto-1407"
      fat-i: 9.99999E-45
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
    --assertf~= 8.18268889815127E-78  fat-k  1E-4 
    --test-- "float-auto-1408"
      fat-i: 9.99999E-45
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
    --assertf~= 1.0  fat-k  1E-4 
    --test-- "float-auto-1409"
      fat-i: 9.99999E-45
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
    --assertf~= 1.2987E-63  fat-k  1E-4 
    --test-- "float-auto-1410"
      fat-i: 7.7E+18
      fat-j: -2147483648.0
      fat-k:  fat-i / fat-j
    --assertf~= -3585591912.26959  fat-k  1E-4 
    --test-- "float-auto-1411"
      fat-i: 7.7E+18
      fat-j: 2147483647.0
      fat-k:  fat-i / fat-j
    --assertf~= 3585591913.93926  fat-k  1E-4 
    --test-- "float-auto-1412"
      fat-i: 7.7E+18
      fat-j: -1.0
      fat-k:  fat-i / fat-j
    --assertf~= -7.7E+18  fat-k  1E-4 
    --test-- "float-auto-1413"
      fat-i: 7.7E+18
      fat-j: 3.0
      fat-k:  fat-i / fat-j
    --assertf~= 2.56666666666667E+18  fat-k  1E-4 
    --test-- "float-auto-1414"
      fat-i: 7.7E+18
      fat-j: -7.0
      fat-k:  fat-i / fat-j
    --assertf~= -1.1E+18  fat-k  1E-4 
    --test-- "float-auto-1415"
      fat-i: 7.7E+18
      fat-j: 5.0
      fat-k:  fat-i / fat-j
    --assertf~= 1.54E+18  fat-k  1E-4 
    --test-- "float-auto-1416"
      fat-i: 7.7E+18
      fat-j: 123456.789
      fat-k:  fat-i / fat-j
    --assertf~= 62370000567567.0  fat-k  1E-4 
    --test-- "float-auto-1417"
      fat-i: 7.7E+18
      fat-j: 1.222090944E+33
      fat-k:  fat-i / fat-j
    --assertf~= 6.30067675225323E-15  fat-k  1E-4 
    --test-- "float-auto-1418"
      fat-i: 7.7E+18
      fat-j: 9.99999E-45
      fat-k:  fat-i / fat-j
    --assertf~= 7.7000077000077E+62  fat-k  1E-4 
    --test-- "float-auto-1419"
      fat-i: 7.7E+18
      fat-j: 7.7E+18
      fat-k:  fat-i / fat-j
    --assertf~= 1.0  fat-k  1E-4 
  ]
float-auto-test-func
  --test-- "float-auto-1420"
  --assert false  = ( 0.0 = -1E-13 )
  --test-- "float-auto-1421"
  --assert true  = ( 0.0 = 0.0 )
  --test-- "float-auto-1422"
  --assert false  = ( 0.0 = 1E-13 )
  --test-- "float-auto-1423"
  --assert true  = ( -2147483648.0 = -2147483648.0 )
  --test-- "float-auto-1424"
  --assert true  = ( -2147483648.0 = -2147483648.0 )
  --test-- "float-auto-1425"
  --assert true  = ( -2147483648.0 = -2147483648.0 )
  --test-- "float-auto-1426"
  --assert true  = ( 2147483647.0 = 2147483647.0 )
  --test-- "float-auto-1427"
  --assert true  = ( 2147483647.0 = 2147483647.0 )
  --test-- "float-auto-1428"
  --assert true  = ( 2147483647.0 = 2147483647.0 )
  --test-- "float-auto-1429"
  --assert false  = ( -1.0 = -1.0000000000001 )
  --test-- "float-auto-1430"
  --assert true  = ( -1.0 = -1.0 )
  --test-- "float-auto-1431"
  --assert false  = ( -1.0 = -0.9999999999999 )
  --test-- "float-auto-1432"
  --assert false  = ( 3.0 = 2.9999999999999 )
  --test-- "float-auto-1433"
  --assert true  = ( 3.0 = 3.0 )
  --test-- "float-auto-1434"
  --assert false  = ( 3.0 = 3.0000000000001 )
  --test-- "float-auto-1435"
  --assert false  = ( -7.0 = -7.0000000000001 )
  --test-- "float-auto-1436"
  --assert true  = ( -7.0 = -7.0 )
  --test-- "float-auto-1437"
  --assert false  = ( -7.0 = -6.9999999999999 )
  --test-- "float-auto-1438"
  --assert false  = ( 5.0 = 4.9999999999999 )
  --test-- "float-auto-1439"
  --assert true  = ( 5.0 = 5.0 )
  --test-- "float-auto-1440"
  --assert false  = ( 5.0 = 5.0000000000001 )
  --test-- "float-auto-1441"
  --assert true  = ( 123456.789 = 123456.789 )
  --test-- "float-auto-1442"
  --assert true  = ( 123456.789 = 123456.789 )
  --test-- "float-auto-1443"
  --assert true  = ( 123456.789 = 123456.789 )
  --test-- "float-auto-1444"
  --assert true  = ( 1.222090944E+33 = 1.222090944E+33 )
  --test-- "float-auto-1445"
  --assert true  = ( 1.222090944E+33 = 1.222090944E+33 )
  --test-- "float-auto-1446"
  --assert true  = ( 1.222090944E+33 = 1.222090944E+33 )
  --test-- "float-auto-1447"
  --assert false  = ( 9.99999E-45 = -1E-13 )
  --test-- "float-auto-1448"
  --assert true  = ( 9.99999E-45 = 9.99999E-45 )
  --test-- "float-auto-1449"
  --assert false  = ( 9.99999E-45 = 1E-13 )
  --test-- "float-auto-1450"
  --assert true  = ( 7.7E+18 = 7.7E+18 )
  --test-- "float-auto-1451"
  --assert true  = ( 7.7E+18 = 7.7E+18 )
  --test-- "float-auto-1452"
  --assert true  = ( 7.7E+18 = 7.7E+18 )
  --test-- "float-auto-1453"
  --assert true  = ( 0.0 <> -1E-13 )
  --test-- "float-auto-1454"
  --assert false  = ( 0.0 <> 0.0 )
  --test-- "float-auto-1455"
  --assert true  = ( 0.0 <> 1E-13 )
  --test-- "float-auto-1456"
  --assert false  = ( -2147483648.0 <> -2147483648.0 )
  --test-- "float-auto-1457"
  --assert false  = ( -2147483648.0 <> -2147483648.0 )
  --test-- "float-auto-1458"
  --assert false  = ( -2147483648.0 <> -2147483648.0 )
  --test-- "float-auto-1459"
  --assert false  = ( 2147483647.0 <> 2147483647.0 )
  --test-- "float-auto-1460"
  --assert false  = ( 2147483647.0 <> 2147483647.0 )
  --test-- "float-auto-1461"
  --assert false  = ( 2147483647.0 <> 2147483647.0 )
  --test-- "float-auto-1462"
  --assert true  = ( -1.0 <> -1.0000000000001 )
  --test-- "float-auto-1463"
  --assert false  = ( -1.0 <> -1.0 )
  --test-- "float-auto-1464"
  --assert true  = ( -1.0 <> -0.9999999999999 )
  --test-- "float-auto-1465"
  --assert true  = ( 3.0 <> 2.9999999999999 )
  --test-- "float-auto-1466"
  --assert false  = ( 3.0 <> 3.0 )
  --test-- "float-auto-1467"
  --assert true  = ( 3.0 <> 3.0000000000001 )
  --test-- "float-auto-1468"
  --assert true  = ( -7.0 <> -7.0000000000001 )
  --test-- "float-auto-1469"
  --assert false  = ( -7.0 <> -7.0 )
  --test-- "float-auto-1470"
  --assert true  = ( -7.0 <> -6.9999999999999 )
  --test-- "float-auto-1471"
  --assert true  = ( 5.0 <> 4.9999999999999 )
  --test-- "float-auto-1472"
  --assert false  = ( 5.0 <> 5.0 )
  --test-- "float-auto-1473"
  --assert true  = ( 5.0 <> 5.0000000000001 )
  --test-- "float-auto-1474"
  --assert false  = ( 123456.789 <> 123456.789 )
  --test-- "float-auto-1475"
  --assert false  = ( 123456.789 <> 123456.789 )
  --test-- "float-auto-1476"
  --assert false  = ( 123456.789 <> 123456.789 )
  --test-- "float-auto-1477"
  --assert false  = ( 1.222090944E+33 <> 1.222090944E+33 )
  --test-- "float-auto-1478"
  --assert false  = ( 1.222090944E+33 <> 1.222090944E+33 )
  --test-- "float-auto-1479"
  --assert false  = ( 1.222090944E+33 <> 1.222090944E+33 )
  --test-- "float-auto-1480"
  --assert true  = ( 9.99999E-45 <> -1E-13 )
  --test-- "float-auto-1481"
  --assert false  = ( 9.99999E-45 <> 9.99999E-45 )
  --test-- "float-auto-1482"
  --assert true  = ( 9.99999E-45 <> 1E-13 )
  --test-- "float-auto-1483"
  --assert false  = ( 7.7E+18 <> 7.7E+18 )
  --test-- "float-auto-1484"
  --assert false  = ( 7.7E+18 <> 7.7E+18 )
  --test-- "float-auto-1485"
  --assert false  = ( 7.7E+18 <> 7.7E+18 )
  --test-- "float-auto-1486"
  --assert false  = ( 0.0 < -1E-13 )
  --test-- "float-auto-1487"
  --assert false  = ( 0.0 < 0.0 )
  --test-- "float-auto-1488"
  --assert true  = ( 0.0 < 1E-13 )
  --test-- "float-auto-1489"
  --assert false  = ( -2147483648.0 < -2147483648.0 )
  --test-- "float-auto-1490"
  --assert false  = ( -2147483648.0 < -2147483648.0 )
  --test-- "float-auto-1491"
  --assert false  = ( -2147483648.0 < -2147483648.0 )
  --test-- "float-auto-1492"
  --assert false  = ( 2147483647.0 < 2147483647.0 )
  --test-- "float-auto-1493"
  --assert false  = ( 2147483647.0 < 2147483647.0 )
  --test-- "float-auto-1494"
  --assert false  = ( 2147483647.0 < 2147483647.0 )
  --test-- "float-auto-1495"
  --assert false  = ( -1.0 < -1.0000000000001 )
  --test-- "float-auto-1496"
  --assert false  = ( -1.0 < -1.0 )
  --test-- "float-auto-1497"
  --assert true  = ( -1.0 < -0.9999999999999 )
  --test-- "float-auto-1498"
  --assert false  = ( 3.0 < 2.9999999999999 )
  --test-- "float-auto-1499"
  --assert false  = ( 3.0 < 3.0 )
  --test-- "float-auto-1500"
  --assert true  = ( 3.0 < 3.0000000000001 )
  --test-- "float-auto-1501"
  --assert false  = ( -7.0 < -7.0000000000001 )
  --test-- "float-auto-1502"
  --assert false  = ( -7.0 < -7.0 )
  --test-- "float-auto-1503"
  --assert true  = ( -7.0 < -6.9999999999999 )
  --test-- "float-auto-1504"
  --assert false  = ( 5.0 < 4.9999999999999 )
  --test-- "float-auto-1505"
  --assert false  = ( 5.0 < 5.0 )
  --test-- "float-auto-1506"
  --assert true  = ( 5.0 < 5.0000000000001 )
  --test-- "float-auto-1507"
  --assert false  = ( 123456.789 < 123456.789 )
  --test-- "float-auto-1508"
  --assert false  = ( 123456.789 < 123456.789 )
  --test-- "float-auto-1509"
  --assert false  = ( 123456.789 < 123456.789 )
  --test-- "float-auto-1510"
  --assert false  = ( 1.222090944E+33 < 1.222090944E+33 )
  --test-- "float-auto-1511"
  --assert false  = ( 1.222090944E+33 < 1.222090944E+33 )
  --test-- "float-auto-1512"
  --assert false  = ( 1.222090944E+33 < 1.222090944E+33 )
  --test-- "float-auto-1513"
  --assert false  = ( 9.99999E-45 < -1E-13 )
  --test-- "float-auto-1514"
  --assert false  = ( 9.99999E-45 < 9.99999E-45 )
  --test-- "float-auto-1515"
  --assert true  = ( 9.99999E-45 < 1E-13 )
  --test-- "float-auto-1516"
  --assert false  = ( 7.7E+18 < 7.7E+18 )
  --test-- "float-auto-1517"
  --assert false  = ( 7.7E+18 < 7.7E+18 )
  --test-- "float-auto-1518"
  --assert false  = ( 7.7E+18 < 7.7E+18 )
  --test-- "float-auto-1519"
  --assert true  = ( 0.0 > -1E-13 )
  --test-- "float-auto-1520"
  --assert false  = ( 0.0 > 0.0 )
  --test-- "float-auto-1521"
  --assert false  = ( 0.0 > 1E-13 )
  --test-- "float-auto-1522"
  --assert false  = ( -2147483648.0 > -2147483648.0 )
  --test-- "float-auto-1523"
  --assert false  = ( -2147483648.0 > -2147483648.0 )
  --test-- "float-auto-1524"
  --assert false  = ( -2147483648.0 > -2147483648.0 )
  --test-- "float-auto-1525"
  --assert false  = ( 2147483647.0 > 2147483647.0 )
  --test-- "float-auto-1526"
  --assert false  = ( 2147483647.0 > 2147483647.0 )
  --test-- "float-auto-1527"
  --assert false  = ( 2147483647.0 > 2147483647.0 )
  --test-- "float-auto-1528"
  --assert true  = ( -1.0 > -1.0000000000001 )
  --test-- "float-auto-1529"
  --assert false  = ( -1.0 > -1.0 )
  --test-- "float-auto-1530"
  --assert false  = ( -1.0 > -0.9999999999999 )
  --test-- "float-auto-1531"
  --assert true  = ( 3.0 > 2.9999999999999 )
  --test-- "float-auto-1532"
  --assert false  = ( 3.0 > 3.0 )
  --test-- "float-auto-1533"
  --assert false  = ( 3.0 > 3.0000000000001 )
  --test-- "float-auto-1534"
  --assert true  = ( -7.0 > -7.0000000000001 )
  --test-- "float-auto-1535"
  --assert false  = ( -7.0 > -7.0 )
  --test-- "float-auto-1536"
  --assert false  = ( -7.0 > -6.9999999999999 )
  --test-- "float-auto-1537"
  --assert true  = ( 5.0 > 4.9999999999999 )
  --test-- "float-auto-1538"
  --assert false  = ( 5.0 > 5.0 )
  --test-- "float-auto-1539"
  --assert false  = ( 5.0 > 5.0000000000001 )
  --test-- "float-auto-1540"
  --assert false  = ( 123456.789 > 123456.789 )
  --test-- "float-auto-1541"
  --assert false  = ( 123456.789 > 123456.789 )
  --test-- "float-auto-1542"
  --assert false  = ( 123456.789 > 123456.789 )
  --test-- "float-auto-1543"
  --assert false  = ( 1.222090944E+33 > 1.222090944E+33 )
  --test-- "float-auto-1544"
  --assert false  = ( 1.222090944E+33 > 1.222090944E+33 )
  --test-- "float-auto-1545"
  --assert false  = ( 1.222090944E+33 > 1.222090944E+33 )
  --test-- "float-auto-1546"
  --assert true  = ( 9.99999E-45 > -1E-13 )
  --test-- "float-auto-1547"
  --assert false  = ( 9.99999E-45 > 9.99999E-45 )
  --test-- "float-auto-1548"
  --assert false  = ( 9.99999E-45 > 1E-13 )
  --test-- "float-auto-1549"
  --assert false  = ( 7.7E+18 > 7.7E+18 )
  --test-- "float-auto-1550"
  --assert false  = ( 7.7E+18 > 7.7E+18 )
  --test-- "float-auto-1551"
  --assert false  = ( 7.7E+18 > 7.7E+18 )
  --test-- "float-auto-1552"
  --assert true  = ( 0.0 >= -1E-13 )
  --test-- "float-auto-1553"
  --assert true  = ( 0.0 >= 0.0 )
  --test-- "float-auto-1554"
  --assert false  = ( 0.0 >= 1E-13 )
  --test-- "float-auto-1555"
  --assert true  = ( -2147483648.0 >= -2147483648.0 )
  --test-- "float-auto-1556"
  --assert true  = ( -2147483648.0 >= -2147483648.0 )
  --test-- "float-auto-1557"
  --assert true  = ( -2147483648.0 >= -2147483648.0 )
  --test-- "float-auto-1558"
  --assert true  = ( 2147483647.0 >= 2147483647.0 )
  --test-- "float-auto-1559"
  --assert true  = ( 2147483647.0 >= 2147483647.0 )
  --test-- "float-auto-1560"
  --assert true  = ( 2147483647.0 >= 2147483647.0 )
  --test-- "float-auto-1561"
  --assert true  = ( -1.0 >= -1.0000000000001 )
  --test-- "float-auto-1562"
  --assert true  = ( -1.0 >= -1.0 )
  --test-- "float-auto-1563"
  --assert false  = ( -1.0 >= -0.9999999999999 )
  --test-- "float-auto-1564"
  --assert true  = ( 3.0 >= 2.9999999999999 )
  --test-- "float-auto-1565"
  --assert true  = ( 3.0 >= 3.0 )
  --test-- "float-auto-1566"
  --assert false  = ( 3.0 >= 3.0000000000001 )
  --test-- "float-auto-1567"
  --assert true  = ( -7.0 >= -7.0000000000001 )
  --test-- "float-auto-1568"
  --assert true  = ( -7.0 >= -7.0 )
  --test-- "float-auto-1569"
  --assert false  = ( -7.0 >= -6.9999999999999 )
  --test-- "float-auto-1570"
  --assert true  = ( 5.0 >= 4.9999999999999 )
  --test-- "float-auto-1571"
  --assert true  = ( 5.0 >= 5.0 )
  --test-- "float-auto-1572"
  --assert false  = ( 5.0 >= 5.0000000000001 )
  --test-- "float-auto-1573"
  --assert true  = ( 123456.789 >= 123456.789 )
  --test-- "float-auto-1574"
  --assert true  = ( 123456.789 >= 123456.789 )
  --test-- "float-auto-1575"
  --assert true  = ( 123456.789 >= 123456.789 )
  --test-- "float-auto-1576"
  --assert true  = ( 1.222090944E+33 >= 1.222090944E+33 )
  --test-- "float-auto-1577"
  --assert true  = ( 1.222090944E+33 >= 1.222090944E+33 )
  --test-- "float-auto-1578"
  --assert true  = ( 1.222090944E+33 >= 1.222090944E+33 )
  --test-- "float-auto-1579"
  --assert true  = ( 9.99999E-45 >= -1E-13 )
  --test-- "float-auto-1580"
  --assert true  = ( 9.99999E-45 >= 9.99999E-45 )
  --test-- "float-auto-1581"
  --assert false  = ( 9.99999E-45 >= 1E-13 )
  --test-- "float-auto-1582"
  --assert true  = ( 7.7E+18 >= 7.7E+18 )
  --test-- "float-auto-1583"
  --assert true  = ( 7.7E+18 >= 7.7E+18 )
  --test-- "float-auto-1584"
  --assert true  = ( 7.7E+18 >= 7.7E+18 )
  --test-- "float-auto-1585"
  --assert false  = ( 0.0 <= -1E-13 )
  --test-- "float-auto-1586"
  --assert true  = ( 0.0 <= 0.0 )
  --test-- "float-auto-1587"
  --assert true  = ( 0.0 <= 1E-13 )
  --test-- "float-auto-1588"
  --assert true  = ( -2147483648.0 <= -2147483648.0 )
  --test-- "float-auto-1589"
  --assert true  = ( -2147483648.0 <= -2147483648.0 )
  --test-- "float-auto-1590"
  --assert true  = ( -2147483648.0 <= -2147483648.0 )
  --test-- "float-auto-1591"
  --assert true  = ( 2147483647.0 <= 2147483647.0 )
  --test-- "float-auto-1592"
  --assert true  = ( 2147483647.0 <= 2147483647.0 )
  --test-- "float-auto-1593"
  --assert true  = ( 2147483647.0 <= 2147483647.0 )
  --test-- "float-auto-1594"
  --assert false  = ( -1.0 <= -1.0000000000001 )
  --test-- "float-auto-1595"
  --assert true  = ( -1.0 <= -1.0 )
  --test-- "float-auto-1596"
  --assert true  = ( -1.0 <= -0.9999999999999 )
  --test-- "float-auto-1597"
  --assert false  = ( 3.0 <= 2.9999999999999 )
  --test-- "float-auto-1598"
  --assert true  = ( 3.0 <= 3.0 )
  --test-- "float-auto-1599"
  --assert true  = ( 3.0 <= 3.0000000000001 )
  --test-- "float-auto-1600"
  --assert false  = ( -7.0 <= -7.0000000000001 )
  --test-- "float-auto-1601"
  --assert true  = ( -7.0 <= -7.0 )
  --test-- "float-auto-1602"
  --assert true  = ( -7.0 <= -6.9999999999999 )
  --test-- "float-auto-1603"
  --assert false  = ( 5.0 <= 4.9999999999999 )
  --test-- "float-auto-1604"
  --assert true  = ( 5.0 <= 5.0 )
  --test-- "float-auto-1605"
  --assert true  = ( 5.0 <= 5.0000000000001 )
  --test-- "float-auto-1606"
  --assert true  = ( 123456.789 <= 123456.789 )
  --test-- "float-auto-1607"
  --assert true  = ( 123456.789 <= 123456.789 )
  --test-- "float-auto-1608"
  --assert true  = ( 123456.789 <= 123456.789 )
  --test-- "float-auto-1609"
  --assert true  = ( 1.222090944E+33 <= 1.222090944E+33 )
  --test-- "float-auto-1610"
  --assert true  = ( 1.222090944E+33 <= 1.222090944E+33 )
  --test-- "float-auto-1611"
  --assert true  = ( 1.222090944E+33 <= 1.222090944E+33 )
  --test-- "float-auto-1612"
  --assert false  = ( 9.99999E-45 <= -1E-13 )
  --test-- "float-auto-1613"
  --assert true  = ( 9.99999E-45 <= 9.99999E-45 )
  --test-- "float-auto-1614"
  --assert true  = ( 9.99999E-45 <= 1E-13 )
  --test-- "float-auto-1615"
  --assert true  = ( 7.7E+18 <= 7.7E+18 )
  --test-- "float-auto-1616"
  --assert true  = ( 7.7E+18 <= 7.7E+18 )
  --test-- "float-auto-1617"
  --assert true  = ( 7.7E+18 <= 7.7E+18 )

===end-group===

~~~end-file~~~
