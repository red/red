Red/System [
	Title:   "Red interpreter"
	Author:  "Nenad Rakocevic"
	File: 	 %interpreter.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

interpreter: context [
	verbose: 0
	
	#enum fetch-args-mode! [
		MODE_FETCH:			0							;-- regular arguments evaluation and fetching
		MODE_APPLY:			1							;-- fetch literally and apply arguments
		MODE_APPLY_SOME:	2							;-- search and apply arguments
		MODE_APPLY_SAFER:	4							;-- fetch one value only per argument; skip if inactive
	]
	
	#enum fetch-type! [									;	Bits 21-20 of a typeset! slot header
		FETCH_WORD:			00000000h
		FETCH_GET_WORD:		00100000h
		FETCH_LIT_WORD:		00200000h
		FETCH_SET_WORD:		00300000h
	]

	#enum events! [
		EVT_INIT:			00000001h
		EVT_END:			00000002h
		EVT_PROLOG:			00000004h
		EVT_EPILOG:			00000008h
		EVT_ENTER:			00000010h
		EVT_EXIT:			00000020h
		EVT_OPEN:			00000040h
		EVT_RETURN:			00000080h
		EVT_FETCH:			00000100h
		EVT_PUSH:			00000200h
		EVT_SET:			00000400h
		EVT_CALL:			00000800h
		EVT_ERROR:			00001000h
		EVT_THROW:			00002000h
		EVT_CATCH:			00004000h
		EVT_EXPR:			00008000h
		;EVT_EVAL_PATH:		00000000h					;-- reserved for future use
		;EVT_SET_PATH:		00000000h
	]
	
	trace?:		no										;-- yes: event mode active (only set by do/trace)
	tracing?:	no										;-- currently enabled/disabled event generation
	trace-fun:	as red-function! 0						;-- event handler reference (on stack)
	fun-locs:	0										;-- event handler locals count
	fun-evts:	0										;-- bitmask for encoding selected events
	all-events:	1FFFFh									;-- bit-mask of all events
	near:		declare red-block!						;-- Near: field in error! objects
	
	log: func [msg [c-string!]][print "eval: " print-line msg]
	
	decode-filter: func [fun [red-function!] return: [integer!]
		/local
			evts flag sym [integer!]
			value tail [red-word!]
			blk		   [red-block!]
			s		   [series!]
	][
		s: as series! fun/more/value
		blk: as red-block! s/offset
		if any [TYPE_OF(blk) <> TYPE_BLOCK block/rs-tail? blk][return all-events]
		blk: as red-block! block/rs-head blk
		if TYPE_OF(blk) <> TYPE_BLOCK [return all-events]

		s: GET_BUFFER(blk)
		value: as red-word! s/offset + blk/head
		tail:  as red-word! s/tail
		evts:  0
		while [value < tail][
			if TYPE_OF(value) = TYPE_WORD [
				sym: symbol/resolve value/symbol
				flag: case [
					sym = words/_prolog/symbol	[EVT_PROLOG]
					sym = words/_epilog/symbol	[EVT_EPILOG]
					sym = words/_enter/symbol	[EVT_ENTER]
					sym = words/_exit/symbol	[EVT_EXIT]
					sym = words/_fetch/symbol	[EVT_FETCH]
					sym = words/_push/symbol	[EVT_PUSH]
					sym = words/_open/symbol	[EVT_OPEN]
					sym = words/_return/symbol	[EVT_RETURN]
					sym = words/_set/symbol		[EVT_SET]
					sym = words/_call/symbol	[EVT_CALL]
					sym = words/_expr/symbol	[EVT_EXPR]
					sym = words/_error/symbol	[EVT_ERROR]
					sym = words/_init/symbol	[EVT_INIT]
					sym = words/_end/symbol		[EVT_END]
					sym = words/_throw/symbol	[EVT_THROW]
					sym = words/_catch/symbol	[EVT_CATCH]
					true						[0]				;-- ignore invalid names
				]
				evts: evts or flag
			]
			value: value + 1
		]
		evts
	]

	fire-event: func [
		event  	[events!]
		code	[red-block!]
		pc		[red-value!]
		ref		[red-value!]
		value   [red-value!]
		/local
			saved head tail [red-value!]
			evt   [red-word!]
			int	  [red-integer!]
			more  [series!]
			ctx	  [node!]
			len	base top i [integer!]
			csaved [int-ptr!]
	][
		assert all [trace-fun <> null TYPE_OF(trace-fun) = TYPE_FUNCTION]
		if fun-evts and event = 0 [exit]
		
		base: (as-integer stack/arguments - stack/bottom) >> 4
		top:  (as-integer stack/top - stack/bottom) >> 4
		saved: stack/top
		csaved: as int-ptr! stack/ctop
		stack/top: stack/top + 1						;-- keep last value
		more: as series! trace-fun/more/value
		int: as red-integer! more/offset + 4
		ctx: either TYPE_OF(int) = TYPE_INTEGER [as node! int/value][global-ctx]
		
		stack/mark-func words/_interp-cb trace-fun/ctx
		evt: switch event [
			EVT_PROLOG	[words/_prolog]
			EVT_EPILOG	[words/_epilog]
			EVT_ENTER	[words/_enter]
			EVT_EXIT	[words/_exit]
			EVT_FETCH	[words/_fetch]
			EVT_PUSH	[words/_push]
			EVT_OPEN	[words/_open]
			EVT_RETURN	[words/_return]
			EVT_SET		[words/_set]
			EVT_CALL	[words/_call]
			EVT_EXPR	[words/_expr]
			EVT_ERROR	[words/_error]
			EVT_INIT	[words/_init]
			EVT_END		[words/_end]
			EVT_THROW	[words/_throw]
			EVT_CATCH	[words/_catch]
			default		[assert false null]
		]
		stack/push as red-value! evt					;-- event name
		either null? code [
			stack/push none-value						;-- code
			integer/push -1								;-- offset
		][
			code: as red-block! stack/push as red-value! code
			i: either null? pc [-1][
				head: block/rs-head code
				tail: block/rs-tail code
				either all [head <= pc pc <= tail][(as-integer pc - head) >> 4][-1]
			]
			integer/push i
		]
		if any [value = null TYPE_OF(value) = 0][value: none-value]
		stack/push value								;-- value
		ref: switch event [
			EVT_CALL EVT_RETURN EVT_PROLOG EVT_EPILOG EVT_SET [ref]
			default [none-value]
		]
		stack/push ref									;-- reference (word, path,...)
		pair/push base top								;-- frame (pair!)
		if positive? fun-locs [_function/init-locals fun-locs]

		tracing?: no
		catch RED_THROWN_ERROR [call trace-fun ctx as red-value! words/_interp-cb CB_INTERPRETER]
		if system/thrown <> 0 [re-throw]
		tracing?: yes
		
		stack/unwind
		stack/top: saved
		stack/set-ctop csaved
	]
	
	fire-init:	does [if tracing? [fire-event EVT_INIT null null null null]]
	fire-end:	does [if tracing? [fire-event EVT_END  null null null null]]
	fire-throw:	does [if tracing? [fire-event EVT_THROW null null null stack/arguments]]
	fire-catch:	does [if tracing? [fire-event EVT_CATCH null null null stack/arguments]]
	
	fire-call: func [ref [red-value!] fun [red-function!]][
		if tracing? [fire-event EVT_CALL null null ref as red-value! fun]
	]
	fire-return: func [ref [red-value!] fun [red-function!]][
		if tracing? [fire-event EVT_RETURN null null ref stack/arguments]
	]
	
	preprocess-spec: func [
		native 	[red-native!]
		return: [node!]
		/local
			fun		  [red-function!]
			list	  [red-block!]
			value	  [red-value!]
			tail	  [red-value!]
			saved	  [red-value!]
			base	  [red-value!]
			int		  [red-integer!]
			w		  [red-word!]
			blk		  [red-block!]
			ts		  [red-typeset!]
			s		  [series!]
			mode	  [integer!]
			locals	  [integer!]
			refs	  [integer!]
			function? [logic!]
			store	  [subroutine!]
	][
		#if debug? = yes [if verbose > 2 [print-line "cache: pre-processing function spec"]]

		store: [
			blk: as red-block! value + 1
			ts: either all [
				blk < tail
				TYPE_OF(blk) = TYPE_BLOCK
				positive? block/rs-length? blk
			][
				typeset/make-with list blk
			][
				typeset/make-default list
			]
			ts/header: ts/header and flag-fetch-mask or mode
		]
		saved: stack/top
		function?: any [TYPE_OF(native) = TYPE_ROUTINE TYPE_OF(native) = TYPE_FUNCTION]

		s: as series! either function? [
			fun:  as red-function! native
			fun/spec/value
		][
			native/spec/value
		]
		locals: 0
		refs:	1										;-- 1-based array index
		list:	block/push-only* 8
		value:	s/offset
		tail:	s/tail

		while [value < tail][
			#if debug? = yes [if verbose > 2 [print-line ["cache: spec entry type: " TYPE_OF(value)]]]
			switch TYPE_OF(value) [
				TYPE_WORD		[mode: FETCH_WORD     store]
				TYPE_GET_WORD	[mode: FETCH_GET_WORD store]
				TYPE_LIT_WORD	[mode: FETCH_LIT_WORD store]
				TYPE_REFINEMENT [
					w: as red-word! value
					either refinements/local/symbol = symbol/resolve w/symbol [
						base: value
						value: value + 1
						while [all [value < tail TYPE_OF(value) <> TYPE_SET_WORD]][value: value + 1]
						locals: (as-integer value - base) >> 4
					][
						w: as red-word! block/rs-append list value
						unless function? [
							w/index: refs
							refs: refs + 1
						]
					]
				]
				TYPE_SET_WORD [
					w: as red-word! value
					if words/return* <> symbol/resolve w/symbol [
						fire [TO_ERROR(script bad-func-def)	w]
					]
					mode: FETCH_SET_WORD
					store
				]
				default [0]								;-- ignore other values
			]
			value: value + 1
		]
		if locals > 0 [integer/make-in list locals]
		if all [not function? refs > 1][integer/make-in list refs - 1]
		stack/top: saved
		list/node
	]
	
	set-locals: func [
		fun [red-function!]
		/local
			tail  [red-value!]
			value [red-value!]
			s	  [series!]
			set?  [logic!]
	][
		s: as series! fun/spec/value
		value: s/offset
		tail:  s/tail
		set?:  no
		
		while [value < tail][
			switch TYPE_OF(value) [
				TYPE_WORD
				TYPE_GET_WORD
				TYPE_LIT_WORD [
					if set? [none/push]
				]
				TYPE_REFINEMENT [
					unless set? [set?: yes]
					logic/push false
				]
				default [0]								;-- ignore other values
			]
			value: value + 1
		]
	]
	
	call: func [
		fun	  [red-function!]
		ctx	  [node!]
		ref	  [red-value!]
		class [cb-class!]
		/local
			s	   [series!]
			code   [red-integer!]
			saved  [node!]
			fctx   [red-context!]
			int	   [red-integer!]
			prev?  [logic!]
			allow? [logic!]
			call   [function! []]
			ocall  [function! [octx [node!]]]
	][
		prev?: tracing?
		allow?: all [prev? class <> CB_INTERPRETER]
		if allow? [
			int: as red-integer! #get system/state/callbacks/bits
			assert TYPE_OF(int) = TYPE_INTEGER
			if class and int/value = 0 [tracing?: no]	;-- disable tracing for unwanted internal callbacks
		]
		s: as series! fun/more/value
		code: as red-integer! s/offset + 2
		either any [TYPE_OF(code) <> TYPE_INTEGER zero? code/value][
			if allow? [fire-call ref fun]
			eval-function fun as red-block! s/offset ref
			if allow? [
				fire-return ref fun
				tracing?: prev?
			]
		][
			fctx: GET_CTX(fun)
			saved: fctx/values
			assert system/thrown = 0
			catch RED_THROWN_ERROR [
				either ctx = global-ctx [
					call: as function! [] code/value
					call
					0									;FIXME: required to pass compilation
				][
					ocall: as function! [octx [node!]] code/value
					ocall ctx
					0
				]
			]
			fctx/values: saved
			if allow? [tracing?: prev?]

			switch system/thrown [
				RED_THROWN_ERROR
				RED_THROWN_BREAK
				RED_THROWN_CONTINUE
				RED_THROWN_THROW	[re-throw]			;-- let exception pass through
				RED_THROWN_EXIT
				RED_THROWN_RETURN	[stack/unwind-last]
				default [0]								;-- else, do nothing
			]
			system/thrown: 0
		]
	]
	
	eval-function: func [
		fun  [red-function!]
		body [red-block!]
		ref  [red-value!]								;-- referent word! or path!
		/local
			ctx		 [red-context!]
			saved	 [node!]
			thrown	 [integer!]
			prev	 [logic!]
			force?	 [logic!]
			prevent? [logic!]
	][
		ctx: GET_CTX(fun)
		saved: ctx/values
		ctx/values: as node! stack/arguments
		stack/set-in-func-flag yes
		prev: tracing?
		force?:   fun/header and flag-force-trace <> 0
		prevent?: fun/header and flag-no-trace <> 0
		if force?   [tracing?: trace?]					;-- force tracing only if trace mode enabled
		if prevent? [tracing?: no]						;-- force tracing only if trace mode enabled
		
		if tracing? [
			catch RED_THROWN_ERROR [fire-event EVT_PROLOG body null ref as red-value! fun]
			if system/thrown >= RED_THROWN_THROW [
				stack/set-in-func-flag no
				ctx/values: saved
				re-throw
			]
			system/thrown: 0
		]
		assert system/thrown = 0
		
		catch RED_THROWN_ERROR [eval body yes]
		
		if tracing? [
			thrown: system/thrown
			system/thrown: 0
			fire-event EVT_EPILOG body null ref as red-value! fun
			system/thrown: thrown
		]
		if any [force? prevent?][tracing?: prev]
		stack/set-in-func-flag no
		ctx/values: saved
		switch system/thrown [
			RED_THROWN_ERROR
			RED_THROWN_BREAK
			RED_THROWN_CONTINUE
			RED_THROWN_THROW	[re-throw]				;-- let exception pass through
			default [0]									;-- else, do nothing
		]
		system/thrown: 0
	]
	
	exec-routine: func [
		rt [red-routine!]
		/local
			code	[red-integer!]
			arg		[red-value!]
			base	[red-value!]
			bool	[red-logic!]
			int		[red-integer!]
			rtype	[red-integer!]
			fl		[red-float!]
			value	[red-value!]
			tail	[red-value!]
			dt		[red-datatype!]
			w		[red-word!]
			s		[series!]
			ret		[integer!]
			retf	[float!]
			sym		[integer!]
			count	[integer!]
			cnt 	[integer!]
			args	[integer!]
			type	[integer!]
			saved	[int-ptr!]
			pos		[byte-ptr!]
			bits 	[byte-ptr!]
			set? 	[logic!]
			extern?	[logic!]
			call	[function! [return: [integer!]]]
			callf	[function! [return: [float!]]]
			callex	[function! [[cdecl custom] return: [integer!]]]
	][
		extern?: rt/header and flag-extern-code <> 0
		s:		as series! rt/more/value
		code:	as red-integer! s/offset + 2
		rtype:  as red-integer! s/offset + 4
		args:	routine/get-arity rt
		count:	args - 1				;-- zero-based stack access
		
		either extern? [
			base: stack/arguments
			;@@ cdecl is hardcoded in the caller, needs to be dynamic!
			callex: as function! [[cdecl custom] return: [integer!]] code/value
			stack/mark-native words/_body
			
			#if stack-align-16? = yes [
				saved: system/stack/align
				cnt: 4 - (count + 1 and 3)
				while [cnt > 0][push 0 cnt: cnt - 1]
			]
			#if target = 'ARM [
				saved: system/stack/align
			]
			while [count >= 0][
				arg: base + count
				#either libRed? = yes [
					push red/ext-ring/store arg			;-- copy the exported values to libRed's buffer
				][
					push arg
				]
				count: count - 1
			]
			arg: as red-value! callex args
			#either any [stack-align-16? = yes target = 'ARM][	;@@ 64-bit alignment required on ARM
				system/stack/top: saved
			][
				pop args
			]
			stack/unwind
			stack/set-last arg
		][
			call: as function! [return: [integer!]] code/value

			s: as series! rt/spec/value
			value: s/offset
			tail:  s/tail
			
			until [										;-- scan forward for end of arguments
				switch TYPE_OF(value) [
					TYPE_SET_WORD
					TYPE_REFINEMENT [break]
					default			[0]
				]
				value: value + 1
				value >= tail
			]

			while [count >= 0][							;-- push arguments in reverse order
				value: value - 1
				if TYPE_OF(value) =	TYPE_BLOCK [
					w: as red-word! block/rs-head as red-block! value
					if TYPE_OF(w) <> TYPE_WORD [fire [TO_ERROR(script invalid-type-spec) w]]
					sym: w/symbol
					arg: stack/arguments + count
					
					if sym <> words/any-type! [			;-- type-checking argument
						dt: as red-datatype! _context/get w
						case [
							TYPE_OF(dt)	= TYPE_TYPESET [
								bits: (as byte-ptr! dt) + 4
								type: TYPE_OF(arg)
								BS_TEST_BIT(bits type set?)
								unless set? [ERR_EXPECT_ARGUMENT(dt/value count)]
							]
							TYPE_OF(arg) = dt/value [0]	;-- all good, do nothing
							true [ERR_EXPECT_ARGUMENT(dt/value count)]
						]
					]
					case [
						sym = words/logic!	 [push logic/get arg]
						sym = words/integer! [push integer/get arg]
						sym = words/float!	 [push float/get arg]
						true		 		 [push arg]
					]
					count: count - 1
				]
			]
			either positive? rtype/value [
				switch rtype/value [
					TYPE_LOGIC	[
						ret: call
						bool: as red-logic! stack/arguments
						bool/header: TYPE_LOGIC
						bool/value: ret <> 0
					]
					TYPE_INTEGER [
						ret: call
						int: as red-integer! stack/arguments
						int/header: TYPE_INTEGER
						int/value: ret
					]
					TYPE_FLOAT [
						callf: as function! [return: [float!]] code/value
						retf: callf
						fl: as red-float! stack/arguments
						fl/header: TYPE_FLOAT
						fl/value: retf
					]
					default [assert false]				;-- should never happen
				]
			][call]
		]
	]
	
	eval-path: func [
		value   [red-value!]							;-- path to evaluate
		pc		[red-value!]
		end		[red-value!]
		code	[red-block!]
		set?	[logic!]
		get?	[logic!]
		sub?	[logic!]
		case?	[logic!]
		return: [red-value!]
		/local
			head tail item parent gparent saved prev arg p-item [red-value!]
			path  [red-path!]
			obj	  [red-object!]
			w	  [red-word!]
			ser	  [red-series!]
			type idx   [integer!]
			tail? evt? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "eval: path"]]
		
		path: as red-path! value
		head: block/rs-head as red-block! path
		tail: block/rs-tail as red-block! path
		if head = tail [fire [TO_ERROR(script empty-path)]]
		if tracing? [fire-event EVT_ENTER as red-block! path head null null]
		if tracing? [fire-event EVT_FETCH as red-block! path head head head]
		
		item:  head + 1
		saved: stack/top
		idx:   0
		
		if TYPE_OF(head) <> TYPE_WORD [fire [TO_ERROR(script word-first) path]]
		
		p-item: head
		w: as red-word! head
		parent: _context/get w
		gparent: null
		
		switch TYPE_OF(parent) [
			TYPE_ACTION									;@@ replace with TYPE_ANY_FUNCTION
			TYPE_NATIVE
			TYPE_ROUTINE
			TYPE_FUNCTION [
				if set? [fire [TO_ERROR(script invalid-path-set) path]]
				if get? [fire [TO_ERROR(script invalid-path-get) path]]
				pc: eval-code parent pc end code yes path item - 1 parent MODE_FETCH no
				unless sub? [stack/set-last stack/top]
				if tracing? [fire-event EVT_EXIT as red-block! path tail null stack/arguments]
				return pc
			]
			TYPE_UNSET [fire [TO_ERROR(script unset-path) path head]]
			default	   [0]
		]
		if tracing? [fire-event EVT_PUSH as red-block! path head head parent]

		if w/ctx <> global-ctx [
			obj: as red-object! GET_CTX(w) + 1
			if TYPE_OF(obj) <> TYPE_OBJECT [gparent: as red-value! obj]
		]
		
		while [item < tail][
			#if debug? = yes [if verbose > 0 [print-line ["eval: path parent: " TYPE_OF(parent)]]]
			
			if tracing? [fire-event EVT_FETCH as red-block! path item item item]
			
			value: switch TYPE_OF(item) [ 
				TYPE_GET_WORD [_context/get as red-word! item]
				TYPE_PAREN 	  [
					eval as red-block! item no			;-- eval paren content
					stack/top - 1
				]
				default [item]
			]
			if tracing? [fire-event EVT_PUSH as red-block! path item item value]
			if TYPE_OF(value) = TYPE_UNSET [fire [TO_ERROR(script invalid-path) path item]]
			#if debug? = yes [if verbose > 0 [print-line ["eval: path item: " TYPE_OF(value)]]]
			
			;-- invoke eval-path action
			prev: parent
			type: TYPE_OF(parent)
			tail?: item + 1 = tail
			arg: either all [set? tail?][stack/arguments][null]
			evt?: no

			if all [set?  head + 2 <= item  item + 1 = tail][ ;-- check only if set-path of length > 2
				ser: as red-series! gparent
				evt?: either ser = null [no][
					obj: as red-object! ser
					switch TYPE_OF(ser) [
						TYPE_OBJECT [all [obj/on-set <> null TYPE_OF(p-item) = TYPE_WORD]]
						TYPE_ANY_BLOCK   [gparent <> null]
						default			 [no]
					]
				]
			]
			parent: actions/eval-path parent value arg path gparent p-item idx case? get? tail? evt?

			if all [not get? not set?][
				switch TYPE_OF(parent) [
					TYPE_ACTION							;@@ replace with TYPE_ANY_FUNCTION
					TYPE_NATIVE
					TYPE_ROUTINE
					TYPE_FUNCTION [
						pc: eval-code parent pc end code sub? path item prev MODE_FETCH no
						parent: stack/get-top
						item: tail						;-- force loop exit
					]
					default [0]
				]
			]
			p-item: item
			gparent: prev								;-- save previous parent reference
			item: item + 1
			idx: idx + 1
		]
		if tracing? [fire-event EVT_EXIT as red-block! path tail null parent]

		stack/top: saved
		either sub? [stack/push parent][stack/push-last parent]
		pc
	]

	eval-arguments: func [
		native 	[red-native!]
		pc		[red-value!]
		end	  	[red-value!]
		code	[red-block!]
		path	[red-path!]
		ref-pos [red-value!]
		mode	[fetch-args-mode!]
		infix?	[logic!]
		return: [red-value!]
		/local
			value head tail path-end arg new saved base pc-pos call-pos s-end [red-value!]
			fun					[red-function!]
			fname				[red-word!]
			ref	name			[red-word!]
			ref-slot			[red-refinement!]
			blk					[red-block!]
			int					[red-integer!]
			ctx					[red-context!]
			bool b2				[red-logic!]
			s					[series!]
			args nctx			[node!]
			p ref-array	offset	[int-ptr!]
			pos	bits			[byte-ptr!]
			index arg-cnt ref-cnt loc-cnt sym-cnt type xcode idx exp-type [integer!]
			required? function? routine? set? get? apply? native? ifx? some? t? safer? ref? [logic!]
			fetch-arg get-spec-word	[subroutine!]
			calln				[function! []]
	][
		get-spec-word: [
			ref: _hashtable/get-ctx-word ctx sym-cnt
			word/push* ref/symbol
		]
		fetch-arg: [
			either pc >= end [fire [TO_ERROR(script no-arg) fname get-spec-word]][
				switch value/header and flag-fetch-mode [
					FETCH_WORD [
						#if debug? = yes [if verbose > 0 [log "evaluating argument"]]
						if safer? [s-end: end end: pc + 1]
						pc: eval-expression pc end code infix? yes no
						if safer? [end: s-end]
					]
					FETCH_GET_WORD [
						#if debug? = yes [if verbose > 0 [log "fetching argument as-is"]]
						if tracing? [fire-event EVT_FETCH code pc pc pc]
						new: stack/push pc
						if tracing? [fire-event EVT_PUSH code pc pc new]
						pc: pc + 1
					]
					FETCH_LIT_WORD [
						#if debug? = yes [if verbose > 0 [log "fetching argument"]]
						switch TYPE_OF(pc) [
							TYPE_PAREN [
								stack/mark-interp-native words/_anon
								eval as red-block! pc yes
								stack/unwind
							]
							TYPE_GET_WORD [
								if tracing? [fire-event EVT_FETCH code pc pc pc]
								new: copy-cell _context/get as red-word! pc stack/push*
								if tracing? [fire-event EVT_PUSH code pc pc new]
							]
							TYPE_GET_PATH [eval-path pc pc + 1 end code no yes yes no]
							default		  [
								if tracing? [fire-event EVT_FETCH code pc pc pc]
								new: stack/push pc
								if tracing? [fire-event EVT_PUSH code pc pc new]
							]
						]
						pc: pc + 1
						;if tracing? [fire-event EVT_PUSH code pc pc value yes]
					]
					default [assert false]
				]
			]
		]
		routine?:  TYPE_OF(native) = TYPE_ROUTINE
		native?:   TYPE_OF(native) = TYPE_NATIVE
		function?: any [routine? TYPE_OF(native) = TYPE_FUNCTION]
		ref-array: null
		apply?:	   mode > MODE_FETCH
		some?:	   mode and MODE_APPLY_SOME <> 0
		safer?:	   mode and MODE_APPLY_SAFER <> 0
		
		either apply? [
			call-pos: either path = null [ref-pos][as red-value! path]
			fname: as red-word! ref-pos
		][
			call-pos: pc - 1
			fname: as red-word! call-pos
		]
		if infix? [stack/top: stack/top + 1]
		
		fun: as red-function! native
		s: as series! fun/more/value
		blk: as red-block! s/offset + 1
		either TYPE_OF(blk) = TYPE_BLOCK [args: blk/node][
			args: preprocess-spec native
			blk/header: TYPE_BLOCK
			blk/head:	0
			blk/node:	args
		]
		s: as series! args/value
		head:	   s/offset
		tail:	   s/tail
		value:	   head
		required?: yes
		ref?:	   no
		ifx?:	   infix?								;-- toggle flag to skip fetching left operand
		arg-cnt:   0
		ref-cnt:   1
		loc-cnt:   0
		sym-cnt:   0
		xcode:	   0									;;@@ should not be needed!
		
		either function? [
			ctx: GET_CTX(fun)
			nctx: fun/ctx
		][
			xcode: native/code
			ctx: as red-context! blk - 1
			assert TYPE_OF(ctx) = TYPE_CONTEXT
			s: GET_CTX_SERIES(ctx)
			nctx: s/node
			if value < tail [
				int: as red-integer! tail - 1
				if TYPE_OF(int) = TYPE_INTEGER [
					loop int/value [push -1]			;-- fill space on native stack for refs array
					ref-array: system/stack/top
				]
			]
		]
		;====== Required arguments fetching ======
		while [value < tail][
			switch TYPE_OF(value) [
				TYPE_TYPESET [
					if value/header and flag-fetch-mode <> FETCH_SET_WORD [
						either required? [
							either all [pc >= end apply?][none/push][
								bits: (as byte-ptr! value) + 4
								BS_TEST_BIT(bits TYPE_UNSET set?)

								either all [
									set?					;-- if unset! is accepted
									pc >= end				;-- if no more values to fetch
									value/header and flag-fetch-mode = FETCH_LIT_WORD
								][
									unset/push 				;-- then, supply an unset argument
								][
									either ifx? [ifx?: no][fetch-arg] ;-- left operand already evaluated, skip the 1st argument
									arg:  stack/top - 1
									type: TYPE_OF(arg)
									BS_TEST_BIT(bits type set?)
									unless set? [fire [TO_ERROR(script expect-arg) fname datatype/push type get-spec-word]]
								]
							]
							arg-cnt: arg-cnt + 1
						][
							if function? [none/push]
							if all [mode = MODE_APPLY path = null][fetch-arg stack/pop 1]
						]
						sym-cnt: sym-cnt + 1
					]
				]
				TYPE_REFINEMENT [
					required?: either all [apply? path = null][
						either any [pc >= end some?][
							if function? [logic/push false]
							pc >= end
						][
							fetch-arg
							arg:  stack/top - 1
							type: TYPE_OF(arg)
							if type <> TYPE_LOGIC [fire [TO_ERROR(script expect-arg) fname datatype/push type get-spec-word]]
							bool: as red-logic! arg
							unless function? [
								if bool/value [ref-array/ref-cnt: arg-cnt]
								stack/pop 1
								ref-cnt: ref-cnt + 1
							]
							bool/value
						]
					][
						if function? [logic/push false]
						no
					]
					ref?: yes
					sym-cnt: sym-cnt + 1
				]
				TYPE_INTEGER [loc-cnt: integer/get value] ;-- get local words count
				TYPE_VECTOR  [0]						;-- do nothing
				default		 [assert false]				;-- trap it in case cache is corrupted 
			]
			value: value + 1
		]
		;====== Optional arguments fetching ======
		if any [path <> null some?][
			path-end: either all [some? path = null][
				ref-pos: pc - 1
				end
			][
				fname: as red-word! ref-pos
				assert path <> null
				block/rs-tail as red-block! path
			]
			exp-type: either some? [TYPE_REFINEMENT][TYPE_WORD]
			
			if ref-pos + 1 < path-end [					;-- test if refinements are following the function
				ref: either all [some? path = null][as red-word! pc][as red-word! ref-pos + 1]
				
				while [ref < as red-word! path-end][
					get?: TYPE_OF(ref) = TYPE_GET_WORD
					if all [TYPE_OF(ref) <> exp-type not get?][
						unless ref? [break]
						fire [TO_ERROR(script bad-refine) ref]
					]
					if all [some? path = null][pc: pc + 1]
					
					t?: case [
						all [path <> null not get?][true]
						some? [
							either pc >= end [false][
								pc: eval-expression pc end code infix? yes no
								stack/pop 1
								logic/rs-true? stack/top on ref
							]
						]
						get?  [logic/rs-true? as red-value! _context/get ref on ref]
						true  [true]
					]
					index: case [
						ref/ctx = nctx [ref/index]
						get?		   [_context/find-word ctx ref/symbol no]
						true		   [_context/bind-word ctx ref]
					]
					value: head + index
					if any [
						index < 0
						all [value < tail TYPE_OF(value) <> TYPE_REFINEMENT]
						value >= tail					;-- when invoking a local word as refinement (#5584)
					][fire [TO_ERROR(script no-refine) fname ref]]
					value: value + 1
					sym-cnt: index + 1

					either function? [
						bool: as red-logic! stack/arguments + index
						assert TYPE_OF(bool) = TYPE_LOGIC
						if bool/value [fire [TO_ERROR(script dup-refine) path]]
						bool/value: t?
						arg: as red-value! bool + 1
						saved: stack/top
					][
						if t? [
							ref-slot: as red-refinement! value - 1
							idx: ref-slot/index
							if ref-array/idx <> -1 [fire [TO_ERROR(script dup-refine) path]]
							ref-array/idx: arg-cnt
						]
					]
					while [
						all [
							value < tail
							TYPE_OF(value) = TYPE_TYPESET
							value/header and flag-fetch-mode <> FETCH_SET_WORD
						]
					][
						either all [safer? not t?][pc: pc + 1][
							fetch-arg
							either t? [					;-- refinement set
								new:  stack/top - 1
								type: TYPE_OF(new)
								bits: (as byte-ptr! value) + 4
								BS_TEST_BIT(bits type set?)
								unless set? [fire [TO_ERROR(script expect-arg) fname datatype/push type get-spec-word]]
								if function? [
									copy-cell new arg
									arg: arg + 1
									stack/pop 1
								]
								arg-cnt: arg-cnt + 1
							][							;-- refinement evaluated to a falsy value
								stack/pop 1
							]
							sym-cnt: sym-cnt + 1
						]
						value: value + 1
					]
					if function? [stack/top: saved]		;-- clear up all temporary stack slots
					ref: either all [some? path = null][as red-word! pc][ref + 1]
				]
			]
		]
		;====== End of arguments fetching ======
		if tracing? [
			if infix? [native: as red-native! _context/get as red-word! ref-pos]
			pc-pos: either apply? [null][pc]
			fire-event EVT_CALL code pc-pos call-pos as red-value! native
		]
		either function? [
			if loc-cnt > 0 [assert not routine?	_function/init-locals loc-cnt]
		][
			if ref-array <> null [system/stack/top: ref-array] ;-- reset native stack to our custom arguments frame
			if native? [push no]						;-- avoid 2nd type-checking for natives.
			calln: as function! [] xcode				;-- direct call for actions/natives
			calln
		]
		pc
	]
		
	eval-code: func [
		value	[red-value!]
		pc		[red-value!]
		end		[red-value!]
		code	[red-block!]
		sub?	[logic!]
		path	[red-path!]
		slot 	[red-value!]
		parent	[red-value!]
		mode	[fetch-args-mode!]
		infix?	[logic!]
		return: [red-value!]
		/local
			caller[red-native!]
			pos	  [red-value!]
			name  [red-word!]
			obj   [red-object!]
			fun	  [red-function!]
			int	  [red-integer!]
			s	  [series!]
			ctx	  [node!]
	][
		pos: either mode >= MODE_APPLY [slot][pc - 1]
		name: as red-word! either null? slot [pos][slot]
		if tracing? [
			if infix? [stack/top: stack/top + 1]
			fire-event EVT_OPEN code pc pos as red-value! name
			if infix? [stack/top: stack/top - 1]
		]
		if TYPE_OF(name) <> TYPE_WORD [name: words/_anon]
		caller: as red-native! either infix? [value][stack/push value]			;-- prevent word's value slot to be corrupted #2199
		
		switch TYPE_OF(value) [
			TYPE_ACTION 
			TYPE_NATIVE [
				#if debug? = yes [if verbose > 0 [log "pushing action/native frame"]]
				stack/mark-interp-native name
				assert any [code = null TYPE_OF(code) = TYPE_BLOCK TYPE_OF(code) = TYPE_PAREN TYPE_OF(code) = TYPE_HASH]
				pc: eval-arguments caller pc end code path slot mode infix? ;-- fetch args and exec
				either sub? [stack/unwind][stack/unwind-last]
				#if debug? = yes [
					if verbose > 0 [
						value: stack/get-top
						print-line ["eval: action/native return type: " TYPE_OF(value)]
					]
				]
			]
			TYPE_ROUTINE [
				#if debug? = yes [if verbose > 0 [log "pushing routine frame"]]
				stack/mark-interp-native name
				pc: eval-arguments caller pc end code path slot mode infix?
				exec-routine as red-routine! caller
				either sub? [stack/unwind][stack/unwind-last]
				#if debug? = yes [
					if verbose > 0 [
						value: stack/get-top
						print-line ["eval: routine return type: " TYPE_OF(value)]
					]
				]
			]
			TYPE_FUNCTION [
				#if debug? = yes [if verbose > 0 [log "pushing function frame"]]
				obj: as red-object! parent
				ctx: either all [
					parent <> null
					TYPE_OF(parent) = TYPE_OBJECT
					obj/ctx <> global-ctx
				][
					obj/ctx
				][
					fun: as red-function! value
					s: as series! fun/more/value
					int: as red-integer! s/offset + 4
					either TYPE_OF(int) = TYPE_INTEGER [
						as node! int/value
					][
						name/ctx						;-- get a context from calling name
					]
				]
				stack/mark-interp-func name
				pc: eval-arguments as red-native! value pc end code path slot mode infix?
				call as red-function! caller ctx pos CB_INTERPRETER
				either sub? [stack/unwind][stack/unwind-last]
				#if debug? = yes [
					if verbose > 0 [
						value: stack/get-top
						print-line ["eval: function return type: " TYPE_OF(value)]
					]
				]
			]
		]
		if tracing? [fire-event EVT_RETURN code pc pos stack/get-top]
		
		unless infix? [
			stack/pop 1										;-- slide down the returned value
			copy-cell stack/top stack/top - 1				;-- replacing the saved value slot
		]
		pc
	]
	
	eval-expression: func [
		pc		  [red-value!]
		end	  	  [red-value!]
		code	  [red-block!]
		prefix?	  [logic!]								;-- TRUE => don't check for infix
		sub?	  [logic!]
		passive?  [logic!]
		return:   [red-value!]
		/local
			real   [red-function! value]				;-- op! but uses function! (3 nodes) for better GC stack scanning support
			next   [red-word!]
			ctx	   [red-context!]
			value  [red-value!]
			pos    [red-value!]
			start  [red-value!]
			prev   [red-value!]
			w	   [red-word!]
			op	   [red-op!]
			s	   [series!]
			sym	   [integer!]
			infix? [logic!]
			top?   [logic!]
			check-infix [subroutine!]
	][
		#if debug? = yes [if verbose > 0 [print-line ["eval: fetching value of type " TYPE_OF(pc)]]]
		
		infix?: no
		start: pc
		top?: not sub?
		prev: stack/top
		
		if tracing? [fire-event EVT_FETCH code pc pc pc]
		
		switch TYPE_OF(pc) [
			TYPE_PAREN [
				stack/mark-interp-native words/_body
				eval as red-block! pc yes
				either sub? [stack/unwind][stack/unwind-last]
				pc: pc + 1
				if tracing? [value: stack/arguments]
			]
			TYPE_SET_WORD [
				stack/mark-interp-native as red-word! pc ;@@ ~set
				word/push as red-word! pc
				if tracing? [fire-event EVT_PUSH code pc pc pc]
				pos: pc
				pc: pc + 1
				if pc >= end [fire [TO_ERROR(script need-value) pc - 1]]
				pc: eval-expression pc end code no yes no
				if tracing? [
					value: stack/get-top
					fire-event EVT_SET code pc pos value
				]
				word/set
				either sub? [stack/unwind][stack/unwind-last]
				#if debug? = yes [
					if verbose > 0 [
						value: stack/arguments
						print-line ["eval: set-word return type: " TYPE_OF(value)]
					]
				]
			]
			TYPE_SET_PATH [
				value: pc
				if tracing? [fire-event EVT_PUSH code pc pc pc]
				pc: pc + 1
				if pc >= end [fire [TO_ERROR(script need-value) value]]
				stack/mark-interp-native words/_set-path
				pc: eval-expression pc end code no yes no	;-- yes: push value on top of stack
				if tracing? [fire-event EVT_SET code pc value stack/get-top]
				pc: eval-path value pc end code yes no sub? no
				either sub? [stack/unwind][stack/unwind-last]
				if tracing? [value: stack/arguments]
			]
			TYPE_GET_WORD [
				value: _context/get as red-word! pc
				value: either sub? [
					stack/push value					;-- nested expression: push value
				][
					stack/push-last value				;-- root expression: return value
				]
				if tracing? [fire-event EVT_PUSH code pc pc value]
				pc: pc + 1
			]
			TYPE_LIT_WORD [
				either sub? [
					w: word/push as red-word! pc			;-- nested expression: push value
				][
					w: as red-word! stack/push-last pc		;-- root expression: return value
				]
				w/header: TYPE_WORD						;-- coerce it to a word!
				if tracing? [
					value: as red-value! w
					fire-event EVT_PUSH code pc pc value
				]
				pc: pc + 1
			]
			TYPE_WORD [
				#if debug? = yes [
					if verbose > 0 [
						print "eval: '"
						print-symbol as red-word! pc
						print lf
					]
				]
				value: _context/get as red-word! pc
				pc: pc + 1
				
				switch TYPE_OF(value) [
					TYPE_UNSET	  [fire [TO_ERROR(script no-value) pc - 1]]
					TYPE_LIT_WORD [
						if tracing? [fire-event EVT_PUSH code pc pc - 1 value]
						word/push as red-word! value	;-- push lit-word! on stack
					]
					TYPE_ACTION							;@@ replace with TYPE_ANY_FUNCTION
					TYPE_NATIVE
					TYPE_ROUTINE
					TYPE_FUNCTION [
						pc: eval-code value pc end code sub? null null value MODE_FETCH no
						if tracing? [value: stack/arguments]
					]
					TYPE_OP [
						fire [TO_ERROR(script no-op-arg) pc - 1]
					]
					default [
						if tracing? [fire-event EVT_PUSH code pc - 1 pc - 1 value]
						#if debug? = yes [if verbose > 0 [log "getting word value"]]
						value: either sub? [
							stack/push value			;-- nested expression: push value
						][
							stack/set-last value		;-- root expression: return value
						]
						#if debug? = yes [
							if verbose > 0 [
								value: stack/arguments
								print-line ["eval: word return type: " TYPE_OF(value)]
							]
						]
					]
				]
			]
			TYPE_PATH [
				value: pc
				pc: pc + 1
				pc: eval-path value pc end code no no sub? no
				if tracing? [
					value: either sub? [stack/get-top][stack/arguments]
					fire-event EVT_PUSH code pc pc value
				]
			]
			TYPE_GET_PATH [
				value: pc
				pc: pc + 1
				pc: eval-path value pc end code no yes sub? no
				if tracing? [
					fire-event EVT_PUSH code value value stack/arguments
					value: stack/arguments
				]
			]
			TYPE_LIT_PATH [
				value: either sub? [stack/push pc][stack/push-last pc]
				value/header: TYPE_PATH
				value/data3: 0							;-- ensures args field is null
				if tracing? [fire-event EVT_PUSH code pc pc - 1 value]
				pc: pc + 1
			]
			TYPE_OP [
				--NOT_IMPLEMENTED--						;-- op used in prefix mode
			]
			TYPE_ACTION									;@@ replace with TYPE_ANY_FUNCTION
			TYPE_NATIVE
			TYPE_ROUTINE
			TYPE_FUNCTION [
				either passive? [
					value: either sub? [
						stack/push pc					;-- nested expression: push value
					][
						stack/push-last pc				;-- root expression: return value
					]
					if tracing? [fire-event EVT_PUSH code pc pc value]
					pc: pc + 1
				][
					value: pc + 1
					if value >= end [value: end]
					pc: eval-code pc value end code sub? null null null MODE_FETCH no
					if tracing? [value: stack/arguments]
				]
			]
			TYPE_ISSUE [
				value: pc + 1
				if all [
					value < end
					TYPE_OF(value) = TYPE_BLOCK
				][
					w: as red-word! pc
					sym: symbol/resolve w/symbol
					
					if any [
						sym = words/system
						sym = words/system-global
					][
						fire [TO_ERROR(internal red-system)]
					]
				]
				value: either sub? [
					stack/push pc						;-- nested expression: push value
				][
					stack/push-last pc					;-- root expression: return value
				]
				if tracing? [fire-event EVT_PUSH code pc pc value]
				pc: pc + 1
			]
			default [
				value: either sub? [
					stack/push pc						;-- nested expression: push value
				][
					stack/push-last pc					;-- root expression: return value
				]
				if tracing? [fire-event EVT_PUSH code pc pc value]
				pc: pc + 1
			]
		]
		check-infix: [
			infix?: no
			next: as red-word! pc
			if all [next < end TYPE_OF(next) = TYPE_WORD][
				ctx: TO_CTX(next/ctx)
				if ctx/values <> null [
					op: as red-op! _context/get next
					if TYPE_OF(op) = TYPE_OP [
						#if debug? = yes [if verbose > 0 [print "eval: '" print-symbol as red-word! pc print-line " (infix)"]]
						if tracing? [fire-event EVT_FETCH code pc pc pc]
						stack/top: prev
						infix?: yes
						copy-cell as red-value! op as red-value! real
						set-type as red-value! real GET_OP_SUBTYPE(op)
						pc: eval-code as red-value! real pc + 1 end code sub? null as red-value! next null MODE_FETCH yes
						if tracing? [value: either sub? [stack/get-top][stack/arguments]]
					]
				]
			]
		]
		unless prefix? [until [check-infix not infix?]]
		
		if all [tracing? top?][fire-event EVT_EXPR code pc start value]
		pc
	]
	
	eval-single: func [
		value	[red-value!]
		return: [integer!]								;-- return index of next expression
		/local
			blk	 [red-block!]
			s	 [series!]
			node [node!]
	][
		blk: as red-block! value
		s: GET_BUFFER(blk)
		if s/offset + blk/head = s/tail [
			unset/push-last
			return blk/head
		]
		node: blk/node									;-- save node pointer as slot will be overwritten
		value: eval-next blk s/offset + blk/head s/tail no
		
		s: as series! node/value						;-- refresh buffer pointer
		assert all [s/offset <= value value <= s/tail]
		(as-integer value - s/offset) >> 4
	]

	eval-next: func [
		code	[red-block!]
		value	[red-value!]
		tail	[red-value!]
		sub?	[logic!]
		return: [red-value!]							;-- return start of next expression
	][
		stack/mark-interp-native words/_body			;-- outer stack frame
		value: eval-expression value tail code no sub? no
		either sub? [stack/unwind][stack/unwind-last]
		value
	]
	
	eval: func [
		code   [red-block!]
		chain? [logic!]									;-- chain it with previous stack frame
		/local
			value head tail arg [red-value!]
			saved [red-block! value]
	][
		head: block/rs-head code
		tail: block/rs-tail code
		copy-cell as red-value! near as red-value! saved

		stack/mark-eval words/_body						;-- outer stack frame
		if tracing? [fire-event EVT_ENTER code head null null]
		either head = tail [
			arg: stack/arguments
			arg/header: TYPE_UNSET
		][
			copy-cell as red-value! code as red-value! near ;-- initialize near cell
			value: head
			
			while [value < tail][
				#if debug? = yes [if verbose > 0 [log "root loop..."]]
				near/head: (as-integer value - head) >> 4 + code/head
				value: eval-expression value tail code no no no
				if value + 1 <= tail [stack/reset]
			]
		]
		if tracing? [fire-event EVT_EXIT code tail null stack/arguments]
		copy-cell as red-value! saved as red-value! near
		either chain? [stack/unwind-last][stack/unwind]
	]
	
	init: does [
		trace-fun: as red-function! ALLOC_TAIL(root)	;-- keep the tracing func reachable by the GC marker
		near/header: TYPE_UNSET
	]
]
