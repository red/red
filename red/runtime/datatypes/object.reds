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
			syms	[series!]
			values	[series!]
			sym		[red-value!]
			s-tail	[red-value!]
			value	[red-value!]
	][
		syms:   as series! obj/symbols/value
		values: as series! obj/values/value
		
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
	
	rebind: func [
		fun		[red-function!]
		ctx 	[red-context!]
		/local
			s	 [series!]
			more [red-value!]
	][
		s: as series! fun/more/value
		more: s/offset
		
		if TYPE_OF(more) = TYPE_NONE [
			print-line "*** Error: COPY stuck on missing function's body block"
			halt
		]
		_context/bind as red-block! more ctx yes
		_context/bind as red-block! more fun/ctx no
		
		more: more + 2
		more/header: TYPE_UNSET			;-- invalidate compiled body
	]
	
	make-at: func [
		cell	[red-object!]
		slots	[integer!]
		return: [red-object!]
	][
		cell/header:  TYPE_OBJECT
		cell/symbols: alloc-cells slots
		cell/values:  alloc-cells slots
		cell
	]
	
	;-- Actions -- 
	
	make: func [
		proto	[red-object!]
		spec	[red-block!]
		return:	[red-object!]
		/local
			obj	 [red-object!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/make"]]
		
		obj: as red-object! ALLOC_TAIl(root)
		
		either TYPE_OF(proto) = TYPE_OBJECT [
			copy proto obj null yes null				;-- /deep
		][
			make-at obj 4								;-- arbitrary value
		]
		_context/collect-set-words as red-context! obj spec	
		_context/bind spec as red-context! obj yes
		interpreter/eval spec
		obj
	]
	
	reflect: func [
		obj		[red-object!]
		field	[integer!]
		return:	[red-block!]
		/local
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
		
		case [
			field = words/words [
				blk/node: obj/symbols
				blk: block/clone blk no
			]
			field = words/values [
				blk/node: obj/values
				blk: block/clone blk no
			]
			field = words/body [
				blk/node: obj/symbols
				blk/node: alloc-cells block/rs-length? blk
				
				s: as series! obj/symbols/value
				syms: s/offset
				tail: s/tail
				
				s: as series! obj/values/value
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
		ctx:  as red-context! parent 

		if word/ctx <> ctx [							;-- bind the word to object's context
			word/index: _context/find-word ctx word/symbol
			word/ctx: ctx
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
			value [red-value!]
			tail  [red-value!]
			src	  [series!]
			dst	  [series!]
			size  [integer!]
			slots [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "object/copy"]]
		
		if OPTION?(types) [--NOT_IMPLEMENTED--]

		if OPTION?(part-arg) [
			print-line "***Error: copy/part is not supported on objects"
			halt
		]

		src:	as series! obj/symbols/value
		size:   as-integer src/tail - src/offset
		slots:	size >> 4
		
		new: make-at new slots
		
		;-- process SYMBOLS
		dst: as series! new/symbols/value
		copy-memory as byte-ptr! dst/offset as byte-ptr! src/offset size
		dst/size: size
		dst/tail: dst/offset + slots
		_context/set-context-each as red-context! new dst
		
		;-- process VALUES
		src: as series! obj/values/value
		dst: as series! new/values/value
		copy-memory as byte-ptr! dst/offset as byte-ptr! src/offset size
		dst/size: size
		dst/tail: dst/offset + slots
		
		if deep? [
			value: dst/offset
			tail:  dst/tail
			
			while [value < tail][
				switch TYPE_OF(value) [					;@@ replace it with ANY_SERIES?()
					TYPE_BLOCK
					TYPE_PAREN
					TYPE_PATH
					TYPE_SET_PATH
					TYPE_GET_PATH
					TYPE_LIT_PATH
					TYPE_STRING
					TYPE_FILE [
						actions/copy value value null yes null ;-- overwrite the value
					]
					TYPE_FUNCTION [
						rebind as red-function! value as red-context! new
					]
					default [0]
				]
				value: value + 1
			]
		]

		new
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
			null			;find
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
			null			;select
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