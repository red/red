Red/System [
	Title:   "Red/System modulo operator (//) test script"
	Author:  "Nenad Rakocevic"
	File: 	 %modulo-test.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/origin/BSD-3-License.txt"
]

#include %../../../../quick-test/quick-test.reds
~~~start-file~~~ "modulo-remainder"

===start-group=== "math modulo"

  --test-- "mod-1" --assert  10 //  7 = 3
  --test-- "mod-2" --assert   5 //  3 = 2
  --test-- "mod-3" --assert  15 //  8 = 7
  --test-- "mod-4" --assert   2 //  2 = 0
  
  --test-- "mod-8"  --assert  9 //  4 = 1
  --test-- "mod-9"  --assert  9 // -4 = 1
  --test-- "mod-10" --assert -9 //  4 = 3
  --test-- "mod-11" --assert -9 // -4 = 3
  
  --test-- "mod-12" --assert #"^(09)" // #"^(04)" = #"^(01)"
  --test-- "mod-13" --assert #"^(09)" // #"^(FC)" = #"^(09)"
  --test-- "mod-14" --assert #"^(F7)" // #"^(04)" = #"^(03)"
  --test-- "mod-15" --assert #"^(F7)" // #"^(FC)" = #"^(F7)"

===end-group===

===start-group=== "remainder"

  --test-- "rem-1" --assert  9 %  4 =  1
  --test-- "rem-2" --assert  9 % -4 =  1
  --test-- "rem-3" --assert -9 %  4 = -1
  --test-- "rem-4" --assert -9 % -4 = -1
  
  --test-- "rem-5"  --assert #"^(09)" % #"^(04)" = #"^(01)"
  --test-- "rem-6"  --assert #"^(09)" % #"^(FC)" = #"^(09)"
  --test-- "rem-7"  --assert #"^(F7)" % #"^(04)" = #"^(03)"
  --test-- "rem-8" --assert #"^(F7)" % #"^(FC)" = #"^(F7)"
  
===end-group=== 

===start-group=== "float remainder"

  --test-- "fr-1" --assert  9.0  %  4.0  =  1.0
  --test-- "fr-2" --assert  9.0  % -4.0  =  1.0
  --test-- "fr-3" --assert -9.0  %  4.0  = -1.0
  --test-- "fr-4" --assert -9.0  % -4.0  = -1.0
  --test-- "fr-5" --assert  8.5  %  4.0  =  0.5

  --test-- "fr-6" --assertf~=  8.49 %  4.0    0.49	1E-6
  --test-- "fr-7" --assertf~=  9.0  %  3.9    1.2	1E-6
  --test-- "fr-8" --assertf~=  8.9  %  4.46   4.44	1E-6
  --test-- "fr-9" --assertf~=  8.9  %  4.25   0.4	1E-6

  --test-- "f32r-1" --assert (as-float32 9.0)  % (as-float32 4.0)  = as-float32 1.0
  --test-- "f32r-2" --assert (as-float32 9.0)  % (as-float32 -4.0) = as-float32 1.0
  --test-- "f32r-3" --assert (as-float32 -9.0) % (as-float32 4.0)  = as-float32 -1.0
  --test-- "f32r-4" --assert (as-float32 -9.0) % (as-float32 -4.0) = as-float32 -1.0
  --test-- "f32r-5" --assert (as-float32 8.5)  % (as-float32 4.0) = as-float32 0.5

  --test-- "f32r-6" --assertf32~= (as-float32 8.49) % (as-float32 4.0)  (as-float32  0.49) 1E-6
  --test-- "f32r-7" --assertf32~= (as-float32 9.0)  % (as-float32 3.9)  (as-float32  1.2)  1E-6
  --test-- "f32r-8" --assertf32~= (as-float32 8.9)  % (as-float32 4.46) (as-float32  4.44) 1E-6
  --test-- "f32r-9" --assertf32~= (as-float32 8.9)  % (as-float32 4.25) (as-float32  0.4)  1E-6

===end-group=== 

 
~~~end-file~~~

