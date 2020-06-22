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
#define REDBIN_KIND_MASK			06000000h
#define REDBIN_OWNER_MASK			01000000h

#define REDBIN_REFERENCE_MASK		00020000h
#define REDBIN_MONEY_SIGN_MASK		00010000h

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
			cell/spec:	 spec/node
			cell/args:	 null
			cell/code: either type = TYPE_ACTION [actions/table/index][natives/table/index]
			
			if codec? [stack/pop 1]					;-- drop an unwanted block
		]
		
		if nl? [cell/header: cell/header or flag-new-line]
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
	
	;@@ TBD: remove the cheathseet
	comment {
		word:     header (set?: N ref?: Y) symbol index [reference]
				  header (set?: N ref?: N) symbol index [object]
				  header (set?: Y ref?: N) symbol index -- bound to global context
		
		object:   header (own?: Y) class on-set arity [context]
		          header (own?: N) class [context]
		          header (ref?: Y) [reference]
		
		function: header [spec] [body] [context]
		
		context:  header size symbols* values*
	}
	
	decode-word*: func [
		data    [int-ptr!]
		table   [int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			tag          [subroutine!]
			word new     [red-word!]
			sym end tail [int-ptr!]
			type next    [integer!]
			type2        [integer!]
			set? ref?    [logic!]
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
			end:  decode-reference tail parent
			word: (as red-word! block/rs-tail parent) - 1
			
			type2: TYPE_OF(word)
			assert any [
				type2 = TYPE_OBJECT
				type2 = TYPE_FUNCTION
				all [
					type2 <> TYPE_ISSUE
					ANY_WORD?(type2)
				]
			]
		][
			word: as red-word! ALLOC_TAIL(parent)
		]
		
		sym: table + data/2
		word/header: TYPE_UNSET
		word/symbol: symbol/make (as c-string! table + table/-1) + sym/1
		word/index:  data/3
		
		if ref? [tag return end]
		
		either set? [
			new: _context/add-global-word word/symbol yes no
			word/index: new/index
			word/ctx: global-ctx
		][
			next: 0
			word/ctx: preprocess-binding tail table :next
		]
		
		tag
		either set? [tail][fill-context as int-ptr! next table word/ctx]
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
	
	decode-function: func [
		data    [int-ptr!]
		table   [int-ptr!]
		parent  [red-block!]
		nl?     [logic!]
		return: [int-ptr!]
		/local
			fun    [red-value!]
			series [series!]
			node   [node!]
			next   [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			assert false							;@@ TBD
		][
			next: 0
			node: preprocess-binding data table :next
			series: as series! node/value
			
			fun: copy-cell series/offset + 1 ALLOC_TAIL(parent)
			if nl? [fun/header: fun/header or flag-new-line]
			
			fill-context as int-ptr! next table node
		]
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
		
		stack/pop 1
		if filled? [series/tail: series/offset + slots]
		
		value
	]
	
	preprocess-binding: func [
		data    [int-ptr!]
		table   [int-ptr!]
		tail    [int-ptr!]
		return: [node!]
		/local
			context        [red-context!]
			object         [red-object!]
			fun            [red-function!]
			proto spec     [red-block!]
			body           [red-value!]
			series         [series!]
			node values    [node!]
			here info      [int-ptr!]
			type kind skip [integer!]
			values? stack? [logic!]
			self? owner?   [logic!]
	][
		here: data
		type: data/1 and FFh
		
		assert any [type = TYPE_OBJECT type = TYPE_FUNCTION]
		
		;-- locate context record
		either type = TYPE_OBJECT [
			data: data + 2
			skip: (size? integer!) << 1
			owner?: data/1 and REDBIN_OWNER_MASK <> 0 
			if owner? [data: data + skip]
		][
			proto: block/push-only* 2
			series: as series! proto/node/value
			series/tail: series/offset
			
			data: decode-block data + 1 table proto no
			data: decode-block data table proto no
		]
		
		assert data/1 and FFh = TYPE_CONTEXT
		tail/value: as integer! data
		
		;-- decode context slot
		values?: data/1 and REDBIN_VALUES_MASK <> 0
		stack?:	 data/1 and REDBIN_STACK_MASK  <> 0
		self?:	 data/1 and REDBIN_SELF_MASK   <> 0
		kind:	 data/1 and REDBIN_KIND_MASK   >> 25
		
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
			object/ctx: node
			object/class: data/2					;@@ TBD: potential conflict of concurrent class IDs
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
			spec: as red-block! block/rs-head proto
			body: (block/rs-tail proto) - 1
			
			assert TYPE_OF(spec) = TYPE_BLOCK
			assert TYPE_OF(body) = TYPE_BLOCK
			
			fun: as red-function! alloc-tail series
			fun/header: TYPE_UNSET
			fun/ctx: node
			fun/spec: spec/node
			fun/more: alloc-unset-cells 5
			
			series: as series! fun/more/value
			copy-cell body series/offset
			
			fun/header: TYPE_FUNCTION
			
			stack/pop 1								;-- drop proto block
		]
		
		node
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
		type:	 header and REDBIN_KIND_MASK >> 25
		
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
		neg?: data/1 and REDBIN_MONEY_SIGN_MASK <> 0
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
			end  [int-ptr!]
			bits [byte-ptr!]
			size [integer!]
	][
		either data/1 and REDBIN_REFERENCE_MASK <> 0 [
			end: decode-reference data + 1 parent
			slot: (block/rs-tail parent) - 1
			if nl? [slot/header: slot/header or flag-new-line]
			end
		][
			size: data/2 >> 3							;-- in bytes
			bits: as byte-ptr! data + 2
			
			slot: as red-value! binary/load-in bits size parent
			if nl? [slot/header: slot/header or flag-new-line]
			set-type slot TYPE_BITSET
			
			as int-ptr! align bits + size 32			;-- align at upper 32-bit boundary
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
	
	origin: declare red-block!
	
	decode-reference: func [
		data    [int-ptr!]
		parent  [red-block!]
		return: [int-ptr!]
		/local
			value  [red-value!]
			object [red-object!]
			ctx    [red-context!]
			node   [node!]
			buffer [series!]
			offset [int-ptr!]
	][
		value:  as red-value! origin
		offset: data + 2
		
		loop data/2 [
			value: switch TYPE_OF(value) [
				TYPE_ANY_BLOCK
				TYPE_MAP [
					block/rs-abs-at as red-block! value 0
				]
				TYPE_ACTION
				TYPE_NATIVE [
					block/rs-abs-at as red-block! value 0
				]
				TYPE_OBJECT [
					object: as red-object! value
					ctx: GET_CTX(object)
					buffer: as series! ctx/values/value
					buffer/offset
				]
				TYPE_ANY_WORD
				TYPE_REFINEMENT [
					node: as node! value/data1
					ctx: TO_CTX(node)
					buffer: as series! ctx/values/value
					buffer/offset
				]
				TYPE_FUNCTION
				TYPE_ROUTINE 
				TYPE_OP [
					--NOT_IMPLEMENTED--				;@@ TBD: support for any-function!
					value
				]
				default [
					assert false
					value
				]
			]
			
			value:  value + offset/value
			offset: offset + 1
		]
		
		copy-cell value ALLOC_TAIL(parent)
		
		data + data/2 + 2
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
			TYPE_ACTION
			TYPE_OP			[decode-native data table parent nl?]
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
				--NOT_IMPLEMENTED--
				data
			]
			REDBIN_PADDING [
				decode-value data + 1 table parent
			]
			REDBIN_REFERENCE [
				decode-reference data parent
			]
			default [
				assert false
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
		
		origin: parent
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
	
	offset: 0
	
	header: #{
		52454442494E								;-- REDBIN magic
		01											;-- version
		00											;-- placeholder for flags
		00000000									;-- placeholder for length
		00000000									;-- placeholder for size
	}
	
	path: context [
		size:  1'000
		stack: as int-ptr! allocate size * size? integer!
		top:   stack
		end:   stack + size
		
		push: does [
			if top + 1 = end [reset fire [TO_ERROR(internal too-deep)]]
			top/value: offset
			top: top + 1
			offset: 0
		]
		
		pop: does [
			top: top - 1
			assert top >= stack
			offset: top/value
		]
		
		reset: does [top: stack]
	]
	
	reference: context [
		size: 3'000
		list: as int-ptr! allocate size * size? integer!	;-- node, size, offsets
		top:  list
		end:  list + size
		
		fetch: func [
			node    [node!]
			return: [int-ptr!]
			/local
				here [int-ptr!]
		][
			here: list
			while [here <> top][
				if node = as node! here/value [return here + 1]
				here: here + here/2 + 2
			]
			
			null
		]
		
		store: func [
			node [node!]
			/local
				size [integer!]
		][
			size: (as integer! path/top - path/stack) >> log-b size? integer!
			top/1: as integer! node
			top/2: size
			top: top + 2
			
			copy-memory as byte-ptr! top as byte-ptr! path/stack size * size? integer!
			
			top: top + size
		]
		
		reset: does [top: list]
	]
	
	pad: func [
		buffer [red-binary!]
		size   [integer!]
		/local
			length  [integer!]
			residue [integer!]
			zero    [integer!]
	][
		assert any [size = 32 size = 64]
		
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
	
	encode-native: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		symbols [red-binary!]
		table   [red-binary!]
		strings [red-binary!]
		/local
			here  [int-ptr!]
			index [integer!]
	][
		unless header and REDBIN_REFERENCE_MASK <> 0 [
			here: either TYPE_OF(data) = TYPE_NATIVE [natives/table][actions/table]
			index: 0
			until [index: index + 1 data/data3 = here/index]
			
			record [payload header index]
			encode-block data TYPE_BLOCK yes payload symbols table strings	;-- structure overlap
		]
	]
	
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
				;@@ #4537
				if null? node [assert false]
			
				series: as series! node/value
				value:  series/offset + 1
				type:   TYPE_OF(value)
			
				assert any [type = TYPE_OBJECT type = TYPE_FUNCTION]
				
				either type = TYPE_OBJECT [
					encode-object value type payload symbols table strings
				][
					encode-function value type payload symbols table strings
				]
			]
		]
	]
	
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
		
		header:   TYPE_CONTEXT or (kind << 25)
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
	
	encode-block: func [
		data    [red-value!]
		header  [integer!]
		abs?    [logic!]
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
		unless header and get-type-mask = TYPE_MAP [store payload either abs? [0][data/data1]]
		
		unless header and REDBIN_REFERENCE_MASK <> 0 [
			store payload length
			loop length [
				encode-value value payload symbols table strings
				value:  value + 1
			]
		]
	]
	
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
	
	encode-bitset: func [
		data    [red-value!]
		header  [integer!]
		payload [red-binary!]
		/local
			bits   [red-bitset!]
			length [integer!]
	][
		bits:   as red-bitset! data
		length: bitset/length? bits
		
		store payload header
		
		unless header and REDBIN_REFERENCE_MASK <> 0 [
			store payload length
			emit payload bitset/rs-head bits length >> 3
			pad payload 32
		]
	]
	
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
	][
		either header and REDBIN_REFERENCE_MASK <> 0 [
			assert false							;@@ TBD
		][
			fun: as red-function! data
			ctx: as red-value! GET_CTX(fun)
			series: as series! fun/more/value
			body: series/offset
			assert TYPE_OF(body) = TYPE_BLOCK
			
			store payload header
			encode-block data TYPE_BLOCK yes payload symbols table strings	;-- structure overlap
			encode-block body TYPE_BLOCK no payload symbols table strings
			encode-context ctx payload symbols table strings
		]
	]
	
	encode-reference: func [
		reference [int-ptr!]
		payload   [red-binary!]
	][
		record [payload REDBIN_REFERENCE reference/1]
		emit payload as byte-ptr! reference + 1 reference/1 << log-b size? integer!
	]
	
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
			TYPE_MONEY [(money/get-sign as red-money! data) << 16]
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
			TYPE_POINT
			TYPE_HANDLE
			TYPE_EVENT		[--NOT_IMPLEMENTED--]
			
			TYPE_FUNCTION	[encode-function data header payload symbols table strings]
			
			default			[
				first?: any [ALL_WORD?(type) type = TYPE_OBJECT type = TYPE_FUNCTION]
				
				node: as node! either first? [data/data1][data/data2]
				ref:  reference/fetch node
				
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
					TYPE_NATIVE
					TYPE_ACTION 	[encode-native data header payload symbols table strings]
					TYPE_ANY_BLOCK
					TYPE_MAP		[encode-block data header no payload symbols table strings]
					TYPE_OBJECT		[encode-object data header payload symbols table strings]
					TYPE_ROUTINE
					TYPE_OP			[--NOT_IMPLEMENTED--]
					default			[assert false]
				]
				
				unless global? [either null? ref [path/pop][encode-reference ref payload]]
			]
		]
		
		offset: offset + 1
	]
	
	encode: func [
		data    [red-value!]
		return: [red-binary!]
		/local
			payload table symbols strings [red-binary!]
			here [int-ptr!]
			head [byte-ptr!]
			length size sym-len str-len sym-size [integer!]
	][
		codec?: yes
		offset: 0
		
		path/reset
		reference/reset
		
		;-- payload
		payload: binary/make-at stack/push* 4		;@@ TBD: heuristics for pre-allocation
		symbols: binary/make-at stack/push* 4
		table:   binary/make-at stack/push* 4
		strings: binary/make-at stack/push* 4
		
		encode-value data payload symbols table strings
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
		here/1: 1									;-- always 1 root record
		here/2: size
		
		stack/pop 4
		
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