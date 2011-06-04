REBOL [
	Title:   "Red/System compiler"
	Author:  "Nenad Rakocevic"
	File: 	 %compiler.r
	Rights:  "Copyright (C) 2011 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/dockimbel/Red/blob/master/BSD-3-License.txt"
]

do %linker.r
do %emitter.r

system-dialect: context [
	verbose:  0									;-- logs verbosity level
	job: none									;-- reference the current job object	
	runtime-env: none							;-- hold OS-specific Red/System runtime
	runtime-path: %runtime/
	nl: newline
	
	;errors: [
	;	type	["message" arg1 "and" arg2]
	;]
	
	loader: context [
		verbose: 0
		include-dirs: none
		include-list: make hash! 20
		defs: make block! 100
		
		hex-chars: charset "0123456789ABCDEF"
		
		init: does [
			include-dirs: copy [%runtime/]
			clear include-list
			clear defs
			insert defs <no-match>				;-- required to avoid empty rule (causes infinite loop)
		]
		
		included?: func [file [file!]][
			file: get-modes file 'full-path
			either find include-list file [true][
				append include-list file
				false
			]
		]
		
		find-path: func [file [file!]][
			either slash = first file [
				if exists? file [return file] 		;-- absolute path check
			][
				foreach dir include-dirs [			;-- relative path check using known directories
					if exists? dir/:file [return dir/:file]
				]
			]
			make error! reform ["Include File Access Error:" file]
		]
		
		expand-string: func [src [string! binary!] /local value s e][
			if verbose > 0 [print "running string preprocessor..."]
			
			parse/all/case src [						;-- not-LOAD-able syntax support
				any [
					s: copy value 1 8 hex-chars #"h" e: (		;-- literal hexadecimal support
						e: change/part s to integer! to issue! value e
					) :e
					| skip
				]
			]
		]
		
		expand-block: func [src [block!] /local blk rule name value s e][		
			if verbose > 0 [print "running block preprocessor..."]			
			parse/case src blk: [
				some [
					defs								;-- resolve definitions in a single pass
					| #define set name word! set value skip (
						if verbose > 0 [print [mold name #":" mold value]]
						if word? value [value: to lit-word! value]
						rule: copy/deep [s: _ e: (e: change/part s _ e) :e]
						rule/2: to lit-word! name
						rule/4/4: :value						
						either tag? defs/1 [remove defs][append defs '|]						
						append defs rule
					)
					| s: #include set name file! e: (
						either included? name: find-path name [
							s: skip s 2					;-- already included, skip it
						][
							if verbose > 0 [print ["...including file:" mold name]]
							value: skip process/short name 2			;-- skip Red/System header						
							e: skip change/part s value e 2
							insert s reduce [#script name]				;-- mark code origin
							insert e reduce [#script compiler/script]	;-- put back the parent origin
						]
					) :s
					| into blk
					| skip
				]
			]
		]
		
		process: func [input [file! string!] /short /local src err path][
			if verbose > 0 [print ["processing" mold either file? input [input]['runtime]]]
			
			if file? input [
				if all [
					%./ <> path: first split-path input	;-- is there a path in the filename?
					not find include-dirs path
				][
					append include-dirs path			;-- register source's dir as include dir
				]
				if error? set/any 'err try [src: as-string read/binary input][	;-- read source file
					print ["File Access Error:" mold disarm err]
				]
			]
			either file? input [
				unless short [compiler/script: input]
			][
				compiler/script: 'memory
			]
			expand-string src: any [src input]			;-- process string-level compiler directives
			
			;TBD: add Red/System header checking here!
			
			if error? set/any 'err try [src: load src][	;-- convert source to blocks
				print ["Syntax Error at LOAD phase:" mold disarm err]
			]
			
			unless short [expand-block src]				;-- process block-level compiler directives		
			src
		]
	]
	
	compiler: context [
		job: 		 none								;-- compilation job object
		pc:			 none								;-- source code input cursor
		script:		 none								;-- source script file name
		last-type:	 none								;-- type of last value from an expression
		locals: 	 none								;-- currently compiled function specification block
		locals-init: []									;-- currently compiler function locals variable init list
		func-name:	 none								;-- currently compiled function name
		verbose:  	 0									;-- logs verbosity level
	
		imports: 	   make block! 10					;-- list of imported functions
		bodies:	  	   make hash!  40					;-- list of functions to compile [name [specs] [body]...]
		globals:  	   make hash!  40					;-- list of globally defined symbols from scripts
		aliased-types: make hash!  10					;-- list of aliased type definitions
		
		pos:		none								;-- validation rules cursor for error reporting
		return-def: to-set-word 'return					;-- return: keyword
		fail:		[end skip]							;-- fail rule
		rule: w:	none								;-- global parsing rules helpers
		
		not-set!:	[logic! integer!]									;-- reserved for internal use only
		number!: 	[byte! integer!]									;-- reserved for internal use only
		poly!:		[byte! integer! pointer! struct! c-string!]			;-- reserved for internal use only
		any-type!:	[byte! integer! pointer! struct! c-string! logic!]	;-- reserved for internal use only
		type-sets:	[not-set! number! poly! any-type!]					;-- reserved for internal use only
		
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
			;>>		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- shift left
			;<<		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- shift right
			=		[2	op		- [a [any-type!] b [any-type!]  return: [logic!]]]
			<>		[2	op		- [a [any-type!] b [any-type!]  return: [logic!]]]
			>		[2	op		- [a [poly!]   b [poly!]   return: [logic!]]]
			<		[2	op		- [a [poly!]   b [poly!]   return: [logic!]]]
			>=		[2	op		- [a [poly!]   b [poly!]   return: [logic!]]]
			<=		[2	op		- [a [poly!]   b [poly!]   return: [logic!]]]
			not		[1	inline	- [a [not-set!] 		   return: [logic!]]]	;@@ return should be not-set!
			size?	[1  inline  - [value [any-type!] 	   return: [integer!]]]
		]
		
		user-functions: tail functions	;-- marker for user functions
		
		action-class: context [action: type: data: none]
		
		struct-syntax: [
			pos: opt [into ['align integer! opt ['big | 'little]]]	;-- struct's attributes
			pos: any [word! into type-spec]							;-- struct's members
		]
		
		pointer-syntax: ['integer!]
		
		type-syntax: [
			'logic! | 'int32! | 'integer! | 'uint8! | 'byte!
			| 'c-string!
			| 'pointer! into [pointer-syntax]
			| 'struct!  into [struct-syntax]
		]

		type-spec: [
			pos: some type-syntax | set w word! (		;-- multiple types allowed for internal usage			
				unless find aliased-types w [			;-- make the rule fail if not found
					throw-error ["invalid struct syntax:" mold pos]
				]	
			)
		]		
		
		keywords: [
			;&			 []
			as			 [comp-as]
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
			struct 		 [comp-struct]
			pointer 	 [comp-pointer]
		]
		
		throw-error: func [err [word! string! block!]][
			print [
				"*** Compilation Error:"
				either word? err [
					join uppercase/part mold err 1 " error"
				][reform err]
				"^/*** in file:" mold script
				either locals [join "^/*** in function: " func-name][""]
				"^/*** at: " mold copy/part pc 8
			]
			clean-up
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
		
		backtrack: func [value /local res][
			pc: any [res: find/only/reverse pc value pc]
			to logic! res
		]
		
		blockify: func [value][either block? value [value][reduce [value]]]

		literal?: func [value][
			not any [word? value path? value value = <last>]
		]
		
		not-initialized?: func [name [word!] /local pos][
			all [
				locals
				pos: find locals /local
				pos: find pos name
				not find locals-init name
			]
		]
		
		base-type?: func [value][
			if block? value [value: value/1]
			to logic! find emitter/datatypes value
		]
		
		encode-cond-test: func [value [logic!]][
			pick [<true> <false>] value
		]
		
		decode-cond-test: func [value [tag!]][
			select [<true> #[true] <false> #[false]] value
		]
		
		get-return-type: func [name [word!] /local type][
			type: select functions/:name/4 return-def
			unless type [
				backtrack name
				throw-error ["return type missing in function:" name]
			]
			type/1
		]
		
		set-last-type: func [spec [block!]][
			if spec: select spec return-def [last-type: spec/1]
		]
		
		get-variable-spec: func [name [word!]][
			any [
				all [locals select locals name]
				select globals name
			]
		]
		
		resolve-aliased: func [type [word! block!] /local name][
			name: either block? type [type/1][type]
			all [
				not base-type? name
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
				return [function!]
			]
			unless base-type? type/1 [
				type: select aliased-types type/1
			]
			type
		]
		
		resolve-path-type: func [path [path! set-path!] /parent prev /local type][
			type: either parent [
				resolve-type/with path/1 prev
			][
				resolve-type path/1
			]
			either tail? skip path 2 [
				switch/default type/1 [
					c-string! ['byte!]
					pointer!  [
						check-pointer-path path
						type/2/1						;-- return pointed value type
					]
					struct!   [
						either type: select type/2 path/2 [
							type/1
						][
							backtrack path
							throw-error [
								"invalid struct member" path/2 "in" mold path
							]
						]
					]
				][
					backtrack path
					throw-error "invalid path value"
				]
			][
				resolve-path-type/parent next path second type
			]
		]
		
		get-mapped-type: func [value][
			case [
				value = <last>  [last-type]
				tag?    value	['logic!]
				logic?  value	['logic!]
				word?   value 	[resolve-type value]
				char?   value	['byte!]
				string? value	['c-string!]
				path?   value	[resolve-path-type value]
				block?  value	[
					either object? value/1 [
						;get-mapped-type value/2		;@@
						value/1/type
					][
						get-return-type value/1
					]
				]
				paren?  value	[
					reduce either all [value/1 = 'struct word? value/2][
						[value/2]
					][
						[to word! join value/1 #"!" value/2]
					]
				]
				'else 			[type?/word value]		;@@ should throw an error?
			]	
		]
		
		argument-type?: func [arg /local type][
			switch/default type?/word arg [
				char!	 ['byte!]
				integer! ['integer!]
				logic!   ['logic!]
				word!	 [first resolve-type arg]
				block!	 [
					case [
						object? arg/1 [arg/1/type]
						'op = second select functions arg/1 [
							either base-type? type: get-return-type arg/1 [
								type					;-- unique returned type, stop here
							][
								argument-type? arg/2	;-- recursively search for an atomic left operand
							]
						]
						'else [get-return-type arg/1]
					]
				]
				tag!	 [either word? last-type [last-type][last-type/1]]
				path!	 [resolve-path-type arg]
			][
				throw-error ["Undefined type for:" mold arg]
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
				spec: select functions expr/1 		;-- works for unary & binary functions only!
			]
			type: case [
				all [block? expr object? expr/1][
					expr/1/type						 ;-- type casting case
				]
				all [func? find [op inline] spec/2][ ;-- works for unary & binary functions only!
					argument-type? expr/2			;-- recursively search for return type
				]
				all [func? quiet][
					select spec/4 return-def		;-- workaround error throwing in get-return-value
				]
				'else [get-mapped-type expr]
			]
			blockify type 							;-- normalize type spec
		]
		
		cast: func [ctype [word! block!] value /local type][
			type: blockify get-mapped-type value
			ctype: blockify ctype

			if type/1 = ctype/1 [
				throw-warning/at [
					"type casting from" type/1 
					"to" ctype/1 "is not necessary"
				] 'as
			]
			if any [
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
		
		init-local: func [name [word!] expr [block!] casted [block! none!] /local pos type][	
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
			unless type [type: get-mapped-type value]
			append globals reduce [name type: compose [(type)]]
			type
		]
		
		add-function: func [type [word!] spec [block!] cc [word!] /local name arity][		
			if find functions name: to word! spec/1 [
				;TBD: symbol already defined
			]
			;TBD: check spec syntax (here or somewhere else)
			arity: 0
			parse spec/3 [opt block! any [word! block! (arity: arity + 1)]]
			repend functions [
				name reduce [arity type cc new-line/all spec/3 off]
			]
		]
		
		check-pointer-path: func [path [path! set-path!] /local ending][
			ending: path/2
			unless any [
				integer? ending
				all [word? ending get-variable-spec ending]
				ending = 'value
			][
				backtrack path
				throw-error "invalid pointer path ending"
			]
		]
		
		check-specs: func [name specs /local type spec-type attribs value][
			unless block? specs [throw-error 'syntax]
			attribs: ['infix | 'callback]

			unless parse specs [
				pos: opt [into [some attribs]]			;-- functions attributes
				pos: any [pos: word! into type-spec]	;-- arguments definition
				pos: opt [								;-- return type definition				
					set value set-word! (					
						rule: pick reduce [[into type-spec] fail] value = return-def
					) rule
				]
				pos: opt [/local some [pos: word! opt [into type-spec]]] ;-- local variables definition
			][			
				throw-error rejoin ["invalid definition for function " name ": " mold pos]
			]		
		]
		
		check-expected-type: func [name [word!] expr expected [block!] /ret /key /local type alias][
			unless any [not none? expr key][return none]			;-- expr == none for special keywords
			
			if all [
				not none? expr							;-- expr can be false, so explicit check for none is required
				first type: resolve-expr-type expr
			][											;-- check if a type is returned or none
				type: blockify resolve-aliased type
				if alias: select aliased-types expected/1 [expected: alias]
			]
			unless any [
				all [
					type
					find type-sets expected
					find expected: get expected/1 type/1 ;-- internal polymorphic case
				]
				expected = type 						 ;-- normal mono-type case
			][
				any [
					backtrack any [all [block? expr expr/1] expr]
					backtrack name
				]
				throw-error [
					reform case [
						ret   [["wrong return type in function:" name]]
						key   [[uppercase form name "requires a conditional expression"]]
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
				list/1/1 <> list/2/1				;-- allow implicit casting for math ops only
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
					all [list/1/1 = 'byte! find [c-string! pointer! struct!] list/2/1]
					all [list/2/1 = 'byte! find [c-string! pointer! struct!] list/1/1]
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
		
		check-body: func [body][
			case/all [
				not block? :body [throw-error 'syntax 'block-expected]
				empty? body  	 [throw-error 'syntax 'empty-block]
			]
		]
		
		fetch-into: func [code [block! paren!] body [block!] /local save-pc][		;-- compile sub-block
			save-pc: pc
			pc: code
			do body
			pc: next save-pc						;-- skip over body block (a bit ugly, to be improved)
		]
		
		fetch-func: func [name /local specs type cc][
			;check if name is word and taken
			check-specs name pc/2
			specs: pc/2
			type: 'native
			cc:   'stdcall							;-- default calling convention
			
			if all [
				not empty? specs
				block? specs/1
			][
				case [
					find specs/1 'infix [
						;TBD: check for two arguments presence
						specs: next specs
						type: 'infix
					]
					find specs/1 'callback [
						cc: 'cdecl					;TBD: make it configurable
					]
					; add future attributes processing code here
				]
			]
			add-function type reduce [name none specs] cc
			emitter/add-native to word! name
			repend bodies [to word! name specs pc/3 script]
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
					][
						expr: expr/1					;-- remove outer brackets if variable
					]
					expr
				]
			]
			expr
		]
				
		comp-directive: has [list reloc][
			switch/default pc/1 [
				#import [
					unless block? pc/2 [
						;TBD: syntax error
					]
					foreach [lib cc specs] pc/2 [		;-- cc = calling convention
						;TBD: check lib/specs validity
						unless list: select imports lib [
							repend imports [lib list: make block! 10]
						]
						forskip specs 3 [
							repend list [specs/2 reloc: make block! 1]
							add-function 'import specs cc
							emitter/import-function to word! specs/1 reloc
						]						
					]				
					pc: skip pc 2
				]
				#syscall [
					unless block? pc/2 [
						;TBD: syntax error
					]
					foreach [name code specs] pc/2 [
						;TBD: check call/code/specs validity
						add-function 'syscall reduce [name none specs] 'syscall
						append last functions code		;-- extend definition with syscode
						;emitter/import-function to word! specs/1 reloc
					]				
					pc: skip pc 2
				]
				#define  [pc: skip pc 3]				;-- preprocessed before
				#include [pc: skip pc 2]				;-- preprocessed before
				#script	 [								;-- internal compiler directive
					compiler/script: pc/2				;-- set the origin of following code
					pc: skip pc 2
				]
			][
				;TBD: unknown directive error
			]
		]
		
		comp-reference-literal: has [value][
			value: to paren! reduce [pc/1 pc/2]
			unless find [set-word! set-path!] type?/word pc/-1 [
				throw-error "assignment expected for struct value"
			]
			pc: skip pc 2
			value
		]
		
		comp-struct: does [
			either word? pc/2 [
				resolve-aliased pc/2					;-- just check if alias is defined
			][
				unless parse pos: pc/2 struct-syntax [
					throw-error ["invalid struct syntax:" mold pos]
				]
			]
			comp-reference-literal
		]
		
		comp-pointer: does [
			unless parse pos: pc/2 pointer-syntax [
				throw-error ["invalid pointer syntax:" mold pos]
			]
			comp-reference-literal
		]
		
		comp-as: has [ctype][
			ctype: pc/2
			unless any [
				parse blockify ctype type-syntax
				find aliased-types ctype
			][
				throw-error ["invalid target type casting:" ctype]
			]
			pc: skip pc 2
			reduce [
				make action-class [
					action: 'type-cast
					type: blockify ctype
				]
				fetch-expression
			]
		]
		
		comp-alias: does [
			unless set-word? pc/-1 [
				throw-error "assignment expected for ALIAS"
			]
			unless pc/2 = 'struct! [
				throw-error "ALIAS only works on struct! type"
			]
			repend aliased-types [to word! pc/-1 reduce [pc/2 pc/3]]
			unless parse pos: pc/3 struct-syntax [
				throw-error ["invalid struct syntax:" mold pos]
			]
			pc: skip pc 3
			none
		]
		
		comp-size?: has [type value][
			pc: next pc
			value: pc/1
			if any [find [true false] value][
				value: do value
			]
			type: switch/default type?/word value [
				word!	  [resolve-type value]
				path!	  [resolve-path-type value]
				set-path! [resolve-path-type value]
			][
				get-mapped-type value
			]
			unless block? type [type: reduce [type]]
			
			emitter/get-size type value
			last-type: get-return-type 'size?
			pc: next pc
			<last>
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
				check-expected-type/key name expr [logic!]	;-- verify conditional expression
				expr: process-logic-encoding expr
			]
			reduce [
				expr 
				emitter/chunks/stop						;-- returns a chunk block!
			]
		]
		
		process-logic-encoding: func [expr][			;-- preprocess logic values
			switch/default type?/word expr [
				logic! [ [#[true]] ]
				word!  [
					emitter/target/emit-operation '= [<last> 0]
					[#[true]]
				]
				block! [
					either find comparison-op expr/1 [
						expr
					][
						process-logic-encoding expr/1
					]
				]
				tag! [either expr <> <last> [ [#[true]] ][expr]]
			][expr]
		]
		
		comp-if: has [expr unused chunk][		
			pc: next pc
			expr: fetch-expression/final				;-- compile expression
			check-expected-type/key 'if expr [logic!]	;-- verify conditional expression
			expr: process-logic-encoding expr
			check-body pc/1								;-- check TRUE block
	
			set [unused chunk] comp-block-chunked		;-- compile TRUE block
			emitter/set-signed-state expr				;-- properly set signed/unsigned state
			emitter/branch/over/on chunk expr/1			;-- insert IF branching			
			emitter/merge chunk
			last-type: none
			<last>
		]
		
		comp-either: has [expr e-true e-false c-true c-false offset type][
			pc: next pc
			expr: fetch-expression/final				;-- compile expression
			check-expected-type/key 'either expr [logic!]	;-- verify conditional expression
			expr: process-logic-encoding expr
			check-body pc/1								;-- check TRUE block
			check-body pc/2								;-- check FALSE block
			
			set [e-true c-true]  comp-block-chunked		;-- compile TRUE block		
			set [e-false c-false] comp-block-chunked	;-- compile FALSE block
		
			offset: emitter/branch/over c-false
			emitter/set-signed-state expr				;-- properly set signed/unsigned state	
			emitter/branch/over/adjust/on c-true negate offset expr/1	;-- skip over JMP-exit
			emitter/merge emitter/chunks/join c-true c-false

			type: resolve-expr-type/quiet e-true		
			last-type: either type = resolve-expr-type/quiet e-false [type][none] ;-- allow nesting if both blocks return same type
			<last>
		]
		
		comp-until: has [expr chunk][
			pc: next pc
			check-body pc/1
			set [expr chunk] comp-block-chunked/test 'until
			emitter/branch/back/on chunk expr/1	
			emitter/merge chunk	
			last-type: none
			<last>
		]
		
		comp-while: has [expr unused cond body  offset bodies][
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
			last-type: none
			<last>
		]
		
		comp-expression-list: func [/_all /local list offset bodies op][
			pc: next pc
			check-body pc/1								;-- check body block
			
			list: make block! 8
			fetch-into pc/1 [
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
			last-type: 'logic!
			encode-cond-test not _all					;-- special encoding
		]
		
		comp-assignment: has [name value][
			name: pc/1
			pc: next pc
			either none? value: fetch-expression [		;-- explicitly test for none!
				none
			][				
				new-line/all reduce [name value] no
			]
		]
		
		comp-get-word: has [name spec][
			either all [
				spec: select functions name: to word! pc/1
				spec/2 = 'native
			][
				emitter/target/emit-get-address name
				pc: next pc
				last-type: 'integer!
				<last>
			][
				throw-error "get-word syntax only reserved for native functions for now"
			]
		]
	
		comp-word: has [entry args n name expr][
			name: pc/1
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
				
				entry: find functions name [
					pc: next pc							;-- it's a function		
					args: make block! n: entry/2/1
					loop n [append/only args fetch-expression]	;-- fetch n arguments
					head insert args name
				]
				'else [throw-error ["undefined symbol:" mold name]]
			]
		]
		
		comp-expression: func [
			tree [block!] /keep
			/local name value data offset body args prepare-value type casted
		][
			prepare-value: [		
				if all [block? tree/2 object? tree/2/1][
					casted: tree/2/1/type				;-- save casting type
					if all [block? tree/2/2 object? tree/2/2/1][
						raise-casting-error
					]
					tree/2: cast casted tree/2/2		;-- remove encoding object
				]
				value: either block? tree/2 [
					get-return-type tree/2/1			;-- check that function is returning a value
					comp-expression/keep tree/2			;-- function call case
					<last>
				][
					tree/2
				]
				either all [tag? value value <> <last>][	;-- special encoding for ALL/ANY
					data: true
					value: <last>
				][
					data: value
				]
				if path? value [
					emitter/access-path value none
					value: <last>
				]
			]
			switch/default type?/word tree/1 [
				set-word! [								;-- variable assignment --
					name: to word! tree/1
					do prepare-value
					if not-initialized? name [
						init-local name tree casted		;-- mark as initialized and infer type if required
					]
					either type: get-variable-spec name [  ;-- test if known variable (local or global)
						if all [casted type <> casted][
							backtrack tree/1
							throw-error [
								"attempt to change type of variable:" name
							]
						]
					][
						type: add-symbol name data casted  ;-- if unknown add it to global context
					]
					if none? type/1 [
						backtrack tree/1
						throw-error ["unable to determine a type for:" name]
					]
					emitter/store name value type
				]
				set-path! [								;-- path assignment --
					do prepare-value
					resolve-path-type tree/1			;-- check path validity
					;TBD: raise error if ANY/ALL passed as argument				
					emitter/access-path tree/1 value
				]
				object! [								;-- special actions @@
					switch tree/1/action [
						type-cast [						;-- apply type casting
							do prepare-value
							last-type: tree/1/type
						]
						;-- add more special actions here
					]
				]
			][											;-- function call --
				name: to word! tree/1
				args: next tree
				if all [tag? args/1 args/1 <> <last>][	;-- special encoding for ALL/ANY
					if 1 < length? args [
						throw-error [
							"function" name
							"requires only one argument when passing ANY/ALL expression"
						]
					]									
					args/1: <last>
				]
				
				type: emitter/call name args
				if type [last-type: type]
				
				if all [keep last-type = 'logic!][
					emitter/logic-to-integer name		;-- runtime logic! conversion before storing @@
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
			expr: switch/default type?/word pc/1 [
				set-word!	[comp-assignment]
				word!		[comp-word]
				get-word!	[comp-get-word]
				path! 		[do pass]
				set-path!	[comp-assignment]
				paren!		[comp-block]
				char!		[do pass]
				integer!	[do pass]
				string!		[do pass]
				block!		[do pass]					;-- struct! and pointer! specs
			][
				throw-error [
					pick [
						"compiler directive are not allowed in code blocks"
						"datatype not allowed"
					] issue? pc/1
				]
			]
			expr: reduce-logic-tests expr
			if final [
				if verbose >= 3 [?? expr]
				case [
					block? expr [
						either keep [
							comp-expression/keep expr
						][
							comp-expression expr
						]
					]
					not find [none! tag! object!] type?/word expr [
						emitter/target/emit-load expr
					]
				]
			]
			expr
		]
		
		comp-block: func [/final /local expr][
			fetch-into pc/1 [
				while [not tail? pc][
					either pc/1 = 'comment [pc: skip pc 2][
						expr: either final [
							fetch-expression/final
						][
							fetch-expression
						]
					]
				]
			]
			expr
		]
		
		comp-dialect: has [expr][
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
					pc/1 = 'comment [pc: skip pc 2]
					'else [expr: fetch-expression/final]
				]
			]
			expr
		]
		
		comp-func-body: func [name [word!] spec [block!] body [block!] /local args-size expr ret][
			locals: spec
			func-name: name
			args-size: emitter/enter name locals		;-- build function prolog
			pc: body
			
			expr: comp-dialect							;-- compile function's body
			
			if ret: select spec return-def [
				check-expected-type/ret name expr ret	;-- validate return value type
			]
			emitter/leave name locals args-size			;-- build function epilog
			clear locals-init
			locals: func-name: none
		]
		
		comp-natives: does [
			if verbose >= 2 [print "^/---^/Compiling native functions^/---"]
			foreach [name spec body origin] bodies [
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
			if verbose >= 2 [print ""]
			emitter/reloc-native-calls
		]
		
		comp-header: does [
			unless pc/1 = 'RED/System [
				;TBD: syntax error
			]
			unless block? pc/2 [
				;TBD: syntax error
			]
			pc: skip pc 2
		]

		run: func [src [block!] /no-header][
			pc: src
			unless no-header [comp-header]
			comp-dialect
		]
		
		finalize: does [
			comp-natives
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
	
	comp-runtime: func [type [word!]][
		compiler/script: type
		compiler/run/no-header loader/process runtime-env/:type
	]
	
	set-runtime: func [job [object!]][
		runtime-env: load switch job/format [
			PE     [runtime-path/win32.r]
			ELF    [runtime-path/linux.r]
			;Mach-o [runtime-path/posix.r]
		]
	]
	
	clean-up: does [
		clear compiler/imports
		clear compiler/bodies
		clear compiler/globals
		clear compiler/aliased-types
		clear compiler/user-functions
	]
	
	make-job: func [opts [object!] file [file!] /local job][
		file: last split-path file						;-- remove path
		file: to-file first parse file "."				;-- remove extension
		
		job: construct/with third opts linker/job-class	
		job/output: file
		job
	]
	
	dt: func [code [block!] /local t0][
		t0: now/time/precise
		do code
		now/time/precise - t0
	]
	
	options-class: context [
		link?: 		no					;-- yes = invoke the linker and finalize the job
		build-dir:	%builds/			;-- where to place compile/link results
		format:		select [			;-- file format
						3	'PE				;-- Windows
						4	'ELF			;-- Linux
						5	'Mach-o			;-- Mac OS X
					] system/version/4
		type:		'exe				;-- file type ('exe | 'dll | 'lib | 'obj)
		target:		'IA32				;-- CPU target
		verbosity:	0					;-- logs verbosity level
		sub-system:	'console			;-- 'GUI | 'console
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
			emitter/init opts/link? job: make-job opts last files	;-- last file's name is retained for output
			compiler/job: job
			set-runtime job
			set-verbose-level opts/verbosity
			
			loader/init
			comp-runtime 'prolog
			
			foreach file files [compiler/run loader/process file]
			
			comp-runtime 'epilog
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
				job/sections: compose/deep [
					code   [- 	(emitter/code-buf)]
					data   [- 	(emitter/data-buf)]
					import [- - (compiler/imports)]
				]
				linker/build/in job opts/build-dir
			]
		]
		output-logs
		if opts/link? [clean-up]

		also
			reduce [comp-time link-time any [all [job/buffer length? job/buffer] 0]]
			compiler/job: job: none
	]
]