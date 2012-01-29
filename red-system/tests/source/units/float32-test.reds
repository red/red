Red/System [
	Title:   "Red/System integer! datatype tests"
	Author:  "Peter W A Wood"
	File: 	 %float32-test.reds
	Version: 0.1.0
	Rights:  "Copyright (C) 2012 Peter W A Wood. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
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
    f: as float32! 9.99999E-45
  --assert f = as float32! 9.99999E-45
  --test-- "float32-4"
    f: as float32! 1.0
    f1: f
  --assert f1 = as float32! 1.0
===end-group===

===start-group=== "float argument to external function"

	#import [
		LIBM-file cdecl [
			sin32: "sin" [
				x 		[float!]
				return: [float32!]
			]
			cos32: "cos" [
				x 		[float!]
				return: [float32!]
			]
		]
	]
	pi32: 3.1415927
	
	--test-- "float-ext-1"
	--assert (as float32! -1.0) = cos32 pi32
	
	;--test-- "float-ext-2"
	;--assert  (as float32! 0.0) = sin32 pi32		; not working, because of rounding error.
	
	--test-- "float-ext-3"
	--assert (as float32! -1.0) = cos32 3.1415927
	
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
  --assert 1 = ff as float32! 1.222090944E+33 as float32! 9.99999E-45
  
===end-group===

===start-group=== "float32 locals"

	local-float: func [n [float32!] return: [float32!] /local p][p: n p]

	--test-- "float32-loc-1"
	pi64: 3.14159265358979
	pi: local-float as float32! 3.1415927
	--assert pi =  as float32! 3.1415927
	--assert (as float32! -1.0) = cos32 pi64
	--assert (as float32! -1.0) = local-float cos32 pi64
	
	--test-- "float32-loc-2"
	f: local-float pi
	--assert pi = local-float f

	--test-- "float32-loc-3"
	local-float2: func [n [float32!] return: [float32!] /local p][p: n local-float p]
	
	pi: local-float2 as float32! 3.1415927
	--assert (as float32! 3.1415927) = local-float2 pi
	--assert (as float32! -1.0) = local-float2 cos32 pi64
	f: local-float2 pi
	--assert pi = local-float2 f

	--test-- "float32-loc-4"
	local-float3: func [n [float32!] return: [float32!] /local p [float32!]][p: n local-float p]

	pi: local-float3 as float32! 3.1415927
	--assert (as float32! 3.1415927) = local-float3 pi
	--assert (as float32! -1.0) = local-float3 cos32 pi64
	f: local-float3 pi
	--assert pi = local-float3 f

	--test-- "float32-loc-5"
	local-float4: func [n [float32!] return: [float32!] /local r p][p: n p]
	--assert (as float32! 3.1415927) = local-float4 pi
	--assert (as float32! -1.0) = local-float4 cos32 pi64
	f: local-float4 pi
	--assert pi = local-float4 f
	
	--test-- "float32-loc-6"
	local-float5: func [n [float32!] return: [float32!] /local r p][p: n local-float p]
	--assert (as float32! 3.1415927) = local-float5 pi
	--assert (as float32! -1.0) = local-float5 cos32 pi64
	f: local-float5 pi
	--assert pi = local-float5 f

===end-group===

===start-group=== "float32 function return"

 
    ff1: func [
      ff1i      [integer!]
      return:   [float32!]
    ][
      as float32! switch ff1i [
        1 [1.0]
        2 [1.222090944E+33]
        3 [9.99999E-45]
      ]
    ]
  --test-- "float32 return 1"
  --assert (as float32! 1.0) = ff1 1
  --test-- "float32 return 2"
  --assert (as float32! 1.222090944E+33) = ff1 2
  --test-- "float32 return 3"
  --assert (as float32! 9.99999E-45) = ff1 3
  
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
    sf3/b: as float32! 9.99999E-45
    
  --assert (as float32! 1.222090944E+33) = sf3/a
  --assert (as float32! 9.99999E-45) = sf3/b
    
  --test-- "float32-struct-4"
    sf4: declare struct! [
      c   [byte!]
      a   [float32!]
      l   [logic!]
      b   [float32!]
    ]
    sf4/a: as float32! 1.222090944E+33
    sf4/b: as float32! 9.99999E-45
  --assert (as float32! 1.222090944E+33) = sf4/a
  --assert (as float32! 9.99999E-45) = sf4/b

===end-group===

===start-group=== "float32 pointers"

  --test-- "float32-point-1"
  pi: as float32! 3.1415927
  p: declare pointer! [float32!]
  p/value: as float32! 3.1415927
  --assert pi = p/value
 
 ;TBD: add more float pointer tests in %pointer-test.reds.

===end-group===

~~~end-file~~~
