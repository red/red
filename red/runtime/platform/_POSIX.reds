Red/System [
	Title:   "Red runtime POSIX API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %POSIX.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]


#define __LC_CTYPE 0
#define __LC_ALL   6

#import [
	LIBC-file cdecl [
		putwchar: "putwchar" [
			wchar		[integer!]						;-- wchar is 32-bit on UNIX 32-bit systems @@64-bit
		]
		wprintf: "wprintf" [
			[variadic]
			return: 	[integer!]
		]
		setlocale: "setlocale" [
			category	[integer!]
			locale		[c-string!]
			return:		[c-string!]
		]
	]
]

;-------------------------------------------
;-- Print a UCS-4 string to console
;-------------------------------------------
print-UCS4: func [
	str 	[int-ptr!]									;-- zero-terminated UCS-4 string
	/local
		cp [integer!]
][
	assert str <> null

	while [cp: str/value not zero? cp][
		case [
			cp <= 7Fh [
				putwchar cp
			]
			cp <= 07FFh [
				putwchar cp >> 6 or C0h
				putwchar cp and 3Fh or 80h
			]
			cp <= FFFFh [
				putwchar cp >> 12 or E0h
				putwchar cp >> 6 and 3Fh or 80h
				putwchar cp and 3Fh or 80h
			]
			cp <= 001FFFFFh [
				putwchar cp >> 18 or F0h
				putwchar cp >> 12 and 3Fh or 80h
				putwchar cp >>  6 and 3Fh or 80h
				putwchar cp and 3Fh or 80h
			]
			true [
				print-line "Error in print-UCS4: codepoint > 1FFFFFh"
			]
		]
		str: str + 2
	]
]

;-------------------------------------------
;-- Print a UCS-4 string to console
;-------------------------------------------
print-line-UCS4: func [
	str    [int-ptr!]									;-- zero-terminated UCS-4 string
	/local
		cp [integer!]									;-- codepoint
][
	assert str <> null

	print-UCS4 str										;@@ throw an error on failure
	putwchar 10											;-- newline
]

;-------------------------------------------
;-- Print a UCS-2 string to console
;-------------------------------------------
print-UCS2: func [
	str 	[byte-ptr!]									;-- zero-terminated UCS-2 string
	/local
		cp [integer!]
][
	assert str <> null

	while [
		cp: as-integer str/2
		cp: cp << 8 + str/1
		not zero? cp
	][
		case [
			cp <= 7Fh [
				putwchar cp
			]
			cp <= 07FFh [
				putwchar cp >> 6 or C0h
				putwchar cp and 3Fh or 80h
			]
			true [
				putwchar cp >> 12 or E0h
				putwchar cp >> 6 and 3Fh or 80h
				putwchar cp and 3Fh or 80h
			]
		]
		str: str + 2
	]
]

;-------------------------------------------
;-- Print a UCS-2 string with newline to console
;-------------------------------------------
print-line-UCS2: func [
	str 	[byte-ptr!]									;-- zero-terminated UCS-2 string
][
	assert str <> null
	print-UCS2 str
	putwchar 10											;-- newline
]

;-------------------------------------------
;-- Print a Latin-1 string to console
;-------------------------------------------
print-Latin1: func [
	str 	[c-string!]									;-- zero-terminated Latin-1 string
][
	assert str <> null
	prin str
]

;-------------------------------------------
;-- Print a Latin-1 string with newline to console
;-------------------------------------------
print-line-Latin1: func [
	str [c-string!]										;-- zero-terminated Latin-1 string
][
	assert str <> null
	prin str
	putwchar 10											;-- newline
]

;-------------------------------------------
;-- Red/System Unicode replacement printing functions
;-------------------------------------------

prin: func [s [c-string!] return: [c-string!] /local p][
	p: s
	while [p/1 <> null-byte][
		putwchar as-integer p/1
		p: p + 1
	]
	s
]

prin-int: func [i [integer!] return: [integer!]][
	wprintf ["%i" i]									;-- UTF-8 literal string
	i
]

prin-hex: func [i [integer!] return: [integer!]][
	wprintf ["%08X" i]									;-- UTF-8 literal string
	i
]

prin-float: func [f [float!] return: [float!]][
	wprintf ["%.14g" f]									;-- UTF-8 literal string
	f
]

prin-float32: func [f [float32!] return: [float32!]][
	wprintf ["%.7g" as-float f]							;-- UTF-8 literal string
	f
]
