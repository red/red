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
out-buffer:	 allocate 1024
out-buffer-head: out-buffer
out-buffer-tail: out-buffer + 1024
out-buffer-flush: func [/local n chars][
	n: 0
	chars: as integer! (out-buffer - out-buffer-head)
	either dos-console? [
		WriteConsole stdout out-buffer-head chars >> 1 :n null
	][
		WriteFile stdout as c-string! out-buffer-head chars :n 0
	]
	out-buffer: out-buffer-head
]

;-------------------------------------------
;-- check whether we are in console mode
;-------------------------------------------
init-dos-console: func [/local n [integer!]][
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

print-screen: func [
	str		[byte-ptr!]
	size	[integer!]
	unit	[integer!]					;-- not support UCS-4
	lf?		[logic!]
	/local
		skip  [integer!]
		tail  [byte-ptr!]
][
	skip: 0
	tail: str + size
	either unit = Latin1 [
		while [size > 0][
			if str/1 = #"^[" [
				out-buffer-flush
				skip: process-ansi-sequence (str + 1) tail Latin1
			]
			either skip = 0 [
				out-buffer/1: str/1
				out-buffer/2: null-byte ;this should be always 0 in Latin1
				str: str + 1
				size: size - 1
				out-buffer: out-buffer + 2
				if out-buffer >= out-buffer-tail [
					out-buffer-flush
				]
			][
				str: str + skip + 1
				size: size - skip - 1
				skip: 0
			]
		]
	][ ;UCS2 Version
		while [size > 0][
			if all [str/1 = #"^[" str/2 = null-byte] [
				out-buffer-flush
				skip: process-ansi-sequence (str + 2) tail UCS-2
			]
			either skip = 0 [
				out-buffer/1: str/1
				out-buffer/2: str/2
				out-buffer: out-buffer + 2
				str: str + 2
				size: size - 2
				if out-buffer >= out-buffer-tail [
					out-buffer-flush
				]
			][
				str: str + skip + 2
				size: size - skip - 2
				skip: 0
			]
		]
	]
	out-buffer-flush
	if lf? [
		WriteConsole stdout as byte-ptr! "^M^@^/^@" 2 :skip null
	]
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
][
	while [size > 0][
		cp: switch unit [
			Latin1 [as-integer p/value]
			UCS-2  [(as-integer p/2) << 8 + p/1]
			UCS-4  [p4: as int-ptr! p p4/value]
		]
		;make sure we have enough space to hold the UCS-4 char
		if (out-buffer + 4) >= out-buffer-tail [ out-buffer-flush ]
		n: unicode/cp-to-utf8 cp out-buffer
		out-buffer: out-buffer + n
		p: p + unit
		size: size - unit
	]
	out-buffer-flush
	if lf? [
		WriteFile stdout "^M^/" 2 :n 0
	]
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

prin-int*: func [i [integer!] return: [integer!] /local n][
	n: swprintf [out-buffer #u16 "%i" i]
	out-buffer: out-buffer + (n << 1)
	out-buffer-flush
	i
]

prin-2hex*: func [i [integer!] return: [integer!] /local n][
	n: swprintf [out-buffer #u16 "%02X" i]
	out-buffer: out-buffer + (n << 1)
	out-buffer-flush
	i
]

prin-hex*: func [i [integer!] return: [integer!] /local n][
	n: swprintf [out-buffer #u16 "%08X" i]
	out-buffer: out-buffer + (n << 1)
	out-buffer-flush
	i
]

prin-float*: func [f [float!] return: [float!] /local n][
	n: swprintf [out-buffer #u16 "%.16g" f]
	out-buffer: out-buffer + (n << 1)
	out-buffer-flush
	f
]

prin-float32*: func [f [float32!] return: [float32!] /local n][
	n: swprintf [out-buffer #u16 "%.7g" as-float f]
	out-buffer: out-buffer + (n << 1)
	out-buffer-flush
	f
]