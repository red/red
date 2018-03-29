Red/System [
	Title:	"Red Dynamic Print System"
	Author: "Qingtian Xie"
	File: 	%print.reds
	Tabs: 	4
	Rights: "Copyright (C) 2017-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

dyn-print: context [

	red-print!: alias function! [
		str		[red-string!]
		nl?		[logic!]
	]

	rs-print!: alias function! [
		str		[c-string!]			;-- UTF-8 string
		size	[integer!]
		nl?		[logic!]
	]

	ptr-array!: alias struct! [
		ptr		[int-ptr!]
	]

	red-prints: as ptr-array! 0
	rs-prints: as ptr-array! 0
	red-cnt: 0
	rs-cnt: 0
	red-size: 5
	rs-size: 5

	#define CHECK_SIZE(prints size cnt) [
		if cnt = size [
			size: size + 5
			p: as ptr-array! allocate size * size? ptr-array!
			copy-memory as byte-ptr! p as byte-ptr! prints cnt * size? ptr-array!
			free as byte-ptr! prints
			prints: p
		]
	]

	;-- public APIs

	add: func [
		red-print	[int-ptr!]			;-- function pointer for Red print
		rs-print	[int-ptr!]			;-- function pointer for Red/System print
		/local
			p		[ptr-array!]
	][
		if red-print <> null [
			CHECK_SIZE(red-prints red-size red-cnt)
			p: red-prints + red-cnt
			p/ptr: red-print
			red-cnt: red-cnt + 1
		]
		if rs-print <> null [
			CHECK_SIZE(rs-prints rs-size rs-cnt)
			p: rs-prints + rs-cnt
			p/ptr: rs-print
			rs-cnt: rs-cnt + 1
		]
	]

	remove: func [
		red-print	[int-ptr!]			;-- function pointer for Red print
		rs-print	[int-ptr!]			;-- function pointer for Red/System print
	][
		remove-print red-print red-prints :red-cnt 
		remove-print rs-print rs-prints :rs-cnt 
	]

	red-print: func [
		str		[red-string!]
		nl?		[logic!]
		/local
			p	[ptr-array!]
			f	[red-print!]
	][
		p: red-prints
		loop red-cnt [
			f: as red-print! p/ptr
			f str nl?
			p: p + 1
		]
	]

	rs-print: func [
		str		[c-string!]
		size	[integer!]
		nl?		[logic!]
		/local
			p	[ptr-array!]
			ff	[rs-print!]
	][
		p: rs-prints
		loop rs-cnt [
			ff: as rs-print! p/ptr
			ff str size nl?
			p: p + 1
		]
	]

	;-- utils functions

	init: does [
		red-prints: as ptr-array! allocate red-size * size? ptr-array!
		rs-prints: as ptr-array! allocate rs-size * size? ptr-array!
		#if sub-system = 'console [add as int-ptr! :red-print-cli null]
	]

	remove-print: func [
		ptr			[int-ptr!]
		prints		[ptr-array!]
		cnt			[int-ptr!]
		/local
			n		[integer!]
			p		[ptr-array!]
			end		[ptr-array!]
	][
		if ptr <> null [
			n: cnt/value
			p: prints
			end: p + n
			loop n [
				if p/ptr = ptr [
					move-memory
						as byte-ptr! p
						as byte-ptr! (p + 1)
						as-integer end - p - 1
					cnt/value: n - 1
					break
				]
				p: p + 1
			]
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