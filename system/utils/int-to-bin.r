REBOL [
	Title:   "Red/System integer! to binary! conversion library"
	Author:  "Nenad Rakocevic"
	File: 	 %int-to-bin.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]


int-to-bin: context [
	little-endian?: yes
	
	set 'to-bin8 func [v [integer! char!]][
		to binary! to char! 256 + v and 255
	]

	set 'to-bin16 func [v [integer! char!]][			;TBD: add big-endian support
		reverse skip debase/base to-hex to integer! v 16 2
	]

	set 'to-bin32 func [v [integer! char!]][			;TBD: add big-endian support
		reverse debase/base to-hex to integer! v 16
	]
]