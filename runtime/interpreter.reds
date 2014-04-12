Red/System [
	Title:   "Red interpreter"
	Author:  "Nenad Rakocevic"
	File: 	 %interpreter.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define CHECK_INFIX [
	if all [
		next < end
		TYPE_OF(next) = TYPE_WORD
	][
		value: _context/get next
		if TYPE_OF(value) = TYPE_OP [
			either next = as red-word! pc [
				if verbose > 0 [log "infix detected!"]
				infix?: yes
			][
				if TYPE_OF(pc) = TYPE_WORD [
					left: _context/get as red-word! pc
				]
				unless all [
					TYPE_OF(pc) = TYPE_WORD
					any [
						TYPE_OF(left) = TYPE_ACTION
						TYPE_OF(left) = TYPE_NATIVE
						TYPE_OF(left) = TYPE_FUNCTION
					]
					literal-first-arg? as red-native! left	;-- a literal argument is expected
				][
					if verbose > 0 [log "infix detected!"]
					infix?: yes
				]
			]
		]
	]
]

#define FETCH_ARGUMENT [
	if pc >= end [
		print-line "*** Interpreter Error: missing argument..."
		halt
	]
	switch TYPE_OF(value) [
		TYPE_WORD [
			if verbose > 0 [log "evaluating argument"]
			pc: eval-expression pc end no yes
		]
		TYPE_GET_WORD [
			if verbose > 0 [log "fetching argument as-is"]
			stack/push pc
			pc: pc + 1
		]
		default [
			if verbose > 0 [log "fetching argument"]
			switch TYPE_OF(pc) [
				TYPE_GET_WORD [
					copy-cell _context/get as red-word! pc stack/push*
				]
				TYPE_PAREN [
					either TYPE_OF(value) = TYPE_LIT_WORD [
						stack/mark-native as red-word! pc	;@@ ~paren
						eval as red-block! pc yes
						stack/unwind
					][
						stack/push pc
					]
				]
				default [
					stack/push pc
				]
			]
			pc: pc + 1
		]
	]
]

