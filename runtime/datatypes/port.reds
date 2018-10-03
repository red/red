Red/System [
	Title:   "Port! datatype runtime functions"
	Author:  "Nenad RAKOCEVIC"
	File: 	 %port.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

port: context [
	verbose: 0
	
	#enum field! [
		field-spec
		field-scheme
		field-actor
		field-awake
		field-state
		field-data
	]
	
	call-function: func [
		actor   [red-function!]
		ctx	    [node!]
		return: [red-value!]
		/local
			count [integer!]
	][
		count: _function/calc-arity null actor 0
		if positive? count [_function/init-locals count]
		_function/call actor ctx
		stack/unwind-last
	]
	
	get-actors: func [
		port	 [red-object!]
		action	 [red-word!]
		return:  [red-object!]
		/local
			actors [red-object!]
	][
		stack/mark-func action null
		#call [select-scheme port]
		actors: as red-object! stack/arguments
		assert TYPE_OF(actors) = TYPE_OBJECT
		stack/unwind
		actors
	]
	
	get-actor: func [
		actors  [red-object!]
		action	[red-word!]
		return: [red-function!]
		/local
			actor [red-function!]
	][
		actor: as red-function! object/rs-select actors as red-value! action
		if TYPE_OF(actor) = TYPE_NONE [fire [TO_ERROR(access no-port-action) action]]
		actor
	]

	;-- actions --
	
	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-object!]
		/local
			new		[red-object!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/make"]]

		new: as red-object! stack/push*

		object/copy
			as red-object! #get system/standard/port
			as red-object! new
			null
			no
			null

		new/class:  0
		new/on-set: null
		
		new: object/make new spec type
		new/header: TYPE_PORT							;-- implicit reset of all header flags
		new/class:  0
		new
	]

	form: func [
		obj		[red-object!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/form"]]

		mold obj buffer no no no arg part 0
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
		#if debug? = yes [if verbose > 0 [print-line "port/mold"]]

		string/concatenate-literal buffer "make port! ["
		part: object/serialize obj buffer only? all? flat? arg part - 12 yes indent + 1 yes
		if indent > 0 [part: object/do-indent buffer indent part]
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 1
	]
	
	create: func [
		spec	[red-value!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/create"]]
		
		actors: get-actors as red-object! spec words/_create
		actor: get-actor actors words/_create
		stack/mark-func words/_create actors/ctx
		stack/push spec
		call-function actor actors/ctx
	]
	
	close: func [
		port	[red-object!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/close"]]

		actors: get-actors port words/_close
		actor: get-actor actors words/_close
		stack/mark-func words/_close actors/ctx
		stack/push as red-value! port
		call-function actor actors/ctx
	]
	
	delete: func [
		port	[red-object!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/delete"]]

		actors: get-actors port words/_delete
		actor: get-actor actors words/_delete
		stack/mark-func words/_delete actors/ctx
		stack/push as red-value! port
		call-function actor actors/ctx
	]
	
	modify: func [
		port	[red-object!]
		field	[red-value!]
		value	[red-value!]
		case?	[logic!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/modify"]]

		actors: get-actors port words/_modify
		actor: get-actor actors words/_modify
		stack/mark-func words/_modify actors/ctx
		stack/push as red-value! port
		stack/push field
		stack/push value
		logic/push case?
		call-function actor actors/ctx
	]
		
	open: func [
		port	[red-object!]
		new?	[logic!]
		read?	[logic!]
		write?	[logic!]
		seek?	[logic!]
		allow	[red-value!]
		return:	[red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/open"]]
		
		actors: get-actors port words/_open
		actor: get-actor actors words/_open
		stack/mark-func words/_open actors/ctx
		stack/push as red-value! port
		logic/push new?
		logic/push read?
		logic/push write?
		logic/push seek?
		stack/push allow
		call-function actor actors/ctx
	]
	
	query: func [
		port	[red-object!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/query"]]

		actors: get-actors port words/_query
		actor: get-actor actors words/_query
		stack/mark-func words/_query actors/ctx
		stack/push as red-value! port
		call-function actor actors/ctx
	]	
			
	read: func [
		port	[red-object!]
		part	[red-value!]
		seek	[red-value!]
		binary? [logic!]
		lines?	[logic!]
		info?	[logic!]
		as-arg	[red-value!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/read"]]

		;TBD
		as red-value! none-value
	]
	
	rename: func [
		from	[red-value!]
		to		[red-value!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/rename"]]

		actors: get-actors as red-object! from words/_rename
		actor: get-actor actors words/_rename
		stack/mark-func words/_rename actors/ctx
		stack/push from
		stack/push to
		call-function actor actors/ctx
	]
	
	update: func [
		port	[red-object!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/update"]]

		actors: get-actors port words/_update
		actor: get-actor actors words/_update
		stack/mark-func words/_update actors/ctx
		stack/push as red-value! port
		call-function actor actors/ctx
	]
	
	write: func [
		port	[red-object!]
		data	[red-value!]
		binary? [logic!]
		lines?	[logic!]
		info?	[logic!]
		append? [logic!]
		part	[red-value!]
		seek	[red-value!]
		allow	[red-value!]
		as-arg	[red-value!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/write"]]

		;TBD
		as red-value! none-value
	]

	init: does [
		datatype/register [
			TYPE_PORT
			TYPE_OBJECT
			"port!"
			;-- General actions --
			:make			;make
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
			:create
			:close
			:delete
			:modify
			:open
			null			;open?
			:query
			:read
			:rename
			:update
			:write
		]
	]
]