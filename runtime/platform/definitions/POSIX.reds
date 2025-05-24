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

#define O_RDONLY	0
#define O_WRONLY	1
#define O_RDWR		2
#define O_BINARY	0

#define S_IREAD		256
#define S_IWRITE    128
#define S_IRGRP		32
#define S_IWGRP		16
#define S_IROTH		4

#define	DT_DIR		#"^(04)"
#define S_IFDIR		4000h
#define S_IFREG		8000h

#define BFFM_SETEXPANDED 1130

#define SIGPIPE 13
#define SIG_IGN [as int-ptr! 1]

#define INET6_ADDRSTRLEN 46

; Wordexp types
wordexp-type!: alias struct! [
	we_wordc  [integer!]
	we_wordv  [str-array!]
	we_offs   [integer!]
]

pollfd!: alias struct! [
	fd				[integer!]
	events			[integer!]						;-- high 16-bit: events
]													;-- low  16-bit: revents

#define OS_POLLIN 		1

#case [
	any [OS = 'macOS OS = 'FreeBSD OS = 'NetBSD] [
		#define TIOCGWINSZ		40087468h
		#define TERM_TCSADRAIN	1
		#define TERM_VTIME		18
		#define TERM_VMIN		17

		#define TERM_BRKINT		02h
		#define TERM_INPCK		10h
		#define TERM_ISTRIP		20h
		#define TERM_ICRNL		0100h
		#define TERM_IXON		0200h
		#define TERM_OPOST		01h
		#define TERM_CS8		0300h
		#define TERM_ISIG		80h
		#define TERM_ICANON		0100h
		#define TERM_ECHO		08h	
		#define TERM_IEXTEN		4000h

		termios!: alias struct! [
			c_iflag			[integer!]
			c_oflag			[integer!]
			c_cflag			[integer!]
			c_lflag			[integer!]
			c_cc1			[integer!]						;-- c_cc[20]
			c_cc2			[integer!]
			c_cc3			[integer!]
			c_cc4			[integer!]
			c_cc5			[integer!]
			c_ispeed		[integer!]
			c_ospeed		[integer!]
		]
	]
	true [													;-- Linux
		#define TIOCGWINSZ		5413h
		#define TERM_VTIME		6
		#define TERM_VMIN		7

		#define TERM_BRKINT		2
		#define TERM_INPCK		20
		#define TERM_ISTRIP		40
		#define TERM_ICRNL		400
		#define TERM_IXON		2000
		#define TERM_OPOST		1
		#define TERM_CS8		60
		#define TERM_ISIG		1
		#define TERM_ICANON		2
		#define TERM_ECHO		10
		#define TERM_IEXTEN		100000

		#either OS = 'Android [
			#define TERM_TCSADRAIN	5403h

			termios!: alias struct! [
				c_iflag			[integer!]
				c_oflag			[integer!]
				c_cflag			[integer!]
				c_lflag			[integer!]
				;c_line			[byte!]
				c_cc1			[integer!]					;-- c_cc[19]
				c_cc2			[integer!]
				c_cc3			[integer!]
				c_cc4			[integer!]
				c_cc5			[integer!]
			]
		][
			#define TERM_TCSADRAIN	1

			termios!: alias struct! [						;-- sizeof(termios) = 60
				c_iflag			[integer!]
				c_oflag			[integer!]
				c_cflag			[integer!]
				c_lflag			[integer!]
				c_line			[byte!]
				c_cc1			[byte!]						;-- c_cc[32]
				c_cc2			[byte!]
				c_cc3			[byte!]
				c_cc4			[integer!]
				c_cc5			[integer!]
				c_cc6			[integer!]
				c_cc7			[integer!]
				c_cc8			[integer!]
				c_cc9			[integer!]
				c_cc10			[integer!]
				pad				[integer!]					;-- for proper alignment
				c_ispeed		[integer!]
				c_ospeed		[integer!]
			]
		]
	]
]

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
	sec		[integer!] 		;-- Seconds
	nsec	[integer!] 		;-- Nanoseconds
]

