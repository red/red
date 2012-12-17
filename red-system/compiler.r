REBOL [
	Title:   "Red/System compiler"
	Author:  "Nenad Rakocevic"
	File: 	 %compiler.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

do %utils/profiler.r
profiler/active?: no

do %utils/r2-forward.r
do %utils/int-to-bin.r
do %utils/IEEE-754.r
do %utils/virtual-struct.r
do %utils/secure-clean-path.r
do %linker.r
do %emitter.r

system-dialect: make-profilable context [
	verbose:  	  0										;-- logs verbosity level
	job: 		  none									;-- reference the current job object	
	runtime-path: %runtime/
	red-runtime-path: %../red/runtime/
	nl: 		  newline
	
	loader: do bind load %loader.r 'self
	
	compiler: make-profilable context [
		job:		 	 none							;-- shortcut for job object
		pc:			 	 none							;-- source code input cursor
		script:		 	 none							;-- source script file name
		none-type:	 	 [#[none]]						;-- marker for "no value returned"
		last-type:	 	 none-type						;-- type of last value from an expression
		locals: 	 	 none							;-- currently compiled function specification block
		definitions:  	 make block! 100
		enumerations: 	 make hash! 10
		expr-call-stack: make block! 1					;-- simple stack of nested calls for a given expression
		locals-init: 	 []								;-- currently compiler function locals variable init list
		func-name:	 	 none							;-- currently compiled function name
		block-level: 	 0								;-- nesting level of input source block
		verbose:  	 	 0								;-- logs verbosity level
	
		imports: 	   	 make block! 10					;-- list of imported functions
		natives:	   	 make hash!  40					;-- list of functions to compile [name [specs] [body]...]
		ns-path:		 none							;-- namespaces access path
		ns-stack:		 none							;-- namespaces resolution stack
		ns-list:		 make hash!  8					;-- namespaces definition list [name [word type...]...]
		sym-ctx-table:	 make hash!  100				;-- reverse lookup table for contexts
		globals:  	   	 make hash!  40					;-- list of globally defined symbols from scripts
		aliased-types: 	 make hash!  10					;-- list of aliased type definitions
		keywords-list:	 make block! 20
		
		resolve-alias?:  yes							;-- YES: instruct the type resolution function to reduce aliases
		decoration:		 slash							;-- decoration separator for namespaces
		
		debug-lines: reduce [							;-- runtime source line/file information storage
			'records make block!  1000					;-- [address line file] records
			'files	 make hash!   20					;-- filenames table
		]
		
		pos:		none								;-- validation rules cursor for error reporting
		return-def: to-set-word 'return					;-- return: keyword
		fail:		[end skip]							;-- fail rule
		rule: value: v: none							;-- global parsing rules helpers
		
		not-set!:	  [logic! integer! byte!]			;-- reserved for internal use only
		number!: 	  [byte! integer!]					;-- reserved for internal use only
		any-float!:	  [float! float32! float64!]		;-- reserved for internal use only
		any-number!:  union number! any-float!			;-- reserved for internal use only
		pointers!:	  [pointer! struct! c-string!] 		;-- reserved for internal use only
		any-pointer!: union pointers! [function!]		;-- reserved for internal use only
		poly!:		  union any-number! pointers!		;-- reserved for internal use only
		any-type!:	  union poly! [logic!]			  	;-- reserved for internal use only
		type-sets:	  [									;-- reserved for internal use only
			not-set! number! poly! any-type! any-pointer!
			any-number!
		]
		
		comparison-op: [= <> < > <= >=]
		
		functions: to-hash [
		;--Name--Arity--Type----Cc--Specs--		   Cc = Calling convention
			+		[2	op		- [a [poly!]   b [poly!]   return: [poly!]]]
			-		[2	op		- [a [poly!]   b [poly!]   return: [poly!]]]
			*		[2	op		- [a [any-number!] b [any-number!] return: [any-number!]]]
			/		[2	op		- [a [any-number!] b [any-number!] return: [any-number!]]]
			and		[2	op		- [a [number!] b [number!] return: [number!]]]
			or		[2	op		- [a [number!] b [number!] return: [number!]]]
			xor		[2	op		- [a [number!] b [number!] return: [number!]]]
			//		[2	op		- [a [any-number!] b [any-number!] return: [any-number!]]]		;-- modulo
			///		[2	op		- [a [any-number!] b [any-number!] return: [any-number!]]]		;-- remainder (real syntax: %)
			>>		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- shift left signed
			<<		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- shift right signed
			-**		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- shift right unsigned
			=		[2	op		- [a [any-type!] b [any-type!]  return: [logic!]]]
			<>		[2	op		- [a [any-type!] b [any-type!]  return: [logic!]]]
			>		[2	op		- [a [poly!]   b [poly!]   return: [logic!]]]
			<		[2	op		- [a [poly!]   b [poly!]   return: [logic!]]]
			>=		[2	op		- [a [poly!]   b [poly!]   return: [logic!]]]
			<=		[2	op		- [a [poly!]   b [poly!]   return: [logic!]]]
			not		[1	inline	- [a [not-set!] 		   return: [not-set!]]]
			push	[1	inline	- [a [any-type!]]]
			pop		[0	inline	- [						   return: [integer!]]]
		]
		
		user-functions: tail functions					;-- marker for user functions
		
		action-class: context [action: type: data: none]
		
		struct-syntax: [
			pos: opt [into ['align integer! opt ['big | 'little]]]	;-- struct's attributes
			pos: some [word! into type-spec]						;-- struct's members
		]
		
		pointer-syntax: ['integer! | 'byte! | 'float32! | 'float64! | 'float!]
		
		func-pointer: ['function! set value block! (check-specs '- value)]
		
		type-syntax: [
			'logic! | 'integer! | 'byte! | 'int16!		;-- int16! needed for AVR8 backend
			| 'float! | 'float32! | 'float64!
			| 'c-string!
			| 'pointer! into [pointer-syntax]
			| 'struct!  into [struct-syntax]
		]

		type-spec: [
			pos: some type-syntax | pos: set value word! (	;-- multiple types allowed for internal usage		
				unless any [
					all [v: find-aliased/prefix value v <> value find aliased-types v pos/1: v]			;-- rewrite the type to prefix it
					find aliased-types value
					all [v: resolve-ns value v <> value enum-type? v pos/1: v]	;-- rewrite the type to prefix it
					all [enum-type? value pos/1: 'integer!]
				][throw false]							;-- stop parsing if unresolved type			
			)
		]		
		
		keywords: make hash! [
			;&			 [throw-error "reserved for future use"]
			as			 [comp-as]
			assert		 [comp-assert]
			size? 		 [comp-size?]
			if			 [comp-if]
			either		 [comp-either]
			case		 [comp-case]
			switch		 [comp-switch]
			until		 [comp-until]
			while		 [comp-while]
			any			 [comp-expression-list]
			all			 [comp-expression-list/_all]
			exit		 [comp-exit]
			return		 [comp-exit/value]
			declare		 [comp-declare]
			null		 [comp-null]
			context		 [comp-context]
			with		 [comp-with]
			comment 	 [comp-comment]
			
			true		 [also true pc: next pc]		  ;-- converts word! to logic!
			false		 [also false pc: next pc]		  ;-- converts word! to logic!
			
			func 		 [raise-level-error "a function"] ;-- func declaration not allowed at this level
			function 	 [raise-level-error "a function"] ;-- func declaration not allowed at this level
			alias 		 [raise-level-error "an alias"]	  ;-- alias declaration not allowed at this level
		]
		
		foreach [word action] keywords [append keywords-list word]
		foreach [name spec] functions  [append keywords-list name]
		
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
				either locals [join "^/*** in function: " func-name][""]
			]
			if pc [
				print [
					"*** at line:" calc-line lf
					"*** near:" mold copy/part pc 8
				]
			]
			quit-on-error
		]
		
		throw-warning: func [msg [string! block!] /near][
			print [
				"*** Warning:" 	reform msg
				"^/*** in:" 	mold script
				"^/*** at:" 	mold copy/part any [all [near back pc] pc] 8
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
		
		raise-runtime-error: func [error [integer!]][
			emitter/target/emit-get-pc				;-- get current CPU program counter address
			last-type: [integer!]					;-- emit-get-pc returns an integer! (required for next line)
			compiler/comp-call '***-on-quit reduce [error <last>] ;-- raise a runtime error
		]
		
		undecorate: func [value [word! path! set-word! set-path!] /local v pos][
			unless find v: mold value decoration [return value]
			
			while [pos: find v decoration][
				unless find ns-list to path! copy/part v pos [
					pos: next pos
					v: append replace/all copy/part head v pos decoration slash pos
					return load v
				]
				v: at v pos + 1
			]
			value
		]
		
		backtrack: func [value /local res][
			if find [word! path! set-word! set-path!] type?/word value [
				value: undecorate value
			]
			pc: any [res: find/only/reverse pc value pc]
			to logic! res
		]
		
		blockify: func [value][either block? value [value][reduce [value]]]

		literal?: func [value][
			not any [word? value get-word? value path? value block? value value = <last>]
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
			
			either alias: find-aliased/position type/1 [		
				get-alias-id alias
			][
				type: resolve-aliased type
				type: switch/default type/1 [
					any-pointer! ['int-ptr!]
					pointer! [pick [int-ptr! byte-ptr!] type/2/1 = 'integer!]
				][type/1]
				select emitter/datatype-ID type
			]
		]
		
		system-reflexion?: func [path [path! set-path!] /local def][
			if path/1 = 'system [
				switch path/2 [
					alias [
						unless path/3 [
							backtrack path
							throw-error "invalid system/alias path access"
						]
						unless def: find-aliased/position path/3 [
							backtrack path
							throw-error ["undefined alias name:" path/3]
						]
						last-type: [integer!]
						return get-alias-id def			;-- special encoding for aliases
					]
					words [
						unless path/3 [
							backtrack path
							throw-error "invalid system/words path access"
						]
						path: remove/part copy path 2
						return either 1 = length? path [
							either set-path? path [to set-word! path/1][path/1]
						][
							path
						]
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
		
		get-return-type: func [name [word!] /local type spec][
			unless all [
				spec: find-functions name
				type: select spec/2/4 return-def
			][
				backtrack name
				throw-error ["return type missing in function:" name]
			]
			any [type none-type]
		]
		
		set-last-type: func [spec [block!]][
			if spec: select spec return-def [last-type: spec]
		]
		
		local-variable?: func [name [word!]][
			all [locals find locals name]
		]
		
		exists-variable?: func [name [word! set-word!]][
			name: to word! name
			to logic! any [
				local-variable? name
				find globals name
			]
		]
		
		select-globals: func [name [word!] /local pos][
			all [
				pos: find globals name
				pos/2
			]
		]
		
		get-variable-spec: func [name [word!]][
			any [
				all [locals select locals name]
				select-globals name
			]
		]
		
		get-arity: func [spec [block!] /local count][
			count: 0
			parse spec [opt block! any [word! block! (count: count + 1)]]
			count
		]
		
		any-path?: func [value][
			find [path! set-path! lit-path!] type?/word value
		]
		
		any-float?: func [type [block!]][
			find any-float! type/1
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
		
		equal-types-list?: func [types [block!]][
			forall types [							;-- check if all last expressions are of same type
				unless types/1/1 [return none-type]	;-- test if type is defined
				types/1: resolve-aliased types/1	;-- reduce aliases and pseudo-types
				if all [
					not head? types
					not equal-types? types/-1/1 types/1/1
				][
					return none-type
				]
			]
			first head types						;-- all types equal, return the first one
		]
						
		with-alias-resolution: func [mode [logic!] body [block!] /local saved][
			saved: resolve-alias?
			resolve-alias?: mode	
			do body
			resolve-alias?: saved
		]
		
		find-aliased: func [type [word!] /prefix /position /local ns pos][
			if all [ns: resolve-ns type find aliased-types ns][type: ns]
			if prefix [return ns]
			pos: find aliased-types type
			either position [pos][all [pos pos/2]]
		]
		
		resolve-aliased: func [type [block!] /local name][
			name: type/1
			all [
				type/1								;-- ensure it is not [none]
				not base-type? name
				not find type-sets name
				not all [
					enum-type? name
					type: [integer!]
				]
				not type: find-aliased name
				throw-error ["unknown type:" type]
			]
			type
		]
		
		resolve-type: func [name [word!] /with parent [block! none!] /local type local?][
			type: any [
				all [parent select parent name]
				local?: all [locals select locals name]
				select-globals name
			]
			if all [not type find functions name][
				return reduce ['function! functions/(decorate-fun name)/4]
			]
			if any [
				all [not local?	any [enum-type? name enum-id? name]]
				enum-type? type/1
			][
				return [integer!]
			]
			unless any [not resolve-alias? base-type? type/1][
				type: find-aliased type/1
			]
			type
		]
		
		resolve-struct-member-type: func [spec [block!] name [word!] /local type][
			unless type: select spec name [
				while [not all [any-path? pc/1 find pc/1 name]][pc: back pc]
				throw-error [
					"invalid struct member" to lit-word! name "in:" mold to path! pc/1
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
		
		get-type: func [value /local type][
			switch/default type?/word value [
				none!	 [none-type]				;-- no type case (func with no return value)
				tag!	 [either value = <last> [last-type][ [logic!] ]]
				logic!	 [[logic!]]
				word! 	 [resolve-type value]
				char!	 [[byte!]]
				integer! [[integer!]]
				decimal! [[float!]]
				string!	 [[c-string!]]
				path!	 [resolve-path-type value]
				object!  [value/type]
				block!	 [
					if value/1 = 'not [return get-type value/2]	;-- special case for NOT multitype native
					
					either 'op = second get-function-spec value/1 [
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
				get-word! [
					type: resolve-type to word! value
					switch/default type/1 [
						function! [type]
						integer! byte! float! float32! [compose/deep [pointer! [(type/1)]]]
					][
						throw-error ["invalid datatype for a get-word:" mold type]
					]
				]
			][
				throw-error ["not accepted datatype:" type? value]
			]
		]
		
		enum-type?: func [name [word!] /local type][
			all [
				type: find/skip enumerations name 3			;-- SELECT/SKIP on hash! unreliable!
				reduce [next type]
			]
		]
		
		enum-id?: func [name [word!] /local pos][
			all [
				pos: find/skip next enumerations name 3
				reduce [pos/-1]
			]
		]

		get-enumerator: func [name [word!] /value /local pos][
			all [
				pos: find/skip next enumerations name 3		;-- SELECT/SKIP on hash! unreliable!
				pos/2
			]
		]
		
		set-enumerator: func [
			identifier [word!] name [word! block!] value [integer! word!] /local list v
		][
			store-ns-symbol identifier
			if ns-path [identifier: ns-prefix identifier]
			
			if word? name [name: reduce [name]]
			forall name [
				store-ns-symbol name/1
				if ns-path [name/1: ns-prefix name/1]
				check-enum-word name/1
			]
			name: head name
			
			if all [
				word? value
				none? value: get-enumerator resolve-ns value
			][
				throw-error ["cannot resolve literal enum value for:" form name]
			]
			forall name [
				if verbose > 3 [print ["Enum:" identifier "[" name/1 "=" value "]"]]
				repend enumerations [identifier name/1 value]
			]
			value: value + 1
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
				spec: find functions expr/1 		 ;-- works for unary & binary functions only!
				spec: spec/2
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
				'else [
					expr: get-type expr
					if resolve-alias? [expr: resolve-aliased expr]
					expr
				]
			]
			type
		]
		
		push-call: func [action [word! set-word! set-path!]][
			append/only expr-call-stack action
			if verbose >= 4 [
				new-line/all expr-call-stack off
				?? expr-call-stack
			]
		]
		
		pop-calls: does [clear expr-call-stack]
		
		cast: func [obj [object!] /local value ctype type][
			value: obj/data
			ctype: resolve-aliased obj/type
			type: get-type value

			if all [type = obj/type type/1 <> 'function!][
				throw-warning/near [
					"type casting from" type/1 
					"to" obj/type/1 "is not necessary"
				] 'as
			]
			if any [
				all [type/1 = 'function! not find [function! integer!] ctype/1]
				all [find [float! float64!] ctype/1 not find [float! float64! float32!] type/1]
				all [find [float! float64!] type/1  not find [float! float64! float32!] ctype/1]
				all [type/1 = 'float32! not find [float! float64! integer!] ctype/1]
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
						integer! [value: to char! value and 255]
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
		
		decorate-function: func [name [word!]][
			to word! join "_local_" form name
		]
		
		find-functions: func [name [word!]][
			if all [
				locals
				type: select locals name
				type/1 = 'function!
			][
				name: decorate-function name
			]
			find functions name
		]

		get-function-spec: func [name [word!] /local spec][
			all [
				spec: find-functions name
				spec/2
			]
		]

		decorate-fun: func [name [word!] /local type][
			either all [
				locals
				type: select locals name
				block? type
				type/1 = 'function!
			][
				decorate-function name
			][
				name
			]
		]

		remove-func-pointers: has [vars name][
			vars: any [find/tail locals /local []]
			forall vars [
				if all [
					word? vars/1
					block? vars/2
					vars/2/1 = 'function!
				][
					name: decorate-function vars/1
					remove/part find functions name 2
				]
			]
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
		
		store-ns-symbol: func [name [word!] /local pos][
			if ns-path [
				either pos: find/skip sym-ctx-table name 2 [
					either block? pos/2 [
						if find/only pos/2 ns-path [exit]
					][
						if ns-path = pos/2 [exit]
						pos/2: reduce [pos/2]
					]
					append/only pos/2 copy ns-path
				][
					append sym-ctx-table name
					append/only sym-ctx-table copy ns-path
				]
			]
		]
		
		add-ns-symbol: func [name [set-word!]][
			append second find/only ns-list ns-path to word! name
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
		
		ns-decorate: func [path [path!] /global /set][
			to get pick [set-word! word!] to logic! set mold path	;-- unless / use: replace/all mold path slash decoration
		]

		ns-join: func [ns [path! word!] name [word! path! set-word! set-path!]][
			join ns to word! mold/flat name
		]

		ns-prefix: func [name [word! path! set-word! set-path!] /set][
			if set-word? name [name: to word! name]
			name: ns-join ns-path name
			either set [ns-decorate/set name][ns-decorate name]
		]
		
		check-enum-word: func [name [word!] /local error][
			case [
				all [find keywords name name <> 'context][
					error: ["attempt to redefine a protected keyword:" name]
				]

				find functions name [
					error: ["attempt to redefine existing function name:" name]
				]

				find definitions name [
					error:  ["attempt to redefine existing definition:" name]
				]

				find-aliased name [
					error:  ["attempt to redefine existing alias definition:" name]
				]

				base-type? name [
					error:  ["redeclaration of base type:" name ]
				]

				any [
					exists-variable? name
					get-variable-spec name
				][										;-- it's a variable			
					error:  ["redeclaration of variable:" name]
				]

				enum-type? name [
					error:  ["redeclaration of enum identifier:" name ]
				]
				
				enum-id? name [
					error:  ["redeclaration of enumerator:" name ]
				]
			]
			if error [throw-error error]
		]
		
		check-keywords: func [name [word!]][
			if find keywords name [
				throw-error ["attempt to redefine a protected keyword:" name]
			]
		]
		
		check-path-index: func [path [path! set-path!] type [word!] /local ending enum-value][
			ending: path/2
			case [
				all [type = 'pointer ending = 'value][]	;-- pass thru case
				word? ending [
					either all [
						not local-variable? ending
						enum-value: get-enumerator ending
					][
						path/2: ending: enum-value
					][
						unless any [
							local-variable? ending
							find globals ending: resolve-ns ending
							get-enumerator ending
						][
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
			if any [enum-type? name	enum-id? name][
				pc: back pc
				throw-error ["attempt to redefine existing enumerator:" name]
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
			/local type type-def spec-type attribs value args locs cconv pos
		][
			unless block? specs [
				throw-error "function definition requires a specification block"
			]
			cconv: ['cdecl | 'stdcall]
			attribs: [
				[cconv ['variadic | 'typed]]
				| [['variadic | 'typed] cconv]
				| 'infix | 'variadic | 'typed | 'callback | cconv
			]
			type-def: pick [[func-pointer | type-spec] [type-spec]] to logic! extend

			unless catch [
				parse specs [
					pos: opt [into attribs]				;-- functions attributes
					pos: opt string!
					pos: copy args any [pos: word! into type-def opt string!]	;-- arguments definition
					pos: opt [							;-- return type definition				
						set value set-word! (					
							rule: pick reduce [[into type-spec] fail] value = return-def
						) rule
						opt string!
					]
					pos: opt [/local copy locs some [pos: word! opt [into type-spec]]] ;-- local variables definition
				]
			][
				throw-error rejoin ["invalid definition for function " name ": " mold pos]
			]
			if block? args [
				remove-each s args [string? s]
				foreach [name type] args [
					if enum-id? name [
						throw-warning ["function's argument redeclares enumeration:" name]
					]
				]
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
				if alias: find-aliased expected/1 [expected: alias]
			]
			if all [
				ret
				block? expr
				any [set-word? expr/1 set-path? expr/1]
			][
				type: none
			]
			unless any [
				all [
					object? expr
					expr/action = 'null
					type: either expected/1 = 'any-type! [expr/type][expected]	;-- morph null type to expected
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
					any [
						find [any-type! any-pointer!] expected/1
						all [
							expected/1 = 'function!
							compare-func-specs name expr type/2 expected/2	 ;-- callback case
						]
					]
				]
				expected = type 						;-- normal single-type case
				all [
					type
					type/1 = 'integer!
					enum-type? expected/1				;-- TODO: add also a value check for enums
				]
			][
				if expected = type [type: 'null]		;-- make null error msg explicit
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
		
		check-arguments-type: func [name args /local entry spec list type][
			if find [set-word! set-path!] type?/word name [exit]
			
			entry: find functions name
			if all [
				not empty? spec: entry/2/4 
				block? spec/1
			][
				spec: next spec							;-- jump over attributes block
			]
			list: clear []
			forall args [
				either all [decimal? args/1 spec/2/1 = 'float32!][
					args/1:	make action-class [			;-- inject type casting to float32!
						action: 'type-cast
						type: [float32!]
						data: args/1					;-- literal float!
					]
					append/only list spec/2				;-- pass-thru for float! values used as float32! arguments
				][
					append/only list check-expected-type name args/1 spec/2
				]
				spec: skip spec	2
			]
			if all [
				any [
					find emitter/target/comparison-op name
					find emitter/target/bitwise-op name
				]
				not equal-types? list/1/1 list/2/1		;-- allow implicit casting for math ops only
			][
				backtrack name
				throw-error [
					"left and right argument must be of same type for:" name
					"^/*** left:" join list/1/1 #"," "right:" list/2/1
				]
			]
			if find emitter/target/math-op name	[
				case [
					any [
						all [list/1/1 = 'byte! any-pointer? list/2]
						all [list/2/1 = 'byte! any-pointer? list/1]
					][
						backtrack name
						throw-error [
							"arguments must be of same size for:" name
							"^/*** left:" join list/1/1 #"," "right:" list/2/1
						]
					]
					any [string? unbox args/1 string? unbox args/2][
						backtrack name
						throw-error "a literal string cannot be used with a math operator"
					]
				]
			]
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
		
		fetch-into: func [								;-- compile sub-block
			code [block! paren!] body [block!] /root
			/local save-pc level
		][
			if root [
				level: block-level						;-- save block level from parent context
				clear expr-call-stack
			]
			save-pc: pc
			pc: code
			do body
			if root [block-level: level]
			next pc: save-pc
		]
		
		get-cconv: func [specs [block!]][
			pick [cdecl stdcall] to logic! all [
				not empty? specs
				block? specs/1
				find specs/1 'cdecl
			]
		]
		
		fetch-func: func [name /local specs type cc][
			name: to word! name
			store-ns-symbol name
			if ns-path [name: ns-prefix name]
			check-func-name name
			check-specs name specs: pc/2
			specs: copy specs
			remove-each s specs [string? s]
			
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
			repend natives [
				name specs pc/3 script
				all [ns-path copy ns-path]
				all [ns-stack copy/deep ns-stack]		;@@ /deep doesn't work on paths
			]
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
						all [
							word? expr/1
							any [
								get-variable-spec expr/1
								enum-id? expr/1
							]
						]
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
		
		process-import: func [defs [block!] /local lib list cc name specs spec id reloc pos][
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
							pos: set name set-word! (
								name: to word! name
								store-ns-symbol name
								if ns-path [name: ns-prefix name]
								check-func-name name
							)
							pos: set id   string!   (repend list [id reloc: make block! 1])
							pos: set spec block!    (
								check-specs/extend name spec
								specs: copy specs
								specs/1: name
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
		
		process-syscall: func [defs [block!] /local name id spec pos][
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
		
		process-enum: func [name value /local enum-value enum-names][
			unless word? name [throw-error "enumeration expected a word as name"]
			
			either block? value [
				check-enum-word name 					;-- first checking enumeration identifier possible conflicts
				parse value [
					(enum-value: 0)
					any [
						[
							copy enum-names word!
							| (enum-names: make block! 10) some [
								set enum-name set-word!
								(append enum-names to word! enum-name)
							]	set enum-value [integer! | word!]
						] 
						(enum-value: set-enumerator name enum-names enum-value)
						| set enum-name 1 skip (
							throw-error ["invalid enumeration:" to word! enum-name]
						)
					]
				]
			][
				throw-error ["invalid enumeration (block required!):" mold value]
			]
		]
		
		comp-chunked: func [body [block!]][
			emitter/chunks/start
			do body
			emitter/chunks/stop
		]

		comp-directive: has [body][
			switch/default pc/1 [
				#import  [process-import  pc/2  pc: skip pc 2]
				#syscall [process-syscall pc/2	pc: skip pc 2]
				#enum	 [process-enum pc/2 pc/3 pc: skip pc 3]
				#verbose [set-verbose-level pc/2 pc: skip pc 2]
				#script	 [								;-- internal compiler directive
					compiler/script: secure-clean-path pc/2	;-- set the origin of following code
					pc: skip pc 2
				]
			][
				throw-error ["unknown directive" pc/1]
			]
		]
		
		comp-comment: does [
			pc: next pc
			either block? pc/1 [pc: next pc][fetch-expression]
			none
		]
		
		comp-with: has [ns list with-ns words res][
			ns: pc/2
			unless all [any [word? ns block? ns] block? pc/3][
				throw-error "WITH invalid argument"
			]
			unless block? ns [ns: reduce [ns]]
			
			forall ns [
				unless path? ns/1 [ns/1: to path! ns/1]
				unless find/only ns-list ns/1 [throw-error ["undefined context" ns/1]]
			]
			with-ns: unique copy ns
			
			list: clear []
			foreach ns with-ns [
				either empty? res: intersect list words: to block! second find/only ns-list ns [
					append list words
				][
					throw-warning rejoin [
						"contexts are using identical word"
						pick ["s: " ": "] 1 < length? res
						res
					]
				]
			]

			list: copy with-ns
			forall list [if path? list/1 [list/1: list/1/1]]	;@@ remove
			unless ns-stack [ns-stack: make block! 1]
			append ns-stack list
			
			fetch-into/root pc/3 [comp-dialect]
			
			pc: skip pc 3
			clear skip tail ns-stack negate length? list
			if empty? ns-stack [ns-stack: none]
			
			none
		]
		
		comp-context: has [name level][
			unless block? pc/2 [throw-error "context specification block is missing"]
			unless set-word? pc/-1 [throw-error "context's name setting is missing"]
			unless zero? block-level [
				pc: back pc
				throw-error "context has to be declared at root level"
			]
			
			check-keywords name: to word! pc/-1
			if any [										;@@ factorize this out
				all [locals find locals name]
				find globals name
				find functions name
				find aliased-types name
				find definitions name
				find enumerations name
			][
				pc: back pc
				throw-error "context name is already taken"
			]
			pc: next pc
			
			unless ns-stack [ns-stack: make block! 1]
			append ns-stack to word! mold/flat name
			
			either ns-path [
				append ns-path to word! mold/flat name
			][
				ns-path: to lit-path! mold/flat name		;-- workaround newline flag remanence issue
			]
			either find/only ns-list ns-path [
				throw-error ["context" name "already defined"]
			][
				repend ns-list [copy ns-path make hash! 32]
			]

			fetch-into/root pc/1 [comp-dialect]
			
			remove back tail ns-path
			if empty? ns-path [ns-path: none]
			remove back tail ns-stack
			if empty? ns-stack [ns-stack: none]
			
			pc: next pc
			none
		]
		
		comp-declare: has [rule value pos offset ns][
			unless find [set-word! set-path!] type?/word pc/-1 [
				throw-error "assignment expected before literal declaration"
			]
			value: to paren! reduce either find [pointer! struct!] pc/2 [
				rule: get pick [struct-syntax pointer-syntax] pc/2 = 'struct!
				unless catch [parse pos: pc/3 rule][
					throw-error ["invalid literal syntax:" mold pos]
				]
				if all [
					pc/2 = 'struct!
					(length? pc/3) <> (length? unique/skip pc/3 2)
				][
					throw-error ["duplicate member name in struct:" mold pc/3]
				]
				if pc/3/1 = 'float64! [pc/3/1: 'float!]
				offset: 3
				[pc/2 pc/3]
			][
				unless all [word? pc/2 resolve-aliased reduce [pc/2]][
					throw-error ["declaring literal for type" pc/2 "not supported"]
				]
				value: pc/2
				if all [ns-path ns: find-aliased/prefix value][value: ns]
				offset: 2
				['struct! value]
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
			if ptr?: find [pointer! struct! function!] ctype [ctype: reduce [pc/2 pc/3]]
			
			unless any [
				parse blockify ctype [func-pointer | type-syntax]
				find-aliased ctype
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
		
		comp-alias: has [name pos][
			unless set-word? pc/-1 [
				throw-error "assignment expected for ALIAS"
			]
			unless find [struct! function!] pc/2 [
				throw-error "ALIAS only allowed for struct! and function!"
			]
			name: to word! pc/-1
			store-ns-symbol name
			all [
				not base-type? name
				ns-path
				name: ns-prefix name
			]
			if find aliased-types name [
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
			switch pc/2 [
				struct! [
					unless catch [parse pos: pc/3 struct-syntax][
						throw-error ["invalid struct syntax:" mold pos]
					]
				]
				function! [check-specs 'pointer pc/3]
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
					all [enum-type? expr [integer!]]
					find-aliased expr
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
					emitter/target/emit-integer-operation '= [<last> 0]
					reduce [not invert?]
				]
				object? expr [
					expr: cast expr
					unless find [word! path!] type?/word any [
						all [block? expr expr/1] expr 
					][
						emitter/target/emit-integer-operation '= [<last> 0]
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
						emitter/target/emit-integer-operation '= [<last> 0]
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
		
		comp-either: has [expr e-true e-false c-true c-false offset t-true t-false ret][
			pc: next pc
			expr: fetch-expression/final				;-- compile expression
			check-conditional 'either expr				;-- verify conditional expression
			expr: process-logic-encoding expr no
			check-body pc/1								;-- check TRUE block
			check-body pc/2								;-- check FALSE block
			
			set [e-true c-true]   comp-block-chunked	;-- compile TRUE block
			set [e-false c-false] comp-block-chunked	;-- compile FALSE block

			t-true:  resolve-expr-type/quiet e-true
			t-false: resolve-expr-type/quiet e-false

			last-type: either all [
				t-true/1 t-false/1
				t-true:  resolve-aliased t-true			;-- alias resolution is safe here
				t-false: resolve-aliased t-false
				equal-types? t-true/1 t-false/1
			][t-true][none-type]						;-- allow nesting if both blocks return same type

			if any [
				all [
					locals								;-- if in function body
					tail? pc							;-- and if at tail of body
					ret: select locals return-def		;-- and if function returns something
					ret/1 = 'logic!						;-- and if it returns a logic! value
				]
				all [
					not empty? expr-call-stack
					last-type/1 = 'logic!				;-- and if EITHER returns a logic! too
				]
			][
				if block? e-true  [emitter/logic-to-integer/with e-true  c-true]
				if block? e-false [emitter/logic-to-integer/with e-false c-false]
			]
		
			offset: emitter/branch/over c-false
			emitter/set-signed-state expr				;-- properly set signed/unsigned state
			emitter/branch/over/adjust/on c-true negate offset expr/1	;-- skip over JMP-exit
			emitter/merge emitter/chunks/join c-true c-false
			<last>
		]
		
		comp-case: has [cases list test body op bodies offset types][
			pc: next pc
			check-body cases: pc/1
			list:  make block! 8
			types: make block! 8
			
			until [										;-- collect and pre-compile all cases
				fetch-into cases [						;-- compile case test
					append/only list comp-block-chunked/only/test 'case
					cases: pc							;-- set cursor after the expression
				]
				check-body cases/1
				fetch-into cases [						;-- compile case body
					append/only list body: comp-block-chunked
					append/only types resolve-expr-type/quiet body/1
				]
				tail? cases: next cases
			]
			
			bodies: comp-chunked [raise-runtime-error 100] ;-- raise a runtime error if unmatched value
			
			list: tail list								;-- point to last case test
			until [										;-- left join all cases in reverse order			
				list: skip list -2
				set [test body] list					;-- retrieve case-test and case-body chunks

				emitter/set-signed-state test/1			;-- properly set signed/unsigned state
				offset: negate emitter/branch/over bodies		;-- insert case exit branching
				emitter/branch/over/on/adjust body/2 test/1/1 offset	;-- insert case test branching
				
				body: emitter/chunks/join test/2 body/2	;-- join case test with case body
				bodies: emitter/chunks/join body bodies	;-- left join case with other cases
				head? list		
			]	
			emitter/merge bodies						;-- commit all to main code buffer
			pc: next pc
			last-type: equal-types-list? types			;-- test if usage in expression allowed
			<last>
		]
		
		comp-switch: has [expr save-type spec value values body bodies list types default pos][
			pc: next pc
			expr: fetch-expression/keep/final			;-- compile argument
			if any [none? expr last-type = none-type][
				throw-error "SWITCH argument has no return value"
			]
			save-type: last-type			
			check-body spec: pc/1
			foreach w [values list types][set w make block! 8]
			forall spec [								;-- resolve possible enumeration symbols
				if all [word? spec/1 spec/1 <> 'default][
					check-enum-symbol spec
				]
			]
			
			;-- check syntax and store parts in different lists
			unless parse spec [
				some [
					pos: copy value some [integer! | char!] 
					(repend values [value none])		;-- [value body-offset ...]
					pos: block! (
						fetch-into pos [				;-- compile action body
							body: comp-block-chunked
							append/only list body/2		
							append/only types resolve-expr-type/quiet body/1
						]
					)
				]
				opt [
					'default pos: block! (
						fetch-into pos [				;-- compile default body
							default: comp-block-chunked
							append/only types resolve-expr-type/quiet default/1
						]
					)
				]
			][
				throw-error ["wrong syntax in SWITCH block at:" copy/part pos 4]
			]

			;-- assemble all actions together, with exit at end for each one
			bodies: emitter/chunks/empty
			list: tail list								;-- point to last action
			until [										;-- left join all actions in reverse order		
				body: first list: back list
				unless empty? bodies/1 [
					emitter/branch/over bodies			;-- insert case exit branching
				]
				bodies: emitter/chunks/join body bodies	;-- left join action with other actions		
				change at values 2 * index? list length? bodies/1
				head? list		
			]
			
			;-- insert default clause or jump to runtime error
			either default [
				emitter/branch/over bodies          	;-- insert default exit branching
				bodies: emitter/chunks/join default/2 bodies ;-- insert default action
			][
				body: comp-chunked [raise-runtime-error 101] ;-- raise a runtime error if unmatched value
				bodies: emitter/chunks/join body bodies
			]

			;-- construct tests + branching and insert them at head
			last-type: save-type
			emitter/set-signed-state expr				;-- properly set signed/unsigned state
			values: tail values
			until [
				values: skip values -2
				foreach v values/1 [					;-- process multiple values per action
					body: comp-chunked [
						emitter/target/emit-integer-operation '= reduce [<last> v]
					]
					emitter/branch/over/on/adjust bodies [=] values/2	;-- insert action branching			
					bodies: emitter/chunks/join body bodies
				]
				head? values
			]
			emitter/merge bodies						;-- commit all to main code buffer	
			
			pc: next pc
			last-type: equal-types-list? types			;-- test if usage in expression allowed
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
		
		comp-assignment: has [name value n enum ns][
			push-call name: pc/1
			pc: next pc
			if set-word? name [
				n: to word! name
				unless local-variable? n [store-ns-symbol n]
				
				unless all [
					local-variable? n
					n = 'context						;-- explicitly allow 'context name for local variables
				][
					check-keywords n					;-- forbid keywords redefinition
				]
				if find definitions n [
					backtrack name
					throw-error ["redeclaration of definition" name]
				]
				if all [
					not local-variable? n
					enum: enum-id? n
				][
					backtrack name
					throw-error ["redeclaration of enumerator" name "from" enum]
				]
				if all [
					get-word? pc/1
					find functions to word! pc/1
				][
					throw-error "storing a function! requires a type casting"
				]
				unless local-variable? n [
					if ns-path [add-ns-symbol pc/-1]
					if all [ns: resolve-ns n ns <> n][name: to set-word! ns]
					check-func-name/only to word! name	;-- avoid clashing with an existing function name		
				]
			]
			if set-path? name [
				unless any [name/1 = 'system local-variable? name/1][
					name: resolve-ns-path name
				]
				if all [series? name value: system-reflexion? name][name: value]
			]
			
			either none? value: fetch-expression [		;-- explicitly test for none!
				none
			][
				new-line/all reduce [name value] no
			]
		]
		
		comp-func-args: func [name [word!] entry [hash!] /local attribute fetch expr args n pos][
			push-call name
			pc: next pc							;-- it's a function
			either attribute: check-variable-arity? entry/2/4 [
				fetch: [
					pos: pc
					expr: fetch-expression
					either attribute = 'typed [
						if all [expr = <last> none? last-type/1][
							pc: pos
							throw-error "expression has no defined return type"
						]
						append args id: get-type-id expr
						append/only args expr
						append args pick [#_ 0] id = emitter/datatype-ID/float! ;-- 32-bit padding
					][
						append/only args expr
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
				new-line/all head insert/only args name no
			]
		]
		
		resolve-ns-path: func [path [path! set-path!] /local new pos][
			new: resolve-ns/path path/1					;-- try to prefix path/1

			either find/only ns-list to path! new [		;-- check if (prefixed) path/1 is a namespace
				new: to path! new
				until [									;-- collect all ns prefixes from head
					path: next path
					append new path/1					;-- move each path value to new one
					not find/only ns-list new			;-- while the new path is still a namespace
				]
				new: ns-decorate new					;-- prefix and convert to word 
				unless tail? next path [				;-- if non-ns remains in path
					new: append to path! new next path	;-- convert back to path by adding non-ns remain 
				]
				if set-path? path [
					new: to either word? new [set-word!][set-path!] new
				]
				new
			][
				unless word? new [path/1: ns-decorate new]	;-- only prefix+convert path/1 if required
				path
			]
		]
		
		comp-path: has [path value ns][
			path: pc/1
			if #":" = first mold path/1 [
				throw-error "get-path! syntax is not supported"
			]
			either all [
				not local-variable? path/1
				path: resolve-ns-path path
				word? path
			][
				if value: get-enumerator path [
					last-type: [integer!]
					pc: next pc
					return value
				]
				comp-word/with path
			][
				either value: system-reflexion? path [
					either path/2 = 'words [
						return comp-word/with/root value ;-- re-route to global word resolution
					][
						pc: next pc
					]
				][
					comp-word/path path/1				;-- check if root word is defined
					last-type: resolve-path-type path
				]
				any [value path]
			]
		]
		
		comp-get-word: has [spec name ns][
			name: to word! pc/1
			case [
				all [spec: find functions name: resolve-ns name spec: spec/2][
					unless find [native routine] spec/2 [
						throw-error "get-word syntax only reserved for native functions for now"
					]
					unless spec/5 = 'callback [append spec 'callback]
				]
				not	any [
					local-variable? to word! pc/1
					find globals name
				][
					throw-error "cannot get a pointer on an undefined identifier"
				]
			]
			also to get-word! name pc: next pc
		]
		
		match-ns: func [name [word!] ctx [word! path!] path /local pos][
			either pos: find ns-stack either path? ctx [ctx/1][ctx][ ;-- match (1st) context with stack
				if path? ctx [							;-- context hierarchy to match with stack
					foreach level ctx [					;-- match each context with next one on stack
						if pos/1 <> level [return none]	;-- if doesn't match, prefix doesn't apply
						pos: next pos					;-- next stack entry
					]
				]
				if path [return ns-join to path! ctx name] ;-- if /path, defer word conversion
				ns-decorate ns-join to path! ctx name	;-- prefix and convert back to word
			][
				none									;-- no match on stack
			]
		]
		
		resolve-ns: func [name [word!] /path /local ctx][
			unless ns-stack [return name]				;-- no current ns, pass-thru

			if ctx: find/skip sym-ctx-table name 2 [	;-- fetch context candidates
				ctx: ctx/2								;-- SELECT/SKIP on hash! unreliable!
				either block? ctx [						;-- more than one candidate
					ctx: tail ctx						;-- start from last defined context
					until [
						ctx: back ctx
						if value: match-ns name ctx/1 path [
							return value				;-- prefix name if context on stack
						]
						head? ctx
					]									;-- no match found, pass-thru
				][										;-- one parent context only
					name: any [match-ns name ctx path name] ;-- prefix name if context is on stack
				]
			]
			name
		]
	
		comp-word: func [
			/path symbol [word!]
			/with word [word!]
			/root										;-- system/words/* pass-thru
			/local entry name local? spec type
		][
			name: pc/1
			name: any [
				word
				symbol
				all [local-variable? name name]			;-- pass-thru for locals
				all [not root resolve-ns name]
				name
			]
			local?: local-variable? name
			case [
				all [
					not all [local? name = 'context]
					entry: select keywords name			;-- it's a reserved word
				][
					push-call pc/1
					do entry
				]
				any [
					all [
						local?
						any [
							all [						;-- block local function pointers
								block? type: select locals name
								'function! <> type/1
							]
							not block? type				;-- pass-thru
						]
					]
					all [
						find globals name
						'function! <> first get-type name	;-- block function pointers
					]
				][										;-- it's a variable
					if not-initialized? name [
						throw-error ["local variable" name "used before being initialized!"]
					]
					last-type: resolve-type name
					also name pc: next pc
				]
				type: enum-type? name [
					last-type: type
					if verbose >= 3 [print ["ENUMERATOR" name "=" last-type]]
					also name pc: next pc
				]
				all [
					not path
					entry: find-functions name
				][
					spec: entry/2/4
					if all [
						block? spec/1
						find spec/1 'infix
						path? pc/1
					][
						throw-error "infix functions cannot be called using a path"
					]
					comp-func-args name entry
				]
				'else [throw-error ["undefined symbol:" mold name]]
			]
		]
		
		cast-null: func [variable [set-word! set-path!] /local casting][
			unless all [
				attempt [
					casting: get-type any [
						all [set-word? variable	to word! variable]
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
					find [import native infix routine] functions/:name/2
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
			/local list type res import? left right dup var-arity? saved? arg expr
		][
			name: decorate-fun name
			list: either issue? args/1 [				;-- bypass type-checking for variable arity calls
				args/2
			][
				check-arguments-type name args
				args
			]
			order-args name list						;-- reorder argument according to cconv

			import?: functions/:name/2 = 'import		;@@ syscalls don't seem to need special alignment??
			if import? [emitter/target/emit-stack-align-prolog args]

			type: functions/:name/2
			either type <> 'op [					
				forall list [							;-- push function's arguments on stack
					expr: list/1
					if block? unbox expr [comp-expression expr yes]	;-- nested call
					if object? expr [cast expr]
					if type <> 'inline [
						emitter/target/emit-argument expr functions/:name ;-- let target define how arguments are passed
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
			if import? [emitter/target/emit-stack-align-epilog args]
			res
		]
				
		comp-path-assign: func [
			set-path [set-path!] expr casted [block! none!]
			/local type new value
		][
			if all [
				not local-variable? set-path/1
				enum-id? set-path/1
			][
				backtrack set-path
				throw-error ["enumeration cannot be used as path root:" set-path/1]
			]
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
			emitter/access-path set-path either any [block? value path? value][
				 <last>
			][
				expr
			]
		]
		
		comp-variable-assign: func [
			set-word [set-word!] expr casted [block! none!]
			/local name type new value fun-name
		][
			name: to word! set-word		
			if find aliased-types name [
				backtrack set-word
				throw-error "name already used for as an alias definition"
			]
			if not-initialized? name [
				init-local name expr casted				;-- mark as initialized and infer type if required
			]

			if all [
				casted
				casted/1 = 'function!
				local-variable? name
			][
				fun-name: to word! join "_local_" form name
				add-function 'routine reduce [fun-name none casted/2] get-cconv casted/2
				append last functions reduce [name 'local]
			]
			
			either type: any [
				get-variable-spec name					;-- test if known variable (local or global)	
				enum-id? name
			][
				type: resolve-aliased type
				value: get-type expr
				if block? expr [parse value [type-spec]] ;-- prefix return type if required	
				new: resolve-aliased value
				
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
				if all [casted casted/1 = 'function!][
					add-function 'routine reduce [name none casted/2] get-cconv casted/2
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
			
			;-- dead expressions elimination
			if all [
				not any [tail? pc variable]				;-- not last expression nor assignment value
				1 >= length? expr-call-stack			;-- one (for math op) or no parent call
				'switch <> pick tail expr-call-stack -1
				any [
					all [
						any [
							word? expr 					;-- variable alone
							literal? expr				;-- literal, but not logic value
						]
						'logic! <> first get-type expr
					]
					all [
						block? expr
						functions/(decorate-fun expr/1)/2 = 'op	;-- math expression
						any [							;-- no return value, or return value type <> logic!
							not type: find functions/(expr/1)/4 return-def
							type/2/1 <> 'logic!
						]
					]
				]
			][exit]

			;-- emitting expression code
			either block? expr [
				type: comp-call expr/1 next expr 		;-- function call case (recursive)
				if type [last-type: type]				;-- set last-type if not already set
			][
				last-type: either not any [
					all [new? literal? unbox expr]		;-- if new variable, value will be store in data segment
					all [set-path? variable not path? expr]	;-- value loaded at lower level
					tag? unbox expr
				][
					emitter/target/emit-load either boxed [boxed][expr]	;-- emit code for single value
					either all [boxed not decimal? unbox expr][
						emitter/target/emit-casting boxed no	;-- insert runtime type casting if required
						boxed/type
					][
						resolve-expr-type expr
					]
				][
					resolve-expr-type expr
				]
			]
			
			;-- postprocessing result
			if all [
				any [keep? variable]					;-- if result needs to be stored
				block? expr								;-- and if expr is a function call		
				last-type/1 = 'logic!					;-- which return type is logic!
			][
				emitter/logic-to-integer expr/1			;-- runtime logic! conversion before storing
			]
			
			if all [									;-- clean FPU stack when required
				not any [keep? variable]
				any-float? last-type
				block? expr
				any [
					not find functions/(expr/1)/4 return-def	;-- clean if no return value
					1 = length? expr-call-stack					;-- or if return value not used
				]
			][			
				emitter/target/emit-float-trash-last	;-- avoid leaving a FPU slot occupied,
			]											;-- if return value is not used.
			
			;-- storing result if assignement required
			if variable [
				if all [boxed not casting][
					casting: resolve-aliased boxed/type
				]
				unless boxed [boxed: expr]
				switch type?/word variable [
					set-word! [comp-variable-assign variable expr casting]
					set-path! [comp-path-assign		variable boxed casting]
				]
			]
		]
		
		check-enum-symbol: func [code [any-block!] /local value][
			if all [									;-- if enum, replace it with its integer value
				word? code/1
				not local-variable? code/1
				value: get-enumerator resolve-ns code/1
			][
				change code value
			]
		]
		
		infix?: func [pos [block! paren!] /local specs][
			all [
				not tail? pos
				word? pos/1
				specs: find functions resolve-ns pos/1
				specs: specs/2
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
		
		fetch-expression: func [/final /keep /local expr pass value][
			check-infix-operators
			
			if verbose >= 4 [print ["<<<" mold pc/1]]
			pass: [also pc/1 pc: next pc]
			
			if tail? pc [
				pc: back pc
				throw-error "missing argument"
			]
			if job/debug? [store-dbg-lines]
			
			check-enum-symbol pc

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
				decimal!	[do pass]
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
						if all [paren? pc/1 not infix? at pc 2][raise-paren-error]
						expr: do fetch
						unless tail? pc [pop-calls]
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
						expr: fetch-expression/final/keep
					]
					'else [expr: fetch-expression/final/keep]
				]
				pop-calls
				emitter/target/on-root-level-entry
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
					object? expr 
					find [block! tag!] type?/word expr/data
				][
					emitter/target/emit-casting expr no	;-- insert runtime type casting when required
					last-type: expr/type
				]
			]
			emitter/leave name locals args-sz local-sz	;-- build function epilog
			remove-func-pointers
			clear locals-init
			locals: func-name: none
		]
		
		comp-natives: does [			
			foreach [name spec body origin ns nss] natives [
				if verbose >= 2 [
					print [
						"---------------------------------------^/"
						"function:" name newline
						"---------------------------------------"
					]
				]
				script: origin
				ns-path: ns
				ns-stack: nss
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

		run: func [obj [object!] src [block!] file [file!] /no-header /runtime /no-events][
			runtime: to logic! runtime
			job: obj
			pc: src
			script: secure-clean-path file
			unless no-header [comp-header]
			unless no-events [emitter/target/on-global-prolog runtime]
			comp-dialect
			unless no-events [
				case [
					runtime [
						emitter/target/on-global-epilog yes	;-- postpone epilog event after comp-runtime-epilog
					]
					not job/runtime? [
						emitter/target/on-global-epilog no
					]
				]
			]
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
					"-- emitter/symbols --"  nl mold new-line/all/skip to-block emitter/symbols yes 2 nl
				]
			]
			verbose >= 2 [
				print [
					"-- compiler/functions --" nl mold new-line/all/skip to-block compiler/functions yes 2 nl
				]
			]
			verbose >= 6 [
				print [
					"-- emitter/code-buf --" nl mold emitter/code-buf nl
					"-- emitter/data-buf --" nl mold emitter/data-buf nl
					"as-string:"        	 nl mold as-string emitter/data-buf nl
				]
			]
		]
	]

	comp-start: has [script][
		emitter/start-prolog
		script: secure-clean-path runtime-path/start.reds
 		compiler/run/no-events job loader/process script script
 		emitter/start-epilog
 
		;-- selective clean-up of compiler's internals
 		remove/part find compiler/globals 'system 2		;-- avoid 'system redefinition clash
 		remove/part find emitter/symbols 'system 4
		clear compiler/definitions
		clear compiler/aliased-types
	]
	
	comp-runtime-prolog: has [script][
		script: secure-clean-path runtime-path/common.reds
 		compiler/run/runtime job loader/process script script
	]
	
	comp-runtime-epilog: does [	
		if job/type = 'exe [
			compiler/comp-call '***-on-quit [0 0]		;-- call runtime exit handler
		]
		emitter/target/on-global-epilog no
	]
	
	clean-up: does [
		compiler/ns-path: 
		compiler/ns-stack: 
		compiler/locals: none
		compiler/resolve-alias?:  yes
		
		clear compiler/imports
		clear compiler/natives
		clear compiler/ns-list
		clear compiler/sym-ctx-table
		clear compiler/globals
		clear compiler/definitions
		clear compiler/enumerations
		clear compiler/aliased-types
		clear compiler/user-functions
		clear compiler/debug-lines/records
		clear compiler/debug-lines/files
		clear emitter/symbols
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
	
	set 'dt func [code [block!] /local t0][
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
		cpu-version:	6.0				;-- CPU version (default: Pentium Pro)
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
		literal-pool?:	no				;-- yes => use pools to store literals, no => store them inlined (default: no)
		unicode?:		no				;-- yes => use Red Unicode API for printing on screen
		red-only?:		no				;-- yes => stop compilation at Red/System level and display output
	]
	
	compile: func [
		files [file! block!]							;-- source file or block of source files
		/options
			opts [object!]
		/loaded 										;-- source code is already in LOADed format
			src	[block!]
		/local
			comp-time link-time err
	][
		comp-time: dt [
			unless block? files [files: reduce [files]]
			
			unless opts [opts: make options-class []]
			job: make-job opts last files				;-- last input filename is retained for output name
			emitter/init opts/link? job
			if opts/verbosity >= 10 [set-verbose-level opts/verbosity]
			
			clean-up
			loader/init
			
			unless opts/use-natives? [comp-start]		;-- init libC properly
			if opts/runtime? [comp-runtime-prolog]
			
			set-verbose-level opts/verbosity
			foreach file files [
				src: either loaded [
					loader/process/with src file
				][
					loader/process file
				]
				compiler/run job src file
			]
			set-verbose-level 0
			if opts/runtime? [comp-runtime-epilog]
			
			set-verbose-level opts/verbosity
			compiler/finalize							;-- compile all functions
			set-verbose-level 0
		]
		if verbose >= 5 [
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
		
		set-verbose-level opts/verbosity
		output-logs
		if opts/link? [clean-up]

		reduce [comp-time link-time any [all [job/buffer length? job/buffer] 0]]
	]
]
