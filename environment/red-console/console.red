Red [
	Title:	 "Red Console Widget"
	Author:	 "Qingtian Xie"
	File:	 %console.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Qingtian Xie. All rights reserved."
]

make face! [
	type: 'base color: white offset: 0x0 size: 400x400
	menu: [
		"Copy^-Ctrl+C"		 copy
		"Paste^-Ctrl+V"		 paste
		"Select All^-Ctrl+A" select-all
	]
	actors: object [
		on-create: func [face [object!]][]
		on-key: func [face [object!] event [event!]][
			either event/key = #"^M" [				;-- ENTER key
				exit-event-loop
			][
				append line event/key
			]
		]
		on-time: func [face [object!] event [event!]][]
		on-menu: func [face [object!] event [event!]][
			switch event/picked [
				copy		[probe 'TBD]
				paste		['TBD]
				select-all	['TBD]
			]
		]
	]

	;-- data structures used by console
	lines:	make block! 1000
	prompt: none
	line:	none								;-- current editing line
]