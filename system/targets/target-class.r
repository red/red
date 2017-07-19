REBOL [
	Title:   "Red/System code emitter base object"
	Author:  "Nenad Rakocevic"
	File: 	 %target-class.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

target-class: context [
	target: little-endian?: struct-align: ptr-size: void-ptr: none ; TBD: document once stabilized
	default-align: stack-width: stack-slot-max:				  	   ; TBD: document once stabilized
	branch-offset-size: locals-offset: none						   ; TBD: document once stabilized
	
	on-global-prolog: 		 none					;-- called at start of global code section
	on-global-epilog: 		 none					;-- called at end of global code section
	on-finalize:	  		 none					;-- called after all sources are compiled
	on-root-level-entry:	 none					;-- called after a root level expression or directive is compiled
	emit-stack-align-prolog: none					;-- align stack on imported function calls
	emit-stack-align-epilog: none					;-- unwind aligned stack
	emit-float-trash-last:	 none					;-- FPU clean-up code after use in expression
	PIC?:					 none					;-- PIC flag set from compilation job options
	
	compiler: 	none								;-- just a short-cut
	width: 		none								;-- current operand width in bytes
	signed?: 	none								;-- TRUE => signed op, FALSE => unsigned op
	last-saved?: no									;-- TRUE => operand saved in another register
	verbose:  	0									;-- logs verbosity level
	
	emit-casting: emit-call-syscall: emit-call-import: ;-- just pre-bind word to avoid contexts issue
	emit-call-native: emit-not: emit-push: emit-pop:
	emit-integer-operation: emit-float-operation: 
	emit-throw:	on-init: emit-alt-last: emit-log-b:
	emit-variable: none
	
	comparison-op: [= <> < > <= >=]
	math-op:	   compose [+ - * / // (to-word "%")]
	mod-rem-op:    compose [// (to-word "%")]
	mod-rem-func:  compose [// mod (to-word "%") rem]
	bitwise-op:	   [and or xor]
	bitshift-op:   [>> << -**]
	
	opp-conditions: [
	;-- condition ------ opposite condition --
		overflow?		 not-overflow?
		not-overflow?	 overflow?			
		=				 <>
		<>				 =
		even?			 odd?
		odd?			 even?
		<				 >=
		>=				 <
		<=				 >
		>				 <=
	]
	
	opposite?: func [cond [word!]][
		first select/skip opp-conditions cond 2
	]
	
	power-of-2?: func [n [integer! char!]][
		if all [
			n: to integer! n
			positive? n
			zero? n - 1 and n
		][
			to integer! log-2 n
		]
	]
	
	stack-encode: func [offset [integer!]][
		either any [								;-- local variables only
			offset < -128
			offset > 127
		][
			to-bin32 offset
		][
			to-bin8 offset
		]
	]
	
	emit: func [bin [binary! char! block!]][
		if verbose >= 4 [print [">>>emitting code:" mold bin]]
		append emitter/code-buf bin
	]
	
	emit-reloc-addr: func [spec [block!]][
		append spec/3 emitter/tail-ptr				;-- save reloc position
		emit void-ptr								;-- emit void addr, reloc later		
		unless empty? emitter/chunks/queue [				
			append/only 							;-- record reloc reference
				second last emitter/chunks/queue
				back tail spec/3					
		]
	]
	
	get-width: func [operand type /local value][
		reduce [
			emitter/size-of? value: case [
				type 	[operand]
				'else 	[			
					value: first compiler/get-type operand
					either value = 'any-pointer! ['pointer!][value]
				]
			]
			value
		]
	]
	
	set-width: func [operand /type /local value][
		value: get-width operand type
		width: value/1
		signed?: emitter/signed? value/2
	]
	
	with-width-of: func [value body [block!] /alt /local old][
		old: width
		set-width compiler/unbox value
		do body
		width: old
		if all [alt object? value][emit-casting value yes]	;-- casting for right operand
	]
	
	implicit-cast: func [arg /local right-width][
		right-width: first get-width arg none
		
		if any [
			all [width = 4 right-width = 1]			;-- detect byte! -> integer! implicit casting
			find [float! float32! float64!] first compiler/get-type arg
		][
			arg: make object! [action: 'type-cast type: [integer!] data: arg]
			emit-casting arg yes					;-- type cast right argument
		]
	]
	
	argument-size?: func [arg cdecl [logic!] /local type][
		max 
			any [
				all [object? arg arg/action = 'null emitter/size-of? 'integer!]
				all [
					type: compiler/get-type arg
					any [
						all [cdecl type/1 = 'float32! 8]	;-- promote to C double
						emitter/size-of? type
					]
				]
			]
			stack-width
	]
	
	call-arguments-size?: func [args [block!] /cdecl /local total type][
		total: 0
		foreach arg args [
			if arg <> #_ [							;-- bypass place-holder marker
				total: total + argument-size? arg to logic! cdecl
			]
		]
		total
	]
	
	foreach-member: func [spec [block!] body [block!] /local type][
		either 'value = last spec [
			unless 'struct! = spec/1 [spec: compiler/find-aliased spec/1]
			body: bind/copy body 'type
			if block? spec/1 [spec: next spec]

			foreach [name t] spec/2 [				;-- skip 'struct!
				unless word? name [break]
				either 'value = last type: t [
					foreach-member type body
				][
					do body
				]
			]
		][
			do body
		]
	]
	
	get-arguments-class: func [args [block!] /local c a b arg][
		c: 1
		foreach op [a b][
			arg: either object? args/:c [compiler/cast args/:c][args/:c]
			set op either arg = <last> [
				 'reg								;-- value in accumulator
			][
				switch type?/word arg [
					logic!	  [args/:c: to integer! arg 'imm]
					char! 	  ['imm]
					integer!  ['imm]
					decimal!  ['imm]
					word! 	  ['ref] 				;-- value needs to be fetched
					get-word! ['ref]
					block!    ['reg] 				;-- value in accumulator (or in alt-acc)
					path!     ['reg] 				;-- value in accumulator (or in alt-acc)
				]
			]
			c: c + 1
		]
		if verbose >= 3 [?? a ?? b]					;-- a and b hold addressing modes for operands
		reduce [a b]
	]
	
	emit-call: func [name [word!] args [block!] /local spec fspec res type attribs][
		if verbose >= 3 [print [">>>calling:" mold name mold args]]

		fspec: select compiler/functions name
		spec: any [select emitter/symbols name next fspec]
		type: either fspec/2 = 'routine [fspec/2][first spec]
		attribs: compiler/get-attributes fspec/4

		switch type [
			syscall [
				emit-call-syscall args fspec attribs
			]
			import [
				emit-call-import args fspec spec attribs
			]
			native [
				switch/default name [
					log-b [							;@@ needs a new function type...
						emit-pop
						emit-log-b compiler/last-type/1
					]
				][
					emit-call-native args fspec spec attribs
				]
			]
			routine [
				emit-call-native/routine args fspec spec attribs name
			]
			inline [
				if block? args/1 [args/1: <last>]	;-- works only for unary functions	
				do select [
					not	  [emit-not args/1]
					push  [emit-push args/1]
					pop	  [emit-pop]
					throw [
						compiler/check-throw
						compiler/last-type: [integer!]
						either compiler/catch-attribut? [
							emit-throw args/1
						][
							emit-throw/thru args/1
						]
					]
				] name
				if name = 'not [res: compiler/get-type args/1]
			]
			op [
				either compiler/any-float? compiler/resolve-expr-type args/1 [
					emit-float-operation name args
				][
					emit-integer-operation name args
				]
				unless find comparison-op name [	;-- comparison always return a logic!
					res: any [
						all [block? args/1 compiler/last-type]
						compiler/get-type args/1	;-- other ops return type of the first argument	
					]
				]
			]
		]
		res
	]
]