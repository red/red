Red/System [
	Title:   "Function! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %function.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2012-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

_function: context [
	verbose: 0
		
	collect-word: func [
		value  [red-value!]
		list   [red-block!]
		ignore [red-block!]
		/local		
			result [red-value!]
			word   [red-value!]
	][
		word: stack/push value
		word/header: TYPE_WORD							;-- convert the set-word! into a word!

		result: block/find ignore word null no no no no null null no no no no

		if TYPE_OF(result) = TYPE_NONE [
			block/rs-append list word
			block/rs-append ignore word
		]
		stack/pop 2										;-- remove word and FIND result from stack
	]
	
	collect-many-words: func [
		blk	   [red-block!]
		list   [red-block!]
		ignore [red-block!]
		/local
			slot  [red-value!]
			tail  [red-value!]
	][
		slot: block/rs-head blk
		tail: block/rs-tail blk
		
		while [slot < tail][
			if any [								;-- replace with ANY_WORD?
				TYPE_OF(slot) = TYPE_WORD
				TYPE_OF(slot) = TYPE_GET_WORD
				TYPE_OF(slot) = TYPE_LIT_WORD
			][
				collect-word slot list ignore
			]
			slot: slot + 1
		]
	]
	
	collect-deep: func [
		list   [red-block!]
		ignore [red-block!]
		blk    [red-block!]
		/local
			value [red-value!]
			tail  [red-value!]
			w	  [red-word!]
			slot  [red-value!]
			type  [integer!]
			many? [logic!]
	][
		value: block/rs-head blk
		tail:  block/rs-tail blk
		
		while [value < tail][
			switch TYPE_OF(value) [
				TYPE_SET_WORD [
					collect-word value list ignore
				]
				TYPE_WORD [
					w: as red-word! value
					many?: any [
						EQUAL_SYMBOLS?(w/symbol words/foreach)
						EQUAL_SYMBOLS?(w/symbol words/remove-each)
						;EQUAL_SYMBOLS?(w/symbol words/map-each)
					]
					if any [
						many?
						EQUAL_SYMBOLS?(w/symbol words/repeat)
					][
						if value + 1 < tail [
							slot: value + 1
							type: TYPE_OF(slot)
							either all [many? type = TYPE_BLOCK][
								collect-many-words as red-block! slot list ignore
							][
								if any [type = TYPE_WORD type = TYPE_SET_WORD][
									collect-word slot list ignore
								]
							]
						]
					]
				]
				TYPE_BLOCK
				TYPE_PAREN [
					collect-deep list ignore as red-block! value
				]
				default [0]
			]
			value: value + 1
		]
	]
	
	collect-words: func [
		spec	[red-block!]
		body	[red-block!]
		return: [red-block!]
		/local
			list	[red-block!]
			ignore	[red-block!]
			extern	[red-block!]
			value	[red-value!]
			tail	[red-value!]
			word	[red-word!]
			s		[series!]
			extern? [logic!]
	][
		list: block/push-only* 8
		ignore: block/clone spec no no
		
		value:  as red-value! refinements/extern		;-- process optional /extern
		extern: as red-block! block/find spec value null no no no no null null no no no no
		extern?: no

		if TYPE_OF(extern) = TYPE_BLOCK [
			value: _series/pick as red-series! extern 1 null

			extern?: TYPE_OF(value) = TYPE_REFINEMENT	;-- ensure it is not another word type
			if extern? [
				s: GET_BUFFER(spec)
				value: s/offset + extern/head + 1
				while [all [value < s/tail TYPE_OF(value) = TYPE_WORD]][ ;-- search for end of externs
					value: value + 1
				]
				if all [value < s/tail TYPE_OF(value) = TYPE_REFINEMENT][
					word: as red-word! value
					if refinements/local/symbol = symbol/resolve word/symbol [
						value: value + 1
						while [value < s/tail][			;-- collect explicit locals
							if TYPE_OF(value) = TYPE_WORD [
								block/rs-append list value
							]
							value: value + 1
						]
					]
				]
				s/tail: s/offset + extern/head			;-- cut /extern and extern words out
			]
		]
		stack/pop 1										;-- remove FIND result from stack
		
		value:  block/rs-head ignore
		tail:	block/rs-tail ignore
		
		while [value < tail][
			switch TYPE_OF(value) [
				TYPE_STRING
				TYPE_BLOCK
				TYPE_WORD 	  [0]						;-- do nothing
				TYPE_REFINEMENT
				TYPE_GET_WORD
				TYPE_LIT_WORD
				TYPE_SET_WORD [
					value/header: TYPE_WORD				;-- convert it to a word!
				]
				default [
					if extern? [fire [TO_ERROR(script bad-func-extern) value]]
				]
			]
			value: value + 1
		]
		
		collect-deep list ignore body
		
		if 0 < block/rs-length? list [
			if -1 = count-locals spec/node spec/head yes [
				block/rs-append spec as red-value! refinements/local
			]
			value: as red-value! words/_local
			value: block/find list value null no no no no null null no no no no
			if TYPE_OF(value) <> TYPE_NONE [_series/remove as red-series! value null null] ;@@ will trigger ownership events
			block/rs-append-block spec list
		]
		list
	]
	
	check-duplicates: func [
		spec [red-block!]
		/local
			word [red-word!]
			tail [red-word!]
			pos	 [red-word!]
			sym	 [integer!]
	][
		word: as red-word! block/rs-head spec
		tail: as red-word! block/rs-tail spec
		
		while [word < tail][
			switch TYPE_OF(word) [
				TYPE_WORD
				TYPE_GET_WORD
				TYPE_LIT_WORD
				TYPE_REFINEMENT [
					pos: word
					sym: symbol/resolve word/symbol
					word: word + 1

					while [word < tail][
						switch TYPE_OF(word) [
							TYPE_WORD
							TYPE_GET_WORD
							TYPE_LIT_WORD
							TYPE_REFINEMENT [
								if sym = symbol/resolve word/symbol [
									fire [TO_ERROR(script dup-vars) word]
								]
							]
							default [0]
						]
						word: word + 1
					]
					word: pos
				]
				default [0]
			]
			word: word + 1
		]
	]
	
	check-type-spec: func [
		spec [red-block!]
		/local
			value [red-value!]
			tail  [red-value!]
			v	  [red-value!]
			type  [integer!]
	][
		value: block/rs-head spec
		tail:  block/rs-tail spec

		while [value < tail][
			v: either TYPE_OF(value) = TYPE_WORD [
				word/get as red-word! value
			][
				value
			]
			type: TYPE_OF(v)
			unless any [
				type = TYPE_DATATYPE
				type = TYPE_TYPESET
				type = TYPE_WORD
			][
				fire [TO_ERROR(script invalid-type-spec) value]
			]
			value: value + 1
		]
	]
	
	decode-attributes: func [
		list	[red-block!]
		return: [integer!]
		/local
			w	  [red-word!]
			end	  [red-word!]
			sym	  [integer!]
			flags [integer!]
	][
		w:   as red-word! block/rs-head list
		end: as red-word! block/rs-tail list
		flags: 0
		
		while [w < end][
			if TYPE_OF(w) <> TYPE_WORD [return -1]		;-- error case
			sym: symbol/resolve w/symbol 
			case [
				sym = words/trace 	[flags: flags or flag-force-trace]
				sym = words/no-trace[flags: flags or flag-no-trace]
				true 				[0]
			]
			w: w + 1
		]
		flags
	]
	
	validate: func [									;-- temporary minimalist spec checking
		spec	[red-block!]
		return: [integer!]
		/local
			value  [red-value!]
			end	   [red-value!]
			next   [red-value!]
			next2  [red-value!]
			w      [red-word!]
			flags  [integer!]
			local? [logic!]
			ret?   [logic!]
			do-error [subroutine!]
	][
		do-error: [fire [TO_ERROR(script bad-func-def) spec]]
		value:  block/rs-head spec
		end:    block/rs-tail spec
		local?: ret?: no
		flags:  0
		
		if all [value < end TYPE_OF(value) = TYPE_BLOCK][
			flags: decode-attributes as red-block! value
			if flags = -1 [do-error]
			value: value + 1							;-- skip optional attributs block
		]
		
		while [value < end][
			switch TYPE_OF(value) [
				TYPE_WORD
				TYPE_GET_WORD
				TYPE_LIT_WORD [
					if all [local? any [TYPE_OF(value) = TYPE_GET_WORD TYPE_OF(value) = TYPE_LIT_WORD]][do-error]
					next: value + 1
					if all [next < end TYPE_OF(next) = TYPE_STRING][
						next2: next + 1
						if all [next2 < end TYPE_OF(next2) = TYPE_BLOCK][do-error]
					]
					if all [ret? not local?][do-error]
					value: value + 1
					if all [
						next < end
						TYPE_OF(next) = TYPE_BLOCK
					][
						check-type-spec as red-block! next
						value: value + 1
					]
				]
				TYPE_SET_WORD [								 ;-- only return: is allowed as a set-word!
					w: as red-word! value
					if words/return* <> symbol/resolve w/symbol [do-error]
					next: value + 1
					next2: next + 1
					unless all [
						next < end
						TYPE_OF(next) = TYPE_BLOCK			 ;-- return: must have a type spec
						any [
							next2 = end						 ;-- return: with type spec is enough
							TYPE_OF(next2) = TYPE_REFINEMENT ;-- This allows a return: spec before each refinement
							TYPE_OF(next2) = TYPE_STRING	 ;-- docstring is allowed for returned arg
						]
					][do-error]
					ret?: yes
					value: next2
				]
				TYPE_REFINEMENT [
					w: as red-word! value 
					either refinements/local/symbol = symbol/resolve w/symbol [local?: yes][
						if local? [do-error]
					]
					next: value + 1
					if next < end [
						if all [
							TYPE_OF(next) <> TYPE_WORD
							TYPE_OF(next) <> TYPE_GET_WORD
							TYPE_OF(next) <> TYPE_LIT_WORD
							TYPE_OF(next) <> TYPE_REFINEMENT
							TYPE_OF(next) <> TYPE_SET_WORD
							TYPE_OF(next) <> TYPE_STRING
						][
							value: next do-error
						]
					]
					value: value + 1
				]
				TYPE_STRING [
					value: value + 1
				]
				default [do-error]
			]
		]
		check-duplicates spec
		flags
	]
	
	count-locals: func [
		node	[node!]
		offset	[integer!]
		local?	[logic!]								;-- TRUE: return -1 to signify lack of /local refinement
		return: [integer!]
		/local
			value  [red-value!]
			tail   [red-value!]
			ref	   [red-refinement!]
			s	   [series!]
			sym	   [integer!]
			cnt	   [integer!]
			count? [logic!]
	][
		s: as series! node/value
		value:  s/offset + offset
		tail:   s/tail
		sym: 	refinements/local/symbol
		count?: no
		cnt:	0
		
		while [value < tail][
			switch TYPE_OF(value) [
				TYPE_REFINEMENT [
					unless count? [
						ref: as red-refinement! value
						if sym = symbol/resolve ref/symbol [
							count?: yes
							cnt: cnt + 1
						]
					]
				]
				TYPE_WORD [if count? [cnt: cnt + 1]]
				default	  [0]
			]
			value: value + 1
		]
		either all [local? not count?][-1][cnt]
	]
	
	init-locals: func [
		nb 	   [integer!]
		/local
			p  [red-value!]
	][
		assert nb > 0
		logic/push false								;-- /local = false
		nb: nb - 1
		while [nb > 0][
			p: stack/push*
			p/header: TYPE_NONE
			nb: nb - 1
		]
	]

	push: func [
		spec	 [red-block!]
		body	 [red-block!]
		ctx		 [node!]								;-- if not null, context is predefined by compiler
		code	 [integer!]
		obj-ctx	 [node!]
		flags	 [integer!]
		return:	 [node!]								;-- return function's local context reference
		/local
			fun    [red-function!]
			native [red-native!]
			value  [red-value!]
			int	   [red-integer!]
			args   [red-block!]
			more   [series!]
			s	   [series!]
			f-ctx  [node!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_function/push"]]

		f-ctx: either null? ctx [_context/make spec yes no CONTEXT_FUNCTION][ctx]
		fun: as red-function! stack/push*
		fun/header: TYPE_UNSET
		fun/spec:	spec/node
		fun/ctx:	f-ctx
		fun/more:	alloc-unset-cells 5
		fun/header: TYPE_FUNCTION or flags
		
		s: as series! f-ctx/value
		copy-cell as red-value! fun s/offset + 1		;-- set back-reference
		
		more: as series! fun/more/value
		either null? body [
			value: none-value
		][
			body: block/clone body yes yes
			stack/pop 1
			value: as red-value! body
		]
		copy-cell value alloc-tail more					;-- store body block or none
		
		alloc-tail more									;-- skip the precompiled args slot
		
		int: as red-integer! alloc-tail more			;; (reserved for future use)
		if code <> 0 [
			int/header: TYPE_INTEGER
			int/value: code
		]
		
		value: alloc-tail more							;-- function! value self-reference (for op!)
		value/header: TYPE_UNSET
		
		int: as red-integer! alloc-tail more
		either null? obj-ctx [
			int/header: TYPE_UNSET
		][
			int/header: TYPE_INTEGER
			int/value: as-integer obj-ctx				;-- store the pointer as 32-bit integer
		]
		
		if all [null? ctx not null? body][
			_context/bind body GET_CTX(fun) no			;-- do not bind if predefined context (already done)
		]
		f-ctx
	]
		
	;-- Actions --
	
	make: func [
		proto	[red-value!]
		list	[red-block!]
		type	[integer!]
		return:	[red-function!]
		/local
			spec  [red-block!]
			body  [red-block!]
			flags [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "function/make"]]
		
		if any [
			TYPE_OF(list) <> TYPE_BLOCK
			2 > block/rs-length? list
		][
			fire [TO_ERROR(script bad-func-def)	list]
		]
		spec: as red-block! block/rs-head list
		
		if TYPE_OF(spec) <> TYPE_BLOCK [
			fire [TO_ERROR(script bad-func-def)	list]
		]
		flags: validate spec
		body: spec + 1
		
		if TYPE_OF(body) <> TYPE_BLOCK [
			fire [TO_ERROR(script bad-func-def)	list]
		]
		push spec body null 0 null flags
		as red-function! stack/get-top
	]
	
	reflect: func [
		fun		[red-function!]
		field	[integer!]
		return:	[red-block!]
		/local
			blk	 [red-block!]
			word [red-word!]
			tail [red-value!]
			s	 [series!]
	][
		case [
			field = words/spec [
				blk: as red-block! stack/arguments		;-- overwrite the function slot on stack
				blk/header: TYPE_BLOCK
				blk/node: fun/spec						;-- order of assignments matters
				blk/head: 0
			]
			field = words/body [
				s: as series! fun/more/value
				stack/set-last s/offset
			]
			field = words/words [
				blk: as red-block! stack/arguments		;-- overwrite the function slot on stack
				blk/header: TYPE_BLOCK
				blk/node: _hashtable/get-ctx-symbols GET_CTX(fun)
				blk/head: 0
				blk: block/clone blk no no
				
				word: as red-word! block/rs-head blk
				tail: block/rs-tail blk
				while [word < as red-word! tail][
					word/ctx: fun/ctx
					word: word + 1
				]
			]
			true [
				--NOT_IMPLEMENTED--						;@@ raise error
			]
		]
		blk												;@@ TBD: remove it when all cases implemented
	]
	
	form: func [
		value	[red-function!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "function/form"]]

		string/concatenate-literal buffer "?function?"
		part - 10
	]

	mold: func [
		fun		[red-function!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			s	  [series!]
			blk	  [red-block! value]
			value [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "function/mold"]]

		string/concatenate-literal buffer "func "
		
		blk/header: TYPE_BLOCK
		blk/head: 0
		blk/node: fun/spec
		part: block/mold blk buffer no all? flat? arg part - 5 indent	;-- spec
		
		s: as series! fun/more/value
		value: s/offset
		either TYPE_OF(value) = TYPE_NONE [
			string/concatenate-literal buffer " none"
			part - 5
		][
			block/mold as red-block! s/offset buffer no all? flat? arg part indent	;-- body
		]
	]

	compare: func [
		arg1	[red-function!]							;-- first operand
		arg2	[red-function!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			type  [integer!]
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "function/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_FUNCTION [RETURN_COMPARE_OTHER]
		switch op [
			COMP_EQUAL
			COMP_FIND
			COMP_SAME
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [
				res: SIGN_COMPARE_RESULT((as-integer arg1/more) (as-integer arg2/more))
			]
			default [
				res: -2
			]
		]
		res
	]

	init: does [
		datatype/register [
			TYPE_FUNCTION
			TYPE_CONTEXT
			"function!"
			;-- General actions --
			:make
			null			;random
			:reflect
			null			;to
			:form
			:mold
			null			;eval-path
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
			null			;copy
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
			null			;put
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