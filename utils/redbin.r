REBOL [
	Title:   "Redbin format encoder for Red compiler"
	Author:  "Nenad Rakocevic"
	File: 	 %redbin.r
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

redbin: context [
	buffer: make binary! 100'000
	
	
	
	init: func [flags [block! none]][
		clear buffer
		append buffer "REDBIN"
	]
]