Red/System [
	Title:   "ANSI Escape sequences support in Windows CLI console"
	Author:  "Oldes"
	File: 	 %win32-ansi.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2017 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#define FOREGROUND_BLACK 		   00h
#define FOREGROUND_BLUE 		   01h
#define FOREGROUND_GREEN 	 	   02h
#define FOREGROUND_CYAN 	 	   03h
#define FOREGROUND_RED 		 	   04h
#define FOREGROUND_MAGENTA	 	   05h
#define FOREGROUND_YELLOW	 	   06h
#define FOREGROUND_GREY		 	   07h
#define FOREGROUND_INTENSITY	   08h
#define FOREGROUND_WHITE	 	   0Fh
#define BACKGROUND_BLUE			   10h
#define BACKGROUND_CYAN 	 	   30h
#define BACKGROUND_GREEN		   20h
#define BACKGROUND_RED			   40h
#define BACKGROUND_MAGENTA	 	   50h
#define BACKGROUND_YELLOW	 	   60h
#define BACKGROUND_GREY		 	   70h
#define BACKGROUND_INTENSITY	   80h
#define COMMON_LVB_REVERSE_VIDEO 4000h
#define COMMON_LVB_UNDERSCORE    8000h

#enum ansi-erase-mode! [
	ERASE_DOWN
	ERASE_UP
	ERASE_SCREEN
	ERASE_LINE
	ERASE_LINE_END
	ERASE_LINE_START
]



#define LOWORD(int) (int and FFFFh)
#define HIWORD(int) (int >>> 16)
#define coord! integer!

CONSOLE_SCREEN_BUFFER_INFO!: alias struct! [
	size            [integer!]
	cursor          [integer!]
	attr-left       [integer!]
	top-right       [integer!]
	bottom-maxWidth [integer!]
	maxHeigth       [integer!]
]

csbi: declare CONSOLE_SCREEN_BUFFER_INFO!

saved-cursor: 0
;user can change default colors in properties and we must use this settings for correct reset
default-attributes: 0 ;this value holds default attributes and is used on `reset` command 

#import [
	"kernel32.dll" stdcall [
		SetConsoleTextAttribute: "SetConsoleTextAttribute" [
			handle 		[integer!]
			attributes  [integer!]
			return:		[integer!]
		]
		SetConsoleCursorPosition: "SetConsoleCursorPosition" [
			handle      [integer!]
			position    [coord!]
			return:     [integer!]
		]
		GetConsoleScreenBufferInfo: "GetConsoleScreenBufferInfo" [
			handle 		[integer!]
			info        [CONSOLE_SCREEN_BUFFER_INFO!]
			return:		[integer!]
		]
		FillConsoleOutputCharacter: "FillConsoleOutputCharacterW" [
			handle 		[integer!]
			wchar       [integer!]
			length      [integer!]
			writeCoord  [coord!]
			written     [int-ptr!]
			return:     [integer!]
		]
		FillConsoleOutputAttribute: "FillConsoleOutputAttribute" [
			handle 		[integer!]
			attributes  [integer!]
			length      [integer!]
			writeCoord  [coord!]
			written     [int-ptr!]
			return:     [integer!]
		]
	]
]

;-------------------------------------------
;-- ANSI escape sequence emulation          
;-------------------------------------------
console-store-position: does [
	GetConsoleScreenBufferInfo stdout csbi
	saved-cursor: csbi/cursor
]
console-store-default: does[
	GetConsoleScreenBufferInfo stdout csbi
	default-attributes: LOWORD(csbi/attr-left)
]

clear-screen: func[
	"Clears the screen and moves the cursor to the home position (line 0, column 0)"
	mode       [ansi-erase-mode!]
	/local
		num    [integer!]
		len    [integer!]
		from   [coord!]
		cols   [integer!]
		rows   [integer!]
][
	GetConsoleScreenBufferInfo stdout csbi
	num: 0
	cols: LOWORD(csbi/size)
	rows: HIWORD(csbi/size)
	switch mode [
		ERASE_DOWN [
			len: cols * (rows - HIWORD(csbi/cursor))
			from: csbi/cursor and FFFF0000h ;@@ should it erase the line where is cursor?
		]
		ERASE_UP [
			len: cols * HIWORD(csbi/cursor)
			from: 0
		]
		ERASE_SCREEN [
			len: cols * rows
			from: 0
		]
		ERASE_LINE_END [
			len: LOWORD(csbi/size) - LOWORD(csbi/cursor)
			from: csbi/cursor
		]
		ERASE_LINE_START [
			len: LOWORD(csbi/cursor)
			from: csbi/cursor and FFFF0000h
		]
		ERASE_LINE [
			len: LOWORD(csbi/size)
			from: csbi/cursor and FFFF0000h
		]
	]
	FillConsoleOutputCharacter stdout as-integer #" " len from :num
	FillConsoleOutputAttribute stdout default-attributes len from :num
	if any [
		mode = ERASE_SCREEN
		mode = ERASE_LINE
		mode = ERASE_LINE_START ;@@ should I move cursor in this case?
	][
		SetConsoleCursorPosition stdout from
	]
]

