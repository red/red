Red [
	Title:   "BMP codec"
	Author:  "Qingtian Xie"
	File:	 %bmp.red
	Tabs:	 4
	Rights:  "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

put system/codecs 'bmp context [
	title: ""
	name: 'BMP
	mime-type: [image/bmp]
	suffixes: [%.bmp]
	
	encode: routine [img [image!] where [any-type!]][
		#if not find [Android Linux FreeBSD Syllabe] OS [
			stack/set-last as cell! image/encode img where IMAGE_BMP
		]
	]

	decode: routine [data [any-type!]][
		#if not find [Android Linux FreeBSD Syllabe] OS [
			stack/set-last as cell! image/decode data
		]
	]
]