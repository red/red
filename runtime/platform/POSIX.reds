Red/System [
	Title:   "Red runtime POSIX API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %POSIX.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]


#define __LC_CTYPE 0
#define __LC_ALL   6

#import [
	LIBC-file cdecl [
		wprintf: "wprintf" [
			[variadic]
			return: 	[integer!]
		]
		setlocale: "setlocale" [
			category	[integer!]
			locale		[c-string!]
			return:		[c-string!]
		]
		getcwd: "getcwd" [
			buf		[byte-ptr!]
			size	[integer!]
			return: [byte-ptr!]
		]
	]
]

;-------------------------------------------
;-- Print a UCS-4 string to console
;-------------------------------------------
print-UCS4: func [
	str 	[int-ptr!]									;-- zero-terminated UCS-4 string
	size	[integer!]
	/local
		cp [integer!]
][
	assert str <> null

	while [not zero? size][
		cp: str/value 
		case [
			cp <= 7Fh [
				putchar as-byte cp
			]
			cp <= 07FFh [
				putchar as-byte cp >> 6 or C0h
				putchar as-byte cp and 3Fh or 80h
			]
			cp <= FFFFh [
				putchar as-byte cp >> 12 or E0h
				putchar as-byte cp >> 6 and 3Fh or 80h
				putchar as-byte cp and 3Fh or 80h
			]
			cp <= 001FFFFFh [
				putchar as-byte cp >> 18 or F0h
				putchar as-byte cp >> 12 and 3Fh or 80h
				putchar as-byte cp >>  6 and 3Fh or 80h
				putchar as-byte cp and 3Fh or 80h
			]
			true [
				print-line "Error in print-UCS4: codepoint > 1FFFFFh"
			]
		]
		size: size - 4
		str: str + 1
	]
]

;-------------------------------------------
;-- Print a UCS-4 string to console
;-------------------------------------------
print-line-UCS4: func [
	str    [int-ptr!]									;-- UCS-4 string
	size   [integer!]
	/local
		cp [integer!]									;-- codepoint
][
	assert str <> null

	print-UCS4 str size									;@@ throw an error on failure
	putchar as-byte 10									;-- newline
]

;-------------------------------------------
;-- Print a UCS-2 string to console
;-------------------------------------------
print-UCS2: func [
	str 	[byte-ptr!]									;-- UCS-2 string
	size	[integer!]
	/local
		cp [integer!]
][
	assert str <> null

	while [not zero? size][
		cp: as-integer str/2
		cp: cp << 8 + str/1
		case [
			cp <= 7Fh [
				putchar as-byte cp
			]
			cp <= 07FFh [
				putchar as-byte cp >> 6 or C0h
				putchar as-byte cp and 3Fh or 80h
			]
			true [
				putchar as-byte cp >> 12 or E0h
				putchar as-byte cp >> 6 and 3Fh or 80h
				putchar as-byte cp and 3Fh or 80h
			]
		]
		size: size - 2
		str: str + 2
	]
]

;-------------------------------------------
;-- Print a UCS-2 string with newline to console
;-------------------------------------------
print-line-UCS2: func [
	str 	[byte-ptr!]									;-- UCS-2 string
	size	[integer!]
][
	assert str <> null
	print-UCS2 str size
	putchar as-byte 10									;-- newline
]

;-------------------------------------------
;-- Print a Latin-1 string to console
;-------------------------------------------
print-Latin1: func [
	str 	[c-string!]									;-- Latin-1 string
	size	[integer!]
	/local
		cp [integer!]
][
	assert str <> null

	while [not zero? size][
		cp: as-integer str/1
		either cp <= 7Fh [
			putchar as-byte cp
		][
			putchar as-byte cp >> 6 or C0h
			putchar as-byte cp and 3Fh or 80h
		]
		size: size - 1
		str: str + 1
	]
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
	putchar as-byte 10									;-- newline
]

;-------------------------------------------
;-- Red/System Unicode replacement printing functions
;-------------------------------------------

prin*: func [
	s		[c-string!]
	return: [c-string!]
	/local
		p  [c-string!]
		cp [integer!]
][
	p: s
	while [cp: as-integer p/1 cp <> 0][
		either cp <= 7Fh [
			putchar as-byte cp
		][
			putchar as-byte cp >> 6 or C0h
			putchar as-byte cp and 3Fh or 80h
		]
		p: p + 1
	]
	s
]

prin-int*: func [i [integer!] return: [integer!]][
	printf ["%i" i]										;-- UTF-8 literal string
	i
]

prin-2hex*: func [i [integer!] return: [integer!]][
	printf ["%02X" i]									;-- UTF-8 literal string
	i
]

prin-hex*: func [i [integer!] return: [integer!]][
	printf ["%08X" i]									;-- UTF-8 literal string
	i
]

prin-float*: func [f [float!] return: [float!]][
	printf ["%.16g" f]									;-- UTF-8 literal string
	f
]

prin-float32*: func [f [float32!] return: [float32!]][
	printf ["%.7g" as-float f]							;-- UTF-8 literal string
	f
]

get-current-dir: func [
	len		[int-ptr!]
	return: [c-string!]
	/local
		path [byte-ptr!]
][
	path: allocate 4096
	if null? getcwd path 4095 [path/1: #"^@"]
	len/value: length? as c-string! path
	as c-string! path
]