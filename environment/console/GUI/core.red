Red [
	Title:	 "Red Console Core Data Structure"
	Author:	 "Qingtian Xie"
	File:	 %core.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

object [
	lines:		make block! 1000				;-- line buffer
	nlines:		make block! 1000				;-- line count of each line, changed according to window width
	heights:	make block! 1000				;-- height of each (wrapped) line, in pixels
	selects:	make block! 8					;-- selected texts: [start-linenum idx end-linenum idx]

	max-lines:	1000							;-- maximum size of the line buffer
	full?:		no								;-- is line buffer full?
	ask?:		no								;-- is it in ask loop
	prin?:		no								;-- start prin?
	newline?:	no								;-- start a new line?
	mouse-up?:	yes
	ime-open?:	no
	ime-pos:	0

	top:		1								;-- index of the first visible line in the line buffer
	line:		none							;-- current editing line
	pos:		0								;-- insert position of the current editing line

	scroll-y:	0								;-- in pixels

	line-y:		0								;-- y offset of editing line
	line-h:		0								;-- average line height
	char-width: 0								;-- average char width
	page-cnt:	0								;-- number of lines in one page
	line-cnt:	0								;-- number of lines in total (include wrapped lines)
	screen-cnt: 0								;-- number of lines on screen
	delta-cnt:	0

	history:	system/console/history
	hist-idx:	0
	hist-line:	none							;-- for saving the current editing line
	hist-pos:	0								;-- current editing line's caret position

	clipboard:	none							;-- data in clipboard for pasting
	clip-buf:	make string! 20					;-- buffer for copy into clipboard
	paste-cnt:	0
	box:		make face! [
					type: 'rich-text
					tabs: none
					line-spacing: none
					handles: none
				]

	undo-stack: make block! 60
	redo-stack: make block! 20

	windows:	none							;-- all the windows opened

	tab-size:	4
	foreground: 0.0.0
	background: none
	select-bg:	none							;-- selected text background color
	pad-left:	3

	color?:		no
	theme: #(
		foreground	[0.0.0]
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

	do-ask-loop: function [/no-wait][
		system/view/platform/do-event-loop no-wait
	]

	exit-ask-loop: func [/escape][
		clear selects
		caret/visible?: no
		either escape [append line #"^["][
			if all [not empty? line line <> first history][insert history line]
			hist-idx: 0	
		]
		prin?: no
		newline?: yes
		system/view/platform/exit-event-loop
	]

	refresh: func [][
		system/view/platform/redraw console
		do-ask-loop/no-wait
	]

	vprin: func [str [string!]][
		either empty? lines [
			append lines str
		][
			append last lines str
		]
		calc-top
	]

	vprint: func [str [string!] lf? [logic!] /local s cnt][
		unless console/state [exit]

		if all [not lf? newline?][newline?: no add-line make string! 8]
		if lf? [newline?: yes]
		s: find str lf
		either s [
			cnt: 0
			until [
				add-line copy/part str s
				str: skip s 1
				cnt: cnt + 1
				if cnt = 100 [
					refresh
					cnt: 0
				]
				not s: find str lf
			]
			either str/1 = lf [
				add-line ""
			][
				either all [lf? not prin?][add-line copy str][vprin str]
			]
		][
			either all [lf? not prin?][add-line str][vprin str]
		]
		prin?: not lf?
		if system/console/running? [
			system/view/platform/redraw console
		]
		()				;-- return unset!
	]

	reset-buffer: func [blk [block!] /advance /local src][
		src: blk
		blk: head blk
		move/part src blk max-lines
		clear src
		blk
	]

	add-line: func [str [string!]][
		either full? [
			delta-cnt: first nlines
			line-cnt: line-cnt - delta-cnt
			if top <> 1 [top: top - 1]
			either max-lines + 1 = index? lines [
				lines: reset-buffer lines
				nlines: reset-buffer nlines
				heights: reset-buffer heights
			][
				lines: next lines
				nlines: next nlines
				heights: next heights
			]
			append lines str
			calc-top/new
		][
			append lines str
			full?: max-lines = length? lines
			calc-top
		]
	]

	calc-last-line: func [new? [logic!] /local n cnt h total][
		n: length? lines
		box/text: head last lines
		total: line-cnt
		cnt: rich-text/line-count? box
		h: cnt * line-h
		either any [new? n > length? nlines][			;-- add a new line
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

	calc-top: func [/new /local delta n][
		n: calc-last-line new
		if n < 0 [
			delta: scroller/position + n
			scroller/position: either delta < 1 [1][delta]
		]
		if n <> 0 [scroller/max-size: line-cnt - 1 + page-cnt]
		delta: screen-cnt + n - page-cnt
		if screen-cnt < page-cnt [
			screen-cnt: screen-cnt + n
			if screen-cnt > page-cnt [screen-cnt: page-cnt]
		]
		if delta >= 0 [reset-top]
	]

	reset-top: func [/force /local n][
		n: line-cnt - page-cnt
		if any [
			scroller/position <= n
			all [full? force]
		][
			top: length? lines
			scroll-y: line-h - last heights
			scroller/position: scroller/max-size - page-cnt + 1
			scroll-lines page-cnt - 1
		]
	]

	update-theme: func [][
		foreground: first select theme 'foreground
		background: first select theme 'background
		select-bg:  reduce ['backdrop first select theme 'selected]
		console/color: background
	]

	update-cfg: func [font [object!] cfg [block!] /local sz][
		box/font: font
		max-lines: cfg/buffer-lines
		box/text: "XX"
		sz: size-text box
		char-width: 1 + sz/x / 2
		box/tabs: tab-size * char-width
		line-h: rich-text/line-height? box 1
		box/line-spacing: line-h
		caret/size/y: line-h
		if cfg/background [change theme/background cfg/background]
		if font/color [change theme/foreground font/color]
		adjust-console-size gui-console-ctx/console/size
		update-theme
	]

	adjust-console-size: function [size [pair!]][
		cols: size/x - pad-left / char-width
		rows: size/y / line-h
		system/console/size: as-pair cols rows
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
		if empty? lines [exit]
		key: event/key
		n: switch/default key [ 
			up			[1]
			down		[-1]
			page-up		[scroller/page-size]
			page-down	[0 - scroller/page-size]
			track		[scroller/position - event/picked]
			wheel		[event/picked * 3]
		][0]
		if n <> 0 [
			scroll-lines n
			system/view/platform/redraw console
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
		offset: caret-to-offset box pos + index? line
		offset/x: offset/x + pad-left
		offset/y: offset/y + h + scroll-y
		if ask? [
			either offset/y < console/size/y [
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
		start: pick heights n
		offset/x: offset/x - pad-left 
		offset/y: y + start - h
		append selects n
		append selects offset-to-caret box offset
	]

	mouse-to-caret: func [event [event!] /local offset][
		offset: event/offset
		if any [offset/y < line-y offset/y > (line-y + last heights)][exit]

		offset/x: offset/x - pad-left
		offset/y: offset/y - line-y
		box/text: head line
		pos: (offset-to-caret box offset) - (index? line)
		if pos < 0 [pos: 0]
		update-caret
	]

	mouse-down: func [event [event!]][
		if empty? lines [exit]
		mouse-up?: no
		clear selects

		offset-to-line event/offset
		mouse-to-caret event
	]

	mouse-up: func [event [event!]][
		if empty? lines [exit]
		mouse-up?: yes
		if 2 = length? selects [clear selects]
		system/view/platform/redraw console
	]

	mouse-move: func [event [event!]][
		if any [empty? lines mouse-up? empty? selects][exit]

		clear skip selects 2
		offset-to-line event/offset
		mouse-to-caret event
		system/view/platform/redraw console
	]

	jump-word: func [left? [logic!] return: [integer!] /local start n][
		either left? [
			start: find/reverse/tail skip line pos #" "
			either start [
				n: (index? start) - pos - index? line
				if all [zero? n pos <> 0][n: -1]
			][n: pos]
		][
			start: find skip line pos #" "
			unless start [start: tail line]
			n: (index? start) - pos - index? line
			if all [zero? n pos <> length? line][n: 1]
		]
		n
	]

	select-all: func [][
		if empty? lines [exit]
		reduce/into [1 1 line-cnt 1 + length? head line] clear selects
		system/view/platform/redraw console
	]

	select-text: func [n [integer!] /local start end start-idx end-idx c][
		if zero? n [exit]

		c: length? lines			;-- index of current editing line
		set [start start-idx end end-idx] selects
		if all [start <> c end = c][start: c start-idx: end-idx]
		if start <> c [start: c start-idx: pos + index? line end: c]
		end-idx: pos + n + index? line
		reduce/into [start start-idx end end-idx] clear selects
	]

	move-caret: func [n [integer!] /event e [event!] /local left? idx][
		idx: pos + n
		if any [negative? idx idx > length? line][
			if all [event not e/shift?][clear selects]
			exit
		]

		if event [
			left?: n = -1
			if e/ctrl? [n: jump-word left?]
			either e/shift? [select-text n][clear selects]
		]
		pos: pos + n
		if negative? pos [pos: 0]
		if pos > length? line [pos: pos - n]
	]

	scroll-lines: func [delta /local n len cnt end offset][
		end: scroller/max-size - page-cnt + 1
		offset: scroller/position

		if any [
			all [offset = 1 delta > 0]
			all [zero? scroll-y offset = end delta < 0]
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
					scroll-y: delta * line-h
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

	update-scroller: func [delta /local n end][
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
		calc-top
		system/view/platform/redraw console
	]


	copy-selection: func [
		return: [logic!]
		/local start-n end-n start-idx end-idx len n str swap?
	][
		if any [empty? selects 3 > length? selects][				;-- empty selection, copy the whole line
			write-clipboard line
			return no
		]

		swap?: selects/1 > selects/3
		if swap? [move/part skip selects 2 selects 2]				;-- swap start and end
		set [start-n start-idx end-n end-idx] selects
		if all [start-n = end-n start-idx = end-idx][				;-- select nothing
			if swap? [move/part skip selects 2 selects 2]
			exit
		]

		clear clip-buf
		either start-n = end-n [
			len: end-idx - start-idx
			if len < 0 [start-idx: end-idx len: 0 - len]
			insert/part clip-buf at head pick lines start-n start-idx len
		][
			n: start-n
			until [
				str: head pick lines n
				case [
					n = start-n [
						append clip-buf at str start-idx
						append clip-buf #"^/"
					]
					n = end-n	[append/part clip-buf str end-idx - 1]
					true		[
						append clip-buf str
						append clip-buf #"^/"
					]
				]
				n: n + 1
				n > end-n
			]
		]
		if swap? [move/part skip selects 2 selects 2]
		write-clipboard clip-buf
		yes
	]

	paste: func [/resume /local nl? start end idx][
		delete-selected
		unless resume [clipboard: read-clipboard]
		if all [clipboard not empty? clipboard][
			start: clipboard
			end: find clipboard #"^M"
			either end [nl?: yes][nl?: no end: tail clipboard]
			insert/part skip line pos start end
			idx: pos
			pos: pos + offset? start end
			clipboard: skip end either end/2 = #"^/" [2][1]
			if nl? [
				caret/visible?: no
				insert history line
				unless resume [system/view/platform/exit-event-loop]
			]
			calc-top
			if empty? clipboard [
				clear selects
				clear redo-stack
				reduce/into [idx pos - idx] undo-stack
				system/view/platform/redraw console
			]
			paste-cnt: paste-cnt + 1
			if paste-cnt = 100 [
				system/view/platform/redraw console
				paste-cnt: 0
			]
		]
		not empty? clipboard
	]

	cut: func [][
		either copy-selection [
			delete-selected
		][
			clear line pos: 0
		]
	]

	undo: func [s1 [block!] s2 [block!] /local idx data s][
		if empty? s1 [exit]
		set [idx data] s1
		remove/part s1 2

		either integer? data [
			s: take/part skip line idx data
			reduce/into [idx s] s2
			pos: idx
		][									;-- else insert string? or char?
			insert skip line idx data
			data: either string? data [length? data][1]
			reduce/into [idx data] s2
			pos: idx + data
		]
		clear selects
	]

	do-completion: func [
		str		[string!]
		char	[char!]
		/local
			p-idx candidates str2
	][
		p-idx: index? str
		candidates: red-complete-input skip str pos yes
		case [
			empty? candidates [
				insert skip str pos char
				pos: pos + 1
				clear redo-stack
			]
			1 = length? candidates [
				clear head str
				pos: (index? candidates/1) - p-idx
				append str head candidates/1
				clear redo-stack
			]
			true [
				str2: insert form next candidates system/console/prompt
				poke lines length? lines str2
				calc-top
				add-line line
			]
		]
		clear selects
	]

	fetch-history: func [direction [word!] /local max str p][
		if zero? hist-idx [
			hist-line: at copy head line index? line
			hist-pos: pos
		]

		max: length? history
		case [
			direction = 'prev [hist-idx: hist-idx + 1]
			direction = 'next [hist-idx: hist-idx - 1]
		]
		if hist-idx < 0 [hist-idx: 0 exit]
		if hist-idx > max [hist-idx: max]
		either zero? hist-idx [str: hist-line p: hist-pos][
			str: pick history hist-idx
			p: length? str
			clear redo-stack
			clear selects
		]

		clear line
		append line str
		pos: p
		system/view/platform/redraw console
	]

	delete-selected: func [
		return: [logic!]
		/local start-n start-idx end-n end-idx n idx s del?
	][
		del?: no
		if all [
			not empty? selects
			2 < length? selects
		][
			set [start-n start-idx end-n end-idx] selects
			if all [start-n = length? lines start-n = end-n][
				n: absolute end-idx - start-idx
				idx: min start-idx end-idx
				idx: idx - index? line
				if negative? idx [
					n: n + idx
					idx: 0
				]
				if n > 0 [
					if start-idx < end-idx [pos: pos - n]
					s: copy/part skip line idx n
					reduce/into [idx s] undo-stack
					remove/part skip line idx n
					clear selects clear redo-stack
					del?: yes
				]
			]
		]
		del?
	]

	delete-text: func [
		ctrl?	[logic!]
		/backward
		/local n idx s del?
	][
		if delete-selected [exit]

		del?: no
		if all [not backward pos <> 0][
			if #" " = pick line pos [ctrl?: no]
			either ctrl? [
				idx: index? line
				start-idx: find/reverse/tail skip line pos #" "
				either all [start-idx (index? start-idx) > idx][
					n: pos + idx - index? start-idx
				][
					start-idx: line
					n: pos
				]
				pos: pos - n
				s: take/part start-idx n
				reduce/into [pos s] undo-stack
			][
				pos: pos - 1
				s: take skip line pos
				reduce/into [pos s] undo-stack
			]
			del?: yes
		]
		if all [backward pos < length? line][
			s: take skip line pos
			reduce/into [pos s] undo-stack
			del?: yes
		]
		if del? [clear selects clear redo-stack]
	]

	clean: func [][
		full?:		no
		top:		1
		scroll-y:	0
		line-y:		0
		line-cnt:	0
		screen-cnt: 0
		clear lines
		clear nlines
		clear heights
		clear selects
		add-line line
	]

	run-file: func [f [file!]][
		append clear line rejoin ["do " mold f]
		exit-ask-loop
	]

	press-key: func [event [event!] /local char ctrl? shift?][
		unless ask? [exit]
		if ime-open? [
			remove/part skip line ime-pos pos - ime-pos
			pos: ime-pos
			ime-open?: no
		]

		ctrl?: event/ctrl?
		shift?: event/shift?
		char: event/key
		#if config/OS = 'macOS [
		if find event/flags 'command [
			char: switch char [
				#"c" [#"^C"]
				#"v" [#"^V"]
				#"z" [#"^Z"]
				#"y" [#"^Y"]
				#default [char]
			]
		]]
		switch/default char [
			#"^M"	[exit-ask-loop]					;-- ENTER key
			#"^H"	[delete-text ctrl?]
			#"^-"	[unless empty? line [do-completion line char]]
			left	[move-caret/event -1 event]
			right	[move-caret/event 1 event]
			up		[either ctrl? [scroll-lines  1][fetch-history 'prev]]
			down	[either ctrl? [scroll-lines -1][fetch-history 'next]]
			insert	[if event/shift? [paste exit]]
			delete	[delete-text/backward ctrl?]
			#"^A" home	[if shift? [select-text 0 - pos] pos: 0]
			#"^E" end	[
				if shift? [select-text (length? line) - pos]
				pos: length? line
			]
			#"^C"	[copy-selection exit]
			#"^V"	[paste exit]
			#"^X"	[cut]
			#"^Z"	[undo undo-stack redo-stack]
			#"^Y"	[undo redo-stack undo-stack]
			#"^["	[exit-ask-loop/escape]
			#"^~"	[delete-text yes]				;-- Ctrl + Backspace
			#"^L"	[clean]
			#"^K"	[clear line pos: 0]				;-- delete the whole line
		][
			unless empty? selects [delete-selected]
			if all [char? char char > 31][
				insert skip line pos char
				reduce/into [pos 1] undo-stack
				clear redo-stack
				pos: pos + 1
			]
			clear selects
		]
		console/rate: 6
		if caret/rate [caret/rate: none caret/color: caret-clr]
		calc-top
		system/view/platform/redraw console
	]

	clear-stack: func [][
		clear undo-stack
		clear redo-stack
	]

	mark-selects: func [
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
		append styles as-pair start-idx len
		append styles select-bg
		if swap? [move/part skip selects 2 selects 2]
	]

	paint: func [/local str cmds y n h cnt delta num end styles][
		if empty? lines [exit]
		cmds: [pen color text 0x0 text-box]
		cmds/2: foreground
		cmds/4/x: pad-left
		cmds/5: box
		end: console/size/y
		y: scroll-y
		n: top
		num: line-cnt
		styles: box/data
		foreach str at lines top [
			box/text: head str
			if color? [highlight/add-styles head str clear styles theme]
			mark-selects styles n
			cmds/4/y: y
			system/view/platform/draw-face console cmds

			cnt: rich-text/line-count? box
			h: cnt * line-h
			poke heights n h
			line-cnt: line-cnt + cnt - pick nlines n
			poke nlines n cnt
			clear styles

			n: n + 1
			y: y + h
			if y > end [break]
		]
		line-y: y - h
		screen-cnt: y / line-h
		if screen-cnt > page-cnt [screen-cnt: page-cnt]
		update-caret
		update-scroller line-cnt - num
	]
]