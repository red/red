Red/System [
	Title:   "Red runtime OS API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %imports.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#either OS = 'Windows [
	#import [
		"kernel32.dll" stdcall [
			OS-VirtualAlloc: "VirtualAlloc" [
				address		[byte-ptr!]
				size		[integer!]
				type		[integer!]
				protection	[integer!]
				return:		[byte-ptr!]
			]
			OS-VirtualFree: "VirtualFree" [
				address 	[byte-ptr!]
				size		[integer!]
				return:		[integer!]
			]
		]
	]
	
	#define VA_COMMIT_RESERVE	3000h			;-- MEM_COMMIT | MEM_RESERVE
	#define VA_PAGE_RW			04h				;-- PAGE_READWRITE
	#define VA_PAGE_RWX			40h				;-- PAGE_EXECUTE_READWRITE
	
	;-------------------------------------------
	;-- Allocate paged virtual memory region from OS (Windows)
	;-------------------------------------------
	allocate-virtual: func [
		size 	[integer!]						;-- allocated size in bytes (page size multiple)
		exec? 	[logic!]						;-- TRUE => executable region
		return: [byte-ptr!]						;-- allocated memory region pointer
		/local ptr
	][
		ptr: OS-VirtualAlloc 
			null
			size
			VA_COMMIT_RESERVE
			either exec? [VA_PAGE_RWX][VA_PAGE_RW]
			
		if ptr = null [***-on-quit 97 0]		;-- raise runtime error
		ptr
	]
	;-------------------------------------------
	;-- Free paged virtual memory region from OS (Windows)
	;-------------------------------------------
	free-virtual: func [
		ptr [byte-ptr!]							;-- address of memory region to release
		size [integer!]							;-- allocated size in bytes (page size multiple)
	][
		if negative? OS-VirtualFree ptr size [
			***-on-quit 96 as-integer ptr		;-- raise runtime error
		]
	]
][	
	#define MMAP_PROT_RW		03h				;-- PROT_READ | PROT_WRITE
	#define MMAP_PROT_RWX		07h				;-- PROT_READ | PROT_WRITE | PROT_EXEC
	
	#define MMAP_MAP_PRIVATE    02h
	#define MMAP_MAP_ANONYMOUS  20h

	#syscall [
		OS-mmap: SYSCALL_MMAP [
			address		[byte-ptr!]
			size		[integer!]
			protection	[integer!]
			flags		[integer!]
			fd			[integer!]
			offset		[integer!]
			return:		[byte-ptr!]
		]
		OS-munmap: SYSCALL_MUNMAP [
			address		[byte-ptr!]
			size		[integer!]
			return:		[integer!]
		]
	]
	;-------------------------------------------
	;-- Allocate paged virtual memory region from OS (UNIX)
	;-------------------------------------------
	allocate-virtual: func [
		size 	[integer!]						;-- allocated size in bytes (page size multiple)
		exec? 	[logic!]						;-- TRUE => executable region
		return: [byte-ptr!]						;-- allocated memory region pointer
	][
		ptr: OS-mmap 
			null 
			size
			either exec? [MMAP_PROT_RWX][MMAP_PROT_RW]
			MMAP_MAP_PRIVATE or MMAP_MAP_ANONYMOUS
			-1									;-- portable value
			0
			
		if negative? as-integer ptr [
			***-on-quit 97 0					;-- raise runtime error
		]
		ptr
	]
	;-------------------------------------------
	;-- Free paged virtual memory region from OS (UNIX)
	;-------------------------------------------	
	free-virtual: func [
		ptr [byte-ptr!]							;-- address of memory region to release
		size [integer!]							;-- allocated size in bytes (page size multiple)
	][
		if negative? OS-munmap ptr size [
			***-on-quit 96 as-integer ptr		;-- raise runtime error
		]
	]
]