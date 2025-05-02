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

#either target = 'ARM [
	#define SYSCALL_GETDENTS64	217
][
	#define SYSCALL_GETDENTS64	220
]

#define SYSCALL_MMAP2		192
#define SYSCALL_MUNMAP		91
#define SYSCALL_MMAP		SYSCALL_MMAP2

#define	EPERM				1			;-- Operation not permitted
#define	ENOENT				2			;-- No such file or directory
#define	EINTR				4			;-- Interrupted system call
#define	EAGAIN				11			;-- Try again
#define	ENOSYS				38			;-- Function not implemented

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
		#either target = 'ARM [
			;-- https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/stat.h#L49
			stat!: alias struct! [					;-- stat64 struct, 104 bytes
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
				pad2		  [integer!]
				st_size		  [integer!]
				st_size_h	  [integer!]
				st_blksize	  [integer!]
				pad3		  [integer!]
				st_blocks	  [integer!]
				st_blocks_h	  [integer!]
				st_atime	  [timespec! value]
				st_mtime	  [timespec! value]
				st_ctime	  [timespec! value]
				st_ino_h	  [integer!]
				st_ino_l	  [integer!]
			]
		][
			;-- https://elixir.bootlin.com/linux/latest/source/arch/arm/include/uapi/asm/stat.h#L57
			;-- https://elixir.bootlin.com/linux/v5.9.10/source/arch/x86/include/uapi/asm/stat.h
			stat!: alias struct! [					;-- stat64 struct, 96 bytes
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
				st_size_h	  [integer!]
				st_blksize	  [integer!]
				st_blocks	  [integer!]
				st_blocks_h	  [integer!]
				st_atime	  [timespec! value]
				st_mtime	  [timespec! value]
				st_ctime	  [timespec! value]
				st_ino_h	  [integer!]
				st_ino_l	  [integer!]
			]
		]

		#either dynamic-linker = "/lib/ld-musl-i386.so.1" [
			#define DIRENT_NAME_OFFSET 19
		][
			#define DIRENT_NAME_OFFSET 11
		]
		dirent!: alias struct! [
			d_ino			[integer!]
			d_off			[integer!]
			d_reclen		[byte!]
			d_reclen_pad	[byte!]
			d_type			[byte!]
			;d_name			[byte! [256]]
		]

		#define LINUX_DIRENT64_NAME_OFFSET	19
		linux_dirent64!: alias struct! [
			d_ino_1			[integer!]		;-- 64-bit inode number
			d_ino_2			[integer!]
			d_off_1			[integer!]		;-- 64-bit offset to next structure
			d_off_2			[integer!]
			d_reclen		[byte!]
			d_reclen_pad	[byte!]
			d_type			[byte!]	
			;d_reclen		[integer!]		;-- uint16! size of this dirent
			;d_type			[byte!]			;-- file type
			;d_name			[char!]			;-- filename (null-terminated)
		]
	]
]