Red/System [
	File: 	 %parser.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define VISITOR_FUNC(name) [name [visit-fn!]]

visitor!: alias struct! [
	VISITOR_FUNC(visit-if)
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
	RST_IF
	RST_SWITCH
	RST_CASE
	RST_ANY
	RST_ALL
	RST_ASSIGN
	RST_EXPR_END		;-- end marker of expr types
	RST_CONTEXT
	RST_FUNC
	RST_VAR_DECL
	RST_WHILE
	RST_LOOP
	RST_UNTIL
	RST_BREAK
	RST_CONTINUE
	RST_THROW
	RST_CATCH
	RST_RETURN
	RST_EXIT
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
	RST_VAR_LOCAL:	2	;-- local variable
	RST_VAR_PARAM:	4	;-- var-decl! is a parameter
	RST_FN_CTX:		8
	RST_INFIX_FN:	10h
	RST_INFIX_OP:	20h
]

#define SET_TYPE_KIND(node kind) [node/header: kind]
#define TYPE_KIND(node) (node/header and FFh)
#define ADD_TYPE_FLAGS(node flags) [node/header: node/header or (flags << 8)]
#define TYPE_FLAGS(node) (node/header >>> 8)

#define SET_NODE_TYPE(node type) [node/header: type]
#define ADD_NODE_FLAGS(node flags) [node/header: node/header or (flags << 8)]
#define NODE_TYPE(node) (node/header and FFh)
#define NODE_FLAGS(node) (node/header >>> 8)

;-- fn-type! /header bits: 8 - 15 opcode, 16 - 31: attributes
#define FN_OPCODE(f) (f/header >>> 8 and FFh)
#define FN_ATTRS(f) (f/header >>> 16)
#define ADD_FN_ATTRS(f attrs) [f/header: f/header or (attrs << 16)]
#define SET_FN_OPCODE(f op) [f/header: f/header and FFFF00FFh or (op << 8)]

#define RST_NODE_FIELDS(self) [	;-- RST: R/S Syntax Tree
	header	[integer!]		;-- rst-node-type! bits: 0 - 7
	next	[self]
	token	[cell!]
]

#define RST_STMT_FIELDS(self) [
	RST_NODE_FIELDS(self)
	accept	[accept-fn!]
]

#define RST_EXPR_FIELDS(self) [
	RST_NODE_FIELDS(self)
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
	RST_NODE_FIELDS(rst-node!)
]

rst-stmt!: alias struct! [
	RST_STMT_FIELDS(rst-stmt!)
]

rst-expr!: alias struct! [
	RST_EXPR_FIELDS(rst-expr!)
]

ssa-var!: alias struct! [
	index		[integer!]
	value		[instr!]
	loop-bset	[integer!]	;-- loop bitset, var used in loops, can encode 32 loops
	extra-bset	[ptr-array!]
]

#define LOCAL?(var) (NODE_FLAGS(var) and RST_VAR_LOCAL <> 0)

var-decl!: alias struct! [	;-- variable declaration
	RST_NODE_FIELDS(var-decl!)
	typeref		[red-block!]
	type		[rst-type!]
	init		[rst-expr!]	;-- init expression or parameter idx
	ssa			[ssa-var!]
]

variable!: alias struct! [
	RST_EXPR_FIELDS(variable!)
	decl		[var-decl!]
]

context!: alias struct! [
	RST_NODE_FIELDS(context!)
	parent		[context!]
	child		[context!]
	stmts		[rst-stmt!]
	last-stmt	[rst-stmt!]
	decls		[int-ptr!]
	ret-type	[rst-type!]
	typecache	[int-ptr!]
	n-ssa-vars	[integer!]	;-- number of variable that written more than once
	n-loops		[integer!]
	loop-stack	[vector!]
	level		[integer!]
	src-blk		[red-block!]
	script		[cell!]
]

fn!: alias struct! [
	RST_EXPR_FIELDS(fn!)
	parent		[context!]
	body		[red-block!]
	locals		[var-decl!]
	ir			[ir-fn!]
]

fn-call!: alias struct! [
	RST_EXPR_FIELDS(fn-call!)
	args		[rst-expr!]
]

assignment!: alias struct! [
	RST_EXPR_FIELDS(assignment!)
	target		[variable!]
	expr		[rst-expr!]
]

