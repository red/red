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
		on-time: func [face [object!] event [event!]][
			caret/rate: 2
			face/rate: none
		]
		draw: get 'system/view/platform/draw-face
		on-draw: func [
			face [object!] event [event!]
			/local
				str cmds y n h
		][
			probe "draw..................."
			box/target: face
			unless face/state [exit]
			cmds: [text 0x0 text-box]	
			cmds/3: box
			y: 0
			n: top

			foreach str at lines top [
				box/text: head str
				box/prepare
				cmds/2/y: y
				draw face cmds
				h: box/height
				n: n + 1
				y: y + h
			]
			update-caret
		]
		on-key: func [
			face [object!] event [event!]
			/local
				char
		][
			if process-shortcuts event [exit]
probe reduce [event/key event/flags]
			char: event/key
			switch/default char [
				#"^M" [exit-event-loop]				;-- ENTER key
				#"^H" [if pos <> 0 [pos: pos - 1 remove skip line pos]]
				left  [move-caret -1]
				right [move-caret 1]
				up	  []
				down  []
			][
				insert skip line pos char
				pos: pos + 1
			]
			face/rate: 10
			if caret/rate [caret/rate: none caret/color: 0.0.0.1]
			update-caret
		]
		on-menu: func [sface [object!] event [event!]][
			switch event/picked [
				copy		[probe 'TBD]
				paste		['TBD]
				select-all	['TBD]
			]
		]
	]

	update-caret: func [/local s h offset][
		box/text: head line
		box/prepare

		s: skip lines top
		h: 0
		forall s [
			h: h + 17
		]
		offset: box/offset? pos + index? line
		offset/y: offset/y + h
		caret/offset: offset
	]

	move-caret: func [n][
		pos: pos + n
		if negative? pos [pos: 0]
		if pos > length? line [pos: pos - n]
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
	heights:	make block! 1000				;-- height of each line
	lines:		make block! 1000				;-- line buffer
	max-lines:	1000							;-- maximum size of the line buffer
	full?:		no								;-- Is line buffer full?

	top:		1								;-- index of the first visible line in the line buffer
	line:		none							;-- current editing line
	pos:		0								;-- insert position of the current editing line

	box:		none
	caret:		none
]