Red/System [
	Title:   "Description"
	Author:  "Qingtian Xie"
	File: 	 %case-folding.reds
	Type:	 'library
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#include %case-folding-table.reds

case-folding: context [

	upper-to-lower: declare red-vector!
	lower-to-upper: declare red-vector!

	compare-integer: func [								;-- Compare function return integer!
		p1		 [int-ptr!]
		p2		 [int-ptr!]
		op		 [integer!]
		flags	 [integer!]
		return:  [integer!]
	][
		p1/value - p2/value
	]

	init: func [
		/local
			size  [integer!]
			sz	  [integer!]
			s	  [series!]
			a	  [integer!]
			b	  [integer!]
			table [int-ptr!]
	][
		size: size? to-lowercase-table
		sz: size * (size? integer!)
		;-- make upper-to-lower vector!
		vector/make-at
			as red-value! upper-to-lower
			size
			TYPE_CHAR
			size? integer!
		s: GET_BUFFER(upper-to-lower)
		copy-memory
			as byte-ptr! s/offset
			as byte-ptr! to-lowercase-table
			sz
		s/tail: as cell! ((as byte-ptr! s/offset) + sz)

		size: size? to-uppercase-table
		sz: size * (size? integer!)
		;-- make lower-to-upper vector!
		vector/make-at
			as red-value! lower-to-upper
			size
			TYPE_CHAR
			size? integer!
		s: GET_BUFFER(lower-to-upper)
		copy-memory
			as byte-ptr! s/offset
			as byte-ptr! to-uppercase-table
			sz
		s/tail: as cell! ((as byte-ptr! s/offset) + sz)
	]

	change-char: func [
		cp		[integer!]
		upper?	[logic!]
		return: [integer!]
		/local
			c	  [integer!]
			last  [integer!]
			end   [integer!]
			table [int-ptr!]
			vec   [red-vector!]
			s	  [series!]
	][
		vec: either upper? [lower-to-upper][upper-to-lower]
		s: GET_BUFFER(vec)
		table: as int-ptr! s/offset

		last: vector/rs-length? vec
		end: last - 1
		unless any [cp < table/1 cp > table/last][
			c: -1
			until [
				c: c + 2
				if table/c > cp [return cp]
				if table/c = cp [
					c: c + 1
					return table/c
				]
				c = end
			]
		]
		cp
	]

	change: func [
		arg		[red-value!]
		part	[integer!]
		upper?	[logic!]
		return: [red-value!]
		/local
			limit [red-value!]
			int   [red-integer!]
			char  [red-char!]
			str	  [red-string!]
			str2  [red-string!]
			w	  [red-word!]
			unit  [integer!]
			unit2 [integer!]
			s	  [series!]
			p	  [byte-ptr!]
			p4	  [int-ptr!]
			cp	  [integer!]
			len   [integer!]
			i	  [integer!]
	][
		either TYPE_OF(arg) = TYPE_CHAR [
			char: as red-char! arg
			char/value: change-char char/value upper?
		][
			str: as red-string! arg
			s: GET_BUFFER(str)
			unit: GET_UNIT(s)
			p: (as byte-ptr! s/offset) + (str/head << (log-b unit))
			len: (as-integer s/tail - (as red-value! p)) >> (log-b unit)
			if positive? part [ 
				limit: arg + part
				len: either TYPE_OF(limit) = TYPE_INTEGER [
					int: as red-integer! limit
					int/value
				][
					str2: as red-string! limit
					unless all [
						TYPE_OF(str2) = TYPE_OF(str)		;-- handles ANY-STRING!
						str2/node = str/node
					][
						ERR_INVALID_REFINEMENT_ARG(refinements/_part limit)
					]
					str2/head - str/head
				]
				if negative? len [len: 0]
			]

			i: 0
			while [i < len][
				cp: switch unit [
					Latin1 [as-integer p/value]
					UCS-2  [(as-integer p/2) << 8 + p/1]
					UCS-4  [p4: as int-ptr! p p4/value]
				]
				s: string/poke-char s p change-char cp upper?
				unit2: GET_UNIT(s)
				if unit2 > unit [
					unit: unit2
					p: (as byte-ptr! s/offset) + (str/head + i << (log-b unit))
				]
				i: i + 1
				p: p + unit
			]
			w: either upper? [words/_uppercase][words/_lowercase]
			ownership/check as red-value! str w null str/head len
		]
		arg
	]
]
