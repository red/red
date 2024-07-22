Red/System [
	File: 	 %parser.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define VISITOR_FUNC(name) [name [visit-fn!]]

visitor!: alias struct! [
	VISITOR_FUNC(visit-if)
	VISITOR_FUNC(visit-either)
	VISITOR_FUNC(visit-case)
	VISITOR_FUNC(visit-switch)
	VISITOR_FUNC(visit-loop)
	VISITOR_FUNC(visit-while)
	VISITOR_FUNC(visit-until)
	VISITOR_FUNC(visit-func)
	VISITOR_FUNC(visit-break)
	VISITOR_FUNC(visit-continue)
	VISITOR_FUNC(visit-return)
	VISITOR_FUNC(visit-exit)
	VISITOR_FUNC(visit-fn-call)
	VISITOR_FUNC(visit-assign)
	VISITOR_FUNC(visit-bin-op)
	VISITOR_FUNC(visit-var)
	VISITOR_FUNC(visit-string)
	VISITOR_FUNC(visit-array)
	VISITOR_FUNC(visit-literal)
]

#define ACCEPT_FN_SPEC [self [int-ptr!] v [visitor!] data [int-ptr!] return: [int-ptr!]]
#define VISIT_FN_SPEC [node [int-ptr!] data [int-ptr!] return: [int-ptr!]]

accept-fn!: alias function! [ACCEPT_FN_SPEC]
visit-fn!: alias function! [VISIT_FN_SPEC]

#enum type-kind! [
	TYPE_VOID
	TYPE_LOGIC
	TYPE_INT
	TYPE_FLOAT
	TYPE_ARRAY
	TYPE_STRUCT
	TYPE_FUNC
	TYPE_POINTER
	TYPE_NULL
]

#enum rst-type! [
	RST_VAR
	RST_CONTEXT
	RST_FUNC
	RST_IF
	RST_EITHER
	RST_WHILE
	RST_ASSIGN
	RST_INT
	RST_FLOAT
	RST_STRING
	RST_BYTE
	RST_LOGIC
	RST_BINARY
	RST_LIT_ARRAY		;-- literal array
	RST_DECLARE
	RST_NOT
	RST_SIZEOF
	RST_FN_CALL
]

#enum fn-attr! [
	FN_CC_STDCALL:		1
	FN_CC_CDECL:		2
	FN_INFIX:			4
	FN_CALLBACK:		8
	FN_VARIADIC:		10h
	FN_TYPED:			20h
	FN_CUSTOM:			40h
	FN_CATCH:			80h
	FN_EXTERN:			0100h
]

#enum rst-node-flag! [
	RST_FLAG_FN_CTX:	1
]

#define SET_TYPE_KIND(node kind) [node/header: node/header and FFFFFF00h or kind]
#define TYPE_KIND(node) (node/header and FFh)
#define SET_TYPE_FLAGS(node flags) [node/header: node/header and FFh or (flags << 8)]

#define SET_RST_TYPE(node type) [node/header: node/header and FFFFFF00h or type]
#define RST_TYPE(node) (node/header and FFh)
#define RST_FLAGS(node) (node/header and FFh >> 8)


#define RST_NODE(self) [	;-- RST: R/S Syntax Tree
	header	[integer!]		;-- rst-type! bits: 0 - 8
	next	[self]
	token	[cell!]
]

#define RST_STMT(self) [
	RST_NODE(self)
	accept	[accept-fn!]
]

#define RST_EXPR(self) [
	RST_NODE(self)
	accept		[accept-fn!]
	type		[int-ptr!]
	exact-type	[int-ptr!]
]

rst-node!: alias struct! [
	RST_NODE(int-ptr!)
]

rst-stmt!: alias struct! [
	RST_STMT(rst-stmt!)
]

rst-expr!: alias struct! [
	RST_EXPR(rst-expr!)
]

var-decl!: alias struct! [	;-- variable declaration
	RST_NODE(var-decl!)
	typeref		[red-block!]
	type		[int-ptr!]
	init		[int-ptr!]	;-- init expression
]

