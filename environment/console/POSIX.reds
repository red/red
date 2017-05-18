Red/System [
	Title:	"INPUT POSIX API imported functions and structures definitions"
	Author: "Nenad Rakocevic, Xie Qingtian"
	File: 	%POSIX.reds
	Tabs: 	4
	Rights: "Copyright (C) 2014-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: {
		Freely inspired by linenoise fork from msteveb:
		https://github.com/msteveb/linenoise/blob/master/linenoise.c
	}
]

#define OS_POLLIN 		1

#case [
	any [OS = 'MacOSX OS = 'FreeBSD] [
		#define TIOCGWINSZ		40087468h
		#define TERM_TCSADRAIN	1
		#define TERM_VTIME		18
		#define TERM_VMIN		17

		#define TERM_BRKINT		02h
		#define TERM_INPCK		10h
		#define TERM_ISTRIP		20h
		#define TERM_ICRNL		0100h
		#define TERM_IXON		0200h
		#define TERM_OPOST		01h
		#define TERM_CS8		0300h
		#define TERM_ISIG		80h
		#define TERM_ICANON		0100h
		#define TERM_ECHO		08h	
		#define TERM_IEXTEN		4000h

		termios!: alias struct! [
			c_iflag			[integer!]
			c_oflag			[integer!]
			c_cflag			[integer!]
			c_lflag			[integer!]
			c_cc1			[integer!]						;-- c_cc[20]
			c_cc2			[integer!]
			c_cc3			[integer!]
			c_cc4			[integer!]
			c_cc5			[integer!]
			c_ispeed		[integer!]
			c_ospeed		[integer!]
		]
	]
	true [													;-- Linux
		#define TIOCGWINSZ		5413h
		#define TERM_VTIME		6
		#define TERM_VMIN		7

		#define TERM_BRKINT		2
		#define TERM_INPCK		20
		#define TERM_ISTRIP		40
		#define TERM_ICRNL		400
		#define TERM_IXON		2000
		#define TERM_OPOST		1
		#define TERM_CS8		60
		#define TERM_ISIG		1
		#define TERM_ICANON		2
		#define TERM_ECHO		10
		#define TERM_IEXTEN		100000

		#either OS = 'Android [
			#define TERM_TCSADRAIN	5403h

			termios!: alias struct! [
				c_iflag			[integer!]
				c_oflag			[integer!]
				c_cflag			[integer!]
				c_lflag			[integer!]
				;c_line			[byte!]
				c_cc1			[integer!]					;-- c_cc[19]
				c_cc2			[integer!]
				c_cc3			[integer!]
				c_cc4			[integer!]
				c_cc5			[integer!]
			]
		][
			#define TERM_TCSADRAIN	1

			termios!: alias struct! [						;-- sizeof(termios) = 60
				c_iflag			[integer!]
				c_oflag			[integer!]
				c_cflag			[integer!]
				c_lflag			[integer!]
				c_line			[byte!]
				c_cc1			[byte!]						;-- c_cc[32]
				c_cc2			[byte!]
				c_cc3			[byte!]
				c_cc4			[integer!]
				c_cc5			[integer!]
				c_cc6			[integer!]
				c_cc7			[integer!]
				c_cc8			[integer!]
				c_cc9			[integer!]
				c_cc10			[integer!]
				pad				[integer!]					;-- for proper alignment
				c_ispeed		[integer!]
				c_ospeed		[integer!]
			]
		]
	]
]

pollfd!: alias struct! [
	fd				[integer!]
	events			[integer!]						;-- high 16-bit: events
]													;-- low  16-bit: revents

winsize!: alias struct! [
	rowcol			[integer!]
	xypixel			[integer!]
]

#either OS = 'Android [
	tcgetattr: func [
		fd		[integer!]
		termios [termios!]
		return: [integer!]
	][
		ioctl fd 5401h as winsize! termios
	]
	tcsetattr: func [
		fd			[integer!]
		opt_actions [integer!]
		termios 	[termios!]
		return: 	[integer!]
	][
		ioctl fd opt_actions as winsize! termios
	]
][
	#import [
	LIBC-file cdecl [
		tcgetattr: "tcgetattr" [
			fd		[integer!]
			termios [termios!]
			return: [integer!]
		]
		tcsetattr: "tcsetattr" [
			fd			[integer!]
			opt_actions [integer!]
			termios 	[termios!]
			return: 	[integer!]
		]
	]]
]

