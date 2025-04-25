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
	box		[red-object!]
	arg0	[red-value!]
	type	[integer!]
	return: [red-value!]
	/local
		values	[red-value!]
		str		[red-string!]
		sz		[red-pair!]
		pos		[red-pair!]
		int		[red-integer!]
		x y		[integer!]
		xx yy	[integer!]
		w h		[integer!]
		ww hh	[integer!]
		pt		[red-point2D!]
		cnt		[integer!]
		n		[integer!]
		series	[series!]
		unit	[integer!]
		offset	[byte-ptr!]
		tail	[byte-ptr!]
		cp idx	[integer!]
][
	values: get-node-facet box/ctx 0
	str: as red-string! values + FACE_OBJ_TEXT
	sz: as red-pair! values + FACE_OBJ_SIZE
	either ANY_COORD?(sz) [
		GET_PAIR_XY_INT(sz w h)
	][
		w: 7FFFFFFFh
		h: 7FFFFFFFh
	]
	as red-value! switch type [
		TBOX_METRICS_OFFSET?
		TBOX_METRICS_OFFSET_LOWER [
			int: as red-integer! arg0
			idx:	int/value
			x:		0
			y:		0
			cnt:	0
			series: GET_BUFFER(str)
			unit: 	GET_UNIT(series)
			offset: (as byte-ptr! series/offset) + (str/head << (log-b unit))
			tail:   as byte-ptr! series/tail
			while [all [cnt < idx offset < tail]][
				cp: string/get-char offset unit
				either cp = as-integer lf [
					y: y + 1
					x: 0
				][
					n: char-width? cp
					x: x + n
				]
				either x > w [	;-- wrap text
					y: y + 1
					x: x - n
					if x <= 0 [break]	;-- width is too small that cannot even contain 1 char
					x: 0
				][
					offset: offset + unit
					cnt: cnt + 1
				]
			]
			either type = TBOX_METRICS_OFFSET? [x: x - n][y: y + 1]
			point2D/push as float32! x as float32! y
		]
		TBOX_METRICS_INDEX?
		TBOX_METRICS_CHAR_INDEX? [
			pos: as red-pair! arg0
			GET_PAIR_XY_INT(pos x y)
			xx:		0
			yy:		0
			cnt:	1
			series: GET_BUFFER(str)
			unit: 	GET_UNIT(series)
			offset: (as byte-ptr! series/offset) + (str/head << (log-b unit))
			tail:   as byte-ptr! series/tail

			;-- skip y lines
			while [all [offset < tail yy < y]][
				cp: string/get-char offset unit
				if cp = as-integer lf [
					yy: yy + 1
					xx: 0
					offset: offset + unit
					cnt: cnt + 1
					continue
				]
				n: char-width? cp
				xx: xx + n
				offset: offset + unit
				cnt: cnt + 1
				if xx >= w [		;-- wrap text
					yy: yy + 1
					if xx > w [
						offset: offset - unit
					]
					xx: 0
				]
			]
			while [all [offset < tail xx < x]][
				cp: string/get-char offset unit
				if cp = as-integer lf [
					cnt: cnt + 1
					break
				]
				n: char-width? cp
				xx: xx + n
				offset: offset + unit
				cnt: cnt + 1
			]
			if all [
				type = TBOX_METRICS_CHAR_INDEX?
				xx <= x
				yy <= y
				offset = tail
			][cnt: cnt - 1]
			integer/push cnt
		]
		TBOX_METRICS_LINE_HEIGHT [
			float/push 1.0
		]
		default [
			ww: 0 hh: 0
			size-text str w h :ww :hh
			either type = TBOX_METRICS_SIZE [
				point2D/push as float32! ww as float32! hh
			][
				integer/push hh
			]
		]
	]
]

OS-text-box-layout: func [
	box		[red-object!]
	target	[handle!]
	ft-clr	[integer!]
	catch?	[logic!]
	return: [handle!]
	/local
		w	[widget!]
][
	w: as widget! face-handle? box
	if null? w [
		w: as widget! OS-make-view box null
	]
	as handle! w
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