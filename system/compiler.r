REBOL [
	Title:   "Red/System compiler"
	Author:  "Nenad Rakocevic"
	File: 	 %compiler.r
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

do-cache %system/utils/profiler.r
profiler/active?: no

do-cache %system/utils/r2-forward.r
do-cache %system/utils/int-to-bin.r
do-cache %system/utils/IEEE-754.r
do-cache %system/utils/virtual-struct.r
do-cache %system/utils/secure-clean-path.r
do-cache %system/utils/unicode.r
do-cache %system/linker.r
do-cache %system/emitter.r
do-cache %system/utils/libRedRT.r

system-dialect: make-profilable context [
	verbose:  	  0										;-- logs verbosity level
	job: 		  none									;-- reference the current job object	
	runtime-path: pick [%system/runtime/ %runtime/] encap?
	nl: 		  newline
	
	loader: do bind load-cache %system/loader.r 'self
	
	options-class: context [
		config-name:		none						;-- Preconfigured compilation target ID
		OS:					none						;-- Operating System
		OS-version:			0							;-- OS version
		ABI:				none						;-- optional ABI flags (word! or block!)
		link?:				no							;-- yes = invoke the linker and finalize the job
		debug?:				no							;-- reserved for future use
		build-prefix:		%builds/					;-- prefix to use for output file name (none: no prefix)
		build-basename:		none						;-- base name to use for output file name (none: derive from input name)
		build-suffix:		none						;-- suffix to use for output file name (none: derive from output type)
		format:				none						;-- file format
		type:				'exe						;-- file type ('exe | 'dll | 'lib | 'obj | 'drv)
		target:				'IA-32						;-- CPU target
		cpu-version:		6.0							;-- CPU version (default: Pentium Pro)
		verbosity:			0							;-- logs verbosity level
		sub-system:			'console					;-- 'GUI | 'console
		runtime?:			yes							;-- include Red/System runtime
		use-natives?:		no							;-- force use of native functions instead of C bindings
		debug?:				no							;-- emit debug information into binary
		debug-safe?:		yes							;-- try to avoid over-crashing on runtime debug reports
		dev-mode?:		 	none						;-- yes => turn on developer mode (pre-build runtime, default), no => build a single binary
		need-main?:			no							;-- yes => emit a function prolog/epilog around global code
		PIC?:				no							;-- generate Position Independent Code
		base-address:		none						;-- base image memory address
		dynamic-linker: 	none						;-- ELF dynamic linker ("interpreter")
		syscall:			'Linux						;-- syscalls convention: 'Linux | 'BSD
		export-ABI:			none						;-- force a calling convention for exports
		stack-align-16?:	no							;-- yes => align stack to 16 bytes
		literal-pool?:		no							;-- yes => use pools to store literals, no => store them inlined (default: no)
		unicode?:			no							;-- yes => use Red Unicode API for printing on screen
		red-pass?:			no							;-- yes => Red compiler was invoked
		red-only?:			no							;-- yes => stop compilation at Red/System level and display output
		red-store-bodies?:	yes							;-- no => do not store function! value bodies (body-of will return none)
		red-strict-check?:	yes							;-- no => defers undefined word errors reporting at run-time
		red-tracing?:		yes							;-- no => do not compile tracing code
		red-help?:			no							;-- yes => keep doc-strings from boot.red
		legacy:				none						;-- block of optional OS legacy features flags
		gui-console?:		no							;-- yes => redirect printing to gui console (temporary)
		libRed?: 			no
		libRedRT?: 			no
		libRedRT-update?:	no
		modules:			none
		show:				none
		command-line:		none
	]
	
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
		loop-stack:		 make block! 1					;-- keep track of in-loop state
		locals-init: 	 []								;-- currently compiler function locals variable init list
		func-name:	 	 none							;-- currently compiled function name
		func-locals-sz:	 none							;-- currently compiled function locals size on stack
		user-code?:		 no
		block-level: 	 0								;-- nesting level of input source block
		catch-level:	 0								;-- nesting level of CATCH body block
		verbose:  	 	 0								;-- logs verbosity level
	
		imports: 	   	 make block! 10					;-- list of imported functions
		exports: 	   	 make block! 10					;-- list of exported symbols
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
		shift-right-sym: to word! ">>>"					;-- workaround REBOL LOAD limitation
		less-or-equal:	 to word! "<="					;-- workaround REBOL LOAD limitation
		greater-than:	 to word! ">"					;-- workaround REBOL LOAD limitation
		
		debug-lines: reduce [							;-- runtime source line/file information storage
			'records make block!  1000					;-- [address line file] records
			'files	 make hash!   20					;-- filenames table
		]
		
		pos:		none								;-- validation rules cursor for error reporting
		return-def: to-set-word 'return					;-- return: keyword
		fail:		[end skip]							;-- fail rule
		rule: value: v: none							;-- global parsing rules helpers
		
		number!: 	  [byte! integer!]					;-- reserved for internal use only
		bit-set!: 	  [byte! integer! logic!]			;-- reserved for internal use only
		any-float!:	  [float! float32! float64!]		;-- reserved for internal use only
		any-number!:  union number! any-float!			;-- reserved for internal use only
		pointers!:	  [pointer! struct! c-string!] 		;-- reserved for internal use only
		any-pointer!: union pointers! [function!]		;-- reserved for internal use only
		poly!:		  union any-number! pointers!		;-- reserved for internal use only
		any-type!:	  union poly! [logic!]			  	;-- reserved for internal use only
		type-sets:	  [									;-- reserved for internal use only
			number! poly! any-type! any-pointer!
			any-number! bit-set!
		]
		
		comparison-op: [= <> < > <= >=]
		
		functions: to-hash compose [
		;--Name--Arity--Type----Cc--Specs--		   Cc = Calling convention
			+		[2	op		- [a [poly!]   b [poly!]   return: [poly!]]]
			-		[2	op		- [a [poly!]   b [poly!]   return: [poly!]]]
			*		[2	op		- [a [any-number!] b [any-number!] return: [any-number!]]]
			/		[2	op		- [a [any-number!] b [any-number!] return: [any-number!]]]
			and		[2	op		- [a [bit-set!] b [bit-set!] return: [bit-set!]]]
			or		[2	op		- [a [bit-set!] b [bit-set!] return: [bit-set!]]]
			xor		[2	op		- [a [bit-set!] b [bit-set!] return: [bit-set!]]]
			//		[2	op		- [a [any-number!] b [any-number!] return: [any-number!]]]		;-- modulo
      (to-word "%")	[2	op		- [a [any-number!] b [any-number!] return: [any-number!]]]		;-- remainder (real syntax: %)
			>>		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- shift right signed
			<<		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- shift left signed
			-**		[2	op		- [a [number!] b [number!] return: [number!]]]		;-- shift right unsigned
			=		[2	op		- [a [any-type!] b [any-type!]  return: [logic!]]]
			<>		[2	op		- [a [any-type!] b [any-type!]  return: [logic!]]]
			>		[2	op		- [a [any-type!] b [any-type!]  return: [logic!]]]
			<		[2	op		- [a [any-type!] b [any-type!]  return: [logic!]]]
			>=		[2	op		- [a [any-type!] b [any-type!]  return: [logic!]]]
			<=		[2	op		- [a [any-type!] b [any-type!]  return: [logic!]]]
			not		[1	inline	- [a [bit-set!] 		   return: [bit-set!]]]
			push	[1	inline	- [a [any-type!]]]
			pop		[0	inline	- [						   return: [integer!]]]
			throw	[1	inline	- [n [integer!]]]
			log-b	[1	native	- [n [number!] return: [integer!]]]
		]
		
		repend functions [shift-right-sym copy functions/-**]
		
		user-functions: tail functions					;-- marker for user functions
		
		action-class: context [action: type: data: none]
		
		struct-syntax: [
			pos: opt [into ['align integer! opt ['big | 'little]]]	;-- struct's attributes
			pos: some [word! into [func-pointer | type-spec]]		;-- struct's members
		]
		
		pointer-syntax: ['integer! | 'byte! | 'float32! | 'float64! | 'float!]
		
		func-pointer: ['function! set value block! (check-specs '- value)]
		
		type-syntax: [
			'logic! | 'integer! | 'byte! | 'int16!		;-- int16! needed for AVR8 backend
			| 'float! | 'float32! | 'float64!
			| 'c-string!
			| 'pointer! into [pointer-syntax]
			| 'struct!  into [struct-syntax] opt 'value
		]

		type-spec: [
			pos: some type-syntax | pos: set value word! (	;-- multiple types allowed for internal usage		
				unless any [
					all [v: find-aliased/prefix value v <> value find aliased-types v pos/1: v]			;-- rewrite the type to prefix it
					find aliased-types value
					all [v: resolve-ns value v <> value enum-type? v pos/1: v]	;-- rewrite the type to prefix it
					all [enum-type? value pos/1: 'integer!]
				][throw false]							;-- stop parsing if unresolved type			
			) opt 'value
		]		
		
		keywords: make hash! [
			;&			 [throw-error "reserved for future use"]
			?? 			 [comp-print-debug]
			as			 [comp-as]
			assert		 [comp-assert]
			size? 		 [comp-size?]
			if			 [comp-if]
			either		 [comp-either]
			case		 [comp-case]
			switch		 [comp-switch]
			until		 [comp-until]
			while		 [comp-while]
			loop		 [comp-loop]
			any			 [comp-expression-list]
			all			 [comp-expression-list/_all]
			exit		 [comp-exit]
			return		 [comp-exit/value]
			break		 [comp-break]
			continue	 [comp-continue]
			catch		 [comp-catch]
			declare		 [comp-declare]
			use			 [comp-use]
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
		
		calling-keywords: [								;-- keywords accepted in expr-call-stack
			?? as assert size? if either case switch until while any all
			return catch
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
		
		;raise-paren-error: does [
		;	pc: back pc
		;	throw-error "parens are only allowed nested in an expression"
		;]
		
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
		
		get-type-id: func [value /direct /local type alias][
			either direct [type: value][
				with-alias-resolution off [type: resolve-expr-type value]
			]
			
			either alias: find-aliased/position type/1 [
				get-alias-id alias
			][
				type: any [resolve-aliased/silent type [integer!]]
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
				]
			]
			none
		]
		
		system-action?: func [path [path!] /local expr][
			if path/1 = 'system [
				switch/default path/2 [
					stack [
						switch/default path/3 [
							allocate [
								pc: next pc
								fetch-expression/final/keep 'stack-alloc
								if any [none? last-type last-type/1 <> 'integer!][
									throw-error "system/stack/allocate expects an integer! argument"
								]
								emitter/target/emit-alloc-stack
								emitter/target/emit-get-stack
								last-type: [pointer! [integer!]]
								true
							]
							free [
								pc: next pc
								fetch-expression/final/keep 'stack-free
								if any [none? last-type last-type/1 <> 'integer!][
									throw-error "system/stack/free expects an integer! argument"
								]
								emitter/target/emit-free-stack
								true
							]
							;push []
							;pop  []
						][false]
					]
				][false]
			]
		]
		
		base-type?: func [value][
			if block? value [value: value/1]
			to logic! find/skip emitter/datatypes value 3
		]
		
		unbox: func [value][
			either object? value [value/data][value]
		]
		
		clear-docstrings: func [spec [block!]][
			remove-each s spec [string? s]
			spec
		]
		
		get-return-type: func [name [word!] /check /local type spec][
			unless all [
				spec: find-functions name
				any [
					type: select spec/2/4 return-def
					check
				]
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
		
		catch-attribut?: does [
			all [locals block? locals/1 find locals/1 'catch]
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
		
		get-args-array: func [name [word!] /local count array spec][ ;-- used by linker for debug info
			count: 0
			array: clear #{}							;-- re-use buffer
			
			parse functions/:name/4 [
				opt block!
				any [
					word!
					spec: block! (
						count: count + 1
						id: get-type-id/direct spec/1
						if id >= 1000 [id: 100]
						append array to char! id
					)
				]
			]
			reduce [count array]
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
		
		struct-by-value?: func [type [block!]][
			all [
				'value = last type
				any [
					'struct! = type/1
					'struct! = first find-aliased type/1
				]
			]
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
		
		resolve-aliased: func [type [block!] /silent /local name][
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
				any [
					all [silent return none]
					throw-error ["unknown type:" type]
				]
			]
			type
		]
		
		resolve-type: func [name /with parent /local type local? pos mark][
			if get-word? name [name: to word! name]
			
			type: any [
				all [parent select parent name]
				local?: all [locals select locals name]
				select-globals name
			]
			if all [not type pos: select functions decorate-fun name][
				if mark: find pos: pos/4 /local [
					pos: copy/part pos mark			;-- remove locals
				]
				return reduce ['function! pos]
			]
			if any [
				all [not local?	any [enum-type? name enum-id? name]]
				all [type enum-type? type/1]
			][
				return [integer!]
			]
			unless any [not resolve-alias? none? type base-type? type/1][
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
		
		resolve-path-type: func [path [path! set-path!] /parent prev /local type path-error p1][
			path-error: [
				pc: skip pc -2
				throw-error ["invalid path value:" mold path]
			]
			
			p1: to word! path/1
			either parent [
				resolve-struct-member-type prev p1	;-- just check for correct member name
				with-alias-resolution on [
					type: resolve-type/with p1 prev
				]
			][
				with-alias-resolution on [
					type: resolve-type p1
				]
			]

			all [
				get-word? path/1 word? path/2
				'function! <> first resolve-struct-member-type type/2 path/2
				return [pointer! [integer!]]			;-- struct member get-path! -> int-ptr!
			]
			
			unless type path-error
			
			either tail? skip path 2 [
				switch/default type/1 [
					struct!   [
						unless word? path/2 [
							backtrack path
							throw-error ["invalid struct member" path/2]
						]
						resolve-struct-member-type type/2 path/2
					]
					pointer!  [
						check-path-index path 'pointer
						reduce [type/2/1]				;-- return pointed value type
					]
					c-string! [
						check-path-index path 'string
						[byte!]
					]

				] path-error
			][
				resolve-path-type/parent next path second type
			]
		]
		
		get-type: func [value /local type][
			switch/default type?/word value [
				word! 	 [resolve-type value]
				integer! [[integer!]]
				path!	 [resolve-path-type value]
				block!	 [
					if value/1 = 'not [return get-type value/2]	;-- special case for NOT multitype native
					
					either 'op = second get-function-spec value/1 [
						either base-type? type: get-return-type/check value/1 [
							type						;-- unique returned type, stop here
						][
							get-type value/2			;-- recursively search for left operand base type
						]
					][
						get-return-type/check value/1
					]
				]
				object!  [value/type]
				tag!	 [either value = <last> [last-type][[logic!]]]
				string!	 [[c-string!]]
				get-word! [
					type: resolve-type to word! value
					
					switch/default type/1 [
						function! [type]
						integer! byte! float! float32! [compose/deep [pointer! [(type/1)]]]
					][
						with-alias-resolution off [
							type: resolve-type to word! value
						]
						either struct-by-value? type [
							type
						][
							throw-error ["invalid datatype for a get-word:" mold type]
						]
					]
				]
				logic!	 [[logic!]]
				char!	 [[byte!]]
				decimal! [[float!]]
				paren!	 [
					switch/default value/1 [
						struct!  [reduce pick [[value/2][value/1 value/2]] word? value/2]
						pointer! [reduce [value/1 value/2]]
					][
						next next reduce ['array! length? value	'pointer! get-type value/1]	;-- hide array size
					]
				]
				none!	 [none-type]					;-- no type case (func with no return value)

			][
				throw-error ["not accepted datatype:" type? value]
			]
		]
		
		enum-type?: func [name [word!] /local type][
			all [
				type: find/skip enumerations name 3		;-- SELECT/SKIP on hash! unreliable!
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
			if ns-path [
				add-ns-symbol to set-word! identifier
				identifier: ns-prefix identifier
			]
			
			if word? name [name: reduce [name]]
			forall name [
				store-ns-symbol name/1
				if ns-path [
					add-ns-symbol to set-word! name/1
					name/1: ns-prefix name/1
				]
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
			if value < 2147483647 [value: value + 1] ;-- avoid math overflow error
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
		
		check-throw: does [
			unless any [locals positive? catch-level][
				backtrack 'throw
				throw-error "THROW used without a wrapping CATCH"
			]
		]
		
		push-loop: func [type [word!]][append loop-stack type]
		
		pop-loop: does [remove back tail loop-stack]
		
		push-call: func [action [word! set-word! set-path!]][
			append/only expr-call-stack action
			if verbose >= 4 [
				new-line/all expr-call-stack off
				?? expr-call-stack
			]
		]
		
		pop-calls: does [clear expr-call-stack]
		
		count-outer-loops: has [n][
			n: 0
			parse loop-stack [any ['loop (n: n + 1) | skip]]
			n
		]
		
		cast: func [obj [object!] /quiet /local value ctype type][
			value: obj/data
			ctype: resolve-aliased obj/type
			type: get-type value

			if all [not quiet type = obj/type type/1 <> 'function!][
				throw-warning/near [
					"type casting from" type/1 
					"to" obj/type/1 "is not necessary"
				] 'as
			]
			if any [
				all [type/1 = 'function! not find [function! integer!] ctype/1]
				all [find [float! float64!] ctype/1 not any [any-float? type type/1 = 'integer!]]
				all [find [float! float64!] type/1  not any [any-float? ctype ctype/1 = 'integer!]]
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
					if find [byte! logic! float! float32! float64!] type/1 [
						value: to integer! value
					]
				]
				logic! [
					switch type/1 [
						byte! 	 [value: value <> null]
						integer! [value: value <> 0]
					]
				]
				float! float32! [
					if type/1 = 'integer! [
						value: to decimal! value
					]
				]
			]
			value
		]
		
		decorate-function: func [name [word!]][
			to word! join "_local_" form name
		]
		
		decorate-local-func-ptr: func [name [word!] /local type][
			either all [
				locals
				type: select locals name
				type: resolve-aliased type
				type/1 = 'function!
			][
				decorate-function name
			][
				name
			]
		]
		
		find-functions: func [name [word!]][
			name: decorate-local-func-ptr name
			any [
				find functions name
				find functions resolve-ns name
			]
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
				if 'value = last get-type expr [
					throw-error ["cannot infer type for:" mold name]
				]
				insert/only at pos 2 type: any [
					casted
					resolve-expr-type expr
				]
				if verbose > 2 [print ["inferred type" mold type "for variable:" pos/1]]
			]
		]
		
		order-ctx-candidates: func [a b][				;-- order by increasing path size,
			to logic! not all [							;-- and word! before path!.
				path? a
				any [
					word? b
					all [path? b greater? length? a length? b]
				]
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
					sort/compare pos/2 :order-ctx-candidates
				][
					append sym-ctx-table name
					append/only sym-ctx-table copy ns-path
				]
			]
		]
		
		add-ns-symbol: func [name [set-word!] /local ctx ns][
			name: to word! name
			if find second find/only ns-list ns-path name [exit]
			if ns-stack [
				ctx: tail ns-stack
				until [
					ctx: back ctx
					if all [
						ns: find/only ns-list to path! ctx/1
						find second ns name 
					][exit]
					head? ctx
				]
			]
			append second find/only ns-list ns-path name
		]
		
		add-symbol: func [name [word!] value type][
			unless type [type: get-type value]
			unless 'array! = first head type [type: copy type]
			append globals reduce [name type]
			type
		]
		
		add-function: func [type [word!] spec [block!] cc [word!]][
			repend functions [
				to word! spec/1 reduce [get-arity spec/3 type cc new-line/all spec/3 off]
			]
			if find-attribute spec/3 'callback [
				append last functions 'callback
			]
		]
		
		compare-func-specs: func [
			f-type [block!] c-type [block!] /with fun [word!] cb [get-word! object!] /local spec pos idx
		][
			if all [with not object? cb][
				cb: to word! cb
				if all [
					select functions :cb
					functions/:cb/3 <> functions/:fun/3 
				][
					throw-error [
						"incompatible calling conventions between"
						fun "and" cb
					]
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
				[cconv ['variadic | 'typed | 'custom]]
				| [['variadic | 'typed | 'custom] cconv]
				| 'catch | 'infix | 'variadic | 'typed | 'custom | 'callback | cconv
			]
			type-def: pick [[func-pointer | type-spec] [type-spec]] to logic! extend

			unless catch [
				parse specs [
					opt [								;-- function's attribute and main doc-string
						string! opt [into attribs]		;-- can be specified in any order
						| into attribs opt string!
					]
					pos: copy args any [
						pos: 'return (throw-error ["Cannot use `return` as argument name at:" mold pos])
						| word! into type-def opt string!	;-- arguments definition
					]
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
				clear-docstrings args
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
							compare-func-specs/with type/2 expected/2 name expr	 ;-- callback case
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
		
		check-variable-arity?: func [spec [block!] /local attribs][
			all [
				attribs: get-attributes spec
				any [
					all [find attribs 'variadic 'variadic]
					all [find attribs 'typed 'typed]
					all [find attribs 'custom 'custom]
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
		
		get-attributes: func [spec [block!]][
			any [
				all [block? spec/1 spec/1]
				all [string? spec/1 block? spec/2 spec/2]
			]
		]
		
		find-attribute: func [spec [block!] name [word!]][
			either list: get-attributes spec [
				to logic! find list name
			][
				false
			]
		]
		
		get-cconv: func [specs [block!]][
			pick [cdecl stdcall] to logic! all [
				not empty? specs
				find-attribute specs 'cdecl
			]
		]
		
		init-struct-values: func [specs [block!] /local name type][
			if specs: find/tail specs /local [
				parse specs [
					any [
						set name word!
						opt [set type block! (
							if struct-by-value? type [
								append locals-init name
							]
						)]
					]
				]
			]
		]
		
		fetch-func: func [name /local specs type cc attribs][
			name: to word! name
			store-ns-symbol name
			if ns-path [add-ns-symbol pc/-1]
			if ns-path [name: ns-prefix name]
			check-func-name name
			check-specs name specs: pc/2
			specs: copy specs
			clear-docstrings specs
			
			type: 'native
			cc:   'stdcall								;-- default calling convention
			
			if all [
				not empty? specs
				attribs: get-attributes specs
			][
				case [
					find attribs 'infix [
						if 2 <> get-arity specs [
							throw-error [
								"infix function requires 2 arguments, found"
								get-arity specs "for" name
							]
						]
						type: 'infix
					]
					find attribs 'cdecl   [cc: 'cdecl]
					find attribs 'stdcall [cc: 'stdcall]	;-- get ready when fastcall will be the default cc
				]
			]
			add-function type reduce [name none specs] cc
			emitter/add-native name
			repend natives [
				name specs pc/3 script
				all [ns-path copy ns-path]
				all [ns-stack copy/deep ns-stack]		;@@ /deep doesn't work on paths
				user-code?
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
			all [
				block? expr
				1 = length? expr
				literal? expr/1
				expr: expr/1							;-- unwrap literal value
			]
			expr
		]
		
		flag-callback: func [name [word!] cc [word! none!] /local spec][
			spec: second find-functions name
			spec/3: any [cc job/export-ABI all [job/red-pass? spec/3] 'cdecl]
			unless spec/5 = 'callback [append spec 'callback]
		]
		
		process-export: has [defs cc ns entry spec list name sym][
			if job/type = 'exe [
				throw-error "#export directive requires a library compilation mode"
			]
			if word? pc/2 [
				unless find [stdcall cdecl] cc: pc/2 [
					throw-error ["invalid calling convention specifier:" cc]
				]
				pc: next pc
			]
			list: pc/2
			while [not tail? list][
				sym: list/1
				entry: none
				unless any [word? sym path? sym][
					throw-error ["invalid exported symbol:" mold sym]
				]
				if path? sym [sym: resolve-ns-path sym]
				unless any [
					find globals sym
					entry: find-functions sym
				][
					throw-error ["undefined exported symbol:" mold sym]
				]
				if entry [
					flag-callback sym cc
					sym: entry/1
				]
				either string? name: pick list 2 [
					list: next list
				][
					name: form sym
				]
				repend exports [sym any [find/match name "exec/" name]]
				list: next list
			]
		]
		
		process-import: func [defs [block!] /local lib list cc name specs spec id reloc pos new? funcs err][
			unless block? defs [throw-error "#import expects a block! as argument"]
			
			err: ["invalid import specification at:" pos]
			unless parse defs [
				some [
					pos: set lib string! (
						new?: no
						unless list: select imports lib [
						 	list: make block! 10
							new?: yes
						]
					)
					pos: set cc ['cdecl | 'stdcall]		;-- calling convention
					pos: into [
						some [
							specs:						;-- new function mapping marker
							pos: set name set-word! (
								name: to word! name
								store-ns-symbol name
								if ns-path [
									add-ns-symbol to set-word! name
									name: ns-prefix name
								]
								check-func-name name
							)
							pos: set id   string!
							pos: set spec block!    (
								clear-docstrings spec
								either all [1 = length? spec not block? spec/1][
									unless parse spec type-spec [throw-error err]
									either ns-path [
										add-ns-symbol specs/1
										add-symbol ns-prefix to word! specs/1 none spec
									][
										add-symbol to word! specs/1 none spec
									]
									repend list [to issue! id reloc: make block! 1]
									emitter/import/var name reloc
								][
									check-specs/extend name spec
									specs: copy specs
									specs/1: name
									add-function 'import specs cc
									reloc: all [funcs: select imports lib select funcs id]
									unless reloc [repend list [id reloc: make block! 1]]
									emitter/import name reloc
								]
							)
						]
					](if new? [repend imports [lib list]])
				]
			][throw-error err]
		]
		
		process-syscall: func [defs [block!] /local name id spec pos][
			unless block? defs [throw-error "#syscall expects a block! as argument"]
			unless parse defs [
				some [
					pos: set name set-word! (check-func-name name: to word! name)
					pos: set id   integer!
					pos: set spec block!    (
						check-specs/extend name spec
						spec: copy spec
						clear-docstrings spec
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
					any [[
							copy enum-names word!
							| (enum-names: make block! 10) some [
								set enum-name set-word!
								(append enum-names to word! enum-name)
							]	set enum-value [integer! | word!]
						] 
						(enum-value: set-enumerator name enum-names enum-value)
						| set enum-name skip (
							throw-error ["invalid enumeration syntax:" mold enum-name]
						)
					]
				]
			][
				throw-error ["invalid enumeration (block required!):" mold value]
			]
		]
		
		process-get: func [code [block!] /local value][
			unless job/red-pass? [						;-- when Red runtime is included in a R/S app
				pc: skip pc 2							;-- just ignore #get directive
				return none
			]
			unless red/process-get-directive code/2 pc [
				throw-error ["cannot resolve path:" code/2]
			]
			fetch-expression #get
		]
		
		process-in: func [code [block!] /local value][
			unless job/red-pass? [						;-- when Red runtime is included in a R/S app
				pc: skip pc 2							;-- just ignore #in directive
				return none
			]
			unless red/process-in-directive code/2 code/3 pc [
				throw-error ["cannot resolve path:" code/2]
			]
			fetch-expression #in
		]
		
		process-check: func [code [block!] /local checks][
			unless job/red-pass? [						;-- when Red runtime is included in a R/S app
				pc: skip pc 2							;-- just ignore directive
				return none
			]
			checks: red/process-typecheck-directive code/2
			remove/part pc 2
			if checks [insert pc checks]
			none										;-- do not return an expression to compile
		]
		
		process-call: func [code [block!] /local mark][
			unless job/red-pass? [						;-- when Red runtime is included in a R/S app
				pc: skip pc 2							;-- just ignore #call directive
				return none
			]
			mark: tail red/output
			red/process-call-directive code/2 yes
			remove/part pc 2
			insert pc mark
			clear mark
			none										;-- do not return an expression to compile
		]
		
		process-u16: func [code [block!] /local str pos][
			unless string? str: code/2 [
				throw-error "#u16 can only be applied to literal strings"
			]
			parse/all str [any [skip pos: (insert pos null) skip]]
			append str null								;-- extra NUL for UTF-16 version
			pc: next pc
			fetch-expression #u16
		]
		
		comp-chunked: func [body [block!]][
			emitter/chunks/start
			do body
			emitter/chunks/stop
		]

		comp-directive: has [body][
			switch/default pc/1 [
				#import    [process-import  pc/2  pc: skip pc 2]
				#export    [process-export  pc/2  pc: skip pc 2]
				#syscall   [process-syscall pc/2  pc: skip pc 2]
				#call	   [process-call  pc]
				#get	   [process-get	  pc]
				#in		   [process-in	  pc]
				#typecheck [process-check pc]			;-- internal compiler directive
				#enum	   [process-enum pc/2 pc/3 pc: skip pc 3]
				#verbose   [set-verbose-level pc/2 pc: skip pc 2 none]
				#u16	   [process-u16 	  pc]
				#user-code [user-code?: not user-code? pc: next pc]
				#build-date[change pc mold now]
				#script	   [							;-- internal compiler directive
					unless pc/2 = 'in-memory [
						compiler/script: secure-clean-path pc/2	;-- set the origin of following code
					]
					pc: skip pc 2
					none
				]
			][
				throw-error ["unknown directive" pc/1]
			]
		]
		
		comp-print-debug: has [out][
			unless word? name: pc/2 [
				throw-error "?? needs a word as argument"
			]
			out: next next compose/deep [
				2 (to pair! reduce [calc-line 1])		;-- hidden line offset header
				print-line [
					2 (to pair! reduce [calc-line 1])	;-- hidden line offset header
					(join name ": ") (name)
				]
			]
			out/2: next next out/2
			change/part pc out 2
			none
		]
		
		comp-comment: does [
			pc: next pc
			either block? pc/1 [pc: next pc][fetch-expression 'comment]
			none
		]
		
		comp-with: has [ns list with-ns words res ctx][
			ns: pc/2
			unless all [any [word? ns block? ns] block? pc/3][
				throw-error "WITH invalid argument"
			]
			unless block? ns [ns: reduce [ns]]
			
			forall ns [
				ns/1: either path? ctx: resolve-ns/path ns/1 [ctx][to path! ctx]
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
				if path? value: pc/2 [value: to word! form value]
				
				unless all [word? value resolve-aliased reduce [value]][
					throw-error ["declaring literal for type" value "not supported"]
				]
				if all [ns-path ns: find-aliased/prefix value][value: ns]
				offset: 2
				['struct! value]
			]
			pc: skip pc offset
			value
		]
		
		comp-use: has [spec use-init use-locals use-stack size][
			pc: next pc
			unless all [block? spec: pc/1 not empty? spec][
				backtrack 'use
				throw-error "USE requires a spec block as first argument"
			]
			unless block? pc/2 [
				backtrack 'use
				throw-error "USE requires a body block as second argument"
			]
			unless locals [
				backtrack 'use
				throw-error "USE can only be used from inside a function's body"
			]
			
			use-init:   tail locals-init
			use-locals: tail locals
			use-stack:  tail emitter/stack
			
			unless find locals /local [append locals /local]
			append locals spec
			size: emitter/calc-locals-offsets use-locals
			func-locals-sz: func-locals-sz + size
			
			pc: next pc
			fetch-into/root pc/1 [comp-dialect]
			pc: next pc
			
			func-locals-sz: func-locals-sz - size
			clear use-init
			clear use-locals
			clear use-stack
			last-type: none-type
			none
		]
		
		comp-null: does [
			pc: next pc
			make action-class [action: 'null type: [any-pointer!] data: 0]
		]
		
		comp-as: has [ctype ptr? expr type][
			ctype: pc/2
			if ptr?: find [pointer! struct! function!] ctype [ctype: reduce [pc/2 pc/3]]
			if path? ctype [ctype: to word! form ctype]
			
			if any [
				not find [word! block!] type?/word ctype
				not any [	
					parse blockify ctype [func-pointer | type-syntax]
					find-aliased ctype
				]
			][
				throw-error ["invalid target type casting:" mold ctype]
			]
			pc: skip pc pick [3 2] to logic! ptr?
			expr: fetch-expression 'as

			if all [
				block? ctype
				ctype/1 = 'function!
				type: get-type expr
				type/1 = 'function!
			][
				unless compare-func-specs ctype/2 copy type/2 [
					throw-error "invalid functions casting: specifications not matching"
				]
			]
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
				expr: fetch-expression/final 'assert
				check-conditional 'assert expr			;-- verify conditional expression
				expr: process-logic-encoding expr yes

				insert/only pc next next compose [
					2 (to pair! reduce [line 1])		;-- hidden line offset header
					***-on-quit 98 as integer! system/pc
				]
				set [unused chunk] comp-block-chunked	;-- compile TRUE block
				emitter/set-signed-state expr			;-- properly set signed/unsigned state
				emitter/branch/over/on chunk reduce [expr/1] ;-- branch over if expr is true
				emitter/merge chunk
				last-type: none-type
				<last>
			][
				pc: next pc
				fetch-expression none					;-- consume next expression
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
			if ns-path [add-ns-symbol pc/-1]
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
			if path? expr: pc/1 [expr: to word! form expr]
			
			unless all [
				word? expr
				type: any [
					all [base-type? expr expr]
					all [enum-type? expr [integer!]]
					find-aliased expr
				]
				pc: next pc
			][
				expr: fetch-expression/final 'size?
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
				expr: fetch-expression/final/keep 'return ;-- compile expression to return
				type: check-expected-type/ret func-name expr ret
				ret: either type [last-type: type <last>][none]
			][
				if ret [throw-error "EXIT keyword is not compatible with declaring a return value"]
			]
			emitter/target/emit-jump-point emitter/exits
			ret
		]

		comp-catch: has [offset locals-size unused chunk start end cb? cnt][
			pc: next pc
			fetch-expression/keep/final 'catch
			if any [not last-type last-type <> [integer!]][
				backtrack 'catch
				throw-error "CATCH expects a threshold value of type integer!"
			]
			unless block? pc/1 [
				backtrack 'catch
				throw-error "CATCH requires a body block as 2nd argument"
			]
			
			catch-level: catch-level + 1
			set [unused chunk] comp-block-chunked		;-- compile body block
			catch-level: catch-level - 1

			start: comp-chunked [emitter/target/emit-open-catch length? chunk/1 not locals]
			chunk: emitter/chunks/join start chunk
			
			locals-size: any [all [locals func-locals-sz] 0]
			cb?: to logic! all [locals 'callback = last functions/:func-name]
			unless zero? cnt: count-outer-loops [locals-size: locals-size + (4 * cnt)]
			
			end: comp-chunked [emitter/target/emit-close-catch locals-size not locals cb?]
			chunk: emitter/chunks/join chunk end
			emitter/merge chunk
			
			last-type: none-type
			none
		]

		comp-block-chunked: func [/only /test name [word!] /bool /local expr][
			emitter/chunks/start
			expr: either only [
				fetch-expression/final none				;-- returns first expression
			][
				comp-block/final						;-- returns last expression
			]
			if test [
				check-conditional name expr				;-- verify conditional expression
				expr: process-logic-encoding expr no
			]
			if bool [
				if all [
					block? expr
					find comparison-op expr/1
					last-type/1 = 'logic!
				][
					emitter/logic-to-integer expr/1
				]
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
				set-word? expr [
					pc: find/reverse pc set-word!
					throw-error "assignment not supported in conditional expression"
				]
				'else [expr]
			]
		]
		
		comp-if: has [expr unused chunk][		
			pc: next pc
			expr: fetch-expression/final 'if			;-- compile expression
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
		
		comp-either: has [expr e-true e-false c-true c-false offset t-true t-false ret mark][
			pc: next pc
			expr: fetch-expression/final 'either		;-- compile expression
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
			cases: pc/1
			list:  make block! 8
			types: make block! 8
			
			until [										;-- collect and pre-compile all cases
				append expr-call-stack #test			;-- marker for disabling expression post-processing
				fetch-into cases [						;-- compile case test
					append/only list comp-block-chunked/only/test 'case
					cases: pc							;-- set cursor after the expression
				]
				clear find expr-call-stack #test
				
				append expr-call-stack #body			;-- marker for enabling expression post-processing
				fetch-into cases [						;-- compile case body
					append/only list body: comp-block-chunked/bool
					append/only types resolve-expr-type/quiet body/1
				]
				clear find expr-call-stack #body
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
			expr: fetch-expression/keep/final 'switch	;-- compile argument
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
							body: comp-block-chunked/bool
							append/only list body/2
							append/only types resolve-expr-type/quiet body/1
						]
					)
				]
				opt [
					'default pos: block! (
						fetch-into pos [				;-- compile default body
							default: comp-block-chunked/bool
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
		
		comp-break: does [
			if empty? loop-stack [throw-error "BREAK used with no loop"]
			switch last loop-stack [
				while-cond [throw-error "BREAK cannot be used in WHILE condition block"]
				loop	   [emitter/target/emit-pop]
			]
			emitter/target/emit-jump-point last emitter/breaks
			pc: next pc
			none
		]
		
		comp-continue: does [
			if empty? loop-stack [throw-error "CONTINUE used with no loop"]
			if 'while-cond = last loop-stack [
				throw-error "CONTINUE cannot be used in WHILE condition block"
			]
			emitter/target/emit-jump-point last either 'until = last loop-stack [
				emitter/cont-back						;-- jump at the beginning for UNTIL iterator,
			][											;-- as the looping condition cannot be guessed.
				emitter/cont-next						;-- jump at end for all others
			]
			pc: next pc
			none
		]
		
		comp-loop: has [expr body start][
			pc: next pc
			
			fetch-expression/keep/final 'loop			;-- compile expression
			if any [none? last-type last-type/1 <> 'integer!][
				throw-error "LOOP requires an integer as argument"
			]
			check-body pc/1
			emitter/target/emit-integer-operation '= [<last> 0]	;-- insert counter comparison to 0 (skipping)
			
			emitter/init-loop-jumps
			push-loop 'loop
			start: comp-chunked [emitter/target/emit-start-loop]
			set [expr body] comp-block-chunked
			pop-loop
			
			body: emitter/chunks/join start body
			emitter/resolve-loop-jumps body 'cont-next
			body: emitter/chunks/join body comp-chunked [emitter/target/emit-end-loop]
			emitter/target/signed?: yes					;-- force signed comparison for the counter
			emitter/branch/back/on body less-or-equal
			emitter/resolve-loop-jumps body 'breaks
			emitter/branch/over/on body greater-than	;-- skip loop if counter <= 0
			emitter/merge body
			last-type: none-type
			<last>
		]
		
		comp-until: has [expr chunk][
			pc: next pc
			check-body pc/1
			emitter/init-loop-jumps
			push-loop 'until
			set [expr chunk] comp-block-chunked/test 'until
			pop-loop
			emitter/resolve-loop-jumps chunk 'cont-back
			emitter/branch/back/on chunk expr/1
			emitter/resolve-loop-jumps chunk 'breaks
			emitter/merge chunk	
			last-type: none-type
			<last>
		]
		
		comp-while: has [expr unused cond body offset bodies][
			pc: next pc
			check-body pc/1								;-- check condition block
			check-body pc/2								;-- check body block
			emitter/init-loop-jumps
			
			push-loop 'while-cond
			set [expr cond]   comp-block-chunked/test 'while	;-- Condition block
			pop-loop
			push-loop 'while
			set [unused body] comp-block-chunked		;-- Body block
			pop-loop
			
			if logic? expr/1 [expr: [<>]]				;-- re-encode test op
			offset: emitter/branch/over body			;-- Jump to condition
			emitter/resolve-loop-jumps body 'cont-next
			bodies: emitter/chunks/join body cond
			emitter/set-signed-state expr				;-- properly set signed/unsigned state
			emitter/branch/back/on/adjust bodies reduce [expr/1] offset ;-- Test condition, exit if FALSE
			emitter/resolve-loop-jumps bodies 'breaks
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
		
		comp-assignment: has [name value n enum ns local?][
			push-call name: pc/1
			pc: next pc
			if set-word? name [
				if all [
					2 <= length? expr-call-stack
					not find calling-keywords value: first skip tail expr-call-stack -2
					find functions value
				][
					backtrack name
					throw-error "nested assignment in expression not supported"
				]
				n: to word! name
				local?: local-variable? n
				unless any [locals local?][store-ns-symbol n]
				
				if find [set-word! set-path!] type?/word pc/1 [
					backtrack name
					throw-error "cascading assignments not supported"
				]
				unless all [local? n = 'context][		;-- explicitly allow 'context name for local variables
					check-keywords n					;-- forbid keywords redefinition
				]
				if find definitions n [
					backtrack name
					throw-error ["redeclaration of definition" name]
				]
				if all [
					not local?
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
				unless local? [
					ns: resolve-ns n
					if all [locals ns not find globals ns][
						throw-error ["variable" n "not declared"]
					]
					if all [ns-path none? locals][add-ns-symbol pc/-1]
					if all [ns ns <> n][name: to set-word! ns]
					check-func-name/only to word! name	;-- avoid clashing with an existing function name		
				]
			]
			if set-path? name [
				unless any [name/1 = 'system local-variable? name/1][
					name: resolve-ns-path name
				]
				if all [series? name value: system-reflexion? name][name: value]
			]
			
			either none? value: fetch-expression name [	;-- explicitly test for none!
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
					expr: fetch-expression name
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
				loop n [append/only args fetch-expression name]	;-- fetch n arguments
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
		
		comp-path: has [path value ns type name get?][
			path: pc/1
			if get?: get-word? path/1 [path/1: to word! path/1]
			
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
				case [
					value: system-reflexion? path [
						either path/2 = 'words [
							return comp-word/with/root value ;-- re-route to global word resolution
						][
							pc: next pc
						]
					]
					system-action? path [
						return <last>
					]
					all [
						not get?
						'function! = first type: resolve-path-type path 
					][
						name: to word! form path
						check-specs name type/2
						clear-docstrings type/2
						add-function 'routine reduce [name none type/2] get-cconv type/2
						append last functions reduce [path 'local]
						return comp-func-args name skip tail functions -2
					]
					'else [
						comp-word/path path/1				;-- check if root word is defined
						last-type: resolve-path-type path
						all [
							get?
							'struct! = first get-type path/1
							'function! <> first resolve-path-type path 
							path/1: to get-word! path/1		;-- reform the pseudo get-path (for forward propagation)
						]
					]
				]
				any [value path]
			]
		]
		
		comp-get-word: has [spec name ns symbol][
			name: to word! pc/1
			unless local-variable? name [name: resolve-ns name]
			comp-word/with/check name
			
			if all [
				spec: find functions name
				spec: spec/2
			][
				unless find [native routine] spec/2 [
					throw-error "get-word syntax only reserved for native functions for now"
				]
				if all [
					symbol: last expr-call-stack
					spec: find functions symbol
					spec/2/2 = 'import					;-- only flag it when passed to external calls
					spec/2/5 <> 'callback
				][
					append spec/2 'callback				;@@ force cdecl ????
				]
			]
			also to get-word! name pc: next pc
		]
		
		direct-match-ns: func [ctx [path!] name [word!] path /local ns][
			if all [
				any [
					all [ns-stack find/only ns-stack ctx]
					all [ns-path find/only ns-path ctx]
				]
				ns: find/only ns-list ctx
				find ns/2 name
			][
				if path [return ns-join to path! ctx name] ;-- if /path, defer word conversion
				ns-decorate ns-join ctx name
			]
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
		
		resolve-ns: func [name [word!] /path /local ctx pos][
			unless ns-stack [return name]				;-- no current ns, pass-thru

			if ctx: find/skip sym-ctx-table name 2 [	;-- fetch context candidates
				ctx: ctx/2								;-- SELECT/SKIP on hash! unreliable!
				either block? ctx [						;-- more than one candidate
					all [								;-- try direct matching first
						pos: find/only ctx to path! load mold ns-stack	;-- safer to-path conversion
						return either path [
							ns-join to path! first pos name
						][
							ns-decorate ns-join first pos name
						]
					]
					ctx: tail ctx						;-- start from last defined context
					until [
						ctx: back ctx
						if value: any [
							match-ns name ctx/1 path 
							direct-match-ns ctx/1 name path
						][
							return value				;-- prefix name if context on stack
						]
						head? ctx
					]									;-- no match found, pass-thru
				][										;-- one parent context only
					name: any [
						match-ns name ctx path		 	;-- prefix name if context is on stack
						direct-match-ns ctx name path
						name
					]
				]
			]
			name
		]
	
		comp-word: func [
			/path symbol [word!]
			/with word [word!]
			/root										;-- system/words/* pass-thru
			/check										;-- check word validity, do not consume input
			/local entry name local? spec type
		][
			name: pc/1
			if name = shift-right-sym [name: '-**]		;-- replace '>>> words produced by Red layer

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
					if find calling-keywords name [push-call pc/1]
					unless check [do entry]
				]
				any [
					all [
						local?
						any [
							all [						;-- block local function pointers
								block? type: select locals name
								type: resolve-aliased type
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
					unless check [also name pc: next pc]
				]
				type: enum-type? name [
					last-type: type
					if verbose >= 3 [print ["ENUMERATOR" name "=" last-type]]
					unless check [also name pc: next pc]
				]
				all [
					not path
					entry: find-functions name
				][
					name: decorate-local-func-ptr name
					spec: entry/2/4
					if all [
						find-attribute spec 'infix
						path? pc/1
					][
						throw-error "infix functions cannot be called using a path"
					]
					unless check [comp-func-args name entry]
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
				pc: skip pc -2
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
		
		external-call?: func [spec [block!] /local attribs][
			to logic! any [
				spec/5 = 'callback
				all [
					attribs: get-attributes spec/4
					any [find attribs 'cdecl find attribs 'stdcall]
				]
			]
		]
		
		get-caller: func [name [word!] /root /local list found? stk][
			stk: exclude expr-call-stack [as #body #test]
			if tail? next stk [return none]
			
			list: back find stk name
			unless root [return any [all [find calling-keywords list/1 none] list/1]]
			
			while [found?: find calling-keywords list/1][list: back list]
			all [not found? not tail? next list list/1]
		]
		
		pass-struct-pointer?: func [spec [block!] slots [integer!]][
			all [
				spec/2 = 'import						 ;-- system ABI is enforced on imports only
				spec/3 = 'cdecl							 ;-- stdcall applies to R/S or Windows ABI
				any [
					all [1 < slots job/target = 'ARM]	 ;-- ARM requires it only for struct > 4 bytes
					all [
						not find [Windows MacOSX] job/OS ;-- fallback on Linux ABI
						job/target <> 'ARM
					]
				]
			]
		]
		
		process-returned-struct: func [name [word!] spec [block!] args [block!] /local alloc? slots caller][
			if all [
				slots: emitter/struct-slots?/check spec/4
				any [
					2 < slots							;-- R/S and Windows ABI
					pass-struct-pointer? spec slots		;-- check other cases
				]
			][
				unless caller: get-caller name [
					caller: either tail? pc [
						get-caller/root name
					][
						any [get-caller/root name 'args-top] ;-- 'args-top is just for routing in SWITCH 
					]
				]
				insert/only args switch/default type?/word caller [
					none!	  [<ret-ptr>]
					set-word! [
						unless get-variable-spec to word! caller [
							backtrack caller
							throw-error "variable not declared"
						]
						bind to word! caller caller		;-- binding for future shadow objects support  
					]
					set-path! [
						unless get-variable-spec caller/1 [
							backtrack caller
							throw-error ["unknown path root variable:" caller/1]
						]
						to path! caller
					]
					word!	  [
						alloc?: yes
						emitter/target/emit-reserve-stack slots
						to tag! emitter/arguments-size? spec/4
					]
				][
					throw-error ["comp-call error: (should not happen) bad caller type:" mold caller]
				]
			]
			all [alloc? slots]							;-- return slots allocated on stack, or none
		]

		comp-call: func [
			name [word!] args [block!]
			/local
				list type res align? left right dup var-arity? saved? arg expr spec fspec
				types slots
		][
			name: decorate-fun name
			list: either issue? args/1 [args/2][		;-- bypass type-checking for variable arity calls
				check-arguments-type name args
				args
			]
			spec: functions/:name
			slots: process-returned-struct name spec list	
			order-args name list						;-- reorder argument according to cconv
			
			align?: all [
				args/1 <> #custom
				any [
					spec/2 = 'import					;@@ syscalls don't seem to need special alignment??
					all [spec/2 = 'routine external-call? spec]
				]
			]
			if align? [emitter/target/emit-stack-align-prolog args spec]
			
			if args/1 <> #custom [
				type: second fspec: functions/:name
				either type <> 'op [
					all [
						not empty? list
						not all [block? fspec/4/1 intersect fspec/4/1 [variadic typed]]
						types: any [
							find/last fspec/4 return-def
							find/last fspec/4 /local
							tail fspec/4
						]
						types: back types
					]
					forall list [						;-- push function's arguments on stack
						expr: list/1
						if block? unbox expr [comp-expression expr yes]	;-- nested call
						if object? expr [cast expr]
						if type <> 'inline [
							either all [types not tag? expr block? types/1 'value = last types/1][
								emitter/push-struct expr resolve-aliased types/1
							][
								emitter/target/emit-argument expr fspec ;-- let target define how arguments are passed
							]
						]
						if types [types: skip types -2]
					]
				][										;-- nested calls as op argument require special handling
					if any [string? list/1 string? list/2][
						backtrack first find/reverse pc string!
						throw-error "literal string values cannot be used with operators"
					]
					if block? unbox list/1 [comp-expression list/1 yes]	;-- nested call
					left:  unbox list/1
					right: unbox list/2
					if saved?: all [block? left any [block? right path? right]][
						emitter/target/emit-save-last	;-- optionally save left argument result
					]
					if block? unbox list/2 [comp-expression list/2 yes]	;-- nested call
					if saved? [emitter/target/emit-restore-last]
				]
			]
			if all [user-code? spec/2 <> 'import][libRedRT/collect-extra name]
			
			res: emitter/target/emit-call name args

			either res [
				last-type: res
			][
				set-last-type functions/:name/4			;-- catch nested calls return type
			]
			if align? [emitter/target/emit-stack-align-epilog args]
			if slots  [emitter/target/emit-release-stack slots]
			res
		]
				
		comp-path-assign: func [
			set-path [set-path!] expr casted [block! none!] store? [logic!]
			/local type new value spec
		][
			value: unbox expr
			if all [
				find [block! path! tag!] type?/word value
				'value <> last last-type				;-- struct by value has specific handling
			][
				emitter/target/emit-move-path-alt		;-- save assigned value
			]
			if all [
				not local-variable? set-path/1
				enum-id? set-path/1
			][
				backtrack set-path
				throw-error ["enumeration cannot be used as path root:" set-path/1]
			]
			unless spec: get-variable-spec set-path/1 [
				backtrack set-path
				throw-error ["unknown path root variable:" set-path/1]
			]
			type: resolve-path-type set-path			;-- check path validity
			new: resolve-aliased get-type expr
			
			all [
				block? spec
				'value = last spec						;-- for local struct by value only
				not-initialized? set-path/1
				init-local set-path/1 expr casted		;-- mark as initialized and infer type if required
			]

			if type <> any [casted new][
				backtrack set-path
				throw-error [
					"type mismatch on setting path:" to path! set-path
					"^/*** expected:" mold type
					"^/*** found:" mold any [casted new]
				]
			]
			if store? [
				emitter/access-path set-path either any [block? value path? value][
					 <last>
				][
					expr
				]
			]
		]
		
		comp-variable-assign: func [
			set-word [set-word!] expr casted [block! none!] store? [logic!]
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
				fun-name: decorate-function name
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
				if all [
					new/1 = 'any-pointer!
					any-pointer? type
				][
					new: type
				]
				if 'value = last new [new: head remove back tail copy new]

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
					throw-error "variable not declared"
				]
				if any [
					all [casted casted/1 = 'function!]
					all [expr = <last> casted: last-type last-type/1 = 'function!]
				][
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
			
			if store? [
				unless all [paren? value 'value = last value][ ;-- struct by value excluded from heap allocation
					emitter/store name value type
				]
			]
		]
		
		comp-expression: func [expr keep? [logic!] /local variable boxed casting new? type spec store?][
			store?: no
			
			;-- preprocessing expression
			if all [block? expr find [set-word! set-path!] type?/word expr/1][
				variable: expr/1
				store?: yes
				expr: expr/2							;-- switch to assigned expression
				if set-word? variable [
					new?: any [
						not exists-variable? variable
						to logic! find [string! paren!] type?/word expr
					]
				]
			]			
			if object? expr [							;-- unbox type-casting object
				if all [variable expr/action = 'null][
					casting: cast-null variable
				]
				boxed: expr
				expr: either any-float? boxed/type [cast/quiet expr][cast expr]
			]
			
			;-- dead expressions elimination
			if all [
				not keep?
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
					emitter/target/emit-load expr		;-- emit code for single value
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
			if block? expr [							;-- if expr is a function call
				all [
					variable
					'value = last last-type				;-- for a struct passed by value
					word? expr/1
					spec: select functions expr/1
					pass-struct-pointer? spec emitter/struct-slots?/check spec/4
					store?: no							;-- avoid emitting assignment code
				]
				if all [
					any [
						keep?
						variable						;-- result needs to be stored
						all [
							'case = pick tail expr-call-stack -3
							#test <> pick tail expr-call-stack -2
							4 <= length? expr-call-stack
						]
					]
					last-type/1 = 'logic!				;-- function's return type is logic!
				][
					emitter/logic-to-integer expr/1		;-- runtime logic! conversion before storing
				]
				if all [
					variable boxed						;-- process casting if result assigned to variable
					find [logic! integer! float! float32! float64!] last-type/1
					find [logic! integer! float! float32! float64!] boxed/type	;-- fixes #967
					last-type/1 <> boxed/type
				][
					emitter/target/emit-casting boxed no ;-- insert runtime type casting if required
					last-type: boxed/type
				]
			]
			
			if all [									;-- clean FPU stack when required
				not variable
				block? expr
				word? expr/1
				any-float? get-return-type/check expr/1
				any [
					not find functions/(expr/1)/4 return-def	 ;-- clean if no return value
					all [
						1 = length? expr-call-stack ;-- or if return value not used
						not all [locals find locals return-def] ;@@ works for non-terminal expressions only
					]
				]
				not find expr-call-stack set-word!
				not find expr-call-stack set-path!
			][
				emitter/target/emit-float-trash-last	;-- avoid leaving a x86 FPU slot occupied,
			]											;-- if return value is not used.
			
			;-- storing result if assignement required
			if variable [
				if all [boxed not casting][
					casting: resolve-aliased boxed/type
				]
				unless boxed [boxed: expr]
				switch type?/word variable [
					set-word! [comp-variable-assign variable expr casting store?]
					set-path! [comp-path-assign		variable boxed casting store?]
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
			if infix? pc [
				either infix? back tail expr-call-stack [
					exit								;-- infix op already processed
				][
					throw-error "invalid use of infix operator"
				]
			]
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
		
		fetch-expression: func [
			caller [any-word! issue! none! set-path!]
			/final /keep /local expr pass value mark
		][
			mark: tail expr-call-stack
			check-infix-operators
			
			if verbose >= 4 [print ["<<<" mold pc/1]]
			pass: [also pc/1 pc: next pc]
			
			if tail? pc [
				either caller [
					unless backtrack caller [pc: back pc]
					throw-error [mold caller "is missing an argument"]
				][
					pc: back pc
					throw-error "missing argument"
				]
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
				block!		[also to paren! pc/1 pc: next pc]
				issue!		[comp-directive]
			][
				throw-error "datatype not allowed"
			]
			expr: reduce-logic-tests expr

			if final [
				if verbose >= 3 [?? expr]
				unless find [none! tag!] type?/word expr [
					comp-expression expr to logic! keep
				]
				clear mark
			]
			expr
		]
		
		comp-block: func [/final /only /local expr save-pc mark][
			block-level: block-level + 1
			save-pc: pc
			pc: pc/1

			either only [
				expr: either final [fetch-expression/final none][fetch-expression none]
				unless tail? pc [
					throw-error "more than one expression found in parentheses"
				]
			][
				mark: tail expr-call-stack
				while [not tail? pc][
					;if all [paren? pc/1 not infix? at pc 2][raise-paren-error]
					expr: either final [fetch-expression/final none][fetch-expression none]
					clear mark
				]
			]
			pc: next save-pc
			
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
						;unless infix? at pc 2 [raise-paren-error]
						expr: fetch-expression/final/keep none
					]
					'else [expr: fetch-expression/final/keep none]
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
			init-struct-values spec
			locals: spec
			func-name: name
			set [args-sz local-sz] emitter/enter name locals ;-- build function prolog
			func-locals-sz: local-sz
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
				ret: all [
					'value = last ret
					any [
						all [ret/1 = 'struct! ret/2]
						all [ret: resolve-aliased ret ret/1 = 'struct! ret/2]
					]
				]
			]
			emitter/leave name locals args-sz local-sz ret ;-- build function epilog
			remove-func-pointers
			clear locals-init
			locals: func-name: func-locals-sz: none
		]
		
		comp-natives: does [			
			foreach [name spec body origin ns nss user?] natives [
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
				user-code?: user?
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
		
		get-proto: func [name [word!]][
			switch/default job/OS [
				Windows [
					[handle [integer!]]
				]
				MacOSX [
					pick [
						[
							argc	[integer!]
							argv	[struct! [s [c-string!]]]
							envp	[struct! [s [c-string!]]]
							apple	[struct! [s [c-string!]]]
							pvars	[program-vars!]
						]
						[[cdecl]]
					] name = 'on-load
				]
			][											;-- Linux
				[[cdecl]]
			]
		]
		
		add-dll-callbacks: has [list code exp][			;-- add missing callbacks
			list: copy [on-load on-unload]
			if job/OS = 'Windows [
				append list [on-new-thread on-exit-thread]
			]
			code: make block! 1
			exp:  make block! 1
			
			foreach fun list [
				unless find/skip natives fun 7 [
					repend code [
						to set-word! fun 'func get-proto fun []	;-- stdcall
					]
				]
			]
			unless empty? code [
				pc: code
				comp-dialect
			]
		]

		run: func [obj [object!] src [block!] file [file!] /no-header /runtime /no-events][
			runtime: to logic! runtime
			job: obj
			pc: src
			script: secure-clean-path file
	
			unless no-header [comp-header]
			unless no-events [emitter/target/on-global-prolog runtime job/type]
			comp-dialect
			unless no-events [
				case [
					runtime [
						emitter/target/on-global-epilog yes	job/type ;-- postpone epilog event after comp-runtime-epilog
					]
					not job/runtime? [
						emitter/target/on-global-epilog no job/type
					]
				]
			]
		]
		
		finalize: has [tmpl words][
			if verbose >= 2 [print "^/---^/Compiling native functions^/---"]
			
			if job/type = 'dll [
				if all [job/dev-mode? job/libRedRT?][
					libRedRT/process job functions exports
				]
				if empty? exports [
					throw-error "missing #export directive for library production"
				]
				add-dll-callbacks 						;-- make sure they are defined
			]
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
	
	emit-func-prolog: func [name [word!] /local spec][
		compiler/add-function 'native reduce [name none []] 'stdcall
		spec: emitter/add-native name
		spec/2: either name = '***-boot-rs [1][emitter/tail-ptr]
		emitter/target/emit-prolog name [] 0
	]
	
	emit-main-prolog: has [name spec][
		either job/type = 'exe [
			emitter/target/on-init
		][												;-- wrap global code in a function
			emit-func-prolog '***-boot-rs
		]
	]

	comp-start: has [script][
		emitter/libc-init?: yes
		emitter/start-prolog
		;emitter/target/on-init							;@@ required?
		
		script:	either encap? [
			set-cache-base %system/runtime/
			%start.reds
		][
			secure-clean-path runtime-path/start.reds
		]
 		compiler/run/no-events job loader/process/own script script
 		emitter/start-epilog
 
		;-- selective clean-up of compiler's internals
 		remove/part find compiler/globals 'system 2		;-- avoid 'system redefinition clash
 		remove/part find emitter/symbols 'system 4
		clear compiler/definitions
		clear compiler/aliased-types
		emitter/libc-init?: no
	]
	
	comp-runtime-prolog: func [red? [logic!] payload [binary! none!] /local script ext][
		script: either encap? [
			set-cache-base %system/runtime/
			%common.reds
		][
			secure-clean-path runtime-path/common.reds
		]
 		compiler/run/runtime job loader/process/own script script
 		
 		if red? [
			if all [job/dev-mode? job/type = 'exe][
				ext: switch/default job/OS [Windows [%.dll] MacOSX [%.dylib]][%.so]
				compiler/process-import compose [
					(join "libRedRT" ext) stdcall [__red-boot: "red/boot" []]
				]
				compiler/comp-call '__red-boot []
			]
			if payload [								;-- Redbin boot data handling
				emitter/target/emit-load-literal [binary!] payload
				emitter/target/emit-move-path-alt
				emitter/access-path first [system/boot-data:] <last> 
			]
 			unless empty? red/sys-global [
				set-cache-base %./
				compiler/run job loader/process red/sys-global %***sys-global.reds
 			]
 			if any [not job/dev-mode? job/libRedRT?][
				set-cache-base %runtime/
				script: pick [%red.reds %../runtime/red.reds] encap?
				compiler/run job loader/process/own script script
			]
 		]
 		if job/type = 'dll [
			emitter/target/emit-epilog '***-boot-rs [] 0 0
			emit-func-prolog '***-main
		]
 		set-cache-base none
	]
	
	comp-runtime-epilog: does [
		either job/need-main? [
			emitter/target/on-global-epilog no job/type	;-- emit main() epilog
		][
			switch job/type [
				exe [compiler/comp-call '***-on-quit [0 0]]	;-- call runtime exit handler
				dll [emitter/target/emit-epilog '***-main [] 0 0]
				drv [emitter/target/emit-epilog '***-boot-rs [] 0 0]
			]
		]
	]
	
	clean-up: does [
		compiler/ns-path: 
		compiler/ns-stack: 
		compiler/locals: none
		compiler/resolve-alias?:  yes
		compiler/user-code?: no
		
		clear compiler/imports
		clear compiler/exports
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
		file: last split-path file					;-- remove path
		file: to-file first parse file "."			;-- remove extension
		case [
			none? job/build-basename [
				job/build-basename: file
			]
			slash = last job/build-basename [
				append job/build-basename file
			]
		]
		job
	]
	
	set 'dt func [code [block!] /local t0][
		t0: now/time/precise
		do code
		now/time/precise - t0
	]

	collect-resources: func [
		header	[block!]
		res		[block!]
		file	[file!]
		/local icon name value info main-path version-info-key base
	][
		info: make block! 8
		main-path: first split-path file
		base: either encap? [%system/assets/][%assets/]
		
		either icon: select header first [Icon:][
			append res 'icon
			either any [word? :icon any-word? :icon][
				repend/only res [
					join base select [
						default %red.ico
						flat 	%red.ico
						old		%red-3D.ico
						mono	%red-mono.ico
					] :icon
				]
			][
				icon: either file? icon [reduce [icon]][icon]
				foreach file icon [
					append info either loader/relative-path? file [
						join main-path file
					][file]
					unless exists? last info [
						red/throw-error ["cannot find icon:" last info]
					]
				]
				append/only res copy info
			]
		][
			append res compose/deep [icon [(base/red.ico)]]
		]

		clear info
		append res 'version

		version-info-key: [
			Title: Version: Company: Comments: Notes:
			Rights: Trademarks: Author: ProductName:
		]
		foreach name version-info-key [
			if value: select header name [
				append info reduce [to word! name value]
			]
		]
		append/only res info
	]
	
	compile: func [
		files [file! block!]							;-- source file or block of source files
		/options
			opts [object!]
		/loaded 										;-- source code is already in LOADed format
			job-data [block!]
		/local
			comp-time link-time err output src resources icon
	][
		comp-time: dt [
			unless block? files [files: reduce [files]]
			
			unless opts [opts: make options-class []]
			job: make-job opts last files				;-- last input filename is retained for output name
			emitter/init opts/link? job
			if opts/verbosity >= 10 [set-verbose-level opts/verbosity]
			
			clean-up
			loader/init
			emit-main-prolog
			
			job/need-main?: to logic! any [
				job/need-main?							;-- pass-thru if set in config file
				all [
					job/type = 'exe
					not find [Windows MacOSX] job/OS
				]
			]
			
			if all [
				job/need-main?
				not opts/use-natives?
				opts/runtime?
			][
				comp-start								;-- init libC properly
			]		
			if opts/runtime? [
				comp-runtime-prolog to logic! loaded all [loaded job-data/3]
			]
			
			set-verbose-level opts/verbosity
			resources: either loaded [job-data/4][make block! 8]
			if job/libRedRT-update? [libRedRT/init-extras]
			
			foreach file files [
				either loaded [
					src: loader/process/with job-data/1 file
				][
					src: loader/process file
					if job/OS = 'Windows [collect-resources src/2 resources file]
				]
				compiler/run job src file
			]
			set-verbose-level 0
			if opts/runtime? [comp-runtime-epilog]
			
			set-verbose-level opts/verbosity
			compiler/finalize							;-- compile all functions
			set-verbose-level 0
			
			if job/libRedRT-update? [libRedRT/save-extras]
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
				unless empty? compiler/exports [
					append job/sections compose/deep/only [
						export [- - (compiler/exports)]
					]
				]
				if job/OS = 'Windows [
					if icon: find resources 'icon [
						insert skip icon 2 reduce ['group-icon icon/2]
					]
					append resources reduce ['manifest none]		;-- always use manifest file in DLL and EXE
				]
				unless empty? resources [
					append job/sections compose/deep/only [
						rsrc   [- - (resources)]
					]
				]
				if opts/debug? [
					job/debug-info: reduce ['lines compiler/debug-lines]
				]
				output: linker/build job
			]
		]
		
		set-verbose-level opts/verbosity
		output-logs
		if any [opts/link? not opts/dev-mode?][clean-up]
		set-verbose-level 0

		reduce [
			comp-time
			link-time
			any [all [job/buffer length? job/buffer] 0]
			output
		]
	]
]
