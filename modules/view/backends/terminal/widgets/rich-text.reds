Red/System [
	Title:	"Rich Text Widget"
	Author: "Xie Qingtian"
	File: 	%rich-text.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

init-rich-text: func [
	widget		[widget!]
][
	update-rich-text widget
	widget/update: as update-func! :update-rich-text
	widget/render: as render-func! :draw-rich-text
]

update-rich-text: func [
	widget		[widget!]
	/local
		data	[int-ptr!]
		len		[integer!]
		values	[red-value!]
		styles	[red-block!]
		color	[red-tuple!]
		str		[red-string!]
		p		[pixel!]
		i idx	[integer!]
		cp clr	[integer!]
][
	values: get-face-values widget
	styles: as red-block! values + FACE_OBJ_DATA
	str:	as red-string! values + FACE_OBJ_TEXT
	color:	as red-tuple! values + FACE_OBJ_COLOR

	if TYPE_OF(str) <> TYPE_STRING [exit]

	data: widget/data
	len: string/rs-length? str

	if all [
		data <> null
		data/value < len
	][
		free as byte-ptr! data
		data: null
		widget/data: null
	]

	if any [zero? len TYPE_OF(styles) <> TYPE_BLOCK][exit]

	if null? data [
		data: as int-ptr! zero-alloc len + 1 * size? pixel!
		data/value: len
		widget/data: data
	]

	clr: 0
	if TYPE_OF(color) = TYPE_TUPLE [
		if any [
			TUPLE_SIZE?(color) = 3
			color/array1 >>> 24 <> FFh
		][
			clr: make-color-256 get-tuple-color color
		]
	]

	;-- fill attribute string buffer
	p: as pixel! data
	i: 0
	idx: str/head
	while [i < len][
		p: p + 1
		i: i + 1
		cp: string/rs-abs-at str idx
		p/code-point: cp
		p/bg-color: clr
		p/fg-color: 0
		p/flags: 0
		idx: idx + 1
	]
	parse-text-styles as int-ptr! widget data styles str no
]

draw-rich-text: func [
	x			[integer!]
	y			[integer!]
	widget		[widget!]
][
	_widget/render x y widget 0
]