Red [
	Title:	 "Red Console Widget"
	Author:	 "Qingtian Xie"
	File:	 %console.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Qingtian Xie. All rights reserved."
]

terminal!: object [
	lines:		make block! 1000				;-- line buffer
	nlines:		make block! 1000				;-- line count of each line
	heights:	make block! 1000				;-- height of each line

	max-lines:	1000							;-- maximum size of the line buffer
	full?:		no								;-- Is line buffer full?

	top:		1								;-- index of the first visible line in the line buffer
	line:		none							;-- current editing line
	pos:		0								;-- insert position of the current editing line

	scroll-y:	0

	line-h:		0								;-- average line height
	page-cnt:	0								;-- number of lines in one page
	line-cnt:	0								;-- number of lines on screen (include wrapped lines)

	box:		make text-box! []
	caret:		none
	scroller:	none
	target:		none

	draw: get 'system/view/platform/draw-face

	print: func [value [any-type!] /local str][
		if block? value [value: reduce value]
		str: form value
		append lines str
		calc-top
		()				;-- return unset!
	]

	update-cfg: func [font cfg][
		box/font: font
		max-lines: cfg/buffer-lines
		box/text: "X"
		box/layout
		line-h: box/line-height 1
		caret/size/y: line-h
	]

	resize: func [new-size [pair!]][
		box/size: new-size
		box/size/y: 0
		if scroller [
			page-cnt: new-size/y / line-h
			scroller/page-size: page-cnt
		]
	]

	scroll: func [key /local n][
		n: either integer? key [key * 3][
			switch/default key [
				up		[1]
				down	[-1]
				page-up [scroller/page-size]
				page-down [0 - scroller/page-size]
			][0]
		]
		scroll-lines n
	]

	update-caret: func [/local len n s h lh offset][
		n: top
		h: 0
		len: length? skip lines top
		loop len [
			h: h + pick heights n
			n: n + 1
		]
		offset: box/offset? pos + index? line
		offset/y: offset/y + h + scroll-y
		caret/offset: offset
	]

	move-caret: func [n][
		pos: pos + n
		if negative? pos [pos: 0]
		if pos > length? line [pos: pos - n]
	]

	scroll-lines: func [delta /local n len cnt][
	?? delta
		scroller/position: scroller/position - delta
		either delta > 0 [			;-- scroll up
			
		][
			n: top
			len: length? lines
			until [
				cnt: pick nlines n
				delta: delta + cnt
				n: n + 1
				any [delta >= 0 n > len]
			]
			if delta > 0 [
				delta: delta - cnt
				n: n - 1
				delta: delta * line-h
				scroll-y: either top = n [scroll-y + delta][delta]
			]
			top: n
		]
		show target
	]

	calc-last-line: func [/local n cnt h num][
		n: length? lines
		box/text: head last lines
		box/layout
		num: line-cnt
		h: box/height
		cnt: box/line-count
		either n > length? nlines [
			append heights h
			append nlines cnt
			line-cnt: line-cnt + cnt
		][
			poke heights n h
			line-cnt: line-cnt + cnt - pick nlines n
			poke nlines n cnt
		]
		if num <> line-cnt [update-scroller]
	]

	calc-top: func [/local delta n cnt h win-h][
		calc-last-line
		delta: line-cnt - scroller/position - page-cnt
		if delta < 0 [exit]

		scroll-lines -1 - delta
	]

	update-scroller: func [][
		scroller/max-size: line-cnt - 1 + scroller/page-size
	]

	process-shortcuts: function [event [event!]][
		if find event/flags 'control [
			switch event/key [
				#"C"		[probe "copy"]
			]
		]
	]

	press-key: func [event [event!] /local char][
		if process-shortcuts event [exit]
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
		target/rate: 6
		if caret/rate [caret/rate: none caret/color: 0.0.0.1]
		calc-top
	]

	paint: func [/local str cmds y n h cnt delta num][
		cmds: [text 0x0 text-box]
		cmds/3: box
		y: scroll-y
?? y
		n: top
		num: line-cnt
		foreach str at lines top [
			box/text: head str
			highlight/add-styles head str clear box/styles
			box/layout
			cmds/2/y: y
			draw target cmds

			h: box/height
			;cnt: box/line-count
			;poke heights n h
			;line-cnt: line-cnt + cnt - pick nlines n
			;poke nlines n cnt

			n: n + 1
			y: y + h
		]
?? y
		update-caret
		if num <> line-cnt [update-scroller]
	]
]

console!: make face! [
	type: 'base color: white offset: 0x0 size: 400x400 cursor: 'I-beam
	flags: [Direct2D scrollable]
	menu: [
		"Copy^-Ctrl+C"		 copy
		"Paste^-Ctrl+V"		 paste
		"Select All^-Ctrl+A" select-all
	]
	actors: object [
		on-time: func [face [object!] event [event!]][
			extra/caret/rate: 2
			face/rate: none
		]
		on-draw: func [face [object!] event [event!]][
			extra/paint
		]
		on-scroll: func [face [object!] event [event!]][
			extra/scroll event/key
		]
		on-wheel: func [face [object!] event [event!]][
			extra/scroll event/picked
		]
		on-key: func [face [object!] event [event!]][
			extra/press-key event
		]
		on-menu: func [face [object!] event [event!]][
			switch event/picked [
				copy		[probe 'TBD]
				paste		['TBD]
				select-all	['TBD]
			]
		]
	]

	resize: func [new-size][
		self/size: new-size
		extra/resize new-size
	]

	init: func [/local terminal box scroller][
		terminal: extra
		terminal/target: self
		box: terminal/box
		box/fixed?: yes
		box/target: self
		box/styles: make block! 200
		scroller: get-scroller self 'horizontal
		scroller/visible?: no
		scroller: get-scroller self 'vertical
		scroller/position: 1
		terminal/scroller: scroller
		print: get 'terminal/print
	]

	apply-cfg: func [cfg][
		self/font:	make font! [
			name:  cfg/font-name
			size:  cfg/font-size
			color: cfg/font-color
		]
		self/color:	cfg/background
		extra/update-cfg self/font cfg
	]

	extra: make terminal! []
]