interpreter: context [
	verbose: 0

	return-type: -1										;-- return type for routine calls
	in-func?:	 0										;@@ make it thread-safe?
	
	log: func [msg [c-string!]][
		print "eval: "
		print-line msg
	]
	
	print-symbol: func [
		word [red-word!]
		/local
			sym [red-symbol!]
	][
		sym: symbol/get word/symbol
		print sym/cache
	]
	
	literal-first-arg?: func [
		native 	[red-native!]
		return: [logic!]
		/local
			fun	  	  [red-function!]
			value	  [red-value!]
			tail	  [red-value!]
			s		  [series!]
	][
		s: as series! either TYPE_OF(native) = TYPE_FUNCTION [
			fun: as red-function! native
			fun/spec/value
		][
			native/spec/value
		]
		value: s/offset
		tail:  s/tail
		
		while [value < tail][
			switch TYPE_OF(value) [
				TYPE_WORD 		[return no]
				TYPE_LIT_WORD	[return yes]
				default 		[0]
			]
			value: value + 1
		]
		no
	]
	
	eval-option: func [
		pc		  [red-value!]
		end		  [red-value!]
		value	  [red-value!]
		tail	  [red-value!]
		word	  [red-word!]
		offset	  [int-ptr!]
		args	  [int-ptr!]
		function? [logic!]
		return:	  [red-value!]
		/local
			ref	  [red-refinement!]
			slot  [red-logic!]
			type  [integer!]
			pos	  [integer!]
			idx	  [integer!]
			pos2  [integer!]
	][
		pos:  0											;-- stack offset
		idx:  1											;-- native stack ref-array index
		args/value: 0
		
		while [value < tail][
		
			switch TYPE_OF(value) [
				TYPE_REFINEMENT [
					ref: as red-refinement! value
					either EQUAL_WORDS?(ref word) [
						slot: as red-logic! stack/arguments + pos
						slot/value: true
						
						value: value + 1
						pos2: pos + 1
						while [
							type: TYPE_OF(value)
							all [
								value < tail
								any [
									type = TYPE_WORD
									type = TYPE_GET_WORD
									type = TYPE_LIT_WORD
									type = TYPE_STRING
								]
							]
						][
							unless type = TYPE_STRING [
								FETCH_ARGUMENT
								if function? [
									copy-cell stack/top - 1 stack/arguments + pos2 
									stack/pop 1
								]
								pos2: pos2 + 1
								args/value: args/value + 1
							]
							value: value + 1
						]
						unless function? [offset/value: idx]
						return pc
					][
						idx: idx + 1
					]
					pos: pos + 1
				]
				TYPE_WORD
				TYPE_GET_WORD
				TYPE_LIT_WORD [
					pos: pos + 1
				]
				default [0]
			]
			
			value: value + 1
		]
		print "Error: refinement /"
		print-symbol word
		print-line " not found!"
		halt
		null
	]
	
	eval-function: func [
		[catch]
		fun  [red-function!]
		body [red-block!]
		/local
			ctx	  [red-context!]
			saved [node!]
	][
		in-func?: in-func? + 1
		ctx: GET_CTX(fun)
		saved: ctx/values
		ctx/values: as node! stack/arguments
		eval body yes
		ctx/values: saved
		in-func?: in-func? - 1
	]
	
	exec-routine: func [
		fun	 [red-routine!]
		/local
			native [red-native!]
			arg	   [red-value!]
			bool   [red-logic!]
			int	   [red-integer!]
			s	   [series!]
			ret	   [integer!]
			count  [integer!]
			call
	][
		s: as series! fun/more/value
		native: as red-native! s/offset + 2
		call: as function! [return: [integer!]] native/code
		count: (routine/get-arity fun) - 1				;-- zero-based stack access
		
		while [count >= 0][
			arg: stack/arguments + count
			switch TYPE_OF(arg) [
				TYPE_LOGIC	 [push logic/get arg]
				TYPE_INTEGER [push integer/get arg]
				default		 [push arg]
			]
			count: count - 1
		]
		either positive? return-type [
			ret: call
			switch return-type [
				TYPE_LOGIC	[
					bool: as red-logic! stack/arguments
					bool/header: TYPE_LOGIC
					bool/value: ret <> 0
				]
				TYPE_INTEGER [
					int: as red-integer! stack/arguments
					int/header: TYPE_INTEGER
					int/value: ret
				]
				default [assert false]					;-- should never happen
			]
		][
			call
		]
	]
	
	eval-infix: func [
		value 	  [red-value!]
		pc		  [red-value!]
		end		  [red-value!]
		sub?	  [logic!]
		return:   [red-value!]
		/local
			next   [red-word!]
			left   [red-value!]
			infix? [logic!]
			op	   [red-op!]
			call-op
	][
		stack/keep
		pc: pc + 1										;-- skip operator
		pc: eval-expression pc end yes yes				;-- eval right operand
		op: as red-op! value
		call-op: as function! [] op/code
		call-op

		if verbose > 0 [
			value: stack/arguments
			print-line ["eval: op return type: " TYPE_OF(value)]
		]
		
		infix?: no
		next: as red-word! pc
		CHECK_INFIX
		if infix? [pc: eval-infix value pc end sub?]
		pc
	]
	
	eval-arguments: func [
		native 	[red-native!]
		pc		[red-value!]
		end	  	[red-value!]
		path	[red-path!]
		pos 	[red-value!]
		return: [red-value!]
		/local
			fun	  	  [red-function!]
			function? [logic!]
			routine?  [logic!]
			value	  [red-value!]
			head	  [red-value!]
			tail	  [red-value!]
			w		  [red-word!]
			blk		  [red-block!]
			dt		  [red-datatype!]
			path-end  [red-value!]
			s		  [series!]
			required? [logic!]
			index	  [integer!]
			count	  [integer!]
			offset	  [integer!]
			args	  [integer!]
			size	  [integer!]
			ref-array [int-ptr!]
			ret-set?  [logic!]
			call
	][
		routine?:  TYPE_OF(native) = TYPE_ROUTINE
		function?: any [routine? TYPE_OF(native) = TYPE_FUNCTION]
		
		s: as series! either function? [
			fun: as red-function! native
			fun/spec/value
		][
			native/spec/value
		]
		
		head:  s/offset
		value: head
		tail:  s/tail
		
		unless null? path [
			path-end: block/rs-tail as red-block! path
			if pos + 1 = path-end [path: null]			;-- no refinement following the function
		]												;-- so, process it as a non-path call
		
		count:  	 0									;-- base arity (mandatory arguments only)
		index: 	 	 1
		args:		 -1
		offset:		 -1
		ref?:		 no
		required?:	 yes								;-- yes: processing mandatory args, no: optional args
		
		unless function? [
			size: as-integer tail - value				;@@ takes more space than really needed
			ref-array: system/stack/top - size
			system/stack/top: ref-array					;-- reserve space on native stack for refs array
		]
		
		while [value < tail][
			if verbose > 0 [print-line ["eval: spec entry type: " TYPE_OF(value)]]
			switch TYPE_OF(value) [
				TYPE_WORD
				TYPE_GET_WORD
				TYPE_LIT_WORD [
					either required? [
						blk: as red-block! value + 1
						either all [
							pc >= end
							TYPE_OF(value) = TYPE_LIT_WORD
							value + 1 < tail
							TYPE_OF(blk) = TYPE_BLOCK
							symbol/is-any-type? as red-word! block/pick blk 1 null	;-- check for [any-type!] spec
						][
							unset/push
						][
							FETCH_ARGUMENT
						]
						count: count + 1
					][
						if function? [none/push]
					]
				]
				TYPE_REFINEMENT [
					if required? [required?: no]		;-- no more mandatory arguments
					
					either function? [
						logic/push false
					][
						ref-array/index: -1
						index: index + 1
					]
				]
				TYPE_SET_WORD [
					w: as red-word! value
					unless words/return* = symbol/resolve w/symbol [
						print "*** Error: invalid function definition: "
						print-symbol w
						print-line ":"
					]
					if routine? [
						ret-set?: yes
						value: block/pick (as red-block! value + 1) 1 null
						assert TYPE_OF(value) = TYPE_WORD
						dt: as red-datatype! _context/get as red-word! value
						assert TYPE_OF(dt) = TYPE_DATATYPE
						return-type: dt/value
					]
				]
				default [0]								;-- ignore other values
			]
			value: value + 1
		]
		
		unless ret-set? [return-type: -1]				;-- set the default correctly in case of nested calls
		
		unless routine? [
			if path <> null [
				pos: pos + 1
				
				while [pos < path-end][
					pc: eval-option pc end head tail as red-word! pos :offset :args function?
					
					unless function? [
						either args > 0 [
							ref-array/offset: count + args - 1
							count: count + args
						][
							ref-array/offset: 0
						]
					]
					pos: pos + 1
				]	
			]
		]
		
		unless function? [
			system/stack/top: ref-array					;-- reset native stack to our custom arguments frame
			call: as function! [] native/code			;-- direct call for actions/natives
			call
		]
		pc
	]
	
	eval-path: func [
		value   [red-value!]
		pc		[red-value!]							;-- path to evaluate
		end		[red-value!]
		set?	[logic!]
		return: [red-value!]
		/local 
			path   [red-path!]
			head   [red-value!]
			tail   [red-value!]
			item   [red-value!]
			parent [red-value!]
			saved  [red-value!]
	][
		if verbose > 0 [print-line "eval: path"]
		
		path:   as red-path! value
		head:   block/rs-head as red-block! path
		tail:   block/rs-tail as red-block! path
		item:   head + 1
		saved:  stack/top
		
		if TYPE_OF(head) <> TYPE_WORD [
			print-line "*** Error: path value must start with a word!"
			halt
		]
		
		parent: _context/get as red-word! head
		
		switch TYPE_OF(parent) [
			TYPE_ACTION								;@@ replace with TYPE_ANY_FUNCTION
			TYPE_NATIVE
			TYPE_ROUTINE
			TYPE_FUNCTION [
				pc: eval-code parent pc end yes path item - 1
				return pc
			]
			default [0]
		]
				
		while [item < tail][
			#if debug? = yes [if verbose > 0 [print-line ["eval: path parent: " TYPE_OF(parent)]]]
			
			value: either any [
				TYPE_OF(item) = TYPE_GET_WORD 
				all [
					parent = head
					TYPE_OF(item) = TYPE_WORD
					TYPE_OF(parent) <> TYPE_OBJECT
				]
			][
				_context/get as red-word! item
			][
				item
			]
			switch TYPE_OF(value) [
				TYPE_UNSET [
					print-line "*** Error: word in path has no value!"
					stack/push parent
					return pc
				]
				TYPE_PAREN [
					stack/mark-native words/_body		;@@ ~paren
					eval as red-block! value yes		;-- eval paren content
					stack/unwind
					value: stack/top - 1
				]
				default [0]								;-- pass-thru
			]
			#if debug? = yes [if verbose > 0 [print-line ["eval: path item: " TYPE_OF(value)]]]
			
			parent: actions/eval-path parent value all [set? item + 1 = tail]
			
			switch TYPE_OF(parent) [
				TYPE_ACTION								;@@ replace with TYPE_ANY_FUNCTION
				TYPE_NATIVE
				TYPE_ROUTINE
				TYPE_FUNCTION [
					pc: eval-code parent pc end yes path item
					return pc
				]
				default [0]
			]
			
			item: item + 1
		]
		
		stack/top: saved
		stack/push parent
		pc
	]
	
	eval-code: func [
		value	[red-value!]
		pc		[red-value!]
		end		[red-value!]
		sub?	[logic!]
		path	[red-path!]
		slot 	[red-value!]
		return: [red-value!]
		/local
			name   [red-word!]
	][
		name: as red-word! pc - 1
		if TYPE_OF(name) <> TYPE_WORD [name: words/_anon]
		
		switch TYPE_OF(value) [
			TYPE_ACTION 
			TYPE_NATIVE [
				if verbose > 0 [log "pushing action/native frame"]
				stack/mark-native name
				pc: eval-arguments as red-native! value pc end path slot 	;-- fetch args and exec
				either sub? [stack/unwind][stack/unwind-last]

				if verbose > 0 [
					value: stack/arguments
					print-line ["eval: action/native return type: " TYPE_OF(value)]
				]
			]
			TYPE_ROUTINE [
				if verbose > 0 [log "pushing routine frame"]
				stack/mark-native name
				pc: eval-arguments as red-native! value pc end path slot
				exec-routine as red-routine! value
				either sub? [stack/unwind][stack/unwind-last]

				if verbose > 0 [
					value: stack/arguments
					print-line ["eval: routine return type: " TYPE_OF(value)]
				]
			]
			TYPE_FUNCTION [
				if verbose > 0 [log "pushing function frame"]
				stack/mark-func name
				pc: eval-arguments as red-native! value pc end path slot
				_function/call as red-function! value
				either sub? [stack/unwind][stack/unwind-last]

				if verbose > 0 [
					value: stack/arguments
					print-line ["eval: function return type: " TYPE_OF(value)]
				]
			]
		]
		pc
	]
	
	eval-expression: func [
		pc		  [red-value!]
		end	  	  [red-value!]
		prefix?	  [logic!]								;-- TRUE => don't check for infix
		sub?	  [logic!]
		return:   [red-value!]
		/local
			next   [red-word!]
			value  [red-value!]
			left   [red-value!]
			w	   [red-word!]
			op	   [red-value!]
			sym	   [integer!]
			infix? [logic!]
	][
		if verbose > 0 [print-line ["eval: fetching value of type " TYPE_OF(pc)]]
		
		infix?: no
		unless prefix? [
			next: as red-word! pc + 1
			CHECK_INFIX
			if infix? [
				stack/mark-native as red-word! pc + 1
				sub?: yes								;-- force sub? for infix expressions
				op: value
			]
		]
		
		switch TYPE_OF(pc) [
			TYPE_PAREN [
				stack/mark-native as red-word! pc		;@@ ~paren
				eval as red-block! pc yes
				either sub? [stack/unwind][stack/unwind-last]
				pc: pc + 1
			]
			TYPE_SET_WORD [
				stack/mark-native as red-word! pc		;@@ ~set
				word/push as red-word! pc
				pc: pc + 1
				pc: eval-expression pc end no yes
				word/set
				either sub? [stack/unwind][stack/unwind-last]
				
				if verbose > 0 [
					value: stack/arguments
					print-line ["eval: set-word return type: " TYPE_OF(value)]
				]
			]
			TYPE_SET_PATH [
				value: pc
				pc: pc + 1
				pc: eval-expression pc end no yes		;-- yes: push value on top of stack
				pc: eval-path value pc end yes
			]
			TYPE_GET_WORD [
				copy-cell _context/get as red-word! pc stack/push*
				pc: pc + 1
			]
			TYPE_LIT_WORD [
				either sub? [
					w: word/push as red-word! pc		;-- nested expression: push value
				][
					w: as red-word! stack/set-last pc	;-- root expression: return value
				]
				w/header: TYPE_WORD						;-- coerce it to a word!
				pc: pc + 1
			]
			TYPE_WORD [
				if verbose > 0 [
					print "eval: '"
					print-symbol as red-word! pc
					print lf
				]
				value: _context/get as red-word! pc
				
				if positive? in-func? [
					w: as red-word! pc
					sym: w/symbol
					case [
						sym = words/exit* [
							copy-cell unset-value stack/arguments
							stack/unroll-last stack/FLAG_FUNCTION
							throw THROWN_EXIT
						]
						sym = words/return* [
							pc: pc + 1
							either pc >= end [
								copy-cell unset-value stack/arguments
							][
								pc: eval-expression pc end no yes
							]
							stack/unroll-last stack/FLAG_FUNCTION
							throw THROWN_RETURN
						]
						true [0]
					]
				]
				pc: pc + 1
				
				switch TYPE_OF(value) [
					TYPE_UNSET [
						print-line "*** Error: word has no value!"
						either sub? [stack/push unset-value][stack/set-last unset-value]
					]
					TYPE_LIT_WORD [
						word/push as red-word! value	;-- push lit-word! on stack
					]
					TYPE_ACTION							;@@ replace with TYPE_ANY_FUNCTION
					TYPE_NATIVE
					TYPE_ROUTINE
					TYPE_FUNCTION [
						pc: eval-code value pc end sub? null null
					]
					default [
						if verbose > 0 [log "getting word value"]
						either sub? [
							stack/push value			;-- nested expression: push value
						][
							stack/set-last value		;-- root expression: return value
						]
						
						if verbose > 0 [
							value: stack/arguments
							print-line ["eval: word return type: " TYPE_OF(value)]
						]
					]
				]
			]
			TYPE_PATH [
				value: pc
				pc: pc + 1
				pc: eval-path value pc end no
			]
			TYPE_LIT_PATH [
				value: stack/push pc
				value/header: TYPE_PATH
				pc: pc + 1
			]
			TYPE_OP [
				--NOT_IMPLEMENTED--						;-- op used in prefix mode
			]
			default [
				either sub? [
					stack/push pc						;-- nested expression: push value
				][
					stack/set-last pc					;-- root expression: return value
				]
				pc: pc + 1
			]
		]
		
		if infix? [
			pc: eval-infix op pc end sub?
			unless prefix? [
				either sub? [stack/unwind][stack/unwind-last]
			]
		]
		pc
	]

	eval-next: func [
		value	[red-value!]
		tail	[red-value!]
		sub?	[logic!]
		return: [red-value!]							;-- return start of next expression
	][
		stack/mark-native words/_body					;-- outer stack frame
		value: eval-expression value tail no sub?
		either sub? [stack/unwind][stack/unwind-last]
		value
	]
	
	eval: func [
		code   [red-block!]
		chain? [logic!]									;-- chain it with previous stack frame
		/local
			value [red-value!]
			tail  [red-value!]
			arg	  [red-value!]
	][
		value: block/rs-head code
		tail:  block/rs-tail code
		if value = tail [
			arg: stack/arguments
			arg/header: TYPE_UNSET
			exit
		]

		stack/mark-native words/_body					;-- outer stack frame
		
		while [value < tail][
			if verbose > 0 [log "root loop..."]
			value: eval-expression value tail no no
			if value + 1 < tail [stack/reset]
		]
		either chain? [stack/unwind-last][stack/unwind]
	]
	
]