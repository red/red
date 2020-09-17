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

#define	SOL_SOCKET	0000FFFFh
#define SO_ERROR	1007h

#define	ENOMEM				12			;-- Cannot allocate memory
#define	EACCES				13			;-- Permission denied
#define	EAGAIN				35			;-- Try again
#define	EINPROGRESS			36			;-- Operation now in progress
#define	EALREADY			37			;-- Operation already in progress

#define MMAP_PROT_RW		03h			;-- PROT_READ | PROT_WRITE
#define MMAP_PROT_RWX		07h			;-- PROT_READ | PROT_WRITE | PROT_EXEC

#define MMAP_MAP_PRIVATE    02h
#define MMAP_MAP_ANONYMOUS  1000h

#define SC_PAGE_SIZE		29

#define SYSCALL_MMAP		197
#define SYSCALL_MUNMAP		73

#define gestaltSystemVersion		1937339254			;-- "sysv"
#define gestaltSystemVersionMajor	1937339185			;-- "sys1"
#define gestaltSystemVersionMinor	1937339186			;-- "sys2"
#define gestaltSystemVersionBugFix	1937339187			;-- "sys3"

#define	_SC_NPROCESSORS_CONF	57
#define	_SC_NPROCESSORS_ONLN	58

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
	st_blocks	[integer!]
	st_blksize	[integer!]
	st_flags	[integer!]
	st_gen		[integer!]
	st_lspare	[integer!]
	st_qspare_1 [integer!]				;-- int64
	st_qspare_2 [integer!]
	st_qspare_3 [integer!]				;-- int64
	st_qspare_4 [integer!]
]
;;-- #if __DARWIN_64_BIT_INO_T
;stat!: alias struct! [				;-- __DARWIN_STRUCT_STAT64
;	st_dev		[integer!]
;	st_modelink	[integer!]			;-- st_mode & st_link are both 16bit fields
;	st_ino_1	[integer!]			;-- int64
;	st_ino_2	[integer!]
;	st_uid		[integer!]
;	st_gid		[integer!]
;	st_rdev		[integer!]
;	atv_sec		[integer!]
;	atv_msec	[integer!]
;	mtv_sec		[integer!]
;	mtv_msec	[integer!]
;	ctv_sec		[integer!]
;	ctv_msec	[integer!]
;	birth_sec	[integer!]
;	birth_msec	[integer!]
;	st_size_1	[integer!]			;-- int64
;	st_size		[integer!]
;	st_blocks_1	[integer!]			;-- int64
;	st_blocks_2	[integer!]
;	st_blksize	[integer!]
;	st_flags	[integer!]
;	st_gen		[integer!]
;	st_lspare	[integer!]
;	st_qspare_1 [integer!]			;-- int64
;	st_qspare_2 [integer!]
;	st_qspare_3 [integer!]			;-- int64
;	st_qspare_4 [integer!]
;]
;#define DIRENT_NAME_OFFSET	21
;dirent!: alias struct! [
;	d_ino		[integer!]
;	_d_ino_		[integer!]
;	d_seekoff	[integer!]
;	_d_seekoff_	[integer!]
;	d_reclen	[integer!]				;-- d_reclen & d_namlen
;	;d_namlen	[integer!]
;	d_type		[byte!]
;	;d_name		[byte! [1024]]
;]
;;-- #endif

dirent!: alias struct! [
	d_ino		[integer!]
	d_reclen	[byte!]
	_d_reclen_	[byte!]
	d_type		[byte!]
	d_namlen	[byte!]
	;d_name		[byte! [256]]
]
