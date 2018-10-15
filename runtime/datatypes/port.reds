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
	
	#enum port-field! [
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
	
	do-action: func [
		action	[red-word!]
		args	[integer!]
		return:	[red-value!]
		/local
			port   [red-value!]
			actors [red-object!]
			actor  [red-function!]
	][
		port: stack/arguments
		actors: get-actors as red-object! port action
		actor: get-actor actors action
		stack/mark-func action actors/ctx
		stack/push port
		if args > 1 [stack/push port + 1]
		call-function actor actors/ctx
	]
	
	do-action-port: func [
		action	[red-word!]
		port	[red-object!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		actors: get-actors port action
		actor: get-actor actors action
		stack/mark-func action actors/ctx
		stack/push as red-value! port
		call-function actor actors/ctx
	]

	;-- actions --
	
	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-object!]
		/local
			new	   [red-object!]
			parts  [red-object!]
			state  [red-object!]
			base   [red-value!]
			scheme [red-word!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/make"]]

		either TYPE_OF(spec) = TYPE_OBJECT [
			parts: as red-object! copy-cell spec stack/push*
		][
			new: as red-object! stack/push*
			object/copy
				as red-object! #get system/standard/url-parts
				as red-object! new
				null
				no
				null

			new/class:  0
			new/on-set: null
			parts: object/make new spec type
		]
		scheme: as red-word! object/get-values parts 0	;-- `scheme` field
		if TYPE_OF(scheme) <> TYPE_WORD [fire [TO_ERROR(access no-scheme) spec]]

		new: as red-object! stack/push*
		object/copy
			as red-object! #get system/standard/port
			as red-object! new
			null
			no
			null

		new/header: TYPE_PORT							;-- implicit reset of all header flags
		new/class:  OBJ_CLASS_PORT!
		
		base: object/get-values new
		copy-cell as red-value! parts  base + field-spec
		copy-cell as red-value! scheme base + field-scheme
		object/copy
			as red-object! #get system/standard/port-state
			as red-object! base + field-state
			null
			no
			null
		
		new
	]

	form: func [
		port	[red-object!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/form"]]

		mold port buffer no no no arg part 0
	]

	mold: func [
		port	[red-object!]
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
		part: object/serialize port buffer only? all? flat? arg part - 12 yes indent + 1 yes
		if indent > 0 [part: object/do-indent buffer indent part]
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 1
	]
	
	at: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "port/at"]]
		do-action words/_at 2
	]
	
	pick: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "port/pick"]]
		do-action words/_pick 2
	]
	
	skip: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "port/skip"]]
		do-action words/_skip 2
	]
	
	back: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "port/back"]]
		do-action words/_back 1
	]
	
	clear: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "port/clear"]]
		do-action words/_clear 1
	]

	head: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "port/head"]]
		do-action words/_head 1
	]
	
	head?: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "port/head?"]]
		do-action words/_head? 1
	]
	
	index?: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "port/index?"]]
		do-action words/_index? 1
	]
	
	length?: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "port/length?"]]
		do-action words/_length? 1
	]
	
	next: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "port/next"]]
		do-action words/_next 1
	]
	
	tail: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "port/tail"]]
		do-action words/_tail 1
	]
	
	tail?: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "port/tail?"]]
		do-action words/_tail? 1
	]
	
	change: func [
		port	[red-object!]
		value	[red-value!]
		part	[red-value!]
		only?	[logic!]
		dup		[red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/change"]]
			
		actors: get-actors as red-object! port words/_change
		actor: get-actor actors words/_change
		stack/mark-func words/_change actors/ctx
		stack/push as red-value! port
		stack/push value
		logic/push OPTION?(part)
		either OPTION?(part) [stack/push part][none/push]
		logic/push only?
		logic/push OPTION?(dup)
		either OPTION?(dup) [stack/push dup][none/push]
		call-function actor actors/ctx
	]
	
	find: func [
		port	[red-object!]
		value	[red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		same?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		tail?	 [logic!]
		match?	 [logic!]
		return:  [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/find"]]
			
		actors: get-actors as red-object! port words/_find
		actor: get-actor actors words/_find
		stack/mark-func words/_find actors/ctx
		stack/push as red-value! port
		stack/push value
		logic/push OPTION?(part)
		either OPTION?(part) [stack/push part][none/push]
		logic/push only?
		logic/push case?
		logic/push same?
		logic/push any?
		logic/push OPTION?(with-arg)
		either OPTION?(with-arg) [stack/push as red-value! with-arg][none/push]
		logic/push OPTION?(skip)
		either OPTION?(skip) [stack/push as red-value! skip][none/push]
		logic/push last?
		logic/push reverse?
		logic/push tail?
		logic/push match?
		call-function actor actors/ctx
	]
	
	insert: func [
		port	[red-object!]
		value	[red-value!]
		part	[red-value!]
		only?	[logic!]
		dup		[red-value!]
		append? [logic!]
		return:	[red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/insert"]]
			
		actors: get-actors as red-object! port words/_insert
		actor: get-actor actors words/_insert
		stack/mark-func words/_insert actors/ctx
		stack/push as red-value! port
		stack/push value
		logic/push OPTION?(part)
		either OPTION?(part) [stack/push part][none/push]
		logic/push only?
		logic/push OPTION?(dup)
		either OPTION?(dup) [stack/push dup][none/push]
		logic/push append?
		call-function actor actors/ctx
	]
	
	move: func [
		port	[red-object!]
		target	[red-value!]
		part	[red-integer!]
		return:	[red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/move"]]
			
		actors: get-actors as red-object! port words/_move
		actor: get-actor actors words/_move
		stack/mark-func words/_move actors/ctx
		stack/push as red-value! port
		stack/push target
		logic/push OPTION?(part)
		either OPTION?(part) [stack/push as red-value! part][none/push]
		call-function actor actors/ctx
	]
	
	copy: func [
		port	[red-object!]
		new		[red-value!]
		part	[red-value!]
		deep?	[logic!]
		types	[red-value!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/copy"]]
			
		actors: get-actors as red-object! port words/_copy
		actor: get-actor actors words/_copy
		stack/mark-func words/_copy actors/ctx
		stack/push as red-value! port
		logic/push OPTION?(part)
		either OPTION?(part) [stack/push part][none/push]
		logic/push deep?
		logic/push OPTION?(types)
		either OPTION?(types) [stack/push types][none/push]
		call-function actor actors/ctx
		copy-cell stack/arguments new
	]
	
	create: func [
		port	[red-object!]
		return: [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/create"]]
		do-action-port words/_create port
	]
	
	close: func [
		port	[red-object!]
		return: [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/close"]]
		do-action-port words/_close port
	]
	
	delete: func [
		port	[red-object!]
		return: [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/delete"]]
		do-action-port words/_delete port
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
	
	poke: func [
		port	[red-object!]
		index	[integer!]
		data	[red-value!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/poke"]]
		
		actors: get-actors port words/_poke
		actor: get-actor actors words/_poke
		stack/mark-func words/_poke actors/ctx
		stack/push as red-value! port
		stack/push boxed
		stack/push data
		call-function actor actors/ctx
	]
	
	put: func [
		port	[red-object!]
		key		[red-value!]
		value	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/put"]]

		actors: get-actors port words/_put
		actor: get-actor actors words/_put
		stack/mark-func words/_put actors/ctx
		stack/push as red-value! port
		stack/push key
		stack/push value
		logic/push case?
		call-function actor actors/ctx
	]
	
	query: func [
		port	[red-object!]
		return: [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/query"]]
		do-action-port words/_query port
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

		create port
		open port no no no OPTION?(seek) none-value
		;res: copy
		close port
		;res
		as red-value! none-value
	]
	
	remove: func [
		port	[red-object!]
		part	[red-value!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/remove"]]
			
		actors: get-actors as red-object! port words/_remove
		actor: get-actor actors words/_remove
		stack/mark-func words/_remove actors/ctx
		stack/push as red-value! port
		logic/push OPTION?(part)
		either OPTION?(part) [stack/push part][none/push]
		call-function actor actors/ctx
	]
	
	reverse: func [
		port	[red-object!]
		part	[red-value!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/reverse"]]

		actors: get-actors as red-object! port words/_reverse
		actor: get-actor actors words/_reverse
		stack/mark-func words/_reverse actors/ctx
		stack/push as red-value! port
		logic/push OPTION?(part)
		either OPTION?(part) [stack/push part][none/push]
		call-function actor actors/ctx
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

	select: func [
		port	 [red-object!]
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
		return:  [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/select"]]

		actors: get-actors as red-object! port words/_select
		actor: get-actor actors words/_select
		stack/mark-func words/_select actors/ctx
		stack/push as red-value! port
		stack/push value
		logic/push OPTION?(part)
		either OPTION?(part) [stack/push part][none/push]
		logic/push only?
		logic/push case?
		logic/push same?
		logic/push any?
		logic/push OPTION?(with-arg)
		either OPTION?(with-arg) [stack/push as red-value! with-arg][none/push]
		logic/push OPTION?(skip)
		either OPTION?(skip) [stack/push as red-value! skip][none/push]
		logic/push last?
		logic/push reverse?
		call-function actor actors/ctx
	]
	
	sort: func [
		port	[red-object!]
		case?    [logic!]
		skip	 [red-integer!]
		compare	 [red-function!]
		part	 [red-value!]
		all?	 [logic!]
		reverse? [logic!]
		stable?  [logic!]
		return:  [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/sort"]]
		
		actors: get-actors as red-object! port words/_sort
		actor: get-actor actors words/_sort
		stack/mark-func words/_sort actors/ctx
		stack/push as red-value! port
		logic/push case?
		logic/push OPTION?(skip)
		either OPTION?(skip) [stack/push as red-value! skip][none/push]
		logic/push OPTION?(compare)
		either OPTION?(compare) [stack/push as red-value! compare][none/push]
		logic/push OPTION?(part)
		either OPTION?(part) [stack/push part][none/push]
		logic/push all?
		logic/push reverse?
		logic/push stable?
		call-function actor actors/ctx
	]
	
	swap: func [
		port	[red-object!]
		series2	[red-value!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/swap"]]
		
		actors: get-actors as red-object! port words/_sort
		actor: get-actor actors words/_sort
		stack/mark-func words/_sort actors/ctx
		stack/push as red-value! port
		stack/push series2
		call-function actor actors/ctx
	]
	
	take: func [
		port	[red-object!]
		part	[red-value!]
		deep?	[logic!]
		last?	[logic!]
		return: [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/take"]]
		
		actors: get-actors as red-object! port words/_take
		actor: get-actor actors words/_take
		stack/mark-func words/_take actors/ctx
		stack/push as red-value! port
		logic/push OPTION?(part)
		either OPTION?(part) [stack/push part][none/push]
		logic/push deep?
		logic/push last?
		call-function actor actors/ctx
	]
	
	trim: func [
		port	 [red-object!]
		head?	 [logic!]
		tail?	 [logic!]
		auto?	 [logic!]
		lines?	 [logic!]
		all?	 [logic!]
		with-arg [red-value!]
		return:  [red-value!]
		/local
			actors [red-object!]
			actor  [red-function!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/trim"]]

		actors: get-actors as red-object! port words/_trim
		actor: get-actor actors words/_trim
		stack/mark-func words/_trim actors/ctx
		stack/push as red-value! port
		logic/push head?
		logic/push tail?
		logic/push auto?
		logic/push lines?
		logic/push all?
		logic/push OPTION?(with-arg)
		either OPTION?(with-arg) [stack/push with-arg][none/push]
		call-function actor actors/ctx
	]
	
	update: func [
		port	[red-object!]
		return: [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "port/update"]]
		do-action-port words/_update port
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
			:at
			:back
			:change
			:clear
			:copy
			:find
			:head
			:head?
			:index?
			:insert
			:length?
			:move
			:next
			:pick
			:poke
			:put
			:remove
			:reverse
			:select
			:sort
			:skip
			:swap
			:tail
			:tail?
			:take
			:trim
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