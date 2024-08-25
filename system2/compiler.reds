Red/System [
	Title:   "Red/System compiler"
	File: 	 %compiler.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

compiler: context [

	verbose: 3

	#define enter-block(blk) [
		saved-blk: cur-blk
		cur-blk: blk
	]

	#define exit-block [
		cur-blk: saved-blk
	]

	#define ARRAY_DATA(arr) (as ptr-ptr! (arr + 1))
	#define array-value! [array-1! value]
	#define INIT_ARRAY_VALUE(a v) [a/length: 1 a/val-1: as byte-ptr! v]
	#define INIT_ARRAY_2(a v1 v2) [a/length: 2 a/val-1: as byte-ptr! v1 a/val-2: as byte-ptr! v2]

	ptr-array!: alias struct! [
		length	[integer!]
		;--data
	]

	array-1!: alias struct! [		;-- ptr array with one value
		length	[integer!]
		val-1	[byte-ptr!]
	]

	array-2!: alias struct! [		;-- ptr array with two values
		length	[integer!]
		val-1	[byte-ptr!]
		val-2	[byte-ptr!]
	]

	empty-array: as ptr-array! 0

	ptr-array: context [
		make: func [
			size	[integer!]
			return: [ptr-array!]
			/local
				a	[ptr-array!]
		][
			a: as ptr-array! malloc (size * size? int-ptr!) + size? ptr-array!
			a/length: size
			a
		]

		copy-n: func [
			arr		[ptr-array!]
			n		[integer!]
			return: [ptr-array!]
			/local
				new [ptr-array!]
		][
			assert n <= arr/length
			new: make n
			copy-memory as byte-ptr! ARRAY_DATA(new) as byte-ptr! ARRAY_DATA(arr) n * size? int-ptr!
			new
		]

		copy: func [
			arr		[ptr-array!]
			return: [ptr-array!]
			/local
				new [ptr-array!]
		][
			new: make arr/length
			copy-memory as byte-ptr! ARRAY_DATA(new) as byte-ptr! ARRAY_DATA(arr) arr/length * size? int-ptr!
			new
		]

		grow: func [
			arr		[ptr-array!]
			length	[integer!]
			return: [ptr-array!]
			/local
				a	[ptr-array!]
		][
			either length > arr/length [
				a: make length
				copy-memory as byte-ptr! ARRAY_DATA(a) as byte-ptr! ARRAY_DATA(arr) arr/length * size? int-ptr!
				a
			][
				arr
			]
		]

		append: func [
			arr		[ptr-array!]
			ptr		[byte-ptr!]
			return: [ptr-array!]
			/local
				a	[ptr-array!]
				len [integer!]
				p	[ptr-ptr!]
				pp	[ptr-ptr!]
		][
			len: arr/length
			a: make len + 1
			p: ARRAY_DATA(a)
			pp: ARRAY_DATA(arr)
			loop len [
				p/value: pp/value
				p: p + 1
				pp: pp + 1
			]
			p/value: as int-ptr! ptr
			a
		]
	]

	dyn-array!: alias struct! [
		length		[integer!]
		data		[ptr-array!]
	]

	dyn-array: context [
		init: func [
			arr		[dyn-array!]
			size	[integer!]
			return: [dyn-array!]
		][
			arr/length: 0
			arr/data: ptr-array/make size
			arr
		]

		make: func [
			size	[integer!]
			return: [dyn-array!]
		][
			init as dyn-array! malloc size? dyn-array! size
		]

		clear: func [
			arr		[dyn-array!]
		][
			arr/length: 0
		]

		grow: func [
			arr		[dyn-array!]
			new-sz	[integer!]
			/local
				new-cap [integer!]
		][
			if new-sz <= arr/data/length [exit]

			new-cap: arr/data/length << 1
			if new-sz > new-cap [new-cap: new-sz]

			arr/data: ptr-array/grow arr/data new-cap
		]

		append: func [
			arr		[dyn-array!]
			ptr		[int-ptr!]
			/local
				p	[ptr-ptr!]
				len [integer!]
		][
			len: arr/length + 1
			if len > arr/data/length [
				grow arr len
			]

			arr/length: len
			p: ARRAY_DATA(arr/data) + (len - 1)
			p/value: ptr
		]

		append-n: func [
			"append N values"
			arr		[dyn-array!]
			parr	[ptr-array!]
			/local
				n	[integer!]
				p	[ptr-ptr!]
				pp	[ptr-ptr!]
		][
			n: arr/length + parr/length
			if n > arr/data/length [
				grow arr n
			]

			p: ARRAY_DATA(arr/data) + arr/length
			pp: ARRAY_DATA(parr)
			loop parr/length [
				p/value: pp/value
				p: p + 1
				pp: pp + 1
			]
			arr/length: n
		]

		to-array: func [
			arr		[dyn-array!]
			return: [ptr-array!]
		][
			ptr-array/copy-n arr/data arr/length
		]
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

	#include %utils/vector.reds
	#include %utils/mempool.reds
	#include %utils/hashmap.reds
	#include %opcode.reds
	#include %parser.reds
	#include %rst-printer.reds
	#include %op-cache.reds
	#include %config.reds
	#include %type-checker.reds
	#include %ir-graph.reds
	#include %lowering.reds

	_mempool: as mempool! 0

	src-blk: as red-block! 0
	cur-blk: as red-block! 0
	script: as cell! 0

	ir-module: as ir-module! 0

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

	comp-fn: func [
		fn		[fn!]
		parent	[context!]
		f-ctx	[context!]
		return: [context!]
		/local
			src	[red-block!]
			ctx [context!]
			ir	[ir-fn!]
	][
		src: fn/body
		src-blk: src
		probe "parse"
		ctx: parser/parse-context fn/token src parent f-ctx
		probe "check"
		type-checker/check ctx
		probe "print RST"
		rst-printer/print-program ctx
		probe "generate SSA"
		ir: ir-graph/generate fn ctx
		vector/append-ptr ir-module/functions as byte-ptr! ir
		probe "Lowering SSA"
		lowering/do-fn ir
		probe "SSA to machine code"
		ctx
	]

	init-func-ctx: func [
		ctx			[context!]
		fn			[fn!]
		/local
			ft		[fn-type!]
			var		[var-decl!]
			ssa		[ssa-var!]
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
			if NODE_TYPE(fn) = RST_FUNC [
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

	comp-dialect: func [
		src			[red-block!]
		job			[red-object!]
		/local
			ctx 	[context!]
			fn		[fn! value]
	][
		script: object/rs-select job as cell! word/load "script"
		ir-module: as ir-module! malloc size? ir-module!
		ir-module/functions: vector/make size? int-ptr! 100

		fn/token: null
		fn/body: src
		fn/type: as rst-type! op-cache/void-op
		ctx: comp-fn :fn null null
		comp-functions ctx
	]

	init: does [
		_mempool: mempool/make
		empty-array: ptr-array/make 0

		common-literals/init
		parser/init
		op-cache/init
		type-system/init

		config/int-type: type-system/get-int-type config/int-width false
	]

	clean: does [
		mempool/destroy _mempool
		if ir-printer/blocks <> null [
			vector/destroy ir-printer/blocks
		]
	]
]