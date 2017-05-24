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

		WIN32_FIND_DATA: alias struct! [
			dwFileAttributes	[integer!]
			ftCreationTime		[float!]
			ftLastAccessTime	[float!]
			ftLastWriteTime		[float!]
			nFileSizeHigh		[integer!]
			nFileSizeLow		[integer!]
			dwReserved0			[integer!]
			dwReserved1			[integer!]
			;cFileName			[byte-ptr!]				;-- WCHAR  cFileName[ 260 ]
			;cAlternateFileName	[c-string!]				;-- cAlternateFileName[ 14 ]
		]

		#import [
			"kernel32.dll" stdcall [
				GetFileAttributesW: "GetFileAttributesW" [
					path		[c-string!]
					return:		[integer!]
				]
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
				CreateDirectory: "CreateDirectoryW" [
					pathname	[c-string!]
					sa			[int-ptr!]
					return:		[logic!]
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
				FindFirstFile: "FindFirstFileW" [
					filename	[c-string!]
					filedata	[WIN32_FIND_DATA]
					return:		[integer!]
				]
				FindNextFile: "FindNextFileW" [
					file		[integer!]
					filedata	[WIN32_FIND_DATA]
					return:		[integer!]
				]
				FindClose: "FindClose" [
					file		[integer!]
					return:		[integer!]
				]
				GetFileSize: "GetFileSize" [
					file		[integer!]
					high-size	[integer!]
					return:		[integer!]
				]
				CloseHandle:	"CloseHandle" [
					obj			[integer!]
					return:		[logic!]
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
				lstrlen: "lstrlenW" [
					str			[byte-ptr!]
					return:		[integer!]
				]
				WideCharToMultiByte: "WideCharToMultiByte" [
					CodePage			[integer!]
					dwFlags				[integer!]
					lpWideCharStr		[c-string!]
					cchWideChar			[integer!]
					lpMultiByteStr		[byte-ptr!]
					cbMultiByte			[integer!]
					lpDefaultChar		[c-string!]
					lpUsedDefaultChar	[integer!]
					return:				[integer!]
				]
				GetLogicalDriveStrings: "GetLogicalDriveStringsW" [
					buf-len		[integer!]
					buffer		[byte-ptr!]
					return:		[integer!]
				]
			]
			"user32.dll" stdcall [
				SendMessage: "SendMessageW" [
					hWnd		[integer!]
					msg			[integer!]
					wParam		[integer!]
					lParam		[integer!]
					return: 	[integer!]
				]
				GetForegroundWindow: "GetForegroundWindow" [
					return:		[integer!]
				]
			]
		]
	][
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
				dirent!: alias struct! [				;@@ the same as MacOSX
					d_ino		[integer!]
					d_reclen	[byte!]
					_d_reclen_	[byte!]
					d_type		[byte!]
					d_namlen	[byte!]
					;d_name		[byte! [256]]
				]
			]
			OS = 'MacOSX [
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
					st_qspare_1 [integer!]
					st_qspare_2 [integer!]
				]
				;;-- #if __DARWIN_64_BIT_INO_T
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

		#either OS = 'MacOSX [
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
	]

	make-dir: func [
		path	[c-string!]
		return: [logic!]
	][
		#either OS = 'Windows [
			CreateDirectory path null
		][
			zero? mkdir path 511						;-- 0777
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
				either any [
					mode and RIO_APPEND <> 0
					mode and RIO_SEEK <> 0
				][
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
				either mode and RIO_APPEND <> 0 [
					modes: modes or O_APPEND
				][
					if mode and RIO_SEEK = 0 [modes: modes or O_TRUNC]
				]
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

	file-exists?: func [
		path	[c-string!]
		return: [logic!]
	][
		#either OS = 'Windows [
			-1 <> GetFileAttributesW path
		][
			-1 <> _access path 0						;-- F_OK: 0
		]
	]

	seek-file: func [
		file	[integer!]
		offset	[integer!]
	][
		#case [
			OS = 'Windows [
				SetFilePointer file offset null SET_FILE_BEGIN
			]
			OS = 'MacOSX [
				lseek file offset 0 0					;@@ offset is 64bit
			]
			true [
				lseek file offset 0						;-- SEEK_SET
			]
		]
	]

	read-data: func [
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

	write-data: func [
		file	[integer!]
		data	[byte-ptr!]
		size	[integer!]
		return:	[integer!]
		/local
			len [integer!]
			ret	[integer!]
	][
		#either OS = 'Windows [
			len: 0
			ret: WriteFile file data size :len null
			ret: either zero? ret [-1][1]
		][
			ret: _write file data size
		]
		ret
	]

	close-file: func [
		file	[integer!]
		return:	[logic!]
	][
		#either OS = 'Windows [
			CloseHandle file
		][
			zero? _close file
		]
	]

	lines-to-block: func [
		src		[byte-ptr!]								;-- UTF-8 input buffer
		size	[integer!]								;-- size of src in bytes (excluding terminal NUL)
		return: [red-block!]
		/local
			blk		[red-block!]
			start	[byte-ptr!]
			end		[byte-ptr!]
	][
		blk: block/push-only* 1
		if zero? size [return blk]

		start: src
		until [
			if src/1 = lf [
				end: src - 1
				if end/1 <> cr [end: src]
				string/load-in as-c-string start as-integer end - start blk UTF-8
				start: src + 1
			]
			size: size - 1
			src: src + 1
			zero? size
		]
		if start <> src [string/load-in as-c-string start as-integer src - start blk UTF-8]
		blk
	]

	read-file: func [
		filename [c-string!]
		part	 [integer!]
		offset	 [integer!]
		binary?	 [logic!]
		lines?	 [logic!]
		unicode? [logic!]
		return:	 [red-value!]
		/local
			buffer	[byte-ptr!]
			file	[integer!]
			size	[integer!]
			val		[red-value!]
			str		[red-string!]
			len		[integer!]
			type	[integer!]
	][
		unless unicode? [								;-- only command line args need to be checked
			if filename/1 = #"^"" [filename: filename + 1]	;-- FIX: issue #1234
			len: length? filename
			if filename/len = #"^"" [filename/len: null-byte]
		]
		file: open-file filename RIO_READ unicode?
		if file < 0 [return none-value]

		size: file-size? file

		if size <= 0 [
			close-file file
			val: stack/push*
			string/rs-make-at val 1
			type: either binary? [TYPE_BINARY][TYPE_STRING]
			set-type val type
			return val
		]

		if offset > 0 [
			seek-file file offset
			size: size - offset
		]
		if part > 0 [
			if part < size [size: part]
		]
		buffer: allocate size
		len: read-data file buffer size
		close-file file

		if negative? len [return none-value]

		val: as red-value! either binary? [
			binary/load buffer size
		][
			either lines? [lines-to-block buffer size][
				str: as red-string! stack/push*
				str/header: TYPE_STRING					;-- implicit reset of all header flags
				str/head: 0
				str/node: unicode/load-utf8-buffer as-c-string buffer size null null yes
				str/cache: null							;-- @@ cache small strings?
				str
			]
		]
		free buffer
		val
	]

	write-file: func [
		filename [c-string!]
		data	 [byte-ptr!]
		size	 [integer!]
		offset	 [integer!]
		binary?	 [logic!]
		append?  [logic!]
		lines?	 [logic!]
		unicode? [logic!]
		block?	 [logic!]
		return:	 [integer!]
		/local
			file	[integer!]
			n		[integer!]
			len		[integer!]
			mode	[integer!]
			ret		[integer!]
			blk		[red-block!]
			value	[red-value!]
			tail	[red-value!]
			buffer	[red-string!]
			lineend [c-string!]
			lf-sz	[integer!]
	][
		either null? filename [
			file: stdout
		][
			unless unicode? [							;-- only command line args need to be checked
				if filename/1 = #"^"" [filename: filename + 1]	;-- FIX: issue #1234
				len: length? filename
				if filename/len = #"^"" [filename/len: null-byte]
			]
			mode: RIO_WRITE
			if append? [mode: mode or RIO_APPEND]
			if offset >= 0 [mode: mode or RIO_SEEK]
			file: open-file filename mode unicode?
			if file < 0 [return file]
		]

		if offset > 0 [seek-file file offset]
		#either OS = 'Windows [
			lineend: "^M^/"
			lf-sz: 2
			if append? [SetFilePointer file 0 null SET_FILE_END]
		][
			lineend: "^/"
			lf-sz: 1
		]
		ret: 1
		either lines? [
			buffer: string/rs-make-at stack/push* 16
			blk: as red-block! data
			value: block/rs-head blk
			tail:  block/rs-tail blk
			while [value < tail][
				data: value-to-buffer value -1 :size binary? buffer
				write-data file data size
				ret: write-data file as byte-ptr! lineend lf-sz
				value: value + 1
			]
		][
			ret: write-data file data size
			if block? [ret: write-data file as byte-ptr! lineend lf-sz]
		]
		if filename <> null [close-file file]
		ret
	]

	dir?: func [
		filename [red-file!]
		return:  [logic!]
		/local
			len  [integer!]
			pos  [integer!]
			cp1  [integer!]
			cp2  [integer!]
			cp3  [integer!]
	][
		len: string/rs-length? as red-string! filename
		if zero? len [return false]
		pos: filename/head + len - 1
		cp1: string/rs-abs-at as red-string! filename pos
		cp2: either len > 1 [string/rs-abs-at as red-string! filename pos - 1][0]
		cp3: either len > 2 [string/rs-abs-at as red-string! filename pos - 2][0]

		any [
			cp1 = 47		;-- #"/"
			cp1 = 92 		;-- #"\"
			all [
				cp1 = 46	;-- #"."
				any [
					len = 1 cp2 = 47 cp2 = 92
					all [cp2 = 46 any [cp3 = 47 cp3 = 92 len = 2]]
				]
			]
		]
	]

	read-dir: func [
		filename	[red-file!]
		return:		[red-block!]
		/local
			info
			buf		[byte-ptr!]
			p		[byte-ptr!]
			name	[byte-ptr!]
			handle	[integer!]
			blk		[red-block!]
			str		[red-string!]
			len		[integer!]
			i		[integer!]
			cp		[byte!]
			s		[series!]
	][
		len: string/rs-length? as red-string! filename
		len: filename/head + len - 1
		cp: as byte! string/rs-abs-at as red-string! filename len
		if cp = #"." [string/append-char GET_BUFFER(filename) as-integer #"/"]

		#either OS = 'Windows [
			blk: block/push-only* 1
			if all [zero? len cp = #"/"][
				len: 1 + GetLogicalDriveStrings 0 null	;-- add NUL terminal
				buf: allocate len << 1
				GetLogicalDriveStrings len buf
				i: 0
				name: buf
				p: name
				len: len - 2
				until [
					if all [name/1 = #"^@" name/2 = #"^@"][
						name: name - 4
						name/1: #"/"
						name/3: #"^@"
						str: string/load-in as-c-string p lstrlen p blk UTF-16LE
						str/header: TYPE_FILE
						name: name + 4
						p: name + 2
					]
					name: name + 2
					i: i + 1
					i = len
				]
				free buf
				return blk
			]

			s: string/append-char GET_BUFFER(filename) as-integer #"*"

			info: as WIN32_FIND_DATA allocate WIN32_FIND_DATA_SIZE
			handle: FindFirstFile file/to-OS-path filename info
			len: either cp = #"." [1][0]
			s/tail: as cell! (as byte-ptr! s/tail) - (GET_UNIT(s) << len)

			if handle = -1 [fire [TO_ERROR(access cannot-open) filename]]

			name: (as byte-ptr! info) + 44
			until [
				unless any [							;-- skip over the . and .. dir case
					name = null
					all [
						(string/get-char name UCS-2) = as-integer #"."
						any [
							zero? string/get-char name + 2 UCS-2
							all [
								(string/get-char name + 2 UCS-2) = as-integer #"."
								zero? string/get-char name + 4 UCS-2
							]
						]
					]
				][
					str: string/load-in as-c-string name lstrlen name blk UTF-16LE
					if info/dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0 [
						string/append-char GET_BUFFER(str) as-integer #"/"
					]
					set-type as red-value! str TYPE_FILE
				]
				zero? FindNextFile handle info
			]
			FindClose handle
			free as byte-ptr! info
			blk
		][
			handle: opendir file/to-OS-path filename
			if zero? handle [fire [TO_ERROR(access cannot-open) filename]]
			blk: block/push-only* 1
			while [
				info: readdir handle
				info <> null
			][
				name: (as byte-ptr! info) + DIRENT_NAME_OFFSET
				unless any [							;-- skip over the . and .. dir case
					name = null
					all [
						name/1 = #"."
						any [
							name/2 = #"^@"
							all [name/2 = #"." name/3 = #"^@"]
						]
					]
				][
					#either OS = 'MacOSX [
						len: as-integer info/d_namlen
					][
						len: length? as-c-string name
					]
					str: string/load-in as-c-string name len blk UTF-8
					if info/d_type = DT_DIR [
						string/append-char GET_BUFFER(str) as-integer #"/"
					]
					set-type as red-value! str TYPE_FILE
				]
			]
			if cp = #"." [
				s: GET_BUFFER(filename)
				s/tail: as cell! (as byte-ptr! s/tail) - GET_UNIT(s)
			]
			closedir handle
			blk
		]
	]

	read: func [
		filename [red-file!]
		part	 [red-value!]
		seek	 [red-value!]
		binary?	 [logic!]
		lines?	 [logic!]
		return:	 [red-value!]
		/local
			data	[red-value!]
			int		[red-integer!]
			size	[integer!]
			offset	[integer!]
	][
		if dir? filename [
			return as red-value! read-dir filename
		]

		size: -1
		offset: -1
		if OPTION?(part) [
			int: as red-integer! part
			size: int/value
		]
		if OPTION?(seek) [
			int: as red-integer! seek
			offset: int/value
		]
		data: read-file file/to-OS-path filename size offset binary? lines? yes
		if TYPE_OF(data) = TYPE_NONE [
			fire [TO_ERROR(access cannot-open) filename]
		]
		data
	]

	value-to-buffer: func [
		data	[red-value!]
		part	[integer!]
		size	[int-ptr!]
		binary? [logic!]
		buffer	[red-string!]
		return: [byte-ptr!]
		/local
			type	[integer!]
			len		[integer!]
			str  	[red-string!]
			buf		[byte-ptr!]
	][
		type: TYPE_OF(data)
		case [
			type = TYPE_STRING [
				len: part
				str: as red-string! data
				buf: as byte-ptr! unicode/io-to-utf8 str :len not binary?
			]
			type = TYPE_BINARY [
				buf: binary/rs-head as red-binary! data
				len: binary/rs-length? as red-binary! data
				if all [part > 0 len > part][len: part]
			]
			true [
				len: 0
				actions/mold as red-value! data buffer no yes no null 0 0
				buf: value-to-buffer as red-value! buffer part :len binary? null
				string/rs-reset buffer
			]
		]
		size/value: len
		buf
	]

	write: func [
		filename [red-file!]
		data	 [red-value!]
		part	 [red-value!]
		seek	 [red-value!]
		binary?	 [logic!]
		append?  [logic!]
		lines?	 [logic!]
		return:  [integer!]
		/local
			len  	[integer!]
			buf  	[byte-ptr!]
			int  	[red-integer!]
			limit	[integer!]
			type	[integer!]
			offset	[integer!]
			buffer	[red-string!]
			name	[c-string!]
			block?	[logic!]
	][
		block?: no
		offset: -1
		limit: -1
		if OPTION?(part) [
			either TYPE_OF(part) = TYPE_INTEGER [
				int: as red-integer! part
				if negative? int/value [return -1]		;-- early exit if part <= 0
				limit: int/value
			][
				ERR_INVALID_REFINEMENT_ARG(refinements/_part part)
			]
		]
		if OPTION?(seek) [
			int: as red-integer! seek
			offset: int/value
		]

		either all [lines? TYPE_OF(data) = TYPE_BLOCK][
			buf: as byte-ptr! data
			block?: yes
		][
			if lines? [block?: yes lines?: no]
			len: 0
			buffer: string/rs-make-at stack/push* 16
			buf: value-to-buffer data limit :len binary? buffer
		]

		name: either null? filename [null][file/to-OS-path filename]
		type: write-file name buf len offset binary? append? lines? yes block?
		if negative? type [fire [TO_ERROR(access cannot-open) filename]]
		type
	]

	#switch OS [
		Windows [
			IID_IWinHttpRequest:			[06F29373h 4B545C5Ah F16E25B0h 0EBF8ABFh]
			IID_IStream:					[0000000Ch 00000000h 0000000Ch 46000000h]
			
			IWinHttpRequest: alias struct! [
				QueryInterface			[QueryInterface!]
				AddRef					[AddRef!]
				Release					[Release!]
				GetTypeInfoCount		[integer!]
				GetTypeInfo				[integer!]
				GetIDsOfNames			[integer!]
				Invoke					[integer!]
				SetProxy				[integer!]
				SetCredentials			[integer!]
				Open					[function! [this [this!] method [byte-ptr!] url [byte-ptr!] async1 [integer!] async2 [integer!] async3 [integer!] async4 [integer!] return: [integer!]]]
				SetRequestHeader		[function! [this [this!] header [byte-ptr!] value [byte-ptr!] return: [integer!]]]
				GetResponseHeader		[function! [this [this!] header [byte-ptr!] value [int-ptr!] return: [integer!]]]
				GetAllResponseHeaders	[function! [this [this!] header [int-ptr!] return: [integer!]]]
				Send					[function! [this [this!] body1 [integer!] body2 [integer!] body3 [integer!] body4 [integer!] return: [integer!]]]
				Status					[function! [this [this!] status [int-ptr!] return: [integer!]]]
				StatusText				[integer!]
				ResponseText			[function! [this [this!] body [int-ptr!] return: [integer!]]]
				ResponseBody			[function! [this [this!] body [tagVARIANT] return: [integer!]]]
				ResponseStream			[integer!]
				GetOption				[integer!]
				PutOption				[integer!]
				WaitForResponse			[integer!]
				Abort					[integer!]
				SetTimeouts				[integer!]
				SetClientCertificate	[integer!]
				SetAutoLogonPolicy		[integer!]
			]

			BSTR-length?: func [s [integer!] return: [integer!] /local len [int-ptr!]][
				len: as int-ptr! s - 4
				len/value >> 1
			]

			process-headers: func [
				headers	[c-string!]
				return: [red-hash!]
				/local
					len  [integer!]
					s	 [byte-ptr!]
					ss	 [byte-ptr!]
					p	 [byte-ptr!]
					mp	 [red-hash!]
					w	 [red-value!]
					res  [red-value!]
					val  [red-block!]
					new? [logic!]
			][
				len: WideCharToMultiByte CP_UTF8 0 headers -1 null 0 null 0
				s: allocate len
				ss: s
				WideCharToMultiByte CP_UTF8 0 headers -1 s len null 0

				mp: map/make-at stack/push* null 20
				p: s
				while [s/1 <> null-byte][
					if s/1 = #":" [						;-- key, maybe have duplicated key
						new?: no
						s/1: null-byte
						w: as red-value! word/push* symbol/make as-c-string p
						res: map/eval-path mp w null null no
						either TYPE_OF(res) = TYPE_NONE [
							new?: yes
						][
							if TYPE_OF(res) <> TYPE_BLOCK [
								val: block/push-only* 4
								block/rs-append val res
								copy-cell as cell! val res
								stack/pop 1
							]
							val: as red-block! res
						]

						p: s + 2
						until [
							s: s + 1
							if s/1 = #"^M" [			;-- value
								res: as red-value! string/load as-c-string p as-integer s - p UTF-8
								either new? [
									map/put mp w res no
								][
									block/rs-append val res
								]
								p: s + 2
							]
							s/1 = #"^M"
						]
						stack/pop 2
					]
					s: s + 1
				]
				free ss
				mp
			]

			request-http: func [
				method	[integer!]
				url		[red-url!]
				header	[red-block!]
				data	[red-value!]
				binary? [logic!]
				lines?	[logic!]
				info?	[logic!]
				return: [red-value!]
				/local
					action	[c-string!]
					hr 		[integer!]
					clsid	[tagGUID]
					async 	[tagVARIANT]
					body 	[tagVARIANT]
					IH		[interface!]
					http	[IWinHttpRequest]
					bstr-d	[byte-ptr!]
					bstr-m	[byte-ptr!]
					bstr-u	[byte-ptr!]
					buf-ptr [integer!]
					s		[series!]
					value	[red-value!]
					tail	[red-value!]
					l-bound [integer!]
					u-bound [integer!]
					array	[integer!]
					res		[red-value!]
					blk		[red-block!]
					len		[integer!]
			][
				res: as red-value! none-value
				len: -1
				buf-ptr: 0
				bstr-d: null
				clsid: declare tagGUID
				async: declare tagVARIANT
				body:  declare tagVARIANT
				VariantInit async
				VariantInit body
				async/data1: VT_BOOL
				async/data3: 0							;-- VARIANT_FALSE

				switch method [
					HTTP_GET [
						action: #u16 "GET"
						body/data1: VT_ERROR
					]
					HTTP_PUT [
						action: #u16 "PUT"
						--NOT_IMPLEMENTED--
					]
					HTTP_POST [
						action: #u16 "POST"
						either null? data [
							body/data1: VT_ERROR
						][
							body/data1: VT_BSTR
							bstr-d: SysAllocString unicode/to-utf16-len as red-string! data :len no
							body/data3: as-integer bstr-d
						]
					]
					default [--NOT_IMPLEMENTED--]
				]

				IH: declare interface!
				http: null

				hr: CLSIDFromProgID #u16 "WinHttp.WinHttpRequest.5.1" clsid

				if hr >= 0 [
					hr: CoCreateInstance as int-ptr! clsid 0 CLSCTX_INPROC_SERVER IID_IWinHttpRequest IH
				]

				if hr >= 0 [
					http: as IWinHttpRequest IH/ptr/vtbl
					bstr-m: SysAllocString action
					bstr-u: SysAllocString unicode/to-utf16 as red-string! url
					hr: http/Open IH/ptr bstr-m bstr-u async/data1 async/data2 async/data3 async/data4
					SysFreeString bstr-m
					SysFreeString bstr-u
				]

				either hr >= 0 [
					either header <> null [
						s: GET_BUFFER(header)
						value: s/offset + header/head
						tail:  s/tail

						while [value < tail][
							bstr-u: SysAllocString unicode/to-utf16 word/as-string as red-word! value
							value: value + 1
							bstr-m: SysAllocString unicode/to-utf16 as red-string! value
							value: value + 1
							http/SetRequestHeader IH/ptr bstr-u bstr-m
							SysFreeString bstr-m
							SysFreeString bstr-u
						]
					][
						bstr-u: SysAllocString #u16 "Content-Type"
						bstr-m: SysAllocString #u16 "application/x-www-form-urlencoded"
						http/SetRequestHeader IH/ptr bstr-u bstr-m
						SysFreeString bstr-m
						SysFreeString bstr-u
					]
					hr: http/Send IH/ptr body/data1 body/data2 body/data3 body/data4
				][
					return res
				]

				if hr >= 0 [
					if info? [
						blk: block/push-only* 3
						hr: http/Status IH/ptr :len
						if hr >= 0 [
							integer/make-in blk len
							hr: http/GetAllResponseHeaders IH/ptr :buf-ptr
						]
						if hr >= 0 [
							block/rs-append blk as red-value! process-headers as c-string! buf-ptr
							SysFreeString as byte-ptr! buf-ptr
						]
					]
					if all [method = HTTP_POST bstr-d <> null][SysFreeString bstr-d]
					hr: http/ResponseBody IH/ptr body
				]

				if hr >= 0 [				
					array: body/data3
					if all [
						VT_ARRAY or VT_UI1 = body/data1
						1 = SafeArrayGetDim array
					][
						l-bound: 0
						u-bound: 0
						SafeArrayGetLBound array 1 :l-bound
						SafeArrayGetUBound array 1 :u-bound
						SafeArrayAccessData array :buf-ptr
						len: u-bound - l-bound + 1
						res: as red-value! either binary? [
							binary/load as byte-ptr! buf-ptr len
						][
							either lines? [
								lines-to-block as byte-ptr! buf-ptr len
							][
								string/load as c-string! buf-ptr len UTF-8
							]
						]
						SafeArrayUnaccessData array
					]
					if body/data1 and VT_ARRAY > 0 [SafeArrayDestroy array]
					if info? [
						block/rs-append blk res
						res: as red-value! blk
					]
				]

				if http <> null [http/Release IH/ptr]
				res
			]
		]
		MacOSX [
			#either OS-version > 10.7 [
				#define CFNetwork.lib "/System/Library/Frameworks/CFNetwork.framework/CFNetwork"
			][
				#define CFNetwork.lib "/System/Library/Frameworks/CoreServices.framework/CoreServices" 
			]
			#import [
				LIBC-file cdecl [
					objc_getClass: "objc_getClass" [
						class		[c-string!]
						return:		[integer!]
					]
					sel_getUid: "sel_getUid" [
						name		[c-string!]
						return:		[integer!]
					]
					objc_msgSend: "objc_msgSend" [[variadic] return: [integer!]]
				]
				CFNetwork.lib cdecl [
					__CFStringMakeConstantString: "__CFStringMakeConstantString" [
						cStr		[c-string!]
						return:		[integer!]
					]
					CFURLCreateWithString: "CFURLCreateWithString" [
						allocator	[integer!]
						url			[integer!]
						baseUrl		[integer!]
						return:		[integer!]
					]
					CFHTTPMessageCreateRequest: "CFHTTPMessageCreateRequest" [
						allocator	[integer!]
						method		[integer!]
						url			[integer!]
						version		[integer!]
						return:		[integer!]
					]
					CFHTTPMessageGetResponseStatusCode: "CFHTTPMessageGetResponseStatusCode" [
						response	[integer!]
						return:		[integer!]
					]
					CFHTTPMessageCopyAllHeaderFields: "CFHTTPMessageCopyAllHeaderFields" [
						response	[integer!]
						return:		[integer!]
					]
					CFHTTPMessageSetBody: "CFHTTPMessageSetBody" [
						msg			[integer!]
						data		[integer!]
					]
					CFHTTPMessageSetHeaderFieldValue: "CFHTTPMessageSetHeaderFieldValue" [
						msg			[integer!]
						header		[integer!]
						value		[integer!]
					]
					CFReadStreamCreateForHTTPRequest: "CFReadStreamCreateForHTTPRequest" [
						allocator	[integer!]
						request		[integer!]
						return:		[integer!]
					]
				]
				"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" cdecl [
					kCFBooleanTrue: "kCFBooleanTrue" [integer!]
					kCFStreamPropertyHTTPShouldAutoredirect: "kCFStreamPropertyHTTPShouldAutoredirect" [integer!]
					kCFStreamPropertyHTTPResponseHeader: "kCFStreamPropertyHTTPResponseHeader" [integer!]
					CFReadStreamOpen: "CFReadStreamOpen" [
						stream		[integer!]
						return:		[integer!]
					]
					CFReadStreamRead: "CFReadStreamRead" [
						stream		[integer!]
						buffer		[byte-ptr!]
						size		[integer!]
						return:		[integer!]
					]
					CFReadStreamClose: "CFReadStreamClose" [
						stream		[integer!]
					]
					CFDataCreate: "CFDataCreate" [
						allocator	[integer!]
						data		[byte-ptr!]
						length		[integer!]
						return:		[integer!]
					]
					CFStringCreateWithCString: "CFStringCreateWithCString" [
						allocator	[integer!]
						cStr		[c-string!]
						encoding	[integer!]
						return:		[integer!]
					]
					CFURLCreateStringByAddingPercentEscapes: "CFURLCreateStringByAddingPercentEscapes" [
						allocator	[integer!]
						cf-str		[integer!]
						unescaped	[integer!]
						escaped		[integer!]
						encoding	[integer!]
						return:		[integer!]
					]
					CFURLCreateWithFileSystemPath: "CFURLCreateWithFileSystemPath" [
						allocator	[integer!]
						filePath	[integer!]
						pathStyle	[integer!]
						isDir		[logic!]
						return:		[integer!]
					]
					CFReadStreamSetProperty: "CFReadStreamSetProperty" [
						stream		[integer!]
						name		[integer!]
						value		[integer!]
						return:		[integer!]
					]
					CFReadStreamCopyProperty: "CFReadStreamCopyProperty" [
						stream		[integer!]
						property	[integer!]
						return:		[integer!]
					]
					CFDictionaryGetCount: "CFDictionaryGetCount" [
						dict		[integer!]
						return:		[integer!]
					]
					CFDictionaryGetKeysAndValues: "CFDictionaryGetKeysAndValues" [
						dict		[integer!]
						keys		[int-ptr!]
						values		[int-ptr!]
					]
					CFStringGetCStringPtr: "CFStringGetCStringPtr" [
						str			[integer!]
						encoding	[integer!]
						return:		[c-string!]
					]
					CFRelease: "CFRelease" [
						cf			[integer!]
					]
				]
			]

			#define kCFStringEncodingUTF8		08000100h
			#define kCFStringEncodingMacRoman	0

			#define CFSTR(cStr)		[__CFStringMakeConstantString cStr]
			#define CFString(cStr)	[CFStringCreateWithCString 0 cStr kCFStringEncodingUTF8]

			to-NSString: func [str [red-string!] return: [integer!] /local len][
				len: -1
				objc_msgSend [
					objc_getClass "NSString"
					sel_getUid "stringWithUTF8String:"
					unicode/to-utf8 str :len
				]
			]

			to-NSURL: func [
				str		[red-string!]
				file?	[logic!]						;-- local file path or url?
				return: [integer!]
				/local
					nsstr	[integer!]
					url		[integer!]
					path	[integer!]
			][
				nsstr: to-NSString str
				either file? [
					path: objc_msgSend [nsstr sel_getUid "stringByExpandingTildeInPath"]
					;@@ release path ? Does it already autoreleased?
					path: CFURLCreateWithFileSystemPath 0 path 0 false
				][
					url: CFURLCreateStringByAddingPercentEscapes 0 nsstr 0 0 kCFStringEncodingUTF8
					path: CFURLCreateWithString 0 url 0
					CFRelease url
				]
				objc_msgSend [nsstr sel_getUid "release"]
				path
			]

			split-set-cookie: func [
				s		[c-string!]
				return: [red-value!]
				/local
					blk		[red-block!]
					p		[c-string!]
					p1		[c-string!]
					p2		[c-string!]
			][
				blk: block/push-only* 2
				until [
					p: s
					until [s: s + 1 s/1 = #";"]			;-- skip name and value 
					s: s + 2
					p1: strstr s "expires="				;-- only `expires` contains #"," among all the cookie attributes
					p2: strchr s #","
					either p2 = null [
						p2: strchr s null-byte
						s: p2
					][
						s: p1 + 20
						if s > p2 [p2: strchr s #","]
						s: p2 + 2
					]
					string/load-in p as-integer p2 - p blk UTF-8
					s/1 = null-byte
				]
				either 1 = block/rs-length? blk [block/rs-head blk][as red-value! blk]
			]

			dict-to-map: func [
				dict	[integer!]
				return: [red-hash!]
				/local
					i		[integer!]
					keys	[int-ptr!]
					vals	[int-ptr!]
					sz		[integer!]
					mp		[red-hash!]
					k		[c-string!]
					v		[c-string!]
					w		[red-value!]
					res		[red-value!]
					sel_str [integer!]
			][
				sz: CFDictionaryGetCount dict
				mp: map/make-at stack/push* null sz << 1
				keys: as int-ptr! allocate sz << 2
				vals: as int-ptr! allocate sz << 2
				CFDictionaryGetKeysAndValues dict keys vals
				sel_str: sel_getUid "UTF8String"

				i: 0
				while [i < sz][
					i: i + 1
					k: CFStringGetCStringPtr keys/i kCFStringEncodingMacRoman
					v: CFStringGetCStringPtr vals/i kCFStringEncodingMacRoman
					if k = null [k: as c-string! objc_msgSend [keys/i sel_str]]	;-- fallback when CFStringGetCStringPtr failed
					if v = null [v: as c-string! objc_msgSend [vals/i sel_str]]

					w: as red-value! word/push* symbol/make k
					res: either zero? strncmp k "Set-Cookie" 10 [
						split-set-cookie v
					][
						as red-value! string/load v length? v UTF-8
					]

					map/put mp w res no
					stack/pop 2
				]
				free as byte-ptr! keys
				free as byte-ptr! vals
				mp
			]

			request-http: func [
				method	[integer!]
				url		[red-url!]
				header	[red-block!]
				data	[red-value!]
				binary? [logic!]
				lines?	[logic!]
				info?	[logic!]
				return: [red-value!]
				/local
					len			[integer!]
					action		[c-string!]
					raw-url		[integer!]
					escaped-url [integer!]
					cf-url		[integer!]
					req			[integer!]
					body		[integer!]
					buf			[byte-ptr!]
					datalen		[integer!]
					cf-key		[integer!]
					cf-val		[integer!]
					value		[red-value!]
					tail		[red-value!]
					s			[series!]
					bin			[red-binary!]
					stream		[integer!]
					response	[integer!]
					blk			[red-block!]
			][
				switch method [
					HTTP_GET  [action: "GET"]
					HTTP_PUT  [action: "PUT"]
					HTTP_POST [action: "POST"]
					default [--NOT_IMPLEMENTED--]
				]

				body: 0
				len: -1
				raw-url: CFString((unicode/to-utf8 as red-string! url :len))
				escaped-url: CFURLCreateStringByAddingPercentEscapes 0 raw-url 0 0 kCFStringEncodingUTF8
				cf-url: CFURLCreateWithString 0 escaped-url 0

				req: CFHTTPMessageCreateRequest 0 CFSTR(action) cf-url CFSTR("HTTP/1.1")
				CFRelease raw-url
				CFRelease escaped-url

				if zero? req [return as red-value! none-value]

				if all [data <> null any [method = HTTP_POST method = HTTP_PUT]][
					datalen: -1
					either TYPE_OF(data) = TYPE_STRING [
						buf: as byte-ptr! unicode/to-utf8 as red-string! data :datalen
					][
						buf: binary/rs-head as red-binary! data
						datalen: binary/rs-length? as red-binary! data
					]
					body: CFDataCreate 0 buf datalen
					CFHTTPMessageSetBody req body
				]

				stream: CFString("application/x-www-form-urlencoded; charset=utf-8")
				CFHTTPMessageSetHeaderFieldValue req CFSTR("Content-Type") stream
				if header <> null [
					s: GET_BUFFER(header)
					value: s/offset + header/head
					tail:  s/tail

					while [value < tail][
						len: -1
						cf-key: CFString((unicode/to-utf8 word/as-string as red-word! value :len))
						value: value + 1
						len: -1
						cf-val: CFString((unicode/to-utf8 as red-string! value :len))
						value: value + 1
						CFHTTPMessageSetHeaderFieldValue req cf-key cf-val
						CFRelease cf-val
						CFRelease cf-key
					]
				]
				CFRelease stream

				stream: CFReadStreamCreateForHTTPRequest 0 req
				if zero? stream [return none-value]

				CFReadStreamSetProperty stream kCFStreamPropertyHTTPShouldAutoredirect kCFBooleanTrue
				CFReadStreamOpen stream
				buf: allocate 4096
				bin: binary/make-at stack/push* 4096
				until [
					len: CFReadStreamRead stream buf 4096
					either len > 0 [
						binary/rs-append bin buf len
					][
						if negative? len [
							free buf
							CFReadStreamClose stream
							unless zero? body [CFRelease body]
							CFRelease cf-url
							CFRelease req
							CFRelease stream
							return none-value
						]
					]
					len <= 0
				]

				free buf

				if info? [
					blk: block/push-only* 3
					response: CFReadStreamCopyProperty stream kCFStreamPropertyHTTPResponseHeader
					len: CFHTTPMessageGetResponseStatusCode response
					integer/make-in blk len
					len: CFHTTPMessageCopyAllHeaderFields response
					block/rs-append blk as red-value! dict-to-map len
					CFRelease response
					CFRelease len
				]
				
				CFReadStreamClose stream
				unless zero? body [CFRelease body]
				CFRelease cf-url
				CFRelease req
				CFRelease stream

				unless binary? [
					buf: binary/rs-head bin
					len: binary/rs-length? bin
					either lines? [
						bin: as red-binary! lines-to-block buf len
					][
						bin/header: TYPE_STRING
						bin/node: unicode/load-utf8 as c-string! buf len
					]
				]
				if info? [
					block/rs-append blk as red-value! bin
					bin: as red-binary! blk
				]
				as red-value! bin
			]
		]
		#default [
	
			#define CURLOPT_URL				10002
			#define CURLOPT_HTTPGET			80
			#define CURLOPT_POSTFIELDSIZE	60
			#define CURLOPT_NOPROGRESS		43
			#define CURLOPT_FOLLOWLOCATION	52
			#define CURLOPT_POSTFIELDS		10015
			#define CURLOPT_WRITEDATA		10001
			#define CURLOPT_HEADERDATA		10029
			#define CURLOPT_HTTPHEADER		10023
			#define CURLOPT_WRITEFUNCTION	20011
			#define CURLOPT_HEADERFUNCTION	20079

			#define CURLE_OK				0
			#define CURL_GLOBAL_ALL 		3

			#define CURLINFO_RESPONSE_CODE	00200002h

			;-- use libcurl, may need to install it on some distros
			#import [
				"libcurl.so.4" cdecl [
					curl_global_init: "curl_global_init" [
						flags	[integer!]
						return: [integer!]
					]
					curl_easy_init: "curl_easy_init" [
						return: [integer!]
					]
					curl_easy_setopt: "curl_easy_setopt" [
						curl	[integer!]
						option	[integer!]
						param	[integer!]
						return: [integer!]
					]
					curl_easy_getinfo: "curl_easy_getinfo" [
						curl	[integer!]
						option	[integer!]
						param	[int-ptr!]
						return: [integer!]
					]
					curl_slist_append: "curl_slist_append" [
						slist	[integer!]
						pragma	[c-string!]
						return:	[integer!]
					]
					curl_slist_free_all: "curl_slist_free_all" [
						slist	[integer!]
					]
					curl_easy_perform: "curl_easy_perform" [
						handle	[integer!]
						return: [integer!]
					]
					curl_easy_strerror: "curl_easy_strerror" [
						error	[integer!]
						return: [c-string!]
					]
					curl_easy_cleanup: "curl_easy_cleanup" [
						handle	[integer!]
					]
					curl_global_cleanup: "curl_global_cleanup" []
				]
			]

			get-http-response: func [
				[cdecl]
				data	 [byte-ptr!]
				size	 [integer!]
				nmemb	 [integer!]
				userdata [byte-ptr!]
				return:	 [integer!]
				/local
					bin  [red-binary!]
					len  [integer!]
			][
				bin: as red-binary! userdata
				len: size * nmemb
				binary/rs-append bin data len
				len
			]

			get-http-header: func [
				[cdecl]
				s		 [byte-ptr!]
				size	 [integer!]
				nmemb	 [integer!]
				userdata [byte-ptr!]
				return:	 [integer!]
				/local
					p	 [byte-ptr!]
					mp	 [red-hash!]
					len  [integer!]
					w	 [red-value!]
					res  [red-value!]
					val  [red-block!]
					new? [logic!]
			][
				mp: as red-hash! userdata
				len: size * nmemb
				if zero? strncmp as c-string! s "HTTP/1.1" 8 [return len]

				p: s
				while [s/1 <> null-byte][
					if s/1 = #":" [						;-- key, maybe have duplicated key
						new?: no
						s/1: null-byte
						w: as red-value! word/push* symbol/make as-c-string p
						res: map/eval-path mp w null null no
						either TYPE_OF(res) = TYPE_NONE [
							new?: yes
						][
							if TYPE_OF(res) <> TYPE_BLOCK [
								val: block/push-only* 4
								block/rs-append val res
								copy-cell as cell! val res
								stack/pop 1
							]
							val: as red-block! res
						]

						p: s + 2
						until [
							s: s + 1
							if s/1 = #"^M" [			;-- value
								res: as red-value! string/load as-c-string p as-integer s - p UTF-8
								either new? [
									map/put mp w res no
								][
									block/rs-append val res
								]
								p: s + 2
							]
							s/1 = #"^M"
						]
						stack/pop 2
					]
					s: s + 1
				]
				len				
			]

			request-http: func [
				method	[integer!]
				url		[red-url!]
				header	[red-block!]
				data	[red-value!]
				binary? [logic!]
				lines?	[logic!]
				info?	[logic!]
				return: [red-value!]
				/local
					len		[integer!]
					curl	[integer!]
					res		[integer!]
					buf		[byte-ptr!]
					action	[c-string!]
					bin		[red-binary!]
					value	[red-value!]
					tail	[red-value!]
					s		[series!]
					str		[red-string!]
					slist	[integer!]
					mp		[red-hash!]
					blk		[red-block!]
			][
				switch method [
					HTTP_GET  [action: "GET"]
					;HTTP_PUT  [action: "PUT"]
					HTTP_POST [action: "POST"]
					default [--NOT_IMPLEMENTED--]
				]

				curl_global_init CURL_GLOBAL_ALL
				curl: curl_easy_init

				if zero? curl [
					probe "ERROR: libcurl init failed."
					curl_global_cleanup
					return none-value
				]

				slist: 0
				len: -1
				bin: binary/make-at stack/push* 4096
				
				curl_easy_setopt curl CURLOPT_URL as-integer unicode/to-utf8 as red-string! url :len
				curl_easy_setopt curl CURLOPT_NOPROGRESS 1
				curl_easy_setopt curl CURLOPT_FOLLOWLOCATION 1
				
				curl_easy_setopt curl CURLOPT_WRITEFUNCTION as-integer :get-http-response
				curl_easy_setopt curl CURLOPT_WRITEDATA as-integer bin

				if info? [
					blk: block/push-only* 3
					mp: map/make-at stack/push* null 20
					curl_easy_setopt curl CURLOPT_HEADERDATA as-integer mp
					curl_easy_setopt curl CURLOPT_HEADERFUNCTION as-integer :get-http-header
				]

				if header <> null [
					s: GET_BUFFER(header)
					value: s/offset + header/head
					tail:  s/tail

					while [value < tail][
						str: word/as-string as red-word! value	;-- cast word! to string!
						_series/copy as red-series! str as red-series! str null yes null
						string/append-char GET_BUFFER(str) as-integer #":"
						string/append-char GET_BUFFER(str) as-integer #" "
						value: value + 1
						string/concatenate str as red-string! value -1 0 yes no
						len: -1
						slist: curl_slist_append slist unicode/to-utf8 str :len
						value: value + 1
					]
					curl_easy_setopt curl CURLOPT_HTTPHEADER slist
				]

				case [
					method = HTTP_GET [
						curl_easy_setopt curl CURLOPT_HTTPGET 1
					]
					method = HTTP_POST [
						if data <> null [
							len: -1
							either TYPE_OF(data) = TYPE_STRING [
								buf: as byte-ptr! unicode/to-utf8 as red-string! data :len
							][
								buf: binary/rs-head as red-binary! data
								len: binary/rs-length? as red-binary! data
							]
							curl_easy_setopt curl CURLOPT_POSTFIELDSIZE len
							curl_easy_setopt curl CURLOPT_POSTFIELDS as-integer buf
						]
					]
				]
				res: curl_easy_perform curl

				if info? [
					curl_easy_getinfo curl CURLINFO_RESPONSE_CODE :len
					integer/make-in blk len
				]

				unless zero? slist [curl_slist_free_all slist]
				curl_easy_cleanup curl
				curl_global_cleanup

				if res <> CURLE_OK [
					print-line ["ERROR: " curl_easy_strerror res]
					return none-value
				]

				unless binary? [
					buf: binary/rs-head bin
					len: binary/rs-length? bin
					either lines? [
						bin: as red-binary! lines-to-block buf len
					][
						bin/header: TYPE_STRING
						bin/node: unicode/load-utf8 as c-string! buf len
					]
				]

				if info? [
					block/rs-append blk as red-value! mp
					block/rs-append blk as red-value! bin
					bin: as red-binary! blk
				]
				as red-value! bin
			]
		]
	]
]
