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

#define OS-page-size	4096					;@@ target/OS dependent

;-------------------------------------------
;-- Return an integer rounded to the closer upper page size multiple
;-------------------------------------------
page-round: func [
	size 	[integer!]							;-- a memory region size
	return: [integer!]							;-- rounded value
][
	and
		size + OS-page-size
		negate OS-page-size
]

#either OS = 'Windows [
	#import [
		"kernel32.dll" stdcall [
			OS-VirtualAlloc: "VirtualAlloc" [
				address		[byte-ptr!]
				size		[integer!]
				type		[integer!]
				protection	[integer!]
				return:		[int-ptr!]
			]
			OS-VirtualFree: "VirtualFree" [
				address 	[int-ptr!]
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
		return: [int-ptr!]						;-- allocated memory region pointer
		/local ptr
	][
		size: page-round size + 4				;-- account for header (one word)
		
		ptr: OS-VirtualAlloc 
			null
			size
			VA_COMMIT_RESERVE
			either exec? [VA_PAGE_RWX][VA_PAGE_RW]
			
		if ptr = null [raise-error RED_ERR_VMEM_OUT_OF_MEMORY 0]
		ptr/value: size							;-- store size in header
		ptr + 1									;-- return pointer after header
	]
	
	;-------------------------------------------
	;-- Free paged virtual memory region from OS (Windows)
	;-------------------------------------------
	free-virtual: func [
		ptr [int-ptr!]							;-- address of memory region to release
	][
		ptr: ptr - 1							;-- return back to header
		if negative? OS-VirtualFree ptr ptr/value [
			raise-error RED_ERR_VMEM_RELEASE_FAILED as-integer ptr
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
		return: [int-ptr!]						;-- allocated memory region pointer
	][
		size: page-round size + 4				;-- account for header (one word)
		
		ptr: OS-mmap 
			null 
			size
			either exec? [MMAP_PROT_RWX][MMAP_PROT_RW]
			MMAP_MAP_PRIVATE or MMAP_MAP_ANONYMOUS
			-1									;-- portable value
			0
			
		if negative? as-integer ptr [
			raise-error RED_ERR_VMEM_OUT_OF_MEMORY 0
		]
		ptr/value: size							;-- store size in header
		ptr + 1									;-- return pointer after header
	]
	
	;-------------------------------------------
	;-- Free paged virtual memory region from OS (UNIX)
	;-------------------------------------------	
	free-virtual: func [
		ptr [int-ptr!]							;-- address of memory region to release
	][
		ptr: ptr - 1							;-- return back to header
		if negative? OS-munmap ptr ptr/value [
			raise-error RED_ERR_VMEM_RELEASE_FAILED as-integer ptr
		]
	]
]