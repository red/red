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


#define COORD_Y(value)      (value >>> 16)
#define COORD_X(value)      (value and 0000FFFFh)       
#define coord! integer!

CONSOLE_SCREEN_BUFFER_INFO!: alias struct! [
	size                [coord!]
	cursor              [coord!]
	attributes          [integer!]
	leftTop             [coord!]
	rightBottom         [coord!]
	maximumWindowSize   [coord!]
]

csbi: declare CONSOLE_SCREEN_BUFFER_INFO!
saved-cursor: declare coord!

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

clear-console: func[
	/local
		handle [integer!]
		num    [integer!]
		len    [integer!]
][
	GetConsoleScreenBufferInfo stdout csbi
	num: 0
	len: COORD_X(csbi/size) * COORD_Y(csbi/size)
	FillConsoleOutputCharacter stdout as-integer #" " len 0 :num
	FillConsoleOutputAttribute stdout csbi/attributes len 0 :num ;@@ when I do this, next time changed background is not used to the end of line :/
	                                                             ;@@ but when I don't do this, previously used background would not be cleared
	SetConsoleCursorPosition stdout 0
]
console-store-position: does [
	GetConsoleScreenBufferInfo stdout csbi
	saved-cursor: csbi/cursor
]
set-console-cursor: func[
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
		attribute: csbi/attributes
	]
	switch value [
		0  [attribute: FOREGROUND_GREY]
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
		39 [attribute: attribute and F7h] ; FOREGROUND_INTENSITY]
		40 [attribute: (attribute and 8Fh)]
		41 [attribute: (attribute and 8Fh) or BACKGROUND_RED]
		42 [attribute: (attribute and 8Fh) or BACKGROUND_GREEN]
		43 [attribute: (attribute and 8Fh) or BACKGROUND_YELLOW]
		44 [attribute: (attribute and 8Fh) or BACKGROUND_BLUE]
		45 [attribute: (attribute and 8Fh) or BACKGROUND_MAGENTA]
		46 [attribute: (attribute and 8Fh) or BACKGROUND_CYAN]
		47 [attribute: (attribute and 8Fh) or BACKGROUND_GREY]
		49 [attribute: attribute and 7Fh] ; BACKGROUND_INTENSITY]
		default [attribute: value]
	]
	attribute
]

;-- Based on http://ascii-table.com/ansi-escape-sequences.php
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
						;@@ todo
						state: -1
					]
					cp = #"J" [ ;-- Clear screen from cursor down.
						;@@ todo
						state: -1
					]
					any [cp = #"H" cp = #"f"] [
						set-console-cursor 0
						state: -1
					]
					cp = #"?" [	;@@ just for testing purposes
						GetConsoleScreenBufferInfo stdout csbi
						print-line "Screen buffer info:"
						print-line ["   size______ " COORD_X(csbi/size) "x" COORD_Y(csbi/size)]
						print-line ["   cursor____ " COORD_X(csbi/cursor) "x" COORD_Y(csbi/cursor)]
						print-line ["   attribute_ " csbi/attributes]
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
						row: COORD_Y(cursor) - value1
						if row < 0 [ row: 0 ]
						set-console-cursor (cursor and 0000FFFFh) or (row << 16)
						state: -1
					]
					cp = #"B" [ ;-- Cursor Down.
						GetConsoleScreenBufferInfo stdout csbi
						cursor: csbi/cursor
						row: COORD_Y(cursor) + value1
						if row < COORD_Y(csbi/size) [ row: COORD_Y(csbi/size) ]
						set-console-cursor (cursor and 0000FFFFh) or (row << 16)
						state: -1
					]
					cp = #"C" [ ;-- Cursor Forward.
						GetConsoleScreenBufferInfo stdout csbi
						cursor: csbi/cursor
						col: COORD_X(cursor) + value1
						if col > COORD_X(csbi/size)  [ col: COORD_X(csbi/size) ]
						set-console-cursor (cursor and FFFF0000h) or (col and 0000FFFFh)
						state: -1
					]
					cp = #"D" [ ;-- Cursor Backward.
						GetConsoleScreenBufferInfo stdout csbi
						cursor: csbi/cursor
						col: COORD_X(cursor) - value1
						if col < 0 [ col: 0 ]
						set-console-cursor (cursor and FFFF0000h) or (col and 0000FFFFh)
						state: -1
					]
					cp = #"J" [
						if value1 = 2 [clear-console]
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

