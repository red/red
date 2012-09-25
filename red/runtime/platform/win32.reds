Red/System [
	Title:   "Red runtime win32 API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %win32.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#define VA_COMMIT_RESERVE	3000h						;-- MEM_COMMIT | MEM_RESERVE
#define VA_PAGE_RW			04h							;-- PAGE_READWRITE
#define VA_PAGE_RWX			40h							;-- PAGE_EXECUTE_READWRITE

#define _O_TEXT        	 	4000h  						;-- file mode is text (translated)
#define _O_BINARY       	8000h  						;-- file mode is binary (untranslated)
#define _O_WTEXT        	00010000h 					;-- file mode is UTF16 (translated)
#define _O_U16TEXT      	00020000h 					;-- file mode is UTF16 no BOM (translated)
#define _O_U8TEXT       	00040000h 					;-- file mode is UTF8  no BOM (translated)


platform: context [
	
	#enum file-descriptors! [
		fd-stdout: 1									;@@ hardcoded, safe?
		fd-stderr: 2									;@@ hardcoded, safe?
	]

	page-size: 4096

	#import [
		LIBC-file cdecl [
			putwchar: "putwchar" [
				wchar		[integer!]					;-- wchar is 16-bit on Windows
			]
			wprintf: "wprintf_s" [
				[variadic]
				return: 	[integer!]
			]
			_setmode: "_setmode" [
				handle		[integer!]
				mode		[integer!]
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
	;-- Print a UCS-4 string to console
	;-------------------------------------------
	print-UCS4: func [
		str    [int-ptr!]								;-- zero-terminated UCS-4 string
		/local
			cp [integer!]								;-- codepoint
	][
		assert str <> null
		
		while [cp: str/value not zero? cp][			
			either str/value > FFFFh [
				cp: cp - 00010000h						;-- encode surrogate pair
				putwchar cp >> 10 + D800h				;-- emit lead
				putwchar cp and 03FFh + DC00h			;-- emit trail
			][
				putwchar cp								;-- UCS-2 codepoint
			]
			str: str + 1
		]
	]
		
	;-------------------------------------------
	;-- Print a UCS-4 string to console
	;-------------------------------------------
	print-line-UCS4: func [
		str    [int-ptr!]								;-- zero-terminated UCS-4 string
		/local
			cp [integer!]								;-- codepoint
	][
		assert str <> null
		print-UCS4 str									;@@ throw an error on failure
		putwchar 10										;-- newline
	]
	
	;-------------------------------------------
	;-- Print a UCS-2 string to console
	;-------------------------------------------
	print-UCS2: func [
		str 	[byte-ptr!]								;-- zero-terminated UCS-2 string
	][
		assert str <> null
		wprintf str										;@@ throw an error on failure
	]

	;-------------------------------------------
	;-- Print a UCS-2 string with newline to console
	;-------------------------------------------
	print-line-UCS2: func [
		str 	[byte-ptr!]								;-- zero-terminated UCS-2 string
	][
		assert str <> null
		wprintf str										;@@ throw an error on failure
		putwchar 10										;-- newline
	]
	
	;-------------------------------------------
	;-- Print a Latin-1 string to console
	;-------------------------------------------
	print-Latin1: func [
		str 	[c-string!]								;-- zero-terminated Latin-1 string
		/local
			cp [integer!]								;-- codepoint
	][
		assert str <> null

		while [cp: as-integer str/1 not zero? cp][
			putwchar cp
			str: str + 1
		]
	]
	
	;-------------------------------------------
	;-- Print a Latin-1 string with newline to console
	;-------------------------------------------
	print-line-Latin1: func [
		str [c-string!]									;-- zero-terminated Latin-1 string
	][
		assert str <> null
		print-Latin1 str
		putwchar 10										;-- newline
	]
	
	;-------------------------------------------
	;-- Red/System Unicode replacement printing functions
	;-------------------------------------------
	
	prin: func [s [c-string!] return: [c-string!] /local p][
		p: s
		while [p/1 <> null-byte][
			putwchar as-integer p/1
			p: p + 1
		]
		s
	]

	prin-int: func [i [integer!] return: [integer!]][
		wprintf ["%^(00)i^(00)^(00)" i]								;-- UTF-16 literal string
		i
	]

	prin-hex: func [i [integer!] return: [integer!]][
		wprintf ["%^(00)0^(00)8^(00)X^(00)^(00)" i]					;-- UTF-16 literal string
		i
	]

	prin-float: func [f [float!] return: [float!]][
		wprintf ["^(00)%^(00).^(00)1^(00)4^(00)g^(00)^(00)" f]		;-- UTF-16 literal string
		f
	]

	prin-float32: func [f [float32!] return: [float32!]][
		wprintf ["^(00)%^(00).^(00)7^(00)g^(00)^(00)" as-float f]	;-- UTF-16 literal string
		f
	]
	
	;-------------------------------------------
	;-- Do platform-specific initialization tasks
	;-------------------------------------------
	init: does [
		_setmode fd-stdout _O_U16TEXT					;@@ throw an error on failure
		_setmode fd-stderr _O_U16TEXT					;@@ throw an error on failure
	]
]