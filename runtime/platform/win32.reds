Red/System [
	Title:   "Red runtime win32 API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %win32.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#include %COM.reds

#define VA_COMMIT_RESERVE	3000h						;-- MEM_COMMIT | MEM_RESERVE
#define VA_PAGE_RW			04h							;-- PAGE_READWRITE
#define VA_PAGE_RWX			40h							;-- PAGE_EXECUTE_READWRITE

#define _O_TEXT        	 	4000h  						;-- file mode is text (translated)
#define _O_BINARY       	8000h  						;-- file mode is binary (untranslated)
#define _O_WTEXT        	00010000h 					;-- file mode is UTF16 (translated)
#define _O_U16TEXT      	00020000h 					;-- file mode is UTF16 no BOM (translated)
#define _O_U8TEXT       	00040000h 					;-- file mode is UTF8  no BOM (translated)

#define GENERIC_WRITE		40000000h
#define GENERIC_READ 		80000000h
#define FILE_SHARE_READ		00000001h
#define FILE_SHARE_WRITE	00000002h
#define OPEN_EXISTING		00000003h

#define FORMAT_MESSAGE_ALLOCATE_BUFFER    00000100h
#define FORMAT_MESSAGE_IGNORE_INSERTS     00000200h
#define FORMAT_MESSAGE_FROM_STRING        00000400h
#define FORMAT_MESSAGE_FROM_HMODULE       00000800h
#define FORMAT_MESSAGE_FROM_SYSTEM        00001000h

#define WEOF				FFFFh

platform: context [

	#enum file-descriptors! [
		fd-stdout: 1									;@@ hardcoded, safe?
		fd-stderr: 2									;@@ hardcoded, safe?
	]

	GdiplusStartupInput!: alias struct! [
		GdiplusVersion				[integer!]
		DebugEventCallback			[integer!]
		SuppressBackgroundThread	[integer!]
		SuppressExternalCodecs		[integer!]
	]

	gdiplus-token: 0

	page-size: 4096
	confd: -2

	buffer: allocate  1024
	pbuffer: buffer ;this stores buffer's head position

	#import [
		LIBC-file cdecl [
			;putwchar: "putwchar" [
			;	wchar		[integer!]					;-- wchar is 16-bit on Windows
			;]
			wprintf: "wprintf" [
				[variadic]
				return: 	[integer!]
			]
			fflush: "fflush" [
				fd			[integer!]
				return:		[integer!]
			]
			_setmode: "_setmode" [
				handle		[integer!]
				mode		[integer!]
				return:		[integer!]
			]
			_get_osfhandle: "_get_osfhandle" [
				fd			[integer!]
				return:		[integer!]
			]
			;_open_osfhandle: "_open_osfhandle" [
			;	handle		[integer!]
			;	flags		[integer!]
			;	return:		[integer!]
			;]
		]
		"kernel32.dll" stdcall [
			VirtualAlloc: "VirtualAlloc" [
				address		[byte-ptr!]
				size		[integer!]
				type		[integer!]
				protection	[integer!]
				return:		[int-ptr!]
			]
			VirtualFree: "VirtualFree" [
				address 	[int-ptr!]
				size		[integer!]
				return:		[integer!]
			]
			WriteConsole: 	 "WriteConsoleW" [
				consoleOutput	[integer!]
				buffer			[byte-ptr!]
				charsToWrite	[integer!]
				numberOfChars	[int-ptr!]
				_reserved		[int-ptr!]
				return:			[integer!]
			]
			WriteFile: "WriteFile" [
				handle			[integer!]
				buffer			[c-string!]
				len				[integer!]
				written			[int-ptr!]
				overlapped		[integer!]
				return:			[integer!]
			]
			GetConsoleMode:	"GetConsoleMode" [
				handle			[integer!]
				mode			[int-ptr!]
				return:			[integer!]
			]
			GetCurrentDirectory: "GetCurrentDirectoryW" [
				buf-len			[integer!]
				buffer			[byte-ptr!]
				return:			[integer!]
			]
			FormatMessage: "FormatMessageW" [
				dwFlags			[integer!]
				lpSource		[byte-ptr!]
				dwMessageId		[integer!]
				dwLanguageId	[integer!]
				lpBuffer		[int-ptr!]
				nSize			[integer!]
				Argument		[integer!]
				return:			[integer!]
			]
			LocalFree: "LocalFree" [
				hMem			[integer!]
				return:			[integer!]
			]
		]
		"gdiplus.dll" stdcall [
			GdiplusStartup: "GdiplusStartup" [
				token		[int-ptr!]
				input		[integer!]
				output		[integer!]
				return:		[integer!]
			]
			GdiplusShutdown: "GdiplusShutdown" [
				token		[integer!]
			]
		]
	]

	error-msg: func [
		error	[integer!]
		/local
			len  [integer!]
			pbuf [integer!]
	][
		pbuf: 0
		len: FormatMessage
			FORMAT_MESSAGE_ALLOCATE_BUFFER or
			FORMAT_MESSAGE_FROM_SYSTEM or
			FORMAT_MESSAGE_IGNORE_INSERTS
			null
			error
			0400h			;-- user default language
			:pbuf
			0
			0
		if positive? len [
			WriteConsole stdout as byte-ptr! pbuf len :len null
			LocalFree pbuf
		]
	]

	;-------------------------------------------
	;-- Allocate paged virtual memory region from OS
	;-------------------------------------------
	allocate-virtual: func [
		size 	[integer!]								;-- allocated size in bytes (page size multiple)
		exec? 	[logic!]								;-- TRUE => executable region
		return: [int-ptr!]								;-- allocated memory region pointer
		/local ptr prot
	][
		prot: either exec? [VA_PAGE_RWX][VA_PAGE_RW]

		ptr: VirtualAlloc
			null
			size
			VA_COMMIT_RESERVE
			prot

		if ptr = null [
			raise-error RED_ERR_VMEM_OUT_OF_MEMORY 0
		]
		ptr
	]

	;-------------------------------------------
	;-- Free paged virtual memory region from OS
	;-------------------------------------------
	free-virtual: func [
		ptr [int-ptr!]									;-- address of memory region to release
	][
		if negative? VirtualFree ptr ptr/value [
			raise-error RED_ERR_VMEM_RELEASE_FAILED as-integer ptr
		]
	]

	;-------------------------------------------
	;-- Initialize console ouput handle
	;-------------------------------------------
	init-console-out: func [][
		confd: simple-io/CreateFileA
					"CONOUT$"
					GENERIC_WRITE
					FILE_SHARE_READ or FILE_SHARE_WRITE
					null
					OPEN_EXISTING
					0
					null
	]

	;-------------------------------------------
	;-- putwchar use windows api internal
	;-------------------------------------------
	putwchar: func [
		wchar	[integer!]								;-- wchar is 16-bit on Windows
		return:	[integer!]
		/local
			n	[integer!]
			cr	[integer!]
			con	[integer!]
	][
		n: 0
		cr: as integer! #"^M"

		con: GetConsoleMode _get_osfhandle fd-stdout :n		;-- test if output is a console
		either con > 0 [									;-- output to console
			if confd = -2 [init-console-out]
			if confd = -1 [return WEOF]
			WriteConsole confd (as byte-ptr! :wchar) 1 :n null
		][													;-- output to redirection file
			if wchar = as integer! #"^/" [					;-- convert lf to crlf
				WriteFile _get_osfhandle fd-stdout (as c-string! :cr) 2 :n 0
			]
			WriteFile _get_osfhandle fd-stdout (as c-string! :wchar) 2 :n 0
		]
		wchar
	]

	;-------------------------------------------
	;-- putbuffer use windows api internal
	;-------------------------------------------
	putbuffer: func [
		chars [integer!]
		return: [integer!]
		/local
			n	[integer!]
			con	[integer!]
	][
		n: 0
		con: GetConsoleMode _get_osfhandle fd-stdout :n		;-- test if output is a console
		either con > 0 [									;-- output to console
			if confd = -2 [init-console-out]
			if confd = -1 [return WEOF]					
			WriteConsole confd pbuffer chars :n null
		][													;-- output to redirection file
			WriteFile _get_osfhandle fd-stdout as c-string! pbuffer 2 * chars :n 0
		]
		buffer: pbuffer
		chars
	]
	;-------------------------------------------
	;-- Print a UCS-4 string to console
	;-------------------------------------------
	print-UCS4: func [
		str    [int-ptr!]								;-- UCS-4 string
		size   [integer!]
		/local
			cp [integer!]								;-- codepoint
	][
		assert str <> null

		while [not zero? size][
			cp: str/value
			either str/value > FFFFh [
				cp: cp - 00010000h						;-- encode surrogate pair
				putwchar cp >> 10 + D800h				;-- emit lead
				putwchar cp and 03FFh + DC00h			;-- emit trail
			][
				putwchar cp								;-- UCS-2 codepoint
			]
			str: str + 1
			size: size - 4
		]
	]

	;-------------------------------------------
	;-- Print a UCS-4 string to console
	;-------------------------------------------
	print-line-UCS4: func [
		str    [int-ptr!]								;-- UCS-4 string
		size   [integer!]
		/local
			cp [integer!]								;-- codepoint
	][
		assert str <> null
		print-UCS4 str size								;@@ throw an error on failure
		putwchar 10										;-- newline
	]

	;-------------------------------------------
	;-- Print a UCS-2 string to console
	;-------------------------------------------
	print-UCS2: func [
		str 	[byte-ptr!]								;-- UCS-2 string
		size	[integer!]
		/local
			chars [integer!]
	][
		assert str <> null
		chars: 0
		while [not zero? size][
			buffer/1: str/1
			buffer/2: str/2
			chars: chars + 1
			buffer: buffer + 2
			str: str + 2
			size: size - 2
			if chars = 512 [  ; if the buffer has 1024 bytes, it has room for 512 chars
				putbuffer chars
				chars: 0
			]
		]
		putbuffer chars
	]

	;-------------------------------------------
	;-- Print a UCS-2 string with newline to console
	;-------------------------------------------
	print-line-UCS2: func [
		str 	[byte-ptr!]								;-- UCS-2 string
		size	[integer!]
	][
		assert str <> null
		print-UCS2 str size								;@@ throw an error on failure
		buffer/1: #"^M"
		buffer/2: null-byte
		buffer/3: #"^/"
		buffer/4: null-byte
		putbuffer 2 									;-- newline
	]

	;-------------------------------------------
	;-- Print a Latin-1 string to console
	;-------------------------------------------
	print-Latin1: func [
		str 	[c-string!]								;-- Latin-1 string
		size	[integer!]
		/local
			chars [integer!]							;-- mumber of used chars in buffer
	][
		assert str <> null
		chars: 0
		while [not zero? size][
			buffer/1: str/1
			buffer/2: null-byte ;this should be always 0 in Latin1
			size: size - 1
			str: str + 1
			chars: chars + 1
			buffer: buffer + 2
			if chars = 512 [  ; if the buffer has 1024 bytes, it has room for 512 chars
				putbuffer chars
				chars: 0
			]
		]
		putbuffer chars
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
		buffer/1: #"^M"
		buffer/2: null-byte
		buffer/3: #"^/"
		buffer/4: null-byte
		putbuffer 2 									;-- newline
	]


	;-------------------------------------------
	;-- Red/System Unicode replacement printing functions
	;-------------------------------------------

	prin*: func [s [c-string!] return: [c-string!] /local p][
		p: s
		while [p/1 <> null-byte][
			putwchar as-integer p/1
			p: p + 1
		]
		s
	]

	prin-int*: func [i [integer!] return: [integer!]][
		wprintf [#u16 "%i" i]
		fflush null										;-- flush all streams
		i
	]

	prin-2hex*: func [i [integer!] return: [integer!]][
		wprintf [#u16 "%02X" i]
		fflush null
		i
	]
	
	prin-hex*: func [i [integer!] return: [integer!]][
		wprintf [#u16 "%08X" i]
		fflush null
		i
	]

	prin-float*: func [f [float!]][
		wprintf [#u16 "%.16g" f]
		fflush null
	]

	prin-float32*: func [f [float32!]][
		wprintf [#u16 "%.7g" as-float f]
		fflush null
	]

	init-gdiplus: func [/local startup-input res][
		startup-input: declare GdiplusStartupInput!
		startup-input/GdiplusVersion: 1
		startup-input/DebugEventCallback: 0
		startup-input/SuppressBackgroundThread: 0
		startup-input/SuppressExternalCodecs: 0
		res: GdiplusStartup :gdiplus-token as-integer startup-input 0
	]

	shutdown-gdiplus: does [
		GdiplusShutdown gdiplus-token 
	]

	;-------------------------------------------
	;-- Do platform-specific initialization tasks
	;-------------------------------------------
	init: does [
		init-gdiplus
		#if unicode? = yes [
			_setmode fd-stdout _O_U16TEXT				;@@ throw an error on failure
			_setmode fd-stderr _O_U16TEXT				;@@ throw an error on failure
		]
		CoInitializeEx 0 COINIT_APARTMENTTHREADED
	]
]