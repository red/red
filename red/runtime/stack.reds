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
	
	;-- header flags
	#enum flags! [
		FLAG_FUNCTION:	80000000h						;-- function! call
		FLAG_NATIVE:	40000000h						;-- native! or action! call
		FLAG_ROUTINE:	20000000h						;--	<reserved>
		FLAG_TRY:		10000000h						;--	TRY native
		FLAG_CATCH:		08000000h						;-- CATCH native
		FLAG_THROW_ATR:	04000000h						;-- Throw function attribut
		FLAG_CATCH_ATR:	02000000h						;--	Catch function attribut
	]
	
	arg-stk:  block/make-in root 1024					;-- argument stack (should never be relocated)
	call-stk: block/make-in root 512					;-- call stack (should never be relocated)
	
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
	

	reset: func [
		return:  [cell!]
		/local
			s	 [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/reset"]]
		
		top: arguments									;-- overwrite last value
		arguments
	]
	
	keep: func [
		return:  [cell!]
		/local
			s	 [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/keep"]]
		
		top: arguments + 1								;-- keep last value in arguments slot
		arguments
	]
	
	mark-native: MARK_STACK(FLAG_NATIVE)
	mark-func:	 MARK_STACK(FLAG_FUNCTION)
	mark-try:	 MARK_STACK(FLAG_TRY)
	mark-catch:	 MARK_STACK(FLAG_CATCH)
		
	unwind: does [
		#if debug? = yes [if verbose > 0 [print-line "stack/unwind"]]

		assert cbottom <= ctop
		ctop: ctop - 2
		
		either ctop = cbottom [
			arguments: bottom
			top: bottom
		][
			top: arguments + 1							;-- keep last value on stack
			arguments: as red-value! ctop/2
		]
		
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
		ctop: ctop + 2									;-- ctop points past the current call frame
		copy-cell last as red-value! ctop/2
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
		top: top - positions
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
	]
]
