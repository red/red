Red/System [
	Title:   "Redbin format encoder and decoder for Red runtime"
	Author:  "Qingtian Xie"
	File: 	 %redbin.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic & Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define REDBIN_COMPACT_MASK			01h
#define REDBIN_COMPRESSED_MASK		02h
#define REDBIN_SYMBOL_TABLE_MASK	04h

#define REDBIN_VALUES_MASK			40000000h
#define REDBIN_STACK_MASK			20000000h
#define REDBIN_SELF_MASK			10000000h
#define REDBIN_SET_MASK				08000000h

redbin: context [
	verbose: 0
	
	#enum redbin-value-type! [
		REDBIN_PADDING: 	0
		REDBIN_REFERENCE: 	255
	]
	
	buffer:		 as byte-ptr! 0
	root-base:	 as red-value! 0
	root-offset: 0
	
	preprocess-symbols: func [
		base 	[int-ptr!]
		/local
			syms	[int-ptr!]
			end		[int-ptr!]
			strings [c-string!]
	][
		syms:	 base + 2
		end:	 syms + base/value
		strings: as-c-string end
		
		while [syms < end][
			syms/1: symbol/make strings + syms/1
			syms: syms + 1
		]
	]
	
	decode-native: func [
		data	[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			cell  [red-native!]
			spec  [red-block!]
			s	  [series!]
			sym	  [int-ptr!]
			type  [integer!]
			index [integer!]
	][
		type:  data/1 and FFh
		index: data/2
		cell:  as red-native! ALLOC_TAIL(parent)
		data:  data + 2
		
		either type = TYPE_OP [
			sym: table + index
			copy-cell
				as red-value! op/make null as red-block! _context/get-global sym/1 TYPE_OP
				as red-value! cell
		][
			spec: as red-block! block/rs-tail parent
			data: decode-block data table parent off

			cell/header: type								;-- implicit reset of all header flags
			if nl? [cell/header: cell/header or flag-new-line]
			cell/spec:	 spec/node
			cell/args:	 null
			either type = TYPE_ACTION [
				cell/code: actions/table/index
			][
				cell/code: natives/table/index
			]
		]
		data
	]
	
	decode-map: func [
		data	[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			blk  [red-block!]
			cell [cell!]
			size [integer!]
			sz   [integer!]
	][
		size: data/2
		sz: size
		if zero? sz [sz: 1]
		#if debug? = yes [if verbose > 0 [print [#":" size #":"]]]

		blk: block/make-at as red-block! ALLOC_TAIL(parent) sz
		data: data + 2
		while [size > 0][
			data: decode-value data table blk
			size: size - 1
		]
		cell: as cell! map/make-at as red-value! blk blk sz
		if nl? [cell/header: cell/header or flag-new-line]
		data
	]
	
	decode-context: func [
		data	[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		return: [int-ptr!]
		/local
			ctx		[red-context!]
			slot	[red-word!]
			obj		[red-object!]
			values	[int-ptr!]
			sym		[int-ptr!]
			header	[integer!]
			values? [logic!]
			stack?	[logic!]
			self?	[logic!]
			slots	[integer!]
			new		[node!]
			symbols	[node!]
			s		[series!]
			i		[integer!]
	][
		header:  data/1
		values?: header and REDBIN_VALUES_MASK <> 0 
		stack?:	 header and REDBIN_STACK_MASK  <> 0 
		self?:	 header and REDBIN_SELF_MASK   <> 0 
		slots:	 data/2

		if values? [values: data + 2 + slots]
		
		new: _context/create slots stack? self?
		obj: as red-object! ALLOC_TAIL(parent)			;-- use an object to store the ctx node
		obj/header: TYPE_OBJECT
		obj/ctx:	new
		obj/class:	-1
		obj/on-set: null
		
		s: as series! new/value
		copy-cell as red-value! obj s/offset + 1		;-- set back-reference
		
		ctx: TO_CTX(new)
		symbols: ctx/symbols
		data: data + 2
		i: 0

		while [slots > 0][
			sym: table + data/1
			;-- create the words entries in the symbol table of the context
			slot: 		 as red-word! alloc-tail as series! symbols/value
			slot/header: TYPE_WORD
			slot/ctx: 	 new
			slot/symbol: sym/1
			slot/index:  i
			
			i: i + 1
			data: data + 1
			slots: slots - 1
		]
		data
	]
	
	decode-issue: func [
		data	[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			w	[red-word!]
			sym	[int-ptr!]
	][
		sym: table + data/2
		w: as red-word! ALLOC_TAIL(parent)
		w/header: TYPE_ISSUE
		if nl? [w/header: w/header or flag-new-line]
		w/symbol: sym/1
		data + 2
	]
	
	decode-word: func [
		data	[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			new	   [red-word!]
			w	   [red-word!]
			obj	   [red-object!]
			sym	   [int-ptr!]
			offset [integer!]
			ctx	   [node!]
			set?   [logic!]
			s	   [series!]
	][
		sym: table + data/2								;-- get the decoded symbol
		new: as red-word! ALLOC_TAIL(parent)
		new/header: data/1 and FFh
		if nl? [new/header: new/header or flag-new-line]
		new/symbol: sym/1
		set?: data/1 and REDBIN_SET_MASK <> 0
		
		offset: data/3
		either offset = -1 [
			new/ctx: global-ctx
			w: _context/add-global-word sym/1 yes no
			new/index: w/index
		][
			obj: as red-object! block/rs-abs-at root offset + root-offset
			assert TYPE_OF(obj) = TYPE_OBJECT
			ctx: obj/ctx
			new/ctx: ctx
			either data/4 = -1 [
				new/index: _context/find-word TO_CTX(ctx) sym/1 yes
			][
				new/index: data/4
			]
		]
		data: data + 4
		
		if set? [
			offset: block/rs-length? parent
			data: decode-value data table parent
			_context/set new block/rs-abs-at root offset
			s: GET_BUFFER(parent)
			offset: offset - 1
			s/tail: s/offset + offset					;-- drop unwanted values in parent
		]
		data
	]
	
	decode-string: func [
		data	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local str header unit size s
	][
		header: data/1
		unit: header >>> 8 and FFh
		size: data/3 << (log-b unit)					;-- optimized data/3 * unit

		str: as red-string! ALLOC_TAIL(parent)
		str/header: header and FFh						;-- implicit reset of all header flags
		if nl? [str/header: str/header or flag-new-line]
		str/head: 	data/2
		str/node: 	alloc-bytes size
		
		data: data + 3
		s: GET_BUFFER(str)
		copy-memory as byte-ptr! s/offset as byte-ptr! data size
		
		s/flags: s/flags and flag-unit-mask or unit
		s/tail: as cell! (as byte-ptr! s/offset) + size
		
		data: as int-ptr! ((as byte-ptr! data) + size)
		either (as-integer data) and 3 = 0 [data][
			as int-ptr! ((as-integer data) + 4 and -4) ;-- align to upper 32-bit boundary
		]
	]

	decode-block: func [
		data	[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			blk  [red-block!]
			size [integer!]
			sz   [integer!]
	][
		size: data/3
		sz: size
		if zero? sz [sz: 1]
		#if debug? = yes [if verbose > 0 [print [#":" size #":"]]]
		
		blk: block/make-in parent sz
		blk/head: data/2
		blk/header: data/1 and FFh
		if nl? [blk/header: blk/header or flag-new-line]
		data: data + 3
		
		while [size > 0][
			data: decode-value data table blk
			size: size - 1
		]
		data
	]

	decode-tuple: func [
		data	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			tuple [red-tuple!]
			size  [integer!]
	][
		size: data/1 >>> 8 and FFh
		tuple: as red-tuple! ALLOC_TAIL(parent)
		tuple/header: TYPE_TUPLE or (size << 19)
		if nl? [tuple/header: tuple/header or flag-new-line]
		tuple/array1: data/2
		tuple/array2: data/3
		tuple/array3: data/4
		data + 4
	]

	decode-value: func [
		data	[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		return: [int-ptr!]
		/local 
			type [integer!]
			cell [cell!]
			nl?	 [logic!]
	][
		type: data/1 and FFh
		nl?:  data/1 and 80000000h <> 0
		#if debug? = yes [if verbose > 0 [print [#"<" type #">"]]]
		
		cell: null
		data: switch type [
			TYPE_WORD
			TYPE_SET_WORD
			TYPE_LIT_WORD
			TYPE_GET_WORD
			TYPE_REFINEMENT [decode-word data table parent nl?]
			TYPE_STRING
			TYPE_FILE
			TYPE_URL
			TYPE_TAG
			TYPE_EMAIL
			TYPE_BINARY		[decode-string data parent nl?]
			TYPE_INTEGER	[
				cell: as cell! integer/make-in parent data/2
				data + 2
			]
			TYPE_PATH
			TYPE_LIT_PATH
			TYPE_SET_PATH
			TYPE_GET_PATH
			TYPE_BLOCK
			TYPE_PAREN		[decode-block data table parent nl?]
			TYPE_CONTEXT	[decode-context data table parent]
			TYPE_ISSUE		[decode-issue data table parent nl?]
			TYPE_TYPESET	[
				cell: as cell! typeset/make-in parent data/2 data/3 data/4
				data + 4
			]
			TYPE_FLOAT	[
				cell: as cell! float/make-in parent data/2 data/3
				data + 3
			]
			TYPE_PERCENT [
				cell: as cell! percent/make-in parent data/2 data/3
				data + 3
			]
			TYPE_TIME	[
				cell: as cell! time/make-in parent data/2 data/3
				data + 3
			]
			TYPE_CHAR		[
				cell: as cell! char/make-in parent data/2
				data + 2
			]
			TYPE_DATATYPE	[
				cell: as cell! datatype/make-in parent data/2
				data + 2
			]
			TYPE_PAIR	[
				cell: as cell! pair/make-in parent data/2 data/3
				data + 3
			]
			TYPE_UNSET		[
				cell: as cell! unset/make-in parent
				data + 1
			]
			TYPE_NONE		[
				cell: as cell! none/make-in parent
				data + 1
			]
			TYPE_LOGIC		[
				cell: as cell! logic/make-in parent as logic! data/2
				data + 2
			]
			TYPE_MAP		[decode-map data table parent nl?]
			TYPE_NATIVE
			TYPE_ACTION
			TYPE_OP			[decode-native data table parent nl?]
			TYPE_TUPLE		[decode-tuple data parent nl?]
			REDBIN_PADDING	[
				decode-value data + 1 table parent
			]
			TYPE_FUNCTION
			TYPE_BITSET
			TYPE_POINT
			TYPE_OBJECT
			TYPE_ERROR
			TYPE_VECTOR
			REDBIN_REFERENCE [
				--NOT_IMPLEMENTED--
				data
			]
		]
		if all [nl? cell <> null][cell/header: cell/header or flag-new-line]
		data
	]

	decode: func [
		data	[byte-ptr!]
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
			len			[integer!]
			count		[integer!]
			i			[integer!]
			s			[series!]
			not-set?	[logic!]
	][
		;----------------
		;-- decode header
		;----------------
		p: data
		unless all [					;-- magic="REDBIN"
			p/1 = #"R" p/2 = #"E" p/3 = #"D"
			p/4 = #"B" p/5 = #"I" p/6 = #"N"
		][
			print-line "Error: Not a Redbin file!"
			halt
		]
		p: p + 7						;-- skip magic(6 bytes) + version(1 byte)
		compact?:	 (as-integer p/1) and REDBIN_COMPACT_MASK <> 0
		compressed?: (as-integer p/1) and REDBIN_COMPRESSED_MASK <> 0
		sym-table?:  (as-integer p/1) and REDBIN_SYMBOL_TABLE_MASK <> 0
		p: p + 1
		
		if compressed? [p: crush/decompress p null]

		p4: as int-ptr! p

		count: p4/1						;-- read records number
		len: p4/2						;-- read records size in bytes
		p4: p4 + 2						;-- skip both fields
		p: as byte-ptr! p4
		
		;----------------
		;-- get symbol table if we have it.
		;----------------
		table: null
		if sym-table? [
			preprocess-symbols p4
			table: p4 + 2
			p: p + 8 + (p4/1 * 4 + p4/2)
		]

		;----------------
		;-- decode values
		;----------------
		s: GET_BUFFER(parent)
		root-offset: (as-integer s/tail - s/offset) >> 4
		
		end: p + len
		#if debug? = yes [if verbose > 0 [i: 0]]
		
		while [p < end][
			#if debug? = yes [
				p4: as int-ptr! p
				not-set?: p4/1 and REDBIN_SET_MASK = 0
				if verbose > 0 [print [i #":"]]
			]
			p: as byte-ptr! decode-value as int-ptr! p table parent
			#if debug? = yes [if verbose > 0 [if not-set? [i: i + 1] print lf]]
		]
		
		root-base: (block/rs-head parent) + root-offset
		root-base
	]
	
	boot-load: func [payload [byte-ptr!] keep? [logic!] return: [red-value!] /local saved ret][
		if keep? [saved: root-base]
		ret: decode payload root
		if keep? [root-base: saved]
		ret
	]
]