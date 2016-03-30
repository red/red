Red/System [
	Title:   "Curses example: display Red and curses information"
	Author:  "Bruno Anselme"
	EMail:   "be.red@free.fr"
	File:    %curses-example.reds
	Rights:  "Copyright (c) 2013-2015 Bruno Anselme"
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Needs: {
		Red/System >= 0.3.1
		%curses.reds
	}
	Purpose: {
		Display Red and curses information.
		Test some terminal features.
	}
]

#include %../curses.reds

#switch OS [
	Windows   [ op-sys: "Windows" op-num: 1 ]
	MacOSX    [ op-sys: "MacOSX"  op-num: 2 ]
	#default  [ op-sys: "Linux"   op-num: 0 ]
]

with curses [
	;-------------------------------------
	show-attr: func [   								;-- Print one attribute line, returns next line number
		wid     [window!]
		line    [integer!]
		attr    [integer!]
		mesg    [c-string!]
		return: [integer!]
	][
		mvwprintw [ wid line 2 mesg ]
		wmove wid line 25
		wprintw-attr wid attr "This is a Red's world"
		line + 1
	]
	;-------------------------------------
	show-all-attr: func [								;-- Create the attributes window
		return:  [window!]
		/local   win line
	][
		win: newwin 10 50 4 15
		box win 0 0
		line: 0
		mvwprintw [ win line 3 " Characters attibutes " ]
		line: line + 1
		line: show-attr win line A_BOLD "Bright or bold"
		line: show-attr win line A_REVERSE "Reverse"
		line: show-attr win line A_BLINK "Blink"
		line: show-attr win line A_UNDERLINE "Underline"
		line: show-attr win line A_INVIS "Invisible"
		line: show-attr win line A_DIM "Half bright"
		line: show-attr win line (A_BOLD or A_REVERSE or A_BLINK) "Bold+reverse+blink"
		line: show-attr win line (A_BOLD or A_UNDERLINE) "Bold+underline"
		win
	]
	;-------------------------------------
	init-color-pairs: func [							;--  Initialise 64 color-pairs with 8 basic colors
		/local id colb colf
	][
		colb: COLOR_BLACK
		colf: COLOR_BLACK
		until [
			colf: COLOR_BLACK
			until [
				id: (8 * colb) + colf + 1
				init-pair id colf colb
				colf: colf + 1
				colf > COLOR_WHITE
			]
			colb: colb + 1
			colb > COLOR_WHITE
		]
	]
	;-------------------------------------
	show-color: func [   								;-- Print the mesg with a calculated color pair value
		wid     [window!]
		line    [integer!]
		col     [integer!]
		mesg    [c-string!]
		return: [integer!]
		/local id
	][
		id: (8 * col) + line
		wattron wid color-pair id
		mvwprintw [ wid line (6 * col + 1) mesg ]
		wattroff wid color-pair id
		line + 1
	]
	;-------------------------------------
	show-all-colors: func [								;-- Create the colors window
		return:  [window!]
		/local win line column colb colf
	][
		win: newwin 10 50 4 15
		wcolor-set win 5
		box win 0 0
		line: 0
		mvwprintw [ win line 3 " Colors " ]
		colb: COLOR_BLACK
		colf: COLOR_BLACK
		column: 0
		until [
			line: 1
			colf: COLOR_BLACK
			until [
				line: show-color win line column " Red "
				colf: colf + 1
				colf > COLOR_WHITE
			]
			column: column + 1
			colb: colb + 1
			colb > COLOR_WHITE
		]
		win
	]
	;-------------------------------------
	show-term-inf: func [								;-- Create the terminal information window
		return:  [window!]
		/local win r g b col
	][
		win: newwin 13 ((getmaxx screen) - 10) 2 6
		r: 0 g: 0 b: 0
		col: COLOR_YELLOW
		box win 0 0
		mvwprintw [ win 0 3 " Terminal informations " ]
		mvwprintw [ win 1  2 "Terminal name    : %s" longname ]
		mvwprintw [ win 2  2 "Curses version   : %s" version ]
		mvwprintw [ win 3  2 "Application      : %s" system/args-list/item ]
		mvwprintw [ win 4  2 "OS               : %s" op-sys ]
		mvwprintw [ win 5  2 "Screen size      : %dx%d" getmaxx screen getmaxy screen ]
		mvwprintw [ win 6  2 "UTF-8            : %s" either UTF-8 [ "true" ][ "false" ]]
		win
	]
	;-------------------------------------
	show-features: func [								;-- Create the terminal information window
		return:  [window!]
		/local car key
	][
		win-demo: newwin 13 ((getmaxx screen) - 10) 2 6
		box win-demo 0 0
		mvwprintw [ win-demo 0 3 " Terminal features  (Esc to quit)" ]
		mvwprintw [ win-demo 1  2 "Has colors        : %s" either has-colors [ "true" ][ "false" ]]
		mvwprintw [ win-demo 2  2 "Can change color  : %s" either can-change-color [ "true" ][ "false" ]]
		mvwprintw [ win-demo 3  2 "Has Ins-Del char  : %s" either has-ic [ "true" ][ "false" ]]
		mvwprintw [ win-demo 4  2 "Has Ins-Del line  : %s" either has-il [ "true" ][ "false" ]]

		mvwprintw [ win-demo 6  2 "B to ring bell    : (if avaliable)" ]
		mvwprintw [ win-demo 7  2 "F to flash screen : (if avaliable)" ]
		mvwprintw [ win-demo 9  2 "Esc to quit" ]
		wrefresh win-demo
		until [
			key: getch
			car: trace-key key
			car: car and #"^(DF)"						;-- uppercase
			if key <> FFFFFFFFh [
				switch car [
				#"B"    [ beep  refresh ]
				#"F"    [ flash refresh ]
				default [ ]
				]
			]
			all [ ((key and A_ATTRIBUTES) = 0) (car = #"^(1B)") ]
		]
		del-win-demo
		touchwin win-menu
		return 0
	]
	;-------------------------------------
	show-input: func [									;-- Create the test input window
		return:  [window!]
		/local win str
	][
		win: newwin 10 50 4 15
		wcolor-set win 6
		box win 0 0
		mvwprintw [ win 0 3 " Test string input " ]
		mvwprintw [ win 2  2 "Write here : " ]
		str: make-c-string 1001
		wmove win 2 15
		wrefresh win
		curs-set 1
		echo-on
		nocbreak
		wgetstr win str
		echo-off
		raw
		mvwprintw [ win 5  2 "You wrote  : %s " str ]
		curs-set 0
		win
	]
	;-------------------------------------
	show-boxes: func [									;-- Create the boxes window
		return:  [window!]
		/local win
	][
		win: newwin 10 50 4 15
		wborder win #"|" #"+" #"-" #"=" #"/" #"\" #"\" #"/"
		mvwprintw [ win 0 3  " Border characters " ]
		mvwprintw [ win 2  4 "Border drawn with user defined characters" ]
		mvwhline win 3 4 (as integer! #"~") 41
		win
	]
	;-------------------------------------
	trace-key: func [
		key      [integer!]
		return:  [byte!]
		/local car nb-rows memcur
	][
		nb-rows: getmaxy screen
		memcur: curs-set 0
		car: 0
		either (key and FFFFFF00h) = 0 [
		car: key and 000000FFh
		mvprintw [ (nb-rows - 2)  3
					"Character pressed (int-hex-char) : %4d -   %02Xh -            "
					car
					car
				]
		mvaddch (nb-rows - 2)  53 car
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
		wrefresh win-demo
		curs-set memcur
		return as byte! car
	]
	;-------------------------------------
	show-edit: func [									;-- Create the test input window
		return:  [window!]
		/local  key car wx wy
	][
		wy: 3
		wx: 8
		win-demo: newwin 15 50 wy wx
		key: 0
		wbkgdset win-demo A_REVERSE
		werase win-demo
		mvwprintw [ win-demo 0 3 " Mini screen editor (Esc to quit)" ]
		mvwprintw [ win-demo 2  2 "Move the cursor with the arrow keys" ]
		mvwprintw [ win-demo 3  2 "Try Delete and Insert key" ]
		mvwprintw [ win-demo 4  2 "Insert/delete lines with Page Up/Down" ]
		mvwprintw [ win-demo 5  2 "Input text anywhere" ]
		mvwprintw [ win-demo 7  2 "Esc to quit Screen Editor" ]
		wmove win-demo 1 2
		if op-num = 1 [ move wy (wx + 2) ]				;-- Bugged Windows cursor management
		curs-set 1
		wrefresh win-demo
		until [
		key: getch
		car: trace-key key
		if key <> FFFFFFFFh [
			switch key [
			0000007Fh   [ wmove win-demo getcury win-demo ((getcurx win-demo) - 1) wdelch win-demo ]
			KEY_DC      [ wdelch win-demo ]
			KEY_IC      [ winsch win-demo 32 ]
			KEY_NPAGE   [ wdeleteln win-demo ]
			KEY_PPAGE   [ winsertln win-demo ]
			KEY_DOWN    [ wmove win-demo ((getcury win-demo) + 1) getcurx win-demo ]
			KEY_UP      [ wmove win-demo ((getcury win-demo) - 1) getcurx win-demo ]
			KEY_LEFT    [ wmove win-demo getcury win-demo ((getcurx win-demo) - 1) ]
			KEY_RIGHT   [ wmove win-demo getcury win-demo ((getcurx win-demo) + 1) ]
			default     [
				if ((key and A_ATTRIBUTES) = 0) [
				waddch win-demo as integer! car
				]
			]
			]
			if op-num = 1 [ move (wy - 1 + getcury win-demo) (wx + getcurx win-demo) ]	;-- Bugged Windows cursor management
			wrefresh win-demo
		]
		all [ ((key and A_ATTRIBUTES) = 0) (car = #"^(1B)") ]
		]
		curs-set 0
		wbkgdset win-demo A_NORMAL
		del-win-demo
		return 0
	]
	;-------------------------------------
	draw-charset: func [
		win      [window!]
		mask     [integer!]
		col      [integer!]
		/local car [integer!] row limit
	][
		row: 3
		wmove win row col
		car: 32
		either UTF-8 [ limit: 127 ][ limit: 255 ]
		until [
		waddch win (mask or car)
		car: car + 1
		if (car % 32) = 0 [
			row: row + 1
			wmove win row col
		]
		car = limit
		]
	]
	;-------------------------------------
	show-charset: func [								;-- Create the characters window
		return:  [window!]
		/local win
	][
		win: newwin 18 67 1 1
		wcolor-set win 6
		box win 0 0
		mvwprintw [ win 0 3 " Characters set " ]
		mvwprintw [ win 1 10 "Normal charset" ]
		draw-charset win A_NORMAL      1
		mvwprintw [ win 1 44 "Alt charset" ]
		draw-charset win A_ALTCHARSET  34
		if UTF-8 [
		mvwprintw-attr win 12 5 (A_REVERSE or A_BLINK) " Warning "
		wprintw [ win " : UTF-8 charset" ]
		mvwprintw [ win 13 17 "Only 7 bits chars are displayed" ]
		]
		return win
	]
	;-------------------------------------
	show-menu: func [									;-- Create the menu window
		return:  [window!]
		/local win
	][
		win: newwin 12 35 1 1
		wcolor-set win 7
		box win 0 0
		mvwprintw [ win  0 3 " Menu " ]
		mvwprintw [ win  1 2 "1 Terminal infos" ]
		mvwprintw [ win  2 2 "2 Check characters attributes" ]
		mvwprintw [ win  3 2 "3 Check colors" ]
		mvwprintw [ win  4 2 "4 Border characters" ]
		mvwprintw [ win  5 2 "5 Check terminal features" ]
		mvwprintw [ win  6 2 "6 Mini screen editor" ]
		mvwprintw [ win  7 2 "7 Test string input" ]
		mvwprintw [ win  8 2 "8 Display charset" ]
	;    mvwprintw [ win  9 2 "Accents éèàùüâô" ]
		mvwprintw [ win 10 2 "Ctrl+Q to exit" ]
		return win
	]
	;-------------------------------------
	del-win-demo: func [								;-- delete information window
	][
		if win-demo <> 0 [
		werase win-demo
		wrefresh win-demo
		delwin win-demo
		win-demo: 0
		touchwin win-menu
		]
	]
	;-------------------------------------
	main-loop: func [
		/local row col key car cc
	][
		key: 0
		car: #"^(00)"
		refresh
		wrefresh win-menu
		until [
			key: getch
			car: trace-key key
			if car <> #"^(00)" [
				del-win-demo
				refresh
				switch car [
					#"1"      [ win-demo: show-term-inf ]
					#"2"      [ win-demo: show-all-attr ]
					#"3"      [ win-demo: show-all-colors ]
					#"4"      [ win-demo: show-boxes ]
					#"5"      [ win-demo: show-features ]
					#"6"      [ win-demo: show-edit ]
					#"7"      [ win-demo: show-input ]
					#"8"      [ win-demo: show-charset ]
					default [  ]
				]
				wrefresh win-menu
				wrefresh win-demo
			]
			all [ ((key and A_ATTRIBUTES) = 0) (car = #"^Q") ]
		]
	]
	;-------------------------------------
	init-menu-bar: func [  								;-- callback function for ripoffline
		[cdecl]
		wid      [integer!]
		cols     [integer!]
	;    return:  [integer!]
	][
		menu-bar: wid
	;    return 0
	]
	;-------------------------------------
	init-status-bar: func [  							;-- callback function for ripoffline
		[cdecl]
		wid      [integer!]
		cols     [integer!]
	;    return:  [integer!]
	][
		status-bar: wid
	;    return 0
	]
	;-------------------------------------
	menu-bar: 0
	status-bar: 0
	ripoffline  1 as integer! :init-menu-bar
	ripoffline -1 as integer! :init-status-bar
	screen: init-screen
	init-color-pairs
	color-set 3

	wcolor-set menu-bar 49
	werase menu-bar
	wcolor-set status-bar 25
	werase status-bar
	wprintw  [ menu-bar "Line reserved for Menu bar" ]
	wnoutrefresh menu-bar
	either op-num = 1 [
		wprintw  [ status-bar "Line reserved for Status bar" ]
	][
		wprintw  [ status-bar curses/locale ]
	]
	wnoutrefresh status-bar

	box screen 0 0
	mvprintw [ 0 2 " The Red/System Curses Show " ]
	win-demo: 0
	win-menu: show-menu
	main-loop
	endwin
	if op-num = 1 [ print [ lf lf ] ]  					;-- Windows console needs to scroll
	print [ "That's all folks..." lf ]
]