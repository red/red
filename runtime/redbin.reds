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

	#define REDBIN_NATIVE_MASK			00800000h
	#define REDBIN_BODY_MASK			00400000h
	#define REDBIN_COMPLEMENT_MASK		00200000h
	#define REDBIN_MONEY_SIGN_MASK		00100000h

	#define REDBIN_REFERENCE_MASK		00080000h
	
	;-- Special record types
	
	#enum redbin-value-type! [
		REDBIN_PADDING: 	0
		REDBIN_REFERENCE: 	255
	]
	
	;-- Top-level declarations
	
	origin:      declare red-block!
	buffer:		 as byte-ptr! 0
	root-base:	 as red-value! 0
	
	root-offset: 0
	offset:      0
	codec?:      no
	
	header: #{
		52454442494E								;-- REDBIN magic
		02											;-- version
		00											;-- placeholder for flags
		00000000									;-- placeholder for length (bytes)
		00000000									;-- placeholder for size (number of root records)
	}
		
	;-- Support --
	
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

		on-gc-mark: does [_hashtable/mark map]
		
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
				map: _hashtable/init 1024 null HASH_TABLE_INTEGER 1
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
		parent  [red-block!]
		return: [int-ptr!]
		/local
			resolve [subroutine!]
			value   [red-value!]
			object  [red-object!]
			ctx     [red-context!]
			blk     [red-block! value]
			node    [node!]
			series  [series!]
			offset  [int-ptr!]
			count   [integer!]
			type    [integer!]
	][
		value:  as red-value! origin
		offset: data + 2
		count:  data/2
		
		resolve: [
			assert any [offset/value = 0 offset/value = 1]
			either as logic! offset/value [			;-- body
				assert type = TYPE_FUNCTION
				
				node:   as node! value/data3
				series: as series! node/value
				value:  series/offset
				
				assert TYPE_OF(value) = TYPE_BLOCK
				value
			][										;-- spec
				assert any [type = TYPE_FUNCTION type = TYPE_OP]
				
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
					series/offset + offset/value
				]
			]
		]
		
		while [count > 0][
			type:  TYPE_OF(value)
			value: switch type [
				TYPE_ANY_BLOCK
				TYPE_MAP [
					block/rs-abs-at as red-block! value 0
				]
				TYPE_OBJECT [
					object: as red-object! value
					ctx: GET_CTX(object)
					series: as series! ctx/values/value
					series/offset
				]
				TYPE_ANY_WORD
				TYPE_REFINEMENT [
					node: as node! value/data1
					ctx: TO_CTX(node)
					either ON_STACK?(ctx) [
						value: as red-value! ctx + 1
						type:  TYPE_OF(value)
						assert type = TYPE_FUNCTION
						resolve
					][
						series: as series! ctx/values/value
						series/offset
					]
				]
				TYPE_ACTION
				TYPE_NATIVE [
					block/rs-abs-at as red-block! value 0
				]
				TYPE_FUNCTION
				TYPE_OP [
					resolve
				]
				default [
					assert false
					value							;-- pass compiler's type checking
				]
			]
			
			unless any [type = TYPE_FUNCTION type = TYPE_OP][value: value + offset/value]
			offset: offset + 1
			count:  count  - 1
		]
		
		copy-cell value ALLOC_TAIL(parent)
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
		p: p + 7									;-- skip magic (6 bytes) + version (1 byte)
		compact?:	 (as-integer p/1) and REDBIN_COMPACT_MASK <> 0
		compressed?: (as-integer p/1) and REDBIN_COMPRESSED_MASK <> 0
		sym-table?:  (as-integer p/1) and REDBIN_SYMBOL_TABLE_MASK <> 0
		p: p + 1
		
		if compressed? [p: crush/decompress p null]
		
		p4: as int-ptr! p
		
		count: p4/1									;-- read records number
		len: p4/2									;-- read records size in bytes
		p4: p4 + 2									;-- skip both fields
		p: as byte-ptr! p4
		
		;----------------
		;-- get symbol table if we have it.
		;----------------
		table: null
		if sym-table? [
			unless codec? [preprocess-symbols p4]
			table: p4 + 2
			p: p + 8 + (p4/1 * 4 + p4/2)
		]
		
		;----------------
		;-- decode values
		;----------------
		unless codec? [
			s: GET_BUFFER(parent)
			root-offset: (as-integer s/tail - s/offset) >> log-b size? cell!
		]
		
		end: p + len
		#if debug? = yes [if verbose > 0 [i: 0]]
		
		origin: parent								;-- track root block for references
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
			first?  [logic!]
			global? [logic!]
	][
		type:   TYPE_OF(data)
		header: type or either zero? (data/header and flag-new-line) [0][REDBIN_NEWLINE_MASK]
		header: header or switch type [
			TYPE_TUPLE [TUPLE_SIZE?(data) << 8]
			TYPE_MONEY [(money/get-sign as red-money! data) << 20]
			default    [0]
		]

		switch type [
			TYPE_UNSET
			TYPE_NONE		[store payload header]
			TYPE_DATATYPE
			TYPE_LOGIC 		[record [payload header data/data1]]
			TYPE_INTEGER
			TYPE_CHAR 		[record [payload header data/data2]]
			TYPE_PAIR 		[record [payload header data/data2 data/data3]]
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
			TYPE_POINT
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
					TYPE_ANY_BLOCK
					TYPE_MAP		[encode-block data header payload symbols table strings]
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
			TYPE_REFINEMENT [
				;@@ TBD: incompatible encodings
				either codec? [decode-word* data table parent nl?][decode-word data table parent nl?]
			]
			TYPE_ANY_STRING
			TYPE_BINARY		[decode-string data parent nl?]
			TYPE_INTEGER	[
				cell: as cell! integer/make-in parent data/2
				data + 2
			]
			TYPE_ANY_PATH
			TYPE_BLOCK
			TYPE_PAREN		[decode-block data table parent nl?]
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
			TYPE_HASH		[decode-hash data table parent nl?]
			TYPE_MAP		[decode-map data table parent nl?]
			TYPE_NATIVE
			TYPE_ACTION		[decode-native data table parent nl?]
			TYPE_OP			[decode-op data table parent nl?]
			TYPE_TUPLE		[decode-tuple data parent nl?]
			TYPE_MONEY		[decode-money data parent nl?]
			TYPE_BITSET     [decode-bitset data parent nl?]
			TYPE_VECTOR     [decode-vector data parent nl?]
			TYPE_IMAGE		[decode-image data parent nl?]
			TYPE_ERROR		[decode-error data table parent nl?]
			TYPE_OBJECT		[decode-object data table parent nl?]
			TYPE_FUNCTION	[decode-function data table parent nl?]
			TYPE_PORT
			TYPE_ROUTINE
			TYPE_HANDLE
			TYPE_EVENT
			TYPE_POINT [
				reset
				fire [TO_ERROR(access no-codec) datatype/push type]
				data								;-- pass compiler's type checking
			]
			REDBIN_PADDING [
				decode-value data + 1 table parent
			]
			REDBIN_REFERENCE [
				decode-reference data parent
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
			_context/find-or-store ctx id yes new :i
			if all [not stack? values?][value: decode-value value table values]
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
		
		assert node = context/self
		
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
		
		loop slots [
			sym: table + data/1
			id:  symbol/make (as c-string! table + table/-1) + sym/1
			
			_context/find-or-store context id yes context/self :new
			if filled? [value: decode-value value table values]
			
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
			here            [int-ptr!]
			type kind skip  [integer!]
			values? stack?  [logic!]
			self? owner?    [logic!]
	][
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
		
		assert data/1 and FFh = TYPE_CONTEXT
		tail/value: as integer! data
		
		;-- decode context slot
		values?: data/1 and REDBIN_VALUES_MASK <> 0
		stack?:	 data/1 and REDBIN_STACK_MASK  <> 0
		self?:	 data/1 and REDBIN_SELF_MASK   <> 0
		kind:	 data/1 and REDBIN_KIND_MASK   >> 26
		
		node:   alloc-cells 2
		series: as series! node/value
		values: either stack? [null][alloc-unset-cells either zero? data/2 [1][data/2]]
		
		context: as red-context! alloc-tail series
		context/header: TYPE_UNSET
		context/symbols: _hashtable/init data/2 null HASH_TABLE_SYMBOL HASH_SYMBOL_CONTEXT
		context/values: values
		context/self: node
		
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
			object/class:  data/2					;@@ TBD: potential conflict of concurrent class IDs
			object/on-set: either owner? [alloc-cells 2][null]
			
			if owner? [
				data: data + 2
				
				series: as series! object/on-set/value
				series/tail: series/offset + 2
				
				integer/make-at series/offset data/1
				integer/make-at series/offset + 1 data/2
			]
			
			object/header: TYPE_OBJECT
		][
			proto: block/push-only* 2
			spec:  block/make-in proto either zero? data/2 [1][data/2]
			body:  block/make-in proto either zero? data/3 [1][data/3]
			
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
			change [red-integer!]
			deep   [red-integer!]
			ctx    [red-value!]
			buffer [series!]
			owner? [logic!]
	][
		object: as red-object! data
		owner?: not null? object/on-set
		
		if owner? [header: header or REDBIN_OWNER_MASK]
		
		store payload header
		
		unless header and REDBIN_REFERENCE_MASK <> 0 [
			store payload object/class
			if owner? [
				buffer: as series! object/on-set/value
				change: as red-integer! buffer/offset
				deep:   as red-integer! buffer/offset + 1
				
				record [payload change/value deep/value]
			]
			
			ctx: as red-value! TO_CTX(object/ctx)
			encode-context ctx payload symbols table strings
		]
	]
	
	decode-object: func [
		data    [int-ptr!]
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
			data: decode-reference data + 1 parent
			last: (as red-object! block/rs-tail parent) - 1
			
			type: TYPE_OF(last)
			assert any [type = TYPE_OBJECT ANY_WORD?(type)]
			
			series: as series! last/ctx/value
			object: copy-cell series/offset + 1 as red-value! last
			if nl? [object/header: object/header or flag-new-line]
			
			data
		][
			next: 0
			node: preprocess-binding data table :next
			series: as series! node/value
			
			object: copy-cell series/offset + 1 ALLOC_TAIL(parent)
			if nl? [object/header: object/header or flag-new-line]
			
			fill-context as int-ptr! next table node
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
		
		record [payload header code/value]
		
		index: error/field-arg1
		until [
			encode-value base + index payload symbols table strings
			index: index + 1
			index > error/field-stack
		]
	]
	
	decode-error: func [
		data    [int-ptr!]
		table   [int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			err    [red-object!]
			ctx    [red-context!]
			series [series!]
	][
		err: error/make null as red-value! integer/box data/2 TYPE_ERROR
		err: as red-object! copy-cell as red-value! err ALLOC_TAIL(parent)
		if nl? [err/header: err/header or flag-new-line]
		
		ctx: GET_CTX(err)
		series: as series! ctx/values/value
		series/tail: series/offset + 3
		
		parent: block/push-only* 6
		parent/node: ctx/values 
		
		data: data + 2
		loop 6 [data: decode-value data table parent]
		
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
		until [index: index + 1 data/data3 = here/index]
		
		record [payload header index]
		
		slot/head: 0
		slot/node: as node! data/data2
		slot/header: TYPE_BLOCK
		
		encode-value as red-value! slot payload symbols table strings
		offset: offset - 1
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
			type  [integer!]
			index [integer!]
	][
		type:  data/1 and FFh
		index: data/2
		cell:  as red-native! ALLOC_TAIL(parent)
		
		if codec? [parent: block/push-only* 1]	;-- redirect slot allocation
		spec: as red-block! block/rs-tail parent
		data: decode-block data + 2 table parent off
		
		cell/header: type						;-- implicit reset of all header flags
		cell/spec:	 spec/node
		cell/args:	 null
		cell/code:   either type = TYPE_ACTION [actions/table/index][natives/table/index]
		
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
		/local
			slot    [red-value!]
			series  [series!]
			node    [node!]
			type    [integer!]
			native? [logic!]
			body?   [logic!]
	][
		;@@ TBD: #4563
		native?: data/header and flag-native-op <> 0	;-- native, action
		body?:   data/header and body-flag      <> 0	;-- function, routine
		
		if native? [header: header or REDBIN_NATIVE_MASK]
		if body?   [header: header or REDBIN_BODY_MASK]
		
		store payload header
		
		either body? [
			node:   as node! data/data3
			series: as series! node/value
			slot:   series/offset + 3
			type:   TYPE_OF(slot)
			
			assert any [type = TYPE_FUNCTION type = TYPE_ROUTINE]
			either type = TYPE_FUNCTION [
				encode-value slot payload symbols table strings
			][
				reset
				fire [TO_ERROR(access no-codec) data]
			]
		][
			slot: stack/push*
			slot/data1:  0
			slot/data2:  data/data2
			slot/header: TYPE_BLOCK
			
			encode-value slot payload symbols table strings
			stack/pop 1
			store payload data/data3
		]
		
		offset: offset - 1							;-- compensate for extra recursion
	]
	
	decode-op: func [
		data	[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			op      [red-op!]
			extra   [red-function!]
			spec    [red-block!]
			series  [series!]
			node    [node!]
			next    [integer!]
			native? [logic!]
			body?   [logic!]
	][
		native?: data/1 and REDBIN_NATIVE_MASK <> 0
		body?:   data/1 and REDBIN_BODY_MASK   <> 0
		data:    data + 1
		
		op: as red-op! ALLOC_TAIL(parent)
		op/header: TYPE_UNSET
		
		parent: block/push-only* 1
		
		node: either body? [
			assert data/1 and FFh = TYPE_FUNCTION
			next: 0
			node: preprocess-binding data table :next
			data: fill-context as int-ptr! next table node
			
			series: as series! node/value
			extra:  as red-function! series/offset + 1
			assert TYPE_OF(extra) = TYPE_FUNCTION
			
			series: as series! extra/more/value
			copy-cell as red-value! extra series/offset + 3
			
			extra/spec
		][
			data: decode-block data table parent nl?
			spec: as red-block! block/rs-head parent
			spec/node
		]
		
		op/args:   null
		op/spec:   node
		op/code:   either body? [as integer! extra/more][data/1]
		op/header: TYPE_OP
		
		if nl?     [op/header: op/header or flag-new-line]
		if native? [op/header: op/header or flag-native-op]
		if body?   [op/header: op/header or body-flag]
		
		if body? [
			data: fill-spec-body data table extra
			op/spec: extra/spec						;-- refresh node pointer (case with referenced buffers)
		]
		
		stack/pop 1
		either body? [data][data + 1]
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
			slot [red-value! value]
			old  [integer!]
	][
		old: offset
		
		slot/data1: 0
		slot/data2: spec/data2
		slot/header: TYPE_BLOCK
		
		offset: 0									;-- form artifical paths to spec and body blocks
		data: slot
		encode-value data payload symbols table strings
		
		offset: 1
		data: body
		encode-value data payload symbols table strings
		
		offset: old
	]
	
 	decode-function: func [
		data    [int-ptr!]
		table   [int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			fun    [red-function!]
			source [red-value!]
			series [series!]
			node   [node!]
			size   [int-ptr!]
			next   [integer!]
			type   [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			data: decode-reference data + 1 parent
			fun: (as red-function! block/rs-tail parent) - 1
			
			type: TYPE_OF(fun)
			assert any [type = TYPE_FUNCTION type = TYPE_OP ANY_WORD?(type)]
			either type = TYPE_OP [
				series: as series! fun/more/value
				source: series/offset + 3
				assert TYPE_OF(source) = TYPE_FUNCTION
			][
				series: as series! fun/ctx/value
				source: series/offset + 1
			]
			
			fun: as red-function! copy-cell source as red-value! fun
			if nl? [fun/header: fun/header or flag-new-line]
			
			data
		][
			next: 0
			node: preprocess-binding data table :next
			data: fill-context as int-ptr! next table node
			
			series: as series! node/value
			fun: as red-function! copy-cell series/offset + 1 ALLOC_TAIL(parent)
			if nl? [fun/header: fun/header or flag-new-line]
			
			fill-spec-body data table fun
		]
	]
	
	fill-spec-body: func [
		data    [int-ptr!]
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
			assert data/1 and FFh = TYPE_BLOCK
			ref?:  data/1 and REDBIN_REFERENCE_MASK <> 0
			either ref? [
				data: decode-reference data + 2 parent
				assert TYPE_OF(cell) = TYPE_BLOCK
				series/tail: series/tail - 1
			][
				size: data + 2
				data: size + 1
				loop size/1 [data: decode-value data table slot]
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
			node   [node!]
			series [series!]
			type   [integer!]
	][
		node: as node! data/data1
		
		;@@ TBD: #4537
		if null? node [node: global-ctx]
		
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
				
				assert any [type = TYPE_OBJECT type = TYPE_FUNCTION]
				either type = TYPE_OBJECT [
					encode-object value type payload symbols table strings
				][
					encode-function value type payload symbols table strings
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
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			w	[red-word!]
			sym	[int-ptr!]
	][
		w: as red-word! ALLOC_TAIL(parent)
		sym: table + data/2
		w/symbol: either codec? [symbol/make (as c-string! table + table/-1) + sym/1][sym/1]
		w/header: TYPE_ISSUE
		if nl? [w/header: w/header or flag-new-line]
		data + 2
	]
	
	decode-word: func [								;-- Redbin v.1
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
			data: decode-value data table parent
			_context/set new block/rs-abs-at root offset
			s: GET_BUFFER(parent)
			offset: offset - 1
			s/tail: s/offset + offset				;-- drop unwanted values in parent
		]
		data
	]
	
	decode-word*: func [							;-- Redbin v.2
		data    [int-ptr!]
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
		
		type: data/1 and FFh
		set?: data/1 and REDBIN_SET_MASK <> 0
		ref?: data/1 and REDBIN_REFERENCE_MASK <> 0
		tail: data + 3
		
		either ref? [
			tail: decode-reference tail parent
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
				assert op/header and flag-native-op =  0
				assert op/header and body-flag      <> 0
				
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
			word/ctx: preprocess-binding tail table :next
		]
		
		tag
		data: either set? [tail][fill-context as int-ptr! next table word/ctx]
		
		series:  as series! word/ctx/value
		backref: series/offset + 1
		
		type: backref/header and FFh
		assert any [type = TYPE_OBJECT type = TYPE_FUNCTION]
		
		either type = TYPE_OBJECT [data][fill-spec-body data table as red-function! backref]
	]
	
	;-- SERIES!
	
	;-- block!, paren!, hash!, map!, path!, lit-path!, set-path!, get-path!
	
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
			loop length [
				encode-value value payload symbols table strings
				value:  value + 1
			]
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
			end  [int-ptr!]
			size [integer!]
			sz   [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			end: decode-reference data + 2 parent
			blk: (as red-block! block/rs-tail parent) - 1
			
			blk/header: data/1 and FFh
			if nl? [blk/header: blk/header or flag-new-line]
			blk/head: data/2
			
			end
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
	]
	
	decode-map: func [
		data	[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			blk  [red-block!]
			end  [int-ptr!]
			size [integer!]
			sz   [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			end: decode-reference data + 1 parent
			blk: (as red-block! block/rs-tail parent) - 1
			if nl? [blk/header: blk/header or flag-new-line]
			end
		][
			size: data/2
			sz: size
			if zero? sz [sz: 1]
			#if debug? = yes [if verbose > 0 [print [#":" size #":"]]]
			
			blk: block/make-at as red-block! ALLOC_TAIL(parent) sz
			if nl? [blk/header: blk/header or flag-new-line]
			map/make-at as red-value! blk blk sz
			
			data: data + 2
			loop size [data: decode-value data table blk]
			_hashtable/put-all as node! blk/extra blk/head 2
			
			data
		]
	]
	
	decode-hash: func [
		data	[int-ptr!]
		table	[int-ptr!]
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			hash [red-hash!]
			end  [int-ptr!]
			size [integer!]
			sz   [integer!]
	][
	
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			end: decode-reference data + 2 parent
			hash: (as red-hash! block/rs-tail parent) - 1
			if nl? [hash/header: hash/header or flag-new-line]
			end
		][
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
			loop size [data: decode-value data table as red-block! hash]
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
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			slot   [red-value!]
			vec    [red-vector!]
			buffer [series!]
			end    [int-ptr!]
			values [byte-ptr!]
			unit   [integer!]
			size   [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			end: decode-reference data + 2 parent
			vec: (as red-vector! block/rs-tail parent) - 1
			
			if nl? [vec/header: vec/header or flag-new-line]
			vec/head: data/2
			
			end
		][
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
		parent	[red-block!]
		nl?		[logic!]
		return: [int-ptr!]
		/local
			str    [red-string!]
			end    [int-ptr!]
			header [integer!]
			unit   [integer!]
			size   [integer!]
			s      [series!]
	][	
		header: data/1
		either header and REDBIN_REFERENCE_MASK <> 0 [
			end: decode-reference data + 2 parent
			str: (as red-string! block/rs-tail parent) - 1
			
			str/header: header and FFh
			if nl? [str/header: str/header or flag-new-line]
			str/head: data/2
			
			end
		][
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
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			slot   [red-image!]
			argb   [red-binary!]
			end    [int-ptr!]
			pixels [byte-ptr!]
			width  [integer!]
			height [integer!]
			size   [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			end: decode-reference data + 2 parent
			slot: (as red-image! block/rs-tail parent) - 1
			
			if nl? [slot/header: slot/header or flag-new-line]
			slot/head: data/2
			
			end
		][
			width:  IMAGE_WIDTH(data/3)
			height: IMAGE_HEIGHT(data/3)
			size:   width * height << 2					;-- 4 bytes per pixel
			
			pixels: as byte-ptr! data + 3
			argb:   binary/load pixels size
			
			slot: as red-image! ALLOC_TAIL(parent)
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
	
	;-- money!
	
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
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			slot   [red-bitset!]
			end    [int-ptr!]
			bits   [byte-ptr!]
			size   [integer!]
			not?   [logic!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			end: decode-reference data + 1 parent
			slot: as red-bitset! (block/rs-tail parent) - 1
			if nl? [slot/header: slot/header or flag-new-line]
			end
		][
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
]