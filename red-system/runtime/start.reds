Red/System [
	Title:   "Red/System OS-independent runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %start.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#include %lib-names.reds

__stack!: alias struct! [
	top		[pointer! [integer!]]
	frame	[pointer! [integer!]]
]

system: declare struct! [							;-- trimmed down temporary system definition
	stack		[__stack!]							;-- stack virtual access
]

#switch OS [
	Linux [
		#import [LIBC-file cdecl [
			libc-start: "__libc_start_main" [
				main 			[function! []]
				argc 			[integer!]
				argv 			[pointer! [integer!]]
				init 			[function! []]
				finish 			[function! []]
				loader-finish 	[function! []]
				stack-end 		[pointer! [integer!]]
			]
		]]

		system/stack/frame: as pointer! [integer!] 0
		***__argc: pop
		***__argv: system/stack/top
		system/stack/top: as pointer! [integer!] (FFFFFFF0h and as integer! ***__argv)

		libc-start :***-start ***__argc ***__argv null null null ***__argv
	]
]
