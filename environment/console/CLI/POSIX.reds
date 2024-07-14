Red/System [
	Title:	"INPUT POSIX API imported functions and structures definitions"
	Author: "Nenad Rakocevic, Xie Qingtian"
	File: 	%POSIX.reds
	Tabs: 	4
	Rights: "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: {
		Freely inspired by linenoise fork from msteveb:
		https://github.com/msteveb/linenoise/blob/master/linenoise.c
	}
]

old-act:	declare sigaction!
saved-term: declare termios!
utf-char: as-c-string allocate 10
poller: 	declare pollfd!
relative-y:	0
bottom-y:	0
init?:		no

fd-read-char: func [
	timeout [integer!]
	return: [byte!]
	/local
		c [byte!]
][
	c: as-byte -1
	if any [
		zero? poll poller 1 timeout
		1 <> read stdin :c 1
	][
		return as-byte -1
	]
	c
]

fd-read: func [
	return: [integer!]								;-- input codepoint or -1
	/local
		c	[integer!]
		len [integer!]
		i	[integer!]
][
	if 1 <> read stdin as byte-ptr! utf-char 1 [return -1]
	c: as-integer utf-char/1
	case [
		c and 80h = 0	[len: 1]
		c and E0h = C0h [len: 2]
		c and F0h = E0h [len: 3]
		c and F8h = F0h [len: 4]
	]
	if any [len < 1 len > 4][return -1]

	i: 1
	while [i < len][
		if all [
			len >= (i + 1)
			1 <> read stdin as byte-ptr! utf-char + i 1
		][
			return -1
		]
		i: i + 1
	]
	unicode/decode-utf8-char utf-char :len
]

check-special: func [
	return: [integer!]
	/local
		c  [byte!]
		c2 [byte!]
		c3 [byte!]
][
	c: fd-read-char 50
	if (as-integer c) > 127 [return 27]

	c2: fd-read-char 50
	if (as-integer c2) > 127 [return as-integer c2]

	if any [c = #"[" c = #"O"][
		switch c2 [
			#"A" [return KEY_UP]
			#"B" [return KEY_DOWN]
			#"C" [return KEY_RIGHT]
			#"D" [return KEY_LEFT]
			#"F" [return KEY_END]
			#"H" [return KEY_HOME]
			default []
		]
	]
	if all [c = #"[" #"1" <= c2 c2 <= #"8"][
		c: fd-read-char 50
		if c = #"~" [
			switch c2 [
				#"2" [return KEY_INSERT]
				#"3" [return KEY_DELETE]
				#"5" [return KEY_PAGE_UP]
				#"6" [return KEY_PAGE_DOWN]
				#"7" [return KEY_HOME]
				#"8" [return KEY_END]
				default [return KEY_NONE]
			]
		]
		if all [(as-integer c) <> -1 c <> #"~"][
			c3: fd-read-char 50
		]

		if all [c2 = #"2" c = #"0" #"~" = fd-read-char 50][
			pasting?: c3 = #"0"
		]
	]
	KEY_NONE
]

emit: func [c [byte!]][
	write stdout :c 1
]

emit-string: func [
	s [c-string!]
][
	write stdout as byte-ptr! s length? s
]

emit-string-int: func [
	begin [c-string!]
	n	  [integer!]
	end	  [byte!]
][
	emit-string begin
	emit-string integer/form-signed n
	emit end
]

