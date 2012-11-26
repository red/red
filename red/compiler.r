REBOL [
	Title:   "Red compiler"
	Author:  "Nenad Rakocevic"
	File: 	 %compiler.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

do %../red-system/compiler.r

red: context [
	verbose:  	  0										;-- logs verbosity level
	job: 		  none									;-- reference the current job object	
	script:		  none
	main-path:	  none
	runtime-path: %runtime/
	nl: 		  newline
	symbols:	  make hash! 1000
	ctx-stack:	  [gctx]
	lexer: 		  do bind load %lexer.r 'self
	extracts:	  do bind load %utils/extractor.r 'self	;-- @@ to be removed once we get redbin loader.
	sys-global:   make block! 1
	
	pc: 		  none
	locals:		  none
	locals-stack: make block! 32
	output:		  make block! 100
	sym-table:	  make block! 1000
	literals:	  make block! 1000
	declarations: make block! 1000
	last-type:	  none
	return-def:   to-set-word 'return					;-- return: keyword
	s-counter:	  0										;-- series suffix counter
	depth:		  0										;-- expression nesting level counter

	unboxed-set:  [integer! char! float! float32! logic!]
	block-set:	  [block! paren! path! set-path! lit-path!]
	string-set:	  [string! binary!]
	series-set:	  union block-set string-set
	
	actions: 	  make block! 100
	op-actions:	  make block! 20
	keywords: 	  make block! 10
	
	actions-prefix: to path! 'actions
	natives-prefix: to path! 'natives
	
	intrinsics:   [
		if unless either any all while until loop repeat
		foreach forall break halt func function
	]

	functions: make hash! [
	;---name--type--arity----------spec----------------------------refs--
		make [action! 2 [type [datatype! word!] spec [any-type!]] #[none]]	;-- must be pre-defined
	]
	
	make-keywords: does [
		foreach [name spec] functions [
			if spec/1 = 'intrinsic! [
				repend keywords [name reduce [to word! join "comp-" name]]
			]
		]
		bind keywords self
	]

	set-last-none: does [copy [stack/reset none/push-last]]	;-- copy required for R/S line counting injection

	--not-implemented--: does [print "Feature not yet implemented!" halt]
	
	quit-on-error: does [
		clean-up
		if system/options/args [quit/return 1]
		halt
	]

	throw-error: func [err [word! string! block!]][
		print [
			"*** Compilation Error:"
			either word? err [
				join uppercase/part mold err 1 " error"
			][reform err]
			"^/*** in file:" mold script
			;either locals [join "^/*** in function: " func-name][""]
		]
		if pc [
			print [
				;"*** at line:" calc-line lf
				"*** near:" mold copy/part pc 8
			]
		]
		quit-on-error
	]
	
	any-function?: func [value [word!]][
		find [native! action! op! function! routine!] value
	]
	
	literal?: func [expr][
		find [
			char!
			integer!
			tuple!
			decimal!
			refinement!
			lit-word!
		] type?/word expr
	]
	
	unicode-char?: func [value][
		all [issue? value value/1 = #"'"]
	]
	
	insert-lf: func [pos][
		new-line skip tail output pos yes
	]
	
	emit: func [value][
		either block? value [append output value][append/only output value]
	]
		
	emit-src-comment: func [pos [block! paren!] /local cmt][
		cmt: trim/lines mold/only/flat clean-lf-deep copy/deep/part pos offset? pos pc
		if 50 < length? cmt [cmt: append copy/part cmt 50 "..."]
		emit reduce [
			'------------| (cmt)
		]
	]
	
	emit-push-word: func [name [word!]][	
		emit 'word/push
		emit decorate-symbol name
		insert-lf -2
	]
	
	emit-get-word: func [name [word!]][
		emit 'word/get
		emit decorate-symbol name
		insert-lf -2
	]
	
	emit-open-frame: func [name [word!]][
		emit 'stack/mark
		emit decorate-symbol name
		insert-lf -2
	]
	
	emit-close-frame: does [
		emit 'stack/unwind
		insert-lf -1
	]
	
	emit-action: func [name [word!] /with options [block!]][
		emit join actions-prefix to word! join name #"*"
		insert-lf either with [
			emit options
			-1 - length? options
		][
			-1
		]
	]
	
	emit-native: func [name [word!] /with options [block!]][
		emit join natives-prefix to word! join name #"*"
		insert-lf either with [
			emit options
			-1 - length? options
		][
			-1
		]
	]
	
	get-counter: does [s-counter: s-counter + 1]
	
	clean-lf-deep: func [blk [block! paren!] /local pos][
		blk: copy/deep blk
		parse blk rule: [
			pos: (new-line/all pos off)
			into rule | skip
		]
		blk
	]

	clean-lf-flag: func [name [word! lit-word! set-word! get-word! refinement!]][
		mold/flat to word! name
	]
	
	decorate-symbol: func [name [word!]][
		to word! join "~" clean-lf-flag name
	]
	
	decorate-func: func [name [word!]][
		to word! join "f_" clean-lf-flag name
	]
	
	decorate-series-var: func [name [word!]][
		to word! join name get-counter
	]
	
	declare-variable: func [name [string!] /init value /local var set-var][
		set-var: to set-word! var: to word! name

		unless find declarations set-var [
			repend declarations [set-var any [value 0]]	;-- declare variable at root level
			new-line skip tail declarations -2 yes
		]
		reduce [var set-var]
	]
	
	add-symbol: func [name [word!] /local sym id][
		unless find symbols name [
			sym: decorate-symbol name
			id: 1 + ((length? symbols) / 2)
			repend symbols [name reduce [sym id]]
			repend sym-table [
				to set-word! sym 'word/load mold name
			]
			new-line skip tail sym-table -3 on
		]
	]
	
	get-symbol-id: func [name [word!]][
		second select symbols name
	]
	
	push-locals: func [symbols [block!]][
		append/only locals-stack symbols
	]

	pop-locals: does [
		also
			last locals-stack
			remove back tail locals-stack
	]
	
	infix?: func [pos [block! paren!] /local specs][
		all [
			not tail? pos
			word? pos/1
			specs: select functions pos/1
			'op! = specs/1
		]
	]
	
	check-spec: func [spec [block!] /local symbols value pos stop locals][
		symbols: make block! length? spec
		locals:  0
		
		unless parse spec [
			opt string!
			any [
				pos: [
					word! opt block! opt string!
					| lit-word!   	 opt string!
					| get-word! 	 opt string!
					| refinement!	 opt string!
				] (append symbols to word! pos/1)
			]
			opt [
				pos: set-word! (if pos/1 <> return-def [stop: [end skip]]) stop
				pos: block! opt string!
			]
		][
			throw-error ["invalid function spec block:" pos]
		]
		if pos: find/tail spec /local [
			parse pos [any [word! (locals: locals + 1) | skip]]
		]
		reduce [symbols locals]
	]
	
	make-refs-table: func [spec [block!] /local mark pos arity list ref args][
		arity: 0
		parse spec [
			any [
				word! (arity: arity + 1)
				| mark: refinement! (pos: mark) break
				| skip
			]
		]
		if all [pos pos/1 <> /local][
			list: make block! 8
			ref: 0
			parse pos [
				some [
					pos: refinement! opt string! (
						ref: ref + 1
						if pos/1 = /local [return reduce [list arity]]
						repend list [pos/1 ref 0]
						args: 0
					)
					| word! opt block! opt string! (
						change back tail list args: args + 1
					)
					| set-word! break
				]
			]
		]
		reduce [list arity]
	]
	
	add-function: func [name [word!] spec [block!] /local refs arity][
		set [refs arity] make-refs-table spec
		repend functions [name reduce ['function! arity spec refs]]
	]
	
	fetch-functions: func [pos [block!] /local name type spec refs arity][
		name: to word! pos/1
		if find functions name [exit]					;-- mainly intended for 'make (hardcoded)

		switch type: pos/3 [
			native! [if find intrinsics name [type: 'intrinsic!]]
			action! [append actions name]
			op!     [repend op-actions [name to word! pos/4]]
		]
		spec: either pos/3 = 'op! [
			third select functions to word! pos/4
		][
			clean-lf-deep pos/4/1
		]
		set [refs arity] make-refs-table spec
		repend functions [name reduce [type arity spec refs]]
	]
	
	emit-block: func [blk [block!] /sub level /local name item value word action type][
		unless sub [
			emit-open-frame 'append
			emit to set-word! name: decorate-series-var 'blk
			emit 'block/push*
			emit max 1 length? blk
			insert-lf -3
		]
		level: 0
		
		forall blk [
			item: blk/1
			either any-block? item [
				type: either all [path? item get-word? item/1]['get-path][type? item]
				
				emit-open-frame 'append
				emit to lit-path! reduce [to word! form type 'push*]
				emit max 1 length? item
				insert-lf -2
				
				level: level + 1
				emit-block/sub to block! item level
				level: level - 1
				
				emit-close-frame
				emit 'block/append*
				insert-lf -1
				emit 'stack/keep						;-- reset stack, but keep block as last value
				insert-lf -1
			][
				if item = #get-definition [				;-- temporary directive
					value: select extracts/definitions blk/2
					change/only/part blk value 2
					item: blk/1
				]
				action: 'push
				value: case [
					unicode-char? item [
						value: item
						item: #"_"						;-- placeholder just to pass the char! type to item
						to integer! next value
					]
					any-word? item [
						add-symbol word: to word! clean-lf-flag item
						decorate-symbol word
					]
					string? item [
						emit compose [tmp: string/load (item)]
						insert-lf -3
						new-line back tail output off
						'tmp
					]
					'else [
						item
					]
				]
				emit load rejoin [form type? :item slash action]
				emit value
				insert-lf -2
				
				emit 'block/append*
				insert-lf -1
				unless tail? next blk [
					emit 'stack/keep					;-- reset stack, but keep block as last value
					insert-lf -1
				]
			]
		]
		unless sub [emit-close-frame]
		name
	]
	
	redirect-to-literals: func [body [block!] /local saved][
		saved: output
		output: literals
		also
			do body
			output: saved
	]
	
	comp-literal: func [root? [logic!] /local value char? name][
		value: pc/1
		either any [
			char?: unicode-char? value
			literal? value
		][
			if root? [
				emit 'stack/reset						;-- reset top to arguments base
				insert-lf -1
			]
			either char? [
				emit [char/push]
				emit to integer! next value
			][
				emit load rejoin [form type? value slash 'push]
				emit load mold value
			]
			insert-lf -2
			
			if root? [
				emit 'stack/keep						;-- drop root level last value
				insert-lf -1
			]
		][
			switch/default type?/word value [
				block!	[
					name: redirect-to-literals [emit-block value]
					emit 'block/push
					emit name
					insert-lf -2
				]
				paren!	[
					name: redirect-to-literals [emit-block to block! value]
					emit 'paren/push
					emit name
					insert-lf -2
				]
				path!	[
					name: redirect-to-literals [emit-block to block! value]
					emit 'path/push
					emit name
					insert-lf -2
				]
				string!	[
					redirect-to-literals [
						emit to set-word! name: decorate-series-var 'str
						emit [string/load]
						emit value
						insert-lf -3
					]	
					emit 'string/push
					emit name
					insert-lf -2
				]
				file!	[]
				url!	[]
				binary!	[]
				issue!	[]
			][
				throw-error ["comp-literal: unsupported type" mold value]
			]
		]
		pc: next pc
	]
		
	comp-boolean-expressions: func [type [word!] test [block!] /local list body][
		list: back tail comp-chunked-block
		
		if empty? head list [
			emit set-last-none
			insert-lf -1
			exit
		]
		bind test 'body
		
		;-- most nested test first (identical for ANY and ALL)
		body: compose/deep [if logic/false? [(set-last-none)]]
		new-line body yes
		insert body list/1
		
		;-- emit expressions tree from leaf to root
		while [not head? list][
			list: back list
			
			insert/only body 'stack/reset
			new-line body yes
			
			body: reduce test
			new-line body yes
			
			insert body list/1
		]
		emit-open-frame type
		emit body
		emit-close-frame
	]
	
	comp-any: does [
		comp-boolean-expressions 'any ['if 'logic/false? body]
	]
	
	comp-all: does [
		comp-boolean-expressions 'all [
			'either 'logic/false? set-last-none body
		]
	]
		
	comp-if: does [
		emit-open-frame 'if
		comp-expression
		emit [
			if logic/true?
		]
		comp-sub-block									;-- compile TRUE block
		emit-close-frame
	]
	
	comp-unless: does [
		emit-open-frame 'unless
		comp-expression
		emit [
			if logic/false?
		]
		comp-sub-block									;-- compile FALSE block
	]

	comp-either: does [
		emit-open-frame 'either
		comp-expression		
		emit [
			either logic/true?
		]
		comp-sub-block									;-- compile TRUE block
		comp-sub-block									;-- compile FALSE block
		emit-close-frame
	]
	
	comp-loop: has [name set-name][
		depth: depth + 1
		
		set [name set-name] declare-variable join "i" depth
		
		comp-expression									;@@ optimize case for literal counter
		
		emit set-name
		insert-lf -1
		emit [
			integer/get*
			stack/reset
			until
		]
		new-line skip tail output -3 off
		
		comp-sub-block									;-- compile body
		
		repend last output [
			set-name name '- 1
			name '= 0
		]
		new-line skip tail last output -3 on
		new-line skip tail last output -7 on
		depth: depth - 1
	]
	
	comp-until: does [
		emit [
			until
		]
		comp-sub-block									;-- compile body
		append/only last output 'logic/true?
		new-line back tail last output on
	]
	
	comp-while: does [
		emit [
			while
		]
		comp-sub-block									;-- compile condition
		append/only last output 'logic/true?
		new-line back tail last output on
		comp-sub-block									;-- compile body
	]
	
	comp-repeat: has [name cnt set-cnt lim set-lim][
		add-symbol pc/1
		name: decorate-symbol pc/1
		
		depth: depth + 1

		emit 'stack/reset
		insert-lf - 1
		
		pc: next pc
		comp-expression									;-- compile 2nd argument
		
		set [cnt set-cnt] declare-variable join "r" depth		;-- integer counter
		set [lim set-lim] declare-variable join "rlim" depth	;-- counter limit
		emit reduce [									;@@ only integer! argument supported
			set-lim 'integer/get*
			set-cnt 0
		]
		insert-lf -2
		insert-lf -4
		emit 'stack/reset
		insert-lf -1

		emit-open-frame 'repeat
		emit compose/deep [
			while [
				;-- set word 1 + get word
				;-- TBD: set word next get word
				(set-cnt) (cnt) + 1
				_context/set-integer (name) (cnt)
				;-- (get word) < value
				;-- TBD: not tail? get word
				(cnt) <= (lim)
			]
		]
		new-line last output on
		new-line skip tail last output -3 on
		
		comp-sub-block
		emit-close-frame
		depth: depth - 1
	]
		
	comp-foreach: has [word blk name cond][
		either block? pc/1 [
			;TBD: raise error if not a block of words only
			foreach word blk: pc/1 [add-symbol word]
			name: redirect-to-literals [emit-block blk]
		][
			add-symbol word: pc/1
		]
		pc: next pc
		
		comp-expression									;-- compile series argument
		;TBD: check if result is any-series!
		emit 'stack/keep
		insert-lf -2
		
		emit compose either blk [
			cond: compose [natives/foreach-next-block (length? blk)]
			[block/push (name)]								;-- block argument
		][
			cond: compose [natives/foreach-next]
			[word/push (decorate-symbol word)]			;-- word argument
		]
		insert-lf -2
		
		emit-open-frame 'foreach
		emit compose/deep [
			while [(cond)]
		]
		comp-sub-block									;-- compile body
		emit-close-frame
	]
	
	comp-forall: has [word][
		;TBD: check if word argument refers to any-series!
		word: decorate-symbol pc/1
		emit compose [
			word/get  (word)							;-- save series (for resetting on end)
			word/push (word)							;-- word argument
		]
		insert-lf -4
		pc: next pc
		
		emit-open-frame 'forall
		emit copy/deep [								;-- copy/deep required for R/S lines injection
			while [natives/forall-loop]
		]
		comp-sub-block									;-- compile body
		append last output [							;-- inject at tail of body block
			natives/forall-next							;-- move series to next position
		]
		emit [
			natives/forall-end							;-- reset series
			stack/unwind
		]
	]
	
	comp-halt: does [
		emit 'halt
		insert-lf -1
	]
	
	comp-func: has [name spec body symbols init locals locals-nb][
		name: to word! pc/-1
		pc: next pc
		set [spec body] pc
		set [symbols locals-nb] check-spec spec
		add-function name spec
		
		set [spec body] redirect-to-literals [
			reduce [emit-block spec emit-block body]
		]
		
		emit-open-frame 'set
		emit-push-word name
		emit compose [
			_function/push (spec) (body)
		]
		emit 'word/set
		insert-lf -1
		emit-close-frame

		push-locals copy symbols
		
		forall symbols [
			symbols/1: decorate-symbol symbols/1
		]
		
		locals: either empty? symbols [
			symbols
		][
			head insert copy symbols /local
		]
		emit reduce [to set-word! decorate-func name 'func locals]
		insert-lf -3
		
		pc: next pc
		comp-sub-block									;-- compile function's body

		pop-locals
		init: make block! 4 * length? symbols
		
		forall symbols [
			append init to set-word! symbols/1
			new-line back tail init on
			either head? symbols [
				append/only init 'stack/arguments
			][
				repend init [symbols/-1 '+ 1]
			]
		]
		unless zero? locals-nb [
			append init compose [
				_function/init-locals (1 + locals-nb)
			]
		]
		name: decorate-symbol name
		if find symbols name [name: to path! reduce ['exec name]]
		
		append init compose [
			stack/mark (name)			;@@ make a unique name for function's body frame
		]
		append last output [
			stack/unwind
			stack/return-last
		]
		insert last output init
	]
	
	emit-path: func [path [path! set-path!] set? [logic!] /local value][
		value: path/1
		switch type?/word value [
			word! [
				case [
					head? path [
						emit-get-word value
					]
					all [set? tail? next path][
						emit-open-frame 'poke
						emit-path back path
						emit-get-word value
						insert-lf -2
						comp-expression					;-- fetch assigned value
						emit-action 'poke
						emit-close-frame
					]
					'else [
						emit-open-frame 'select
						emit-path back path set?
						emit-get-word value
						insert-lf -2
						emit-action 'select
						emit-close-frame
					]
				]
			]
			get-word! [
				emit-open-frame 'pick
				emit-path back path set?
				emit-get-word to word! value
				insert-lf -2
				emit-action 'pick
				emit-close-frame
			]
			integer! [
				either all [set? tail? next path][
					emit-open-frame 'poke
					emit-path back path set?
					emit compose [integer/push (value)]
					insert-lf -2
					comp-expression					;-- fetch assigned value
					emit-action 'poke
					emit-close-frame
				][					
					emit-open-frame 'pick
					emit-path back path set?
					emit compose [integer/push (value)]
					insert-lf -2
					emit-action 'pick
					emit-close-frame
				]
			]
			paren! [
				--not-implemented--
			]
			string!	[
				--not-implemented--
			]
		]
	]
	
	comp-path: func [/set /local path value emit? get? entry][
		path: copy pc/1
		emit?: yes
		
		forall path [
			switch/default type?/word value: path/1 [
				word! [
					if all [not set not get? entry: find functions value][
						either head? path [
							pc: next pc
							comp-call path entry/2		;-- call function with refinements
						][
							--not-implemented--			;TBD: resolve access path to function
						]
						emit?: no						;-- no further emitted code needed
					]
				]
				get-word! [
					if head? path [
						get?: yes
						change path to word! path/1
					]
				]
				integer! paren! string!	[
					if head? path [path-head-error]
				]
			][
				throw-error ["cannot use" mold type? value "value in path:" pc/1]
			]
		]
		if emit? [
			if set [pc: next pc]						;-- skip set-path to be ready to fetch argument
			emit-path back tail path to logic! set		;-- emit code recursively from tail
			unless set [pc: next pc]
		]
	]
		
	comp-call: func [
		call [word! path!]
		spec [block!]
		/local item name compact? refs ref? cnt pos ctx mark list offset emit-no-ref args
	][
		either spec/1 = 'intrinsic! [
			switch call keywords
		][
			compact?: spec/1 <> 'function!				;-- do not push refinements on stack
			refs: make block! 1							;-- refinements storage in compact mode
			cnt: 0
			
			name: either path? call [call/1][call]
			name: to word! clean-lf-flag name
			emit-open-frame name
			
			loop spec/2 [comp-expression]				;-- fetch arguments
			
			either compact? [
				refs: either spec/4 [
					head insert/dup make block! 8 -1 (length? spec/4) / 3	;-- init with -1
				][
					[]									;-- function with no refinements
				]
				if path? call [
					cnt: spec/2							;-- function base arity
					foreach ref next call [
						unless pos: find/skip spec/4 to refinement! ref 3 [
							throw-error [call/1 "has no refinement called" ref]
						]
						poke refs pos/2 cnt				;-- set refinement's arguments base offset
						loop pos/3 [comp-expression]	;-- fetch refinement arguments
						cnt: cnt + pos/3				;-- increase by nb of arguments
					]
				]
			][											;-- prepare function! stack layout
				emit-no-ref: [
					emit [logic/push false]
					insert-lf -2
					loop args [
						emit 'none/push
						insert-lf -1
					]
				]
				either path? call [
					ctx: copy spec/4					;-- get a new context block
					foreach ref next call [
						unless pos: find/skip spec/4 to refinement! ref 3 [
							throw-error [call/1 "has no refinement called" ref]
						]
						offset: pos/2 + spec/2 + 1
						poke ctx index? pos true		;-- switch refinement to true in context
						unless zero? pos/3 [			;-- process refinement's arguments
							list: make block! 1
							insert/only at ctx offset list ;-- add a adjacent block of code
							loop pos/3 [
								mark: tail output
								comp-expression
								append/only list copy mark
								clear mark
							]
						]
					]
					forall ctx [						;-- push context values on stack
						switch type?/word ctx/1 [
							refinement! [				;-- unused refinement
								args: ctx/3
								do emit-no-ref
							]
							logic! [					;-- used refinement
								emit [logic/push true]
								insert-lf -2
								if block? ctx/2 [
									foreach code ctx/2 [emit code] ;-- emit pre-compiled arguments
								]
							]
						]
					]
				][
					if spec/4 [
						foreach [ref offset args] spec/4 emit-no-ref
					]
				]
			]
			
			switch spec/1 [
				native! 	[emit-native/with name refs]
				action! 	[emit-action/with name refs]
				op!			[]
				function!	[emit decorate-func name insert-lf -1]
			]
			emit-close-frame
		]
	]
	
	comp-func-set: func [name [word!]][
		emit-open-frame 'set
		comp-expression
		emit compose [copy-cell stack/arguments (decorate-symbol name)]
		insert-lf -3
		emit-close-frame
	]
	
	comp-set-word: has [name value][
		name: pc/1
		pc: next pc
		add-symbol name: to word! clean-lf-flag name
		if infix? pc [
			throw-error "invalid use of set-word as operand"
		]
		case [
			pc/1 = 'func [
				comp-func								;-- function definition needs special framing
			]
			all [
				not empty? locals-stack
				find last locals-stack name
			][
				comp-func-set name
			]
			'else [
				emit-open-frame 'set
				emit-push-word name
				comp-expression							;-- fetch a value
				emit 'word/set
				insert-lf -1
				emit-close-frame
			]
		]
	]

	comp-word: func [/literal /final /local name entry][
		name: to word! pc/1
		pc: next pc
		case [
			all [not final name = 'make any-function? pc/1][
				fetch-functions skip pc -2				;-- extract functions definitions
				pc: back pc
				comp-word/final
			]
			all [not literal entry: find functions name][
				comp-call name entry/2
			]
			entry: find symbols name [
				either lit-word? pc/1 [
					emit-push-word name
				][
					either all [
						not empty? locals-stack
						find last locals-stack name
					][
						emit compose [stack/push (decorate-symbol name)]
						insert-lf -2
					][
						emit-get-word name
					]
				]
			]
			'else [
				pc: back pc
				throw-error ["undefined word" pc/1]
			]
		]
	]
	
	search-expr-end: func [pos [block! paren!]][
		if infix? next pos [pos: search-expr-end skip pos 2]
		pos
	]
	
	make-func-prefix: func [name [word!]][
		load rejoin [									;@@ cache results locally
			head remove back tail form functions/:name/1 "s/"
			name #"*"
		]
	]
	
	check-infix-operators: has [name op pos end ops][
		if infix? pc [return false]						;-- infix op already processed,
														;-- or used in prefix mode.
		if infix? next pc [
			pos: pc
			end: search-expr-end pos					;-- recursive search of expression end
			
			ops: make block! 1
			pos: end									;-- start from end of expression
			until [
				op: pos/-1			
				name: any [select op-actions op op]
				insert ops name							;-- remember ops in left-to-right order
				emit-open-frame name
				pos: skip pos -2						;-- process next previous op
				pos = pc								;-- until we reach the beginning of expression
			]
			
			comp-expression/no-infix					;-- fetch first left operand
			pc: next pc
			
			forall ops [
				comp-expression/no-infix				;-- fetch right operand
				emit make-func-prefix ops/1
				insert-lf -1
				emit-close-frame
				unless tail? next ops [pc: next pc]		;-- jump over op word unless last operand
			]
			return true									;-- infix expression processed
		]
		false											;-- not an infix expression
	]
	
	comp-directive: has [file][
		switch/default pc/1 [
			#include [
				unless file? file: pc/2 [
					throw-error ["#include requires a file argument:" pc/2]
				]
				if slash <> pick file 1 [
					file: rejoin [system/options/path main-path file]
				]
				unless exists? file [
					throw-error ["include file not found:" pc/2]
				]
				change/part pc load-source file 2
			]
			#system [
				unless block? pc/2 [
					throw-error "#system requires a block argument"
				]
				emit pc/2
				pc: skip pc 2
			]
			#system-global [
				unless block? pc/2 [
					throw-error "#system-global requires a block argument"
				]
				append sys-global pc/2
				pc: skip pc 2
			]
			#get-definition [							;-- temporary directive
				either value: select extracts/definitions pc/2 [
					change/only/part pc value 2
					comp-expression						;-- continue expression fetching
				][
					pc: next pc
				]
			]
			#load [										;-- temporary directive
				change/part/only pc to do pc/2 pc/3 3 2
				comp-expression							;-- continue expression fetching
			]
		][
			throw-error ["Unknown directive:" pc/1]
		]
	]
	
	comp-expression: func [/no-infix /root /local saved][
		unless no-infix [
			if check-infix-operators [exit]
		]

		if tail? pc [
			pc: back pc
			throw-error "missing argument"
		]
		switch/default type?/word pc/1 [
			issue!		[
				either unicode-char? pc/1 [
					comp-literal to logic! root			;-- special encoding for Unicode char!
				][
					comp-directive
				]
			]
			;-- active datatypes with specific literal form
			set-word!	[comp-set-word]
			word!		[comp-word]
			get-word!	[comp-word/literal]
			paren!		[saved: pc pc: pc/1 comp-block pc: next saved]
			set-path!	[comp-path/set]
			path! 		[comp-path]
		][
			comp-literal to logic! root
		]
		if all [root not tail? pc][
			emit 'stack/reset							;-- clear stack from last root expression result
			insert-lf -1
		]
	]
	
	comp-chunked-block: has [list mark saved][
		list: clear []
		saved: pc
		pc: pc/1										;-- dive in nested code
		mark: tail output
		
		comp-block/with [
			append/only list copy mark
			clear mark
		]
		
		pc: next saved
		list
	]
	
	comp-sub-block: has [mark saved][
		mark: tail output

		saved: pc
		pc: pc/1										;-- dive in nested code
		comp-block
		pc: next saved									;-- step over block in source code				

		change/part/only mark copy/deep mark tail mark	;-- put output code between [...]
		clear next mark									;-- remove code at "above" level
		head insert last output [
			stack/reset
		]
	]
	
	comp-block: func [
		/with body [block!]
		/local expr
	][
		while [not tail? pc][
			expr: pc
			comp-expression/root
			
			if all [verbose > 2 positive? offset? pc expr][probe copy/part expr pc]
			if verbose > 0 [emit-src-comment expr]
			
			if with [do body]
		]
	]
	
	comp-init: does [
		add-symbol 'datatype!
		foreach [name specs] functions [add-symbol name]

		;-- Create datatype! datatype and word
		emit [
			word/push ~datatype!
			datatype/push TYPE_DATATYPE			
			word/set
			stack/reset
		]
	]
	
	comp-red: func [code [block!] /local out ctx pos][
		out: copy/deep [
			Red/System [origin: 'Red]
			
			#include %red.reds
						
			with red [
				exec: context [
				
				]
			]
		]
		output: out/7/3
		
		comp-init
		
		pc: load-source %red/boot.red					;-- compile Red's boot script
		comp-block
		make-keywords									;-- register intrinsics functions
		
		pc: code										;-- compile user code
		pos: tail output
		comp-block
		
		insert output [
			------------| "Main program"
		]
		if verbose = 1 [probe skip pos 2]
		
		insert output declarations
		insert output [
			------------| "Declarations"
		]
		
		insert output literals
		insert output [
			------------| "Literals"
		]
		
		insert output sym-table
		insert output [
			------------| "Symbols"
		]
		
		unless empty? sys-global [
			insert at out 3 sys-global
			new-line at out 3 yes
		]

		output: out
		if verbose > 1 [?? output]
	]
	
	load-source: func [file [file! block!] /local src][
		either file? file [
			script: file
			src: lexer/process read/binary file
		][
			script: 'memory
			src: file
		]
		next src										;-- skip header block
	]
	
	clean-up: does [
		unless empty? locals-stack [
			make error! "locals-stack not empty"		;-- force an "internal error"
		]
		clear symbols
		clear sys-global
		clear output
		clear sym-table
		clear literals
		clear declarations
		clear actions
		clear op-actions
		clear keywords
		clear skip functions 2							;-- keep MAKE definition
		s-counter: 0
		depth:	   0
	]

	compile: func [
		file [file! block!]								;-- source file or block of code
		opts [object!]
		/local time
	][
		verbose: opts/verbosity
		clean-up
		main-path: first split-path file
		
		time: dt [comp-red load-source file]
		reduce [output time]
	]
]

