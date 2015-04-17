REBOL [
	Title:   "Red compiler"
	Author:  "Nenad Rakocevic"
	File: 	 %compiler.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

do-cache %system/compiler.r

red: context [
	verbose:	   0									;-- logs verbosity level
	job: 		   none									;-- reference the current job object	
	script-name:   none
	script-path:   none
	main-path:	   none
	runtime-path:  %runtime/
	include-stk:   make block! 3
	included-list: make block! 20
	needed:		   make block! 4
	symbols:	   make hash! 1000
	globals:	   make hash! 1000						;-- words defined in global context
	aliases: 	   make hash! 100
	contexts:	   make hash! 100						;-- storage for statically compiled contexts
	ctx-stack:	   make block! 8						;-- contexts access path
	lexer: 		   do bind load-cache %lexer.r 'self
	extracts:	   do bind load-cache %utils/extractor.r 'self ;-- @@ to be removed once we get redbin loader.
	sys-global:    make block! 1
	lit-vars: 	   reduce [
		'block	   make hash! 1000
		'string	   make hash! 1000
		'context   make hash! 1000
	]
	 
	pc: 		   none
	locals:		   none
	locals-stack:  make block! 32
	output:		   make block! 100
	sym-table:	   make block! 1000
	literals:	   make block! 1000
	declarations:  make block! 1000
	bodies:		   make block! 1000
	ssa-names: 	   make block! 10						;-- unique names lookup table (SSA form)
	last-type:	   none
	return-def:    to-set-word 'return					;-- return: keyword
	s-counter:	   0									;-- series suffix counter
	depth:		   0									;-- expression nesting level counter
	booting?:	   none									;-- YES: compiling boot script
	no-global?:	   no									;-- YES: put global code in a function
	nl: 		   newline
 
	unboxed-set:   [integer! char! float! float32! logic!]
	block-set:	   [block! paren! path! set-path! lit-path!]	;@@ missing get-path!
	string-set:	   [string! binary!]
	series-set:	   union block-set string-set
	
	actions: 	   make block! 100
	op-actions:	   make block! 20
	keywords: 	   make block! 10
	
	actions-prefix: to path! 'actions
	natives-prefix: to path! 'natives
	
	intrinsics:   [
		if unless either any all while until loop repeat
		foreach forall break func function does has
		exit return switch case routine set get reduce
	]
	
	word-iterators: [repeat foreach forall]				;-- only ones that use word(s) as counter
	
	standard-modules: [
		View		%modules/view/VID.red
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
			"^/*** in file:" mold script-name
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
	
	relative-path?: func [file [file!]][
		not find "/~" first file
	]
	
	process-include-paths: func [code [block!] /local rule file][
		parse code rule: [
			some [
				#include file: (
					script-path: any [script-path main-path]
					if all [script-path relative-path? file/1][
						file/1: clean-path join script-path file/1
					]
				)
				| into rule
				| skip
			]
		]
	]
	
	process-calls: func [code [block!] /global /local rule pos mark][
		parse code rule: [
			some [
				#call pos: (
					mark: tail output
					process-call-directive pos/1 to logic! global
					change/part back pos mark 2
					clear mark
				)
				| into rule
				| skip
			]
		]
	]
	
	preprocess-strings: func [code [block!] /local rule s][  ;-- re-encode strings for Red/System
		parse code rule: [
			any [
				s: string! (lexer/decode-UTF8-string s/1)
				into rule
				| skip
			]
		]
	]
	
	convert-to-block: func [mark [block!]][
		change/part/only mark copy/deep mark tail mark	;-- put code between [...]
		clear next mark									;-- remove code at "upper" level
	]
	
	any-function?: func [value [word!]][
		find [native! action! op! function! routine!] value
	]
	
	scalar?: func [expr][
		find [
			unset!
			none!
			logic!
			datatype!
			char!
			integer!
			tuple!
			decimal!
			refinement!
			issue!
			lit-word!
			word! 
			get-word!
			set-word!
			pair!
		] type?/word :expr
	]
	
	local-word?: func [name [word!]][
		all [not empty? locals-stack find last locals-stack name]
	]
	
	unicode-char?: func [value][
		all [issue? value value/1 = #"'"]
	]
	
	float-special?: func [value][
		all [issue? value value/1 = #"."]
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
	
	get-word-index: func [name [word!] /with c [word!] /local ctx pos list][
		if with [
			ctx: select contexts c
			return (index? find ctx name) - 1
		]
		list: tail ctx-stack
		until [											;-- search backward in parent contexts
			list: back list
			ctx: select contexts list/1
			if pos: find ctx name [
				return (index? pos) - 1					;-- 0-based access in context table
			]
			head? list
		]
		throw-error ["Should not happen: not found context for word: " mold name]
	]
	
	emit-push-word: func [name [any-word!] /local type][
		type: to word! form type? name
		name: to word! :name
		
		either local-word? name [
			emit append to path! type 'push-local
			emit last ctx-stack
			emit get-word-index name
			insert-lf -3
		][
			emit append to path! type 'push
			emit decorate-symbol name
			insert-lf -2
		]
	]
	
	emit-get-word: func [name [word!] /any? /literal /local new][
		either local-word? name [
			emit 'stack/push							;-- local word
		][
			if new: select ssa-names name [name: new]	;@@ add a check for function! type
			emit case [									;-- global word
				literal ['get-word/get]
				any?	['word/get-any]
				'else	['word/get]
			]
		]
		emit decorate-symbol name
		insert-lf -2
	]
	
	emit-load-string: func [buffer [string! file! url!]][
		emit to path! reduce [to word! form type? buffer 'load]
		emit form buffer
		emit 1 + length? buffer							;-- account for terminal zero
		emit 'UTF-8
	]
	
	emit-open-frame: func [name [word!] /local type][
		emit case [
			'function! = all [
				type: find functions name
				first first next type
			]['stack/mark-func]
			name = 'try	  ['stack/mark-try]
			name = 'catch ['stack/mark-catch]
			'else		  ['stack/mark-native]
		]
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
	
	emit-exit-function: does [
		emit [
			stack/unwind-last
			stack/unroll stack/FLAG_FUNCTION
			ctx/values: as node! pop
			exit
		]
		insert-lf -5
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
	
	prefix-global: func [word [word!]][					;@@ to be removed?
		append to path! 'exec word
	]
	
	decorate-type: func [type [word!]][
		to word! join "red-" mold/flat type
	]
	
	decorate-exec-ctx: func [name [word!]][
		append to path! 'exec name
	]
	
	decorate-symbol: func [name [word!] /local pos][
		if pos: find/case/skip aliases name 2 [name: pos/2]
		to word! join "~" clean-lf-flag name
	]
	
	decorate-func: func [name [word!] /strict /local new][
		if all [not strict new: select ssa-names name][name: new]
		to word! join "f_" clean-lf-flag name
	]
	
	decorate-series-var: func [name [word!] /local new list][
		new: to word! join name get-counter
		list: select lit-vars select [blk block str string ctx context] name
		if all [list not find list new][append list new]
		new
	]
	
	declare-variable: func [name [string! word!] /init value /local var set-var][
		set-var: to set-word! var: to word! name

		unless find declarations set-var [
			repend declarations [set-var any [value 0]]	;-- declare variable at root level
			new-line skip tail declarations -2 yes
		]
		reduce [var set-var]
	]
	
	add-symbol: func [name [word!] /local sym id alias][
		unless find/case symbols name [
			if find symbols name [
				if find/case/skip aliases name 2 [exit]
				alias: decorate-series-var name
				repend aliases [name alias]
			]
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
	
	add-global: func [name [word!]][
		unless any [
			local-word? name
			find globals name
		][
			repend globals [name 'unset!]
		]
	]
	
	push-context: func [ctx [block!] /local name][
		append contexts name: decorate-series-var 'ctx
		append/only contexts ctx
		append ctx-stack name
		name
	]
	
	pop-context: does [
		clear back tail ctx-stack
	]
	
	find-contexts: func [name [word!]][
		ctx: tail ctx-stack
		while [not head? ctx][
			ctx: back ctx
			if find select contexts ctx/1 name [return ctx/1]
		]
		none
	]
	
	push-locals: func [symbols [block!]][
		append/only locals-stack symbols
	]

	pop-locals: does [
		also
			last locals-stack
			remove back tail locals-stack
	]
	
	literal-first-arg?: func [spec [block!]][
		parse spec [
			any [
				word! 		(return no)
				| lit-word! (return yes)
				| /local	(return no)
				| skip
			]
		]
		no
	]
	
	infix?: func [pos [block! paren!] /local specs][
		all [
			not tail? pos
			word? pos/1
			specs: select functions pos/1
			'op! = specs/1
			not all [									;-- check if a literal argument is not expected
				word? pos/-1
				specs: select functions pos/-1
				literal-first-arg? specs/3				;-- literal arg needed, disable infix mode
			]
		]
	]
	
	convert-types: func [spec [block!] /local value][
		forall spec [
			if spec/1 = /local [break]					;-- avoid processing local variable
			if all [
				block? value: spec/1
				not find [integer! logic!] value/1 
			][
				value/1: decorate-type either value/1 = 'any-type! ['value!][value/1]
			]
		]
	]
	
	check-invalid-call: func [name [word!]][
		if all [
			find [exit return] name
			empty? locals-stack
		][
			pc: back pc
			throw-error "EXIT or RETURN used outside of a function"
		]
	]
	
	check-redefined: func [name [word!] /local pos][
		if pos: find functions name [
			remove/part pos 2							;-- remove function definition
		]
	]
	
	check-func-name: func [name [word!] /local new pos][
		if find functions name [
			new: to word! append mold/flat name get-counter
			either pos: find ssa-names name [
				pos/2: new
			][
				repend ssa-names [name new]
			]
			name: new
		]
		name
	]
	
	check-spec: func [spec [block!] /local symbols value pos stop locals return?][
		symbols: make block! length? spec
		locals:  0
		
		unless parse spec [
			opt string!
			any [
				pos: /local (append symbols 'local) some [
					pos: word! (
						append symbols to word! pos/1
						locals: locals + 1
					)
					pos: opt block! pos: opt string!
				]
				| set-word! (
					if any [return? pos/1 <> return-def][stop: [end skip]]
					return?: yes						;-- allow only one return: statement
				) stop pos: block! opt string!
				| [
					[word! | lit-word! | get-word!] opt block! opt string!
					| refinement! opt string!
				] (append symbols to word! pos/1)
			]
		][
			throw-error ["invalid function spec block:" mold pos]
		]
		forall spec [
			if all [
				word? spec/1
				find next spec spec/1
			][
				pc: skip pc -2
				throw-error ["duplicate word definition:" spec/1]
			]
		]
		reduce [symbols locals]
	]
	
	make-refs-table: func [spec [block!] /local mark pos arity arg-rule list ref args][
		arity: 0
		arg-rule: [word! | lit-word! | get-word!]
		parse spec [
			any [
				arg-rule (arity: arity + 1)
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
					| arg-rule opt block! opt string! (
						change back tail list args: args + 1	;@@ one argument by refinement max!!
					)
					| set-word! break
				]
			]
		]
		reduce [list arity]
	]
	
	add-function: func [name [word!] spec [block!] /type kind [word!] /local refs arity][
		set [refs arity] make-refs-table spec
		repend functions [name reduce [any [kind 'function!] arity spec refs]]
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
	
	emit-block: func [
		blk [block!] /sub level [integer!] /bind ctx [word!]
		/local name item value word action type
	][
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
			either any-block? :item [
				type: either all [path? item get-word? item/1][
					item/1: to word! item/1 ;this is workaround of missing get-path! in R2
					'get-path
				][type? :item]
				
				emit-open-frame 'append
				emit to lit-path! reduce [to word! form type 'push*]
				emit max 1 length? item
				insert-lf -2
				
				level: level + 1
				either bind [
					emit-block/sub/bind to block! item level ctx
				][
					emit-block/sub to block! item level
				]
				level: level - 1
				
				emit-close-frame
				emit 'block/append*
				insert-lf -1
				emit 'stack/keep						;-- reset stack, but keep block as last value
				insert-lf -1
			][
				if :item = #get-definition [			;-- temporary directive
					value: select extracts/definitions blk/2
					change/only/part blk value 2
					item: blk/1
				]
				action: 'push
				value: case [
					unicode-char? :item [
						value: item
						item: #"_"						;-- placeholder just to pass the char! type to item
						to integer! next value
					]
					any-word? :item [
						add-symbol word: to word! clean-lf-flag item
						value: decorate-symbol word
						either all [bind local-word? to word! :item][
							action: 'push-local
							reduce [ctx get-word-index/with to word! :item ctx]
						][
							value
						]
						
					]
					issue? :item [
						add-symbol word: to word! form item
						decorate-symbol word
					]
					find [string! file! url!] type?/word :item [
						emit [tmp:]
						insert-lf -1
						emit-load-string item
						new-line back tail output off
						'tmp
					]
					find [logic! unset! datatype!] type?/word :item [
						to word! form :item
					]
					pair? :item [
						reduce [item/x item/y]
					]
					none? :item [
						[]								;-- no argument
					]
					'else [
						item
					]
				]
				either float-special? :item [
					emit 'float/push64
					emit-fp-special item
					insert-lf -3
				][
					either decimal? :item [
						emit 'float/push64
						emit-float item
						insert-lf -3
					][
						emit to path! reduce [to word! form type? :item action]
						emit value
						insert-lf -1 - either block? value [length? value][1]
					]
				]
				
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
	
	emit-path: func [path [path! set-path!] set? [logic!] /local value mark][
		value: path/1
		switch type?/word value [
			word! [
				add-symbol value: to word! clean-lf-flag value
				case [
					head? path [
						emit-get-word value
					]
					all [set? tail? next path][
						emit-open-frame 'poke
						emit-open-frame 'find
						emit-path back path set?
						emit-push-word value
						emit-action/with 'find [-1 -1 -1 -1 -1 -1 -1 -1 -1 -1]
						emit-close-frame
						emit [integer/push 2] 
						insert-lf -2
						comp-expression					;-- fetch assigned value
						emit-action 'poke
						emit-close-frame
					]
					'else [
						emit-open-frame 'select
						emit-path back path set?
						emit-push-word value
						insert-lf -2
						emit-action/with 'select [-1 -1 -1 -1 -1 -1 -1 -1]
						emit-close-frame
					]
				]
			]
			get-word! [
				either all [set? tail? next path][
					emit-open-frame 'poke
					emit-path back path set?
					emit-get-word to word! value
					
					emit copy/deep [unless stack/top-type? = TYPE_INTEGER] ;-- choose action at run-time
					insert-lf -4
					
					mark: tail output					;-- SELECT action
					emit [stack/pop 1]					;-- overwrite the get-word on stack top
					insert-lf -2
					emit-open-frame 'find
					emit-path back path set?
					emit-get-word to word! value
					emit-action/with 'find [-1 -1 -1 -1 -1 -1 -1 -1 -1 -1]
					emit-action 'index?
					emit [stack/pop 2]
					insert-lf -2
					emit [integer/push 1]
					insert-lf -2
					emit-action 'add
					emit-close-frame
					convert-to-block mark
					
					comp-expression						;-- fetch assigned value
					emit-action 'poke
					emit-close-frame
				][
					add-symbol 'pick-select
					emit-open-frame 'pick-select
					emit-path back path set?
					emit-get-word to word! value
					
					emit copy/deep [either stack/top-type? = TYPE_INTEGER] ;-- choose action at run-time
					insert-lf -4
					
					mark: tail output					;-- PICK action
					emit-action 'pick
					convert-to-block mark
					
					mark: tail output					;-- SELECT action
					emit-action/with 'select [-1 -1 -1 -1 -1 -1 -1 -1]
					convert-to-block mark
					
					emit-close-frame
				]
			]
			integer! [
				either all [set? tail? next path][
					emit-open-frame 'poke
					emit-path back path set?
					emit compose [integer/push (value)]
					insert-lf -2
					comp-expression						;-- fetch assigned value
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
			string!	[
				--not-implemented--
			]
		]
	]
		
	emit-routine: func [name [word!] spec [block!] /local type cnt offset alter][
		declare-variable/init 'r_arg to paren! [as red-value! 0]
		emit [r_arg: stack/arguments]
		insert-lf -2

		offset: 0
		if all [
			type: select spec return-def
			find [integer! logic!] type/1 
		][
			offset: 1
			append/only output append to path! form get type/1 'box
		]
		if alter: select ssa-names name [name: alter]
		emit name
		cnt: 0

		forall spec [
			if string? spec/1 [
				if tail? remove spec [break]
			]
			if any [spec/1 = /local set-word? spec/1][
				spec: head spec
				break									;-- avoid processing local variable	
			]
			unless block? spec/1 [
				unless block? spec/2 [
					insert/only next spec [red-value!]
				]
				either find [integer! logic!] spec/2/1 [
					append/only output append to path! form get spec/2/1 'get
				][
					emit reduce ['as spec/2/1]
				]
				emit 'r_arg
				unless head? spec [emit reduce ['+ cnt]]
				cnt: cnt + 1
			]
		]
		insert-lf negate cnt * 2 + offset + 1
	]
	
	redirect-to-literals: func [body [block!] /local saved][
		saved: output
		output: literals
		also
			do body
			output: saved
	]

	emit-float: func [value [decimal!] /local bin][
		bin: IEEE-754/to-binary64 value
		emit to integer! copy/part bin 4
		emit to integer! skip bin 4
	]

	emit-fp-special: func [value [issue!]][
		switch next value [
			#INF  [emit to integer! #{7FF00000} emit 0]
			#INF- [emit to integer! #{FFF00000} emit 0]
			#NaN  [emit to integer! #{7FF80000} emit 0]			;-- smallest quiet NaN
			#0-	  [emit to integer! #{80000000} emit 0]
		]
	]
	
	comp-literal: func [root? [logic!] /inactive /local value char? special? name w make-block type][
		value: pc/1
		either any [
			char?: unicode-char? value
			special?: float-special? value
			scalar? :value
		][
			if root? [
				emit 'stack/reset						;-- reset top to arguments base
				insert-lf -1
			]
			case [
				char? [
					emit 'char/push
					emit to integer! next value
					insert-lf -2
				]
				special? [
					emit 'float/push64
					emit-fp-special value
					insert-lf -3
				]
				decimal? :value [
					emit 'float/push64
					emit-float value
					insert-lf -3
				]
				find [refinement! issue! lit-word!] type?/word :value [
					add-symbol w: to word! form value
					type: to word! form type? :value
					if all [lit-word? :value not inactive][type: 'word]
					
					either all [not issue? :value local-word? w][
						emit append to path! type 'push-local
						emit last ctx-stack
						emit get-word-index w
						insert-lf -3
					][
						emit to path! reduce [type 'push]
						emit to path! reduce ['exec decorate-symbol w]
						insert-lf -2
					]
				]
				none? :value [
					emit 'none/push
					insert-lf -1
				]
				any-word? :value [
					add-symbol to word! :value
					emit-push-word :value
				]
				pair? :value [
					emit 'pair/push
					emit reduce [value/1 value/2]
					insert-lf -3
				]
				'else [
					emit to path! reduce [to word! form type? :value 'push]
					emit load mold :value
					insert-lf -2
				]
			]
			if root? [
				emit 'stack/keep						;-- drop root level last value
				insert-lf -1
			]
		][
			make-block: [
				redirect-to-literals [
					value: to block! value
					either empty? ctx-stack [
						emit-block value
					][
						emit-block/bind value last ctx-stack
					]
				]
			]
			switch/default type?/word value [
				block!	[
					name: do make-block
					emit 'block/push
					emit name
					insert-lf -2
				]
				paren!	[
					name: do make-block
					emit 'paren/push
					emit name
					insert-lf -2
				]
				path! set-path!	[
					name: do make-block
					either lit-path? pc/1 [
						emit 'path/push
					][
						emit to path! reduce [to word! form type? pc/1 'push]
					]
					emit name
					insert-lf -2
				]
				string!	file! url! [
					redirect-to-literals [
						emit to set-word! name: decorate-series-var 'str
						insert-lf -1
						emit-load-string value
					]	
					emit to path! reduce [to word! form type? value 'push]
					emit name
					insert-lf -2
				]
				binary!	[]
			][
				throw-error ["comp-literal: unsupported type" mold value]
			]
		]
		pc: next pc
		name
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
		either block? pc/1 [
			comp-boolean-expressions 'any ['if 'logic/false? body]
		][
			emit-open-frame 'any
			comp-expression
			emit-native 'any
			emit-close-frame
		]
	]
	
	comp-all: does [
		either block? pc/1 [
			comp-boolean-expressions 'all [
				'either 'logic/false? set-last-none body
			]
		][
			emit-open-frame 'all
			comp-expression
			emit-native 'all
			emit-close-frame
		]
	]
		
	comp-if: does [
		emit-open-frame 'if
		comp-expression
		emit compose/deep [
			either logic/false? [(set-last-none)]
		]
		comp-sub-block 'if-body							;-- compile TRUE block
		emit-close-frame
	]
	
	comp-unless: does [
		emit-open-frame 'unless
		comp-expression
		emit [
			either logic/false?
		]
		comp-sub-block 'unless-body						;-- compile FALSE block
		append/only output set-last-none
		emit-close-frame
	]

	comp-either: does [
		emit-open-frame 'either
		comp-expression		
		emit [
			either logic/true?
		]
		comp-sub-block 'either-true						;-- compile TRUE block
		comp-sub-block 'either-false					;-- compile FALSE block
		emit-close-frame
	]
	
	comp-loop: has [name set-name mark][
		depth: depth + 1
		
		set [name set-name] declare-variable join "i" depth
		
		comp-expression									;@@ optimize case for literal counter
		
		emit compose [(set-name) integer/get*]
		insert-lf -2
		emit compose/deep [
			either (name) <= 0 [(set-last-none)]
		]
		mark: tail output
		emit [
			until
		]
		new-line skip tail output -3 off
		
		comp-sub-block 'loop-body						;-- compile body
		
		repend last output [
			set-name name '- 1
			name '= 0
		]
		new-line skip tail last output -3 on
		new-line skip tail last output -7 on
		depth: depth - 1
		
		convert-to-block mark
	]
	
	comp-until: does [
		emit [
			until
		]
		comp-sub-block 'until-body						;-- compile body
		append/only last output 'logic/true?
		new-line back tail last output on
	]
	
	comp-while: does [
		emit [
			while
		]
		comp-sub-block 'while-condition					;-- compile condition
		append/only last output 'logic/true?
		new-line back tail last output on
		comp-sub-block 'while-body						;-- compile body
	]
	
	comp-repeat: has [name word cnt set-cnt lim set-lim action][
		add-symbol word: pc/1
		add-global word
		name: decorate-symbol word
		action: either local-word? word [
			'natives/repeat-set							;-- set the value slot on stack
		][
			'_context/set-integer						;-- set the word value in global context
		]
		
		depth: depth + 1

		emit 'stack/reset
		insert-lf -1
		
		pc: next pc
		comp-expression									;-- compile 2nd argument
		
		set [cnt set-cnt] declare-variable join "r" depth		;-- integer counter
		set [lim set-lim] declare-variable join "rlim" depth	;-- counter limit
		emit reduce either local-word? word [					;@@ only integer! argument supported
			[
				set-lim 'natives/repeat-init* name
				set-cnt 0
			]
		][
			[
				set-lim 'integer/get*
				'_context/set-integer name lim
				set-cnt 0
			]
		]
		insert-lf -2
		insert-lf -5
		insert-lf -7
		emit 'stack/reset
		insert-lf -1
		
		emit-open-frame 'repeat
		emit compose/deep [
			while [
				;-- set word 1 + get word
				;-- TBD: set word next get word
				(set-cnt) (cnt) + 1
				;-- (get word) < value
				;-- TBD: not tail? get word
				(cnt) <= (lim)
			]
		]
		new-line last output on
		new-line skip tail last output -3 on
		new-line skip tail last output -6 on
		
		comp-sub-block 'repeat-body
		insert last output reduce [action name cnt]
		new-line last output on
		emit-close-frame
		depth: depth - 1
	]
		
	comp-foreach: has [word blk name cond ctx][
		either block? pc/1 [
			;TBD: raise error if not a block of words only
			foreach word blk: pc/1 [
				add-symbol word
				add-global word
			]
			name: redirect-to-literals [
				either ctx: find-contexts to word! blk/1 [
					emit-block/bind blk ctx
				][
					emit-block blk
				]
			]
		][
			add-symbol word: pc/1
			add-global word
		]
		pc: next pc
		
		comp-expression									;-- compile series argument
		;TBD: check if result is any-series!
		emit 'stack/keep
		insert-lf -1
		
		either blk [
			cond: compose [natives/foreach-next-block (length? blk)]
			emit compose [block/push (name)]			;-- block argument
		][
			cond: compose [natives/foreach-next]
			emit-push-word word							;-- word argument
		]
		insert-lf -2
		
		emit-open-frame 'foreach
		emit compose/deep [
			while [(cond)]
		]
		comp-sub-block 'foreach-body					;-- compile body
		emit-close-frame
	]
	
	comp-forall: has [word][
		;TBD: check if word argument refers to any-series!
		word: decorate-symbol pc/1
		emit-get-word pc/1								;-- save series (for resetting on end)
		emit-push-word pc/1								;-- word argument
		pc: next pc
		
		emit-open-frame 'forall
		emit copy/deep [								;-- copy/deep required for R/S lines injection
			while [natives/forall-loop]
		]
		comp-sub-block 'forall-body						;-- compile body
		append last output [							;-- inject at tail of body block
			natives/forall-next							;-- move series to next position
		]
		emit [
			natives/forall-end							;-- reset series
			stack/unwind
		]
	]
	
	comp-func-body: func [
		name [word!] spec [block!] body [block!] symbols [block!] locals-nb [integer!]
		/local init locals
	][
		push-locals copy symbols						;-- prepare compiled spec block
		forall symbols [symbols/1: decorate-symbol symbols/1]
		locals: append copy [/local ctx] symbols
		emit reduce [to set-word! decorate-func/strict name 'func locals]
		insert-lf -3

		comp-sub-block/with 'func-body body				;-- compile function's body

		;-- Function's prolog --
		pop-locals
		init: make block! 4 * length? symbols
		
		append init compose [							;-- point context values series to stack
			ctx: TO_CTX(to paren! last ctx-stack)
			push ctx/values								;-- save previous context values pointer
			ctx/values: as node! stack/arguments
		]
		new-line skip tail init -4 on
		
		forall symbols [								;-- assign local variable to Red arguments
			append init to set-word! symbols/1
			new-line back tail init on
			either head? symbols [
				append/only init 'stack/arguments
			][
				repend init [symbols/-1 '+ 1]
			]
		]
		unless zero? locals-nb [						;-- init local words on stack
			append init compose [
				_function/init-locals (1 + locals-nb)
			]
		]
		name: decorate-symbol name
		if find symbols name [name: prefix-global name]	;@@
		
		append init compose [							;-- body stack frame
			stack/mark-native (name)	;@@ make a unique name for function's body frame
		]
		
		;-- Function's epilog --
		append last output compose [
			stack/unwind-last							;-- closing body stack frame, and propagating last value
			ctx/values: as node! pop					;-- restore context values pointer
		]
		new-line skip tail last output -4 yes
		
		insert last output init
	]
	
	collect-words: func [spec [block!] body [block!] /local pos end ignore words rule word][
		if pos: find spec /extern [
			either end: find next pos refinement! [
				ignore: copy/part next pos end
				remove/part spec pos end
			][
				ignore: copy next pos
				clear pos
			]
			unless empty? intersect ignore spec [
				pc: skip pc -2
				throw-error ["duplicate word definition in function:" pc/1]
			]
		]
		foreach item spec [								;-- add all arguments to ignore list
			if find [word! lit-word! get-word!] type?/word item [
				unless ignore [ignore: make block! 1]
				append ignore to word! :item
			]
		]
		words: make block! 1
		
		make-local: [
			unless any [
				all [ignore	find ignore word]
				find words word
			][
				append words word
			]
		]
		parse body rule: [
			any [
				pos: set-word! (
					word: to word! pos/1
					do make-local
				)
				| pos: word! (
					if all [
						find word-iterators pos/1
						pos/2
					][
						foreach word any [
							all [block? pos/2 pos/2]
							reduce [pos/2]
						] make-local
					]
				)
				| path! | set-path! | lit-path!			;-- avoid 'into visiting them
				| into rule
				| skip
			]
		]
		unless empty? words [
			unless find spec /local [append spec /local]
			append spec words
		]
	]
	
	comp-func: func [
		/collect /does /has
		/local name word spec body symbols locals-nb spec-blk body-blk ctx src-name
	][
		name: check-func-name src-name: to word! pc/-1
		add-symbol word: to word! clean-lf-flag name
		add-global word
		
		pc: next pc
		set [spec body] pc
		case [
			collect [collect-words spec body]
			does	[body: spec spec: make block! 1 pc: back pc]
			has		[spec: head insert copy spec /local]
		]
		set [symbols locals-nb] check-spec spec
		add-function name spec
		
		redirect-to-literals [							;-- store spec and body blocks
			push-locals symbols
			spec-blk: emit-block spec
			ctx: push-context copy symbols
			emit compose [
				(to set-word! ctx) _context/make (spec-blk) yes no	;-- build context with value on stack
			]
			insert-lf -4
			body-blk: either job/red-store-bodies? [emit-block/bind body ctx]['null]
			pop-locals
		]
		
		emit-open-frame 'set							;-- function value creation
		emit-push-word src-name
		emit reduce [
			'_function/push spec-blk body-blk ctx
			'as 'integer! to get-word! decorate-func/strict name
		]
		insert-lf -7
		new-line skip tail output -3 no
		emit 'word/set
		insert-lf -1
		emit-close-frame
		
		repend bodies [									;-- save context for deferred function compilation
			name spec body symbols locals-nb copy locals-stack copy ssa-names copy ctx-stack
		]
		pop-context
		pc: skip pc 2
	]
	
	comp-function: does [
		comp-func/collect
	]
	
	comp-does: does [
		comp-func/does
	]
	
	comp-has: does [
		comp-func/has
	]
	
	comp-routine: has [name word spec spec* body spec-blk body-blk][
		name: check-func-name to word! pc/-1
		add-symbol word: to word! clean-lf-flag name
		add-global word
		
		pc: next pc
		set [spec body] pc

		preprocess-strings body							;-- encode strings for Red/System
		check-spec spec
		add-function/type name spec 'routine!
		
		process-calls body								;-- process #call directives
		
		clear find spec*: copy spec /local
		spec-blk: redirect-to-literals [emit-block spec*]
		body-blk: either job/red-store-bodies? [
			redirect-to-literals [emit-block body]
		][
			'null
		]
		convert-types spec
		either no-global? [
			repend bodies [								;-- saved for deferred inclusion
				name spec body none none none none none
			]
		][
			emit reduce [to set-word! name 'func]
			insert-lf -2
			append/only output spec
			append/only output body
		]
		
		emit-open-frame 'set							;-- routine value creation
		emit-push-word name
		emit compose [
			routine/push (spec-blk) (body-blk) as integer! (to get-word! name)
		]
		emit 'word/set
		insert-lf -1
		emit-close-frame

		pc: skip pc 2
	]
	
	comp-exit: does [
		pc: next pc
		emit [
			copy-cell unset-value stack/arguments
		]
		emit-exit-function
	]

	comp-return: does [
		comp-expression
		emit-exit-function
	]
	
	comp-switch: has [mark name arg body list cnt pos default? value][
		if path? pc/-1 [
			foreach ref next pc/-1 [
				switch/default ref [
					default [default?: yes]
					;all []
				][throw-error ["SWITCH has no refinement called" ref]]
			]
		]
		emit-open-frame 'switch
		mark: tail output								;-- pre-compile the SWITCH argument
		comp-expression
		arg: copy mark
		clear mark
		
		body: pc/1
		unless block? body [
			throw-error "SWITCH expects a block as second argument"
		]
		list: make block! 4
		cnt: 1
		parse body [									;-- build a [value index] pairs list
			any [
				value: skip (repend list [value/1 cnt])
				to block! skip (cnt: cnt + 1)
			]
		]
		name: redirect-to-literals [emit-block list]
		
		emit-open-frame 'select							;-- SWITCH lookup frame
		emit compose [block/push (name)]
		insert-lf -2
		emit arg
		emit [integer/push 2]							;-- /skip 2
		insert-lf -2
		emit-action/with 'select [-1 0 -1 -1 -1 2 -1 -1] ;-- select/only/skip
		emit-close-frame
		
		emit [switch integer/get-any*]
		insert-lf -2
		
		clear list
		cnt: 1
		parse body [									;-- build SWITCH cases
			any [skip to block! pos: (
				mark: tail output
				comp-sub-block/with 'switch-body pos/1
				pc: back pc			;-- restore PC position (no block consumed)
				repend list [cnt mark/1]
				clear mark
				cnt: cnt + 1
			) skip]
		]
		unless empty? body [pc: next pc]
		
		append list 'default							;-- process default case
		either default? [
			comp-sub-block 'switch-default				;-- compile default block
			append/only list last output
			clear back tail output
		][
			append/only list copy [0]					;-- placeholder for keeping R/S compiler happy
		]
		append/only output list
		emit-close-frame
	]
	
	comp-case: has [all? path saved list mark body chunk][
		if path? path: pc/-1 [
			either path/2 = 'all [all?: yes][
				throw-error ["CASE has no refinement called" path/2]
			]
		]
		unless block? pc/1 [
			throw-error "CASE expects a block as argument"
		]
		
		saved: pc
		pc: pc/1
		list: make block! length? pc
		
		while [not tail? pc][							;-- precompile all conditions and cases
			mark: tail output
			comp-expression								;-- process condition
			append/only list copy mark
			clear mark
			case [
				tail? pc [
					throw-error "CASE is missing a value"
				]
				block? pc/1 [
					append/only list comp-sub-block 'case	;-- process case block
					clear back tail output
				]
				'else [
					chunk: tail output
					comp-expression/no-infix/root
					all [								;-- fixes #512
						not empty? chunk
						chunk/1 <> 'stack/reset
						insert/only chunk 'stack/reset
					]
					append/only list copy chunk
					clear chunk
				]
			]
		]
		pc: next saved
		
		either all? [
			foreach [test body] list [					;-- /all mode
				emit-open-frame 'case
				emit test
				emit compose/deep [
					either logic/false? [(set-last-none)]
				]
				append/only output body
				emit-close-frame
			]
		][												;-- default single selection mode
			list: skip tail list -2
			body: reduce ['either 'logic/true? list/2 set-last-none]
			new-line body yes
			insert body list/1
			
			;-- emit expressions tree from leaf to root
			while [not head? list][
				list: skip list -2
				
				insert/only body 'stack/reset
				new-line body yes
				
				body: reduce ['either 'logic/true? list/2 body]
				new-line body yes
				insert body list/1
			]
			
			emit-open-frame 'case
			emit body
			emit-close-frame
		]
	]
	
	comp-reduce: has [list into?][
		into?: path? pc/-1
		unless block? pc/1 [
			emit-open-frame 'reduce
			comp-expression							;-- compile not-literal-block argument
			if into? [comp-expression]				;-- optionally compile /into argument
			emit-native/with 'reduce reduce [pick [1 -1] into?]
			emit-close-frame
			exit
		]
		
		list: either empty? pc/1 [
			pc: next pc								;-- pass the empty source block
			make block! 1
		][
			comp-chunked-block						;-- compile literal block
		]
		
		emit-open-frame 'reduce
		either path? pc/-2 [						;-- -2 => account for block argument
			comp-expression							;-- compile /into argument
		][
			emit 'block/push-only*					;-- create a fresh new block on stack only
			emit max 1 length? list
			insert-lf -2
		]
		foreach chunk list [
			emit chunk
			either into? [
				emit [actions/insert* -1 0 -1]
				insert-lf -4
			][
				emit 'block/append*
				insert-lf -1
			]
			emit 'stack/keep						;-- reset stack, but keep block as last value
			insert-lf -1
		]
		unless empty? list [remove back tail output] ;-- remove the extra 'stack/keep
		emit-close-frame
	]
	
	comp-set: has [name][
		either lit-word? pc/1 [
			name: to word! pc/1
			either local-word? name [
				pc: next pc
				comp-local-set/any? name
			][
				comp-set-word/native
			]
		][
			if block? pc/1 [						;-- if words are literals, register them
				foreach w pc/1 [
					add-symbol w: to word! w
					unless local-word? w [
						add-global w				;-- register it as global
					]
				]
			]
			emit-open-frame 'set
			comp-expression
			comp-expression
			emit-native/with 'set [-1]
			emit-close-frame
		]
	]
	
	comp-get: has [symbol][
		either lit-word? pc/1 [
			add-symbol symbol: to word! pc/1
			either path? pc/-1 [						;@@ add check for validaty of refinements		
				emit-get-word/any? symbol
			][
				emit-get-word symbol
			]
			pc: next pc
		][
			emit-open-frame 'get
			comp-expression
			emit-native/with 'get [-1]
			emit-close-frame
		]
	]
	
	comp-path: func [/set /local path value get? entry alter][
		path: copy pc/1
		
		value: path/1
		if all [not set not get? entry: find functions value][
			if alter: select ssa-names value [
				entry: find functions alter
			]
			either head? path [
				pc: next pc
				comp-call path entry/2		;-- call function with refinements
				exit
			][
				;--not-implemented--			;TBD: resolve access path to function
			]
		]
					
		emit-open-frame 'body
		if set [
			saved: pc
			pc: next pc
			comp-expression
			after: pc
			pc: saved
		]
		comp-literal no
		pc: back pc
		emit pick [interpreter/do-set-path interpreter/do-path] to logic! set
		insert-lf -1
		emit-close-frame
		pc: either set [after][next pc]
	]
	
	comp-arguments: func [spec [block!] nb [integer!] /ref name [refinement!] /local word][
		if ref [spec: find/tail spec name]
		loop nb [
			while [not any-word? spec/1][				;-- skip attributs and docstrings
				spec: next spec
			]
			switch type?/word spec/1 [
				lit-word! [
					either all [
						tail? pc
						all [spec/2 find spec/2 'any-type!]
					][
						emit 'unset/push				;-- provide unset as placeholder
						insert-lf -1
					][
						switch/default type?/word pc/1 [
							get-word! [
								add-symbol to word! pc/1
								comp-expression
							]
							lit-word! [
								add-symbol word: to word! pc/1
								emit 'lit-word/push
								emit decorate-symbol word
								insert-lf -2
								pc: next pc
							]
							word! [
								add-symbol word: to word! pc/1
								emit-push-word word				;@@ add specific type checking
								pc: next pc
							]
							paren! [comp-expression]
						][
							comp-literal no
						]
					]
				]
				get-word! [comp-literal/inactive no]
				word!     [comp-expression]
			]
			spec: next spec
		]
	]
		
	comp-call: func [
		call [word! path!]
		spec [block!]
		/local item name compact? refs ref? cnt pos ctx mark list offset emit-no-ref args option
	][
		either spec/1 = 'intrinsic! [
			switch any [all [path? call call/1] call] keywords
		][
			compact?: spec/1 <> 'function!				;-- do not push refinements on stack
			refs: make block! 1							;-- refinements storage in compact mode
			cnt: 0
			
			name: either path? call [call/1][call]
			name: to word! clean-lf-flag name
			emit-open-frame name
			
			comp-arguments spec/3 spec/2				;-- fetch arguments
			
			either compact? [
				refs: either spec/4 [
					head insert/dup make block! 8 -1 (length? spec/4) / 3	;-- init with -1
				][
					[]									;-- function with no refinements
				]
				if path? call [
					cnt: spec/2							;-- function base arity
					foreach ref next call [
						ref: to refinement! ref
						unless pos: find/skip spec/4 ref 3 [
							throw-error [call/1 "has no refinement called" ref]
						]
						poke refs pos/2 cnt				;-- set refinement's arguments base offset
						comp-arguments/ref spec/3 pos/3 ref ;-- fetch refinement arguments
						cnt: cnt + pos/3				;-- increase by nb of arguments
					]
				]
			][											;-- prepare function! stack layout
				emit-no-ref: [							;-- populate stack for unused refinement
					emit [logic/push false]				;-- unused refinement is set to FALSE
					insert-lf -2
					loop args [
						emit 'none/push					;-- unused arguments are set to NONE
						insert-lf -1
					]
				]
				either path? call [						;-- call with refinements?
					ctx: copy spec/4					;-- get a new context block
					foreach ref next call [
						option: to refinement! either integer? ref [form ref][ref]
						
						unless pos: find/skip spec/4 option 3 [
							throw-error [call/1 "has no refinement called" ref]
						]
						offset: 2 + index? pos
						poke ctx index? pos true		;-- switch refinement to true in context
						unless zero? args: pos/3 [		;-- process refinement's arguments
							list: make block! 1
							ctx/:offset: list 			;-- compiled refinement arguments storage
							mark: tail output
							comp-arguments/ref spec/3 args option
							append/only list copy mark
							clear mark
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
								if block? ctx/3 [
									foreach code ctx/3 [emit code] ;-- emit pre-compiled arguments
								]
							]
						]
					]
				][										;-- call with no refinements
					if spec/4 [
						foreach [ref offset args] spec/4 emit-no-ref
					]
				]
			]
			
			switch spec/1 [
				native! 	[emit-native/with name refs]
				action! 	[emit-action/with name refs]
				op!			[]
				function! 	[emit decorate-func name insert-lf -1]
				routine!	[emit-routine name spec/3]
			]
			emit-close-frame
		]
	]
	
	comp-local-set: func [name [word!] /any? /local offset][
		emit-open-frame 'set
		comp-expression
		offset: either any? [
			emit [copy-cell stack/arguments]
			-3
		][
			emit 'word/set-local
			-2
		]
		emit decorate-symbol name
		insert-lf offset
		emit-close-frame
	]
	
	comp-set-word: func [/native /local name value][
		name: pc/1
		pc: next pc
		add-symbol name: to word! clean-lf-flag name
		add-global name
		
		if infix? pc [
			throw-error "invalid use of set-word as operand"
		]
		if all [not booting? find intrinsics name][		
			throw-error ["attempt to redefine a keyword:" name]
		]
		case [
			pc/1 = 'func	 [comp-func]
			pc/1 = 'function [comp-function]
			pc/1 = 'has		 [comp-has]
			pc/1 = 'does	 [comp-does]
			pc/1 = 'routine	 [comp-routine]
			local-word? name [comp-local-set name]
			'else [
				check-redefined name
				emit-open-frame 'set
				either native [							;-- 1st argument
					pc: back pc
					comp-expression						;-- fetch a value
				][
					emit-push-word name					;-- push set-word
				]
				comp-expression							;-- fetch a value (2nd argument)
				either native [
					emit-native/with 'set [-1]			;@@ refinement not handled yet
				][
					emit 'word/set
					insert-lf -1
				]
				emit-close-frame
			]
		]
	]

	comp-word: func [/literal /final /local name local? alter emit-word][
		name: to word! pc/1
		pc: next pc										;@@ move it deeper
		local?: local-word? name
		
		emit-word: [
			either lit-word? pc/-1 [					;@@
				emit-push-word name
			][
				either literal [
					emit-get-word/literal name
				][
					emit-get-word name
				]
			]
		]
		
		case [
			name = 'exit	[comp-exit]
			name = 'return	[comp-return]
			all [
				not final
				not local?
				name = 'make
				any-function? pc/1
			][
				fetch-functions skip pc -2				;-- extract functions definitions
				pc: back pc
				comp-word/final
			]
			all [
				not literal
				not local?
				entry: find functions name
			][
				if alter: select ssa-names name [
					entry: find functions alter
				]
				check-invalid-call name
				comp-call name entry/2
			]
			any [
				find globals name
				find-contexts name
			][
				do emit-word
			]
			'else [
				either job/red-strict-check? [
					pc: back pc
					throw-error ["undefined word" pc/1]
				][
					do emit-word
				]
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
	
	check-infix-operators: has [name op pos end ops spec][
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
				name: ops/1
				spec: functions/:name
				switch/default spec/1 [
					function! [emit decorate-func name insert-lf -1]
					routine!  [emit-routine name spec/3]
				][
					emit make-func-prefix name
					insert-lf -1
				]
				
				emit-close-frame
				unless tail? next ops [pc: next pc]		;-- jump over op word unless last operand
			]
			return true									;-- infix expression processed
		]
		false											;-- not an infix expression
	]
	
	process-call-directive: func [body [block!] global? /local name spec cmd types type arg][
		name: to word! clean-lf-flag body/1
		if any [
			not spec: select functions name
			not spec/1 = 'function!
		][
			throw-error ["invalid #call function name:" name]
		]
		either global? [
			emit 'red/stack/mark-func
			emit decorate-exec-ctx decorate-symbol name
			insert-lf -2
		][
			emit-open-frame name
		]
		
		types: spec/3
		body: next body
		
		loop spec/2 [									;-- process arguments
			types: find/tail types word!
			unless block? types/1 [
				throw-error ["type undefined for" types/1 "in function" name]
			]
			either 1 = length? types/1 [
				type: types/1/1
			][
				arg: body/1
				if word? arg [arg: get arg]
				type: none
				foreach value types/1 [
					if value = type?/word arg [type: value break]
				]
				unless type [
					throw-error ["cannot determine #call argument type:" arg]
				]
			]
			cmd: to path! reduce [to word! form get type 'push]
			if global? [insert cmd 'red]
			emit cmd
			insert-lf -1
			case [
				none? body/1 [
					throw-error ["missing argument(s) in #call body"]
				]
				body/1 = 'as [
					emit copy/part body 3
					body: skip body 3
				]
				body/1 = 'none [
					body: next body
				]
				'else [
					emit body/1
					body: next body
				]
			]
		]
		
		types: next types								;-- process refinements
		while [not tail? types][
			switch type?/word types/1 [
				refinement! [
					if types/1 = /local [break]
					emit [red/logic/push false]
					insert-lf -2
				]
				word! [
					emit 'red/none/push
					insert-lf -1
				]
				set-word! [break]
			]
			types: next types
		]
		
		name: decorate-func name						;-- function call
		if global? [name: decorate-exec-ctx name]
		emit name
		insert-lf -1
		
		either global? [
			emit 'red/stack/unwind-last
			insert-lf -1
			emit 'red/stack/reset
		][
			emit-close-frame
			emit 'stack/reset
		]
		insert-lf -1
	]

	comp-directive: has [file saved version mark][
		switch pc/1 [
			#include [
				unless file? file: pc/2 [
					throw-error ["#include requires a file argument:" pc/2]
				]
				append include-stk script-path
				
				script-path: either all [not booting? relative-path? file][
					file: clean-path join any [script-path main-path] file
					first split-path file
				][
					none
				]
				unless any [booting? exists? file][
					throw-error ["include file not found:" pc/2]
				]
				either find included-list file [
					script-path: take/last include-stk
					remove/part pc 2
				][
					saved: script-name
					insert skip pc 2 #pop-path
					change/part pc next load-source file 2	;@@ Header skipped, should be processed
					script-name: saved
					append included-list file
				]
				true
			]
			#pop-path [
				script-path: take/last include-stk
				pc: next pc
			]
			#system [
				unless block? pc/2 [
					throw-error "#system requires a block argument"
				]
				process-include-paths pc/2
				process-calls pc/2
				preprocess-strings pc/2					;-- encode strings for Red/System
				mark: tail output
				emit pc/2
				new-line mark on
				pc: skip pc 2
				true
			]
			#system-global [
				unless block? pc/2 [
					throw-error "#system-global requires a block argument"
				]
				process-include-paths pc/2
				preprocess-strings pc/2					;-- encode strings for Red/System
				unless sys-global/1 = 'Red/System [
					append sys-global copy/deep [Red/System []]
				]
				append sys-global pc/2
				pc: skip pc 2
				true
			]
			#get-definition [							;-- temporary directive
				either value: select extracts/definitions pc/2 [
					change/only/part pc value 2
					comp-expression						;-- continue expression fetching
				][
					pc: next pc
				]
				true
			]
			#load [										;-- temporary directive
				change/part/only pc to do pc/2 pc/3 3
				comp-expression							;-- continue expression fetching
				true
			]
			#version [
				change pc rejoin [load-cache %version.r ", " now]
				comp-expression
				true
			]
		]
	]
	
	comp-expression: func [/no-infix /root][
		unless no-infix [
			if check-infix-operators [exit]
		]

		if tail? pc [
			pc: back pc
			throw-error "missing argument"
		]
		switch/default type?/word pc/1 [
			issue!		[
				either any [
					unicode-char?  pc/1
					float-special? pc/1
				][
					comp-literal to logic! root			;-- special encoding for Unicode char!
				][
					unless comp-directive [
						comp-literal to logic! root
					]
				]
			]
			;-- active datatypes with specific literal form
			set-word!	[comp-set-word]
			word!		[comp-word]
			get-word!	[comp-word/literal]
			paren!		[comp-next-block]
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
	
	comp-next-block: func [/with blk /local saved][
		saved: pc
		pc: any [blk pc/1]
		comp-block
		pc: next saved
	]
	
	comp-chunked-block: has [list mark saved][
		list: make block! 10
		saved: pc
		pc: pc/1										;-- dive in nested code
		mark: tail output
		
		comp-block/no-root/with [
			mold mark									;-- black magic, fixes #509, R2 internal memory corruption
			append/only list copy mark
			clear mark
		]
		
		pc: next saved
		list
	]
	
	comp-sub-block: func [origin [word!] /with body /local mark saved][
		unless any [with block? pc/1][
			throw-error [
				"expected a block for" uppercase form origin
				"instead of" mold type? pc/1 "value"
			]
		]
		
		mark: tail output
		saved: pc
		pc: any [body pc/1]								;-- dive in nested code
		comp-block
		pc: next saved									;-- step over block in source code				

		convert-to-block mark
		head insert last output [
			stack/reset
		]
	]
	
	comp-block: func [
		/with body [block!]
		/no-root
		/local expr
	][
		if tail? pc [
			emit 'unset/push
			insert-lf -1
			exit
		]
		while [not tail? pc][
			expr: pc
			either no-root [comp-expression][comp-expression/root]
			
			if all [verbose > 2 positive? offset? pc expr][probe copy/part expr pc]
			if verbose > 0 [emit-src-comment expr]
			
			if with [do body]
		]
	]
	
	comp-bodies: does [
		foreach [name spec body symbols locals-nb stack ssa ctx] bodies [
			either none? symbols [						;-- routine in no-global? mode
				emit reduce [to set-word! name 'func]
				insert-lf -2
				append/only output spec
				append/only output body
			][
				locals-stack: stack
				ssa-names: ssa
				ctx-stack: ctx
				comp-func-body name spec body symbols locals-nb
			]
		]
		clear locals-stack
		clear ssa-names
	]
	
	comp-init: does [
		add-symbol 'datatype!
		add-global 'datatype!
		foreach [name specs] functions [
			add-symbol name
			add-global name
		]

		;-- Create datatype! datatype and word
		emit compose [
			stack/mark-native ~set
			word/push (decorate-symbol 'datatype!)
			datatype/push TYPE_DATATYPE
			word/set
			stack/unwind
			stack/reset
		]
	]
	
	comp-source: func [code [block!] /local user main][
		output: make block! 10000
		comp-init
		
		pc: next load-source/hidden %boot.red			;-- compile Red's boot script
		booting?: yes
		comp-block
		make-keywords									;-- register intrinsics functions
		booting?: no
		
		pc: code										;-- compile user code
		user: tail output
		comp-block
		
		main: output
		output: make block! 1000
		
		comp-bodies										;-- compile deferred functions
		
		reduce [user main]
	]
	
	comp-as-lib: func [code [block!] /local user main defs pos][
		out: copy/deep [
			Red/System [
				type:   'dll
				origin: 'Red
			]
			
			with red [
				exec: context [
					<declarations>
					init: func [/local tmp] <script>
				]
			]
			on-load: does [
				red/init
				exec/init
			]
		]
		
		set [user main] comp-source code
		
		defs: make block! 10'000
		
		foreach [type cast][
			block	red-block!
			string	red-string!
			context node!
		][
			foreach name lit-vars/:type [
				repend defs [to set-word! name 'as cast 0]
				new-line skip tail defs -4 on
			]
		]
		foreach [name spec] symbols [
			repend defs [to set-word! spec/1 'as 'red-word! 0]
			new-line skip tail defs -4 on
		]
		append defs [
			------------| "Declarations"
		]
		append defs declarations
		pos: tail defs
		append defs [
			------------| "Functions"
		]
		append defs output
;		if verbose = 2 [probe pos]
		
		script: make block! 10'000
		append script [
			------------| "Symbols"
		]
		append script sym-table
		append script [
			------------| "Literals"
		]
		append script literals
		append script [
			------------| "Main program"
		]
		append script main
;		if find [1 2] verbose [probe user]
		
		unless empty? sys-global [
			process-calls/global sys-global				;-- lazy #call processing
		]
		
		pos: third pick tail out -4
		change/only find pos <script> script
		remove pos: find pos <declarations>
		insert pos defs
		
		output: out
		if verbose > 2 [?? output]
	]
	
	comp-as-exe: func [code [block!] /local out user main][
		out: copy/deep [
			Red/System [origin: 'Red]

			red/init
			
			with red [
				exec: context <script>
			]
		]
		
		set [user main] comp-source code
		
		;-- assemble all parts together in right order
		script: make block! 10'000
		
		append script [
			------------| "Symbols"
		]
		append script sym-table
		append script [
			------------| "Literals"
		]
		append script literals
		append script [
			------------| "Declarations"
		]
		append script declarations
		pos: tail script
		append script [
			------------| "Functions"
		]
		append script output
		if verbose = 2 [probe pos]
		
		append script [
			------------| "Main program"
		]
		append script main
		if find [1 2] verbose [probe user]
		
		unless empty? sys-global [
			process-calls/global sys-global				;-- lazy #call processing
		]

		change/only find last out <script> script		;-- inject compilation result in template
		output: out
		if verbose > 2 [?? output]
	]
	
	load-source: func [file [file! block!] /hidden /local src][
		either file? file [
			unless hidden [script-name: file]
			src: lexer/process read-binary-cache file
		][
			unless hidden [script-name: 'memory]
			src: file
		]
		src
	]
	
	process-needs: func [header [block!] src [block!] /local list file mods][
		case [
			list: select header first [Needs:][
				unless block? list [list: reduce [list]]
				mods: make block! 2
				
				foreach mod list [
					unless file: select standard-modules mod [
						throw-error ["module not found:" mod]
					]
					unless find needed mod [
						file: split-path join system/options/home file
						script-path: file/1
						repend mods [#include file/2]
					]
				]
				insert src mods
			]	
		]
	]
	
	clean-up: does [
		clear include-stk
		clear included-list
		clear needed
		clear symbols
		clear aliases
		clear globals
		clear sys-global
		clear contexts
		clear ctx-stack
		clear output
		clear sym-table
		clear literals
		clear declarations
		clear bodies
		clear actions
		clear op-actions
		clear keywords
		clear skip functions 2							;-- keep MAKE definition
		clear lit-vars/block
		clear lit-vars/string
		clear lit-vars/context
		s-counter: 0
		depth:	   0
	]

	compile: func [
		file [file! block!]								;-- source file or block of code
		opts [object!]
		/local time src
	][
		verbose: opts/verbosity
		job: opts
		clean-up
		main-path: first split-path file
		no-global?: job/type = 'dll
		
		time: dt [
			src: load-source file
			process-needs src/1 next src
			src: next src
			job/red-pass?: yes
			either no-global? [comp-as-lib src][comp-as-exe src]
		]
		reduce [output time]
	]
]
