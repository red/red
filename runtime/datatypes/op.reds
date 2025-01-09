Red/System [
	Title:   "Op! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %op.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

op: context [
	verbose: 0
	
	binary?: func [										;-- check if arity is binary
		spec	[node!]
		return: [logic!]
		/local
			value [red-value!]
			tail  [red-value!]
			word  [red-word!]
			s	  [series!]
			arity [integer!]
			sym	  [integer!]
			left? [logic!]
	][
		s: as series! spec/value
		value: s/offset
		tail:  s/tail
		arity: 0
		left?: no
		
		while [value < tail][
			switch TYPE_OF(value) [
				TYPE_WORD [
					left?: yes
					arity: arity + 1
				]
				TYPE_GET_WORD
				TYPE_LIT_WORD [
					unless left? [return false]			;-- get/lit-arg on left operand not supported
					arity: arity + 1
				]
				TYPE_REFINEMENT [
					word: as red-word! value
					sym: symbol/resolve word/symbol
					either any [
						sym = refinements/local/symbol
						sym = refinements/extern/symbol
					][break][return no]
				]
				TYPE_SET_WORD [break]
				default [0]
			]
			value: value + 1
		]
		arity = 2
	]
	
	;-- Actions -- 
	
	make: func [
		proto	[red-value!]
		spec	[red-block!]							;-- type casted to red-block! to avoid an additional var
		dtype	[integer!]
		return:	[red-op!]
		/local
			op		[red-op!]
			fun		[red-function!]
			type	[integer!]
			s		[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "op/make"]]

		type: TYPE_OF(spec)
		unless any [
			type = TYPE_ACTION							;@@ replace with ANY_NATIVE? when available
			type = TYPE_NATIVE
			type = TYPE_FUNCTION
			type = TYPE_ROUTINE
		][fire [TO_ERROR(script invalid-type) datatype/push type]]
		
		fun: as red-function! spec						;-- /spec field access overlaps in any-function! cells
		unless binary? fun/spec [fire [TO_ERROR(script bad-op-spec)]]
		
		op: as red-op! copy-cell as red-value! spec stack/arguments
		if any [type = TYPE_FUNCTION type = TYPE_ROUTINE][
			fun: as red-function! spec
			s: as series! fun/more/value
			;@@ check if slot #4 is already set!
			copy-cell as red-value! fun s/offset + 3 ;-- save a copy of the function value
		]
		op/header: TYPE_OP or (type << 16)
		op
	]
	
	form: func [
		value	[red-native!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "op/form"]]

		string/concatenate-literal buffer "?op?"
		part - 4
	]
	
	mold: func [
		op		[red-native!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			more [red-value!]
			fun	 [red-function!]
			blk	 [red-block!]
			s	 [series!]
			pre	 [c-string!]
			body?[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "op/mold"]]

		string/concatenate-literal buffer "make op! "
		part: part - 9
		body?: GET_OP_SUBTYPE(op) = TYPE_FUNCTION
		pre: either body? ["func "]["["]
		string/concatenate-literal buffer pre
		part: part - length? pre
		
		stack/mark-native words/_anon					;-- avoid block/mold corrupting current stack frame
		part: block/mold								;-- mold spec
			native/reflect op words/spec
			buffer
			only?
			all?
			flat?
			arg
			part
			indent
		stack/unwind
		
		either body? [										;-- mold body if available
			s: as series! op/more/value
			blk: as red-block! s/offset
			if TYPE_OF(blk) = TYPE_BLOCK [
				part: block/mold blk buffer no all? flat? arg part indent
			]
		][
			string/concatenate-literal buffer "]"
			part: part - 1
		]
		part
	]

	compare: func [
		arg1	[red-op!]								;-- first operand
		arg2	[red-op!]								;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			type  [integer!]
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "op/compare"]]

		type: TYPE_OF(arg2)
		if type <> TYPE_OP [RETURN_COMPARE_OTHER]
		switch op [
			COMP_EQUAL
			COMP_SAME
			COMP_STRICT_EQUAL
			COMP_FIND
			COMP_NOT_EQUAL
			COMP_SORT
			COMP_CASE_SORT [
				res: SIGN_COMPARE_RESULT(arg1/code arg2/code)
			]
			default [
				res: -2
			]
		]
		res
	]

	init: does [
		datatype/register [
			TYPE_OP
			TYPE_NATIVE
			"op!"
			;-- General actions --
			:make
			null			;random
			INHERIT_ACTION	;reflect
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