Red/System [
	Title:   "Red/System OS-independent runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %common.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

#define zero? 		[0 =]
#define positive?	[0 < ]	;-- space required after the lesser-than symbol
#define negative?	[0 > ]

#define forever		[while [true]]
#define does		[func []]
