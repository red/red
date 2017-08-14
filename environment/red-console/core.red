Red [
	Title:	 "Red Console Core Data Structure"
	Author:	 "Qingtian Xie"
	File:	 %core.red
	Tabs:	 4
	Rights:  "Copyright (C) 2016 Qingtian Xie. All rights reserved."
]

do [

terminal!: object [
	lines:		make block! 1000				;-- line buffer
	nlines:		make block! 1000				;-- line count of each line, will change according to window width
	heights:	make block! 1000				;-- height of each (wrapped) line, in pixels
	selects:	make block! 8					;-- selected texts: [start-linenum idx end-linenum idx]

	max-lines:	1000							;-- maximum size of the line buffer
	full?:		no								;-- is line buffer full?
	ask?:		no								;-- is it in ask loop
	mouse-up?:	yes
	ime-open?:	no
	ime-pos:	0

	top:		1								;-- index of the first visible line in the line buffer
	line:		none							;-- current editing line
	pos:		0								;-- insert position of the current editing line

	scroll-y:	0								;-- in pixels

	line-y:		0								;-- y offset of editing line
	line-h:		0								;-- average line height
	page-cnt:	0								;-- number of lines in one page
	line-cnt:	0								;-- number of lines in total (include wrapped lines)
	screen-cnt: 0								;-- number of lines on screen
	delta-cnt:	0

	box:		make text-box! []
	caret:		none							;-- caret face
	scroller:	none							;-- scroller face
	target:		none							;-- target base face
	tips:		none

	tab-size:	4
	background: none
	select-bg:	none							;-- selected text background color

	theme: #(
		background	[252.252.252]
		selected	[200.200.255]				;-- selected text background color
		string!		[120.120.61]
		integer!	[255.0.0]
		float!		[255.0.0]
		pair!		[255.0.0]
		percent!	[255.128.128]
		datatype!	[0.222.0]
		lit-word!	[0.0.255 bold]
		set-word!	[0.0.255]
		tuple!		[0.0.0]
		url!		[0.0.255 underline]
		comment!	[128.128.128]
	)

	draw: get 'system/view/platform/draw-face
	redraw: get 'system/view/platform/redraw

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
					redraw target
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
		redraw target
		do-events/no-wait
		last-lf?: yes
		()				;-- return unset!
	]

	reset-buffer: func [blk [block!] /advance /local s][
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
				lines: reset-buffer/advance lines
				nlines: reset-buffer nlines
				heights: reset-buffer heights
			][
				lines: next lines
				nlines: next nlines
				heights: next heights
			]
		][
			full?: max-lines = length? lines
		]
	]

	update-theme: func [][
		background: first select theme 'background
		select-bg:  reduce ['backdrop first select theme 'selected]
		target/color: background
	]

	update-cfg: func [font [object!] cfg [block!]][
		box/state: none					;TBD release resources in text-box!
		box/font: font
		max-lines: cfg/buffer-lines
		box/text: "X"
		box/layout
		box/tabs: tab-size * box/width
		line-h: box/line-height 1
		caret/size/y: line-h
		update-theme
	]

	resize: func [new-size [pair!] /local y][
		y: new-size/y
		new-size/x: new-size/x - 20
		new-size/y: y + line-h
		box/size: new-size
		if scroller [
			page-cnt: y / line-h
			scroller/page-size: page-cnt
			scroller/max-size: line-cnt - 1 + page-cnt
			scroller/position: scroller/position
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
			wheel		[event/picked]
		][0]
		if n <> 0 [
			scroll-lines n
			redraw target
		]
	]

	update-caret: func [/local len n s h lh offset][
		unless line [exit]
		n: top
		h: 0
		len: length? skip lines top
		loop len [
			h: h + pick heights n
			n: n + 1
		]
		offset: box/offset? pos + index? line
		offset/y: offset/y + h + scroll-y
		if ask? [
			either offset/y < target/size/y [
				caret/offset: offset
				unless caret/visible? [caret/visible?: yes]
			][
				if caret/visible? [caret/visible?: no]
			]
		]
	]

	offset-to-line: func [offset [pair!] /local h y start end n][
		;if offset/y > (line-y + last heights) [exit]

		y: offset/y - scroll-y
		end: line-y - scroll-y
		h: 0
		n: top
		until [
			h: h + pick heights n
			if y < h [break]
			n: n + 1
			h > end
		]
		if n > length? lines [n: length? lines]
		box/text: head pick lines n
		box/layout
		start: pick heights n
		offset/y: y + start - h
		append selects n
		append selects box/index? offset
	]

	mouse-to-caret: func [event [event!] /local offset][
		offset: event/offset
		if any [offset/y < line-y offset/y > (line-y + last heights)][exit]

		offset/y: offset/y - line-y
		box/text: head line
		box/layout
		pos: (box/index? offset) - (index? line)
		if pos < 0 [pos: 0]
		update-caret
	]

	mouse-down: func [event [event!]][
		mouse-up?: no
		clear selects

		offset-to-line event/offset
		mouse-to-caret event
	]

	mouse-up: func [event [event!]][
		mouse-up?: yes
		redraw target
	]

	mouse-move: func [event [event!]][
		if any [mouse-up? empty? selects][exit]

		clear skip selects 2
		offset-to-line event/offset
		mouse-to-caret event
		redraw target
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

	calc-last-line: func [/local n cnt h total][
		n: length? lines
		box/text: head last lines
		box/layout
		total: line-cnt
		h: box/height
		cnt: box/line-count
		either n > length? nlines [			;-- add a new line
			append heights h
			append nlines cnt
			line-cnt: line-cnt + cnt
		][
			poke heights n h
			line-cnt: line-cnt + cnt - pick nlines n
			poke nlines n cnt
		]
		n: line-cnt - total - delta-cnt
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

	process-ime-input: func [event [event!] /local text][
		text: event/picked
		either ime-open? [
			change/part skip line ime-pos text pos - ime-pos
		][
			ime-pos: pos
			insert skip line pos text
			ime-open?: yes
		]
		pos: ime-pos + length? text
		calc-top/edit
		redraw target
	]

	process-shortcuts: function [event [event!]][
		if find event/flags 'control [
			switch event/key [
				#"C"		[probe "copy"]
			]
		]
	]

	press-key: func [event [event!] /local char][
		if ime-open? [
			remove/part skip line ime-pos pos - ime-pos
			pos: ime-pos
			ime-open?: no
		]
		if process-shortcuts event [exit]
		char: event/key
		switch/default char [
			#"^M" [									;-- ENTER key
				caret/visible?: no
				system/view/platform/exit-event-loop
			]
			#"^H" [if pos <> 0 [pos: pos - 1 remove skip line pos]]
			#"^-" [				;TBD autocompletion
				insert skip line pos char
				pos: pos + 1
			]
			left  [move-caret -1]
			right [move-caret 1]
			up	  []
			down  []
		][
			if all [char? char char > 31][
				insert skip line pos char
				pos: pos + 1
			]
		]
		target/rate: 6
		if caret/rate [caret/rate: none caret/color: 0.0.0.1]
		calc-top/edit
		redraw target
	]

	paint-selects: func [
		styles n
		/local start-n end-n start-idx end-idx len swap?
	][
		if any [empty? selects 3 > length? selects][exit]

		swap?: selects/1 > selects/3
		if swap? [move/part skip selects 2 selects 2]				;-- swap start and end
		set [start-n start-idx end-n end-idx] selects
		if any [
			n < start-n
			n > end-n
			all [start-n = end-n start-idx = end-idx]				;-- select nothing
		][
			if swap? [move/part skip selects 2 selects 2]
			exit
		]

		either start-n = end-n [
			len: end-idx - start-idx
			if len < 0 [start-idx: end-idx len: 0 - len]
		][
			len: length? head pick lines n
			case [
				n = start-n [len: len - start-idx + 1]
				n = end-n	[start-idx: 1 len: end-idx - 1]
				true		[start-idx: 1]
			]
		]
		append styles start-idx
		append styles len
		append styles select-bg
		if swap? [move/part skip selects 2 selects 2]
	]

	paint: func [/local str cmds y n h cnt delta num end styles][
		unless line [exit]
		cmds: [text 0x0 text-box]
		cmds/3: box
		end: target/size/y
		y: scroll-y
		n: top
		num: line-cnt
		styles: box/styles
		foreach str at lines top [
			box/text: head str
			highlight/add-styles head str clear styles theme
			paint-selects styles n
			box/layout
			clear styles
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
		line-y: y - h
		screen-cnt: y / line-h
		update-caret
		update-scroller line-cnt - num
	]
]

]