set-console-cursor: func[
	"Moves the cursor to the specified position (coordinates)"
	position   [coord!]
][
	SetConsoleCursorPosition stdout position
]
set-console-graphic: func[
	mode  [integer!]
][
	SetConsoleTextAttribute stdout mode
]
update-graphic-mode: func[
	attribute  [integer!]
	value      [integer!]
	return: [integer!]
	/local
		tmp [integer!]
][	
	if attribute < 0 [
		GetConsoleScreenBufferInfo stdout csbi
		attribute: LOWORD(csbi/attr-left)
	]
	switch value [
		0  [attribute: default-attributes]
		1  [attribute: attribute or FOREGROUND_INTENSITY or BACKGROUND_INTENSITY]
		4  [attribute: attribute or COMMON_LVB_UNDERSCORE]
		7  [tmp: (attribute and F0h) >> 4 attribute: ((attribute and 0Fh) << 4) or tmp ] ;reverse
		30 [attribute: (attribute and F8h)]
		31 [attribute: (attribute and F8h) or FOREGROUND_RED]
		32 [attribute: (attribute and F8h) or FOREGROUND_GREEN]
		33 [attribute: (attribute and F8h) or FOREGROUND_YELLOW]
		34 [attribute: (attribute and F8h) or FOREGROUND_BLUE]
		35 [attribute: (attribute and F8h) or FOREGROUND_MAGENTA]
		36 [attribute: (attribute and F8h) or FOREGROUND_CYAN]
		37 [attribute: (attribute and F8h) or FOREGROUND_GREY]
		39 [attribute: attribute or FOREGROUND_INTENSITY]
		40 [attribute: (attribute and 8Fh)]
		41 [attribute: (attribute and 8Fh) or BACKGROUND_RED]
		42 [attribute: (attribute and 8Fh) or BACKGROUND_GREEN]
		43 [attribute: (attribute and 8Fh) or BACKGROUND_YELLOW]
		44 [attribute: (attribute and 8Fh) or BACKGROUND_BLUE]
		45 [attribute: (attribute and 8Fh) or BACKGROUND_MAGENTA]
		46 [attribute: (attribute and 8Fh) or BACKGROUND_CYAN]
		47 [attribute: (attribute and 8Fh) or BACKGROUND_GREY]
		49 [attribute: attribute or BACKGROUND_INTENSITY]
		default [attribute: value]
	]
	attribute
]

