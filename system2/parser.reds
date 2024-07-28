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
#define KEYWORD_FN_SPEC [
	pc		[cell!]
	end		[cell!]
	expr	[ptr-ptr!]	;-- a pointer to receive the expr
	ctx		[context!]
	return: [cell!]
]

accept-fn!: alias function! [ACCEPT_FN_SPEC]
visit-fn!: alias function! [VISIT_FN_SPEC]
keyword-fn!: alias function! [KEYWORD_FN_SPEC]

#enum rst-op! [		;@@ order matters
	RST_OP_ADD
	RST_OP_SUB
	RST_OP_MUL
	RST_OP_DIV
	RST_OP_MOD
	RST_OP_REM
	RST_OP_AND
	RST_OP_OR
	RST_OP_XOR
	RST_OP_SHL
	RST_OP_SAR
	RST_OP_SHR
	RST_OP_EQ
	RST_OP_NE
	RST_OP_LT
	RST_OP_LTEQ
	RST_OP_GT
	RST_OP_GTEQ
	RST_OP_SIZE
	;-- sugar ops
	RST_MIXED_EQ	;-- e.g. compare int with uint
	RST_MIXED_NE
	RST_MIXED_LT
	RST_MIXED_LTEQ
]

#enum rst-type-kind! [
	RST_TYPE_VOID
	RST_TYPE_LOGIC
	RST_TYPE_INT
	RST_TYPE_BYTE
	RST_TYPE_FLOAT
	RST_TYPE_C_STR
	RST_TYPE_FUNC
	RST_TYPE_STRUCT
	RST_TYPE_ARRAY
	RST_TYPE_PTR
]

#enum rst-node-type! [
	RST_VOID
	RST_LOGIC
	RST_INT
	RST_BYTE
	RST_FLOAT
	RST_PTR
	RST_NULL
	RST_C_STR
	RST_BYTE_PTR
	RST_INT_PTR
	RST_BINARY
	RST_LIT_ARRAY		;-- literal array
	RST_BIN_OP
	RST_DECLARE
	RST_NOT
	RST_SIZEOF
	RST_FN_CALL
	RST_VAR
	RST_EITHER
	RST_EXPR_END		;-- end marker of expr types
	RST_CONTEXT
	RST_FUNC
	RST_VAR_DECL
	RST_IF
	RST_WHILE
	RST_ASSIGN
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
	RST_FN_CTX:		1
	RST_INFIX_FN:	2
	RST_INFIX_OP:	4
]

#define SET_TYPE_KIND(node kind) [node/header: node/header and FFFFFF00h or kind]
#define TYPE_KIND(node) (node/header and FFh)
#define SET_TYPE_FLAGS(node flags) [node/header: node/header and FFh or (flags << 8)]
#define TYPE_FLAGS(node) (node/header >> 8 and FFh)

#define SET_NODE_TYPE(node type) [node/header: node/header and FFFFFF00h or type]
#define SET_NODE_FLAGS(node flags) [node/header: node/header and FFh or (flags << 8)]
#define NODE_TYPE(node) (node/header and FFh)
#define NODE_FLAGS(node) (node/header >> 8 and FFh)

#define RST_NODE(self) [	;-- RST: R/S Syntax Tree
	header	[integer!]		;-- rst-node-type! bits: 0 - 7
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
	cast-type	[rst-type!]
	type		[rst-type!]
]

#define TYPE_HEADER [
	header		[integer!]		;-- Kind and flags
	token		[cell!]
]

rst-type!: alias struct! [
	TYPE_HEADER
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
	type		[rst-type!]
	init		[rst-expr!]	;-- init expression
]

variable!: alias struct! [
	RST_EXPR(variable!)
	decl		[var-decl!]
]

context!: alias struct! [
	RST_NODE(context!)
	parent		[context!]
	child		[context!]
	stmts		[rst-stmt!]
	last-stmt	[rst-stmt!]
	decls		[int-ptr!]
	typecache	[int-ptr!]
	src-blk		[red-block!]
	script		[cell!]
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
	target		[variable!]
	expr		[rst-expr!]
]

bin-op!: alias struct! [
	RST_EXPR(bin-op!)
	op			[int-ptr!]
	op-type		[fn-type!]
	left		[rst-expr!]
	right		[rst-expr!]
]

literal!: alias struct! [
	RST_EXPR(literal!)
]

logic-literal!: alias struct! [
	RST_EXPR(literal!)
	value		[logic!]
]

int-literal!: alias struct! [
	RST_EXPR(int-literal!)
	value		[integer!]
]

