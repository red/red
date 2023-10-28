Red [
	Title:	"Make Text UI of faces"
	Author: "Xie Qingtian"
	File: 	%make-ui.red
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

check-color-support: function [][
	color-term: get-env "COLORTERM"
	term: get-env "TERM"
	if any [
		find color-term "24bit"
		find color-term "truecolor"
	][return 4]

	either any [
		find color-term "256"
		find term "256"
	][2][4]
]

focused?: routine [
	face	[object!]
	/local
		widget	[int-ptr!]
		bool	[red-logic!]
][
	widget: gui/face-handle? face
	logic/box either null? widget [false][gui/has-focus? widget]
]

widget-data: routine [
	face	[object!]
	/local
		widget	[int-ptr!]
][
	widget: gui/face-handle? face
	integer/box as-integer gui/widget-data widget
]

make-progress-ui: function [
	face	[face!]
][
	proportion: face/data
	case [
		proportion <= 1e-16 [proportion: 0.0]
		proportion >= 1.0 [proportion: 1.0]
	]
	ui: make string! 50
	append ui #"["
	bar: face/size/x - 2	;-- exclude [ and ]
	val: to-integer round/ceiling bar * proportion
	append/dup ui #"#" val
	append/dup ui #" " bar - val
	append ui #"]"
	face/text: ui
]

make-text-list-ui: function [
	face	[face!]
][
	data: face/data
	unless any [block? data map? data hash? data][exit]

	idx: face/selected
	unless integer? idx [
		idx: 1
		if focused? face [face/selected: 1]
	]
	unless focused? face [idx: -1]

	head: widget-data face		;-- we use widget/data to save the idx of the first entry
	data: skip face/data head
	i: head + 1
	ui: make string! 200
	foreach s data [
		if i = idx [
			append ui "^[[7m"	;-- highlight selected item
		]
		append ui s
		append ui lf
		if i = idx [
			append ui "^[[27m"	;-- reset highlight for next items
		]
		i: i + 1
	]
	face/text: ui
]