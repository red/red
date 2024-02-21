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
	
	upper-table: declare int-ptr!
	lower-table: declare int-ptr!
	
	tbl-size: 64 * 1024 * size? integer!

	init: func [
		/local
			sz [integer!]
			i  [integer!]
			p  [int-ptr!]
	][
		;-- setup fast-lookup tables for 16-bit codepoints
		upper-table: as int-ptr! allocate tbl-size
		set-memory as byte-ptr! upper-table null-byte tbl-size
		p: uppercase-table-low
		sz: (size? uppercase-table-low) / 2
		loop sz [
			i: p/1
			upper-table/i: p/2
			p: p + 2 
		]
		
		lower-table: as int-ptr! allocate tbl-size
		set-memory as byte-ptr! lower-table null-byte tbl-size
		p: lowercase-table-low
		sz: (size? lowercase-table-low) / 2
		loop sz [
			i: p/1
			lower-table/i: p/2
			p: p + 2 
		]
	]

	change-char: func [
		cp		[integer!]
		upper?	[logic!]
		return: [integer!]
		/local
			c sz end [integer!]
			table [int-ptr!]
	][
		either cp <= FFFFh [
			table: either upper? [upper-table][lower-table]
			c: table/cp
			either zero? c [cp][c]
		][
			table: either upper? [
				sz: size? uppercase-table-high
				uppercase-table-high
			][
				sz: size? lowercase-table-high
				lowercase-table-high
			]
			end: sz - 1
			unless any [cp < table/1 cp > table/sz][
				c: -1
				until [
					c: c + 2
					if table/c > cp [return cp]
					if table/c = cp [c: c + 1 return table/c]
					c = end
				]
			]
			cp
		]
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
