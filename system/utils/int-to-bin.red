Red [
	Title:   "Red/System integer! to binary! conversion library"
	Author:  "Nenad Rakocevic"
	File: 	 %int-to-bin.red
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]


int-to-bin: context [
	little-endian?: yes
	
	set 'to-bin8 func [v [integer! char!]][
		skip to binary! to integer! v 3
	]

	set 'to-bin16 func [v [integer! char!]][			;TBD: add big-endian support
		reverse skip to binary! to integer! v 2
	]

	set 'to-bin32 func [v [integer! char!]][			;TBD: add big-endian support
		reverse to binary! v
	]
]