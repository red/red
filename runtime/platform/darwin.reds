Red/System [
	Title:   "Red runtime Darwin API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %darwin.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

platform: context [ 

	#include %POSIX.reds

	#import  [
		LIBC-file cdecl [
			_NSGetEnviron: "_NSGetEnviron" [
				return: 	[int-ptr!]
			]
		]
	]
	
	environ: 0
	page-size: 0

	#syscall [
		mmap: SYSCALL_MMAP [
			address		[byte-ptr!]
			size		[integer!]
			protection	[integer!]
			flags		[integer!]
			fd			[integer!]
			offset		[integer!]
			return:		[byte-ptr!]
		]
		munmap: SYSCALL_MUNMAP [
			address		[byte-ptr!]
			size		[integer!]
			return:		[integer!]
		]
	]
	;-------------------------------------------
	;-- Allocate paged virtual memory region from OS
	;-------------------------------------------
	allocate-virtual: func [
		size 	[integer!]						;-- allocated size in bytes (page size multiple)
		exec? 	[logic!]						;-- TRUE => executable region
		return: [int-ptr!]						;-- allocated memory region pointer
		/local
			ptr  [byte-ptr!]
			prot [integer!]
	][
		assert zero? (size and (page-size - 1))	;-- size is a multiple of page size
		prot: either exec? [MMAP_PROT_RWX][MMAP_PROT_RW]

		ptr: mmap 
			null 
			size
			prot	
			MMAP_MAP_PRIVATE or MMAP_MAP_ANONYMOUS
			-1									;-- portable value
			0

		if 12 = as-integer ptr [throw OS_ERROR_VMEM_OUT_OF_MEMORY]
		as int-ptr! ptr
	]

	;-------------------------------------------
	;-- Free paged virtual memory region from OS
	;-------------------------------------------	
	free-virtual: func [
		ptr [int-ptr!]							;-- address of memory region to release
	][
		if -1 = munmap as byte-ptr! ptr ptr/value [
			throw OS_ERROR_VMEM_RELEASE_FAILED
		]
	]
	
	init: func [/local ptr [int-ptr!]][
		ptr: _NSGetEnviron
		environ: ptr/value
		page-size: sysconf SC_PAGE_SIZE
		setlocale __LC_ALL ""					;@@ check if "utf8" is present in returned string?
	]
]