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
	full?:		no								;-- is line buffer full?
	ask?:		no								;-- is it in ask loop

	top:		1								;-- index of the first visible line in the line buffer
	line:		none							;-- current editing line
	pos:		0								;-- insert position of the current editing line

	scroll-y:	0

	line-h:		0								;-- average line height
	page-cnt:	0								;-- number of lines in one page
	line-cnt:	0								;-- number of lines on screen (include wrapped lines)
	delta-cnt:	0
	screen-cnt: 0

	box:		make text-box! []
	caret:		none
	scroller:	none
	target:		none
	tips:		none

	draw: get 'system/view/platform/draw-face

	print: func [value [any-type!] /local str s cnt][
		if block? value [value: reduce value]
		str: form value
		s: find str lf
		either s [
			cnt: 0
			until [
				add-line copy/part str s
				calc-top
				str: skip s 1
				cnt: cnt + 1
				if cnt = 200 [
					show target
					loop 3 [do-events/no-wait]
					cnt: 0
				]
				not s: find str lf
			]
			either lf = last str [
				add-line ""
			][
				add-line copy str
			]
		][
			add-line str
		]
		calc-top
		show target
		do-events/no-wait
		()				;-- return unset!
	]

	reset-block: func [blk [block!] /advance /local s][
		s: either advance [next blk][blk]
		blk: head blk
		move/part s blk max-lines
		clear s
		blk
	]

	add-line: func [str][
		append lines str
		either full? [
			delta-cnt: first nlines
			line-cnt: line-cnt - delta-cnt
			if top <> 1 [top: top - 1]
			either max-lines = index? lines [
				lines: reset-block/advance lines
				nlines: reset-block nlines
				heights: reset-block heights
			][
				lines: next lines
				nlines: next nlines
				heights: next heights
			]
		][
			full?: max-lines = length? lines
		]
	]

	update-cfg: func [font cfg][
		box/font: font
		max-lines: cfg/buffer-lines
		box/text: "X"
		box/layout
		line-h: box/line-height 1
		caret/size/y: line-h
	]

	resize: func [new-size [pair!] /local y][
		y: new-size/y
		new-size/x: new-size/x - 20
		new-size/y: 0
		box/size: new-size
		if scroller [
			page-cnt: y / line-h
			scroller/page-size: page-cnt
		]
	]

	scroll: func [event /local key n][
		unless ask? [exit]
		key: event/key
		n: switch/default key [ 
			up			[1]
			down		[-1]
			page-up		[scroller/page-size]
			page-down	[0 - scroller/page-size]
			track		[scroller/position - event/picked]
			mouse-wheel [event/picked * 3]
		][0]
		if n <> 0 [
			scroll-lines n
			show target
		]
	]

	update-caret: func [/local len n s h lh offset offset2][
		n: top
		h: 0
		len: length? skip lines top
		loop len [
			h: h + pick heights n
			n: n + 1
		]
		offset: box/offset? pos + index? line
		offset/y: offset/y + h + scroll-y
		offset2: offset
		offset2/y: offset2/y + line-h
		tips/offset: offset2
		if ask? [
			either offset/y < target/size/y [
				caret/offset: offset
				unless caret/visible? [caret/visible?: yes]
			][
				if caret/visible? [caret/visible?: no]
			]
		]
	]

	move-caret: func [n][
		pos: pos + n
		if negative? pos [pos: 0]
		if pos > length? line [pos: pos - n]
	]

	scroll-lines: func [delta /local n len cnt end offset][
		end: scroller/max-size - page-cnt + 1
		offset: scroller/position

		if any [
			all [offset = 1 delta > 0]
			all [offset = end delta < 0]
		][exit]

		offset: offset - delta
		scroller/position: either offset < 1 [1][
			either offset > end [end][offset]
		]

		if zero? delta [exit]

		n: top
		either delta > 0 [						;-- scroll up
			delta: delta + (scroll-y / line-h + pick nlines n)
			scroll-y: 0
			until [
				cnt: pick nlines n
				delta: delta - cnt
				n: n - 1
				any [delta < 1 n < 1]
			]
			if delta <= 0 [
				n: n + 1
				if delta < 0 [
					delta: delta + cnt * line-h
					scroll-y: 0 - delta
				]
			]
			if zero? n [n: 1 scroll-y: 0]
		][										;-- scroll down
			len: length? lines
			delta: scroll-y / line-h + delta
			scroll-y: 0
			until [
				cnt: pick nlines n
				delta: delta + cnt
				n: n + 1
				any [delta >= 0 n > len]
			]
			if delta > 0 [
				n: n - 1
				scroll-y: delta - cnt * line-h
			]
			if n > len [n: len scroll-y: 0]
		]
		top: n
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
		n: line-cnt - num - delta-cnt
		delta-cnt: 0
		n
	]

	calc-top: func [/edit /local delta n][
		n: calc-last-line
		if n < 0 [
			delta: scroller/position + n
			scroller/position: either delta < 1 [1][delta]
		]
		if n <> 0 [scroller/max-size: line-cnt - 1 + page-cnt]
		delta: screen-cnt + n - page-cnt

		if delta >= 0 [
			either edit [
				n: line-cnt - page-cnt
				if scroller/position < n [
					top: length? lines
					scroller/position: scroller/max-size - page-cnt + 1
					scroll-lines page-cnt - 1
				]
			][
				scroll-lines -1 - delta
			]
		]
	]

	update-scroller: func [delta /reposition /local n end][
		end: scroller/max-size - page-cnt + 1
		if delta <> 0 [scroller/max-size: line-cnt - 1 + page-cnt]
		if delta < 0 [
			n: scroller/position
			if n <> end [scroller/position: n - delta]
		]
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
			#"^M" [									;-- ENTER key
				caret/visible?: no
				exit-event-loop
			]
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
		calc-top/edit
		show target
	]

	paint: func [/local str cmds y n h cnt delta num end][
		cmds: [text 0x0 text-box]
		cmds/3: box
		end: target/size/y
		y: scroll-y
		n: top
		num: line-cnt
		foreach str at lines top [
			box/text: head str
			highlight/add-styles head str clear box/styles
			box/layout
			cmds/2/y: y
			draw target cmds

			h: box/height
			cnt: box/line-count
			poke heights n h
			line-cnt: line-cnt + cnt - pick nlines n
			poke nlines n cnt

			n: n + 1
			y: y + h
			if y > end [break]
		]
		screen-cnt: y / line-h
		update-caret
		update-scroller line-cnt - num
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
			probe "on-draw"
			extra/paint
		]
		on-scroll: func [face [object!] event [event!]][
			extra/scroll event
		]
		on-wheel: func [face [object!] event [event!]][
			extra/scroll event
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
		scroller/max-size: 2
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