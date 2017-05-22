REBOL [
	Title:   "Red compiler"
	Author:  "Nenad Rakocevic"
	File: 	 %compiler.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

do-cache %system/compiler.r

red: context [
	verbose:	   0									;-- logs verbosity level
	job: 		   none									;-- reference the current job object
	script-name:   none
	script-path:   none
	script-file:   none									;-- #system metadata for R/S loader
	main-path:	   none
	runtime-path:  %runtime/
	include-stk:   make block! 3
	included-list: make block! 20
	script-stk:	   make block! 10
	needed:		   make block! 4
	symbols:	   make hash! 1000
	globals:	   make hash! 1000						;-- words defined in global context
	aliases: 	   make hash! 100
	contexts:	   make hash! 100						;-- storage for statically compiled contexts
	ctx-stack:	   make block! 8						;-- contexts access path
	shadow-funcs:  make block! 1000						;-- shadow functions contexts [symbol object! ctx...]
	objects:	   make block! 600						;-- shadow objects contexts [name object! ctx...]
	obj-stack:	   to path! 'objects					;-- current object access path
	container-obj?: none								;-- closest wrapping object
	func-objs:	   none									;-- points to 'objects first in-function object
	paths-stack:   make block! 4						;-- stack of generated code for handling dual codepaths for paths
	native-ts:	   make block! 200						;-- prepared native! typesets: [name [<ts-list>] ...]
	rebol-gctx:	   bind? 'rebol
	expr-stack:	   make block! 8
	current-call:  none
	
	unless value? 'Red [red: none]						;-- for %preprocessor to load
	
	lexer: 		   do bind load-cache %lexer.r 'self
	extracts:	   do bind load-cache %utils/extractor.r 'self
	redbin:		   do bind load-cache %utils/redbin.r 'self
	preprocessor:  do-cache file: %utils/preprocessor.r
	preprocessor:  do preprocessor/expand/clean load-cache file none ;-- apply preprocessor on itself
	
	sys-global:    make block! 1
	lit-vars: 	   reduce [
		'block	   make hash! 1000
		'string	   make hash! 1000
		'context   make hash! 1000
		'typeset   make hash! 100
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
	types-cache:   make hash!  100						;-- store compiled typesets [types array name...]
	last-type:	   none
	return-def:    to-set-word 'return					;-- return: keyword
	s-counter:	   0									;-- series suffix counter
	depth:		   0									;-- expression nesting level counter
	max-depth:	   0
	booting?:	   none									;-- YES: compiling boot script
	nl: 		   newline
	set 'float!	   'float								;-- type names not defined in Rebol
	set 'handle!   'handle
	comment-marker: '------------|
 
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
		forever foreach forall func function does has
		exit return switch case routine set get reduce
		context object construct try break continue
		remove-each
	]
	
	logic-words:  [true false yes no on off]
	
	word-iterators: [repeat foreach forall remove-each]	;-- only the ones using word(s) as counter(s)
	
	iterators: [loop until while repeat foreach forall forever remove-each]
	
	standard-modules: [
	;-- Name ------ Entry file -------------- OS availability -----
		View		%modules/view/view.red	  [Windows MacOSX]
	]

	func-constructors: [
		'func | 'function | 'does | 'has | 'routine | 'make 'function!
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

	throw-error: func [err [word! string! block!] /near code [block!]][
		print [
			"*** Compilation Error:"
			either word? err [
				join uppercase/part mold err 1 " error"
			][reform err]
			"^/*** in file:" to-local-file script-name
			;either locals [join "^/*** in function: " func-name][""]
		]
		if pc [
			print [
				;"*** at line:" calc-line lf
				"*** near:" mold any [code copy/part pc 8]
			]
		]
		quit-on-error
	]
	
	dispatch-ctx-keywords: func [original [any-word! none!] /with alt-value][
		if path? alt-value [alt-value: alt-value/1]
		
		switch/default any [alt-value pc/1][
			func	  [comp-func]
			function  [comp-function]
			has		  [comp-has]
			does	  [comp-does]
			routine	  [comp-routine]
			construct [comp-construct]
			object
			context	  [
				either obj: is-object? pc/2 [
					comp-context/with/extend original obj
				][
					comp-context/with original
				]
			]
		][no]
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
					unless empty? script-stk [
						insert next file reduce [#script last script-stk]
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
				| #get pos: (process-get-directive pos/1 back pos)
				| into rule
				| skip
			]
		]
	]
	
	process-routine-calls: func [code [block!] ctx [word!] ignore [block!] obj [object!] /local rule name][
		parse code rule: [
			some [
				name: word! (
					if all [in obj name/1 not find ignore name/1][
						name/1: decorate-obj-member name/1 ctx
					]
				)
				| path! | set-path! | lit-path!
				| into rule
				| skip
			]
		]
	]
	
	preprocess-strings: func [code [block!] /local rule s][  ;-- re-encode strings for Red/System
		parse code rule: [
			any [
				s: string! (lexer/decode-UTF8-string s/1)
				| into rule
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
			decimal!
			refinement!
			issue!
			lit-word!
			word! 
			get-word!
			set-word!
			pair!
			time!
		] type?/word :expr
	]
	
	local-bound?: func [original [any-word!] /local obj][
		all [
			not empty? locals-stack
			rebol-gctx <> obj: bind? original
			find shadow-funcs obj
		]
	]
	
	local-word?: func [name [word!]][
		all [not empty? locals-stack find last locals-stack name]
	]
	
	unicode-char?:  func [value][value/1 = #"'"]
	float-special?: func [value][value/1 = #"."]
	tuple-value?:	func [value][value/1 = #"~"]
	percent-value?: func [value][#"%" = last value]
	
	map-value?: func [value][all [block? value value/1 = #!map!]]
	
	insert-lf: func [pos][
		new-line skip tail output pos yes
	]
	
	emit: func [value][
		either block? value [append output value][append/only output value]
	]
		
	emit-src-comment: func [pos [block! paren! none!] /with cmt [string!]][
		unless cmt [
			cmt: trim/lines mold/only/flat clean-lf-deep copy/deep/part pos offset? pos pc
		]
		if 50 < length? cmt [cmt: append copy/part cmt 50 "..."]
		emit reduce [
			comment-marker (cmt)
		]
	]
	
	find-ssa: func [name [word!]][find/skip ssa-names name 2]
	
	select-ssa: func [name [word!] /local pos][
		all [pos: find/skip ssa-names name 2 pos/2]
	]
	
	parent-object?: func [obj [object!]][
		all [not empty? locals-stack (next first obj) = container-obj?]
	]
	
	find-binding: func [original [any-word!] /local ctx idx obj][
		all [
			ctx: all [
				rebol-gctx <> obj: bind? original
				any [select objects obj select shadow-funcs obj]
			]
			attempt [idx: get-word-index/with to word! original ctx]
			reduce [ctx idx]
		]
	]
	
	select-object: func [ctx [word!] /local pos][
		pos: find objects ctx
		either object? pos/2 [pos/2][pos/-1]
	]
	
	bind-function: func [body [block!] shadow [object!] /local self* rule pos][
		bind body shadow
		if 1 < length? obj-stack [
			self*: in do obj-stack 'self				;-- rebing SELF to the wrapping object
			
			parse body rule: [
				any [pos: 'self (pos/1: self*) | into rule | skip]
			]
		]
	]
	
	get-word-index: func [name [word!] /with c [word!] /local ctx pos list][
		if with [
			ctx: select contexts c
			return either pos: find ctx name [(index? pos) - 1][none]
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
	
	emit-push-from: func [
		name [any-word!] original [any-word!] type [word!] actions [block!]
		/local ctx obj idx
	][
		either all [
			ctx: all [
				rebol-gctx <> obj: bind? original
				select objects obj
			]
			attempt [idx: get-word-index/with name ctx]
		][
			emit append to path! type actions/1
			emit either parent-object? obj ['octx][ctx] ;-- optional parametrized context reference (octx)
			emit idx
			insert-lf -3
		][
			emit append to path! type actions/2
			emit prefix-exec name
			insert-lf -2
		]
	]
	
	emit-push-word: func [name [any-word!] original [any-word!] /local type ctx obj][
		type: to word! form type? name
		name: to word! :name
		
		either all [
			rebol-gctx <> obj: bind? original
			ctx: select shadow-funcs obj
		][
			emit append to path! type 'push-local
			emit ctx
			emit get-word-index name					;@@ replace that 
			insert-lf -3
		][
			emit-push-from name original type [push-local push]
		]
	]
	
	emit-get-word: func [name [word!] original [any-word!] /any? /literal /local new obj ctx][
		either all [
			rebol-gctx <> obj: bind? original
			ctx: select shadow-funcs obj
		][	
			either all [not empty? ctx-stack ctx <> last ctx-stack][
				emit 'word/get-local
				emit ctx
				emit get-word-index name				;-- word from another function context
				insert-lf -3
				exit
			][
				emit 'stack/push						;-- local word
			]
			emit decorate-symbol/no-alias name
		][
			if new: select-ssa name [name: new]			;@@ add a check for function! type
			emit case [									;-- global word
				all [
					literal
					obj = rebol-gctx
				][
					'get-word/get
				]
				any?  ['word/get-any]
				'else [
					emit-push-from name name 'word [get-local get]
					exit
				]
			]
			emit decorate-symbol name
		]
		insert-lf -2
	]
	
	get-path-word: func [
		original [any-word!] blk [block!] get? [logic!]
		/local name new obj ctx idx
	][
		name: to word! original
		
		either all [
			rebol-gctx <> obj: bind? original
			find shadow-funcs obj
		][
			either get? [
				append blk decorate-symbol/no-alias name ;-- local word, point to value slot
			][
				append blk [as cell!]
				append/only blk prefix-exec name		;-- force global word
			]
		][
			if new: select-ssa name [name: new]			;@@ add a check for function! type
			either get? [
				either all [
					rebol-gctx <> obj
					ctx: select objects obj
					attempt [idx: get-word-index/with name ctx]
				][
					repend blk [
						'word/get-in
						either parent-object? obj ['octx][ctx] ;-- optional parametrized context reference (octx)
						idx
					]
				][	
					append/only blk '_context/get
					append/only blk prefix-exec name
				]
			][
				append blk [as cell!]
				append/only blk prefix-exec name
			]
			
		]
		blk
	]

	emit-open-frame: func [name [word!] /local symbol type][
		symbol: either name = 'try-all ['try][name]
		unless find symbols symbol [add-symbol symbol]
		emit case [
			'function! = all [
				type: find functions name
				first first next type
			]['stack/mark-func]
			find iterators name ['stack/mark-loop]
			name = 'try			['stack/mark-try]
			name = 'try-all		['stack/mark-try-all]
			name = 'catch		['stack/mark-catch]
			'else				['stack/mark-native]
		]
		emit prefix-exec symbol
		insert-lf -2
	]
	
	emit-close-frame: func [/last][
		emit pick [stack/unwind-last stack/unwind] to logic! last
		insert-lf -1
	]
	
	emit-stack-reset: does [
		emit 'stack/reset
		insert-lf -1
	]
	
	emit-dyn-check: does [
		;emit 'stack/check-call
		;insert-lf -1
	]
	
	build-exception-handler: has [body][
		body: make block! 8
		append body [
			0					[0]
		]
		unless find expr-stack 'while-cond [
			either empty? intersect iterators expr-stack [
				append body [
					RED_THROWN_BREAK
					RED_THROWN_CONTINUE [re-throw]
				]
			][
				append body [
					RED_THROWN_BREAK    [break]
					RED_THROWN_CONTINUE [continue]
				]
			]
		]
		append body [
			RED_THROWN_RETURN
		]
		append/only body pick [
			[re-throw]
			[stack/unroll stack/FRAME_FUNCTION ctx/values: saved system/thrown: 0 exit]
		] empty? locals-stack
		
		append body [
			RED_THROWN_EXIT
		]
		append/only body pick [
			[re-throw]
			[ctx/values: saved system/thrown: 0 exit]
		] empty? locals-stack

		append body [
			default [re-throw]
		]
		reduce [body]
	]
	
	emit-function: func [name [word!] /with ctx-name [word!]][
		emit decorate-func name
		insert-lf either with [emit ctx-name -2][-1]
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
	
	emit-native: func [name [word!] /with options [block!] /local wrap? pos body][
		if wrap?: to logic! find [parse do] name [emit 'switch]
		emit join natives-prefix to word! join name #"*"
		emit 'true										;-- request run-time type-checking
		pos: either with [
			emit options
			-2 - length? options
		][
			-2
		]
		insert-lf pos - pick [1 0] wrap?
		if wrap? [emit build-exception-handler]
	]
	
	emit-exit-function: does [
		emit [
			stack/unroll stack/FRAME_FUNCTION
			ctx/values: saved
			exit
		]
		insert-lf -5
	]
	
	emit-deep-check: func [path [series!] fpath [path!] /local obj-stk list check check2 obj top? parent-ctx][
		check:  [
			'object/unchanged?
				prefix-exec path/1						;-- word (object! value)
				third obj: find objects do obj-stk		;-- class id (integer!)
		]
		check2: [
			'object/unchanged2?
				parent-ctx								;-- ctx (node!)
				get-word-index/with path/1 parent-ctx	;-- object slot in parent's ctx
				third obj: find objects do obj-stk		;-- class id
		]
		obj-stk: copy/part fpath (index? find fpath path/1) - 1
		obj-stk/1: either find-contexts path/1 ['func-objs]['objects]

		either 2 = length? path [
			append obj-stk path/1
			reduce check
		][
			list: make block! 3 * length? path
			while [not tail? next path][
				append obj-stk path/1
				repend list get pick [check check2] head? path
				parent-ctx: obj/2
				path: next path
			]
			new-line list on
			new-line skip list 3 on
			new-line/all/skip skip list 3 on 4
			reduce ['all list]
		]
	]
	
	get-RS-type-ID: func [name [word! datatype!] /word /local type][ ;-- Red type name to R/S type ID
		name: either datatype? name [form name][
			head remove back tail form name				;-- remove ending #"!"
		]
		replace/all name #"-" #"_"
		type: to word! uppercase head insert name "TYPE_"
		either word [type][select extracts/definitions type]
	]
	
	make-typeset: func [
		spec [block!] option [block! none!] f-spec [block!] native? [logic!]
		/local bs ts word bit idx name
	][
		spec: sort spec									;-- sort types to reduce cache misses
		
		either bs: find/only/skip types-cache spec 4 [
			ts: bs/2
			name: bs/3
		][
			ts: copy [0 0 0]

			foreach type spec [
				unless block? type [
					type: either word: in extracts/scalars type [get word][reduce [type]]

					foreach word type [
						bit: get-RS-type-ID name: word
						unless bit [throw-error/near ["invalid datatype name:" name] f-spec]
						idx: (bit / 32) + 1
						poke ts idx ts/:idx or shift/logical -2147483648 bit and 255
					]
				]
			]
			forall ts [ts/1: to integer! to-bin32 ts/1]	;-- convert to little-endian values
			
			idx: redbin/emit-typeset/root ts/1 ts/2 ts/3
			redirect-to literals [
				name: decorate-series-var 'ts
				emit compose [(to set-word! name) as red-typeset! get-root (idx)]
				insert-lf -5
			]
			append types-cache reduce [spec ts name idx]
		]
		spec: either option [
			option: to word! join "~" clean-lf-flag option/1
			reduce ['type-check-alt option name]
		][
			reduce ['type-check name]
		]
		if native? [
			clear back tail spec
			append spec compose [as red-typeset! get-root (any [idx bs/4])]
		]
		spec
	]
	
	emit-type-checking: func [name [word!] spec [block!] /native /local pos type][
		unless native [name: to word! next form name]	;-- remove prefix decoration
		
		either pos: any [
			find spec name
			find spec to lit-word! name
		][
			type: case [
				block? pos/2 					[pos/2]
				all [string? pos/3 block? pos/3][pos/3]
				'else 							[[default!]]
			]
			make-typeset type find/reverse pos refinement! spec to logic! native
		][
			none
		]
	]
	
	emit-argument-type-check: func [
		index [integer!] name [word!] slot [block! word! path!]
		/local spec count arg
	][
		spec: functions/:name/3
		count: 0
		forall spec [
			if find [word! lit-word! get-word!] type?/word spec/1 [
				either count = index [arg: spec/1 break][count: count + 1]
			]
		]

		emit emit-type-checking/native arg spec
		emit index
		emit slot
		insert-lf -7
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
	
	prefix-func: func [word [word!] /with path][
		if 1 < length? obj-stack [
			path: any [obj-func-call? word next any [path obj-stack]]
			word: decorate-obj-member word path
		]
		word
	]
	
	prefix-exec: func [word [word!]][
		either any [empty? locals-stack not find-contexts word][
			decorate-symbol word
		][
			decorate-exec-ctx decorate-symbol word ;-- 'exec prefix to access the word! and not the local value
		]
	]
	
	generate-anon-name: has [name][
		add-symbol name: to word! rejoin ["<anon" get-counter #">"]
		name
	]
	
	decorate-obj-member: func [word [word!] path /local value][
		parse value: mold path [some [p: #"/" (p/1: #"~") | skip]]
		to word! rejoin [value #"~" word]
	]
	
	decorate-type: func [type [word!]][
		to word! join "red-" mold/flat type
	]
	
	decorate-exec-ctx: func [name [word!]][
		append to path! 'exec name
	]
	
	decorate-symbol: func [name [word!] /no-alias /local pos][
		if all [not no-alias pos: find/case/skip aliases name 2][name: pos/2]
		to word! join "~" clean-lf-flag name
	]
	
	decorate-func: func [name [word!] /strict /local new][
		if all [not strict new: select-ssa name][name: new]
		to word! join "f_" clean-lf-flag name
	]
	
	decorate-series-var: func [name [word!] /local new list][
		new: to word! join name get-counter
		list: select lit-vars select [blk block str string ctx context ts typeset] name
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
	
	add-symbol: func [name [word!] /with original /local sym id alias][
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
				to set-word! sym 'word/load mold any [original name]
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
	
	push-call: func [name [word! tag!]][
		append expr-stack name
	]
	
	pop-call: does [
		remove back tail expr-stack
	]
	
	add-context: func [ctx [block!] /local name][
		append contexts name: decorate-series-var 'ctx
		append/only contexts ctx
		name
	]
	
	push-context: func [ctx [block!] /local name][
		append ctx-stack name: add-context ctx
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
	
	to-context-spec: func [spec [block!]][
		spec: copy spec
		forall spec [spec/1: to set-word! spec/1]
		append spec none
		make object! spec
	]
	
	iterator-pending?: does [
		not empty? intersect expr-stack iterators
	]
	
	get-obj-base: func [name [any-word!]][
		either local-word? name [func-objs][objects]
	]
	
	get-obj-base-word: func [name [any-word!]][
		either local-word? name ['func-objs]['objects]
	]
	
	find-object: func [spec [word! object!] /by-name][
		case [
			by-name [find/skip objects spec 6]
			'else	[none]
		]
	]
	
	find-proto: func [obj [block!] fun [word!] /local proto o multi?][
		if proto: obj/4 [
			all [
				multi?: 2 = length? proto				;-- multiple inheritance case
				in proto/1 fun
				in proto/2 fun
				return obj/1							;-- method redefined in spec
			]
			if in proto/1 fun [return obj/1]			;-- check <spec> prototype
			if o: find-proto find objects proto/1 fun [return o] ;-- recurse into previous prototypes
			
			unless proto/2 [return none]				;-- finish if simple inheritance case
			if in proto/2 fun [return proto/2]			;-- check <base> prototype
			if o: find-proto find objects proto/2 fun [return o] ;-- recurse into previous prototypes
		]
		none
	]
	
	search-obj: func [path [path!] /local search base fpath found?][
		search: [
			fpath: head insert copy path base
			until [									;-- evaluate nested paths from longer to shorter
				remove back tail fpath
				any [
					tail? next fpath
					object? found?: attempt [do fpath]	;-- path evaluates to an object: found!
				]
			]
		]

		base: get-obj-base-word path/1
		do search									;-- check if path is an absolute object path
		if all [not found? 1 < length? obj-stack][
			base: obj-stack
			do search								;-- check if path is a relative object path			
			unless all [
				found?
				find fpath path/1					;-- check if the start of path is in the found path (avoids false positive)
			][
				return none							;-- not an object access path
			]
		]
		reduce [found? fpath base]
	]
	
	object-access?: func [path [series!] /local res][
		either path/1 = 'self [
			bind? path/1
		][
			all [
				1 < length? obj-stack
				in do obj-stack path/1
				insert path next obj-stack			;-- insert prefix into object path
			]
			search-obj to path! path
		]
	]
	
	is-object?: func [expr /local pos][
		unless find [word! get-word! path!] type?/word expr [return none]
		any [
			attempt [do join obj-stack expr]
			all [
				find [object! word!] type?/word expr
				pos: find-object/by-name expr
				pos/2
			]
		]
	]
	
	obj-func-call?: func [name [any-word!] /local obj][
		if any [rebol-gctx = obj: bind? name find shadow-funcs obj][return no]
		select objects obj
	]
	
	obj-func-path?: func [path [path!] /local fpath base symbol found? fun origin name obj][
		either path/1 = 'self [
			found?: bind? path/1
			path: copy path
			path/1: pick find objects found? -1
			fun: head insert copy path 'objects 
			fpath: head clear next copy path
		][
			set [found? fpath base] search-obj to path! path
			unless found? [return none]

			fun: append copy fpath either base = obj-stack [ ;-- extract function access path without refinements
				pick path 1 + (length? fpath) - (length? obj-stack)
			][
				pick path length? fpath
			]
			unless function! = attempt [do fun][return none] ;-- not a function call
			remove fpath								;-- remove 'objects prefix
		]

		obj: 	find objects found?
		origin: find-proto obj last fun
		name:	either origin [select objects origin][obj/2]
		symbol: decorate-obj-member first find/tail fun fpath name

		either find functions symbol [
			fpath: next find path last fpath			;-- point to function name
			reduce [
				either 1 = length? fpath [fpath/1][copy fpath]
				symbol
				obj/2 									;-- object instance ctx name
			]
		][
			none
		]
	]
	
	system-words-path?: func [path [path! set-path!]][
		if all [
			2 < length? path
			find/match path 'system/words 
		][
			remove/part path 2
			either 1 = length? path [
				switch type?/word pc/1: load mold path [
					set-word!	[comp-set-word]
					word!		[comp-word]
					get-word!	[comp-word/literal]
				]
				path: none
			][
				bind path/1 'rebol						;-- force binding to global context
			]
		]
		path
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
	
	infix?: func [pos [block! paren!] /local specs left][
		all [
			not tail? pos
			word? pos/1
			specs: select functions pos/1
			'op! = specs/1
			not all [									;-- check if a literal argument is not expected
				word? left: pos/-1
				not local-word? left
				specs: select functions left
				literal-first-arg? specs/3				;-- literal arg needed, disable infix mode
			]
		]
	]
	
	convert-types: func [spec [block!] /local value][
		forall spec [
			if spec/1 = /local [break]					;-- avoid processing local variable
			if all [
				block? value: spec/1
				not find [integer! logic! float!] value/1 
			][
				value/1: decorate-type either value/1 = 'any-type! ['value!][value/1]
			]
		]
	]
	
	rewrite-locals: func [code [block!] /local rule s pos word ctx p?][
		parse code rule: [
			some [
				[
					'stack/push (p?: yes)
					| 'set-path* (p?: no)
					| 'eval-path (p?: no)
				] pos: (
					if #"~" = first word: form pos/1 [
						if ctx: find-contexts word: to word! next word [
							pos: either p? [back pos][pos]
							change/part pos reduce [
								'word/get-local ctx get-word-index word
							] pick [2 1] p?
							new-line pos yes
							pos: next pos				;-- skip the value
						]
					]
				) :pos
				| into rule
				| skip
			]
		]
	]
	
	find-function: func [name [word!] original [any-word!] /local entry bound?][
		all [
			entry: find functions name
			any [
				all [not bound?: local-bound? original head? functions]	;-- global case
				all [bound? not head? functions]		;-- local case
			]
			entry
		]
	]
	
	check-invalid-exit: func [name [word!]][
		if empty? locals-stack [
			pc: back pc
			throw-error [uppercase form name "used outside of a function"]
		]
	]
	
	check-redefined: func [name [word!] original [any-word!] /only /local pos entry][
		if all [not only pos: find-function name original][
			remove/part pos 2							;-- remove previous function definition
		]
		if all [
			pos: find get-obj-base name name
			not all [
				entry: local-bound? original			;-- retrieve shadow function
				block? select entry/3 name				;-- if type(s) specified, keep object definition
			]
		][
			pos/1: none
		]
	]
	
	check-func-name: func [name [word!] /local new pos][
		if find functions name [
			new: to word! append append mold/flat name "||" get-counter
			either pos: find-ssa name [
				pos/2: new
			][
				repend ssa-names [name new]
			]
			name: new
		]
		name
	]
	
	check-cloned-function: func [new [word!] /local name alter entry pos alias old type][
		if all [
			get-word? pc/1
			name: to word! pc/1	
			all [
				alter: get-prefix-func name
				entry: find functions alter
				name: alter
			]
		][
			if alter: select-ssa name [
				entry: find functions alter
			]
			repend functions [new entry/2]

			unless local-bound? pc/-1 [
				switch/default type: entry/2/1 [
					routine! [
						alias: new
						old: decorate-exec-ctx name
					]
					native! [
						alias: decorate-func new
						old: load rejoin ["red/" natives-prefix slash name #"*"]
					]
					action! [
						alias: decorate-func new
						old: load rejoin ["red/" actions-prefix slash name #"*"]
					]
				][
					alias: decorate-func new
					old: decorate-exec-ctx decorate-func name
				]
				libRedRT/collect-aliased alias old
			]
			
			either pos: find-ssa new [					;-- add the real function name as alias
				pos/2: name
			][
				repend ssa-names [new name]
			]
		]
	]
	
	check-new-func-name: func [path [path!] symbol [word!] ctx [word!] /local name][
		if any [
			set-word? name: pc/-1
			all [lit-word? name 'set = pc/-2]
		][
			name: to word! name
			repend functions [name append select functions symbol ctx]
			
			either pos: find-ssa name [					;-- add the real function name as alias
				pos/2: symbol
			][
				repend ssa-names [name symbol]
			]
		]
	]
	
	check-spec: func [spec [block!] /local symbols word pos stop locals return?][
		symbols: make block! length? spec
		locals:  0
		
		unless parse spec [
			opt string!
			any [
				pos: /local (append symbols 'local) [
					some [
						pos: word! (
							unless find symbols word: to word! pos/1 [
								append symbols word
								locals: locals + 1
							]
						)
						pos: opt block! pos: opt string!
					]
					| (
						remove pos
						clear back tail symbols
					)
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

		s: copy spec
		forall s [if any-word? s/1 [s/1: to word! s/1]]
		
		forall s [
			if all [
				word? s/1
				find next s s/1
			][
				pc: skip pc -2
				throw-error ["duplicate word definition:" s/1]
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
	
	get-prefix-func: func [name [word!] /local path word ctx][
		if 1 < length? obj-stack [
			path: copy obj-stack
			while [1 < length? path][
				if all [word: in do path name function! = get word][
					return prefix-func/with name path
				]
				remove back tail path
			]
		]
		if all [										;-- check for method case during function compilation stage
			container-obj?
			ctx: obj-func-call? name
		][
			return decorate-obj-member name ctx
		]
		name
	]
	
	add-function: func [name [word!] spec [block!] /type kind [word!] /local refs arity pos][
		set [refs arity] make-refs-table spec
		repend functions [name reduce [any [kind 'function!] arity spec refs]]
	]
	
	fetch-functions: func [pos [block!] /local name type spec refs arity nat? proto entry][
		if any [tail? pos not any-word? pos/1][
			pc: back pc
			throw-error "Non-compilable function definition"
		]
		name: to word! pos/1
		if find functions name [exit]					;-- mainly intended for 'make (hardcoded)

		switch type: pos/3 [
			native! [nat?: yes if find intrinsics name [type: 'intrinsic!]]
			action! [append actions name]
			op!     [repend op-actions [name proto: get-prefix-func to word! pos/4]]
		]
		spec: either pos/3 = 'op! [
			either entry: find functions proto [
				if all [proto <> to word! pos/4 1 < length? obj-stack][
					append entry/2 select objects do obj-stack	;-- append context name if method
				]
				entry/2/3
			][
				throw-error ["Cannot MAKE OP! from unknown function:" mold pos/4]
			]
		][
			clean-lf-deep pos/4/1
		]
		if nat? [prepare-typesets name spec]
		set [refs arity] make-refs-table spec
		repend functions [name reduce [type arity spec refs]]
	]
	
	emit-path: func [
		path [path! set-path!] set? [logic!] alt? [logic!]
		/local pos words item blk get?
	][
		either set? [
			emit-open-frame 'eval-set-path
			either alt? [								;-- object path (fallback case)
				emit [									;-- get arguments just below the stack record
					if stack/arguments > stack/bottom [stack/push stack/arguments - 1]
				]
				insert-lf -5
			][
				comp-expression							;-- fetch assigned value (normal case)
			]
		][
			emit-open-frame 'eval-path
		]
		pos: tail output
		
		if path/1 = last obj-stack [remove path]		;-- remove temp object prefix inserted by object-access?
		
		emit either integer? last path [
			pick [set-int-path* eval-int-path*] set?
		][
			pick [set-path* eval-path*] set?
		]
		path: back tail path
		while [not head? path: back path][
			emit pick [eval-int-path eval-path] integer? path/1
		]												;-- path should be at head again
		
		words: clear []
		blk: []
		forall path [
			append words either integer? item: path/1 [item][
				get?: to logic! any [head? path get-word? item]
				get-path-word item clear blk get?
			]
		]
		emit words
		
		new-line/all pos no
		new-line pos yes
		emit-close-frame
	]
	
	emit-eval-path: func [/set][
		emit 'actions/eval-path*
		emit either set ['true]['false]
		insert-lf -2
	]
	
	emit-path-func: func [body [block!] octx [word!] cnt [integer!] /local pos f-name rule arity name][
		pos: body
		body: copy pos
		clear pos
		
		if all [1 = length? body body/1 = 'stack/reset][clear body]
		rewrite-locals body
		
		name: either pos: find body 'pos [
			either body = [
				stack/push pos
				stack/reset
			][
				clear body
				2
			][
				insert body [
					pos: stack/arguments
				]
				4
			]
		][2]
		if #"~" <> first form name: pick body name [
			name: [words/_anon]
		]
		
		if all [not empty? body 'stack/unwind = last body][
			change/only back tail body 'stack/unwind-last
			new-line back tail body yes
		]
		unless any [empty? body 1 = length? body][
			arity: 0
			parse body rule: [
				some [
					'stack/push 'pos pos: '+ (
						arity: arity + 1
						either arity = 1 [pos: remove/part pos 2][pos/2: arity - 1]
					) :pos
					| into rule
					| skip
				]
			]
			redirect-to declarations [
				f-name: decorate-func to word! join "~path" cnt
				emit reduce [to set-word! f-name 'func [octx [node!] /local pos] body]
				insert-lf -4
			]
			emit compose [
				stack/defer-call (name) as-integer (to get-word! f-name) (arity) (octx)
			]
			f-name
		]
	]
	
	emit-dynamic-path: func [
		body [block!]
		/local path idx mark saved cnt frame? octx blk-idx
	][
		octx: pick [octx null] to logic! all [
			not empty? locals-stack
			container-obj?
		]
		path: first paths-stack
		blk-idx: redbin/emit-block path
		
		if frame?: all [
			not emit-path-func body octx cnt: get-counter
			not empty? expr-stack
			find [<infix> switch case] last expr-stack
		][
			emit-open-frame 'dyn-path					;-- wrap it in a stack frame in this case
		]
		emit-get-word path/1 path/1
		insert-lf -2
		saved: output
		
		forall path [
			emit [either stack/func?]
			insert-lf -2
			idx: (index? path) - 1
			emit compose/deep [[stack/push-call as red-path! get-root (blk-idx) (idx) 0 (octx)]]

			either tail? next path [
				emit [[stack/adjust]]
			][
				mark: tail output
				unless head? path [
					emit [
						stack/top: stack/top - 1
						copy-cell stack/top stack/top - 1
					]
				]
				emit-open-frame 'eval-path
				emit [stack/push stack/arguments - 1]
				insert-lf -4
				emit append to path! to word! form type? path/2 'push
				emit prefix-exec path/2
				insert-lf -2
				emit-eval-path no
				emit 'stack/unwind-part
				insert-lf -1
				change/only/part mark mark: copy mark tail output
				output: mark
			]
		]
		remove paths-stack
		output: saved
		if frame? [emit-close-frame]
	]
	
	get-return-type: func [spec [block!] /local type][	;-- for routine spec blocks
		all [
			type: select spec return-def
			find [integer! logic! float!] type/1
			type
		]
	]
	
	emit-routine: func [name [word!] spec [block!] /local type cnt offset alter][
		declare-variable/init 'r_arg to paren! [as red-value! 0]
		emit [r_arg: stack/arguments]
		insert-lf -2

		offset: 0
		if type: get-return-type spec [
			offset: 1
			append/only output append to path! form get type/1 'box
		]
		if alter: select-ssa name [name: alter]
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
				either find [integer! logic! float!] spec/2/1 [
					type: either spec/2/1 = 'float! ['float][get spec/2/1]
					append/only output append to path! form type 'get
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
	
	redirect-to: func [out [block!] body [block!] /local saved][
		saved: output
		output: out
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

	comp-literal: func [
		/inactive /with val
		/local value char? special? percent? map? tuple? name w make-block type idx
	][
		make-block: [
			value: to block! value
			either empty? ctx-stack [
				redbin/emit-block value
			][
				redbin/emit-block/with value last ctx-stack
			]
		]
		value: either with [val][pc/1]					;-- val can be NONE
		map?: map-value? :value
		
		either any [
			all [
				issue? :value
				any [
					char?:	  unicode-char? value
					special?: float-special? value
					percent?: percent-value? value
					tuple?:	  tuple-value? value
				]
			]
			scalar? :value
			map?
		][
			case [
				char? [
					emit 'char/push
					emit to integer! next value
					insert-lf -2
				]
				percent? [
					value: to decimal! to string! copy/part value back tail value
					emit 'percent/push64
					emit-float value / 100.0
					insert-lf -3
				]
				special? [
					emit 'float/push64
					emit-fp-special value
					insert-lf -3
				]
				map? [
					emit compose [map/push as red-hash! get-root (redbin/emit-block value)]
					insert-lf -3
				]
				decimal? :value [
					emit 'float/push64
					emit-float value
					insert-lf -3
				]
				tuple? [
					bin: tail reverse debase/base next value 16
					emit 'tuple/push
					emit length? head bin
					emit to integer! skip bin -4
					emit to integer! copy/part skip bin -4 -4
					emit to integer! copy/part skip bin -8 -4
					insert-lf -5
				]
				find [refinement! issue!] type?/word :value [
					add-symbol w: to word! form value
					type: to word! form type? :value
					
					either all [not issue? :value local-word? w][
						emit append to path! type 'push-local
						emit last ctx-stack
						emit get-word-index w
						insert-lf -3
					][
						emit to path! reduce [type 'push]
						emit to path! reduce ['exec decorate-symbol w]	;@@ replace by prefix-exec
						insert-lf -2
					]
				]
				none? :value [
					emit 'none/push
					insert-lf -1
				]
				any-word? :value [
					add-symbol name: to word! :value
					either all [lit-word? :value not inactive][
						emit-push-word :name :value
					][
						emit-push-word :value :value
					]
				]
				pair? :value [
					emit 'pair/push
					emit reduce [value/1 value/2]
					insert-lf -3
				]
				time? :value [
					emit 'time/push
					emit (to decimal! value) * 1E9
					insert-lf -2
				]
				'else [
					emit to path! reduce [to word! form type? :value 'push]
					emit load mold :value
					insert-lf -2
				]
			]
		][
			switch/default type?/word value [
				block!	[
					emit compose [block/push get-root (do make-block)]
					insert-lf -3
				]
				paren!	[
					emit compose [paren/push get-root (do make-block)]
					insert-lf -3
				]
				path! set-path!	[
					idx: do make-block
					case [
						inactive [
							either get-word? pc/1/1 [
								emit 'get-path/push
							][
								emit to path! reduce [to word! form type? pc/1 'push]
								if path? pc/1 [emit [as red-path!]]
							]
						]
						lit-path? pc/1 [
							emit 'path/push
							emit [as red-path!]
						]
						true [
							emit to path! reduce [to word! form type? pc/1 'push]
							if path? pc/1 [emit [as red-path!]]
						]
					]
					emit reduce ['get-root idx]
					insert-lf -3
				]
				string!	file! url! tag! email! [
					idx: redbin/emit-string/root value
					emit to path! reduce [to word! form type? value 'push]
					emit compose [as red-string! get-root (idx)]
					insert-lf -5
				]
				binary!	[
					idx: redbin/emit-string/root value
					emit 'binary/push
					emit compose [as red-binary! get-root (idx)]
					insert-lf -5
				]
			][
				throw-error ["comp-literal: unsupported type" mold value]
			]
		]
		unless with [pc: next pc]
		name
	]
	
	inherit-functions: func [							 ;-- multiple inheritance case
		new [object!] extend [object!]
		/local symbol name entry
	][
		foreach word next first extend [
			if function! = get in extend word [
				symbol: decorate-obj-member word select objects extend
				
				repend functions [
					name: decorate-obj-member word select objects new
					select functions symbol
				]
				either entry: find bodies symbol [		;-- not allowed for libRedRT client programs
					append bodies name
					append bodies bind/copy copy/part next entry 8 new
				][
					redirect-to literals [
						emit compose [#define (decorate-func name) (decorate-func symbol)]
					]
				]
				add-symbol name
			]
		]
	]
	
	comp-context: func [
		/with word
		/extend proto [object!]
		/passive only? [logic!]
		/locals
			words ctx spec name id func? obj original body pos entry symbol
			body? ctx2 new blk list path on-set-info values w defer mark blk-idx
			event pos2 loc-s loc-d shadow-path saved-pc saved set?
	][
		saved-pc: pc
		either set-path? original: pc/-1 [
			path: original
		][
			name: to word! original: any [word original]
			check-redefined/only name original
		]
		words: any [all [proto third proto] make block! 8] ;-- start from existing ctx or fresh
		list:  clear any [list []]
		values: make block! 8
		
		if proto [proto: reduce [proto]]
		
		either body?: block? pc/2 [
			parse body: pc/2 [							;-- collect words from body block
				some [
					(clear list)
					pos: set-word! (
						append list pos/1				;-- store new word
						value: pos
						until [
							value: next value
							any [tail? value not set-word? value/1]
						]
						value: value/1
						if all [not only? word? value][
							if find logic-words value [value: get value]
						]
						w: to word! pos/1
						either entry: find/skip values w 2 [ ;-- store first following value (CONSTRUCT)
							entry/2: value
						][
							repend values [w value]
						]
						func?: no
					)
					[func-constructors (func?: yes) | none] (
						foreach word list [
							either entry: find words word [
								if func? [entry/2: function!]
							][
								append words word
								append words either func? [function!][none]
							]
						]
					) | skip
				]
			]

			spec: make block! (length? words) / 2
			forskip words 2 [append spec to word! words/1]
		][
			unless extend [
				pos: tail output						;-- defer it to runtime evaluation	
				pc: next pc
				either pc/-1 = 'object! [
					emit-open-frame 'make
					emit-get-word pc/-1 pc/-1
					comp-expression
					emit-action 'make
				][
					emit-open-frame 'context
					comp-expression
					emit-function 'context
				]
				emit-close-frame
				defer: copy pos
				clear pos
				return defer
			]
			obj:    find objects proto/1				;-- simple inheritance case
			spec:   next first obj/1
			words:  third obj/1
			
			unless find [context object object!] pc/1 [
				unless new: is-object? pc/2 [
					comp-call 'make select functions 'make ;-- fallback to runtime creation
					return none
				]
				
				ctx2: select objects new				;-- multiple inheritance case
				spec: union spec next first new
				insert proto new
				
				forskip words 2 [
					if word: in new words/1 [words/2: get in new words/1]
				]
				foreach [name value] third new [
					unless find words name [repend words [name value]]
				]
			]
		]

		ctx: add-context spec
		blk-idx: redbin/emit-context/root ctx spec no yes
		
		redirect-to literals [							;-- store spec and body blocks
			emit compose [
				(to set-word! ctx) get-root-node (blk-idx)	;-- assign context
			]
			insert-lf -3
		]
		
		symbol: either path [ctx][
			if pos: find get-obj-base name name [pos/1: none] ;-- unbind word with previous object
			
			get pick [name ctx] to logic! any [			;-- ctx for object's word, else name
				rebol-gctx = obj: bind? original
				find shadow-funcs obj
			]
		]
		
		repend objects [								;-- register shadow object	
			symbol										;-- object access word
			obj: make object! words						;-- shadow object
			ctx											;-- object's context name
			id: get-counter								;-- unique object ID
			proto										;-- optional prototype object
			none										;-- [idx loc idx2 loc2...] (for events)
		]
		on-set-info: back tail objects

		shadow-path: either all [
			with
			find [lit-word! lit-path!] type?/word saved-pc/-2
			saved-pc/-3 = 'set
		][
			set?: yes
			either lit-word? saved: saved-pc/-2 [		;-- from root level
				to path! reduce ['objects to word! saved]
			][
				head insert saved 'objects
			]
		][
			join obj-stack either path [to path! path][name] ;-- account for current object stack
		]
		either path [
			unless attempt [
				do reduce [to set-path! shadow-path obj] ;-- set object in shadow tree
			][
				path: symbol							;-- undefined object path, so use ctx name
			]
		][
			unless tail? next obj-stack [				;-- set object in shadow tree (if sub-object)
				do reduce [to set-path! shadow-path obj]
			]
		]
		if body? [bind body obj]
		

		unless all [empty? locals-stack not iterator-pending?][	;-- in a function or iteration block
			emit compose [
				(to set-word! ctx) _context/clone get-root-node (blk-idx)	;-- rebuild context
			]
			insert-lf -3
		]
		
		if proto [
			if body? [inherit-functions obj last proto]
			emit reduce ['object/duplicate select objects last proto ctx]
			insert-lf -3
		]
		if all [not body? not passive][
			inherit-functions obj new
			emit reduce ['object/transfer ctx2 ctx]
			insert-lf -3
		]

		emit-src-comment/with none rejoin [mold pc/-1 " context " mold spec]

		emit-open-frame 'body
		case [
			passive [									;-- CONSTRUCT support
				bind values obj
				foreach [name value] values [
					emit-open-frame 'set
					emit-push-word name name
					comp-literal/with value
					
					emit-native/with 'set [-1 -1 -1 -1]
					emit-close-frame
				]
				pc: skip pc 2
			]
			all [body? not empty? pc/2][
				saved: copy obj-stack					;-- preserve current object stack
				either set? [
					obj-stack: append to path! 'objects any [path name] ;-- from root
				][
					append obj-stack any [path name]	;-- from current objects stack
				]
				pc: next pc
				comp-next-block yes
				obj-stack: saved						;-- restore objects stack
			]
			'else [
				pc: skip pc 2
			]
		]
		pos: none
		
		defer: reduce ['object/init-push ctx id]		;-- deferred emission
		new-line defer yes
		
		;-- events definitions processing
		loc-s: loc-d: 0
		event: 'on-change*
		if pos: find spec event [
			pos: (index? pos) - 1					;-- 0-based contexts arrays
			entry: any [
				find functions decorate-obj-member event ctx
				all [proto find functions decorate-obj-member event select objects proto/1]
			]
			unless zero? loc-s: second check-spec entry/2/3 [
				loc-s: loc-s + 1					;-- account for /local
			]
		]
		event: 'on-deep-change*
		if pos2: find spec event [
			pos2: (index? pos2) - 1					;-- 0-based contexts arrays
			entry: any [
				find functions decorate-obj-member event ctx
				all [proto find functions decorate-obj-member event select objects proto/1]
			]
			unless zero? loc-d: second check-spec entry/2/3 [
				loc-d: loc-d + 1					;-- account for /local
			]
		]
		if any [pos pos2][
			unless pos  [pos:  -1]
			unless pos2 [pos2: -1]
			change/only on-set-info reduce [pos loc-s pos2 loc-d]	;-- cache values
			repend defer ['object/init-events ctx pos loc-s pos2 loc-d]
			new-line skip defer 3 yes
		]
		
		emit 'stack/revert
		insert-lf -1
		
		defer
	]
	
	comp-object: :comp-context
	
	comp-construct: has [only? with? obj][
		only?: with?: no
		
		if all [
			path? pc/1
			not parse pc/1 [skip 2 [opt ['only (only?: yes) | 'with (with?: yes)]]] ;@@ handle duplicates
		][
			throw-error "Invalid CONSTRUCT refinement"
		]
		either with? [
			unless obj: is-object? pc/3 [--not-implemented--]
			also 
				comp-context/passive/extend only? obj
				pc: next pc
		][
			comp-context/passive only?
		]												;-- return object deferred block
	]
	
	comp-try: has [all? mark body call handlers][
		call: pick [try-all try] to logic! all?: path? pc/-1
		
		emit-open-frame 'body
		either block? pc/1 [
			emit-open-frame call
			emit [catch RED_THROWN_ERROR]
			insert-lf -2
			body: comp-sub-block 'try
			if body/1 = 'stack/reset [remove body]
			mark: tail output
			insert body mark
			clear mark
			append body [
				stack/unwind
			]
			unless all? [
				emit [switch system/thrown]
				handlers: build-exception-handler
				insert handlers/1 [
					RED_THROWN_ERROR  [
						natives/handle-thrown-error
					]
				]
				emit handlers
			]
			emit either all? [
				[
					stack/adjust-post-try
				]
			][
				[
					if system/thrown <> RED_THROWN_ERROR [stack/adjust-post-try]
				]
			]
			emit [
				system/thrown: 0
			]
		][
			emit-open-frame call						;-- fallback option
			comp-expression
			unless all? [
				emit 'switch
				insert-lf -1
			]
			emit-native/with 'try reduce [pick [0 -1] all?]
			new-line back tail output no
			unless all? [emit build-exception-handler]
			emit-close-frame
		]
		emit-close-frame
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
		comp-expression/close-path
		emit compose/deep [
			either logic/false? [(set-last-none)]
		]
		comp-sub-block 'if-body							;-- compile TRUE block
		emit-close-frame
	]
	
	comp-unless: does [
		emit-open-frame 'unless
		comp-expression/close-path
		emit [
			either logic/false?
		]
		comp-sub-block 'unless-body						;-- compile FALSE block
		append/only output set-last-none
		emit-close-frame
	]

	comp-either: does [
		emit-open-frame 'either
		comp-expression/close-path
		emit [
			either logic/true?
		]
		comp-sub-block 'either-true						;-- compile TRUE block
		comp-sub-block 'either-false					;-- compile FALSE block
		emit-close-frame
	]
	
	comp-loop: has [name set-name mark][
		depth: depth + 1
		if depth > max-depth [max-depth: depth]

		set [name set-name] declare-variable join "i" depth
		
		emit-open-frame 'loop
		comp-expression/close-path						;@@ optimize case for literal counter
		emit-argument-type-check 0 'loop 'stack/arguments
		
		emit compose [(set-name) integer/get*]
		insert-lf -2
		emit compose/deep [
			either (name) <= 0 [(set-last-none)]
		]
		mark: tail output
		emit compose [
			loop (name)
		]
		new-line skip tail output -3 off
		
		push-call 'loop
		comp-sub-block 'loop-body						;-- compile body
		pop-call

		new-line skip tail last output -3 on
		new-line skip tail last output -7 on
		depth: depth - 1
		
		convert-to-block mark
		emit-close-frame
	]
	
	comp-until: does [
		emit-open-frame 'until
		emit [
			until
		]
		push-call 'until
		comp-sub-block 'until-body						;-- compile body
		pop-call
		append/only last output 'logic/true?
		new-line back tail last output on
		emit-close-frame
	]
	
	comp-while: does [
		emit-open-frame 'while
		emit [
			while
		]
		push-call 'while-cond
		comp-sub-block 'while-condition					;-- compile condition
		append/only last output 'logic/true?
		new-line back tail last output on
		pop-call
		push-call 'while
		comp-sub-block 'while-body						;-- compile body
		pop-call
		emit-close-frame
	]
	
	comp-repeat: has [name word cnt set-cnt lim set-lim action][
		unless any-word? word: pc/1 [
			pc: back pc
			throw-error "REPEAT expects a word as first argument"
		]
		emit-open-frame 'repeat
		
		add-symbol word
		add-global word
		name: decorate-symbol word
		action: either local-word? word [
			'natives/repeat-set							;-- set the value slot on stack
		][
			'_context/set-integer						;-- set the word value in global context
		]
		
		depth: depth + 1
		if depth > max-depth [max-depth: depth]

		emit-stack-reset
		
		pc: next pc
		comp-expression/close-path						;-- compile 2nd argument
		emit-argument-type-check 1 'repeat 'stack/arguments
		
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
		emit-stack-reset
		
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
		
		push-call 'repeat
		comp-sub-block 'repeat-body
		pop-call
		insert last output reduce [action name cnt]
		new-line last output on
		emit-close-frame
		emit-close-frame
		depth: depth - 1
	]
	
	comp-forever: does [
		pc: back pc
		change/part pc [while [true]] 1
	]
		
	comp-foreach: has [word blk cond ctx idx][
		either block? pc/1 [
			;TBD: raise error if not a block of words only
			foreach word blk: pc/1 [
				add-symbol word
				add-global word
			]
			idx: either ctx: find-contexts to word! blk/1 [
				redbin/emit-block/with blk ctx
			][
				redbin/emit-block blk
			]
		][
			add-symbol word: pc/1
			add-global word
		]
		pc: next pc
		
		emit-open-frame 'foreach
		comp-expression/close-path						;-- compile series argument
		emit-argument-type-check 1 'foreach 'stack/arguments
		
		either blk [
			cond: compose [natives/foreach-next-block (length? blk)]
			emit compose [block/push get-root (idx)]		;-- block argument
		][
			cond: compose [natives/foreach-next]
			emit-push-word word	word					;-- word argument
		]
		insert-lf -2
		
		emit-open-frame 'foreach
		emit compose/deep [
			while [(cond)]
		]
		push-call 'foreach
		comp-sub-block 'foreach-body					;-- compile body
		pop-call
		emit-close-frame
		emit-close-frame
	]
	
	comp-forall: has [word name][
		name: pc/1
		word: decorate-symbol name
		emit-get-word name name							;-- save series (for resetting on end)
		emit-push-word name name						;-- word argument
		pc: next pc
		
		emit-open-frame 'forall
		emit make-typeset [series!] none functions/forall/3 yes
		emit [0 stack/arguments - 2]					;-- index of first argument
		insert-lf -9
		emit copy/deep [								;-- copy/deep required for R/S lines injection
			while [natives/forall-loop]
		]
		push-call 'forall
		comp-sub-block 'forall-body						;-- compile body
		pop-call
		
		append last output [							;-- inject at tail of body block
			natives/forall-next							;-- move series to next position
		]
		emit [
			natives/forall-end							;-- reset series
			stack/unwind
		]
	]
	
	comp-remove-each: has [word blk cond ctx idx][
		either block? pc/1 [
			;TBD: raise error if not a block of words only
			foreach word blk: pc/1 [
				add-symbol word
				add-global word
			]
			idx: either ctx: find-contexts to word! blk/1 [
				redbin/emit-block/with blk ctx
			][
				redbin/emit-block blk
			]
		][
			add-symbol word: pc/1
			add-global word
		]
		pc: next pc
		
		emit-open-frame 'remove-each
		emit [integer/push 0]							;-- store number of words to set
		insert-lf -2
		comp-expression/close-path						;-- compile series argument
		emit-argument-type-check 1 'remove-each [stack/arguments + 1]

		either blk [
			cond: compose [natives/foreach-next-block (length? blk)]
			emit compose [block/push get-root (idx)]		;-- block argument
		][
			cond: compose [natives/foreach-next]
			emit-push-word word	word					;-- word argument
		]
		insert-lf -2

		emit-open-frame 'remove-each
		if blk [
			emit 'natives/remove-each-init
			insert-lf -1
		]
		emit compose/deep [
			while [(cond)]
		]
		push-call 'remove-each
		comp-sub-block 'remove-each-body				;-- compile body
		append last output compose [
			natives/remove-each-next (either blk [length? blk][1])
		]
		pop-call
		emit-close-frame
		emit-close-frame
	]
	
	comp-break: has [inner?][
		if empty? intersect iterators expr-stack [
			pc: back pc
			throw-error "BREAK used with no loop"
		]
		if inner?: 'forall = last intersect expr-stack iterators [
			emit 'natives/forall-end-adjust
			insert-lf -1
		]
		emit compose [stack/unroll-loop (to word! form inner?) break]
		insert-lf -3
	]
	
	comp-continue: has [loops][
		if empty? loops: intersect expr-stack iterators [
			pc: back pc
			throw-error "CONTINUE used with no loop"
		]
		if 'forall = last loops [
			emit 'natives/forall-next					;-- move series to next position
			insert-lf -1
		]
		emit [stack/unroll-loop yes continue]
		insert-lf -3
		insert-lf -1
	]
	
	comp-func-body: func [
		name [word!] spec [block!] body [block!] symbols [block!] locals-nb [integer!]
		/local init locals blk args?
	][
		push-locals copy symbols						;-- prepare compiled spec block
		forall symbols [symbols/1: decorate-symbol/no-alias symbols/1]
		locals: append copy [/local ctx saved] symbols
		blk: either container-obj? [head insert copy locals [octx [node!]]][locals]
		emit reduce [to set-word! decorate-func/strict name 'func blk]
		insert-lf -3

		comp-sub-block/with 'func-body body				;-- compile function's body

		;-- Function's prolog --
		pop-locals
		init: make block! 4 * length? symbols
		
		append init compose [							;-- point context values series to stack
			ctx: TO_CTX(to paren! last ctx-stack)
			saved: ctx/values
			ctx/values: as node! stack/arguments
		]
		new-line skip tail init -4 on
		args?: yes
		
		forall symbols [								;-- assign local variable to Red arguments
			append init to set-word! symbols/1
			new-line back tail init on
			if symbols/1 = '~local [args?: no]			;-- signal end of arguments
			
			if all [
				args?
				blk: emit-type-checking symbols/1 spec
			][
				append init blk
				append init (index? symbols) - 1		;-- index of argument for the type-checker
			]
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
		if find symbols name [name: decorate-exec-ctx name]
		
		append init compose [							;-- body stack frame
			stack/mark-func-body words/_body
		]
		
		;-- Function's epilog --
		append last output compose [
			stack/unwind-last							;-- closing body stack frame, and propagating last value
			ctx/values: saved			;-- restore context values pointer
		]
		new-line skip tail last output -4 yes
		
		insert last output init
	]
	
	collect-words: func [spec [block!] body [block!] /local pos loc end ignore words word rule counter][
		if pos: find spec /extern [
			either end: any [
				find next pos refinement!
				find next pos set-word!
			][
				ignore: copy/part next pos end
				remove/part pos end
			][
				ignore: copy next pos
				clear pos
			]
			unless empty? intersect ignore spec [
				pc: skip pc -2
				throw-error ["duplicate word definition in function:" pc/1]
			]
		]
		;-- Remove local words that are duplicates of lit/get-word arguments
		if loc: find spec /local [
			pos: loc
			while [not tail? pos][
				either all [
					find [word! lit-word! get-word!] type?/word pos/1
					any [ 
						find/part spec to lit-word! pos/1 loc
						find/part spec to get-word! pos/1 loc
					]
				][
					remove pos
				][
					pos: next pos
				]
			]
		]
		
		foreach item spec [								;-- add all arguments to ignore list
			if find [word! lit-word! get-word! refinement!] type?/word item [
				unless ignore [ignore: make block! 1]
				item: to word! :item
				unless find ignore item [append ignore item]
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
						counter: pos/2
					][
						foreach word any [
							all [block? counter counter]
							all [any-word? counter reduce [counter]]
							[]
						] make-local
					]
				)
				| path! | lit-path! | set-path!
				| into rule
				| skip
			]
		]
		unless empty? words [
			pos: tail spec
			unless find spec /local [append spec /local]
			append spec words
			new-line pos yes
			new-line/all next pos no
		]
	]
	
	comp-func: func [
		/collect /does /has
		/local
			name word spec body symbols locals-nb spec-idx body-idx ctx pos octx
			src-name original global? path obj fpath shadow defer ctx-idx body-code
			alter entry mark
	][
		unless all [block? pc/2 any [does block? pc/3]][ ;-- fallback if no literal spec & body blocks
			word: pc/1
			all [
				alter: get-prefix-func word
				entry: find-function alter word
				name: alter
			]
			pc: next pc
			mark: tail output
			comp-call/thru word entry/2
			defer: copy mark
			clear mark
			return defer
		]
		original: pc/-1
		case [
			set-path? original [
				path: original
				either set [obj fpath] object-access? path [
					do reduce [join to set-path! fpath last path 'function!] ;-- update shadow object info
					obj: find objects obj
					name: to word! rejoin [any [obj/-1 obj/2] #"~" last path] 
					add-symbol name
				][
					name: generate-anon-name			;-- undetermined function assignment case
				]
			]
			find [set-word! lit-word!] type?/word :original [
				src-name: to word! original
				unless global?: all [lit-word? :original pc/-2 = 'set][
					src-name: get-prefix-func src-name
				]
				name: check-func-name src-name
				add-symbol/with word: to word! clean-lf-flag name to word! clean-lf-flag original
				unless any [
					local-word? name
					1 < length? obj-stack
				][
					add-global word
				]
			]
			'else [name: generate-anon-name]			;-- unassigned function case
		]
		
		pc: next pc
		set [spec body] pc
		case [
			collect [collect-words spec body]
			does	[body: spec spec: make block! 1 pc: back pc]
			has		[spec: head insert copy spec /local]
		]
		set [symbols locals-nb] check-spec spec
		add-function name spec
		if pos: find spec return-def [register-user-type/store name pos/2]

		
		push-locals symbols								;-- store spec and body blocks
		ctx: push-context copy symbols
		ctx-idx: redbin/emit-context/root ctx symbols yes no
		spec-idx: redbin/emit-block spec
		redirect-to literals [
			emit compose [
				(to set-word! ctx) get-root-node (ctx-idx) ;-- build context with value on stack
			]
			insert-lf -3
		]
		pop-locals

		repend shadow-funcs [							;-- register a new shadow context
			decorate-func/strict name
			shadow: to-context-spec symbols
			ctx
			spec
		]
		bind-function body shadow
		
		body-code: either job/red-store-bodies? [
			body-idx: redbin/emit-block body
			reduce ['get-root body-idx]
		][
			[null]
		]
		
		octx: either 1 < length? obj-stack [select objects do obj-stack]['null]
		if all [global? octx <> 'null][append last functions octx]	;-- add origin obj ctx to function's entry
		
		defer: compose [
			_function/push get-root (spec-idx) (body-code) (ctx)
			as integer! (to get-word! decorate-func/strict name)
			(octx)
		]
		new-line defer yes
		new-line skip tail defer -4 no
		repend bodies [									;-- save context for deferred function compilation
			name spec body symbols locals-nb 
			copy locals-stack copy ssa-names copy ctx-stack
			all [1 < length? obj-stack next first do obj-stack] ;-- save optional wrapping object
		]
		pop-context
		pc: skip pc 2
		defer
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
	
	comp-routine: has [name word spec spec* body spec-idx body-idx original ctx ret][
		name: check-func-name get-prefix-func to word! original: pc/-1
		add-symbol word: to word! clean-lf-flag name
		add-global word
		
		pc: next pc
		set [spec body] pc

		preprocess-strings body							;-- encode strings for Red/System
		check-spec spec
		add-function/type name spec 'routine!
		
		process-calls body								;-- process #call directives
		if ctx: find-binding original [
			process-routine-calls body ctx/1 spec select-object ctx/1
		]
		clear find spec*: copy spec /local
		spec-idx: redbin/emit-block spec*
		body-idx: either job/red-store-bodies? [
			reduce [redbin/emit-block body]
		][
			-1
		]
		convert-types spec
		emit reduce [to set-word! name 'func]
		insert-lf -2
		append/only output spec
		append/only output body
		
		ret: any [
			all [ret: get-return-type spec get-RS-type-ID ret/1]
			-1
		]
		
		pc: skip pc 2
		compose [
			routine/push get-root (spec-idx) get-root (body-idx) as integer! (to get-word! name) (ret) no
		]
	]
	
	comp-exit: does [
		check-invalid-exit 'exit
		pc: next pc
		emit [
			copy-cell unset-value stack/arguments
		]
		emit-exit-function
	]

	comp-return: does [
		check-invalid-exit 'return
		comp-expression
		emit-exit-function
	]
	
	comp-self: func [original [any-word!] /local obj ctx][
		either rebol-gctx = obj: bind? original [
			pc: back pc									;-- backtrack and process word again
			comp-word/thru
		][
			obj: find objects obj
			either obj/5 [
				ctx: either empty? locals-stack [obj/2]['octx]
				emit reduce ['object/push ctx obj/3 obj/5/1 obj/5/2 obj/5/3 obj/5/4] ;-- event(s) case
				insert-lf -7
			][
				emit reduce ['object/init-push obj/2 obj/3]
				insert-lf -3
			]
		]
	]
	
	comp-switch: has [mark arg body list cnt pos default? value idx][
		if path? pc/-1 [
			foreach ref next pc/-1 [
				switch/default ref [
					default [default?: yes]
					;all []
				][throw-error ["SWITCH has no refinement called" ref]]
			]
		]
		push-call 'switch
		emit-open-frame 'switch
		mark: tail output								;-- pre-compile the SWITCH argument
		comp-expression/close-path
		arg: copy mark
		clear mark
		
		body: pc/1
		if any [not block? body empty? body][
			append output arg
			comp-expression								;-- compile cases argument
			if default? [comp-expression]				;-- optionally compile /default argument
			emit-native/with 'switch reduce [pick [2 -1] to logic! default?]
			emit-close-frame
			pop-call
			exit
		]
		list: make block! 4
		cnt: 1
		parse body [									;-- build a [value index] pairs list
			any [
				block! (cnt: cnt + 1)
				| value: skip (repend list [value/1 cnt])
			]
		]
		idx: redbin/emit-block list
		
		emit-open-frame 'select-key*					;-- SWITCH lookup frame
		emit arg
		emit compose [block/push get-root (idx)]
		insert-lf -3
		emit [select-key* no no]
		insert-lf -2
		emit-close-frame
		
		emit [switch integer/get-any*]
		insert-lf -2
		
		clear list
		cnt: 1
		parse body [									;-- build SWITCH cases
			any [skip to block! pos: (
				mark: tail output
				comp-sub-block/with 'switch-body pos/1
				pc: back pc								;-- restore PC position (no block consumed)
				repend list [cnt mark/1]
				clear mark
				cnt: cnt + 1
			) skip]
		]
		pc: next pc
		
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
		pop-call
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
		push-call 'case
		
		while [not tail? pc][							;-- precompile all conditions and cases
			mark: tail output
			comp-expression/close-path					;-- process condition
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
		pop-call
	]
	
	comp-reduce: has [list into?][
		push-call 'reduce
		
		into?: path? pc/-1
		unless block? pc/1 [
			emit-open-frame 'reduce
			comp-expression							;-- compile not-literal-block argument
			if into? [comp-expression]				;-- optionally compile /into argument
			emit-native/with 'reduce reduce [pick [1 -1] into?]
			emit-close-frame
			pop-call
			exit
		]
		
		list: either empty? pc/1 [
			pc: next pc								;-- pass the empty source block
			make block! 1
		][
			comp-chunked-block						;-- compile literal block
		]
		
		either path? pc/-2 [						;-- -2 => account for block argument
			comp-expression							;-- compile /into argument
		][
			emit 'block/push-only*					;-- create a fresh new block on stack only
			emit max 1 length? list
			insert-lf -2
		]
		emit-open-frame 'reduce
		foreach chunk list [
			emit chunk
			either into? [
				emit 'block/insert-thru
				insert-lf -1
			][
				emit 'block/append-thru
				insert-lf -1
			]
			emit-stack-reset
		]
		emit-close-frame
		pop-call
		emit [stack/pop 1]
	]
	
	comp-set: has [name call any? case? only? some? w][
		either all [lit-word? pc/1 not path? pc/-1][
			name: to word! pc/1
			either local-bound? pc/1 [
				pc: next pc
				comp-local-set name
			][
				comp-set-word/native
			]
		][
			either block? pc/1 [						;-- if words are literals, register them
				foreach w pc/1 [
					unless any-word? w [throw-error ["Invalid argument to SET:" mold pc/1]]
					add-symbol w: to word! w
					unless local-word? w [add-global w]	;-- register it as global
				]
			][
				if lit-word? pc/1 [
					add-symbol w: to word! pc/1
					unless local-word? w [add-global w]	;-- register it as global
				]
			]
			call: pc/-1
			foreach [flag opt][any? any case? case only? only some? some][
				set flag pick [0 -1] to logic! all [path? call find call opt]
			]
			emit-open-frame 'set
			comp-expression
			comp-expression
			emit-native/with 'set reduce [any? case? only? some?]
			emit-close-frame
		]
	]
	
	comp-get: has [symbol original call any? case?][
		either lit-word? original: pc/1 [
			add-symbol symbol: to word! original
			either path? pc/-1 [						;@@ add check for validaty of refinements		
				emit-get-word/any? symbol original
			][
				emit-get-word symbol original
			]
			pc: next pc
		][
			call: pc/-1
			case?: to logic! all [path? call find call 'case]
			any?:  to logic! all [path? call find call 'any]
			emit-open-frame 'get
			comp-substitute-expression
			emit-native/with 'get reduce [pick [0 -1] any? pick [0 -1] case?]
			emit-close-frame
		]
	]
	
	comp-path: func [
		root? [logic!]
		/set?
		/local 
			path value emit? get? entry alter saved after dynamic? ctx mark obj?
			fpath symbol obj self? true-blk defer obj-field? parent fire index breaks
	][
		path:  copy pc/1
		emit?: yes
		set?:  to logic! set?
		
		unless path: system-words-path? path [exit]
		
		if dynamic?: find path paren! [					;-- fallback to interpreter if parens found
			emit-open-frame 'body
			if set? [
				saved: pc
				pc: next pc
				comp-expression
				after: pc
				pc: saved
			]
			comp-literal
			pc: back pc
			
			unless set? [emit [stack/mark-native words/_body]]	;@@ not clean...
			emit compose [
				interpreter/eval-path stack/top - 1 null null (to word! form set?) no (to word! form root?) no
			]
			unless set? [emit [stack/unwind-last]]
			
			emit-close-frame
			pc: either set? [after][next pc]
			exit
		]
		
		if all [not set? defer: dispatch-ctx-keywords/with pc/1/1 path/1][
			if block? defer [emit defer]
			exit
		]
		
		forall path [									;-- preprocessing path
			switch/default type?/word value: path/1 [
				word! [
					if all [
						not set? not get?
						all [
							alter: get-prefix-func value
							entry: find-function alter value
							name: alter
						]
					][
						if head? path [
							if alter: select-ssa name [entry: find functions alter]
							pc: next pc
							either ctx: any [
								obj-func-call? value
								pick entry/2 5
							][
								comp-call/with path entry/2 name ctx ;-- call function with refinements
							][
								comp-call path entry/2
							]
							exit
						]
					]
					add-symbol value					;-- ensure the word is defined in global context
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
		self?: path/1 = 'self

		if all [
			not any [set? dynamic? find path integer!]
			set [fpath symbol ctx] obj-func-path? path
		][
			either get? [
				check-new-func-name path symbol ctx
			][
				pc: next pc
				comp-call/with fpath functions/:symbol symbol ctx
				exit
			]
		]
		
		obj?: all [
			not any [dynamic? find path integer!]
			set [obj fpath] object-access? path
			obj
		]
		
		if set? [
			pc: next pc
			either obj? [									;-- fetch assigned value earlier
				unless defer: dispatch-ctx-keywords none [	;-- detect function/object declaration
					comp-expression
				]
			][
				defer: dispatch-ctx-keywords none
			]
			if block? defer [emit defer]
		]
		

		if obj-field?: all [
			obj? 
			word? last path								;-- not allow get-words to pass (#1141)
			any [self? (length? path) = length? fpath]	;-- allow only object-path/field forms
		][
			ctx: second obj: find objects obj
			unless index: get-word-index/with last path ctx [
				throw-error ["word" last path "not defined in" path]
			]
			
			true-blk: compose/deep pick [
				[[word/set-in-ctx (ctx) (index)]]
				[[word/get-local  (ctx) (index)]]
			] set?
			
			mark: none
			either self? [
				if all [not empty? locals-stack	container-obj?][
					true-blk/1/2: 'octx
				]
				mark: tail output
				emit first true-blk
			][
				emit compose [
					either (emit-deep-check path fpath) (true-blk)
				]
			]
			if all [set? obj/5 obj/5/1 <> -1][			;-- detect on-set callback 
				insert clear any [mark last output] compose [
					stack/keep							;-- save new value
					word/replace (ctx) (get-word-index/with last path ctx)	;-- push old, set new
				]
				fire: pick [
					object/loc-fire-on-set*
					object/fire-on-set*
				] to logic! local-word? first back back tail path
				
				parent: either 2 < length? path [		;-- extract word from parent context
					breaks: [-12 -9 -6 -1]
					set [obj fpath] object-access? copy/part path (length? path) - 1
					ctx: second obj: find objects obj
					['word/from ctx get-word-index/with pick tail path -2 ctx]
				][
					breaks: [-10 -7 -4 -1]				;-- word is in global context
					[decorate-symbol path/1]
				]
				repend any [mark last output] compose [
					fire
						(parent)
						decorate-exec-ctx decorate-symbol last path
				]
				append any [mark last output][
					stack/reset
				]
				foreach pos breaks [new-line skip tail any [mark last output] pos yes]
			]
		]
		mark: tail output
		
		;either any [obj? set? get? dynamic? not parse path [some word!]][
			unless self? [
				emit-path path set? to logic! any [obj? defer]
				unless obj-field? [obj?: no]			;-- static path emitted, not special anymore
			]
		;][
		;	append/only paths-stack path				;-- defer path generation
		;]
		
		if all [obj? not self?][change/only/part mark copy mark tail output]
		unless set? [pc: next pc]
	]
	
	comp-arguments: func [spec [block!] nb [integer!] /ref name [refinement!] /local word paths type][
		if ref [spec: find/tail spec name]
		paths: length? paths-stack
		
		repeat i nb [
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
						type: either all [path? pc/1 get-word? pc/1/1][
							'get-path!
						][type?/word pc/1]
						switch/default type [
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
								emit-push-word word	word	;@@ add specific type checking
								pc: next pc
							]
							lit-path! [comp-literal/inactive]
							paren! get-path! [comp-expression]
						][
							comp-literal
						]
					]
				]
				get-word! [comp-literal/inactive]
				word!     [comp-expression]
			]
			if paths < length? paths-stack [
				if 'stack/unwind = last output [i: i + 1] ;-- count nested argument with path
				repeat n nb - i + 1 [
					emit [stack/push pos +]
					emit n - 1
					insert-lf -4
				]
				return true								;-- stop compiling new arguments
			]
			spec: next spec
		]
		false
	]
		
	comp-call: func [
		call [word! path!]
		spec [block!]
		/with symbol ctx-name [word!]
		/thru
		/local 
			item name compact? refs ref? cnt pos ctx mark list offset emit-no-ref
			args option stop?
	][
		either all [not thru spec/1 = 'intrinsic!][
			switch any [all [path? call call/1] call] keywords
		][
			compact?: spec/1 <> 'function!				;-- do not push refinements on stack
			refs: make block! 1							;-- refinements storage in compact mode
			cnt: 0
			
			name: either path? call [call/1][call]
			name: to word! clean-lf-flag name
			either all [with not empty? locals-stack][	;-- only if in a function's body
				emit reduce [							;-- special case for path-generated wrapper functions
					'stack/mark-func 
					decorate-exec-ctx decorate-symbol name
				]
				insert-lf -2
			][
				emit-open-frame name
			]
			current-call: call							;-- for error reporting
			pos: pc
			comp-arguments spec/3 spec/2				;-- fetch arguments
			
			if all [path? call none? spec/4][
				pc: back pos
				throw-error [call/1 "has no refinement"]
			]
			
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
						unless stop? [
							stop?: comp-arguments/ref spec/3 pos/3 ref ;-- fetch refinement arguments
						]
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
							unless stop? [
								stop?: comp-arguments/ref spec/3 args option
							]
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
				intrinsic!								;-- fallback to native case
				native! 	[emit-native/with name refs]
				action! 	[emit-action/with name refs]
				op!			[]
				routine!	[emit-routine any [symbol name] spec/3]
				function! 	[
					emit decorate-func any [symbol name]
					insert-lf either with [emit ctx-name -2][-1]
				]
				
			]
			emit-close-frame
		]
	]
	
	comp-local-set: func [name [word!]][
		emit-open-frame 'set
		comp-expression
		emit [copy-cell stack/arguments]
		emit decorate-symbol name
		insert-lf -3
		emit-close-frame
	]
	
	comp-set-make: has [entry name][
		name: pc/-1
		switch/default pc/2 [
			datatype! [
				either pc/3 = #get-definition [
					redbin/emit-word/root/set? name none none
					redbin/emit-datatype pc/4
					pc: skip pc 4
					yes
				][
					no
				]
			]
			action!
			native! [
				either pc/3/2 = #get-definition [
					redbin/emit-word/root/set? name none none
					either pc/2 = 'action! [
						redbin/emit-native/action pc/3/3 pc/3/1
					][
						redbin/emit-native pc/3/3 pc/3/1
					]
					fetch-functions back pc
					pc: skip pc 3
					yes
				][
					no
				]
			]
			op! [
				;entry: select functions to word! pc/3
				;either find [action! native!] entry/1 [
				;	name: to set-word! pc/3
				;	redbin/emit-word/root/set? name none none
				;	redbin/emit-op name
				;	fetch-functions back pc
				;	pc: skip pc 3
				;	yes
				;][
					no
				;]
			]
			typeset! [
				no
			]
		][
			no
		]
	]
	
	comp-set-word: func [
		/native
		/local 
			name value ctx original obj obj-bound? deep? inherit? proto
			defer mark start take-frame preset?
	][
		name: original: pc/1
		pc: next pc
		unless local-word? name: to word! clean-lf-flag name [
			add-symbol name
			add-global name
		]
		
		if infix? pc [
			emit-push-word original original
			exit
		]
		if all [not booting? find intrinsics name][
			throw-error ["attempt to redefine a keyword:" name]
		]
		
		obj-bound?: all [
			rebol-gctx <> obj: bind? original
			not find shadow-funcs obj
		]
		deep?: 1 < length? obj-stack
		mark: tail output
		take-frame: [start: copy mark clear mark not block? pc/1]
		
		;-- Try to push the name/value pair into Redbin data --
		all [
			not deep?
			rebol-gctx = obj
			empty? expr-stack
			pc/1 = 'make
			comp-set-make
			exit
		]
		
		if all [word? name not path? pc/1 word? pc/1 is-object? pc/1][
			register-object/store pc/1 name
		]
		;-- General case: emit stack-oriented construction code --
		emit-open-frame 'set
		
		either native [									;-- 1st argument
			pc: back pc
			comp-expression								;-- fetch a value
		][
			unless obj-bound? [
				emit-push-word name	original 			;-- push set-word
			]
		]
		
		push-call 'set
		case [
			all [
				pc/1 = 'make
				any [pc/2 = 'object! proto: is-object? pc/2]
			][
				do take-frame
				check-redefined name original
				pc: next pc
				defer: either proto [
					comp-context/with/extend original proto
				][
					comp-context/with original
				]
				unless defer [insert mark start]		;-- restore beginning of frame
			]
			all [
				any [word? pc/1 path? pc/1]
				do take-frame
				defer: dispatch-ctx-keywords/with original pc/1
			][]
			'else [
				if start [emit start]
				unless obj-bound? [check-redefined name original]
				check-cloned-function name
				comp-substitute-expression				;-- fetch a value (2nd argument)
			]
		]
		pop-call
		
		if block? defer [								;-- object or function case
			emit start
			emit defer
		]
		
		either native [
			emit-native/with 'set [-1 -1 -1 -1]			;@@ refinement not handled yet
		][
			either all [obj-bound? ctx: select objects obj][
				emit 'word/set-in
				emit either parent-object? obj ['octx][ctx] ;-- optional parametrized context reference (octx)
				emit get-word-index/with name ctx
				insert-lf -3
			][
				emit 'word/set
				insert-lf -1
			]
		]
		emit-close-frame
	]

	comp-word: func [/literal /final /thru /local name local? alter emit-word original new ctx defer][
		name: to word! original: pc/1
		local?: local-bound? original
		
		emit-word: [
			either lit-word? original [					;@@
				emit-push-word name original
			][
				either literal [
					emit-get-word/literal name original
				][
					emit-get-word name original
				]
			]
		]
		
		if defer: dispatch-ctx-keywords original [
			if block? defer [emit defer]
			exit
		]
		pc: next pc										;@@ move it deeper
		
		case [
			all [not thru name = 'exit	][comp-exit]
			all [not thru name = 'return][comp-return]
			all [not thru name = 'self	][comp-self original]
			all [
				not final
				not local?
				name = 'make
				word? pc/1
				any-function? pc/1
			][
				fetch-functions skip pc -2				;-- extract functions definitions
				pc: back pc
				comp-word/final
			]
			all [
				not literal
				not local?
				any [
					all [
						alter: get-prefix-func original
						entry: find functions alter
						name: alter
					]
					all [
						rebol-gctx = bind? original
						entry: find functions name
					]
				]
			][
				if alter: select-ssa name [entry: find functions alter]
				
				either ctx: any [
					obj-func-call? original
					pick entry/2 5
				][
					comp-call/with name entry/2 name ctx
				][
					comp-call name entry/2
				]
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
	
	check-infix-operators: func [
		root? [logic!]
		/local name op pos end ops spec substitute cnt paths single?
	][
		if infix? pc [return false]						;-- infix op already processed,
														;-- or used in prefix mode.
		if infix? next pc [
			substitute: [
				if paths < length? paths-stack [
					emit [stack/push pos +]
					emit cnt
					insert-lf -4
					cnt: cnt + 1
				]
			]
			cnt: 0
			pos: pc
			end: search-expr-end pos					;-- recursive search of expression end
			
			ops: make block! 1
			pos: end									;-- start from end of expression
			until [
				op: pos/-1			
				name: any [select op-actions op op]
				insert ops name							;-- remember ops in left-to-right order
				emit-open-frame op
				pos: skip pos -2						;-- process next previous op
				pos = pc								;-- until we reach the beginning of expression
			]
			paths: length? paths-stack
			comp-expression/no-infix					;-- fetch first left operand
			do substitute
			pc: next pc

			forall ops [
				paths: length? paths-stack
				single?: path? pc/1
				comp-expression/no-infix				;-- fetch right operand
				if single? [do substitute]
				
				name: ops/1
				spec: functions/:name
				switch/default spec/1 [
					function! [
						emit decorate-func name
						insert-lf either spec/5 [emit spec/5 -2][-1]
					]
					routine!  [emit-routine name spec/3]
				][
					emit make-func-prefix name
					insert-lf either spec/1 = 'native! [emit 'yes -2][-1] ;-- request run-time type-checking
				]
				
				emit-close-frame
				unless tail? next ops [pc: next pc]		;-- jump over op word unless last operand
			]
			return true									;-- infix expression processed
		]
		false											;-- not an infix expression
	]
	
	prepare-typesets: func [name [word!] spec [block!] /local list cnt arg expr][
		list: insert make block! 10 [0 0x0]				;-- insert fake debug header info
		cnt: 0
		
		parse spec [
			any [
				set arg [word! | lit-word! | get-word!] (
					append list compose [
						(emit-type-checking/native arg spec)
						(cnt)
						stack/arguments
					]
					new-line back tail list off
					insert-lf either cnt > 0 [
						expr: to paren! compose [stack/arguments + (cnt)]
						expr: insert expr [0 0x0]		;-- insert fake debug header info				
						change/only back tail list expr
						-5
					][-3]
					cnt: cnt + 1
				)
				| refinement! (cnt: cnt + 1)
				| skip
			]
		]
		unless empty? list [
			list: insert list [0 0x0]
			list: reduce ['if 'check? list]
			repend native-ts [name list]
		]
	]
		
	process-typecheck-directive: func [spec [word! block!] /local name res pos refs][
		name: either block? spec [spec/1][spec]
		if pos: select [								;-- words protected from macro replacement
			-unless-	unless
			-forever-	forever
			-does-		does
			-prin-		prin
			-positive?-	positive?
			-negative?-	negative?
			-max-		max
			-min-		min
			-zero?-     zero?
		] name [
			name: pos
		]
		res: select native-ts name
		
		if all [res block? spec][
			refs: functions/:name/4
			spec: next spec
			parse res/3 [								;-- rewrite checks for optional args
				some [
					pos: 'type-check-alt (
						if tail? spec [throw-error ["missing values in #typecheck block:" spec]]
						pos/1: 'type-check-opt
						pos/2: pick spec select refs to refinement! next form pos/2
						remove at pos 8
						new-line pos yes
					) 2 skip
					| skip
				]
			]
		]
		res
	]
	
	process-get-directive: func [
		spec code [block!] /local obj fpath ctx blk idx
	][
		switch/default type?/word spec [
			path! [
				unless parse spec [some word!][
					throw-error ["invalid #get argument:" spec]
				]
				set [obj fpath] object-access? spec
				ctx: second obj: find objects obj
				unless idx: get-word-index/with last spec ctx [return none]
				remove/part code 2
				blk: [red/word/get-in (decorate-exec-ctx ctx) (idx)]
				insert code compose blk
			]
			word! [
				remove/part code 2
				insert code compose [red/word/get (decorate-exec-ctx decorate-symbol spec)]
			]
		][throw-error ["invalid #get argument:" spec]]
	]
	
	process-in-directive: func [
		path word code [block!] /local obj fpath ctx blk idx
	][
		if any [not path? path not any-word? :word][
			throw-error ["invalid #in argument:" mold path mold :word]
		]
		append path word
		set [obj fpath] object-access? path
		ctx: second obj: find objects obj
		unless idx: get-word-index/with word ctx [return none]
		remove/part code 3
		blk: [red/object/get-word (decorate-exec-ctx ctx) (idx)]
		insert code compose blk
	]
	
	process-call-directive: func [
		body [block!] global?
		/local name spec cmd types type arg path ctx offset
	][
		name: body/1
		switch/default type?/word name [
			word! [name: to word! clean-lf-flag name]
			path! [set [path name ctx] obj-func-path? body/1]
		][
			throw-error ["invalid function name in #call:" mold body]
		]
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
			type: none
			types: find/tail types word!
			if block? types/1 [
				either 1 = length? types/1 [
					type: types/1/1
				][
					arg: body/1
					if word? arg [arg: attempt [get arg]]
					type: none
					foreach value types/1 [
						if value = type?/word arg [type: value break]
					]
				]
				if type = 'any-type! [type: none]
			]
			offset: either type [
				cmd: to path! reduce [to word! form get type 'push]
				if global? [insert cmd pick [exec red] type = 'event!] ;@@ ad-hoc treatment of event!...
				-1
			][
				cmd: [red/stack/push as cell!]
				-3
			]
			emit cmd
			insert-lf offset
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
					emit 'red/logic/push 
					emit to word! form to logic! all [
						path? path
						find path to word! types/1
					]
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
		insert-lf either ctx [emit decorate-exec-ctx ctx -2][-1]
		
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
	
	in-cache?: func [file [file!] /local path][
		either encap? [
			if exists?-cache file [return yes]
			if any [not value? 'script-path not script-path][return no]
			
			path: either slash = first script-path [
				skip script-path length? system/script/path
			][
				script-path
			]
			exists?-cache secure-clean-path join path file
		][
			no
		]
	]

	comp-directive: has [file saved version mark script-file cache?][
		switch pc/1 [
			#include [
				unless file? file: pc/2 [
					throw-error ["#include requires a file argument:" pc/2]
				]
				cache?: in-cache? file
				append include-stk script-path
				
				script-path: either all [not booting? relative-path? file][
					file: clean-path join any [script-path main-path] file
					first split-path file
				][
					none
				]
				
				unless any [cache? booting? exists? file][
					throw-error ["include file not found:" pc/2]
				]
				either find included-list file [
					script-path: take/last include-stk
					remove/part pc 2
				][
					script-file: file
					if all [slash <> first file	script-path][
						script-file: clean-path join script-path file
					]
					append script-stk script-file
					emit reduce [						;-- force a newline at head
						#script script-file
					]
					saved: script-name
					insert skip pc 2 #pop-path
					src: load-source/header file
					src: preprocessor/expand src job
					change/part pc next src 2			;@@ Header skipped, should be processed
					script-name: saved
					append included-list file
					unless empty? expr-stack [comp-expression]
				]
				true
			]
			#pop-path [
				take/last script-stk
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
				emit reduce [							;-- force a newline at head
					#script script-name
				]
				mark: tail output
				emit pc/2
				new-line mark on
				emit reduce [							;-- force a newline at head
					#script script-name
				]
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
				repend sys-global [						;-- force a newline at head
					#script script-name
				]
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
				change pc form load-cache %version.r
				comp-expression
				true
			]
			#build-date [
				change pc mold now
				comp-expression
				true
			]
			#build-config [
				change/only pc load find mold job #"["
				comp-expression
				true
			]
			#register-intrinsics [						;-- internal boot-level directive
				if booting? [
					pc: next pc
					make-keywords						;-- register intrinsics functions
				]
				booting?
			]
		]
	]
	
	comp-substitute-expression: has [paths mark][
		paths: length? paths-stack
		mark: tail output
		
		comp-expression
		
		if all [
			paths < length? paths-stack
			not find mark [stack/push pos]
		][
			emit [stack/push pos + 0]
			insert-lf -4
		]
		mark: none
	]
	
	comp-expression: func [/no-infix /root /close-path /local out paths][
		root: to logic! root 
		if any [root close-path][out: tail output]
		paths: length? paths-stack
		
		unless no-infix [
			if check-infix-operators root [
				if all [any [root close-path] paths < length? paths-stack][
					emit-dynamic-path out
					push-call <infix>
					loop length? paths-stack [
						emit-dynamic-path make block! 0
					]
					pop-call
					if tail? pc [emit-dyn-check]
				]
				if all [root 'stack/reset <> last output][
					emit-stack-reset					;-- clear stack from last root expression result
				]
				exit
			]

		]
		if tail? pc [
			pc: any [find/reverse pc current-call back pc]
			throw-error "missing argument"
		]
		
		switch/default type?/word pc/1 [
			issue!		[
				either all [
					issue? pc/1
					any [
						unicode-char?  pc/1
						float-special? pc/1
						percent-value? pc/1
					]
				][
					comp-literal						;-- issue! used for special encoding
				][
					unless comp-directive [comp-literal]
				]
			]
			;-- active datatypes with specific literal form
			set-word!	[comp-set-word]
			word!		[comp-word]
			get-word!	[comp-word/literal]
			paren!		[comp-next-block root]
			set-path!	[comp-path/set? root]
			path! 		[comp-path root]
		][
			comp-literal
		]
		if root [
			either tail? pc	[
				unless find/only [stack/reset stack/unwind] last output [
					emit-dyn-check
				]
			][
				if 'stack/reset <> last output [
					emit-stack-reset					;-- clear stack from last root expression result
				]
			]
		]
		if any [root close-path][
			if paths < length? paths-stack [
				emit-dynamic-path out
				if tail? pc [emit-dyn-check]
			]
		]
	]
	
	comp-next-block: func [root? [logic!] /with blk /local saved pos][
		saved: pc
		pc: any [blk pc/1]
		
		comp-block
		
		unless root? [
			case [
				'stack/reset = last output [remove back tail output]
				all [
					comment-marker = pick tail output -2
					'stack/reset = pick tail output -3
				][
					remove skip tail output -3
				]
			]
		]
		pc: next saved
	]
	
	comp-chunked-block: has [list mark saved][
		list: make block! 10
		saved: pc
		pc: pc/1										;-- dive in nested code
		mark: tail output
		
		comp-block/with [
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
		/local expr size
	][
		if tail? pc [
			emit 'unset/push
			insert-lf -1
			exit
		]
		while [not tail? pc][
			expr: pc
			either no-root [comp-expression][comp-expression/root]
			
			if all [verbose > 3 positive? size: offset? expr pc][probe copy/part expr size]
			if verbose > 0 [emit-src-comment expr]
			
			if with [do body]
		]
	]
	
	register-object: func [obj [word!] name /store /local pos prev entry][
		if pos: find-object/by-name obj [
			;if prev: find get-obj-base name name [prev/1: none] ;-- unbind word with previous object

			insert entry: tail objects copy/part pos 6
			entry/1: to word! name			;@@ set-path! case
			if store [
				obj: entry/2
				either set-path? name [
					do reduce [to set-path! join obj-stack to path! name obj] ;-- set object in shadow tree
				][
					unless tail? next obj-stack [		;-- set object in shadow tree (if sub-object)
						do reduce [to set-path! join obj-stack name obj]
					]
				]
			]
		]
	]
	
	register-user-type: func [name [any-word! set-path!] spec [block!] /store /local found? types pos prev entry obj][
		found?: no
		types: spec
		
		forall types [
			if #"!" <> last mold types/1 [				;-- enforce trailing ! convention
				throw-error ["invalid type specified:" mold spec]
			]
			if pos: find/skip objects types/1 6 [
				if found? [throw-error ["unsupported multiple object type spec:" mold spec]]
				if prev: find get-obj-base name name [prev/1: none] ;-- unbind word with previous object

				insert entry: tail objects copy/part pos 6
				entry/1: to word! name			;@@ set-path! case
				types/1: 'object!
				
				if store [
					obj: entry/2
					either set-path? name [
						do reduce [to set-path! join obj-stack to path! name obj] ;-- set object in shadow tree
					][
						unless tail? next obj-stack [		;-- set object in shadow tree (if sub-object)
							do reduce [to set-path! join obj-stack name obj]
						]
					]
				]
				found?: yes
			]
		]
	]
	
	preprocess-types: func [name spec [block!] /local pos][
		parse spec [
			any [pos: word! block! (register-user-type pos/1 pos/2) | skip]
		]
	]
	
	comp-bodies: does [
		obj-stack: to path! 'func-objs
		
		foreach [name spec body symbols locals-nb stack ssa ctx obj?] bodies [
			locals-stack: stack
			ssa-names: ssa
			ctx-stack: ctx
			container-obj?: obj?
			func-objs: tail objects
			depth: max-depth
			preprocess-types name spec

			comp-func-body name spec body copy symbols locals-nb ;-- copy avoids symbols corruption by decoration
		]
		clear locals-stack
		clear ssa-names
		func-objs: none
	]
	
	comp-init: does [
		redbin/init
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
	
	comp-finish: does [
		redbin/finish pick [[compress] []] to logic! redc/load-lib?
	]
	
	comp-source: func [code [block!] /local user main saved mods][
		output: make block! 10000
		comp-init
		
		pc: next preprocessor/expand/clean load-source/hidden %boot.red job ;-- compile Red's boot script
		unless job/red-help? [clear-docstrings pc]
		booting?: yes
		comp-block
		booting?: no
		
		mods: tail output
		append output [#user-code]
		foreach module needed [
			saved: if script-path [copy script-path]
			script-path: first split-path module
			pc: next preprocessor/expand load-source/hidden module job
			unless job/red-help? [clear-docstrings pc]
			comp-block
			script-path: saved
		]

		pc: code										;-- compile user code
		user: tail output
		comp-block
		append output [#user-code]
		
		main: output
		output: make block! 1000
		
		comp-bodies										;-- compile deferred functions
		comp-finish
		libRedRT/save-extras
		
		reduce [user mods main]
	]
	
	comp-as-lib: func [code [block!] /local user main mark defs pos ext-ctx][
		out: copy/deep [
			Red/System [
				type:   'dll
				origin: 'Red
			]
			
			with red [
				exec: context [
					<declarations>
					<script>
				]
			]
		]
		
		set [user mark main] comp-source code

		defs: make block! 10'000
		foreach [type cast][
			block	red-block!
			string	red-string!
			context node!
			typeset	red-typeset!
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
			obj: as red-object! 0
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
		
		pos: third last out
		change find pos <script> script
		remove pos: find pos <declarations>
		insert pos defs
		
		output: out	
		if verbose > 2 [?? output]
	]
	
	comp-as-exe: func [code [block!] /local out user mods main defs][
		out: copy/deep either job/dev-mode? [[
			Red/System [origin: 'Red]

			<imports>

			with red [
				root-base: redbin/boot-load system/boot-data yes
				exec: context <script>
			]
		]][[
			Red/System [origin: 'Red]

			red/init
			
			with red [
				exec: context <script>
			]
		]]
		
		if all [job/dev-mode? not job/libRedRT?][
			replace out <imports> libRedRT/get-include-file job
		]
		set [user mods main] comp-source code
		
		;-- assemble all parts together in right order
		script: make block! 100'000
		
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
	
	clear-docstrings: func [script [block!] /local clean rule pos][
		clean: [any [pos: string! (remove pos) | skip]]
		
		parse script rule: [
			some [
				['action! | 'native!] into [into clean]
				| ['func | 'function | 'routine] into clean
				| into rule
				| skip
			]
		]
	]
	
	load-source: func [file [file! block!] /hidden /header /local src][
		if all [encap? header slash = first file not exists? file][
			file: head remove/part copy file length? system/script/path
		]
		either file? file [
			unless hidden [script-name: file]
			src: lexer/process read-cache file
		][
			unless hidden [script-name: 'in-memory]
			src: file
		]
		src
	]
	
	process-config: func [header [block!] /local spec][
		if spec: select header first [config:][
			do bind spec job
			if job/command-line [do bind job/command-line job]		;-- ensures cmd-line options have priority
		]
		if all [job/type = 'dll job/OS <> 'Windows][job/PIC?: yes]	;-- ensure PIC mode is enabled
	]
	
	process-needs: func [header [block!] src [block!] /local list file mods][
		either all [
			list: select header first [Needs:]
			find [word! lit-word! block!] type?/word list	;-- do not process other types
		][
			unless block? list [list: reduce [list]]
			job/modules: list
			mods: make block! 2
			
			foreach mod list [
				unless file: find standard-modules mod [
					throw-error ["module not found:" mod]
				]
				all [
					any [file/3 = 'all find file/3 job/OS]
					not find needed file/2
					append needed file/2
				]
			]
		][
			job/modules: make block! 0
		]
		if all [
			job/OS = 'Windows
			job/sub-system = 'GUI
			not find job/modules 'View
		][
			throw-error "Windows target requires View module (`Needs: View` in the header)"
		]
	]
	
	clean-up: does [
		clear include-stk
		clear included-list
		clear script-stk
		clear needed
		clear symbols
		clear aliases
		clear globals
		clear sys-global
		clear contexts
		clear ctx-stack
		clear objects
		obj-stack: to path! 'objects					;-- reset it to original value
		clear paths-stack
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
		clear lit-vars/typeset
		clear types-cache
		clear shadow-funcs
		clear native-ts
		s-counter: 0
		depth:	   0
		max-depth: 0
		redbin/index: 0									;-- required here by libRedRT
		container-obj?:
		script-path:
		script-file:
		main-path: none
	]

	compile: func [
		file [file! block!]								;-- source file or block of code
		opts [object!]
		/local time src resources defs
	][
		verbose: opts/verbosity
		job: opts
		clean-up
		main-path: first split-path any [all [block? file system/options/path] file]
		resources: make block! 8

		time: dt [
			src: load-source file
			job/red-pass?: yes
			process-config src/1
			preprocessor/expand/clean src job
			if job/show = 'expanded [probe next src]
			process-needs src/1 next src
			extracts/init job
			if job/libRedRT? [libRedRT/init]
			if file? file [system-dialect/collect-resources src/1 resources file]
			src: next src
			
			if all [job/dev-mode? not job/libRedRT?][
				defs: libRedRT/get-definitions
				append clear functions defs/1
				;redbin/index:	defs/2
				globals:		defs/3
				objects:		compose/deep bind objects: defs/4 red
				contexts:		defs/5
				actions:		defs/6
				op-actions:		defs/7
				foreach w defs/8 [add-symbol w]
				append literals defs/9
				s-counter:		defs/10
				needed: 		exclude needed defs/11	;-- exclude already compiled modules
				make-keywords
			]
			either job/type = 'dll [comp-as-lib src][comp-as-exe src]
		]
		reduce [output time redbin/buffer resources]
	]
]
