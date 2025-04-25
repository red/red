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

#define POLLIN		0001h
#define POLLPRI		0002h
#define POLLOUT		0004h
#define POLLERR		0008h
#define POLLHUP		0010h
#define POLLNVAL	0020h

#define EPOLLIN			01h
#define EPOLLPRI		02h
#define EPOLLOUT		04h
#define EPOLLRDNORM		40h
#define EPOLLRDBAND		80h
#define EPOLLWRNORM		0100h
#define EPOLLWRBAND		0200h
#define EPOLLMSG		0400h
#define EPOLLERR		08h
#define EPOLLHUP		10h
#define EPOLLRDHUP		2000h
#define EPOLLWAKEUP		20000000h
#define EPOLLONESHOT	40000000h
#define EPOLLET			80000000h

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
	
; Wordexp types
wordexp-type!: alias struct! [
	we_wordc  [integer!]
	we_wordv  [str-array!]
	we_offs   [integer!]
]

pollfd!: alias struct! [
	fd				[integer!]
	events			[integer!]				;-- high 16-bit: events
]											;-- low  16-bit: revents

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

ns_rr!: alias struct! [		;-- size: 1044 (32bit) 1048 (64bit)
	name	[byte!]			;-- 1025 bytes array
	;uint16_t	type;		;-- offset: 1026
	;uint16_t	rr_class;	;-- offset: 1028
	;uint32_t	ttl;		;-- offset: 1032
	;uint16_t	rdlength;	;-- offset: 1036
	;const u_char *	rdata;	;-- offset: 1040
]

ns_msg!: alias struct! [	;-- size: 48 (32bit) 
	msg			[c-string!]
	eom			[c-string!]
	id			[uint16!]
	;flags		[uint16!]
	counts		[integer!]
	counts2		[integer!]
	sections	[byte-ptr!]
	sections2	[byte-ptr!]
	sections3	[byte-ptr!]
	sections4	[byte-ptr!]
	sect		[integer!]
	rrnum		[integer!]
	msg_ptr		[c-string!]
]

res_state!: alias struct! [	;-- size: 512 bytes
	retrans		[integer!]
	retry		[integer!]
	options		[ulong!]
	nscount		[integer!]
	nsaddr1		[sockaddr_in!]
	nsaddr2		[sockaddr_in!]
	nsaddr3		[sockaddr_in!]
	id			[integer!]
]

