Red [
	Title:	"INPUT prototype for Unix platforms"
	Author: "Nenad Rakocevic"
	File: 	%input.red
	Tabs: 	4
	Rights: "Copyright (C) 2014 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
	Notes: {
		Freely inspired by linenoise fork from msteveb:
		https://github.com/msteveb/linenoise/blob/master/linenoise.c
	}
]

#system [

	terminal: context [

	#either OS <> 'Windows [
		#define OS_POLLIN 		1
		#define TERM_TCSADRAIN	1

		#case [
			any [OS = 'MacOSX OS = 'FreeBSD] [
				#define TIOCGWINSZ		40087468h
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
					c_cc1			[integer!]					;-- c_cc[20]
					c_cc2			[integer!]
					c_cc3			[integer!]
					c_cc4			[integer!]
					c_cc5			[integer!]
					c_ispeed		[integer!]
					c_ospeed		[integer!]
				]
			]
			true [
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

		pollfd!: alias struct! [
			fd				[integer!]
			events			[integer!]						;-- high 16-bit: events
		]													;-- low  16-bit: revents

		winsize!: alias struct! [
			rowcol			[integer!]
			xypixel			[integer!]
		]

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
		lines-y:	0

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
				p	[byte-ptr!]
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
			c: unicode/decode-utf8-char utf-char :len
			switch c [
				#"^(0D)" [KEY_ENTER]
				#"^(7F)" [KEY_BACKSPACE]
				default  [c]
			]
		]

		check-special: func [
			return: [integer!]
			/local
				c  [byte!]
				c2 [byte!]
		][
			c: fd-read-char 50
			if (as-integer c) < 0 [return 27]

			c2: fd-read-char 50
			if (as-integer c) < 0 [return as-integer c2]

			if any [c = #"[" c = #"O"][
				switch c2 [
					#"A" [return KEY_UP]
					#"B" [return KEY_DOWN]
					#"C" [return KEY_RIGHT]
					#"D" [return KEY_LEFT]
					#"F" [return KEY_END]
					#"H" [return KEY_HOME]
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
					]
				]
				while [all [(as-integer c) <> -1 c <> #"~"]][
					c: fd-read-char 50
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

		emit-buf: func [c [byte!]][
			pbuffer/1: c
			pbuffer: pbuffer + 1
		]

		emit-red-string: func [
			str			[red-string!]
			size		[integer!]
			head-as-tail? [logic!]
			return: 	[integer!]
			/local
				series	[series!]
				offset	[byte-ptr!]
				tail	[byte-ptr!]
				unit	[integer!]
				cp		[integer!]
				bytes	[integer!]
				cnt		[integer!]
				x		[integer!]
				w		[integer!]
		][
			x:		0
			w:		0
			cnt:	0
			bytes:	0
			series: GET_BUFFER(str)
			unit: 	GET_UNIT(series)
			offset: (as byte-ptr! series/offset) + (str/head << (unit >> 1))
			tail:   as byte-ptr! series/tail
			if head-as-tail? [
				tail: offset
				offset: as byte-ptr! series/offset
			]
			until [
				while [
					all [offset < tail cnt < size]
				][
					cp: string/get-char offset unit
					w: wcwidth? cp
					cnt: switch w [
						1  [cnt + 1]
						2  [either size - cnt = 1 [x: 2 cnt + 3][cnt + 2]]	;-- reach screen edge, handle wide char
						default [0]
					]
					case [
						cp <= 7Fh [
							emit-buf as-byte cp
						]
						cp <= 07FFh [
							emit-buf as-byte cp >> 6 or C0h
							emit-buf as-byte cp and 3Fh or 80h
						]
						cp <= FFFFh [
							emit-buf as-byte cp >> 12 or E0h
							emit-buf as-byte cp >> 6 and 3Fh or 80h
							emit-buf as-byte cp and 3Fh or 80h
						]
						cp <= 001FFFFFh [
							emit-buf as-byte cp >> 18 or F0h
							emit-buf as-byte cp >> 12 and 3Fh or 80h
							emit-buf as-byte cp >>  6 and 3Fh or 80h
							emit-buf as-byte cp and 3Fh or 80h
						]
						true [
							print-line "Error in emit-red-string: codepoint > 1FFFFFh"
						]
					]
					offset: offset + unit
				]
				bytes: bytes + cnt
				if cnt = size [				;-- emit new-line and set cursor to start.
					emit-buf #"^(0A)"
					emit-buf #"^(0D)"
				]
				size: columns - x
				x: 0
				cnt: 0
				offset >= tail
			]
			bytes
		]

		query-cursor: func [
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
							columns: n
							return true
						]
						all [#"0" <= c c <= #"9"][
							n: n * 10 + (c - #"0")
						]
						true [
							columns: n
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
		][
			ws: declare winsize!

			if zero? ioctl stdout TIOCGWINSZ ws [
				columns: ws/rowcol >> 16
				exit
			]

			if zero? columns [
				columns: 80

				if query-cursor [
					here: columns
					emit-string "^[[999C"

					either query-cursor [
						if columns > here [				;-- reset cursor position
							emit-string-int "^[[" columns - here #"D"
						]
					][
						emit cr
					]
				]
			]
		]

		erase-to-bottom: does [
			if positive? lines-y [emit-string-int "^[[" lines-y #"A"]	;-- move to origin row
			emit-string "^(0D)^[[J"					;-- erase down to the bottom of the screen		
		]

		set-cursor-pos: func [
			line	[red-string!]
			offset	[integer!]
			size	[integer!]
			/local
				x	[integer!]
				y	[integer!]
		][
			lines-y: size / columns			;-- the lines of all outputs occupy
			y: size / columns  - (offset / columns)
			x: offset // columns
			
			if all [						;-- special case: when moving cursor to the first char of a line
				widechar? line				;-- the first char of the line is a widechar
				columns - x = 1				;-- but in pre line only 1 space left
			][
				y: y - 1
				x: 0
			]

			if positive? y [				;-- set cursor position: y
			    emit-string-int "^[[" y #"A"
			    lines-y: lines-y - y
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
			line 	 [red-string!]
			hist-blk [red-block!]
			/local
				term [termios!]
				cc	 [byte-ptr!]
				so	 [sigaction!]
		][
			utf-char: as-c-string allocate 10
			
			copy-cell as red-value! line as red-value! input-line
			copy-cell as red-value! hist-blk as red-value! history
			
			so: declare sigaction!						;-- install resizing signal trap
			so/sigaction: as-integer :on-resize
			so/flags: 	SA_SIGINFO ;or SA_RESTART
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

		restore: does [
			tcsetattr stdin TERM_TCSADRAIN saved-term
			free buffer
		]
		
	][;-- ================================================================= --

		#define VK_BACK 				 	08h
		#define VK_TAB 					 	09h
		#define VK_CLEAR 				 	0Ch
		#define VK_RETURN 				 	0Dh
		#define VK_SHIFT 				 	10h
		#define VK_CONTROL 				 	11h
		#define VK_PRIOR 				 	21h
		#define VK_NEXT 				 	22h
		#define VK_END 					 	23h
		#define VK_HOME 				 	24h
		#define VK_LEFT 				 	25h
		#define VK_UP 					 	26h
		#define VK_RIGHT 				 	27h
		#define VK_DOWN 				 	28h
		#define VK_SELECT 				 	29h
		#define VK_INSERT 				 	2Dh
		#define VK_DELETE 				 	2Eh
		#define KEY_EVENT 				 	01h
		#define MOUSE_EVENT 			 	02h
		#define WINDOW_BUFFER_SIZE_EVENT 	04h
		#define MENU_EVENT 				 	08h
		#define FOCUS_EVENT 			 	10h
		#define ENHANCED_KEY 			 	0100h
		#define FOREGROUND_BLUE 		 	01h
		#define FOREGROUND_GREEN 		 	02h
		#define FOREGROUND_RED 			 	04h
		#define ENABLE_LINE_INPUT 			02h
		#define ENABLE_ECHO_INPUT 			04h

		mouse-event!: alias struct! [
			Position  [integer!]			;-- high 16-bit: Y	low 16-bit: X
			BtnState  [integer!]
			KeyState  [integer!]
			Flags	  [integer!]
		]

		key-event!: alias struct! [		   ;typedef struct _KEY_EVENT_RECORD {
			KeyDown   			[integer!] ;  WINBOOL bKeyDown;  	offset: 0
			RepeatCnt-KeyCode	[integer!] ;  WORD wRepeatCount;            4
			ScanCode-Char		[integer!] ;  WORD wVirtualKeyCode;    		6
			KeyState  			[integer!] ;  WORD wVirtualScanCode;  		8
		]                          		   ;  union {
                                           ;    WCHAR UnicodeChar;
                                           ;    CHAR AsciiChar;
                                           ;  } uChar;						10
                                           ;  DWORD dwControlKeyState;		12
                                           ;} KEY_EVENT_RECORD,*PKEY_EVENT_RECORD;
		input-record!: alias struct! [
			EventType [integer!]
			Event	  [integer!]
			pad2	  [integer!]
			pad3	  [integer!]
			pad4	  [integer!]
		]

		screenbuf-info!: alias struct! [	;-- size? screenbuf-info! = 22
			Size	  [integer!]        	;typedef struct _CONSOLE_SCREEN_BUFFER_INFO {
			Position  [integer!]        	;  COORD dwSize;		offset: 0
			pad1	  [integer!]        	;  COORD dwCursorPosition;		4
			pad2	  [integer!]        	;  WORD wAttributes;			8
			pad3	  [integer!]        	;  SMALL_RECT srWindow;			10
			pad4 	  [byte!]           	;  COORD dwMaximumWindowSize;	18
			pad5 	  [byte!]           	;} CONSOLE_SCREEN_BUFFER_INFO,*PCONSOLE_SCREEN_BUFFER_INFO;
		]									;-- sizeof(CONSOLE_SCREEN_BUFFER_INFO) = 22

		#import [
			"kernel32.dll" stdcall [
				ReadConsoleInput: "ReadConsoleInputW" [
					handle			[integer!]
					arrayOfRecs		[integer!]
					length			[integer!]
					numberOfRecs	[int-ptr!]
					return:			[integer!]
				]
				SetConsoleMode: "SetConsoleMode" [
					handle			[integer!]
					mode			[integer!]
					return:			[integer!]
				]
				GetConsoleMode:	"GetConsoleMode" [
					handle			[integer!]
					mode			[int-ptr!]
					return:			[integer!]
				]
				WriteConsole: 	 "WriteConsoleW" [
					consoleOutput	[integer!]
					buffer			[byte-ptr!]
					charsToWrite	[integer!]
					numberOfChars	[int-ptr!]
					_reserved		[int-ptr!]
					return:			[integer!]
				]
				FillConsoleOutputAttribute: "FillConsoleOutputAttribute" [
					handle			[integer!]
					attributs		[integer!]
					length			[integer!]
					coord			[integer!]
					numberOfAttrs	[int-ptr!]
				]
				FillConsoleOutputCharacter: "FillConsoleOutputCharacterW" [
					handle			[integer!]
					attributs		[integer!]
					length			[integer!]
					coord			[integer!]
					numberOfChars	[int-ptr!]
				]
				SetConsoleCursorPosition: "SetConsoleCursorPosition" [
					handle 			[integer!]
					coord 			[integer!]
				]
				GetConsoleScreenBufferInfo: "GetConsoleScreenBufferInfo" [
					handle 			[integer!]
					info 			[integer!]
					return: 		[integer!]
				]
			]
		]

		input-rec: declare input-record!
		base-y:	 	 0
		saved-con:	 0

		#define FIRST_WORD(int) (int and FFFFh)
		#define SECOND_WORD(int) (int >>> 16)

		fd-read: func [
			return: 	[integer!]
			/local
				key 	[key-event!]
				n	 	[integer!]
				keycode [integer!]
		][
			n: 0
			while [true] [
				if zero? ReadConsoleInput stdin as-integer input-rec 1 :n [return -1]
				key: as key-event! (as-integer input-rec) + (size? integer!)

				if all [
					input-rec/EventType and FFFFh = KEY_EVENT
					key/KeyDown <> 0
				][
					keycode: SECOND_WORD(key/RepeatCnt-KeyCode)  ;-- 1st RepeatCnt 2 KeyCode
					switch keycode [
						VK_LEFT		[return KEY_LEFT]
						VK_RIGHT	[return KEY_RIGHT]
						VK_UP		[return KEY_UP]
						VK_DOWN		[return KEY_DOWN]
						VK_INSERT	[return KEY_INSERT]
						VK_DELETE	[return KEY_DELETE]
						VK_HOME		[return KEY_HOME]
						VK_END		[return KEY_END]
						VK_PRIOR	[return KEY_PAGE_UP]
						VK_NEXT		[return KEY_PAGE_DOWN]
						VK_BACK 	[return KEY_BACKSPACE]
						VK_RETURN 	[return KEY_ENTER]
						VK_CONTROL  []
						default 	[
							return SECOND_WORD(key/ScanCode-Char) ;-- return Char
						]
					]
				]
			]
			-1
		]

		get-window-size: func [
			return: 	[integer!]
			/local
				info 	[screenbuf-info!]
				x-y 	[integer!]
		][
			info: declare screenbuf-info!
			if zero? GetConsoleScreenBufferInfo stdout as-integer info [return -1]
			x-y: info/Size
			columns: FIRST_WORD(x-y)
			rows: SECOND_WORD(x-y)
			if columns <= 0 [columns: 80 return -1]
			x-y: info/Position
			base-y: SECOND_WORD(x-y)
			0
		]

		emit-buf: func [cp [integer!] /local b][
			b: as byte-ptr! :cp
			pbuffer/1: b/1
			pbuffer/2: b/2
			pbuffer: pbuffer + 2
		]

		emit-red-string: func [
			str	 		  [red-string!]
			size 		  [integer!]
			head-as-tail? [logic!]
			return:		  [integer!]
			/local
				x		  [integer!]
				cnt		  [integer!]
				n		  [integer!]
				bytes	  [integer!]
				cp		  [integer!]
				unit	  [integer!]
				series	  [series!]
				offset	  [byte-ptr!]
				tail	  [byte-ptr!]
		][
			x:		0
			n:		0
			bytes:	0
			cnt:	0
			series: GET_BUFFER(str)
			unit: 	GET_UNIT(series)
			offset: (as byte-ptr! series/offset) + (str/head << (unit >> 1))
			tail:	as byte-ptr! series/tail
			if head-as-tail? [
				tail: offset
				offset: as byte-ptr! series/offset
			]
			until [
				while [
					all [offset < tail cnt < size]
				][
					cp: string/get-char offset unit
					cnt: either cp > FFh [
						either size - cnt = 1 [x: 2 cnt + 3][cnt + 2]	;-- reach screen edge, handle wide char
					][
						cnt + 1
					]
					emit-buf cp
					offset: offset + unit
				]
				bytes: bytes + cnt
				size: columns - x
				cnt: 0
				x: 0

				offset >= tail
			]
			bytes
		]

		erase-to-bottom: func [
			/local
				n	 [integer!]
				info [screenbuf-info!]
				x-y  [integer!]
		][
			n: 0
			info: declare screenbuf-info!

			SetConsoleCursorPosition stdout base-y << 16
			GetConsoleScreenBufferInfo stdout as-integer info
			x-y: info/Position
			FillConsoleOutputCharacter							;-- clear screen
				stdout
				20h												;-- #" " = 20h
				rows - SECOND_WORD(x-y) * columns				;-- (rows - y) * columns
				x-y
				:n
		]

		set-cursor-pos: func [
			line	[red-string!]
			offset	[integer!]
			size	[integer!]
			/local
				x	[integer!]
				y	[integer!]
		][
			y: offset / columns
			x: offset // columns
			if all [
				widechar? line
				columns - x = 1
			][
				y: y + 1
				x: 0
			]
			SetConsoleCursorPosition stdout base-y + y << 16 or x
		]

		output-to-screen: func [/local n][
			n: 0
			WriteConsole stdout buffer (as-integer pbuffer - buffer) / 2 :n null
		]

		init: func [
			line 		[red-string!]
			hist-blk	[red-block!]
			/local
				mode	[integer!]
		][
			copy-cell as red-value! line as red-value! input-line
			copy-cell as red-value! hist-blk as red-value! history

			GetConsoleMode stdin :saved-con
			mode: not (ENABLE_LINE_INPUT and ENABLE_ECHO_INPUT)		;-- turn off some features
			SetConsoleMode stdin saved-con and mode
			buffer: allocate buf-size
		]

		restore: does [SetConsoleMode stdin saved-con free buffer]

	] ;-- =================End Of OS Dependent Functions==================== --

		#enum special-key! [
			KEY_UNSET:		 -1
			KEY_NONE:		  0
			KEY_UP:			-20
			KEY_DOWN:		-21
			KEY_RIGHT:		-22
			KEY_LEFT:		-23
			KEY_END:		-24
			KEY_HOME:		-25
			KEY_INSERT:		-26
			KEY_DELETE:		-27
			KEY_PAGE_UP:	-28
			KEY_PAGE_DOWN:	-29
			KEY_ENTER:		-30
			KEY_BACKSPACE:	-31
		]

		#define KEY-CTRL-A	#"^A"
		#define	KEY-CTRL-E	#"^E"

		buffer:		declare byte-ptr!
		pbuffer:	declare byte-ptr!
		input-line: declare red-string!
		saved-line:	declare red-string!
		prompt:		declare	red-string!
		history:	declare red-block!
		buf-size:	512
		columns:	-1
		rows:		-1

		combining-table: [
			0300h 036Fh 0483h 0486h 0488h 0489h
			0591h 05BDh 05BFh 05BFh 05C1h 05C2h
			05C4h 05C5h 05C7h 05C7h 0600h 0603h
			0610h 0615h 064Bh 065Eh 0670h 0670h
			06D6h 06E4h 06E7h 06E8h 06EAh 06EDh
			070Fh 070Fh 0711h 0711h 0730h 074Ah
			07A6h 07B0h 07EBh 07F3h 0901h 0902h
			093Ch 093Ch 0941h 0948h 094Dh 094Dh
			0951h 0954h 0962h 0963h 0981h 0981h
			09BCh 09BCh 09C1h 09C4h 09CDh 09CDh
			09E2h 09E3h 0A01h 0A02h 0A3Ch 0A3Ch
			0A41h 0A42h 0A47h 0A48h 0A4Bh 0A4Dh
			0A70h 0A71h 0A81h 0A82h 0ABCh 0ABCh
			0AC1h 0AC5h 0AC7h 0AC8h 0ACDh 0ACDh
			0AE2h 0AE3h 0B01h 0B01h 0B3Ch 0B3Ch
			0B3Fh 0B3Fh 0B41h 0B43h 0B4Dh 0B4Dh
			0B56h 0B56h 0B82h 0B82h 0BC0h 0BC0h
			0BCDh 0BCDh 0C3Eh 0C40h 0C46h 0C48h
			0C4Ah 0C4Dh 0C55h 0C56h 0CBCh 0CBCh
			0CBFh 0CBFh 0CC6h 0CC6h 0CCCh 0CCDh
			0CE2h 0CE3h 0D41h 0D43h 0D4Dh 0D4Dh
			0DCAh 0DCAh 0DD2h 0DD4h 0DD6h 0DD6h
			0E31h 0E31h 0E34h 0E3Ah 0E47h 0E4Eh
			0EB1h 0EB1h 0EB4h 0EB9h 0EBBh 0EBCh
			0EC8h 0ECDh 0F18h 0F19h 0F35h 0F35h
			0F37h 0F37h 0F39h 0F39h 0F71h 0F7Eh
			0F80h 0F84h 0F86h 0F87h 0F90h 0F97h
			0F99h 0FBCh 0FC6h 0FC6h 102Dh 1030h
			1032h 1032h 1036h 1037h 1039h 1039h
			1058h 1059h 1160h 11FFh 135Fh 135Fh
			1712h 1714h 1732h 1734h 1752h 1753h
			1772h 1773h 17B4h 17B5h 17B7h 17BDh
			17C6h 17C6h 17C9h 17D3h 17DDh 17DDh
			180Bh 180Dh 18A9h 18A9h 1920h 1922h
			1927h 1928h 1932h 1932h 1939h 193Bh
			1A17h 1A18h 1B00h 1B03h 1B34h 1B34h
			1B36h 1B3Ah 1B3Ch 1B3Ch 1B42h 1B42h
			1B6Bh 1B73h 1DC0h 1DCAh 1DFEh 1DFFh
			200Bh 200Fh 202Ah 202Eh 2060h 2063h
			206Ah 206Fh 20D0h 20EFh 302Ah 302Fh
			3099h 309Ah A806h A806h A80Bh A80Bh
			A825h A826h FB1Eh FB1Eh FE00h FE0Fh
			FE20h FE23h FEFFh FEFFh FFF9h FFFBh
			00010A01h 00010A03h 00010A05h 00010A06h 00010A0Ch 00010A0Fh
			00010A38h 00010A3Ah 00010A3Fh 00010A3Fh 0001D167h 0001D169h
			0001D173h 0001D182h 0001D185h 0001D18Bh 0001D1AAh 0001D1ADh
			0001D242h 0001D244h 000E0001h 000E0001h 000E0020h 000E007Fh
			000E0100h 000E01EFh
		]

		ambiguous-table: [
			00A1h 00A1h 00A4h 00A4h 00A7h 00A8h
			00AAh 00AAh 00AEh 00AEh 00B0h 00B4h
			00B6h 00BAh 00BCh 00BFh 00C6h 00C6h
			00D0h 00D0h 00D7h 00D8h 00DEh 00E1h
			00E6h 00E6h 00E8h 00EAh 00ECh 00EDh
			00F0h 00F0h 00F2h 00F3h 00F7h 00FAh
			00FCh 00FCh 00FEh 00FEh 0101h 0101h
			0111h 0111h 0113h 0113h 011Bh 011Bh
			0126h 0127h 012Bh 012Bh 0131h 0133h
			0138h 0138h 013Fh 0142h 0144h 0144h
			0148h 014Bh 014Dh 014Dh 0152h 0153h
			0166h 0167h 016Bh 016Bh 01CEh 01CEh
			01D0h 01D0h 01D2h 01D2h 01D4h 01D4h
			01D6h 01D6h 01D8h 01D8h 01DAh 01DAh
			01DCh 01DCh 0251h 0251h 0261h 0261h
			02C4h 02C4h 02C7h 02C7h 02C9h 02CBh
			02CDh 02CDh 02D0h 02D0h 02D8h 02DBh
			02DDh 02DDh 02DFh 02DFh 0391h 03A1h
			03A3h 03A9h 03B1h 03C1h 03C3h 03C9h
			0401h 0401h 0410h 044Fh 0451h 0451h
			2010h 2010h 2013h 2016h 2018h 2019h
			201Ch 201Dh 2020h 2022h 2024h 2027h
			2030h 2030h 2032h 2033h 2035h 2035h
			203Bh 203Bh 203Eh 203Eh 2074h 2074h
			207Fh 207Fh 2081h 2084h 20ACh 20ACh
			2103h 2103h 2105h 2105h 2109h 2109h
			2113h 2113h 2116h 2116h 2121h 2122h
			2126h 2126h 212Bh 212Bh 2153h 2154h
			215Bh 215Eh 2160h 216Bh 2170h 2179h
			2190h 2199h 21B8h 21B9h 21D2h 21D2h
			21D4h 21D4h 21E7h 21E7h 2200h 2200h
			2202h 2203h 2207h 2208h 220Bh 220Bh
			220Fh 220Fh 2211h 2211h 2215h 2215h
			221Ah 221Ah 221Dh 2220h 2223h 2223h
			2225h 2225h 2227h 222Ch 222Eh 222Eh
			2234h 2237h 223Ch 223Dh 2248h 2248h
			224Ch 224Ch 2252h 2252h 2260h 2261h
			2264h 2267h 226Ah 226Bh 226Eh 226Fh
			2282h 2283h 2286h 2287h 2295h 2295h
			2299h 2299h 22A5h 22A5h 22BFh 22BFh
			2312h 2312h 2460h 24E9h 24EBh 254Bh
			2550h 2573h 2580h 258Fh 2592h 2595h
			25A0h 25A1h 25A3h 25A9h 25B2h 25B3h
			25B6h 25B7h 25BCh 25BDh 25C0h 25C1h
			25C6h 25C8h 25CBh 25CBh 25CEh 25D1h
			25E2h 25E5h 25EFh 25EFh 2605h 2606h
			2609h 2609h 260Eh 260Fh 2614h 2615h
			261Ch 261Ch 261Eh 261Eh 2640h 2640h
			2642h 2642h 2660h 2661h 2663h 2665h
			2667h 266Ah 266Ch 266Dh 266Fh 266Fh
			273Dh 273Dh 2776h 277Fh E000h F8FFh
			FFFDh FFFDh 000F0000h 000FFFFDh 00100000h 0010FFFDh
		]

		in-cp-table?: func [
			cp		[integer!]
			table	[int-ptr!]
			return: [logic!]
			/local
				a	[integer!]
				b	[integer!]
				max [integer!]
		][
			max: size? table
			if any [cp < table/1 cp > table/max][return no]

			a: -1
			until [
				a: a + 2
				b: a + 1
				if all [cp > table/a cp < table/b][return yes]
				b = max
			]
			no
		]

		wcwidth?: func [
			cp		[integer!]
			return: [integer!]
		][
			if zero? cp [return 0]
			if any [						;-- tests for 8-bit control characters
				cp < 32
				all [cp >= 7Fh cp < A0h]
			][return -1]

			if in-cp-table? cp combining-table [return 0]

			if all [
				cp >= 1100h
				any [
					cp <= 115Fh									;-- Hangul Jamo init. consonants
					cp = 2329h
					cp = 232Ah
					all [cp >= 2E80h cp <= A4CFh cp <> 303Fh]	;-- CJK ... Yi
					all [cp >= AC00h cp <= D7A3h]				;-- Hangul Syllables
					all [cp >= F900h cp <= FAFFh]				;-- CJK Compatibility Ideographs
					all [cp >= FE10h cp <= FE19h]				;-- Vertical forms
					all [cp >= FE30h cp <= FE6Fh]				;-- CJK Compatibility Forms
					all [cp >= FF00h cp <= FF60h]				;-- Fullwidth Forms
					all [cp >= FFE0h cp <= FFE6h]
					all [cp >= 00020000h cp <= 0002FFFDh]
					all [cp >= 00030000h cp <= 0003FFFDh]
				]
			][return 2]
			1
		]

		widechar?: func [
			str			[red-string!]
			return:		[logic!]
			/local
				cp		[integer!]
				unit	[integer!]
				s		[series!]
				offset	[byte-ptr!]
		][
			s: GET_BUFFER(str)
			unit: GET_UNIT(s)
			offset: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
			cp: 0
			if offset < as byte-ptr! s/tail [cp: string/get-char offset unit]
			cp > FFh
		]

		on-resize: does [
			get-window-size
			refresh
		]

		fetch-history: does [
			string/rs-reset input-line
			string/concatenate input-line as red-string! block/rs-head history -1 0 yes no
			input-line/head: string/get-length input-line yes
		]

		init-buffer: func [
			str			[red-string!]
			/local
				unit	[integer!]
				s		[series!]
				size	[integer!]
		][
			s: GET_BUFFER(str)
			unit: GET_UNIT(s)
			if unit < 2 [unit: 2]			;-- always treat string as widechar string
			size: (string/rs-length? str) << (unit >> 1)
			if size > buf-size [
				buf-size: size
				free buffer
				buffer: allocate size
			]
			pbuffer: buffer
		]

		refresh: func [
			/local
				line   [red-string!]
				offset [integer!]
				bytes  [integer!]
				x	   [integer!]
				y	   [integer!]
				saved  [integer!]
				psize  [integer!]
		][
			line: input-line
			erase-to-bottom					;-- erase down to the bottom of the screen

			init-buffer line
			bytes: emit-red-string prompt columns no

			psize: bytes // columns
			offset: bytes + (emit-red-string line columns - psize yes)	;-- output until reach cursor posistion

			psize: offset // columns
			bytes: offset + (emit-red-string line columns - psize no)	;-- continue until reach tail

			output-to-screen
			set-cursor-pos line offset bytes
		]

		edit: func [
			prompt-str [red-string!]
			/local
				line   [red-string!]
				c	   [integer!]
				offset [integer!]
		][
			line: input-line			
			copy-cell as red-value! prompt-str as red-value! prompt
			history/head: block/rs-length? history		;@@ set history list to tail (temporary)
				
			get-window-size
			refresh

			while [true][
				c: fd-read
				#if OS <> 'Windows [if c = 27 [c: check-special]]

				switch c [
					KEY_ENTER [
						exit
					]
					KEY_BACKSPACE [
						unless zero? line/head [
							line/head: line/head - 1
							string/remove-char line line/head
							refresh
						]
					]
					KEY_LEFT [
						unless zero? line/head [
							line/head: line/head - 1
							refresh
						]
					]
					KEY_RIGHT [
						if 0 < string/rs-length? line [
							line/head: line/head + 1
							refresh
						]
					]
					KEY_UP [
						unless zero? history/head [
							history/head: history/head - 1
							fetch-history
							line/head: string/get-length line yes
							refresh
						]
					]
					KEY_DOWN [
						unless block/rs-tail? history [
							history/head: history/head + 1
							either block/rs-tail? history [
								string/rs-reset line
							][
								fetch-history
							]
							refresh
						]
					]
					KEY_HOME 
					KEY-CTRL-A [
						line/head: 0
						refresh
					]
					KEY_END
					KEY-CTRL-E [
						line/head: string/get-length line yes
						refresh
					]
					KEY_DELETE [
						unless string/rs-tail? line [
							string/remove-char line line/head
							refresh
						]
					]
					KEY_PAGE_UP
					KEY_PAGE_DOWN
					KEY_UNSET
					KEY_NONE []						;-- do nothing
					
					default [
						either zero? string/rs-length? line [
							string/append-char GET_BUFFER(line) c
						][
							string/insert-char GET_BUFFER(line) line/head c
						]
						line/head: line/head + 1
						refresh
					]
				]
			]
			line/head: 0
		]
	]
]

init-console: routine [line [string!] hist [block!]][
	terminal/init line hist
]

input: routine [prompt [string!]][
	terminal/edit prompt
	terminal/restore
]


input-line: make string! 10'000

history: [
	"hello world"
	{print mold [append "hello" [40 + 2] "world"]}
	"mold 2 + 3"
	"1 + 2"
]

init-console input-line history

input "red> "
print lf

print ["input:" mold head input-line]