;-- Based on http://ascii-table.com/ansi-escape-sequences.php and http://www.termsys.demon.co.uk/vtansi.htm
parse-ansi-sequence: func[
	str 	[byte-ptr!]
	unit    [integer!]
	return: [integer!]
	/local
		cp      [byte!]
		bytes   [integer!]
		state   [integer!]
		value1  [integer!]
		value2  [integer!]
		command [integer!]
		attribute [integer!]
		cursor  [coord!]
		col     [integer!]
		row     [integer!]
][
	switch unit [
		Latin1 [
			if str/2 <> #"[" [return 0]
			str: str + 2
			bytes: 2
		]
		UCS-2  [
			if str/3 <> #"[" [return 0]
			str: str + 4
			bytes: 4
		]
		UCS-4  [
			if str/5 <> #"[" [return 0]
			str: str + 8
			bytes: 8
		]
	]
	state:   1
	value1:  0
	value2:  0
	attribute: -1
	until [
		cp: str/1
		str: str + unit
		bytes: bytes + unit
		switch state [
			1 [ ;value1 start
				case [
					all [cp >= #"0" cp <= #"9"][
						value1: ((value1 * 10) + (cp - #"0")) // FFFFh
						state: 2
					]
					cp = #";" [] ;do nothing
					cp = #"s" [	;-- Saves the current cursor position.
						console-store-position
						state: -1
					]
					cp = #"u" [ ;-- Returns the cursor to the position stored by the Save Cursor Position sequence.
						set-console-cursor saved-cursor
						state: -1
					]
					cp = #"K" [ ;-- Erase Line.
						clear-screen ERASE_LINE_END
						state: -1
					]
					cp = #"J" [ ;-- Clear screen from cursor down.
						clear-screen ERASE_DOWN
						state: -1
					]
					any [cp = #"H" cp = #"f"] [
						set-console-cursor 0
						state: -1
					]
					cp = #"?" [	;@@ just for testing purposes
						GetConsoleScreenBufferInfo stdout csbi
						print-line "Screen buffer info:"
						print-line ["   size______ " LOWORD(csbi/size) "x" HIWORD(csbi/size)]
						print-line ["   cursor____ " LOWORD(csbi/cursor) "x" HIWORD(csbi/cursor)]
						print-line ["   attribute_ " as int-ptr! LOWORD(csbi/attr-left) " " as int-ptr! default-attributes]
						print-line ["   left______ " HIWORD(csbi/attr-left) " top: " LOWORD(csbi/top-right)]
						print-line ["   right_____ " HIWORD(csbi/top-right) " bottom: " LOWORD(csbi/bottom-maxWidth)]
						print-line ["   max_______ " HIWORD(csbi/bottom-maxWidth) "x" LOWORD(csbi/maxHeigth)]
						state: -1
					]
					true [ state: -1 ]
				]
			]
			2 [ ;value1 continue
				case [
					all [cp >= #"0" cp <= #"9"][
						value1: ((value1 * 10) + (cp - #"0")) // FFFFh
					]
					cp = #";" [
						state: 3
					]
					cp = #"m" [
						attribute: update-graphic-mode attribute value1
						set-console-graphic attribute
						state: -1
					]
					cp = #"A" [ ;-- Cursor Up.
						GetConsoleScreenBufferInfo stdout csbi
						cursor: csbi/cursor
						row: HIWORD(cursor) - value1
						if row < 0 [ row: 0 ]
						set-console-cursor (cursor and 0000FFFFh) or (row << 16)
						state: -1
					]
					cp = #"B" [ ;-- Cursor Down.
						GetConsoleScreenBufferInfo stdout csbi
						cursor: csbi/cursor
						row: HIWORD(cursor) + value1
						if row < HIWORD(csbi/size) [ row: HIWORD(csbi/size) ]
						set-console-cursor (cursor and 0000FFFFh) or (row << 16)
						state: -1
					]
					cp = #"C" [ ;-- Cursor Forward.
						GetConsoleScreenBufferInfo stdout csbi
						cursor: csbi/cursor
						col: LOWORD(cursor) + value1
						if col > LOWORD(csbi/size)  [ col: LOWORD(csbi/size) ]
						set-console-cursor (cursor and FFFF0000h) or (col and 0000FFFFh)
						state: -1
					]
					cp = #"D" [ ;-- Cursor Backward.
						GetConsoleScreenBufferInfo stdout csbi
						cursor: csbi/cursor
						col: LOWORD(cursor) - value1
						if col < 0 [ col: 0 ]
						set-console-cursor (cursor and FFFF0000h) or (col and 0000FFFFh)
						state: -1
					]
					cp = #"J" [
						case [
							value1 = 1 [clear-screen ERASE_UP]
							value1 = 2 [clear-screen ERASE_SCREEN]
							true [] ;ignore other values
						]
						state: -1
					]
					cp = #"K" [
						case [
							value1 = 1 [clear-screen ERASE_LINE_START]
							value1 = 2 [clear-screen ERASE_LINE]
							true [] ;ignore other values
						]
						state: -1
					]
					true [ state: -1 ]
				]
			]
			3 [ ;value2 start
				case [
					all [cp >= #"0" cp <= #"9"][
						value2: ((value2 * 10) + (cp - #"0")) // FFFFh
						state: 4
					]
					cp = #";" [] ;do nothing
					true [ state: -1 ]
				]
			] ;value2 continue
			4 [
				case [
					all [cp >= #"0" cp <= #"9"][
						value2: ((value2 * 10) + (cp - #"0")) // FFFFh
					]
					cp = #"m" [
						attribute: update-graphic-mode update-graphic-mode attribute value1 value2
						set-console-graphic attribute
						state: -1 
					]
					cp = #";" [
						attribute: update-graphic-mode update-graphic-mode attribute value1 value2
						value1: 0
						value2: 0
						state: 1
					]
					any [cp = #"H" cp = #"f"] [ ;-- Cursor Position.
						set-console-cursor (value1 and 0000FFFFh) or (value2 << 16)
						state: -1
					]
					true [ state: -1 ]
				]
			]
		]
		state < 0
	]
	bytes
]

console-store-default