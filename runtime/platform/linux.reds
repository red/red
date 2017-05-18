Red/System [
	Title:   "Red runtime Linux API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %linux.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

#define MMAP_PROT_RW		03h				;-- PROT_READ | PROT_WRITE
#define MMAP_PROT_RWX		07h				;-- PROT_READ | PROT_WRITE | PROT_EXEC

#define MMAP_MAP_SHARED     01h
#define MMAP_MAP_PRIVATE    02h
#define MMAP_MAP_ANONYMOUS  20h

#either OS = 'Android [
	#define SC_PAGE_SIZE	28h
][
	#define SC_PAGE_SIZE	1Eh
]

#define SYSCALL_MMAP2		192
#define SYSCALL_MUNMAP		91
#define SYSCALL_MMAP		SYSCALL_MMAP2

#define	EPERM				1			;-- Operation not permitted
#define	ENOENT				2			;-- No such file or directory
#define	EINTR				4			;-- Interrupted system call
#define	EAGAIN				11			;-- Try again
#define	ENOSYS				38			;-- Function not implemented

platform: context [
	
	#either OS = 'Android [
		#either type = 'exe [
			#include %POSIX.reds
		][
			#include %android.reds
		]
	][
		#include %POSIX.reds
	]

	#import  [
		LIBC-file cdecl [
			sysconf: "sysconf" [
				property	[integer!]
				return:		[integer!]
			]
			environ: "environ" [integer!]
		]
	]

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
		/local ptr prot
	][
		size: round-to-next size 16
		assert zero? (size and 0Fh)				;-- size is a multiple of 16
		prot: either exec? [MMAP_PROT_RWX][MMAP_PROT_RW]

		ptr: mmap 
			null 
			size
			prot	
			MMAP_MAP_PRIVATE or MMAP_MAP_ANONYMOUS
			-1									;-- portable value
			0

		if -1 = as-integer ptr [throw OS_ERROR_VMEM_OUT_OF_MEMORY]
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
	
	
	init: does [
		page-size: sysconf SC_PAGE_SIZE			;@@ add error checking!
		#if type = 'exe [
			setlocale __LC_CTYPE ""					;@@ check if "utf8" is present in returned string?
		]
	]
]