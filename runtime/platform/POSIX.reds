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

#define RTLD_LAZY	1

environ: as int-ptr! 0

timeval!: alias struct! [
	tv_sec	[integer!]
	tv_usec [integer!]
]

tm!: alias struct! [
	sec		[integer!]		;-- Seconds		[0-60] (1 leap second)
	min		[integer!]		;-- Minutes		[0-59]
	hour	[integer!]		;-- Hours		[0-23]
	mday	[integer!]		;-- Day			[1-31]
	mon		[integer!]		;-- Month		[0-11]
	year	[integer!]		;-- Years since 1900
	wday	[integer!]		;-- Day of week [0-6]
	yday	[integer!]		;-- Days in year[0-365]
	isdst	[integer!]		;-- DST			[-1/0/1]

	gmtoff	[integer!]		;-- Seconds east of UTC
	zone	[c-string!]		;-- Timezone abbreviation
]

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
		dlopen:	"dlopen" [
			dllpath		[c-string!]
			flags		[integer!]
			return:		[integer!]
		]
		dlsym: "dlsym" [
			handle		[integer!]
			symbol		[c-string!]
			return:		[int-ptr!]
		]
		getcwd: "getcwd" [
			buf		[byte-ptr!]
			size	[integer!]
			return: [byte-ptr!]
		]
		chdir: "chdir" [
			path	[c-string!]
			return: [integer!]
		]
		usleep: "usleep" [
			microseconds [integer!]
			return: 	 [integer!]
		]
		getenv: "getenv" [
			name		[c-string!]
			return:		[c-string!]
		]
		setenv: "setenv" [
			name		[c-string!]
			val			[c-string!]
			overwrite	[integer!]
			return:		[integer!]
		]
		unsetenv: "unsetenv" [
			name		[c-string!]
			return:		[integer!]
		]
		gettimeofday: "gettimeofday" [
			tv		[timeval!]
			tz		[integer!]			;-- obsolete
			return: [integer!]			;-- 0: success -1: failure
		]
		gmtime: "gmtime" [
			tv_sec	[int-ptr!]
			return: [tm!]
		]
		localtime: "localtime" [
			tv_sec	[int-ptr!]
			return: [tm!]
		]
	]
]

wait: func [time [integer!]][usleep time]

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
		time	[timeval!]
		tm		[tm!]
		micro	[float!]
		t		[float!]
][
	time: declare timeval!
	gettimeofday time 0
	tm: either utc? [gmtime as int-ptr! time][localtime as int-ptr! time]
	micro: 0.0
	if precise? [micro: integer/to-float time/tv_usec]
	t: integer/to-float tm/hour * 3600 + (tm/min * 60) + tm/sec * 1000
	t * 1E3 + micro * 1E3			;-- nano second
]