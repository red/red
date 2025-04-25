Red/System [
	Title:   "Object! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %object.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

object: context [
	verbose: 0
	
	class-id: 1'000'000									;-- base ID for dynamically created objects
		
	get-new-id: func [return: [integer!]][				;@@ protect from concurrent accesses
		class-id: class-id + 1
		class-id
	]
	
	rs-find: func [
		obj		 [red-object!]
		value	 [red-value!]
		return:	 [integer!]								;-- -1 if not found, else index
		/local
			word [red-word!]
			type [integer!]
	][
		type: TYPE_OF(value)
		assert ANY_WORD?(type)
		word: as red-word! value
		 _context/find-word GET_CTX(obj) word/symbol yes
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
			type   [integer!]
	][
		type: TYPE_OF(value)
		assert ANY_WORD?(type)
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
	][
		as red-value! _hashtable/get-ctx-word TO_CTX(obj) index
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
			s   [series!]
	][
		s: _hashtable/get-ctx-words GET_CTX(obj)
		(as-integer s/tail - s/offset) >> 4
	]
	
	clear-nl-flags: func [
		s [series!]
		/local
			cell [red-value!]
			tail [red-value!]
	][
		cell: s/offset
		tail: s/tail
		while [cell < tail][
			cell/header: cell/header and flag-nl-mask
			cell: cell + 1
		]
	]
	
	clear-words-flags: func [
		ctx [red-context!]
		/local
			s	 [series!]
			syms [red-value!]
			tail [red-value!]
			mask [integer!]
	][
		s: _hashtable/get-ctx-words ctx
		syms: s/offset
		tail: s/tail
		mask: not flag-word-dirty
		while [syms < tail][
			syms/header: syms/header and mask
			syms: syms + 1
		]
	]
	
	set-many: func [
		obj	  [red-object!]
		value [red-value!]
		any?  [logic!]
		only? [logic!]
		some? [logic!]
		/local
			smudge  [subroutine!]
			ctx		[red-context!]
			ctx2	[red-context!]
			obj2	[red-object!]
			word	[red-word!]
			values	[red-value!]
			values2	[red-value!]
			tail	[red-value!]
			tail2   [red-value!]
			end		[red-value!]
			new		[red-value!]
			old		[red-value!]
			p		[red-pair!]
			s		[series!]
			i		[integer!]
			idx-s	[integer!]
			idx-d	[integer!]
			type	[integer!]
			on-set?	[logic!]
	][
		smudge: [word/header: word/header or flag-word-dirty]
	
		ctx:	 GET_CTX(obj)
		s:		 as series! ctx/values/value				;-- object values
		values:  s/offset
		tail:	 s/tail
		type:	 TYPE_OF(value)
		on-set?: obj/on-set <> null
		
		s:       _hashtable/get-ctx-words ctx				;-- object symbols
		word:    as red-word! s/offset
		tail2:   s/tail
		
		if on-set? [
			s: as series! obj/on-set/value
			p: as red-pair! s/offset
			idx-s: p/x >> 16
			p: p + 1
			idx-d: p/x >> 16
		]

		either all [not only? any [type = TYPE_BLOCK type = TYPE_OBJECT]][
			either type = TYPE_BLOCK [				;-- first value slot
				end:     block/rs-tail as red-block! value
				values2: block/rs-head as red-block! value
			][
				obj2:    as red-object! value
				ctx:     GET_CTX(obj2)
				s:       as series! ctx/values/value 
				end:     s/tail
				values2: s/offset
			]
			
			i: 0
			if all [not only? not some?][					;-- pre-check of unset values
				while [word < tail2][
					if values2 = end [break]				;-- reached the end of the rightmost argument
					if all [not any? TYPE_OF(values2) = TYPE_UNSET][
						fire [TO_ERROR(script need-value) word]
					]
					i: i + 1
					word: word + 1
					values2: values2 + 1
				]
			]
		
			word: word - i									;-- reset pointers after iteration
			values2: values2 - i
			
			either type = TYPE_BLOCK [
				i: 0
				while [values < tail][
					new: _series/pick as red-series! value i + 1 null
					unless all [some? TYPE_OF(new) = TYPE_NONE][
						either on-set? [
							if all [i <> idx-s i <> idx-d][	;-- do not overwrite event handlers
								old: stack/push values
								copy-cell new values
								fire-on-set obj word old new
							]
						][
							copy-cell new values
						]
						smudge
					]
					i: i + 1
					word: word + 1
					values: values + 1
				]
			][
				obj2: as red-object! value
				ctx2: GET_CTX(obj2)
				while [values < tail][
					i: _context/find-word ctx2 word/symbol yes
					if i > -1 [
						new: values2 + i
						unless all [some? TYPE_OF(new) = TYPE_NONE][
							either on-set? [
								if all [i <> idx-s i <> idx-d][		;-- do not overwrite event handlers
									old: stack/push values
									copy-cell new values
									fire-on-set obj word old new
								]
							][
								copy-cell new values
							]
							smudge
						]
					]
					word: word + 1
					values: values + 1
				]
			]
		][
			i: 0
			while [values < tail][
				either on-set? [
					if all [i <> idx-s i <> idx-d][		;-- do not overwrite event handlers
						old: stack/push values
						copy-cell value values
						fire-on-set obj word old value
					]
				][
					copy-cell value values
				]
				smudge
				i: i + 1
				word: word + 1
				values: values + 1
			]
		]
	]

	make-callback-node: func [
		spec-s	[node!]
		spec-d	[node!]
		idx-s	[integer!]								;-- for on-change* event
		loc-s	[integer!]
		idx-d	[integer!]								;-- for on-deep-change* event
		loc-d	[integer!]
		return: [node!]
		/local
			node [node!]
			p	 [red-pair!]
			s	 [series!]
	][
		node: alloc-cells 2
		s: as series! node/value
		p: as red-pair! s/offset
		p/header: TYPE_PAIR
		p/x: (idx-s << 16) or loc-s				;-- cache info for on-change* position and locals count
		p/y: as-integer spec-s					;-- cache fun/spec node (change detection purpose)

		p: as red-pair! s/offset + 1
		p/header: TYPE_PAIR
		p/x: (idx-d << 16) or loc-d				;-- cache info for on-deep-change* position and locals count
		p/y: as-integer spec-d					;-- cache fun/spec node (change detection purpose)
		node
	]
	
	on-deep?: func [
		obj		[red-object!]
		return: [logic!]
		/local
			p	[red-pair!]
			s	[series!]
	][
		if obj/on-set <> null [
			s: as series! obj/on-set/value
			p: as red-pair! s/offset + 1
			if p/x >> 16 <> -1 [return true]
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
			spec-s	[node!]
			spec-d	[node!]
			idx-s	[integer!]
			idx-d	[integer!]
			loc-s	[integer!]
			loc-d	[integer!]
			sym		[integer!]
			type	[integer!]
	][
		s:		 _hashtable/get-ctx-words ctx
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
			type: TYPE_OF(fun)
			if all [type <> TYPE_FUNCTION type <> TYPE_ROUTINE][
				fire [TO_ERROR(script bad-field-set) words/_on-change* datatype/push type]
			]
			spec-s: fun/spec
			loc-s: _function/count-locals spec-s 0 no
		]
		if idx-d >= 0 [
			fun: as red-function! s/offset + idx-d
			type: TYPE_OF(fun)
			if all [type <> TYPE_FUNCTION type <> TYPE_ROUTINE][
				fire [TO_ERROR(script bad-field-set) words/_on-deep-change* datatype/push type]
			]
			spec-d: fun/spec
			loc-d: _function/count-locals spec-d 0 no
		]
		make-callback-node spec-s spec-d idx-s loc-s idx-d loc-d
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
	
	loc-ctx-fire-on-set*: func [						;-- compiled code entry point
		parent-ctx [node!]
		field      [red-word!]
		/local
			s	[series!]
			obj	[red-value!]
	][
		s: as series! parent-ctx/value
		obj: as red-value! s/offset + 1
		loc-fire-on-set* obj field
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
			p	  [red-pair!]
			ctx	  [red-context!]
			index [integer!]
			count [integer!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/fire-on-set"]]
		
		assert TYPE_OF(obj) = TYPE_OBJECT
		assert obj/on-set <> null
		
		s: as series! obj/on-set/value
		p: as red-pair! s/offset
		assert TYPE_OF(p) = TYPE_PAIR
		index: p/x >> 16
		count: p/x and FFFFh
		if index = -1 [exit]							;-- abort if no on-change* handler
		
		ctx: GET_CTX(obj) 
		s: as series! ctx/values/value
		fun: as red-function! s/offset + index
		if TYPE_OF(fun) <> TYPE_FUNCTION [fire [TO_ERROR(script invalid-obj-evt) fun]]
		if fun/spec <> as node! p/y [					;-- check cache validity
			count: _function/count-locals fun/spec 0 no ;-- refresh cached locals count
			p/x: index << 16 or count
			p/y: as-integer fun/spec					;-- refresh cached spec node
		]
		
		if word/ctx <> obj/ctx [						;-- bind word when invoked from compiler (~exec/<word>)
			word: as red-word! stack/push as red-value! word	;@@ not pop after the call, but should be fine.
			_context/bind-word ctx word
		]
		
		stack/mark-func words/_on-change* fun/ctx
		stack/push as red-value! word
		stack/push old
		stack/push new
		if positive? count [_function/init-locals count]
		interpreter/call fun obj/ctx as red-value! words/_on-change* CB_OBJ_CHANGE
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
			p	  [red-pair!]
			ctx	  [red-context!]
			index [integer!]
			count [integer!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/fire-on-deep"]]

		assert TYPE_OF(owner) = TYPE_OBJECT
		if null? owner/on-set [fire [TO_ERROR(script invalid-obj-evt) owner]]
		
		s: as series! owner/on-set/value
		p: as red-pair! s/offset + 1
		assert TYPE_OF(p) = TYPE_PAIR
		index: p/x >> 16
		count: p/x and FFFFh
		if index = -1 [exit]							;-- abort if no on-deep-change* handler		
		if null? new [new: as red-value! none-value]

		ctx: GET_CTX(owner) 
		s: as series! ctx/values/value
		fun: as red-function! s/offset + index
		if TYPE_OF(fun) = TYPE_FUNCTION [
			if fun/spec <> as node! p/y [					;-- check cache validity
				count: _function/count-locals fun/spec 0 no ;-- refresh cached locals count
				p/x: index << 16 or count
				p/y: as-integer fun/spec					;-- refresh cached spec node
			]
			
			stack/mark-func words/_on-deep-change* fun/ctx
			stack/push as red-value! owner
			stack/push as red-value! word
			stack/push target
			stack/push as red-value! action
			stack/push new
			integer/push pos
			integer/push nb
			if positive? count [_function/init-locals count]
			interpreter/call fun owner/ctx as red-value! words/_on-deep-change* CB_OBJ_DEEP
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
		while [n > 0][
			string/concatenate-literal buffer "    "
			n: n - 1
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
			blank	[integer!]
	][
		ctx: 	GET_CTX(obj)
		syms:   _hashtable/get-ctx-words ctx
		values: as series! ctx/values/value
		
		sym:	syms/offset
		s-tail: syms/tail
		value: 	values/offset
		evt1:	words/_on-change*/symbol
		evt2:	words/_on-deep-change*/symbol
		
		if sym = s-tail [return part]					;-- exit if empty

		either flat? [
			indent?: no
			blank: as-integer space
		][
			if mold? [
				either only? [indent?: no][
					string/append-char GET_BUFFER(buffer) as-integer lf
					part: part - 1
				]
			]
			blank: as-integer lf
		]
		cycles/push obj/ctx

		while [sym < s-tail][
			if part <= 0 [
				cycles/pop
				return part
			]

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
				part: actions/mold value buffer no all? flat? arg part tabs

				if any [indent? sym + 1 < s-tail][			;-- no final LF when FORMed
					string/append-char GET_BUFFER(buffer) blank
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

		s: _hashtable/get-ctx-words from
		symbol: s/offset
		tail: s/tail
		
		s: as series! from/values/value
		value: s/offset

		s: as series! to/values/value
		target: s/offset

		while [symbol < tail][
			word: as red-word! symbol
			idx: _context/find-word to word/symbol yes
			assert idx > -1
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
	
	clone-series: func [
		src    [node!]									;-- src context
		dst	   [node!]									;-- dst context (extension of src)
		copy?  [logic!]									;-- TRUE for compiler, FALSE otherwise
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
				actions/copy as red-series! value target null yes null
				
				if ANY_BLOCK?(type) [
					_context/bind as red-block! target to yes
				]
			][
				if copy? [copy-cell value target]		;-- just propagate the old value
			]
			value: value + 1
			target: target + 1
		]
	]
	
	extend: func [
		ctx		[red-context!]							;-- new context
		spec	[red-context!]							;-- spec object context
		obj		[red-object!]							;-- new object
		return: [logic!]								;-- TRUE if words added to new context
		/local
			syms  [red-value!]
			tail  [red-value!]
			vals  [red-value!]
			value [red-value!]
			base  [red-value!]
			word  [red-word!]
			type  [integer!]
			s	  [series!]
	][
		s: _hashtable/get-ctx-words spec
		syms: s/offset
		tail: s/tail

		s: as series! spec/values/value
		vals: s/offset
		
		s: _hashtable/get-ctx-words ctx
		base: s/tail - s/offset
		
		s: as series! ctx/values/value

		;-- 1st pass: fill and eventually extend the context
		while [syms < tail][
			value: _context/add-and-set ctx as red-word! syms vals
			syms: syms + 1
			vals: vals + 1
		]
		
		;-- 2nd pass: deep copy series and rebind functions
		value: s/offset
		tail:  s/tail
		
		while [value < tail][
			type: TYPE_OF(value)
			case [
				ANY_SERIES?(type) [
					actions/copy
						as red-series! value
						value							;-- overwrite the value
						null
						yes
						null
				]
				type = TYPE_FUNCTION [
					rebind as red-function! value ctx
				]
				true [0]
			]
			value: value + 1
		]
		s: _hashtable/get-ctx-words ctx					;-- refreshing pointer
		s/tail - s/offset > base						;-- TRUE: new words added
	]
	
	rebind: func [
		fun	 [red-function!]
		octx [red-context!]
		/local
			s	 [series!]
			more [red-value!]
			blk  [red-block!]
			spec [red-block!]
			ctx	 [red-context!]
			fctx [node!]
	][
		s: as series! fun/more/value
		more: s/offset
		
		if TYPE_OF(more) = TYPE_NONE [
			fire [TO_ERROR(script bad-func-def) fun]
		]
		spec: as red-block! stack/push*
		spec/header: TYPE_BLOCK
		spec/head:	 0
		spec/node:	 fun/spec
		
		fctx: copy-series as series! fun/ctx/value		;-- clone the ctx 2-cell block
		ctx: TO_CTX(fctx)
		
		blk: block/clone as red-block! more yes yes
		_context/bind blk octx yes						;-- rebind new body to object's context
		_context/bind blk ctx  no						;-- rebind new body to function's context
		_function/push spec blk	fctx null null fun/header ;-- recreate function
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
			ss	[series!]
			sz	[integer!]
	][
		ctx: TO_CTX(node)
		s: as series! ctx/values/value
		if s/offset = s/tail [
			ss: _hashtable/get-ctx-words ctx
			sz: (as-integer (ss/tail - ss/offset)) >> 4
			s/tail: s/offset + sz						;-- (late) setting of 'values right tail pointer
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
		return: [node!]
		/local
			obj [red-object!]
			s	[series!]
	][
		obj: as red-object! stack/get-top
		assert TYPE_OF(obj) = TYPE_OBJECT
		obj/on-set: make-callback-node null null idx-s loc-s idx-d loc-d
		if idx-d <> -1 [ownership/set-owner as red-value! obj obj null]
		
		s: as series! ctx/value
		copy-cell as red-value! obj s/offset + 1		;-- refresh back-reference
		obj/on-set
	]
	
	push: func [
		ctx		[node!]
		evt		[node!]
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
		obj/on-set: evt
		
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
		obj/header: TYPE_UNSET
		obj/ctx:	_context/create slots no yes null CONTEXT_OBJECT
		obj/class:	0
		obj/on-set: null
		obj/header: TYPE_OBJECT
		
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

		s: _hashtable/get-ctx-words ctx
		base: s/tail - s/offset
		
		while [cell < tail][
			if TYPE_OF(cell) = TYPE_SET_WORD [
				id: _context/add ctx as red-word! cell
				s: as series! ctx/values/value
				values: s/offset

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
	
	do-copy: func [
		obj      [red-object!]
		new	  	 [red-object!]
		deep?	 [logic!]
		types	 [red-value!]
		evt-rst? [logic!]								;-- TRUE: reset events
		return:	 [red-object!]
		/local
			ctx	  [red-context!]
			nctx  [red-context!]
			value [red-value!]
			tail  [red-value!]
			src	  [series!]
			dst	  [series!]
			node  [node!]
			size  [integer!]
			slots [integer!]
			type  [integer!]
			sym	  [red-word!]
			w-ctx [node!]
	][
		ctx:	GET_CTX(obj)
		src:	_hashtable/get-ctx-words ctx
		size:   as-integer src/tail - src/offset
		slots:	size >> 4

		type: TYPE_OF(obj)								;-- object!, error!, port!,...
		new/header: TYPE_UNSET
		new/ctx: _context/create slots no yes ctx CONTEXT_OBJECT
		new/class: obj/class
		either evt-rst? [new/on-set: null][new/on-set: obj/on-set]
		new/header: type

		nctx: GET_CTX(new)
		copy-cell as red-value! new as red-value! nctx + 1	;-- set back-reference

		if size <= 0 [return new]						;-- empty object!

		;-- process SYMBOLS
		sym: _hashtable/get-ctx-word nctx 0
		w-ctx: new/ctx
		loop slots [
			sym/ctx: w-ctx
			sym: sym + 1
		]

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
					TYPE_ANY_PATH
					TYPE_ANY_STRING [
						actions/copy 
							as red-series! value
							value						;-- overwrite the value
							null
							yes
							null
					]
					TYPE_FUNCTION [
						rebind as red-function! value nctx
					]
					default [0]
				]
				value: value + 1
			]
		][
			while [value < tail][
				if TYPE_OF(value) = TYPE_FUNCTION [
					rebind as red-function! value nctx
				]
				value: value + 1
			]
		]
		if evt-rst? [register-events new nctx]
		new
	]
	
	construct: func [
		spec	[red-block!]
		proto	[red-object!]
		only?	[logic!]
		return:	[red-object!]
		/local
			obj	 [red-object!]
	][
		obj: as red-object! stack/push*
		either null? proto [
			make-at obj 4									;-- arbitrary value
			obj/class: get-new-id
			obj/on-set: null
		][
			copy proto obj null yes null
		]
		collect-couples GET_CTX(obj) spec only?
		obj
	]
	
	register-events: func [
		obj [red-object!]
		ctx [red-context!]
	][
		obj/on-set: on-set-defined? ctx
		if on-deep? obj [ownership/set-owner as red-value! obj obj null]
		copy-cell as red-value! obj as red-value! ctx + 1
	]
	
	;-- Actions --
	
	make: func [
		proto	[red-object!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-object!]
		/local
			obj		[red-object!]
			obj2	[red-object!]
			ctx		[red-context!]
			blk		[red-block!]
			p-obj?  [logic!]
			new?	[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/make"]]
		
		obj: as red-object! stack/push*
		obj/header: TYPE_UNSET
		
		p-obj?: TYPE_OF(proto) = TYPE_OBJECT
		
		either p-obj? [
			do-copy proto obj yes null no				;-- /deep and keep events
		][
			make-at obj 4								;-- arbitrary value
		]
		ctx: GET_CTX(obj)
		
		switch TYPE_OF(spec) [
			TYPE_OBJECT [
				obj2: as red-object! spec
				obj/class: either extend ctx GET_CTX(obj2) obj [get-new-id][proto/class] ;@@ class-id is not transmitted for 'self!
				register-events obj ctx
			]
			TYPE_BLOCK [
				blk: as red-block! spec
				new?: _context/collect-set-words ctx blk
				_context/bind blk ctx yes				;-- bind spec block
				if p-obj? [clone-series proto/ctx obj/ctx no] ;-- clone and rebind proto's series
				
				interpreter/eval blk no
				
				clear-words-flags ctx
				clear-nl-flags as series! ctx/values/value
				obj/class: either any [new? not p-obj?][get-new-id][proto/class]
				register-events obj ctx
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
			len	  [integer!]
	][
		blk: 		as red-block! stack/push*
		blk/header: TYPE_BLOCK
		blk/head: 	0
		
		ctx: GET_CTX(obj)
		
		case [
			field = words/changed [
				blk/header: TYPE_UNSET
				blk/node: alloc-cells 2
				blk/header: TYPE_BLOCK
				s: _hashtable/get-ctx-words ctx
				syms: s/offset
				tail: s/tail
				s: GET_BUFFER(blk)
				
				while [syms < tail][
					if syms/header and flag-word-dirty <> 0 [copy-cell as cell! syms ALLOC_TAIL(blk)]
					syms: syms + 1
				]
			]
			field = words/class [
				return as red-block! integer/box obj/class
			]
			field = words/words [
				blk/node: _hashtable/get-ctx-symbols ctx
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
				blk/node: _hashtable/get-ctx-symbols ctx
				len: block/rs-length? blk
				if len = 0 [len: 1]
				blk/header: TYPE_UNSET
				blk/node: alloc-cells len
				blk/header: TYPE_BLOCK
				
				s: _hashtable/get-ctx-words ctx
				syms: s/offset
				tail: s/tail
				
				s: as series! ctx/values/value
				vals: s/offset
				
				while [syms < tail][
					word: as red-word! block/rs-append blk syms
					word/header: TYPE_SET_WORD or flag-new-line
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
			field = words/owner [
				return as red-block! logic/box ctx/header and flag-owner <> 0
			]
			field = words/events? [
				return as red-block! logic/box obj/on-set <> null
			]
			true [
				--NOT_IMPLEMENTED--						;@@ raise error
			]
		]
		assert all [blk/header and get-type-mask = TYPE_BLOCK blk/node <> null]
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

		if cycles/detect? as red-value! obj buffer :part no [return part]
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
		
		if cycles/detect? as red-value! obj buffer :part yes [return part]
		
		unless only? [
			string/concatenate-literal buffer "make object! ["
			part: part - 14
		]
		part: serialize obj buffer only? all? flat? arg part yes indent + 1 yes
		if all [not flat? indent > 0][part: do-indent buffer indent part]
		either only? [part][
			string/append-char GET_BUFFER(buffer) as-integer #"]"
			part - 1
		]
	]
	
	eval-path: func [
		parent	[red-object!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		gparent [red-value!]
		p-item	[red-value!]
		index	[integer!]
		case?	[logic!]
		get?	[logic!]
		tail?	[logic!]
		evt?	[logic!]
		return:	[red-value!]
		/local
			word	 [red-word!]
			ctx		 [red-context!]
			old		 [red-value!]
			res		 [red-value!]
			on-set?  [logic!]
			do-error [subroutine!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/eval-path"]]
	
		do-error: [
			case [
				all [get? tail?][res: as red-value! unset/push]
				tail? [fire [TO_ERROR(script invalid-path) path element]]
				true  [fire [TO_ERROR(script unset-path) path element]]
			]
		]
		word: as red-word! element
		if TYPE_OF(word) <> TYPE_WORD [fire [TO_ERROR(script invalid-path) path element]]

		res: null
		ctx: GET_CTX(parent)
		if any [word/ctx <> parent/ctx word/index = -1][ ;-- bind the word to object's context
			word/index: _context/find-word ctx word/symbol yes
			if word/index = -1 [do-error return res]
			word/ctx: parent/ctx
		]
		on-set?: parent/on-set <> null
		
		either value <> null [
			if all [word/index = -1	word/symbol = words/self][
				fire [TO_ERROR(script invalid-path) path element]
			]
			if on-set? [old: stack/push _context/get-in word ctx]
			_context/set-in word value ctx no
			if on-set? [fire-on-set parent as red-word! element old value]
			res: value
		][
			res: _context/get-in word ctx
			if TYPE_OF(res) = TYPE_UNSET [do-error]
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

		either obj1/ctx = obj2/ctx [return 0][
			if op = COMP_SAME [return -1]
		]

		if cycles/find? obj1/ctx [
			return either cycles/find? obj2/ctx [0][-1]
		]

		ctx1: GET_CTX(obj1)
		s: _hashtable/get-ctx-words ctx1
		sym1: as red-word! s/offset
		tail: as red-word! s/tail
		
		ctx2: GET_CTX(obj2)
		s: _hashtable/get-ctx-words ctx2

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
		cycles/push obj2/ctx
		
		until [
			s1: symbol/resolve sym1/symbol
			s2: symbol/resolve sym2/symbol
			if s1 <> s2 [
				cycles/pop-n 2
				return SIGN_COMPARE_RESULT(s1 s2)
			]
			type1: TYPE_OF(value1)
			type2: TYPE_OF(value2)
			either any [
				type1 = type2
				all [word/any-word? type1 word/any-word? type2]
				all [ANY_NUMBER?(type1) ANY_NUMBER?(type2)]
			][
				res: actions/compare-value value1 value2 op
				sym1: sym1 + 1
				sym2: sym2 + 1
				value1: value1 + 1
				value2: value2 + 1
			][
				cycles/pop-n 2
				return SIGN_COMPARE_RESULT(type1 type2)
			]
			any [
				res <> 0
				sym1 >= tail
			]
		]
		cycles/pop-n 2
		res
	]
	
	copy: func [
		obj      [red-object!]
		new	  	 [red-object!]
		part-arg [red-value!]
		deep?	 [logic!]
		types	 [red-value!]
		return:	 [red-object!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/copy"]]
		
		if OPTION?(part-arg) [
			ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
		]
		if OPTION?(types) [--NOT_IMPLEMENTED--]

		do-copy obj new deep? types yes
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
		/local
			type [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/select"]]
		
		type: TYPE_OF(value)
		unless ANY_WORD?(type) [
			fire [TO_ERROR(script invalid-type) datatype/push type]
		]
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
			sym = words/changed [
				if TYPE_OF(value) <> TYPE_NONE [fire [TO_ERROR(script invalid-arg) value]]
				clear-words-flags GET_CTX(obj)
			]
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
		/local
			word [red-word!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/put"]]

		word: as red-word! field
		if TYPE_OF(word) <> TYPE_WORD [fire [TO_ERROR(script invalid-key-type) datatype/push TYPE_OF(word)]]
		
		eval-path obj field value as red-value! none-value null null -1 case? no yes no
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
			null			;find
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