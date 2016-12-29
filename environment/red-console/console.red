Red [
	Title:	 "Red Console Widget"
	Author:	 "Qingtian Xie"
	File:	 %console.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Qingtian Xie. All rights reserved."
]

make face! [
	type: 'base color: white offset: 0x0 size: 400x400 cursor: 'I-beam
	menu: [
		"Copy^-Ctrl+C"		 copy
		"Paste^-Ctrl+V"		 paste
		"Select All^-Ctrl+A" select-all
	]
	actors: object [
		;on-time: func [face [object!] event [event!]][]
		on-draw: func [
			face [object!] event [event!]
			/local
				str cmds y m
		][
			probe box/font/name
			cmds: [text 0x0 text-box]	
			cmds/3: box
			y: 0

			foreach str at lines top [
				box/text: str
				cmds/2/y: y
				system/view/platform/draw-face face cmds
				m: box/metrics
				y: y + m/2
			]
		]
		on-key: func [face [object!] event [event!]][
			if process-shortcuts event [exit]

			either event/key = #"^M" [				;-- ENTER key
				exit-event-loop
			][
				append line event/key
			]
			caret/offset/x: caret/offset/x + 8
		]
		on-menu: func [face [object!] event [event!]][
			switch event/picked [
				copy		[probe 'TBD]
				paste		['TBD]
				select-all	['TBD]
			]
		]
	]

	process-shortcuts: function [event [event!]][
		if find event/flags 'control [
			switch event/key [
				#"C"		[probe "copy"]
			]
		]
	]

	init: func [caret-face][
		self/flags: [Direct2D]
		box: make text-box! []
		caret: caret-face
	]

	;-- data structures used by console
	lines:		make block! 1000				;-- line buffer
	max-lines:	1000							;-- maximum size of the line buffer
	full?:		no								;-- Is line buffer full?

	top:		1								;-- index of the first visible line in the line buffer
	line:		none							;-- current editing line

	box:		none
	caret:		none
]