emit-red-char: func [
	cp			[integer!]
][
	if hide-input? [cp: as-integer #"*"]
	case [
		cp <= 7Fh [
			pbuffer/1: as-byte cp
			pbuffer: pbuffer + 1
		]
		cp <= 07FFh [
			pbuffer/1: as-byte cp >> 6 or C0h
			pbuffer/2: as-byte cp and 3Fh or 80h
			pbuffer: pbuffer + 2
		]
		cp <= FFFFh [
			pbuffer/1: as-byte cp >> 12 or E0h
			pbuffer/2: as-byte cp >> 6 and 3Fh or 80h
			pbuffer/3: as-byte cp and 3Fh or 80h
			pbuffer: pbuffer + 3
		]
		cp <= 001FFFFFh [
			pbuffer/1: as-byte cp >> 18 or F0h
			pbuffer/2: as-byte cp >> 12 and 3Fh or 80h
			pbuffer/3: as-byte cp >>  6 and 3Fh or 80h
			pbuffer/4: as-byte cp and 3Fh or 80h
			pbuffer: pbuffer + 4
		]
		true [
			print-line "Error in emit-red-string: codepoint > 1FFFFFh"
		]
	]
]

query-cursor: func [
	pos		[int-ptr!]
	return: [logic!]								;-- FALSE: failed to retrieve it
	/local
		c	[byte!]
		n x y [integer!]
][
	emit-string "^[[6n"								;-- ask for cursor location
	if all [
		  esc = fd-read-char 100
		 #"[" = fd-read-char 100
	][
		x: 0
		y: 0
		n: 0
		while [true][
			c: fd-read-char 100
			case [
				c = #";" [y: n - 1 n: 0]
				all [c = #"R" n <> 0 n < 1000][
					x: n - 1
					pos/value: y << 16 or x
					return true
				]
				all [#"0" <= c c <= #"9"][
					n: n * 10 + as-integer (c - #"0")
				]
				true [
					return true
				]
			]
		]
	]
	false
]

get-window-size: func [
	/local
		ws	 [winsize! value]
		size [red-pair!]
][
	ws/rowcol: 0
	ws/xypixel: 0
	if zero? ioctl stdout TIOCGWINSZ :ws [
		columns: ws/rowcol >> 16
		rows: ws/rowcol and FFFFh
	]
	if any [zero? columns zero? rows][
		columns: 80
		rows: 24
	]
	size: as red-pair! #get system/console/size
	size/x: columns
	size/y: rows
]

reset-cursor-pos: does [
	if positive? relative-y [emit-string-int "^[[" relative-y #"A"]	;-- move to origin row
	either cursor-pos and FFFFh = 0 [
		emit cr
	][
		emit-string-int "^[[" cursor-pos and FFFFh + 1 #"G"
	]
]

erase-to-bottom: does [
	emit-string "^[[0J"				;-- erase down to the bottom of the screen
]

set-cursor-pos: func [
	line	[red-string!]
	offset	[integer!]
	size	[integer!]
	/local
		x	[integer!]
		y	[integer!]
][
	relative-y: size / columns		;-- the lines of all outputs occupy
	y: size / columns - (offset / columns)
	x: offset // columns

	if all [						;-- special case: when moving cursor to the first char of a line
		widechar? line				;-- the first char of the line is a widechar
		columns - x = 1				;-- but in pre line only 1 space left
	][
		y: y - 1
		x: 0
	]

	if zero? (size % columns) [emit #"^(0A)"]

	bottom-y: y
	if positive? y [				;-- set cursor position: y
	    emit-string-int "^[[" y #"A"
	    relative-y: relative-y - y
	]
	either zero? x [		 		;-- set cursor position: x
		emit #"^(0D)"
	][
		emit-string-int "^(0D)^[[" x #"C"
	]
]

move-cursor-bottom: does [
	if bottom-y > 0 [emit-string-int "^[[" bottom-y #"B"]
]

output-to-screen: does [
	write stdout buffer (as-integer pbuffer - buffer)
]

init: func [][
	console?: 1 = isatty stdin
	if console? [
		get-window-size
	]
]

init-console: func [
	/local
		term [termios! value]
		cc	 [byte-ptr!]
		so	 [sigaction! value]
][
	relative-y: 0
	
	if console? [
		sigemptyset (as-integer :so) + 4
		so/sigaction: as-integer :on-resize
		so/flags: 0
		#either OS = 'Linux [
			sigaction SIGWINCH :so null
		][
			sigaction SIGWINCH :so old-act
		]

		tcgetattr stdin saved-term					;@@ check returned value

		copy-memory 
			as byte-ptr! :term
			as byte-ptr! saved-term
			size? termios!

		term/c_iflag: term/c_iflag and not (
			TERM_BRKINT or TERM_ICRNL or TERM_INPCK or TERM_ISTRIP or TERM_IXON
		)
		term/c_oflag: term/c_oflag and not TERM_OPOST
		term/c_cflag: term/c_cflag or TERM_CS8
		term/c_lflag: term/c_lflag and not (
			TERM_ECHO or TERM_ICANON or TERM_IEXTEN or TERM_ISIG
		)
		#case [
			any [OS = 'macOS OS = 'FreeBSD OS = 'NetBSD] [
				cc: (as byte-ptr! :term) + (4 * size? integer!)
			]
			true [cc: (as byte-ptr! :term) + (4 * size? integer!) + 1]
		]
		cc/TERM_VMIN:  as-byte 1
		cc/TERM_VTIME: as-byte 0

		tcsetattr stdin TERM_TCSADRAIN :term

		poller/fd: stdin
		poller/events: OS_POLLIN

		buffer: allocate buf-size
		unless init? [
			emit-string "^[[?2004h"		;-- enable bracketed paste mode: https://cirw.in/blog/bracketed-paste
			init?: yes
		]
	]
	#if OS = 'macOS [
		#if modules contains 'View [#if GUI-engine <> 'terminal [
			with gui [
				if NSApp <> 0 [do-events yes]
			]
		]]
	]
]

restore: does [
	tcsetattr stdin TERM_TCSADRAIN saved-term
	#if OS <> 'Linux [sigaction SIGWINCH old-act null]
	free buffer
]
