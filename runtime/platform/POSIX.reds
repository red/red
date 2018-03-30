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


#define __LC_CTYPE 0
#define __LC_ALL   6

#define RTLD_LAZY	1

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

; Wordexp enums
#define	WRDE_DOOFFS		1
#define	WRDE_APPEND		2
#define	WRDE_NOCMD		4
#define	WRDE_REUSE		8
#define	WRDE_SHOWERR	16
#define	WRDE_UNDEF		32
#define	__WRDE_FLAGS	63

#define	WRDE_NOSPACE	1
#define	WRDE_BADCHAR	2
#define	WRDE_BADVAL		3
#define	WRDE_CMDSUB		4
#define	WRDE_SYNTAX		5

; Wordexp types
wordexp-type!: alias struct! [
	we_wordc  [integer!]
	we_wordv  [str-array!]
	we_offs   [integer!]
]

pollfd!: alias struct! [
	fd		[integer!]
	events	[integer!]			;-- events / revents
]

#define POLLIN		0001h
#define POLLPRI		0002h
#define POLLOUT		0004h
#define POLLERR		0008h
#define POLLHUP		0010h
#define POLLNVAL	0020h

; Values for the second argument to fcntl
#define F_DUPFD		0
#define F_GETFD		1
#define F_SETFD		2
#define F_GETFL		3
#define F_SETFL		4

#import [
	LIBC-file cdecl [
		setlocale: "setlocale" [
			category	[integer!]
			locale		[c-string!]
			return:		[c-string!]
		]
		sysctl: "sysctl" [
			name	[int-ptr!]
			namelen [integer!]
			oldp	[byte-ptr!]
			oldlenp [int-ptr!]
			newp	[byte-ptr!]
			newlen	[integer!]
			return: [integer!]
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
		difftime: "difftime" [
			end		[integer!]
			begin	[integer!]
			return: [float!]
		]
		time: "time" [
			ptr		[int-ptr!]
			return: [integer!]
		]
		gmtime: "gmtime" [
			tv_sec	[int-ptr!]
			return: [tm!]
		]
		localtime: "localtime" [
			tv_sec	[int-ptr!]
			return: [tm!]
		]
		mktime: "mktime" [
			tm		[tm!]
			return: [integer!]
		]
		fork: "fork" [
			return:        [integer!]
		]
		sleep: "sleep" [
			nb             [integer!]
			return:        [integer!]
		]
		execvp: "execvp" [
			cmd            [c-string!]
			args-list      [str-array!]
			return:        [integer!]
		]
		wordexp: "wordexp" [
			words          [c-string!]
			pwordexp       [wordexp-type!]
			flags          [integer!]
			return:        [integer!]
		]
		wordfree: "wordfree" [
			pwordexp       [wordexp-type!]
			return:        [integer!]
		]
		wait-child: "wait" [
			status         [int-ptr!]
			return:        [integer!]
		]
		waitpid: "waitpid" [
			pid            [integer!]
			status         [int-ptr!]
			options        [integer!]
			return:        [integer!]
		]
		pipe: "pipe" [
			pipedes        [int-ptr!]  "Pointer to a 2 integers array"
			return:        [integer!]
		]
		dup2: "dup2" [
			fd             [integer!]
			fd2            [integer!]
			return:        [integer!]
		]
		_open:	"open" [
			filename	[c-string!]
			flags		[integer!]
			mode		[integer!]
			return:		[integer!]
		]
		io-open: "open" [
			filename		[c-string!]
			flags			[integer!]
			return:			[integer!]
		]
		io-close: "close" [
			fd             [integer!]
			return:        [integer!]
		]
		io-read: "read" [
			fd             [integer!]
			buf            [byte-ptr!]
			nbytes         [integer!]
			return:        [integer!]  "Number of bytes read or error"
		]
		io-write: "write" [
			fd             [integer!]
			buf            [byte-ptr!]
			nbytes         [integer!]
			return:        [integer!]  "Number of bytes written or error"
		]
		fcntl: "fcntl" [
			[variadic]
			; fd           [integer!]    "File descriptor"
			; cmd          [integer!]    "Command"
			; ...                        "Optional arguments"
			return:        [integer!]
		]
		poll: "poll" [
			fds				[pollfd!]
			nfds			[integer!]
			timeout 		[integer!]
			return: 		[integer!]
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
	time :t
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
