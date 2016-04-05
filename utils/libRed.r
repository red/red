REBOL [
	Title:   "Information extractor from Red runtime source code"
	Author:  "Nenad Rakocevic"
	File: 	 %libRed.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Notes: {
		These utility functions extract types ID and function definitions from Red
		runtime source code and make it available to the compiler, before the Red runtime
		is actually compiled.
		
		This procedure is required during bootstrapping, as the REBOL compiler can't
		examine loaded Red data in memory at runtime.
	}
]

context [

	funcs: [
		copy-cell
		get-root
		get-root-node
		type-check-alt
		type-check
		set-int-path*
		eval-int-path*
		set-path*
		eval-path*
		eval-int-path
		eval-path
			
		stack/mark
		stack/unwind
		stack/unwind-last
		stack/reset
		stack/push
		stack/check-call
		stack/unroll
		stack/revert
		stack/adjust-post-try
		
		interpreter/eval-path
		
		none/push-last
		
		logic/false?
		logic/true?
		
		;*/push-local
		refinement/push-local
		lit-word/push-local
		
		
		*/push
		
		block/push-only*
		block/insert-thru
		block/append-thru
		
		percent/push64
		float/push64
		
		word/get
		word/get-local
		word/get-any
		word/get-in
		word/set-in
		word/replace
		word/from
		
		get-word/get
		
		_context/get
		_context/clone
		_context/set-integer
		
		object/duplicate
		object/transfer
		object/init-push
		object/init-events
		object/loc-fire-on-set*
		object/fire-on-set*
		
		integer/get-any*
		integer/get*
		integer/get
		logic/get
		float/get
		
		integer/box
		logic/box
		float/box
		
		_function/init-locals
		;_function/push
		;routine/push
		
		object/unchanged?
		object/unchanged2?
		
		natives/repeat-init*
		natives/repeat-set
		natives/foreach-next-block
		natives/foreach-next
		natives/forall-loop
		natives/forall-next
		natives/forall-end
		
		actions/*
		natives/*
	]
	
	vars: funcs: [
		stack/arguments
		stack/top
	]
	
	exports: make block! 300
	imports: make block! 100
	

]