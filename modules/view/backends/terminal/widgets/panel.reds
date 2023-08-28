Red/System [
	Title:	"Panel widget"
	Author: "Xie Qingtian"
	File: 	%panel.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

init-panel: func [
	widget		[widget!]
][
	widget/render: as render-func! :draw-panel
]

draw-panel: func [
	x			[integer!]
	y			[integer!]
	widget		[widget!]
][
	_widget/render-text x y widget 0
]