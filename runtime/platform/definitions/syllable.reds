Red/System [
	Title:   "Red runtime Syllable API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %syllable.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
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

;-- http://glibc.sourcearchive.com/documentation/2.7-18lenny7/glibc-2_87_2bits_2stat_8h_source.html
stat!: alias struct! [
	st_mode		[integer!]
	st_ino		[integer!]
	st_dev		[integer!]
	st_nlink	[integer!]
	st_uid		[integer!]
	st_gid		[integer!]
	filler1		[integer!]				;-- not in spec above...
	filler2		[integer!]				;-- not in spec above...
	st_size		[integer!]
	;...incomplete...
]
#define DIRENT_NAME_OFFSET 8
dirent!: alias struct! [
	d_ino		[integer!]
	d_reclen	[byte!]
	_d_reclen_	[byte!]
	d_type		[byte!]
	d_namlen	[byte!]
	;d_name		[byte! [256]]
]