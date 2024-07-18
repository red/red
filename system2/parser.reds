Red/System [
	File: 	 %parser.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define VISITOR_FUNC(name) [name [visit-fn!]]

visitor!: alias struct! [
	VISITOR_FUNC(visit-if)
	VISITOR_FUNC(visit-while)
	VISITOR_FUNC(visit-func)
]

#define ACCEPT_FN_SPEC [self [int-ptr!] v [visitor!] data [int-ptr!] return: [int-ptr!]]

accept-fn!: alias function! [ACCEPT_FN_SPEC]
visit-fn!: alias function! [node [int-ptr!] data [int-ptr!] return: [int-ptr!]]

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

#define SET_TYPE_KIND(node kind) [node/header: node/header and FFFFFF00h or kind]
#define TYPE_KIND(node) (node/header and FFh)
#define SET_TYPE_FLAGS(node flags) [node/header: node/header and FFh or (flags << 8)]

#define SET_RST_TYPE(node type) [node/header: node/header and FFFFFF00h or type]
#define RST_TYPE(node) (node/header and FFh)

parser: context [
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

	error-TBD: does [
		probe "Parse Error: TBD"
		halt
	]

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

	var-decl!: alias struct! [	;-- variable declaration
		RST_NODE(var-decl!)
		typeref	[red-block!]
		type		[int-ptr!]
		init		[int-ptr!]	;-- init expression
	]

	member!: alias struct! [
		RST_NODE(member!)
	]

	context!: alias struct! [
		RST_NODE(context!)
		parent		[context!]
		members		[member!]
		decls		[node!]
	]

	fn!: alias struct! [
		RST_EXPR(fn!)
		parent		[context!]
		spec		[red-block!]
		body		[red-block!]
		locals		[var-decl!]
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
	#define STRING?(v) [TYPE_OF(v) = TYPE_STRING]
	#define BLOCK?(v) [TYPE_OF(v) = TYPE_BLOCK]
	#define PAREN?(V) [TYPE_OF(v) = TYPE_PAREN]

	k_func:		symbol/make "func"
	k_function:	symbol/make "function"
	k_alias:	symbol/make "alias"
	k_context:	symbol/make "context"
	k_if:		symbol/make "if"
	k_either:	symbol/make "either"
	k_while:	symbol/make "while"
	k_until:	symbol/make "until"
	k_loop:		symbol/make "loop"
	k_case:		symbol/make "case"
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

	make-ctx: func [
		name	[red-value!]
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
		ctx/decls: hashmap/make sz
		SET_RST_TYPE(ctx RST_CONTEXT)
		if parent <> null [
			parent/next: ctx
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

	parse-expr: func [
		pc		[red-value!]
		end		[red-value!]
		ctx		[context!]
		return: [red-value!]
		/local
			sym [integer!]
			w	[red-word!]
	][
		if WORD?(pc) [
			w: as red-word! pc
			sym: symbol/resolve w/symbol
			case [
				sym = k_if [0]
				sym = k_either [0]
			]
		]
		pc
	]

	parse-assignment: func [
		pc		[red-value!]
		end		[red-value!]
		ctx		[context!]
		return: [red-value!]
		/local
			pc2 [red-value!]
	][
		pc2: peek-next pc end

		pc
	]

	parse-code: func [
		pc		[red-value!]
		end		[red-value!]
		ctx		[context!]
		return: [red-value!]
	][
		either SET_WORD?(pc) [
			parse-assignment pc end ctx
		][
			parse-expr pc end ctx
		]
	]

	parse-issue: func [
		pc		[red-value!]
		end		[red-value!]
		ctx		[context!]
		return: [red-value!]
	][
		pc
	]

	add-decl: func [
		ctx		[context!]
		name	[red-value!]
		decl	[int-ptr!]
		return: [logic!]		;-- false if already exist
		/local
			key [red-value!]
			val [red-value!]
	][
		true
	]

	parse-context: func [
		name	[red-value!]
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
	][
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
							pc2: expect-next pc2 end TYPE_BLOCK
							parse-context pc as red-block! pc2 ctx func?
							pc2 + 1
						]
						true [parse-assignment pc end ctx]
					]
				]
				ISSUE?(pc) [parse-issue pc end ctx]
				true [parse-code pc end ctx]
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
		as cell! body + 1
	]
]