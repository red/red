Red/System [
	Title:   "Red memory allocator tests"
	Author:  "Nenad Rakocevic"
	File: 	 %allocator-tests.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]


#include %../runtime/runtime.reds

;-- add a minimal number of memory frames
alloc-node-frame nodes-per-frame
alloc-series-frame

s1: alloc-series 5
s2: alloc-series 100

memory-stats 2

dump-series-frame memory/s-head

free-all