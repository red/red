Red/System []

#enum TYPE-STRING-ENCODING! [
	TYPE-STRING-UTF8
	TYPE-STRING-UNICODE
]

type-string!: alias struct! [
	type	[integer!]
]

type-string: context [

	;-- two byte unicode to utf8
	to-utf8: func [
		code	[byte-ptr!]
		utf8	[byte-ptr!]
		len		[int-ptr!]
		return:	[logic!]
		/local
			end		[byte-ptr!]
			temp	[integer!]
			pb		[byte-ptr!]
			unit	[integer!]
			c		[integer!]
	][
		unless null? utf8 [
			end: utf8 + len/1
		]
		len/1: 0
		temp: 0
		pb: as byte-ptr! :temp
		forever [
			unit: (as integer! code/2) << 8
			unit: unit + as integer! code/1
			if unit = 0 [break]
			c: unicode/cp-to-utf8 unit pb
			if c = 0 [return false]
			unless null? utf8 [
				either utf8 + c < end [
					copy-memory utf8 pb c
					utf8: utf8 + c
				][return false]
			]
			code: code + 2
			len/1: len/1 + c
		]
		unless null? utf8 [
			utf8/1: #"^(00)"
		]
		len/1: len/1 + 1
		true
	]

	unicode-length?: func [
		code	[byte-ptr!]
		return:	[integer!]
		/local
			unit	[integer!]
			count	[integer!]
	][
		count: 0
		forever [
			unit: (as integer! code/2) << 8
			unit: unit + as integer! code/1
			count: count + 1
			if unit = 0 [break]
			code: code + 2
		]
		count
	]

	to-unicode: func [
		utf8	[byte-ptr!]
		code	[byte-ptr!]
		len		[int-ptr!]
		return:	[logic!]
		/local
			end		[byte-ptr!]
			temp	[integer!]
			low		[integer!]
			high	[integer!]
	][
		unless null? code [
			end: code + len/1
		]
		len/1: 0
		temp: 0
		forever [
			utf8: unicode/fast-decode-utf8-char utf8 :temp
			if temp = 0 [break]
			if temp = -1 [return false]
			low: temp and FFFFh
			high: temp >>> 16
			unless null? code [
				either code + 2 < end [
					code/1: as byte! low and FFh
					code/2: as byte! low >>> 8 and FFh
					code: code + 2
				][return false]
				if high <> 0 [
					either code + 2 < end [
						code/1: as byte! high and FFh
						code/2: as byte! high >>> 8 and FFh
						code: code + 2
					][return false]
				]
			]
			either high = 0 [
				len/1: len/1 + 2
			][
				len/1: len/1 + 4
			]
		]
		unless null? code [
			either code + 2 <= end [
				code/1: #"^(00)"
				code/2: #"^(00)"
			][return false]
		]
		len/1: len/1 + 2
		true
	]

	load-utf8: func [
		utf8		[byte-ptr!]
		return:		[type-string!]
		/local
			len		[integer!]
			buf		[int-ptr!]
			data	[byte-ptr!]
	][
		if null? utf8 [return null]
		len: 1 + length? as c-string! utf8
		buf: as int-ptr! allocate 4 + len
		buf/1: TYPE-STRING-UTF8
		data: as byte-ptr! buf + 1
		copy-memory data utf8 len
		as type-string! buf
	]

	load-unicode: func [
		code		[byte-ptr!]
		return:		[type-string!]
		/local
			len		[integer!]
			buf		[int-ptr!]
			data	[byte-ptr!]
	][
		if null? code [return null]
		len: 2 * unicode-length? code
		buf: as int-ptr! allocate 4 + len
		buf/1: TYPE-STRING-UNICODE
		data: as byte-ptr! buf + 1
		copy-memory data code len
		as type-string! buf
	]

	release: func [
		str			[type-string!]
	][
		if null? str [exit]
		free as byte-ptr! str
	]

#either OS = 'Windows [
	uprint: func [
		str			[type-string!]
		/local
			buf		[int-ptr!]
			p		[byte-ptr!]
			len		[integer!]
			code	[byte-ptr!]
	][
		if null? str [print "null" exit]

		if str/type = TYPE-STRING-UNICODE [
			buf: as int-ptr! str
			p: as byte-ptr! buf + 1
			platform/print-UCS2 p 2 * platform/lstrlen p
			exit
		]
		if str/type = TYPE-STRING-UTF8 [
			buf: as int-ptr! str
			p: as byte-ptr! buf + 1
			len: 0
			unless to-unicode p null :len [
				print "null" exit
			]
			code: allocate len
			to-unicode p code :len
			platform/print-UCS2 code len - 2
			free code
			exit
		]
	]
][
	uprint: func [
		str			[type-string!]
		/local
			buf		[int-ptr!]
			p		[byte-ptr!]
			len		[integer!]
			utf8	[byte-ptr!]
	][
		if null? str [print "null" exit]

		if str/type = TYPE-STRING-UTF8 [
			buf: as int-ptr! str
			p: as byte-ptr! buf + 1
			print-line as c-string! p
			exit
		]
		if str/type = TYPE-STRING-UNICODE [
			buf: as int-ptr! str
			p: as byte-ptr! buf + 1
			len: 0
			unless to-utf8 p null :len [
				print "null" exit
			]
			utf8: allocate len
			to-utf8 p utf8 :len
			print-line as c-string! utf8
			free utf8
			exit
		]
	]
]]
