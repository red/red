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

		#define TERM_TCSADRAIN	1

		#either OS = 'MacOSX [
			#define TIOCGWINSZ	40087468h
		][
			#define TIOCGWINSZ	5413h
		]

		pollfd!: alias struct! [
			fd				[integer!]
			events			[integer!]						;-- high 16-bit: events
		]													;-- low  16-bit: revents

		winsize!: alias struct! [
			rowcol			[integer!]
			xypixel			[integer!]
		]

		termios!: alias struct! [
			c_iflag			[integer!]
			c_oflag			[integer!]
			c_cflag			[integer!]
			c_lflag			[integer!]
			c_line			[byte!]
			c_cc1			[byte!]							;-- c_cc[32]
			c_cc2			[byte!]
			c_cc3			[byte!]
			c_cc4			[integer!]
			c_cc5			[integer!]
			c_cc6			[integer!]
			c_cc7			[integer!]
			c_cc8			[integer!]
			c_cc9			[integer!]
			c_cc10			[integer!]
			pad				[integer!]						;-- for proper alignment
			c_ispeed		[integer!]
			c_ospeed		[integer!]
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
		][
			x:		0
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
					cnt: either cp > FFh [
						either size - cnt = 1 [x: 2 cnt + 3][cnt + 2]	;-- reach screen edge, handle wide char
					][
						cnt + 1
					]
					case [
						cp <= 7Fh [
							emit as-byte cp
						]
						cp <= 07FFh [
							emit as-byte cp >> 6 or C0h
							emit as-byte cp and 3Fh or 80h
						]
						cp <= FFFFh [
							emit as-byte cp >> 12 or E0h
							emit as-byte cp >> 6 and 3Fh or 80h
							emit as-byte cp and 3Fh or 80h
						]
						cp <= 001FFFFFh [
							emit as-byte cp >> 18 or F0h
							emit as-byte cp >> 12 and 3Fh or 80h
							emit as-byte cp >>  6 and 3Fh or 80h
							emit as-byte cp and 3Fh or 80h
						]
						true [
							print-line "Error in emit-red-string: codepoint > 1FFFFFh"
						]
					]
					offset: offset + unit
				]
				bytes: bytes + cnt
				if cnt = size [
					emit-string "^(0A)^[[0G"				;-- emit new line and set cursor to start.
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

		refresh: func [
			/local
				line   [red-string!]
				offset [integer!]
				x	   [integer!]
				y	   [integer!]
				saved  [integer!]
				psize  [integer!]
		][
			line: input-line
			if positive? lines-y [emit-string-int "^[[" lines-y #"A"]	;-- move to origin row
			emit-string "^(0D)^[[J"					;-- erase down to the bottom of the screen

			bytes: emit-red-string prompt columns no

			psize: bytes // columns
			offset: bytes + (emit-red-string line columns - psize yes)	;-- output until reach cursor posistion

			psize: offset // columns
			bytes: offset + (emit-red-string line columns - psize no)	;-- continue until reach tail

			lines-y: bytes / columns		;-- the lines of all outputs occupy
			y: bytes / columns  - (offset / columns)
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
			cc: (as byte-ptr! term) + (4 * size? integer!) + 2
			cc/TERM_VMIN:  as-byte 1
			cc/TERM_VTIME: as-byte 0

			tcsetattr stdin TERM_TCSADRAIN term
			
			poller/fd: stdin
			poller/events: OS_POLLIN
		]

		restore: does [
			tcsetattr stdin TERM_TCSADRAIN saved-term			
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

		#define STRUCT_MEMBER(base offset) ((as-integer base) + offset)
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
				key: as key-event! STRUCT_MEMBER(input-rec (size? integer!))

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
					WriteConsole stdout (as byte-ptr! :cp) 1 :n null
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

		refresh: func [
			/local
				line	[red-string!]
				offset	[integer!]
				n		[integer!]
				x		[integer!]
				y		[integer!]
				x-y		[integer!]
				bytes	[integer!]
				psize	[integer!]
				info	[screenbuf-info!]
		][
			n:	  0
			line: input-line

			SetConsoleCursorPosition stdout base-y << 16

			info: declare screenbuf-info!
			GetConsoleScreenBufferInfo stdout as-integer info
			x-y: info/Position
			FillConsoleOutputCharacter							;-- clear screen
				stdout
				20h												;-- #" " = 20h
				rows - SECOND_WORD(x-y) * columns
				x-y
				:n

			bytes: emit-red-string prompt columns no

			psize: bytes // columns
			offset: bytes + (emit-red-string line columns - psize yes)	;-- output until reach cursor posistion

			psize: offset // columns
			bytes: offset + (emit-red-string line columns - psize no)	;-- continue until reach tail

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

		restore: does [SetConsoleMode stdin saved-con]

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

		input-line: declare red-string!
		saved-line:	declare red-string!
		prompt:		declare	red-string!
		history:	declare red-block!
		columns:	-1
		rows:		-1

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
