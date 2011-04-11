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
		defs: make block! 100
		
		num-chars: charset "0123456789"
		
		init: does [
			include-dirs: copy [%runtime/]
			clear defs
			insert defs <no-match>				;-- required to avoid empty rule (causes infinite loop)
		]
		
		find-path: func [file [file!]][
			foreach dir include-dirs [
				if exists? dir/:file [return dir/:file]
			]
			make error! reform ["Include File Access Error:" file]
		]
		
		expand-string: func [src [string! binary!] /local value s e][
			if verbose > 0 [print "running string preprocessor..."]
			
			parse/all/case src [				;-- not-LOAD-able syntax support
				any [
					s: copy value 1 8 num-chars #"h" e: (		;-- literal hexadecimal support
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
						rule: copy/deep [s: _ e: (e: change/part s _ e) :e]
						rule/2: to lit-word! name
						rule/4/4: value
						either tag? defs/1 [remove defs][append defs '|]
						append defs rule
					)
					| s: #include set name file! e: (
						if verbose > 0 [print ["...including file:" mold name]]
						name: find-path name
						value: skip process/short name 2 		;-- skip Red/System header						
						e: change/part s value e
					) :s
					| s: set value char! (e: change s to integer! value) :e
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
			expand-string src: any [src input]			;-- process string-level compiler directives
			
			;TBD: add Red/System header checking here!
			
			if error? set/any 'err try [src: load src][	;-- convert source to blocks
				print ["Syntax Error at LOAD phase:" mold disarm err]
			]
			
			unless short [expand-block src]		;-- process block-level compiler directives
			src
		]
	]
	
	compiler: context [
		job: pc: last-type: locals: none
		verbose:  0										;-- logs verbosity level
	
		imports: 	   make block! 10
		bodies:	  	   make hash! 40					;-- [name [specs] [body]...]
		globals:  	   make hash! 40
		aliased-types: make hash! 10
		
		functions: to-hash [
		;--Name--Arity--Type----Cc--Specs--		   Cc = Calling convention
			+		[2	op		- [a [number! pointer!] b [number! pointer!] return: [integer!]]]
			-		[2	op		- [a [number! pointer!] b [number! pointer!] return: [integer!]]]
			*		[2	op		- [a [number!] b [number!] return: [integer!]]]
			/		[2	op		- [a [number!] b [number!] return: [integer!]]]
			and		[2	op		- [a [number!] b [number!] return: [integer!]]]		;-- AND
			or		[2	op		- [a [number!] b [number!] return: [integer!]]]		;-- OR
			xor		[2	op		- [a [number!] b [number!] return: [integer!]]]		;-- XOR
			//		[2	op		- [a [number!] b [number!] return: [integer!]]]		;-- modulo
			;>>		[2	op		- [a [number!] b [number!] return: [integer!]]]		;-- shift left
			;<<		[2	op		- [a [number!] b [number!] return: [integer!]]]		;-- shift right
			=		[2	op		- [a b return: [logic!]]]
			<>		[2	op		- [a b return: [logic!]]]
			>		[2	op		- [a [number! pointer!] b [number! pointer!] return: [logic!]]]
			<		[2	op		- [a [number! pointer!] b [number! pointer!] return: [logic!]]]
			>=		[2	op		- [a [number! pointer!] b [number! pointer!] return: [logic!]]]
			<=		[2	op		- [a [number! pointer!] b [number! pointer!] return: [logic!]]]
			;not	[1	inline	- [a [number!]]]									;-- NOT
			;make	[2 	inline	- [type [word!] spec [number! pointer!]]]
			length? [1	inline	- [v [c-string!] return: [integer!]]]
		]
		
		user-functions: tail functions	;-- marker for user functions
		
		datatype: 	[
			'int8! | 'int16! | 'int32! | 'integer! | 'int64! | 'uint8! | 'uint16! |
			'uint32! | 'uint64! | 'pointer! | 'binary! | 'c-string! 
			| 'struct! word!	;@@ 
		]
		
		reserved-words: [
			;&			 [comp-pointer]
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
			true		 [also true pc: next pc]		;-- converts word! to logic!
			false		 [also false pc: next pc]		;-- converts word! to logic!
		]
		
		throw-error: func [err [word! string!]][
			print [
				"***"
				either word? err [
					join uppercase/part mold err 1 " error"
				][err]
			]
			print ["at: " mold copy/part pc 4]
			clean-up
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
					value = <last>  [last-type]
					block? value	[compose/deep [(to-word join value/1 #"!") [(value/2)]]]
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
			<last>
		]
		
		comp-block-chunked: func [/only /test /local expr][
			emitter/chunks/start
			expr: either only [
				fetch-expression/final					;-- returns first expression
			][
				comp-block/final						;-- returns last expression
			]
			if test [expr: check-logic expr]
			reduce [
				expr 
				emitter/chunks/stop						;-- returns a chunk block!
			]
		]
		
		check-logic: func [expr][		
			switch/default type?/word expr [
				logic! [reduce [expr]]
				word!  [
					switch/default first resolve-type expr [
						logic! [
							emitter/target/emit-operation '= [<last> 0]
							[#[true]]					;-- request '= comparison
						]
						function! [
							;TBD: test
						]
					][
						throw-error "expected logic! variable or conditional expression"
					]
				]
			][expr]
		]
		
		comp-if: has [expr unused chunk][		
			pc: next pc
			expr: fetch-expression/final				;-- compile condition expression
			expr: check-logic expr		
			check-body pc/1
	
			set [unused chunk] comp-block-chunked		;-- TRUE block
			emitter/branch/over/on chunk expr/1			;-- insert IF branching			
			emitter/merge chunk		
			<last>
		]
		
		comp-either: has [expr unused c-true c-false offset][
			pc: next pc
			expr: fetch-expression/final				;-- compile condition
			expr: check-logic expr
			check-body pc/1
			check-body pc/2
			
			set [unused c-true]  comp-block-chunked		;-- TRUE block		
			set [unused c-false] comp-block-chunked		;-- FALSE block
		
			offset: emitter/branch/over c-false
			emitter/branch/over/adjust/on c-true negate offset expr/1	;-- skip over JMP-exit
			emitter/merge emitter/chunks/join c-true c-false
			<last>
		]
		
		comp-until: has [expr chunk][
			pc: next pc
			check-body pc/1
			set [expr chunk] comp-block-chunked/test
			emitter/branch/back/on chunk expr/1	
			emitter/merge chunk			
			<last>
		]
		
		comp-while: has [expr unused cond body  offset bodies][
			pc: next pc
			check-body pc/1
			check-body pc/2
			
			set [expr cond]   comp-block-chunked/test	;-- Condition block
			set [unused body] comp-block-chunked		;-- Body block
			
			if logic? expr/1 [expr: [<>]]				;-- re-encode test op
			offset: emitter/branch/over body			;-- Jump to condition
			bodies: emitter/chunks/join body cond
			emitter/branch/back/on/adjust bodies reduce [expr/1] offset ;-- Test condition, exit if FALSE
			emitter/merge bodies
			<last>
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
			pick [1x0 0x1] not invert					;-- 1x0 => test for TRUE, 0x1 => opposite
		]
		
		comp-set-word: has [name value][
			name: pc/1
			pc: next pc
			switch/default pc/1 [
				func [
					fetch-func name
					none
				]
				function [
					fetch-func name
					none
				]
				alias [
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
				pointer [
					;TBD check pointer spec validity
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
		
		comp-expression: func [tree /assign /local name value offset body][	
			switch/default type?/word tree/1 [
				set-word! [				
					name: to-word tree/1
					value: either block? tree/2 [
						comp-expression/assign tree/2
						<last>
					][
						tree/2
					]
					add-symbol name value
					if path? value [
						emitter/access-path value
						value: <last>
					]
					if logic? value [						;-- convert literal logic! values
						value: to-integer value				;-- TRUE => 1, FALSE => 0
					]
					emitter/target/emit-store name value
				]
				set-path! [
					value: either block? tree/2 [
						comp-expression tree/2
						<last>
					][
						tree/2
					]
					emitter/access-path/store path value
				]
			][		
				name: to-word tree/1
				emitter/target/emit-call name next tree
				get-return-type functions/:name/4
				if all [
					assign 
					find emitter/target/comparison-op name
					last-type = 'logic!
				][											;-- runtime logic! conversion before storing
					set [offset body] emitter/chunks/make-boolean
					emitter/branch/over/on/adjust body reduce [name] offset
					emitter/merge body
				]
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
					not find [none! tag! logic! pair!] type?/word expr [
						emitter/target/emit-last expr	; TBD: add logic! emitter! ??
					]
				]
			]
			either pair? expr [							;-- special encoding for ALL/ANY
				reduce [select [1x0 #[true] 0x1 #[false]] expr]
			][
				expr
			]
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
		compiler/run/no-header loader/process runtime-env/:type
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
	
	make-job: func [opts [object!] file [file!] /local job][
		file: last split-path file			;-- remove path
		file: to-file first parse file "."	;-- remove extension
		
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
		files [file! block!]			;-- source file or block of source files
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
			compiler/finalize			;-- compile all functions
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
			reduce [comp-time link-time length? job/buffer]
			compiler/job: job: none
	]
]