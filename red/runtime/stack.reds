Red/System [
	Title:   "Red execution stack functions"
	Author:  "Nenad Rakocevic"
	File: 	 %stack.reds
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

stack: context [										;-- call stack
	verbose: 0

	frame!: alias struct! [
		header 	[integer!]								;-- cell header
		symbol	[integer!]								;-- index in symbol table
		spec	[node!]									;-- spec block (cleaned-up form)
		prev	[integer!]								;-- index to beginning of previous stack frame
	]

	data: block/make-in root 2048						;-- stack series
	frame-base: 0										;-- root frame has no previous frame
	base: 0
	
	set-flag data/node flag-ins-tail					;-- optimize for tail insertion
	
	reset: func [
		position [integer!]
		return:  [cell!]
		/local
			s	 [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/reset"]]
		
		assert positive? position
		
		s: GET_BUFFER(data)
		s/tail: s/offset + frame-base + position		;-- position is one-based
		s/tail
	]

	mark: func [
		call	[red-word!]
		/local
			frame [frame!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/mark"]]

		frame: as frame! push
		frame/header: TYPE_STACKFRAME
		frame/symbol: either null? call [-1][call/symbol]
		frame/prev: frame-base
		
		s: GET_BUFFER(data)
		frame-base: (as-integer (as cell! frame) - s/offset) >> 4
				#if debug? = yes [
			if verbose > 1 [
				print-line ["frame-base: " frame-base]
				dump
			]
		]
	]
		
	unwind: func [
		/local 
			s	   [series!]
			frame  [frame!]
			offset [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/unwind"]]

		s: GET_BUFFER(data)
		frame: as frame! s/offset + frame-base
		frame-base: frame/prev
		either zero? frame-base [
			s/tail: s/offset + 1
		][
			s/tail: as cell! frame + 1
		]
		copy-cell
			as cell! frame + 1
			as cell! frame
			
		#if debug? = yes [
			if verbose > 1 [
				print [
					"frame-base: " frame-base lf
					"tail: " s/tail lf
				]
				dump
			]
		]
	]
	
	init: does [
		mark null
	]
	
	arguments: func [
		return: [cell!]
		/local
			s 	[series!]
	][
		s: GET_BUFFER(data)
		s/offset + frame-base + 1						;-- +1 for jumping over frame cell
	]

	push-last: func [
		last	[red-value!]
		return: [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/push-last"]]
		
		copy-cell last arguments		
	]
	
	push: func [
		return: [cell!]
	][
		#if debug? = yes [if verbose > 0 [print-line "stack/push"]]
		
		ALLOC_TAIL(data)
	]

	#if debug? = yes [	
		dump: func [										;-- debug purpose only
			/local
				s	[series!]
		][
			s: GET_BUFFER(data)
			dump-memory
				as byte-ptr! s/offset
				4
				(as-integer s/tail + 1 - s/offset) >> 4
			print-line ["frame-base: " frame-base]
			print-line ["tail: " s/tail]
		]
	]
]
