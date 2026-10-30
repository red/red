Red [
	Title:   "TIFF codec"
	Author:  "Nenad Rakocevic"
	File:	 %TIFF.red
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

put system/codecs 'tiff context [
	title: ""
	name: 'TIFF
	mime-type: [image/tiff]
	suffixes: [%.tif %.tiff]
	
	encode: routine [img [image!] where [any-type!]][
		#if not find [Android FreeBSD NetBSD Syllabe] OS [
			stack/set-last as cell! image/encode img where IMAGE_TIFF
		]
	]

	decode: routine [data [any-type!]][
		#if not find [Android FreeBSD NetBSD Syllabe] OS [
			stack/set-last as cell! image/decode data
		]
	]
]