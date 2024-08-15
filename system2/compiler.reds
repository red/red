Red/System [
	Title:   "Red/System compiler"
	File: 	 %compiler.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

compiler: context [

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
	#include %type-checker.reds
	#include %ir-graph.reds

	_mempool: as mempool! 0

	src-blk: as red-block! 0
	cur-blk: as red-block! 0
	script: as cell! 0

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
	][
		src: fn/body
		src-blk: src
		ctx: parser/parse-context fn/token src parent f-ctx
		type-checker/check ctx
		rst-printer/print-program ctx
		ir-graph/generate fn ctx
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
	]

	clean: does [
		mempool/destroy _mempool
		if ir-printer/blocks <> null [
			vector/destroy ir-printer/blocks
		]
	]
]