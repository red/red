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
		#import [
			LIBC-file cdecl [
				_open:	"open" [
					filename	[c-string!]
					flags		[integer!]
					mode		[integer!]
					return:		[integer!]
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
			
		]
		if file = -1 [
			print-line "*** Error: File not found"
			quit -1
		]
		file
	]
	
	file-size?: func [
		file	[integer!]
		return:	[integer!]
	][
		#either OS = 'Windows [
			GetFileSize file null
		][
		
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
	][
		#either OS = 'Windows [
			read-sz: -1
			res: ReadFile file buffer size :read-sz null
			
			if any [zero? res read-sz <> size][
				print-line "*** Error: cannot read file"
				quit -3
			]
			res
		][

		]
	]
	
	close-file: func [
		file	[integer!]
		return:	[integer!]
	][
		#either OS = 'Windows [
			CloseHandle file
		][

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
		size: file-size? file
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