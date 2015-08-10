Red/System [
	Title:	"Simple file IO functions (temporary)"
	Author: "Nenad Rakocevic"
	File: 	%simple-io.reds
	Tabs: 	4
	Rights: "Copyright (C) 2012-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

simple-io: context [

	#enum red-io-mode! [
		RIO_READ:	1
		RIO_WRITE:	2
		RIO_APPEND:	4
		RIO_SEEK:	8
		RIO_NEW:	16
	]

	#either OS = 'Windows [

		#define GENERIC_WRITE			40000000h
		#define GENERIC_READ 			80000000h
		#define FILE_SHARE_READ			00000001h
		#define FILE_SHARE_WRITE		00000002h
		#define OPEN_ALWAYS				00000004h
		#define OPEN_EXISTING			00000003h
		#define CREATE_ALWAYS			00000002h
		#define FILE_ATTRIBUTE_NORMAL	00000080h

		#define SET_FILE_BEGIN			0
		#define SET_FILE_CURRENT		1
		#define SET_FILE_END			2

		#import [
			"kernel32.dll" stdcall [
				CreateFileA: "CreateFileA" [			;-- temporary needed by Red/System
					filename	[c-string!]
					access		[integer!]
					share		[integer!]
					security	[int-ptr!]
					disposition	[integer!]
					flags		[integer!]
					template	[int-ptr!]
					return:		[integer!]
				]
				CreateFileW: "CreateFileW" [
					filename	[c-string!]
					access		[integer!]
					share		[integer!]
					security	[int-ptr!]
					disposition	[integer!]
					flags		[integer!]
					template	[int-ptr!]
					return:		[integer!]
				]
				ReadFile:	"ReadFile" [
					file		[integer!]
					buffer		[byte-ptr!]
					bytes		[integer!]
					read		[int-ptr!]
					overlapped	[int-ptr!]
					return:		[integer!]
				]
				WriteFile:	"WriteFile" [
					file		[integer!]
					buffer		[byte-ptr!]
					bytes		[integer!]
					written		[int-ptr!]
					overlapped	[int-ptr!]
					return:		[integer!]
				]
				GetFileSize: "GetFileSize" [
					file		[integer!]
					high-size	[integer!]
					return:		[integer!]
				]
				CloseHandle:	"CloseHandle" [
					obj			[integer!]
					return:		[integer!]
				]
				SetFilePointer: "SetFilePointer" [
					file		[integer!]
					distance	[integer!]
					pDistance	[int-ptr!]
					dwMove		[integer!]
					return:		[integer!]
				]
				SetEndOfFile: "SetEndOfFile" [
					file		[integer!]
					return:		[integer!]
				]
			]
		]
	][
		#define O_RDONLY	0
		#define O_WRONLY	1
		#define O_RDWR		2
		#define O_BINARY	4

		#define O_CREAT		64

		#define S_IREAD		256
		#define S_IWRITE    128
		#define S_IRGRP		[S_IREAD >> 3]
		#define S_IWGRP		[S_IWRITE >> 3]
		#define S_IROTH		[S_IREAD >> 6]

		#import [
			LIBC-file cdecl [
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
			]
		]
		
		#case [
			OS = 'FreeBSD [
				;-- http://fxr.watson.org/fxr/source/sys/stat.h?v=FREEBSD10
				stat!: alias struct! [
					st_dev		[integer!]
					st_ino		[integer!]
					st_modelink	[integer!]					;-- st_mode & st_link are both 16bit fields
					st_uid		[integer!]
					st_gid		[integer!]
					st_rdev		[integer!]
					atv_sec		[integer!]					;-- struct timespec inlined
					atv_msec	[integer!]
					mtv_sec		[integer!]					;-- struct timespec inlined
					mtv_msec	[integer!]
					ctv_sec		[integer!]					;-- struct timespec inlined
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
					btm_msec    [integer!]                  ;-- struct timespec inlined
					pad0		[integer!]
					pad1		[integer!]
				]
			]
			OS = 'MacOSX [
				stat!: alias struct! [
					st_dev		[integer!]
					st_ino		[integer!]
					st_modelink	[integer!]					;-- st_mode & st_link are both 16bit fields
					st_uid		[integer!]
					st_gid		[integer!]
					st_rdev		[integer!]
					atv_sec		[integer!]					;-- struct timespec inlined
					atv_msec	[integer!]
					mtv_sec		[integer!]					;-- struct timespec inlined
					mtv_msec	[integer!]
					ctv_sec		[integer!]					;-- struct timespec inlined
					ctv_msec	[integer!]
					st_size		[integer!]
					st_blocks	[integer!]
					st_blksize	[integer!]
					st_flags	[integer!]
					st_gen		[integer!]
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
			]
			OS = 'Android [ ; else
				;https://android.googlesource.com/platform/bionic.git/+/master/libc/include/sys/stat.h
				stat!: alias struct! [				;-- stat64 struct
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
			]
			true [ ; else
				;-- http://lxr.free-electrons.com/source/arch/x86/include/uapi/asm/stat.h
				stat!: alias struct! [				;-- stat64 struct
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
			]
		]

		#case [
			any [OS = 'MacOSX OS = 'FreeBSD OS = 'Android] [
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
	]
	
	open-file: func [
		filename [c-string!]
		mode	 [integer!]
		unicode? [logic!]
		return:	 [integer!]
		/local
			file   [integer!]
			modes  [integer!]
			access [integer!]
	][
		#either OS = 'Windows [
			either mode and RIO_READ <> 0 [
				modes: GENERIC_READ
				access: OPEN_EXISTING
			][
				modes: GENERIC_WRITE
				either mode and RIO_APPEND <> 0 [
					access: OPEN_ALWAYS
				][
					access: CREATE_ALWAYS
				]
			]
			either unicode? [
				file: CreateFileW
					filename
					modes
					FILE_SHARE_READ or FILE_SHARE_WRITE
					null
					access
					FILE_ATTRIBUTE_NORMAL
					null
			][
				file: CreateFileA
					filename
					modes
					FILE_SHARE_READ or FILE_SHARE_WRITE
					null
					access
					FILE_ATTRIBUTE_NORMAL
					null
			]
		][
			either mode and RIO_READ <> 0 [
				modes: O_BINARY or O_RDONLY
				access: S_IREAD
			][
				modes: O_BINARY or O_WRONLY or O_CREAT
				access: S_IREAD or S_IWRITE or S_IRGRP or S_IWGRP or S_IROTH
			]
			file: _open filename modes access
		]
		if file = -1 [return -1]
		file
	]
	
	file-size?: func [
		file	 [integer!]
		return:	 [integer!]
		/local s
	][
		#case [
			OS = 'Windows [
				GetFileSize file null
			]
			any [OS = 'MacOSX OS = 'FreeBSD OS = 'Android] [
				s: declare stat!
				_stat file s
				s/st_size
			]
			true [ ; else
				s: declare stat!
				_stat 3 file s
				s/st_size
			]
		]
	]
	
	read-buffer: func [
		file	[integer!]
		buffer	[byte-ptr!]
		size	[integer!]
		return:	[integer!]
		/local
			read-sz [integer!]
			res		[integer!]
	][
		#either OS = 'Windows [
			read-sz: -1
			res: ReadFile file buffer size :read-sz null
			res: either zero? res [-1][1]
		][
			res: _read file buffer size
		]
		res
	]
	
	close-file: func [
		file	[integer!]
		return:	[integer!]
	][
		#either OS = 'Windows [
			CloseHandle file
		][
			_close file
		]
	]

	to-OS-path: func [
		src		[red-file!]
		return: [c-string!]
		/local
			str [red-string!]
			len [integer!]
	][
		str: string/rs-make-at stack/push* string/rs-length? as red-string! src
		file/to-local-path src str no
		#either OS = 'Windows [
			unicode/to-utf16 str
		][
			len: -1
			unicode/to-utf8 str :len no
		]
	]

	read-file: func [
		filename [c-string!]
		binary?	 [logic!]
		unicode? [logic!]
		return:	 [red-value!]
		/local
			buffer	[byte-ptr!]
			file	[integer!]
			size	[integer!]
			val		[red-value!]
			str		[red-string!]
			len		[integer!]
	][
		unless unicode? [		;-- only command line args need to be checked
			if filename/1 = #"^"" [filename: filename + 1]	;-- FIX: issue #1234
			len: length? filename
			if filename/len = #"^"" [filename/len: null-byte]
		]
		file: open-file filename RIO_READ unicode?
		if file < 0 [return none-value]

		size: file-size? file

		if size <= 0 [
			print-line "*** Warning: empty file"
		]
		
		buffer: allocate size
		len: read-buffer file buffer size
		close-file file

		if negative? len [return none-value]

		val: as red-value! either binary? [
			binary/load buffer size
		][
			str: as red-string! stack/push*
			str/header: TYPE_STRING							;-- implicit reset of all header flags
			str/head: 0
			str/node: unicode/load-utf8-buffer as-c-string buffer size null null yes
			str/cache: either size < 64 [as-c-string buffer][null]			;-- cache only small strings
			str
		]
		free buffer
		val
	]

	write-file: func [
		filename [c-string!]
		data	 [byte-ptr!]
		size	 [integer!]
		binary?	 [logic!]
		append?  [logic!]
		unicode? [logic!]
		return:	 [integer!]
		/local
			file	[integer!]
			len		[integer!]
			mode	[integer!]
			ret		[integer!]
	][
		unless unicode? [		;-- only command line args need to be checked
			if filename/1 = #"^"" [filename: filename + 1]	;-- FIX: issue #1234
			len: length? filename
			if filename/len = #"^"" [filename/len: null-byte]
		]
		mode: RIO_WRITE
		if append? [mode: mode or RIO_APPEND]
		file: open-file filename mode unicode?
		if file < 0 [return file]

		#either OS = 'Windows [
			len: 0
			if append? [SetFilePointer file 0 null SET_FILE_END]
			ret: WriteFile file data size :len null
			ret: either zero? ret [-1][1]
		][
			ret: _write file data size
		]
		close-file file
		ret
	]

	read: func [
		filename [red-file!]
		binary?	 [logic!]
		return:	 [red-value!]
		/local
			data [red-value!]
	][
		data: read-file to-OS-path filename binary? yes
		if TYPE_OF(data) = TYPE_NONE [
			fire [TO_ERROR(access cannot-open) filename]
		]
		data
	]

	write: func [
		filename [red-file!]
		data	 [red-value!]
		part	 [red-value!]
		binary?	 [logic!]
		append?  [logic!]
		return:  [integer!]
		/local
			len  	[integer!]
			str  	[red-string!]
			buf  	[byte-ptr!]
			int  	[red-integer!]
			limit	[integer!]
			type	[integer!]
	][
		limit: -1
		if OPTION?(part) [
			either TYPE_OF(part) = TYPE_INTEGER [
				int: as red-integer! part
				if negative? int/value [return -1]			;-- early exit if part <= 0
				limit: int/value
			][
				ERR_INVALID_REFINEMENT_ARG(refinements/_part part)
			]
		]
		type: TYPE_OF(data)
		case [
			type = TYPE_STRING [
				len: limit
				str: as red-string! data
				buf: as byte-ptr! unicode/to-utf8 str :len not binary?
			]
			type = TYPE_BINARY [
				buf: binary/rs-head as red-binary! data
				len: binary/rs-length? as red-binary! data
				if all [limit > 0 len > limit][len: limit]
			]
			true [ERR_EXPECT_ARGUMENT(type 1)]
		]
		type: write-file to-OS-path filename buf len binary? append? yes
		if negative? type [
			fire [TO_ERROR(access cannot-open) filename]
		]
		type
	]
]
