Red/System [
	Title:   "Function! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %function.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
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

		result: block/find ignore word null no no no null null no no no no

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
			assert any [								;-- replace with ANY_WORD?
				TYPE_OF(slot) = TYPE_WORD
				TYPE_OF(slot) = TYPE_GET_WORD
				TYPE_OF(slot) = TYPE_LIT_WORD
			]
			collect-word slot list ignore
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
			many? [logic!]
			slot  [red-value!]
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
						;EQUAL_SYMBOLS?(w/symbol words/remove-each)
						;EQUAL_SYMBOLS?(w/symbol words/map-each)
					]
					if any [
						many?
						EQUAL_SYMBOLS?(w/symbol words/repeat)
					][
						if value + 1 < tail [
							slot: value + 1
							either all [many? TYPE_OF(slot) = TYPE_BLOCK][
								collect-many-words as red-block! slot list ignore
							][
								collect-word slot list ignore
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
			s		[series!]
			extern? [logic!]
	][
		list: block/push* 8
		block/rs-append list as red-value! refinements/local
		
		ignore: block/clone spec no
		block/rs-append ignore as red-value! refinements/local
		
		value:  as red-value! refinements/extern		;-- process optional /extern
		extern: as red-block! block/find spec value null no no no null null no no no no
		extern?: TYPE_OF(extern) <> TYPE_NONE
		
		if extern? [
			s: GET_BUFFER(spec)
			s/tail: s/offset + extern/head				;-- cut /extern and extern words out			
		]
		stack/pop 1										;-- remove FIND result from stack
		
		value:  block/rs-head ignore
		tail:	block/rs-tail ignore
		
		while [value < tail][
			switch TYPE_OF(value) [
				TYPE_WORD 	  [0]						;-- do nothing
				TYPE_REFINEMENT
				TYPE_GET_WORD
				TYPE_SET_WORD [
					value/header: TYPE_WORD				;-- convert it to a word!
				]
				default [
					if extern? [
						print-line ["*** Error: invalid /extern values"]
						halt
					]
				]
			]
			value: value + 1
		]
		
		collect-deep list ignore body
		
		if 1 < block/rs-length? list [
			block/rs-append-block spec list
		]
		list
	]
	
	validate: func [									;-- temporary mimalist spec checking
		spec [red-block!]
		/local
			value  [red-value!]
			end	   [red-value!]
			next   [red-value!]
			block? [logic!]
	][
		value: block/rs-head spec
		end:   block/rs-tail spec
		
		while [value < end][
			switch TYPE_OF(value) [
				TYPE_WORD
				TYPE_GET_WORD [
					next: value + 1
					block?: all [
						next < end
						TYPE_OF(next) = TYPE_BLOCK
					]
					value: value + either block? [2][1]
				]
				TYPE_SET_WORD [
					next: value + 1
					unless all [
						next < end
						TYPE_OF(next) = TYPE_BLOCK
					][
						print-line "*** Error: return: not followed by type in function spec"
						halt
					]
					value: next
				]
				TYPE_LIT_WORD
				TYPE_REFINEMENT
				TYPE_BLOCK
				TYPE_STRING [
					value: value + 1
				]
				default [
					print-line "*** Error: invalid value in function spec"
					halt
				]
			]
		]
	]
	
	init-locals: func [
		nb 	   [integer!]
		/local
			p  [red-value!]
	][
		until [
			p: stack/push*
			p/header: TYPE_NONE
			nb: nb - 1
			zero? nb
		]
	]

	push: func [
		spec	 [red-block!]
		body	 [red-block!]
		ctx		 [red-context!]							;-- if not null, context is predefined by compiler
		code	 [integer!]
		return:	 [red-context!]							;-- return function's local context
		/local
			fun    [red-function!]
			native [red-native!]
			value  [red-value!]
			more   [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "_function/push"]]

		fun: as red-function! stack/push*
		fun/header:  TYPE_FUNCTION						;-- implicit reset of all header flags
		fun/spec:	 spec/node
		fun/ctx:	 either null? ctx [_context/make spec yes][ctx]
		fun/more:	 alloc-cells 3
		
		more: as series! fun/more/value
		value: either null? body [none-value][as red-value! body]
		copy-cell value alloc-tail more					;-- store body block or none
		alloc-tail more									;-- reserved place for "symbols"
		
		native: as red-native! alloc-tail more
		native/header: TYPE_NATIVE
		native/code: code
		
		if all [null? ctx not null? body][
			_context/bind body fun/ctx no				;-- do not bind if predefined context (already done)
		]
		fun/ctx
	]
		
	;-- Actions -- 
	
	reflect: func [
		fun		[red-function!]
		field	[integer!]
		return:	[red-block!]
		/local
			blk [red-block!]
			s	[series!]
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
				blk: as red-block! s/offset
				stack/set-last as red-value! blk
			]
			field = words/words [
				--NOT_IMPLEMENTED--						;@@ build the words block from spec
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
			s	[series!]
			blk [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "function/mold"]]

		string/concatenate-literal buffer "func "
		
		blk: as red-block! stack/push*
		blk/header: TYPE_BLOCK
		blk/head: 0
		blk/node: fun/spec
		part: block/mold blk buffer only? all? flat? arg part - 5 indent	;-- spec
		
		s: as series! fun/more/value
		block/mold as red-block! s/offset buffer only? all? flat? arg part indent	;-- body
	]

	init: does [
		datatype/register [
			TYPE_FUNCTION
			TYPE_CONTEXT
			"function!"
			;-- General actions --
			null			;make
			null			;random
			:reflect
			null			;to
			:form
			:mold
			null			;get-path
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
			null			;copy
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