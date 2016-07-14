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

~~~end-file~~~
