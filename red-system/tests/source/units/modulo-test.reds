Red/System [
	Title:   "Red/System modulo operator (//) test script"
	Author:  "Nenad Rakocevic"
	File: 	 %modulo-test.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/origin/BSD-3-License.txt"
]

#include %../../quick-test/quick-test.reds
~~~start-file~~~ "modulo"
  --test-- "mod-1" --assert  10 //  7 = 3
  --test-- "mod-2" --assert   5 //  3 = 2
  --test-- "mod-3" --assert  15 //  8 = 7
  --test-- "mod-4" --assert   2 //  2 = 0
  --test-- "mod-5" --assert -10 // -7 = -3
  --test-- "mod-6" --assert -10 //  7 = -3
  --test-- "mod-7" --assert  10 // -7 = 3
~~~end-file~~~

