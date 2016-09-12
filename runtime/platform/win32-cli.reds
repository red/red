Red/System [
	Title:   "Red runtime win32 command line print functions"
	Author:  "Nenad Rakocevic"
	File: 	 %win32-cli.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

confd: -2
buffer: allocate 1024
pbuffer: buffer ;this stores buffer's head position

;-------------------------------------------
;-- Initialize console ouput handle
;-------------------------------------------
init-console-out: func [][
	confd: simple-io/CreateFileA
				"CONOUT$"
				GENERIC_WRITE
				FILE_SHARE_READ or FILE_SHARE_WRITE
				null
				OPEN_EXISTING
				0
				null
]

;-------------------------------------------
;-- putwchar use windows api internal
;-------------------------------------------
putwchar: func [
	wchar	[integer!]								;-- wchar is 16-bit on Windows
	return:	[integer!]
	/local
		n	[integer!]
		cr	[integer!]
		con	[integer!]
][
	n: 0
	cr: as integer! #"^M"

	con: GetConsoleMode _get_osfhandle fd-stdout :n		;-- test if output is a console
	either con > 0 [									;-- output to console
		if confd = -2 [init-console-out]
		if confd = -1 [return WEOF]
		WriteConsole confd (as byte-ptr! :wchar) 1 :n null
	][													;-- output to redirection file
		if wchar = as integer! #"^/" [					;-- convert lf to crlf
			WriteFile _get_osfhandle fd-stdout (as c-string! :cr) 2 :n 0
		]
		WriteFile _get_osfhandle fd-stdout (as c-string! :wchar) 2 :n 0
	]
	wchar
]

;-------------------------------------------
;-- putbuffer use windows api internal
;-------------------------------------------
putbuffer: func [
	chars [integer!]
	return: [integer!]
	/local
		n	[integer!]
		con	[integer!]
][
	n: 0
	con: GetConsoleMode _get_osfhandle fd-stdout :n		;-- test if output is a console
	either con > 0 [									;-- output to console
		if confd = -2 [init-console-out]
		if confd = -1 [return WEOF]					
		WriteConsole confd pbuffer chars :n null
	][													;-- output to redirection file
		WriteFile _get_osfhandle fd-stdout as c-string! pbuffer 2 * chars :n 0
	]
	buffer: pbuffer
	chars
]

;-------------------------------------------
;-- Print a UCS-4 string to console
;-------------------------------------------
print-UCS4: func [
	str    [int-ptr!]								;-- UCS-4 string
	size   [integer!]
	/local
		cp [integer!]								;-- codepoint
][
	assert str <> null

	while [not zero? size][
		cp: str/value
		either cp > FFFFh [
			cp: cp - 00010000h						;-- encode surrogate pair
			putwchar cp >> 10 + D800h				;-- emit lead
			putwchar cp and 03FFh + DC00h			;-- emit trail
		][
			putwchar cp								;-- UCS-2 codepoint
		]
		str: str + 1
		size: size - 4
	]
]

;-------------------------------------------
;-- Print a UCS-4 string to console
;-------------------------------------------
print-line-UCS4: func [
	str    [int-ptr!]								;-- UCS-4 string
	size   [integer!]
][
	assert str <> null
	print-UCS4 str size								;@@ throw an error on failure
	putwchar 10										;-- newline
]

;-------------------------------------------
;-- Print a UCS-2 string to console
;-------------------------------------------
print-UCS2: func [
	str 	[byte-ptr!]								;-- UCS-2 string
	size	[integer!]
	/local
		chars [integer!]
][
	assert str <> null
	chars: 0
	while [not zero? size][
		buffer/1: str/1
		buffer/2: str/2
		chars: chars + 1
		buffer: buffer + 2
		str: str + 2
		size: size - 2
		if chars = 512 [  ; if the buffer has 1024 bytes, it has room for 512 chars
			putbuffer chars
			chars: 0
		]
	]
	putbuffer chars
]

;-------------------------------------------
;-- Print a UCS-2 string with newline to console
;-------------------------------------------
print-line-UCS2: func [
	str 	[byte-ptr!]								;-- UCS-2 string
	size	[integer!]
][
	assert str <> null
	print-UCS2 str size								;@@ throw an error on failure
	buffer/1: #"^M"
	buffer/2: null-byte
	buffer/3: #"^/"
	buffer/4: null-byte
	putbuffer 2 									;-- newline
]

;-------------------------------------------
;-- Print a Latin-1 string to console
;-------------------------------------------
print-Latin1: func [
	str 	[c-string!]								;-- Latin-1 string
	size	[integer!]
	/local
		chars [integer!]							;-- mumber of used chars in buffer
][
	assert str <> null
	chars: 0
	while [not zero? size][
		buffer/1: str/1
		buffer/2: null-byte ;this should be always 0 in Latin1
		size: size - 1
		str: str + 1
		chars: chars + 1
		buffer: buffer + 2
		if chars = 512 [  ; if the buffer has 1024 bytes, it has room for 512 chars
			putbuffer chars
			chars: 0
		]
	]
	putbuffer chars
]

;-------------------------------------------
;-- Print a Latin-1 string with newline to console
;-------------------------------------------
print-line-Latin1: func [
	str  [c-string!]									;-- Latin-1 string
	size [integer!]
][
	assert str <> null
	print-Latin1 str size
	buffer/1: #"^M"
	buffer/2: null-byte
	buffer/3: #"^/"
	buffer/4: null-byte
	putbuffer 2 									;-- newline
]


;-------------------------------------------
;-- Red/System Unicode replacement printing functions
;-------------------------------------------

prin*: func [s [c-string!] return: [c-string!] /local p][
	p: s
	while [p/1 <> null-byte][
		putwchar as-integer p/1
		p: p + 1
	]
	s
]

prin-int*: func [i [integer!] return: [integer!]][
	wprintf [#u16 "%i" i]
	fflush null										;-- flush all streams
	i
]

prin-2hex*: func [i [integer!] return: [integer!]][
	wprintf [#u16 "%02X" i]
	fflush null
	i
]

prin-hex*: func [i [integer!] return: [integer!]][
	wprintf [#u16 "%08X" i]
	fflush null
	i
]

prin-float*: func [f [float!] return: [float!]][
	wprintf [#u16 "%.16g" f]
	fflush null
	f
]

prin-float32*: func [f [float32!] return: [float32!]][
	wprintf [#u16 "%.7g" as-float f]
	fflush null
	f
]