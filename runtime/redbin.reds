Red/System [
	Title:   "Redbin format encoder and decoder for Red runtime"
	Author:  "Qingtian Xie, Vladimir Vasilyev"
	File: 	 %redbin.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015-2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

redbin: context [
	verbose: 0
	
	#define CHECK_RECORD_LEN(n) [len: n check]
	;-- Redbin header flags
	
	#define REDBIN_COMPACT_MASK			01h
	#define REDBIN_COMPRESSED_MASK		02h
	#define REDBIN_SYMBOL_TABLE_MASK	04h
	
	;-- Record header flags
	
	#define REDBIN_NEWLINE_MASK			80000000h
	#define REDBIN_VALUES_MASK			40000000h
	#define REDBIN_STACK_MASK			20000000h
	#define REDBIN_SELF_MASK			10000000h

	#define REDBIN_KIND_MASK			0C000000h
	#define REDBIN_SET_MASK				02000000h
	#define REDBIN_OWNER_MASK			01000000h

	#define REDBIN_COMPLEMENT_MASK		00800000h
	#define REDBIN_MONEY_SIGN_MASK		00400000h
	#define REDBIN_REFERENCE_MASK		00080000h
	
	;-- Special record types
	
	#enum redbin-value-type! [
		REDBIN_PADDING: 	0
		REDBIN_REFERENCE: 	255
	]
	
	;-- Compact encoding tag space
	
	#define REDBIN_CP_ESCAPE			3Fh				;-- varint type ID follows (types >= 63)
	#define REDBIN_CP_MODIFIER			40h				;-- per-class variant bit
	#define REDBIN_CP_INT0				80h				;-- 80h-BFh: integer! immediates 0-63
	#define REDBIN_CP_NL				C0h				;-- new-line flag on next record
	#define REDBIN_CP_REF				C1h				;-- next record is in referral form
	#define REDBIN_CP_TRUE				C2h
	#define REDBIN_CP_FALSE				C3h
	#define REDBIN_CP_GSET				C4h				;-- v1 only: global-set word follows
	
	#define REDBIN_CP_CTX_KIND_MASK		03h				;-- context! flags byte layout
	#define REDBIN_CP_CTX_STACK			04h
	#define REDBIN_CP_CTX_SELF			08h
	#define REDBIN_CP_CTX_VALUES		10h

	#define REDBIN_CP_MAX_REFS			65536			;-- anti-DoS cap on a reference's waypoint count

	;-- Top-level declarations
	
	origin:      as red-block! 0
	buffer:		 as byte-ptr! 0
	root-base:	 as red-value! 0
	input:		 as int-ptr! 0						;-- save decoded data beginning for error reports
	
	root-offset: 0
	offset:      0
	codec?:      no
	
	#if debug? = yes [indent: 0]
	
	header: protect #{
		52454442494E								;-- REDBIN magic
		02											;-- version
		00											;-- placeholder for flags
		00000000									;-- placeholder for size (number of root records)
		00000000									;-- placeholder for length (bytes)
	}
		
	;-- Compact decoding state & primitives --

	sym-count:	0									;-- symbols in the payload's table
	sym-str-size: 0									;-- byte size of the strings blob (bounds read-sym offsets)
	cp-val:		0									;-- scalar produced by the last read-* helper
	cp-ref:		as red-value! 0						;-- value produced by read-reference-cp (transient)
	dec-ref?:	no									;-- referral-form flag returned by read-spec-block-cp

	cp-refs:	as int-ptr! 0						;-- scratch buffer for reference waypoints
	cp-refs-sz:	0

	;-- Support --
	
	build-symbol-table: func [						;-- intern all symbols into a transient table,
		base 	[int-ptr!]							;-- leaving the input payload untouched
		return: [int-ptr!]
		/local
			syms	[int-ptr!]
			end		[int-ptr!]
			strings [c-string!]
			table	[int-ptr!]
			slot	[int-ptr!]
	][
		syms:	 base + 2
		end:	 syms + base/value
		strings: as-c-string end
		table:	 as int-ptr! allocate base/value << 2
		slot:	 table

		while [syms < end][
			slot/1: symbol/make strings + syms/1
			syms: syms + 1
			slot: slot + 1
		]
		table
	]
	
	pad: func [
		buffer [red-binary!]
		size   [integer!]
		/local
			length  [integer!]
			residue [integer!]
			zero    [float!]
	][
		assert any [size = 32 size = 64]
		
		size:    size >> 3
		length:  binary/rs-length? buffer
		residue: length // size
		zero:    0.0								;-- 8 zero bytes
		
		unless zero? residue [
			binary/rs-append buffer as byte-ptr! :zero size - residue
		]
	]
	
	align: func [
		address [byte-ptr!]
		bits    [integer!]
		return: [byte-ptr!]
		/local
			delta [integer!]
	][
		assert any [bits = 32 bits = 64]
		
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
	
	;-- Reference sub-system --
	
	reset: does [path/reset reference/reset]			;-- should be called before & after `encode`
	
	path: context [
		stack: as int-ptr! 0							;-- initialized by 'reset'
		top:   stack
		end:   stack
		
		push: func [/local newsz [integer!] new [int-ptr!]] [
			if top + 1 > end [
				newsz: (as-integer end - stack) * 3 / 2					;-- +50% of current size
				new: as int-ptr! realloc as byte-ptr! stack newsz
				if null? new [reset fire [TO_ERROR(internal no-memory)]]
				top: new + (top - stack)
				end: new + (newsz / size? integer!)
				stack: new
			]
			top/value: offset
			top: top + 1
			offset: 0
		]
		
		pop: does [
			top: top - 1
			assert top >= stack
			offset: top/value
		]
		
		reset: func [/local min-size [integer!]] [
			min-size: 1024
			if (as-integer end - stack) > (min-size * size? integer!) [	;-- free the extra RAM
				free as byte-ptr! stack
				stack: as int-ptr! 0
			]
			if null? stack [											;-- start with the min. size
				stack: as int-ptr! allocate min-size * size? integer!
				end: stack + min-size
			]
			top: stack
		]
	]
	
	reference: context [
		;-- a map of node! -> offset in 'list'
		map:  as node! 0								;-- initialized in 'reset'
		list: as int-ptr! 0								;-- as well
		top:  list
		end:  list
		
		fetch: func [
			node    [node!]
			return: [int-ptr!]
			/local
				here [int-ptr!]
				slot [red-integer!]
		][
			slot: as red-integer! _hashtable/get-value map as-integer node
			if null? slot [return null]
			list + slot/value
		]
		
		store: func [
			node [node!]
			/local
				size  [integer!]
				newsz [integer!]
				reqsz [integer!]
				new   [int-ptr!]
				slot  [red-integer!]
		][
			size: (as integer! path/top - path/stack) >> log-b size? integer!
			if top + size + 1 > end [									;-- (node=1) + size
				reqsz: (as-integer (top + size + 1) - list) + 8'192		;-- min. required + reserve for later
				newsz: (as-integer end - list) * 3 / 2					;-- +50% of current size
				if newsz < reqsz [newsz: reqsz]
				new: as int-ptr! realloc as byte-ptr! list newsz
				if null? new [reset fire [TO_ERROR(internal no-memory)]]
				top: new + (top - list)
				end: new + (newsz / size? integer!)
				list: new
			]
			assert not null? map
			slot: as red-integer! _hashtable/put-key map as-integer node
			assert not null? slot
			integer/make-at as cell! slot (as-integer top - list) / size? integer!
			top/1: size
			copy-memory as byte-ptr! top + 1 as byte-ptr! path/stack size * size? integer!
			top: top + size + 1
		]

		on-gc-mark: does [_hashtable/mark as int-ptr! :map]
		
		reset: func [/local min-size] [
			min-size: 16'384
			if (as-integer end - list) > (min-size * size? integer!) [	;-- free the extra RAM
				free as byte-ptr! list
				list: as int-ptr! 0
			]
			if null? list [												;-- start with the min. size
				list: as int-ptr! allocate min-size * size? integer!
				end: list + min-size
			]
			top: list
			either null? map [
				map: _hashtable/init 1024 null HASH_TABLE_NODE_KEY 1
				collector/register as int-ptr! :on-gc-mark
			][
				_hashtable/clear-map map
			]
		]
	]

	encode-reference: func [
		reference [int-ptr!]
		payload   [red-binary!]
	][
		record [payload REDBIN_REFERENCE reference/1]
		emit payload as byte-ptr! reference + 1 reference/1 << log-b size? integer!
	]
	
	decode-reference: func [
		data    [int-ptr!]
		end		[int-ptr!]
		parent  [red-block!]
		return: [int-ptr!]
	][
		if data + 2 > end [throw-error data]
		if data + 2 + data/2 > end [throw-error data]
		
		copy-cell resolve-path data + 2 data/2 (as byte-ptr! data) ALLOC_TAIL(parent)
		data + data/2 + 2
	]
	
	;-- Redbin codec interface
	
	encode: func [
		data    [red-value!]
		return: [red-binary!]
		/local
			payload table   [red-binary!]
			symbols strings [red-binary!]
			here            [int-ptr!]
			head            [byte-ptr!]
			length size     [integer!]
			table-length    [integer!]
			buffer-length   [integer!]
			table-size      [integer!]
	][
		codec?: yes
		offset: 0
		
		reset
		
		;-- payload
		payload: binary/make-at stack/push* size? cell!
		symbols: binary/make-at stack/push* 4
		table:   binary/make-at stack/push* 4
		strings: binary/make-at stack/push* 4

		encode-value data payload symbols table strings
		size: binary/rs-length? payload
		
		;-- symbol table
		table-length: binary/rs-length? table
		unless zero? table-length [
			buffer-length: binary/rs-length? strings
			table-size: table-length >> 2
			
			binary/rs-insert payload 0 binary/rs-head strings buffer-length	;-- strings buffer
			binary/rs-insert payload 0 binary/rs-head table table-length	;-- offsets table
			
			binary/rs-insert payload 0 as byte-ptr! :buffer-length 4		;-- size of the strings buffer
			binary/rs-insert payload 0 as byte-ptr! :table-size 4			;-- number of symbol records
		]
		
		;-- Redbin header
		binary/rs-insert payload 0 header 16		;-- size of the header
		head: binary/rs-head payload
		head/8: either zero? table-length [null-byte][#"^(04)"]
		here: as int-ptr! head + 8					;-- skip to length entry
		here/1: 1									;-- always 1 root record
		here/2: size
		
		stack/pop 4
		
		reset
		payload
	]
	
	decode: func [
		data	[byte-ptr!]
		parent	[red-block!]
		codec?  [logic!]							;-- YES: called by Redbin codec
		size	[integer!]							;-- total input byte length; < 0 = trusted (boot), unbounded
		return: [red-value!]
		/local
			p			[byte-ptr!]
			iend		[byte-ptr!]					;-- real input end (null = unbounded/trusted); bounds validation
			written		[integer!]
			saved		[byte-ptr!]
			compact?	[logic!]
			compressed? [logic!]
			sym-table?	[logic!]
			s			[series!]
	][
		;----------------
		;-- decode header
		;----------------
		p: data
		unless all [								;-- magic="REDBIN"
			p/1 = #"R" p/2 = #"E" p/3 = #"D"
			p/4 = #"B" p/5 = #"I" p/6 = #"N"
		][
			either codec? [
				fire [TO_ERROR(script invalid-data) stack/arguments]
			][
				print-line "Error: Not a Redbin file!"
				halt
			]
		]
		input: as int-ptr! data						;-- save it for error reports
		iend: either size < 0 [null][data + size]	;-- real input end for bounds validation (null = trusted)
		p: p + 7									;-- skip magic (6 bytes) + version (1 byte)
		compact?:	 (as-integer p/1) and REDBIN_COMPACT_MASK <> 0
		compressed?: (as-integer p/1) and REDBIN_COMPRESSED_MASK <> 0
		sym-table?:  (as-integer p/1) and REDBIN_SYMBOL_TABLE_MASK <> 0
		p: p + 1
		
		saved: null
		written: 0
		if compressed? [
			p: crush/decompress p :written
			if p = null [
				either codec? [
					fire [TO_ERROR(script invalid-data) stack/arguments]
				][
					print-line "Error: Redbin compressed data corrupted!"
					halt
				]
			]
			saved: p
			iend: p + written						;-- real end = decompressed buffer end
		]
		unless codec? [
			s: GET_BUFFER(parent)
			root-offset: (as-integer s/tail - s/offset) >> log-b size? cell!
		]
		
		either compact? [
			decode-compact p iend parent sym-table?
		][
			decode-fat p iend parent sym-table?
		]
		
		if compressed? [crush/release saved]
		input: null
		unless codec? [root-base: (block/rs-head parent) + root-offset]
		root-base
	]
	
	boot-load: func [payload [byte-ptr!] keep? [logic!] return: [red-value!] /local saved ret state][
		codec?: no
		state: collector/active?
		collector/active?: no
		if keep? [saved: root-base]
		ret: decode payload root no -1
		if keep? [root-base: saved]
		collector/active?: state
		ret
	]
	
	;-- ANY-VALUE! --
	
	encode-value: func [
		data    [red-value!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			node    [node!]
			ref     [int-ptr!]
			type    [integer!]
			header  [integer!]
			mask	[integer!]
			flags	[integer!]
			first?  [logic!]
			global? [logic!]
	][
		type: TYPE_OF(data)
		mask: either zero? (data/header and flag-new-line) [0][REDBIN_NEWLINE_MASK]
		flags: switch type [
			TYPE_TUPLE [TUPLE_SIZE?(data) << 8]
			TYPE_MONEY [(money/get-sign as red-money! data) << 22]
			default    [0]
		]
		header: type or mask or flags
		#if debug? = yes [if verbose > 0 [loop indent << 2 [prin " "] probe ["<< type: " type]]]

		switch type [
			TYPE_UNSET
			TYPE_NONE		[store payload header]
			TYPE_DATATYPE
			TYPE_LOGIC 		[record [payload header data/data1]]
			TYPE_INTEGER
			TYPE_CHAR 		[record [payload header data/data2]]
			TYPE_PAIR 		[record [payload header data/data2 data/data3]]
			TYPE_POINT2D	[record [payload header data/data1 data/data2]]
			TYPE_POINT3D	[record [payload header data/data1 data/data2 data/data3]]
			TYPE_PERCENT
			TYPE_TIME
			TYPE_FLOAT 		[pad payload 64 record [payload header data/data3 data/data2]]
			TYPE_DATE 		[record [payload header data/data1 data/data3 data/data2]]
			TYPE_TYPESET
			TYPE_TUPLE
			TYPE_MONEY		[record [payload header data/data1 data/data2 data/data3]]
			TYPE_ISSUE		[record [payload header encode-symbol data table symbols strings]]
			TYPE_ERROR		[encode-error data header payload symbols table strings]
			TYPE_OP			[encode-op data header payload symbols table strings]
			TYPE_NATIVE
			TYPE_ACTION 	[encode-native data header payload symbols table strings]
			TYPE_PORT
			TYPE_TRIPLE
			TYPE_HANDLE
			TYPE_EVENT
			TYPE_ROUTINE 	[
				reset
				fire [TO_ERROR(access no-codec) data]
			]
			default			[
				first?:  any [ALL_WORD?(type) type = TYPE_OBJECT type = TYPE_FUNCTION]
				node:    as node! either first? [data/data1][data/data2]
				ref:     reference/fetch node
				global?: all [first? node = global-ctx]
				
				unless global? [
					either null? ref [
						path/push
						reference/store node
					][
						header: header or REDBIN_REFERENCE_MASK
					]
				]
				
				switch type [
					TYPE_ANY_STRING
					TYPE_VECTOR
					TYPE_BINARY		[encode-string data header payload]
					TYPE_BITSET		[encode-bitset data header payload]
					TYPE_IMAGE		[encode-image data header payload]
					TYPE_ANY_WORD
					TYPE_REFINEMENT	[encode-word data header payload symbols table strings]
					TYPE_ANY_BLOCK	[encode-block data header payload symbols table strings]
					TYPE_MAP		[encode-map data header payload symbols table strings]
					TYPE_OBJECT		[encode-object data header payload symbols table strings]
					TYPE_FUNCTION	[encode-function data header payload symbols table strings]
					default			[assert false]
				]
				
				unless global? [either null? ref [path/pop][encode-reference ref payload]]
			]
		]

		offset: offset + 1
	]
	
	decode-value: func [
		data	[int-ptr!]
		end		[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		return: [int-ptr!]
		/local 
			type [integer!]
			len	 [integer!]
			cell [cell!]
			nl?	 [logic!]
			check [subroutine!]
	][
		type: data/1 and FFh
		nl?:  data/1 and REDBIN_NEWLINE_MASK <> 0
		#if debug? = yes [if verbose > 0 [print [#"<" type #">"]]]
		check: [if data + len > end [throw-error data]]
		
		cell: null
		data: switch type [
			TYPE_ANY_WORD
			TYPE_REFINEMENT [
				;@@ TBD: incompatible encodings
				either codec? [decode-word* data end table parent nl?][decode-word data end table parent nl?]
			]
			TYPE_ANY_STRING
			TYPE_BINARY		[decode-string data end parent nl?]
			TYPE_INTEGER	[
				CHECK_RECORD_LEN(2)
				cell: as cell! integer/make-in parent data/2
				data + 2
			]
			TYPE_ANY_PATH
			TYPE_BLOCK
			TYPE_PAREN		[decode-block   data end table parent nl?]
			TYPE_CONTEXT	[decode-context data end table parent]
			TYPE_ISSUE		[decode-issue   data end table parent nl?]
			TYPE_TYPESET	[
				CHECK_RECORD_LEN(4)
				cell: as cell! typeset/make-in parent data/2 data/3 data/4
				data + 4
			]
			TYPE_FLOAT		[
				CHECK_RECORD_LEN(3)
				cell: as cell! float/make-in parent data/2 data/3
				data + 3
			]
			TYPE_PERCENT 	[
				CHECK_RECORD_LEN(3)
				cell: as cell! percent/make-in parent data/2 data/3
				data + 3
			]
			TYPE_TIME		[
				CHECK_RECORD_LEN(3)
				cell: as cell! time/make-in parent data/2 data/3
				data + 3
			]
			TYPE_DATE		[
				CHECK_RECORD_LEN(4)
				cell: as cell! date/make-in parent data/2 data/3 data/4
				data + 4
			]
			TYPE_CHAR		[
				CHECK_RECORD_LEN(2)
				cell: as cell! char/make-in parent data/2
				data + 2
			]
			TYPE_DATATYPE	[
				CHECK_RECORD_LEN(2)
				cell: as cell! datatype/make-in parent data/2
				data + 2
			]
			TYPE_PAIR		[
				CHECK_RECORD_LEN(3)
				cell: as cell! pair/make-in parent data/2 data/3
				data + 3
			]
			TYPE_POINT2D	[
				CHECK_RECORD_LEN(3)
				cell: ALLOC_TAIL(parent)
				cell/header: TYPE_POINT2D
				cell/data1: data/2
				cell/data2: data/3
				cell/data3: 0
				data + 3
			]
			TYPE_POINT3D	[
				CHECK_RECORD_LEN(4)
				cell: ALLOC_TAIL(parent)
				cell/header: TYPE_POINT3D
				cell/data1: data/2
				cell/data2: data/3
				cell/data3: data/4
				data + 4
			]
			TYPE_UNSET		[
				CHECK_RECORD_LEN(1)
				cell: as cell! unset/make-in parent
				data + 1
			]
			TYPE_NONE		[
				CHECK_RECORD_LEN(1)
				cell: as cell! none/make-in parent
				data + 1
			]
			TYPE_LOGIC		[
				CHECK_RECORD_LEN(2)
				cell: as cell! logic/make-in parent as logic! data/2
				data + 2
			]
			TYPE_HASH		[decode-hash data end table parent nl?]
			TYPE_MAP		[decode-map data  end table parent nl?]
			TYPE_NATIVE
			TYPE_ACTION		[decode-native   data end table parent nl?]
			TYPE_OP			[decode-op       data end table parent nl?]
			TYPE_TUPLE		[decode-tuple    data end parent nl?]
			TYPE_MONEY		[decode-money    data end parent nl?]
			TYPE_BITSET     [decode-bitset   data end parent nl?]
			TYPE_VECTOR     [decode-vector   data end parent nl?]
			TYPE_IMAGE		[decode-image    data end parent nl?]
			TYPE_ERROR		[decode-error    data end table parent nl?]
			TYPE_OBJECT		[decode-object   data end table parent nl?]
			TYPE_FUNCTION	[decode-function data end table parent nl?]
			TYPE_PORT
			TYPE_ROUTINE
			TYPE_HANDLE
			TYPE_EVENT
			TYPE_TRIPLE [
				reset
				fire [TO_ERROR(access no-codec) datatype/push type]
				data								;-- pass compiler's type checking
			]
			REDBIN_PADDING [
				decode-value data + 1 end table parent
			]
			REDBIN_REFERENCE [
				decode-reference data end parent
			]
			default [
				assert false
				data								;-- pass compiler's type checking
			]
		]
		if all [nl? cell <> null][cell/header: cell/header or flag-new-line]
		data
	]
	
	;-- CONTEXT! --

	encode-context: func [
		data    [red-value!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			ctx           [red-context!]
			value         [red-value!]
			values words  [series!]
			header length [integer!]
			kind          [integer!]
			stack? self?  [logic!]
			values?       [logic!]
	][
		#if debug? = yes [if verbose > 0 [loop indent << 2 [prin " "] probe "<< type: context!"]]

		ctx:     as red-context! data
		kind:    GET_CTX_TYPE(ctx)
		stack?:  ON_STACK?(ctx)
		self?:   ctx/header and flag-self-mask <> 0
		values?: no
		
		header:   TYPE_CONTEXT or (kind << 26)
		if stack? [header: header or REDBIN_STACK_MASK]
		if self?  [header: header or REDBIN_SELF_MASK]
		
		words:  _hashtable/get-ctx-words ctx
		length: (as integer! words/tail - words/offset) >> log-b size? cell!
		
		unless stack? [
			values: as series! ctx/values/value
			value:  values/offset
			loop length [							;-- pre-scan for presence of values
				values?: TYPE_OF(value) <> TYPE_UNSET
				if values? [header: header or REDBIN_VALUES_MASK break]
				value: value + 1
			]
		]
		
		record [payload header length]
		
		value: words/offset
		loop length [
			store payload encode-symbol value table symbols strings
			value: value + 1
		]
		
		unless stack? [
			if values? [
				value: values/offset
				loop length [
					encode-value value payload symbols table strings
					value: value + 1
				]
			]
		]
	]
	
	decode-context: func [
		data	[int-ptr!]
		end		[int-ptr!]
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
			id      [integer!]
	][
		header: data/1
		slots:  data/2
		value:  data + 2 + slots
		if value > end [throw-error data]
		
		values?: header and REDBIN_VALUES_MASK <> 0
		stack?:	 header and REDBIN_STACK_MASK  <> 0
		self?:	 header and REDBIN_SELF_MASK   <> 0
		type:	 header and REDBIN_KIND_MASK >> 26
		
		new: _context/create slots stack? self? null type
		
		obj: as red-object! ALLOC_TAIL(parent)		;-- use an object to store the ctx node
		obj/header: TYPE_OBJECT
		obj/ctx:	new
		obj/class:	-1
		obj/on-set: null
		
		s: as series! new/value
		copy-cell as red-value! obj s/offset + 1	;-- set back-reference
			
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
			id:  either codec? [symbol/make (as c-string! table + table/-1) + sym/1][sym/1]
			;-- create the words entries in the symbol table of the context
			_context/find-or-store ctx id yes :i
			if all [not stack? values?][value: decode-value value end table values]
			data: data + 1
		]
		
		if values? [
			s/tail: s/offset + slots
			stack/pop 1									;-- drop unwanted block
		]
		
		value
	]
	
	fill-context: func [
		data    [int-ptr!]
		end     [int-ptr!]
		table   [int-ptr!]
		node    [node!]
		return: [int-ptr!]
		/local
			values    [red-block!]
			context   [red-context!]
			series    [series!]
			value sym [int-ptr!]
			id new    [integer!]
			slots     [integer!]
			values?   [logic!]
			stack?    [logic!]
			filled?   [logic!]
	][
		assert data/1 and FFh = TYPE_CONTEXT
		
		values?: data/1 and REDBIN_VALUES_MASK <> 0
		stack?:	 data/1 and REDBIN_STACK_MASK  <> 0
		filled?: all [not stack? values?]
		
		series:  as series! node/value
		context: as red-context! series/offset
		
		if filled? [
			values: block/push-only* data/2
			values/node: context/values
			
			series: as series! context/values/value
			series/tail: series/offset
		]
		
		slots: data/2
		data:  data + 2
		value: data + slots
		new:   0
		
		if value > end [throw-error data]
		
		loop slots [
			sym: table + data/1
			id:  symbol/make (as c-string! table + table/-1) + sym/1
			
			_context/find-or-store context id yes :new
			if filled? [value: decode-value value end table values]
			
			data: data + 1
		]
		
		if filled? [
			stack/pop 1
			series/tail: series/offset + slots
		]
		
		value
	]
	
	preprocess-binding: func [
		data    [int-ptr!]
		end     [int-ptr!]
		table   [int-ptr!]
		tail    [int-ptr!]
		return: [node!]
		/local
			context         [red-context!]
			object          [red-object!]
			fun             [red-function!]
			proto spec body [red-block!]
			series          [series!]
			node values     [node!]
			here pos        [int-ptr!]
			type kind skip  [integer!]
			size			[integer!]
			values? stack?  [logic!]
			self? owner?    [logic!]
	][
		if data + 1 >= end [throw-error data]
		here: data
		type: data/1 and FFh
		
		assert any [type = TYPE_OBJECT type = TYPE_FUNCTION]
		
		;-- locate context record
		data: either type = TYPE_OBJECT [
			data: data + 2
			skip: (size? integer!) << 1
			owner?: data/1 and REDBIN_OWNER_MASK <> 0 
			either owner? [data + skip][data]
		][
			data + 3
		]
		if data >= end [throw-error data]
		
		assert data/1 and FFh = TYPE_CONTEXT
		pos: data
		
		;-- decode context slot
		values?: data/1 and REDBIN_VALUES_MASK <> 0
		stack?:	 data/1 and REDBIN_STACK_MASK  <> 0
		self?:	 data/1 and REDBIN_SELF_MASK   <> 0
		kind:	 data/1 and REDBIN_KIND_MASK   >> 26

		values: either stack? [null][
			size: either zero? data/2 [1][data/2]
			alloc-unset-cells size
		]
		node: alloc-unset-cells 2
		series: as series! node/value

		context: as red-context! alloc-tail series
		context/header: TYPE_UNSET
		context/symbols: _hashtable/init data/2 null HASH_TABLE_SYMBOL HASH_SYMBOL_CONTEXT
		context/values: values
		
		context/header: TYPE_CONTEXT
		SET_CTX_TYPE(context kind)
		if self?  [context/header: context/header or flag-self-mask]
		if stack? [context/header: context/header or flag-series-stk]
		
		data: here
		
		;-- decode back-reference slot
		either type = TYPE_OBJECT [
			object: as red-object! alloc-tail series
			object/header: TYPE_UNSET
			object/ctx:    node
			object/class:  either codec? [-1][data/2]	;@@ TBD: concurrent class IDs — codec (untrusted) forces a fresh id; boot keeps the stored one
			object/on-set: either owner? [alloc-cells 2][null]
			
			if owner? [
				data: data + 2
				
				series: as series! object/on-set/value
				series/tail: series/offset + 2
				
				pair/make-at series/offset data/1 0
				pair/make-at series/offset + 1 data/2 0
			]
			
			object/header: TYPE_OBJECT
		][
			proto: block/push-only* 2
			size: either zero? data/2 [1][data/2]
			spec: block/make-in proto size
			size: either zero? data/3 [1][data/3]
			body: block/make-in proto size
			
			fun: as red-function! alloc-tail series
			fun/header: TYPE_UNSET
			fun/ctx:    node
			fun/spec:   spec/node
			fun/more:   alloc-unset-cells 5
			
			series: as series! fun/more/value
			series/tail: series/offset + 5
			copy-cell as red-value! body series/offset
			stack/pop 1
			
			fun/header: TYPE_FUNCTION
		]
		tail/value: as integer! pos
		node
	]
	
	;-- ANY-OBJECT! --

	;-- object!
	
	encode-object: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			object [red-object!]
			change [red-pair!]
			deep   [red-pair!]
			ctx    [red-value!]
			buffer [series!]
			owner? [logic!]
	][
		object: as red-object! data
		owner?: not null? object/on-set
		
		if owner? [header: header or REDBIN_OWNER_MASK]
		
		store payload header
		
		unless header and REDBIN_REFERENCE_MASK <> 0 [
			#if debug? = yes [indent: indent + 1]
			store payload object/class
			if owner? [
				buffer: as series! object/on-set/value
				change: as red-pair! buffer/offset
				deep:   as red-pair! buffer/offset + 1
				
				record [payload change/x deep/x]
			]
			
			ctx: as red-value! TO_CTX(object/ctx)
			encode-context ctx payload symbols table strings
			#if debug? = yes [indent: indent - 1]
		]
	]
	
	decode-object: func [
		data    [int-ptr!]
		end		[int-ptr!]
		table   [int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			last   [red-object!]
			object [red-value!]
			series [series!]
			node   [node!]
			next   [integer!]
			type   [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			data: decode-reference data + 1 end parent
			last: (as red-object! block/rs-tail parent) - 1
			
			type: TYPE_OF(last)
			assert any [type = TYPE_OBJECT ANY_WORD?(type)]
			
			series: as series! last/ctx/value
			object: copy-cell series/offset + 1 as red-value! last
			if nl? [object/header: object/header or flag-new-line]
			
			data
		][
			next: 0
			node: preprocess-binding data end table :next
			series: as series! node/value
			
			object: copy-cell series/offset + 1 ALLOC_TAIL(parent)
			if nl? [object/header: object/header or flag-new-line]
			
			fill-context as int-ptr! next end table node
		]
	]
	
	;-- error!
	
	encode-error: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			err   [red-object!]
			base  [red-value!]
			code  [red-integer!]
			index [integer!]
	][
		err:  as red-object! data
		base: object/get-values err
		code: as red-integer! base + error/field-code
		
		path/push
		reference/store err/ctx
		record [payload header code/value]
		
		index: error/field-arg1
		until [
			encode-value base + index payload symbols table strings
			index: index + 1
			index > error/field-stack
		]
		path/pop
	]
	
	decode-error: func [
		data    [int-ptr!]
		end		[int-ptr!]
		table   [int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			err    [red-object!]
			ctx    [red-context!]
			series [series!]
	][
		if data + 2 >= end [throw-error data]
		err: error/make null as red-value! integer/box data/2 TYPE_ERROR
		err: as red-object! copy-cell as red-value! err ALLOC_TAIL(parent)
		if nl? [err/header: err/header or flag-new-line]
		
		ctx: GET_CTX(err)
		series: as series! ctx/values/value
		series/tail: series/offset + 3
		
		parent: block/push-only* 6
		parent/node: ctx/values 
		
		data: data + 2
		loop 6 [data: decode-value data end table parent]
		
		series/tail: series/offset + 9
		stack/pop 1
		data
	]
	
	;-- ANY-FUNCTION! --
	
	;-- native!, action!
	
	encode-native: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			slot  [red-block! value]
			here  [int-ptr!]
			index [integer!]
	][
		here: either TYPE_OF(data) = TYPE_NATIVE [natives/table][actions/table]
		index: 0
		until [index: index + 1 data/data1 = here/index]
		record [payload header index]
		
		slot/head: 0
		slot/node: as node! data/data2
		slot/header: TYPE_BLOCK
		
		encode-value as red-value! slot payload symbols table strings
		offset: offset - 1
	]
	
	decode-native: func [
		data	[int-ptr!]
		end		[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			cell  [red-native!]
			spec  [red-block!]
			value [red-value!]
			type  [integer!]
			index [integer!]
			more  [series!]
			node  [node!]
	][
		type:  data/1 and FFh
		index: data/2
		cell:  as red-native! ALLOC_TAIL(parent)
		
		if data + 2 > end [throw-error data]
		if codec? [parent: block/push-only* 1]	;-- redirect slot allocation
		spec: as red-block! block/rs-tail parent
		data: decode-block data + 2 end table parent off
		
		cell/header: TYPE_UNSET
		cell/spec:	 spec/node
		cell/code:   either type = TYPE_ACTION [actions/table/index][natives/table/index]
		cell/more:	 alloc-unset-cells 2
		cell/header: type						;-- implicit reset of all header flags
		
		more: as series! cell/more/value
		node: _context/make spec yes no CONTEXT_FUNCTION
		copy-cell as red-value! (as series! node/value) + 1 alloc-tail more	;-- ctx slot
		value: alloc-tail more							;-- args cache slot
		value/header: TYPE_UNSET
		
		if nl? [cell/header: cell/header or flag-new-line]
		if codec? [stack/pop 1]					;-- drop an unwanted block
		
		data
	]
	
	;-- op!
	
	encode-op: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
	][
		;@@ TBD: #4563
		header: header and flag-subtype-mask or (data/header and flag-subtype-select)
		store payload header
		
		if TYPE_OF(data) = TYPE_ROUTINE [reset fire [TO_ERROR(access no-codec) data]]
		header: data/header
		set-type data GET_OP_SUBTYPE(data)
		encode-value data payload symbols table strings
		data/header: header	
		offset: offset - 1							;-- compensate for extra recursion
	]
	
	decode-op: func [
		data	[int-ptr!]
		end		[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			op   [red-op!]
			flag [integer!]
	][
		if data + 1 >= end [throw-error data]
		flag: data/value and flag-subtype-select
		data: data + 1
		op: as red-op! block/rs-tail parent
		data: decode-value data end table parent
		op/header: op/header and flag-subtype-mask or flag
		set-type as red-value! op TYPE_OP
		if nl? [op/header: op/header or flag-new-line]
		data
	]
	
	;-- function!
	
	encode-function: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			fun      [red-function!]
			ctx body [red-value!]
			series   [series!]
			size     [integer!]
	][
		store payload header
		unless header and REDBIN_REFERENCE_MASK <> 0 [
			fun: as red-function! data
			ctx: as red-value! GET_CTX(fun)
			series: as series! fun/more/value
			body: series/offset
			assert TYPE_OF(body) = TYPE_BLOCK
			
			size: block/rs-length? as red-block! body
			series: as series! fun/spec/value
			
			record [
				payload
				(as integer! series/tail - series/offset) >> size? integer!
				size
			]
			
			encode-context   ctx  payload symbols table strings
			encode-spec-body data body payload symbols table strings
		]
	]
	
	encode-spec-body: func [
		spec    [red-value!]
		body    [red-value!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			data [red-value!]
			slot [red-block! value]
			old  [integer!]
	][
		old: offset
		
		slot/head: 0
		slot/node: as node! spec/data2
		slot/header: TYPE_BLOCK
		
		offset: 0									;-- form artifical paths to spec and body blocks
		data: as red-value! slot
		encode-value data payload symbols table strings
		
		offset: 1
		data: body
		encode-value data payload symbols table strings
		
		offset: old
	]
	
 	decode-function: func [
		data    [int-ptr!]
		end		[int-ptr!]
		table   [int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			fun    [red-function!]
			op	   [red-op!]
			source [red-value!]
			series [series!]
			node   [node!]
			size   [int-ptr!]
			next   [integer!]
			type   [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			data: decode-reference data + 1 end parent
			fun: (as red-function! block/rs-tail parent) - 1
			
			type: TYPE_OF(fun)
			assert any [type = TYPE_FUNCTION type = TYPE_OP ANY_WORD?(type)]
			either type = TYPE_OP [
				fun/header: TYPE_FUNCTION
			][
				series: as series! fun/ctx/value
				source: series/offset + 1
				copy-cell source as red-value! fun
			]
			
			if nl? [fun/header: fun/header or flag-new-line]
			data
		][
			next: 0
			node: preprocess-binding data end table :next
			data: fill-context as int-ptr! next end table node
			
			series: as series! node/value
			fun: as red-function! copy-cell series/offset + 1 ALLOC_TAIL(parent)
			if nl? [fun/header: fun/header or flag-new-line]
			
			fill-spec-body data end table fun
		]
	]
	
	fill-spec-body: func [
		data    [int-ptr!]
		end		[int-ptr!]
		table   [int-ptr!]
		fun     [red-function!]
		return: [int-ptr!]
		/local
			process [subroutine!]
			slot    [red-block!]
			cell    [red-block!]
			parent  [red-block!]
			series  [series!]
			size    [int-ptr!]
			ref?    [logic!]
	][
		parent: block/push-only* 1
		series: GET_BUFFER(parent)
		cell:   as red-block! series/offset
		ref?:   no
		
		process: [
			if data + 1 > end [throw-error data]
			assert data/1 and FFh = TYPE_BLOCK
			ref?:  data/1 and REDBIN_REFERENCE_MASK <> 0
			either ref? [
				data: decode-reference data + 2 end parent
				assert TYPE_OF(cell) = TYPE_BLOCK
				series/tail: series/tail - 1
			][
				if data + 3 > end [throw-error data]
				size: data + 2
				data: size + 1
				loop size/1 [data: decode-value data end table slot]
			]
		]
		
		slot: as red-block! stack/push*
		slot/head: 0
		slot/node: fun/spec
		slot/header: TYPE_BLOCK
		process
		if ref? [fun/spec: cell/node]				;-- refresh node pointer to a referenced buffer
		
		slot: as red-block! (as series! fun/more/value) + 1
		process
		if ref? [slot/node: cell/node]
		
		stack/pop 2
		data
	]
	
	;-- ALL-WORD!
	
	;-- word!, lit-word!, set-word!, get-word!, refinement!
	
	encode-word: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			value  [red-value!]
			ref	   [red-value!]
			ctx	   [red-context!]
			node   [node!]
			series [series!]
			type   [integer!]
	][
		node: as node! data/data1
		
		;@@ TBD: #4537
		if null? node [node: global-ctx]
		
		ctx: TO_CTX(node)
		ref: as red-value! ctx + 1
		type: TYPE_OF(ref)
		if any [									 ;-- native function context case
			type = TYPE_NONE
			type = TYPE_UNSET
			type = TYPE_BLOCK
		][
			node: global-ctx
		]
		if node = global-ctx [
			header: header or REDBIN_SET_MASK
			value:  _context/get-any data/data2 node
		]
		
		record [payload header encode-symbol data table symbols strings]
		store payload data/data3					;@@ TBD: redundant for global context
		
		unless header and REDBIN_REFERENCE_MASK <> 0 [
			either node = global-ctx [
				;@@ TBD: encode-value value payload symbols table strings
				0
			][
				series: as series! node/value
				value:  series/offset + 1
				type:   TYPE_OF(value)
				
				;@@ TBD: #4552
				if TYPE_OF(series/offset) = TYPE_OBJECT [
					reset
					fire [TO_ERROR(access no-codec) data]
				]
				switch type [
					TYPE_OBJECT	  [encode-object value type payload symbols table strings]
					TYPE_FUNCTION [encode-function value type payload symbols table strings]
					TYPE_BLOCK	  [0]				;-- function's spec cache block, do nothing
					default		  [assert false]
				]
			]
		]
	]
	
	encode-symbol: func [
		data    [red-value!]
		table   [red-binary!]
		symbols [red-binary!]
		strings [red-binary!]
		return: [integer!]
		/local
			_symbol    [red-symbol!]
			start here [int-ptr!]
			string     [c-string!]
			length     [integer!]
			end id     [integer!]
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
			_symbol: symbol/get data/data2
			string:  as c-string! (as series! _symbol/cache/value) + 1
			length:  binary/rs-length? strings
			
			store table length
			store symbols data/data2
			emit strings as byte-ptr! string (length? string) + 1
			
			pad strings 64
		]
		
		id
	]
	
	decode-issue: func [
		data	[int-ptr!]
		end		[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			w	[red-word!]
			sym	[int-ptr!]
	][
		if data + 2 > end [throw-error data]
		w: as red-word! ALLOC_TAIL(parent)
		sym: table + data/2
		w/symbol: either codec? [symbol/make (as c-string! table + table/-1) + sym/1][sym/1]
		w/header: TYPE_ISSUE
		if nl? [w/header: w/header or flag-new-line]
		data + 2
	]
	
	decode-word: func [								;-- Redbin v.1
		data	[int-ptr!]
		end		[int-ptr!]
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
		if data + 4 > end [throw-error data]
		sym: table + data/2							;-- get the decoded symbol
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
			data: decode-value data end table parent
			_context/set new block/rs-abs-at root offset
			s: GET_BUFFER(parent)
			offset: offset - 1
			s/tail: s/offset + offset				;-- drop unwanted values in parent
		]
		data
	]
	
	decode-word*: func [							;-- Redbin v.2
		data    [int-ptr!]
		end		[int-ptr!]
		table   [int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			tag       [subroutine!]
			word new  [red-word!]
			op        [red-op!]
			backref   [red-value!]
			series    [series!]
			node      [node!]
			sym tail  [int-ptr!]
			type next [integer!]
			type2     [integer!]
			set? ref? [logic!]
	][
		tag: [
			word/header: type
			if nl? [word/header: word/header or flag-new-line]
		]
		if any [data + 3 > end null? table][throw-error data]

		type: data/1 and FFh
		set?: data/1 and REDBIN_SET_MASK <> 0
		ref?: data/1 and REDBIN_REFERENCE_MASK <> 0
		tail: data + 3
		
		either ref? [
			tail: decode-reference tail end parent
			word: (as red-word! block/rs-tail parent) - 1
			
			type2: TYPE_OF(word)
			assert any [							;-- copy over context node from these slots
				type2 = TYPE_OBJECT
				type2 = TYPE_FUNCTION
				type2 = TYPE_OP
				ANY_WORD?(type2)
			]
			if type2 = TYPE_OP [					;-- locate function! slot
				op: as red-op! word
				assert GET_OP_SUBTYPE(op) = TYPE_FUNCTION
				node: as node! op/code
				series: as series! node/value
				copy-cell as red-value! series/offset + 3 as red-value! word
				assert TYPE_OF(word) = TYPE_FUNCTION
			]
		][
			word: as red-word! ALLOC_TAIL(parent)
		]
		
		sym: table + data/2
		word/header: TYPE_UNSET
		word/symbol: symbol/make (as c-string! table + table/-1) + sym/1
		word/index:  data/3
		
		if ref? [tag return tail]
		
		either set? [
			new: _context/add-global-word word/symbol yes no
			word/index: new/index
			word/ctx: global-ctx
		][
			next: 0
			word/ctx: preprocess-binding tail end table :next
		]
		
		tag
		data: either set? [tail][fill-context as int-ptr! next end table word/ctx]
		
		series:  as series! word/ctx/value
		backref: series/offset + 1
		
		type: backref/header and FFh
		assert any [type = TYPE_OBJECT type = TYPE_FUNCTION]
		
		either type = TYPE_OBJECT [data][fill-spec-body data end table as red-function! backref]
	]
	
	;-- SERIES!
	
	;-- block!, paren!, hash!, path!, lit-path!, set-path!, get-path!
	
	encode-block: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			series [red-series!]
			value  [red-value!]
			buffer [series!]
			length [integer!]
			push?  [logic!]
	][
		series: as red-series! data
		buffer: GET_BUFFER(series)
		length: _series/get-length series yes
		value:  buffer/offset
		
		store payload header
		unless header and get-type-mask = TYPE_MAP [store payload data/data1]
		
		unless header and REDBIN_REFERENCE_MASK <> 0 [
			store payload length
			#if debug? = yes [indent: indent + 1]
			loop length [
				encode-value value payload symbols table strings
				value:  value + 1
			]
			#if debug? = yes [indent: indent - 1]
		]
	]

	encode-map: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			series [red-series!]
			value  [red-value!]
			key	   [red-value!]
			buffer [series!]
			length [integer!]
			push?  [logic!]
	][
		series: as red-series! data
		store payload header

		unless header and REDBIN_REFERENCE_MASK <> 0 [
			length: map/rs-length? as red-hash! series
			store payload length * 2

			#if debug? = yes [indent: indent + 1]

			buffer: GET_BUFFER(series)
			key: buffer/offset
			length: _series/get-length series yes
			length: length / 2
			loop length [
				value: key + 1
				if value/header <> MAP_KEY_DELETED [
					encode-value key payload symbols table strings
					encode-value value payload symbols table strings
				]
				key: value + 1
			]
			#if debug? = yes [indent: indent - 1]
		]
	]
	
	decode-block: func [
		data	[int-ptr!]
		end		[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			blk  [red-block!]
			tail [int-ptr!]
			size [integer!]
			sz   [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			tail: decode-reference data + 2 end parent
			blk: (as red-block! block/rs-tail parent) - 1
			
			blk/header: data/1 and FFh
			if nl? [blk/header: blk/header or flag-new-line]
			blk/head: data/2
			
			tail
		][
			if data + 3 > end [throw-error data]		
			size: data/3
			sz: size
			if zero? sz [sz: 1]
			#if debug? = yes [if verbose > 0 [print [#":" size #":"]]]
			
			blk: block/make-in parent sz
			blk/head: data/2
			blk/header: data/1 and FFh
			if nl? [blk/header: blk/header or flag-new-line]
			data: data + 3
			
			loop size [data: decode-value data end table blk]
			
			data
		]
	]
	
	decode-map: func [
		data	[int-ptr!]
		end		[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			blk  [red-block!]
			m	 [red-hash!]
			tail [int-ptr!]
			size [integer!]
			sz   [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			tail: decode-reference data + 1 end parent
			blk: (as red-block! block/rs-tail parent) - 1
			if nl? [blk/header: blk/header or flag-new-line]
			tail
		][
			if data + 2 > end [throw-error data]
			size: data/2
			sz: size
			if zero? sz [sz: 1]
			#if debug? = yes [if verbose > 0 [print [#":" size #":"]]]
			
			blk: block/make-at as red-block! ALLOC_TAIL(parent) sz
			if nl? [blk/header: blk/header or flag-new-line]
			m: map/make-at as red-value! blk blk sz
			
			data: data + 2
			loop size [data: decode-value data end table blk]
			_hashtable/put-all m/table m/head 2
			
			data
		]
	]
	
	decode-hash: func [
		data	[int-ptr!]
		end		[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			hash [red-hash!]
			tail [int-ptr!]
			size [integer!]
			sz   [integer!]
	][
	
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			tail: decode-reference data + 2 end parent
			hash: (as red-hash! block/rs-tail parent) - 1
			if nl? [hash/header: hash/header or flag-new-line]
			tail
		][
			if data + 3 > end [throw-error data]
			size: data/3
			sz: size
			if zero? sz [sz: 1]
			#if debug? = yes [if verbose > 0 [print [#":" size #":"]]]
			
			hash: as red-hash! block/make-at as red-block! ALLOC_TAIL(parent) sz
			hash/head: data/2
			hash/table: _hashtable/init sz as red-block! hash HASH_TABLE_HASH 1
			
			hash/header: TYPE_HASH
			if nl? [hash/header: hash/header or flag-new-line]
			
			data: data + 3
			loop size [data: decode-value data end table as red-block! hash]
			_hashtable/put-all hash/table hash/head 1
			
			data
		]
	]
	
	;-- vector!, string!, tag!, url!, email!, ref!, file!
	
	encode-string: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		/local
			series [red-series!]
			buffer [series!]
			value  [byte-ptr!]
			length [integer!]
			unit   [integer!]
	][
		series: as red-series! data
		buffer: GET_BUFFER(series)
		unit:   GET_UNIT(buffer)
		length: _series/get-length series yes
		value:  as byte-ptr! buffer/offset
		header: header or (unit << 8)
		
		record [payload header data/data1]
		unless header and REDBIN_REFERENCE_MASK <> 0 [
			store payload length
			if TYPE_OF(data) = TYPE_VECTOR [store payload data/data3]
			unless zero? length [emit payload value length << log-b unit]
			pad payload 32
		]
	]
	
	decode-vector: func [
		data    [int-ptr!]
		end		[int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			slot   [red-value!]
			vec    [red-vector!]
			buffer [series!]
			tail   [int-ptr!]
			values [byte-ptr!]
			unit   [integer!]
			size   [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			tail: decode-reference data + 2 end parent
			vec: (as red-vector! block/rs-tail parent) - 1
			
			if nl? [vec/header: vec/header or flag-new-line]
			vec/head: data/2
			
			tail
		][
			if data + 4 > end [throw-error data]
			unit: data/1 >>> 8 and FFh
			size: data/3 << log-b unit				;-- in bytes
			
			slot: ALLOC_TAIL(parent)
			vec: as red-vector! slot
			vec/header: TYPE_UNSET
			vec/head: 	data/2
			vec/node: 	alloc-bytes size
			vec/type:	data/4
			
			buffer: GET_BUFFER(vec)
			buffer/flags: buffer/flags and flag-unit-mask or unit
			buffer/tail: as red-value! (as byte-ptr! buffer/offset) + size
			
			values: as byte-ptr! data + 4
			copy-memory as byte-ptr! buffer/offset values size
			
			vec/header: TYPE_VECTOR
			if nl? [vec/header: vec/header or flag-new-line]
			
			as int-ptr! align values + size 32		;-- align at upper 32-bit boundary
		]
	]
	
	decode-string: func [
		data	[int-ptr!]
		end		[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			str    [red-string!]
			tail   [int-ptr!]
			header [integer!]
			unit   [integer!]
			size   [integer!]
			s      [series!]
	][	
		header: data/1
		either header and REDBIN_REFERENCE_MASK <> 0 [
			tail: decode-reference data + 2 end parent
			str: (as red-string! block/rs-tail parent) - 1
			
			str/header: header and FFh
			if nl? [str/header: str/header or flag-new-line]
			str/head: data/2
			
			tail
		][
			if data + 3 > end [throw-error data]
			unit: header >>> 8 and FFh
			size: data/3 << log-b unit				;-- optimized data/3 * unit

			str: as red-string! ALLOC_TAIL(parent)
			str/header: TYPE_UNSET
			str/head: 	data/2
			str/node: 	alloc-bytes size
			str/cache:	null
			str/header: header and FFh				;-- implicit reset of all header flags
			if nl? [str/header: str/header or flag-new-line]
			
			data: data + 3
			s: GET_BUFFER(str)
			copy-memory as byte-ptr! s/offset as byte-ptr! data size
			
			s/flags: s/flags and flag-unit-mask or unit
			s/tail: as cell! (as byte-ptr! s/offset) + size
			
			as int-ptr! align (as byte-ptr! data) + size 32	;-- align at upper 32-bit boundary
		]
	]
	
	;-- image!
	
	encode-image: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		/local
			argb [red-binary!]
	][
		record [payload header data/data1]
		
		unless header and REDBIN_REFERENCE_MASK <> 0 [
			argb: image/extract-data as red-image! data EXTRACT_ARGB
			store payload data/data3
			emit payload binary/rs-head argb binary/rs-length? argb
		]
	]
	
	decode-image: func [
		data    [int-ptr!]
		end		[int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			slot   [red-image!]
			argb   [red-binary!]
			tail   [int-ptr!]
			pixels [byte-ptr!]
			width  [integer!]
			height [integer!]
			size   [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			tail: decode-reference data + 2 end parent
			slot: (as red-image! block/rs-tail parent) - 1
			
			if nl? [slot/header: slot/header or flag-new-line]
			slot/head: data/2
			
			tail
		][
			if data + 3 > end [throw-error data]

			if overflow? [
				width:  IMAGE_WIDTH(data/3)
				height: IMAGE_HEIGHT(data/3)
				size:   width * height << 2								;-- 4 bytes per pixel

				pixels: as byte-ptr! data + 3
				argb: binary/load pixels size
			][throw-error data]
			
			slot: as red-image! ALLOC_TAIL(parent)
			slot/header: TYPE_UNSET						;-- ensures GC-safety
			slot/head: data/2
			slot/size: data/3
			slot/node: OS-image/make-image width height null null null
			
			slot/header: TYPE_IMAGE
			if nl? [slot/header: slot/header or flag-new-line]
			
			image/set-data slot argb EXTRACT_ARGB
			
			as int-ptr! pixels + size
		]
	]
	
	;-- Misc. --
	
	;-- tuple!
	
	decode-tuple: func [
		data	[int-ptr!]
		end		[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			tuple [red-tuple!]
			size  [integer!]
	][
		if data + 4 > end [throw-error data]
		size: data/1 >>> 8 and FFh
		tuple: as red-tuple! ALLOC_TAIL(parent)
		tuple/header: TYPE_TUPLE or (size << 19)
		if nl? [tuple/header: tuple/header or flag-new-line]
		tuple/array1: data/2
		tuple/array2: data/3
		tuple/array3: data/4
		data + 4
	]
	
	;-- money!
	
	decode-money: func [
		data	[int-ptr!]
		end		[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			slot [red-money!]
			cur	 [byte-ptr!]
			neg? [logic!]
	][
		if data + 4 > end [throw-error data]
		neg?: data/1 and REDBIN_MONEY_SIGN_MASK <> 0
		cur: as byte-ptr! data + 1
		slot: money/make-in ALLOC_TAIL(parent) neg? as-integer cur/1 cur + 1
		if nl? [slot/header: slot/header or flag-new-line]
		data + 4
	]
	
	;-- bitset!
	
	encode-bitset: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		/local
			bits   [red-bitset!]
			series [series!]
			length [integer!]
	][
		bits:   as red-bitset! data
		length: (bitset/length? bits) >> 3			;-- in bytes
		series: GET_BUFFER(bits)
		
		if FLAG_NOT?(series) [header: header or REDBIN_COMPLEMENT_MASK]
		store payload header
		
		unless header and REDBIN_REFERENCE_MASK <> 0 [
			store payload length
			emit payload bitset/rs-head bits length
			pad payload 32
		]
	]
	
	decode-bitset: func [
		data    [int-ptr!]
		end		[int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			slot   [red-bitset!]
			tail   [int-ptr!]
			bits   [byte-ptr!]
			size   [integer!]
			not?   [logic!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			tail: decode-reference data + 1 end parent
			slot: as red-bitset! (block/rs-tail parent) - 1
			if nl? [slot/header: slot/header or flag-new-line]
			tail
		][
			if data + 2 > end [throw-error data]
			size: data/2
			not?: data/1 and REDBIN_COMPLEMENT_MASK <> 0
			bits: as byte-ptr! data + 2
			
			slot: as red-bitset! binary/load-in bits size parent
			if nl? [slot/header: slot/header or flag-new-line]
			set-type as red-value! slot TYPE_BITSET
			if not? [set-flag slot/node flag-bitset-not]
			
			as int-ptr! align bits + size 32		;-- align at upper 32-bit boundary
		]
	]
	
	decode-fat: func [
		p       [byte-ptr!]
		iend    [byte-ptr!]								;-- real input end (null = trusted boot payload, unbounded)
		parent  [red-block!]
		table?  [logic!]
		/local
			p4			[int-ptr!]
			table		[int-ptr!]
			end			[byte-ptr!]
			count len i	[integer!]
			not-set?	[logic!]
	][
		if all [iend <> null (as-integer iend - p) < 8][	;-- fat count+len occupy two 4-byte fields
			fire [TO_ERROR(script invalid-data) stack/arguments]
		]
		p4: as int-ptr! p
		
		count: p4/1									;-- read records number
		len: p4/2									;-- read records size in bytes
		p4: p4 + 2									;-- skip both fields
		p: as byte-ptr! p4
		
		;----------------
		;-- get symbol table if we have it.
		;----------------
		table: null
		if table? [
			table: either codec? [p4 + 2][build-symbol-table p4]	;-- payload is never modified
			p: p + 8 + (p4/1 * 4 + p4/2)
		]
		
		;----------------
		;-- decode values
		;----------------
		end: p + len
		#if debug? = yes [if verbose > 0 [i: 0]]
		
		origin: parent								;-- track root block for references
		while [p < end][
			#if debug? = yes [
				p4: as int-ptr! p
				not-set?: p4/1 and REDBIN_SET_MASK = 0
				if verbose > 0 [print [i #":"]]
			]
			p: as byte-ptr! decode-value as int-ptr! p as int-ptr! end table parent
			#if debug? = yes [if verbose > 0 [if not-set? [i: i + 1] print lf]]
		]
		if all [not codec? table <> null][free as byte-ptr! table]
	]
	
	;-- Compact format --

	throw-error-cp: func [p [byte-ptr!]][
		fire [TO_ERROR(script rb-invalid-record) integer/push 1 + as-integer p - as byte-ptr! input] ;-- 1-based byte offset (ptr-space subtraction, item 21)
	]

	read-byte: func [									;-- byte into cp-val; returns the advanced cursor
		p   [byte-ptr!]
		end [byte-ptr!]
		return: [byte-ptr!]
	][
		if p >= end [throw-error-cp p]
		cp-val: as-integer p/1
		p + 1
	]

	read-varint: func [									;-- LEB128 uint32 into cp-val; returns advanced cursor
		p   [byte-ptr!]
		end [byte-ptr!]
		return: [byte-ptr!]
		/local
			v b shift [integer!]
	][
		v: 0
		shift: 0
		until [
			if p >= end [throw-error-cp p]
			b: as-integer p/1
			p: p + 1
			if all [shift = 28 b and F0h <> 0][throw-error-cp p]	;-- overflows 32 bits or 6th byte
			v: v or ((b and 7Fh) << shift)
			shift: shift + 7
			b and 80h = 0
		]
		cp-val: v
		p
	]

	read-svarint: func [								;-- zigzag signed varint into cp-val
		p   [byte-ptr!]
		end [byte-ptr!]
		return: [byte-ptr!]
		/local
			v [integer!]
	][
		p: read-varint p end
		v: cp-val
		cp-val: (v >>> 1) xor (0 - (v and 1))
		p
	]

	read-u32: func [									;-- 4 bytes little-endian into cp-val
		p   [byte-ptr!]
		end [byte-ptr!]
		return: [byte-ptr!]
	][
		if 4 > (as-integer end - p) [throw-error-cp p]
		cp-val: (as-integer p/1)
			or ((as-integer p/2) << 8 )
			or ((as-integer p/3) << 16)
			or ((as-integer p/4) << 24)
		p + 4
	]

	read-sym: func [									;-- symbol index -> interned ID in cp-val, lazily like fat
		p     [byte-ptr!]
		end   [byte-ptr!]
		table [int-ptr!]								;-- in-place per-symbol offsets array (4-byte LE each)
		return: [byte-ptr!]
		/local
			idx [integer!]
			q   [byte-ptr!]
			ofs [integer!]
	][
		p: read-varint p end
		idx: cp-val
		if any [null? table idx < 0 idx >= sym-count][throw-error-cp p]
		q: (as byte-ptr! table) + (idx << 2)			;-- offset[idx], read LE unaligned (compact has no padding)
		ofs: (as-integer q/1)
			or ((as-integer q/2) << 8)
			or ((as-integer q/3) << 16)
			or ((as-integer q/4) << 24)

		if any [ofs < 0 ofs >= sym-str-size][throw-error-cp p]	;-- offset must land inside the strings blob
		q: (as byte-ptr! table) + (sym-count << 2) + ofs	;-- strings blob follows the offsets array
		cp-val: symbol/make as c-string! q
		p
	]

	read-reference-cp: func [							;-- varint waypoints -> target value in cp-ref
		p   [byte-ptr!]
		end [byte-ptr!]
		return: [byte-ptr!]
		/local
			count [integer!]
			q     [int-ptr!]
	][
		p: read-varint p end
		count: cp-val
		if count <= 0 [throw-error-cp p]
		if count > REDBIN_CP_MAX_REFS [throw-error-cp p]	;-- anti-DoS: bound the cp-refs allocation
		if count > (as-integer end - p) [throw-error-cp p]	;-- each waypoint is >= 1 byte
		if count > cp-refs-sz [							;-- grow only; realloc reuses/extends the block
			cp-refs-sz: count + 32
			cp-refs: as int-ptr! realloc as byte-ptr! cp-refs cp-refs-sz << 2	;-- realloc(null,…) = malloc
		]
		q: cp-refs
		loop count [
			p: read-varint p end
			q/value: cp-val
			q: q + 1
		]
		cp-ref: resolve-path cp-refs count p
		p
	]

	emit-byte: func [
		buffer [red-binary!]
		value  [integer!]
	][
		binary/rs-append buffer as byte-ptr! :value 1	;-- little-endian: low byte first
	]

	emit-varint: func [									;-- LEB128, value taken as 32-bit unsigned
		buffer [red-binary!]
		value  [integer!]
		/local
			b [integer!]
	][
		until [
			b: value and 7Fh
			value: value >>> 7
			if value <> 0 [b: b or 80h]
			emit-byte buffer b
			zero? value
		]
	]

	emit-svarint: func [								;-- zigzag-mapped signed varint
		buffer [red-binary!]
		value  [integer!]
	][
		emit-varint buffer (value << 1) xor (value >> 31)
	]

	emit-tag: func [
		buffer [red-binary!]
		type   [integer!]
		mod?   [logic!]
		/local
			flag [integer!]
	][
		flag: either mod? [REDBIN_CP_MODIFIER][0]
		either type < REDBIN_CP_ESCAPE [
			emit-byte buffer type or flag
		][
			emit-byte buffer REDBIN_CP_ESCAPE or flag
			emit-varint buffer type
		]
	]

	encode-reference-cp: func [							;-- varint waypoint path, no leading tag:
		reference [int-ptr!]							;-- position after a REF-marked record implies it
		payload   [red-binary!]
		/local
			p     [int-ptr!]
			count [integer!]
	][
		count: reference/1
		emit-varint payload count
		p: reference + 1
		loop count [
			emit-varint payload p/value
			p: p + 1
		]
	]

	resolve-path: func [								;-- walk a reference path to its target value
		offset  [int-ptr!]
		count   [integer!]
		pos     [byte-ptr!]								;-- input position of the reference, for error reporting
		return: [red-value!]
		/local
			resolve [subroutine!]
			value   [red-value!]
			object  [red-object!]
			ctx     [red-context!]
			blk     [red-block! value]
			rblk    [red-block!]
			node    [node!]
			series  [series!]
			s-head  [red-value!]
			s-tail  [red-value!]
			n       [integer!]
			type    [integer!]
	][
		value: as red-value! origin
		
		resolve: [
			if all [offset/value <> 0 offset/value <> 1][throw-error-cp pos]	;-- spec (0) or body (1) only
			either as logic! offset/value [				;-- body
				if type <> TYPE_FUNCTION [throw-error-cp pos]
				
				node:   as node! value/data3
				series: as series! node/value
				value:  series/offset
				
				if TYPE_OF(value) <> TYPE_BLOCK [throw-error-cp pos]
				value
			][											;-- spec
				if all [type <> TYPE_FUNCTION type <> TYPE_OP][throw-error-cp pos]
				
				offset: offset + 1
				count:  count  - 1
				node:   as node! value/data2
				
				either zero? count [
					blk/node: node
					blk/head: 0
					blk/header: TYPE_BLOCK
					as red-value! blk
				][
					series: as series! node/value
					n: (as-integer series/tail - series/offset) >> log-b size? cell!
					if any [offset/value < 0 offset/value >= n][throw-error-cp pos]
					series/offset + offset/value
				]
			]
		]
		
		while [count > 0][
			type:  TYPE_OF(value)
			s-head: null
			s-tail: null								;-- null => function/op branch: no index add
			value: switch type [
				TYPE_ANY_BLOCK
				TYPE_MAP [
					rblk: as red-block! value
					series: GET_BUFFER(rblk)
					s-head: series/offset
					s-tail: series/tail
					s-head									;-- head element; an empty origin is rejected by the bounds check below (never assert in rs-abs-at)
				]
				TYPE_ERROR
				TYPE_OBJECT [
					object: as red-object! value
					ctx: GET_CTX(object)
					series: as series! ctx/values/value
					s-head: series/offset
					s-tail: series/tail
					either type = TYPE_ERROR [
						series/offset + error/field-arg1
					][
						series/offset
					]
				]
				TYPE_ANY_WORD
				TYPE_REFINEMENT [
					node: as node! value/data1
					ctx: TO_CTX(node)
					either ON_STACK?(ctx) [
						value: as red-value! ctx + 1
						type:  TYPE_OF(value)
						if type <> TYPE_FUNCTION [throw-error-cp pos]
						resolve
					][
						series: as series! ctx/values/value
						s-head: series/offset
						s-tail: series/tail
						series/offset
					]
				]
				TYPE_ACTION
				TYPE_NATIVE [
					rblk: as red-block! value
					series: GET_BUFFER(rblk)
					s-head: series/offset
					s-tail: series/tail
					s-head
				]
				TYPE_FUNCTION
				TYPE_OP [
					resolve
				]
				default [
					throw-error-cp pos
					value								;-- keep the compiler type-checker happy
				]
			]
			
			unless any [type = TYPE_FUNCTION type = TYPE_OP][
				if null? s-tail [throw-error-cp pos]
				n: (as-integer s-tail - s-head) >> log-b size? cell!	;-- element count bounds the waypoint
				if any [offset/value < (0 - n) offset/value > n][throw-error-cp pos]
				value: value + offset/value
				if any [value < s-head value >= s-tail][throw-error-cp pos]	;-- result must be a live element
			]
			offset: offset + 1
			count:  count  - 1
		]
		value
	]

	encode-cp: func [
		data    [red-value!]
		return: [red-binary!]
		/local
			payload out     [red-binary!]
			symbols strings [red-binary!]
			size            [integer!]
			str-size        [integer!]
			count flags     [integer!]
			p               [byte-ptr!]
			ofs             [integer!]
	][
		codec?: yes
		offset: 0
		
		reset
		
		;-- payload
		payload: binary/make-at stack/push* size? cell!
		symbols: binary/make-at stack/push* 4
		strings: binary/make-at stack/push* 4
		
		encode-value-cp data payload symbols null strings
		size:	  binary/rs-length? payload
		count:	  (binary/rs-length? symbols) >> 2
		str-size: binary/rs-length? strings
		
		;-- Redbin header + symbol table + records
		out: binary/make-at stack/push* 24 + (count << 2) + str-size + size
		emit out header 7								;-- magic + version
		flags: REDBIN_COMPACT_MASK
		unless zero? count [flags: flags or REDBIN_SYMBOL_TABLE_MASK]
		emit-byte out flags
		emit-varint out 1								;-- always 1 root record
		emit-varint out size
		unless zero? count [
			emit-varint out count
			emit-varint out str-size
			p:   binary/rs-head strings					;-- per-symbol offsets (4-byte LE), read in place by the decoder
			ofs: 0
			loop count [
				emit-byte out ofs and FFh
				emit-byte out ofs >>> 8 and FFh
				emit-byte out ofs >>> 16 and FFh
				emit-byte out ofs >>> 24 and FFh
				while [p/1 <> null-byte][p: p + 1  ofs: ofs + 1]
				p:   p + 1  ofs: ofs + 1
			]
			emit out binary/rs-head strings str-size
		]
		emit out binary/rs-head payload size
		
		stack/pop 4
		
		reset
		out
	]

	decode-compact: func [
		p       [byte-ptr!]
		iend    [byte-ptr!]								;-- real input end (null = trusted boot payload, unbounded)
		parent  [red-block!]
		table?  [logic!]
		/local
			cpos       [byte-ptr!]						;-- read cursor, threaded into decode-value-cp on the stack
			cend       [byte-ptr!]						;-- input end (the collector fixes both up on a compaction)
			table      [int-ptr!]
			count len  [integer!]
			nsyms sz   [integer!]
			rem        [integer!]
			q          [byte-ptr!]
	][
		cpos: p
		cend: p + 20									;-- provisional guard over the two header varints
		if all [iend <> null cend > iend][cend: iend]
		cpos: read-varint cpos cend count: cp-val		;-- number of root records
		cpos: read-varint cpos cend len:   cp-val		;-- records size in bytes

		nsyms: 0
		sz:    0
		if table? [
			cend: cpos + 20								;-- provisional guard over the two table varints
			if all [iend <> null cend > iend][cend: iend]
			cpos: read-varint cpos cend nsyms: cp-val
			cpos: read-varint cpos cend sz:    cp-val
			if any [nsyms < 0 sz < 0][throw-error-cp cpos]
			if iend <> null [							;-- the offsets array + strings blob must fit the input
				rem: as-integer iend - cpos
				if nsyms > (rem >> 2) [throw-error-cp cpos]			;-- nsyms*4 fits (guards nsyms<<2 overflow too)
				if sz > (rem - (nsyms << 2)) [throw-error-cp cpos]	;-- strings blob fits after the offsets
				if sz > 0 [
					q: cpos + (nsyms << 2) + sz - 1
					if q/1 <> null-byte [throw-error-cp cpos]		;-- strings blob NUL-terminated within bounds
				]
			]
		]

		table: null
		sym-count: 0
		sym-str-size: 0
		if table? [										;-- read the symbol table in place, like fat (no interning here):
			table: as int-ptr! cpos						;-- per-symbol offsets array (4-byte LE each)
			cpos:  cpos + (nsyms << 2)					;-- read-sym derives the strings base from table itself
			cpos:  cpos + sz
			sym-count: nsyms
			sym-str-size: sz
		]
		
		if all [iend <> null len > (as-integer iend - cpos)][throw-error-cp cpos]	;-- records section must fit the input
		cend: cpos + len
		origin: parent									;-- track root block for references
		while [cpos < cend][cpos: decode-value-cp cpos cend table parent]
	]

	encode-float: func [
		data    [red-value!]
		type    [integer!]
		payload [red-binary!]
		/local
			fl     [red-float!]
			f      [float!]
			k      [integer!]
			whole? [logic!]
	][
		fl: as red-float! data
		f:  fl/value
		whole?: no
		k: 0
		either type = TYPE_PERCENT [					;-- short form: hundredths, round-trip checked
			if all [f >= -21474836.0 f <= 21474836.0][
				k: as-integer either f >= 0.0 [f * 100.0 + 0.5][f * 100.0 - 0.5]
				whole?: f = ((as-float k) / 100.0)
			]
		][
			if all [f >= -2147483000.0 f <= 2147483000.0][
				k: as-integer f
				whole?: f = as-float k
			]
		]
		if all [whole? k = 0][							;-- -0.0 keeps the 8-byte form
			whole?: data/data3 and 80000000h = 0
		]
		either whole? [
			emit-tag payload type yes
			emit-svarint payload k
		][
			emit-tag payload type no
			store payload data/data2					;-- IEEE-754 binary64, little-endian
			store payload data/data3
		]
	]

	encode-value-cp: func [
		data    [red-value!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			node    [node!]
			ref buf [int-ptr!]
			p       [byte-ptr!]
			type    [integer!]
			v n     [integer!]
			first?  [logic!]
			global? [logic!]
			ref?    [logic!]
	][
		type: TYPE_OF(data)
		if data/header and flag-new-line <> 0 [emit-byte payload REDBIN_CP_NL]
		#if debug? = yes [if verbose > 0 [loop indent << 2 [prin " "] probe ["<< type: " type]]]

		switch type [
			TYPE_UNSET
			TYPE_NONE		[emit-tag payload type no]
			TYPE_DATATYPE	[
				emit-tag payload type no
				emit-varint payload data/data1
			]
			TYPE_LOGIC		[
				emit-byte payload either zero? data/data1 [REDBIN_CP_FALSE][REDBIN_CP_TRUE]
			]
			TYPE_INTEGER	[
				v: data/data2
				either all [v >= 0 v <= 63][
					emit-byte payload REDBIN_CP_INT0 + v
				][
					emit-tag payload type no
					emit-svarint payload v
				]
			]
			TYPE_CHAR		[
				emit-tag payload type no
				emit-varint payload data/data2
			]
			TYPE_PAIR		[
				emit-tag payload type no
				emit-svarint payload data/data2
				emit-svarint payload data/data3
			]
			TYPE_POINT2D	[
				emit-tag payload type no
				store payload data/data1
				store payload data/data2
			]
			TYPE_POINT3D	[
				emit-tag payload type no
				store payload data/data1
				store payload data/data2
				store payload data/data3
			]
			TYPE_PERCENT
			TYPE_TIME
			TYPE_FLOAT 		[encode-float data type payload]
			TYPE_DATE 		[
				v: data/data1
				either v and 00010000h = 0 [			;-- time? flag clear: 4-byte form
					emit-tag payload type no
					store payload v
				][
					emit-tag payload type yes
					store payload v
					store payload data/data2			;-- IEEE-754 binary64, little-endian
					store payload data/data3
				]
			]
			TYPE_TYPESET	[
				buf: system/stack/allocate 3
				buf/1: data/data1
				buf/2: data/data2
				buf/3: data/data3
				p: as byte-ptr! buf
				n: 12
				while [all [n > 0 p/n = null-byte]][n: n - 1]	;-- trim trailing zero bytes
				emit-tag payload type no
				emit-byte payload n
				unless zero? n [emit payload p n]
			]
			TYPE_TUPLE		[
				n: TUPLE_SIZE?(data)
				either n = 3 [
					emit-tag payload type no
				][
					emit-tag payload type yes
					emit-byte payload n
				]
				emit payload (as byte-ptr! data) + 4 n
			]
			TYPE_MONEY		[
				emit-tag payload type 1 = money/get-sign as red-money! data
				emit payload (as byte-ptr! data) + 4 12	;-- currency byte + 11 nibble bytes
			]
			TYPE_ISSUE		[
				emit-tag payload type no
				emit-varint payload encode-symbol-cp data table symbols strings
			]
			TYPE_ERROR		[encode-error-cp data payload symbols table strings]
			TYPE_OP			[encode-op-cp data payload symbols table strings]
			TYPE_NATIVE
			TYPE_ACTION 	[encode-native-cp data payload symbols table strings]
			TYPE_PORT
			TYPE_TRIPLE
			TYPE_HANDLE
			TYPE_EVENT
			TYPE_ROUTINE 	[
				reset
				fire [TO_ERROR(access no-codec) data]
			]
			default			[
				first?:  any [ALL_WORD?(type) type = TYPE_OBJECT type = TYPE_FUNCTION]
				node:    as node! either first? [data/data1][data/data2]
				ref:     reference/fetch node
				global?: all [first? node = global-ctx]
				ref?:    no
				
				unless global? [
					either null? ref [
						path/push
						reference/store node
					][
						ref?: yes
						emit-byte payload REDBIN_CP_REF
					]
				]
				
				switch type [
					TYPE_ANY_STRING
					TYPE_VECTOR
					TYPE_BINARY		[encode-string-cp data type ref? payload]
					TYPE_BITSET		[encode-bitset-cp data type ref? payload]
					TYPE_IMAGE		[encode-image-cp data type ref? payload]
					TYPE_ANY_WORD
					TYPE_REFINEMENT	[encode-word-cp data type ref? payload symbols table strings]
					TYPE_ANY_BLOCK	[encode-block-cp data type ref? payload symbols table strings]
					TYPE_MAP		[encode-map-cp data type ref? payload symbols table strings]
					TYPE_OBJECT		[encode-object-cp data type ref? payload symbols table strings]
					TYPE_FUNCTION	[encode-function-cp data type ref? payload symbols table strings]
					default			[assert false]
				]
				
				unless global? [either null? ref [path/pop][encode-reference-cp ref payload]]
			]
		]

		offset: offset + 1
	]

	encode-context-cp: func [
		data    [red-value!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			ctx          [red-context!]
			value        [red-value!]
			values words [series!]
			flags length [integer!]
			stack?       [logic!]
			values?      [logic!]
	][
		#if debug? = yes [if verbose > 0 [loop indent << 2 [prin " "] probe "<< type: context!"]]

		ctx:     as red-context! data
		stack?:  ON_STACK?(ctx)
		values?: no
		
		flags: GET_CTX_TYPE(ctx)
		if stack? [flags: flags or REDBIN_CP_CTX_STACK]
		if ctx/header and flag-self-mask <> 0 [flags: flags or REDBIN_CP_CTX_SELF]
		
		words:  _hashtable/get-ctx-words ctx
		length: (as integer! words/tail - words/offset) >> log-b size? cell!
		
		unless stack? [
			values: as series! ctx/values/value
			value:  values/offset
			loop length [								;-- pre-scan for presence of values
				values?: TYPE_OF(value) <> TYPE_UNSET
				if values? [flags: flags or REDBIN_CP_CTX_VALUES break]
				value: value + 1
			]
		]
		
		emit-tag payload TYPE_CONTEXT no
		emit-byte payload flags
		emit-varint payload length
		
		value: words/offset
		loop length [
			emit-varint payload encode-symbol-cp value table symbols strings
			value: value + 1
		]
		
		unless stack? [
			if values? [
				value: values/offset
				loop length [
					encode-value-cp value payload symbols table strings
					value: value + 1
				]
			]
		]
	]

	encode-object-cp: func [
		data    [red-value!]
		type    [integer!]
		ref?    [logic!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			object [red-object!]
			change [red-pair!]
			deep   [red-pair!]
			ctx    [red-value!]
			buffer [series!]
			owner? [logic!]
	][
		object: as red-object! data
		owner?: all [not ref? not null? object/on-set]
		
		emit-tag payload type owner?
		
		unless ref? [
			#if debug? = yes [indent: indent + 1]
			emit-svarint payload object/class
			if owner? [
				buffer: as series! object/on-set/value
				change: as red-pair! buffer/offset
				deep:   as red-pair! buffer/offset + 1
				
				emit-svarint payload change/x
				emit-svarint payload deep/x
			]
			
			ctx: as red-value! TO_CTX(object/ctx)
			encode-context-cp ctx payload symbols table strings
			#if debug? = yes [indent: indent - 1]
		]
	]

	encode-error-cp: func [
		data    [red-value!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			err   [red-object!]
			base  [red-value!]
			code  [red-integer!]
			index [integer!]
	][
		err:  as red-object! data
		base: object/get-values err
		code: as red-integer! base + error/field-code
		
		path/push
		reference/store err/ctx
		emit-tag payload TYPE_ERROR no
		emit-varint payload code/value
		
		index: error/field-arg1
		until [
			encode-value-cp base + index payload symbols table strings
			index: index + 1
			index > error/field-stack
		]
		path/pop
	]

	encode-native-cp: func [
		data    [red-value!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			slot  [red-block! value]
			here  [int-ptr!]
			index [integer!]
	][
		here: either TYPE_OF(data) = TYPE_NATIVE [natives/table][actions/table]
		index: 0
		until [index: index + 1 data/data1 = here/index]
		emit-tag payload TYPE_OF(data) no
		emit-varint payload index
		
		slot/head: 0
		slot/node: as node! data/data2
		slot/header: TYPE_BLOCK
		
		encode-value-cp as red-value! slot payload symbols table strings
		offset: offset - 1
	]

	encode-op-cp: func [
		data    [red-value!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			header [integer!]
	][
		;@@ TBD: #4563
		if GET_OP_SUBTYPE(data) = TYPE_ROUTINE [reset fire [TO_ERROR(access no-codec) data]]
		emit-tag payload TYPE_OP no						;-- subtype derived from the underlying record
		
		header: data/header
		set-type data GET_OP_SUBTYPE(data)
		encode-value-cp data payload symbols table strings
		data/header: header
		offset: offset - 1								;-- compensate for extra recursion
	]

	encode-function-cp: func [
		data    [red-value!]
		type    [integer!]
		ref?    [logic!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			fun      [red-function!]
			ctx body [red-value!]
			series   [series!]
			size     [integer!]
	][
		emit-tag payload type no
		unless ref? [
			fun: as red-function! data
			ctx: as red-value! GET_CTX(fun)
			series: as series! fun/more/value
			body: series/offset
			assert TYPE_OF(body) = TYPE_BLOCK
			
			size: block/rs-length? as red-block! body
			series: as series! fun/spec/value
			
			emit-varint payload (as integer! series/tail - series/offset) >> size? integer!
			emit-varint payload size
			
			encode-context-cp   ctx  payload symbols table strings
			encode-spec-body-cp data body payload symbols table strings
		]
	]

	encode-spec-body-cp: func [
		spec    [red-value!]
		body    [red-value!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			data [red-value!]
			slot [red-block! value]
			old  [integer!]
	][
		old: offset
		
		slot/head: 0
		slot/node: as node! spec/data2
		slot/header: TYPE_BLOCK
		
		offset: 0										;-- form artifical paths to spec and body blocks
		data: as red-value! slot
		encode-value-cp data payload symbols table strings
		
		offset: 1
		data: body
		encode-value-cp data payload symbols table strings
		
		offset: old
	]

	encode-word-cp: func [
		data    [red-value!]
		type    [integer!]
		ref?    [logic!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			value  [red-value!]
			ref	   [red-value!]
			ctx	   [red-context!]
			node   [node!]
			series [series!]
			vtype  [integer!]
	][
		node: as node! data/data1
		
		;@@ TBD: #4537
		if null? node [node: global-ctx]
		
		ctx: TO_CTX(node)
		ref: as red-value! ctx + 1
		vtype: TYPE_OF(ref)
		if any [										;-- native function context case
			vtype = TYPE_NONE
			vtype = TYPE_UNSET
			vtype = TYPE_BLOCK
		][
			node: global-ctx
		]
		
		either all [node = global-ctx not ref?][		;-- canonical form: global binding, symbol only
			emit-tag payload type no
			emit-varint payload encode-symbol-cp data table symbols strings
		][
			emit-tag payload type yes
			emit-varint payload encode-symbol-cp data table symbols strings
			emit-svarint payload data/data3
			
			unless ref? [								;-- inline context carrier record
				series: as series! node/value
				value:  series/offset + 1
				vtype:  TYPE_OF(value)
				
				;@@ TBD: #4552
				if TYPE_OF(series/offset) = TYPE_OBJECT [
					reset
					fire [TO_ERROR(access no-codec) data]
				]
				switch vtype [
					TYPE_OBJECT	  [encode-object-cp value vtype no payload symbols table strings]
					TYPE_FUNCTION [encode-function-cp value vtype no payload symbols table strings]
					TYPE_BLOCK	  [0]					;-- function's spec cache block, do nothing
					default		  [assert false]
				]
			]
		]
	]

	encode-symbol-cp: func [
		data    [red-value!]
		table   [red-binary!]
		symbols [red-binary!]
		strings [red-binary!]
		return: [integer!]
		/local
			_symbol    [red-symbol!]
			start here [int-ptr!]
			string     [c-string!]
			length     [integer!]
			end id     [integer!]
	][
		start: as int-ptr! binary/rs-head symbols
		end:   (binary/rs-length? symbols) >> 2
		id:    0
		
		while [id < end][								;-- reuse symbol records when possible
			here: start + id
			if here/value = data/data2 [break]
			id: id + 1
		]
		if id = end [
			_symbol: symbol/get data/data2
			string:  as c-string! (as series! _symbol/cache/value) + 1
			
			store symbols data/data2
			emit strings as byte-ptr! string (length? string) + 1	;-- UTF-8 + NUL, no padding
		]
		id
	]

	encode-block-cp: func [
		data    [red-value!]
		type    [integer!]
		ref?    [logic!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			series [red-series!]
			value  [red-value!]
			buffer [series!]
			length [integer!]
	][
		series: as red-series! data
		buffer: GET_BUFFER(series)
		length: _series/get-length series yes
		value:  buffer/offset
		
		emit-tag payload type data/data1 <> 0
		if data/data1 <> 0 [emit-varint payload data/data1]
		
		unless ref? [
			emit-varint payload length
			#if debug? = yes [indent: indent + 1]
			loop length [
				encode-value-cp value payload symbols table strings
				value:  value + 1
			]
			#if debug? = yes [indent: indent - 1]
		]
	]

	encode-map-cp: func [
		data    [red-value!]
		type    [integer!]
		ref?    [logic!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			series [red-series!]
			value  [red-value!]
			key	   [red-value!]
			buffer [series!]
			length [integer!]
	][
		series: as red-series! data
		emit-tag payload type no
		
		unless ref? [
			length: map/rs-length? as red-hash! series
			emit-varint payload length * 2
			
			#if debug? = yes [indent: indent + 1]

			buffer: GET_BUFFER(series)
			key: buffer/offset
			length: _series/get-length series yes
			length: length / 2
			loop length [
				value: key + 1
				if value/header <> MAP_KEY_DELETED [
					encode-value-cp key payload symbols table strings
					encode-value-cp value payload symbols table strings
				]
				key: value + 1
			]
			#if debug? = yes [indent: indent - 1]
		]
	]

	encode-string-cp: func [
		data    [red-value!]
		type    [integer!]
		ref?    [logic!]
		payload [red-binary!]
		/local
			series [red-series!]
			buffer [series!]
			value  [byte-ptr!]
			length [integer!]
			unit   [integer!]
	][
		series: as red-series! data
		buffer: GET_BUFFER(series)
		unit:   GET_UNIT(buffer)
		length: _series/get-length series yes
		value:  as byte-ptr! buffer/offset
		
		emit-tag payload type data/data1 <> 0
		if data/data1 <> 0 [emit-varint payload data/data1]
		
		unless ref? [
			either type = TYPE_BINARY [
				emit-varint payload length
				unless zero? length [emit payload value length]
			][
				either type = TYPE_VECTOR [
					emit-byte payload data/data3 << 2 or log-b unit
					emit-varint payload length
					unless zero? length [emit payload value length << log-b unit]
				][										;-- any-string!: raw UCS-1/2/4, unit packed into length
					emit-varint payload length << 2 or log-b unit
					unless zero? length [emit payload value length << log-b unit]
				]
			]
		]
	]

	encode-image-cp: func [
		data    [red-value!]
		type    [integer!]
		ref?    [logic!]
		payload [red-binary!]
		/local
			argb [red-binary!]
	][
		emit-tag payload type data/data1 <> 0
		if data/data1 <> 0 [emit-varint payload data/data1]
		
		unless ref? [
			argb: image/extract-data as red-image! data EXTRACT_ARGB
			emit-varint payload IMAGE_WIDTH(data/data3)
			emit-varint payload IMAGE_HEIGHT(data/data3)
			emit payload binary/rs-head argb binary/rs-length? argb
		]
	]

	encode-bitset-cp: func [
		data    [red-value!]
		type    [integer!]
		ref?    [logic!]
		payload [red-binary!]
		/local
			bits   [red-bitset!]
			series [series!]
			length [integer!]
	][
		bits:   as red-bitset! data
		length: (bitset/length? bits) >> 3				;-- in bytes
		series: GET_BUFFER(bits)
		
		emit-tag payload type FLAG_NOT?(series)
		
		unless ref? [
			emit-varint payload length
			emit payload bitset/rs-head bits length
		]
	]

	decode-binding-cp: func [							;-- consume an object!/function! carrier record,
		p         [byte-ptr!]
		end       [byte-ptr!]
		table     [int-ptr!]							;-- building context + back-reference structures
		parent    [red-block!]							;-- null: no back-reference copy (word carrier)
		nl?       [logic!]
		type      [integer!]
		mod?      [logic!]
		bind-word [red-word!]							;-- word to bind to the context before values fill (or null)
		return:   [byte-ptr!]							;-- advanced cursor (callers ignore the built node)
		/local
			context         [red-context!]
			object          [red-object!]
			fun             [red-function!]
			proto spec body [red-block!]
			values-blk cell [red-block!]
			series vseries  [series!]
			node values     [node!]
			tag flags slots [integer!]
			kind size new   [integer!]
			class on1 on2   [integer!]
			spec-sz body-sz [integer!]
			id              [integer!]
			owner? stack?   [logic!]
			self? values?   [logic!]
			filled?         [logic!]
	][
		assert any [type = TYPE_OBJECT type = TYPE_FUNCTION]
		
		owner?: no
		class: 0 on1: 0 on2: 0
		spec-sz: 0 body-sz: 0
		either type = TYPE_OBJECT [
			owner?: mod?
			p: read-svarint p end class: cp-val
			if owner? [
				p: read-svarint p end on1: cp-val
				p: read-svarint p end on2: cp-val
			]
		][
			p: read-varint p end spec-sz: cp-val
			p: read-varint p end body-sz: cp-val
		]
		
		p: read-byte p end tag: cp-val					;-- context! record header
		if tag and 3Fh <> TYPE_CONTEXT [throw-error-cp p]
		p: read-byte p end flags: cp-val
		p: read-varint p end slots: cp-val
		if slots < 0 [throw-error-cp p]
		
		kind:	 flags and REDBIN_CP_CTX_KIND_MASK
		stack?:	 flags and REDBIN_CP_CTX_STACK  <> 0
		self?:	 flags and REDBIN_CP_CTX_SELF   <> 0
		values?: flags and REDBIN_CP_CTX_VALUES <> 0
		
		values: either stack? [null][
			size: either zero? slots [1][slots]
			alloc-unset-cells size
		]
		node: alloc-unset-cells 2
		series: as series! node/value
		
		context: as red-context! alloc-tail series
		context/header: TYPE_UNSET
		context/symbols: _hashtable/init slots null HASH_TABLE_SYMBOL HASH_SYMBOL_CONTEXT
		context/values: values
		
		context/header: TYPE_CONTEXT
		SET_CTX_TYPE(context kind)
		if self?  [context/header: context/header or flag-self-mask]
		if stack? [context/header: context/header or flag-series-stk]
		
		either type = TYPE_OBJECT [
			object: as red-object! alloc-tail series
			object/header: TYPE_UNSET
			object/ctx:    node
			object/class:  either codec? [-1][class]	;@@ TBD: concurrent class IDs — codec (untrusted) forces a fresh id; boot keeps the stored one
			object/on-set: either owner? [alloc-cells 2][null]
			
			if owner? [
				vseries: as series! object/on-set/value
				vseries/tail: vseries/offset + 2
				pair/make-at vseries/offset on1 0
				pair/make-at vseries/offset + 1 on2 0
			]
			object/header: TYPE_OBJECT
		][
			proto: block/push-only* 2
			size: either zero? spec-sz [1][spec-sz]
			spec: block/make-in proto size
			size: either zero? body-sz [1][body-sz]
			body: block/make-in proto size
			
			fun: as red-function! alloc-tail series
			fun/header: TYPE_UNSET
			fun/ctx:    node
			fun/spec:   spec/node
			fun/more:   alloc-unset-cells 5
			
			vseries: as series! fun/more/value
			vseries/tail: vseries/offset + 5
			copy-cell as red-value! body vseries/offset
			stack/pop 1
			
			fun/header: TYPE_FUNCTION
		]
		if parent <> null [								;-- object!/function! used as a value
			cell: as red-block! copy-cell series/offset + 1 ALLOC_TAIL(parent)
			if nl? [cell/header: cell/header or flag-new-line]
		]
		
		if bind-word <> null [bind-word/ctx: node]		;-- wire the word's binding before values decode, so self-references through it resolve (cycle-10)
		
		filled?: all [not stack? values?]				;-- fill symbols, then values if present
		if filled? [
			values-blk: block/push-only* slots
			values-blk/node: context/values
			
			vseries: as series! context/values/value
			vseries/tail: vseries/offset
		]
		new: 0
		loop slots [									;-- all symbols first, then all values
			p: read-sym p end table id: cp-val
			_context/find-or-store context id yes :new
		]
		if filled? [
			loop slots [p: decode-value-cp p end table values-blk]
			stack/pop 1
			vseries/tail: vseries/offset + slots
		]
		if type = TYPE_FUNCTION [						;-- fill spec/body on the value actually used:
			either parent <> null [						;-- the parent copy, else the node-internal fun
				p: fill-spec-body-cp p end table as red-function! cell	;-- (a referral spec replaces the node
			][											;-- pointer, which the copy would otherwise miss)
				p: fill-spec-body-cp p end table as red-function! series/offset + 1
			]
		]
		p
	]

	read-spec-block-cp: func [							;-- consume a spec/body block record
		p       [byte-ptr!]
		end     [byte-ptr!]
		table   [int-ptr!]
		slot    [red-block!]							;-- decode destination (existing buffer)
		cell    [red-block!]							;-- referral form: resolved block copied here
		return: [byte-ptr!]								;-- advanced cursor (referral flag in `dec-ref?`)
		/local
			value    [red-value!]
			tag size [integer!]
			ref?     [logic!]
	][
		ref?: no
		while [
			if p >= end [throw-error-cp p]
			tag: as-integer p/1
			any [tag = REDBIN_CP_NL tag = REDBIN_CP_REF]
		][
			if tag = REDBIN_CP_REF [ref?: yes]			;-- new-line flags are void on spec/body slots
			p: p + 1
		]
		p: read-byte p end tag: cp-val
		if tag and 3Fh <> TYPE_BLOCK [throw-error-cp p]
		if tag and REDBIN_CP_MODIFIER <> 0 [p: read-varint p end]	;-- head: always zero for spec/body
		
		either ref? [
			p: read-reference-cp p end
			value: cp-ref
			copy-cell value as red-value! cell
			if TYPE_OF(cell) <> TYPE_BLOCK [throw-error-cp p]
		][
			p: read-varint p end size: cp-val
			if size < 0 [throw-error-cp p]
			loop size [p: decode-value-cp p end table slot]
		]
		dec-ref?: ref?
		p
	]

	fill-spec-body-cp: func [
		p     [byte-ptr!]
		end   [byte-ptr!]
		table [int-ptr!]
		fun   [red-function!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			slot cell [red-block!]
			series    [series!]
			ref?      [logic!]
	][
		cell: as red-block! stack/push*					;-- scratch cell for referral resolution
		cell/header: TYPE_UNSET
		
		slot: as red-block! stack/push*
		slot/head: 0
		slot/node: fun/spec
		slot/header: TYPE_BLOCK
		p: read-spec-block-cp p end table slot cell
		ref?: dec-ref?
		if ref? [fun/spec: cell/node]					;-- refresh node pointer to a referenced buffer
		
		slot: as red-block! (as series! fun/more/value) + 1
		p: read-spec-block-cp p end table slot cell
		ref?: dec-ref?
		if ref? [slot/node: cell/node]
		
		stack/pop 2
		p
	]

	decode-word-cp: func [								;-- version-2 grammar (codec)
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		type   [integer!]
		mod?   [logic!]
		ref?   [logic!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			word new [red-word!]
			op       [red-op!]
			value    [red-value!]
			series   [series!]
			node     [node!]
			sym idx  [integer!]
			type2    [integer!]
			ctag     [integer!]
	][
		either mod? [
			p: read-sym p end table sym: cp-val
			p: read-svarint p end idx: cp-val
			either ref? [
				p: read-reference-cp p end value: cp-ref
				word: as red-word! copy-cell value ALLOC_TAIL(parent)
				
				type2: TYPE_OF(word)
				assert any [							;-- copy over context node from these slots
					type2 = TYPE_OBJECT
					type2 = TYPE_FUNCTION
					type2 = TYPE_OP
					ANY_WORD?(type2)
				]
				if type2 = TYPE_OP [					;-- locate function! slot
					op: as red-op! word
					assert GET_OP_SUBTYPE(op) = TYPE_FUNCTION
					node: as node! op/code
					series: as series! node/value
					copy-cell as red-value! series/offset + 3 as red-value! word
					assert TYPE_OF(word) = TYPE_FUNCTION
				]
				word/header: TYPE_UNSET
				word/symbol: sym
				word/index:  idx
			][
				word: as red-word! ALLOC_TAIL(parent)
				word/header: type						;-- set now: the binding resolves through it during fill
				word/symbol: sym
				word/index:  idx
				
				p: read-byte p end ctag: cp-val			;-- inline context carrier record
				type2: ctag and 3Fh
				unless any [type2 = TYPE_OBJECT type2 = TYPE_FUNCTION][throw-error-cp p]
				p: decode-binding-cp p end table null no type2 ctag and REDBIN_CP_MODIFIER <> 0 word
			]
		][
			p: read-sym p end table sym: cp-val			;-- canonical form: global binding
			word: as red-word! ALLOC_TAIL(parent)
			word/header: TYPE_UNSET
			new: _context/add-global-word sym yes no
			word/symbol: sym
			word/index:  new/index
			word/ctx:    global-ctx
		]
		word/header: type
		if nl? [word/header: word/header or flag-new-line]
		p
	]

	decode-word1-cp: func [								;-- version-1 grammar (boot payload)
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		type   [integer!]
		mod?   [logic!]
		gset?  [logic!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			new w   [red-word!]
			obj     [red-object!]
			s       [series!]
			sym idx [integer!]
			ctx ofs [integer!]
	][
		p: read-sym p end table sym: cp-val
		new: as red-word! ALLOC_TAIL(parent)
		new/header: TYPE_UNSET
		new/symbol: sym
		
		either mod? [
			p: read-varint p end ctx: cp-val			;-- context record index among roots
			p: read-svarint p end idx: cp-val
			obj: as red-object! block/rs-abs-at root ctx + root-offset
			assert TYPE_OF(obj) = TYPE_OBJECT
			new/ctx: obj/ctx
			new/index: either idx = -1 [
				_context/find-word TO_CTX(obj/ctx) sym yes
			][
				idx
			]
		][
			new/ctx: global-ctx
			w: _context/add-global-word sym yes no
			new/index: w/index
		]
		new/header: type
		if nl? [new/header: new/header or flag-new-line]
		
		if gset? [										;-- global-set: value record follows
			ofs: block/rs-length? parent
			p: decode-value-cp p end table parent
			_context/set new block/rs-abs-at root ofs
			s: GET_BUFFER(parent)
			s/tail: s/offset + (ofs - 1)				;-- drop both word and value from parent
		]
		p
	]

	decode-context-cp: func [							;-- root-level context! record (boot payload)
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			ctx     [red-context!]
			obj     [red-object!]
			values  [red-block!]
			s       [series!]
			new     [node!]
			flags   [integer!]
			slots   [integer!]
			kind id [integer!]
			i       [integer!]
			values? [logic!]
			stack?  [logic!]
			self?   [logic!]
	][
		p: read-byte p end flags: cp-val
		p: read-varint p end slots: cp-val
		if slots < 0 [throw-error-cp p]
		
		kind:	 flags and REDBIN_CP_CTX_KIND_MASK
		stack?:	 flags and REDBIN_CP_CTX_STACK  <> 0
		self?:	 flags and REDBIN_CP_CTX_SELF   <> 0
		values?: flags and REDBIN_CP_CTX_VALUES <> 0
		
		new: _context/create slots stack? self? null kind
		
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
		i: 0
		loop slots [									;-- all symbols first, then all values
			p: read-sym p end table id: cp-val
			_context/find-or-store ctx id yes :i
		]
		if all [not stack? values?][
			loop slots [p: decode-value-cp p end table values]
		]
		if values? [
			s/tail: s/offset + slots
			stack/pop 1									;-- drop unwanted block
		]
		p
	]

	decode-object-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		mod?   [logic!]
		ref?   [logic!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			last   [red-object!]
			object [red-value!]
			value  [red-value!]
			series [series!]
			type   [integer!]
	][
		either ref? [
			p: read-reference-cp p end value: cp-ref
			last: as red-object! copy-cell value ALLOC_TAIL(parent)
			
			type: TYPE_OF(last)
			assert any [type = TYPE_OBJECT ANY_WORD?(type)]
			
			series: as series! last/ctx/value
			object: copy-cell series/offset + 1 as red-value! last
			if nl? [object/header: object/header or flag-new-line]
			p
		][
			decode-binding-cp p end table parent nl? TYPE_OBJECT mod? null
		]
	]

	decode-function-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		ref?   [logic!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			fun    [red-function!]
			value  [red-value!]
			source [red-value!]
			series [series!]
			type   [integer!]
	][
		either ref? [
			p: read-reference-cp p end value: cp-ref
			fun: as red-function! copy-cell value ALLOC_TAIL(parent)
			
			type: TYPE_OF(fun)
			assert any [type = TYPE_FUNCTION type = TYPE_OP ANY_WORD?(type)]
			either type = TYPE_OP [
				fun/header: TYPE_FUNCTION
			][
				series: as series! fun/ctx/value
				source: series/offset + 1
				copy-cell source as red-value! fun
			]
			if nl? [fun/header: fun/header or flag-new-line]
			p
		][
			decode-binding-cp p end table parent nl? TYPE_FUNCTION no null
		]
	]

	decode-block-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		type   [integer!]
		mod?   [logic!]
		ref?   [logic!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			blk   [red-block!]
			value [red-value!]
			head  [integer!]
			size  [integer!]
			sz    [integer!]
	][
		either mod? [p: read-varint p end head: cp-val][head: 0]
		if head < 0 [throw-error-cp p]
		
		either ref? [
			p: read-reference-cp p end value: cp-ref
			blk: as red-block! copy-cell value ALLOC_TAIL(parent)
			blk/header: type
			if nl? [blk/header: blk/header or flag-new-line]
			blk/head: head
		][
			p: read-varint p end size: cp-val
			if any [size < 0 size > (as-integer end - p)][throw-error-cp p]	;-- each element needs >= 1 byte
			sz: size
			if zero? sz [sz: 1]
			
			blk: block/make-in parent sz
			blk/head: head
			blk/header: type
			if nl? [blk/header: blk/header or flag-new-line]
			
			loop size [p: decode-value-cp p end table blk]
		]
		p
	]

	decode-hash-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		mod?   [logic!]
		ref?   [logic!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			hash  [red-hash!]
			value [red-value!]
			head  [integer!]
			size  [integer!]
			sz    [integer!]
	][
		either mod? [p: read-varint p end head: cp-val][head: 0]
		if head < 0 [throw-error-cp p]
		
		either ref? [
			p: read-reference-cp p end value: cp-ref
			hash: as red-hash! copy-cell value ALLOC_TAIL(parent)
			if nl? [hash/header: hash/header or flag-new-line]
			hash/head: head
		][
			p: read-varint p end size: cp-val
			if any [size < 0 size > (as-integer end - p)][throw-error-cp p]	;-- each element needs >= 1 byte
			sz: size
			if zero? sz [sz: 1]
			
			hash: as red-hash! block/make-at as red-block! ALLOC_TAIL(parent) sz
			hash/head: head
			hash/table: _hashtable/init sz as red-block! hash HASH_TABLE_HASH 1
			
			hash/header: TYPE_HASH
			if nl? [hash/header: hash/header or flag-new-line]
			
			loop size [p: decode-value-cp p end table as red-block! hash]
			_hashtable/put-all hash/table hash/head 1
		]
		p
	]

	decode-map-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		ref?   [logic!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			blk   [red-block!]
			m     [red-hash!]
			value [red-value!]
			size  [integer!]
			sz    [integer!]
	][
		either ref? [
			p: read-reference-cp p end value: cp-ref
			blk: as red-block! copy-cell value ALLOC_TAIL(parent)
			if nl? [blk/header: blk/header or flag-new-line]
		][
			p: read-varint p end size: cp-val
			if any [size < 0 size > (as-integer end - p)][throw-error-cp p]	;-- each element needs >= 1 byte
			sz: size
			if zero? sz [sz: 1]
			
			blk: block/make-at as red-block! ALLOC_TAIL(parent) sz
			if nl? [blk/header: blk/header or flag-new-line]
			m: map/make-at as red-value! blk blk sz
			
			loop size [p: decode-value-cp p end table blk]
			_hashtable/put-all m/table m/head 2
		]
		p
	]

	decode-string-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		type   [integer!]
		mod?   [logic!]
		ref?   [logic!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			str   [red-string!]
			value [red-value!]
			s     [series!]
			head  [integer!]
			unit  [integer!]
			size  [integer!]
	][
		either mod? [p: read-varint p end head: cp-val][head: 0]
		if head < 0 [throw-error-cp p]

		either ref? [
			p: read-reference-cp p end value: cp-ref
			str: as red-string! copy-cell value ALLOC_TAIL(parent)
			str/header: type
			if nl? [str/header: str/header or flag-new-line]
			str/head: head
		][
			p: read-varint p end size: cp-val			;-- char-length << 2 | log2(unit)
			if any [size < 0 (size and 3) = 3][throw-error-cp p]	;-- unit is 1/2/4 (log2 0/1/2), never 8
			unit: 1 << (size and 3)
			size: size >>> 2							;-- char count
			if size > ((as-integer end - p) >> log-b unit) [throw-error-cp p]	;-- each char = unit bytes
			size: size << log-b unit					;-- raw byte-length (overflow-free)

			str: as red-string! ALLOC_TAIL(parent)		;-- cell-first, as unset: GC-safe alloc+copy (like fat)
			str/header: TYPE_UNSET
			str/head: 	head
			str/node: 	alloc-bytes size
			str/cache:	null							;-- strings carry a c-string cache; clear the fresh cell's

			s: GET_BUFFER(str)
			s/flags: s/flags and flag-unit-mask or unit
			s/tail: as red-value! (as byte-ptr! s/offset) + size
			unless zero? size [copy-memory as byte-ptr! s/offset p size]
			p: p + size

			str/header: type
			if nl? [str/header: str/header or flag-new-line]
		]
		p
	]

	decode-binary-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		mod?   [logic!]
		ref?   [logic!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			bin   [red-binary!]
			value [red-value!]
			s     [series!]
			head  [integer!]
			size  [integer!]
	][
		either mod? [p: read-varint p end head: cp-val][head: 0]
		if head < 0 [throw-error-cp p]
		
		either ref? [
			p: read-reference-cp p end value: cp-ref
			bin: as red-binary! copy-cell value ALLOC_TAIL(parent)
			bin/header: TYPE_BINARY
			if nl? [bin/header: bin/header or flag-new-line]
			bin/head: head
		][
			p: read-varint p end size: cp-val
			if any [size < 0 size > (as-integer end - p)][throw-error-cp p]
			
			bin: as red-binary! ALLOC_TAIL(parent)
			bin/header: TYPE_UNSET
			bin/head: 	head
			bin/node: 	alloc-bytes size
			
			s: GET_BUFFER(bin)
			unless zero? size [copy-memory as byte-ptr! s/offset p size]
			s/flags: s/flags and flag-unit-mask or 1
			s/tail: as cell! (as byte-ptr! s/offset) + size
			p: p + size
			
			bin/header: TYPE_BINARY
			if nl? [bin/header: bin/header or flag-new-line]
		]
		p
	]

	decode-vector-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		mod?   [logic!]
		ref?   [logic!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			vec    [red-vector!]
			value  [red-value!]
			buffer [series!]
			head   [integer!]
			elem   [integer!]
			unit   [integer!]
			size   [integer!]
	][
		either mod? [p: read-varint p end head: cp-val][head: 0]
		if head < 0 [throw-error-cp p]
		
		either ref? [
			p: read-reference-cp p end value: cp-ref
			vec: as red-vector! copy-cell value ALLOC_TAIL(parent)
			if nl? [vec/header: vec/header or flag-new-line]
			vec/head: head
		][
			p: read-byte p end elem: cp-val
			unit: 1 << (elem and 3)
			p: read-varint p end size: cp-val
			if size < 0 [throw-error-cp p]
			if size > ((as-integer end - p) >> log-b unit) [throw-error-cp p]	;-- each element = unit bytes
			size: size << log-b unit					;-- in bytes (overflow-free)
			
			vec: as red-vector! ALLOC_TAIL(parent)
			vec/header: TYPE_UNSET
			vec/head: 	head
			vec/node: 	alloc-bytes size
			vec/type:	elem >> 2
			
			buffer: GET_BUFFER(vec)
			buffer/flags: buffer/flags and flag-unit-mask or unit
			buffer/tail: as red-value! (as byte-ptr! buffer/offset) + size
			
			unless zero? size [copy-memory as byte-ptr! buffer/offset p size]
			p: p + size
			
			vec/header: TYPE_VECTOR
			if nl? [vec/header: vec/header or flag-new-line]
		]
		p
	]

	decode-bitset-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		mod?   [logic!]									;-- complemented set
		ref?   [logic!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			slot  [red-bitset!]
			value [red-value!]
			size  [integer!]
	][
		either ref? [
			p: read-reference-cp p end value: cp-ref
			slot: as red-bitset! copy-cell value ALLOC_TAIL(parent)
			if nl? [slot/header: slot/header or flag-new-line]
		][
			p: read-varint p end size: cp-val
			if any [size < 0 size > (as-integer end - p)][throw-error-cp p]
			
			slot: as red-bitset! binary/load-in p size parent
			if nl? [slot/header: slot/header or flag-new-line]
			set-type as red-value! slot TYPE_BITSET
			if mod? [set-flag slot/node flag-bitset-not]
			p: p + size
		]
		p
	]

	decode-image-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		mod?   [logic!]
		ref?   [logic!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			slot   [red-image!]
			value  [red-value!]
			argb   [red-binary!]
			head   [integer!]
			width  [integer!]
			height [integer!]
			size   [integer!]
	][
		either mod? [p: read-varint p end head: cp-val][head: 0]
		if head < 0 [throw-error-cp p]
		
		either ref? [
			p: read-reference-cp p end value: cp-ref
			slot: as red-image! copy-cell value ALLOC_TAIL(parent)
			if nl? [slot/header: slot/header or flag-new-line]
			slot/head: head
		][
			p: read-varint p end width:  cp-val
			p: read-varint p end height: cp-val
			if any [width < 0 width > FFFFh height < 0 height > FFFFh][throw-error-cp p]
			
			if all [width > 0 height > ((as-integer end - p) >> 2 / width)][throw-error-cp p]	;-- w*h*4 fits, overflow-free
			size: width * height << 2
			if size > (as-integer end - p) [throw-error-cp p]
			
			argb: binary/load p size
			
			slot: as red-image! ALLOC_TAIL(parent)
			slot/header: TYPE_UNSET						;-- ensures GC-safety
			slot/head: head
			slot/size: height << 16 or width
			slot/node: OS-image/make-image width height null null null
			
			slot/header: TYPE_IMAGE
			if nl? [slot/header: slot/header or flag-new-line]
			
			image/set-data slot argb EXTRACT_ARGB
			p: p + size
		]
		p
	]

	decode-native-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		type   [integer!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			cell  [red-native!]
			spec  [red-block!]
			value [red-value!]
			index [integer!]
			more  [series!]
			node  [node!]
	][
		p: read-varint p end index: cp-val
		if index < 1 [throw-error-cp p]
		cell: as red-native! ALLOC_TAIL(parent)
		
		if codec? [parent: block/push-only* 1]			;-- redirect slot allocation
		spec: as red-block! block/rs-tail parent
		p: decode-value-cp p end table parent
		if TYPE_OF(spec) <> TYPE_BLOCK [throw-error-cp p]
		
		cell/header: TYPE_UNSET
		cell/spec:	 spec/node
		cell/code:   either type = TYPE_ACTION [actions/table/index][natives/table/index]
		cell/more:	 alloc-unset-cells 2
		cell/header: type								;-- implicit reset of all header flags
		
		more: as series! cell/more/value
		node: _context/make spec yes no CONTEXT_FUNCTION
		copy-cell as red-value! (as series! node/value) + 1 alloc-tail more	;-- ctx slot
		value: alloc-tail more							;-- args cache slot
		value/header: TYPE_UNSET
		
		if nl? [cell/header: cell/header or flag-new-line]
		if codec? [stack/pop 1]							;-- drop an unwanted block
		p
	]

	decode-op-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			op  [red-op!]
			sub [integer!]
	][
		op: as red-op! block/rs-tail parent
		p: decode-value-cp p end table parent			;-- underlying function!/native!/action! record
		sub: TYPE_OF(op)
		op/header: op/header and flag-subtype-mask or (sub << 16 and flag-subtype-select)
		set-type as red-value! op TYPE_OP
		if nl? [op/header: op/header or flag-new-line]
		p
	]

	decode-error-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		nl?    [logic!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			err     [red-object!]
			ctx     [red-context!]
			scratch [red-block!]
			series  [series!]
			code    [integer!]
	][
		p: read-varint p end code: cp-val
		err: error/make null as red-value! integer/box code TYPE_ERROR
		err: as red-object! copy-cell as red-value! err ALLOC_TAIL(parent)
		if nl? [err/header: err/header or flag-new-line]
		
		ctx: GET_CTX(err)
		series: as series! ctx/values/value
		series/tail: series/offset + 3
		
		scratch: block/push-only* 6
		scratch/node: ctx/values
		
		loop 6 [p: decode-value-cp p end table scratch]
		
		series/tail: series/offset + 9
		stack/pop 1
		p
	]

	decode-value-cp: func [
		p      [byte-ptr!]
		end    [byte-ptr!]
		table  [int-ptr!]
		parent [red-block!]
		return: [byte-ptr!]								;-- advanced cursor
		/local
			cell    [cell!]
			value   [red-value!]
			w       [red-word!]
			buf fp  [int-ptr!]
			tag typ [integer!]
			v n     [integer!]
			lo hi d [integer!]
			f       [float!]
			mod?    [logic!]
			nl?     [logic!]
			ref?    [logic!]
			gset?   [logic!]
	][
		if p >= end [throw-error-cp p]
		nl?: ref?: gset?: no
		while [
			tag: as-integer p/1
			any [tag = REDBIN_CP_NL tag = REDBIN_CP_REF tag = REDBIN_CP_GSET]
		][
			p: p + 1
			if p >= end [throw-error-cp p]
			if tag = REDBIN_CP_NL   [nl?: yes]
			if tag = REDBIN_CP_REF  [ref?: yes]
			if tag = REDBIN_CP_GSET [
				if codec? [throw-error-cp p]			;-- version-1 streams only
				gset?: yes
			]
		]
		p: p + 1										;-- consume the tag byte
		#if debug? = yes [if verbose > 0 [print [#"<" tag and 3Fh #">"]]]
		
		cell: null
		either tag >= REDBIN_CP_INT0 [
			if any [ref? gset?][throw-error-cp p]
			either tag < REDBIN_CP_NL [
				cell: as cell! integer/make-in parent tag and 3Fh	;-- integer! immediate 0-63
			][
				switch tag [
					REDBIN_CP_TRUE  [cell: as cell! logic/make-in parent yes]
					REDBIN_CP_FALSE [cell: as cell! logic/make-in parent no]
					REDBIN_REFERENCE [
						p: read-reference-cp p end		;-- standalone reference record
						value: cp-ref
						cell: copy-cell value ALLOC_TAIL(parent)
					]
					default [throw-error-cp p]			;-- reserved tags
				]
			]
		][
			mod?: tag and REDBIN_CP_MODIFIER <> 0
			typ: tag and 3Fh
			if typ = REDBIN_CP_ESCAPE [p: read-varint p end typ: cp-val]
			if zero? typ [throw-error-cp p]
			
			if all [gset? not ALL_WORD?(typ)][throw-error-cp p]
			
			switch typ [
				TYPE_INTEGER	[p: read-svarint p end cell: as cell! integer/make-in parent cp-val]
				TYPE_CHAR		[p: read-varint p end cell: as cell! char/make-in parent cp-val]
				TYPE_DATATYPE	[p: read-varint p end cell: as cell! datatype/make-in parent cp-val]
				TYPE_UNSET		[cell: as cell! unset/make-in parent]
				TYPE_NONE		[cell: as cell! none/make-in parent]
				TYPE_PAIR		[
					p: read-svarint p end v: cp-val
					p: read-svarint p end n: cp-val
					cell: as cell! pair/make-in parent v n
				]
				TYPE_POINT2D	[
					cell: ALLOC_TAIL(parent)
					cell/header: TYPE_UNSET
					p: read-u32 p end cell/data1: cp-val
					p: read-u32 p end cell/data2: cp-val
					cell/data3: 0
					cell/header: TYPE_POINT2D
				]
				TYPE_POINT3D	[
					cell: ALLOC_TAIL(parent)
					cell/header: TYPE_UNSET
					p: read-u32 p end cell/data1: cp-val
					p: read-u32 p end cell/data2: cp-val
					p: read-u32 p end cell/data3: cp-val
					cell/header: TYPE_POINT3D
				]
				TYPE_FLOAT
				TYPE_PERCENT
				TYPE_TIME		[
					either mod? [						;-- whole-number short form
						p: read-svarint p end v: cp-val
						f: as-float v
						if typ = TYPE_PERCENT [f: f / 100.0]
						fp: as int-ptr! :f
						lo: fp/1
						hi: fp/2
					][
						p: read-u32 p end lo: cp-val
						p: read-u32 p end hi: cp-val
					]
					switch typ [
						TYPE_FLOAT	 [cell: as cell! float/make-in   parent hi lo]
						TYPE_PERCENT [cell: as cell! percent/make-in parent hi lo]
						TYPE_TIME	 [cell: as cell! time/make-in    parent hi lo]
					]
				]
				TYPE_DATE		[
					p: read-u32 p end d: cp-val
					either d and 00010000h = 0 [		;-- time? flag
						if mod? [throw-error-cp p]
						lo: 0
						hi: 0
					][
						unless mod? [throw-error-cp p]
						p: read-u32 p end lo: cp-val
						p: read-u32 p end hi: cp-val
					]
					cell: as cell! date/make-in parent d hi lo
				]
				TYPE_TYPESET	[
					p: read-byte p end n: cp-val
					if n > 12 [throw-error-cp p]
					if n > (as-integer end - p) [throw-error-cp p]
					buf: system/stack/allocate 3
					buf/1: 0
					buf/2: 0
					buf/3: 0
					unless zero? n [copy-memory as byte-ptr! buf p n]
					p: p + n
					cell: as cell! typeset/make-in parent buf/1 buf/2 buf/3
				]
				TYPE_TUPLE		[
					either mod? [p: read-byte p end n: cp-val][n: 3]
					if any [n < 1 n > 12 n > (as-integer end - p)][throw-error-cp p]
					cell: ALLOC_TAIL(parent)
					cell/header: TYPE_UNSET
					cell/data1: 0
					cell/data2: 0
					cell/data3: 0
					copy-memory (as byte-ptr! cell) + 4 p n
					p: p + n
					cell/header: TYPE_TUPLE or (n << 19)
				]
				TYPE_MONEY		[
					if 12 > (as-integer end - p) [throw-error-cp p]
					cell: as cell! money/make-in ALLOC_TAIL(parent) mod? as-integer p/1 p + 1
					p: p + 12
				]
				TYPE_ISSUE		[
					p: read-sym p end table v: cp-val
					w: as red-word! ALLOC_TAIL(parent)
					w/header: TYPE_UNSET
					w/symbol: v
					w/header: TYPE_ISSUE
					cell: as cell! w
				]
				TYPE_WORD
				TYPE_SET_WORD
				TYPE_LIT_WORD
				TYPE_GET_WORD
				TYPE_REFINEMENT [
					either codec? [
						p: decode-word-cp p end table parent typ mod? ref? nl?
					][
						p: decode-word1-cp p end table parent typ mod? gset? nl?
					]
				]
				TYPE_CONTEXT	[p: decode-context-cp p end table parent]
				TYPE_BLOCK
				TYPE_PAREN
				TYPE_PATH
				TYPE_LIT_PATH
				TYPE_SET_PATH
				TYPE_GET_PATH	[p: decode-block-cp  p end table parent typ mod? ref? nl?]
				TYPE_HASH		[p: decode-hash-cp   p end table parent mod? ref? nl?]
				TYPE_MAP		[p: decode-map-cp    p end table parent ref? nl?]
				TYPE_STRING
				TYPE_FILE
				TYPE_URL
				TYPE_TAG
				TYPE_EMAIL
				TYPE_REF		[p: decode-string-cp p end table parent typ mod? ref? nl?]
				TYPE_BINARY		[p: decode-binary-cp p end table parent mod? ref? nl?]
				TYPE_VECTOR		[p: decode-vector-cp p end table parent mod? ref? nl?]
				TYPE_BITSET		[p: decode-bitset-cp p end table parent mod? ref? nl?]
				TYPE_IMAGE		[p: decode-image-cp  p end table parent mod? ref? nl?]
				TYPE_ERROR		[p: decode-error-cp  p end table parent nl?]
				TYPE_NATIVE
				TYPE_ACTION		[p: decode-native-cp p end table parent typ nl?]
				TYPE_OP			[p: decode-op-cp     p end table parent nl?]
				TYPE_OBJECT		[p: decode-object-cp p end table parent mod? ref? nl?]
				TYPE_FUNCTION	[p: decode-function-cp p end table parent ref? nl?]
				TYPE_PORT
				TYPE_ROUTINE
				TYPE_HANDLE
				TYPE_EVENT
				TYPE_TRIPLE [
					reset
					fire [TO_ERROR(access no-codec) datatype/push typ]
				]
				default [throw-error-cp p]
			]
		]
		if all [nl? cell <> null][cell/header: cell/header or flag-new-line]
		p
	]

	
	;-- error processing
	
	throw-error: func [pos [int-ptr!]][
		fire [TO_ERROR(script rb-invalid-record) integer/push 1 + as-integer pos - input] ;-- 1-based indexes
	]
]
