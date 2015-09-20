Red [
	Title:   "PNG codec"
	Author:  "Qingtian Xie"
	File:	 %png.red
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Qingtian Xie. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

put system/codecs 'png context [
	title: ""
	name: 'PNG
	mime-type: [image/png]
	suffixes: [%.png]
	
	encode: routine [image [image!]][]

	decode: routine [data [any-type!]][
		either TYPE_OF(data) = TYPE_BINARY [
			stack/set-last as cell! image/load-binary as red-binary! data
		][
			image/make-at stack/arguments as red-string! data
		]
	]
]