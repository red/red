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

dos-console?:	yes
buffer:			as byte-ptr! 0
pbuffer:		as byte-ptr! 0
cbuffer:		as byte-ptr! 0

#include %win32-ansi.reds

;-------------------------------------------
;-- check whether we are in console mode
;-------------------------------------------
init-dos-console: func [/local n [integer!]][
	cbuffer:		allocate 128
	buffer:			allocate 1024
	pbuffer:		buffer ;this stores buffer's head position
	n: 0
	dos-console?: 0 < GetConsoleMode stdout :n
]

;-------------------------------------------
;-- putwchar use windows api internal
;-------------------------------------------
putwchar: func [
	wchar	[integer!]									;-- wchar is 16-bit on Windows
	return:	[integer!]
	/local
		n	[integer!]
][
	n: 0
	WriteConsole stdout (as byte-ptr! :wchar) 1 :n null
	wchar
]

;-------------------------------------------
;-- putbuffer use windows api internal
;-------------------------------------------
putbuffer: func [
	chars	[integer!]
	return: [integer!]
	/local
		n	[integer!]
][
	n: 0
	WriteConsole stdout pbuffer chars :n null
	buffer: pbuffer
	n
]

write-file: func [
	chars	 [integer!]
	/local n [integer!]
][
	n: 0
	WriteFile stdout as c-string! pbuffer chars :n 0
	buffer: pbuffer
]

print-screen: func [
	str		[byte-ptr!]
	size	[integer!]
	unit	[integer!]					;-- not support UCS-4
	lf?		[logic!]
	/local
		chars [integer!]
		skip  [integer!]
][
	chars: 0
	skip: 0
	either unit = Latin1 [
		while [size > 0][
			if str/1 = #"^[" [
				putbuffer chars
				chars: 0
				skip: parse-ansi-sequence str Latin1
			]
			either skip = 0 [
				buffer/1: str/1
				buffer/2: null-byte ;this should be always 0 in Latin1
				str: str + 1
				size: size - 1
				chars: chars + 1
				buffer: buffer + 2
				if chars = 510 [  ; if the buffer has 1024 bytes, it has room for 512 chars
					putbuffer chars
					chars: 0
				]
			][
				str: str + skip
				size: size - skip
				skip: 0
			]
		]
	][ ;UCS2 Version
		while [size > 0][
			if all [str/1 = #"^[" str/2 = null-byte] [
				putbuffer chars
				chars: 0
				skip: parse-ansi-sequence str UCS-2
			]
			either skip = 0 [
				buffer/1: str/1
				buffer/2: str/2
				chars: chars + 1
				buffer: buffer + 2
				str: str + 2
				size: size - 2
				if chars = 510 [  ; if the buffer has 1024 bytes, it has room for 512 chars
					putbuffer chars
					chars: 0
				]
			][
				str: str + skip
				size: size - skip
				skip: 0
			]
		]
	]
	if lf? [
		buffer/1: #"^M"
		buffer/2: null-byte
		buffer/3: #"^/"
		buffer/4: null-byte
		chars: chars + 2
	]
	putbuffer chars
]

print-file: func [
	p		[byte-ptr!]
	size	[integer!]
	unit	[integer!]
	lf?		[logic!]
	/local
		n		[integer!]
		p4		[int-ptr!]
		cp		[integer!]							;-- codepoint
		chars	[integer!]
][
	chars: 0
	while [size > 0][
		cp: switch unit [
			Latin1 [as-integer p/value]
			UCS-2  [(as-integer p/2) << 8 + p/1]
			UCS-4  [p4: as int-ptr! p p4/value]
		]
		n: unicode/cp-to-utf8 cp buffer
		chars: chars + n
		buffer: buffer + n
		p: p + unit
		size: size - unit
		if chars > 1020 [
			write-file chars
			chars: 0
		]
	]
	if lf? [
		buffer/1: #"^M"
		buffer/2: #"^/"
		chars: chars + 2
	]
	write-file chars
]

print-str: func [
	str		[byte-ptr!]
	size	[integer!]
	unit	[integer!]
	lf?		[logic!]
][
	either dos-console? [
		print-screen str size unit lf?
	][
		print-file str size unit lf?
	]
]

wflush: func [len [integer!]][
	print-str cbuffer len * 2 UCS-2 no
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

	either dos-console? [
		while [not zero? size][
			cp: str/value
			either cp > FFFFh [
				cp: cp - 00010000h					;-- encode surrogate pair
				putwchar cp >> 10 + D800h			;-- emit lead
				putwchar cp and 03FFh + DC00h		;-- emit trail
			][
				putwchar cp							;-- UCS-2 codepoint
			]
			str: str + 1
			size: size - 4
		]
	][
		print-file as byte-ptr! str size UCS-4 no
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
	either dos-console? [
		print-UCS4 str size							;@@ throw an error on failure
		putwchar 10									;-- newline
	][
		print-file as byte-ptr! str size UCS-4 yes
	]
]

;-------------------------------------------
;-- Print a UCS-2 string to console
;-------------------------------------------
print-UCS2: func [
	str 	[byte-ptr!]								;-- UCS-2 string
	size	[integer!]
][
	assert str <> null
	print-str str size UCS-2 no
]

;-------------------------------------------
;-- Print a UCS-2 string with newline to console
;-------------------------------------------
print-line-UCS2: func [
	str 	[byte-ptr!]								;-- UCS-2 string
	size	[integer!]
][
	assert str <> null
	print-str str size UCS-2 yes
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
	print-str as byte-ptr! str size Latin1 no
]

;-------------------------------------------
;-- Print a Latin-1 string with newline to console
;-------------------------------------------
print-line-Latin1: func [
	str  [c-string!]									;-- Latin-1 string
	size [integer!]
][
	assert str <> null
	print-str as byte-ptr! str size Latin1 yes
]


;-------------------------------------------
;-- Red/System Unicode replacement printing functions
;-------------------------------------------

prin*: func [s [c-string!] return: [c-string!] /local p n][
	either dos-console? [
		p: s
		while [p/1 <> null-byte][
			putwchar as-integer p/1
			p: p + 1
		]
	][
		n: 0
		WriteFile stdout s length? s :n 0
	]
	s
]

prin-int*: func [i [integer!] return: [integer!]][
	wflush swprintf [cbuffer #u16 "%i" i]
	i
]

prin-2hex*: func [i [integer!] return: [integer!]][
	wflush swprintf [cbuffer #u16 "%02X" i]
	i
]

prin-hex*: func [i [integer!] return: [integer!]][
	wflush swprintf [cbuffer #u16 "%08X" i]
	i
]

prin-float*: func [f [float!] return: [float!]][
	wflush swprintf [cbuffer #u16 "%.16g" f]
	f
]

prin-float32*: func [f [float32!] return: [float32!]][
	wflush swprintf [cbuffer #u16 "%.7g" as-float f]
	f
]