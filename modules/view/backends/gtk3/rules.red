Red [
	Title:   "VID macOS GUI post-processing rules"
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
ok-captions: 	 ["ok" "save" "apply"]

Cancel-OK: function [
	"Put OK buttons last"
	root [object!]
][
	foreach-face/with root [
		pos-x: face/offset/x
		face/offset/x: f/offset/x
		f/offset/x: pos-x
	][
		either all [
			face/type = 'button
			find ok-captions face/text
		][
			last-but: none
			pos-x: face/offset/x
			pos-y: face/offset/y

			foreach f face/parent/pane [
				all [
					f <> face
					f/type = 'button
					find cancel-captions f/text
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