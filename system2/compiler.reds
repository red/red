Red/System [
	Title:   "Red/System compiler"
	File: 	 %compiler.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

compiler: context [

	#include %utils/vector.reds
	#include %utils/mempool.reds
	#include %utils/hashmap.reds
	#include %utils/array.reds
	#include %utils/bit-table.reds

	verbose: 3

	#enum arch-id! [
		arch-x86
		arch-x86-64
		arch-arm
		arch-arm64
	]

	dprint: func [
		[typed]	count [integer!] list [typed-value!]
	][
		if verbose >= 3 [
			_print count list no
			prin-byte lf
		]
	]

	;-- used in red cell!
	#define TYPE_INT64		100
	#define TYPE_ADDR		101
	#define TYPE_REF		102

	val!: alias struct! [
		header	[integer!]
		value	[integer!]
		ptr		[int-ptr!]
	]

	#define enter-block(blk) [
		saved-blk: cur-blk
		cur-blk: blk
	]

	#define exit-block [
		cur-blk: saved-blk
	]

	#define LIST_INSERT(l item) [
		l: make-list as int-ptr! item l
	]

	#define xmalloc(type) [
		as type malloc size? type
	]

	mach-program!: alias struct! [
		data-buf	[vector!]	;-- vector<byte!>
		code-buf	[vector!]	;-- vector<byte!>
		functions	[vector!]	;-- vector<codegen!>
		imports		[int-ptr!]	;-- token-map<libname, token-map<func-name, vector<int>>>
	]

	;-- lisp-like list
	list!: alias struct! [
		head	[int-ptr!]
		tail	[list!]
	]

	make-list: func [
		head	[int-ptr!]
		tail	[list!]
		return: [list!] 
		/local
			l	[list!]
	][
		l: as list! malloc size? list!
		l/head: head
		l/tail: tail
		l
	]

	align-up: func [
		i		[integer!]
		align	[integer!]
		return: [integer!]
	][
		i + align - 1 / align * align
	]

	common-literals: context [
		logic-true: as cell! 0
		logic-false: as cell! 0
		int-zero: as cell! 0
		int-one: as cell! 0
		int-two: as cell! 0
		int-four: as cell! 0
		float-zero: as cell! 0
		float-one: as cell! 0

		init: func [
			/local
				i	[red-integer!]
				b	[red-logic!]
				f	[red-float!]
		][
			logic-true: as cell! malloc size? cell!
			b: as red-logic! logic-true
			b/header: TYPE_LOGIC
			b/value: true

			logic-false: as cell! malloc size? cell!
			b: as red-logic! logic-false
			b/header: TYPE_LOGIC
			b/value: false

			int-zero: as cell! malloc size? cell!
			i: as red-integer! int-zero
			i/header: TYPE_INTEGER
			i/value: 0

			int-one: as cell! malloc size? cell!
			i: as red-integer! int-one
			i/header: TYPE_INTEGER
			i/value: 1
			
			int-two: as cell! malloc size? cell!
			i: as red-integer! int-two
			i/header: TYPE_INTEGER
			i/value: 2

			int-four: as cell! malloc size? cell!
			i: as red-integer! int-four
			i/header: TYPE_INTEGER
			i/value: 4

			float-zero: as cell! malloc size? cell!
			f: as red-float! float-zero
			f/header: TYPE_FLOAT
			f/value: 0.0

			float-one: as cell! malloc size? cell!
			f: as red-float! float-one
			f/header: TYPE_FLOAT
			f/value: 1.0
		]
	]

	#define acquire-buf(n) [
		p: vector/acquire buf n
	]

	put-b: func [buf [vector!] b [integer!] /local p [byte-ptr!]][
		acquire-buf(1)
		p/value: as byte! b
	]

	put-bb: func [buf [vector!] b1 [integer!] b2 [integer!] /local p [byte-ptr!]][
		acquire-buf(2)
		p/1: as byte! b1
		p/2: as byte! b2
	]

	put-bbb: func [buf [vector!] b1 [integer!] b2 [integer!] b3 [integer!] /local p [byte-ptr!]][
		acquire-buf(3)
		p/1: as byte! b1
		p/2: as byte! b2
		p/3: as byte! b3
	]

	put-16: func [buf [vector!] d [integer!] /local p [byte-ptr!]][
		acquire-buf(2)
		p/1: as byte! d
		p/2: as byte! d >> 8
	]

	;-- 32-bit little-endian integer!
	put-32: func [buf [vector!] d [integer!] /local p [byte-ptr!] pp [int-ptr!]][
		acquire-buf(4)
		pp: as int-ptr! p
		pp/value: d
	]

	;-- 32-bit big-endian integer!
	put-32be: func [buf [vector!] d [integer!] /local p [byte-ptr!]][
		acquire-buf(4)
		p/1: as byte! d >> 24
		p/2: as byte! d >> 16
		p/3: as byte! d >> 8
		p/4: as byte! d
	]

	change-at-32: func [
		p		[byte-ptr!]
		pos		[integer!]
		d		[integer!]
		/local
			buf	[int-ptr!]
	][
		buf: as int-ptr! p + pos
		buf/value: d
	]

	#include %opcode.reds
	#include %type-system.reds
	#include %rst/parser.reds
	#include %rst/rst-printer.reds
	#include %rst/op-cache.reds
	#include %rst/type-checker.reds

	data-section: context [
		buf: as vector! 0
		code-to-data: as int-ptr! 0		;-- hashmap
		data-to-data: as int-ptr! 0		;-- hashmap

		acquire: func [
			size	[integer!]
		][
			vector/acquire buf size
		]

		pos: func [return: [integer!]][buf/length]

		emit-b: func [b [integer!]][
			put-b buf b
		]

		emit-d: func [d [integer!]][put-32 buf d]

		emit-val: func [v [val!] /local f [red-float!] p [int-ptr!]][
			switch TYPE_OF(v) [
				TYPE_FLOAT [
					f: as red-float! v
					p: :f/value
					emit-d p/1
					emit-d p/2
				]
				default [0]
			]
		]

		record-pos: func [/local idx [integer!]][
			emit-d 0
			idx: pos
			record-reloc-pos data-to-data idx - 4 idx
		]

		store-literal: func [
			val		[rst-expr!]
			return: [logic!]
			/local
				ty	[integer!]
				b	[logic-literal!]
				int [int-literal!]
				arr [array-literal!]
				v	[cell!]
				len	[integer!]
				idx [integer!]
				p	[byte-ptr!]
				pp	[int-ptr!]
				f	[float-literal!]
		][
			ty: NODE_TYPE(val)
			if ty > RST_LIT_ARRAY [return false]

			switch ty [
				RST_LOGIC	[
					b: as logic-literal! val
					emit-b as integer! b/value
				]
				RST_INT		[
					int: as int-literal! val
					emit-d int/value
				]
				RST_BYTE [0]
				RST_FLOAT [
					f: as float-literal! val
					pp: :f/value
					emit-d pp/1
					emit-d pp/2
				]
				RST_NULL [emit-d 0]
				RST_C_STR
				RST_BINARY [0]
				RST_LIT_ARRAY [
					record-pos
					arr: as array-literal! val
					v: arr/token
					switch TYPE_OF(v) [
						TYPE_STRING [
							len: -1
							p: as byte-ptr! unicode/to-utf8 as red-string! v :len
							either len >= 0 [
								len: len + 1	;-- include null-byte
								arr/length: len
								loop len [
									emit-b as integer! p/value
									p: p + 1
								]
							][
								emit-b as integer! null-byte
							]
						]
						TYPE_BLOCK [
							0
						]
					]
				]
				default [0]
			]
			true
		]
	]

	record-global: func [
		var		[var-decl!]
		/local
			sz idx [integer!]
	][
		if var/data-idx >= 0 [exit]

		sz: type-size? var/type yes
		with [data-section][
			var/data-idx: pos
			unless store-literal var/init [
				record-pos
				acquire sz
			]
		]
	]

	record-reloc-pos: func [
		map		[int-ptr!]
		pos		[integer!]
		ref		[integer!]
		/local
			p	[ptr-ptr!]
			vec [vector!]
	][
		p: hashmap/get map ref
		either p <> null [
			vec: as vector! p/value
		][
			vec: vector/make size? integer! 2
			hashmap/put map ref as int-ptr! vec
		]
		vector/append-int vec pos
	]

	record-abs-ref: func [
		pos		[integer!]
		ref		[val!]
		/local
			var [var-decl!]
	][
		var: as var-decl! ref/ptr
		record-reloc-pos data-section/code-to-data pos var/data-idx
	]

	#include %ir/ir-graph.reds
	#include %ir/optimizer.reds
	#include %ir/lowering.reds
	#include %backend.reds

	fn-alloc-regs!: alias function! [codegen [codegen!]]
	fn-make-frame!: alias function! [ir [ir-fn!] return: [frame!]]
	fn-make-cc!: alias function! [fn [fn!] op [instr-op!] return: [call-conv!]]
	fn-generate!: alias function! [cg [codegen!] blk [basic-block!] i [instr!]]
	fn-insert-instrs!: alias function! [cg [codegen!] v [vreg!] idx [integer!]]
	fn-insert-move!: alias function! [cg [codegen!] arg [move-arg!]]
	fn-assemble!: alias function! [cg [codegen!] i [mach-instr!]]
	fn-patch-call!: alias function! [ref [integer!] pos [integer!]]
	fn-is-reg!: alias function! [r [integer!] return: [logic!]]
	fn-to-xmmr!: alias function! [r [integer!] return: [integer!]]

	target: context [
		arch: arch-x86
		addr-width: 32		;-- width of address in bits
		addr-size: 4		;-- size of address in bytes
		addr-align: 4
		page-align: 4096
		int-width: 32
		int-mask: 1 << int-width - 1
		int-type: as rst-type! 0
		int32-arith?: yes		;-- native support for int32 arithmetic
		int64-arith?: no		;-- native support for int64 arithmetic
		big-endian?: no

		;-- backend specific functions
		alloc-regs: as fn-alloc-regs! 0
		make-frame: as fn-make-frame! 0
		make-cc:	as fn-make-cc! 0
		gen-op:		as fn-generate! 0
		gen-if:		as fn-generate! 0
		gen-switch:	as fn-generate! 0
		gen-goto:	as fn-generate! 0
		gen-throw:	as fn-generate! 0
		gen-restore-var: as fn-insert-instrs! 0
		gen-save-var: as fn-insert-instrs! 0
		gen-move-loc: as fn-insert-move! 0
		gen-move-imm: as fn-insert-move! 0
		assemble: as fn-assemble! 0
		patch-call: as fn-patch-call! 0
		gpr-reg?: as fn-is-reg! 0
		xmm-reg?: as fn-is-reg! 0
		to-xmm-reg: as fn-to-xmmr! 0
	]

	_mempool: as mempool! 0

	src-blk: as red-block! 0
	cur-blk: as red-block! 0
	script: as cell! 0

	ir-module: as ir-module! 0
	program: as mach-program! 0

	vector-to-array: func [
		vec		[vector!]
		return: [ptr-array!]
		/local
			arr [ptr-array!]
	][
		arr: ptr-array/make vec/length
		copy-memory as byte-ptr! ARRAY_DATA(arr) vec/data arr/length * size? int-ptr!
		arr
	]

	vector-to-block: func [
		vec		[vector!]
		blk		[red-block!]
		/local
			p	[int-ptr!]
	][
		p: as int-ptr! vec/data
		loop vec/length [
			red/integer/make-in blk p/value
			p: p + 1
		]
	]

	prin-token: func [v [cell!]][
		if null? v [exit]
		#call [prin-cell v]
	]

	;@@ the memory returned should be zeroed
	malloc: func [size [integer!] return: [byte-ptr!]][
		mempool/alloc _mempool size
	]

	calc-line: func [
		pc		[cell!]
		return: [integer!]
		/local
			idx		[integer!]
			beg		[cell!]
			header	[cell!]
			prev	[integer!]
			p		[red-pair!]
	][
		header: block/rs-abs-at cur-blk 0
		beg: block/rs-head cur-blk
		idx: (as-integer pc - beg) >> 4 + 1
		if cur-blk = src-blk [idx: idx + 2]		;-- skip header Red/System [...]
		prev: 1

		while [
			header: header + 1
			header < beg
		][
			p: as red-pair! header
			if p/y = idx [return p/x]
			if p/y > idx [return prev]
			prev: p/x
		]
		p/x
	]

	throw-error: func [
		[typed] count [integer!] list [typed-value!]
		/local
			s	[c-string!]
			w	[cell!]
			pc	[cell!]
			p	[cell!]
			h	[integer!]
	][
		pc: as cell! list/value
		list: list + 1
		count: count - 1
		
		prin "*** Compilation Error: "
		until [
			either list/type = type-c-string! [
				s: as-c-string list/value prin s
			][
				w: as cell! list/value
				if w <> null [prin-token w]
			]

			count: count - 1	
			if count <> 0 [prin " "]

			list: list + 1
			zero? count
		]
		print "^/*** in file: " prin-token compiler/script
		print ["^/*** at line: " calc-line pc lf]
		p: block/rs-head cur-blk
		h: cur-blk/head
		cur-blk/head: (as-integer pc - p) >> 4 + h
		print "*** near: " #call [prin-block cur-blk 200]
		cur-blk/head: h
		print "^/"
		quit 1
	]

	unreachable: func [pc [cell!]][
		throw-error [pc "Should not reach here!!!"]
	]

	comp-fn: func [
		fn		[fn!]
		parent	[context!]
		f-ctx	[context!]
		return: [context!]
		/local
			src	[red-block!]
			ctx [context!]
			ir	[ir-fn!]
			cg	[codegen!]
	][
		src: fn/body
		src-blk: src
		dprint "^/^/=> Parsing"
		ctx: parser/parse-context fn/token src parent f-ctx

		dprint "=> Type checking"
		type-checker/check ctx
		if verbose >= 3 [rst-printer/print-program ctx]

		dprint "=> Generating SSA"
		ir: ir-graph/generate fn ctx
		if verbose >= 3 [ir-printer/print-graph ir]

		dprint "=> Lowering SSA"
		lowering/do-fn ir
		if verbose >= 3 [ir-printer/print-graph ir]

		cg: backend/generate ir
		vector/append-ptr program/functions as byte-ptr! cg
		ctx
	]

	init-func-ctx: func [
		ctx			[context!]
		fn			[fn!]
		/local
			ft		[fn-type!]
			var		[var-decl!]
			add-decls [subroutine!]
	][
		add-decls: [
			while [var <> null][
				unless parser/add-decl ctx var/token as int-ptr! var [
					throw-error [var/token "symbol name was already defined"]
				]
				var: var/next
			]
		]

		ADD_NODE_FLAGS(ctx RST_FN_CTX)

		ft: as fn-type! fn/type
		ctx/ret-type: ft/ret-type

		var: ft/params
		add-decls

		var: fn/locals
		add-decls
	]

	comp-functions: func [
		ctx		[context!]
		/local
			n		[integer!]
			decls	[int-ptr!]
			kv		[int-ptr!]
			f-ctx	[context!]
			fn		[fn!]
	][
		if null? ctx [exit]

		decls: ctx/decls
		n: hashmap/size? decls

		kv: null
		loop n [
			kv: hashmap/next decls kv
			fn: as fn! kv/2
			if all [NODE_TYPE(fn) = RST_FUNC NODE_FLAGS(fn) and RST_IMPORT_FN = 0][
				cur-blk: fn/body
				f-ctx: parser/make-ctx fn/token ctx yes
				init-func-ctx f-ctx fn
				comp-fn fn ctx f-ctx
				comp-functions f-ctx		;-- compile funcs defined inside the func
			]
		]
		comp-functions ctx/child
		comp-functions ctx/next
	]

	reloc-fn-calls: func [
		funcs		[vector!]
		/local
			p		[ptr-ptr!]
			cg		[codegen!]
			pos		[integer!]
			fn		[fn!]
			refs	[vector!]
			ref		[int-ptr!]
	][
		p: as ptr-ptr! funcs/data
		loop funcs/length [				;-- reloc native calls
			cg: as codegen! p/value
			pos: cg/mark
			fn: cg/fn/fn
			refs: as vector! fn/body
			if refs <> null [
				ref: as int-ptr! refs/data
				loop refs/length [
					target/patch-call ref/value pos
					ref: ref + 1
				]
			]
			p: p + 1
		]
	]

	fill-job-symbols: func [
		symbols		[red-block!]
		/local
			map		[int-ptr!]
			n		[integer!]
			refs	[vector!]
			ref		[int-ptr!]
			pint	[int-ptr!]
			w-global [cell!]
			w-dash	 [cell!]
			blk blk2 [red-block!]
	][
		w-global: as cell! word/load "global"
		w-dash: as cell! word/load "-"
		map: data-section/code-to-data
		n: hashmap/size? map
		ref: null
		loop n [
			ref: hashmap/next map ref
			red/tag/load-in "data" 4 symbols UTF-8
			blk: red/block/make-in symbols 4
			red/block/rs-append blk w-global
			red/integer/make-in blk ref/1
			refs: as vector! ref/2
			blk2: red/block/make-in blk refs/length
			pint: as int-ptr! refs/data
			loop refs/length [
				red/integer/make-in blk2 pint/value
				pint: pint + 1
			]
			red/block/rs-append blk w-dash
		]

		map: data-section/data-to-data
		n: hashmap/size? map
		ref: null
		loop n [
			ref: hashmap/next map ref
			red/tag/load-in "data" 4 symbols UTF-8
			blk: red/block/make-in symbols 4
			red/block/rs-append blk w-global
			red/integer/make-in blk ref/1
			red/block/make-in blk 1	;-- empty block
			refs: as vector! ref/2
			blk2: red/block/make-in blk refs/length
			pint: as int-ptr! refs/data
			loop refs/length [
				red/integer/make-in blk2 pint/value
				pint: pint + 1
			]
		]
	]

	fill-job-imports: func [
		imports		[red-block!]
		/local
			mdata	[node!]
			s		[series!]
			val		[cell!]
			s-tail	[cell!]
			vv tt	[cell!]
			blk		[red-block!]
			refs	[vector!]
			h		[red-handle!]
	][
		mdata: token-map/get-data program/imports
		s: as series! mdata/value
		val: s/offset
		s-tail: s/tail

		while [val < s-tail][
			red/block/rs-append imports val		;-- libname
			h: as red-handle! val + 1
			mdata: token-map/get-data as int-ptr! h/value
			s: as series! mdata/value
			blk: red/block/make-in imports (as-integer (s/tail - s/offset)) >> 4
			vv: s/offset
			tt: s/tail
			while [vv < tt][
				red/block/rs-append blk vv		;-- func name
				h: as red-handle! vv + 1
				refs: as vector! h/value
				vector-to-block refs red/block/make-in blk refs/length
				vv: vv + 2
			]
			val: val + 2
		]
	]

	fill-job-code: func [
		code		[red-binary!]
		/local
			len		[integer!]
			s		[series!]
	][
		len: program/code-buf/length
		red/binary/make-at as cell! code len
		s: GET_BUFFER(code)
		copy-memory as byte-ptr! s/offset program/code-buf/data len
		s/tail: as cell! (as byte-ptr! s/tail) + len
	]

	fill-job-data: func [
		data		[red-binary!]
		/local
			len		[integer!]
			s		[series!]
	][
		len: program/data-buf/length
		red/binary/make-at as cell! data len
		s: GET_BUFFER(data)
		copy-memory as byte-ptr! s/offset program/data-buf/data len
		s/tail: as cell! (as byte-ptr! s/tail) + len
	]

	init-program: func [][
		ir-module: as ir-module! malloc size? ir-module!
		ir-module/functions: vector/make size? int-ptr! 100

		program: xmalloc(mach-program!)
		program/functions: ptr-vector/make 100
		program/imports:  token-map/make 50
		program/code-buf: vector/make 1 4096
		program/data-buf: vector/make 1 4096

		data-section/buf: program/data-buf
		data-section/code-to-data: hashmap/make 200
		data-section/data-to-data: hashmap/make 200
	]

	comp-dialect: func [
		src			[red-block!]
		job			[red-object!]
		/local
			ctx 	[context!]
			fn		[fn!]
			cg		[codegen!]
			p		[ptr-ptr!]
			funcs	[vector!]
			code	[red-binary!]
			data	[red-binary!]
			symbols [red-block!]
			imports [red-block!]
			_job	[cell! value]
	][
		job: as red-object! copy-cell as cell! job _job		;-- job slot will be overwrite by lexer
		script: object/rs-select job as cell! word/load "script"
		code: as red-binary! object/rs-select job as cell! word/load "code-buf"
		data: as red-binary! object/rs-select job as cell! word/load "data-buf"
		symbols: as red-block! object/rs-select job as cell! word/load "symbols"
		imports: as red-block! object/rs-select job as cell! word/load "imports"

		init-program

		fn: xmalloc(fn!)
		fn/body: src
		fn/type: as rst-type! op-cache/void-op

		;-- compiling
		;-- TBD compile functions with multi-threads
		stack/mark-try-all words/_anon
		catch CATCH_ALL_EXCEPTIONS [
			ctx: comp-fn fn null null
			comp-functions ctx
			stack/unwind
		]
		stack/adjust-post-try
		if system/thrown <> 0 [re-throw]

		;-- generating machine code
		funcs: program/functions
		p: as ptr-ptr! funcs/data
		loop funcs/length [
			cg: as codegen! p/value
			backend/assemble-instrs cg
			backend/patch-labels
			p: p + 1
		]
		;dump-hex program/code-buf/data

		reloc-fn-calls funcs

		;-- fill the job object, we'll do the rest part in Red
		fill-job-symbols symbols
		fill-job-imports imports
		fill-job-code code
		fill-job-data data
	]

	init-target: func [
		job [red-object!]
		/local
			w	[red-word!]
			sym [integer!]
	][
		w: as red-word! object/rs-select job as cell! word/load "target"
		sym: symbol/resolve w/symbol
		target/arch: case [
			sym = symbol/make "IA-32" [arch-x86]
			sym = symbol/make "AMD64" [arch-x86-64]
			sym = symbol/make "arm"	  [arch-arm]
			sym = symbol/make "arm64" [arch-arm64]
		]

		with [target backend][
			switch arch [
				arch-x86 [
					addr-width: 32		;-- width of address in bits
					addr-size: 4		;-- size of address in bytes
					addr-align: 4
					page-align: 4096
					int-width: 32
					int-mask: 1 << int-width - 1
					int64-arith?: no	;-- native support for int64 arithmetic

					x86-cond/init
					x86-reg-set/init
					x86-stdcall/init
					x86-cdecl/init
					x86-internal-cc/init
					
					target/make-cc: :x86-cc/make
					target/make-frame: :x86/make-frame
					target/gen-op: as fn-generate! :x86/gen-op
					target/gen-if: as fn-generate! :x86/gen-if
					target/gen-goto: as fn-generate! :x86/gen-goto
					target/gen-restore-var: as fn-insert-instrs! :x86/gen-restore
					target/gen-save-var: as fn-insert-instrs! :x86/gen-save
					target/gen-move-loc: as fn-insert-move! :x86/gen-move-loc
					target/gen-move-imm: as fn-insert-move! :x86/gen-move-imm
					target/assemble: as fn-assemble! :x86/assemble
					target/patch-call: as fn-patch-call! :x86/patch-call
					x86/asm/rex-byte: 0
				]
				arch-x86-64 [
					addr-width: 64		;-- width of address in bits
					addr-size: 8		;-- size of address in bytes
					addr-align: 8
					page-align: 4096
					int-width: 64
					int-mask: 1 << int-width - 1
					int64-arith?: yes	;-- native support for int64 arithmetic

					x86-cond/init
					x64-reg-set/init
					x64-win-cc/init
					x64-internal-cc/init

					target/make-cc: :x64-cc/make
					target/make-frame: :x86/make-frame
					target/gen-op: as fn-generate! :x86/gen-op
					target/gen-if: as fn-generate! :x86/gen-if
					target/gen-goto: as fn-generate! :x86/gen-goto
					target/gen-restore-var: as fn-insert-instrs! :x86/gen-restore
					target/gen-save-var: as fn-insert-instrs! :x86/gen-save
					target/gen-move-loc: as fn-insert-move! :x86/gen-move-loc
					target/gen-move-imm: as fn-insert-move! :x86/gen-move-imm
					target/assemble: as fn-assemble! :x86/assemble
					target/patch-call: as fn-patch-call! :x86/patch-call
					x86/asm/rex-byte: REX_W
				]
				arch-arm
				arch-arm64 [0]
				default [0]
			]
		]
	]

	init: func [job [red-object!]][
		_mempool: mempool/make
		empty-array: ptr-array/make 0

		init-target job
		common-literals/init
		type-system/init	;@@ init it first
		parser/init
		op-cache/init
		type-checker/init
		rst-printer/init
		ir-graph/init
		backend/init
	]

	clean: does [
		mempool/destroy _mempool
		if ir-printer/blocks <> null [
			vector/destroy ir-printer/blocks
		]
	]
]