Red/System [
	Title:	"Base widget"
	Author: "Xie Qingtian"
	File: 	%base.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

init-base: func [
	widget		[widget!]
][
	widget/render: as render-func! :draw-base
]

draw-base: func [
	x			[integer!]
	y			[integer!]
	widget		[widget!]
][
	_widget/render-text x y widget 0
]