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

print [lf ">> allocating 3 series" lf]
s1: alloc-series 5
s2: alloc-series 100
s3: alloc-series 5

memory-stats 3

dump-series-frame memory/s-active

print [lf ">> freeing 2nd series" lf]
free-series memory/s-head s2
dump-series-frame memory/s-active

print [lf ">> compacting frame" lf]
compact-series-frame memory/s-active
dump-series-frame memory/s-active

memory-stats 3

free-all