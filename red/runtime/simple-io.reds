Red/System [
	Title:	"Simple file IO functions (temporary)"
	Author: "Nenad Rakocevic"
	File: 	%simple-io.reds
	Tabs: 	4
	Rights: "Copyright (C) 2012-2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

simple-io: context [

	#either OS = 'Windows [
	
		#define GENERIC_READ 			80000000h
		#define FILE_SHARE_READ			00000001h
		#define OPEN_EXISTING			00000003h
		#define FILE_ATTRIBUTE_NORMAL	00000080h

		#import [
			"kernel32.dll" stdcall [
				CreateFile:	"CreateFileA" [
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
				GetFileSize: "GetFileSize" [
					file		[integer!]
					high-size	[integer!]
					return:		[integer!]
				]
				CloseHandle:	"CloseHandle" [
					obj			[integer!]
					return:		[integer!]
				]
			]
		]
	][
		#define O_RDONLY	0
		
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
				_close:	"close" [
					file		[integer!]
					return:		[integer!]
				]
			]
		]
		
		#either OS = 'MacOSX [
			stat!: alias struct! [
				st_dev		[integer!]
				st_ino		[integer!]
				st_mode		[integer!]
				st_nlink	[integer!]
				st_uid		[integer!]
				st_gid		[integer!]
				st_rdev		[integer!]
				st_atime	[integer!]					;-- struct timespec
				st_mtime	[integer!]					;-- struct timespec
				st_ctime	[integer!]					;-- struct timespec
				st_size		[integer!]
				st_blocks	[integer!]
				st_blksize	[integer!]
				st_flags	[integer!]
				st_gen		[integer!]
			]
			#import [
				LIBC-file cdecl [
					;--- https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/10.6/man2/stat.2.html?useVersion=10.6
					_stat:	"stat" [
						filename	[c-string!]
						restrict	[stat!]
						return:		[integer!]
					]
				]
			]
		][
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
			#import [
				LIBC-file cdecl [
					;--- http://refspecs.linuxbase.org/LSB_3.0.0/LSB-Core-generic/LSB-Core-generic/baselib-xstat-1.html
					_stat:	"__xstat" [
						version		[integer!]
						filename	[c-string!]
						restrict	[stat!]
						return:		[integer!]
					]
				]
			]
		]
	]
	
	open-file: func [
		filename [c-string!]
		return:	 [integer!]
		/local
			file [integer!]
	][
		#either OS = 'Windows [
			file: CreateFile 
				filename
				GENERIC_READ
				FILE_SHARE_READ
				null
				OPEN_EXISTING
				FILE_ATTRIBUTE_NORMAL
				null
		][
			file: _open filename O_RDONLY 0
		]
		if file = -1 [
			print-line "*** Error: File not found"
			quit -1
		]
		file
	]
	
	file-size?: func [
		file	 [integer!]
		filename [c-string!]
		return:	 [integer!]
		/local s
	][
		#switch OS [
			Windows [
				GetFileSize file null
			]
			MacOSX [
				s: declare stat!
				_stat filename s
				s/st_size
			]
			#default [
				s: declare stat!
				_stat 3 filename s
				s/st_size
			]
		]
	]
	
	read-file: func [
		file	[integer!]
		buffer	[byte-ptr!]
		size	[integer!]
		return:	[integer!]
		/local
			read-sz [integer!]
			res		[integer!]
			error?	[logic!]
	][
		#either OS = 'Windows [
			read-sz: -1
			res: ReadFile file buffer size :read-sz null
			error?: any [zero? res read-sz <> size]
		][
			res: _read file buffer size
			error?: res <= 0
		]
		if error? [
			print-line "*** Error: cannot read file"
			quit -3
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
	
	read-txt: func [
		filename [c-string!]
		return:	 [red-string!]
		/local
			buffer	[byte-ptr!]
			file	[integer!]
			size	[integer!]
			str		[red-string!]
	][
		file: open-file filename
		size: file-size? file filename
		if size <= 0 [
			print-line "*** Error: empty file"
			quit -2
		]
		
		buffer: allocate size + 1						;-- account for terminal NUL
		read-file file buffer size
		close-file file
		
		size: size + 1
		buffer/size: null-byte
		str: string/load as-c-string buffer size
		free buffer
		str
	]
]