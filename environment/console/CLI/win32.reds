Red/System [
	Title:	"INPUT win32 API imported functions and structures definitions"
	Author: "Nenad Rakocevic, Xie Qingtian"
	File: 	%win32.reds
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

#either modules contains 'View [][
	#define VK_BACK 				08h
	#define VK_TAB 					09h
	#define VK_CLEAR 				0Ch
	#define VK_RETURN 				0Dh
	#define VK_SHIFT				10h
	#define VK_CONTROL				11h
	#define VK_PRIOR				21h
	#define VK_NEXT					22h
	#define VK_END					23h
	#define VK_HOME					24h
	#define VK_LEFT					25h
	#define VK_UP					26h
	#define VK_RIGHT				27h
	#define VK_DOWN					28h
	#define VK_SELECT				29h
	#define VK_INSERT				2Dh
	#define VK_DELETE				2Eh
]

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
	]
]

input-rec: declare input-record!
saved-con: 0
utf-char: allocate 10
bottom-y: 0

#define FIRST_WORD(int) (int and FFFFh)
#define SECOND_WORD(int) (int >>> 16)

isatty: func [
	handle	[int-ptr!]
	return:	[logic!]
][
	2 = GetFileType handle			;-- FILE_TYPE_CHAR: 2
]

stdin-read: func [
	return:		[integer!]
	/local
		i		[integer!]
		c		[integer!]
		len		[integer!]
		read-sz [integer!]
][
	read-sz: 0
	if zero? ReadFile stdin utf-char 1 :read-sz null [return -1]

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
			zero? 	ReadFile stdin utf-char + i 1 :read-sz null
		][
			return -1
		]
		i: i + 1
	]
	c: unicode/decode-utf8-char as-c-string utf-char :len
	c
]

fd-read: func [
	return: 	[integer!]
	/local
		key 	[key-event!]
		n	 	[integer!]
		keycode [integer!]
		size    [red-pair!]
		c		[integer!]
][
	n: 0
	forever [
		if zero? ReadConsoleInput stdin as-integer input-rec 1 :n [return -1]
		switch input-rec/EventType and FFFFh [
			KEY_EVENT [
				key: as key-event! (as-integer input-rec) + (size? integer!)
				if key/KeyDown <> 0 [
					keycode: SECOND_WORD(key/RepeatCnt-KeyCode)  ;-- 1st RepeatCnt 2 KeyCode
					c: SECOND_WORD(key/ScanCode-Char)
					case [
						 zero? c [
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
								VK_RETURN	[return KEY_ENTER]
								default		[return KEY_NONE]
							]
						]
						keycode = VK_CONTROL []
						true [return c] ;-- return Char
					]
				]
			]
			WINDOW_BUFFER_SIZE_EVENT [
				get-window-size
			]
			;FOCUS_EVENT
			;MENU_EVENT
			;MOUSE_EVENT
			default []
		]
	]
	-1
]

get-window-size: func [
	return: 	[integer!]
	/local
		info 	[screenbuf-info! value]
		x-y 	[integer!]
		size    [red-pair!]
][
	size: as red-pair! #get system/console/size
	columns: size/x
	rows: size/y
	if zero? GetConsoleScreenBufferInfo stdout :info [return -1]
	x-y: info/Size
	columns: FIRST_WORD(x-y)
	rows: SECOND_WORD(x-y)
	size/x: SECOND_WORD(info/top-right) - SECOND_WORD(info/attr-left) + 1
	size/y: FIRST_WORD(info/bottom-maxWidth) - FIRST_WORD(info/top-right) + 1
	if columns <= 0 [size/x: 80 columns: 80 return -1]
	cursor-pos: info/Position
	0
]

emit-red-char: func [cp [integer!] /local n][
	if hide-input? [cp: as-integer #"*"]
	n: 2 * unicode/cp-to-utf16 cp pbuffer
	pbuffer: pbuffer + n
]

reset-cursor-pos: does [
	SetConsoleCursorPosition stdout cursor-pos
]

query-cursor: func [
	pos		[int-ptr!]
	return: [logic!]
	/local
		info [screenbuf-info! value]
][
	GetConsoleScreenBufferInfo stdout :info
	pos/value: info/Position
	true
]

erase-to-bottom: func [
	/local
		n	 [integer!]
		info [screenbuf-info! value]
		x-y  [integer!]
		x	 [integer!]
][
	x: FIRST_WORD(cursor-pos)
	n: 0
	GetConsoleScreenBufferInfo stdout :info
	x-y: info/Position
	FillConsoleOutputCharacter							;-- clear screen
		stdout
		20h												;-- #" " = 20h
		rows - SECOND_WORD(x-y) * columns - x			;-- (rows - y) * columns - x
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
		y2	[integer!]
		yy	[integer!]
		xx	[integer!]
		n	[integer!]
][
	fflush 0

	y: offset / columns
	x: offset // columns
	if all [
		widechar? line
		columns - x = 1
	][
		y: y + 1
		x: 0
	]

	if all [zero? x offset = size][ ;-- write a newline to force the scrolling
		n: 0
		WriteConsole stdout as byte-ptr! #u16 "^/" 1 :n null
	]

	xx: FIRST_WORD(cursor-pos)
	yy: SECOND_WORD(cursor-pos)
	SetConsoleCursorPosition stdout yy + y << 16 or x

	n: size / columns + 1		;-- the lines of all outputs occupy
	n: n - (rows - yy)
	if n > 0 [
		yy: yy - n
		if yy < 0 [yy: 0]
		cursor-pos: yy << 16 or xx
	]
	bottom-y: yy + (size / columns)
]

move-cursor-bottom: does [
	SetConsoleCursorPosition stdout bottom-y << 16
]

output-to-screen: func [/local n][
	n: 0
	WriteConsole stdout buffer (as-integer pbuffer - buffer) / 2 :n null
]

init: func [][
	console?: isatty as int-ptr! stdin
	if console? [
		get-window-size
	]
]

init-console: func [
	/local
		mode	[integer!]
][
	if console? [
		GetConsoleMode stdin :saved-con
		mode: saved-con and (not ENABLE_PROCESSED_INPUT)	;-- turn off PROCESSED_INPUT, so we can handle control-c
		mode: mode or ENABLE_QUICK_EDIT_MODE or ENABLE_WINDOW_INPUT	;-- use the mouse to select and edit text
		SetConsoleMode stdin mode
		buffer: allocate buf-size
	]
]

restore: does [
	SetConsoleMode stdin saved-con free buffer
]
