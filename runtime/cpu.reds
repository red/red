Red/System [
	Title:	"Processor Util Functions"
	Author: "Xie Qingtian"
	File: 	%cpu.reds
	Tabs:	4
	Rights: "Copyright (C) 2017 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

cpu: context [
	
#either OS = 'Windows [
	yield: does [Sleep 1]
][
	#import [
		LIBC-file cdecl [
			sched_yield: "sched_yield" [
				return: [integer!]
			]
		]
	]

	yield: does [sched_yield]
]

]