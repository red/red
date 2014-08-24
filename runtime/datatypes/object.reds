Red/System [
	Title:   "Object! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %object.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

object: context [
	verbose: 0
	
	class-id: 1'000'000									;-- base ID for dynamically created objects
	
	get-new-id: func [return: [integer!]][				;@@ protect from concurrent accesses
		class-id: class-id + 1
		class-id
	]
	
	unchanged?: func [
		word	[red-word!]
		id		[integer!]
		return: [logic!]
		/local
			obj [red-object!]
	][
		obj: as red-object! _context/get word
		all [
			TYPE_OF(obj) = TYPE_OBJECT
			obj/class = id
		]
	]
	
	unchanged2?: func [
		node	[node!]
		index	[integer!]
		id		[integer!]
		return: [logic!]
		/local
			obj	   [red-object!]
			ctx	   [red-context!]
			values [series!]
	][
		ctx: TO_CTX(node)
		values: as series! ctx/values/value
		obj: as red-object! values/offset + index
		all [
			TYPE_OF(obj) = TYPE_OBJECT
			obj/class = id
		]
	]
	
	do-indent: func [
		buffer	[red-string!]
		tabs	[integer!]
		part	[integer!]
		return:	[integer!]
		/local
			n [integer!]
	][
		n: tabs
		until [
			string/concatenate-literal buffer "    "
			n: n - 1
			zero? n
		]
		part - (4 * tabs)
	]
	
	serialize: func [
		obj		[red-object!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent?	[logic!]
		tabs	[integer!]
		return: [integer!]
		/local
			ctx		[red-context!]
			syms	[series!]
			values	[series!]
			sym		[red-value!]
			s-tail	[red-value!]
			value	[red-value!]
	][
		ctx: 	GET_CTX(obj)
		syms:   as series! ctx/symbols/value
		values: as series! ctx/values/value
		
		sym:	syms/offset
		s-tail: syms/tail
		value: 	values/offset
		
		while [sym < s-tail][
			if indent? [part: do-indent buffer tabs part]
			
			part: word/mold as red-word! sym buffer no no flat? arg part tabs
			string/concatenate-literal buffer ": "
			part: part - 2
			
			part: actions/mold value buffer only? all? flat? arg part tabs
			
			if any [indent? sym + 1 < s-tail][			;-- no final LF when FORMed
				string/append-char GET_BUFFER(buffer) as-integer lf
				part: part - 1
			]
			sym: sym + 1
			value: value + 1
		]
		part
	]
	
	extend: func [
		ctx		[red-context!]
		spec	[red-context!]
		return: [logic!]
		/local
			syms  [red-value!]
			tail  [red-value!]
			vals  [red-value!]
			value [red-value!]
			base  [red-value!]
			type  [integer!]
			s	  [series!]
	][
		s: as series! spec/symbols/value
		syms: s/offset
		tail: s/tail

		s: as series! spec/values/value
		vals: s/offset
		
		s: as series! ctx/symbols/value
		base: s/tail - s/offset

		while [syms < tail][
			value: _context/add-with ctx as red-word! syms vals
			
			unless null? value [
				type: TYPE_OF(value)
				case [
					ANY_SERIES?(type) [
						actions/copy
							as red-series! value
							value						;-- overwrite the value
							null
							yes
							null
					]
					type = TYPE_FUNCTION [
						rebind as red-function! value ctx
					]
					true [0]
				]
			]
			syms: syms + 1
			vals: vals + 1
		]
		s: as series! ctx/symbols/value					;-- refreshing pointer
		s/tail - s/offset > base						;-- TRUE: new words added
	]
	
	rebind: func [
		fun		[red-function!]
		ctx 	[red-context!]
		/local
			s	 [series!]
			more [red-value!]
			blk  [red-block!]
			spec [red-block!]
	][
		s: as series! fun/more/value
		more: s/offset
		
		if TYPE_OF(more) = TYPE_NONE [
			print-line "*** Error: COPY stuck on missing function's body block"
			halt
		]
		spec: as red-block! stack/push*
		spec/head: 0
		spec/node: fun/spec
		
		blk: block/clone as red-block! more yes
		_context/bind blk ctx yes						;-- rebind new body to object
		_function/push spec blk	fun/ctx null			;-- recreate function
		copy-cell stack/top - 1	as red-value! fun		;-- overwrite function slot in object
		stack/pop 2										;-- remove extra stack slots (block/clone and _function/push)
		
		s: as series! fun/more/value
		more: s/offset + 2
		more/header: TYPE_UNSET							;-- invalidate compiled body
	]
	
	push: func [
		ctx		[node!]
		class	[integer!]
		return: [red-object!]
		/local
			obj	[red-object!]
	][
		obj: as red-object! stack/push*
		obj/header: TYPE_OBJECT
		obj/ctx:	ctx
		obj/class:	class
		obj
	]
	
	make-at: func [
		obj		[red-object!]
		slots	[integer!]
		return: [red-object!]
	][
		obj/header: TYPE_OBJECT
		obj/ctx:	_context/create slots no yes
		obj/class:	0
		obj
	]
	
	;-- Actions --
	
	make: func [
		proto	[red-object!]
		spec	[red-value!]
		return:	[red-object!]
		/local
			obj	 [red-object!]
			obj2 [red-object!]
			ctx  [red-context!]
			blk  [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/make"]]
		
		obj: as red-object! stack/push*
		
		either TYPE_OF(proto) = TYPE_OBJECT [
			copy proto obj null yes null				;-- /deep
		][
			make-at obj 4								;-- arbitrary value
		]
		ctx: GET_CTX(obj)
		
		switch TYPE_OF(spec) [
			TYPE_OBJECT [
				obj2: as red-object! spec
				obj/class: either extend ctx GET_CTX(obj2) [get-new-id][proto/class]
			]
			TYPE_BLOCK [
				blk: as red-block! spec
				_context/collect-set-words ctx blk
				_context/bind blk ctx yes
				interpreter/eval blk no
				obj/class: get-new-id
			]
			default [
				print-line "*** Error: invalid spec value for object construction"
				halt
			]
		]
		obj
	]
	
	reflect: func [
		obj		[red-object!]
		field	[integer!]
		return:	[red-block!]
		/local
			ctx	  [red-context!]
			blk   [red-block!]
			syms  [red-value!]
			vals  [red-value!]
			tail  [red-value!]
			value [red-value!]
			s	  [series!]
	][
		blk: 		as red-block! stack/push*
		blk/header: TYPE_BLOCK
		blk/head: 	0
		
		ctx: GET_CTX(obj)
		
		case [
			field = words/words [
				blk/node: ctx/symbols
				blk: block/clone blk no
			]
			field = words/values [
				blk/node: ctx/values
				blk: block/clone blk no
			]
			field = words/body [
				blk/node: ctx/symbols
				blk/node: alloc-cells block/rs-length? blk
				
				s: as series! ctx/symbols/value
				syms: s/offset
				tail: s/tail
				
				s: as series! ctx/values/value
				vals: s/offset
				
				while [syms < tail][
					value: block/rs-append blk syms
					value/header: TYPE_SET_WORD
					block/rs-append blk vals
					syms: syms + 1
					vals: vals + 1
				]
			]
			true [
				--NOT_IMPLEMENTED--						;@@ raise error
			]
		]
		as red-block! stack/set-last as red-value! blk
	]
	
	form: func [
		obj		[red-object!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/form"]]

		serialize obj buffer no no no arg part no 0
	]
	
	mold: func [
		obj		[red-object!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/mold"]]
		
		string/concatenate-literal buffer "make object! [^/"
		part: serialize obj buffer only? all? flat? arg part - 15 yes indent + 1
		if indent > 0 [part: do-indent buffer indent part]
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 1
	]
	
	eval-path: func [
		parent	[red-object!]							;-- implicit type casting
		element	[red-value!]
		set?	[logic!]
		return:	[red-value!]
		/local
			word [red-word!]
			ctx  [red-context!]
	][
		word: as red-word! element
		ctx:  GET_CTX(parent)

		if word/ctx <> parent/ctx [						;-- bind the word to object's context
			word/index: _context/find-word ctx word/symbol no
			word/ctx: parent/ctx
		]
		either set? [
			_context/set-in word stack/arguments ctx 
			stack/arguments
		][
			_context/get-in word ctx
		]
	]
	
	copy: func [
		obj      [red-object!]
		new	  	 [red-object!]
		part-arg [red-value!]
		deep?	 [logic!]
		types	 [red-value!]
		return:	 [red-object!]
		/local
			ctx	  [red-context!]
			nctx  [red-context!]
			value [red-value!]
			tail  [red-value!]
			src	  [series!]
			dst	  [series!]
			size  [integer!]
			slots [integer!]
			type  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/copy"]]
		
		if OPTION?(types) [--NOT_IMPLEMENTED--]

		if OPTION?(part-arg) [
			print-line "***Error: copy/part is not supported on objects"
			halt
		]

		ctx:	GET_CTX(obj)
		src:	as series! ctx/symbols/value
		size:   as-integer src/tail - src/offset
		slots:	size >> 4
		
		new: make-at new slots
		new/class: obj/class
		nctx: GET_CTX(new)
		
		;-- process SYMBOLS
		dst: as series! nctx/symbols/value
		copy-memory as byte-ptr! dst/offset as byte-ptr! src/offset size
		dst/size: size
		dst/tail: dst/offset + slots
		_context/set-context-each dst new/ctx
		
		;-- process VALUES
		src: as series! ctx/values/value
		dst: as series! nctx/values/value
		copy-memory as byte-ptr! dst/offset as byte-ptr! src/offset size
		dst/size: size
		dst/tail: dst/offset + slots
		
		if deep? [
			value: dst/offset
			tail:  dst/tail
			
			while [value < tail][
				type: TYPE_OF(value)
				case [
					ANY_SERIES?(type) [
						actions/copy 
							as red-series! value
							value						;-- overwrite the value
							null
							yes
							null
					]
					type = TYPE_FUNCTION [
						rebind as red-function! value nctx
					]
					true [0]
				]
				value: value + 1
			]
		]

		new
	]
	
	find: func [
		obj		 [red-object!]
		value	 [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		tail?	 [logic!]
		match?	 [logic!]
		return:	 [red-value!]
		/local
			word [red-word!]
			ctx	 [node!]
			id	 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/find"]]
		
		assert any [									;@@ replace with ANY_WORD?
			TYPE_OF(value) = TYPE_WORD
			TYPE_OF(value) = TYPE_LIT_WORD
			TYPE_OF(value) = TYPE_GET_WORD
			TYPE_OF(value) = TYPE_SET_WORD
		]
		word: as red-word! value
		ctx: obj/ctx
		id: _context/find-word TO_CTX(ctx) word/symbol yes
		as red-value! either id = -1 [none-value][true-value]
	]
	
	select: func [
		obj		 [red-object!]
		value	 [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		return:	 [red-value!]
		/local
			word   [red-word!]
			ctx	   [red-context!]
			values [series!]
			node   [node!]
			id	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/select"]]
		
		assert any [									;@@ replace with ANY_WORD?
			TYPE_OF(value) = TYPE_WORD
			TYPE_OF(value) = TYPE_LIT_WORD
			TYPE_OF(value) = TYPE_GET_WORD
			TYPE_OF(value) = TYPE_SET_WORD
		]
		word: as red-word! value
		node: obj/ctx
		ctx: TO_CTX(node)
		id: _context/find-word ctx word/symbol yes
		if id = -1 [return as red-value! none-value]
		
		values: as series! ctx/values/value
		values/offset + id
	]
	
	init: does [
		datatype/register [
			TYPE_OBJECT
			TYPE_VALUE
			"object!"
			;-- General actions --
			:make
			null			;random
			:reflect
			null			;to
			:form
			:mold
			:eval-path
			null			;set-path
			null			;compare
			;-- Scalar actions --
			null			;absolute
			null			;add
			null			;divide
			null			;multiply
			null			;negate
			null			;power
			null			;remainder
			null			;round
			null			;subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			:copy
			:find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;next
			null			;pick
			null			;poke
			null			;remove
			null			;reverse
			:select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update	
			null			;write
		]
	]
]