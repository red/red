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
	verbose:  0								;-- logs verbosity level
	job: none								;-- reference the current job object	
	runtime-env: none						;-- hold OS-specific Red/System runtime
	runtime-path: %runtime/
	nl: newline
	
	;errors: [
	;	type	["message" arg1 "and" arg2]
	;]
	
	preprocessor: context [
		verbose: 0
	
		alpha-chars: charset [#"A" - #"Z" #"a" - #"z"]
		num-chars: charset "0123456789"
		special: charset "_-"
		alpha-num: union special union alpha-chars num-chars
		value-char: complement charset ";^/"
		ws: charset " ^-^/^M"
		space: charset " "

		expand: func [source [string! binary!] /local defs name value rule s e][
			source: as-string source
			defs: make block! 100
			parse/all/case source [				;-- 1st pass: get definitions
				any [
					newline any ws "#define" some space
					copy name some alpha-num
					copy value some value-char (
						rule: copy/deep [s: _ e: (e: change/part s _ e) :e |]
						rule/2: name
						rule/4/4: trim value
						append defs rule
						if verbose >= 1 [
							print ["define:" mold name "=>" mold value]
						]
					)
					| s: copy value 1 8 num-chars #"h" e: (
						e: change/part s to-integer to-issue value e
					) :e
					| skip
				]
			]
			unless empty? defs [				;-- 2nd pass: resolve definitions
				remove back tail defs
				parse/all/case source [
					any ["#define" to newline | defs | skip]
				]
			]
			source
		]
	]
	
	compiler: context [
		job: pc: last-type: locals: none
		verbose:  0							;-- logs verbosity level
	
		imports: 	   make block! 10
		bodies:	  	   make hash! 40		;-- [name [specs] [body]...]
		globals:  	   make hash! 40
		aliased-types: make hash! 10
		
		functions: to-hash [
		;--Name--Arity--Type----Cc--Specs--		   Cc = Calling convention
			+		[2	op		- [a [number! pointer!] b [number! pointer!]]]
			-		[2	op		- [a [number! pointer!] b [number! pointer!]]]
			*		[2	op		- [a [number!] b [number!]]]
			/		[2	op		- [a [number!] b [number!]]]
			and		[2	op		- [a [number!] b [number!]]]		;-- AND
			or		[2	op		- [a [number!] b [number!]]]		;-- OR
			xor		[2	op		- [a [number!] b [number!]]]		;-- XOR
			mod		[2	op		- [a [number!] b [number!]]]		;-- modulo
			;>>		[2	op		- [a [number!] b [number!]]]		;-- shift left
			;<<		[2	op		- [a [number!] b [number!]]]		;-- shift right
			=		[2	op		- [a b]]
			<>		[2	op		- [a b]]
			>		[2	op		- [a [number! pointer!] b [number! pointer!]]]
			<		[2	op		- [a [number! pointer!] b [number! pointer!]]]
			>=		[2	op		- [a [number! pointer!] b [number! pointer!]]]
			<=		[2	op		- [a [number! pointer!] b [number! pointer!]]]
			not		[1	inline	- [a [number!]]]					;-- NOT
			make	[2 	inline	- [type [word!] spec [number! pointer!]]]
			length? [1	inline	- [v [string! binary! struct!]]]
		]
		
		user-functions: tail functions	;-- marker for user functions
		
		datatype: 	[
			'int8! | 'int16! | 'int32! | 'integer! | 'int64! | 'uint8! | 'uint16! |
			'uint32! | 'uint64! | 'hexa! | 'pointer! | 'binary! | 'string! 
			| 'struct! word!
		]
		
		reserved-words: [
			&			 [comp-pointer]
			as			 [comp-as]
			size? 		 [comp-size?]
			if			 [comp-if]
			either		 [comp-either]
			until		 [comp-until]
			while		 [comp-while]
			any			 [comp-expression-list]
			all			 [comp-expression-list/invert]
			null	 	 [also 0 pc: next pc]
			struct! 	 [also 'struct! pc: next pc]
		]
		
		throw-error: func [err [word! string!]][
			print [
				"***"
				either word? err [
					join uppercase/part mold err 1 " error"
				][err]
			]
			print ["at: " mold copy/part pc 4]
			halt
		]
		
		get-return-type: func [spec][	
			if spec: select spec [return:][last-type: spec/1]
		]
		
		resolve-type: func [name [word!] /with parent [block!] /local type][
			type: any [
				all [with select parent name]
				all [locals select locals name]
				select globals name
			]
			unless find emitter/datatypes type/1 [
				type: select aliased-types type/1
			]
			type
		]
		
		add-symbol: func [name [word!] value /local type new ctx][
			ctx: any [locals globals]
			unless find ctx name [
				type: case [
					value = 'last 	[last-type]
					block? value	[compose/deep [struct! [(value/2)]]]
					word? value 	[first select ctx value]
					'else 			[type?/word value]
				]			
				append ctx new: reduce [name compose [(type)]]
				if ctx = globals [emitter/set-global new value]
			]
		]
		
		add-function: func [type [word!] spec [block!] cc [word!] /local name arity][		
			if find functions name: to-word spec/1 [
				;TBD: symbol already defined
			]
			;TBD: check spec syntax (here or somewhere else)
			arity: either pos: find spec/3 /local [
				(index? pos) -  1 / 2
			][
				(length? spec/3) / 2
			]		
			if find spec/3 [return:][arity: arity - 1]
			repend functions [
				name reduce [arity type cc new-line/all spec/3 off]
			]
		]
		
		check-specs: func [specs /local type s][
			unless block? specs [throw-error 'syntax]
			type: [
				some datatype | s: set w word! (
					if find aliased-types w [s: next s]		;-- make the rule fail if not found
				) :s
			]
			unless parse specs [
				any [word! into type]			;TBD: check datatypes compatibility!
				opt  [set-word! into type]
				opt  [/local some [word! into type]]
			][
				throw-error "invalid function specs"
			]
		]
		
		check-body: func [body][
			case/all [
				not block? :body [throw-error 'syntax 'block-expected]
				empty? body  [throw-error 'syntax 'empty-block]
			]
		]
		
		fetch-into: func [code [block! paren!] body [block!] /local save-pc][		;-- compile sub-block
			save-pc: pc
			pc: code
			do body
			pc: next save-pc
		]
		
		fetch-func: func [name][
			;check if name taken
			check-specs pc/2
			add-function 'native reduce [name none pc/2] 'stdcall
			emitter/add-native to-word name
			repend bodies [to-word name pc/2 pc/3]
			pc: skip pc 3
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
							emitter/import-function to-word specs/1	reloc
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
						;emitter/import-function to-word specs/1 reloc					
					]				
					pc: skip pc 2
				]
				#define [pc: skip pc 3]					;-- preprocessed before
			][
				;TBD: unknown directive error
			]
		]
		
		comp-as: has [type value][
			type: pc/2
			pc: skip pc 2
			value: fetch-expression
			last-type: either block? type [type][reduce [type]]
			value
		]
		
		comp-size?: has [type size][
			pc: next pc
			type: resolve-type pc/1
			size: select emitter/datatypes type/1
			emitter/target/emit-last size
			pc: next pc
			'last
		]
		
		comp-block-chunked: func [/only][
			emitter/chunks/start
			reduce [
				either only [
					fetch-expression/final				;-- returns first expression
				][
					comp-block/final					;-- returns last expression
				]
				emitter/chunks/stop						;-- returns a chunk block!
			]
		]
		
		comp-if: has [expr unused chunk][		
			pc: next pc
			expr: fetch-expression/final				;-- compile condition
			check-body pc/1
		
			set [unused chunk] comp-block-chunked		;-- TRUE block
			emitter/branch/over/on chunk expr/1			;-- insert IF branching			
			emitter/merge chunk		
			'last
		]
		
		comp-either: has [expr unused c-true c-false offset][
			pc: next pc
			expr: fetch-expression/final				;-- compile condition
			check-body pc/1
			check-body pc/2
			
			set [unused c-true]  comp-block-chunked		;-- TRUE block		
			set [unused c-false] comp-block-chunked		;-- FALSE block
		
			offset: emitter/branch/over c-false
			emitter/branch/over/adjust/on c-true negate offset expr/1	;-- skip over JMP-exit
			emitter/merge emitter/chunks/join c-true c-false
			'last
		]
		
		comp-until: has [expr chunk][
			pc: next pc
			check-body pc/1
			set [expr chunk] comp-block-chunked
			emitter/branch/back/on chunk expr/1	
			emitter/merge chunk			
			'last
		]
		
		comp-while: has [expr unused cond body  offset bodies][
			pc: next pc
			check-body pc/1
			check-body pc/2
			
			set [expr cond]   comp-block-chunked		;-- Condition block
			set [unused body] comp-block-chunked		;-- Body block
			
			offset: emitter/branch/over body			;-- Jump to condition
			bodies: emitter/chunks/join body cond
			emitter/branch/back/on/adjust bodies reduce [expr/1] offset ;-- Test condition, exit if FALSE
			emitter/merge bodies
			'last
		]
		
		comp-expression-list: func [/invert /local list offset bodies test][
			pc: next pc
			check-body pc/1
			
			list: make block! 8
			fetch-into pc/1 [
				while [not tail? pc][					;-- comp all expressions in chunks
					append/only list comp-block-chunked/only
				]
			]
			list: back tail list
			set [offset bodies] emitter/chunks/make-boolean		;-- emit ending FALSE/TRUE block
			test: either invert [list/1/1/1][reduce [list/1/1/1]]
			emitter/branch/over/on/adjust bodies test offset	;-- last branching
			bodies: emitter/chunks/join list/1/2 bodies			;-- left join last expression with ending block
			while [not head? list][								;-- left join all remaining expr in reverse order
				list: back list
				test: either invert [list/1/1/1][reduce [list/1/1/1]]
				emitter/branch/over/on/adjust bodies test offset	;-- emit branch first
				bodies: emitter/chunks/join list/1/2 bodies			;-- then left join expr
			]
			emitter/merge bodies
			not invert									;-- true => test for TRUE, false => opposite
		]
		
		comp-set-word: has [name value][
			name: pc/1
			pc: next pc
			switch/default pc/1 [
				func [
					fetch-func name
					none
				]
				alias-type [
					;TBD: check specs block validity
					repend aliased-types [
						to word! name
						either find [struct! pointer!] to-word pc/2 [
							also reduce [pc/2 pc/3] pc: skip pc 3	
						][
							also pc/2 pc: skip pc 2
						]
					]
					none
				]
				struct [
					;TBD check struct spec validity
					add-symbol to-word name reduce [pc/1 pc/2]
					pc: skip pc 2
					none
				]
			][
				value: fetch-expression
				new-line/all reduce [name value] no
			]
		]
	
		comp-word: has [entry args n name][
			case [
				entry: select reserved-words pc/1 [	;-- reserved word
					do entry
				]
				any [
					all [locals find locals pc/1]
					find globals pc/1
				][									;-- it's a variable
					also pc/1 pc: next pc
				]
				entry: find functions name: pc/1 [
					pc: next pc						;-- it's a function		
					args: make block! n: entry/2/1
					if all [
						entry/1 = 'make 
						find [struct!] pc/1
					][
						n: n + 1
					]
					loop n [						;-- fetch n arguments
						append/only args fetch-expression	;TBD: check arg types!
					]
					head insert args name
				]
				'else [throw-error "undefined symbol"]
			]
		]
		
		comp-set-path: does [
			path: pc/1		
			pc: next pc		
			value: fetch-expression
			new-line/all reduce [path value] no
		]
		
		order-args: func [tree /local func? name type][
			if all [
				func?: not find [set-word! set-path!] type?/word tree/1
				name: to-word tree/1
				find [import native] functions/:name/2
				find [stdcall cdecl gcc45] functions/:name/3
			][
				reverse next tree
			]
			foreach v next tree [if block? v [order-args v]]	;-- recursive processing
		]
		
		comp-expression: func [tree /local name value][	
			switch/default type?/word tree/1 [
				set-word! [				
					name: to-word tree/1
					value: either block? tree/2 [
						comp-expression tree/2
						'last
					][
						tree/2
					]
					add-symbol name value
					if path? value [
						emitter/access-path value
						value: 'last
					]
					emitter/target/emit-store name value
				]
				set-path! [
					value: either block? tree/2 [
						comp-expression tree/2
						'last
					][
						tree/2
					]
					emitter/access-path/store path value
				]
			][		
				name: to-word tree/1
				emitter/target/emit-call name next tree
				get-return-type functions/:name/4
			]
		]
		
		infix?: func [pos [block! paren!] /local specs][
			all [
				not tail? pos
				word? pos/1
				specs: select functions pos/1
				specs/2 = 'op
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
		
		fetch-expression: func [/final /local expr][
			check-infix-operators
			if verbose >= 4 [print ["<<<" mold pc/1]]
			
			expr: switch/default type?/word pc/1 [
				set-word!	[comp-set-word]
				word!		[comp-word]
				path! 		[also pc/1 pc: next pc]
				set-path!	[comp-set-path]
				paren!		[comp-block]
				integer!	[also pc/1 pc: next pc]
				decimal! 	[also pc/1 pc: next pc]
				string!		[also pc/1 pc: next pc]
				block!		[also pc/1 pc: next pc]		;-- struct! and pointer! specs
				struct!		[also pc/1 pc: next pc]		;-- literal struct! value
			][
				throw-error "datatype not allowed"
			]
			if final [
				if verbose >= 3 [?? expr]
				case [
					block? expr [
						order-args expr
						comp-expression expr
					]
					not find [logic! none!] type?/word expr [
						emitter/target/emit-last expr
					]
				]
			]
			any [all [logic? expr reduce [expr]] expr]	;TBD: check this
		]
		
		comp-block: func [/final /local expr][
			fetch-into pc/1 [
				while [not tail? pc][
					expr: either final [
						fetch-expression/final
					][
						fetch-expression
					]
				]
			]
			expr
		]
		
		comp-dialect: does [
			while [not tail? pc][
				case [
					issue? pc/1 [comp-directive]
					find [
						set-word!
						word! 
						path!
						set-path!
					] type?/word pc/1 [
						fetch-expression/final
					]
					'else [throw-error 'syntax]
				]
			]
		]
		
		comp-func: func [name spec body /local args-size][
			locals: spec
			args-size: emitter/enter name locals
			pc: body
			comp-dialect
			emitter/leave name locals args-size
			locals: none
		]
		
		comp-natives: does [
			if verbose >= 2 [print "^/---^/Compiling native functions^/---"]
			foreach [name spec body] bodies [
				if verbose >= 2 [print ["function:" name]]
				comp-func name spec body
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
			preprocessor
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
		compiler/run/no-header load preprocessor/expand runtime-env/:type
	]
	
	set-runtime: func [job][
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
	
	make-job: func [file [file!] /local fmt][
		file: last split-path file			;-- remove path
		file: to-file first parse file "."	;-- remove extension
		
		fmt: select [					;TBD: allow cross-compilation!
			3	'PE						;-- Windows
			4	'ELF					;-- Linux
			5	'Mach-o					;-- Mac OS X
		] system/version/4
		
		make linker/job-class [
			output: 	file
			format:		fmt
			type: 		'exe
			target:		'IA32
			sub-system: 'console
			;sub-system: 'GUI
		]
	]
	
	dt: func [code [block!] /local t0][
		t0: now/time/precise
		do code
		now/time/precise - t0
	]
	
	compile: func [
		files [file! block!]			;-- source file or block of source files
		/in
			path						;-- where to place compile/link results
		/link							;-- invoke the linker and finalize the job
		/level
			verbosity [integer!]		;-- logs verbosity (0 => none)
		/local
			comp-time link-time err src
	][
		comp-time: dt [
			unless block? files [files: reduce [files]]
			emitter/init link job: make-job last files	;-- last file's name is retained for output
			compiler/job: job
			set-runtime job
			
			if level [set-verbose-level verbosity]
			
			comp-runtime 'prolog
			
			foreach file files [
				src: preprocessor/expand read/binary file			
				if error? set/any 'err try [src: load src][
					print ["Syntax Error at LOAD phase:" mold disarm err]
				]			
				compiler/run src				
			]
			
			comp-runtime 'epilog
			compiler/finalize
		]
		if verbose >= 4 [
			print [
				"-- emitter/code-buf (no-relocations):"
				nl mold emitter/code-buf nl
			]
		]

		if link [
			link-time: dt [
				job/symbols: emitter/symbols
				job/sections: compose/deep [
					code   [- 	(emitter/code-buf)]
					data   [- 	(emitter/data-buf)]
					import [- - (compiler/imports)]
				]
				linker/build/in job any [path %builds/]
			]
		]
		output-logs
		if link [clean-up]
		
		also
			reduce [comp-time link-time length? job/buffer]
			compiler/job: job: none
	]
]