Red/System [
	Title:   "Red action functions"
	Author:  "Nenad Rakocevic"
	File: 	 %actions.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

actions: context [
	verbose: 0
	
	table: declare int-ptr!
	
	register: func [
		[variadic]
		count	[integer!]
		list	[int-ptr!]
		/local
			offset [integer!]
			index  [integer!]
	][
		offset: 0
		index:  1
		
		until [
			table/index: list/value
			index: index + 1
			list: list + 1
			count: count - 1
			zero? count
		]
		assert index = (ACTIONS_NB + 1)
	]
	
	get-action-ptr-from: func [
		type	[integer!]								;-- datatype ID
		action	[integer!]								;-- action ID
		return: [integer!]								;-- action pointer (datatype-dependent)
		/local
			index [integer!]
	][
		index: type << 8 + action
		index: action-table/index						;-- lookup action function pointer

		if zero? index [
			print-line [
				"^/*** Script error: action " action
				" not defined for type: " type
			]
			halt
		]
		index
	]
	
	;@@ temporary stack-oriented version kept until internal API fully changed
	get-action-ptr*: func [
		action	[integer!]								;-- action ID
		return: [integer!]								;-- action pointer (datatype-dependent)
		/local
			arg  [red-value!]
	][
		arg: stack/arguments
		get-action-ptr-from TYPE_OF(arg) action
	]	

	get-action-ptr: func [
		value	[red-value!]							;-- any-type! value
		action	[integer!]								;-- action ID
		return: [integer!]								;-- action pointer (datatype-dependent)
	][
		get-action-ptr-from TYPE_OF(value) action
	]
	
	get-index-argument: func [
		return:	 [integer!]
		/local
			arg  [red-value!]
			int  [red-integer!]
			char [red-char!]
			bool [red-logic!]
	][
		arg: stack/arguments + 1
		switch TYPE_OF(arg) [
			TYPE_INTEGER [int:  as red-integer! arg int/value]
			TYPE_CHAR 	 [char: as red-char! 	arg char/value]
			TYPE_LOGIC	 [bool: as red-logic! 	arg 2 - as-integer bool/value]
			default		 [0]
		]
	]


	;--- Actions polymorphic calls ---

	make*: func [
		return:	 [red-value!]
	][
		stack/set-last make stack/arguments stack/arguments + 1
	]

	make: func [
		proto 	 [red-value!]
		spec	 [red-value!]
		return:	 [red-value!]
		/local
			dt	 [red-datatype!]
			int  [red-integer!]
			type [integer!]
			action-make
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/make"]]
		
		type: TYPE_OF(proto)
		if type = TYPE_DATATYPE [
			dt: as red-datatype! proto
			type: dt/value
		]

		action-make: as function! [
			proto 	 [red-value!]
			spec	 [red-value!]
			return:	 [red-value!]						;-- newly created value
		] get-action-ptr-from type ACT_MAKE
		
		action-make proto spec
	]

	random*: func [
		seed	[integer!]
		secure	[integer!]
		only	[integer!]
		return:	[red-value!]
	][
		random
			as red-value! stack/arguments
			as logic! seed + 1
			as logic! secure + 1
			as logic! only + 1
	]

	random: func [
		value   [red-value!]
		seed?	[logic!]
		secure? [logic!]
		only?	[logic!]
		return: [red-value!]
		/local
			action-random
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/random"]]

		action-random: as function! [
			value	[red-value!]
			seed?	[logic!]
			secure? [logic!]
			only?	[logic!]
			return: [red-value!]
		] get-action-ptr value ACT_RANDOM

		action-random value seed? secure? only?
	]

	reflect*: func [
		return: [red-block!]
	][
		reflect stack/arguments as red-word! stack/arguments + 1
	]
	
	reflect: func [
		value	[red-value!]
		field	[red-word!]
		return: [red-block!]
		/local
			action-reflect
	][
		action-reflect: as function! [
			value	[red-value!]
			field	[integer!]
			return:	[red-block!]
		] get-action-ptr-from TYPE_OF(value) ACT_REFLECT
			
		action-reflect value field/symbol
	]
	
	to*: func [
	][
		to stack/arguments stack/arguments + 1
	]

	to: func [
		type       [red-value!]
		spec       [red-value!]
		/local
			result    [cell!]
			red-type  [red-datatype!]
			trg-type  [integer!]
			src-type  [integer!]
			bin       [red-binary!]
			bin2      [red-binary!]
			str       [red-string!]
			str2      [red-string!]
			int       [red-integer!]
			p         [byte-ptr!]
			p2        [byte-ptr!]
			tail      [byte-ptr!]
			s         [series!]
			len       [integer!]
			unit      [integer!]
	][
		trg-type: TYPE_OF(type)
		src-type: TYPE_OF(spec)
		if trg-type = TYPE_DATATYPE [
			red-type: as red-datatype! type
			trg-type: red-type/value
		]

		result: as cell! type

		switch trg-type [
			TYPE_STRING [
				switch src-type [
					TYPE_BINARY [
						bin: as red-binary! spec
						len: binary/get-length bin
						str: string/rs-make-at result len
						s: GET_BUFFER(bin)
						unicode/load-utf8-buffer as c-string! s/offset len + 1 GET_BUFFER(str) null
					]
					default [
						str: string/rs-make-at result 16
						actions/form spec str null 0
					]
				]
			]
			TYPE_BINARY [
				switch src-type [
					TYPE_STRING [
						str: as red-string! spec
						len: unicode/get-utf8-length str -1 ;-- -1: no part
						bin: binary/make-at result len
						binary/concatenate-str bin str -1 1 no
					]
					TYPE_INTEGER [
						bin: binary/make-at result 8
						p: (as byte-ptr! spec)
						tail: p + 8
						p: p + 16
						s: GET_BUFFER(bin)
						p2: as byte-ptr! s/tail
						while [p > tail][                  ;@@ I wish to have `loop` in Red/System
							p2/1: p/0
							p2: p2 + 1
							p: p - 1
						]
						s/tail: as cell! p2
					]
					TYPE_CHAR [
						bin: binary/make-at result 1
						int: as red-integer! spec
						binary/append-char GET_BUFFER(bin) int/value
					]
					TYPE_BINARY [
						bin2: as red-binary! spec
						len: binary/get-length bin2
						bin: binary/make-at result len
						binary/concatenate-bin bin bin2 -1 1 no
					]
					default [
						result/header: TYPE_NONE
					]
				]
			]
			TYPE_INTEGER [
				switch src-type [
					TYPE_CHAR
					TYPE_INTEGER [
						int: as red-integer! spec
						result/header: TYPE_INTEGER
						result/data2: int/value
					]
					TYPE_BINARY [
						bin: as red-binary! spec
						s: GET_BUFFER(bin)
						result/header: TYPE_INTEGER
						result/data2: binary/get-byte (as byte-ptr! s/offset) + bin/head
					]
					default [
						result/header: TYPE_NONE
					]
				]
			]
			TYPE_CHAR [
				switch src-type [
					TYPE_CHAR
					TYPE_INTEGER [
						int: as red-integer! spec
						result/header: TYPE_CHAR
						result/data2: int/value
					]
					TYPE_STRING [
						str: as red-string! spec
						s: GET_BUFFER(str)
						unit: GET_UNIT(s)
						p: (as byte-ptr! s/offset) + (str/head << (unit >> 1))
						either p = as byte-ptr! s/tail [
							print-line {** Script error: cannot MAKE/TO char! from: ""}  ;@@ replace by error!
							result/header: TYPE_NONE
						][
							result/header: TYPE_CHAR
							result/data2: string/get-char p unit
						]
					]
					TYPE_BINARY [
						bin: as red-binary! spec
						s: GET_BUFFER(bin)
						p: (as byte-ptr! s/offset) + bin/head
						either p = as byte-ptr! s/tail [
							print-line "** Script error: cannot MAKE/TO char! from: #{}"  ;@@ replace by error!
							result/header: TYPE_NONE
						][
							len: 4
							result/header: TYPE_CHAR
							result/data2: unicode/decode-utf8-char as c-string! p :len
						]
					]
					default [
						result/header: TYPE_NONE
					]
				]
			]
			default [
				result/header: TYPE_NONE
			]
		]

		stack/pop 1 ;removes the spec, result is on stack
		
	]

	form*: func [
		part	   [integer!]
		/local
			arg	   [red-value!]
			buffer [red-string!]
			int    [red-integer!]
			limit  [integer!]
	][
		arg: stack/arguments + part
		
		limit: either part >= 0 [
			int: as red-integer! arg
			int/value
		][0]
		
		stack/keep										;-- keep last value
		buffer: string/rs-make-at stack/push* 16		;@@ /part argument
		limit: form stack/arguments buffer arg limit
		
		if all [part >= 0 negative? limit][
			string/truncate-from-tail GET_BUFFER(buffer) limit
		]
		stack/set-last as red-value! buffer
	]
	
	form: func [
		value   [red-value!]							;-- FORM argument
		buffer  [red-string!]							;-- FORM buffer
		arg		[red-value!]							;-- max bytes count
		part	[integer!]
		return: [integer!]
		/local
			action-form
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/form"]]

		action-form: as function! [
			value	[red-value!]						;-- FORM argument
			buffer	[red-string!]						;-- FORM buffer
			arg		[red-value!]						;-- max bytes count
			part	[integer!]
			return: [integer!]							;-- remaining part count
		] get-action-ptr value ACT_FORM

		action-form value buffer arg part
	]
	
	mold*: func [
		only	[integer!]
		_all	[integer!]
		flat	[integer!]
		part	[integer!]
		/local
			arg	   [red-value!]
			buffer [red-string!]
			int    [red-integer!]
			limit  [integer!]
	][
		arg: stack/arguments + part
		
		limit: either part >= 0 [
			int: as red-integer! arg
			int/value
		][0]

		stack/keep										;-- keep last value
		buffer: string/rs-make-at stack/push* 16		;@@ /part argument
		limit: mold 
			stack/arguments
			buffer
			as logic! only + 1
			as logic! _all + 1
			as logic! flat + 1
			arg
			limit
			0
		
		if all [part >= 0 negative? limit][
			string/truncate-from-tail GET_BUFFER(buffer) limit
		]
		stack/set-last as red-value! buffer
	]
	
	mold: func [
		value    [red-value!]							;-- MOLD argument
		buffer   [red-string!]							;-- MOLD buffer
		only?	 [logic!]
		all?	 [logic!]
		flat?	 [logic!]
		arg		 [red-value!]
		part     [integer!]								;-- max bytes count
		indent	 [integer!]
		return:  [integer!]
		/local
			action-mold
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/mold"]]

		action-mold: as function! [
			value	 [red-value!]						;-- FORM argument
			buffer	 [red-string!]						;-- FORM buffer
			only?	 [logic!]
			all?	 [logic!]
			flat?	 [logic!]
			part-arg [red-value!]		
			part	 [integer!]							;-- max bytes count
			indent	 [integer!]
			return:  [integer!]							;-- remaining part count
		] get-action-ptr value ACT_MOLD

		action-mold value buffer only? all? flat? arg part indent
	]
	
	eval-path: func [
		parent	[red-value!]
		element	[red-value!]
		set?	[logic!]
		return:	[red-value!]
		/local
			value		[red-value!]
			action-path
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/eval-path"]]
				
		action-path: as function! [
			parent	[red-value!]
			element	[red-value!]
			set?	[logic!]
			return:	[red-value!]
		] get-action-ptr parent ACT_EVALPATH
		
		action-path parent element set?
	]
	
	set-path*: func [][]
	
	compare*: func [
		op		[comparison-op!]
		return: [red-logic!]
		/local
			result [red-logic!]
	][
		result: as red-logic! stack/arguments
		result/value: compare stack/arguments stack/arguments + 1 op
		result/header: TYPE_LOGIC
		result
	]	
	
	compare: func [
		value1  [red-value!]
		value2  [red-value!]
		op	    [comparison-op!]
		return: [logic!]
		/local
			action-compare
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/compare"]]
		
		action-compare: as function! [
			value1  [red-value!]						;-- first operand
			value2  [red-value!]						;-- second operand
			op	    [integer!]							;-- type of comparison
			return: [logic!]
		] get-action-ptr value1 ACT_COMPARE
		
		action-compare value1 value2 op
	]
	
	absolute*: func [
		return:	[red-value!]
		/local
			action-absolute
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/absolute"]]

		action-absolute: as function! [
			return:	[red-value!]						;-- absoluted value
		] get-action-ptr* ACT_ABSOLUTE
		action-absolute
	]
	
	add*: func [
		return:	[red-value!]
		/local
			action-add
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/add"]]

		action-add: as function! [
			return:	[red-value!]						;-- addition resulting value
		] get-action-ptr* ACT_ADD
		action-add
	]
	
	divide*: func [
		return:	[red-value!]
		/local
			action-divide
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/divide"]]

		action-divide: as function! [
			return:	[red-value!]						;-- division resulting value
		] get-action-ptr* ACT_DIVIDE
		action-divide
	]
	
	multiply*: func [
		return:	[red-value!]
		/local
			action-multiply
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/multiply"]]

		action-multiply: as function! [
			return:	[red-value!]						;-- multiplication resulting value
		] get-action-ptr* ACT_MULTIPLY
		action-multiply
	]
	
	negate*: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/negate"]]

		negate-action stack/arguments
	]

	negate-action: func [								;-- negate is a Red/System keyword
		value	[red-value!]
		return:	[red-value!]
		/local
			action-negate
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/negate"]]

		action-negate: as function! [
			value	[red-value!]
			return:	[red-value!]						;-- negated value
		] get-action-ptr value ACT_NEGATE
		
		action-negate value
	]

	power*: func [
		return:	[red-value!]
		/local
			action-power
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/power"]]

		action-power: as function! [
			return:	[red-value!]						;-- addition resulting value
		] get-action-ptr* ACT_POWER
		action-power
	]

	remainder*: func [
		return:	  [red-value!]
		/local
			action-remainder
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/remainder"]]

		action-remainder: as function! [
			return:	  [red-value!]
		] get-action-ptr* ACT_REMAINDER
		action-remainder
	]

	round*: func [][]
	
	subtract*: func [
		return:	[red-value!]
		/local
			action-subtract
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/subtract"]]

		action-subtract: as function! [
			return:	[red-value!]						;-- addition resulting value
		] get-action-ptr* ACT_SUBTRACT
		action-subtract
	]
	
	even?*: func [
		return:	[red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/even?"]]
		
		logic/box even? stack/arguments
	]
	
	even?: func [
		value	[red-value!]
		return: [logic!]
		/local
			action-even?
	][
		action-even?: as function! [
			value	[red-value!]
			return: [logic!]							;-- TRUE if value is even.
		] get-action-ptr value ACT_EVEN?
		
		action-even? value
	]
	
	odd?*: func [
		return:	[red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/odd?"]]
		
		logic/box odd? stack/arguments
	]
	
	odd?: func [
		value	[red-value!]
		return: [logic!]
		/local
			action-odd?
	][
		action-odd?: as function! [
			value	[red-value!]
			return: [logic!]							;-- TRUE if value is odd.
		] get-action-ptr value ACT_ODD?
		
		action-odd? value
	]
	
	and~*: func [
		return:	[red-value!]
		/local
			action-and~
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/and~"]]

		action-and~: as function! [
			return:	[red-value!]						;-- division resulting value
		] get-action-ptr* ACT_AND~
		action-and~
	]
	
	complement*: does [
		stack/set-last complement stack/arguments
	]
	
	complement: func [
		value	[red-value!]
		return:	[red-value!]
		/local
			action-complement
	][
		action-complement: as function! [
			value	[red-value!]
			return:	[red-value!]						;-- complemented value
		] get-action-ptr value ACT_COMPLEMENT
		
		action-complement value
	]

	or~*: func [
		return:	[red-value!]
		/local
			action-or~
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/or~"]]

		action-or~: as function! [
			return:	[red-value!]						;-- division resulting value
		] get-action-ptr* ACT_OR~
		action-or~
	]

	xor~*: func [
		return:	[red-value!]
		/local
			action-xor~
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/xor~"]]

		action-xor~: as function! [
			return:	[red-value!]						;-- division resulting value
		] get-action-ptr* ACT_XOR~
		action-xor~
	]

	append*: func [
		part  [integer!]
		only  [integer!]
		dup   [integer!]
	][
		; assert ANY-SERIES?(TYPE_OF(stack/arguments))
		insert
			as red-series! stack/arguments
			stack/arguments + 1
			stack/arguments + part
			as logic! only + 1
			stack/arguments + dup
			yes
	]
	
	at*: func [
		return:	[red-value!]
		/local
			action-at
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/at"]]

		action-at: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_AT
		action-at
	]
	
	back*: func [
		return:	[red-value!]
		/local
			action-back
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/back"]]

		action-back: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_BACK
		action-back
	]
	
	change*: func [][]
	
	clear*: func [
		return:	[red-value!]
		/local
			action-clear
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/clear"]]
		clear stack/arguments
	]
	
	clear: func [
		value	[red-value!]
		return:	[red-value!]
		/local
			action-clear
	][
		action-clear: as function! [
			value	[red-value!]
			return:	[red-value!]						;-- argument series
		] get-action-ptr value ACT_CLEAR
		
		action-clear value
	]
	
	copy*: func [
		part	[integer!]
		deep	[integer!]
		types	[integer!]
		return:	[red-value!]
	][
		stack/set-last copy
			as red-series! stack/arguments
			stack/push*
			stack/arguments + part
			as logic! deep + 1
			stack/arguments + types
	]
	
	copy: func [
		series  [red-series!]
		new		[red-value!]
		part	[red-value!]
		deep?	[logic!]
		types	[red-value!]
		return:	[red-value!]
		/local
			action-copy
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/copy"]]
		
		new/header: series/header
			
		action-copy: as function! [
			series  [red-series!]
			new		[red-value!]
			part	[red-value!]
			deep?	[logic!]
			types	[red-value!]
			return: [red-series!]
		] get-action-ptr as red-value! series ACT_COPY
					
		action-copy series new part deep? types
		new
	]
	
	find*: func [
		part	 [integer!]
		only	 [integer!]
		case-arg [integer!]
		any-arg  [integer!]
		with-arg [integer!]
		skip	 [integer!]
		last	 [integer!]
		reverse	 [integer!]
		tail	 [integer!]
		match	 [integer!]
	][
		; assert ANY-SERIES?(TYPE_OF(stack/arguments))
		stack/set-last find
			as red-series! stack/arguments
			stack/arguments + 1
			stack/arguments + part
			as logic! only + 1
			as logic! case-arg + 1
			as logic! any-arg + 1
			as red-string!  stack/arguments + with-arg
			as red-integer! stack/arguments + skip
			as logic! last + 1
			as logic! reverse + 1
			as logic! tail + 1
			as logic! match + 1
	]
		
	find: func [
		series   [red-series!]
		value    [red-value!]
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
		return:  [red-value!]
		/local
			action-find
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/find"]]
	
		action-find: as function! [
			series   [red-series!]
			value    [red-value!]
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
			return:  [red-value!]
		] get-action-ptr as red-value! series ACT_FIND
			
		action-find series value part only? case? any? with-arg skip last? reverse? tail? match?
	]
	
	head*: func [
		return:	[red-value!]
		/local
			action-head
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/head"]]

		action-head: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_HEAD
		action-head
	]
	
	head?*: func [
		return:	[red-value!]
		/local
			action-head?
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/head?"]]

		action-head?: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_HEAD?
		action-head?
	]
	
	index?*: func [
		return:	[red-value!]
		/local
			action-index?
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/index?"]]

		action-index?: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_INDEX?
		action-index?
	]

	insert*: func [
		part  [integer!]
		only  [integer!]
		dup   [integer!]
	][
		; assert ANY-SERIES?(TYPE_OF(stack/arguments))
		insert
			as red-series! stack/arguments
			stack/arguments + 1
			stack/arguments + part
			as logic! only + 1
			stack/arguments + dup
			no
	]
	
	insert: func [
		series  [red-series!]
		value   [red-value!]
		part	[red-value!]
		only?	[logic!]
		dup		[red-value!]
		append? [logic!]
		return:	[red-value!]
		/local
			action-insert
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/insert"]]

		action-insert: as function! [
			series  [red-series!]
			value   [red-value!]
			part	[red-value!]
			only?	[logic!]
			dup		[red-value!]
			append? [logic!]
			return:	[red-value!]						;-- series after insertion position
		] get-action-ptr as red-value! series ACT_INSERT
		
		action-insert series value part only? dup append?
	]
	
	length?*: func [
		return:	[red-integer!]
		/local
			int	  [red-integer!]
			value [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/length?"]]

		int: as red-integer! stack/arguments
		value: length? stack/arguments					;-- must be set before slot is modified
		either value = -1 [
			none/push-last
		][
			int/value:  value
			int/header: TYPE_INTEGER
		]
		int
	]
	
	length?: func [
		value	[red-value!]
		return: [integer!]
		/local
			action-length?
	][
		action-length?: as function! [
			value	[red-value!]
			return:	[integer!]							;-- length of series
		] get-action-ptr value ACT_LENGTH?
		
		action-length? value
	]
	
	next*: func [
		return:	[red-value!]
		/local
			action-next
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/next"]]

		action-next: as function! [
			return:	[red-value!]						;-- next value from series
		] get-action-ptr* ACT_NEXT
		action-next
	]
	
	pick*: func [
		return:	 [red-value!]
	][
		stack/set-last pick
			as red-series! stack/arguments
			get-index-argument
			stack/arguments + 1
	]
	
	pick: func [
		series	[red-series!]
		index	[integer!]
		boxed	[red-value!]							;-- boxed index value
		return:	[red-value!]
		/local
			action-pick
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/pick"]]

		action-pick: as function! [
			series	[red-series!]
			index	[integer!]
			boxed	[red-value!]						;-- boxed index value
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr as red-value! series ACT_PICK
		
		action-pick series index boxed
	]
	
	poke*: func [
		return:	[red-value!]
	][	
		poke
			as red-series! stack/arguments
			get-index-argument
			stack/arguments + 2
			stack/arguments + 1
		
		stack/set-last stack/arguments
	]


	poke: func [
		series	[red-series!]
		index	[integer!]								;-- unboxed value
		data	[red-value!]
		boxed	[red-value!]							;-- boxed index value
		/local
			action-poke
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/poke"]]

		action-poke: as function! [
			series	[red-series!]
			index	[integer!]
			data	[red-value!]
			boxed	[red-value!]
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr as red-value! series ACT_POKE
		
		action-poke series index data boxed
	]
	
	remove*: func [
		part [integer!]
	][	
		remove
			as red-series! stack/arguments
			stack/arguments + part
	]
	
	remove: func [
		series  [red-series!]
		part	[red-value!]
		return:	[red-value!]
		/local
			action-remove
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/remove"]]
		
		action-remove: as function! [
			series	[red-series!]
			part	[red-value!]
			return:	[red-value!]
		] get-action-ptr as red-value! series ACT_REMOVE
		
		action-remove series part
	]

	reverse*: func [
		part [integer!]
	][
		reverse
			as red-series! stack/arguments
			stack/arguments + part
	]

	reverse: func [
		series  [red-series!]
		part	[red-value!]
		return:	[red-value!]
		/local
			action-reverse
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/reverse"]]

		action-reverse: as function! [
			series	[red-series!]
			part	[red-value!]
			return:	[red-value!]
		] get-action-ptr as red-value! series ACT_REVERSE

		action-reverse series part
	]
	
	select*: func [
		part	 [integer!]
		only	 [integer!]
		case-arg [integer!]
		any-arg  [integer!]
		with-arg [integer!]
		skip	 [integer!]
		last	 [integer!]
		reverse	 [integer!]
	][
		; assert ANY-SERIES?(TYPE_OF(stack/arguments))
		stack/set-last select
			as red-series! stack/arguments
			stack/arguments + 1
			stack/arguments + part
			as logic! only + 1
			as logic! case-arg + 1
			as logic! any-arg + 1
			as red-string!  stack/arguments + with-arg
			as red-integer! stack/arguments + skip
			as logic! last + 1
			as logic! reverse + 1
	]

	select: func [
		series   [red-series!]
		value    [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		return:  [red-value!]
		/local
			action-select
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/select"]]

		action-select: as function! [
			series   [red-series!]
			value    [red-value!]
			part	 [red-value!]
			only?	 [logic!]
			case?	 [logic!]
			any?	 [logic!]
			with-arg [red-string!]
			skip	 [red-integer!]
			last?	 [logic!]
			reverse? [logic!]
			return:  [red-value!]
		] get-action-ptr as red-value! series ACT_SELECT

		action-select series value part only? case? any? with-arg skip last? reverse?
	]
	
	sort*: func [][]
	
	skip*: func [
		return:	[red-value!]
		/local
			action-skip
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/skip"]]

		action-skip: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_SKIP
		action-skip
	]
	
	swap*: func [
		return: [red-series!]
	][
		swap
			as red-series! stack/arguments
			as red-series! stack/arguments + 1
	]

	swap: func [
		series1 [red-series!]
		series2	[red-series!]
		return:	[red-series!]
		/local
			action-swap
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/swap"]]

		action-swap: as function! [
			series1	[red-series!]
			series2	[red-series!]
			return:	[red-series!]
		] get-action-ptr as red-value! series1 ACT_SWAP

		action-swap series1 series2
	]
	
	tail*: func [
		return:	[red-value!]
		/local
			action-tail
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/tail"]]

		action-tail: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_TAIL
		action-tail
	]
	
	tail?*: func [
		return:	[red-value!]
		/local
			action-tail?
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/tail?"]]

		action-tail?: as function! [
			return:	[red-value!]						;-- picked value from series
		] get-action-ptr* ACT_TAIL?
		action-tail?
	]

	take*: func [
		part	[integer!]
		deep	[integer!]
		last	[integer!]
		return:	[red-value!]
	][
		stack/set-last take
			as red-series! stack/arguments
			stack/arguments + part
			as logic! deep + 1
			as logic! last + 1
	]

	take: func [
		series  [red-series!]
		part	[red-value!]
		deep?	[logic!]
		last?	[logic!]
		return:	[red-value!]
		/local
			action-take
	][
		#if debug? = yes [if verbose > 0 [print-line "actions/take"]]

		action-take: as function! [
			series  [red-series!]
			part	[red-value!]
			deep?	[logic!]
			last?	[logic!]
			return: [red-value!]
		] get-action-ptr as red-value! series ACT_TAKE

		action-take series part deep? last?
	]

	trim*: func [][]
	create*: func [][]
	close*: func [][]
	delete*: func [][]
	modify*: func [][]
	open*: func [][]
	open?*: func [][]
	query*: func [][]
	read*: func [][]
	rename*: func [][]
	update*: func [][]
	write*: func [][]
	
	
	init: does [
		table: as int-ptr! allocate ACTIONS_NB * size? integer!
		
		register [
			;-- General actions --
			:make*
			:random*
			:reflect*
			:to*
			:form*
			:mold*
			:eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute*
			:add*
			:divide*
			:multiply*
			:negate*
			:power*
			:remainder*
			null			;round
			:subtract*
			:even?*
			:odd?*
			;-- Bitwise actions --
			:and~*
			:complement*
			:or~*
			:xor~*
			;-- Series actions --
			:append*
			:at*
			:back*
			null			;change
			:clear*
			:copy*
			:find*
			:head*
			:head?*
			:index?*
			:insert*
			:length?*
			:next*
			:pick*
			:poke*
			:remove*
			:reverse*
			:select*
			null			;sort
			:skip*
			:swap*
			:tail*
			:tail?*
			:take*
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