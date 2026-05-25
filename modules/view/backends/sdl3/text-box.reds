Red/System [
	Title:	"SDL3 text-box placeholders"
	File: 	%text-box.reds
	Tabs: 	4
]

OS-text-box-color: func [dc [handle!] layout [handle!] pos [integer!] len [integer!] color [integer!]][]
OS-text-box-background: func [dc [handle!] layout [handle!] pos [integer!] len [integer!] color [integer!]][]
OS-text-box-weight: func [layout [handle!] pos [integer!] len [integer!] weight [integer!]][]
OS-text-box-italic: func [layout [handle!] pos [integer!] len [integer!]][]
OS-text-box-underline: func [layout [handle!] pos [integer!] len [integer!] opts [red-value!] tail [red-value!]][]
OS-text-box-strikeout: func [layout [handle!] pos [integer!] len [integer!] opts [red-value!] tail [red-value!]][]
OS-text-box-border: func [layout [handle!] pos [integer!] len [integer!] opts [red-value!] tail [red-value!] return: [integer!]][0]
OS-text-box-font-name: func [font [handle!] layout [handle!] pos [integer!] len [integer!] name [red-string!]][]
OS-text-box-font-size: func [font [handle!] layout [handle!] pos [integer!] len [integer!] size [float!]][]

OS-text-box-metrics: func [
	state	[red-block!]
	arg0	[red-value!]
	type	[integer!]
	return: [red-value!]
][
	as red-value! none-value
]

OS-text-box-layout: func [
	box			[red-object!]
	target		[int-ptr!]
	nscolor		[integer!]
	catch?		[logic!]
	return:		[integer!]
][
	0
]

adjust-index: func [
	str		[red-string!]
	offset	[integer!]
	idx		[integer!]
	adjust	[integer!]
	return: [integer!]
	/local
		s		[series!]
		unit	[integer!]
		head	[byte-ptr!]
		tail	[byte-ptr!]
		c		[integer!]
][
	assert TYPE_OF(str) = TYPE_STRING
	s: GET_BUFFER(str)
	unit: GET_UNIT(s)
	if unit = UCS-4 [
		head: (as byte-ptr! s/offset) + (str/head + offset << 2)
		tail: head + (idx * 4)
		while [head < tail][
			c: string/get-char head unit
			if c >= 00010000h [
				idx: idx + adjust
				if adjust < 0 [tail: tail - unit]
			]
			head: head + unit
		]
	]
	idx
]
