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
			list [typed-float32!]
			return: [float32!]
		][
			list/value
		]
	
		fatf2: function [
			[typed]
			count [integer!]
			list [typed-float32!]
			return: [float32!]
			/local
				a [float32!]
				b [float32!]
		][
			a: list/value 
			list: list + 1
			b: list/value
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

===start-group=== "Arithmetic and comparison"

  --test-- "float-auto-1"
  --assertf32~= as float32!  2147483.0  (( as float32!  0.0 ) + ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-2"
      f32-i: as float32! 0.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-3"
  --assertf32~= as float32!  3.0  (( as float32!  0.0 ) + ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-4"
      f32-i: as float32! 0.0
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  3.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-5"
  --assertf32~= as float32!  5.0  (( as float32!  0.0 ) + ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-6"
      f32-i: as float32! 0.0
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  5.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-7"
  --assertf32~= as float32!  456.789  (( as float32!  0.0 ) + ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-8"
      f32-i: as float32! 0.0
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  456.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-9"
  --assertf32~= as float32!  123456.7  (( as float32!  0.0 ) + ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-10"
      f32-i: as float32! 0.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123456.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-11"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  0.0 ) + ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-12"
      f32-i: as float32! 0.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-13"
  --assertf32~= as float32!  9.99999E-7  (( as float32!  0.0 ) + ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-14"
      f32-i: as float32! 0.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  9.99999E-7  f32-k  as float32!  1E-6 
  --test-- "float-auto-15"
  --assertf32~= as float32!  7.7E+18  (( as float32!  0.0 ) + ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-16"
      f32-i: as float32! 0.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-17"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  -2147483.0 ) + ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-18"
      f32-i: as float32! -2147483.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-19"
  --assertf32~= as float32!  7.69999999999785E+18  (( as float32!  -2147483.0 ) + ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-20"
      f32-i: as float32! -2147483.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.69999999999785E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-21"
  --assertf32~= as float32!  2147483.0  (( as float32!  2147483.0 ) + ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-22"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-23"
  --assertf32~= as float32!  4294966.0  (( as float32!  2147483.0 ) + ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-24"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  4294966.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-25"
  --assertf32~= as float32!  2147482.0  (( as float32!  2147483.0 ) + ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-26"
      f32-i: as float32! 2147483.0
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147482.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-27"
  --assertf32~= as float32!  2147486.0  (( as float32!  2147483.0 ) + ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-28"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147486.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-29"
  --assertf32~= as float32!  2147476.0  (( as float32!  2147483.0 ) + ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-30"
      f32-i: as float32! 2147483.0
      f32-j: as float32! -7.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147476.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-31"
  --assertf32~= as float32!  2147488.0  (( as float32!  2147483.0 ) + ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-32"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147488.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-33"
  --assertf32~= as float32!  2147939.789  (( as float32!  2147483.0 ) + ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-34"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147939.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-35"
  --assertf32~= as float32!  2270939.7  (( as float32!  2147483.0 ) + ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-36"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2270939.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-37"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  2147483.0 ) + ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-38"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-39"
  --assertf32~= as float32!  2147483.000001  (( as float32!  2147483.0 ) + ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-40"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147483.000001  f32-k  as float32!  1E-6 
  --test-- "float-auto-41"
  --assertf32~= as float32!  7.70000000000215E+18  (( as float32!  2147483.0 ) + ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-42"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.70000000000215E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-43"
  --assertf32~= as float32!  2147482.0  (( as float32!  -1.0 ) + ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-44"
      f32-i: as float32! -1.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147482.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-45"
  --assertf32~= as float32!  2.0  (( as float32!  -1.0 ) + ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-46"
      f32-i: as float32! -1.0
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-47"
  --assertf32~= as float32!  4.0  (( as float32!  -1.0 ) + ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-48"
      f32-i: as float32! -1.0
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  4.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-49"
  --assertf32~= as float32!  455.789  (( as float32!  -1.0 ) + ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-50"
      f32-i: as float32! -1.0
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  455.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-51"
  --assertf32~= as float32!  123455.7  (( as float32!  -1.0 ) + ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-52"
      f32-i: as float32! -1.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123455.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-53"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  -1.0 ) + ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-54"
      f32-i: as float32! -1.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-55"
  --assertf32~= as float32!  7.7E+18  (( as float32!  -1.0 ) + ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-56"
      f32-i: as float32! -1.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-57"
  --assertf32~= as float32!  3.0  (( as float32!  3.0 ) + ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-58"
      f32-i: as float32! 3.0
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  3.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-59"
  --assertf32~= as float32!  2147486.0  (( as float32!  3.0 ) + ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-60"
      f32-i: as float32! 3.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147486.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-61"
  --assertf32~= as float32!  2.0  (( as float32!  3.0 ) + ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-62"
      f32-i: as float32! 3.0
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-63"
  --assertf32~= as float32!  6.0  (( as float32!  3.0 ) + ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-64"
      f32-i: as float32! 3.0
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  6.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-65"
  --assertf32~= as float32!  8.0  (( as float32!  3.0 ) + ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-66"
      f32-i: as float32! 3.0
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  8.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-67"
  --assertf32~= as float32!  459.789  (( as float32!  3.0 ) + ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-68"
      f32-i: as float32! 3.0
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  459.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-69"
  --assertf32~= as float32!  123459.7  (( as float32!  3.0 ) + ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-70"
      f32-i: as float32! 3.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123459.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-71"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  3.0 ) + ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-72"
      f32-i: as float32! 3.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-73"
  --assertf32~= as float32!  3.000000999999  (( as float32!  3.0 ) + ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-74"
      f32-i: as float32! 3.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  3.000000999999  f32-k  as float32!  1E-6 
  --test-- "float-auto-75"
  --assertf32~= as float32!  7.7E+18  (( as float32!  3.0 ) + ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-76"
      f32-i: as float32! 3.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-77"
  --assertf32~= as float32!  2147476.0  (( as float32!  -7.0 ) + ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-78"
      f32-i: as float32! -7.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147476.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-79"
  --assertf32~= as float32!  449.789  (( as float32!  -7.0 ) + ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-80"
      f32-i: as float32! -7.0
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  449.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-81"
  --assertf32~= as float32!  123449.7  (( as float32!  -7.0 ) + ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-82"
      f32-i: as float32! -7.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123449.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-83"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  -7.0 ) + ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-84"
      f32-i: as float32! -7.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-85"
  --assertf32~= as float32!  7.7E+18  (( as float32!  -7.0 ) + ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-86"
      f32-i: as float32! -7.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-87"
  --assertf32~= as float32!  5.0  (( as float32!  5.0 ) + ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-88"
      f32-i: as float32! 5.0
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  5.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-89"
  --assertf32~= as float32!  2147488.0  (( as float32!  5.0 ) + ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-90"
      f32-i: as float32! 5.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147488.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-91"
  --assertf32~= as float32!  4.0  (( as float32!  5.0 ) + ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-92"
      f32-i: as float32! 5.0
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  4.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-93"
  --assertf32~= as float32!  8.0  (( as float32!  5.0 ) + ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-94"
      f32-i: as float32! 5.0
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  8.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-95"
  --assertf32~= as float32!  10.0  (( as float32!  5.0 ) + ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-96"
      f32-i: as float32! 5.0
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  10.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-97"
  --assertf32~= as float32!  461.789  (( as float32!  5.0 ) + ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-98"
      f32-i: as float32! 5.0
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  461.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-99"
  --assertf32~= as float32!  123461.7  (( as float32!  5.0 ) + ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-100"
      f32-i: as float32! 5.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123461.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-101"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  5.0 ) + ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-102"
      f32-i: as float32! 5.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-103"
  --assertf32~= as float32!  5.000000999999  (( as float32!  5.0 ) + ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-104"
      f32-i: as float32! 5.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  5.000000999999  f32-k  as float32!  1E-6 
  --test-- "float-auto-105"
  --assertf32~= as float32!  7.7E+18  (( as float32!  5.0 ) + ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-106"
      f32-i: as float32! 5.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-107"
  --assertf32~= as float32!  456.789  (( as float32!  456.789 ) + ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-108"
      f32-i: as float32! 456.789
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  456.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-109"
  --assertf32~= as float32!  2147939.789  (( as float32!  456.789 ) + ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-110"
      f32-i: as float32! 456.789
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147939.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-111"
  --assertf32~= as float32!  455.789  (( as float32!  456.789 ) + ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-112"
      f32-i: as float32! 456.789
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  455.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-113"
  --assertf32~= as float32!  459.789  (( as float32!  456.789 ) + ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-114"
      f32-i: as float32! 456.789
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  459.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-115"
  --assertf32~= as float32!  449.789  (( as float32!  456.789 ) + ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-116"
      f32-i: as float32! 456.789
      f32-j: as float32! -7.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  449.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-117"
  --assertf32~= as float32!  461.789  (( as float32!  456.789 ) + ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-118"
      f32-i: as float32! 456.789
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  461.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-119"
  --assertf32~= as float32!  913.578  (( as float32!  456.789 ) + ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-120"
      f32-i: as float32! 456.789
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  913.578  f32-k  as float32!  1E-6 
  --test-- "float-auto-121"
  --assertf32~= as float32!  123913.489  (( as float32!  456.789 ) + ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-122"
      f32-i: as float32! 456.789
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123913.489  f32-k  as float32!  1E-6 
  --test-- "float-auto-123"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  456.789 ) + ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-124"
      f32-i: as float32! 456.789
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-125"
  --assertf32~= as float32!  456.789000999999  (( as float32!  456.789 ) + ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-126"
      f32-i: as float32! 456.789
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  456.789000999999  f32-k  as float32!  1E-6 
  --test-- "float-auto-127"
  --assertf32~= as float32!  7.7E+18  (( as float32!  456.789 ) + ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-128"
      f32-i: as float32! 456.789
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-129"
  --assertf32~= as float32!  123456.7  (( as float32!  123456.7 ) + ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-130"
      f32-i: as float32! 123456.7
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123456.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-131"
  --assertf32~= as float32!  2270939.7  (( as float32!  123456.7 ) + ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-132"
      f32-i: as float32! 123456.7
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2270939.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-133"
  --assertf32~= as float32!  123455.7  (( as float32!  123456.7 ) + ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-134"
      f32-i: as float32! 123456.7
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123455.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-135"
  --assertf32~= as float32!  123459.7  (( as float32!  123456.7 ) + ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-136"
      f32-i: as float32! 123456.7
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123459.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-137"
  --assertf32~= as float32!  123449.7  (( as float32!  123456.7 ) + ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-138"
      f32-i: as float32! 123456.7
      f32-j: as float32! -7.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123449.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-139"
  --assertf32~= as float32!  123461.7  (( as float32!  123456.7 ) + ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-140"
      f32-i: as float32! 123456.7
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123461.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-141"
  --assertf32~= as float32!  123913.489  (( as float32!  123456.7 ) + ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-142"
      f32-i: as float32! 123456.7
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123913.489  f32-k  as float32!  1E-6 
  --test-- "float-auto-143"
  --assertf32~= as float32!  246913.4  (( as float32!  123456.7 ) + ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-144"
      f32-i: as float32! 123456.7
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  246913.4  f32-k  as float32!  1E-6 
  --test-- "float-auto-145"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  123456.7 ) + ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-146"
      f32-i: as float32! 123456.7
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-147"
  --assertf32~= as float32!  123456.700001  (( as float32!  123456.7 ) + ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-148"
      f32-i: as float32! 123456.7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123456.700001  f32-k  as float32!  1E-6 
  --test-- "float-auto-149"
  --assertf32~= as float32!  7.70000000000012E+18  (( as float32!  123456.7 ) + ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-150"
      f32-i: as float32! 123456.7
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.70000000000012E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-151"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) + ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-152"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-153"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) + ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-154"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! -2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-155"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) + ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-156"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-157"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) + ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-158"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-159"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) + ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-160"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-161"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) + ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-162"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! -7.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-163"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) + ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-164"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-165"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) + ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-166"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-167"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) + ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-168"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-169"
  --assertf32~= as float32!  2.445888E+22  (( as float32!  1.222944E+22 ) + ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-170"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2.445888E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-171"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) + ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-172"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-173"
  --assertf32~= as float32!  1.223714E+22  (( as float32!  1.222944E+22 ) + ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-174"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.223714E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-175"
  --assertf32~= as float32!  9.99999E-7  (( as float32!  9.99999E-7 ) + ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-176"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  9.99999E-7  f32-k  as float32!  1E-6 
  --test-- "float-auto-177"
  --assertf32~= as float32!  2147483.000001  (( as float32!  9.99999E-7 ) + ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-178"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  2147483.000001  f32-k  as float32!  1E-6 
  --test-- "float-auto-179"
  --assertf32~= as float32!  3.000000999999  (( as float32!  9.99999E-7 ) + ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-180"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  3.000000999999  f32-k  as float32!  1E-6 
  --test-- "float-auto-181"
  --assertf32~= as float32!  5.000000999999  (( as float32!  9.99999E-7 ) + ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-182"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  5.000000999999  f32-k  as float32!  1E-6 
  --test-- "float-auto-183"
  --assertf32~= as float32!  456.789000999999  (( as float32!  9.99999E-7 ) + ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-184"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  456.789000999999  f32-k  as float32!  1E-6 
  --test-- "float-auto-185"
  --assertf32~= as float32!  123456.700001  (( as float32!  9.99999E-7 ) + ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-186"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  123456.700001  f32-k  as float32!  1E-6 
  --test-- "float-auto-187"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  9.99999E-7 ) + ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-188"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-189"
  --assertf32~= as float32!  1.999998E-6  (( as float32!  9.99999E-7 ) + ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-190"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.999998E-6  f32-k  as float32!  1E-6 
  --test-- "float-auto-191"
  --assertf32~= as float32!  7.7E+18  (( as float32!  9.99999E-7 ) + ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-192"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-193"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) + ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-194"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-195"
  --assertf32~= as float32!  7.69999999999785E+18  (( as float32!  7.7E+18 ) + ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-196"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! -2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.69999999999785E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-197"
  --assertf32~= as float32!  7.70000000000215E+18  (( as float32!  7.7E+18 ) + ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-198"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.70000000000215E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-199"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) + ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-200"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-201"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) + ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-202"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-203"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) + ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-204"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! -7.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-205"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) + ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-206"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-207"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) + ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-208"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-209"
  --assertf32~= as float32!  7.70000000000012E+18  (( as float32!  7.7E+18 ) + ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-210"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.70000000000012E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-211"
  --assertf32~= as float32!  1.223714E+22  (( as float32!  7.7E+18 ) + ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-212"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.223714E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-213"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) + ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-214"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-215"
  --assertf32~= as float32!  1.54E+19  (( as float32!  7.7E+18 ) + ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-216"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
  --assertf32~= as float32!  1.54E+19  f32-k  as float32!  1E-6 
  --test-- "float-auto-217"
  --assertf32~= as float32!  2147483.0  (( as float32!  0.0 ) - ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-218"
      f32-i: as float32! 0.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-219"
  --assertf32~= as float32!  1.0  (( as float32!  0.0 ) - ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-220"
      f32-i: as float32! 0.0
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-221"
  --assertf32~= as float32!  7.0  (( as float32!  0.0 ) - ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-222"
      f32-i: as float32! 0.0
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  7.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-223"
  --assertf32~= as float32!  2147483.0  (( as float32!  2147483.0 ) - ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-224"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-225"
  --assertf32~= as float32!  4294966.0  (( as float32!  2147483.0 ) - ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-226"
      f32-i: as float32! 2147483.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  4294966.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-227"
  --assertf32~= as float32!  2147484.0  (( as float32!  2147483.0 ) - ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-228"
      f32-i: as float32! 2147483.0
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147484.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-229"
  --assertf32~= as float32!  2147480.0  (( as float32!  2147483.0 ) - ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-230"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 3.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147480.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-231"
  --assertf32~= as float32!  2147490.0  (( as float32!  2147483.0 ) - ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-232"
      f32-i: as float32! 2147483.0
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147490.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-233"
  --assertf32~= as float32!  2147478.0  (( as float32!  2147483.0 ) - ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-234"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 5.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147478.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-235"
  --assertf32~= as float32!  2147026.211  (( as float32!  2147483.0 ) - ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-236"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 456.789
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147026.211  f32-k  as float32!  1E-6 
  --test-- "float-auto-237"
  --assertf32~= as float32!  2024026.3  (( as float32!  2147483.0 ) - ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-238"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2024026.3  f32-k  as float32!  1E-6 
  --test-- "float-auto-239"
  --assertf32~= as float32!  2147482.999999  (( as float32!  2147483.0 ) - ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-240"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147482.999999  f32-k  as float32!  1E-6 
  --test-- "float-auto-241"
  --assertf32~= as float32!  2147482.0  (( as float32!  -1.0 ) - ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-242"
      f32-i: as float32! -1.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147482.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-243"
  --assertf32~= as float32!  6.0  (( as float32!  -1.0 ) - ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-244"
      f32-i: as float32! -1.0
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  6.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-245"
  --assertf32~= as float32!  3.0  (( as float32!  3.0 ) - ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-246"
      f32-i: as float32! 3.0
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  3.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-247"
  --assertf32~= as float32!  2147486.0  (( as float32!  3.0 ) - ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-248"
      f32-i: as float32! 3.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147486.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-249"
  --assertf32~= as float32!  4.0  (( as float32!  3.0 ) - ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-250"
      f32-i: as float32! 3.0
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  4.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-251"
  --assertf32~= as float32!  10.0  (( as float32!  3.0 ) - ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-252"
      f32-i: as float32! 3.0
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  10.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-253"
  --assertf32~= as float32!  2.999999000001  (( as float32!  3.0 ) - ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-254"
      f32-i: as float32! 3.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2.999999000001  f32-k  as float32!  1E-6 
  --test-- "float-auto-255"
  --assertf32~= as float32!  2147476.0  (( as float32!  -7.0 ) - ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-256"
      f32-i: as float32! -7.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147476.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-257"
  --assertf32~= as float32!  5.0  (( as float32!  5.0 ) - ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-258"
      f32-i: as float32! 5.0
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  5.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-259"
  --assertf32~= as float32!  2147488.0  (( as float32!  5.0 ) - ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-260"
      f32-i: as float32! 5.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147488.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-261"
  --assertf32~= as float32!  6.0  (( as float32!  5.0 ) - ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-262"
      f32-i: as float32! 5.0
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  6.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-263"
  --assertf32~= as float32!  2.0  (( as float32!  5.0 ) - ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-264"
      f32-i: as float32! 5.0
      f32-j: as float32! 3.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-265"
  --assertf32~= as float32!  12.0  (( as float32!  5.0 ) - ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-266"
      f32-i: as float32! 5.0
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  12.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-267"
  --assertf32~= as float32!  4.999999000001  (( as float32!  5.0 ) - ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-268"
      f32-i: as float32! 5.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  4.999999000001  f32-k  as float32!  1E-6 
  --test-- "float-auto-269"
  --assertf32~= as float32!  456.789  (( as float32!  456.789 ) - ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-270"
      f32-i: as float32! 456.789
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  456.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-271"
  --assertf32~= as float32!  2147939.789  (( as float32!  456.789 ) - ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-272"
      f32-i: as float32! 456.789
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147939.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-273"
  --assertf32~= as float32!  457.789  (( as float32!  456.789 ) - ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-274"
      f32-i: as float32! 456.789
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  457.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-275"
  --assertf32~= as float32!  453.789  (( as float32!  456.789 ) - ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-276"
      f32-i: as float32! 456.789
      f32-j: as float32! 3.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  453.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-277"
  --assertf32~= as float32!  463.789  (( as float32!  456.789 ) - ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-278"
      f32-i: as float32! 456.789
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  463.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-279"
  --assertf32~= as float32!  451.789  (( as float32!  456.789 ) - ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-280"
      f32-i: as float32! 456.789
      f32-j: as float32! 5.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  451.789  f32-k  as float32!  1E-6 
  --test-- "float-auto-281"
  --assertf32~= as float32!  456.788999000001  (( as float32!  456.789 ) - ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-282"
      f32-i: as float32! 456.789
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  456.788999000001  f32-k  as float32!  1E-6 
  --test-- "float-auto-283"
  --assertf32~= as float32!  123456.7  (( as float32!  123456.7 ) - ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-284"
      f32-i: as float32! 123456.7
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  123456.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-285"
  --assertf32~= as float32!  2270939.7  (( as float32!  123456.7 ) - ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-286"
      f32-i: as float32! 123456.7
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2270939.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-287"
  --assertf32~= as float32!  123457.7  (( as float32!  123456.7 ) - ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-288"
      f32-i: as float32! 123456.7
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  123457.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-289"
  --assertf32~= as float32!  123453.7  (( as float32!  123456.7 ) - ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-290"
      f32-i: as float32! 123456.7
      f32-j: as float32! 3.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  123453.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-291"
  --assertf32~= as float32!  123463.7  (( as float32!  123456.7 ) - ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-292"
      f32-i: as float32! 123456.7
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  123463.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-293"
  --assertf32~= as float32!  123451.7  (( as float32!  123456.7 ) - ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-294"
      f32-i: as float32! 123456.7
      f32-j: as float32! 5.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  123451.7  f32-k  as float32!  1E-6 
  --test-- "float-auto-295"
  --assertf32~= as float32!  122999.911  (( as float32!  123456.7 ) - ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-296"
      f32-i: as float32! 123456.7
      f32-j: as float32! 456.789
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  122999.911  f32-k  as float32!  1E-6 
  --test-- "float-auto-297"
  --assertf32~= as float32!  123456.699999  (( as float32!  123456.7 ) - ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-298"
      f32-i: as float32! 123456.7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  123456.699999  f32-k  as float32!  1E-6 
  --test-- "float-auto-299"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) - ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-300"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-301"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) - ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-302"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-303"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) - ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-304"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-305"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) - ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-306"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-307"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) - ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-308"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 3.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-309"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) - ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-310"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-311"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) - ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-312"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 5.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-313"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) - ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-314"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 456.789
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-315"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) - ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-316"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 123456.7
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-317"
  --assertf32~= as float32!  1.222944E+22  (( as float32!  1.222944E+22 ) - ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-318"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-319"
  --assertf32~= as float32!  1.222174E+22  (( as float32!  1.222944E+22 ) - ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-320"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.222174E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-321"
  --assertf32~= as float32!  9.99999E-7  (( as float32!  9.99999E-7 ) - ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-322"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  9.99999E-7  f32-k  as float32!  1E-6 
  --test-- "float-auto-323"
  --assertf32~= as float32!  2147483.000001  (( as float32!  9.99999E-7 ) - ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-324"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  2147483.000001  f32-k  as float32!  1E-6 
  --test-- "float-auto-325"
  --assertf32~= as float32!  1.000000999999  (( as float32!  9.99999E-7 ) - ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-326"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  1.000000999999  f32-k  as float32!  1E-6 
  --test-- "float-auto-327"
  --assertf32~= as float32!  7.000000999999  (( as float32!  9.99999E-7 ) - ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-328"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  7.000000999999  f32-k  as float32!  1E-6 
  --test-- "float-auto-329"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) - ( as float32!  0.0 ) )  as float32!  1E-6 
  --test-- "float-auto-330"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-331"
  --assertf32~= as float32!  7.70000000000215E+18  (( as float32!  7.7E+18 ) - ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-332"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  7.70000000000215E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-333"
  --assertf32~= as float32!  7.69999999999785E+18  (( as float32!  7.7E+18 ) - ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-334"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 2147483.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  7.69999999999785E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-335"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) - ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-336"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-337"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) - ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-338"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 3.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-339"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) - ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-340"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-341"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) - ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-342"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 5.0
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-343"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) - ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-344"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 456.789
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-345"
  --assertf32~= as float32!  7.69999999999988E+18  (( as float32!  7.7E+18 ) - ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-346"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 123456.7
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  7.69999999999988E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-347"
  --assertf32~= as float32!  7.7E+18  (( as float32!  7.7E+18 ) - ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-348"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
  --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-349"
  --assertf32~= as float32!  4611683235289.0  (( as float32!  -2147483.0 ) * ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-350"
      f32-i: as float32! -2147483.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  4611683235289.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-351"
  --assertf32~= as float32!  2147483.0  (( as float32!  -2147483.0 ) * ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-352"
      f32-i: as float32! -2147483.0
      f32-j: as float32! -1.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-353"
  --assertf32~= as float32!  15032381.0  (( as float32!  -2147483.0 ) * ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-354"
      f32-i: as float32! -2147483.0
      f32-j: as float32! -7.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  15032381.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-355"
  --assertf32~= as float32!  4611683235289.0  (( as float32!  2147483.0 ) * ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-356"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  4611683235289.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-357"
  --assertf32~= as float32!  6442449.0  (( as float32!  2147483.0 ) * ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-358"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  6442449.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-359"
  --assertf32~= as float32!  10737415.0  (( as float32!  2147483.0 ) * ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-360"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  10737415.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-361"
  --assertf32~= as float32!  980946612.087  (( as float32!  2147483.0 ) * ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-362"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  980946612.087  f32-k  as float32!  1E-6 
  --test-- "float-auto-363"
  --assertf32~= as float32!  265121164486.1  (( as float32!  2147483.0 ) * ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-364"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  265121164486.1  f32-k  as float32!  1E-6 
  --test-- "float-auto-365"
  --assertf32~= as float32!  2.626251449952E+28  (( as float32!  2147483.0 ) * ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-366"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  2.626251449952E+28  f32-k  as float32!  1E-6 
  --test-- "float-auto-367"
  --assertf32~= as float32!  2.147480852517  (( as float32!  2147483.0 ) * ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-368"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  2.147480852517  f32-k  as float32!  1E-6 
  --test-- "float-auto-369"
  --assertf32~= as float32!  1.65356191E+25  (( as float32!  2147483.0 ) * ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-370"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  1.65356191E+25  f32-k  as float32!  1E-6 
  --test-- "float-auto-371"
  --assertf32~= as float32!  2147483.0  (( as float32!  -1.0 ) * ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-372"
      f32-i: as float32! -1.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-373"
  --assertf32~= as float32!  1.0  (( as float32!  -1.0 ) * ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-374"
      f32-i: as float32! -1.0
      f32-j: as float32! -1.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-375"
  --assertf32~= as float32!  7.0  (( as float32!  -1.0 ) * ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-376"
      f32-i: as float32! -1.0
      f32-j: as float32! -7.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  7.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-377"
  --assertf32~= as float32!  6442449.0  (( as float32!  3.0 ) * ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-378"
      f32-i: as float32! 3.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  6442449.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-379"
  --assertf32~= as float32!  9.0  (( as float32!  3.0 ) * ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-380"
      f32-i: as float32! 3.0
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  9.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-381"
  --assertf32~= as float32!  15.0  (( as float32!  3.0 ) * ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-382"
      f32-i: as float32! 3.0
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  15.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-383"
  --assertf32~= as float32!  1370.367  (( as float32!  3.0 ) * ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-384"
      f32-i: as float32! 3.0
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  1370.367  f32-k  as float32!  1E-6 
  --test-- "float-auto-385"
  --assertf32~= as float32!  370370.1  (( as float32!  3.0 ) * ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-386"
      f32-i: as float32! 3.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  370370.1  f32-k  as float32!  1E-6 
  --test-- "float-auto-387"
  --assertf32~= as float32!  3.668832E+22  (( as float32!  3.0 ) * ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-388"
      f32-i: as float32! 3.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  3.668832E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-389"
  --assertf32~= as float32!  2.999997E-6  (( as float32!  3.0 ) * ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-390"
      f32-i: as float32! 3.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  2.999997E-6  f32-k  as float32!  1E-6 
  --test-- "float-auto-391"
  --assertf32~= as float32!  2.31E+19  (( as float32!  3.0 ) * ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-392"
      f32-i: as float32! 3.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  2.31E+19  f32-k  as float32!  1E-6 
  --test-- "float-auto-393"
  --assertf32~= as float32!  15032381.0  (( as float32!  -7.0 ) * ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-394"
      f32-i: as float32! -7.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  15032381.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-395"
  --assertf32~= as float32!  7.0  (( as float32!  -7.0 ) * ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-396"
      f32-i: as float32! -7.0
      f32-j: as float32! -1.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  7.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-397"
  --assertf32~= as float32!  49.0  (( as float32!  -7.0 ) * ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-398"
      f32-i: as float32! -7.0
      f32-j: as float32! -7.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  49.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-399"
  --assertf32~= as float32!  10737415.0  (( as float32!  5.0 ) * ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-400"
      f32-i: as float32! 5.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  10737415.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-401"
  --assertf32~= as float32!  15.0  (( as float32!  5.0 ) * ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-402"
      f32-i: as float32! 5.0
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  15.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-403"
  --assertf32~= as float32!  25.0  (( as float32!  5.0 ) * ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-404"
      f32-i: as float32! 5.0
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  25.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-405"
  --assertf32~= as float32!  2283.945  (( as float32!  5.0 ) * ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-406"
      f32-i: as float32! 5.0
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  2283.945  f32-k  as float32!  1E-6 
  --test-- "float-auto-407"
  --assertf32~= as float32!  617283.5  (( as float32!  5.0 ) * ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-408"
      f32-i: as float32! 5.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  617283.5  f32-k  as float32!  1E-6 
  --test-- "float-auto-409"
  --assertf32~= as float32!  6.11472E+22  (( as float32!  5.0 ) * ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-410"
      f32-i: as float32! 5.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  6.11472E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-411"
  --assertf32~= as float32!  4.999995E-6  (( as float32!  5.0 ) * ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-412"
      f32-i: as float32! 5.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  4.999995E-6  f32-k  as float32!  1E-6 
  --test-- "float-auto-413"
  --assertf32~= as float32!  3.85E+19  (( as float32!  5.0 ) * ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-414"
      f32-i: as float32! 5.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  3.85E+19  f32-k  as float32!  1E-6 
  --test-- "float-auto-415"
  --assertf32~= as float32!  980946612.087  (( as float32!  456.789 ) * ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-416"
      f32-i: as float32! 456.789
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  980946612.087  f32-k  as float32!  1E-6 
  --test-- "float-auto-417"
  --assertf32~= as float32!  1370.367  (( as float32!  456.789 ) * ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-418"
      f32-i: as float32! 456.789
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  1370.367  f32-k  as float32!  1E-6 
  --test-- "float-auto-419"
  --assertf32~= as float32!  2283.945  (( as float32!  456.789 ) * ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-420"
      f32-i: as float32! 456.789
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  2283.945  f32-k  as float32!  1E-6 
  --test-- "float-auto-421"
  --assertf32~= as float32!  208656.190521  (( as float32!  456.789 ) * ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-422"
      f32-i: as float32! 456.789
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  208656.190521  f32-k  as float32!  1E-6 
  --test-- "float-auto-423"
  --assertf32~= as float32!  56393662.5363  (( as float32!  456.789 ) * ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-424"
      f32-i: as float32! 456.789
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  56393662.5363  f32-k  as float32!  1E-6 
  --test-- "float-auto-425"
  --assertf32~= as float32!  5.58627366816E+24  (( as float32!  456.789 ) * ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-426"
      f32-i: as float32! 456.789
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  5.58627366816E+24  f32-k  as float32!  1E-6 
  --test-- "float-auto-427"
  --assertf32~= as float32!  4.56788543211E-4  (( as float32!  456.789 ) * ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-428"
      f32-i: as float32! 456.789
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  4.56788543211E-4  f32-k  as float32!  1E-6 
  --test-- "float-auto-429"
  --assertf32~= as float32!  3.5172753E+21  (( as float32!  456.789 ) * ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-430"
      f32-i: as float32! 456.789
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  3.5172753E+21  f32-k  as float32!  1E-6 
  --test-- "float-auto-431"
  --assertf32~= as float32!  265121164486.1  (( as float32!  123456.7 ) * ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-432"
      f32-i: as float32! 123456.7
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  265121164486.1  f32-k  as float32!  1E-6 
  --test-- "float-auto-433"
  --assertf32~= as float32!  370370.1  (( as float32!  123456.7 ) * ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-434"
      f32-i: as float32! 123456.7
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  370370.1  f32-k  as float32!  1E-6 
  --test-- "float-auto-435"
  --assertf32~= as float32!  617283.5  (( as float32!  123456.7 ) * ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-436"
      f32-i: as float32! 123456.7
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  617283.5  f32-k  as float32!  1E-6 
  --test-- "float-auto-437"
  --assertf32~= as float32!  56393662.5363  (( as float32!  123456.7 ) * ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-438"
      f32-i: as float32! 123456.7
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  56393662.5363  f32-k  as float32!  1E-6 
  --test-- "float-auto-439"
  --assertf32~= as float32!  15241556774.89  (( as float32!  123456.7 ) * ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-440"
      f32-i: as float32! 123456.7
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  15241556774.89  f32-k  as float32!  1E-6 
  --test-- "float-auto-441"
  --assertf32~= as float32!  1.509806305248E+27  (( as float32!  123456.7 ) * ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-442"
      f32-i: as float32! 123456.7
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  1.509806305248E+27  f32-k  as float32!  1E-6 
  --test-- "float-auto-443"
  --assertf32~= as float32!  0.1234565765433  (( as float32!  123456.7 ) * ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-444"
      f32-i: as float32! 123456.7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  0.1234565765433  f32-k  as float32!  1E-6 
  --test-- "float-auto-445"
  --assertf32~= as float32!  9.5061659E+23  (( as float32!  123456.7 ) * ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-446"
      f32-i: as float32! 123456.7
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  9.5061659E+23  f32-k  as float32!  1E-6 
  --test-- "float-auto-447"
  --assertf32~= as float32!  2.626251449952E+28  (( as float32!  1.222944E+22 ) * ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-448"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  2.626251449952E+28  f32-k  as float32!  1E-6 
  --test-- "float-auto-449"
  --assertf32~= as float32!  3.668832E+22  (( as float32!  1.222944E+22 ) * ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-450"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  3.668832E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-451"
  --assertf32~= as float32!  6.11472E+22  (( as float32!  1.222944E+22 ) * ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-452"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  6.11472E+22  f32-k  as float32!  1E-6 
  --test-- "float-auto-453"
  --assertf32~= as float32!  5.58627366816E+24  (( as float32!  1.222944E+22 ) * ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-454"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  5.58627366816E+24  f32-k  as float32!  1E-6 
  --test-- "float-auto-455"
  --assertf32~= as float32!  1.509806305248E+27  (( as float32!  1.222944E+22 ) * ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-456"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  1.509806305248E+27  f32-k  as float32!  1E-6 
  --test-- "float-auto-457"
  --assertf32~= as float32!  1.222942777056E+16  (( as float32!  1.222944E+22 ) * ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-458"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  1.222942777056E+16  f32-k  as float32!  1E-6 
  --test-- "float-auto-459"
  --assertf32~= as float32!  2.147480852517  (( as float32!  9.99999E-7 ) * ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-460"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  2.147480852517  f32-k  as float32!  1E-6 
  --test-- "float-auto-461"
  --assertf32~= as float32!  2.999997E-6  (( as float32!  9.99999E-7 ) * ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-462"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  2.999997E-6  f32-k  as float32!  1E-6 
  --test-- "float-auto-463"
  --assertf32~= as float32!  4.999995E-6  (( as float32!  9.99999E-7 ) * ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-464"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  4.999995E-6  f32-k  as float32!  1E-6 
  --test-- "float-auto-465"
  --assertf32~= as float32!  4.56788543211E-4  (( as float32!  9.99999E-7 ) * ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-466"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  4.56788543211E-4  f32-k  as float32!  1E-6 
  --test-- "float-auto-467"
  --assertf32~= as float32!  0.1234565765433  (( as float32!  9.99999E-7 ) * ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-468"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  0.1234565765433  f32-k  as float32!  1E-6 
  --test-- "float-auto-469"
  --assertf32~= as float32!  1.222942777056E+16  (( as float32!  9.99999E-7 ) * ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-470"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  1.222942777056E+16  f32-k  as float32!  1E-6 
  --test-- "float-auto-471"
  --assertf32~= as float32!  9.99998000001E-13  (( as float32!  9.99999E-7 ) * ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-472"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  9.99998000001E-13  f32-k  as float32!  1E-6 
  --test-- "float-auto-473"
  --assertf32~= as float32!  7699992300000.0  (( as float32!  9.99999E-7 ) * ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-474"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  7699992300000.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-475"
  --assertf32~= as float32!  1.65356191E+25  (( as float32!  7.7E+18 ) * ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-476"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  1.65356191E+25  f32-k  as float32!  1E-6 
  --test-- "float-auto-477"
  --assertf32~= as float32!  2.31E+19  (( as float32!  7.7E+18 ) * ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-478"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  2.31E+19  f32-k  as float32!  1E-6 
  --test-- "float-auto-479"
  --assertf32~= as float32!  3.85E+19  (( as float32!  7.7E+18 ) * ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-480"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  3.85E+19  f32-k  as float32!  1E-6 
  --test-- "float-auto-481"
  --assertf32~= as float32!  3.5172753E+21  (( as float32!  7.7E+18 ) * ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-482"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  3.5172753E+21  f32-k  as float32!  1E-6 
  --test-- "float-auto-483"
  --assertf32~= as float32!  9.5061659E+23  (( as float32!  7.7E+18 ) * ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-484"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  9.5061659E+23  f32-k  as float32!  1E-6 
  --test-- "float-auto-485"
  --assertf32~= as float32!  7699992300000.0  (( as float32!  7.7E+18 ) * ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-486"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  7699992300000.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-487"
  --assertf32~= as float32!  5.929E+37  (( as float32!  7.7E+18 ) * ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-488"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
  --assertf32~= as float32!  5.929E+37  f32-k  as float32!  1E-6 
  --test-- "float-auto-489"
  --assertf32~= as float32!  1.0  (( as float32!  -2147483.0 ) / ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-490"
      f32-i: as float32! -2147483.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-491"
  --assertf32~= as float32!  2147483.0  (( as float32!  -2147483.0 ) / ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-492"
      f32-i: as float32! -2147483.0
      f32-j: as float32! -1.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-493"
  --assertf32~= as float32!  306783.285714286  (( as float32!  -2147483.0 ) / ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-494"
      f32-i: as float32! -2147483.0
      f32-j: as float32! -7.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  306783.285714286  f32-k  as float32!  1E-6 
  --test-- "float-auto-495"
  --assertf32~= as float32!  1.0  (( as float32!  2147483.0 ) / ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-496"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-497"
  --assertf32~= as float32!  715827.666666667  (( as float32!  2147483.0 ) / ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-498"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  715827.666666667  f32-k  as float32!  1E-6 
  --test-- "float-auto-499"
  --assertf32~= as float32!  429496.6  (( as float32!  2147483.0 ) / ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-500"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  429496.6  f32-k  as float32!  1E-6 
  --test-- "float-auto-501"
  --assertf32~= as float32!  4701.25813012135  (( as float32!  2147483.0 ) / ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-502"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  4701.25813012135  f32-k  as float32!  1E-6 
  --test-- "float-auto-503"
  --assertf32~= as float32!  17.3946249980762  (( as float32!  2147483.0 ) / ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-504"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  17.3946249980762  f32-k  as float32!  1E-6 
  --test-- "float-auto-505"
  --assertf32~= as float32!  1.75599455085433E-16  (( as float32!  2147483.0 ) / ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-506"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.75599455085433E-16  f32-k  as float32!  1E-6 
  --test-- "float-auto-507"
  --assertf32~= as float32!  2147485147485.15  (( as float32!  2147483.0 ) / ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-508"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  2147485147485.15  f32-k  as float32!  1E-6 
  --test-- "float-auto-509"
  --assertf32~= as float32!  2.78893896103896E-13  (( as float32!  2147483.0 ) / ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-510"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  2.78893896103896E-13  f32-k  as float32!  1E-6 
  --test-- "float-auto-511"
  --assertf32~= as float32!  4.65661427820383E-7  (( as float32!  -1.0 ) / ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-512"
      f32-i: as float32! -1.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  4.65661427820383E-7  f32-k  as float32!  1E-6 
  --test-- "float-auto-513"
  --assertf32~= as float32!  1.0  (( as float32!  -1.0 ) / ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-514"
      f32-i: as float32! -1.0
      f32-j: as float32! -1.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-515"
  --assertf32~= as float32!  0.142857142857143  (( as float32!  -1.0 ) / ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-516"
      f32-i: as float32! -1.0
      f32-j: as float32! -7.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  0.142857142857143  f32-k  as float32!  1E-6 
  --test-- "float-auto-517"
  --assertf32~= as float32!  1.39698428346115E-6  (( as float32!  3.0 ) / ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-518"
      f32-i: as float32! 3.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.39698428346115E-6  f32-k  as float32!  1E-6 
  --test-- "float-auto-519"
  --assertf32~= as float32!  1.0  (( as float32!  3.0 ) / ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-520"
      f32-i: as float32! 3.0
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-521"
  --assertf32~= as float32!  0.6  (( as float32!  3.0 ) / ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-522"
      f32-i: as float32! 3.0
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  0.6  f32-k  as float32!  1E-6 
  --test-- "float-auto-523"
  --assertf32~= as float32!  6.56758372027347E-3  (( as float32!  3.0 ) / ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-524"
      f32-i: as float32! 3.0
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  6.56758372027347E-3  f32-k  as float32!  1E-6 
  --test-- "float-auto-525"
  --assertf32~= as float32!  2.4300017739013E-5  (( as float32!  3.0 ) / ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-526"
      f32-i: as float32! 3.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  2.4300017739013E-5  f32-k  as float32!  1E-6 
  --test-- "float-auto-527"
  --assertf32~= as float32!  2.45309678938692E-22  (( as float32!  3.0 ) / ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-528"
      f32-i: as float32! 3.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  2.45309678938692E-22  f32-k  as float32!  1E-6 
  --test-- "float-auto-529"
  --assertf32~= as float32!  3000003.000003  (( as float32!  3.0 ) / ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-530"
      f32-i: as float32! 3.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  3000003.000003  f32-k  as float32!  1E-6 
  --test-- "float-auto-531"
  --assertf32~= as float32!  3.8961038961039E-19  (( as float32!  3.0 ) / ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-532"
      f32-i: as float32! 3.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  3.8961038961039E-19  f32-k  as float32!  1E-6 
  --test-- "float-auto-533"
  --assertf32~= as float32!  3.25962999474268E-6  (( as float32!  -7.0 ) / ( as float32!  -2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-534"
      f32-i: as float32! -7.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  3.25962999474268E-6  f32-k  as float32!  1E-6 
  --test-- "float-auto-535"
  --assertf32~= as float32!  7.0  (( as float32!  -7.0 ) / ( as float32!  -1.0 ) )  as float32!  1E-6 
  --test-- "float-auto-536"
      f32-i: as float32! -7.0
      f32-j: as float32! -1.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  7.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-537"
  --assertf32~= as float32!  1.0  (( as float32!  -7.0 ) / ( as float32!  -7.0 ) )  as float32!  1E-6 
  --test-- "float-auto-538"
      f32-i: as float32! -7.0
      f32-j: as float32! -7.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-539"
  --assertf32~= as float32!  2.32830713910192E-6  (( as float32!  5.0 ) / ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-540"
      f32-i: as float32! 5.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  2.32830713910192E-6  f32-k  as float32!  1E-6 
  --test-- "float-auto-541"
  --assertf32~= as float32!  1.66666666666667  (( as float32!  5.0 ) / ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-542"
      f32-i: as float32! 5.0
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.66666666666667  f32-k  as float32!  1E-6 
  --test-- "float-auto-543"
  --assertf32~= as float32!  1.0  (( as float32!  5.0 ) / ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-544"
      f32-i: as float32! 5.0
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-545"
  --assertf32~= as float32!  1.09459728671225E-2  (( as float32!  5.0 ) / ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-546"
      f32-i: as float32! 5.0
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.09459728671225E-2  f32-k  as float32!  1E-6 
  --test-- "float-auto-547"
  --assertf32~= as float32!  4.05000295650216E-5  (( as float32!  5.0 ) / ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-548"
      f32-i: as float32! 5.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  4.05000295650216E-5  f32-k  as float32!  1E-6 
  --test-- "float-auto-549"
  --assertf32~= as float32!  4.0884946489782E-22  (( as float32!  5.0 ) / ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-550"
      f32-i: as float32! 5.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  4.0884946489782E-22  f32-k  as float32!  1E-6 
  --test-- "float-auto-551"
  --assertf32~= as float32!  5000005.000005  (( as float32!  5.0 ) / ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-552"
      f32-i: as float32! 5.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  5000005.000005  f32-k  as float32!  1E-6 
  --test-- "float-auto-553"
  --assertf32~= as float32!  6.49350649350649E-19  (( as float32!  5.0 ) / ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-554"
      f32-i: as float32! 5.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  6.49350649350649E-19  f32-k  as float32!  1E-6 
  --test-- "float-auto-555"
  --assertf32~= as float32!  2.12709017952645E-4  (( as float32!  456.789 ) / ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-556"
      f32-i: as float32! 456.789
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  2.12709017952645E-4  f32-k  as float32!  1E-6 
  --test-- "float-auto-557"
  --assertf32~= as float32!  152.263  (( as float32!  456.789 ) / ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-558"
      f32-i: as float32! 456.789
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  152.263  f32-k  as float32!  1E-6 
  --test-- "float-auto-559"
  --assertf32~= as float32!  91.3578  (( as float32!  456.789 ) / ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-560"
      f32-i: as float32! 456.789
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  91.3578  f32-k  as float32!  1E-6 
  --test-- "float-auto-561"
  --assertf32~= as float32!  1.0  (( as float32!  456.789 ) / ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-562"
      f32-i: as float32! 456.789
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-563"
  --assertf32~= as float32!  3.69999360099533E-3  (( as float32!  456.789 ) / ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-564"
      f32-i: as float32! 456.789
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  3.69999360099533E-3  f32-k  as float32!  1E-6 
  --test-- "float-auto-565"
  --assertf32~= as float32!  3.73515876442421E-20  (( as float32!  456.789 ) / ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-566"
      f32-i: as float32! 456.789
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  3.73515876442421E-20  f32-k  as float32!  1E-6 
  --test-- "float-auto-567"
  --assertf32~= as float32!  456789456.789457  (( as float32!  456.789 ) / ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-568"
      f32-i: as float32! 456.789
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  456789456.789457  f32-k  as float32!  1E-6 
  --test-- "float-auto-569"
  --assertf32~= as float32!  5.93232467532468E-17  (( as float32!  456.789 ) / ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-570"
      f32-i: as float32! 456.789
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  5.93232467532468E-17  f32-k  as float32!  1E-6 
  --test-- "float-auto-571"
  --assertf32~= as float32!  5.74890231959927E-2  (( as float32!  123456.7 ) / ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-572"
      f32-i: as float32! 123456.7
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  5.74890231959927E-2  f32-k  as float32!  1E-6 
  --test-- "float-auto-573"
  --assertf32~= as float32!  41152.2333333333  (( as float32!  123456.7 ) / ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-574"
      f32-i: as float32! 123456.7
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  41152.2333333333  f32-k  as float32!  1E-6 
  --test-- "float-auto-575"
  --assertf32~= as float32!  24691.34  (( as float32!  123456.7 ) / ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-576"
      f32-i: as float32! 123456.7
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  24691.34  f32-k  as float32!  1E-6 
  --test-- "float-auto-577"
  --assertf32~= as float32!  270.270737692895  (( as float32!  123456.7 ) / ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-578"
      f32-i: as float32! 123456.7
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  270.270737692895  f32-k  as float32!  1E-6 
  --test-- "float-auto-579"
  --assertf32~= as float32!  1.0  (( as float32!  123456.7 ) / ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-580"
      f32-i: as float32! 123456.7
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-581"
  --assertf32~= as float32!  1.00950411466101E-17  (( as float32!  123456.7 ) / ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-582"
      f32-i: as float32! 123456.7
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.00950411466101E-17  f32-k  as float32!  1E-6 
  --test-- "float-auto-583"
  --assertf32~= as float32!  123456823456.823  (( as float32!  123456.7 ) / ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-584"
      f32-i: as float32! 123456.7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  123456823456.823  f32-k  as float32!  1E-6 
  --test-- "float-auto-585"
  --assertf32~= as float32!  1.60333376623377E-14  (( as float32!  123456.7 ) / ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-586"
      f32-i: as float32! 123456.7
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.60333376623377E-14  f32-k  as float32!  1E-6 
  --test-- "float-auto-587"
  --assertf32~= as float32!  5.69477849184371E+15  (( as float32!  1.222944E+22 ) / ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-588"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  5.69477849184371E+15  f32-k  as float32!  1E-6 
  --test-- "float-auto-589"
  --assertf32~= as float32!  4.07648E+21  (( as float32!  1.222944E+22 ) / ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-590"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  4.07648E+21  f32-k  as float32!  1E-6 
  --test-- "float-auto-591"
  --assertf32~= as float32!  2.445888E+21  (( as float32!  1.222944E+22 ) / ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-592"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  2.445888E+21  f32-k  as float32!  1E-6 
  --test-- "float-auto-593"
  --assertf32~= as float32!  2.67726236840204E+19  (( as float32!  1.222944E+22 ) / ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-594"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  2.67726236840204E+19  f32-k  as float32!  1E-6 
  --test-- "float-auto-595"
  --assertf32~= as float32!  9.90585363127315E+16  (( as float32!  1.222944E+22 ) / ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-596"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  9.90585363127315E+16  f32-k  as float32!  1E-6 
  --test-- "float-auto-597"
  --assertf32~= as float32!  1.0  (( as float32!  1.222944E+22 ) / ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-598"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-599"
  --assertf32~= as float32!  1.22294522294522E+28  (( as float32!  1.222944E+22 ) / ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-600"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.22294522294522E+28  f32-k  as float32!  1E-6 
  --test-- "float-auto-601"
  --assertf32~= as float32!  1588.23896103896  (( as float32!  1.222944E+22 ) / ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-602"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1588.23896103896  f32-k  as float32!  1E-6 
  --test-- "float-auto-603"
  --assertf32~= as float32!  4.65660962158955E-13  (( as float32!  9.99999E-7 ) / ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-604"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  4.65660962158955E-13  f32-k  as float32!  1E-6 
  --test-- "float-auto-605"
  --assertf32~= as float32!  3.33333E-7  (( as float32!  9.99999E-7 ) / ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-606"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  3.33333E-7  f32-k  as float32!  1E-6 
  --test-- "float-auto-607"
  --assertf32~= as float32!  1.999998E-7  (( as float32!  9.99999E-7 ) / ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-608"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.999998E-7  f32-k  as float32!  1E-6 
  --test-- "float-auto-609"
  --assertf32~= as float32!  2.18919238422992E-9  (( as float32!  9.99999E-7 ) / ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-610"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  2.18919238422992E-9  f32-k  as float32!  1E-6 
  --test-- "float-auto-611"
  --assertf32~= as float32!  8.0999978129984E-12  (( as float32!  9.99999E-7 ) / ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-612"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  8.0999978129984E-12  f32-k  as float32!  1E-6 
  --test-- "float-auto-613"
  --assertf32~= as float32!  8.17698112096711E-29  (( as float32!  9.99999E-7 ) / ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-614"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  8.17698112096711E-29  f32-k  as float32!  1E-6 
  --test-- "float-auto-615"
  --assertf32~= as float32!  1.0  (( as float32!  9.99999E-7 ) / ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-616"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  --test-- "float-auto-617"
  --assertf32~= as float32!  1.2987E-25  (( as float32!  9.99999E-7 ) / ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-618"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.2987E-25  f32-k  as float32!  1E-6 
  --test-- "float-auto-619"
  --assertf32~= as float32!  3585592994216.95  (( as float32!  7.7E+18 ) / ( as float32!  2147483.0 ) )  as float32!  1E-6 
  --test-- "float-auto-620"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  3585592994216.95  f32-k  as float32!  1E-6 
  --test-- "float-auto-621"
  --assertf32~= as float32!  2.56666666666667E+18  (( as float32!  7.7E+18 ) / ( as float32!  3.0 ) )  as float32!  1E-6 
  --test-- "float-auto-622"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  2.56666666666667E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-623"
  --assertf32~= as float32!  1.54E+18  (( as float32!  7.7E+18 ) / ( as float32!  5.0 ) )  as float32!  1E-6 
  --test-- "float-auto-624"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.54E+18  f32-k  as float32!  1E-6 
  --test-- "float-auto-625"
  --assertf32~= as float32!  1.68567982153686E+16  (( as float32!  7.7E+18 ) / ( as float32!  456.789 ) )  as float32!  1E-6 
  --test-- "float-auto-626"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.68567982153686E+16  f32-k  as float32!  1E-6 
  --test-- "float-auto-627"
  --assertf32~= as float32!  62370045530133.2  (( as float32!  7.7E+18 ) / ( as float32!  123456.7 ) )  as float32!  1E-6 
  --test-- "float-auto-628"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  62370045530133.2  f32-k  as float32!  1E-6 
  --test-- "float-auto-629"
  --assertf32~= as float32!  6.29628175942643E-4  (( as float32!  7.7E+18 ) / ( as float32!  1.222944E+22 ) )  as float32!  1E-6 
  --test-- "float-auto-630"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  6.29628175942643E-4  f32-k  as float32!  1E-6 
  --test-- "float-auto-631"
  --assertf32~= as float32!  7.7000077000077E+24  (( as float32!  7.7E+18 ) / ( as float32!  9.99999E-7 ) )  as float32!  1E-6 
  --test-- "float-auto-632"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  7.7000077000077E+24  f32-k  as float32!  1E-6 
  --test-- "float-auto-633"
  --assertf32~= as float32!  1.0  (( as float32!  7.7E+18 ) / ( as float32!  7.7E+18 ) )  as float32!  1E-6 
  --test-- "float-auto-634"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
  --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 

float-auto-test-func: func [
	/local
		f32-i [float32!]
		f32-j [float32!]
		f32-k [float32!]
][
    --test-- "float-auto-635"
      f32-i: as float32! 0.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-636"
      f32-i: as float32! 0.0
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  3.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-637"
      f32-i: as float32! 0.0
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  5.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-638"
      f32-i: as float32! 0.0
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  456.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-639"
      f32-i: as float32! 0.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123456.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-640"
      f32-i: as float32! 0.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-641"
      f32-i: as float32! 0.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  9.99999E-7  f32-k  as float32!  1E-6 
    --test-- "float-auto-642"
      f32-i: as float32! 0.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-643"
      f32-i: as float32! -2147483.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-644"
      f32-i: as float32! -2147483.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.69999999999785E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-645"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-646"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  4294966.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-647"
      f32-i: as float32! 2147483.0
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147482.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-648"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147486.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-649"
      f32-i: as float32! 2147483.0
      f32-j: as float32! -7.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147476.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-650"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147488.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-651"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147939.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-652"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2270939.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-653"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-654"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147483.000001  f32-k  as float32!  1E-6 
    --test-- "float-auto-655"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.70000000000215E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-656"
      f32-i: as float32! -1.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147482.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-657"
      f32-i: as float32! -1.0
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-658"
      f32-i: as float32! -1.0
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  4.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-659"
      f32-i: as float32! -1.0
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  455.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-660"
      f32-i: as float32! -1.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123455.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-661"
      f32-i: as float32! -1.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-662"
      f32-i: as float32! -1.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-663"
      f32-i: as float32! 3.0
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  3.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-664"
      f32-i: as float32! 3.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147486.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-665"
      f32-i: as float32! 3.0
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-666"
      f32-i: as float32! 3.0
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  6.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-667"
      f32-i: as float32! 3.0
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  8.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-668"
      f32-i: as float32! 3.0
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  459.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-669"
      f32-i: as float32! 3.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123459.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-670"
      f32-i: as float32! 3.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-671"
      f32-i: as float32! 3.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  3.000000999999  f32-k  as float32!  1E-6 
    --test-- "float-auto-672"
      f32-i: as float32! 3.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-673"
      f32-i: as float32! -7.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147476.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-674"
      f32-i: as float32! -7.0
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  449.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-675"
      f32-i: as float32! -7.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123449.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-676"
      f32-i: as float32! -7.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-677"
      f32-i: as float32! -7.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-678"
      f32-i: as float32! 5.0
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  5.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-679"
      f32-i: as float32! 5.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147488.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-680"
      f32-i: as float32! 5.0
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  4.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-681"
      f32-i: as float32! 5.0
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  8.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-682"
      f32-i: as float32! 5.0
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  10.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-683"
      f32-i: as float32! 5.0
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  461.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-684"
      f32-i: as float32! 5.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123461.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-685"
      f32-i: as float32! 5.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-686"
      f32-i: as float32! 5.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  5.000000999999  f32-k  as float32!  1E-6 
    --test-- "float-auto-687"
      f32-i: as float32! 5.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-688"
      f32-i: as float32! 456.789
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  456.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-689"
      f32-i: as float32! 456.789
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147939.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-690"
      f32-i: as float32! 456.789
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  455.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-691"
      f32-i: as float32! 456.789
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  459.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-692"
      f32-i: as float32! 456.789
      f32-j: as float32! -7.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  449.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-693"
      f32-i: as float32! 456.789
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  461.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-694"
      f32-i: as float32! 456.789
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  913.578  f32-k  as float32!  1E-6 
    --test-- "float-auto-695"
      f32-i: as float32! 456.789
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123913.489  f32-k  as float32!  1E-6 
    --test-- "float-auto-696"
      f32-i: as float32! 456.789
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-697"
      f32-i: as float32! 456.789
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  456.789000999999  f32-k  as float32!  1E-6 
    --test-- "float-auto-698"
      f32-i: as float32! 456.789
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-699"
      f32-i: as float32! 123456.7
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123456.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-700"
      f32-i: as float32! 123456.7
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2270939.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-701"
      f32-i: as float32! 123456.7
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123455.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-702"
      f32-i: as float32! 123456.7
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123459.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-703"
      f32-i: as float32! 123456.7
      f32-j: as float32! -7.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123449.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-704"
      f32-i: as float32! 123456.7
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123461.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-705"
      f32-i: as float32! 123456.7
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123913.489  f32-k  as float32!  1E-6 
    --test-- "float-auto-706"
      f32-i: as float32! 123456.7
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  246913.4  f32-k  as float32!  1E-6 
    --test-- "float-auto-707"
      f32-i: as float32! 123456.7
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-708"
      f32-i: as float32! 123456.7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123456.700001  f32-k  as float32!  1E-6 
    --test-- "float-auto-709"
      f32-i: as float32! 123456.7
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.70000000000012E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-710"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-711"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! -2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-712"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-713"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-714"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-715"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! -7.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-716"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-717"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-718"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-719"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2.445888E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-720"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-721"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.223714E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-722"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  9.99999E-7  f32-k  as float32!  1E-6 
    --test-- "float-auto-723"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  2147483.000001  f32-k  as float32!  1E-6 
    --test-- "float-auto-724"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  3.000000999999  f32-k  as float32!  1E-6 
    --test-- "float-auto-725"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  5.000000999999  f32-k  as float32!  1E-6 
    --test-- "float-auto-726"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  456.789000999999  f32-k  as float32!  1E-6 
    --test-- "float-auto-727"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  123456.700001  f32-k  as float32!  1E-6 
    --test-- "float-auto-728"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-729"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.999998E-6  f32-k  as float32!  1E-6 
    --test-- "float-auto-730"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-731"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 0.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-732"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! -2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.69999999999785E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-733"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 2147483.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.70000000000215E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-734"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! -1.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-735"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 3.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-736"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! -7.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-737"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 5.0
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-738"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 456.789
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-739"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 123456.7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.70000000000012E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-740"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.223714E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-741"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-742"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i + f32-j
    --assertf32~= as float32!  1.54E+19  f32-k  as float32!  1E-6 
    --test-- "float-auto-743"
      f32-i: as float32! 0.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-744"
      f32-i: as float32! 0.0
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-745"
      f32-i: as float32! 0.0
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  7.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-746"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-747"
      f32-i: as float32! 2147483.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  4294966.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-748"
      f32-i: as float32! 2147483.0
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147484.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-749"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 3.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147480.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-750"
      f32-i: as float32! 2147483.0
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147490.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-751"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 5.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147478.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-752"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 456.789
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147026.211  f32-k  as float32!  1E-6 
    --test-- "float-auto-753"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2024026.3  f32-k  as float32!  1E-6 
    --test-- "float-auto-754"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147482.999999  f32-k  as float32!  1E-6 
    --test-- "float-auto-755"
      f32-i: as float32! -1.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147482.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-756"
      f32-i: as float32! -1.0
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  6.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-757"
      f32-i: as float32! 3.0
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  3.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-758"
      f32-i: as float32! 3.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147486.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-759"
      f32-i: as float32! 3.0
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  4.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-760"
      f32-i: as float32! 3.0
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  10.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-761"
      f32-i: as float32! 3.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2.999999000001  f32-k  as float32!  1E-6 
    --test-- "float-auto-762"
      f32-i: as float32! -7.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147476.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-763"
      f32-i: as float32! 5.0
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  5.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-764"
      f32-i: as float32! 5.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147488.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-765"
      f32-i: as float32! 5.0
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  6.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-766"
      f32-i: as float32! 5.0
      f32-j: as float32! 3.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-767"
      f32-i: as float32! 5.0
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  12.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-768"
      f32-i: as float32! 5.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  4.999999000001  f32-k  as float32!  1E-6 
    --test-- "float-auto-769"
      f32-i: as float32! 456.789
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  456.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-770"
      f32-i: as float32! 456.789
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147939.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-771"
      f32-i: as float32! 456.789
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  457.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-772"
      f32-i: as float32! 456.789
      f32-j: as float32! 3.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  453.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-773"
      f32-i: as float32! 456.789
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  463.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-774"
      f32-i: as float32! 456.789
      f32-j: as float32! 5.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  451.789  f32-k  as float32!  1E-6 
    --test-- "float-auto-775"
      f32-i: as float32! 456.789
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  456.788999000001  f32-k  as float32!  1E-6 
    --test-- "float-auto-776"
      f32-i: as float32! 123456.7
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  123456.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-777"
      f32-i: as float32! 123456.7
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2270939.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-778"
      f32-i: as float32! 123456.7
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  123457.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-779"
      f32-i: as float32! 123456.7
      f32-j: as float32! 3.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  123453.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-780"
      f32-i: as float32! 123456.7
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  123463.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-781"
      f32-i: as float32! 123456.7
      f32-j: as float32! 5.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  123451.7  f32-k  as float32!  1E-6 
    --test-- "float-auto-782"
      f32-i: as float32! 123456.7
      f32-j: as float32! 456.789
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  122999.911  f32-k  as float32!  1E-6 
    --test-- "float-auto-783"
      f32-i: as float32! 123456.7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  123456.699999  f32-k  as float32!  1E-6 
    --test-- "float-auto-784"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-785"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-786"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-787"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-788"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 3.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-789"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-790"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 5.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-791"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 456.789
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-792"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 123456.7
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-793"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.222944E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-794"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.222174E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-795"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  9.99999E-7  f32-k  as float32!  1E-6 
    --test-- "float-auto-796"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  2147483.000001  f32-k  as float32!  1E-6 
    --test-- "float-auto-797"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  1.000000999999  f32-k  as float32!  1E-6 
    --test-- "float-auto-798"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  7.000000999999  f32-k  as float32!  1E-6 
    --test-- "float-auto-799"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 0.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-800"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! -2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  7.70000000000215E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-801"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 2147483.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  7.69999999999785E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-802"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! -1.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-803"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 3.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-804"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! -7.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-805"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 5.0
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-806"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 456.789
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-807"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 123456.7
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  7.69999999999988E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-808"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i - f32-j
    --assertf32~= as float32!  7.7E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-809"
      f32-i: as float32! -2147483.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  4611683235289.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-810"
      f32-i: as float32! -2147483.0
      f32-j: as float32! -1.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-811"
      f32-i: as float32! -2147483.0
      f32-j: as float32! -7.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  15032381.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-812"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  4611683235289.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-813"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  6442449.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-814"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  10737415.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-815"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  980946612.087  f32-k  as float32!  1E-6 
    --test-- "float-auto-816"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  265121164486.1  f32-k  as float32!  1E-6 
    --test-- "float-auto-817"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  2.626251449952E+28  f32-k  as float32!  1E-6 
    --test-- "float-auto-818"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  2.147480852517  f32-k  as float32!  1E-6 
    --test-- "float-auto-819"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  1.65356191E+25  f32-k  as float32!  1E-6 
    --test-- "float-auto-820"
      f32-i: as float32! -1.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-821"
      f32-i: as float32! -1.0
      f32-j: as float32! -1.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-822"
      f32-i: as float32! -1.0
      f32-j: as float32! -7.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  7.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-823"
      f32-i: as float32! 3.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  6442449.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-824"
      f32-i: as float32! 3.0
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  9.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-825"
      f32-i: as float32! 3.0
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  15.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-826"
      f32-i: as float32! 3.0
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  1370.367  f32-k  as float32!  1E-6 
    --test-- "float-auto-827"
      f32-i: as float32! 3.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  370370.1  f32-k  as float32!  1E-6 
    --test-- "float-auto-828"
      f32-i: as float32! 3.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  3.668832E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-829"
      f32-i: as float32! 3.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  2.999997E-6  f32-k  as float32!  1E-6 
    --test-- "float-auto-830"
      f32-i: as float32! 3.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  2.31E+19  f32-k  as float32!  1E-6 
    --test-- "float-auto-831"
      f32-i: as float32! -7.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  15032381.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-832"
      f32-i: as float32! -7.0
      f32-j: as float32! -1.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  7.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-833"
      f32-i: as float32! -7.0
      f32-j: as float32! -7.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  49.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-834"
      f32-i: as float32! 5.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  10737415.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-835"
      f32-i: as float32! 5.0
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  15.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-836"
      f32-i: as float32! 5.0
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  25.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-837"
      f32-i: as float32! 5.0
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  2283.945  f32-k  as float32!  1E-6 
    --test-- "float-auto-838"
      f32-i: as float32! 5.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  617283.5  f32-k  as float32!  1E-6 
    --test-- "float-auto-839"
      f32-i: as float32! 5.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  6.11472E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-840"
      f32-i: as float32! 5.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  4.999995E-6  f32-k  as float32!  1E-6 
    --test-- "float-auto-841"
      f32-i: as float32! 5.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  3.85E+19  f32-k  as float32!  1E-6 
    --test-- "float-auto-842"
      f32-i: as float32! 456.789
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  980946612.087  f32-k  as float32!  1E-6 
    --test-- "float-auto-843"
      f32-i: as float32! 456.789
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  1370.367  f32-k  as float32!  1E-6 
    --test-- "float-auto-844"
      f32-i: as float32! 456.789
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  2283.945  f32-k  as float32!  1E-6 
    --test-- "float-auto-845"
      f32-i: as float32! 456.789
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  208656.190521  f32-k  as float32!  1E-6 
    --test-- "float-auto-846"
      f32-i: as float32! 456.789
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  56393662.5363  f32-k  as float32!  1E-6 
    --test-- "float-auto-847"
      f32-i: as float32! 456.789
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  5.58627366816E+24  f32-k  as float32!  1E-6 
    --test-- "float-auto-848"
      f32-i: as float32! 456.789
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  4.56788543211E-4  f32-k  as float32!  1E-6 
    --test-- "float-auto-849"
      f32-i: as float32! 456.789
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  3.5172753E+21  f32-k  as float32!  1E-6 
    --test-- "float-auto-850"
      f32-i: as float32! 123456.7
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  265121164486.1  f32-k  as float32!  1E-6 
    --test-- "float-auto-851"
      f32-i: as float32! 123456.7
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  370370.1  f32-k  as float32!  1E-6 
    --test-- "float-auto-852"
      f32-i: as float32! 123456.7
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  617283.5  f32-k  as float32!  1E-6 
    --test-- "float-auto-853"
      f32-i: as float32! 123456.7
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  56393662.5363  f32-k  as float32!  1E-6 
    --test-- "float-auto-854"
      f32-i: as float32! 123456.7
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  15241556774.89  f32-k  as float32!  1E-6 
    --test-- "float-auto-855"
      f32-i: as float32! 123456.7
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  1.509806305248E+27  f32-k  as float32!  1E-6 
    --test-- "float-auto-856"
      f32-i: as float32! 123456.7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  0.1234565765433  f32-k  as float32!  1E-6 
    --test-- "float-auto-857"
      f32-i: as float32! 123456.7
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  9.5061659E+23  f32-k  as float32!  1E-6 
    --test-- "float-auto-858"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  2.626251449952E+28  f32-k  as float32!  1E-6 
    --test-- "float-auto-859"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  3.668832E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-860"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  6.11472E+22  f32-k  as float32!  1E-6 
    --test-- "float-auto-861"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  5.58627366816E+24  f32-k  as float32!  1E-6 
    --test-- "float-auto-862"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  1.509806305248E+27  f32-k  as float32!  1E-6 
    --test-- "float-auto-863"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  1.222942777056E+16  f32-k  as float32!  1E-6 
    --test-- "float-auto-864"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  2.147480852517  f32-k  as float32!  1E-6 
    --test-- "float-auto-865"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  2.999997E-6  f32-k  as float32!  1E-6 
    --test-- "float-auto-866"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  4.999995E-6  f32-k  as float32!  1E-6 
    --test-- "float-auto-867"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  4.56788543211E-4  f32-k  as float32!  1E-6 
    --test-- "float-auto-868"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  0.1234565765433  f32-k  as float32!  1E-6 
    --test-- "float-auto-869"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  1.222942777056E+16  f32-k  as float32!  1E-6 
    --test-- "float-auto-870"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  9.99998000001E-13  f32-k  as float32!  1E-6 
    --test-- "float-auto-871"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  7699992300000.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-872"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 2147483.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  1.65356191E+25  f32-k  as float32!  1E-6 
    --test-- "float-auto-873"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 3.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  2.31E+19  f32-k  as float32!  1E-6 
    --test-- "float-auto-874"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 5.0
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  3.85E+19  f32-k  as float32!  1E-6 
    --test-- "float-auto-875"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 456.789
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  3.5172753E+21  f32-k  as float32!  1E-6 
    --test-- "float-auto-876"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 123456.7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  9.5061659E+23  f32-k  as float32!  1E-6 
    --test-- "float-auto-877"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  7699992300000.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-878"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i * f32-j
    --assertf32~= as float32!  5.929E+37  f32-k  as float32!  1E-6 
    --test-- "float-auto-879"
      f32-i: as float32! -2147483.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-880"
      f32-i: as float32! -2147483.0
      f32-j: as float32! -1.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  2147483.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-881"
      f32-i: as float32! -2147483.0
      f32-j: as float32! -7.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  306783.285714286  f32-k  as float32!  1E-6 
    --test-- "float-auto-882"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-883"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  715827.666666667  f32-k  as float32!  1E-6 
    --test-- "float-auto-884"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  429496.6  f32-k  as float32!  1E-6 
    --test-- "float-auto-885"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  4701.25813012135  f32-k  as float32!  1E-6 
    --test-- "float-auto-886"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  17.3946249980762  f32-k  as float32!  1E-6 
    --test-- "float-auto-887"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.75599455085433E-16  f32-k  as float32!  1E-6 
    --test-- "float-auto-888"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  2147485147485.15  f32-k  as float32!  1E-6 
    --test-- "float-auto-889"
      f32-i: as float32! 2147483.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  2.78893896103896E-13  f32-k  as float32!  1E-6 
    --test-- "float-auto-890"
      f32-i: as float32! -1.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  4.65661427820383E-7  f32-k  as float32!  1E-6 
    --test-- "float-auto-891"
      f32-i: as float32! -1.0
      f32-j: as float32! -1.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-892"
      f32-i: as float32! -1.0
      f32-j: as float32! -7.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  0.142857142857143  f32-k  as float32!  1E-6 
    --test-- "float-auto-893"
      f32-i: as float32! 3.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.39698428346115E-6  f32-k  as float32!  1E-6 
    --test-- "float-auto-894"
      f32-i: as float32! 3.0
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-895"
      f32-i: as float32! 3.0
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  0.6  f32-k  as float32!  1E-6 
    --test-- "float-auto-896"
      f32-i: as float32! 3.0
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  6.56758372027347E-3  f32-k  as float32!  1E-6 
    --test-- "float-auto-897"
      f32-i: as float32! 3.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  2.4300017739013E-5  f32-k  as float32!  1E-6 
    --test-- "float-auto-898"
      f32-i: as float32! 3.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  2.45309678938692E-22  f32-k  as float32!  1E-6 
    --test-- "float-auto-899"
      f32-i: as float32! 3.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  3000003.000003  f32-k  as float32!  1E-6 
    --test-- "float-auto-900"
      f32-i: as float32! 3.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  3.8961038961039E-19  f32-k  as float32!  1E-6 
    --test-- "float-auto-901"
      f32-i: as float32! -7.0
      f32-j: as float32! -2147483.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  3.25962999474268E-6  f32-k  as float32!  1E-6 
    --test-- "float-auto-902"
      f32-i: as float32! -7.0
      f32-j: as float32! -1.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  7.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-903"
      f32-i: as float32! -7.0
      f32-j: as float32! -7.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-904"
      f32-i: as float32! 5.0
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  2.32830713910192E-6  f32-k  as float32!  1E-6 
    --test-- "float-auto-905"
      f32-i: as float32! 5.0
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.66666666666667  f32-k  as float32!  1E-6 
    --test-- "float-auto-906"
      f32-i: as float32! 5.0
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-907"
      f32-i: as float32! 5.0
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.09459728671225E-2  f32-k  as float32!  1E-6 
    --test-- "float-auto-908"
      f32-i: as float32! 5.0
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  4.05000295650216E-5  f32-k  as float32!  1E-6 
    --test-- "float-auto-909"
      f32-i: as float32! 5.0
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  4.0884946489782E-22  f32-k  as float32!  1E-6 
    --test-- "float-auto-910"
      f32-i: as float32! 5.0
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  5000005.000005  f32-k  as float32!  1E-6 
    --test-- "float-auto-911"
      f32-i: as float32! 5.0
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  6.49350649350649E-19  f32-k  as float32!  1E-6 
    --test-- "float-auto-912"
      f32-i: as float32! 456.789
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  2.12709017952645E-4  f32-k  as float32!  1E-6 
    --test-- "float-auto-913"
      f32-i: as float32! 456.789
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  152.263  f32-k  as float32!  1E-6 
    --test-- "float-auto-914"
      f32-i: as float32! 456.789
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  91.3578  f32-k  as float32!  1E-6 
    --test-- "float-auto-915"
      f32-i: as float32! 456.789
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-916"
      f32-i: as float32! 456.789
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  3.69999360099533E-3  f32-k  as float32!  1E-6 
    --test-- "float-auto-917"
      f32-i: as float32! 456.789
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  3.73515876442421E-20  f32-k  as float32!  1E-6 
    --test-- "float-auto-918"
      f32-i: as float32! 456.789
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  456789456.789457  f32-k  as float32!  1E-6 
    --test-- "float-auto-919"
      f32-i: as float32! 456.789
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  5.93232467532468E-17  f32-k  as float32!  1E-6 
    --test-- "float-auto-920"
      f32-i: as float32! 123456.7
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  5.74890231959927E-2  f32-k  as float32!  1E-6 
    --test-- "float-auto-921"
      f32-i: as float32! 123456.7
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  41152.2333333333  f32-k  as float32!  1E-6 
    --test-- "float-auto-922"
      f32-i: as float32! 123456.7
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  24691.34  f32-k  as float32!  1E-6 
    --test-- "float-auto-923"
      f32-i: as float32! 123456.7
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  270.270737692895  f32-k  as float32!  1E-6 
    --test-- "float-auto-924"
      f32-i: as float32! 123456.7
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-925"
      f32-i: as float32! 123456.7
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.00950411466101E-17  f32-k  as float32!  1E-6 
    --test-- "float-auto-926"
      f32-i: as float32! 123456.7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  123456823456.823  f32-k  as float32!  1E-6 
    --test-- "float-auto-927"
      f32-i: as float32! 123456.7
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.60333376623377E-14  f32-k  as float32!  1E-6 
    --test-- "float-auto-928"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  5.69477849184371E+15  f32-k  as float32!  1E-6 
    --test-- "float-auto-929"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  4.07648E+21  f32-k  as float32!  1E-6 
    --test-- "float-auto-930"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  2.445888E+21  f32-k  as float32!  1E-6 
    --test-- "float-auto-931"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  2.67726236840204E+19  f32-k  as float32!  1E-6 
    --test-- "float-auto-932"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  9.90585363127315E+16  f32-k  as float32!  1E-6 
    --test-- "float-auto-933"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-934"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.22294522294522E+28  f32-k  as float32!  1E-6 
    --test-- "float-auto-935"
      f32-i: as float32! 1.222944E+22
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1588.23896103896  f32-k  as float32!  1E-6 
    --test-- "float-auto-936"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  4.65660962158955E-13  f32-k  as float32!  1E-6 
    --test-- "float-auto-937"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  3.33333E-7  f32-k  as float32!  1E-6 
    --test-- "float-auto-938"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.999998E-7  f32-k  as float32!  1E-6 
    --test-- "float-auto-939"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  2.18919238422992E-9  f32-k  as float32!  1E-6 
    --test-- "float-auto-940"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  8.0999978129984E-12  f32-k  as float32!  1E-6 
    --test-- "float-auto-941"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  8.17698112096711E-29  f32-k  as float32!  1E-6 
    --test-- "float-auto-942"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
    --test-- "float-auto-943"
      f32-i: as float32! 9.99999E-7
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.2987E-25  f32-k  as float32!  1E-6 
    --test-- "float-auto-944"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 2147483.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  3585592994216.95  f32-k  as float32!  1E-6 
    --test-- "float-auto-945"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 3.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  2.56666666666667E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-946"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 5.0
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.54E+18  f32-k  as float32!  1E-6 
    --test-- "float-auto-947"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 456.789
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.68567982153686E+16  f32-k  as float32!  1E-6 
    --test-- "float-auto-948"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 123456.7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  62370045530133.2  f32-k  as float32!  1E-6 
    --test-- "float-auto-949"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 1.222944E+22
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  6.29628175942643E-4  f32-k  as float32!  1E-6 
    --test-- "float-auto-950"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 9.99999E-7
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  7.7000077000077E+24  f32-k  as float32!  1E-6 
    --test-- "float-auto-951"
      f32-i: as float32! 7.7E+18
      f32-j: as float32! 7.7E+18
      f32-k:  f32-i / f32-j
    --assertf32~= as float32!  1.0  f32-k  as float32!  1E-6 
  ]
float-auto-test-func
  --test-- "float-auto-952"
  --assert true  = ( (as float32!  0.0 ) = (as float32!  0.0 ) )
  --test-- "float-auto-953"
  --assert false  = ( (as float32!  -2147483.0 ) = (as float32!  -2147485.147483 ) )
  --test-- "float-auto-954"
  --assert false  = ( (as float32!  2147483.0 ) = (as float32!  2147485.147483 ) )
  --test-- "float-auto-955"
  --assert false  = ( (as float32!  -1.0 ) = (as float32!  -1.000001 ) )
  --test-- "float-auto-956"
  --assert false  = ( (as float32!  3.0 ) = (as float32!  3.000003 ) )
  --test-- "float-auto-957"
  --assert false  = ( (as float32!  -7.0 ) = (as float32!  -7.000007 ) )
  --test-- "float-auto-958"
  --assert false  = ( (as float32!  5.0 ) = (as float32!  5.000005 ) )
  --test-- "float-auto-959"
  --assert false  = ( (as float32!  456.789 ) = (as float32!  456.789456789 ) )
  --test-- "float-auto-960"
  --assert false  = ( (as float32!  123456.7 ) = (as float32!  123456.8234567 ) )
  --test-- "float-auto-961"
  --assert false  = ( (as float32!  1.222944E+22 ) = (as float32!  1.222945222944E+22 ) )
  --test-- "float-auto-962"
  --assert false  = ( (as float32!  9.99999E-7 ) = (as float32!  9.99999999999E-7 ) )
  --test-- "float-auto-963"
  --assert false  = ( (as float32!  7.7E+18 ) = (as float32!  7.7000077E+18 ) )
  --test-- "float-auto-964"
  --assert false  = ( (as float32!  0.0 ) <> (as float32!  0.0 ) )
  --test-- "float-auto-965"
  --assert true  = ( (as float32!  -2147483.0 ) <> (as float32!  -2147485.147483 ) )
  --test-- "float-auto-966"
  --assert true  = ( (as float32!  2147483.0 ) <> (as float32!  2147485.147483 ) )
  --test-- "float-auto-967"
  --assert true  = ( (as float32!  -1.0 ) <> (as float32!  -1.000001 ) )
  --test-- "float-auto-968"
  --assert true  = ( (as float32!  3.0 ) <> (as float32!  3.000003 ) )
  --test-- "float-auto-969"
  --assert true  = ( (as float32!  -7.0 ) <> (as float32!  -7.000007 ) )
  --test-- "float-auto-970"
  --assert true  = ( (as float32!  5.0 ) <> (as float32!  5.000005 ) )
  --test-- "float-auto-971"
  --assert true  = ( (as float32!  456.789 ) <> (as float32!  456.789456789 ) )
  --test-- "float-auto-972"
  --assert true  = ( (as float32!  123456.7 ) <> (as float32!  123456.8234567 ) )
  --test-- "float-auto-973"
  --assert true  = ( (as float32!  1.222944E+22 ) <> (as float32!  1.222945222944E+22 ) )
  --test-- "float-auto-974"
  --assert true  = ( (as float32!  9.99999E-7 ) <> (as float32!  9.99999999999E-7 ) )
  --test-- "float-auto-975"
  --assert true  = ( (as float32!  7.7E+18 ) <> (as float32!  7.7000077E+18 ) )
  --test-- "float-auto-976"
  --assert false  = ( (as float32!  0.0 ) < (as float32!  0.0 ) )
  --test-- "float-auto-977"
  --assert false  = ( (as float32!  -2147483.0 ) < (as float32!  -2147485.147483 ) )
  --test-- "float-auto-978"
  --assert true  = ( (as float32!  2147483.0 ) < (as float32!  2147485.147483 ) )
  --test-- "float-auto-979"
  --assert false  = ( (as float32!  -1.0 ) < (as float32!  -1.000001 ) )
  --test-- "float-auto-980"
  --assert true  = ( (as float32!  3.0 ) < (as float32!  3.000003 ) )
  --test-- "float-auto-981"
  --assert false  = ( (as float32!  -7.0 ) < (as float32!  -7.000007 ) )
  --test-- "float-auto-982"
  --assert true  = ( (as float32!  5.0 ) < (as float32!  5.000005 ) )
  --test-- "float-auto-983"
  --assert true  = ( (as float32!  456.789 ) < (as float32!  456.789456789 ) )
  --test-- "float-auto-984"
  --assert true  = ( (as float32!  123456.7 ) < (as float32!  123456.8234567 ) )
  --test-- "float-auto-985"
  --assert true  = ( (as float32!  1.222944E+22 ) < (as float32!  1.222945222944E+22 ) )
  --test-- "float-auto-986"
  --assert true  = ( (as float32!  9.99999E-7 ) < (as float32!  9.99999999999E-7 ) )
  --test-- "float-auto-987"
  --assert true  = ( (as float32!  7.7E+18 ) < (as float32!  7.7000077E+18 ) )
  --test-- "float-auto-988"
  --assert false  = ( (as float32!  0.0 ) > (as float32!  0.0 ) )
  --test-- "float-auto-989"
  --assert true  = ( (as float32!  -2147483.0 ) > (as float32!  -2147485.147483 ) )
  --test-- "float-auto-990"
  --assert false  = ( (as float32!  2147483.0 ) > (as float32!  2147485.147483 ) )
  --test-- "float-auto-991"
  --assert true  = ( (as float32!  -1.0 ) > (as float32!  -1.000001 ) )
  --test-- "float-auto-992"
  --assert false  = ( (as float32!  3.0 ) > (as float32!  3.000003 ) )
  --test-- "float-auto-993"
  --assert true  = ( (as float32!  -7.0 ) > (as float32!  -7.000007 ) )
  --test-- "float-auto-994"
  --assert false  = ( (as float32!  5.0 ) > (as float32!  5.000005 ) )
  --test-- "float-auto-995"
  --assert false  = ( (as float32!  456.789 ) > (as float32!  456.789456789 ) )
  --test-- "float-auto-996"
  --assert false  = ( (as float32!  123456.7 ) > (as float32!  123456.8234567 ) )
  --test-- "float-auto-997"
  --assert false  = ( (as float32!  1.222944E+22 ) > (as float32!  1.222945222944E+22 ) )
  --test-- "float-auto-998"
  --assert false  = ( (as float32!  9.99999E-7 ) > (as float32!  9.99999999999E-7 ) )
  --test-- "float-auto-999"
  --assert false  = ( (as float32!  7.7E+18 ) > (as float32!  7.7000077E+18 ) )
  --test-- "float-auto-1000"
  --assert true  = ( (as float32!  0.0 ) >= (as float32!  0.0 ) )
  --test-- "float-auto-1001"
  --assert true  = ( (as float32!  -2147483.0 ) >= (as float32!  -2147485.147483 ) )
  --test-- "float-auto-1002"
  --assert false  = ( (as float32!  2147483.0 ) >= (as float32!  2147485.147483 ) )
  --test-- "float-auto-1003"
  --assert true  = ( (as float32!  -1.0 ) >= (as float32!  -1.000001 ) )
  --test-- "float-auto-1004"
  --assert false  = ( (as float32!  3.0 ) >= (as float32!  3.000003 ) )
  --test-- "float-auto-1005"
  --assert true  = ( (as float32!  -7.0 ) >= (as float32!  -7.000007 ) )
  --test-- "float-auto-1006"
  --assert false  = ( (as float32!  5.0 ) >= (as float32!  5.000005 ) )
  --test-- "float-auto-1007"
  --assert false  = ( (as float32!  456.789 ) >= (as float32!  456.789456789 ) )
  --test-- "float-auto-1008"
  --assert false  = ( (as float32!  123456.7 ) >= (as float32!  123456.8234567 ) )
  --test-- "float-auto-1009"
  --assert false  = ( (as float32!  1.222944E+22 ) >= (as float32!  1.222945222944E+22 ) )
  --test-- "float-auto-1010"
  --assert false  = ( (as float32!  9.99999E-7 ) >= (as float32!  9.99999999999E-7 ) )
  --test-- "float-auto-1011"
  --assert false  = ( (as float32!  7.7E+18 ) >= (as float32!  7.7000077E+18 ) )
  --test-- "float-auto-1012"
  --assert true  = ( (as float32!  0.0 ) <= (as float32!  0.0 ) )
  --test-- "float-auto-1013"
  --assert false  = ( (as float32!  -2147483.0 ) <= (as float32!  -2147485.147483 ) )
  --test-- "float-auto-1014"
  --assert true  = ( (as float32!  2147483.0 ) <= (as float32!  2147485.147483 ) )
  --test-- "float-auto-1015"
  --assert false  = ( (as float32!  -1.0 ) <= (as float32!  -1.000001 ) )
  --test-- "float-auto-1016"
  --assert true  = ( (as float32!  3.0 ) <= (as float32!  3.000003 ) )
  --test-- "float-auto-1017"
  --assert false  = ( (as float32!  -7.0 ) <= (as float32!  -7.000007 ) )
  --test-- "float-auto-1018"
  --assert true  = ( (as float32!  5.0 ) <= (as float32!  5.000005 ) )
  --test-- "float-auto-1019"
  --assert true  = ( (as float32!  456.789 ) <= (as float32!  456.789456789 ) )
  --test-- "float-auto-1020"
  --assert true  = ( (as float32!  123456.7 ) <= (as float32!  123456.8234567 ) )
  --test-- "float-auto-1021"
  --assert true  = ( (as float32!  1.222944E+22 ) <= (as float32!  1.222945222944E+22 ) )
  --test-- "float-auto-1022"
  --assert true  = ( (as float32!  9.99999E-7 ) <= (as float32!  9.99999999999E-7 ) )
  --test-- "float-auto-1023"
  --assert true  = ( (as float32!  7.7E+18 ) <= (as float32!  7.7000077E+18 ) )

===end-group===


~~~end-file~~~
