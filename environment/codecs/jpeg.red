Red [
	Title:   "JPEG codec"
	Author:  "Qingtian Xie"
	File:	 %jpeg.red
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

put system/codecs 'jpeg context [
	title: ""
	name: 'JPEG
	mime-type: [image/jpeg]
	suffixes: [%.jpg %.jpeg %.jpe %.jfif]
	
	encode: routine [img [image!] where [any-type!]][
		#if OS <> 'Linux [
			stack/set-last as cell! image/encode img where IMAGE_JPEG
		]
	]

	decode: routine [data [any-type!]][
		#if OS <> 'Linux [
			stack/set-last as cell! image/decode data
		]
	]
]