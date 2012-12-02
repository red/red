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

	call!: alias struct! [
		header 	[integer!]								;-- cell header
		symbol	[integer!]								;-- index in symbol table
		spec	[node!]									;-- spec block (cleaned-up form)
		args	[red-value!]							;-- pointer to first argument in args stack
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
	
	a-end: as cell! (as byte-ptr! args-series)  + args-series/size
	c-end: as cell! (as byte-ptr! calls-series) + calls-series/size
	
	arguments:	args-series/tail
	bottom:  	args-series/offset
	top:	 	args-series/tail
	cbottom: 	calls-series/offset
	ctop:	 	calls-series/tail
	

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

	mark: func [
		fun		 [red-word!]
		/local
			call [call!]
			s	 [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/mark"]]

		arguments: top
		
		if ctop = c-end [
			print-line ["^/*** Error: call stack overflow!^/"]
			halt
		]
		call: as call! ctop
		call/header: TYPE_STACK_CALL
		call/symbol: either null? fun [-1][fun/symbol]
		call/args: arguments
		ctop: ctop + 1
		
		#if debug? = yes [if verbose > 1 [dump]]
	]
		
	unwind: func [
		/local 
			s	   [series!]
			call  [call!]
			offset [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/unwind"]]

		assert cbottom <= ctop
		ctop: ctop - 1
		
		either ctop = cbottom [
			arguments: bottom
			top: bottom
		][
			top: arguments + 1
			call: as call! ctop			
			call: call - 1
			arguments: call/args
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
		/local 
			cell [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/push"]]
		
		copy-cell value top
		cell: top
		top: top + 1
		if top >= a-end [
			print-line ["^/*** Error: arguments stack overflow!^/"]
			halt
		]
		cell
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
			(as-integer ctop + 1 - cbottom) >> 4
			
			print-line ["ctop: " ctop]
		]
	]
]
