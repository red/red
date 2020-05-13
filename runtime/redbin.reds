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

#define REDBIN_NEWLINE_MASK			80000000h
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
	codec?:      no
	
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
			if codec? [parent: block/push-only* 1]	;-- redirect slot allocation
			
			spec: as red-block! block/rs-tail parent
			data: decode-block data table parent off

			cell/header: type						;-- implicit reset of all header flags
			if nl? [cell/header: cell/header or flag-new-line]
			cell/spec:	 spec/node
			cell/args:	 null
			either type = TYPE_ACTION [
				cell/code: actions/table/index
			][
				cell/code: natives/table/index
			]
			
			if codec? [stack/pop 1]					;-- drop an unwanted block
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
		loop size [data: decode-value data table blk]
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
			obj		[red-object!]
			values  [red-block!]
			value	[int-ptr!]
			sym		[int-ptr!]
			header	[integer!]
			type	[context-type!]
			values? [logic!]
			stack?	[logic!]
			self?	[logic!]
			slots	[integer!]
			new		[node!]
			s		[series!]
			i		[integer!]
	][
		header: data/1
		slots:  data/2
		value:  data + 2 + slots
		
		values?: header and REDBIN_VALUES_MASK <> 0
		stack?:	 header and REDBIN_STACK_MASK  <> 0
		self?:	 header and REDBIN_SELF_MASK   <> 0
		type:	 GET_CTX_TYPE_ALT(header)
		
		new: _context/create slots stack? self? null type
		obj: as red-object! ALLOC_TAIL(parent)			;-- use an object to store the ctx node
		obj/header: TYPE_OBJECT
		obj/ctx:	new
		obj/class:	-1
		obj/on-set: null
		
		s: as series! new/value
		copy-cell as red-value! obj s/offset + 1		;-- set back-reference
		
		ctx: TO_CTX(new)
		unless stack? [
			s: as series! ctx/values/value
			either values? [
				values: block/push-only* slots
				values/node: ctx/values
				s/tail: s/offset						;-- trick decoder into allocating in context's table
			][
				s/tail: s/offset + slots				;-- pre-filled with unset values
			]
		]

		data: data + 2
		i: 0

		loop slots [
			sym: table + data/1
			;-- create the words entries in the symbol table of the context
			_context/find-or-store ctx sym/1 yes new :i
			if all [not stack? values?][value: decode-value value table values]
			data: data + 1
		]
		
		if values? [
			s/tail: s/offset + slots
			stack/pop 1									;-- drop unwanted block
		]
		
		value
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
			either codec? [								;@@ TBD: decode context and bind word to it
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
		]
		data: data + 4
		
		if set? [
			either codec? [
				parent: block/push-only* 1				;-- redirect slot allocation
				data: decode-value data table parent
				_context/set new block/rs-head parent
				stack/pop 1								;-- drop unwanted block
			][
				offset: block/rs-length? parent
				data: decode-value data table parent
				_context/set new block/rs-abs-at root offset
				s: GET_BUFFER(parent)
				offset: offset - 1
				s/tail: s/offset + offset				;-- drop unwanted values in parent
			]
		]
		
		data
	]
	
	decode-string: func [
		data	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			str    [red-string!]
			header [integer!]
			unit   [integer!]
			size   [integer!]
			s      [series!]
	][
		header: data/1
		unit: header >>> 8 and FFh
		size: data/3 << log-b unit						;-- optimized data/3 * unit

		str: as red-string! ALLOC_TAIL(parent)
		if nl? [str/header: str/header or flag-new-line]
		str/header: TYPE_UNSET
		str/head: 	data/2
		str/node: 	alloc-bytes size
		str/cache:	null
		str/header: header and FFh						;-- implicit reset of all header flags
		
		data: data + 3
		s: GET_BUFFER(str)
		copy-memory as byte-ptr! s/offset as byte-ptr! data size
		
		s/flags: s/flags and flag-unit-mask or unit
		s/tail: as cell! (as byte-ptr! s/offset) + size
		
		as int-ptr! align (as byte-ptr! data) + size 32	;-- align at upper 32-bit boundary
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
		
		loop size [data: decode-value data table blk]
		
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
	
	decode-money: func [
		data	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			slot [red-money!]
			cur	 [byte-ptr!]
			neg? [logic!]
	][
		neg?: data/1 and 4000h <> 0
		cur: as byte-ptr! data + 1
		slot: money/make-in ALLOC_TAIL(parent) neg? as-integer cur/1 cur + 1
		if nl? [slot/header: slot/header or flag-new-line]
		data + 4
	]
	
	decode-bitset: func [
		data    [int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			slot [red-value!]
			bits [byte-ptr!]
			size [integer!]
	][
		size: data/2 >> 3							;-- in bytes
		bits: as byte-ptr! data + 2
		
		slot: as red-value! binary/load-in bits size parent
		if nl? [slot/header: slot/header or flag-new-line]
		set-type slot TYPE_BITSET
		
		as int-ptr! align bits + size 32			;-- align at upper 32-bit boundary
	]
	
	decode-vector: func [
		data    [int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			slot    [red-value!]
			_vector [red-vector!]
			buffer  [series!]
			values  [byte-ptr!]
			unit    [integer!]
			size    [integer!]
	][
		unit: data/1 >>> 8 and FFh
		size: data/3 << log-b unit					;-- in bytes
		
		slot: ALLOC_TAIL(parent)
		if nl? [slot/header: slot/header or flag-new-line]
		
		_vector: vector/make-at slot data/3 data/4 unit
		buffer: GET_BUFFER(_vector)
		_vector/head: data/2
		buffer/tail: as red-value! (as byte-ptr! buffer/offset) + size
		
		values: as byte-ptr! data + 4
		copy-memory as byte-ptr! buffer/offset values size
		
		as int-ptr! align values + size 32			;-- align at upper 32-bit boundary
	]
	
	decode-image: func [
		data    [int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			slot   [red-image!]
			rgb    [byte-ptr!]
			alpha  [byte-ptr!]
			width  [integer!]
			height [integer!]
			length [integer!]
	][
		width:  IMAGE_WIDTH(data/3)
		height: IMAGE_HEIGHT(data/3)
		length: width * height						;-- in pixels
		
		rgb:   as byte-ptr! data + 3
		alpha: rgb + (length * 3)
		
		slot: as red-image! ALLOC_TAIL(parent)
		slot/node: OS-image/make-image width height rgb alpha null	;-- null if image is empty
		slot/head: data/2
		slot/size: data/3
		slot/header: TYPE_IMAGE						;-- implicit reset of all header flags
		if nl? [slot/header: slot/header or flag-new-line]
		
		as int-ptr! rgb + (length << 2)
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
		nl?:  data/1 and REDBIN_NEWLINE_MASK <> 0
		#if debug? = yes [if verbose > 0 [print [#"<" type #">"]]]
		
		cell: null
		data: switch type [
			TYPE_ANY_WORD
			TYPE_REFINEMENT [decode-word data table parent nl?]
			TYPE_ANY_STRING
			TYPE_BINARY		[decode-string data parent nl?]
			TYPE_INTEGER	[
				cell: as cell! integer/make-in parent data/2
				data + 2
			]
			TYPE_ANY_BLOCK  [decode-block data table parent nl?]
			TYPE_CONTEXT	[decode-context data table parent]
			TYPE_ISSUE		[decode-issue data table parent nl?]
			TYPE_TYPESET	[
				cell: as cell! typeset/make-in parent data/2 data/3 data/4
				data + 4
			]
			TYPE_FLOAT		[
				cell: as cell! float/make-in parent data/2 data/3
				data + 3
			]
			TYPE_PERCENT 	[
				cell: as cell! percent/make-in parent data/2 data/3
				data + 3
			]
			TYPE_TIME		[
				cell: as cell! time/make-in parent data/2 data/3
				data + 3
			]
			TYPE_DATE		[
				cell: as cell! date/make-in parent data/2 data/3 data/4
				data + 4
			]
			TYPE_CHAR		[
				cell: as cell! char/make-in parent data/2
				data + 2
			]
			TYPE_DATATYPE	[
				cell: as cell! datatype/make-in parent data/2
				data + 2
			]
			TYPE_PAIR		[
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
			TYPE_MONEY		[decode-money data parent nl?]
			TYPE_BITSET     [decode-bitset data parent nl?]
			TYPE_VECTOR     [decode-vector data parent nl?]
			TYPE_IMAGE		[decode-image data parent nl?]
			REDBIN_PADDING	[
				decode-value data + 1 table parent
			]
			TYPE_PORT
			TYPE_OBJECT
			TYPE_ERROR
			TYPE_FUNCTION
			TYPE_ROUTINE
			TYPE_HANDLE
			TYPE_EVENT
			TYPE_POINT
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
		codec?  [logic!]							;-- YES: called by Redbin codec
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
			;@@ TBD: proper error message for runtime codec
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
		unless codec? [
			s: GET_BUFFER(parent)
			root-offset: (as-integer s/tail - s/offset) >> 4
		]
		
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
		
		unless codec? [root-base: (block/rs-head parent) + root-offset]
		root-base
	]
	
	;@@ TBD: temporal definitions
	#define REDBIN_EMIT  [REDBIN_EMIT* as byte-ptr!]
	#define REDBIN_EMIT* [binary/rs-append payload]
	
	header: #{
		52454442494E								;-- REDBIN magic
		01											;-- version
		00											;-- placeholder for flags
		00000000									;-- placeholder for length
		00000000									;-- placeholder for size
	}
	
	pad: func [
		buffer [red-binary!]
		size   [integer!]
		/local
			length  [integer!]
			residue [integer!]
			zero    [integer!]
	][
		size:    size >> 3
		length:  binary/rs-length? buffer
		residue: length // size
		zero:    0
		unless zero? residue [						;@@ TBD: optimize
			loop size - residue [binary/rs-append buffer as byte-ptr! :zero 1]
		]
	]
	
	align: func [
		address [byte-ptr!]
		bits    [integer!]
		return: [byte-ptr!]
		/local
			delta [integer!]
	][
		delta: bits >> 3 - 1
		as byte-ptr! (as integer! address) + delta and not delta
	]
	
	emit: func [
		buffer [red-binary!]
		data   [byte-ptr!]
		size   [integer!]
	][
		binary/rs-append buffer data size
	]
	
	store: func [
		buffer [red-binary!]
		data   [integer!]
	][
		emit buffer as byte-ptr! :data size? data
	]
	
	record: func [
		[variadic]
		count [integer!]
		list  [int-ptr!]
		/local
			payload [red-binary!]
	][
		payload: as red-binary! list/1
		list: list + 1
		loop count - 1 [
			store payload list/1
			list: list + 1
		]
	]
	
	encode-value: func [
		data    [red-value!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		return: [integer!]
		/local
			type length flags [integer!]
	][
		length: 1									;-- at least 1 value is encoded
		
		;@@ TBD: properly emit header with all the flags
		type: TYPE_OF(data)
		
		switch type [
			TYPE_UNSET
			TYPE_NONE [
				store payload type
			]
			TYPE_DATATYPE
			TYPE_LOGIC [
				record [payload type data/data1]
			]
			TYPE_INTEGER
			TYPE_CHAR [
				record [payload type data/data2]
			]
			TYPE_PERCENT
			TYPE_TIME
			TYPE_FLOAT [
				pad payload 64
				record [payload data/data3 data/data2]
			]
			TYPE_PAIR [
				record [payload type data/data2 data/data3]
			]
			TYPE_TYPESET [
				record [payload type data/data1 data/data2 data/data3]
			]
			TYPE_DATE [
				record [payload type data/data1 data/data3 data/data2]
			]
			TYPE_TUPLE [
				flags: type or (TUPLE_SIZE?(data) << 8)
				record [payload flags data/data1 data/data2 data/data3]
			]
			TYPE_MONEY [
				flags: type or ((money/get-sign as red-money! data) << 14)
				record [payload flags data/data1 data/data2 data/data3]
			]
			TYPE_NATIVE
			TYPE_ACTION [
				encode-native data type payload symbols table strings
			]
			TYPE_ANY_WORD
			TYPE_REFINEMENT
			TYPE_ISSUE [
				encode-word data type payload symbols table strings
			]
			default [								;-- indirect values
				switch type [
					TYPE_ANY_STRING
					TYPE_VECTOR
					TYPE_BINARY [
						encode-string data type payload
					]
					TYPE_ANY_BLOCK 
					TYPE_MAP [
						encode-block data type no payload symbols table strings
					]
					TYPE_BITSET [
						encode-bitset data payload
					]
					TYPE_IMAGE [
						encode-image data payload
					]
					default [--NOT_IMPLEMENTED--]	;@@ TBD: proper error message
				]
			]
		]
		
		length
	]
	
	encode-bitset: func [
		data    [red-value!]
		payload [red-binary!]
		/local
			bits   [red-bitset!]
			length [integer!]
			type   [integer!]
	][
		bits:   as red-bitset! data
		length: bitset/length? bits
		type:   TYPE_BITSET
		
		record [payload type length]
		emit payload bitset/rs-head bits length >> 3
		pad payload 32
	]
	
	encode-native: func [
		data    [red-value!]
		type    [datatypes!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			here  [int-ptr!]
			index [integer!]
	][
		here: either type = TYPE_NATIVE [natives/table][actions/table]
		index: 0
		until [index: index + 1 data/data3 = here/index]
		
		record [payload type index]
		encode-block data TYPE_BLOCK yes payload symbols table strings
	]
	
	encode-word: func [
		data    [red-value!]
		type    [datatypes!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			symbol  [integer!]
			context [integer!]
	][
		symbol:  encode-symbol data table symbols strings
		context: encode-context as node! data/data1 payload symbols table strings
		
		record [payload type symbol]
		unless type = TYPE_ISSUE [record [payload context data/data3]]
	]
	
	encode-context: func [
		node    [node!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		return: [integer!]
		/local
			context              [red-context!]
			value                [red-value!]
			values words         [series!]
			header length offset [integer!]
			kind                 [integer!]
			stack? self? values? [logic!]
	][
		if node = global-ctx [return -1]
		
		context: TO_CTX(node)
		kind:    GET_CTX_TYPE(context)
		stack?:  ON_STACK?(context)
		self?:   context/header and flag-self-mask <> 0
		values?: no
		
		header: TYPE_CONTEXT or (kind << 11)
		if stack? [header: header or REDBIN_STACK_MASK]
		if self?  [header: header or REDBIN_SELF_MASK]
		
		values: as series! context/values/value
		words:  _hashtable/get-ctx-words context
		length: (as integer! values/tail - values/offset) >> 4
		offset: binary/rs-length? payload			;@@ TBD: reference to function/object instead
		
		value: as red-value! values + 1
		loop length [
			values?: TYPE_OF(value) <> TYPE_UNSET
			if values? [header: header or REDBIN_VALUES_MASK break]
			value: value + 1
		]
		
		record [payload header length]
		
		value: as red-value! words + 1
		loop length [
			store payload encode-symbol value table symbols strings
			value: value + 1
		]
		
		if values? [
			value: as red-value! values + 1
			loop length [
				encode-value value payload symbols table strings
				value: value + 1
			]
		]
		
		offset
	]
	
	encode-string: func [
		data    [red-value!]
		type    [datatypes!]
		payload [red-binary!]
		/local
			series  [red-series!]
			buffer  [series!]
			_offset [byte-ptr!]
			length  [integer!]
			unit    [integer!]
			flags   [integer!]
	][
		series:  as red-series! data
		buffer:  GET_BUFFER(series)
		unit:    GET_UNIT(buffer)
		length:  _series/get-length series yes
		_offset: as byte-ptr! buffer/offset
		flags:   type or (unit << 8)
		
		record [payload flags data/data1 length]
		
		if type = TYPE_VECTOR [store payload data/data3]
		unless zero? length [
			emit payload _offset length << log-b unit
		]
		
		pad payload 32
	]
	
	encode-block: func [
		data    [red-value!]
		type    [datatypes!]
		abs?    [logic!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		return: [integer!]
		/local
			series  [red-series!]
			_offset [red-value!]
			buffer  [series!]
			length  [integer!]
	][
		series:  as red-series! data
		buffer:  GET_BUFFER(series)
		length:  _series/get-length series yes
		_offset: buffer/offset
		
		store payload type
		unless type = TYPE_MAP [store payload either abs? [0][data/data1]]
		store payload length
		loop length [
			encode-value _offset payload symbols table strings
			_offset: _offset + 1
		]
		
		length
	]
	
	encode-symbol: func [
		data    [red-value!]
		table   [red-binary!]
		symbols [red-binary!]
		strings [red-binary!]
		return: [integer!]
		/local
			_symbol [red-symbol!]
			start here [int-ptr!]
			string  [c-string!]
			length  [integer!]
			end id  [integer!]
	][
		start: as int-ptr! binary/rs-head symbols
		end:   (binary/rs-length? symbols) >> 2
		id:    0
		
		while [id < end][							;-- reuse symbol records when possible
			here: start + id
			if here/value = data/data2 [break]
			id: id + 1
		]
		
		if id = end [
			_symbol: as red-symbol! symbol/get data/data2
			string:  as c-string! (as series! _symbol/cache/value) + 1
			length:  binary/rs-length? strings
			
			store table length
			store symbols data/data2
			emit strings as byte-ptr! string (length? string) + 1
			
			pad strings 64
		]
		
		id
	]
	
	encode-image: func [
		data    [red-value!]
		payload [red-binary!]
		/local
			type  [integer!]
			rgb   [red-binary!]
			alpha [red-binary!]
	][	
		type:  TYPE_IMAGE
		rgb:   image/extract-data as red-image! data EXTRACT_RGB
		alpha: image/extract-data as red-image! data EXTRACT_ALPHA 
		
		record [payload type data/data1 data/data3]
		emit payload binary/rs-head rgb   binary/rs-length? rgb
		emit payload binary/rs-head alpha binary/rs-length? alpha
	]
	
	encode: func [
		data    [red-value!]
		return: [red-binary!]
		/local
			payload table symbols strings[red-binary!]
			here [int-ptr!]
			head [byte-ptr!]
			length size sym-len str-len sym-size [integer!]
	][
		codec?: yes
	
		;-- payload
		payload: binary/make-at stack/push* 4		;@@ TBD: heuristics for pre-allocation
		symbols: binary/make-at stack/push* 4
		table:   binary/make-at stack/push* 4
		strings: binary/make-at stack/push* 4
		
		length: encode-value data payload symbols table strings
		size:   binary/rs-length? payload
		
		;-- symbol table
		sym-len: binary/rs-length? table
		unless zero? sym-len [
			str-len: binary/rs-length? strings
			sym-size: sym-len >> 2
			
			binary/rs-insert payload 0 binary/rs-head strings str-len	;-- strings buffer
			binary/rs-insert payload 0 binary/rs-head table sym-len		;-- symbol records

			binary/rs-insert payload 0 as byte-ptr! :str-len 4			;-- size of the strings buffer
			binary/rs-insert payload 0 as byte-ptr! :sym-size 4			;-- number of symbol records
		]
		
		;-- Redbin header
		binary/rs-insert payload 0 header 16		;-- size of the header
		head: binary/rs-head payload
		head/8: either zero? sym-len [null-byte][#"^(04)"]
		here: as int-ptr! head + 8					;-- skip to length entry
		here/1: length
		here/2: size
		
		payload
	]
	
	boot-load: func [payload [byte-ptr!] keep? [logic!] return: [red-value!] /local saved ret state][
		codec?: no
		state: collector/active?
		collector/active?: no
		if keep? [saved: root-base]
		ret: decode payload root no
		if keep? [root-base: saved]
		collector/active?: state
		ret
	]
]