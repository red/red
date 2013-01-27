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

#define EVAL_CHECK_INPUT [
	if pc >= end [
		print-line "*** Interpreter Error: missing argument..."
		halt
	]
]

#define EVAL_ARGUMENT [
	EVAL_CHECK_INPUT
	if verbose > 0 [log "evaluating argument"]
	pc: eval-expression pc end no yes					;-- eval argument
	count: count + 1
]

#define EVAL_FETCH_ARGUMENT [
	EVAL_CHECK_INPUT
	if verbose > 0 [log "fetching argument"]
	stack/push pc
	pc: pc + 1
	count: count + 1
]

interpreter: context [
	verbose: 0

	ref-array: as int-ptr! allocate 64 * size? integer!	;-- for natives/actions refinements handling
	offset: 0											;-- refinements counter for last call
	count:  0											;-- arguments counter for last call
	return-type: -1										;-- return type for routine calls
	
	log: func [msg [c-string!]][
		print "eval: "
		print-line msg
	]
	
	exec: func [
		native	  [red-native!]							;-- works for action! too
		/local
			index [integer!]
			call
	][
		call: as function! [] native/code
		index: 0
		if positive? offset [
			until [
				system/words/push ref-array/index
				index: index + 1
				offset: offset - 1
				zero? offset
			]
		]
		call
	]
	
	exec-routine: func [
		routine [red-routine!]
		/local
			native [red-native!]
			arg	   [red-value!]
			bool   [red-logic!]
			int	   [red-integer!]
			s	   [series!]
			ret	   [integer!]
			call
	][
		s: as series! routine/more/value
		native: as red-native! s/offset + 2
		call: as function! [return: [integer!]] native/code
		count: count - 1								;-- zero-based stack access
		
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
				default [assert true]					;-- should never happen
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
			op	  [red-op!]
			call-op
	][
		if verbose > 0 [log "infix detected!"]
		
		stack/mark-native as red-word! pc + 1
		eval-expression pc end yes	yes
		pc: pc + 2										;-- skip both left operand and operator
		pc: eval-expression pc end no yes				;-- eval right operand
		op: as red-op! value
		call-op: as function! [] op/code
		call-op
		either sub? [stack/unwind][stack/unwind-last]

		if verbose > 0 [
			value: stack/arguments
			print-line ["eval: op return type: " TYPE_OF(value)]
		]
		pc
	]

	eval-arguments: func [
		native 	[red-native!]
		pc		[red-value!]
		end	  	[red-value!]
		return: [red-value!]
		/local
			fun	  	  [red-function!]
			function? [logic!]
			routine?  [logic!]
			value	  [red-value!]
			tail	  [red-value!]
			dt		  [red-datatype!]
			s		  [series!]
			ref?	  [logic!]
	][
		function?: TYPE_OF(native) = TYPE_FUNCTION
		routine?:  TYPE_OF(native) = TYPE_ROUTINE
		
		s: as series! either any [function? routine?][
			fun: as red-function! native
			fun/spec/node/value
		][
			native/spec/value
		]
		value: s/offset
		tail:  s/tail
		
		count:  	 0
		offset: 	 0
		return-type: -1
		ref?:		 no
		
		while [value < tail][
			if verbose > 0 [print-line ["eval: spec entry type: " TYPE_OF(value)]]
			switch TYPE_OF(value) [
				TYPE_WORD [
					either zero? offset [
						EVAL_ARGUMENT
					][
						either ref? [
							either any [function? routine?][
								none/push
							][
								ref-array/offset: count
								EVAL_ARGUMENT
							]
						][
							ref-array/offset: -1
						]
						offset: offset + 1
					]
				]
				TYPE_LIT_WORD [EVAL_FETCH_ARGUMENT]
				TYPE_GET_WORD [EVAL_FETCH_ARGUMENT]
				TYPE_REFINEMENT [
					ref?: no							;@@ set it correctly once path supported
					either any [function? routine?][
						;TBD: check here if refinement is used
						logic/push false
						offset: 1
					][
						ref-array/offset: -1
						offset: offset + 1
					]
				]
				TYPE_SET_WORD [
					if routine? [
						value: block/pick (as red-block! value + 1) 1
						assert TYPE_OF(value) = TYPE_WORD
						dt: as red-datatype! _context/get as red-word! value
						assert TYPE_OF(dt) = TYPE_DATATYPE
						return-type: dt/value
					]
					return pc
				]
				default [0]
			]
			value: value + 1
		]
		pc
	]
	
	eval-expression: func [
		pc		  [red-value!]
		end	  	  [red-value!]
		infix	  [logic!]								;-- TRUE => don't check for infix
		sub?	  [logic!]
		return:   [red-value!]
		/local
			next  [red-word!]
			value [red-value!]
			fun	  [red-function!]
			w	  [red-word!]
			s	  [series!]
	][
		next: as red-word! pc + 1
		
		if all [
			not infix
			TYPE_OF(next) = TYPE_WORD
		][
			value: _context/get next
			if TYPE_OF(value) = TYPE_OP [
				return eval-infix value pc end sub?
			]
		]

		if verbose > 0 [print-line ["eval: fetching value of type " TYPE_OF(pc)]]
		
		switch TYPE_OF(pc) [
			TYPE_PAREN [
				stack/mark-native as red-word! pc		;@@ ~paren
				eval as red-block! pc no
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
				--NOT_IMPLEMENTED--
			]
			TYPE_GET_WORD [
				word/get as red-word! pc
				pc: pc + 1
			]
			TYPE_LIT_WORD [
				w: word/push as red-word! pc			;-- push lit-word! on stack
				w/header: TYPE_WORD						;-- set correct value type on stack
				pc: pc + 1
			]
			TYPE_WORD [
				value: _context/get as red-word! pc
				pc: pc + 1
				
				switch TYPE_OF(value) [
					TYPE_ACTION 
					TYPE_NATIVE [
						if verbose > 0 [log "pushing action/native frame"]
						stack/mark-native as red-word! pc
						pc: eval-arguments as red-native! value pc end
						exec as red-native! value
						either sub? [stack/unwind][stack/unwind-last]
						
						if verbose > 0 [
							value: stack/arguments
							print-line ["eval: action/native return type: " TYPE_OF(value)]
						]
					]
					TYPE_ROUTINE [
						if verbose > 0 [log "pushing routine frame"]
						stack/mark-native as red-word! pc
						pc: eval-arguments as red-native! value pc end
						exec-routine as red-routine! value
						either sub? [stack/unwind][stack/unwind-last]

						if verbose > 0 [
							value: stack/arguments
							print-line ["eval: routine return type: " TYPE_OF(value)]
						]
					]
					TYPE_FUNCTION [
						if verbose > 0 [log "pushing function frame"]
						stack/mark-func as red-word! pc	;@@
						pc: eval-arguments as red-native! value pc end
						fun: as red-function! value
						s: as series! fun/more/value
						;eval as red-block! s/offset	;@@ eval body version (add an option for that)
						exec as red-native! s/offset + 2
						either sub? [stack/unwind][stack/unwind-last]
												
						if verbose > 0 [
							value: stack/arguments
							print-line ["eval: function return type: " TYPE_OF(value)]
						]
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
				--NOT_IMPLEMENTED--
			]
			TYPE_LIT_PATH [
				--NOT_IMPLEMENTED--
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
		pc
	]

	eval-next: func [
		value	[red-value!]
		tail	[red-value!]
		return: [red-value!]							;-- return start of next expression
	][
		stack/mark-native words/_body					;-- outer stack frame
		value: eval-expression value tail no no
		stack/unwind-last
		value
	]
	
	eval: func [
		code	  [red-block!]
		/local
			value [red-value!]
			tail  [red-value!]
	][
		value: block/rs-head code
		tail:  block/rs-tail code
		if value = tail [
			stack/set-last unset-value
			exit
		]

		stack/mark-native words/_body					;-- outer stack frame
		
		while [value < tail][
			if verbose > 0 [log "root loop..."]
			value: eval-expression value tail no no
			if value + 1 < tail [stack/reset]
		]
		
		stack/unwind-last
	]
	
]