#switch OS [							;-- loading OS-specific bindings
	macOS	 [#include %darwin.reds]
	FreeBSD  [#include %freebsd.reds]
	NetBSD   [#include %netbsd.reds]
	Syllable [#include %syllable.reds]
	#default [#include %linux.reds]
]

#import [
	LIBC-file cdecl [
		signal: "signal" [
			signum		[integer!]
			handler		[int-ptr!]
			return:		[int-ptr!]
		]
		inet_pton: "inet_pton" [
			Family				[integer!]
			pszAddrString		[c-string!]
			pAddrBuf			[int-ptr!]
			return:				[integer!]
		]
		inet_ntop: "inet_ntop" [
			family		[integer!]
			src			[byte-ptr!]
			dst			[c-string!]
			size		[integer!]
			return:		[c-string!]
		]
		strcmp: "strcmp" [
			str1		[c-string!]
			str2		[c-string!]
			return:		[integer!]
		]
		strdup: "strdup" [
			src			[c-string!]
			return:		[c-string!]
		]
		strncmp: "strncmp" [
			str1		[c-string!]
			str2		[c-string!]
			num			[integer!]
			return:		[integer!]
		]
		strnicmp: "strncasecmp" [
			s1			[byte-ptr!]
			s2			[byte-ptr!]
			len			[integer!]
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
		LibC.time: "time" [
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
		LibC.fork: "fork" [
			return:        [integer!]
		]
		execvp: "execvp" [
			cmd            [c-string!]
			args-list      [str-array!]
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
		LibC.pipe: "pipe" [
			pipedes        [int-ptr!]  "Pointer to a 2 integers array"
			return:        [integer!]
		]
		dup2: "dup2" [
			fd             [integer!]
			fd2            [integer!]
			return:        [integer!]
		]
		libC.dup: "dup" [
			fd		[integer!]
			return: [integer!]
		]
		libC.isatty: "isatty" [
			fd		[integer!]
			return:	[integer!]
		]
		ioctl: "ioctl" [
			fd		[integer!]
			request	[integer!]
			ws		[winsize!]
			return: [integer!]
		]
		LibC.open:	"open" [
			filename	[c-string!]
			flags		[integer!]
			mode		[integer!]
			return:		[integer!]
		]
		LibC.open2: "open" [
			filename		[c-string!]
			flags			[integer!]
			return:			[integer!]
		]
		LibC.close: "close" [
			fd             [integer!]
			return:        [integer!]
		]
		LibC.read: "read" [
			fd             [integer!]
			buf            [byte-ptr!]
			nbytes         [integer!]
			return:        [integer!]  "Number of bytes read or error"
		]
		LibC.write: "write" [
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
		LibC.poll: "poll" [
			fds			[pollfd!]
			nfds		[integer!]
			timeout		[integer!]
			return:		[integer!]
		]
		LibC.access: "access" [
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
		socketpair: "socketpair" [
			domain		[integer!]
			type		[integer!]
			protocl		[integer!]
			sv			[int-ptr!]
			return:		[integer!]
		]
		LibC.remove: "remove" [
			pathname	[c-string!]
			return: 	[integer!]
		]
		libC.socket: "socket" [
			family		[integer!]
			type		[integer!]
			protocl		[integer!]
			return:		[integer!]
		]
		LibC.bind: "bind" [
			fd			[integer!]
			addr		[byte-ptr!]
			addrlen		[integer!]
			return:		[integer!]
		]
		LibC.accept: "accept" [
			fd			[integer!]
			addr		[byte-ptr!]
			addrlen		[int-ptr!]
			return:		[integer!]
		]
		LibC.listen: "listen" [
			fd			[integer!]
			backlog		[integer!]
			return:		[integer!]
		]
		LibC.connect: "connect" [
			fd			[integer!]
			addr		[int-ptr!]
			addrlen		[integer!]
			return:		[integer!]
		]
		LibC.send: "send" [
			fd			[integer!]
			buf			[byte-ptr!]
			len			[ulong!]
			flags		[integer!]
			return:		[long!]
		]
		libC.recv: "recv" [
			fd			[integer!]
			buf			[byte-ptr!]
			len			[ulong!]
			flags		[integer!]
			return:		[long!]
		]
		libC.recvfrom: "recvfrom" [
			fd			[integer!]
			buf			[byte-ptr!]
			len			[ulong!]
			flags		[integer!]
			addr		[sockaddr_in6!]
			addrlen		[int-ptr!]
			return:		[long!]
		]
		libC.sendto: "sendto" [
			fd			[integer!]
			buf			[byte-ptr!]
			len			[ulong!]
			flags		[integer!]
			addr		[sockaddr_in6!]
			addrlen		[integer!]
			return:		[long!]
		]
		sendfile: "sendfile" [
			out_fd		[integer!]
			in_fd		[integer!]
			offset		[int-ptr!]
			count		[integer!]
			return:		[integer!]
		]
		setsockopt: "setsockopt" [
			s			[integer!]
			level		[integer!]
			optname		[integer!]
			optval		[c-string!]
			optlen		[integer!]
			return:		[integer!]
		]
		getsockopt: "getsockopt" [
			s			[integer!]
			level		[integer!]
			optname		[integer!]
			optval		[byte-ptr!]
			optlen		[int-ptr!]
			return:		[integer!]
		]
		getpeername: "getpeername" [
			s			[integer!]
			name		[sockaddr_in6!]
			len			[int-ptr!]
			return:		[integer!]
		]
		htons: "htons" [
			hostshort	[uint16!]
			return:		[uint16!]
		]
		ntohs: "ntohs" [
			netshort	[uint16!]
			return:		[uint16!]
		]
		inet_addr: "inet_addr" [
			cp			[c-string!]
			return:		[integer!]
		]
		_rename: "rename" [
			old		[c-string!]
			new		[c-string!]
			return:	[integer!]
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
			res_ninit: "res_9_ninit" [
				statep		[int-ptr!]
				return:		[integer!]
			]
			res_nclose: "res_9_nclose" [
				statep		[int-ptr!]
			]
			res_nmkquery: "res_9_nmkquery" [
				statep		[int-ptr!]
				options		[integer!]
				dname		[c-string!]
				class		[integer!]
				type		[integer!]
				data		[byte-ptr!]
				datalen		[integer!]
				newrr		[byte-ptr!]
				buf			[byte-ptr!]
				buflen		[integer!]
				return:		[integer!]
			]
			ns_initparse: "res_9_ns_initparse" [
				buf			[byte-ptr!]
				buflen		[integer!]
				pmsg		[ns_msg!]
				return:		[integer!]
			]
			ns_msg_getflag: "res_9_ns_msg_getflag" [
				msg			[ns_msg! value]
				flag		[integer!]
				return:		[integer!]
			]
			ns_parserr: "res_9_ns_parserr" [
				pmsg		[ns_msg!]
				section		[integer!]
				index		[integer!]
				rr			[byte-ptr!]
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
			res_ninit: "__res_ninit" [
				statep		[int-ptr!]
				return:		[integer!]
			]
			res_nclose: "__res_nclose" [
				statep		[int-ptr!]
			]
			res_nmkquery: "__res_nmkquery" [
				statep		[int-ptr!]
				options		[integer!]
				dname		[c-string!]
				class		[integer!]
				type		[integer!]
				data		[byte-ptr!]
				datalen		[integer!]
				newrr		[byte-ptr!]
				buf			[byte-ptr!]
				buflen		[integer!]
				return:		[integer!]
			]
			ns_initparse: "ns_initparse" [
				buf			[byte-ptr!]
				buflen		[integer!]
				pmsg		[ns_msg!]
				return:		[integer!]
			]
			ns_msg_getflag: "ns_msg_getflag" [
				msg			[ns_msg! value]
				flag		[integer!]
				return:		[integer!]
			]
			ns_parserr: "ns_parserr" [
				pmsg		[ns_msg!]
				section		[integer!]
				index		[integer!]
				rr			[byte-ptr!]
				return:		[integer!]
			]
		]
	]
]

#case [
	any [OS = 'macOS OS = 'FreeBSD OS = 'NetBSD] [
		#define O_CREAT		0200h
		#define O_TRUNC		0400h
		#define O_EXCL		0800h
		#define O_APPEND	8
		#define	O_NONBLOCK	4
		#define	O_CLOEXEC	01000000h
		
		#define DIRENT_NAME_OFFSET 8

		#define EVFILT_READ		65535	;-- -1 << 16 >>> 16 (int16!)
		#define EVFILT_WRITE	65534
		#define EVFILT_PROC		65531	;-- attached to struct proc
		#define EVFILT_SIGNAL	65530	;-- attached to struct proc
		#define EVFILT_TIMER	65529	;-- timers
		#define EVFILT_MACHPORT	65528	;-- Mach portsets
		#define EVFILT_FS		65527	;-- Filesystem events
		#define EVFILT_USER		65526	;-- User events
		#define EVFILT_VM		65524	;-- Virtual memory events
		#define EVFILT_SYSCOUNT	14

		;/* actions */
		#define EV_ADD			01h		;-- add event to kq (implies enable)
		#define EV_DELETE		02h		;-- delete event from kq
		#define EV_ENABLE		04h		;-- enable event
		#define EV_DISABLE		08h		;-- disable event (not reported)
		#define EV_RECEIPT		40h		;-- force EV_ERROR on success, data == 0

		;/* flags */
		#define EV_ONESHOT		10h		;-- only report one occurrence
		#define EV_CLEAR		20h		;-- clear event state after reporting
		#define EV_DISPATCH		80h		;-- disable event after reporting

		#define EV_SYSFLAGS		F000h	;-- reserved by system
		#define EV_FLAG0		1000h	;-- filter-specific flag
		#define EV_FLAG1		2000h	;-- filter-specific flag

		;/* returned values */
		#define EV_EOF			8000h	;-- EOF detected
		#define EV_ERROR		4000h	;-- error, data contains errno

		#define EV_SET(kevp a b c d e f) [
			kevp/ident: as int-ptr! a
			kevp/filter: c << 16 or b
			kevp/fflags: d
			kevp/data: e
			kevp/udata: as int-ptr! f
		]

		kevent!: alias struct! [
			ident		[int-ptr!]		;-- identifier for this event
			filter		[integer!]
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
				LibC.kqueue: "kqueue" [
					return: [integer!]
				]
				LibC.kevent: "kevent" [
					kq		[integer!]
					clist	[kevent!]
					nchange [integer!]
					evlist	[kevent!]
					nevents [integer!]
					timeout [timespec!]
					return: [integer!]
				]
			]
		]

		#define epoll_event! kevent!
	]
	true [
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

		epoll_event!: alias struct! [
			events		[integer!]
			udata		[int-ptr!]
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

#either OS = 'macOS [
	#define LIBSSL-file "libssl.44.dylib"

	X509_VAL!: alias struct! [
		notBefore		[int-ptr!]
		notAfter		[int-ptr!]
	]
	X509_CINF!: alias struct! [
		version			[int-ptr!]
		serialNumber	[int-ptr!]
		signature		[int-ptr!]
		issuer			[int-ptr!]
		validity		[X509_VAL!]
		subject			[int-ptr!]
		key				[int-ptr!]
		issuerUID		[int-ptr!]
		subjectUID		[int-ptr!]
		extensions		[int-ptr!]
		enc				[int-ptr!]
	]
	X509!: alias struct! [
		cert_info	[X509_CINF!]
		sig_alg		[int-ptr!]
		;; more fields
	]
	X509_getm_notBefore: func [
		cert		[int-ptr!]
		return:		[int-ptr!]
		/local
			x		[X509!]
	][
		x: as X509! cert
		x/cert_info/validity/notBefore
	]
	X509_getm_notAfter: func [
		cert		[int-ptr!]
		return:		[int-ptr!]
		/local
			x		[X509!]
	][
		x: as X509! cert
		x/cert_info/validity/notAfter
	]
][
	#define LIBSSL-file "libssl.so"
]

#define SSL_ERROR_SSL			1
#define SSL_ERROR_WANT_READ		2
#define SSL_ERROR_WANT_WRITE	3
#define SSL_ERROR_WANT_X509_LOOKUP	4
#define SSL_ERROR_SYSCALL		5
#define SSL_ERROR_ZERO_RETURN	6
#define SSL_CTRL_SET_MIN_PROTO_VERSION          123
#define SSL_CTRL_SET_MAX_PROTO_VERSION          124
#define SSL_CTRL_EXTRA_CHAIN_CERT               14
#define SSL_CTRL_CHAIN_CERT                     89
#define SSL_CTRL_SET_TLSEXT_HOSTNAME            55
#define TLSEXT_NAMETYPE_host_name				0
#define SSL_MODE_ENABLE_PARTIAL_WRITE 			1

#define SSL_TLSEXT_ERR_OK 0
#define SSL_TLSEXT_ERR_NOACK 3

#define SSL_VERIFY_NONE							0
#define SSL_VERIFY_PEER							1

#define SSL_CTX_set_mode(ctx mode) [SSL_CTX_ctrl ctx 33 mode null]

#import [
	LIBSSL-file cdecl [
		SSL_CTX_set_default_verify_paths: "SSL_CTX_set_default_verify_paths" [
			ctx		[int-ptr!]
			return: [integer!]
		]
		SSL_CTX_set_cipher_list: "SSL_CTX_set_cipher_list" [
			ctx		[int-ptr!]
			str		[c-string!]
			return: [integer!]
		]
		SSL_CTX_callback_ctrl: "SSL_CTX_callback_ctrl" [
			ctx		[int-ptr!]
			cmd		[integer!]
			cb		[int-ptr!]
			return: [integer!]
		]
		SSL_CTX_new: "SSL_CTX_new" [
			method	[int-ptr!]
			return: [int-ptr!]
		]
		SSL_CTX_free: "SSL_CTX_free" [
			ctx		[int-ptr!]
		]
		TLS_client_method: "TLS_client_method" [
			return: [int-ptr!]
		]
		TLS_server_method: "TLS_server_method" [
			return: [int-ptr!]
		]
		SSL_CTX_set_options: "SSL_CTX_set_options" [
			ctx		[int-ptr!]
			opts	[integer!]
			return:	[integer!]
		]
		SSL_CTX_set_security_level: "SSL_CTX_set_security_level" [
			ctx		[int-ptr!]
			level	[integer!]
			return:	[integer!]
		]
		SSL_CTX_get_security_level: "SSL_CTX_get_security_level" [
			ctx		[int-ptr!]
			return:	[integer!]
		]
		SSL_CTX_build_cert_chain: "SSL_CTX_build_cert_chain" [
			ctx		[int-ptr!]
			flags	[integer!]
			return: [integer!]
		]
		SSL_CTX_use_certificate_chain_file: "SSL_CTX_use_certificate_chain_file" [
			ctx		[int-ptr!]
			file	[c-string!]
			return: [integer!]
		]
		SSL_CTX_use_PrivateKey_file: "SSL_CTX_use_PrivateKey_file" [
			ctx		[int-ptr!]
			file	[c-string!]
			flags	[integer!]
			return: [integer!]
		]
		SSL_CTX_use_PrivateKey: "SSL_CTX_use_PrivateKey" [
			ctx		[int-ptr!]
			pkey	[int-ptr!]
			return: [integer!]
		]
		SSL_CTX_use_certificate: "SSL_CTX_use_certificate" [
			ctx		[int-ptr!]
			x		[int-ptr!]
			return: [integer!]
		]
		SSL_CTX_use_RSAPrivateKey: "SSL_CTX_use_RSAPrivateKey" [
			ctx		[int-ptr!]
			rsa		[int-ptr!]
			return: [integer!]
		]
		SSL_CTX_ctrl: "SSL_CTX_ctrl" [
			ctx		[int-ptr!]
			cmd		[integer!]
			larg	[integer!]
			parg	[int-ptr!]
			return:	[integer!]
		]
		SSL_CTX_check_private_key: "SSL_CTX_check_private_key" [
			ctx		[int-ptr!]
			return: [integer!]
		]
		SSL_CTX_set_verify: "SSL_CTX_set_verify" [
			ctx		[int-ptr!]
			mode	[integer!]
			cb		[int-ptr!]
		]
		SSL_CTX_set_cert_store: "SSL_CTX_set_cert_store" [
			ctx		[int-ptr!]
			store	[int-ptr!]
		]
		SSL_CTX_get_cert_store: "SSL_CTX_get_cert_store" [
			ctx		[int-ptr!]
			return:	[int-ptr!]
		]
		SSL_get_verify_result: "SSL_get_verify_result" [
			ssl		[int-ptr!]
			return:	[integer!]
		]
		SSL_get_shutdown: "SSL_get_shutdown" [
			ssl		[int-ptr!]
			return: [integer!]
		]
		BIO_new_mem_buf: "BIO_new_mem_buf" [
			buf		[c-string!]
			len		[integer!]
			return:	[int-ptr!]
		]
		PEM_read_bio_X509: "PEM_read_bio_X509" [
			bp		[int-ptr!]
			X509	[int-ptr!]
			cb		[int-ptr!]
			u		[byte-ptr!]
			return:	[int-ptr!]
		]
		PEM_read_bio_RSAPrivateKey: "PEM_read_bio_RSAPrivateKey" [
			bp		[int-ptr!]
			rsa		[int-ptr!]
			cb		[int-ptr!]
			u		[byte-ptr!]
			return:	[int-ptr!]
		]
		PEM_read_bio_PrivateKey: "PEM_read_bio_PrivateKey" [
			bp		[int-ptr!]
			key		[int-ptr!]
			cb		[int-ptr!]
			u		[byte-ptr!]
			return:	[int-ptr!]
		]
		BIO_free: "BIO_free" [
			bio		[int-ptr!]
		]
		EVP_PKEY_new: "EVP_PKEY_new" [return: [int-ptr!]]
		EVP_PKEY_free: "EVP_PKEY_free" [key [int-ptr!]]
		EVP_PKEY_set1_RSA: "EVP_PKEY_set1_RSA" [
			pkey	[int-ptr!]
			key		[int-ptr!]
			return: [integer!]
		]
		d2i_AutoPrivateKey: "d2i_AutoPrivateKey" [
			pkey	[int-ptr!]
			pp		[int-ptr!]
			len		[integer!]
			return:	[int-ptr!]
		]
		RSA_new: "RSA_new" [return: [int-ptr!]]
		RSA_free: "RSA_free" [rsa [int-ptr!]]
		RSA_generate_key_ex: "RSA_generate_key_ex" [
			rsa		[int-ptr!]
			bits	[integer!]
			e		[int-ptr!]
			cb		[int-ptr!]
			return: [integer!]
		]
		BN_new: "BN_new" [return: [int-ptr!]]
		BN_free: "BN_free" [a [int-ptr!]]
		BN_set_word: "BN_set_word" [
			a		[int-ptr!]
			w		[integer!]
			return: [integer!]
		]
		X509_new: "X509_new" [
			return: [int-ptr!]
		]
		X509_free: "X509_free" [
			a		[int-ptr!]
		]
		X509_get_serialNumber: "X509_get_serialNumber" [
			a		[int-ptr!]
			return: [int-ptr!]
		]
		X509_STORE_add_cert: "X509_STORE_add_cert" [
			store	[int-ptr!]
			x509	[int-ptr!]
			return:	[integer!]
		]
		X509_STORE_set_default_paths: "X509_STORE_set_default_paths" [
			store	[int-ptr!]
			return:	[integer!]
		]
		ASN1_INTEGER_set: "ASN1_INTEGER_set" [
			a		[int-ptr!]
			v		[integer!]
			return: [integer!]
		]
		#if OS <> 'macOS [
		X509_getm_notBefore: "X509_getm_notBefore" [
			x		[int-ptr!]
			return: [int-ptr!]
		]
		X509_getm_notAfter: "X509_getm_notAfter" [
			x		[int-ptr!]
			return: [int-ptr!]
		]]
		X509_time_adj_ex: "X509_time_adj_ex" [
			t		[int-ptr!]
			day		[integer!]
			sec		[integer!]
			tm		[integer!]
			return: [int-ptr!]
		]
		X509_set_pubkey: "X509_set_pubkey" [
			x		[int-ptr!]
			pkey	[int-ptr!]
			return: [integer!]
		]
		X509_get_subject_name: "X509_get_subject_name" [
			x		[int-ptr!]
			return: [int-ptr!]
		]
		X509_NAME_add_entry_by_txt: "X509_NAME_add_entry_by_txt" [
			name	[int-ptr!]
			a		[c-string!]
			b		[integer!]
			full	[c-string!]
			c		[integer!]
			d		[integer!]
			e		[integer!]
			return: [integer!]
		]
		X509_set_issuer_name: "X509_set_issuer_name" [
			x		[int-ptr!]
			name	[int-ptr!]
			return: [integer!]
		]
		X509_sign: "X509_sign" [
			x		[int-ptr!]
			pkey	[int-ptr!]
			m		[int-ptr!]
			return: [integer!]
		]
		X509_STORE_new: "X509_STORE_new" [
			return: [int-ptr!]
		]
		EVP_sha1: "EVP_sha1" [
			return: [int-ptr!]
		]
		SSL_new: "SSL_new" [
			ctx		[int-ptr!]
			return: [int-ptr!]
		]
		SSL_free: "SSL_free" [
			ssl		[int-ptr!]
		]
		SSL_clear: "SSL_clear" [
			ssl		[int-ptr!]
			return: [integer!]
		]
		SSL_set_SSL_CTX: "SSL_set_SSL_CTX" [
			ssl		[int-ptr!]
			ctx		[int-ptr!]
			return: [int-ptr!]
		]
		SSL_get_servername: "SSL_get_servername" [
			ssl		[int-ptr!]
			type	[integer!]
			return: [c-string!]
		]
		SSL_set_fd: "SSL_set_fd" [
			ssl		[int-ptr!]
			fd		[integer!]
			return: [integer!]
		]
		SSL_set_connect_state: "SSL_set_connect_state" [
			ssl		[int-ptr!]
		]
		SSL_set_accept_state: "SSL_set_accept_state" [
			ssl		[int-ptr!]
		]
		SSL_ctrl: "SSL_ctrl" [
			ssl		[int-ptr!]
			cmd		[integer!]
			larg	[integer!]
			parg	[int-ptr!]
			return:	[integer!]
		]
		SSL_do_handshake: "SSL_do_handshake" [
			ssl		[int-ptr!]
			return: [integer!]
		]
		SSL_get_error: "SSL_get_error" [
			ssl		[int-ptr!]
			ret		[integer!]
			return: [integer!]
		]
		SSL_shutdown: "SSL_shutdown" [
			ssl		[int-ptr!]
			return: [integer!]
		]
		SSL_read: "SSL_read" [
			ssl		[int-ptr!]
			buf		[byte-ptr!]
			num		[integer!]
			return:	[integer!]
		]
		SSL_write: "SSL_write" [
			ssl		[int-ptr!]
			buf		[byte-ptr!]
			num		[integer!]
			return:	[integer!]
		]
		ERR_clear_error: "ERR_clear_error" []
		ERR_get_error: "ERR_get_error" [return: [integer!]]
		ERR_error_string: "ERR_error_string" [
			e		[integer!]
			buf		[c-string!]
			return: [c-string!]
		]
	]
]