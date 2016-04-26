Red/System [
	Title:   "Panel example"
	Author:  "Bruno Anselme"
	EMail:   "be.red@free.fr"
	File:    %panel-example.reds
	Rights:  "Copyright (c) 2013-2015 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Needs: {
		Red/System >= 0.3.1
		curses     >= 5.9 (Linux)
		pdcurses   >= 3.4 (Windows)
	}
	Purpose: {
		Minimalist panel demo.
	}
]

#include %../curses.reds
#include %../panel.reds

#switch OS [
	Windows   [ op-sys: "Windows" op-num: 1 ]
	MacOSX    [ op-sys: "MacOSX"  op-num: 2 ]
	#default  [ op-sys: "Linux"   op-num: 0 ]
]

with [ curses panel ] [
	wid: 0
	;-------------------------------------
	trace-key: func [
		key      [integer!]
		return:  [byte!]
		/local car nb-rows memcur
	][
		nb-rows: getmaxy screen
		memcur: curs-set 0
		car: #"^(00)"
		either (key and FFFFFF00h) = 0 [
			car: as byte! (key and 0000007Fh )
			mvprintw [ (nb-rows - 2)  3
				"Character pressed (int-hex-char) : %4d -   %02Xh - %c         "
				as integer! car
				as integer! car
				(either (car >= #" ") [ car ][ #" " ])
			]
		][
		if key <> FFFFFFFFh [
			mvprintw [ (nb-rows - 2)  3
				"Key pressed       (int-hex-name) : %4d - %04Xh - %s        "
				key
				key
				keyname key
			]
		]
		]
		refresh
		curs-set memcur
		return car
	]
	;-------------------------------------
	fill-window: func [
		win [window!]
		n   [integer!]
	][
		box win 0 0
		mvwprintw [ win 0  2 " Window %d " n ]
		mvwprintw [ win 1  2 "The Red/System panel Show" ]
		mvwprintw [ win 3  2 "Tab to browse through windows" ]
		mvwprintw [ win 4  2 "Use arrow keys to move" ]
		mvwprintw [ win 5  2 "Use Ctrl+arrow keys to resize" ]
		mvwprintw [ win 7  2 "Ctrl+Q to exit" ]
	]
	;-------------------------------------
	add-panel: func [
		n        [integer!]
		return:  [panel!]
		/local win pan
	][
		win: newwin 9 55 n (3 * n)
		pan: new-panel win
		fill-window win n
		pan
	]
	;-------------------------------------
	resize-panel: func [
		n        [integer!]
		addrow   [integer!]
		addcol   [integer!]
		/local row col nbrows nbcols maxrow maxcol win new-win
	][
		win: panel-window panels/n
		row: getbegy win
		col: getbegx win
		nbrows: getmaxy win
		nbcols: getmaxx win
		maxrow: getmaxy screen
		maxcol: getmaxx screen
		nbrows: addrow + nbrows
		nbcols: addcol + nbcols
		; Check screen limits
		if nbrows < 2 [ nbrows: 2 ]
		if (row + nbrows) > maxrow[ nbrows: maxrow - row ]
		if nbcols < 2 [ nbcols: 2 ]
		if (col + nbcols) > maxcol[ nbcols: maxcol - col ]
		new-win: newwin nbrows nbcols row col
		replace-panel panels/n new-win
		fill-window new-win n
		delwin win
	]
	;-------------------------------------
	translate-panel: func [
		n        [integer!]
		addrow   [integer!]
		addcol   [integer!]
		/local row col nbrows nbcols maxrow maxcol win
	][
		win: panel-window panels/n
		row: getbegy win
		col: getbegx win
		nbrows: getmaxy win
		nbcols: getmaxx win
		maxrow: getmaxy screen
		maxcol: getmaxx screen
		row: row + addrow
		col: col + addcol
		; Check screen limits
		if row < 0 [ row: 0 ]
		if (row + nbrows) > maxrow[ row: maxrow - nbrows ]
		if col < 0 [ col: 0 ]
		if (col + nbcols) > maxcol[ col: maxcol - nbcols ]
		move-panel panels/n row col
	]
	;-------------------------------------
	screen: init-screen

	nbpanel: 5
	panel-array: allocate (nbpanel * size? integer!)	;-- Allocate memory for panel pointers
	panels: as  [pointer! [integer!]] panel-array

	i: 1
	until [
		panels/i: add-panel i
		i: i + 1
		i > nbpanel
	]
	key: 0
	car: #"^(00)"
	i: nbpanel
	update-panels
	doupdate
	until [
		key: getch
		car: trace-key key
		switch key [
			9  [										;-- Tab key
				i: i + 1
				if i > nbpanel [ i: 1 ]
				top-panel panels/i
			]
			KEY_BTAB [									;-- Backtab key
				i: i - 1
				if i < 1 [ i: nbpanel ]
				top-panel panels/i
			]
			KEY_DOWN     [ translate-panel i 1 0  ]
			KEY_UP       [ translate-panel i -1 0 ]
			KEY_LEFT     [ translate-panel i 0 -1 ]
			KEY_RIGHT    [ translate-panel i 0 1  ]
			CTL_DOWN     [ resize-panel i 1 0  ]
			CTL_UP       [ resize-panel i -1 0 ]
			CTL_LEFT     [ resize-panel i 0 -1 ]
			CTL_RIGHT    [ resize-panel i 0 1  ]
			default [  ]
		]
		update-panels
		doupdate
		all [ ((key and A_ATTRIBUTES) = 0) (car = #"^Q") ]
	]
	endwin
	free panel-array

	if op-num = 1 [ print [ lf lf ] ]					;-- Windows console needs to scroll
	print [ "That's all folks..." lf ]
]