if!: alias struct! [
	RST_EXPR_FIELDS(rst-node!)
	cond		[rst-expr!]
	t-branch	[rst-stmt!]
	f-branch	[rst-stmt!]
	true-blk	[red-block!]
	false-blk	[red-block!]
]

while!: alias struct! [
	RST_STMT_FIELDS(rst-node!)
	loop-idx	[integer!]
	cond		[rst-stmt!]
	body		[rst-stmt!]
	cond-blk	[red-block!]
	body-blk	[red-block!]
]

return!: alias struct! [
	RST_STMT_FIELDS(rst-node!)
	expr		[rst-expr!]
]

continue!: alias struct! [
	RST_STMT_FIELDS(rst-node!)
]

break!: alias struct! [
	RST_STMT_FIELDS(rst-node!)
]

bin-op!: alias struct! [
	RST_EXPR_FIELDS(bin-op!)
	op			[int-ptr!]
	spec		[fn-type!]
	left		[rst-expr!]
	right		[rst-expr!]
]

literal!: alias struct! [
	RST_EXPR_FIELDS(literal!)
]

logic-literal!: alias struct! [
	RST_EXPR_FIELDS(literal!)
	value		[logic!]
]

int-literal!: alias struct! [
	RST_EXPR_FIELDS(int-literal!)
	value		[integer!]
]

