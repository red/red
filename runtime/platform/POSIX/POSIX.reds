Red/System [
	Title:   "Red runtime POSIX API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %POSIX.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

wait: func [time [float!]][								;-- seconds
	time: time * 1000000.0								;-- microseconds
	if time < 1.0 [time: 1.0]
	usleep as-integer time
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

sprintf-buf: "0000000000000000000000000000000" ;-- 32 bytes wide, big enough.

flush: func [len [integer!]][
	printf sprintf-buf
	dyn-print/rs-print sprintf-buf len no
]

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
	dyn-print/rs-print s as-integer p - s no
	s
]

prin-int*: func [i [integer!] return: [integer!]][
	flush sprintf [sprintf-buf "%i" i]
	i
]

prin-2hex*: func [i [integer!] return: [integer!]][
	flush sprintf [sprintf-buf "%02X" i]
	i
]

prin-hex*: func [i [integer!] return: [integer!]][
	flush sprintf [sprintf-buf "%08X" i]
	i
]

prin-float*: func [f [float!] return: [float!]][
	flush sprintf [sprintf-buf "%.16g" f]
	f
]

prin-float32*: func [f [float32!] return: [float32!]][
	flush sprintf [sprintf-buf "%.7g" as-float f]
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

set-current-dir: func [
	path	[c-string!]
	return: [logic!]
][
	zero? chdir path
]

set-env: func [
	name	[c-string!]
	value	[c-string!]
	return: [logic!]			;-- true for success
][
	either value <> null [
		-1 <> setenv name value 1
	][
		-1 <> unsetenv name
	]
]

get-env: func [
	;; Returns size of retrieved value for success or zero if missing
	;; If return size is greater than valsize then value contents are undefined
	name	[c-string!]
	value	[c-string!]
	valsize [integer!]			;-- includes null terminator
	return: [integer!]
	/local
		val [c-string!]
		len [integer!]
][
	val: getenv name
	if null? val [return 0]

	len: length? val
	if zero? len [return -1]

	if len + 1 > valsize [return len + 1]
	copy-memory as byte-ptr! value as byte-ptr! val len
	len
]

get-time: func [
	utc?	 [logic!]
	precise? [logic!]
	return:  [float!]
	/local
		time	[timeval! value]
		tm		[tm!]
		micro	[float!]
		t		[float!]
][
	gettimeofday time 0
	tm: gmtime as int-ptr! time
	micro: 0.0
	if precise? [
		micro: as-float time/tv_usec
		micro: micro / 1E6
	]
	t: as-float tm/hour * 3600 + (tm/min * 60) + tm/sec
	t + micro
]

get-timezone: func [
	return: [integer!]
	/local
		t	[integer!]
		t2	[integer!]
		tm	[tm!]
][
	t: 0
	_time :t
	tm: localtime :t
	tm/isdst: 0
	t2: mktime tm
	t: as-integer difftime t2 mktime gmtime :t
	t / 60
]

get-date: func [
	utc?	[logic!]
	return:	[integer!]
	/local
		time	[timeval! value]
		tm		[tm!]
		bias	[integer!]
		y		[integer!]
		m		[integer!]
		d		[integer!]
		h		[integer!]
][
	gettimeofday time 0
	tm: either utc? [gmtime as int-ptr! time][localtime as int-ptr! time]
	y: tm/year + 1900
	m: tm/mon + 1
	d: tm/mday

	either utc? [h: 0][
		bias: get-timezone
		h: bias / 60
		if h < 0 [h: 0 - h and 0Fh or 10h]	;-- properly set the sign bit
		h: h << 2 or (bias // 60 / 15 and 03h)
	]
	y << 17 or (m << 12) or (d << 7) or h
]
