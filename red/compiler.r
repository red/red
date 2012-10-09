REBOL [
	Title:   "Red compiler"
	Author:  "Nenad Rakocevic"
	File: 	 %compiler.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

do %../red-system/compiler.r

red: context [
	verbose:  	  0										;-- logs verbosity level
	job: 		  none									;-- reference the current job object	
	script:		  none
	runtime-path: %runtime/
	nl: 		  newline
	symbols:	  make hash! 1000
	ctx-stack:	  [gctx]
	lexer: 		  do bind load %lexer.r 'self
	extracts:	  do bind load %utils/extractor.r 'self	;-- @@ to be removed once we get redbin loader.
	sys-global:   make block! 1
	
	pc: 		  none
	locals:		  none
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

	functions: make hash! [
		if			[intrinsic! [cond  [any-type!] true-blk [block!]]]
		either		[intrinsic! [cond  [any-type!] true-blk [block!] false-blk [block!]]]
		any			[intrinsic! [conds [block!]]]
		all			[intrinsic! [conds [block!]]]
		while		[intrinsic! [cond  [block!] body [block!]]]
		until		[intrinsic! [body  [block!]]]
		loop		[intrinsic! [body  [block!]]]
		repeat		[intrinsic! [word  [word!] value [integer! series!] body [block!]]]
		foreach 	[intrinsic! [word  [word!] series [series!] body [block!]]]
		break		[intrinsic! []]	;@@ add /return option
		make		[action!    [type [datatype! word!] spec [any-type!]]]	;-- must be pre-defined
	]
	
	keywords: make block! (length? functions) / 2
	
	foreach [name spec] functions [
		if spec/1 = 'intrinsic! [
			repend keywords [name reduce [to word! join "comp-" name]]
		]
	]
	bind keywords self
	
	;-- Optimizations for faster symbols lookups in Red/System compiler
	word-push:     to word! "word/push"
	word-get:      to word! "word/get"
	word-set:      to word! "word/set"
	stack-mark:    to word! "stack/mark"
	stack-unwind:  to word! "stack/unwind"
	stack-reset:   to word! "stack/reset"
	stack-keep:    to word! "stack/keep"
	block-push*:   to word! "block/push*"
	block-push:    to word! "block/push"
	block-append*: to word! "block/append*"
	string-push:   to word! "string/push"
	logic-true?:   to word! "logic/true?"
	
	set-last-none: does [compose [(stack-reset) none/push]]

	quit-on-error: does [
		;clean-up
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
;			string!
;			file!
;			url!
			tuple!
			decimal!
			refinement!
			lit-word!
;			binary!
;			issue!
		] type?/word expr
	]
	
	unicode-char?: func [value][
		all [issue? value value/1 = #"'"]
	]
	
	insert-lf: func [pos][
		new-line skip tail output pos yes
	]
	
	emit: func [value][append output value]
		
	emit-src-comment: func [pos [block! paren!]][
		emit reduce [
			'------------| (mold/only clean-lf-deep copy/deep/part pos offset? pos pc)
		]
	]
	
	emit-push-word: func [name [word!]][	
		emit word-push
		emit decorate-symbol name
		insert-lf -2
	]
	
	emit-get-word: func [name [word!]][
		emit word-get
		emit decorate-symbol name
		insert-lf -2
	]
	
	emit-open-frame: func [name [word!]][
		emit stack-mark
		emit decorate-symbol name
		insert-lf -2
	]
	
	emit-close-frame: does [
		emit stack-unwind
		insert-lf -1
	]
	
	get-counter: does [s-counter: s-counter + 1]
	
	clean-lf-deep: func [blk [block!] /local pos][
		blk: copy/deep blk
		parse blk rule: [
			pos: (new-line/all pos off)
			into rule | skip
		]
		blk
	]

	clean-lf-flag: func [name [word! lit-word! set-word! refinement!]][
		mold/flat to word! name
	]
	
	decorate-symbol: func [name [word!]][
		to word! join "_" clean-lf-flag name
	]
	
	decorate-series-var: func [name [word!]][
		to word! join name get-counter
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
	
	infix?: func [pos [block! paren!] /local specs][
		all [
			not tail? pos
			word? pos/1
			specs: select functions pos/1
			'op! = specs/1
		]
	]
	
	fetch-functions: func [pos [block!] /local name][
		name: to word! pos/1
		if find functions name [exit]					;-- mainly intended for 'make (hardcoded)

		switch pos/3 [
			action! [append actions name]
			op!     [repend op-actions [name to word! pos/4]]
		]
		repend functions [
			name reduce [
				pos/3
				either pos/3 = 'op! [
					second select functions to word! pos/4
				][
					clean-lf-deep pos/4/1
				]
			]
		]
	]
	
	emit-block: func [blk [block!] /sub level /local name item value word action][
		unless sub [
			emit-open-frame 'append
			emit to set-word! name: decorate-series-var 'blk
			emit block-push*
			emit length? blk
			insert-lf -3
		]
		level: 0
		
		forall blk [
			either block? item: blk/1 [
				emit-open-frame 'append
				emit block-push*
				emit length? item
				insert-lf -3
				
				level: level + 1
				emit-block/sub item level
				level: level - 1
				
				emit-close-frame
				emit block-append*
				insert-lf -1
				emit stack-keep							;-- reset stack, but keep block as last value
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
						action: 'load
						item
					]
					'else [
						item
					]
				]
				emit to word! rejoin [form type? item slash action]
				emit value
				insert-lf -2
				
				emit block-append*
				insert-lf -1
				unless tail? next blk [
					emit stack-keep						;-- reset stack, but keep block as last value
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
			either char? [
				emit [char/push]
				emit to integer! next value
			][
				emit to word! rejoin [form type? value slash 'push]
				emit load mold value
			]
			insert-lf -2
			
			if root? [
				emit stack-keep							;-- drop root level last value
				insert-lf -1
			]
		][
			switch/default type?/word value [
				block!		[
					name: redirect-to-literals [emit-block value]
					emit block-push
					emit name
					insert-lf -2
				]
				string!		[
					redirect-to-literals [
						emit to set-word! name: decorate-series-var 'str
						emit [string/load]
						emit value
						insert-lf -3
					]	
					emit string-push
					emit name
					insert-lf -2
				]
				file!		[]
				url!		[]
				binary!		[]
				issue!		[]
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
		body: reduce ['unless logic-true? set-last-none]
		new-line body yes
		insert body list/1
		
		;-- emit expressions tree from leaf to root
		while [not head? list][
			list: back list
			
			insert body stack-reset
			new-line body yes
			
			body: reduce test
			new-line body yes
			
			insert body list/1
		]
		emit body	
	]
	
	comp-any: does [
		comp-boolean-expressions 'any ['unless logic-true? body]
	]
	
	comp-all: does [
		comp-boolean-expressions 'all [
			'either 'not logic-true? set-last-none body
		]
	]
		
	comp-if: does [
		comp-expression
		emit compose [
			if (logic-true?)
		]
		comp-sub-block									;-- compile TRUE block
	]
	
	comp-either: does [
		comp-expression		
		emit compose [
			either (logic-true?)
		]
		comp-sub-block									;-- compile TRUE block
		comp-sub-block									;-- compile FALSE block
	]
	
	comp-loop: has [name][
		depth: depth + 1
		
		name: to word! join "i" depth
		repend declarations [to set-word! name 0]		;-- declare variables at root level
		new-line skip tail declarations -2 yes
		
		comp-expression									;@@ optimize case for literal counter
		
		emit to set-word! name
		insert-lf -1
		emit [
			integer/get*
			stack/reset
			until
		]
		new-line skip tail output -3 off
		
		comp-sub-block									;-- compile loop's body
		
		repend last output [
			to set-word! name name '- 1
			name '= 0
		]
		new-line skip tail last output -3 on
		new-line skip tail last output -7 on
		depth: depth - 1
	]
	
	;@@ old code, needs to be refactored
	comp-path-part: func [path parent parent-type /local type][
		switch type: get-type path/1 [
			word!	  [
				if find string-set type [
					throw-error ["Invalid path value:" path/2]
				]
				repend output ['block/select decorate parent decorate path/2]
			]
			get-word! [

			]
			integer!  [
				append output case [
					find block-set parent-type  [[integer/get block/pick]]
					find string-set parent-type ['pick-string]
					'else [throw-error "Houston, we have a problem!"]	;@@ shouldn't happen
				]
				repend output [decorate parent path/1]
			]
			paren!	  [

			]
		]	
		unless tail? path [comp-path-part next path path/1 type]
	]
	
	;@@ old code, needs to be refactored
	comp-path: has [path entry type][
		path: pc/1
		pc: next pc
		either entry: find functions path/1 [			;-- function call
			
		][												;-- path access to series
			type: get-type path/1
			unless find series-set type	[
				throw-error ["can't use path on" mold type "type"]
			]
			comp-path-part next path path/1 type
		]
	]
		
	comp-call: func [call [word! path!] spec [block!] /local item name][
		either spec/1 = 'intrinsic! [
			switch call keywords
		][
			emit-open-frame call
			name: either path? call [call/1][call]
			name: to word! clean-lf-flag name

			parse spec/2 [
				any [
					item: word! (comp-expression)		;-- fetch argument
					| [
						refinement! (
							emit compose [
								word/get (to word! join "_" to logic! all [
									path? call
									find call to word! item
								])
							]
						)
						any [word! opt block! (comp-expression)] ;-- just optional argument
					]
					| set-word! skip
					| skip
				]
			]

			switch spec/1 [
				native! 	[emit to word! rejoin ["natives/" to word! name #"*"]]
				action! 	[emit to word! rejoin ["actions/" name #"*"]]
				op!			[]
				function!	[]
			]
			insert-lf -1
			emit-close-frame
		]
	]
	
	comp-set-word: has [name value][
		name: pc/1
		pc: next pc
		add-symbol name: to word! clean-lf-flag name
		if infix? pc [
			throw-error "invalid use of set-word as operand"
		]
		emit-open-frame 'set
		emit-push-word name
		comp-expression									;-- fetch a value
		emit word-set
		insert-lf -1
		emit-close-frame
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
					emit-get-word name
				]
			]
			'else [
				pc: back pc
				throw-error ["undefined word" pc/1]
			]
		]
	]
	
	search-expr-end: func [pos [block!]][
		if infix? next pos [pos: search-expr-end skip pos 2]
		pos
	]
	
	make-func-prefix: func [name [word!]][
		to word!  rejoin [								;@@ cache results locally
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
	
	comp-directive: func [][
		switch/default pc/1 [
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
			path! 		[comp-path]
			set-path!	[comp-path-assignment]
			paren!		[saved: pc pc: pc/1 comp-block pc: next saved]
		][
			comp-literal to logic! root
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
	]
	
	comp-block: func [
		/with body [block!]
		/local expr
	][
		while [not tail? pc][
			expr: pc
			comp-expression/root
			
			if verbose > 2 [probe copy/part expr pc]
			if verbose > 0 [emit-src-comment expr]
			
			if with [do body]
		]
	]
	
	comp-init: does [
		add-symbol 'datatype!
		foreach [name specs] functions [add-symbol name]

		;-- Create datatype! datatype and word
		emit [
			word/push _datatype!
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
			src: read/binary file
			set [path file] split-path file
			src: lexer/process src
		][
			script: 'memory
			src: file
		]
		next src										;-- skip header block
	]

	compile: func [
		file [file! block!]								;-- source file or block of code
		opts [object!]
		/local time
	][
		verbose: opts/verbosity
		
		time: dt [comp-red load-source file]
		reduce [output time]
	]
]