#import [
	LIBC-file cdecl [
		isatty: "isatty" [
			fd		[integer!]
			return:	[integer!]
		]
		read: "read" [
			fd		[integer!]
			buf		[byte-ptr!]
			size	[integer!]
			return: [integer!]
		]
		write: "write" [
			fd		[integer!]
			buf		[byte-ptr!]
			size	[integer!]
			return: [integer!]
		]
		poll: "poll" [
			fds		[pollfd!]
			nfds	[integer!]
			timeout [integer!]
			return: [integer!]
		]
		ioctl: "ioctl" [
			fd		[integer!]
			request	[integer!]
			ws		[winsize!]
			return: [integer!]
		]
	]
]

saved-term: declare termios!
utf-char:	declare c-string!
poller: 	declare pollfd!
relative-y:	0

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
	col		[int-ptr!]
	return: [logic!]								;-- FALSE: failed to retrieve it
	/local
		c [byte!]
		n [integer!]
][
	emit-string "^[[6n"								;-- ask for cursor location
	if all [
		  esc = fd-read-char 100
		 #"[" = fd-read-char 100
	][
		while [true][
			c: fd-read-char 100
			n: 0
			case [
				c = #";" [n: 0]
				all [c = #"R" n <> 0 n < 1000][
					col/value: n
					return true
				]
				all [#"0" <= c c <= #"9"][
					n: n * 10 + (c - #"0")
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
		ws	 [winsize!]
		here [integer!]
		size [red-pair!]
][
	ws: declare winsize!

	ioctl stdout TIOCGWINSZ ws
	columns: ws/rowcol >> 16

	if zero? columns [
		columns: 80
		here: 0
		if query-cursor :here [
			emit-string "^[[999C"

			either query-cursor :columns [
				if columns > here [				;-- reset cursor position
					emit-string-int "^[[" columns - here #"D"
				]
			][
				emit cr
			]
		]
	]
	size: as red-pair! #get system/console/size
	size/x: columns
	size/y: ws/rowcol and FFFFh
]

reset-cursor-pos: does [
	if positive? relative-y [emit-string-int "^[[" relative-y #"A"]	;-- move to origin row
	emit cr
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

output-to-screen: does [
	write stdout buffer (as-integer pbuffer - buffer)
]

init: func [
	/local
		term [termios!]
		cc	 [byte-ptr!]
		so	 [sigaction!]
		mask [integer!]
][
	console?: 1 = isatty stdin
	relative-y: 0
	utf-char: as-c-string allocate 10
	
	if console? [
		so: declare sigaction!						;-- install resizing signal trap
		mask: (as-integer so) + 4
		sigemptyset mask
		so/sigaction: as-integer :on-resize
		so/flags: 0
		sigaction SIGWINCH so as sigaction! 0

		term: declare termios!
		tcgetattr stdin saved-term					;@@ check returned value

		copy-memory 
			as byte-ptr! term
			as byte-ptr! saved-term
			size? term

		term/c_iflag: term/c_iflag and not (
			TERM_BRKINT or TERM_ICRNL or TERM_INPCK or TERM_ISTRIP or TERM_IXON
		)
		term/c_oflag: term/c_oflag and not TERM_OPOST
		term/c_cflag: term/c_cflag or TERM_CS8
		term/c_lflag: term/c_lflag and not (
			TERM_ECHO or TERM_ICANON or TERM_IEXTEN or TERM_ISIG
		)
		#case [
			any [OS = 'MacOSX OS = 'FreeBSD] [
				cc: (as byte-ptr! term) + (4 * size? integer!)
			]
			true [cc: (as byte-ptr! term) + (4 * size? integer!) + 1]
		]
		cc/TERM_VMIN:  as-byte 1
		cc/TERM_VTIME: as-byte 0

		tcsetattr stdin TERM_TCSADRAIN term

		poller/fd: stdin
		poller/events: OS_POLLIN

		buffer: allocate buf-size
	]
]

restore: does [
	tcsetattr stdin TERM_TCSADRAIN saved-term
	free buffer
	free as byte-ptr! utf-char
]
