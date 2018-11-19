Red/System [
	Title:   "Red runtime FreeBSD API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File:	 %freebsd.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]


#define MMAP_PROT_RW		03h				;-- PROT_READ | PROT_WRITE
#define MMAP_PROT_RWX		07h				;-- PROT_READ | PROT_WRITE | PROT_EXEC

#define MMAP_MAP_PRIVATE    02h
#define MMAP_MAP_ANONYMOUS  1000h

#define SC_PAGE_SIZE		47

#define SYSCALL_MMAP		477
#define SYSCALL_MUNMAP		73

;-- http://fxr.watson.org/fxr/source/sys/stat.h?v=FREEBSD10
stat!: alias struct! [
	st_dev		[integer!]
	st_ino		[integer!]
	st_modelink	[integer!]				;-- st_mode & st_link are both 16bit fields
	st_uid		[integer!]
	st_gid		[integer!]
	st_rdev		[integer!]
	st_atime	[timespec! value]		;-- struct timespec inlined
	st_mtime	[timespec! value]		;-- struct timespec inlined
	st_ctime	[timespec! value]		;-- struct timespec inlined
	st_size		[integer!]
	st_size_h	[integer!]
	st_blocks_l	[integer!]
	st_blocks_h	[integer!]
	st_blksize	[integer!]
	st_flags	[integer!]
	st_gen		[integer!]
	st_lspare	[integer!]
	btm_sec     [integer!]
	btm_msec    [integer!]				;-- struct timespec inlined
	pad0		[integer!]
	pad1		[integer!]
]
dirent!: alias struct! [				;@@ the same as macOS
	d_ino		[integer!]
	d_reclen	[byte!]
	_d_reclen_	[byte!]
	d_type		[byte!]
	d_namlen	[byte!]
	;d_name		[byte! [256]]
]

platform: context [

	#include %POSIX.reds

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
			offset_l	[integer!]
			offset_h    [integer!]              ;-- off_t is 64 bit on FreeBSD
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
		size	[integer!]						;-- allocated size in bytes (page size multiple)
		exec?	[logic!]						;-- TRUE => executable region
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
		page-size: sysconf SC_PAGE_SIZE
		setlocale __LC_ALL ""					;@@ check if "utf8" is present in returned string?
	]
]