context!: alias struct! [
	RST_NODE(context!)
	parent		[context!]
	child		[context!]
	stmts		[rst-stmt!]
	last-stmt	[rst-stmt!]
	decls		[int-ptr!]
]

fn!: alias struct! [
	RST_EXPR(fn!)
	parent		[context!]
	spec		[red-block!]
	body		[red-block!]
	locals		[var-decl!]
]

assignment!: alias struct! [
	RST_EXPR(assignment!)
	target		[var-decl!]
	expr		[rst-expr!]
]

bin-expr!: alias struct! [
	RST_EXPR(bin-expr!)
	left		[rst-expr!]
	right		[rst-expr!]
]

int-literal!: alias struct! [
	RST_EXPR(int-literal!)
	value		[integer!]
]

#define TYPE_HEADER [
	header		[integer!]		;-- Kind and flags
	token		[cell!]
]

fn-type!: alias struct! [
	TYPE_HEADER
	n-params	[integer!]
	params		[var-decl!]
	ret-typeref [red-block!]
	ret-type	[int-ptr!]
]

#define WORD?(v) [TYPE_OF(v) = TYPE_WORD]
#define SET_WORD?(v) [TYPE_OF(v) = TYPE_SET_WORD]
#define GET_WORD?(v) [TYPE_OF(v) = TYPE_GET_WORD]
#define PATH?(v) [TYPE_OF(v) = TYPE_PATH]
#define SET_PATH?(v) [TYPE_OF(v) = TYPE_SET_PATH]
#define GET_PATH?(v) [TYPE_OF(v) = TYPE_GET_PATH]
#define REFINEMENT?(v) [TYPE_OF(v) = TYPE_REFINEMENT]
#define ISSUE?(v) [TYPE_OF(v) = TYPE_ISSUE]
#define FLOAT?(v) [TYPE_OF(v) = TYPE_FLOAT]
#define INTEGER?(v) [TYPE_OF(v) = TYPE_INTEGER]
#define CHAR?(v) [TYPE_OF(v) = TYPE_CHAR]
#define BINARY?(v) [TYPE_OF(v) = TYPE_BINARY]
#define STRING?(v) [TYPE_OF(v) = TYPE_STRING]
#define BLOCK?(v) [TYPE_OF(v) = TYPE_BLOCK]
#define PAREN?(V) [TYPE_OF(v) = TYPE_PAREN]

