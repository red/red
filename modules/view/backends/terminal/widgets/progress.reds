Red/System [
	Title:	"Progress bar widget"
	Author: "Xie Qingtian"
	File: 	%progress.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

make-progress-ui: func [
	widget		[widget!]
	/local
		face	[red-object!]
][
	face: get-face-obj widget
	#call [TUI-helpers/make-progress-ui face]
]

init-progress: func [
	widget		[widget!]
][
	widget/update: as update-func! :make-progress-ui
	widget/render: as render-func! :draw-progress
	make-progress-ui widget
]

draw-progress: func [
	x			[integer!]
	y			[integer!]
	widget		[widget!]
][
	_widget/render x y widget 0
]