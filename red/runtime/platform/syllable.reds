Red/System [
	Title:   "Red runtime Syllable API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %syllable.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#define MMAP_PROT_RW		03h				;-- PROT_READ | PROT_WRITE
#define MMAP_PROT_RWX		07h				;-- PROT_READ | PROT_WRITE | PROT_EXEC

#define MMAP_MAP_SHARED     10h
#define MMAP_MAP_PRIVATE    20h
#define MMAP_MAP_ANONYMOUS  80h

#define SC_PAGE_SIZE		30

#define SYSCALL_MMAP		222
#define SYSCALL_MUNMAP		223

#import  [
	LIBC-file cdecl [
		sysconf: "sysconf" [
			property	[integer!]
			return:		[integer!]
		]
	]
]

OS-page-size: sysconf SC_PAGE_SIZE

#syscall [
	OS-mmap: SYSCALL_MMAP [
		address		[byte-ptr!]
		size		[integer!]
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
OS-allocate-virtual: func [
	size 	[integer!]						;-- allocated size in bytes (page size multiple)
	exec? 	[logic!]						;-- TRUE => executable region
	return: [int-ptr!]						;-- allocated memory region pointer
	/local ptr flags
][
	assert zero? (size and 0Fh)				;-- size is a multiple of 16
	flags: either exec? [MMAP_PROT_RWX][MMAP_PROT_RW]
	flags: flags or (MMAP_MAP_PRIVATE or MMAP_MAP_ANONYMOUS << 4)
	
	ptr: OS-mmap null size flags -1	0

	if negative? as-integer ptr [
		raise-error RED_ERR_VMEM_OUT_OF_MEMORY as-integer system/pc
	]
	as int-ptr! ptr
]

;-------------------------------------------
;-- Free paged virtual memory region from OS (UNIX)
;-------------------------------------------	
OS-free-virtual: func [
	ptr [int-ptr!]							;-- address of memory region to release
][
	if negative? OS-munmap as byte-ptr! ptr ptr/value [
		raise-error RED_ERR_VMEM_RELEASE_FAILED as-integer system/pc
	]
]