parser: context [
	src-blk: as red-block! 0
	script: as cell! 0

	k_func:		symbol/make "func"
	k_function:	symbol/make "function"
	k_alias:	symbol/make "alias"
	k_context:	symbol/make "context"
	k_any:		symbol/make "any"
	k_all:		symbol/make "all"
	k_as:		symbol/make "as"
	k_declare:	symbol/make "declare"
	k_size?:	symbol/make "size?"
	k_not:		symbol/make "not"
	k_null:		symbol/make "null"
	k_if:		symbol/make "if"
	k_either:	symbol/make "either"
	k_while:	symbol/make "while"
	k_until:	symbol/make "until"
	k_loop:		symbol/make "loop"
	k_case:		symbol/make "case"
	k_switch:	symbol/make "switch"
	k_continue:	symbol/make "continue"
	k_break:	symbol/make "break"
	k_throw:	symbol/make "throw"
	k_catch:	symbol/make "catch"
	k_variadic:	symbol/make "variadic"
	k_stdcall:	symbol/make "stdcall"
	k_cdecl:	symbol/make "cdecl"
	k_infix:	symbol/make "infix"
	k_typed:	symbol/make "typed"
	k_custom:	symbol/make "custom"
	k_return:	symbol/make "return"
	k_exit:		symbol/make "exit"
	k_local:	symbol/make "local"
	k_assert:	symbol/make "assert"
	k_comment:	symbol/make "comment"
	k_with:		symbol/make "with"
	k_use:		symbol/make "use"
	k_true:		symbol/make "true"
	k_false:	symbol/make "false"

	;-- issue directives
	k_import:		symbol/make "import"
	k_export:		symbol/make "export"
	k_syscall:		symbol/make "syscall"
	k_call:			symbol/make "call"
	k_get:			symbol/make "get"
	k_in:			symbol/make "in"
	k_enum:			symbol/make "enum"
	k_verbose:		symbol/make "verbose"
	k_u16:			symbol/make "u16"
	k_inline:		symbol/make "inline"
	k_script:		symbol/make "script"
	k_user-code:	symbol/make "user-code"
	k_typecheck:	symbol/make "typecheck"
	k_build-date:	symbol/make "build-date"

	peek: func [
		pc		[cell!]
		end		[cell!]
		idx		[integer!]
		return: [cell!]
	][
		pc: pc + idx
		if pc >= end [probe "Parse Error: EOF" halt]
		pc
	]

	peek-next: func [
		pc		[cell!]
		end		[cell!]
		return: [cell!]
	][
		pc: pc + 1
		if pc >= end [probe "Parse Error: EOF" halt]
		pc
	]

	skip: func [
		pc		[cell!]
		end		[cell!]
		type	[integer!]
		return: [cell!]
	][
		while [
			all [pc < end TYPE_OF(pc) = TYPE]
		][
			pc: pc + 1
		]
		pc
	]

	expect: func [
		pc		[cell!]
		type	[integer!]
	][
		if TYPE_OF(pc) <> type [
			probe ["Parse Error: Expect " type " type"]
			halt
		]
	]

	expect-next: func [
		pc		[cell!]
		end		[cell!]
		type	[integer!]
		return: [cell!]
	][
		pc: pc + 1
		if pc >= end [probe "Parse Error: EOF" halt]
		if TYPE_OF(pc) <> type [
			probe ["Parse Error: Expect " type " type"]
			halt
		]
		pc
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
		header: block/rs-abs-at src-blk 0
		beg: block/rs-head src-blk
		idx: (as-integer pc - beg) >> 4 + 1
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

	error-TBD: does [probe "Error TBD" halt]

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
		
		prin "*** Parse Error: "
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
		p: block/rs-head src-blk
		h: src-blk/head
		src-blk/head: (as-integer pc - p) >> 4 + h
		print "*** near: " #call [prin-block src-blk 200]
		src-blk/head: h
		print "^/"
		quit 1
	]

	make-ctx: func [
		name	[cell!]
		parent	[context!]
		func?	[logic!]
		return: [context!]
		/local
			ctx [context!]
			sz	[integer!]
	][
		sz: either func? [100][1000]
		ctx: as context! malloc size? context!
		ctx/token: name
		ctx/parent: parent
		ctx/stmts: as rst-stmt! malloc size? rst-stmt!	;-- stmt head
		ctx/last-stmt: ctx/stmts
		ctx/decls: hashmap/make sz
		SET_RST_TYPE(ctx RST_CONTEXT)
		if parent <> null [
			ctx/next: parent/child
			parent/child: ctx
		]
		ctx
	]

	make-func: func [
		name	[cell!]
		parent	[context!]
		return: [fn!]
		/local
			f	[fn!]
	][
		func_accept: func [ACCEPT_FN_SPEC][
			v/visit-func self data
		]
		f: as fn! malloc size? fn!
		f/token: name
		f/parent: parent
		f/accept: :func_accept
		SET_RST_TYPE(f RST_FUNC)
		f
	]

	make-int: func [
		value	[integer!]
		pos		[cell!]
		return: [int-literal!]
		/local
			int [int-literal!]
	][
		int_accept: func [ACCEPT_FN_SPEC][
			v/visit-literal self data
		]
		int: as int-literal! malloc size? int-literal!
		SET_RST_TYPE(int RST_INT)
		int/token: pos
		int/value: value
		int/accept: :int_accept
		int
	]

	make-assignment: func [
		target	[var-decl!]
		expr	[rst-expr!]
		pos		[cell!]
		return: [assignment!]
		/local
			assign [assignment!]
	][
		assign_accept: func [ACCEPT_FN_SPEC][
			v/visit-assign self data
		]
		assign: as assignment! malloc size? assignment!
		SET_RST_TYPE(assign RST_ASSIGN)
		assign/token: pos
		assign/target: target
		assign/expr: expr
		assign/accept: :assign_accept
		assign
	]

	make-variable: func [
		name	[cell!]
		typeref	[red-block!]
		list	[var-decl!]
		return: [var-decl!]
		/local
			var [var-decl!]
	][
		var: as var-decl! malloc size? var-decl!
		SET_RST_TYPE(var RST_VAR)
		var/token: name
		var/typeref: typeref
		var/next: list/next
		list/next: var
		var
	]

	parse-call: func [
		pc		[cell!]
		end		[cell!]
		ctx		[context!]
		return: [cell!]
	][
		pc
	]

	parse-expr: func [
		pc		[cell!]
		end		[cell!]
		expr	[ptr-ptr!]	;-- a pointer to receive the expr
		ctx		[context!]
		return: [cell!]
		/local
			sym [integer!]
			w	[red-word!]
			int [red-integer!]
			p	[ptr-ptr!]
			v	[rst-node!]
	][
		case [
			WORD?(pc) [
				w: as red-word! pc
				sym: symbol/resolve w/symbol
				p: hashmap/get ctx/decls sym
				either p <> null [
					v: as rst-node! p/value
					switch RST_TYPE(v) [
						RST_FUNC	[parse-call pc end ctx]
						RST_VAR		[0]
						default		[error-TBD]	;TBD unreachale
					]
				][
					case [
						sym = k_either [0]
						sym = k_case [0]
						sym = k_switch [0]
						sym = k_as [0]
						sym = k_any [0]
						sym = k_all [0]
						sym = k_declare [0]
						sym = k_size? [0]
						sym = k_null [0]
						sym = k_true [0]
						sym = k_false [0]
						true [error-TBD]	;TBD unreachale
					]
				]
			]
			INTEGER?(pc) [
				int: as red-integer! pc
				expr/value: as int-ptr! make-int int/value pc
			]
			FLOAT?(pc) [0]
			GET_WORD?(pc) [0]
			PATH?(pc) [0]
			GET_PATH?(pc) [0]
			ISSUE?(pc) [
				w: as red-word! pc
				sym: symbol/resolve w/symbol
				case [
					sym = k_get [0]
					sym = k_in [0]
					sym = k_u16 [0]
					true [error-TBD]	;TBD error
				]
			]
		]
		pc + 1
	]

	find-var: func [
		name	[red-word!]
		ctx		[context!]
		return: [var-decl!]
		/local
			sym [integer!]
			val [ptr-ptr!]
	][
		sym: symbol/resolve name/symbol
		until [
			val: hashmap/get ctx/decls sym
			ctx: ctx/parent
			any [null? ctx val <> null]
		]
		either val <> null [
			as var-decl! val/value
		][null]
	]

	parse-assignment: func [
		pc		[cell!]
		end		[cell!]
		out		[ptr-ptr!]
		ctx		[context!]
		return: [cell!]
		/local
			var		[var-decl!]
			flags	[integer!]
			list	[var-decl! value]
			set?	[logic!]
			pos		[cell!]
			s		[rst-stmt!]
	][
		var: null
		set?: yes
		case [
			SET_WORD?(pc) [
				var: find-var as red-word! pc ctx
				pos: pc
				flags: RST_FLAGS(ctx)
				either flags and RST_FLAG_FN_CTX <> 0 [
					if any [null? var RST_TYPE(var) <> RST_VAR][
						throw-error [pc "undefined symbol:" pc]
					]
				][
					if null? var [
						list/next: null
						var: make-variable pc null list
						add-decl ctx pc as int-ptr! var
						pc: parse-assignment peek-next pc end end out ctx
						var/init: out/value
						set?: no
					]
				]
			]
			SET_PATH?(pc) [0]
			true [
				set?: no
				pc: parse-expr pc end out ctx
			]
		]
		if set? [
			pc: parse-assignment peek-next pc end end out ctx
			s: as rst-stmt! make-assignment var as rst-expr! out/value pos
			ctx/last-stmt/next: s
			ctx/last-stmt: s
		]
		pc
	]

	parse-statement: func [
		pc		[cell!]
		end		[cell!]
		ctx		[context!]
		return: [cell!]
		/local
			w	[red-word!]
			sym [integer!]
			ptr [ptr-value!]
			s	[rst-stmt!]
			add? [logic!]
	][
		add?: yes
		ptr/value: null
		case [
			WORD?(pc) [
				w: as red-word! pc
				sym: symbol/resolve w/symbol
				case [
					sym = k_if [0]
					sym = k_while [0]
					sym = k_until [0]
					sym = k_loop [0]
					sym = k_continue [0]
					sym = k_break [0]
					sym = k_throw [0]
					sym = k_catch [0]
					true [pc: parse-expr pc end :ptr ctx]
				]
			]
			ISSUE?(pc) [
				w: as red-word! pc
				sym: symbol/resolve w/symbol
				case [
					sym = k_call [0]
					sym = k_typecheck [0]
					sym = k_inline [0]
					sym = k_verbose [0]
					sym = k_user-code [0]
					sym = k_build-date [0]
					true [pc: parse-expr pc end :ptr ctx]
				]
			]
			true [
				pc: parse-assignment pc end :ptr ctx
				add?: no
			]
		]
		if add? [
			assert ptr/value <> null
			s: as rst-stmt! ptr/value
			ctx/last-stmt/next: s
			ctx/last-stmt: s
		]
		pc
	]

	parse-directive: func [
		pc		[cell!]
		end		[cell!]
		ctx		[context!]
		return: [cell!]
		/local
			w	[red-word!]
			sym [integer!]
	][
		w: as red-word! pc
		sym: symbol/resolve w/symbol
		case [
			sym = k_import [0]
			sym = k_export [0]
			sym = k_syscall [0]
			sym = k_script [0]
			true [pc: parse-statement pc end ctx]
		]
		pc
	]

	add-decl: func [
		ctx		[context!]
		name	[cell!]
		decl	[int-ptr!]
		return: [logic!]		;-- false if already exist
		/local
			w	[red-word!]
			sym	[integer!]
	][
		w: as red-word! name
		sym: symbol/resolve w/symbol
		either null? hashmap/get ctx/decls sym [
			hashmap/put ctx/decls sym decl
			true
		][false]
	]

	parse-context: func [
		name	[cell!]
		src		[red-block!]
		parent	[context!]
		func?	[logic!]
		return: [context!]
		/local
			pc	[cell!]
			pc2 [cell!]
			end [cell!]
			sym [integer!]
			w	[red-word!]
			ctx [context!]
			c2	[context!]
			ptr [ptr-value!]
			saved-blk [red-block!]
	][
		src-blk: src
		ctx: make-ctx name parent func?
		pc: block/rs-head src
		end: block/rs-tail src
		while [pc < end][
			pc2: peek-next pc end
			pc: case [
				all [SET_WORD?(pc) WORD?(pc2)][
					w: as red-word! pc2
					sym: symbol/resolve w/symbol
					case [
						any [sym = k_func sym = k_function][
							fetch-func pc end ctx
						]
						sym = k_alias [
							pc2 ;fetch alias
						]
						sym = k_context [
							if func? [throw-error [pc "context has to be declared at root level"]]

							pc2: expect-next pc2 end TYPE_BLOCK
							saved-blk: src-blk
							c2: parse-context pc as red-block! pc2 ctx func?
							src-blk: saved-blk
							unless add-decl ctx pc as int-ptr! c2 [
								throw-error [pc "context name is already taken:" pc]
							]
							pc2 + 1
						]
						true [parse-assignment pc end :ptr ctx]
					]
				]
				ISSUE?(pc) [parse-directive pc end ctx]
				true [parse-statement pc end ctx]
			]
		]
		ctx
	]

	get-attributes: func [
		blk		[red-block!]
		return: [integer!]
		/local
			p	[red-word!]
			end [red-word!]
			attr [integer!]
			sym [integer!]
	][
		attr: 0
		p: as red-word! block/rs-head blk
		end: as red-word! block/rs-tail blk
		while [p < end][
			either WORD?(p) [
				sym: symbol/resolve p/symbol
				attr: attr or case [
					sym = k_cdecl	 [FN_CC_CDECL]
					sym = k_stdcall	 [FN_CC_STDCALL]
					sym = k_variadic [FN_VARIADIC]
					sym = k_typed	 [FN_TYPED]
					sym = k_custom	 [FN_CUSTOM]
					true [0]	;TBD error
				]
			][
				error-TBD ;TBD error
			]
			p: p + 1
		]
		attr
	]

	parse-local: func [
		p		[cell!]
		end		[cell!]
		fn		[fn!]
		return: [cell!]
		/local
			t	[cell!]
			n	[integer!]
			list [var-decl! value]
	][
		list/next: null
		n: 0
		while [p < end][
			case [
				any [WORD?(p) STRING?(p)][n: n + 1]
				BLOCK?(p) [
					if zero? n [error-TBD]	;TBD error
					t: p - 1
					until [
						if WORD?(t) [
							make-variable t as red-block! p list
						]
						t: t - 1
						n: n - 1
						zero? n
					]
				]
				true [error-TBD]	;TBD error
			]
			p: p + 1
		]
		if fn <> null [
			fn/locals: list/next
		]
		p
	]

	parse-fn-spec: func [
		spec	[red-block!]
		fn		[fn!]
		return: [fn-type!]
		/local
			ft	[fn-type!]
			p	[cell!]
			end [cell!]
			p2	[cell!]
			w	[red-word!]
			t s [integer!]
			list [var-decl! value]
			attr [integer!]
	][
		ft: as fn-type! malloc size? fn-type!
		SET_TYPE_KIND(ft TYPE_FUNC)

		p: block/rs-head spec
		end: block/rs-tail spec

		p: skip p end TYPE_STRING			;-- skip doc strings

		if p = end [return ft]

		if BLOCK?(p) [						;-- attributes
			attr: get-attributes as red-block! p
			SET_TYPE_FLAGS(ft attr)
			p: skip p + 1 end TYPE_STRING	;-- skip doc strings
		]

		list/next: null
		s: 0	;-- initial state
		w: as red-word! p
		while [w < as red-word! end][		;-- parse params, return: and /local
			case [
				;; param = word "[" type "]" doc-string?
				all [s = 0 WORD?(w)][
					p2: expect-next p end TYPE_BLOCK
					make-variable p as red-block! p2 list
					p: p2 + 1
					ft/n-params: ft/n-params + 1
				]
				;; return-spec = return: "[" type "]" doc-string?
				all [s < 1 SET_WORD?(w) k_return = symbol/resolve w/symbol][
					s: 1
					p: expect-next as cell! w end TYPE_BLOCK
					ft/ret-typeref: as red-block! p
					p: p + 1
				]
				;; local-var = word+ ("[" type "]")? doc-string?
				all [s < 2 REFINEMENT?(w) k_local = symbol/resolve w/symbol fn <> null][
					s: 2
					p: parse-local as cell! w + 1 end fn
				]
				true [error-TBD]	;TBD error
			]
			w: as red-word! skip p end TYPE_STRING
		]
		ft/params: list/next
		ft
	]

	fetch-func: func [
		pc		[cell!]
		end		[cell!]
		ctx		[context!]
		return: [cell!]
		/local
			fn	[fn!]
			spec [red-block!]
			body [red-block!]
	][
		fn: make-func pc ctx
		body: as red-block! peek pc end 3
		spec: body - 1
		fn/body: body
		fn/spec: spec
		fn/exact-type: as int-ptr! parse-fn-spec spec fn

		unless add-decl ctx pc as int-ptr! fn [
			error-TBD ;TBD error cannot redefine symbol
		]
		as cell! body + 1
	]
]