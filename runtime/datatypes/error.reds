Red/System [
	Title:   "Error! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %error.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
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
			base slot [red-value!]
	][
		base: object/get-values error
		slot: base + field-where
		if TYPE_OF(slot) = TYPE_NONE [copy-cell value slot]	;-- don't overwrite if previously set
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
	
	get-id: func [
		err		[red-object!]
		return: [integer!]
		/local
			id [red-word!]
	][
		id: as red-word! (object/get-values err) + field-id
		id/symbol
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
	
	capture: func [
		err	[red-object!]
		/local
			field [red-integer!]
			blk	  [red-block!]
			int	  [red-integer!]
			level [integer!]
			ptr	  [integer!]
	][
		if TYPE_OF(err) <> TYPE_ERROR [exit]			;-- error! not created yet, give up.
		field: as red-integer! (object/get-values err) + field-stack
		if TYPE_OF(field) = TYPE_INTEGER [
			level: 1
			int: as red-integer! #get system/state/stack-trace
			if all [TYPE_OF(int) = TYPE_INTEGER int/value > 0][level: int/value]
			ptr: field/value
			blk: as red-block! field
			block/make-at blk 20
			stack/trace-in level blk ptr
		]
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
		blk: block/push-only* 2
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
			value   [red-value!]
			tail    [red-value!]
			buffer  [red-string!]
			type    [integer!]
			syntax? [logic!]
	][
		value: block/rs-head blk
		tail:  block/rs-tail blk
		
		syntax?: words/errors/syntax/symbol = get-type obj
		while [value < tail][
			type: TYPE_OF(value)
			if any [
				type = TYPE_WORD
				type = TYPE_GET_WORD
			][
				buffer: string/rs-make-at stack/push* 16
				stack/mark-native words/_body
				either syntax? [
					actions/form object/rs-select obj value buffer null 0
				][
					actions/mold object/rs-select obj value buffer no no yes null 0 0
				]
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
			cat2	[integer!]
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
		new/class:  OBJ_CLASS_ERROR!
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
					int/value < 0
					(sym + object/get-size errors) <= as red-value! w
				][
					fire [TO_ERROR(script out-of-range) spec]
				]
				w: word/make-at w/symbol base + field-type	;-- set 'type field
				_context/bind-word GET_CTX(errors) w
				
				errors: (as red-object! object/get-values errors) + cat
				sym: as red-word! object/get-words errors
				
				w: sym + (int/value // 100 + 2)
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
						if cat = -1 [fire [TO_ERROR(script invalid-spec-field) words/_type]]
						copy-cell value base + field-type
						
						errors: (as red-object! object/get-values errors) + cat
						value: value + 1
						either value < block/rs-tail blk [
							if TYPE_OF(value) <> TYPE_WORD [
								fire [TO_ERROR(script invalid-arg) value]
							]
							cat2: object/rs-find errors value
							if cat2 = -1 [fire [TO_ERROR(script invalid-spec-field) words/_id]]
							copy-cell value base + field-id
						][fire [TO_ERROR(script invalid-spec-field) words/_id]]
					]
					TYPE_SET_WORD [
						_context/bind blk GET_CTX(new) yes
						interpreter/eval blk no

						value: object/rs-select new as red-value! words/_type
						if TYPE_OF(value) <> TYPE_WORD [
							fire [TO_ERROR(script invalid-spec-field) words/_type]
						]
						cat: object/rs-find errors value
						if cat = -1 [fire [TO_ERROR(script invalid-spec-field) words/_type]]

						value: object/rs-select new as red-value! words/_id
						if TYPE_OF(value) <> TYPE_WORD [
							fire [TO_ERROR(script invalid-spec-field) words/_id]
						]
						errors: (as red-object! object/get-values errors) + cat
						cat2: object/rs-find errors value
						if cat2 = -1 [fire [TO_ERROR(script invalid-spec-field) words/_id]]
					]
					default [
						fire [TO_ERROR(internal invalid-error)]
					]
				]
				int: as red-integer! base + field-code
				int/header: TYPE_INTEGER
				int/value: cat * 100 + cat2 - 2
			]
			TYPE_STRING [
				return create TO_ERROR(user message) spec null null
			]
			default [
				fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_ERROR spec]
			]
		]
		copy-cell as red-value! interpreter/near base + field-near
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
			catalog [red-object!]
			value	[red-value!]
			str		[red-string!]
			blk		[red-block!]
			int		[red-integer!]
			arg2	[red-value!]
			print-stack-header make-internal-error [subroutine!]
	][
		#if debug? = yes [if verbose > 0 [print-line "error/form"]]
		
		make-internal-error: [
			copy-cell as red-value! words/errors/internal base + field-type
			copy-cell as red-value! words/errors/invalid-error base + field-id
			errors: as red-object! object/rs-select catalog as red-value! words/errors/internal
			assert TYPE_Of(errors) <> TYPE_NONE
		]
		
		print-stack-header: [
			string/concatenate-literal buffer "^/*** Stack: "
			part: part - 12
		]
		
		base: object/get-values obj
		string/concatenate-literal buffer "*** "
		part: part - 4
		
		catalog: as red-object! #get system/catalog/errors
		errors: as red-object! object/rs-select catalog base + field-type
		if TYPE_Of(errors) = TYPE_NONE [				;-- invalid /type field, overwrite error object
			copy-cell base + field-type base + field-arg1
			make-internal-error
		]
		value: object/rs-select errors base + field-id
		if TYPE_Of(value) = TYPE_NONE [				;-- invalid /id field, overwrite error object
			copy-cell base + field-id base + field-arg1
			make-internal-error
			value: object/rs-select errors base + field-id
			assert TYPE_Of(value) <> TYPE_NONE
		]
		
		str: as red-string! object/rs-select errors as red-value! words/_type ;-- get the error-class banner string
		assert TYPE_OF(str) = TYPE_STRING
		string/concatenate buffer str -1 0 yes no
		part: part - string/rs-length? str
		string/concatenate-literal buffer ": "
		part: part - 2

		if TYPE_OF(value) = TYPE_WORD [
			_context/bind-word GET_CTX(obj) as red-word! value
			value: _context/get-in as red-word! value GET_CTX(obj)
		]
		
		switch TYPE_OF(value) [
			TYPE_STRING [
				str: as red-string! value
				string/concatenate buffer str -1 0 yes no
				part: part - string/rs-length? str
			]
			TYPE_BLOCK [
				blk: block/clone as red-block! value no no
				blk: reduce blk obj
				arg2: as red-value! integer/push 80
				part: block/form blk buffer arg2 80
			]
			default [
				copy-cell base + field-type base + field-arg1
				make-internal-error
			]
		]
		
		string/concatenate-literal buffer "^/*** Where: "
		part: part - 12
		value: base + field-where
		switch TYPE_OF(value) [
			TYPE_WORD [
				part: word/form as red-word! value buffer arg part
			]
			TYPE_STRING [
				str: as red-string! value
				string/concatenate buffer str -1 0 yes no
				part: part - string/rs-length? str
			]
			default [
				string/concatenate-literal buffer "???"
				part: part - 3
			]
		]
		
		string/concatenate-literal buffer "^/*** Near : "
		part: part - 12
		arg2: as red-value! integer/push 40
		part: actions/mold base + field-near buffer yes no yes arg2 40 0
		
		int: as red-integer! #get system/state/stack-trace
		if all [TYPE_OF(int) = TYPE_INTEGER int/value > 0][
			value: base + field-stack
			switch TYPE_OF(value) [
				TYPE_INTEGER [
					print-stack-header
					part: stack/trace int/value as red-integer! value buffer part
				]
				TYPE_BLOCK [
					print-stack-header
					part: actions/form value buffer arg part
				]
				default [0]
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
			w	[red-word!]
	][
		#if debug? = yes [if verbose > 0 [print-line "error/eval-path"]]
		
		w: as red-word! element
		if all [TYPE_OF(w) = TYPE_WORD words/stack = symbol/resolve w/symbol][
			fire [TO_ERROR(script invalid-path-set) path]
		]
		object/eval-path parent element value path gparent p-item index case? get? tail? evt?
	]
	
	compare: func [
		obj1	[red-object!]							;-- first operand
		obj2	[red-object!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return:	[integer!]
		/local
			res [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "error/compare"]]
		
		either TYPE_OF(obj2) = TYPE_ERROR [
			set-type as red-value! obj2 TYPE_OBJECT
			res: object/compare obj1 obj2 op
			set-type as red-value! obj2 TYPE_ERROR
		][
			RETURN_COMPARE_OTHER
		]
		res
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