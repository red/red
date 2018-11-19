Red/System [
	Title:   "POSIX I/O API imported functions definitions"
	Author:  "Xie Qingtian"
	File: 	 %POSIX.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2017 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

systemtime!: alias struct! [
	sec		[integer!] ;seconds
	min		[integer!] ;minutes
	hour	[integer!] ;hours
	mday	[integer!] ;day of the month
	mon		[integer!] ;month
	year	[integer!] ;year
	wday	[integer!] ;day of the week
	yday	[integer!] ;day in the year
	isdst	[integer!] ;daylight saving time
]

timespec!: alias struct! [
	sec		[integer!] ;Seconds
	nsec	[integer!] ;Nanoseconds
]

#case [
	any [OS = 'macOS OS = 'FreeBSD OS = 'Android] [
		#import [
			LIBC-file cdecl [
				;-- https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/10.6/man2/stat.2.html?useVersion=10.6
				_stat:	"fstat" [
					file		[integer!]
					restrict	[stat!]
					return:		[integer!]
				]
			]
		]
	]
	true [
		#import [
			LIBC-file cdecl [
				;-- http://refspecs.linuxbase.org/LSB_3.0.0/LSB-Core-generic/LSB-Core-generic/baselib-xstat-1.html
				_stat:	"__fxstat" [
					version		[integer!]
					file		[integer!]
					restrict	[stat!]
					return:		[integer!]
				]
			]
		]
	]

]

#either OS = 'macOS [
	#import [
		LIBC-file cdecl [
			lseek: "lseek" [
				file		[integer!]
				offset-lo	[integer!]
				offset-hi	[integer!]
				whence		[integer!]
				return:		[integer!]
			]
		]
	]
][
	#import [
		LIBC-file cdecl [
			lseek: "lseek" [
				file		[integer!]
				offset		[integer!]
				whence		[integer!]
				return:		[integer!]
			]
		]
	]
]

#import [
	LIBC-file cdecl [
		_access: "access" [
			filename	[c-string!]
			mode		[integer!]
			return:		[integer!]
		]
		_open:	"open" [
			filename	[c-string!]
			flags		[integer!]
			mode		[integer!]
			return:		[integer!]
		]
		_read:	"read" [
			file		[integer!]
			buffer		[byte-ptr!]
			bytes		[integer!]
			return:		[integer!]
		]
		_write:	"write" [
			file		[integer!]
			buffer		[byte-ptr!]
			bytes		[integer!]
			return:		[integer!]
		]
		_close:	"close" [
			file		[integer!]
			return:		[integer!]
		]
		mkdir: "mkdir" [
			pathname	[c-string!]
			mode		[integer!]
			return:		[integer!]
		]
		opendir: "opendir" [
			filename	[c-string!]
			return:		[integer!]
		]
		readdir: "readdir" [
			file		[integer!]
			return:		[dirent!]
		]
		closedir: "closedir" [
			file		[integer!]
			return:		[integer!]
		]
		_remove: "remove" [
			pathname	[c-string!]
			return: 	[integer!]
		]
		strncmp: "strncmp" [
			str1		[c-string!]
			str2		[c-string!]
			num			[integer!]
			return:		[integer!]
		]
		strstr: "strstr" [
			str			[c-string!]
			substr		[c-string!]
			return:		[c-string!]
		]
		strchr: "strchr" [
			str			[c-string!]
			c			[byte!]
			return:		[c-string!]
		]
		gmtime: "gmtime" [
			time		[pointer! [integer!]]
			return:		[systemtime!]
		]
	]
]