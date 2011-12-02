REBOL [
	Title:   "Red/System compiler"
	Author:  "Nenad Rakocevic"
	File: 	 %compiler.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

do %utils/r2-forward.r
do %utils/int-to-bin.r
do %utils/virtual-struct.r
do %utils/secure-clean-path.r
do %linker.r
do %emitter.r

system-dialect: context [
	verbose:  	  0									;-- logs verbosity level
	job: 		  none								;-- reference the current job object	
	runtime-path: %runtime/
	nl: 		  newline
	
	loader: do bind load %loader.r 'self
	
	compiler: context [
		job:		 none								;-- shortcut for job object
		pc:			 none								;-- source code input cursor
		script:		 none								;-- source script file name
		none-type:	 [#[none]]							;-- marker for "no value returned"
		last-type:	 none-type							;-- type of last value from an expression
		locals: 	 none								;-- currently compiled function specification block
		locals-init: []									;-- currently compiler function locals variable init list
		func-name:	 none								;-- currently compiled function name
		block-level: 0									;-- nesting level of input source block
		verbose:  	 0									;-- logs verbosity level
	
		imports: 	   make block! 10					;-- list of imported functions
		natives:	   make hash!  40					;-- list of functions to compile [name [specs] [body]...]
		globals:  	   make hash!  40					;-- list of globally defined symbols from scripts
		aliased-types: make hash!  10					;-- list of aliased type definitions
		
		resolve-alias?: yes								;-- YES: instruct the type resolution function to reduce aliases
		
		debug-lines: reduce [							;-- runtime source line/file information storage
			'records make block!  1000					;-- [address line file] records
			'files	 make hash!   20					;-- filenames table
		]
		
		pos:		none								;-- validation rules cursor for error reporting
		return-def: to-set-word 'return					;-- return: keyword
		fail:		[end skip]							;-- fail rule
		rule: value: none								;-- global parsing rules helpers
		
		not-set!:	  [logic! integer!]								  ;-- reserved for internal use only
		number!: 	  [byte! integer!]								  ;-- reserved for internal use only
		pointers!:	  [pointer! struct! c-string!] 					  ;-- reserved for internal use only
		any-pointer!: union pointers! [function!]		  			  ;-- reserved for internal use only
		poly!:		  union number!	pointers!					  	  ;-- reserved for internal use only
		any-type!:	  union poly! [logic!]							  ;-- reserved for internal use only
		type-sets:	  [not-set! number! poly! any-type! any-pointer!] ;-- reserved for internal use only
		
		comparison-op: [= <> < > <= >=]
		
		functions: to-hash [
		;--Name--Arity--Type----Cc--Specs--		   Cc = Calling convention
			+		[2	op		- [a [poly!]   b [poly!]   return: [poly!]]]
			-		[2	op		- [a [poly!]   b [poly!]   return: [poly!]]]
			*		[2	op		- [a [number!] b [number!] return: [number!]]]
			/		[2	op		- [a [number!] b [number!] return: [number!]]]
			and		[2	op		- [a [number!] b [number!] return: [number!]]]
			or		[2	op		- [a [number!] b [number!] return: [number!]]]
			xor		[2	op		- [a [number!] b [number!] return: [number!]]]
			//		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- modulo
			///		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- remainder (real syntax: %)
			>>		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- shift left signed
			<<		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- shift right signed
			-**		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- shift right unsigned
			=		[2	op		- [a [any-type!] b [any-type!]  return: [logic!]]]
			<>		[2	op		- [a [any-type!] b [any-type!]  return: [logic!]]]
			>		[2	op		- [a [poly!]   b [poly!]   return: [logic!]]]
			<		[2	op		- [a [poly!]   b [poly!]   return: [logic!]]]
			>=		[2	op		- [a [poly!]   b [poly!]   return: [logic!]]]
			<=		[2	op		- [a [poly!]   b [poly!]   return: [logic!]]]
			not		[1	inline	- [a [not-set!] 		   return: [logic!]]]	;@@ return should be not-set!
			push	[1	inline	- [a [any-type!]]]
			pop		[0	inline	- [						   return: [integer!]]]
		]
		
		user-functions: tail functions					;-- marker for user functions
		
		action-class: context [action: type: data: none]
		
		struct-syntax: [
			pos: opt [into ['align integer! opt ['big | 'little]]]	;-- struct's attributes
			pos: some [word! into type-spec]						;-- struct's members
		]
		
		pointer-syntax: ['integer! | 'byte!]
		
		func-pointer: ['function! set value block! (check-specs '- value)]
		
		type-syntax: [
			'logic! | 'int32! | 'integer! | 'uint8! | 'byte! | 'int16!
			| 'c-string!
			| 'pointer! into [pointer-syntax]
			| 'struct!  into [struct-syntax]
		]

		type-spec: [
			pos: some type-syntax | set value word! (			;-- multiple types allowed for internal usage			
				unless find aliased-types value [throw false]	;-- stop parsing if unresolved type
			)
		]		
		
		keywords: [
			;&			 [throw-error "reserved for future use"]
			as			 [comp-as]
			assert		 [comp-assert]
			size? 		 [comp-size?]
			if			 [comp-if]
			either		 [comp-either]
			until		 [comp-until]
			while		 [comp-while]
			any			 [comp-expression-list]
			all			 [comp-expression-list/_all]
			exit		 [comp-exit]
			return		 [comp-exit/value]
			true		 [also true pc: next pc]		  ;-- converts word! to logic!
			false		 [also false pc: next pc]		  ;-- converts word! to logic!
			func 		 [raise-level-error "a function"] ;-- func declaration not allowed at this level
			function 	 [raise-level-error "a function"] ;-- func declaration not allowed at this level
			alias 		 [raise-level-error "an alias"]	  ;-- alias declaration not allowed at this level
			declare		 [comp-declare]
			null		 [comp-null]
		]
		
		calc-line: has [idx head-end prev p header][
			header: head pc
			idx: (index? pc) - header/1  				;-- calculate real pc position (not counting hidden header)
			prev: 1

			parse header [								;-- search for closest line marker
				skip									;-- skip over header length
				some [
					set p pair! (
						if p/2 = idx [return p/1]		;-- exact value position match
						if p/2 > idx [return prev]		;-- closest value position match 
						prev: p/1
					)
				]
			]
			return p/1									;-- return last marker
		]
		
		store-dbg-lines: has [dbg pos][
			dbg: debug-lines
			unless pos: find dbg/files script [
				pos: tail dbg/files
				append dbg/files script
			]
			repend dbg/records [
				emitter/tail-ptr calc-line index? pos
			]
		]
		
		throw-error: func [err [word! string! block!] /loader][
			print [
				"***" pick ["Loading" "Compilation"] to logic! loader "Error:"
				either word? err [
					join uppercase/part mold err 1 " error"
				][reform err]
				"^/*** in file:" mold script
				either locals [join "^/*** in function: " func-name][""]
			]
			if pc [
				print [
					"*** at line:" calc-line lf
					"*** near:" mold copy/part pc 8
				]
			]
			clean-up
			if system/options/args [quit/return 1]
			halt
		]
		
		throw-warning: func [msg [string! block!] /at mark][
			print [
				"*** Warning:" reform msg
				"^/*** in:" mold script
				"^/*** at: " mold copy/part any [all [at find/reverse pc mark] pc] 8
			]
		]
		
		raise-level-error: func [kind [string!]][
			pc: back pc
			throw-error reform ["declaring" kind "at this level is not allowed"]
		]
		
		raise-casting-error: does [
			backtrack 'as
			throw-error "multiple type casting not allowed"
		]
		
		raise-paren-error: does [
			pc: back pc
			throw-error "parens are only allowed nested in an expression"
		]
		
		backtrack: func [value /local res][
			pc: any [res: find/only/reverse pc value pc]
			to logic! res
		]
		
		blockify: func [value][either block? value [value][reduce [value]]]

		literal?: func [value][
			not any [word? value path? value block? value value = <last>]
		]
		
		not-initialized?: func [name [word!] /local pos][
			all [
				locals
				pos: find locals /local
				pos: find next pos name
				not find locals-init name
			]
		]
		
		get-alias-id: func [pos [hash!]][
			1000 + divide 1 + index? pos 2
		]
		
		get-type-id: func [value /local type alias][
			with-alias-resolution off [type: resolve-expr-type value]
			
			either alias: find aliased-types type/1 [
				get-alias-id alias
			][
				type: resolve-aliased type
				type: either type/1 = 'pointer! [
					pick [int-ptr! byte-ptr!] type/2/1 = 'integer!
				][
					type/1
				]
				select emitter/datatype-ID type
			]
		]
		
		system-reflexion?: func [path [path!] /local def][	
			if path/1 = 'system [
				switch path/2 [
					alias [
						unless path/3 [
							backtrack path
							throw-error "invalid system/alias path access"
						]
						unless def: find aliased-types path/3 [
							backtrack path
							throw-error ["undefined alias name:" path/3]
						]
						last-type: [integer!]
						return get-alias-id def			;-- special encoding for aliases
					]
					; add new special reflective system path here
				]
			]
			none
		]
		
		base-type?: func [value][
			if block? value [value: value/1]
			to logic! find/skip emitter/datatypes value 3
		]
		
		unbox: func [value][
			either object? value [value/data][value]
		]
		
		get-return-type: func [name [word!] /local type][
			type: select functions/:name/4 return-def
			unless type [
				backtrack name
				throw-error ["return type missing in function:" name]
			]
			any [type none-type]
		]
		
		set-last-type: func [spec [block!]][
			if spec: select spec return-def [last-type: spec]
		]
		
		exists-variable?: func [name [word! set-word!]][
			name: to word! name
			to logic! any [
				all [locals find locals name]
				find globals name
			]
		]
		
		get-variable-spec: func [name [word!]][
			any [
				all [locals select locals name]
				select globals name
			]
		]
		
		get-arity: func [spec [block!] /local count][
			count: 0
			parse spec [opt block! any [word! block! (count: count + 1)]]
			count
		]
		
		any-pointer?: func [type [block!]][
			type: first resolve-aliased type
			
			either find type-sets type [
				not empty? intersect get type any-pointer!
			][
				to logic! find any-pointer! type
			]
		]

		equal-types?: func [type1 [word!] type2 [word!]][
			type1: either find type-sets type1 [get type1][reduce [type1]]
			type2: either find type-sets type2 [get type2][reduce [type2]]
			not empty? intersect type1 type2
		]
						
		with-alias-resolution: func [mode [logic!] body [block!] /local saved][
			saved: resolve-alias?
			resolve-alias?: mode	
			do body
			resolve-alias?: saved
		]
		
		resolve-aliased: func [type [block!] /local name][
			name: type/1
			all [
				not base-type? name
				not find type-sets name
				not type: select aliased-types name
				throw-error ["unknown type:" type]
			]
			type
		]
		
		resolve-type: func [name [word!] /with parent [block! none!] /local type][
			type: any [
				all [parent select parent name]
				get-variable-spec name
			]
			if all [not type find functions name][
				return reduce ['function! functions/:name/4]
			]
			unless any [not resolve-alias? base-type? type/1][
				type: select aliased-types type/1
			]
			type
		]
		
		resolve-struct-member-type: func [spec [block!] name [word!] /local type][
			unless type: select spec name [
				pc: skip pc -2
				throw-error [
					"invalid struct member" name "in:" mold to path! pc/1
				]
			]
			either resolve-alias? [resolve-aliased type][type]
		]
		
		resolve-path-type: func [path [path! set-path!] /parent prev /local type path-error saved][
			path-error: [
				pc: skip pc -2
				throw-error "invalid path value"
			]
			either word? path/1 [
				either parent [
					resolve-struct-member-type prev path/1	;-- just check for correct member name
					with-alias-resolution on [
						type: resolve-type/with path/1 prev
					]
				][
					with-alias-resolution on [
						type: resolve-type path/1
					]
				]
			][reduce [type?/word path/1]]
			
			unless type path-error
			
			either tail? skip path 2 [
				switch/default type/1 [
					c-string! [
						check-path-index path 'string
						[byte!]
					]
					pointer!  [
						check-path-index path 'pointer
						reduce [type/2/1]				;-- return pointed value type
					]
					struct!   [
						unless word? path/2 [
							backtrack path
							throw-error ["invalid struct member" path/2]
						]
						resolve-struct-member-type type/2 path/2
					]
				] path-error
			][
				resolve-path-type/parent next path second type
			]
		]
		
		get-type: func [value][
			switch/default type?/word value [
				none!	 [none-type]				;-- no type case (func with no return value)
				tag!	 [either value = <last> [last-type][ [logic!] ]]
				logic!	 [[logic!]]
				word! 	 [resolve-type value]
				char!	 [[byte!]]
				integer! [[integer!]]
				string!	 [[c-string!]]
				path!	 [resolve-path-type value]
				object!  [value/type]
				block!	 [			
					either 'op = second select functions value/1 [
						either base-type? type: get-return-type value/1 [
							type				;-- unique returned type, stop here
						][
							get-type value/2	;-- recursively search for left operand base type
						]
					][
						get-return-type value/1
					]
				]
				paren!	 [
					reduce either all [value/1 = 'struct! word? value/2][
						[value/2]
					][
						[value/1 value/2]
					]
				]
				get-word! [resolve-type to word! value]
			][
				throw-error ["not accepted datatype:" type? value]
			]
		]

		resolve-expr-type: func [expr /quiet /local type func? spec][
			if block? expr [
				switch type?/word expr/1 [
					set-word! [expr: expr/2]			;-- resolve assigned value type
					set-path! [expr: to path! expr/1]	;-- resolve path type
				]
			]			
			func?: all [
				block? expr word? expr/1
				not find comparison-op expr/1
				spec: select functions expr/1 		 ;-- works for unary & binary functions only!
			]
			type: case [
				object? expr [
					expr/type						 ;-- type casting case
				]
				all [func? find [op inline] spec/2][ ;-- works for unary & binary functions only!
					any [
						all [
							expr/1 <> 'not			;-- @@ issue with 'not return type
							spec: select spec/4 return-def
							base-type? spec/1		;-- determined return type
							spec
						]
						get-type expr/2				;-- recursively search for return type
					]
				]
				all [func? quiet][
					any [
						select spec/4 return-def	;-- workaround error throwing in get-return-value
						none-type
					]
				]
				'else [get-type expr]
			]
			type
		]
		
		cast: func [obj [object!] /local value ctype type][
			value: obj/data
			ctype: obj/type
			type: get-type value

			if type = ctype [
				throw-warning/at [
					"type casting from" type/1 
					"to" ctype/1 "is not necessary"
				] 'as
			]
			if any [
				all [type/1 = 'function! ctype/1 <> 'integer!]
				all [ctype/1 = 'byte! find [c-string! pointer! struct!] type/1]
				all [
					find [c-string! pointer! struct!] ctype/1
					find [byte! logic!] type/1
				]
			][
				backtrack value
				throw-error [
					"type casting from" type/1
					"to" ctype/1 "is not allowed"
				]
			]	
			unless literal? value [return value]	;-- shield the following literal conversions
			
			switch ctype/1 [
				byte! [
					switch type/1 [
						integer! [value: value and 255]
						logic! 	 [value: pick [#"^(01)" #"^(00)"] value]
					]
				]
				integer! [
					if find [byte! logic!] type/1 [
						value: to integer! value
					]
				]
				logic! [
					switch type/1 [
						byte! 	 [value: value <> null]
						integer! [value: value <> 0]
					]
				]
			]
			value
		]
		
		init-local: func [name [word!] expr casted [block! none!] /local pos type][
			append locals-init name					;-- mark as initialized
			pos: find locals name
			unless block? pos/2 [					;-- if not typed, infer type
				insert/only at pos 2 type: any [
					casted
					resolve-expr-type expr
				]
				if verbose > 2 [print ["inferred type" mold type "for variable:" pos/1]]
			]
		]
		
		add-symbol: func [name [word!] value type][
			unless type [type: get-type value]
			append globals reduce [name type: compose [(type)]]
			type
		]
		
		add-function: func [type [word!] spec [block!] cc [word!]][
			repend functions [
				to word! spec/1 reduce [get-arity spec/3 type cc new-line/all spec/3 off]
			]		
		]
		
		compare-func-specs: func [
			fun [word!] cb [get-word!] f-type [block!] c-type [block!] /local spec pos idx
		][
			cb: to word! cb
			if functions/:cb/3 <> functions/:fun/3 [
				throw-error [
					"incompatible calling conventions between"
					fun "and" cb
				]
			]
			if pos: find f-type /local [f-type: head clear copy pos] ;-- remove locals
			if block? f-type/1 [f-type: next f-type]	;-- skip optional attributes block
			if block? c-type/1 [c-type: next c-type]	;-- skip optional attributes block
			idx: 2
			foreach [name type] f-type [
				if type <> c-type/:idx [return false]
				idx: idx + 2
			]
			true
		]
		
		check-keywords: func [name [word!]][
			if any [
				find keywords name
				name = 'comment
			][
				throw-error ["attempt to redefined a protected keyword:" name]
			]
		]
		
		check-path-index: func [path [path! set-path!] type [word!] /local ending][
			ending: path/2
			case [
				all [type = 'pointer ending = 'value][]	;-- pass thru case
				word? ending [
					unless get-variable-spec ending [
						backtrack path
						throw-error ["undefined" type "index variable"]
					]
					if 'integer! <> first resolve-type ending [
						backtrack path
						throw-error [
							"attempt to use" type
							"indexing with a non-integer! variable"
						]
					]
				]
				not integer? ending [
					backtrack path
					throw-error [
						"attempt to use" type
						"indexing with a non-integer! value"
					]
				]
			]
		]
		
		check-func-name: func [name [word!] /only][
			if find functions name [
				pc: back pc
				throw-error ["attempt to redefine existing function name:" name]
			]
			if all [not only find any [locals globals] name][
				pc: back pc
				throw-error ["a variable is already using the same name:" name]
			]
		]
		
		check-duplicates: func [
			name [word!] args [block! none!] locs [block! none!]
			/local dups
		][
			if args [remove-each item args: copy args [not word? item]]
			if locs [remove-each item locs: copy locs [not word? item]]
			
			if any [
				all [args (length? unique args) <> length? args]
				all [locs (length? unique locs) <> length? locs]
				all [args locs not empty? dups: intersect args locs]
			][
				throw-error [
					"duplicate variable definition in function" name
					either dups [reform ["for:" mold/only new-line/all dups no]][""]
				]
			]
		]
		
		check-specs: func [
			name specs /extend
			/local type type-def spec-type attribs value args locs cconv
		][
			unless block? specs [
				throw-error "function definition requires a specification block"
			]
			cconv: ['cdecl | 'stdcall]
			attribs: [
				'infix | 'variadic | 'typed | cconv
				| [cconv ['variadic | 'typed]]
				| [['variadic | 'typed] cconv]
			]
			type-def: pick [[func-pointer | type-spec] [type-spec]] to logic! extend

			unless catch [
				parse specs [
					pos: opt [into attribs]				;-- functions attributes
					pos: copy args any [pos: word! into type-def]	;-- arguments definition
					pos: opt [							;-- return type definition				
						set value set-word! (					
							rule: pick reduce [[into type-spec] fail] value = return-def
						) rule
					]
					pos: opt [/local copy locs some [pos: word! opt [into type-spec]]] ;-- local variables definition
				]
			][
				throw-error rejoin ["invalid definition for function " name ": " mold pos]
			]
			check-duplicates name args locs
		]
		
		check-conditional: func [name [word!] expr][
			if last-type/1 <> 'logic! [check-expected-type/key name expr [logic!]]
		]
		
		check-expected-type: func [name [word!] expr expected [block!] /ret /key /local type alias][
			unless any [not none? expr key][return none]   ;-- expr == none for special keywords
			if all [
				not all [object? expr expr/action = 'null] ;-- avoid null type resolution here
				not none? expr							;-- expr can be false, so explicit check for none is required
				first type: resolve-expr-type expr		;-- first => deep check that it's not [none]
			][											;-- check if a type is returned or none
				type: resolve-aliased type
				if alias: select aliased-types expected/1 [expected: alias]
			]
			unless any [
				all [
					object? expr
					expr/action = 'null
					type: expected						;-- morph null type to expected
					any-pointer? expected
				]
				all [
					type
					any [
						find type-sets expected/1
						find type-sets type/1
					]
					equal-types? type/1 expected/1		;-- internal polymorphic case
				]
				all [
					type
					type/1 = 'function!
					expected/1 = 'function!
					compare-func-specs name expr type/2 expected/2	 ;-- callback case
				]
				expected = type 						 ;-- normal single-type case
			][
				if expected = type [type: 'null]		 ;-- make null error msg explicit
				any [
					backtrack any [all [block? expr expr/1] expr]
					backtrack name
				]
				throw-error [
					reform case [
						ret   [["wrong return type in function:" name]]
						key   [[
							uppercase form name "requires a conditional expression"
							either find [while until] name ["as last expression"][""]						
						]]
						'else [["argument type mismatch on calling:" name]]
					]
					"^/*** expected:" join mold expected #","
					"found:" mold new-line/all any [type [none]] no
				]
			]
			type
		]
		
		check-arguments-type: func [name args /local entry spec list][
			if find [set-word! set-path!] type?/word name [exit]
			
			entry: find functions name
			if all [
				not empty? spec: entry/2/4 
				block? spec/1
			][
				spec: next spec						;-- jump over attributes block
			]
			list: []
			foreach arg args [
				append/only list check-expected-type name arg spec/2
				spec: skip spec	2
			]
			if all [
				any [
					find emitter/target/comparison-op name
					find emitter/target/bitwise-op name
				]
				not equal-types? list/1/1 list/2/1	;-- allow implicit casting for math ops only
			][
				backtrack name
				throw-error [
					"left and right argument must be of same type for:" name
					"^/*** left:" join list/1/1 #"," "right:" list/2/1
				]
			]
			if all [
				find emitter/target/math-op name				
				any [
					all [list/1/1 = 'byte! any-pointer? list/2]
					all [list/2/1 = 'byte! any-pointer? list/1]
				]
			][
				backtrack name
				throw-error [
					"arguments must be of same size for:" name
					"^/*** left:" join list/1/1 #"," "right:" list/2/1
				]
			]
			clear list
		]
		
		check-variable-arity?: func [spec [block!]][
			all [
				block? spec/1
				any [
					all [find spec/1 'variadic 'variadic]
					all [find spec/1 'typed 'typed]
				]
			]
		]
		
		check-body: func [body][
			case/all [
				not block? :body [throw-error "expected a block of code"]
				empty? body  	 [throw-error "expected a non-empty block of code"]
			]
		]
		
		fetch-into: func [code [block! paren!] body [block!] /local save-pc][		;-- compile sub-block
			save-pc: pc
			pc: code
			do body
			next pc: save-pc
		]
		
		fetch-func: func [name /local specs type cc][
			name: to word! name
			check-func-name name
			check-specs name specs: pc/2
			type: 'native
			cc:   'stdcall								;-- default calling convention
			
			if all [
				not empty? specs
				block? specs/1
			][
				case [
					find specs/1 'infix [
						if 2 <> get-arity specs [
							throw-error [
								"infix function requires 2 arguments, found"
								get-arity specs "for" name
							]
						]
						type: 'infix
					]
					find specs/1 'cdecl   [cc: 'cdecl]
					find specs/1 'stdcall [cc: 'stdcall]	;-- get ready when fastcall will be the default cc
				]
			]
			add-function type reduce [name none specs] cc
			emitter/add-native name
			repend natives [name specs pc/3 script]
			pc: skip pc 3
		]
		
		reduce-logic-tests: func [expr /local test value][
			test: [logic? expr/2 logic? expr/3]
			
			if all [
				block? expr
				find [= <>] expr/1
				any test
			][
				expr: either all test [
					do expr								;-- let REBOL reduce the expression
				][
					expr: copy expr
					if any [
						all [expr/1 = '= not all [expr/2 expr/3]]
						all [expr/1 = first [<>] any [expr/2 = true expr/3 = true]]
					][
						insert expr 'not
					]
					remove-each v expr [any [find [= <>] v logic? v]]
					if any [
						all [word? expr/1 get-variable-spec expr/1]
						paren? expr/1
						block? expr/1
						object? expr/1
					][
						expr: expr/1					;-- remove outer brackets if variable
					]
					expr
				]
			]
			expr
		]
		
		process-import: func [defs [block!] /local lib list cc name specs spec id reloc][
			unless block? defs [throw-error "#import expects a block! as argument"]
			unless parse defs [
				some [
					pos: set lib string! (
						unless list: select imports lib [
							repend imports [lib list: make block! 10]
						]
					)
					pos: set cc ['cdecl | 'stdcall]		;-- calling convention	
					pos: into [
						some [
							specs:						;-- new function mapping marker
							pos: set name set-word! (check-func-name name: to word! name)
							pos: set id   string!   (repend list [id reloc: make block! 1])
							pos: set spec block!    (
								check-specs/extend name spec
								add-function 'import specs cc
								emitter/import-function name reloc
							)
						]
					]
				]
			][
				throw-error ["invalid import specification at:" pos]
			]		
		]
		
		process-syscall: func [defs [block!] /local name id spec][
			unless block? defs [throw-error "#syscall expects a block! as argument"]
			unless parse defs [
				some [
					pos: set name set-word! (check-func-name name: to word! name)
					pos: set id   integer!
					pos: set spec block!    (
						check-specs/extend name spec
						add-function 'syscall reduce [name none spec] 'syscall
						append last functions id		;-- extend definition with syscode
					)
				]
			][
				throw-error ["invalid syscall specification at:" pos]
			]
		]

		comp-directive: has [body][
			switch/default pc/1 [
				#import  [process-import  pc/2  pc: skip pc 2]
				#syscall [process-syscall pc/2	pc: skip pc 2]
				#script	 [								;-- internal compiler directive
					compiler/script: secure-clean-path pc/2	;-- set the origin of following code
					pc: skip pc 2
				]
			][
				throw-error ["unknown directive" pc/1]
			]
		]
		
		comp-declare: has [rule value pos offset][
			unless find [set-word! set-path!] type?/word pc/-1 [
				throw-error "assignment expected before literal declaration"
			]
			value: to paren! reduce either find [pointer! struct!] pc/2 [
				rule: get pick [struct-syntax pointer-syntax] pc/2 = 'struct!
				unless catch [parse pos: pc/3 rule][
					throw-error ["invalid literal syntax:" mold pos]
				]
				offset: 3
				[pc/2 pc/3]
			][
				unless all [word? pc/2 resolve-aliased reduce [pc/2]][
					throw-error [
						"declaring literal for type" pc/2 "not supported"
					]
				]
				offset: 2
				['struct! pc/2]
			]
			pc: skip pc offset
			value
		]
		
		comp-null: does [
			pc: next pc
			make action-class [action: 'null type: [any-pointer!] data: 0]
		]
		
		comp-as: has [ctype ptr? expr][
			ctype: pc/2
			if ptr?: find [pointer! struct!] ctype [ctype: reduce [pc/2 pc/3]]
			
			unless any [
				parse blockify ctype type-syntax
				find aliased-types ctype
			][
				throw-error ["invalid target type casting:" ctype]
			]
			pc: skip pc pick [3 2] to logic! ptr?
			expr: fetch-expression

			if all [object? expr expr/action = 'null][
				pc: back pc
				throw-error "type casting on null value is not allowed"
			]
			make action-class [
				action: 'type-cast
				type: blockify ctype
				data: expr
			]
		]
		
		comp-assert: has [expr line][
			either job/debug? [
				line: calc-line
				pc: next pc
				expr: fetch-expression/final
				check-conditional 'assert expr			;-- verify conditional expression
				expr: process-logic-encoding expr yes

				insert/only pc next next compose [
					2 (to pair! reduce [line 1])			;-- hidden line offset header
					***-on-quit 98 as integer! system/pc
				]
				set [unused chunk] comp-block-chunked		;-- compile TRUE block
				emitter/set-signed-state expr				;-- properly set signed/unsigned state
				emitter/branch/over/on chunk reduce [expr/1] ;-- branch over if expr is true
				emitter/merge chunk
				last-type: none-type
				<last>
			][
				pc: next pc
				fetch-expression							;-- consume next expression
				none
			]
		]
		
		comp-alias: has [name][
			unless set-word? pc/-1 [
				throw-error "assignment expected for ALIAS"
			]
			unless pc/2 = 'struct! [
				throw-error "ALIAS only works on struct! type"
			]
			if find aliased-types name: to word! pc/-1 [
				pc: back pc
				throw-error reform [
					"alias name already defined as:"
					mold aliased-types/:name
				]
			]
			if base-type? name [
				pc: back pc
				throw-error "a base type name cannot be defined as an alias name"
			]
			repend aliased-types [name reduce [pc/2 pc/3]]
			unless catch [parse pos: pc/3 struct-syntax][
				throw-error ["invalid struct syntax:" mold pos]
			]
			pc: skip pc 3
			none
		]
		
		comp-size?: has [type expr][
			pc: next pc
			unless all [
				word? expr: pc/1
				type: any [
					all [base-type? expr expr]
					select aliased-types expr
				]
				pc: next pc
			][
				expr: fetch-expression/final	
				type: resolve-expr-type expr
			]
			emitter/get-size type expr
		]
		
		comp-exit: func [/value /local expr type ret][
			unless locals [
				throw-error [pc/1 "is not allowed outside of a function"]
			]
			pc: next pc
			ret: select locals return-def
			
			either value [				
				unless ret [							;-- check if return: declared
					throw-error [
						"RETURN keyword used without return: declaration in"
						func-name
					]
				]
				expr: fetch-expression/final/keep		;-- compile expression to return
				type: check-expected-type/ret func-name expr ret
				ret: either type [last-type: type <last>][none]
			][
				if ret [
					throw-error [
						"EXIT keyword is not compatible with declaring a return value"
					]
				]
			]
			emitter/target/emit-exit
			ret
		]

		comp-block-chunked: func [/only /test name [word!] /local expr][
			emitter/chunks/start
			expr: either only [
				fetch-expression/final					;-- returns first expression
			][
				comp-block/final						;-- returns last expression
			]
			if test [
				check-conditional name expr				;-- verify conditional expression
				expr: process-logic-encoding expr no
			]
			reduce [
				expr 
				emitter/chunks/stop						;-- returns a chunk block!
			]
		]
		
		process-logic-encoding: func [expr invert? [logic!]][	;-- preprocess logic values
			case [
				logic? expr [ [#[true]] ]
				find [word! path!] type?/word expr  [
					emitter/target/emit-operation '= [<last> 0]
					reduce [not invert?]
				]
				object? expr [
					expr: cast expr
					unless find [word! path!] type?/word any [
						all [block? expr expr/1] expr 
					][
						emitter/target/emit-operation '= [<last> 0]
					]
					process-logic-encoding expr invert?
				]
				block? expr [
					case [
						find comparison-op expr/1 [expr]
						'else [process-logic-encoding expr/1 invert?]
					]
				]
				tag? expr [
					either last-type/1 = 'logic! [
						emitter/target/emit-operation '= [<last> 0]
						reduce [not invert?]
					][expr] 
				]
				'else [expr]
			]
		]
		
		comp-if: has [expr unused chunk][		
			pc: next pc
			expr: fetch-expression/final				;-- compile expression
			check-conditional 'if expr					;-- verify conditional expression
			expr: process-logic-encoding expr no
			check-body pc/1								;-- check TRUE block
	
			set [unused chunk] comp-block-chunked		;-- compile TRUE block
			emitter/set-signed-state expr				;-- properly set signed/unsigned state
			emitter/branch/over/on chunk expr/1			;-- insert IF branching			
			emitter/merge chunk
			last-type: none-type
			<last>
		]
		
		comp-either: has [expr e-true e-false c-true c-false offset t-true t-false][
			pc: next pc
			expr: fetch-expression/final				;-- compile expression
			check-conditional 'either expr				;-- verify conditional expression
			expr: process-logic-encoding expr no
			check-body pc/1								;-- check TRUE block
			check-body pc/2								;-- check FALSE block
			
			set [e-true c-true]   comp-block-chunked	;-- compile TRUE block		
			set [e-false c-false] comp-block-chunked	;-- compile FALSE block
		
			offset: emitter/branch/over c-false
			emitter/set-signed-state expr				;-- properly set signed/unsigned state	
			emitter/branch/over/adjust/on c-true negate offset expr/1	;-- skip over JMP-exit
			emitter/merge emitter/chunks/join c-true c-false

			t-true:  resolve-expr-type/quiet e-true
			t-false: resolve-expr-type/quiet e-false

			last-type: either all [
				t-true/1 t-false/1
				t-true:  resolve-aliased t-true			;-- alias resolution is safe here
				t-false: resolve-aliased t-false
				equal-types? t-true/1 t-false/1
			][t-true][none-type]						;-- allow nesting if both blocks return same type		
			<last>
		]
		
		comp-until: has [expr chunk][
			pc: next pc
			check-body pc/1
			set [expr chunk] comp-block-chunked/test 'until
			emitter/branch/back/on chunk expr/1	
			emitter/merge chunk	
			last-type: none-type
			<last>
		]
		
		comp-while: has [expr unused cond body offset bodies][
			pc: next pc
			check-body pc/1								;-- check condition block
			check-body pc/2								;-- check body block
			
			set [expr cond]   comp-block-chunked/test 'while	;-- Condition block
			set [unused body] comp-block-chunked		;-- Body block
			
			if logic? expr/1 [expr: [<>]]				;-- re-encode test op
			offset: emitter/branch/over body			;-- Jump to condition
			bodies: emitter/chunks/join body cond
			emitter/set-signed-state expr				;-- properly set signed/unsigned state
			emitter/branch/back/on/adjust bodies reduce [expr/1] offset ;-- Test condition, exit if FALSE
			emitter/merge bodies
			last-type: none-type
			<last>
		]
		
		comp-expression-list: func [/_all /local list offset bodies op][
			pc: next pc
			check-body pc/1								;-- check body block
			
			list: make block! 8
			pc: fetch-into pc/1 [
				while [not tail? pc][					;-- comp all expressions in chunks
					append/only list comp-block-chunked/only/test pick [all any] to logic! _all
				]
			]
			list: back tail list
			set [offset bodies] emitter/chunks/make-boolean			;-- emit ending FALSE/TRUE block
			if _all [emitter/branch/over/adjust bodies offset/1]	;-- conclude by a branch on TRUE
			offset: pick offset not _all				;-- branch to TRUE or FALSE 
			
			until [										;-- left join all expr in reverse order			
				op: either logic? list/1/1/1 [first [<>]][list/1/1/1]
				unless _all [op: reduce [op]]			;-- do not invert the test if ANY
				emitter/set-signed-state list/1/1		;-- properly set signed/unsigned state
				emitter/branch/over/on/adjust bodies op offset		;-- first emit branch				
				bodies: emitter/chunks/join list/1/2 bodies			;-- then left join expr
				also head? list	list: back list
			]	
			emitter/merge bodies
			last-type: [logic!]
			<last>
		]
		
		comp-assignment: has [name value n][
			name: pc/1
			pc: next pc
			if set-word? name [
				check-keywords n: to word! name			;-- forbid keywords redefinition
				if get-word? pc/1 [
					throw-error "storing a function! requires a type casting"
				]
				unless all [locals find locals n][
					check-func-name/only n				;-- avoid clashing with an existing function name
				]
			]
			either none? value: fetch-expression [		;-- explicitly test for none!
				none
			][				
				new-line/all reduce [name value] no
			]
		]
		
		comp-path: has [path value][
			path: pc/1
			comp-word/path path/1						;-- check if root word is defined
			unless value: system-reflexion? path [
				last-type: resolve-path-type path
			]
			any [value path]
		]
		
		comp-get-word: has [spec][
			unless spec: select functions to word! pc/1 [
				throw-error ["function" to word! pc/1 "not defined"] 
			]
			unless spec/2 = 'native [
				throw-error "get-word syntax only reserved for native functions for now"
			]
			unless spec/5 = 'callback [append spec 'callback]
			also pc/1 pc: next pc
		]
	
		comp-word: func [/path symbol [word!] /local entry args n name expr attribute fetch][
			name: any [symbol pc/1]
			case [
				entry: select keywords name [do entry]	;-- it's a reserved word
				
				any [
					all [locals find locals name]
					find globals name
				][										;-- it's a variable			
					if not-initialized? name [
						throw-error ["local variable" name "used before being initialized!"]
					]
					last-type: resolve-type name				
					also name pc: next pc
				]
				all [
					not path
					entry: find functions name 
				][
					pc: next pc							;-- it's a function
					either attribute: check-variable-arity? entry/2/4 [
						fetch: [
							append/only args fetch-expression
							if attribute = 'typed [
								append args get-type-id last args
							]							
						]
						args: make block! 1
						either block? pc/1 [
							fetch-into pc/1 [until [do fetch tail? pc]]
							pc: next pc					;-- jump over arguments block
						][
							do fetch
						]
						reduce [name to-issue attribute args]
					][									;-- fixed arity case
						args: make block! n: entry/2/1
						loop n [append/only args fetch-expression]	;-- fetch n arguments
						head insert args name
					]
				]
				'else [throw-error ["undefined symbol:" mold name]]
			]
		]
		
		cast-null: func [variable [set-word! set-path!] /local casting][
			unless all [
				attempt [
					casting: get-type any [
						all [set-word? variable to word! variable]
						to path! variable
					]
				]
				any-pointer? casting
			][
				backtrack variable
				throw-error "Invalid null assignment"
			]			
			casting
		]
		
		order-args: func [name [word!] args [block!]][
			if any [
				all [
					find [import native infix] functions/:name/2
					find [stdcall cdecl] functions/:name/3
				]
				all [
					functions/:name/2 = 'syscall
					job/syscall = 'BSD
				]
				all [
					functions/:name/2 = 'syscall		
					job/target = 'ARM					;-- odd, but required for Linux/ARM syscalls
					job/syscall = 'Linux
				]
			][		
				reverse args
			]
		]

		comp-call: func [
			name [word!] args [block!] /sub
			/local list type res import? left right dup var-arity? saved? arg
		][
			list: either issue? args/1 [				;-- bypass type-checking for variable arity calls
				args/2
			][
				check-arguments-type name args
				args
			]
			order-args name list						;-- reorder argument according to cconv

			import?: functions/:name/2 = 'import		;@@ syscalls don't seem to need special alignment??
			if import? [emitter/target/emit-stack-align-prolog length? args]

			type: functions/:name/2
			either type <> 'op [					
				forall list [							;-- push function's arguments on stack
					if block? unbox list/1 [comp-expression list/1 yes]	;-- nested call
					if type <> 'inline [
						emitter/target/emit-argument list/1 type ;-- let target define how arguments are passed
					]
				]
			][											;-- nested calls as op argument require special handling
				if block? unbox list/1 [comp-expression list/1 yes]	;-- nested call
				left:  unbox list/1
				right: unbox list/2
				if saved?: all [block? left any [block? right path? right]][
					emitter/target/emit-save-last		;-- optionally save left argument result
				]
				if block? unbox list/2 [comp-expression list/2 yes]	;-- nested call
				if saved? [emitter/target/emit-restore-last]			
			]
			res: emitter/target/emit-call name args to logic! sub

			either res [
				last-type: res
			][
				set-last-type functions/:name/4			;-- catch nested calls return type
			]
			if import? [emitter/target/emit-stack-align-epilog length? args]
			res
		]
				
		comp-path-assign: func [
			set-path [set-path!] expr casted [block! none!]
			/local type new value
		][
			unless get-variable-spec set-path/1 [
				backtrack set-path
				throw-error ["unknown path root variable:" set-path/1]
			]
			type: resolve-path-type set-path			;-- check path validity
			new: resolve-aliased get-type expr		

			if type <> any [casted new][
				backtrack set-path
				throw-error [
					"type mismatch on setting path:" to path! set-path
					"^/*** expected:" mold type
					"^/*** found:" mold any [casted new]
				]
			]
			value: unbox expr
			if any [block? value path? value][value: <last>]

			emitter/access-path set-path value
		]
		
		comp-variable-assign: func [
			set-word [set-word!] expr casted [block! none!]
			/local name type new value
		][
			name: to word! set-word		
			if find aliased-types name [
				backtrack set-word
				throw-error "name already used for as an alias definition"
			]
			if not-initialized? name [
				init-local name expr casted				;-- mark as initialized and infer type if required
			]		
			either type: get-variable-spec name [ 		;-- test if known variable (local or global)		
				type: resolve-aliased type		
				new: resolve-aliased get-type expr			
				
				if type <> any [casted new][
					backtrack set-word
					throw-error [
						"attempt to change type of variable:" name
						"^/*** from:" mold type
						"^/***   to:" mold any [casted new]
					]
				]
			][
				unless zero? block-level [
					backtrack set-word
					throw-error "variable has to be initialized at root level"
				]
				type: add-symbol name unbox expr casted  ;-- if unknown add it to global context
			]
			if none? type/1 [
				backtrack set-word
				throw-error ["unable to determine a type for:" name]
			]
			value: unbox expr
			if any [block? value path? value][value: <last>]
			
			emitter/store name value type
		]
		
		comp-expression: func [expr keep? [logic!] /local variable boxed casting new? type][	
			;-- preprocessing expression
			if all [block? expr find [set-word! set-path!] type?/word expr/1][
				variable: expr/1
				expr: expr/2							;-- switch to assigned expression
				if set-word? variable [
					new?: not exists-variable? variable
				]
			]			
			if object? expr [							;-- unbox type-casting object
				if all [variable expr/action = 'null][
					casting: cast-null variable
				]
				boxed: expr
				expr: cast expr
			]

			;-- emitting expression code
			either block? expr [
				type: comp-call expr/1 next expr 		;-- function call case (recursive)
				if type [last-type: type]				;-- set last-type if not already set
			][
				unless any [
					all [new? literal? unbox expr]		;-- if new variable, value will be store in data segment
					all [set-path? variable literal? unbox expr] ;-- value loaded at lower level
					tag? unbox expr
				][
					emitter/target/emit-load expr		;-- emit code for single value
				]
				last-type: resolve-expr-type expr
			]
			
			;-- postprocessing result
			if boxed [
				emitter/target/emit-casting boxed no 	;-- insert runtime type casting if required
				last-type: boxed/type
			]
			if all [
				any [keep? variable]					;-- if result needs to be stored
				block? expr								;-- and if expr is a function call
				last-type/1 = 'logic!					;-- which return type is logic!
			][
				emitter/logic-to-integer expr/1			;-- runtime logic! conversion before storing
			]
			
			;-- storing result if assignement required
			if variable [
				if all [boxed not casting][
					casting: resolve-aliased boxed/type
				]
				switch type?/word variable [
					set-word! [comp-variable-assign variable expr casting]
					set-path! [comp-path-assign		variable expr casting]
				]
			]
		]
		
		infix?: func [pos [block! paren!] /local specs][
			all [
				not tail? pos
				word? pos/1
				specs: select functions pos/1
				find [op infix] specs/2
			]
		]
		
		check-infix-operators: has [pos][
			if infix? pc [exit]							;-- infix op already processed,
														;-- or used in prefix mode.
			if infix? next pc [
				either find [set-word! set-path! struct!] type?/word pc/1 [
					throw-error "can't use infix operator here"
				][
					pos: 0								;-- relative index of next infix op
					until [								;-- search for all dependent infix op
						pos: pos + 2					;-- target next infix possible position
						insert pc pc/:pos				;-- transform to prefix notation
						remove at pc pos + 1
						not infix? at pc pos + 2		;-- exit when no more infix op found
					]
				]
			]
		]
		
		fetch-expression: func [/final /keep /local expr pass][
			check-infix-operators
			if verbose >= 4 [print ["<<<" mold pc/1]]
			pass: [also pc/1 pc: next pc]
			
			if tail? pc [
				pc: back pc
				throw-error "missing argument"
			]
			if job/debug? [store-dbg-lines]
			
			expr: switch/default type?/word pc/1 [
				set-word!	[comp-assignment]
				word!		[comp-word]
				get-word!	[comp-get-word]
				path! 		[comp-path]
				set-path!	[comp-assignment]
				paren!		[comp-block/only]
				char!		[do pass]
				integer!	[do pass]
				string!		[do pass]
			][
				throw-error [
					pick [
						"compiler directives are not allowed in code blocks"
						"datatype not allowed"
					] issue? pc/1
				]
			]
			expr: reduce-logic-tests expr

			if final [
				if verbose >= 3 [?? expr]
				unless find [none! tag!] type?/word expr [
					comp-expression expr to logic! keep
				]
			]
			expr
		]
		
		comp-block: func [/final /only /local fetch expr][
			fetch: [either final [fetch-expression/final][fetch-expression]]
			block-level: block-level + 1
			pc: fetch-into pc/1 [
				either only [
					expr: do fetch
					unless tail? pc [
						throw-error "more than one expression found in parentheses"
					]
				][
					while [not tail? pc][
						case [
							paren? pc/1 [
								unless infix? at pc 2 [raise-paren-error]
								expr: do fetch
							]
							all [word? pc/1 pc/1 = 'comment][pc: skip pc 2]	
							'else [expr: do fetch]
						]
					]
				]
			]
			block-level: block-level - 1
			expr
		]
		
		comp-dialect: has [expr][
			block-level: 0
			while [not tail? pc][
				case [
					issue? pc/1 [comp-directive]
					all [
						set-word? pc/1
						find [func function] pc/2
					][
						pc: next pc
						fetch-func pc/-1				;-- allow function declaration at root level only
					]
					all [set-word? pc/1 pc/2 = 'alias][
						pc: next pc
						comp-alias						;-- allow alias declaration at root level only
					]
					paren? pc/1 [
						unless infix? at pc 2 [raise-paren-error]
						expr: fetch-expression/final
					]
					all [word? pc/1 pc/1 = 'comment][pc: skip pc 2]
					'else [expr: fetch-expression/final]
				]
			]
			expr
		]
		
		comp-func-body: func [
			name [word!] spec [block!] body [block!]
			/local args-sz local-sz expr ret
		][
			locals: spec
			func-name: name
			set [args-sz local-sz] emitter/enter name locals ;-- build function prolog
			pc: body
			
			expr: comp-dialect							;-- compile function's body
			
			if ret: select spec return-def [
				check-expected-type/ret name expr ret	;-- validate return value type	
				if all [
					last-type/1 = 'logic!
					block? expr
					word? expr/1
				][
					emitter/logic-to-integer expr/1		;-- runtime logic! conversion before returning
				]
			]
			emitter/leave name locals args-sz local-sz	;-- build function epilog
			clear locals-init
			locals: func-name: none
		]
		
		comp-natives: does [			
			foreach [name spec body origin] natives [
				if verbose >= 2 [
					print [
						"---------------------------------------^/"
						"function:" name newline
						"---------------------------------------"
					]
				]
				script: origin
				comp-func-body name spec body
			]
		]
		
		comp-header: has [pos][
			unless pc/1 = 'Red/System [
				throw-error "source is not a Red/System program"
			]
			pc: next pc
			unless block? pc/1 [
				throw-error "missing Red/System program header"
			]
			unless parse pc/1 [any [pos: set-word! skip]][
				throw-error ["invalid program header at:" mold pos]
			]
			pc: next pc
		]

		run: func [obj [object!] src [block!] file [file!] /no-header /runtime][
			runtime: to logic! runtime
			job: obj
			pc: src
			script: secure-clean-path file
			unless no-header [comp-header]
			emitter/target/on-global-prolog runtime
			comp-dialect
			if runtime [emitter/target/on-global-epilog yes]	;-- postpone epilog event after comp-runtime-epilog
		]
		
		finalize: does [
			if verbose >= 2 [print "^/---^/Compiling native functions^/---"]
			comp-natives
			emitter/target/on-finalize
			if verbose >= 2 [print ""]
			emitter/reloc-native-calls
		]
	]
	
	set-verbose-level: func [level [integer!]][
		foreach ctx reduce [
			self
			loader
			compiler
			emitter
			emitter/target
			linker
		][
			ctx/verbose: level
		]
	]
	
	output-logs: does [
		case/all [
			verbose >= 1 [
				print [
					nl
					"-- compiler/globals --" nl mold new-line/all/skip to-block compiler/globals yes 2 nl
					"-- emitter/symbols --"  nl mold emitter/symbols nl
				]
			]
			verbose >= 2 [
				print [
					"-- compiler/functions --" nl mold compiler/functions nl
					"-- emitter/stack --"	   nl mold emitter/stack nl
				]
			]
			verbose >= 3 [
				print [
					"-- emitter/code-buf --" nl mold emitter/code-buf nl
					"-- emitter/data-buf --" nl mold emitter/data-buf nl
					"as-string:"        	 nl mold as-string emitter/data-buf nl
				]
			]
		]
	]
	
	comp-runtime-prolog: has [script][
		script: secure-clean-path runtime-path/common.reds
 		compiler/run/runtime job loader/process script script
	]
	
	comp-runtime-epilog: does [	
		compiler/comp-call '***-on-quit [0 0]			;-- call runtime exit handler
		emitter/target/on-global-epilog no
	]
	
	clean-up: does [
		clear compiler/imports
		clear compiler/natives
		clear compiler/globals
		clear compiler/aliased-types
		clear compiler/user-functions
		clear compiler/debug-lines/records
		clear compiler/debug-lines/files
	]
	
	make-job: func [opts [object!] file [file!] /local job][
		job: construct/with third opts linker/job-class	
		unless job/build-basename [
			file: last split-path file					;-- remove path
			file: to-file first parse file "."			;-- remove extension
			job/build-basename: file
		]
		job
	]
	
	dt: func [code [block!] /local t0][
		t0: now/time/precise
		do code
		now/time/precise - t0
	]
	
	options-class: context [
		config-name:	none			;-- Preconfigured compilation target ID
		OS:				none			;-- Operating System
		OS-version:		none			;-- OS version
		link?:			no				;-- yes = invoke the linker and finalize the job
		debug?:			no				;-- reserved for future use
		build-prefix:	%builds/		;-- prefix to use for output file name (none: no prefix)
		build-basename:	none			;-- base name to use for output file name (none: derive from input name)
		build-suffix:	none			;-- suffix to use for output file name (none: derive from output type)
		format:			none			;-- file format
		type:			'exe			;-- file type ('exe | 'dll | 'lib | 'obj)
		target:			'IA-32			;-- CPU target
		verbosity:		0				;-- logs verbosity level
		sub-system:		'console		;-- 'GUI | 'console
		runtime?:		yes				;-- include Red/System runtime
		use-natives?:	no				;-- force use of native functions instead of C bindings
		debug?:			no				;-- emit debug information into binary
		PIC?:			no				;-- compile using Position Independent Code
		base-address:	none			;-- base image memory address
		dynamic-linker: none			;-- ELF dynamic linker ("interpreter")
		syscall:		'Linux			;-- syscalls convention: 'Linux | 'BSD
		stack-align-16?: no				;-- yes => align stack to 16 bytes
	]
	
	compile: func [
		files [file! block!]							;-- source file or block of source files
		/options
			opts [object!]
		/local
			comp-time link-time err src
	][
		comp-time: dt [
			unless block? files [files: reduce [files]]
			
			
			job: make-job opts last files				;-- last input filename is retained for output name
			emitter/init opts/link? job
			set-verbose-level opts/verbosity
			
			loader/init
			if opts/runtime? [comp-runtime-prolog]
			
			foreach file files [compiler/run job loader/process file file]
			
			if opts/runtime? [comp-runtime-epilog]
			compiler/finalize							;-- compile all functions
		]
		if verbose >= 4 [
			print [
				"-- emitter/code-buf (empty addresses):"
				nl mold emitter/code-buf nl
			]
		]

		if opts/link? [
			link-time: dt [
				job/symbols: emitter/symbols
				job/sections: compose/deep/only [
					code   [- 	(emitter/code-buf)]
					data   [- 	(emitter/data-buf)]
					import [- - (compiler/imports)]
				]
				if opts/debug? [
					job/debug-info: reduce ['lines compiler/debug-lines]
				]
				linker/build job
			]
		]
		output-logs
		if opts/link? [clean-up]

		reduce [comp-time link-time any [all [job/buffer length? job/buffer] 0]]
	]
]