float-literal!: alias struct! [
	RST_EXPR_FIELDS(float-literal!)
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
        hashmap/put keywords k_if		as int-ptr! :parse-if
        hashmap/put keywords k_either	as int-ptr! :parse-if
        hashmap/put keywords k_while	as int-ptr! :parse-while
        hashmap/put keywords k_until	null
        hashmap/put keywords k_loop		null
        hashmap/put keywords k_case		null
        hashmap/put keywords k_switch	null
        hashmap/put keywords k_continue	as int-ptr! :parse-continue
        hashmap/put keywords k_break	as int-ptr! :parse-break
        hashmap/put keywords k_throw	null
        hashmap/put keywords k_catch	null
        hashmap/put keywords k_return	as int-ptr! :parse-return
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

	make-param-types: func [
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
		fn?		[logic!]
		return: [context!]
		/local
			ctx [context!]
	][
		ctx: as context! malloc size? context!
		ctx/token: name
		ctx/parent: parent
		ctx/stmts: as rst-stmt! malloc size? rst-stmt!	;-- stmt head
		ctx/last-stmt: ctx/stmts
		ctx/decls: hashmap/make either fn? [100][1000]
		ctx/loop-stack: vector/make size? integer! 32
		SET_NODE_TYPE(ctx RST_CONTEXT)
		if all [not fn? parent <> null][
			ctx/next: parent/child
			parent/child: ctx
		]
		ctx/src-blk: cur-blk
		ctx/script: script
		ctx/ret-type: type-system/void-type
		ctx/typecache: type-system/make-cache
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
		SET_NODE_TYPE(f RST_FLOAT)
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
		return: [var-decl!]
		/local
			var [var-decl!]
	][
		var: as var-decl! malloc size? var-decl!
		SET_NODE_TYPE(var RST_VAR_DECL)
		var/token: name
		var/typeref: typeref
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
		fn		[fn!]
		out		[ptr-ptr!]
		ctx		[context!]
		return: [cell!]
		/local
			fc	[fn-call!]
			n	[integer!]
			ft	[fn-type!]
			pp	[ptr-value!]
			beg [rst-node! value]
			cur [rst-node!]
	][
		fc: as fn-call! malloc size? fn-call!
		SET_NODE_TYPE(fc RST_FN_CALL)
		call_accept: func [ACCEPT_FN_SPEC][
			v/visit-fn-call self data
		]
		fc/accept: :call_accept
		fc/token: pc
		fc/type: fn/type
		ft: as fn-type! fn/type

		beg/next: null
		cur: :beg
		n: ft/n-params
		loop n [
			pc: advance-next pc end
			pc: parse-expr pc end :pp ctx
			cur/next: as rst-node! pp/value
			cur: cur/next
		]
		fc/args: as rst-expr! beg/next
		out/value: as int-ptr! fc
		pc
	]

	parse-block: func [
		blk		[red-block!]
		ctx		[context!]
		return: [rst-stmt!]
		/local
			pc	[cell!]
			end [cell!]
			stmt [rst-stmt! value]
			last-stmt [rst-stmt!]
			saved-blk [red-block!]
	][
		enter-block(blk)

		stmt/next: null
		last-stmt: ctx/last-stmt
		ctx/last-stmt: :stmt

		pc: block/rs-head blk
		end: block/rs-tail blk
		while [pc < end][
			pc: parse-statement pc end ctx
			pc: pc + 1
		]

		exit-block
		ctx/last-stmt: last-stmt
		stmt/next
	]

	parse-if: func [
		;pc end expr ctx
		KEYWORD_FN_SPEC
		/local
			w		[red-word!]
			cond	[ptr-value!]
			if-expr [if!]
	][
		if_accept: func [ACCEPT_FN_SPEC][
			v/visit-if self data
		]
		w: as red-word! pc
		pc: advance-next pc end		;-- skip keyword: if/either
		pc: parse-expr pc end :cond ctx

		if-expr: as if! malloc size? if!
		SET_NODE_TYPE(if-expr RST_IF)
		if-expr/token: as cell! w
		if-expr/accept: :if_accept
		if-expr/cond: as rst-expr! cond/value

		pc: expect-next pc end TYPE_BLOCK
		if-expr/true-blk: as red-block! pc
		if-expr/t-branch: parse-block as red-block! pc ctx

		if k_either = symbol/resolve w/symbol [
			pc: expect-next pc end TYPE_BLOCK
			if-expr/false-blk: as red-block! pc
			if-expr/f-branch: parse-block as red-block! pc ctx
		]
		expr/value: as int-ptr! if-expr
		pc
	]

	parse-while: func [
		;pc end expr ctx
		KEYWORD_FN_SPEC
		/local
			w		[while!]
	][
		while_accept: func [ACCEPT_FN_SPEC][
			v/visit-while self data
		]
		w: as while! malloc size? while!
		SET_NODE_TYPE(w RST_WHILE)
		w/token: pc
		w/accept: :while_accept

		pc: expect-next pc end TYPE_BLOCK
		w/cond-blk: as red-block! pc
		w/cond: parse-block as red-block! pc ctx

		pc: expect-next pc end TYPE_BLOCK
		w/body-blk: as red-block! pc
		w/body: parse-block as red-block! pc ctx
		expr/value: as int-ptr! w
		pc
	]

	parse-continue: func [
		;pc end expr ctx
		KEYWORD_FN_SPEC
		/local
			c	[continue!]
	][
		cont_accept: func [ACCEPT_FN_SPEC][
			v/visit-continue self data
		]
		c: as continue! malloc size? continue!
		SET_NODE_TYPE(c RST_CONTINUE)
		c/token: pc
		c/accept: :cont_accept

		expr/value: as int-ptr! c
		pc
	]

	parse-break: func [
		;pc end expr ctx
		KEYWORD_FN_SPEC
		/local
			b	[break!]
	][
		break_accept: func [ACCEPT_FN_SPEC][
			v/visit-break self data
		]
		b: as break! malloc size? break!
		SET_NODE_TYPE(b RST_CONTINUE)
		b/token: pc
		b/accept: :break_accept

		expr/value: as int-ptr! b
		pc
	]

	make-return: func [
		pc		[cell!]
		expr	[rst-expr!]
		return: [return!]
		/local
			r	[return!]
	][
		return_accept: func [ACCEPT_FN_SPEC][
			v/visit-return self data
		]
		r: as return! malloc size? return!
		SET_NODE_TYPE(r RST_RETURN)
		r/token: pc
		r/accept: :return_accept
		r/expr: expr
		r
	]

	parse-return: func [
		;pc end expr ctx
		KEYWORD_FN_SPEC
		/local
			pos [cell!]
			r	[return!]
			val [ptr-value!]
	][
		pos: pc
		pc: advance-next pc end		;-- skip keyword: return
		pc: parse-expr pc end :val ctx
		r: make-return pos as rst-expr! val/value

		expr/value: as int-ptr! r
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
				v: as rst-node! find-word w ctx
				either v <> null [
					switch NODE_TYPE(v) [
						RST_FUNC		[pc: parse-call pc end as fn! v expr ctx]
						RST_VAR_DECL	[expr/value: as int-ptr! make-variable as var-decl! v pc]
						default			[unreachable pc]
					]
				][
					sym: symbol/resolve w/symbol
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
			default [throw-error [pc "invalid expression"]]
		]
		pc
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
			pc2		[cell!]
	][
		left: as rst-expr! expr/value
		while [
			pc2: pc + 1
			all [pc2 < end WORD?(pc2)]
		][
			flag: 0
			infix?: no
			w: as red-word! pc2
			sym: symbol/resolve w/symbol
			val: hashmap/get infix-Ops sym
			either null <> val [
				infix?: yes
				flag: RST_INFIX_OP
				op: val/value
			][
				node: as rst-expr! find-word w ctx
				if node <> null [
					type: NODE_TYPE(node)
					if any [type = RST_VAR_DECL type = RST_FUNC][
						t: node/type
						if all [t <> null FN_ATTRS(t) and FN_INFIX <> 0][
							infix?: yes
							flag: RST_INFIX_FN
							op: as int-ptr! t
						]
					]
				]
			]
			either infix? [
				pos: pc2
				pc: parse-sub-expr advance-next pc2 end end :right ctx
				bin: make-bin-op op left as rst-expr! right/value pos
				ADD_NODE_FLAGS(bin flag)
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
		parse-infix-op pc end expr ctx
	]

	find-word: func [
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
			set?	[logic!]
			pos		[cell!]
			s		[rst-stmt!]
	][
		var: null
		set?: yes
		case [
			SET_WORD?(pc) [
				var: find-word as red-word! pc ctx
				pos: pc
				flags: NODE_FLAGS(ctx)
				either flags and RST_FN_CTX <> 0 [
					if any [null? var NODE_TYPE(var) <> RST_VAR_DECL][
						throw-error [pc "undefined symbol:" pc]
					]
				][
					if null? var [
						var: make-var-decl pc null
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
		f-ctx	[context!]
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
		cur-blk: src
		ctx: either null? f-ctx [make-ctx name parent no][f-ctx]
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
								if f-ctx <> null [throw-error [pc "context has to be declared at root level"]]

								pc2: expect-next pc2 end TYPE_BLOCK
								saved-blk: cur-blk
								c2: parse-context pc as red-block! pc2 ctx f-ctx
								cur-blk: saved-blk
								unless add-decl ctx pc as int-ptr! c2 [
									throw-error [pc "context name is already taken:" pc]
								]
								pc2
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
			pc: pc + 1
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
			saved-blk [red-block!]
	][
		enter-block(blk)
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
		exit-block
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
			cur	[var-decl!]
			list [var-decl! value]
	][
		list/next: null
		cur: :list
		n: 0
		while [p < end][
			case [
				any [WORD?(p) STRING?(p)][n: n + 1]
				BLOCK?(p) [
					if zero? n [throw-error [p "missing locals"]]
					t: p - 1
					until [
						if WORD?(t) [
							cur/next: make-var-decl t as red-block! p
							cur: cur/next
							ADD_NODE_FLAGS(cur RST_VAR_LOCAL)
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
			cur [var-decl!]
			list [var-decl! value]
			attr [integer!]
			flag [integer!]
			saved-blk [red-block!]
	][
		ft: as fn-type! malloc size? fn-type!
		SET_TYPE_KIND(ft RST_TYPE_FUNC)
		ft/spec: spec

		p: block/rs-head spec
		end: block/rs-tail spec

		p: skip p end TYPE_STRING			;-- skip doc strings

		if p = end [return ft]

		if BLOCK?(p) [						;-- attributes
			attr: get-attributes as red-block! p
			ADD_FN_ATTRS(ft attr)
			p: skip p + 1 end TYPE_STRING	;-- skip doc strings
		]

		enter-block(spec)

		list/next: null
		cur: :list
		s: 0	;-- initial state
		w: as red-word! p
		while [w < as red-word! end][		;-- parse params, return: and /local
			case [
				;; param = word "[" type "]" doc-string?
				all [s = 0 WORD?(w)][
					p2: expect-next p end TYPE_BLOCK
					cur/next: make-var-decl p as red-block! p2
					cur: cur/next
					flag: RST_VAR_PARAM or RST_VAR_LOCAL
					ADD_NODE_FLAGS(cur flag)
					cur/init: as rst-expr! ft/n-params ;-- parameter index
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
		exit-block

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
		fn/type: as rst-type! parse-fn-spec spec fn

		unless add-decl ctx pc as int-ptr! fn [
			throw-error [pc "symbol name was already defined"]
		]
		as cell! body
	]
]