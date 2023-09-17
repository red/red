Red/System [
	Title:	"Text Box Windows DirectWrite Backend"
	Author: "Xie Qingtian"
	File: 	%text-box.reds
	Tabs: 	4
	Dependency: %draw.reds
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define TBOX_METRICS_OFFSET?		0
#define TBOX_METRICS_INDEX?			1
#define TBOX_METRICS_LINE_HEIGHT	2
#define TBOX_METRICS_SIZE			3
#define TBOX_METRICS_LINE_COUNT		4
#define TBOX_METRICS_CHAR_INDEX?	5
#define TBOX_METRICS_OFFSET_LOWER	6

set-text-box-color: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
	fg?		[logic!]
	/local
		p		[pixel!]
		end		[pixel!]
		max-len [integer!]
][
	max-len: layout/value
	if pos + len > max-len [len: max-len - pos]
	p: (as pixel! layout) + 1
	p: p + pos
	end: p + len
	color: make-color-256 color
	either fg? [
		while [p < end][
			p/fg-color: color
			p: p + 1
		]
	][
		while [p < end][
			p/bg-color: color
			p: p + 1
		]
	]
]

OS-text-box-color: func [
	target	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
][
	set-text-box-color layout pos len color yes
]

OS-text-box-background: func [
	target	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	color	[integer!]
][
	set-text-box-color layout pos len color no
]

set-text-box-style: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	flag	[integer!]
	/local
		p		[pixel!]
		end		[pixel!]
		max-len [integer!]
][
	max-len: layout/value
	if pos + len > max-len [len: max-len - pos]
	p: (as pixel! layout) + 1
	p: p + pos
	end: p + len
	while [p < end][
		p/flags: p/flags or flag
		p: p + 1
	]
]

OS-text-box-weight: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	weight	[integer!]
][
	set-text-box-style layout pos len PIXEL_BOLD
]

OS-text-box-italic: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
][
	set-text-box-style layout pos len PIXEL_ITALIC
]

OS-text-box-underline: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
][
	set-text-box-style layout pos len PIXEL_UNDERLINE
]

OS-text-box-strikeout: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
][
	set-text-box-style layout pos len PIXEL_STRIKE
]

OS-text-box-border: func [
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	opts	[red-value!]					;-- options
	tail	[red-value!]
][
	0
]

OS-text-box-font-name: func [
	font	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	name	[red-string!]
][
]

OS-text-box-font-size: func [
	font	[handle!]
	layout	[handle!]
	pos		[integer!]
	len		[integer!]
	size	[float!]
][
]

OS-text-box-metrics: func [
	state	[red-block!]
	arg0	[red-value!]
	type	[integer!]
	return: [red-value!]
][
	null
]

OS-text-box-layout: func [
	box		[red-object!]
	target	[handle!]
	ft-clr	[integer!]
	catch?	[logic!]
	return: [handle!]
][
	null
]

adjust-index: func [
	str		[red-string!]
	offset	[integer!]
	idx		[integer!]
	adjust	[integer!]
	return: [integer!]
	/local
		s		[series!]
		unit	[integer!]
		head	[byte-ptr!]
		tail	[byte-ptr!]
		i		[integer!]
		c		[integer!]
][
	assert TYPE_OF(str) = TYPE_STRING
	s: GET_BUFFER(str)
	unit: GET_UNIT(s)
	if unit = UCS-4 [
		head: (as byte-ptr! s/offset) + (str/head + offset << 2)
		tail: head + (idx * 4)
		i: 0
		while [head < tail][
			c: string/get-char head unit
			if c >= 00010000h [
				idx: idx + adjust
				if adjust < 0 [tail: tail - unit]
			]
			head: head + unit
		]
	]
	idx
]