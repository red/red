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

timespec!: alias struct! [
	sec		[integer!] ;Seconds
	nsec	[integer!] ;Nanoseconds
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

#switch OS [							;-- loading OS-specific bindings
	macOS	 [#include %darwin.reds]
	FreeBSD  [#include %freebsd.reds]
	Syllable [#include %syllable.reds]
	#default [#include %linux.reds]
]

#import [
	LIBC-file cdecl [
		strncmp: "strncmp" [
			str1		[c-string!]
			str2		[c-string!]
			num			[integer!]
			return:		[integer!]
		]
		strstr: "strstr" [
			str			[c-string!]
			substr		[c-string!]
			return:		[c-string!]
		]
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
		_time: "time" [
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
		_fork: "fork" [
			return:        [integer!]
		]
		_sleep: "sleep" [
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
		_pipe: "pipe" [
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
		_open2: "open" [
			filename		[c-string!]
			flags			[integer!]
			return:			[integer!]
		]
		_close: "close" [
			fd             [integer!]
			return:        [integer!]
		]
		_read: "read" [
			fd             [integer!]
			buf            [byte-ptr!]
			nbytes         [integer!]
			return:        [integer!]  "Number of bytes read or error"
		]
		_write: "write" [
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
		_poll: "poll" [
			fds			[pollfd!]
			nfds		[integer!]
			timeout		[integer!]
			return:		[integer!]
		]
		_access: "access" [
			filename	[c-string!]
			mode		[integer!]
			return:		[integer!]
		]
		mkdir: "mkdir" [
			pathname	[c-string!]
			mode		[integer!]
			return:		[integer!]
		]
		opendir: "opendir" [
			filename	[c-string!]
			return:		[integer!]
		]
		readdir: "readdir" [
			file		[integer!]
			return:		[dirent!]
		]
		closedir: "closedir" [
			file		[integer!]
			return:		[integer!]
		]
		_remove: "remove" [
			pathname	[c-string!]
			return: 	[integer!]
		]
		_socket: "socket" [
			family		[integer!]
			type		[integer!]
			protocl		[integer!]
			return:		[integer!]
		]
		_bind: "bind" [
			fd			[integer!]
			addr		[byte-ptr!]
			addrlen		[integer!]
			return:		[integer!]
		]
		_accept: "accept" [
			fd			[integer!]
			addr		[byte-ptr!]
			addrlen		[int-ptr!]
			return:		[integer!]
		]
		_listen: "listen" [
			fd			[integer!]
			backlog		[integer!]
			return:		[integer!]
		]
		_connect: "connect" [
			fd			[integer!]
			addr		[int-ptr!]
			addrlen		[integer!]
			return:		[integer!]
		]
		_send: "send" [
			fd			[integer!]
			buf			[byte-ptr!]
			len			[integer!]
			flags		[integer!]
			return:		[integer!]
		]
		_recv: "recv" [
			fd			[integer!]
			buf			[byte-ptr!]
			len			[integer!]
			flags		[integer!]
			return:		[integer!]
		]
		sendfile: "sendfile" [
			out_fd		[integer!]
			in_fd		[integer!]
			offset		[int-ptr!]
			count		[integer!]
			return:		[integer!]
		]
		htons: "htons" [
			hostshort	[integer!]
			return:		[integer!]
		]
		inet_addr: "inet_addr" [
			cp			[c-string!]
			return:		[integer!]
		]
	]
]


errno: as int-ptr! 0

#case [
	any [OS = 'macOS OS = 'FreeBSD OS = 'Android] [
		#import [
			LIBC-file cdecl [
				;-- https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/10.6/man2/stat.2.html?useVersion=10.6
				_stat:	"fstat" [
					file		[integer!]
					restrict	[stat!]
					return:		[integer!]
				]
			]
		]
	]
	true [
		#import [
			LIBC-file cdecl [
				;-- http://refspecs.linuxbase.org/LSB_3.0.0/LSB-Core-generic/LSB-Core-generic/baselib-xstat-1.html
				_stat:	"__fxstat" [
					version		[integer!]
					file		[integer!]
					restrict	[stat!]
					return:		[integer!]
				]
			]
		]
	]

]

#either OS = 'macOS [
	#import [
		LIBC-file cdecl [
			lseek: "lseek" [
				file		[integer!]
				offset-lo	[integer!]
				offset-hi	[integer!]
				whence		[integer!]
				return:		[integer!]
			]
		]
	]
][
	#import [
		LIBC-file cdecl [
			lseek: "lseek" [
				file		[integer!]
				offset		[integer!]
				whence		[integer!]
				return:		[integer!]
			]
		]
	]
]

#case [
	any [OS = 'macOS OS = 'FreeBSD] [
		kevent!: alias struct! [
			ident		[int-ptr!]		;-- identifier for this event
			;filter		[int16!]		;-- filter for event
			;flags		[int16!]		;-- general flags
			fflags		[integer!]		;-- filter-specific flags
			data		[int-ptr!]		;-- filter-specific data
			udata		[int-ptr!]		;-- opaque user data identifier
		]
		#import [
			LIBC-file cdecl [
				get-errno-ptr: "__error" [
					return: [int-ptr!]
				]
				kqueue: "kqueue" [
					return: [integer!]
				]
				kevent: "kevent" [
					kq		[integer!]
					clist	[kevent!]
					nchange [integer!]
					evlist	[kevent!]
					nevents [integer!]
					timeout [timespec!]
				]
			]
		]
	]
	true [
		epoll_event!: alias struct! [
			events		[integer!]
			ptr			[int-ptr!]
			pad			[integer!]
		]
		#import [
			LIBC-file cdecl [
				get-errno-ptr: "__errno_location" [
					return: [int-ptr!]
				]
				epoll_create1: "epoll_create1" [
					flags	[integer!]
					return: [integer!]
				]
				epoll_ctl: "epoll_ctl" [
					epfd	[integer!]
					op		[integer!]
					fd		[integer!]
					event	[epoll_event!]
					return: [integer!]
				]
				epoll_wait: "epoll_wait" [
					epfd	[integer!]
					events	[epoll_event!]
					maxev	[integer!]
					timeout [integer!]
					return: [integer!]
				]
			]
		]
	]
]