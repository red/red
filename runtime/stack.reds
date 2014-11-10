Red/System [
	Title:   "Red execution stack functions"
	Author:  "Nenad Rakocevic"
	File: 	 %stack.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

stack: context [										;-- call stack
	verbose: 0
	
	dyn-info!: alias struct! [
		header [integer!]
		code   [integer!]
		count  [integer!]
		locals [integer!]
	]
	
	arg-stk:		declare red-block!					;-- argument stack (should never be relocated)
	call-stk:		declare red-block!					;-- call stack (should never be relocated)
	args-series:	declare series!
	calls-series:	declare series!
	a-end: 			declare red-value!
	c-end: 			declare int-ptr!
	arguments:		declare red-value!
	bottom:  		declare red-value!
	top:	 		declare red-value!
	cbottom: 		declare int-ptr!
	ctop:	 		declare int-ptr!
	
	acc-mode?: no										;-- YES: accumulate expressions on stack
	
	#define MARK_STACK(type) [
		func [
			fun [red-word!]
		][
			#if debug? = yes [if verbose > 0 [print-line "stack/mark"]]

			if ctop = c-end [
				print-line ["^/*** Error: call stack overflow!^/"]
				halt
			]
			ctop/1: type or (fun/symbol << 8)
			ctop/2: as-integer arguments
			arguments: top								;-- top of stack becomes frame base
			ctop: ctop + 2

			#if debug? = yes [if verbose > 1 [dump]]
		]
	]
	
	#define STACK_SET_FRAME [
		either ctop = cbottom [
			arguments: bottom
			top: bottom
		][
			top: arguments + 1							;-- keep last value on stack
			arguments: as red-value! ctop/2
		]
	]
	
	;-- header flags
	#enum flags! [
		FLAG_FUNCTION:	80000000h						;-- function! call
		FLAG_NATIVE:	40000000h						;-- native! or action! call
		FLAG_ROUTINE:	20000000h						;--	<reserved>
		FLAG_TRY:		10000000h						;--	TRY native
		FLAG_CATCH:		08000000h						;-- CATCH native
		FLAG_THROW_ATR:	04000000h						;-- Throw function attribut
		FLAG_CATCH_ATR:	02000000h						;--	Catch function attribut
		FLAG_EVAL:		01000000h						;-- Interpreter root frame
		FLAG_DYN_CALL:	11000000h						;-- Dynamic call (alternative stack mode)
	]
	
	init: does [
		arg-stk:  block/make-in root 1024
		call-stk: block/make-in root 512

		set-flag arg-stk/node flag-series-fixed or flag-series-nogc
		set-flag call-stk/node flag-series-fixed or flag-series-nogc

		;-- Shortcuts for stack buffers simpler and faster access
		;-- (stack buffers are not resizable with such approach
		;-- this can be made more flexible (but slower) if necessary
		;-- in the future)

		args-series:  GET_BUFFER(arg-stk)
		calls-series: GET_BUFFER(call-stk)

		a-end: as cell!    (as byte-ptr! args-series)  + args-series/size
		c-end: as int-ptr! (as byte-ptr! calls-series) + calls-series/size

		arguments:	args-series/tail
		bottom:  	args-series/offset
		top:	 	args-series/tail
		cbottom: 	as int-ptr! calls-series/offset
		ctop:	 	as int-ptr! calls-series/tail
	]
	
	check-call: does [
		if acc-mode? [check-dyn-call]
	]

	reset: func [
		return:  [cell!]
		/local
			s	 [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/reset"]]
		
		either acc-mode? [check-dyn-call][top: arguments]
		arguments
	]
	
	keep: func [
		return:  [cell!]
		/local
			s	 [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/keep"]]
		
		top: arguments + 1								;-- keep last value in arguments slot
		if acc-mode? [check-dyn-call]
		arguments
	]
	
	mark-native: MARK_STACK(FLAG_NATIVE)
	mark-func:	 MARK_STACK(FLAG_FUNCTION)
	mark-try:	 MARK_STACK(FLAG_TRY)
	mark-catch:	 MARK_STACK(FLAG_CATCH)
	mark-eval:	 MARK_STACK(FLAG_EVAL)
	mark-dyn:	 MARK_STACK(FLAG_DYN_CALL)
	
	revert: does [
		#if debug? = yes [if verbose > 0 [print-line "stack/revert"]]

		assert cbottom < ctop
		ctop: ctop - 2
		either ctop = cbottom [
			arguments: bottom
			top: bottom
		][
			top: arguments
			arguments: as red-value! ctop/2
		]
		
		#if debug? = yes [if verbose > 1 [dump]]
	]
	
	unwind-part: does [
		#if debug? = yes [if verbose > 0 [print-line "stack/unwind-part"]]

		assert cbottom < ctop
		ctop: ctop - 2
		either ctop = cbottom [
			arguments: bottom
		][
			arguments: as red-value! ctop/2
		]
		top: top - 1

		#if debug? = yes [if verbose > 1 [dump]]
	]
		
	unwind: does [
		#if debug? = yes [if verbose > 0 [print-line "stack/unwind"]]

		assert cbottom < ctop
		ctop: ctop - 2
		STACK_SET_FRAME
		if acc-mode? [check-dyn-call]
		
		#if debug? = yes [if verbose > 1 [dump]]
	]
	
	unwind-last: func [
		return:  [red-value!]
		/local
			last [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/unwind-last"]]

		last: arguments
		unwind
		copy-cell last arguments
	]

	unroll: func [
		flags	 [integer!]
		/local
			last [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/unroll"]]

		last: arguments
		assert cbottom < ctop
		until [
			ctop: ctop - 2
			any [
				flags and ctop/1 = flags
				ctop <= cbottom
			]
		]
		
		STACK_SET_FRAME
		ctop: ctop + 2									;-- ctop points past the current call frame
		copy-cell last as red-value! ctop/2
	]
	
	eval?: func [
		return: [logic!]
		/local
			cframe [int-ptr!]
	][
		cframe: ctop
		until [
			cframe: cframe - 2
			if FLAG_EVAL and cframe/1 = FLAG_EVAL [return yes]
			cframe <= cbottom
		]
		no
	]
	
	set-last: func [
		last	[red-value!]
		return: [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/set-last"]]
		
		copy-cell last arguments
	]
	
	push*: func [
		return:  [red-value!]
		/local
			cell [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/push*"]]

		cell: top
		top: top + 1
		if top >= a-end [
			print-line ["^/*** Error: arguments stack overflow!^/"]
			halt
		]
		cell
	]
	
	push: func [
		value 	  [red-value!]
		return:   [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/push"]]
		
		copy-cell value top
		push*
	]
	
	pop: func [
		positions [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/pop"]]
		
		top: top - positions
	]
	
	top-type?: func [
		return:  [integer!]
		/local
			value [red-value!]
	][
		value: top - 1
		TYPE_OF(value)
	]
	
	func?: func [
		return: [logic!]
		/local
			value [red-value!]
			type  [integer!]
	][
		value: top - 1
		type: TYPE_OF(value)
		any [											;@@ replace with ANY_FUNCTION?
			type = TYPE_FUNCTION
			type = TYPE_ROUTINE
		]
	]
	
	defer-call: func [
		name   [red-word!]
		code   [integer!]
		count  [integer!]
		octx [node!]
		/local
			info [dyn-info!]
	][
		;mark-native words/_anon
		integer/push as-integer octx					;-- store optional wrapping object pointer
		
		info: as dyn-info! push*
		info/header: TYPE_POINT
		info/code:   code								;-- store wrapping function pointer
		info/count:  count								;-- store caller's arity
		info/locals: -2									;-- store caller's locals count
		
		mark-dyn name									;-- open new frame
		acc-mode?: yes
		arguments/header: TYPE_VALUE					;-- use TYPE_VALUE to signal "no argument"
	]
	
	push-call: func [
		path [red-path!]
		idx  [integer!]
		code [integer!]
		octx [node!]
		/local
			fun		 [red-function!]
			p		 [red-path!]
			info	 [dyn-info!]
			counters [integer!]
	][
		;mark-native words/_anon
		fun: as red-function! top - 1
		
		assert any [
			TYPE_OF(fun) = TYPE_FUNCTION
			TYPE_OF(fun) = TYPE_ROUTINE
		]
		counters: _function/calc-arity path fun idx
		p: as red-path! copy-cell as red-value! path push*
		p/head: idx										;-- store path with function's index
		
		integer/push as-integer octx					;-- store optional wrapping object pointer
		
		info: as dyn-info! push*
		info/header: TYPE_POINT
		info/code:   code								;-- store wrapping function pointer
		info/count:  counters and FFFFh					;-- store caller's arity
		info/locals: counters >> 16						;-- store caller's locals count
		
		mark-dyn as red-word! block/rs-abs-at as red-block! path idx  ;-- open new frame
		acc-mode?: yes
		
		either zero? (counters and FFFFh) [
			arguments/header: TYPE_UNSET
			check-dyn-call								;-- short path to call with no arguments
		][
			arguments/header: TYPE_VALUE				;-- use TYPE_VALUE to signal "no argument"
		]
	]
	
	check-dyn-call: func [
		/local
			int		   [red-integer!]
			fun		   [red-function!]
			obj		   [red-object!]
			base	   [red-value!]
			info	   [dyn-info!]
			ctx		   [node!]
			octx	   [node!]
			more	   [series!]
			p		   [int-ptr!]
			dyn?	   [logic!]
			new-frame? [logic!]
			code
	][
		p: ctop - 2
		if p < cbottom [exit]
		
		if all [
			FLAG_DYN_CALL and p/1 = FLAG_DYN_CALL
			TYPE_OF(arguments) <> TYPE_VALUE
		][
			info: as dyn-info! arguments - 1
			unless zero? info/count [info/count: info/count - 1]
			
			if zero? info/count [
				base: arguments
				either info/locals = -2 [
					fun: null
					new-frame?: no
				][
					ctx: null
					fun: as red-function! base - 4
					more: as series! fun/more/value
					int: as red-integer! more/offset + 4
					obj: as red-object! base - 5
					case [
						TYPE_OF(obj) = TYPE_OBJECT  [ctx: obj/ctx]
						TYPE_OF(int) = TYPE_INTEGER [ctx: as node! int/value]
					]

					new-frame?: info/locals = -1
					case [
						info/locals > 0 [_function/init-locals info/locals]
						new-frame?		[_function/lay-frame]
						true			[0]					;-- 0 locals case, do nothing
					]
				]
				
				code: as function! [octx [node!]] info/code
				int: as red-integer! base - 2
				octx: as node! int/value
				
				acc-mode?: no							;-- temporary disable accumulative mode
				unless null? fun [_function/call fun ctx] ;-- run the detected function
				unless zero? info/code [code octx]		;-- run wrapper code (stored as function)
				if new-frame? [unwind-last]				;-- close new frame created for handling refinements
				unwind-last								;-- close frame opened in 'push-call
				
				;base: arguments
				;unwind
				;push base
				acc-mode?: yes
				
				p: ctop - 2								;-- decide to keep or not the accumulative mode on
				either p < cbottom [
					acc-mode?: no						;-- bottom of stack reached, switch back to normal
				][
					dyn?: FLAG_DYN_CALL and p/1 = FLAG_DYN_CALL
					either dyn? [check-dyn-call][acc-mode?: no] ;-- if another dyn call pending, keep the mode on
				]
			]
		]
	]

	#if debug? = yes [
		dump: does [									;-- debug purpose only
			print-line "^/---- Argument stack ----"
			dump-memory
				as byte-ptr! bottom
				4
				(as-integer top + 1 - bottom) >> 4
			print-line ["arguments: " arguments]
			print-line ["top: " top]
			
			print-line "^/---- Call stack ----"
			dump-memory
				as byte-ptr! cbottom
				4
				(as-integer ctop + 4 - cbottom) >> 4
			print-line ["ctop: " ctop]
		]
	]
]
