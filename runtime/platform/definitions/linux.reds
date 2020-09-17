Red/System [
	Title:   "Red runtime Linux API imported functions definitions"
	Author:  "Nenad Rakocevic"
	File: 	 %linux.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
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

#define _SC_NPROCESSORS_CONF 83
#define _SC_NPROCESSORS_ONLN 84

#define SYSCALL_MMAP2		192
#define SYSCALL_MUNMAP		91
#define SYSCALL_MMAP		SYSCALL_MMAP2

#define SOL_SOCKET	1
#define SO_ERROR 4

#define	EPERM				1			;-- Operation not permitted
#define	ENOENT				2			;-- No such file or directory
#define	EINTR				4			;-- Interrupted system call
#define	EAGAIN				11			;-- Try again
#define ENOMEM				12
#define EACCES				13			;-- No permission
#define	ENOSYS				38			;-- Function not implemented
#define EALREADY			114			;-- Operation already in progress
#define EINPROGRESS			115			;-- Operation now in progress

#define EPOLL_CTL_ADD	1
#define EPOLL_CTL_DEL	2
#define EPOLL_CTL_MOD	3

#case [
	all [legacy find legacy 'stat32] [
		stat!: alias struct! [
			st_dev		[integer!]
			st_ino		[integer!]
			st_mode		[integer!]
			st_nlink	[integer!]
			st_uid		[integer!]
			st_gid		[integer!]
			st_rdev		[integer!]
			st_size		[integer!]
			st_blksize	[integer!]
			st_blocks	[integer!]
			st_atime	[timespec!]
			st_mtime	[timespec!]
			st_ctime	[timespec!]
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
	]
	OS = 'Android [ ; else
		;https://android.googlesource.com/platform/bionic.git/+/master/libc/include/sys/stat.h
		stat!: alias struct! [					;-- stat64 struct
			st_dev_h	  [integer!]
			st_dev_l	  [integer!]
			pad0		  [integer!]
			__st_ino	  [integer!]
			st_mode		  [integer!]
			st_nlink	  [integer!]
			st_uid		  [integer!]
			st_gid		  [integer!]
			st_rdev_h	  [integer!]
			st_rdev_l	  [integer!]
			pad1		  [integer!]
			st_size_h	  [integer!]
			st_size	  [integer!]
			st_blksize	  [integer!]
			st_blocks_h	  [integer!]
			st_blocks	  [integer!]
			st_atime	  [timespec! value]
			st_mtime	  [timespec! value]
			st_ctime	  [timespec! value]
			st_ino_h	  [integer!]
			st_ino_l	  [integer!]
			;...optional padding skipped
		]
		#define DIRENT_NAME_OFFSET	19
		dirent!: alias struct! [
			d_ino		[integer!]
			_d_ino_		[integer!]
			d_off		[integer!]
			_d_off_		[integer!]
			d_reclen	[byte!]
			_d_reclen_	[byte!]
			d_type		[byte!]
			;d_name		[byte! [256]]
		]
	]
	true [ ; else
		;-- http://lxr.free-electrons.com/source/arch/x86/include/uapi/asm/stat.h
		stat!: alias struct! [					;-- stat64 struct
			st_dev_l	  [integer!]
			st_dev_h	  [integer!]
			pad0		  [integer!]
			__st_ino	  [integer!]
			st_mode		  [integer!]
			st_nlink	  [integer!]
			st_uid		  [integer!]
			st_gid		  [integer!]
			st_rdev_l	  [integer!]
			st_rdev_h	  [integer!]
			pad1		  [integer!]
			st_size		  [integer!]
			st_blksize	  [integer!]
			st_blocks	  [integer!]
			st_atime	  [timespec! value]
			st_mtime	  [timespec! value]
			st_ctime	  [timespec! value]
			st_ino_h	  [integer!]
			st_ino_l	  [integer!]
			;...optional padding skipped
		]

		#define DIRENT_NAME_OFFSET 11
		dirent!: alias struct! [
			d_ino			[integer!]
			d_off			[integer!]
			d_reclen		[byte!]
			d_reclen_pad	[byte!]
			d_type			[byte!]
			;d_name			[byte! [256]]
		]
	]
]
