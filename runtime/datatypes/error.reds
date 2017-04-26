Red/System [
	Title:   "Error! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %error.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

error: context [
	verbose: 0
	
	#enum field! [
		field-code
		field-type
		field-id
		field-arg1
		field-arg2
		field-arg3
		field-near
		field-where
		field-stack
	]
	
	set-where: func [
		error [red-object!]
		value [red-value!]
		/local
			base [red-value!]
	][
		base: object/get-values error
		copy-cell value base + field-where
	]
	
	get-type: func [
		err		[red-object!]
		return: [integer!]
		/local
			type [red-word!]
	][
		type: as red-word! (object/get-values err) + field-type
		type/symbol
	]
	
	get-stack-id: func [return: [integer!]][field-stack]
	
	get-call-argument: func [
		idx		[integer!]
		return: [red-word!]
		/local
			cnt   [integer!]
			fun   [red-function!]
			value [red-value!]
			end	  [red-value!]
			s	  [series!]
			type  [integer!]
	][
		fun: as red-function! _context/get stack/get-call
		type: TYPE_OF(fun)
		if all [
			 type <> TYPE_FUNCTION						;@@ replace by ANY_FUNCTION
			 type <> TYPE_ACTION
			 type <> TYPE_NATIVE
			 type <> TYPE_OP
			 type <> TYPE_ROUTINE
		][
			return words/_anon
		]
		s:	   as series! fun/spec/value
		value: s/offset
		end:   s/tail

		cnt: 0
		while [value < end][
			switch TYPE_OF(value) [
				TYPE_WORD
				TYPE_GET_WORD
				TYPE_LIT_WORD
				TYPE_REFINEMENT [
					if cnt = idx [return as red-word! value]
					cnt: cnt + 1
				]
				default [0]
			]
			value: value + 1
		]
		words/_anon										;-- return anonymous name
	]
	
	create: func [
		cat		[red-value!]							;-- expects a word!
		id		[red-value!]							;-- expects a word!
		arg1 	[red-value!]
		arg2 	[red-value!]
		arg3 	[red-value!]
		return: [red-object!]
		/local
			err  [red-object!]
			base [red-value!]
			blk	 [red-block!]
	][
		blk: block/push* 2
		block/rs-append blk cat
		block/rs-append blk id
	
		err:  make null as red-value! blk TYPE_ERROR
		base: object/get-values err
		
		unless null? arg1 [copy-cell arg1 base + field-arg1]
		unless null? arg2 [copy-cell arg2 base + field-arg2]
		unless null? arg3 [copy-cell arg3 base + field-arg3]
		err
	]
	
	reduce: func [
		blk		[red-block!]
		obj		[red-object!]
		return: [red-block!]
		/local
			value  [red-value!]
			tail   [red-value!]
			buffer [red-string!]
			type   [integer!]
	][
		value: block/rs-head blk
		tail:  block/rs-tail blk
		
		while [value < tail][
			type: TYPE_OF(value)
			if any [
				type = TYPE_WORD
				type = TYPE_GET_WORD
			][
				buffer: string/rs-make-at stack/push* 16
				stack/mark-native words/_body
				actions/mold object/rs-select obj value buffer no no yes null 0 0
				stack/unwind
				copy-cell as red-value! buffer value
				stack/pop 1
			]
			value: value + 1
		]
		blk
	]
	
	;-- Actions -- 

	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-object!]
		/local
			new		[red-object!]
			errors	[red-object!]
			base	[red-value!]
			value	[red-value!]
			blk		[red-block!]
			int		[red-integer!]
			sym		[red-word!]
			w		[red-word!]
			cat		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "error/make"]]

		new: as red-object! stack/push*
		
		object/copy
			as red-object! #get system/standard/error
			as red-object! new
			null
			no
			null
		
		new/header: TYPE_ERROR							;-- implicit reset of all header flags
		new/class:  0
		new/on-set: null
		
		base:	object/get-values new
		errors: as red-object! #get system/catalog/errors
		sym:	as red-word! object/get-words errors

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				copy-cell spec base						;-- set 'code field
				int: as red-integer! spec

				cat: int/value / 100
				w: sym + cat
				
				if any [
					int/value <= 0
					(sym + object/get-size errors) <= as red-value! w
				][
					fire [TO_ERROR(script out-of-range) spec]
				]
				w: word/make-at w/symbol base + field-type	;-- set 'type field
				_context/bind-word GET_CTX(errors) w
				
				errors: (as red-object! object/get-values errors) + cat
				sym: as red-word! object/get-words errors
				
				w: sym + (int/value // 100)
				if (sym + object/get-size errors) <= as red-value! w [
					fire [TO_ERROR(script out-of-range) spec]
				]
				w: word/make-at w/symbol base + field-id	;-- set 'id field
				_context/bind-word GET_CTX(errors) w
			]
			TYPE_BLOCK [
				blk: as red-block! spec
				value: block/rs-head blk
				
				switch TYPE_OF(value) [
					TYPE_WORD [
						cat: object/rs-find errors value
						
						if cat = -1 [
							fire [TO_ERROR(script invalid-spec-field) words/_type]
						]
						copy-cell value base + field-type
						
						errors: (as red-object! object/get-values errors) + cat
						value: value + 1
						if value < block/rs-tail blk [
							cat: object/rs-find errors value
							if cat = -1 [
								fire [TO_ERROR(script invalid-spec-field) words/_id]
							]
							copy-cell value base + field-id
						]
					]
					TYPE_SET_WORD [
						value: block/select-word blk words/_type no
						if TYPE_OF(value) = TYPE_NONE [
							fire [TO_ERROR(script missing-spec-field) words/_type]
						]
						value: block/select-word blk words/_id no
						if TYPE_OF(value) = TYPE_NONE [
							fire [TO_ERROR(script missing-spec-field) words/_id]
						]
						_context/bind blk GET_CTX(new) new/ctx yes
						interpreter/eval blk no
					]
					default [
						fire [TO_ERROR(internal invalid-error)]
					]
				]
			]
			TYPE_STRING [
				new: create TO_ERROR(user message) spec null null
			]
			default [
				fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_ERROR spec]
			]
		]
		new
	]
	
	form: func [
		obj		[red-object!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
		/local
			base	[red-value!]
			errors	[red-object!]
			value	[red-value!]
			str		[red-string!]
			blk		[red-block!]
			bool	[red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "error/form"]]
		
		base: object/get-values obj
		string/concatenate-literal buffer "*** "
		part: part - 4
		
		errors: as red-object! #get system/catalog/errors
		errors: as red-object! object/rs-select errors base + field-type
		
		str: as red-string! object/rs-select errors as red-value! words/_type
		assert TYPE_OF(str) = TYPE_STRING
		string/concatenate buffer str -1 0 yes no
		part: part - string/rs-length? str
		string/concatenate-literal buffer ": "
		part: part - 2
		
		value: object/rs-select errors base + field-id
		
		either TYPE_OF(value) = TYPE_STRING [
			str: as red-string! value
			string/concatenate buffer str -1 0 yes no
			part: part - string/rs-length? str
		][
			blk: block/clone as red-block! value no no
			blk: reduce blk obj
			part: block/form blk buffer arg part
		]
		
		string/concatenate-literal buffer "^/*** Where: "
		part: part - 12
		value: base + field-where
		
		either TYPE_OF(value) = TYPE_WORD [
			part: word/form as red-word! value buffer arg part
		][
			string/concatenate-literal buffer "???"
			part: part - 3
		]
		
		bool: as red-logic! #get system/state/trace?
		if all [
			TYPE_OF(bool) = TYPE_LOGIC
			bool/value
		][
			value: base + field-stack
			if TYPE_OF(value) = TYPE_INTEGER [
				string/concatenate-literal buffer "^/*** Stack: "
				part: stack/trace as red-integer! value buffer part - 12
			]
		]
		part
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
		#if debug? = yes [if verbose > 0 [print-line "error/mold"]]

		string/concatenate-literal buffer "make error! ["
		part: object/serialize obj buffer only? all? flat? arg part - 13 yes indent + 1 yes
		if indent > 0 [part: object/do-indent buffer indent part]
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 1
	]

	init: does [
		datatype/register [
			TYPE_ERROR
			TYPE_OBJECT
			"error!"
			;-- General actions --
			:make
			null			;random
			INHERIT_ACTION	;reflect
			null			;to
			:form
			:mold
			INHERIT_ACTION	;eval-path
			null			;set-path
			INHERIT_ACTION	;compare
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
			INHERIT_ACTION	;copy
			INHERIT_ACTION	;find
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
			INHERIT_ACTION	;select
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