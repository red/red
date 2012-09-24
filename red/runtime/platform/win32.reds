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

#define VA_COMMIT_RESERVE	3000h			;-- MEM_COMMIT | MEM_RESERVE
#define VA_PAGE_RW			04h				;-- PAGE_READWRITE
#define VA_PAGE_RWX			40h				;-- PAGE_EXECUTE_READWRITE


platform: context [

	page-size: 4096

	#import [
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
	;-- Allocate paged virtual memory region from OS (Windows)
	;-------------------------------------------
	allocate-virtual: func [
		size 	[integer!]						;-- allocated size in bytes (page size multiple)
		exec? 	[logic!]						;-- TRUE => executable region
		return: [int-ptr!]						;-- allocated memory region pointer
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
	;-- Free paged virtual memory region from OS (Windows)
	;-------------------------------------------
	free-virtual: func [
		ptr [int-ptr!]							;-- address of memory region to release
	][
		if negative? VirtualFree ptr ptr/value [
			raise-error RED_ERR_VMEM_RELEASE_FAILED as-integer ptr
		]
	]
	
]