Red/System [
	Title:   "POSIX I/O API imported functions definitions"
	Author:  "Xie Qingtian"
	File: 	 %POSIX.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2017 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#case [
	OS = 'FreeBSD [
		;-- http://fxr.watson.org/fxr/source/sys/stat.h?v=FREEBSD10
		stat!: alias struct! [
			st_dev		[integer!]
			st_ino		[integer!]
			st_modelink	[integer!]				;-- st_mode & st_link are both 16bit fields
			st_uid		[integer!]
			st_gid		[integer!]
			st_rdev		[integer!]
			atv_sec		[integer!]				;-- struct timespec inlined
			atv_msec	[integer!]
			mtv_sec		[integer!]				;-- struct timespec inlined
			mtv_msec	[integer!]
			ctv_sec		[integer!]				;-- struct timespec inlined
			ctv_msec	[integer!]
			st_size		[integer!]
			st_size_h	[integer!]
			st_blocks_l	[integer!]
			st_blocks_h	[integer!]
			st_blksize	[integer!]
			st_flags	[integer!]
			st_gen		[integer!]
			st_lspare	[integer!]
			btm_sec     [integer!]
			btm_msec    [integer!]				;-- struct timespec inlined
			pad0		[integer!]
			pad1		[integer!]
		]
		dirent!: alias struct! [				;@@ the same as macOS
			d_ino		[integer!]
			d_reclen	[byte!]
			_d_reclen_	[byte!]
			d_type		[byte!]
			d_namlen	[byte!]
			;d_name		[byte! [256]]
		]
	]
	OS = 'macOS [
		stat!: alias struct! [
			st_dev		[integer!]
			st_ino		[integer!]
			st_modelink	[integer!]				;-- st_mode & st_link are both 16bit fields
			st_uid		[integer!]
			st_gid		[integer!]
			st_rdev		[integer!]
			atv_sec		[integer!]				;-- struct timespec inlined
			atv_msec	[integer!]
			mtv_sec		[integer!]				;-- struct timespec inlined
			mtv_msec	[integer!]
			ctv_sec		[integer!]				;-- struct timespec inlined
			ctv_msec	[integer!]
			st_size		[integer!]
			st_blocks	[integer!]
			st_blksize	[integer!]
			st_flags	[integer!]
			st_gen		[integer!]
			st_lspare	[integer!]
			st_qspare_1 [integer!]				;-- int64
			st_qspare_2 [integer!]
			st_qspare_3 [integer!]				;-- int64
			st_qspare_4 [integer!]
		]
		;;-- #if __DARWIN_64_BIT_INO_T
		;stat!: alias struct! [				;-- __DARWIN_STRUCT_STAT64
		;	st_dev		[integer!]
		;	st_modelink	[integer!]			;-- st_mode & st_link are both 16bit fields
		;	st_ino_1	[integer!]			;-- int64
		;	st_ino_2	[integer!]
		;	st_uid		[integer!]
		;	st_gid		[integer!]
		;	st_rdev		[integer!]
		;	atv_sec		[integer!]
		;	atv_msec	[integer!]
		;	mtv_sec		[integer!]
		;	mtv_msec	[integer!]
		;	ctv_sec		[integer!]
		;	ctv_msec	[integer!]
		;	birth_sec	[integer!]
		;	birth_msec	[integer!]
		;	st_size_1	[integer!]			;-- int64
		;	st_size		[integer!]
		;	st_blocks_1	[integer!]			;-- int64
		;	st_blocks_2	[integer!]
		;	st_blksize	[integer!]
		;	st_flags	[integer!]
		;	st_gen		[integer!]
		;	st_lspare	[integer!]
		;	st_qspare_1 [integer!]			;-- int64
		;	st_qspare_2 [integer!]
		;	st_qspare_3 [integer!]			;-- int64
		;	st_qspare_4 [integer!]
		;]
		;#define DIRENT_NAME_OFFSET	21
		;dirent!: alias struct! [
		;	d_ino		[integer!]
		;	_d_ino_		[integer!]
		;	d_seekoff	[integer!]
		;	_d_seekoff_	[integer!]
		;	d_reclen	[integer!]				;-- d_reclen & d_namlen
		;	;d_namlen	[integer!]
		;	d_type		[byte!]
		;	;d_name		[byte! [1024]]
		;]
		;;-- #endif

		dirent!: alias struct! [
			d_ino		[integer!]
			d_reclen	[byte!]
			_d_reclen_	[byte!]
			d_type		[byte!]
			d_namlen	[byte!]
			;d_name		[byte! [256]]
		]
	]
	OS = 'Syllable [
		;-- http://glibc.sourcearchive.com/documentation/2.7-18lenny7/glibc-2_87_2bits_2stat_8h_source.html
		stat!: alias struct! [
			st_mode		[integer!]
			st_ino		[integer!]
			st_dev		[integer!]
			st_nlink	[integer!]
			st_uid		[integer!]
			st_gid		[integer!]
			filler1		[integer!]				;-- not in spec above...
			filler2		[integer!]				;-- not in spec above...
			st_size		[integer!]
			;...incomplete...
		]
		#define DIRENT_NAME_OFFSET 8
		dirent!: alias struct! [
			d_ino		[integer!]
			d_reclen	[byte!]
			_d_reclen_	[byte!]
			d_type		[byte!]
			d_namlen	[byte!]
			;d_name		[byte! [256]]
		]
	]
	all [legacy find legacy 'stat32] [
		stat!: alias struct! [
			st_dev		[integer!]
			st_ino		[integer!]
			st_mode		[integer!]
			st_nlink	[integer!]
			st_uid		[integer!]
			st_gid		[integer!]
			st_rdev		[integer!]
			st_size		[integer!]
			st_blksize	[integer!]
			st_blocks	[integer!]
			st_atime	[integer!]
			st_mtime	[integer!]
			st_ctime	[integer!]
		]
		#define DIRENT_NAME_OFFSET 8
		dirent!: alias struct! [
			d_ino		[integer!]
			d_reclen	[byte!]
			_d_reclen_	[byte!]
			d_type		[byte!]
			d_namlen	[byte!]
			;d_name		[byte! [256]]
		]
	]
	OS = 'Android [ ; else
		;https://android.googlesource.com/platform/bionic.git/+/master/libc/include/sys/stat.h
		stat!: alias struct! [					;-- stat64 struct
			st_dev_h	  [integer!]
			st_dev_l	  [integer!]
			pad0		  [integer!]
			__st_ino	  [integer!]
			st_mode		  [integer!]
			st_nlink	  [integer!]
			st_uid		  [integer!]
			st_gid		  [integer!]
			st_rdev_h	  [integer!]
			st_rdev_l	  [integer!]
			pad1		  [integer!]
			st_size_h	  [integer!]
			st_size	  [integer!]
			st_blksize	  [integer!]
			st_blocks_h	  [integer!]
			st_blocks	  [integer!]
			st_atime	  [integer!]
			st_atime_nsec [integer!]
			st_mtime	  [integer!]
			st_mtime_nsec [integer!]
			st_ctime	  [integer!]
			st_ctime_nsec [integer!]
			st_ino_h	  [integer!]
			st_ino_l	  [integer!]
			;...optional padding skipped
		]
		#define DIRENT_NAME_OFFSET	19
		dirent!: alias struct! [
			d_ino		[integer!]
			_d_ino_		[integer!]
			d_off		[integer!]
			_d_off_		[integer!]
			d_reclen	[byte!]
			_d_reclen_	[byte!]
			d_type		[byte!]
			;d_name		[byte! [256]]
		]
	]
	true [ ; else
		;-- http://lxr.free-electrons.com/source/arch/x86/include/uapi/asm/stat.h
		stat!: alias struct! [					;-- stat64 struct
			st_dev_l	  [integer!]
			st_dev_h	  [integer!]
			pad0		  [integer!]
			__st_ino	  [integer!]
			st_mode		  [integer!]
			st_nlink	  [integer!]
			st_uid		  [integer!]
			st_gid		  [integer!]
			st_rdev_l	  [integer!]
			st_rdev_h	  [integer!]
			pad1		  [integer!]
			st_size		  [integer!]
			st_blksize	  [integer!]
			st_blocks	  [integer!]
			st_atime	  [integer!]
			st_atime_nsec [integer!]
			st_mtime	  [integer!]
			st_mtime_nsec [integer!]
			st_ctime	  [integer!]
			st_ctime_nsec [integer!]
			st_ino_h	  [integer!]
			st_ino_l	  [integer!]
			;...optional padding skipped
		]

		#define DIRENT_NAME_OFFSET 11
		dirent!: alias struct! [
			d_ino			[integer!]
			d_off			[integer!]
			d_reclen		[byte!]
			d_reclen_pad	[byte!]
			d_type			[byte!]
			;d_name			[byte! [256]]
		]
	]
]

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

timespec!: alias struct! [
	tv_sec	[integer!]
	tv_nsec [integer!]
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
			data		[integer!]
		]
		#import [
			LIBC-file cdecl [
				epoll_create: "epoll_create" [
					size	[integer!]
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

#import [
	LIBC-file cdecl [
		_access: "access" [
			filename	[c-string!]
			mode		[integer!]
			return:		[integer!]
		]
		_open:	"open" [
			filename	[c-string!]
			flags		[integer!]
			mode		[integer!]
			return:		[integer!]
		]
		_read:	"read" [
			file		[integer!]
			buffer		[byte-ptr!]
			bytes		[integer!]
			return:		[integer!]
		]
		_write:	"write" [
			file		[integer!]
			buffer		[byte-ptr!]
			bytes		[integer!]
			return:		[integer!]
		]
		_close:	"close" [
			file		[integer!]
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
	]
]