float-literal!: alias struct! [
	RST_EXPR(float-literal!)
	value		[float!]
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

#include %type-system.reds

parser: context [
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

	k_+:			symbol/make "+"
	k_-:			symbol/make "-"
	k_=:			symbol/make "="
	k_>=:			symbol/make ">="
	k_>:			symbol/make ">"
	k_>>:			symbol/make ">>"
	k_>>>:			symbol/make ">>>"
	k_less:			symbol/make "<"
	k_less_eq:		symbol/make "<="
	k_not_eq:		symbol/make "<>"
	k_slash:		symbol/make "/"
	k_dbl_slash:	symbol/make "//"
	k_percent:		symbol/make "%"
	k_star:			symbol/make "*"	

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

	keywords:  as int-ptr! 0
	infix-Ops: as int-ptr! 0

	init: does [
		keywords: hashmap/make 300
		infix-Ops: hashmap/make 100
		hashmap/put infix-Ops k_+			as int-ptr! RST_OP_ADD
		hashmap/put infix-Ops k_-			as int-ptr! RST_OP_SUB
		hashmap/put infix-Ops k_=			as int-ptr! RST_OP_EQ
		hashmap/put infix-Ops k_>=			as int-ptr! RST_OP_GTEQ
		hashmap/put infix-Ops k_>			as int-ptr! RST_OP_GT
		hashmap/put infix-Ops k_>>			as int-ptr! RST_OP_SAR
		hashmap/put infix-Ops k_>>>			as int-ptr! RST_OP_SHR
		hashmap/put infix-Ops k_less		as int-ptr! RST_OP_LT
		hashmap/put infix-Ops k_less_eq		as int-ptr! RST_OP_LTEQ
		hashmap/put infix-Ops k_not_eq		as int-ptr! RST_OP_NE
		hashmap/put infix-Ops k_slash		as int-ptr! RST_OP_DIV
		hashmap/put infix-Ops k_dbl_slash	as int-ptr! RST_OP_MOD
		hashmap/put infix-Ops k_percent		as int-ptr! RST_OP_REM
		hashmap/put infix-Ops k_star		as int-ptr! RST_OP_MUL

		hashmap/put keywords k_any		null
        hashmap/put keywords k_all		null
        hashmap/put keywords k_as		null
        hashmap/put keywords k_declare	null
        hashmap/put keywords k_size?	null
        hashmap/put keywords k_not		null
        hashmap/put keywords k_null		null
        hashmap/put keywords k_if		null
        hashmap/put keywords k_either	null
        hashmap/put keywords k_while	null
        hashmap/put keywords k_until	null
        hashmap/put keywords k_loop		null
        hashmap/put keywords k_case		null
        hashmap/put keywords k_switch	null
        hashmap/put keywords k_continue	null
        hashmap/put keywords k_break	null
        hashmap/put keywords k_throw	null
        hashmap/put keywords k_catch	null
        hashmap/put keywords k_return	null
        hashmap/put keywords k_exit		null
        hashmap/put keywords k_assert	null
        hashmap/put keywords k_comment	null
        hashmap/put keywords k_with		null
        hashmap/put keywords k_use		null
        hashmap/put keywords k_true		as int-ptr! :parse-logic
        hashmap/put keywords k_false	as int-ptr! :parse-logic
	]

	advance: func [
		pc		[cell!]
		end		[cell!]
		idx		[integer!]
		return: [cell!]
	][
		pc: pc + idx
		if pc >= end [
			throw-error [pc - 1 "EOF: expect mroe code"]
		]
		pc
	]

	advance-next: func [
		pc		[cell!]
		end		[cell!]
		return: [cell!]
	][
		pc: pc + 1
		if pc >= end [
			throw-error [pc - 1 "EOF: expect more code"]
		]
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

	unreachable: func [pc [cell!]][
		throw-error [pc "Should not reach here!!!"]
	]

	make-params: func [
		ltype	[rst-type!]
		rtype	[rst-type!]
		return: [ptr-ptr!]
		/local
			pt	[ptr-ptr!]
			t2	[ptr-ptr!]
	][
		pt: as ptr-ptr! malloc 2 * size? int-ptr!
		pt/value: as int-ptr! ltype
		t2: pt + 1
		t2/value: as int-ptr! rtype
		pt
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
		SET_NODE_TYPE(ctx RST_CONTEXT)
		if parent <> null [
			ctx/next: parent/child
			parent/child: ctx
		]
		ctx/src-blk: src-blk
		ctx/script: script
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
		SET_NODE_TYPE(f RST_FUNC)
		f
	]

	make-bin-op: func [
		op		[int-ptr!]
		left	[rst-expr!]
		right	[rst-expr!]
		pos		[cell!]
		return: [bin-op!]
		/local
			b	[bin-op!]
	][
		bin_accept: func [ACCEPT_FN_SPEC][
			v/visit-bin-op self data
		]
		b: as bin-op! malloc size? bin-op!
		b/token: pos
		b/op: op
		b/left: left
		b/right: right
		b/accept: :bin_accept
		SET_NODE_TYPE(b RST_BIN_OP)
		b
	]

	make-int: func [
		pos		[cell!]
		return: [int-literal!]
		/local
			int [int-literal!]
			i	[red-integer!]
	][
		i: as red-integer! pos
		int_accept: func [ACCEPT_FN_SPEC][
			v/visit-literal self data
		]
		int: as int-literal! malloc size? int-literal!
		SET_NODE_TYPE(int RST_INT)
		int/token: pos
		int/value: i/value
		int/accept: :int_accept
		int/type: as rst-type! type-system/integer-type
		int
	]

	make-float: func [
		pos		[cell!]
		return: [float-literal!]
		/local
			f		[float-literal!]
			float	[red-float!]
	][
		float: as red-float! pos
		float_accept: func [ACCEPT_FN_SPEC][
			v/visit-literal self data
		]
		f: as float-literal! malloc size? float-literal!
		SET_NODE_TYPE(f RST_INT)
		f/token: pos
		f/value: float/value
		f/accept: :float_accept
		f/type: as rst-type! type-system/float-type
		f
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
		SET_NODE_TYPE(assign RST_ASSIGN)
		assign/token: pos
		assign/target: make-variable target pos
		assign/expr: expr
		assign/accept: :assign_accept
		assign
	]

	make-var-decl: func [
		name	[cell!]
		typeref	[red-block!]
		list	[var-decl!]
		return: [var-decl!]
		/local
			var [var-decl!]
	][
		var: as var-decl! malloc size? var-decl!
		SET_NODE_TYPE(var RST_VAR_DECL)
		var/token: name
		var/typeref: typeref
		var/next: list/next
		list/next: var
		var
	]

	make-variable: func [
		decl	[var-decl!]
		pos		[cell!]
		return: [variable!]
		/local
			var [variable!]
	][
		var: as variable! malloc size? variable!
		SET_NODE_TYPE(var RST_VAR)
		var_accept: func [ACCEPT_FN_SPEC][
			v/visit-var self data
		]
		var/accept: :var_accept
		var/token: pos
		var/decl: decl
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

	parse-logic: func [
		;pc end expr ctx
		KEYWORD_FN_SPEC
		/local
			b	[logic-literal!]
			bl	[red-logic!]
	][
		bl: as red-logic! pc
		b: as logic-literal! malloc size? logic-literal!
		b_accept: func [ACCEPT_FN_SPEC][
			v/visit-literal self data
		]
		SET_NODE_TYPE(b RST_LOGIC)
		b/token: pc
		b/value: bl/value
		b/accept: :b_accept
		b/type: type-system/logic-type

		expr/value: as int-ptr! b
		pc
	]

	parse-sub-expr: func [
		pc		[cell!]
		end		[cell!]
		expr	[ptr-ptr!]	;-- a pointer to receive the expr
		ctx		[context!]
		return: [cell!]
		/local
			sym [integer!]
			w	[red-word!]
			p	[ptr-ptr!]
			v	[rst-node!]
			parse-keyword [keyword-fn!]
	][
		switch TYPE_OF(pc) [
			TYPE_WORD [
				w: as red-word! pc
				sym: symbol/resolve w/symbol
				p: hashmap/get ctx/decls sym
				either p <> null [
					v: as rst-node! p/value
					switch NODE_TYPE(v) [
						RST_FUNC		[parse-call pc end ctx]
						RST_VAR_DECL	[expr/value: as int-ptr! make-variable as var-decl! v pc]
						default			[unreachable pc]
					]
				][
					p: hashmap/get keywords sym
					either p <> null [		;-- keyword
						parse-keyword: as keyword-fn! p/value
						pc: parse-keyword pc end expr ctx
					][
						throw-error [pc "undefined symbol:" w]
					]
				]
			]
			TYPE_INTEGER [
				expr/value: as int-ptr! make-int pc
			]
			TYPE_FLOAT [
				expr/value: as int-ptr! make-float pc
			]
			TYPE_GET_WORD [0]
			TYPE_PATH [0]
			TYPE_GET_PATH [0]
			TYPE_ISSUE [
				w: as red-word! pc
				sym: symbol/resolve w/symbol
				case [
					sym = k_get [0]
					sym = k_in [0]
					sym = k_u16 [0]
					true [throw-error [pc "unknown directive:" w]]
				]
			]
			default [0]
		]
		pc + 1
	]

	parse-infix-op: func [
		pc		[cell!]
		end		[cell!]
		expr	[ptr-ptr!]
		ctx		[context!]
		return: [cell!]
		/local
			w		[red-word!]
			infix?	[logic!]
			ptr		[ptr-ptr!]
			sym		[integer!]
			node	[rst-expr!]
			type	[rst-node-type!]
			t		[rst-type!]
			flag	[integer!]
			bin		[bin-op!]
			left	[rst-expr!]
			right	[ptr-value!]
			pos		[cell!]
			op		[int-ptr!]
			val		[ptr-ptr!]
	][
		left: as rst-expr! expr/value
		while [all [pc < end WORD?(pc)]][
			flag: 0
			infix?: no
			w: as red-word! pc
			sym: symbol/resolve w/symbol
			val: hashmap/get infix-Ops sym
			either null <> val [
				infix?: yes
				flag: RST_INFIX_OP
				op: val/value
			][
				node: as rst-expr! find-var w ctx
				either node <> null [
					type: NODE_TYPE(node)
					if any [type = RST_VAR_DECL type = RST_FUNC][
						t: node/type
						if all [t <> null TYPE_FLAGS(t) and FN_INFIX <> 0][
							infix?: yes
							flag: RST_INFIX_FN
							op: as int-ptr! t
						]
					]
				][
					throw-error [pc "undefined symbol:" w]
				]
			]
			either infix? [
				pos: pc
				pc: parse-sub-expr advance-next pc end end :right ctx
				bin: make-bin-op op left as rst-expr! right/value pos
				SET_NODE_FLAGS(bin flag)
				left: as rst-expr! bin
			][break]
		]
		expr/value: as int-ptr! left
		pc
	]

	parse-expr: func [
		pc		[cell!]
		end		[cell!]
		expr	[ptr-ptr!]	;-- a pointer to receive the expr
		ctx		[context!]
		return: [cell!]
	][
		pc: parse-sub-expr pc end expr ctx
		if all [pc < end WORD?(pc)][
			pc: parse-infix-op pc end expr ctx
		]
		pc
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
				flags: NODE_FLAGS(ctx)
				either flags and RST_FN_CTX <> 0 [
					if any [null? var NODE_TYPE(var) <> RST_VAR_DECL][
						throw-error [pc "undefined symbol:" pc]
					]
				][
					if null? var [
						list/next: null
						var: make-var-decl pc null list
						add-decl ctx pc as int-ptr! var
						pc: parse-assignment advance-next pc end end out ctx
						var/init: as rst-expr! out/value
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
			pc: parse-assignment advance-next pc end end out ctx
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
		switch TYPE_OF(pc) [
			TYPE_WORD [pc: parse-expr pc end :ptr ctx]
			TYPE_ISSUE [
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
			default [
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
			switch TYPE_OF(pc) [
				TYPE_SET_WORD [
					pc2: advance-next pc end
					pc: either WORD?(pc2) [
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
					][
						parse-assignment pc end :ptr ctx
					]
				]
				TYPE_ISSUE [pc: parse-directive pc end ctx]
				default [pc: parse-statement pc end ctx]
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
					sym = k_infix	 [FN_INFIX]
					sym = k_custom	 [FN_CUSTOM]
					true [
						throw-error [p "unknown func attribute:" p]
						0
					]
				]
			][
				throw-error [p "invalid func attribute:" p]
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
					if zero? n [throw-error [p "missing locals"]]
					t: p - 1
					until [
						if WORD?(t) [
							make-var-decl t as red-block! p list
						]
						t: t - 1
						n: n - 1
						zero? n
					]
				]
				true [throw-error [p "invalid locals:" p]]
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
		SET_TYPE_KIND(ft RST_TYPE_FUNC)

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
					make-var-decl p as red-block! p2 list
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
				true [throw-error [w "invalid func spec" w]]
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
		body: as red-block! advance pc end 3
		spec: body - 1
		fn/body: body
		fn/spec: spec
		fn/type: as rst-type! parse-fn-spec spec fn

		unless add-decl ctx pc as int-ptr! fn [
			throw-error [pc "symbol name is already defined"]
		]
		as cell! body + 1
	]
]