Red [
	Title:	 "Red Console Widget"
	Author:	 "Qingtian Xie"
	File:	 %console.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Qingtian Xie. All rights reserved."
]

make face! [
	type: 'base color: white offset: 0x0 size: 400x400
	cursor: 'I-beam flags: [Direct2D]
	menu: [
		"Copy^-Ctrl+C"		 copy
		"Paste^-Ctrl+V"		 paste
		"Select All^-Ctrl+A" select-all
	]
	actors: object [
		;on-time: func [face [object!] event [event!]][]
		draw: get 'system/view/platform/draw-face
		on-draw: func [
			face [object!] event [event!]
			/local
				str cmds y m
		][
			box/target: face
			unless face/state [exit]
			cmds: [text 0x0 text-box]	
			cmds/3: box
			y: 0

			foreach str at lines top [
				box/text: head str
				box/prepare
				cmds/2/y: y
				draw face cmds
				y: y + box/height
			]
		]
		on-key: func [
			face [object!] event [event!]
			/local
				pos char
		][
			if process-shortcuts event [exit]
probe reduce [event/key event/flags]
			char: event/key
			switch/default char [
				#"^M" [exit-event-loop]				;-- ENTER key
				#"^H" [remove line: back line]
				left  [line: back line]
				right [line: next line]
			][
				insert line event/key
				line: next line
			]
			box/text: head line
			box/prepare
			caret/offset: box/offset? index? line
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