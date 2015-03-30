Red/System [
	Title:   "Redbin format encoder and decoder for Red runtime"
	Author:  "Qingtian Xie"
	File: 	 %redbin.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic & Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define redbin-compact-mask			01h
#define redbin-compressed-mask		02h
#define redbin-symbol-table-mask	04h

redbin: context [

	#enum redbin-value-type! [
		REDBIN_PADDING
		REDBIN_DATATYPE
		REDBIN_UNSET
		REDBIN_NONE
		REDBIN_LOGIC
		REDBIN_BLOCK
		REDBIN_PAREN
		REDBIN_STRING
		REDBIN_FILE
		REDBIN_URL
		REDBIN_CHAR
		REDBIN_INTEGER
		REDBIN_FLOAT
		REDBIN_CONTEXT
		REDBIN_WORD
		REDBIN_SET_WORD
		REDBIN_LIT-WORD
		REDBIN_GET-WORD
		REDBIN_REFINEMENT
		REDBIN_ISSUE
		REDBIN_NATIVE
		REDBIN_ACTION
		REDBIN_OP
		REDBIN_FUNCTION
		REDBIN_PATH
		REDBIN_LIT-PATH
		REDBIN_SET-PATH
		REDBIN_GET-PATH
		REDBIN_BITSET
		REDBIN_POINT
		REDBIN_OBJECT
		REDBIN_TYPESET
		REDBIN_ERROR
		REDBIN_VECTOR
		REDBIN_REFERENCE
	]

	decode-string: func [
		data	[int-ptr!]
		parent	[red-block!]
		return: [int-ptr!]
		/local str header type unit size s
	][
		header: data/1
		type: header and FFh
		unit: header >>> 8 and FFh
		size: data/3 * unit
		type: switch type [
			REDBIN_STRING	[TYPE_STRING]
			REDBIN_FILE		[TYPE_FILE]
			REDBIN_URL		[TYPE_URL]
		]

		str: as red-string! ALLOC_TAIL(parent)
		str/header: type							;-- implicit reset of all header flags
		str/head: 	data/2
		str/node: 	alloc-bytes size + unit			;-- account for NUL
		s: GET_BUFFER(str)
		copy-memory as byte-ptr! s/offset as byte-ptr! data + 3 size
		s/tail: s/tail + size
		string/add-terminal-NUL as byte-ptr! s/tail unit
		data + 3 + size
	]

	decode-block: func [
		data	[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		return: [int-ptr!]
		/local blk size i head type
	][
		type: data/1
		head: data/2
		size: data/3
		blk: block/make-in parent size
		i: 0
		while [i < size][
			data: decode-value data table blk
			i: i + 1
		]
		blk/head: head
		if type = REDBIN_PAREN [blk/header: TYPE_PAREN]
		data
	]

	decode-value: func [
		data	[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		return: [int-ptr!]
		/local type value
	][
		type: data/1 and FFh
		value: ALLOC_TAIL(parent)
		switch type [
			REDBIN_PADDING	[decode-value data + 1 table parent]
			REDBIN_DATATYPE [
				copy-cell as cell! datatype/push data/2 value
				stack/pop 1
				data + 2
			]
			REDBIN_UNSET	[
				copy-cell unset-value value
				data + 1
			]
			REDBIN_NONE		[
				copy-cell none-value value
				data + 1
			]
			REDBIN_LOGIC	[
				copy-cell as cell! logic/push as logic! data/2 value
				stack/pop 1
				data + 2
			]
			REDBIN_BLOCK
			REDBIN_PAREN	[decode-block data table parent]
			REDBIN_STRING
			REDBIN_FILE
			REDBIN_URL		[decode-string data parent]
			REDBIN_CHAR		[
				copy-cell as cell! char/push data/2 value
				stack/pop 1
				data + 2
			]
			REDBIN_INTEGER	[
				copy-cell as cell! integer/push data/2 value
				stack/pop 1
				data + 2
			]
			REDBIN_FLOAT	[
				copy-cell as cell! float/push64 data/2 data/3 value
				stack/pop 1
				data + 3
			]
			REDBIN_CONTEXT
			REDBIN_WORD
			REDBIN_SET_WORD
			REDBIN_LIT-WORD
			REDBIN_GET-WORD
			REDBIN_REFINEMENT
			REDBIN_ISSUE
			REDBIN_NATIVE
			REDBIN_ACTION
			REDBIN_OP
			REDBIN_FUNCTION
			REDBIN_PATH
			REDBIN_LIT-PATH
			REDBIN_SET-PATH
			REDBIN_GET-PATH
			REDBIN_BITSET
			REDBIN_POINT
			REDBIN_OBJECT
			REDBIN_TYPESET
			REDBIN_ERROR
			REDBIN_VECTOR
			REDBIN_REFERENCE [
				--NOT_IMPLEMENTED--
				data
			]
		]
	]

	decode: func [
		data	[byte-ptr!]
		len		[integer!]
		parent	[red-block!]
		return: [red-value!]
		/local
			p			[byte-ptr!]
			end			[byte-ptr!]
			p4			[int-ptr!]
			compact?	[logic!]
			compressed? [logic!]
			sym-table?	[logic!]
			table		[int-ptr!]
			base		[red-value!]
	][
		;----------------
		;-- decode header
		;----------------
		p: data
		end: data + len
		unless all [					;-- magic="REBDBIN"
			p/1 = #"R" p/2 = #"E" p/3 = #"D"
			p/4 = #"B" p/5 = #"I" p/6 = #"N"
		][
			print-line "Error: Not a Redbin file!"
			halt
		]
		p: p + 7						;-- skip magic(6 bytes) + version(1 byte)
		compact?:	 (as-integer p/1) and redbin-compact-mask = redbin-compact-mask
		compressed?: (as-integer p/1) and redbin-compressed-mask = redbin-compressed-mask
		sym-table?:  (as-integer p/1) and redbin-symbol-table-mask = redbin-symbol-table-mask
		p: p + 1

		;----------------
		;-- get symbol table if we have it.
		;----------------
		table: null
		if sym-table? [
			p4: as int-ptr! p
			table: p4 + 2
			p: p + 8 + (p4/1 * 4 + p4/2)
		]

		;----------------
		;-- decode values
		;----------------
		s: GET_BUFFER(parent)
		base: s/tail
		while [p < end][
			p: as byte-ptr! decode-value as int-ptr! p table parent
		]
		base
	]
]