#switch OS [							;-- loading OS-specific bindings
	macOS	 [#include %darwin.reds]
	FreeBSD  [#include %freebsd.reds]
	NetBSD   [#include %netbsd.reds]
	Syllable [#include %syllable.reds]
	#default [#include %linux.reds]
]

winsize!: alias struct! [
	rowcol			[integer!]
	xypixel			[integer!]
]

#either OS = 'Android [
	tcgetattr: func [
		fd		[integer!]
		termios [termios!]
		return: [integer!]
	][
		ioctl fd 5401h as winsize! termios
	]
	tcsetattr: func [
		fd			[integer!]
		opt_actions [integer!]
		termios 	[termios!]
		return: 	[integer!]
	][
		ioctl fd opt_actions as winsize! termios
	]
][
	#import [
	LIBC-file cdecl [
		tcgetattr: "tcgetattr" [
			fd		[integer!]
			termios [termios!]
			return: [integer!]
		]
		tcsetattr: "tcsetattr" [
			fd			[integer!]
			opt_actions [integer!]
			termios 	[termios!]
			return: 	[integer!]
		]
	]]
]

#import [
	LIBC-file cdecl [
		setlocale: "setlocale" [
			category	[integer!]
			locale		[c-string!]
			return:		[c-string!]
		]
		sysconf: "sysconf" [
			property	[integer!]
			return:		[integer!]
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
		sleep: "sleep" [
			nb             [integer!]
			return:        [integer!]
		]
		execvp: "execvp" [
			cmd            [c-string!]
			args-list      [str-array!]
			return:        [integer!]
		]
	#if config-name <> 'Pico [
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
		strnicmp: "strncasecmp" [
			s1			[byte-ptr!]
			s2			[byte-ptr!]
			len			[integer!]
			return:		[integer!]
		]
		
		_rename: "rename" [
			old		[c-string!]
			new		[c-string!]
			return:	[integer!]
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
		strchr: "strchr" [
			str			[c-string!]
			c			[byte!]
			return:		[c-string!]
		]
		_dup: "dup" [
			fd		[integer!]
			return: [integer!]
		]
		isatty: "isatty" [
			fd		[integer!]
			return:	[integer!]
		]
		ioctl: "ioctl" [
			fd		[integer!]
			request	[integer!]
			ws		[winsize!]
			return: [integer!]
		]
	]
]

errno: as int-ptr! 0

#case [
	any [OS = 'macOS OS = 'FreeBSD OS = 'NetBSD OS = 'Android] [
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
	config-name = 'Pico [
		#import [
			LIBC-file cdecl [
				;-- https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/10.6/man2/stat.2.html?useVersion=10.6
				_stat:	"fstat64" [
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
				_stat:	"__fxstat64" [
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
	any [OS = 'FreeBSD OS = 'macOS OS = 'NetBSD] [
		#define O_CREAT		0200h
		#define O_TRUNC		0400h
		#define O_EXCL		0800h
		#define O_APPEND	8
		#define	O_NONBLOCK	4
		#define	O_CLOEXEC	01000000h

		#define DIRENT_NAME_OFFSET 8
		
		#either OS = 'NetBSD [
			#import [
				LIBC-file cdecl [
					get-errno-ptr: "__errno" [
						return: [int-ptr!]
					]
				]
			]
		][
			#import [
				LIBC-file cdecl [
					get-errno-ptr: "__error" [
						return: [int-ptr!]
					]
				]
			]
		]
	]
	true [	;-- Linux
		#define O_CREAT		64
		#define O_EXCL		128
		#define O_TRUNC		512
		#define O_APPEND	1024
		#define	O_NONBLOCK	2048
		#define	O_CLOEXEC	524288
		#either target = 'ARM [
			#define O_DIRECTORY 4000h
		][
			#define O_DIRECTORY 00010000h
		]
		
		#import [
			LIBC-file cdecl [
				get-errno-ptr: "__errno_location" [
					return: [int-ptr!]
				]
			]
		]
	]
]
