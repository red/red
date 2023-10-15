Red/System [
	Title:   "Red execution stack functions"
	Author:  "Nenad Rakocevic"
	File: 	 %stack.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define CALL_STACK_MASK					0F000000h
#define CALL_STACK_FULL_MASK			FF0000FFh
#define CALL_STACK_TYPE?(p flags)		(CALL_STACK_MASK and p/header = flags)
#define NOT_CALL_STACK_TYPE?(p flags)	(CALL_STACK_MASK and p/header <> flags)

stack: context [										;-- call stack
	verbose: 0
	
	call-frame!: alias struct! [
		header [integer!]								;-- symbol ID of the calling function
		prev   [red-value!]								;-- previous frame base
		ctx	   [node!]									;-- context for function's name
		fctx   [node!]
		saved  [node!]
	]
	
	args-series:	as series!		0
	calls-series:	as series!		0
	a-end: 			as red-value!	0
	c-end: 			as call-frame!	0
	arguments:		as red-value!	0
	bottom:  		as red-value!	0
	top:	 		as red-value!	0
	cbottom: 		as call-frame!	0
	ctop:	 		as call-frame! 	0
	
	body-symbol:	0									;-- symbol ID
	anon-symbol:	0									;-- symbol ID
	
	where-ctop:		as call-frame!	0					;-- saved call stack position for "Where:" error field
	
	#define MARK_STACK(type) [
		func [fun [red-word!]][mark fun type]
	]
	
	#define STACK_SET_FRAME [
		either ctop = cbottom [
			arguments: bottom
			top: bottom
		][
			top: arguments + 1							;-- keep last value on stack
			arguments: ctop/prev
		]
	]
	
	;-- header flags
	#enum flags! [
		FLAG_INTERPRET: 80000000h						;-- Called from interpreter
		FLAG_THROW_ATR:	40000000h						;-- Throw function attribute
		FLAG_CATCH_ATR:	20000000h						;--	Catch function attribute
		FLAG_IN_FUNC:	10000000h						;--	Inside of a function body (volatile flag)

		FRAME_FUNCTION:	01000000h						;-- function! call
		FRAME_NATIVE:	02000000h						;-- native! or action! call
		FRAME_ROUTINE:	03000000h						;--	<reserved>
		FRAME_TRY:		04000000h						;--	TRY native
		FRAME_TRY_ALL:	05000000h						;--	TRY native with /ALL
		FRAME_CATCH:	06000000h						;-- CATCH native
		FRAME_EVAL:		87000000h						;-- Interpreter root frame
		FRAME_LOOP:		08000000h						;-- Iterator (for BREAK/CONTINUE support)
		FRAME_DYN_CALL:	09000000h						;-- Dynamic call (alternative stack mode)

		FRAME_INT_FUNC:	81000000h						;-- function! call from interpreter
		FRAME_INT_NAT:	82000000h						;-- native! or action! call from interpreter
		FRAME_IN_CFUNC:	12000000h						;-- Inside a compiled function body
	]
	
	init: does [
		;-- Shortcuts for stack buffers simpler and faster access
		;-- (stack buffers are not resizable with such approach
		;-- this can be made more flexible (but slower) if necessary
		;-- in the future)

		args-series:  GET_BUFFER(arg-stk)
		calls-series: GET_BUFFER(call-stk)

		bottom:  	args-series/offset
		arguments:	bottom
		top:	 	bottom
		cbottom: 	as call-frame! calls-series/offset
		ctop:	 	cbottom

		a-end: as cell!		  (as byte-ptr! bottom)  + args-series/size
		c-end: as call-frame! (as byte-ptr! cbottom) + calls-series/size

		body-symbol: words/_body/symbol
		anon-symbol: words/_anon/symbol
	]
	
	set-ctop: func [ptr [int-ptr!]][ctop: as call-frame! ptr]
	
	mark: func [
		fun  [red-word!]
		type [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/mark"]]

		if ctop >= c-end [
			top: top - 5								;-- make space within the stack for error processing
			if top < bottom [top: bottom]
			fire [TO_ERROR(internal stack-overflow)]
		]
		ctop/header: type or (fun/symbol << 8)
		ctop/prev:	 arguments
		ctop/ctx:	 fun/ctx
		ctop/fctx:	 null
		ctop/saved:  null
		ctop: ctop + 1
		arguments: top								;-- top of stack becomes frame base
		assert top >= bottom
		
		#if debug? = yes [if verbose > 1 [dump]]
	]
	
	mark-func: func [
		fun		 [red-word!]
		ctx-name [node!]
		/local
			ctx	   [red-context!]
			values [node!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/mark-func"]]

		if ctop >= c-end [
			top: top - 5								;-- make space within the stack for error processing
			if top < bottom [top: bottom]
			fire [TO_ERROR(internal stack-overflow)]
		]
		values: either null? ctx-name [null][			;-- null only happens in some libRedRT cases
			ctx: TO_CTX(ctx-name)
			ctx/values
		]

		ctop/header: FRAME_FUNCTION or (fun/symbol << 8)
		ctop/prev:	 arguments
		ctop/ctx:	 fun/ctx
		ctop/fctx:	 ctx-name
		ctop/saved:  values
		ctop: ctop + 1
		arguments: top								;-- top of stack becomes frame base
		assert top >= bottom

		#if debug? = yes [if verbose > 1 [dump]]
	]

	reset: func [
		return:  [cell!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/reset"]]
		
		top: arguments
		assert top >= bottom
		arguments
	]
	
	keep: func [
		return:  [cell!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/keep"]]
		
		top: arguments + 1								;-- keep last value in arguments slot
		arguments
	]
	
	mark-native: 		MARK_STACK(FRAME_NATIVE)
	mark-try:	 		MARK_STACK(FRAME_TRY)
	mark-try-all:		MARK_STACK(FRAME_TRY_ALL)
	mark-catch:	 		MARK_STACK(FRAME_CATCH)
	mark-eval:	 		MARK_STACK(FRAME_EVAL)
	mark-dyn:	 		MARK_STACK(FRAME_DYN_CALL)
	mark-loop:	 		MARK_STACK(FRAME_LOOP)
	mark-interp-native: MARK_STACK(FRAME_INT_NAT)
	mark-interp-func:	MARK_STACK(FRAME_INT_FUNC)
	mark-func-body:		MARK_STACK(FRAME_IN_CFUNC)
	
	set-in-func-flag: func [
		state [logic!]
		/local
			frame [call-frame!]
	][
		frame: ctop - 1
		either state [
			frame/header: frame/header or FLAG_IN_FUNC
		][
			frame/header: frame/header and not FLAG_IN_FUNC
		]
	]
	
	set-interp-flag: func [/local frame [call-frame!]][
		frame: ctop - 1	
		frame/header: frame/header or FLAG_INTERPRET
	]
	
	set-parent-func-flag: func [/local p [call-frame!]][
		p: ctop - 2
		p/header: p/header or FLAG_IN_FUNC
	]
	
	collect-calls: func [
		dst [red-block!]
		/local
			p	  [call-frame!]
			ctx	  [node!]
			sym	  [integer!]
	][
		p: ctop - 1
		until [
			sym: p/header >> 8 and FFFFh
			if all [sym <> body-symbol	sym <> anon-symbol][
				ctx: either null? p/fctx [global-ctx][p/fctx]
				block/rs-append dst as red-value! word/at ctx sym
				integer/make-at ALLOC_TAIL(dst) (as-integer p/prev - stack/bottom) >> 4
			]
			p: p - 1
			p <= cbottom
		]
	]
	
	get-call: func [
		return: [red-word!]
		/local
			p	[call-frame!]
			sym [integer!]
	][
		p: either where-ctop = null [ctop][where-ctop]
		until [
			p: p - 1
			sym: p/header >> 8 and FFFFh
			any [
				all [sym <> body-symbol	sym <> anon-symbol]
				p < cbottom
			]
		]
		where-ctop: null
		either p < cbottom [words/_not-found][word/at p/ctx sym]
	]
	
	update-call: func [
		call [red-value!]
		/local
			w [red-word!]
			p [call-frame!]
	][
		w: as red-word! call
		if TYPE_OF(w) = TYPE_WORD [
			p: either where-ctop = null [ctop][where-ctop]
			assert p > cbottom
			p: p - 1
			p/header: p/header and CALL_STACK_FULL_MASK or (w/symbol << 8)
		]
	]
	
	revert: does [
		#if debug? = yes [if verbose > 0 [print-line "stack/revert"]]

		assert cbottom < ctop
		ctop: ctop - 1
		either ctop = cbottom [
			arguments: bottom
			top: bottom
		][
			top: arguments
			arguments: ctop/prev
		]
		assert top >= bottom
		assert arguments >= bottom
		
		#if debug? = yes [if verbose > 1 [dump]]
	]
	
	unwind-part: does [
		#if debug? = yes [if verbose > 0 [print-line "stack/unwind-part"]]

		assert cbottom < ctop
		ctop: ctop - 1
		either ctop = cbottom [
			arguments: bottom
		][
			arguments: ctop/prev
		]
		top: top - 1
		assert top >= bottom
		assert arguments >= bottom

		#if debug? = yes [if verbose > 1 [dump]]
	]
		
	unwind: does [
		#if debug? = yes [if verbose > 0 [print-line "stack/unwind"]]

		assert cbottom < ctop
		ctop: ctop - 1
		top: arguments + 1
		arguments: ctop/prev
		assert arguments >= bottom
		
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
		assert arguments >= bottom
		copy-cell last arguments
	]
	
	unroll-frames: func [
		flags  [integer!]
		inner? [logic!]									;-- YES: stay in inner frame
		/local
			type [integer!]
			node [node!]
			ctx	 [red-context!]
	][
		assert cbottom < ctop
		until [
			ctop: ctop - 1
			type: CALL_STACK_MASK and ctop/header
			if type = FRAME_FUNCTION [
				node: ctop/fctx
				if node <> null [
					ctx: TO_CTX(node)
					ctx/values: ctop/saved
				]
			]
			any [
				ctop <= cbottom
				type = flags
				type = FRAME_TRY_ALL
			]
		]
		if inner? [ctop: ctop + 1]
		STACK_SET_FRAME
		unless inner? [ctop: ctop + 1]					;-- ctop points past the current call frame
	]

	unroll: func [
		flags	 [integer!]
		/local
			last [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/unroll"]]

		last: arguments
		unroll-frames flags no
		assert ctop/prev >= bottom
		copy-cell last ctop/prev
		arguments: ctop/prev
		top: arguments
	]
	
	unroll-loop: func [inner? [logic!]][
		#if debug? = yes [if verbose > 0 [print-line "stack/unroll-loop"]]
		unroll-frames FRAME_LOOP inner?
	]
	
	adjust: does [
		top: top - 1
		assert top >= bottom
		copy-cell top top - 1
	]
	
	trace-in: func [
		level	[integer!]
		list	[red-block!]							;-- optional call stack storage block
		stk		[integer!]
		/local
			fun	  [red-value!]
			top	  [call-frame!]
			base  [call-frame!]
			sym	  [integer!]
	][
		top: as call-frame! stk
		base: cbottom
		until [
			sym: base/header >> 8 and FFFFh
			if all [sym <> body-symbol sym <> anon-symbol][
				fun: _context/get-any sym base/ctx
				if any [level > 1 TYPE_OF(fun) = TYPE_FUNCTION][
					 word/make-at sym ALLOC_TAIL(list)
				]
			]
			base: base + 1
			base >= top									;-- defensive exit condition
		]
	]
	
	trace: func [
		level	[integer!]
		int		[red-integer!]
		buffer	[red-string!]
		part	[integer!]
		return: [integer!]
		/local
			value [red-value!]
			fun	  [red-value!]
			top	  [call-frame!]
			base  [call-frame!]
			sym	  [integer!]
	][
		top: as call-frame! int/value
		value: stack/push*
		int: as red-integer! value
		int/header: TYPE_INTEGER
		base: cbottom
		
		until [
			sym: base/header >> 8 and FFFFh
			
			if all [sym <> body-symbol sym <> anon-symbol][
				fun: _context/get-any sym base/ctx
				if any [level > 1 TYPE_OF(fun) = TYPE_FUNCTION][
					part: word/form 
						word/make-at sym value
						buffer
						null
						part
					
					if base >= cbottom [
						string/concatenate-literal buffer " "
						part: part - 1
					]
				]
			]
			base: base + 1
			base >= top									;-- defensive exit condition
		]
		part
	]
	
	set-stack: func [
		err [red-object!]
		/local
			base [red-value!]
			int	 [red-integer!]
	][
		base: object/get-values err
		int: as red-integer! base + error/get-stack-id
		if TYPE_OF(int) = TYPE_BLOCK [exit]				;-- call stack already captured
		int/header: TYPE_INTEGER
		int/value:  as-integer ctop
	]
	
	throw-error: func [
		err [red-object!]
		/local
			extra [red-value!]
			all?  [logic!]
	][
		if ctop > cbottom [
			error/set-where err as red-value! get-call
			set-stack err
			extra: top
			unroll-frames FRAME_TRY no

			ctop: ctop - 1
			assert ctop >= cbottom
			top: extra
		]
		if all [
			ctop = cbottom 
			NOT_CALL_STACK_TYPE?(ctop FRAME_TRY)
			NOT_CALL_STACK_TYPE?(ctop FRAME_TRY_ALL)
		][
			set-last as red-value! err
			natives/print* no
			quit -2
		]
		assert top >= bottom
		push as red-value! err
		throw RED_THROWN_ERROR
	]
	
	throw-break: func [
		return? [logic!]
		cont?	[logic!]
		/local
			result	  [red-value!]
			save-top  [red-value!]
			save-ctop [call-frame!]
	][
		assert top >= bottom
		result:	   arguments
		save-top:  top
		save-ctop: ctop
		if ctop > cbottom  [ctop: ctop - 1]
		
		;-- unwind the stack and determine the outcome of a break/continue exception
		until [
			if CALL_STACK_TYPE?(ctop FRAME_TRY_ALL) [
				ctop: save-ctop
				either cont? [fire [TO_ERROR(throw continue)]][fire [TO_ERROR(throw break)]]
			]
			ctop: ctop - 1
			any [
				ctop <= cbottom
				CALL_STACK_TYPE?(ctop FRAME_LOOP)		;-- loop found, we are fine!
			]
		]
		either all [ctop <= cbottom NOT_CALL_STACK_TYPE?(ctop FRAME_LOOP)][
			arguments: result
			top:	   save-top	
			ctop:	   save-ctop
			either cont? [fire [TO_ERROR(throw continue)]][fire [TO_ERROR(throw break)]]
		][
			ctop: ctop + 1
			arguments: ctop/prev
			top: arguments
			assert top >= bottom
			either all [return? not cont?][set-last result][unset/push-last]
			either cont? [
				throw RED_THROWN_CONTINUE
			][
				throw RED_THROWN_BREAK
			]
		]
	]
	
	throw-exit: func [
		return?  [logic!]
		rethrow? [logic!]
		/local
			result	  [red-value!]
			save-top  [red-value!]
			save-ctop [call-frame!]
	][
		assert top >= bottom
		result:	   arguments
		save-top:  top
		save-ctop: ctop
		if all [ctop > cbottom not rethrow?][ctop: ctop - 1]
		
		;-- unwind the stack and determine the outcome of an exit/return exception
		until [
			if CALL_STACK_TYPE?(ctop FRAME_TRY_ALL) [
				ctop: save-ctop
				fire [TO_ERROR(throw return)]
			]
			ctop: ctop - 1
			any [
				ctop <= cbottom
				ctop/header and FLAG_IN_FUNC <> 0		;-- function body, we are fine!
			]
		]
		either all [ctop <= cbottom ctop/header and FLAG_IN_FUNC = 0][
			arguments: result
			top:	   save-top	
			ctop:	   save-ctop
			fire [TO_ERROR(throw return)]
		][
			ctop: ctop + 1
			arguments: ctop/prev
			top: arguments
			assert top >= bottom
			either return? [
				set-last result
				throw RED_THROWN_RETURN
			][
				unset/push-last
				throw RED_THROWN_EXIT
			]
		]
	]
	
	throw-throw: func [
		id [integer!]
		/local
			result	  [red-value!]
			save-top  [red-value!]
			save-ctop [call-frame!]
	][
		assert top >= bottom
		result:	   arguments
		save-top:  top
		save-ctop: ctop
		if ctop > cbottom  [ctop: ctop - 1]
		
		if where-ctop = null [where-ctop: ctop]
		
		;-- unwind the stack and determine the outcome of a throw exception
		until [
			if CALL_STACK_TYPE?(ctop FRAME_TRY_ALL) [
				ctop: save-ctop
				fire [TO_ERROR(throw throw) result]
			]
			ctop: ctop - 1
			any [
				ctop <= cbottom
				CALL_STACK_TYPE?(ctop FRAME_CATCH)		;-- CATCH call found, we are fine!
			]
		]
		either all [ctop <= cbottom NOT_CALL_STACK_TYPE?(ctop FRAME_CATCH)][
			arguments: result
			top:	   save-top	
			ctop:	   save-ctop
			fire [TO_ERROR(throw throw) result]
		][
			ctop: ctop + 1
			arguments: ctop/prev
			top: arguments
			assert top >= bottom
			push result
			push result + 1								;-- get back the NAME argument too
			throw id
		]
	]
	
	adjust-post-try: does [
		if top-type? = TYPE_ERROR [
			assert top - 1 >= bottom
			set-last top - 1
		]
		top: arguments + 1
	]
	
	get-ctop: func [return: [byte-ptr!]][as byte-ptr! ctop - 1]
	
	eval?: func [
		ptr		[byte-ptr!]
		parent? [logic!]
		return: [logic!]
		/local
			cframe [call-frame!]
	][
		cframe: either null? ptr [ctop][(as call-frame! ptr)]
		until [
			cframe: cframe - 1
			if FLAG_INTERPRET and cframe/header = FLAG_INTERPRET [return yes]
			any [parent? cframe <= cbottom]
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
	
	push-last: func [
		value 	  [red-value!]
		return:   [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/push-last"]]

		top: arguments + 1
		copy-cell value arguments
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
			top: top - 5								;-- make space within the stack for error processing
			fire [TO_ERROR(internal stack-overflow)]
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
		if top < bottom [top: bottom]
	]
	
	top-type?: func [
		return:  [integer!]
		/local
			value [red-value!]
	][
		value: top - 1
		assert value >= bottom
		TYPE_OF(value)
	]
	
	get-top: func [return: [red-value!]][
		either top = bottom [top][top - 1]
	]
	
	func?: func [
		return: [logic!]
		/local
			value [red-value!]
			type  [integer!]
	][
		value: top - 1
		assert value >= bottom
		type: TYPE_OF(value)
		any [											;@@ replace with ANY_FUNCTION?
			type = TYPE_FUNCTION
			type = TYPE_ROUTINE
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
				(as-integer ctop + 2 - cbottom) >> 4
			print-line ["ctop: " ctop]
		]
		
		show-frames: func [
			/local
				p	  [call-frame!]
				sym	  [red-symbol!]
				flags lines [integer!]
				lower upper [red-value!]
		][
			p: ctop
			lower: arguments
			upper: top
			
			until [
				sym: symbol/get p/header >> 8 and FFFFh
				flags: p/header and FF000000h
			
				print ["^/-FRAME- : " as-c-string (as series! sym/cache/value) + 1 ", "]
				
				if flags and F0000000h = FLAG_INTERPRET [print "INTERPRET,"]
				if flags and F0000000h = FLAG_THROW_ATR [print "THROW_ATR,"]
				if flags and F0000000h = FLAG_CATCH_ATR [print "CATCH_ATR,"]
				if flags and F0000000h = FLAG_IN_FUNC   [print "IN_FUNC,"]
				if flags and 0F000000h = FRAME_FUNCTION [print "FUNC,"]
				if flags and 0F000000h = FRAME_NATIVE   [print "NATIVE,"]
				if flags and 0F000000h = FRAME_ROUTINE  [print "ROUTINE,"]
				if flags and 0F000000h = FRAME_TRY      [print "TRY,"]
				if flags and 0F000000h = FRAME_TRY_ALL  [print "TRY_ALL,"]
				if flags and 0F000000h = FRAME_CATCH    [print "CATCH,"]
				if flags and FF000000h = FRAME_EVAL     [print "EVAL,"]
				if flags and 0F000000h = FRAME_LOOP     [print "LOOP,"]
				if flags and 0F000000h = FRAME_DYN_CALL [print "DYN_CALL,"]
				if flags and FF000000h = FRAME_INT_FUNC [print "INT_FUNC,"]
				if flags and FF000000h = FRAME_INT_NAT  [print "INT_NAT,"]
				if flags and FF000000h = FRAME_IN_CFUNC [print "IN_CFUNC,"]
				
				print-line [" prev_args: " p/prev]
				lines: (as-integer upper + 1 - lower) >> 4
				if lines > 20 [lines: 20]
				if lines > 0  [dump-memory-raw as byte-ptr! lower 4 lines]
				
				lower: p/prev
				upper: arguments
				p: p - 1
				p < cbottom
			]
			print lf
		]
	]
]
