Red/System [
	Title:	"Text widget"
	Author: "Xie Qingtian"
	File: 	%text.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

init-text: func [
	widget		[widget!]
][
	widget/render: as render-func! :draw-text
]

draw-text: func [
	x			[integer!]
	y			[integer!]
	widget		[widget!]
][
	_widget/render-text x y widget 0
]