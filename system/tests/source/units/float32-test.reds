Red/System [
	Title:		"Red/System float32! datatype tests"
	Author:		"Peter W A Wood"
	File:		%float32-test.reds
	Version:	0.1.0
	Tabs:		4
	Rights:		"Copyright (C) 2012-2015 Peter W A Wood. All rights reserved."
	License:	"BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds

~~~start-file~~~ "float32"

===start-group=== "float32 assignment"
	--test-- "float32-1"
		f: as float32! 100.0
		--assert f = as float32! 100.0
	--test-- "float32-2"
		f: as float32! 1.222090944E+33
		--assert f = as float32! 1.222090944E+33
	--test-- "float32-3"
		f: as float32! 9.99999E-25
		--assert f = as float32! 9.99999E-25
	--test-- "float32-4"
		f: as float32! 1.0
		f1: f
		--assert f1 = as float32! 1.0
===end-group===

===start-group=== "float argument to external function"

		pi64: 3.14159265358979323846
		
	--test-- "float32-ext-1"
		--assert (as float32! -1.0) = as-float32 cos pi64
		
	--test-- "float32-ext-2"
		--assertf32~=  (as float32! 0.00) (as float32! sin pi64) 0.1E-7
		
	--test-- "float32-ext-3"
		--assert (as float32! -1.0) = as-float32 cos 3.1415927
	
===end-group===

===start-group=== "float32 function arguments"
		ff: func [
		  fff     [float32!]
		  ffg     [float32!]
		  return: [integer!]
		  /local
		  ffl [float32!]
		][
		   ffl: fff
		   if ffl <> fff [return 1]
		   ffl: ffg
		   if ffl <> ffg [return 2]
		   1
		]
		
	--test-- "float32-func-args-1"
		--assert 1 = ff as float32! 1.0 as float32! 2.0
		
	--test-- "float32-func-args-2"
		--assert 1 = ff as float32! 1.222090944E+33 as float32! 9.99999E-25
  
===end-group===

===start-group=== "float32 locals"

		local-float: func [n [float32!] return: [float32!] /local p][p: n p]
		
	--test-- "float32-loc-1"
		pi64: 3.14159265358979
		pi32: local-float as float32! 3.1415927
		--assert pi32 =  as float32! 3.1415927
		--assert (as float32! -1.0) = as-float32 cos pi64
		--assert (as float32! -1.0) = local-float as-float32 cos pi64
		
	--test-- "float32-loc-2"
		f: local-float pi32
		--assert pi32 = local-float f
		
	--test-- "float32-loc-3"
		local-float2: func [
			n [float32!] return: [float32!] /local p
		][
			p: n local-float p
		]
		
		pi32: local-float2 as float32! 3.1415927
		--assert (as float32! 3.1415927) = local-float2 pi32
		--assert (as float32! -1.0) = local-float2 as-float32 cos pi64
		f: local-float2 pi32
		--assert pi32 = local-float2 f
		
	--test-- "float32-loc-4"
		local-float3: func [
			n [float32!] return: [float32!] /local p [float32!]
		][
			p: n local-float p
		]
		
		pi32: local-float3 as float32! 3.1415927
		--assert (as float32! 3.1415927) = local-float3 pi32
		--assert (as float32! -1.0) = local-float3 as-float32 cos pi64
		f: local-float3 pi32
		--assert pi32 = local-float3 f
		
	--test-- "float32-loc-5"
		local-float4: func [n [float32!] return: [float32!] /local r p][p: n p]
		--assert (as float32! 3.1415927) = local-float4 pi32
		--assert (as float32! -1.0) = local-float4 as-float32 cos pi64
		f: local-float4 pi32
		--assert pi32 = local-float4 f
		
	--test-- "float32-loc-6"
		local-float5: func [n [float32!] return: [float32!] /local r p][p: n local-float p]
		--assert (as float32! 3.1415927) = local-float5 pi32
		--assert (as float32! -1.0) = local-float5 as-float32 cos pi64
		f: local-float5 pi32
		--assert pi32 = local-float5 f

===end-group===

===start-group=== "float32 function return"

		ff1: func [
				ff1i      [integer!]
				return:   [float32!]
		][
			as float32! switch ff1i [
				1 [1.0]
				2 [1.222090944E+33]
				3 [9.99999E-30]
			]
		]
	--test-- "float32 return 1"
		--assert (as float32! 1.0) = ff1 1
	--test-- "float32 return 2"
		--assert (as float32! 1.222090944E+33) = ff1 2
	--test-- "float32 return 3"
		--assert (as float32! 9.99999E-30) = ff1 3
  
===end-group===

===start-group=== "float32 struct!"

	--test-- "float32-struct-1"
		sf1: declare struct! [
		  a   [float32!]
		]
		--assert (as float32! 0.0) = sf1/a
		
	--test-- "float32-struct-2"
		sf2: declare struct! [
			a   [float32!]
		]
		sf2/a: as float32! 1.222090944E+33
		--assert (as float32! 1.222090944E+33) = sf2/a
		
		 
		sf3: declare struct! [
			a   [float32!]
			b   [float32!]
		]
		
	--test-- "float32-struct-3"
		sf3/a: as float32! 1.222090944E+33
		sf3/b: as float32! 9.99999E-25	  
		--assert (as float32! 1.222090944E+33) = sf3/a
		--assert (as float32! 9.99999E-25) = sf3/b
		  
	--test-- "float32-struct-4"
		sf4: declare struct! [
			c   [byte!]
			a   [float32!]
			l   [logic!]
			b   [float32!]
		]
		sf4/a: as float32! 1.222090944E+33
		  sf4/b: as float32! 9.99999E-25
		--assert (as float32! 1.222090944E+33) = sf4/a
		--assert (as float32! 9.99999E-25) = sf4/b

===end-group===

===start-group=== "float32 pointers"

	--test-- "float32-point-1"
		pi32: as float32! 3.1415927
		p: declare pointer! [float32!]
		p/value: as float32! 3.1415927
		--assert pi32 = p/value
 
===end-group===

===start-group=== "expressions with returned float values"

		fe1: function [
			return: [float32!]
		][
			as float32! 1.0
		]
		fe2: function [
			return: [float32!]
		][
			as float32! 2.0
		]
    
	--test-- "ewrfv0"
		--assertf32~= as float32! 1.0 (fe1 * as float32! 1.0) as float32! 0.1E-3
		
	--test-- "ewrfv1"
		--assertf32~= as float32! 1.0 (as float32! 1.0) * fe1 as float32! 0.1E-3
		
	--test-- "ewrfv2"
		--assertf32~= as float32! 0.5 (fe1 / fe2) as float32! 0.1E-3
		
===end-group===

===start-group=== "float32 arguments to typed functions"
		fatf1: function [
			[typed]
			count [integer!]
			list [typed-value!]
			return: [float32!]
			/local
				a [float32!]
		][
			a: as float32! list/value
			a
		]
    
		fatf2: function [
			[typed]
			count [integer!]
			list [typed-value!]
			return: [float32!]
			/local
				a [float32!]
				b [float32!]
		][
			a: as float32! list/value 
			list: list + 1
			b: as float32! list/value
			a + b
		]
  
	--test-- "fatf-1"
		--assert (as float32! 2.0) = (fatf1 as float32! 2.0)
  
	--test-- "fatf-2"
		--assert (as float32! 2.0) = ((fatf1 as float32! 1.0) + (fatf1 as float32! 1.0))
  
	--test-- "fatf-3"
		--assert (as float32! 3.0) = fatf2 [as float32! 1.0 as float32! 2.0]
  

===end-group===

===start-group=== "Casting float! arguments to float32!"

		cfaf1: function [
			a   [float!]
			return: [float32!]
		][
			as float32! a
		]
		cfaf2: function [
			a   [float!]
			b   [float!]
			return: [float32!]
		][
			(as float32! a) + (as float32! b)
		]
    
	--test-- "cfaf1"
		--assert (as float32! 1.0) = cfaf1 1.0
  
	--test-- "cfaf2"
		--assertf32~= (as float32! 3.0) (cfaf2 1.0 2.0) (as float32! 0.1e-7)

===end-group===

===start-group=== "calculations"

		fcfoo: func [a [float32!] return: [float32!]][a]
		
		fcptr: declare struct! [a [float32!]]
		fcptr/a: as float32! 3.0 
		
		fc2: as float32! 3.0
	
	--test-- "fc-1"
		fc1: as float32! 2.0
		fc1: fc1 / (fc1 - as float32! 1.0)
		--assertf32~= as float32! 2.0 fc1 as float32! 0.1E-7

	--test-- "fc-2"
		--assert (as float32! 5.0) - (as float32! 3.0) = as float32! 2.0		;-- imm/imm

	--test-- "fc-3"
		--assert (as float32! 5.0) - fc2 = as float32! 2.0						;-- imm/ref

	--test-- "fc-4"
		--assert (as float32! 5.0) - (fcfoo as float32! 3.0) = as float32! 2.0	;-- imm/reg(block!)

	--test-- "fc-5"
		--assertf32~= (as float32! 5.0) - fcptr/a as float32! 2.0 as float32! 1E-10	;-- imm/reg(path!)

	--test-- "fc-6"
		--assert fc2 - (as float32! 5.0) = as float32! -2.0						;-- ref/imm

	--test-- "fc-7"
		--assert fc2 - (fcfoo as float32! 5.0) = as float32! -2.0				;-- ref/reg(block!)

	--test-- "fc-8"
		--assert fc2 - fcptr/a = as float32! 0.0								;-- ref/reg(path!)
		
	--test-- "fc-9"
		--assertf32~= (fcfoo as float32! 5.0) - as float32! 3.0 as float32! 2.0 as float32! 1E-10	;-- reg(block!)/imm

	--test-- "fc-10"
		--assert (fcfoo as float32! 5.0) - (fcfoo as float32! 3.0) = as float32! 2.0	;-- reg(block!)/reg(block!)

	--test-- "fc-11"
		--assert (fcfoo as float32! 5.0) - fcptr/a = as float32! 2.0			;-- reg(block!)/reg(path!)
	
	--test-- "fc-12"
		--assert fcptr/a - (fcfoo as float32! 5.0) = as float32! -2.0			;-- reg(path!)/reg(block!)

===end-group===

===start-group=== "implicit literal type casting of function arguments"
	--test-- "fiitc1"
		flitc1-f: function [
			x		[float32!]
			y		[float!]
			z		[float32!]
			return:	[float32!]
		][
			x + z
		]
		--assert (as float32! 4.00) = flitc1-f 1.00 2.00 3.00
===end-group===

~~~end-file~~~
