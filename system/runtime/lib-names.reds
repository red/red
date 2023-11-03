Red/System [
	Title:   "Red/System OS-independent runtime"
	Author:  "Nenad Rakocevic"
	File: 	 %lib-names.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#switch OS [
	Windows  [
	  #define LIBC-file	"msvcrt.dll"
	  #define LIBM-file "msvcrt.dll"
	]
	Syllable [
	  #define LIBC-file	"libc.so.2"
	  #define LIBM-file "libm.so.2"
	]
	macOS	 [
	  #define LIBC-file	"libc.dylib"
	  #define LIBM-file	"libc.dylib"
	]
	Android [
		#define LIBC-file	"libc.so"
		#define LIBM-file	"libm.so"
	]
	FreeBSD [
		#define LIBC-file	"libc.so.7"
		#define LIBM-file	"libm.so.5"
	]
	NetBSD [
		#define LIBC-file	"libc.so"
		#define LIBM-file	"libm.so"
	]
	#default [											;-- Linux
		#case [
			dynamic-linker = "/lib/ld-musl-i386.so.1" [
				#define LIBC-file	"ld-musl-i386.so.1"
				#define LIBM-file	"ld-musl-i386.so.1"
			]
			dynamic-linker = "/lib/ld-uClibc.so.1" [
				#define LIBC-file	"libc.so.1"
				#define LIBM-file	"libc.so.1"
			]
			true [
				#define LIBC-file	"libc.so.6"
				#define LIBM-file	"libm.so.6"
			]
		]
	]
]