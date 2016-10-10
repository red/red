Red/System [
	Title:   "Red runtime Darwin API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %darwin.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]


#define MMAP_PROT_RW		03h				;-- PROT_READ | PROT_WRITE
#define MMAP_PROT_RWX		07h				;-- PROT_READ | PROT_WRITE | PROT_EXEC

#define MMAP_MAP_PRIVATE    02h
#define MMAP_MAP_ANONYMOUS  1000h

#define SC_PAGE_SIZE		29

#define SYSCALL_MMAP		197
#define SYSCALL_MUNMAP		73

#define OBJC_ALLOC(class)		[objc_msgSend [objc_getClass class red/platform/id-alloc]]
#define OBJC_INIT(obj)			[obj: objc_msgSend [obj red/platform/id-init]]
#define OBJC_AUTO_RELEASE(obj)	[obj: objc_msgSend [obj red/platform/id-autorelease]]
#define OBJC_RELEASE(obj)		[objc_msgSend [obj red/platform/id-release]]
#define OBJC_DRAIN(obj)			[objc_msgSend [obj red/platform/id-drain]]

platform: context [

	#include %POSIX.reds

	#import  [
		LIBC-file cdecl [
			sysconf: "sysconf" [
				property	[integer!]
				return:		[integer!]
			]
			objc_getClass: "objc_getClass" [
				class		[c-string!]
				return:		[integer!]
			]
			sel_getUid: "sel_getUid" [
				name		[c-string!]
				return:		[integer!]
			]
			objc_msgSend: "objc_msgSend" [[variadic] return: [integer!]]
		]
	]

	page-size: 0

	true-value: 0						;-- Core Foundation: True value
	id-alloc: 0
	id-init: 0
	id-autorelease: 0
	id-release: 0
	id-drain: 0

	init-object-c: does [
		dlopen "/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation" RTLD_LAZY
		true-value: objc_msgSend [objc_getClass "NSNumber" sel_getUid "numberWithBool:" 1]
		id-alloc: sel_getUid "alloc"
		id-init:  sel_getUid "init"
		id-autorelease: sel_getUid "autorelease"
		id-release: sel_getUid "release"
		id-drain: sel_getUid "drain"
	]

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

		if -1 = as-integer ptr [
			raise-error RED_ERR_VMEM_OUT_OF_MEMORY as-integer system/pc
		]
		as int-ptr! ptr
	]

	;-------------------------------------------
	;-- Free paged virtual memory region from OS
	;-------------------------------------------	
	free-virtual: func [
		ptr [int-ptr!]							;-- address of memory region to release
	][
		if negative? munmap as byte-ptr! ptr ptr/value [
			raise-error RED_ERR_VMEM_RELEASE_FAILED as-integer system/pc
		]
	]
	
	init: does [
		page-size: sysconf SC_PAGE_SIZE
		setlocale __LC_ALL ""					;@@ check if "utf8" is present in returned string?
		init-object-c
	]
]