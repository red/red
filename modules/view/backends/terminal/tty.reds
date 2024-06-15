Red/System [
	Title:	"terminal related functions"
	Author: "Xie Qingtian"
	File: 	%tty.reds
	Tabs: 	4
	Rights: "Copyright (C) 2023 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

tty: context [

	columns:		-1
	rows:			-1
	raw-mode?:	 	no
	cursor-hide?:	no

	#enum DECMode! [ ;-- DEC: Digital Equipment Corporation
  		LineWrapMode:			7
  		CursorMode:				25

  		MouseX10:				9
  		MouseVt200:				1000
  		MouseVt200Highlight:	1001

  		MouseBtnEvent:			1002
  		MouseAnyEvent:			1003

  		MouseUtf8:				1005
  		MouseSgrExt:			1006
  		MouseUrxvt:				1015
  		MouseSgrPixels:			1016
  		AlternateScreen:		1049
	]

	enable: func [
		mode [integer!]
		/local
			buf [tiny-str! value]
			p	[c-string!]
	][
		p: as c-string! :buf
		sprintf [p "^[[?%dh" mode]
		write as byte-ptr! p length? p
	]

	disable: func [
		mode [integer!]
		/local
			buf [tiny-str! value]
			p	[c-string!]
	][
		p: as c-string! :buf
		sprintf [p "^[[?%dl" mode]
		write as byte-ptr! p length? p
	]

	report-cursor-position: func [][
		write as byte-ptr! "^[[6n" 4
	]

	enter-alter-screen: does [
		enable AlternateScreen
		write as byte-ptr! "^[[2J" 4		;-- clear screen
	]

	exit-alter-screen: does [
		disable AlternateScreen		
	]

	enable-mouse: does [
		;-- enable mouse support
		enable MouseVt200
		enable MouseAnyEvent
		enable MouseUrxvt
		enable MouseSgrExt
	]

	disable-mouse: does [
		disable MouseVt200
		disable MouseAnyEvent
		disable MouseUrxvt
		disable MouseSgrExt
	]

	hide-cursor: does [
		unless cursor-hide? [
			disable CursorMode
			cursor-hide?: yes
		]
	]

	show-cursor: does [
		if cursor-hide? [
			enable CursorMode
			cursor-hide?: no
		]
	]

	cursor-down: func [
		n		[integer!]
		/local
			buf [tiny-str! value]
			p	[c-string!]
	][
		if n > 0 [
			p: as c-string! :buf
			sprintf [p "^[[%dB" n]
			write as byte-ptr! p length? p
		]
	]

	get-window-size: func [
		/local
			blk [red-block!]
			obj [red-object!]
			sz	[red-pair!]
	][
		OS-window-size
		blk: as red-block! #get system/view/screens
		if TYPE_OF(blk) = TYPE_BLOCK [
			obj: as red-object! block/rs-head blk
			sz: as red-pair! (object/get-values obj) + FACE_OBJ_SIZE
			sz/header: TYPE_PAIR
			sz/x: columns
			sz/y: rows
		]
		if raw-mode? [screen/on-resize columns rows]
	]

	init: does [
		if all [not raw-mode? isatty?][
			enter-raw-mode
			;enable-mouse
			get-window-size
			raw-mode?: yes
		]
		unless screen/alternate-screen? [report-cursor-position]
	]

	restore: does [
		if raw-mode? [
			;disable-mouse
			exit-raw-mode
			raw-mode?: no
		]
	]

	#either OS = 'Windows [

		#define VK_BACK 				 			08h
		#define VK_TAB 					 			09h
		#define VK_CLEAR 				 			0Ch
		#define VK_RETURN 				 			0Dh
		#define VK_SHIFT							10h
		#define VK_CONTROL							11h
		#define VK_PRIOR							21h
		#define VK_NEXT								22h
		#define VK_END								23h
		#define VK_HOME								24h
		#define VK_LEFT								25h
		#define VK_UP								26h
		#define VK_RIGHT							27h
		#define VK_DOWN								28h
		#define VK_SELECT							29h
		#define VK_INSERT							2Dh
		#define VK_DELETE							2Eh

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

		;@@ use integer16! once available as values are in words
		screenbuf-info!: alias struct! [	;-- size? screenbuf-info! = 22
			Size	        [integer!]     	;typedef struct _CONSOLE_SCREEN_BUFFER_INFO {
			Position        [integer!]     	;  COORD dwSize;		offset: 0
			attr-left       [integer!]     	;  COORD dwCursorPosition;		4
			top-right       [integer!]     	;  WORD wAttributes;			8
			bottom-maxWidth [integer!]     	;  SMALL_RECT srWindow;			10
			pad4 	  [byte!]           	;  COORD dwMaximumWindowSize;	18
			pad5 	  [byte!]           	;} CONSOLE_SCREEN_BUFFER_INFO,*PCONSOLE_SCREEN_BUFFER_INFO;
		]									;-- sizeof(CONSOLE_SCREEN_BUFFER_INFO) = 22

		#import [
			"kernel32.dll" stdcall [
				ReadFile:	"ReadFile" [
					file		[integer!]
					buffer		[byte-ptr!]
					bytes		[integer!]
					read		[int-ptr!]
					overlapped	[int-ptr!]
					return:		[integer!]
				]
				GetNumberOfConsoleInputEvents: "GetNumberOfConsoleInputEvents" [
					hInput		[handle!]
					lpcNumEvent [int-ptr!]
					return:		[integer!]
				]
				ReadConsoleInput: "ReadConsoleInputW" [
					handle			[integer!]
					arrayOfRecs		[input-record!]
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
				WriteConsole: 	 "WriteConsoleA" [
					consoleOutput	[integer!]
					buffer			[byte-ptr!]
					charsToWrite	[integer!]
					numberOfChars	[int-ptr!]
					_reserved		[int-ptr!]
					return:			[integer!]
				]
				GetConsoleScreenBufferInfo: "GetConsoleScreenBufferInfo" [
					handle 			[handle!]
					info 			[screenbuf-info!]
					return: 		[integer!]
				]
				GetConsoleWindow: "GetConsoleWindow" [
					return:			[int-ptr!]
				]
				GetFileType: "GetFileType" [
					hFile			[int-ptr!]
					return:			[integer!]
				]
				WaitForSingleObject: "WaitForSingleObject" [
					hHandle			[handle!]
					dwMs			[integer!]
					return:			[integer!]
				]
				GetConsoleOutputCP: "GetConsoleOutputCP" [
					return:			[integer!]
				]
				SetConsoleOutputCP: "SetConsoleOutputCP" [
					wCodepangeId	[integer!]
					return:			[integer!]
				]
			]
		]

		hide-input?:		no
		saved-out-mode:		0
		saved-in-mode:		0
		saved-in-cp:		0
		saved-out-cp:		0

		isatty: func [
			handle	[int-ptr!]
			return:	[logic!]
		][
			2 = GetFileType handle			;-- FILE_TYPE_CHAR: 2
		]

		OS-window-size: func [
			return: 	[integer!]
			/local
				info 	[screenbuf-info! value]
				x-y 	[integer!]
		][
			columns: 80
			rows: 24
			if zero? GetConsoleScreenBufferInfo as handle! stdout :info [return -1]
			x-y: info/Size
			columns: x-y and FFFFh
			rows: x-y >>> 16
			if any [columns <= 0 rows <= 0][columns: 80 rows: 24 return -1]
			0
		]

		isatty?: func [return: [logic!]][
			isatty as int-ptr! stdin
		]

		write: func [
			data	[byte-ptr!]
			len		[integer!]
			/local
				n	[integer!]
		][
			n: 0
			platform/WriteFile stdout as c-string! data len :n 0
		]

		enter-raw-mode: func [/local mode [integer!]][
			saved-out-cp: GetConsoleOutputCP
			;Note: we don't set input to UTF-8 mode because it's buggy
			SetConsoleOutputCP 65001

			GetConsoleMode stdin :saved-in-mode
			mode: saved-in-mode and (not ENABLE_PROCESSED_INPUT)	;-- turn off PROCESSED_INPUT, so we can handle control-c
			mode: mode and (not ENABLE_ECHO_INPUT)
			mode: mode and (not ENABLE_LINE_INPUT)
			mode: mode or ENABLE_WINDOW_INPUT						;-- size change event
			mode: mode or ENABLE_VIRTUAL_TERMINAL_INPUT
			SetConsoleMode stdin mode

			GetConsoleMode stdout :saved-out-mode
			mode: saved-out-mode or DISABLE_NEWLINE_AUTO_RETURN
			mode: mode or ENABLE_VIRTUAL_TERMINAL_PROCESSING
			SetConsoleMode stdout mode
		]

		exit-raw-mode: does [
			SetConsoleMode stdin saved-in-mode
			SetConsoleMode stdout saved-out-mode
			SetConsoleOutputCP saved-out-cp
		]

		restore-output: does [
			SetConsoleMode stdout saved-out-mode
		]

		set-output: func [/local mode [integer!]][
			mode: saved-out-mode or DISABLE_NEWLINE_AUTO_RETURN
			mode: mode or ENABLE_VIRTUAL_TERMINAL_PROCESSING
			SetConsoleMode stdout mode
		]

		read-input: func [
			parse?		[logic!]
			return:		[integer!]
			/local
				cnt		[integer!]
				key 	[key-event!]
				n	 	[integer!]
				c		[integer!]
				cc		[integer!]
				records [input-record!]
				record	[input-record!]
		][
			n: 0
			if zero? GetNumberOfConsoleInputEvents as handle! stdin :n [
				return 0
			]
			if n <= 0 [return 0]

			cnt: n
			records: as input-record! system/stack/allocate (size? input-record!) >> 2 * cnt
			n: 0
			if zero? ReadConsoleInput stdin records cnt :n [return 0]

			unless parse? [return cnt]		;-- just clear the stdin queue

			cc: 0
			record: records
			while [n <> 0][
				switch record/EventType and FFFFh [
					KEY_EVENT [
						key: as key-event! (as-integer record) + (size? integer!)
						if key/KeyDown <> 0 [						 ;-- handle key down event
							c: key/ScanCode-Char >>> 16				 ;-- UTF-16
							if cc >= D800h [
								c: cc and 03FFh << 10 + (c and 03FFh) + 00010000h
								cc: 0
							]
							either all [c >= D800h c < DC00h][
								cc: c
							][
								ansi-parser/add-char c
							]
						]
					]
					WINDOW_BUFFER_SIZE_EVENT [
						get-window-size
					]
					default [0]
				]
				record: record + 1
				n: n - 1
			]
			cnt
		]

		wait: func [ms [integer!]][
			WaitForSingleObject as handle! stdin ms
		]

	][	;-- Linux and macOS

		old-act:	declare sigaction!
		saved-term: declare termios!

		OS-window-size: func [
			/local
				ws	 [winsize! value]
		][
			ioctl stdout TIOCGWINSZ ws
			columns: ws/rowcol >> 16
			rows: ws/rowcol and FFFFh
		]

		on-resize: func [[cdecl] sig [integer!]][
			get-window-size
		]

		isatty?: func [return: [logic!]][
			1 = isatty stdin
		]

		write: func [
			data	[byte-ptr!]
			len		[integer!]
		][
			platform/io-write stdout data len
		]

		enter-raw-mode: func [
			/local
				term [termios! value]
				cc	 [byte-ptr!]
				so	 [sigaction! value]
		][
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
				any [OS = 'macOS OS = 'FreeBSD OS = 'NetBSD] [
					cc: (as byte-ptr! term) + (4 * size? integer!)
				]
				true [cc: (as byte-ptr! term) + (4 * size? integer!) + 1]
			]
			cc/TERM_VMIN:  as-byte 1
			cc/TERM_VTIME: as-byte 0

			tcsetattr stdin TERM_TCSADRAIN term
		]

		exit-raw-mode: does [
			tcsetattr stdin TERM_TCSADRAIN saved-term
			#if OS <> 'Linux [sigaction SIGWINCH old-act null]
		]


		restore-output: does []

		set-output: func [][]

		read-input: func [
			parse?	[logic!]
			return: [integer!]
			/local
				buf [tiny-str! value]
				p	[byte-ptr!]
				n	[integer!]
				i	[integer!]
		][
			if 0 >= wait 0 [return 0]	;-- no input
		
			p: as byte-ptr! :buf
			n: read stdin p size? tiny-str!
			unless parse? [return n]

			i: 0
			while [i < n][
				i: i + 1
				ansi-parser/add-byte p/i
			]
			n
		]

		wait: func [
			ms		[integer!]
			return: [integer!]
			/local
				poller [pollfd! value]
		][
			poller/fd: stdin
			poller/events: OS_POLLIN
			poll poller 1 ms
		]
	]
]