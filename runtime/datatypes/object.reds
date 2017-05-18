Red/System [
	Title:   "Object! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %object.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

object: context [
	verbose: 0
	
	class-id: 1'000'000									;-- base ID for dynamically created objects
	
	path-parent:  declare red-object!					;-- temporary save parent object for eval-path action
	field-parent: declare red-word!						;-- temporary save obj's field for eval-path action
	
	get-new-id: func [return: [integer!]][				;@@ protect from concurrent accesses
		class-id: class-id + 1
		class-id
	]
	
	check-owner: func [
		slot [red-value!]
		/local
			ser  [red-series!]
			type [integer!]
	][
		type: TYPE_OF(path-parent)
		case [
			type = TYPE_OBJECT [
				ownership/check-slot path-parent field-parent slot
			]	
			ANY_SERIES?(type) [
				ser: as red-series! path-parent
				ownership/check as red-value! ser words/_poke null ser/head 1
			]
			true [0]									;-- ignore other types
		]
	]
	
	check-word: func [
		value [red-value!]
		/local
			type [integer!]
	][
		type: TYPE_OF(value)
		unless any [									;@@ replace with ANY_WORD?
			type = TYPE_WORD
			type = TYPE_LIT_WORD
			type = TYPE_GET_WORD
			type = TYPE_SET_WORD
		][
			fire [TO_ERROR(script invalid-type) datatype/push type]
		]
	]
	
	rs-find: func [
		obj		 [red-object!]
		value	 [red-value!]
		return:	 [integer!]								;-- -1 if not found, else index
		/local
			word [red-word!]
			ctx	 [node!]
	][
		assert any [									;@@ replace with ANY_WORD?
			TYPE_OF(value) = TYPE_WORD
			TYPE_OF(value) = TYPE_LIT_WORD
			TYPE_OF(value) = TYPE_GET_WORD
			TYPE_OF(value) = TYPE_SET_WORD
		]
		word: as red-word! value
		ctx: obj/ctx
		 _context/find-word TO_CTX(ctx) word/symbol yes
	]
	
	rs-select: func [
		obj		 [red-object!]
		value	 [red-value!]
		return:	 [red-value!]
		/local
			word   [red-word!]
			ctx	   [red-context!]
			values [series!]
			id	   [integer!]
	][
		assert any [									;@@ replace with ANY_WORD?
			TYPE_OF(value) = TYPE_WORD
			TYPE_OF(value) = TYPE_LIT_WORD
			TYPE_OF(value) = TYPE_GET_WORD
			TYPE_OF(value) = TYPE_SET_WORD
		]
		word: as red-word! value
		ctx: GET_CTX(obj)
		id: _context/find-word ctx word/symbol yes	
		if id = -1 [return as red-value! none-value]
		
		values: as series! ctx/values/value
		values/offset + id
	]
	
	get-word: func [
		obj		[node!]
		index	[integer!]
		return: [red-value!]
		/local
			ctx [red-context!]
			s   [series!]
	][
		ctx: TO_CTX(obj)
		s: as series! ctx/symbols/value
		s/offset + index
	]
	
	get-words: func [
		obj		[red-object!]
		return: [red-value!]
	][
		get-word obj/ctx 0
	]
	
	get-values: func [
		obj		[red-object!]
		return: [red-value!]
		/local
			ctx [red-context!]
			s   [series!]
	][
		ctx: GET_CTX(obj)
		s: as series! ctx/values/value
		s/offset
	]
	
	get-size: func [
		obj		[red-object!]
		return: [integer!]
		/local
			ctx [red-context!]
			s   [series!]
	][
		ctx: GET_CTX(obj)
		s: as series! ctx/symbols/value
		(as-integer s/tail - s/offset) >> 4
	]
	
	set-many: func [
		obj	  [red-object!]
		value [red-value!]
		only? [logic!]
		some? [logic!]
		/local
			ctx		[red-context!]
			blk		[red-block!]
			obj2	[red-object!]
			ctx2	[red-context!]
			word	[red-word!]
			values	[red-value!]
			values2	[red-value!]
			tail	[red-value!]
			new		[red-value!]
			old		[red-value!]
			s		[series!]
			i		[integer!]
			type	[integer!]
			on-set?	[logic!]
	][
		ctx:	GET_CTX(obj)
		s:		as series! ctx/values/value
		values: s/offset
		tail:	s/tail
		type:	TYPE_OF(value)
		on-set?: obj/on-set <> null
		s: as series! ctx/symbols/value
		word: as red-word! s/offset

		either all [not only? any [type = TYPE_BLOCK type = TYPE_OBJECT]][
			either type = TYPE_BLOCK [
				blk: as red-block! value
				i: 1
				while [values < tail][
					new: _series/pick as red-series! blk i null
					unless all [some? TYPE_OF(new) = TYPE_NONE][
						if on-set? [old: stack/push values]
						copy-cell new values
						if on-set? [fire-on-set obj word old new]
					]
					word: word + 1
					values: values + 1
					i: i + 1
				]
			][
				obj2: as red-object! value
				ctx2: GET_CTX(obj2)
				values2: get-values obj2
				
				while [values < tail][
					i: _context/find-word ctx2 word/symbol yes
					if i > -1 [
						new: values2 + i
						unless all [some? TYPE_OF(new) = TYPE_NONE][
							if on-set? [old: stack/push values]
							copy-cell new values
							if on-set? [fire-on-set obj word old new]
						]
					]
					word: word + 1
					values: values + 1
				]
			]
		][
			while [values < tail][
				if on-set? [old: stack/push values]
				copy-cell value values
				if on-set? [fire-on-set obj word old new]
				word: word + 1
				values: values + 1
			]
		]
	]
	
	save-self-object: func [
		obj		[red-object!]
		return: [node!]
		/local
			node [node!]
			s	 [series!]
	][
		node: alloc-cells 1								;-- hidden object value storage used by SELF
		s: as series! node/value
		copy-cell as red-value! obj s/offset
		node
	]
	
	make-callback-node: func [
		ctx		[red-context!]
		idx-s	[integer!]								;-- for on-change* event
		loc-s	[integer!]
		idx-d	[integer!]								;-- for on-deep-change* event
		loc-d	[integer!]
		return: [node!]
		/local
			node [node!]
			int  [red-integer!]
			s	 [series!]
	][
		node: alloc-cells 2
		s: as series! node/value
		int: as red-integer! s/offset
		int/header: TYPE_INTEGER
		int/value: (idx-s << 16) or loc-s				;-- store info for on-change*

		int: as red-integer! s/offset + 1
		int/header: TYPE_INTEGER
		int/value: (idx-d << 16) or loc-d				;-- store info for on-deep-change*
		node
	]
	
	on-deep?: func [
		obj		[red-object!]
		return: [logic!]
		/local
			int	[red-integer!]
			s	[series!]
	][
		if obj/on-set <> null [
			s: as series! obj/on-set/value
			int: as red-integer! s/offset + 1
			if int/value >>> 16 <> -1 [return true]
		]
		false
	]
	
	on-set-defined?: func [
		ctx		[red-context!]
		return: [node!]
		/local
			head	[red-word!]
			tail	[red-word!]
			word	[red-word!]
			fun		[red-function!]
			s		[series!]
			on-set	[integer!]
			on-deep	[integer!]
			idx-s	[integer!]
			idx-d	[integer!]
			loc-s	[integer!]
			loc-d	[integer!]
			sym		[integer!]
	][
		s:		 as series! ctx/symbols/value
		head:	 as red-word! s/offset
		tail:	 as red-word! s/tail
		word:	 head
		on-set:	 words/_on-change*/symbol
		on-deep: words/_on-deep-change*/symbol
		idx-s:	 -1
		idx-d:	 -1
		loc-s:	 0
		loc-d:	 0
		
		while [word < tail][
			sym: symbol/resolve word/symbol
			if on-set  = sym [idx-s: (as-integer word - head) >> 4]
			if on-deep = sym [idx-d: (as-integer word - head) >> 4]
			word: word + 1
		]
		if all [idx-s < 0 idx-d < 0][return null]		;-- callback is not found
		
		s: as series! ctx/values/value
		if idx-s >= 0 [
			fun: as red-function! s/offset + idx-s
			loc-s: _function/calc-arity null fun 0		;-- passing a null path triggers short code branch
		]
		if idx-d >= 0 [
			fun: as red-function! s/offset + idx-d
			loc-d: _function/calc-arity null fun 0		;-- passing a null path triggers short code branch
		]
		make-callback-node ctx idx-s loc-s idx-d loc-d
	]
	
	loc-fire-on-set*: func [							;-- compiled code entry point
		parent [red-value!]
		field  [red-word!]
	][
		fire-on-set
			as red-object! parent
			field
			stack/top - 1
			stack/top - 2
	]
	
	fire-on-set*: func [								;-- compiled code entry point
		parent [red-word!]
		field  [red-word!]
	][
		fire-on-set
			as red-object! _context/get parent
			field
			stack/top - 1
			stack/top - 2
	]
	
	fire-on-set: func [
		obj	 [red-object!]
		word [red-word!]
		old	 [red-value!]
		new	 [red-value!]
		/local
			fun	  [red-function!]
			int	  [red-integer!]
			ctx	  [red-context!]
			index [integer!]
			count [integer!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/fire-on-set"]]
		
		assert TYPE_OF(obj) = TYPE_OBJECT
		assert obj/on-set <> null
		s: as series! obj/on-set/value
		
		int: as red-integer! s/offset
		assert TYPE_OF(int) = TYPE_INTEGER
		index: int/value >> 16
		count: int/value and FFFFh
		
		ctx: GET_CTX(obj) 
		s: as series! ctx/values/value
		fun: as red-function! s/offset + index
		assert TYPE_OF(fun) = TYPE_FUNCTION
		
		stack/mark-func words/_on-change*
		stack/push as red-value! word
		stack/push old
		stack/push new
		if positive? count [_function/init-locals count]
		_function/call fun obj/ctx
		stack/unwind
	]
	
	fire-on-deep: func [
		owner  [red-object!]
		word   [red-word!]
		target [red-value!]
		action [red-word!]
		new	   [red-value!]
		pos	   [integer!]
		nb	   [integer!]
		/local
			fun	  [red-function!]
			int	  [red-integer!]
			ctx	  [red-context!]
			index [integer!]
			count [integer!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/fire-on-deep"]]

		assert TYPE_OF(owner) = TYPE_OBJECT
		assert owner/on-set <> null
		s: as series! owner/on-set/value

		int: as red-integer! s/offset + 1
		assert TYPE_OF(int) = TYPE_INTEGER
		index: int/value >> 16
		count: int/value and FFFFh
		
		if null? new [new: as red-value! none-value]

		ctx: GET_CTX(owner) 
		s: as series! ctx/values/value
		fun: as red-function! s/offset + index
		if TYPE_OF(fun) = TYPE_FUNCTION [
			stack/mark-func words/_on-deep-change*
			stack/push as red-value! owner
			stack/push as red-value! word
			stack/push target
			stack/push as red-value! action
			stack/push new
			integer/push pos
			integer/push nb
			if positive? count [_function/init-locals count]
			_function/call fun owner/ctx
			stack/unwind
		]
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
		mold?	[logic!]
		return: [integer!]
		/local
			ctx		[red-context!]
			syms	[series!]
			values	[series!]
			sym		[red-value!]
			s-tail	[red-value!]
			value	[red-value!]
			w		[red-word!]
			evt1	[integer!]
			evt2	[integer!]
			id		[integer!]
			blank	[byte!]
	][
		ctx: 	GET_CTX(obj)
		syms:   as series! ctx/symbols/value
		values: as series! ctx/values/value
		
		sym:	syms/offset
		s-tail: syms/tail
		value: 	values/offset
		evt1:	words/_on-change*/symbol
		evt2:	words/_on-deep-change*/symbol
		
		if sym = s-tail [return part]					;-- exit if empty

		either flat? [
			indent?: no
			blank: space
		][
			if mold? [
				string/append-char GET_BUFFER(buffer) as-integer lf
				part: part - 1
			]
			blank: lf
		]
		cycles/push obj/ctx

		while [sym < s-tail][
			w: as red-word! sym
			id: symbol/resolve w/symbol
			
			if any [all [id <> evt1 id <> evt2] all?][
				if indent? [part: do-indent buffer tabs part]
				
				part: word/mold as red-word! sym buffer no no flat? arg part tabs
				string/concatenate-literal buffer ": "
				part: part - 2

				if TYPE_OF(value) = TYPE_VALUE [value/header: TYPE_UNSET] ;-- force uninitialized slot to UNSET
				if TYPE_OF(value) = TYPE_WORD [
					string/append-char GET_BUFFER(buffer) as-integer #"'" ;-- create a literal word
					part: part - 1
				]
				unless cycles/detect? value buffer :part mold? [
					part: actions/mold value buffer only? all? flat? arg part tabs
				]

				if any [indent? sym + 1 < s-tail][			;-- no final LF when FORMed
					string/append-char GET_BUFFER(buffer) as-integer blank
					part: part - 1
				]
			]
			sym: sym + 1
			value: value + 1
		]
		cycles/pop
		part
	]
	
	transfer: func [
		src    [node!]									;-- src context
		dst	   [node!]									;-- dst context (extension of src)
		/local
			from   [red-context!]
			to	   [red-context!]
			word   [red-word!]
			symbol [red-value!]
			value  [red-value!]
			tail   [red-value!]
			target [red-value!]
			s	   [series!]
			idx	   [integer!]
			type   [integer!]
	][
		from: TO_CTX(src)
		to:	  TO_CTX(dst)

		s: as series! from/symbols/value
		symbol: s/offset
		tail: s/tail
		
		s: as series! from/values/value
		value: s/offset

		s: as series! to/values/value
		target: s/offset

		while [symbol < tail][
			word: as red-word! symbol
			idx: _context/find-word to word/symbol yes
			
			type: TYPE_OF(value)
			either ANY_SERIES?(type) [					;-- copy series value in extended object
				actions/copy
					as red-series! value
					target + idx
					null
					yes
					null
			][
				copy-cell value target + idx			;-- just propagate the old value by default
			]
			symbol: symbol + 1
			value: value + 1
		]
	]
	
	duplicate: func [
		src    [node!]									;-- src context
		dst	   [node!]									;-- dst context (extension of src)
		/local
			from   [red-context!]
			to	   [red-context!]
			value  [red-value!]
			tail   [red-value!]
			target [red-value!]
			s	   [series!]
			type   [integer!]
	][
		from: TO_CTX(src)
		to:	  TO_CTX(dst)
		
		s: as series! from/values/value
		value: s/offset
		tail:  s/tail
		
		s: as series! to/values/value
		target: s/offset
		
		while [value < tail][
			type: TYPE_OF(value)
			either ANY_SERIES?(type) [					;-- copy series value in extended object
				actions/copy
					as red-series! value
					target
					null
					yes
					null
			][
				copy-cell value target					;-- just propagate the old value by default
			]
			value: value + 1
			target: target + 1
		]
	]
	
	extend: func [
		ctx		[red-context!]
		spec	[red-context!]
		obj		[red-object!]
		return: [logic!]
		/local
			syms  [red-value!]
			tail  [red-value!]
			vals  [red-value!]
			value [red-value!]
			base  [red-value!]
			word  [red-word!]
			node  [node!]
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
		
		s: as series! ctx/values/value
		node: save-self-object obj

		while [syms < tail][
			value: _context/add-with ctx as red-word! syms vals
			
			if null? value [
				word: as red-word! syms
				value: s/offset + _context/find-word ctx word/symbol yes
				copy-cell vals value
			]
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
					rebind as red-function! value ctx node
				]
				true [0]
			]
			syms: syms + 1
			vals: vals + 1
		]
		s: as series! ctx/symbols/value					;-- refreshing pointer
		s/tail - s/offset > base						;-- TRUE: new words added
	]
	
	rebind: func [
		fun	 [red-function!]
		ctx  [red-context!]
		node [node!]
		/local
			s	 [series!]
			more [red-value!]
			blk  [red-block!]
			spec [red-block!]
	][
		s: as series! fun/more/value
		more: s/offset
		
		if TYPE_OF(more) = TYPE_NONE [
			fire [TO_ERROR(script bad-func-def) fun]
		]
		spec: as red-block! stack/push*
		spec/head: 0
		spec/node: fun/spec
		
		blk: block/clone as red-block! more yes yes
		_context/bind blk ctx node yes					;-- rebind new body to object
		_function/push spec blk	fun/ctx null null		;-- recreate function
		copy-cell stack/top - 1	as red-value! fun		;-- overwrite function slot in object
		stack/pop 2										;-- remove extra stack slots (block/clone and _function/push)
		
		s: as series! fun/more/value
		more: s/offset + 2
		more/header: TYPE_UNSET							;-- invalidate compiled body
	]
	
	init-push: func [
		node	[node!]
		class	[integer!]
		return: [red-object!]
		/local
			ctx [red-context!]
			obj	[red-object!]
			s	[series!]
	][
		ctx: TO_CTX(node)
		s: as series! ctx/values/value
		if s/offset = s/tail [
			s/tail: s/offset + (s/size >> 4)			;-- (late) setting of 'values right tail pointer
		]
		
		obj: as red-object! stack/push*
		obj/header: TYPE_OBJECT
		obj/ctx:	node
		obj/class:	class
		obj/on-set: null								;-- deferred setting, once object's body is evaluated
		
		s: as series! node/value
		copy-cell as red-value! obj s/offset + 1		;-- set back-reference
		obj
	]
	
	init-events: func [
		ctx	  [node!]
		idx-s [integer!]								;-- for on-change* event
		loc-s [integer!]
		idx-d [integer!]								;-- for on-deep-change* event
		loc-d [integer!]
		/local
			obj [red-object!]
			s	[series!]
	][
		obj: as red-object! stack/top - 1
		assert TYPE_OF(obj) = TYPE_OBJECT
		obj/on-set: make-callback-node TO_CTX(ctx) idx-s loc-s idx-d loc-d
		if idx-d <> -1 [ownership/set-owner as red-value! obj obj null]
		
		s: as series! ctx/value
		copy-cell as red-value! obj s/offset + 1		;-- refresh back-reference
	]
	
	push: func [
		ctx		[node!]
		class	[integer!]
		idx-s	[integer!]								;-- for on-change* event
		loc-s	[integer!]
		idx-d	[integer!]								;-- for on-deep-change* event
		loc-d	[integer!]
		return: [red-object!]
		/local
			obj	[red-object!]
			s	[series!]
	][
		obj: as red-object! stack/push*
		obj/header: TYPE_OBJECT
		obj/ctx:	ctx
		obj/class:	class
		obj/on-set: make-callback-node TO_CTX(ctx) idx-s loc-s idx-d loc-d
		
		s: as series! ctx/value
		copy-cell as red-value! obj s/offset + 1		;-- set back-reference
		obj
	]
	
	make-at: func [
		obj		[red-object!]
		slots	[integer!]
		return: [red-object!]
		/local
			s [series!]
	][
		obj/header: TYPE_OBJECT
		obj/ctx:	_context/create slots no yes
		obj/class:	0
		obj/on-set: null
		
		s: as series! obj/ctx/value
		copy-cell as red-value! obj s/offset + 1		;-- set back-reference
		obj
	]
	
	collect-couples: func [
		ctx	 	[red-context!]
		spec 	[red-block!]
		only?	[logic!]
		return: [logic!]
		/local
			cell   [red-value!]
			tail   [red-value!]
			value  [red-value!]
			values [red-value!]
			base   [red-value!]
			word   [red-word!]
			s	   [series!]
			id	   [integer!]
			sym	   [integer!]
	][
		s: GET_BUFFER(spec)
		cell: s/offset
		tail: s/tail

		s: as series! ctx/symbols/value
		base: s/tail - s/offset
		
		s: as series! ctx/values/value
		values: s/offset
		
		while [cell < tail][
			if TYPE_OF(cell) = TYPE_SET_WORD [
				id: _context/add ctx as red-word! cell

				value: cell + 1							;-- fetch next value to assign
				while [all [
					TYPE_OF(value) = TYPE_SET_WORD
					value < tail
				]][
					value: value + 1
				]
				if value = tail [value: as red-value! none-value]
				
				if all [not only? TYPE_OF(value) = TYPE_WORD][ ;-- reduce the value if allowed
					word: as red-word! value
					sym: symbol/resolve word/symbol
					if any [
						sym = words/_true
						sym = words/_yes
						sym = words/_on
					][
						value: as red-value! true-value
					]
					if any [
						sym = words/_false
						sym = words/_no
						sym = words/_off
					][
						value: as red-value! false-value
					]
					if sym = words/none [value: as red-value! none-value]
				]
				
				copy-cell value values + id
			]
			cell: cell + 1
		]
		s/tail - s/offset > base						;-- TRUE: new words added
	]
	
	construct: func [
		spec	[red-block!]
		proto	[red-object!]
		only?	[logic!]
		return:	[red-object!]
		/local
			obj	 [red-object!]
			ctx	 [red-context!]
	][
		obj: as red-object! stack/push*
		make-at obj 4								;-- arbitrary value
		obj/class: get-new-id
		obj/on-set: null
		ctx: GET_CTX(obj)
		
		unless null? proto [extend ctx GET_CTX(proto) obj]
		collect-couples ctx spec only?
		obj
	]
	
	;-- Actions --
	
	make: func [
		proto	[red-object!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-object!]
		/local
			obj	 [red-object!]
			obj2 [red-object!]
			ctx	 [red-context!]
			blk	 [red-block!]
			new? [logic!]
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
				obj/class: either extend ctx GET_CTX(obj2) obj [get-new-id][proto/class] ;@@ class-id is not transmitted for 'self!
			]
			TYPE_BLOCK [
				blk: as red-block! spec
				new?: _context/collect-set-words ctx blk
				_context/bind blk ctx save-self-object obj yes
				interpreter/eval blk no
				obj/class: either any [new? TYPE_OF(proto) <> TYPE_OBJECT][
					get-new-id
				][
					proto/class
				]
				obj/on-set: on-set-defined? ctx
				if on-deep? obj [ownership/set-owner as red-value! obj obj null]
			]
			default [fire [TO_ERROR(syntax malconstruct) spec]]
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
			word  [red-word!]
			s	  [series!]
	][
		blk: 		as red-block! stack/push*
		blk/header: TYPE_BLOCK
		blk/head: 	0
		
		ctx: GET_CTX(obj)
		
		case [
			field = words/class [
				return as red-block! integer/box obj/class
			]
			field = words/words [
				blk/node: ctx/symbols
				blk: block/clone blk no no
				
				word: as red-word! block/rs-head blk
				tail: block/rs-tail blk
				
				while [word < as red-word! tail][
					word/ctx: obj/ctx
					word: word + 1
				]
			]
			field = words/values [
				blk/node: ctx/values
				blk: block/clone blk no no
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
					word: as red-word! block/rs-append blk syms
					word/header: TYPE_SET_WORD
					word/ctx: obj/ctx
					
					value: block/rs-append blk vals
					switch TYPE_OF(value) [
						TYPE_WORD [set-type value TYPE_LIT_WORD]
						TYPE_PATH [set-type value TYPE_LIT_PATH]
						default   [0]
					]
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

		serialize obj buffer no no no arg part no 0 no
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
		
		string/concatenate-literal buffer "make object! ["
		part: serialize obj buffer only? all? flat? arg part - 14 yes indent + 1 yes
		if indent > 0 [part: do-indent buffer indent part]
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 1
	]
	
	eval-path: func [
		parent	[red-object!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			word	 [red-word!]
			ctx		 [red-context!]
			old		 [red-value!]
			res		 [red-value!]
			save-ctx [node!]
			save-idx [integer!]
			on-set?  [logic!]
			rebind?	 [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/eval-path"]]
		
		word: as red-word! element
		if TYPE_OF(word) <> TYPE_WORD [fire [TO_ERROR(script invalid-path) path element]]

		ctx: GET_CTX(parent)

		rebind?: word/ctx <> parent/ctx
		if rebind? [									;-- bind the word to object's context
			save-idx: word/index
			save-ctx: word/ctx
			word/index: _context/find-word ctx word/symbol yes
			if word/index = -1 [
				fire [TO_ERROR(script invalid-path) path element]
			]
			word/ctx: parent/ctx
		]
		on-set?: parent/on-set <> null
		
		either value <> null [
			if on-set? [old: stack/push _context/get-in word ctx]
			_context/set-in word value ctx
			if on-set? [fire-on-set parent as red-word! element old value]
			res: value
		][
			if on-set? [
				copy-cell as red-value! parent as red-value! path-parent
				copy-cell as red-value! word   as red-value! field-parent
			]
			res: _context/get-in word ctx
			if TYPE_OF(res) = TYPE_UNSET [
				if all [path <> null TYPE_OF(path) <> TYPE_GET_PATH][
					res: either null? path [element][path]
					fire [TO_ERROR(script no-value) res]
				]
			]
		]
		if rebind? [
			word/index: save-idx
			word/ctx: save-ctx
		]
		res
	]
	
	compare: func [
		obj1	[red-object!]							;-- first operand
		obj2	[red-object!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			ctx1   [red-context!]
			ctx2   [red-context!]
			sym1   [red-word!]
			sym2   [red-word!]
			tail   [red-word!]
			value1 [red-value!]
			value2 [red-value!]
			s	   [series!]
			diff   [integer!]
			s1	   [integer!]
			s2	   [integer!]
			type1  [integer!]
			type2  [integer!]
			res	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/compare"]]

		if TYPE_OF(obj2) <> TYPE_OBJECT [RETURN_COMPARE_OTHER]

		if op = COMP_SAME [return either obj1/ctx = obj2/ctx [0][-1]]
		if all [
			obj1/ctx = obj2/ctx
			any [op = COMP_EQUAL op = COMP_STRICT_EQUAL op = COMP_NOT_EQUAL]
		][return 0]

		ctx1: GET_CTX(obj1)
		s: as series! ctx1/symbols/value
		sym1: as red-word! s/offset
		tail: as red-word! s/tail
		
		ctx2: GET_CTX(obj2)
		s: as series! ctx2/symbols/value

		diff: (as-integer s/tail - s/offset) - (as-integer tail - sym1)
		if diff <> 0 [
			return either positive? diff [-1][1]
		]	
		if sym1 = tail [return 0]						;-- empty objects case
		
		sym2: as red-word! s/offset
		s: as series! ctx1/values/value
		value1: s/offset
		s: as series! ctx2/values/value
		value2: s/offset
		
		cycles/push obj1/ctx
		
		until [
			s1: symbol/resolve sym1/symbol
			s2: symbol/resolve sym2/symbol
			if s1 <> s2 [
				cycles/pop
				return SIGN_COMPARE_RESULT(s1 s2)
			]
			type1: TYPE_OF(value1)
			type2: TYPE_OF(value2)
			either any [
				type1 = type2
				all [word/any-word? type1 word/any-word? type2]
				all [											;@@ replace by ANY_NUMBER?
					any [type1 = TYPE_INTEGER type1 = TYPE_FLOAT]
					any [type2 = TYPE_INTEGER type2 = TYPE_FLOAT]
				]
			][
				either cycles/find? value1 [
					res: as-integer not natives/same? value1 value2
				][
					res: actions/compare-value value1 value2 op
				]
				sym1: sym1 + 1
				sym2: sym2 + 1
				value1: value1 + 1
				value2: value2 + 1
			][
				cycles/pop
				return SIGN_COMPARE_RESULT(type1 type2)
			]
			any [
				res <> 0
				sym1 >= tail
			]
		]
		cycles/pop
		res
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
			s	  [series!]
			node  [node!]
			size  [integer!]
			slots [integer!]
			type  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/copy"]]
		
		if OPTION?(types) [--NOT_IMPLEMENTED--]

		if OPTION?(part-arg) [
			ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
		]

		ctx:	GET_CTX(obj)
		src:	as series! ctx/symbols/value
		size:   as-integer src/tail - src/offset
		slots:	size >> 4
		
		copy-cell as cell! obj as cell! new
		new/ctx: _context/create slots no yes
		new/class: obj/class
		nctx: GET_CTX(new)
		
		s: as series! new/ctx/value
		copy-cell as red-value! new s/offset + 1		;-- set back-reference

		node:  save-self-object new
		
		if size <= 0 [return new]						;-- empty object!
		
		;-- process SYMBOLS
		dst: as series! nctx/symbols/value
		copy-memory as byte-ptr! dst/offset as byte-ptr! src/offset size
		dst/tail: dst/offset + slots
		_context/set-context-each dst new/ctx

		;-- process VALUES
		src: as series! ctx/values/value
		dst: as series! nctx/values/value
		copy-memory as byte-ptr! dst/offset as byte-ptr! src/offset size
		dst/tail: dst/offset + slots
		
		value: dst/offset
		tail:  dst/tail
		
		either deep? [
			while [value < tail][
				switch TYPE_OF(value) [
					TYPE_BLOCK
					TYPE_PAREN
					TYPE_PATH				;-- any-path!
					TYPE_LIT_PATH
					TYPE_SET_PATH
					TYPE_GET_PATH
					TYPE_STRING				;-- any-string!
					TYPE_FILE
					TYPE_URL
					TYPE_TAG
					TYPE_EMAIL [
						actions/copy 
							as red-series! value
							value						;-- overwrite the value
							null
							yes
							null
					]
					TYPE_FUNCTION [
						rebind as red-function! value nctx node
					]
					default [0]
				]
				value: value + 1
			]
		][
			while [value < tail][
				if TYPE_OF(value) = TYPE_FUNCTION [
					rebind as red-function! value nctx node
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
		same?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		tail?	 [logic!]
		match?	 [logic!]
		return:	 [red-value!]
		/local
			id	 [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/find"]]
		
		check-word value
		id: rs-find obj value
		as red-value! either id = -1 [none-value][true-value]
	]
	
	select: func [
		obj		 [red-object!]
		value	 [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		same?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		return:	 [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/select"]]
		
		check-word value
		rs-select obj value
	]
	
	modify: func [
		obj		[red-object!]
		field	[red-word!]
		value	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			sym  [integer!]
			args [red-value!]
	][
		sym: symbol/resolve field/symbol
		case [
			sym = words/owner [
				ownership/set-owner as red-value! obj obj null
			]
			sym = words/owned [
				if TYPE_OF(value) = TYPE_NONE [
					ownership/unbind as red-value! obj
				]
				if TYPE_OF(value) = TYPE_BLOCK [
					args: block/rs-head as red-block! value
					assert TYPE_OF(args) = TYPE_OBJECT	;@@ raise error on invalid block
					ownership/set-owner 
						as red-value! obj
						as red-object! args
						as red-word! args + 1
				]
			]
			true [0]
		]
		value
	]

	put: func [
		obj		[red-object!]
		field	[red-value!]
		value	[red-value!]
		case?	[logic!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/put"]]

		eval-path obj field value as red-value! none-value case?
		value
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
			:compare
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
			null			;move
			null			;next
			null			;pick
			null			;poke
			:put
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
			:modify
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