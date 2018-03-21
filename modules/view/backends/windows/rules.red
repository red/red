Red [
	Title:   "VID Windows GUI post-processing rules"
	Author:  "Nenad Rakocevic"
	File: 	 %rules.red
	Tabs:	 4
	Rights:  "Copyright (C) 2017-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]


cancel-captions: ["cancel" "delete" "remove"]

color-backgrounds: function [
	"Color the background of faces with no color, with parent's background color"
	root [object!]
][
	foreach-face/with root [face/color: face/parent/color][
		all [
			none? face/color
			find [window panel group-box tab-panel] face/parent/type
			find [text slider radio check group-box tab-panel panel] face/type
		]
	]
]

color-tabpanel-children: function [
	"Color the background of faces with no color, with parent's background color"
	root [object!]
][
	foreach-face/with root [
		face/color: any [
			gp/color
			system/view/metrics/colors/tab-panel
		]
	][
		all [
			none? face/color
			face/parent/type = 'panel
			gp: face/parent/parent
			gp/type = 'tab-panel
			find [text slider radio check group-box tab-panel] face/type
		]
	]
]

OK-Cancel: function [
	"Put Cancel buttons last"
	root [object!]
][
	foreach-face/with root [
		pos-x: face/offset/x							;-- swap the "Cancel" button with last one
		face/offset/x: f/offset/x
		f/offset/x: pos-x
	][
		either all [
			face/type = 'button
			find cancel-captions face/text
		][
			last-but: none
			pos-x: face/offset/x
			pos-y: face/offset/y

			foreach f face/parent/pane [
				all [									;-- search for last button on right
					f <> face
					f/type = 'button
					5 > absolute f/offset/y - pos-y
					pos-x < f/offset/x
					pos-x: f/offset/x
					last-but: f
				]
			]
			last-but
		][no]
	]
]
