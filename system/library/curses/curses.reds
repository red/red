Red/System [
	Title:   "Red/System curses Binding"
	Author:  "Bruno Anselme"
	EMail:   "be.red@free.fr"
	File:    %curses.reds
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
	References: {
		Linux: http://pubs.opengroup.org/onlinepubs/7908799/xcurses/curses.h.html
		Windows: Public Domain Curses for windows : http://sourceforge.net/projects/pdcurses/files/
		Version : pdc34dllw.zip
	}
]

curses: context [
	#define __LC_CTYPE 0
	#define __LC_ALL   6
	#import [
		LIBC-file cdecl [
			setlocale: "setlocale" [
				category  [integer!]
				locale    [c-string!]
				return:   [c-string!]
			]
			find-string: "strstr" [						;-- Return first occurence of substring in string or null if not found
				string    [c-string!]
				substring [c-string!]
				return:   [c-string!]
			]
		]
	]

	#define window!  integer!
	#define sysfile! integer!

	#switch OS [
		Windows   [
			#include %curses-win32.reds
			#define curses-library "pdcurses.dll"
		]
		MacOSX    [
			#include %curses-macosx.reds				;-- TODO: missing file, to be written with macosx curses.h
			#define curses-library "libncursesw.5.dylib";-- TODO: check this
		]
		#default  [
			#include %curses-linux.reds
			#define curses-library "libncursesw.so.5"
		]
	]

	#import [ curses-library cdecl [
		version: "curses_version" [						;-- Return curses library version.
			return:   [c-string!]
		]

		;-- Screen management

		_initscr: "initscr" [   						;-- Start curses mode.
			return:   [window!]
		]
		endwin: "endwin" [      						;-- End curses mode.
			return:   [integer!]
		]
		wrefresh: "wrefresh" [  						;-- Print it on the real screen.
			wid       [window!]
			return:   [integer!]
		]
		wnoutrefresh: "wnoutrefresh" [					;-- Mark window to be refreshed
			wid       [window!]
			return:   [integer!]
		]
		doupdate: "doupdate" [  						;-- Update terminal.
			return:   [integer!]
		]
		refresh: "refresh" [    						;-- Print it on the real screen.
			return:   [integer!]
		]
		cbreak: "cbreak" [      						;-- Sets current terminal input mode to cbreak mode and overrides a call to raw.
			return:   [integer!]
		]
		nocbreak: "nocbreak" [  						;-- Sets current terminal input mode to Cooked Mode without changing the state of ISIG and IXON.
			return:   [integer!]
		]
		raw: "raw" [            						;-- Sets current terminal input mode to Raw Mode.
			return:   [integer!]
		]
		noraw: "noraw" [        						;-- Sets current terminal input mode to Cooked Mode and sets the ISIG and IXON flags.
			return:   [integer!]
		]
		echo-on: "echo" [       						;-- Enable terminal echo.
			return:   [integer!]
		]
		echo-off: "noecho" [    						;-- Disable terminal echo.
			return:   [integer!]
		]

		;-- Window management

		newwin: "newwin" [								;-- Create a new window.
			nlines    [integer!]
			ncols     [integer!]
			begin_y   [integer!]
			begin_x   [integer!]
			return:   [window!]
		]
		subwin: "subwin" [								;-- Create a subwindow  with absolute coordinate.
			orig      [window!]
			nlines    [integer!]
			ncols     [integer!]
			begin_y   [integer!]
			begin_x   [integer!]
			return:   [window!]
		]
		derwin: "derwin" [								;-- Create a subwindow with relative coordinate.
			orig      [window!]
			nlines    [integer!]
			ncols     [integer!]
			begin_y   [integer!]
			begin_x   [integer!]
			return:   [window!]
		]
		mvderwin: "mvderwin" [							;-- Define window coordinate transformation.
			wid       [window!]
			par_y     [integer!]
			par_x     [integer!]
			return:   [integer!]
		]
		dupwin: "dupwin" [								;-- Duplicate a window.
			wid       [window!]
			return:   [window!]
		]
		delwin: "delwin" [								;-- Delete a window.
			wid       [window!]
			return:   [integer!]
		]
		touchwin: "touchwin" [							;-- Touch a window (mark it to refresh).
			wid       [window!]
			return:   [integer!]
		]
		untouchwin: "untouchwin" [						;-- Untouch a window (unmark it to refresh).
			wid       [window!]
			return:   [integer!]
		]
		clear: "clear" [        						;-- Clear main screen
			return:   [integer!]
		]
		wclear: "wclear" [      						;-- Clear the specified window
			wid       [window!]
			return:   [integer!]
		]
		erase: "erase" [        						;-- Erase main screen.
			return:   [integer!]
		]
		werase: "werase" [      						;-- Erase the specified window.
			wid       [window!]
			return:   [integer!]
		]
		clearok: "clearok" [    						;-- Enable or disable screen clearing during refresh.
			wid       [window!]
			bf        [logic!]
			return:   [integer!]
		]
		idlok: "idlok" [        						;-- Enable or disable use of terminal insert and delete line features.
			wid       [window!]
			bf        [logic!]
			return:   [integer!]
		]
		leaveok: "leaveok" [    						;-- Controls the cursor position after a refresh operation.
			wid       [window!]
			bf        [logic!]
			return:   [integer!]
		]
		scrollok: "scrollok" [  						;-- Enable or disable scrolling on a window .
			wid       [window!]
			bf        [logic!]
			return:   [integer!]
		]
		putwin: "putwin" [      						;-- Dump window to a file.
			wid       [window!]
			f         [sysfile!]
			return:   [integer!]
		]
		getwin: "getwin" [      						;-- Reads window-related data stored in the file by putwin.
			f         [sysfile!]
			return:   [window!]
		]
		mvwin: "mvwin" [        						;-- Moves the specified window so that its origin is at position row col. Fails if it passes the edge of the screen.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			return:   [integer!]
		]

		;** Cursor management

		move: "move" [									;-- Move cursor to screen location.
			row       [integer!]
			col       [integer!]
			return:   [integer!]
		]
		wmove: "wmove" [								;-- Move cursor to window location.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			return:   [integer!]
		]
		getbegx: "getbegx" [							;-- Returns the absolute x screen coordinates of the specified window's.
			wid       [window!]
			return:   [integer!]
		]
		getbegy: "getbegy" [							;-- Returns the absolute y screen coordinates of the specified window's.
			wid       [window!]
			return:   [integer!]
		]
		getmaxx: "getmaxx" [							;-- Get window width.
			wid       [window!]
			return:   [integer!]
		]
		getmaxy: "getmaxy" [							;-- Get window height.
			wid       [window!]
			return:   [integer!]
		]
		getparx: "getparx" [							;-- Returns the x coordinate of the window's origin relative to its parent window. Otherwise, -1.
			wid       [window!]
			return:   [integer!]
		]
		getpary: "getpary" [							;-- Returns the y coordinate of the window's origin relative to its parent window. Otherwise, -1.
			wid       [window!]
			return:   [integer!]
		]
		getcurx: "getcurx" [							;-- Get cursor column location.
			wid       [window!]
			return:   [integer!]
		]
		getcury: "getcury" [							;-- Get cursor row location.
			wid       [window!]
			return:   [integer!]
		]
		curs-set: "curs_set" [							;-- Sets the appearance of the cursor based on the value of vis (0,1,2)
			vis       [integer!]
			return:   [integer!]
		]
		mvcur: "mvcur" [								;-- Output cursor movement commands to the terminal.
			oldrow    [integer!]
			oldcol    [integer!]
			newrow    [integer!]
			newcol    [integer!]
			return:   [integer!]
		]

		;-- Keyboard input

		wgetch: "wgetch" [								;-- Wait for user input.
			wid       [window!]
			return:   [integer!]
		]
		mvgetch: "mvgetch" [							;-- Move and wait for user input.
			row       [integer!]
			col       [integer!]
			return:   [integer!]
		]
		mvwgetch: "mvwgetch" [							;-- Move and wait for user input.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			return:   [integer!]
		]
		getnstr: "getnstr" [							;-- Get almost n bytes from input.
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		getstr: "getstr" [								;-- Get a string from the terminal.
			str       [c-string!]
			return:   [integer!]
		]
		mvgetnstr: "mvgetnstr" [						;-- Move and get almost n bytes from input.
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		mvgetstr: "mvgetstr" [							;-- Move and get a string from the terminal.
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			return:   [integer!]
		]
		mvwgetnstr: "mvwgetnstr" [						;-- Move and get almost n bytes from input.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		mvwgetstr: "mvwgetstr" [						;-- Move and get a string from input.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			return:   [integer!]
		]
		wgetnstr: "wgetnstr" [							;-- Get almost n bytes from input.
			wid       [window!]
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		wgetstr: "wgetstr" [							;-- Get a string from input.
			wid       [window!]
			str       [c-string!]
			return:   [integer!]
		]
		keyname: "keyname" [							;-- Get the name of a key.
			key       [integer!]
			return:   [c-string!]
		]
		keypad: "keypad" [								;-- Controls keypad translation. Enable/disable abbreviation of function keys.
			wid       [window!]
			bf        [logic!]
			return:   [integer!]
		]
		halfdelay: "halfdelay" [						;-- Sets the input mode for the current window to Half-Delay Mode and specifies tenths of seconds.
			tenths    [integer!]
			return:   [integer!]
		]
		nodelay: "nodelay" [							;-- Enable or disable block during read.
			wid       [window!]
			bf        [logic!]
			return:   [integer!]
		]
		flushinp: "flushinp" [							;-- Flushes any characters in the input buffer associated with the current screen.
			return:   [integer!]
		]

		;-- Print to screen

		echochar: "echochar" [  						;-- Echo wide-character and immediately refresh the screen.
			ch        [integer!]
			return:   [integer!]
		]
		wechochar: "wechochar" [						;-- Echo wide-character and immediately refresh the window.
			wid       [window!]
			ch        [integer!]
			return:   [integer!]
		]
		addch: "addch" [        						;-- Put wide-character from current cursor position inside stdscr.
			ch        [integer!]
			return:   [integer!]
		]
		addnstr: "addnstr" [    						;-- Put nb characters from string from current cursor position inside stdsrc.
			str       [c-string!]
			nb        [integer!]
			return:   [integer!]
		]
		addstr: "addstr" [      						;-- Put a string from current cursor position into stdsrc.
			str       [c-string!]
			return:   [integer!]
		]
		waddch: "waddch" [      						;-- Put wide-character from current cursor position into window.
			wid       [window!]
			ch        [integer!]
			return:   [integer!]
		]
		mvaddch: "mvaddch" [    						;-- Put character from specified current cursor position inside stdscr.
			row       [integer!]
			col       [integer!]
			ch        [integer!]
			return:   [integer!]
		]
		mvwaddch: "mvwaddch" [  						;-- Put character from specified current cursor position inside window.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			ch        [integer!]
			return:   [integer!]
		]
		mvaddnstr: "mvaddnstr" [						;-- Add n characters from a string to screen and advance cursor.
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		mvaddstr: "mvaddstr" [							;-- Add a string to screen and advance cursor.
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			return:   [integer!]
		]
		mvwaddnstr: "mvwaddnstr" [						;-- Move and add n characters from a string to a window and advance cursor.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		mvwaddstr: "mvwaddstr" [						;-- Move and add a string to a window and advance cursor.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			return:   [integer!]
		]
		waddnstr: "waddnstr" [  						;-- Add n characters from a string to a window and advance cursor.
			wid       [window!]
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		waddstr: "waddstr" [    						;-- Add a string to a window and advance cursor.
			wid       [window!]
			str       [c-string!]
			return:   [integer!]
		]
		insch: "insch" [        						;-- Insert a single-byte character and rendition into screen.
			ch        [integer!]
			return:   [integer!]
		]
		winsch: "winsch" [      						;-- Insert a single-byte character and rendition into a window.
			wid       [window!]
			ch        [integer!]
			return:   [integer!]
		]
		mvinsch: "mvinsch" [    						;-- Move to position and insert a single-byte character and rendition into screen.
			row       [integer!]
			col       [integer!]
			ch        [integer!]
			return:   [integer!]
		]
		mvwinsch: "mvwinsch" [  						;-- Move to position and insert a single-byte character and rendition into a window.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			ch        [integer!]
			return:   [integer!]
		]
		delch: "delch" [        						;-- Delete character from current cursor position inside stdscr.
			return:   [integer!]
		]
		wdelch: "wdelch" [      						;-- Delete character from current cursor position inside window.
			wid       [window!]
			return:   [integer!]
		]
		mvdelch: "mvdelch" [    						;-- Delete character from specified current cursor position inside stdscr.
			row       [integer!]
			col       [integer!]
			return:   [integer!]
		]
		mvwdelch: "mvwdelch" [  						;-- Delete character from specified current cursor position inside window.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			return:   [integer!]
		]
		deleteln: "deleteln" [  						;-- Delete the line containing the cursor.
			return:   [integer!]
		]
		wdeleteln: "wdeleteln" [						;-- Delete the line containing the cursor.
			wid       [window!]
			return:   [integer!]
		]
		insertln: "insertln" [  						;-- Insert a blank line before the current line.
			return:   [integer!]
		]
		winsertln: "winsertln" [						;-- Insert a blank line before the current line.
			wid       [window!]
			return:   [integer!]
		]
		scrl: "scrl" [          						;-- Scroll the current window. If n is positive, the window scrolls n lines toward the first line. Otherwise, the window scrolls -n lines toward the last line.
			n         [integer!]
			return:   [integer!]
		]
		wscrl: "wscrl" [        						;-- Scroll the specified window. If n is positive, the window scrolls n lines toward the first line. Otherwise, the window scrolls -n lines toward the last line.
			wid       [window!]
			n         [integer!]
			return:   [integer!]
		]
		scroll: "scroll" [								;-- Scrolls win one line in the direction of the first line.
			wid       [window!]
			return:   [integer!]
		]

		wprintw: "wprintw" [    						;-- Print from current cursor location inside a window.
			[variadic]
			; wid     [window!]
			; format  [c-string!]
			; ...
			return:   [integer!]
		]
		printw: "printw" [      						;-- Print from current cursor location inside stdscr.
			[variadic]
			; format  [c-string!]
			; ...
			return:   [integer!]
		]
		mvwprintw: "mvwprintw" [						;-- Print from specified cursor location inside a window.
			[variadic]
			; wid     [window!]
			; row     [integer!]
			; col     [integer!]
			; format  [c-string!]
			; ...
			return:   [integer!]
		]
		mvprintw: "mvprintw" [							;-- Print from specified cursor location inside stdscr.
			[variadic]
			; row     [integer!]
			; col     [integer!]
			; format  [c-string!]
			; ...
			return:   [integer!]
		]
		mvscanw: "mvscanw" [							;-- Convert formatted input from a window.
			[variadic]
			; row     [integer!]
			; col     [integer!]
			; format  [c-string!]
			; ...
			return:   [integer!]
		]
		mvwscanw: "mvwscanw" [							;-- Convert formatted input from a window.
			[variadic]
			; wid       [window!]
			; row     [integer!]
			; col     [integer!]
			; format  [c-string!]
			; ...
			return:   [integer!]
		]
		scanw: "scanw" [								;-- Convert formatted input from a window.
			[variadic]
			; format  [c-string!]
			; ...
			return:   [integer!]
		]
		wscanw: "wscanw" [								;-- Convert formatted input from a window.
			[variadic]
			; wid       [window!]
			; format  [c-string!]
			; ...
			return:   [integer!]
		]
		nl-on: "nl" [         							;-- Enable newline translation.
			return:   [integer!]
		]
		nl-off: "nonl" [      							;-- Disable newline translation.
			return:   [integer!]
		]
		clrtoeol: "clrtoeol" [							;-- Erase the current line from the cursor to the end of the line inside stdscr
			return:   [integer!]
		]
		wclrtoeol: "wclrtoeol" [						;-- Erase the current line from the cursor to the end of the line inside the specified window
			wid       [window!]
			return:   [integer!]
		]
		clrtobot: "clrtobot" [  						;-- Clear all lines following the cursor.
			return:   [integer!]
		]
		wclrtobot: "wclrtobot" [						;-- Clear all lines following the cursor.
			wid       [window!]
			return:   [integer!]
		]
		border: "border" [  							;-- Draw borders with specified chars.
			wid       [window!]
			left      [byte!]
			right     [byte!]
			top       [byte!]
			bot       [byte!]
			topl      [byte!]
			topr      [byte!]
			botl      [byte!]
			botr      [byte!]
			return:   [integer!]
		]
		box: "box" [          							;-- Draw borders from single-byte characters and renditions.
			wid       [window!]
			verch     [integer!]
			horch     [integer!]
			return:   [integer!]
		]
		wborder: "wborder" [  							;-- Draw window borders with specified chars.
			wid       [window!]
			left      [byte!]
			right     [byte!]
			top       [byte!]
			bot       [byte!]
			topl      [byte!]
			topr      [byte!]
			botl      [byte!]
			botr      [byte!]
			return:   [integer!]
		]
		hline: "hline" [        						;-- Draw a n characters line proceeding toward the last column of the same line.
			ch        [integer!]
			n         [integer!]
			return:   [integer!]
		]
		mvhline: "mvhline" [    						;-- Move and draw a n characters line proceeding toward the last column of the same line.
			row       [integer!]
			col       [integer!]
			ch        [integer!]
			n         [integer!]
			return:   [integer!]
		]
		mvwhline: "mvwhline" [  						;-- Move and draw a n characters line proceeding toward the last column of the same line in a window.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			ch        [integer!]
			n         [integer!]
			return:   [integer!]
		]
		whline: "mvwhline" [    						;-- Draw a n characters line proceeding toward the last column of the same line in a window.
			wid       [window!]
			ch        [integer!]
			n         [integer!]
			return:   [integer!]
		]
		vline: "vline" [        						;-- Draw a n characters column proceeding toward the last line of the same column
			ch        [integer!]
			n         [integer!]
			return:   [integer!]
		]
		mvvline: "mvvline" [    						;-- Move and draw a n characters column proceeding toward the last line of the same column
			row       [integer!]
			col       [integer!]
			ch        [integer!]
			n         [integer!]
			return:   [integer!]
		]
		mvwvline: "mvwvline" [  						;-- Move and draw a n characters column proceeding toward the last line of the same column in a window.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			ch        [integer!]
			n         [integer!]
			return:   [integer!]
		]
		wvline: "mvwvline" [    						;-- Draw a n characters column proceeding toward the last line of the same column in a window.
			wid       [window!]
			ch        [integer!]
			n         [integer!]
			return:   [integer!]
		]
		beep: "beep" [          						;-- Sounds the audible alarm on the terminal if possible.
			return:   [integer!]
		]
		erasechar: "erasechar" [						;-- Returns the current erase character.
			return:   [integer!]
		]
		flash: "flash" [        						;-- Flashes the screen, or if that is not possible, it sounds the audible alarm on the terminal. If neither signal is possible, nothing happens.
			return:   [integer!]
		]
		insdelln: "insdelln" [  						;-- If n is positive, insert n lines, else delete lines
			nb        [integer!]
			return:   [integer!]
		]
		winsdelln: "winsdelln" [						;-- If n is positive, insert n lines, else delete lines
			wid       [window!]
			nb        [integer!]
			return:   [integer!]
		]
		insnstr: "insnstr" [    						;-- Insert n bytes from a string before the current position.
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		insstr: "insstr" [      						;-- Insert a string before the current position.
			str       [c-string!]
			return:   [integer!]
		]
		winsnstr: "winsnstr" [  						;-- Insert n bytes from a string before the current position.
			wid       [window!]
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		winsstr: "winsstr" [    						;-- Insert a string before the current position.
			wid       [window!]
			str       [c-string!]
			return:   [integer!]
		]
		mvinsnstr: "mvinsnstr" [						;-- Insert n bytes from a string before the specified position.
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		mvinsstr: "mvinsstr" [  						;-- Insert a string before the specified position.
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			return:   [integer!]
		]
		mvwinsnstr: "mvwinsnstr" [ 						;-- Insert n bytes from a string before the specified position.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		mvwinsstr: "mvwinsstr" [						;-- Insert a string before the specified position.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			return:   [integer!]
		]

		;-- Printing attributes

		attron: "attron" [    							;-- Turn on display attribute
			attrs     [integer!]
			return:   [integer!]
		]
		attroff: "attroff" [  							;-- Turn off display attribute
			attrs     [integer!]
			return:   [integer!]
		]
		attrset: "attrset" [  							;-- Set the background attribute
			attrs     [integer!]
			return:   [integer!]
		]
		wattron: "wattron" [  							;-- Turn on display attribute of specified window
			wid       [window!]
			attrs     [integer!]
			return:   [integer!]
		]
		wattroff: "wattroff" [							;-- Turn off display attribute of specified window
			wid       [window!]
			attrs     [integer!]
			return:   [integer!]
		]
		wattrset: "wattrset" [							;-- Set the background attribute of specified window
			wid       [window!]
			attrs     [integer!]
			return:   [integer!]
		]
		getbkgd: "getbkgd" [  							;-- Get background character and rendition using a single-byte character.
			wid       [window!]
			return:   [integer!]
		]

		;-- Colors attributes

		has-colors: "has_colors" [  					;-- Indicate whether terminal supports colours
			return:   [logic!]
		]
		start-color: "start_color" [					;-- Initialise use of colours on terminal
			return:   [integer!]
		]
		can-change-color: "can_change_color" [  		;-- Does the terminal support redefinition of colours ?
			return:   [logic!]
		]
		init_color: "init_color" [  					;-- Redefine specified colour.
			col       [integer!]
			r         [integer!]
			g         [integer!]
			b         [integer!]
			return:   [integer!]
		]
		init-pair: "init_pair" [    					;-- Defines a colour-pair number pair with foreground and background colour
			pair      [integer!]
			f         [integer!]
			b         [integer!]
			return:   [integer!]
		]
		color-content: "color_content" [				;-- Identify red, green and blue intensity of a colour.
			col       [integer!]
			red       [int-ptr!]
			green     [int-ptr!]
			blue      [int-ptr!]
			return:   [integer!]
		]
		_color_set: "color_set" [   					;-- Set the colour of the current screen.
			pair      [integer!]      					;-- Use the higher level interface color-set
			opts      [integer!]
			return:   [integer!]
		]
		_wcolor_set: "wcolor_set" [ 					;-- Set the colour of the specified window.
			wid       [window!]       					;-- Use the higher level interface wcolor-set
			pair      [integer!]
			opts      [integer!]
			return:   [integer!]
		]
		pair-content: "pair_content" [					;-- Get information on a colour pair.
			pair      [integer!]
			f         [int-ptr!]
			b         [int-ptr!]
			return:   [integer!]
		]

		;-- Getting data from screen.

		inch: "inch" [              					;-- Input a single-byte character and rendition.
			return:   [integer!]
		]
		mvinch: "mvinch" [          					;-- Input a single-byte character and rendition at specified position.
			row       [integer!]
			col       [integer!]
			return:   [integer!]
		]
		winch: "winch" [            					;-- Input a single-byte character and rendition from a window.
			wid       [window!]
			return:   [integer!]
		]
		mvwinch: "mvwinch" [        					;-- Input a single-byte character and rendition at specified position from a window.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			return:   [integer!]
		]
		innstr: "innstr" [          					;-- Input a n bytes length string from screen.
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		instr: "instr" [            					;-- Input a string from screen.
			str       [c-string!]
			return:   [integer!]
		]
		winnstr: "winnstr" [        					;-- Input a n bytes length string from a window.
			wid       [window!]
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		winstr: "winstr" [          					;-- Input a string from a window.
			wid       [window!]
			str       [c-string!]
			return:   [integer!]
		]
		mvinnstr: "mvinnstr" [      					;-- Move to position and input a n bytes length string from screen.
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		mvinstr: "mvinstr" [        					;-- Move to position and input a string from screen.
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			return:   [integer!]
		]
		mvwinnstr: "mvwinnstr" [    					;-- Move to position and input a n bytes length string from a window.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			n         [integer!]
			return:   [integer!]
		]
		mvwinstr: "mvwinstr" [      					;-- Move to position and input a string from a window.
			wid       [window!]
			row       [integer!]
			col       [integer!]
			str       [c-string!]
			return:   [integer!]
		]

		;-- Terminal management and attributes

		longname: "longname" [      					;-- Get verbose description of current terminal. It is defined only after the call to initscr or newterm.
			return:   [c-string!]
		]
		scr-dump: "scr_dump" [      					;-- Writes the current contents of the virtual screen to the file named by filename in an unspecified format.
			filename  [c-string!]
			return:   [integer!]
		]
		scr-init: "scr_init" [      					;-- Reads the contents of the file named by filename and uses them to initialise the Curses data structures to what the terminal currently has on its screen.
			filename  [c-string!]
			return:   [integer!]
		]
		meta: "meta" [              					;-- Enable/disable meta-keys. bf=true forces 8 bits return. bf=false forces 7 bits return.
			wid       [window!]
			bf        [logic!]
			return:   [integer!]
		]
		delay-output: "delay_output" [; Delay next refresh for ms milliseconds.
			ms        [integer!]
			return:   [integer!]
		]
		wbkgd: "wbkgd" [            					;-- Turn off the previous background attributes, logical OR the requested attributes into the window rendition, and set the background property of the current or specified window and then apply this setting to every character position in that window.
			wid       [window!]
			chtype    [integer!]
			return:   [integer!]
		]
		wbkgdset: "wbkgdset" [      					;-- Turn off the previous background attributes, logical OR the requested attributes into the window rendition, and set the background property of the current or specified window based on the information in ch.
			wid       [window!]
			chtype   [integer!]
			return:   [integer!]
		]
		has-ic: "has_ic" [          					;-- Indicates whether the terminal has insert and delete character capabilities.
			return:   [logic!]
		]
		has-il: "has_il" [          					;-- Indicates whether the terminal has insert and delete line capabilities, or can simulate them using scrolling regions.
			return:   [logic!]
		]
		idcok: "idcok" [            					;-- Enable or disable use of hardware insert and delete character features.
			wid       [window!]
			bf        [logic!]
			return:   [integer!]
		]
		immedok: "immedok" [        					;-- Enable or disable immediate terminal refresh.
			wid       [window!]
			bf        [logic!]
			return:   [integer!]
		]
		intrflush: "intrflush" [    					;-- Enable or disable flush on interrupt.
			wid       [window!]
			bf        [logic!]
			return:   [integer!]
		]
		isendwin: "isendwin" [      					;-- Determine whether a screen has been refreshed.
			return:   [logic!]
		]
		ripoffline: "ripoffline" [  					;-- Reserves a screen line for use by the application.
			line      [integer!]
			init      [integer!]      					;-- pointer on init: function [ [cdecl] wid [integer!] cols [integer!]
			return:   [integer!]
		]

		def-prog-mode: "def_prog_mode" [     			;-- Saves the current terminal modes as the "program" (in Curses) state for use by reset_prog_mode.
			return:   [integer!]
		]
		def-shell-mode: "def_shell_mode" [   			;-- Saves the current terminal modes as the "shell" (not in Curses) state for use by reset_shell_mode.
			return:   [integer!]
		]
		reset-prog-mode: "reset_prog_mode" [ 			;-- Restores the terminal to the "program" (in Curses) state.
			return:   [integer!]
		]
		reset-shell-mode: "reset_shell_mode" [			;-- Restores the terminal to the "shell" (not in Curses) state.
			return:   [integer!]
		]
		baudrate: "baudrate" [      					;-- Returns the output speed of the terminal in bits per second.
			return:   [integer!]
		]
		#switch OS [
			Windows   [
				ungetch: "PDC_ungetch" [				;-- Push a character onto the input queue.
					ch        [integer!]
					return:   [integer!]
				]
			]
			MacOSX    [
			]
			#default  [
				ungetch: "ungetch" [    				;-- Push a character onto the input queue.
					ch        [integer!]
					return:   [integer!]
				]
			]
		] ; #switch OS
		] ; cdecl
	] ; #import [curses-library

	;-- Higher level interface --------------------------------------------------------------------

	with curses [

		stdscr: 0        ; stdscr must be defined globally

		getyx: function [
			wid      [window!]
			row      [int-ptr!]
			col      [int-ptr!]
		][
			row/value: getcury wid
			col/value: getcurx wid
		]

		initscr: function [
			return: [window!]
		][
			stdscr: _initscr
			return stdscr
		]

		color-set: function [   "Set terminal color pair"
			pair    [integer!]
		][
			_color_set pair 0
		]

		wcolor-set: function [  "Set window color pair"
			wid     [window!]
			pair    [integer!]
		][
			_wcolor_set wid pair 0
		]

		getch: function [  "Wait for user input. Not avaliable on Windows, so redefined here"
			return:  [integer!]
		][
			return wgetch stdscr
		]

		printw-attr: function [  "printw surrounded by attribute on/off"
			attr     [integer!]
			txt      [c-string!]
		][
			attron attr
			printw [ txt ]
			attroff attr
		]

		wprintw-attr: function [  "wprintw surrounded by attribute on/off"
			wid      [window!]
			attr     [integer!]
			txt      [c-string!]
		][
			wattron wid attr
			wprintw [ wid txt ]
			wattroff wid attr
		]

		mvwprintw-attr: function [  "wprintw surrounded by attribute on/off"
			wid      [window!]
			row      [integer!]
			col      [integer!]
			attr     [integer!]
			txt      [c-string!]
		][
			wmove wid row col
			wattron wid attr
			wprintw [ wid txt ]
			wattroff wid attr
		]
		color-pair: function [
			pair     [integer!]
			return:  [integer!]
		][
			return (pair << PDC_COLOR_SHIFT) and A_COLOR
		]
		pair-number: function [
			pair     [integer!]
			return:  [integer!]
		][
			return (pair and A_COLOR) >> PDC_COLOR_SHIFT
		]

		_top_line: 0									;-- Pointer to top line window
		_bottom_line: 0		 							;-- Pointer to bottom line window
		_top_cols: 0									;-- Number of columns in top line window
		_bottom_cols: 0									;-- Number of columns in bottom line window

		init-top-line: function [       "Callback function for ripoffline"
			[cdecl]
			wid      [window!]
			cols     [integer!]
		;      return:  [int-ptr!]
		][
			_top_line: wid
			_top_cols: cols
		;      return 0
		]

		init-bottom-line: function [    "Callback function for ripoffline"
			[cdecl]
			wid      [window!]
			cols     [integer!]
		;      return:  [int-ptr!]
		][
			_bottom_line: wid
			_bottom_cols: cols
		;      return 0
		]

		; Test interface --------------------------------------------------------------------

		init-screen: func [
			return:   [window!]
			/local scr
		][
			scr: initscr
			raw
			echo-off
			curs-set 0									;-- no cursor
			keypad scr true  							;-- return Fkeys
			halfdelay 1
			start-color
			return scr
		]

		init-console: func [
			return:   [window!]
			/local scr
		][
			scr: initscr
			keypad scr true  							;-- return Fkeys
			scrollok scr true
			return scr
		]

		locale: ""
		UTF-8: false
		#switch OS [
			Windows   [		]
			#default  [
				locale: setlocale __LC_ALL ""			;--@@ check if "utf8" is present in returned string?
				if null <> find-string locale "UTF-8" [ UTF-8: true ]
			]
		] ; #switch OS
	] ; with curses
] ; context curses
