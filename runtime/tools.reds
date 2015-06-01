Red/System [
	Title:   "Red runtime helper functions"
	Author:  "Nenad Rakocevic"
	File: 	 %tools.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;-------------------------------------------
;-- Return an integer rounded to the nearest multiple of scale parameter
;-------------------------------------------
round-to: func [
	size 	[integer!]							;-- a memory region size
	scale	[integer!]							;-- scale parameter
	return: [integer!]							;-- nearest scale multiple
][
	assert scale <> 0
	(size - 1 + scale) and (negate scale)
]

;-------------------------------------------
;-- Return an integer rounded to the next nearest multiple of scale parameter
;-------------------------------------------
round-to-next: func [
	size 	[integer!]							;-- a memory region size
	scale	[integer!]							;-- scale parameter
	return: [integer!]							;-- nearest scale multiple
][
	assert scale <> 0
	(size + scale) and (negate scale)
]