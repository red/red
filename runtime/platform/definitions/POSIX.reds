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

#define SOL_SOCKET	1
#define	DT_DIR		#"^(04)"

#define BFFM_SETEXPANDED 1130

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
		LibC.pipe: "pipe" [
			pipedes        [int-ptr!]  "Pointer to a 2 integers array"
			return:        [integer!]
		]
		dup2: "dup2" [
			fd             [integer!]
			fd2            [integer!]
			return:        [integer!]
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
	#define LIBSSL-file "libssl.dylib"
][
	#define LIBSSL-file "libssl.so"
]

#import [
	LIBSSL-file cdecl [
		SSL_CTX_new: "SSL_CTX_new" [
			method	[int-ptr!]
			return: [int-ptr!]
		]
		TLS_client_method: "TLS_client_method" [
			return: [int-ptr!]
		]
		TLS_server_method: "TLS_server_method" [
			return: [int-ptr!]
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
		SSL_CTX_check_private_key: "SSL_CTX_check_private_key" [
			ctx		[int-ptr!]
			return: [integer!]
		]
		EVP_PKEY_new: "EVP_PKEY_new" [return: [int-ptr!]]
		EVP_PKEY_free: "EVP_PKEY_free" [key [int-ptr!]]
		EVP_PKEY_set1_RSA: "EVP_PKEY_set1_RSA" [
			pkey	[int-ptr!]
			key		[int-ptr!]
			return: [integer!]
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
		ASN1_INTEGER_set: "ASN1_INTEGER_set" [
			a		[int-ptr!]
			v		[integer!]
			return: [integer!]
		]
		X509_getm_notBefore: "X509_getm_notBefore" [
			x		[int-ptr!]
			return: [int-ptr!]
		]
		X509_getm_notAfter: "X509_getm_notAfter" [
			x		[int-ptr!]
			return: [int-ptr!]
		]
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
		ERR_get_error: "ERR_get_error" [return: [integer!]]
		ERR_error_string: "ERR_error_string" [
			e		[integer!]
			buf		[c-string!]
			return: [c-string!]
		]
	]
]