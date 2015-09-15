REBOL [
	Title:   "Red/System unicode conversion library"
	Author:  "Qingtian Xie"
	File: 	 %unicode.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Qingtian Xie. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

utf8-to-utf16: func [s [string!] /length /local m cp result cnt][
	result: make string! (length? s) * 2
	cnt: 0
	while [not tail? s][
		cp: first s
		cnt: cnt + 1
		either cp < 128 [
			unless length [repend result [cp #"^@"]]
		][
			m: 8 - length? find	enbase/base	to binary! cp 2 #"0"
			cp: cp xor pick [0 192 224 240 248 252] m
			loop m - 1 [cp: 64 * cp + (63 and first s: next s)]		;--	code point
			either cp < 65536 [
				unless length [append result to-bin16 cp]
			][
				;--	multiple UTF16 characters with surrogates
				either length [cnt: cnt + 1][
					cp: cp - 65536
					append result to-bin16 55296 + shift/logical cp 10
					append result to-bin16 cp and 1023 + 56320
				]
			]
		]
		s: next s
	]
	either length [cnt][result]
]