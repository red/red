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
no-capital:  	 ["a " | "an " | "the " | "and " | "or "]

title-ize: function [text [string!] return: [string!]][
	parse text [
		any #" " some [no-capital | p: (uppercase/part p 1) thru #" "]
	]
	text
]

sentence-ize: function [text [string!] return: [string!]][
	parse text [
		any #" " h: some [
			end
			| remove #"^^" thru #" "					;-- ^ in front of a word to escaped lowercasing
			| s: [thru #" " | to end] e: (lowercase/part s e)
		]
	]
	uppercase/part h 1
]

capitalize: function [
	"Capitalize widget text according to macOS guidelines"
	; https://developer.apple.com/library/content/documentation/UserExperience/Conceptual/OSXHIGuidelines/TerminologyWording.html
	root [object!]
][
	foreach-face/with root [
		if face/menu [
			parse rule: [some [
				pos: string! (title-ize pos/1)
				| into rule
				| skip
			]]
		]
		either find [radio check] face/type [
			sentence-ize face/text
		][
			title-ize face/text
		]
	][
		all [
			face/type = 'button
			face/text
			not empty? face/text
		]
	]
]

adjust-buttons: function [
	"Use standard button classes when buttons are narrow enough"
	root [object!]
][
	def-margins: 2x2
	def-margin-yy: 5
	opts: [class: _]
	svmm: system/view/metrics/margins
	
	foreach-face/with root [
		y: face/size/y - def-margin-yy					;-- remove default button's margins
		opts/2: case [
			y <= 15 [face/size/y: 16 'mini]				;-- 15, margins: 0x1
			y <= 19 [face/size/y: 28 'small]			;-- 18, margins: 4x6
			y <= 37	[face/size/y: 32 'regular]			;-- 21, margins: 4x7
		]
		system/view/VID/add-option face opts
		align: face/options/vid-align

		unless face/options/at-offset [
			axis:  pick [x y] to-logic find [left center right] align
			marg:  select svmm face/options/class
			def-marg: def-margins/:axis

			face/offset/:axis: face/offset/:axis + switch align [ ;-- adjust to alignment
				top		[def-marg - marg/2/x]
				middle  [negate marg/2/y / 2]
				bottom	[marg/2/y - def-marg - marg/2/x]
				left	[def-marg - marg/1/x]
				center  [0]								;-- margin-independent
				right	[marg/1/y - def-marg]
			]
		]
	][
		all [
			face/type = 'button
			face/size
			face/size/y <= 42							;-- 37 + 5
			not empty? face/text
			not all [face/options face/options/class]
		]
	]
]

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