Red/System [
	Title:   "Error! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %error.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
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
	]
	
	create: func [
		code 	[integer!]
		arg1 	[red-value!]
		arg2 	[red-value!]
		arg3 	[red-value!]
		return: [red-object!]
		/local
			err  [red-object!]
			base [red-value!]	
	][
		err:  make null as red-value! integer/push code
		base: object/get-values err
		
		unless null? arg1 [copy-cell arg1 base + field-arg1]
		unless null? arg2 [copy-cell arg2 base + field-arg2]
		unless null? arg3 [copy-cell arg3 base + field-arg3]
		err
	]
	
	;-- Actions -- 

	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		return:	 [red-object!]
		/local
			new		[red-object!]
			obj		[red-object!]
			series	[red-series!]
			errors	[red-object!]
			base	[red-value!]
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
		
		series: as red-series! spec
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
				
				if (sym + object/get-size errors) <= as red-value! w [
					print-line "*** Error: invalid spec value for MAKE"
					return new
				]
				word/make-at w/symbol base + field-type	;-- set 'type field
				
				errors: (as red-object! object/get-values errors) + cat
				sym: as red-word! object/get-words errors
				
				w: sym + (int/value // 100)
				if (sym + object/get-size errors) <= as red-value! w [
					print-line "*** Error: invalid spec value for MAKE"
					return new
				]
				word/make-at w/symbol base + field-id	;-- set 'id field
			]
			default [
				--NOT_IMPLEMENTED--
			]
		]
		new
	]
	
	form: func [
		value	[red-object!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "error/form"]]
		
		;TBD
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
		part: object/serialize obj buffer only? all? flat? arg part - 13 yes indent + 1
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
			null			;next
			null			;pick
			null			;poke
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