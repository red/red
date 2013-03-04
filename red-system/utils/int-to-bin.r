REBOL [
	Title:   "Red/System integer! to binary! conversion library"
	Author:  "Nenad Rakocevic"
	File: 	 %int-to-bin.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]


int-to-bin: context [
	little-endian?: yes

	set 'to-bin func [v [integer!] size [integer!] /local bytes] [
		bytes: integer-to-bytes/width v size
		either little-endian? [reverse bytes] [bytes]
	]
	
	set 'to-bin8 func [v [integer!]] [
		to-bin v 1
	]

	set 'to-bin16 func [v [integer!]] [
		to-bin v 2
	]

	set 'to-bin32 func [v [integer!]] [
		to-bin v 4
	]
]