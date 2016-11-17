Red [
	Title:   "LibRed API definition"
	Author:  "Nenad Rakocevic"
	File: 	 %libRed.red
	Tabs:	 4
	Config:	[type: 'dll]
	Rights:  "Copyright (C) 2016 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#system [

	redBoot: does [red/boot]
	
	redDo: func [
	
	][
	
	]
	
	redQuit: func [
		
	][
		
	]
	
	#export [redBoot "redBoot" redDo redQuit]
]