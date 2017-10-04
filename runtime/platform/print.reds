Red/System [
	Title:	"Red Dynamic Print System"
	Author: "Qingtian Xie"
	File: 	%print.reds
	Tabs: 	4
	Rights: "Copyright (C) 2011-2017 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define MAX_RED_PRINTS	10

print-ctx: context [

	red-print!: alias function! [
		str		[red-string!]
		nl?		[logic!]
	]

	rs-print!: alias function! [
		str		[byte-ptr!]
		size	[integer!]
		unit	[integer!]
		nl?		[logic!]
	]

	print!: alias struct! [
		id			[integer!]
		red-print	[red-print!]
		rs-print	[rs-print!]
	]

	prints: as print! 0
	prints-cnt: 0

	init: does [
		prints: as print! allocate MAX_RED_PRINTS * size? print!
		#if sub-system = 'console [add as int-ptr! :red-print-cli null]
	]

	add: func [
		red-print	[int-ptr!]
		rs-print	[int-ptr!]
		return:		[integer!]
		/local
			p		[print!]
	][
		p: prints + prints-cnt
		p/id: prints-cnt
		p/red-print: as red-print! red-print
		p/rs-print: as rs-print! rs-print
		prints-cnt: prints-cnt + 1
		p/id
	]

	remove: func [
		id		[integer!]
	][
		
	]

	red-print: func [
		str		[red-string!]
		nl?		[logic!]
		/local
			p	[print!]
			idx [integer!]
	][
		idx: 0
		while [idx < prints-cnt][
			p: prints + idx
			p/red-print str nl?
			idx: idx + 1
		]
	]

	rs-print: func [
		str		[byte-ptr!]
		size	[integer!]
		unit	[integer!]
		nl?		[logic!]
		/local
			p	[print!]
			idx [integer!]
	][
		idx: 0
		while [idx < prints-cnt][
			p: prints + idx
			p/rs-print str size unit nl?
			idx: idx + 1
		]
	]

	#if sub-system = 'console [
	red-print-cli: func [
		str		[red-string!]
		lf?		[logic!]
		/local
			series	[series!]
			offset	[byte-ptr!]
			size	[integer!]
			unit	[integer!]
	][
		series: GET_BUFFER(str)
		unit: GET_UNIT(series)
		offset: (as byte-ptr! series/offset) + (str/head << (log-b unit))
		size: as-integer (as byte-ptr! series/tail) - offset

		either lf? [
			switch unit [
				Latin1 [platform/print-line-Latin1 as c-string! offset size]
				UCS-2  [platform/print-line-UCS2 				offset size]
				UCS-4  [platform/print-line-UCS4   as int-ptr!  offset size]

				default [									;@@ replace by an assertion
					print-line ["Error: unknown string encoding: " unit]
				]
			]
		][
			switch unit [
				Latin1 [platform/print-Latin1 as c-string! offset size]
				UCS-2  [platform/print-UCS2   			   offset size]
				UCS-4  [platform/print-UCS4   as int-ptr!  offset size]

				default [									;@@ replace by an assertion
					print-line ["Error: unknown string encoding: " unit]
				]
			]
			fflush 0
		]
	]]
]