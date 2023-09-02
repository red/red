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

focused?: routine [
	face	[object!]
	/local
		widget	[int-ptr!]
		bool	[red-logic!]
][
	widget: gui/face-handle? face
	bool: as red-logic! stack/arguments
	bool/value:  either null? widget [false][gui/has-focus? widget]
	bool/header: TYPE_LOGIC
]

make-progress-ui: function [
	face	[face!]
][
	proportion: face/data
	case [
		proportion <= 1e-16 [proportion: 0.0]
		proportion >= 1.0 [proportion: 1.0]
	]
	face/text: ""
	ui: clear face/text
	append ui #"["
	bar: face/size/x - 2	;-- exclude [ and ]
	val: to-integer round/ceiling bar * proportion
	append/dup ui #"#" val
	append/dup ui #" " bar - val
	append ui #"]"
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
	i: 1
	ui: clear ""
	foreach s face/data [
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