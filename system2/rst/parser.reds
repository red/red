Red/System [
	File: 	 %parser.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define TYPE_RESOLVING [as rst-type! -1]

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
	VISITOR_FUNC(visit-fn-call)
	VISITOR_FUNC(visit-native-call)
	VISITOR_FUNC(visit-assign)
	VISITOR_FUNC(visit-bin-op)
	VISITOR_FUNC(visit-var)
	VISITOR_FUNC(visit-declare)
	VISITOR_FUNC(visit-get-ptr)
	VISITOR_FUNC(visit-not)
	VISITOR_FUNC(visit-size?)
	VISITOR_FUNC(visit-cast)
	VISITOR_FUNC(visit-literal)
	VISITOR_FUNC(visit-lit-array)
	VISITOR_FUNC(visit-comment)
	VISITOR_FUNC(visit-path)
	VISITOR_FUNC(visit-any-all)
	VISITOR_FUNC(visit-throw)
	VISITOR_FUNC(visit-catch)
	VISITOR_FUNC(visit-assert)
	VISITOR_FUNC(visit-context)
	VISITOR_FUNC(visit-sys-alias)
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

#enum rst-op! [		;@@ infix ops, order matters
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
]

#enum rst-node-type! [
	RST_VOID
	RST_LOGIC
	RST_INT
	RST_BYTE
	RST_FLOAT
	RST_NULL
	RST_C_STR
	RST_BINARY
	RST_LIT_ARRAY		;-- literal array
	RST_DECLARE
	RST_GET_PTR
	RST_BIN_OP
	RST_NOT
	RST_SIZEOF
	RST_CAST
	RST_FN_CALL
	RST_NATIVE_CALL
	RST_VAR
	RST_IF
	RST_SWITCH
	RST_CASE
	RST_ANY
	RST_ALL
	RST_ASSIGN
	RST_PATH
	RST_MEMBER
	RST_SYS_ALIAS
	RST_EXPR_END		;-- 26 end marker of expr types
	RST_CONTEXT			;-- 27
	RST_FUNC			;-- 28
	RST_SUBROUTINE		;-- 29
	RST_VAR_DECL		;-- 30
	RST_ENUM			;-- 31
	RST_WHILE
	RST_LOOP
	RST_UNTIL
	RST_BREAK
	RST_CONTINUE
	RST_THROW
	RST_CATCH
	RST_RETURN
	RST_ASSERT
	RST_COMMENT
]

#enum rst-native! [
	N_PUSH
	N_POP
	N_LOG_B
	N_GET_STACK_TOP
	N_SET_STACK_TOP
	N_GET_STACK_FRAME
	N_SET_STACK_FRAME
	N_STACK_ALIGN
	N_STACK_ALLOC
	N_STACK_FREE
	N_STACK_PUSH_ALL
	N_STACK_POP_ALL
	N_PC
	N_GET_CPU_REG
	N_SET_CPU_REG
	N_CPU_OVERFLOW
	N_IO_READ
	N_IO_WRITE
	N_ATOMIC_FENCE
	N_ATOMIC_LOAD
	N_ATOMIC_STORE
	N_ATOMIC_CAS
	N_ATOMIC_ADD
	N_ATOMIC_SUB
	N_ATOMIC_OR
	N_ATOMIC_XOR
	N_ATOMIC_AND
	N_FPU_UPDATE
	N_FPU_GET_CWORD
	N_FPU_SET_CWORD
	N_NATIVE_NUM		;-- number of natives
]

#enum fn-attr! [
	FN_CC_INTERNAL:		0
	FN_CC_STDCALL:		1
	FN_CC_CDECL:		2
	FN_INFIX:			4
	FN_CALLBACK:		8
	FN_VARIADIC:		10h
	FN_TYPED:			20h
	FN_CUSTOM:			40h
	FN_CATCH:			80h
	FN_EXTERN:			0100h
	FN_COMMUTE:			0200h
	FN_ST_ARG:			0400h		;-- this function has struct value argument
]

#enum rst-node-flag! [
	RST_AS_KEEP:	1
	RST_VAR_LOCAL:	2	;-- local variable
	RST_VAR_PARAM:	4	;-- var-decl! is a parameter
	RST_FN_CTX:		8
	RST_VAR_PTR:	10h
	RST_VAR_VAL:	20h
	RST_IMPORT_FN:	40h
	RST_SIZE_TYPE:	80h
	RST_DYN_ALLOC:	0100h
	RST_ST_ARG:		0200h
]

#define SET_NODE_TYPE(node type) [node/header: type]
#define ADD_NODE_FLAGS(node flags) [node/header: node/header or (flags << 8)]
#define NODE_TYPE(node) (node/header and FFh)
#define NODE_FLAGS(node) (node/header >>> 8)
#define RST_WHILE?(node) [node/header and FFh = RST_WHILE]
#define RST_FN_CALL?(node) [node/header and FFh = RST_FN_CALL]
#define FUNC_CTX?(node) [node/header >>> 8 and RST_FN_CTX <> 0]

;-- fn-type! /header bits: 8 - 15 opcode, 16 - 31: attributes
#define FN_OPCODE(f) (f/header >>> 8 and FFh)
#define FN_ATTRS(f) (f/header >>> 16)
#define FN_VARIADIC?(f) (f/header >> 16 and FN_VARIADIC <> 0)
#define FN_TYPED?(f) (f/header >> 16 and FN_TYPED <> 0)
#define FN_ST_ARG?(f) (f/header >> 16 and FN_ST_ARG <> 0)
#define FN_COMMUTE?(f) (f/header >> 16 and FN_COMMUTE <> 0)
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
	instr		[instr!]
	loop-bset	[integer!]	;-- loop bitset, var used in loops, can encode 32 loops
	extra-bset	[ptr-array!]
	decl		[var-decl!]
]

#define PARAM_VAR?(var) (NODE_FLAGS(var) and RST_VAR_PARAM <> 0)
#define NOT_PARAM_VAR?(var) (NODE_FLAGS(var) and RST_VAR_PARAM = 0)
#define LOCAL_VAR?(var) (NODE_FLAGS(var) and RST_VAR_LOCAL <> 0)
#define GLOBAL_VAR?(var) (NODE_FLAGS(var) and RST_VAR_LOCAL = 0)
#define CAST_KEEP?(node) (NODE_FLAGS(node) and RST_AS_KEEP <> 0)
#define RST_VAR_PTR?(node) (NODE_FLAGS(node) and RST_VAR_PTR <> 0)
#define RST_VAR_VAL?(node) (NODE_FLAGS(node) and RST_VAR_VAL <> 0)

var-decl!: alias struct! [	;-- variable declaration
	RST_NODE_FIELDS(var-decl!)
	init		[rst-expr!]	;-- init expression or parameter idx
	typeref		[red-block!]
	type		[rst-type!]
	data-idx	[integer!]	;-- for global var, index in data section
	blkref		[red-block!]
	ssa			[ssa-var!]
]

declare!: alias struct! [
	RST_EXPR_FIELDS(declare!)
	data-idx	[integer!]	 ;-- @@ keep it the same offset as in var-decl!
	blkref		[red-block!] ;-- @@ keep it the same offset as in var-decl!
	typeref		[cell!]
]

enumerator!: alias struct! [
	RST_NODE_FIELDS(enumerator!)
	n-cases		[integer!]
	cases		[member!]
]

sub-fn!: alias struct! [
	RST_STMT_FIELDS(sub-fn!)
	body		[rst-stmt!]
	body-blk	[red-block!]
]

variable!: alias struct! [
	RST_EXPR_FIELDS(variable!)
	decl		[var-decl!]
]

context!: alias struct! [
	RST_STMT_FIELDS(context!)
	parent		 [context!]
	stmts		 [rst-stmt!]
	last-stmt	 [rst-stmt!]
	decls		 [int-ptr!]
	with-ns		 [vector!]
	ret-type	 [rst-type!]
	typecache	 [int-ptr!]
	n-typed		 [integer!]	;-- number of typed values
	n-ssa-vars	 [integer!]	;-- number of variable that written more than once
	n-loops		 [integer!]
	loop-stack	 [vector!]
	loop-counter [var-decl!]
	src-blk		 [red-block!]
	script		 [cell!]
	throw-error? [logic!]
	dyn-alloc?	 [logic!]
]

fn!: alias struct! [
	RST_EXPR_FIELDS(fn!)
	parent		[context!]
	body		[red-block!]
	locals		[var-decl!]
	ir			[ir-fn!]
	with-ns		[vector!]
	refs		[vector!]
]

import-fn!: alias struct! [		;-- extends fn!
	RST_EXPR_FIELDS(fn!)
	parent		[context!]
	body		[red-block!]
	locals		[var-decl!]
	ir			[ir-fn!]
	cc			[call-conv!]
	with-ns		[vector!]
	import-name [cell!]
	import-lib	[cell!]
]

fn-call!: alias struct! [
	RST_EXPR_FIELDS(fn-call!)
	fn			[fn!]
	args		[rst-expr!]
]

get-ptr!: alias struct! [
	RST_EXPR_FIELDS(get-ptr!)
	expr		[rst-expr!]
]

path!: alias struct! [
	RST_EXPR_FIELDS(path!)
	receiver	[var-decl!]
	subs		[member!]
]

member!: alias struct! [
	RST_NODE_FIELDS(member!)
	index		[integer!]
	expr		[rst-expr!]
	type		[rst-type!]
]

cast!: alias struct! [
	RST_EXPR_FIELDS(cast!)
	typeref		[cell!]
	expr		[rst-expr!]
	cast		[integer!]
]

assignment!: alias struct! [
	RST_EXPR_FIELDS(assignment!)
	target		[rst-expr!]
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

case!: alias struct! [
	RST_EXPR_FIELDS(rst-node!)
	cases		[if!]
]

any-all!: alias struct! [
	RST_EXPR_FIELDS(any-all!)
	conds		[rst-expr!]
]

switch-case!: alias struct! [
	RST_NODE_FIELDS(switch-case!)
	expr		[rst-expr!]
	body		[rst-stmt!]
]

switch!: alias struct! [
	RST_EXPR_FIELDS(rst-node!)
	expr		[rst-expr!]
	cases		[switch-case!]
	defcase		[switch-case!]
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

catch!: alias struct! [
	RST_STMT_FIELDS(rst-node!)
	filter		[red-integer!]
	body		[rst-stmt!]
]

native!: alias struct! [
	id			[integer!]
	n-params	[integer!]
	param-types [ptr-ptr!]
	ret-type	[rst-type!]
]

native-call!: alias struct! [
	RST_EXPR_FIELDS(native-call!)
	native		[native!]
	args		[rst-expr!]
]

unary!: alias struct! [
	RST_EXPR_FIELDS(unary!)
	expr		[rst-expr!]
]

sizeof!: alias struct! [
	RST_EXPR_FIELDS(sizeof!)
	expr		[rst-expr!]
	etype		[rst-type!]		;-- type of expr
]

bin-op!: alias struct! [
	RST_EXPR_FIELDS(bin-op!)
	op			[int-ptr!]
	spec		[fn-type!]
	left		[rst-expr!]
	right		[rst-expr!]
]

sys-alias!: alias struct! [
	RST_EXPR_FIELDS(sys-alias!)
	alias-type	[rst-type!]
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

array-literal!: alias struct! [
	RST_EXPR_FIELDS(array-literal!)
	length		[integer!]
]

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
	k_callback:	symbol/make "callback"
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
	k_default:	symbol/make "default"
	k_keep:		symbol/make "keep"
	k_push:		symbol/make "push"
	k_pop:		symbol/make "pop"
	k_log-b:	symbol/make "log-b"

	k_+:			symbol/make "+"
	k_-:			symbol/make "-"
	k_=:			symbol/make "="
	k_>=:			symbol/make ">="
	k_>:			symbol/make ">"
	k_<<:			symbol/make "<<"
	k_>>:			symbol/make ">>"
	k_>>>:			symbol/make ">>>"
	k_less:			symbol/make "<"
	k_less_eq:		symbol/make "<="
	k_not_eq:		symbol/make "<>"
	k_slash:		symbol/make "/"
	k_dbl_slash:	symbol/make "//"
	k_percent:		symbol/make "%"
	k_star:			symbol/make "*"	
	k_and:			symbol/make "and"
	k_or:			symbol/make "or"
	k_xor:			symbol/make "xor"

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

	;-- system/*
	k_system:		symbol/make "system"
	k_stack:		symbol/make "stack"
	k_io:			symbol/make "io"
	k_pc:			symbol/make "pc"
	k_cpu:			symbol/make "cpu"
	k_fpu:			symbol/make "fpu"
	k_eax:			symbol/make "eax"
	k_ecx:			symbol/make "ecx"
	k_edx:			symbol/make "edx"
	k_ebx:			symbol/make "ebx"
	k_esp:			symbol/make "esp"
	k_ebp:			symbol/make "ebp"
	k_esi:			symbol/make "esi"
	k_edi:			symbol/make "edi"
	k_read:			symbol/make "read"
	k_write:		symbol/make "write"
	k_top:			symbol/make "top"
	k_frame:		symbol/make "frame"
	k_align:		symbol/make "align"
	k_allocate:		symbol/make "allocate"
	k_free:			symbol/make "free"
	k_push-all:		symbol/make "push-all"
	k_pop-all:		symbol/make "pop-all"
	k_overflow?:	symbol/make "overflow?"
	k_atomic:		symbol/make "atomic"
	k_fence:		symbol/make "fence"
	k_load:			symbol/make "load"
	k_store:		symbol/make "store"
	k_cas:			symbol/make "cas"
	k_words:		symbol/make "words"
	k_add:			symbol/make "add"
	k_sub:			symbol/make "sub"
	k_or:			symbol/make "or"
	k_xor:			symbol/make "xor"
	k_and:			symbol/make "and"
	k_old:			symbol/make "old"
	k_zero:			symbol/make "zero"
	k_update:		symbol/make "update"
	k_control-word: symbol/make "control-word"

	keywords:  as int-ptr! 0
	infix-Ops: as int-ptr! 0

	native-push:		as native! 0
	native-pop:			as native! 0
	native-log-b:		as native! 0
	get-stack-top:		as native! 0
	set-stack-top:		as native! 0
	get-stack-frame:	as native! 0
	set-stack-frame:	as native! 0
	stack-align:		as native! 0
	stack-allocate: 	as native! 0
	stack-free:			as native! 0
	stack-push-all: 	as native! 0
	stack-pop-all:		as native! 0
	system-pc:			as native! 0
	get-cpu-reg:		as native! 0
	set-cpu-reg:		as native! 0
	cpu-overflow?:		as native! 0
	io-write:			as native! 0
	io-read:			as native! 0
	atomic-fence:		as native! 0
	atomic-load:		as native! 0
	atomic-store:		as native! 0
	atomic-cas:			as native! 0
	atomic-add:			as native! 0
	atomic-sub:			as native! 0
	atomic-or:			as native! 0
	atomic-xor:			as native! 0
	atomic-and:			as native! 0
	fpu-update:			as native! 0
	fpu-get-cword:		as native! 0
	fpu-set-cword:		as native! 0

	init: func [/local arr p [ptr-ptr!]][
		keywords: hashmap/make 300
		infix-Ops: hashmap/make 100
		hashmap/put infix-Ops k_+			as int-ptr! RST_OP_ADD
		hashmap/put infix-Ops k_-			as int-ptr! RST_OP_SUB
		hashmap/put infix-Ops k_=			as int-ptr! RST_OP_EQ
		hashmap/put infix-Ops k_>=			as int-ptr! RST_OP_GTEQ
		hashmap/put infix-Ops k_>			as int-ptr! RST_OP_GT
		hashmap/put infix-Ops k_<<			as int-ptr! RST_OP_SHL
		hashmap/put infix-Ops k_>>			as int-ptr! RST_OP_SAR
		hashmap/put infix-Ops k_>>>			as int-ptr! RST_OP_SHR
		hashmap/put infix-Ops k_less		as int-ptr! RST_OP_LT
		hashmap/put infix-Ops k_less_eq		as int-ptr! RST_OP_LTEQ
		hashmap/put infix-Ops k_not_eq		as int-ptr! RST_OP_NE
		hashmap/put infix-Ops k_slash		as int-ptr! RST_OP_DIV
		hashmap/put infix-Ops k_dbl_slash	as int-ptr! RST_OP_MOD
		hashmap/put infix-Ops k_percent		as int-ptr! RST_OP_REM
		hashmap/put infix-Ops k_star		as int-ptr! RST_OP_MUL
		hashmap/put infix-Ops k_and			as int-ptr! RST_OP_AND
		hashmap/put infix-Ops k_or			as int-ptr! RST_OP_OR
		hashmap/put infix-Ops k_xor			as int-ptr! RST_OP_XOR

		hashmap/put keywords k_any		as int-ptr! :parse-any
        hashmap/put keywords k_all		as int-ptr! :parse-all
        hashmap/put keywords k_as		as int-ptr! :parse-as
        hashmap/put keywords k_declare	as int-ptr! :parse-declare
        hashmap/put keywords k_size?	as int-ptr! :parse-size?
        hashmap/put keywords k_not		as int-ptr! :parse-not
        hashmap/put keywords k_null		as int-ptr! :parse-null
        hashmap/put keywords k_if		as int-ptr! :parse-if
        hashmap/put keywords k_either	as int-ptr! :parse-if
        hashmap/put keywords k_while	as int-ptr! :parse-while
        hashmap/put keywords k_until	as int-ptr! :parse-until
        hashmap/put keywords k_loop		as int-ptr! :parse-loop
        hashmap/put keywords k_case		as int-ptr! :parse-case
        hashmap/put keywords k_switch	as int-ptr! :parse-switch
        hashmap/put keywords k_continue	as int-ptr! :parse-continue
        hashmap/put keywords k_break	as int-ptr! :parse-break
        hashmap/put keywords k_throw	as int-ptr! :parse-throw
        hashmap/put keywords k_catch	as int-ptr! :parse-catch
        hashmap/put keywords k_return	as int-ptr! :parse-return
        hashmap/put keywords k_exit		as int-ptr! :parse-exit
        hashmap/put keywords k_assert	as int-ptr! :parse-assert
        hashmap/put keywords k_comment	as int-ptr! :parse-comment
        hashmap/put keywords k_true		as int-ptr! :parse-logic
        hashmap/put keywords k_false	as int-ptr! :parse-logic
        hashmap/put keywords k_push		as int-ptr! :parse-push
        hashmap/put keywords k_pop		as int-ptr! :parse-pop
        hashmap/put keywords k_log-b	as int-ptr! :parse-log-b

		with type-system [
			arr: as ptr-ptr! malloc size? int-ptr!
			arr/value: as int-ptr! any-type
	        native-push: make-native N_PUSH 1 arr void-type
	        native-pop: make-native N_POP 0 null integer-type

			arr: as ptr-ptr! malloc size? int-ptr!
			arr/value: as int-ptr! integer-type
	        native-log-b: make-native N_LOG_B 1 arr integer-type

			arr: as ptr-ptr! malloc size? int-ptr!
			arr/value: as int-ptr! int-ptr-type
	        get-stack-top: make-native N_GET_STACK_TOP 0 null int-ptr-type
	        set-stack-top: make-native N_SET_STACK_TOP 1 arr int-ptr-type		;@@ non void-type for def-reg
	        get-stack-frame: make-native N_GET_STACK_FRAME 0 null int-ptr-type
	        set-stack-frame: make-native N_SET_STACK_FRAME 1 arr int-ptr-type

			stack-align: make-native N_STACK_ALIGN 0 null int-ptr-type

	        arr: as ptr-ptr! malloc 2 * size? int-ptr!
	        stack-allocate: make-native N_STACK_ALLOC 2 arr int-ptr-type
	        stack-free: make-native N_STACK_FREE 1 arr void-type
			arr/value: as int-ptr! integer-type		;-- slots
			arr: arr + 1
			arr/value: as int-ptr! logic-type		;-- /zero

			system-pc: make-native N_PC 0 null byte-ptr-type

			fpu-update: make-native N_FPU_UPDATE 0 null void-type
			fpu-get-cword: make-native N_FPU_GET_CWORD 0 null integer-type
			arr: as ptr-ptr! malloc size? int-ptr!
			arr/value: as int-ptr! integer-type
			fpu-set-cword: make-native N_FPU_SET_CWORD 1 arr void-type

			get-cpu-reg: make-native N_GET_CPU_REG 1 arr integer-type
			arr: as ptr-ptr! malloc 2 * size? int-ptr!
			set-cpu-reg: make-native N_SET_CPU_REG 2 arr void-type
			arr/value: as int-ptr! integer-type
			arr: arr + 1
			arr/value: as int-ptr! integer-type

			cpu-overflow?: make-native N_CPU_OVERFLOW 0 null logic-type
			stack-push-all: make-native N_STACK_PUSH_ALL 0 null void-type
			stack-pop-all: make-native N_STACK_POP_ALL 0 null void-type

	        arr: as ptr-ptr! malloc 3 * size? int-ptr!
			arr/value: as int-ptr! int-ptr-type
			p: arr + 1
			p/value: as int-ptr! integer-type
			p: p + 1
			p/value: as int-ptr! integer-type
			atomic-fence: make-native N_ATOMIC_FENCE 0 null void-type
			atomic-load: make-native N_ATOMIC_LOAD 1 arr integer-type
			atomic-store: make-native N_ATOMIC_STORE 2 arr void-type
			atomic-cas: make-native N_ATOMIC_CAS 3 arr logic-type
			atomic-add: make-native N_ATOMIC_ADD 3 arr integer-type
			atomic-sub: make-native N_ATOMIC_SUB 3 arr integer-type
			atomic-or:  make-native N_ATOMIC_OR  3 arr integer-type
			atomic-xor: make-native N_ATOMIC_XOR 3 arr integer-type
			atomic-and: make-native N_ATOMIC_AND 3 arr integer-type
        ]
	]

	make-native: func [
		id			[integer!]
		n-params	[integer!]
		ptypes		[ptr-ptr!]
		ret-type	[rst-type!]
		return:		[native!]
		/local
			f		[native!]
	][
		f: xmalloc(native!)
		f/id: id
		f/n-params: n-params
		f/param-types: ptypes
		f/ret-type: ret-type
		f
	]

	advance: func [
		pc		[cell!]
		end		[cell!]
		idx		[integer!]
		return: [cell!]
	][
		pc: pc + idx
		if pc >= end [
			throw-error [pc - 1 "EOF: expect more code"]
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
		return: [cell!]
	][
		if TYPE_OF(pc) <> type [
			throw-error [pc "Expect type:" red-type type]
			halt
		]
		pc
	]

	expect-next: func [
		pc		[cell!]
		end		[cell!]
		type	[integer!]
		return: [cell!]
	][
		pc: pc + 1
		if pc >= end [throw-error [pc - 1 "EOF: expect more code"]]
		if TYPE_OF(pc) <> type [
			throw-error [pc "Expect type:" red-type type]
			halt
		]
		pc
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
		ctx_accept: func [ACCEPT_FN_SPEC][
			v/visit-context self data
		]
		ctx: as context! malloc size? context!
		ctx/token: name
		ctx/parent: parent
		ctx/stmts: as rst-stmt! malloc size? rst-stmt!	;-- stmt head
		ctx/last-stmt: ctx/stmts
		ctx/decls: hashmap/make either fn? [100][1000]
		ctx/loop-stack: vector/make size? integer! 4
		SET_NODE_TYPE(ctx RST_CONTEXT)
		ctx/src-blk: cur-blk
		ctx/script: compiler/script
		ctx/ret-type: type-system/void-type
		ctx/typecache: type-system/make-cache
		ctx/throw-error?: yes
		ctx/accept: :ctx_accept
		ctx
	]

	make-subroutine: func [
		name	[cell!]
		body	[red-block!]
		/local
			s	[sub-fn!]
	][
		s: xmalloc(sub-fn!)
		SET_NODE_TYPE(s RST_SUBROUTINE)
		s/token: name
		s/body-blk: body
		s
	]

	make-func: func [
		name	[cell!]
		parent	[context!]
		import? [logic!]
		return: [fn!]
		/local
			f	[fn!]
	][
		func_accept: func [ACCEPT_FN_SPEC][
			v/visit-func self data
		]
		f: as fn! either import? [malloc size? import-fn!][malloc size? fn!]
		f/token: name
		f/parent: parent
		f/accept: :func_accept
		SET_NODE_TYPE(f RST_FUNC)
		if parent/with-ns <> null [
			f/with-ns: vector/copy parent/with-ns
		]
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

	make-get-ptr: func [
		pc			[cell!]
		expr		[rst-expr!]
		return:		[get-ptr!]
		/local
			g		[get-ptr!]
	][
		get-ptr_accept: func [ACCEPT_FN_SPEC][
			v/visit-get-ptr self data
		]
		g: xmalloc(get-ptr!)
		SET_NODE_TYPE(g RST_GET_PTR)
		g/token: pc
		g/accept: :get-ptr_accept
		g/expr: expr
		g
	]

	parse-get-word: func [
		pc		[cell!]
		ctx		[context!]
		return: [get-ptr!]
		/local
			v	[rst-node!]
			ty	[integer!]
	][
		v: find-word as red-word! pc ctx -1
		either v <> null [
			ty: NODE_TYPE(v)
			if all [ty <> RST_VAR_DECL ty <> RST_FUNC][
				throw-error [pc "invalid get-word"]
			]
			make-get-ptr pc as rst-expr! v
		][
			throw-error [pc "undefined symbol:" pc]
			null
		]
	]

	make-sys-alias: func [
		pc		[cell!]
		return: [sys-alias!]
		/local
			e	[sys-alias!]
	][
		rst-sys-alias_accept: func [ACCEPT_FN_SPEC][
			v/visit-sys-alias self data
		]
		e: xmalloc(sys-alias!)
		SET_NODE_TYPE(e RST_SYS_ALIAS)
		e/token: pc
		e/accept: :rst-sys-alias_accept
		e/type: type-system/integer-type
		e
	]

	make-lit-array: func [
		pos		[cell!]
		return: [array-literal!]
		/local
			a	[array-literal!]
	][
		array_accept: func [ACCEPT_FN_SPEC][
			v/visit-lit-array self data
		]
		a: xmalloc(array-literal!)
		SET_NODE_TYPE(a RST_LIT_ARRAY)
		a/token: pos
		a/accept: :array_accept
		a/type: type-system/lit-array-type? pos
		a
	]

	make-byte: func [
		pos		[cell!]
		return:	[int-literal!]
		/local
			int [int-literal!]
			c	[red-char!]
			v	[integer!]
	][
		c: as red-char! pos
		v: c/value
		byte_accept: func [ACCEPT_FN_SPEC][
			v/visit-literal self data
		]
		int: as int-literal! malloc size? int-literal!
		SET_NODE_TYPE(int RST_BYTE)
		int/accept: :byte_accept
		int/token: pos
		int/value: v
		int/type: type-system/byte-type
		int
	]

	make-int: func [
		pos		[cell!]
		return: [int-literal!]
		/local
			int [int-literal!]
			i	[red-integer!]
			v	[integer!]
	][
		i: as red-integer! pos
		v: i/value
		int_accept: func [ACCEPT_FN_SPEC][
			v/visit-literal self data
		]
		int: as int-literal! malloc size? int-literal!
		SET_NODE_TYPE(int RST_INT)
		int/accept: :int_accept
		int/token: pos
		int/value: v
		int/type: either v < 0 [target/int-type][type-system/integer-type]
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
		f/type: type-system/float-type
		f
	]

	make-assignment: func [
		target	[rst-expr!]
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
		assign/target: target
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
		var: xmalloc(var-decl!)
		SET_NODE_TYPE(var RST_VAR_DECL)
		var/token: name
		var/typeref: typeref
		var/blkref: cur-blk
		var/data-idx: -1
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

	fetch-block-args: func [
		blk		[red-block!]
		args	[ptr-ptr!]
		ctx		[context!]
		return: [integer!]
		/local
			pc 	[cell!]
			end	[cell!]
			beg [rst-node! value]
			cur [rst-node!]
			pp	[ptr-value!]
			n	[integer!]
			saved-blk [red-block!]
			n-args [rst-node!]
	][
		n: 0
		beg/next: null
		cur: :beg
		pc: block/rs-head blk
		end: block/rs-tail blk
		
		enter-block(blk)
		while [pc < end][
			pc: parse-expr pc end :pp ctx
			cur/next: as rst-node! pp/value
			cur: cur/next
			n: n + 1
			pc: pc + 1
		]
		exit-block

		n-args: xmalloc(rst-node!)
		n-args/header: n
		n-args/next: beg/next
		args/value: as int-ptr! n-args
		n
	]

	make-args: func [
		n		[integer!]
		args	[rst-expr!]
		return: [rst-expr!]
		/local
			n-args [rst-node!]
	][
		n-args: xmalloc(rst-node!)
		n-args/header: n	;-- store number of args in header
		n-args/next: as rst-node! args
		as rst-expr! n-args
	]

	fetch-args: func [
		pc		[cell!]
		end		[cell!]
		args	[ptr-ptr!]
		ctx		[context!]
		n		[integer!]
		return: [cell!]
		/local
			beg [rst-node! value]
			cur [rst-node!]
			pp	[ptr-value!]
			blk	[red-block!]
			cnt [integer!]
			i	[integer!]
	][
		pc: advance-next pc end
		if T_BLOCK?(pc) [
			blk: as red-block! pc
			cnt: fetch-block-args blk args ctx
			if all [n > 0 n <> cnt][
				throw-error [pc "wrong number of arguments"]
			]
			if all [
				n = -2
				ctx/n-typed < cnt
			][
				ctx/n-typed: cnt
			]
			return pc
		]

		case [
			n = -1 [throw-error [pc "expected a block of arguments for variadic function"]]
			n = -2 [	;-- typed function call
				n: 1
				if ctx/n-typed < 1 [ctx/n-typed: 1]
			]
			true [0]
		]
		beg/next: null
		cur: :beg
		i: 1
		forever [
			pc: parse-expr pc end :pp ctx
			cur/next: as rst-node! pp/value
			cur: cur/next
			if i = n [break]
			i: i + 1
			pc: advance-next pc end
		]
		args/value: as int-ptr! make-args n as rst-expr! beg/next
		pc
	]

	make-fn-call: func [
		name	[cell!]
		fn		[fn!]
		args	[rst-expr!]
		return: [fn-call!]
		/local
			fc	[fn-call!]
	][
		fc: xmalloc(fn-call!)
		SET_NODE_TYPE(fc RST_FN_CALL)
		call_accept: func [ACCEPT_FN_SPEC][
			v/visit-fn-call self data
		]
		fc/accept: :call_accept
		fc/token: name
		fc/fn: fn
		fc/args: args
		fc
	]

	parse-call: func [
		pc		[cell!]
		end		[cell!]
		fn		[fn!]
		out		[ptr-ptr!]
		ctx		[context!]
		return: [cell!]
		/local
			n	[integer!]
			ft	[fn-type!]
			pp	[ptr-value!]
			name [cell!]
	][
		name: pc
		ft: as fn-type! fn/type
		n: ft/n-params
		either n <> 0 [pc: fetch-args pc end :pp ctx n][pp/value: null]
		out/value: as int-ptr! make-fn-call name fn as rst-expr! pp/value
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

	_parse-if: func [
		pc		[cell!]
		end		[cell!]
		expr	[ptr-ptr!]
		ctx		[context!]
		either? [logic!]
		return: [cell!]
		/local
			cond	[ptr-value!]
			if-expr [if!]
	][
		if_accept: func [ACCEPT_FN_SPEC][
			v/visit-if self data
		]

		if-expr: xmalloc(if!)
		SET_NODE_TYPE(if-expr RST_IF)
		if-expr/token: pc
		if-expr/accept: :if_accept

		pc: parse-expr pc end :cond ctx
		if-expr/cond: as rst-expr! cond/value

		pc: expect-next pc end TYPE_BLOCK
		if-expr/true-blk: as red-block! pc
		if-expr/t-branch: parse-block as red-block! pc ctx

		if either? [
			pc: expect-next pc end TYPE_BLOCK
			if-expr/false-blk: as red-block! pc
			if-expr/f-branch: parse-block as red-block! pc ctx
		]	
		expr/value: as int-ptr! if-expr
		pc
	]

	parse-if: func [
		;pc end expr ctx
		KEYWORD_FN_SPEC
		/local
			w [red-word!]
	][
		w: as red-word! pc
		pc: advance-next pc end		;-- skip keyword: if/either
		_parse-if pc end expr ctx k_either = symbol/resolve w/symbol
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

	parse-exit: func [
		KEYWORD_FN_SPEC
		/local
			r	[return!]
	][
		r: make-return pc null
		expr/value: as int-ptr! r
		pc
	]

	parse-any-all: func [
		KEYWORD_FN_SPEC		
		/local
			a		[any-all!]
			blk		[red-block!]
			val		[cell!]
			s-tail	[cell!]
			pv		[ptr-value!]
			cond	[rst-expr!]
			cur		[rst-expr!]
			eval	[rst-expr! value]
			saved-blk [red-block!]
	][
		any-all_accept: func [ACCEPT_FN_SPEC][
			v/visit-any-all self data
		]
		blk: as red-block! expect-next pc end TYPE_BLOCK
		val: block/rs-head blk
		s-tail: block/rs-tail blk
		if val = s-tail [throw-error [pc "empty block"]]

		enter-block(blk)

		cur: :eval
		while [val < s-tail][
			val: parse-expr val s-tail :pv ctx
			cond: as rst-expr! pv/value
			cur/next: cond
			cur: cond
			val: val + 1
		]
		a: xmalloc(any-all!)
		a/token: pc
		a/accept: :any-all_accept
		a/conds: eval/next

		exit-block
		expr/value: as int-ptr! a
		as cell! blk
	]

	parse-any: func [
		KEYWORD_FN_SPEC
		/local
			node [rst-node!]
	][
		parse-any-all pc end expr ctx
		node: as rst-node! expr/value
		SET_NODE_TYPE(node RST_ANY)
		pc + 1
	]

	parse-all: func [
		KEYWORD_FN_SPEC
		/local
			node [rst-node!]
	][
		parse-any-all pc end expr ctx
		node: as rst-node! expr/value
		SET_NODE_TYPE(node RST_ALL)
		pc + 1
	]

	fetch-type: func [
		pc		[cell!]
		end		[cell!]
		typeref [ptr-ptr!]
		sz?		[logic!]		;-- for parse-size?
		return: [cell!]
		/local
			w	[red-word!]
			sym [integer!]
			blk [red-block!]
	][
		if T_BLOCK?(pc) [
			typeref/value: as int-ptr! pc
			return pc
		]

		blk: xmalloc(red-block!)
		w: as red-word! pc
		if TYPE_OF(w) <> TYPE_WORD [
			throw-error [pc "invalid type, expect a word!"]
		]
		sym: symbol/resolve w/symbol

		typeref/value: as int-ptr! either any [
			sym = k_pointer!
			sym = k_struct!
			sym = k_function!
		][
			red/block/make-at blk 2
			red/block/rs-append blk pc
			either sz? [
				pc: pc + 1
				either any [pc = end TYPE_OF(pc) <> TYPE_BLOCK][
					pc: pc - 1
					red/block/make-in blk 1		;-- make an empty block for spec
				][
					red/block/rs-append blk pc
				]
			][
				pc: expect-next pc end TYPE_BLOCK
				red/block/rs-append blk pc
			]
			blk
		][
			pc
		]
		pc
	]

	parse-as: func [
		KEYWORD_FN_SPEC
		/local
			c	[cast!]
			w	[red-word!]
			e	[ptr-value!]
	][
		cast_accept: func [ACCEPT_FN_SPEC][
			v/visit-cast self data
		]
		c: xmalloc(cast!)
		SET_NODE_TYPE(c RST_CAST)
		c/token: pc
		c/accept: :cast_accept

		pc: advance-next pc end
		pc: fetch-type pc end :e no
		c/typeref: as cell! e/value
		pc: advance-next pc end
		w: as red-word! pc
		if all [T_WORD?(w) k_keep = symbol/resolve w/symbol][
			ADD_NODE_FLAGS(c RST_AS_KEEP)
			pc: advance-next pc end
		]
		pc: parse-expr pc end :e ctx
		c/expr: as rst-expr! e/value
		expr/value: as int-ptr! c
		pc
	]

	parse-declare: func [
		KEYWORD_FN_SPEC
		/local
			d	[declare!]
			e	[ptr-value!]
	][
		declare_accept: func [ACCEPT_FN_SPEC][
			v/visit-declare self data
		]
		d: xmalloc(declare!)
		SET_NODE_TYPE(d RST_DECLARE)
		d/token: pc
		d/accept: :declare_accept
		d/data-idx: -1
		d/blkref: cur-blk

		pc: advance-next pc end
		pc: fetch-type pc end :e no
		d/typeref: as cell! e/value
		expr/value: as int-ptr! d
		pc
	]

	parse-unary: func [
		pc		[cell!]
		end		[cell!]
		expr	[ptr-ptr!]
		ctx		[context!]
		return: [cell!]
		/local
			e	[unary!]
			pv	[ptr-value!]
	][
		e: xmalloc(unary!)
		e/token: pc
		pc: advance-next pc end
		pc: parse-expr pc end :pv ctx
		e/expr: as rst-expr! pv/value
		expr/value: as int-ptr! e
		pc
	]

	parse-alias: func [
		pc		[cell!]
		end		[cell!]
		ctx		[context!]
		return: [cell!]
		/local
			name	[red-word!]
			sym		[integer!]
			val		[ptr-ptr!]
			e		[ptr-value!]
			t		[unresolved-type!]
	][
		name: as red-word! pc
		sym: symbol/resolve name/symbol
		val: hashmap/get ctx/typecache sym
		if val <> null [
			throw-error [pc "redefine type"]
		]

		pc: advance-next pc + 1 end
		pc: fetch-type pc end :e no

		t: xmalloc(unresolved-type!)
		SET_TYPE_KIND(t RST_TYPE_UNRESOLVED)
		t/typeref: as cell! e/value
		hashmap/put ctx/typecache sym as int-ptr! t
		pc
	]

	parse-size?: func [
		KEYWORD_FN_SPEC
		/local
			e	 [sizeof!]
			err? [logic!]
			pv	 [ptr-value!]
	][
		sizeof_accept: func [ACCEPT_FN_SPEC][
			v/visit-size? self data
		]
		err?: ctx/throw-error?
		ctx/throw-error?: no

		e: as sizeof! malloc size? bin-op!	;@@ may convert it to bin-op! in type-checker
		SET_NODE_TYPE(e RST_SIZEOF)
		e/token: pc
		e/accept: :sizeof_accept
		pc: advance-next pc end
		pc: parse-expr pc end :pv ctx
		e/expr: as rst-expr! pv/value
		expr/value: as int-ptr! e

		ctx/throw-error?: err?

		if null? e/expr [	;-- not an expression, may be a type
			pc: fetch-type pc end :pv yes
			e/expr: as rst-expr! pv/value
			ADD_NODE_FLAGS(e RST_SIZE_TYPE)
		]
		pc
	]

	parse-not: func [
		KEYWORD_FN_SPEC
		/local
			e	[unary!]
	][
		not_accept: func [ACCEPT_FN_SPEC][
			v/visit-not self data
		]
		pc: parse-unary pc end expr ctx

		e: as unary! expr/value
		e/accept: :not_accept
		SET_NODE_TYPE(e RST_NOT)
		pc
	]

	parse-null: func [
		KEYWORD_FN_SPEC
		/local
			e	[rst-expr!]
	][
		null_accept: func [ACCEPT_FN_SPEC][
			v/visit-literal self data
		]
		e: xmalloc(rst-expr!)
		SET_NODE_TYPE(e RST_NULL)
		e/token: pc
		e/accept: :null_accept
		e/type: type-system/null-type

		expr/value: as int-ptr! e
		pc
	]

	parse-until: func [
		KEYWORD_FN_SPEC
		/local
			w		[while!]
	][
		until_accept: func [ACCEPT_FN_SPEC][
			v/visit-until self data
		]
		w: as while! malloc size? while!
		SET_NODE_TYPE(w RST_UNTIL)
		w/token: pc
		w/accept: :until_accept

		pc: expect-next pc end TYPE_BLOCK
		w/body-blk: as red-block! pc
		w/body: parse-block as red-block! pc ctx
		expr/value: as int-ptr! w
		pc
	]

	parse-loop: func [
		KEYWORD_FN_SPEC
			/local
			w		[while!]
			pv		[ptr-value!]
	][
		loop_accept: func [ACCEPT_FN_SPEC][
			v/visit-loop self data
		]
		w: as while! malloc size? while!
		SET_NODE_TYPE(w RST_LOOP)
		w/token: pc
		w/accept: :loop_accept

		pc: advance-next pc end
		w/cond-blk: as red-block! pc
		pc: parse-expr pc end :pv ctx
		w/cond: as rst-stmt! pv/value

		pc: expect-next pc end TYPE_BLOCK
		w/body-blk: as red-block! pc
		w/body: parse-block as red-block! pc ctx
		expr/value: as int-ptr! w
		pc
	]

	parse-case: func [
		KEYWORD_FN_SPEC
		/local
			c		[case!]
			blk		[red-block!]
			p		[cell!]
			s-tail	[cell!]
			e		[ptr-value!]
			if-expr	[if!]
			cur-if	[if!]
			saved-blk [red-block!]
	][
		case_accept: func [ACCEPT_FN_SPEC][
			v/visit-case self data
		]

		blk: as red-block! expect-next pc end TYPE_BLOCK
		p: block/rs-head blk
		s-tail: block/rs-tail blk
		if p = s-tail [throw-error [pc "empty case block"]]

		c: xmalloc(case!)
		SET_NODE_TYPE(c RST_CASE)
		c/token: pc
		c/accept: :case_accept

		enter-block(blk)
		p: _parse-if p s-tail :e ctx no
		p: p + 1
		if-expr: as if! e/value
		c/cases: if-expr
		cur-if: if-expr
		while [p < s-tail][
			p: _parse-if p s-tail :e ctx no
			if-expr: as if! e/value	
			cur-if/f-branch: as rst-stmt! if-expr
			cur-if: if-expr
			p: p + 1
		]
		exit-block

		expr/value: as int-ptr! c
		as cell! blk
	]

	parse-switch: func [
		KEYWORD_FN_SPEC
		/local
			s		[switch!]
			c		[switch-case!]
			cur		[switch-case!]
			cases	[switch-case! value]
			e		[rst-expr!]
			cur-e	[rst-expr!]
			ev		[rst-expr! value]
			ty		[integer!]
			pv		[ptr-value!]
			blk		[red-block!]
			p		[cell!]
			s-tail	[cell!]
			w		[red-word!]
			saved-blk [red-block!]
	][
		switch_accept: func [ACCEPT_FN_SPEC][
			v/visit-switch self data
		]
	
		s: xmalloc(switch!)
		SET_NODE_TYPE(s RST_SWITCH)
		s/token: pc
		s/accept: :switch_accept

		pc: advance-next pc end		;-- skip keyword switch
		pc: parse-expr pc end :pv ctx
		s/expr: as rst-expr! pv/value

		blk: as red-block! expect-next pc end TYPE_BLOCK
		p: block/rs-head blk
		s-tail: block/rs-tail blk
		if p = s-tail [throw-error [blk "empty switch block"]]

		enter-block(blk)
		cur: :cases
		cur/next: null
		while [p < s-tail][
			w: as red-word! p
			if all [T_WORD?(w) k_default = symbol/resolve w/symbol][	;-- must be last case
				p: expect-next p s-tail TYPE_BLOCK
				c: xmalloc(switch-case!)
				c/token: p
				c/body: parse-block as red-block! p ctx
				s/defcase: c
				if p + 1 <> s-tail [throw-error [p "wrong syntax in SWITCH block"]]
				break
			]

			ev/next: null
			cur-e: :ev
			while [all [p < s-tail TYPE_OF(p) <> TYPE_BLOCK]][
				p: parse-expr p s-tail :pv ctx
				e: as rst-expr! pv/value
				ty: NODE_TYPE(e)
				if all [ty <> RST_INT ty <> RST_BYTE][
					throw-error [p "expect integer! or byte! literal value"]
				]
				cur-e/next: e
				cur-e: e
				p: p + 1
			]
			if null? ev/next [throw-error [p - 1 "missing case expression in SWITCH"]]

			p: expect p TYPE_BLOCK
			c: xmalloc(switch-case!)
			c/token: p
			c/body: parse-block as red-block! p ctx
			c/expr: ev/next

			cur/next: c
			cur: c
			p: p + 1
		]
		exit-block

		s/cases: cases/next
		expr/value: as int-ptr! s
		as cell! blk
	]

	parse-throw: func [
		KEYWORD_FN_SPEC
		/local
			e	[unary!]
	][
		throw_accept: func [ACCEPT_FN_SPEC][
			v/visit-throw self data
		]
		pc: parse-unary pc end expr ctx

		e: as unary! expr/value
		e/accept: :throw_accept
		SET_NODE_TYPE(e RST_THROW)
		expr/value: as int-ptr! e
		pc
	]

	parse-catch: func [
		KEYWORD_FN_SPEC
		/local
			c	[catch!]
			int [red-integer!]
	][
		catch_accept: func [ACCEPT_FN_SPEC][
			v/visit-catch self data
		]
		int: as red-integer! expect-next pc end TYPE_INTEGER
		pc: expect-next as cell! int end TYPE_BLOCK
		c: xmalloc(catch!)
		SET_NODE_TYPE(c RST_CATCH)
		c/token: pc
		c/filter: int
		c/body: parse-block as red-block! pc ctx
		c/accept: :catch_accept
		expr/value: as int-ptr! c
		pc
	]

	parse-assert: func [
		KEYWORD_FN_SPEC
		/local
			e	[unary!]
	][
		assert_accept: func [ACCEPT_FN_SPEC][
			v/visit-assert self data
		]
		pc: parse-unary pc end expr ctx

		e: as unary! expr/value
		e/accept: :assert_accept
		SET_NODE_TYPE(e RST_ASSERT)
		expr/value: as int-ptr! e
		pc
	]

	parse-comment: func [
		KEYWORD_FN_SPEC
		/local
			e	[rst-stmt!]
	][
		comment_accept: func [ACCEPT_FN_SPEC][
			v/visit-comment self data
		]
		e: xmalloc(rst-stmt!)
		SET_NODE_TYPE(e RST_COMMENT)
		e/token: pc
		e/accept: :comment_accept

		expr/value: as int-ptr! e
		pc + 1
	]

	parse-with: func [
		KEYWORD_FN_SPEC
		/local
			blk		 [red-block!]
			with-ns	 [vector!]
			ns-size	 [integer!]
			c		 [context!]
			val		 [cell!]
			s-tail	 [cell!]
			saved-blk [red-block!]
	][
		blk: as red-block! advance-next pc end
		with-ns: ctx/with-ns
		if null? with-ns [
			with-ns: ptr-vector/make 4
			ctx/with-ns: with-ns
		]

		ns-size: with-ns/length

		either T_WORD?(blk) [
			c: find-context as red-word! blk ctx
			vector/append-ptr with-ns as byte-ptr! c
		][
			if TYPE_OF(blk) <> TYPE_BLOCK [throw-error [blk "expected word! or block!"]]
			val: block/rs-head blk
			s-tail: block/rs-tail blk
			enter-block(blk)
			while [val < s-tail][
				c: find-context as red-word! val ctx
				vector/append-ptr with-ns as byte-ptr! c
				val: val + 1
			]
			exit-block
		]

		pc: expect-next pc + 1 end TYPE_BLOCK
		blk: as red-block! pc
		enter-block(blk)
		val: block/rs-head blk
		s-tail: block/rs-tail blk
		while [val < s-tail][
			val: parse-statement val s-tail ctx
			val: val + 1
		]
		exit-block

		either zero? ns-size [
			vector/destroy with-ns
			ctx/with-ns: null
		][
			with-ns/length: ns-size		;-- pop back
		]
		pc
	]

	parse-use: func [
		KEYWORD_FN_SPEC
	][]

	make-logic: func [
		pc		[cell!]
		val		[logic!]
		return: [rst-expr!]
		/local
			b	[logic-literal!]
			bl	[red-logic!]
	][
		b: as logic-literal! malloc size? int-literal!
		b_accept: func [ACCEPT_FN_SPEC][
			v/visit-literal self data
		]
		SET_NODE_TYPE(b RST_LOGIC)
		bl: as red-logic! pc		;-- ensure pc is a logic!
		bl/header: TYPE_LOGIC
		bl/value: val

		b/token: pc
		b/value: val
		b/accept: :b_accept
		b/type: type-system/logic-type
		as rst-expr! b
	]

	parse-logic: func [
		;pc end expr ctx
		KEYWORD_FN_SPEC
		/local
			w	[red-word!]
			sym [integer!]
			b	[logic!]
	][
		w: as red-word! pc
		sym: symbol/resolve w/symbol
		b: either sym = k_true [true][false]
		expr/value: as int-ptr! make-logic pc b
		pc
	]

	make-native-call: func [
		pos		[cell!]
		native	[native!]
		args	[rst-expr!]
		return: [native-call!]
		/local
			e	[native-call!]
			pv	[ptr-value!]
	][
		native_accept: func [ACCEPT_FN_SPEC][
			v/visit-native-call self data
		]
		e: xmalloc(native-call!)
		SET_NODE_TYPE(e RST_NATIVE_CALL)
		e/token: pos
		e/accept: :native_accept
		e/native: native
		e/args: args
		e/type: native/ret-type
		e
	]

	parse-push: func [
		KEYWORD_FN_SPEC
		/local
			e	[native-call!]
			pv	[ptr-value!]
	][
		pc: fetch-args pc end :pv ctx 1
		e: make-native-call pc native-push as rst-expr! pv/value
		expr/value: as int-ptr! e
		pc
	]

	parse-pop: func [
		KEYWORD_FN_SPEC
		/local
			e	[native-call!]
	][
		e: make-native-call pc native-pop null
		expr/value: as int-ptr! e
		pc
	]

	parse-log-b: func [
		KEYWORD_FN_SPEC
		/local
			e	[native-call!]
			pv	[ptr-value!]
	][
		pc: fetch-args pc end :pv ctx 1
		e: make-native-call pc native-log-b as rst-expr! pv/value
		expr/value: as int-ptr! e
		pc
	]

	make-path: func [
		pos			[cell!]
		receiver	[var-decl!]
		subs		[member!]
		return: 	[path!]
		/local
			p		[path!]
	][
		path_accept: func [ACCEPT_FN_SPEC][
			v/visit-path self data
		]
		p: xmalloc(path!)
		SET_NODE_TYPE(p RST_PATH)
		p/token: pos
		p/accept: :path_accept
		p/receiver: receiver
		p/subs: subs
		p
	]

	make-member: func [
		name		[cell!]
		return:		[member!]
		/local
			m		[member!]
	][
		m: xmalloc(member!)
		SET_NODE_TYPE(m RST_MEMBER)
		m/token: name
		m/index: -1
		m
	]

	parse-struct-member: func [
		ty		[struct-type!]
		name	[cell!]
		return: [member!]
		/local
			m	[member!]
			sym [integer!]
			w	[red-word!]
			f	[struct-field!]
			i	[integer!]
	][
		m: make-member name
		w: as red-word! name
		sym: symbol/resolve w/symbol
		f: ty/fields
		i: 0
		loop ty/n-fields [
			if sym = symbol/resolve f/name/symbol [
				m/index: i
				m/type: f/type
				return m
			]
			i: i + 1
			f: f + 1
		]
		null
	]

	parse-system-path: func [
		pc		[cell!]
		end		[cell!]
		expr	[ptr-ptr!]
		ctx		[context!]
		return: [cell!]
		/local
			ty sym	[integer!]
			w		[red-word!]
			set? 	[logic!]
			path	[cell!]
			val		[cell!]
			s-tail	[cell!]
			f		[native!]
			pv		[ptr-value!]
			args	[rst-expr!]
			z? old?	[logic!]
			check-pc [subroutine!]
	][
		check-pc: [
			if any [
				val = s-tail
				TYPE_OF(w) <> TYPE_WORD
			][throw-error [pc "invalid path"]]
		]
		ty: TYPE_OF(pc)
		if ty = TYPE_GET_PATH [return null]
		path: pc
		set?: ty = TYPE_SET_PATH
		val: block/rs-head as red-block! pc
		s-tail: block/rs-tail as red-block! pc

		val: val + 1
		if TYPE_OF(val) <> TYPE_WORD [throw-error [pc "invalid path value:" val]]
		w: as red-word! val
		sym: symbol/resolve w/symbol
		val: val + 1
		w: as red-word! val
		expr/value: as int-ptr! case [
			sym = k_stack [
				check-pc
				sym: symbol/resolve w/symbol
				case [
					sym = k_top [
						either set? [
							pc: fetch-args pc end :pv ctx 1
							args: as rst-expr! pv/value
							f: set-stack-top
						][
							args: null
							f: get-stack-top
						]
						make-native-call path f args
					]
					sym = k_frame [
						either set? [
							pc: fetch-args pc end :pv ctx 1
							args: as rst-expr! pv/value
							f: set-stack-frame
						][
							args: null
							f: get-stack-frame
						]
						make-native-call path f args
					]
					sym = k_allocate [
						if set? [return null]
						z?: no
						if (val + 1) < s-tail [
							val: val + 1
							w: as red-word! val
							either all [T_WORD?(w) k_zero = symbol/resolve w/symbol][
								z?: yes
							][
								return null
							]
						]
						ctx/dyn-alloc?: yes
						pc: fetch-args pc end :pv ctx 1
						args: as rst-expr! pv/value
						args/next/next: make-logic as cell! w z?
						make-native-call path stack-allocate args
					]
					sym = k_free [
						if set? [return null]
						ctx/dyn-alloc?: yes
						pc: fetch-args pc end :pv ctx 1
						make-native-call path stack-free as rst-expr! pv/value
					]
					sym = k_align [
						ctx/dyn-alloc?: yes
						make-native-call path stack-align null
					]
					sym = k_push-all [
						ctx/dyn-alloc?: yes
						make-native-call path stack-push-all null
					]
					sym = k_pop-all [
						ctx/dyn-alloc?: yes
						make-native-call path stack-pop-all null
					]
					true [
						pc: null
						null
					]
				]
			]
			sym = k_atomic [
				check-pc
				sym: symbol/resolve w/symbol
				case [
					sym = k_load [
						pc: fetch-args pc end :pv ctx 1
						make-native-call path atomic-load as rst-expr! pv/value
					]
					sym = k_store [
						pc: fetch-args pc end :pv ctx 2
						make-native-call path atomic-store as rst-expr! pv/value
					]
					sym = k_cas [
						pc: fetch-args pc end :pv ctx 3
						make-native-call path atomic-cas as rst-expr! pv/value
					]
					sym = k_fence [make-native-call path atomic-fence null]
					true [
						f: case [
							sym = k_add [atomic-add]
							sym = k_sub [atomic-sub]
							sym = k_or  [atomic-or]
							sym = k_xor [atomic-xor]
							sym = k_and [atomic-and]
							true [null]
						]
						either f <> null [
							old?: no
							if (val + 1) < s-tail [
								val: val + 1
								w: as red-word! val
								either all [T_WORD?(w) k_old = symbol/resolve w/symbol][
									old?: yes
								][
									return null
								]
							]
							pc: fetch-args pc end :pv ctx 2
							args: as rst-expr! pv/value
							args/next/next/next: make-logic as cell! w old?
							make-native-call path f args
						][
							pc: null
							null
						]
					]
				]
			]
			sym = k_words [
				pc: null
				-1
			]
			sym = k_alias [
				check-pc
				make-sys-alias val
			]
			sym = k_pc [
				make-native-call pc system-pc null
			]
			sym = k_cpu [
				check-pc
				sym: symbol/resolve w/symbol
				case [
					sym = k_overflow? [
						make-native-call pc cpu-overflow? null
					]
					any [
						sym = k_eax sym = k_ecx sym = k_edx sym = k_ebx
						sym = k_esp sym = k_ebp sym = k_esi sym = k_edi
					][
						either set? [
							pc: fetch-args pc end :pv ctx 1
							args: as rst-expr! pv/value
							f: set-cpu-reg
						][
							args: null
							f: get-cpu-reg
						]
						make-native-call as cell! w f args
					]
					true [
						pc: null
						null
					]
				]
			]
			sym = k_io [
				pc: null
				0
			]
			sym = k_fpu [
				check-pc
				sym: symbol/resolve w/symbol
				case [
					sym = k_update [
						make-native-call pc fpu-update null
					]
					sym = k_control-word [
						either set? [
							pc: fetch-args pc end :pv ctx 1
							args: as rst-expr! pv/value
							f: fpu-set-cword
						][
							args: null
							f: fpu-get-cword
						]
						make-native-call path f args
					]
					true [
						pc: null
						null
					]
				]
			]
			true [
				pc: null
				0
			]
		]
		if val + 1 < s-tail [throw-error [pc "invalid path value:" val + 1]]
		pc
	]

	get-global-ctx: func [
		ctx		[context!]
		return: [context!]
	][
		while [ctx/parent <> null][
			ctx: ctx/parent
		]
		ctx
	]

	parse-path: func [
		pc		[cell!]
		end		[cell!]
		expr	[ptr-ptr!]	;-- a pointer to receive the expr
		ctx		[context!]
		return: [cell!]
		/local
			w		[red-word!]
			sym		[integer!]
			val pc2 [cell!]
			s-tail	[cell!]
			c		[context!]
			v		[rst-node!]
			sub		[rst-node!]
			cur		[rst-node!]
			node	[rst-node! value]
			pp		[ptr-ptr!]
			ty		[integer!]
			idx		[integer!]
			m m2	[member!]
			t		[rst-type!]
			p		[path!]
			ptr		[ptr-type!]
			int		[red-integer!]
			get? 	[logic!]
			set?	[logic!]
	][
		val: block/rs-head as red-block! pc
		s-tail: block/rs-tail as red-block! pc

		w: as red-word! val
		if k_system = symbol/resolve w/symbol [	;-- special case: system/*
			pc2: parse-system-path pc end expr ctx
			if pc2 <> null [return pc2]
			if expr/value = as int-ptr! -1 [	;-- system/words/*
				ctx: get-global-ctx ctx
				val: val + 2
				w: as red-word! val
			]
		]

		ty: TYPE_OF(pc)
		get?: ty = TYPE_GET_PATH
		set?: ty = TYPE_SET_PATH
		v: find-word w ctx -1	;-- resolve first word
		c: ctx
		if null? v [throw-error [pc "undefine symbol in path:" val]]
		ty: NODE_TYPE(v)
		if ty = RST_CONTEXT [
			while [
				val: val + 1
				w: as red-word! val
				all [
					val < s-tail
					T_WORD?(w)
				]
			][
				sym: symbol/resolve w/symbol
				c: as context! v
				pp: hashmap/get c/decls sym
				either pp <> null [
					v: as rst-node! pp/value
					ty: NODE_TYPE(v)
					if ty <> RST_CONTEXT [break]
				][
					throw-error [pc "undefine symbol in path:" w]
				]
			]
		]
		if val = s-tail [throw-error [pc "invalid path"]]	;-- invalid case: ctx1/ctx2
		either val + 1 = s-tail [
			if all [ty <> RST_FUNC ty <> RST_VAR_DECL][
				throw-error [pc "invalid path value:" val]	;-- invalid case: ctx/struct
			]
			either get? [
				expr/value: as int-ptr! make-get-ptr pc as rst-expr! v
			][
				switch ty [
					RST_FUNC		[
						either set? [
							expr/value: as int-ptr! v
						][
							pc: parse-call pc end as fn! v expr ctx
						]
					]
					RST_VAR_DECL	[expr/value: as int-ptr! make-variable as var-decl! v pc]
					default			[throw-error [pc "invalid path"]]
				]
			]
		][
			if ty <> RST_VAR_DECL [throw-error [pc "invalid path"]]

			t: type-checker/infer-type as var-decl! v ctx
			cur: :node
			val: val + 1
			while [val < s-tail][
				switch TYPE_KIND(t) [
					RST_TYPE_STRUCT [
						if TYPE_OF(val) <> TYPE_WORD [
							throw-error [pc "expect a word for struct member" val]
						]
						m: parse-struct-member as struct-type! t val
						t: m/type
						sub: as rst-node! m
					]
					RST_TYPE_PTR RST_TYPE_ARRAY [
						idx: 0
						m: make-member val
						switch TYPE_OF(val) [
							TYPE_WORD [
								w: as red-word! val
								sym: symbol/resolve w/symbol
								either k_value = sym [
									idx: 0
								][
									sub: find-word w ctx -1
									case [
										null? sub [throw-error [pc "wrong index value" val]]
										NODE_TYPE(sub) = RST_VAR_DECL [
											m/expr: as rst-expr! make-variable as var-decl! sub val
										]
										NODE_TYPE(sub) = RST_MEMBER [
											m2: as member! sub
											idx: m2/index - 1
										]
										true [throw-error [pc "wrong index value" val]]
									]
								]
							]
							TYPE_INTEGER [
								int: as red-integer! val
								idx: int/value - 1
							]
							TYPE_PAREN [
								m/expr: parse-paren as red-block! val ctx
							]
							default [throw-error [pc "wrong index value" val]]
						]
						ptr: as ptr-type! t
						t: ptr/type
						m/type: t
						m/index: idx
						sub: as rst-node! m
					]
					default [throw-error [pc "invalid path"]]
				]
				if null? sub [throw-error [pc "invalid path value:" val]]
				val: val + 1
				cur/next: sub
				cur: sub
			]
			p: make-path pc as var-decl! v as member! node/next
			p/type: t
			case [
				get? [expr/value: as int-ptr! make-get-ptr pc as rst-expr! p]
				set? [expr/value: as int-ptr! p]
				true [
					either TYPE_KIND(t) = RST_TYPE_FUNC [		;-- function member in struct
						pc: parse-call pc end as fn! p expr ctx 
					][
						expr/value: as int-ptr! p
					]
				]
			]
		]
		pc
	]

	make-void-node: func [
		pos		[cell!]
		return: [rst-expr!]
		/local
			v	[rst-expr!]
	][
		v: xmalloc(rst-expr!)
		SET_NODE_TYPE(v RST_VOID)
		v/token: pos
		v/type: type-system/void-type
		v
	]

	parse-paren: func [
		blk		[red-block!]
		ctx		[context!]
		return: [rst-expr!]
		/local
			pc	[cell!]
			end [cell!]
			pv	[ptr-value!]
			saved-blk [red-block!]
	][
		pc: block/rs-head blk
		end: block/rs-tail blk
		either pc < end [
			enter-block(blk)
			pc: parse-expr pc end :pv ctx
			if pc + 1 < end [throw-error [blk "only one expression is allowed in paren"]]
			exit-block
			as rst-expr! pv/value
		][
			make-void-node as cell! blk
		]
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
			m	[member!]
			var [variable!]
			t	[rst-type!]
			int [red-integer!]
			parse-keyword [keyword-fn!]
	][
		switch TYPE_OF(pc) [
			TYPE_WORD [
				w: as red-word! pc
				v: find-word w ctx -1
				either v <> null [
					switch NODE_TYPE(v) [
						RST_FUNC		[pc: parse-call pc end as fn! v expr ctx]
						RST_VAR_DECL	[
							var: make-variable as var-decl! v pc
							t: type-checker/infer-type as var-decl! v ctx
							either FUNC_TYPE?(t) [
								var/type: t
								pc: parse-call pc end as fn! var expr ctx
							][
								expr/value: as int-ptr! var
							]
						]
						RST_MEMBER		[	;-- enum value
							m: as member! v
							int: as red-integer! m/token
							int/header: TYPE_INTEGER
							int/value: m/index
							expr/value: as int-ptr! make-int as cell! int
						]
						default			[unreachable pc]
					]
				][
					sym: symbol/resolve w/symbol
					p: hashmap/get keywords sym
					either p <> null [		;-- keyword
						parse-keyword: as keyword-fn! p/value
						pc: parse-keyword pc end expr ctx
					][
						either ctx/throw-error? [
							throw-error [pc "undefined symbol2:" w]
						][
							expr/value: null
							return pc
						]
					]
				]
			]
			TYPE_INTEGER [
				expr/value: as int-ptr! make-int pc
			]
			TYPE_CHAR [
				expr/value: as int-ptr! make-byte pc
			]
			TYPE_FLOAT [
				expr/value: as int-ptr! make-float pc
			]
			TYPE_STRING TYPE_BLOCK TYPE_BINARY [
				expr/value: as int-ptr! make-lit-array pc
			]
			TYPE_GET_WORD [
				expr/value: as int-ptr! parse-get-word pc ctx
			]
			TYPE_PAREN [
				expr/value: as int-ptr! parse-paren as red-block! pc ctx
			]
			TYPE_PATH TYPE_GET_PATH [
				pc: parse-path pc end expr ctx
			]
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
			left	[rst-expr!]
			right	[ptr-value!]
			pos		[cell!]
			op		[int-ptr!]
			val		[ptr-ptr!]
			pc2		[cell!]
			infix-fn? [logic!]
	][
		left: as rst-expr! expr/value
		while [
			pc2: pc + 1
			all [pc2 < end T_WORD?(pc2)]
		][
			infix?: no
			infix-fn?: no
			w: as red-word! pc2
			sym: symbol/resolve w/symbol
			val: hashmap/get infix-Ops sym
			either null <> val [
				infix?: yes
				op: val/value
			][
				node: as rst-expr! find-word w ctx -1
				if node <> null [
					type: NODE_TYPE(node)
					if any [type = RST_VAR_DECL type = RST_FUNC][
						t: node/type
						if all [t <> null FN_ATTRS(t) and FN_INFIX <> 0][
							infix?: yes
							infix-fn?: yes
							op: as int-ptr! t
						]
					]
				]
			]
			either infix? [
				pos: pc2
				pc: parse-sub-expr advance-next pc2 end end :right ctx
				either infix-fn? [
					left/next: as rst-expr! right/value
					left: as rst-expr! make-fn-call pos as fn! node make-args 2 left
				][
					left: as rst-expr! make-bin-op op left as rst-expr! right/value pos
				]
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

	find-with-ns: func [
		name	[red-word!]
		ctx		[context!]
		type	[integer!]
		return: [rst-node!]
		/local
			v	[vector!]
			n	[integer!]
			p	[ptr-ptr!]
			c	[context!]
			d	[rst-node!]
	][
		v: ctx/with-ns
		n: VECTOR_SIZE?(v)
		if zero? n [return null]

		p: VECTOR_DATA(v)
		p: p + n		;-- reverse order
		loop n [
			p: p - 1
			c: as context! p/value
			d: find-in-ctx name c type
			if d <> null [return d]
		]
		null
	]

	find-in-ctx: func [
		name	[red-word!]
		ctx		[context!]
		type	[integer!]		;-- if < 0: match any type
		return: [rst-node!]
		/local
			sym [integer!]
			val [ptr-ptr!]
			d	[rst-node!]
	][
		sym: symbol/resolve name/symbol
		if ctx/with-ns <> null [
			d: find-with-ns name ctx type
			if d <> null [return d]
		]

		val: hashmap/get ctx/decls sym
		if val <> null [
			d: as rst-node! val/value
			if any [type < 0 NODE_TYPE(d) = type][return d]
		]
		null
	]

	find-word: func [
		name	[red-word!]
		ctx		[context!]
		type	[integer!]		;-- if < 0: match any type
		return: [rst-node!]
		/local
			sym [integer!]
			val [ptr-ptr!]
			d	[rst-node!]
	][
		sym: symbol/resolve name/symbol
		while [ctx <> null][
			until [
				if ctx/with-ns <> null [
					d: find-with-ns name ctx type
					if d <> null [return d]
				]

				val: hashmap/get ctx/decls sym
				ctx: ctx/parent
				any [null? ctx val <> null]
			]
			if val <> null [
				d: as rst-node! val/value
				if any [type < 0 NODE_TYPE(d) = type][return d]
			]
		]
		null
	]

	find-context: func [
		name	[red-word!]
		ctx		[context!]
		return: [context!]
		/local
			c	[context!]
	][
		c: as context! find-word name ctx RST_CONTEXT
		if null? c [throw-error [name "undeclared context"]]
		c
	]

	literal-expr?: func [
		e		[rst-expr!]
		return: [logic!]
		/local
			t	[integer!]
	][
		t: NODE_TYPE(e)
		t <= RST_DECLARE
	]

	parse-assignment: func [
		pc		[cell!]
		end		[cell!]
		out		[ptr-ptr!]
		ctx		[context!]
		return: [cell!]
		/local
			p s	[rst-stmt!]
			var [variable!]
			v	[var-decl!]
			t	[rst-expr!]
			a	[assignment!]
	][
		s: ctx/last-stmt
		p: s
		pc: _parse-assignment pc end out ctx
		while [
			s: s/next
			s <> null
		][
			a: as assignment! s
			t: a/target
			if NODE_TYPE(t) = RST_VAR [
				var: as variable! t
				v: var/decl
				if null? v/init [
					v/init: a/expr
					if all [GLOBAL_VAR?(v) literal-expr? a/expr][	;-- remove this assignment
						continue
					]
				]
			]
			p/next: s
			p: s
		]
		ctx/last-stmt: p
		pc
	]

	_parse-assignment: func [
		pc		[cell!]
		end		[cell!]
		out		[ptr-ptr!]
		ctx		[context!]
		return: [cell!]
		/local
			var		[var-decl!]
			pos		[cell!]
			s		[rst-stmt!]
			e		[rst-expr!]
	][
		e: null
		pos: pc
		switch TYPE_OF(pc) [
			TYPE_SET_WORD [
				either FUNC_CTX?(ctx) [	;-- in function context
					var: as var-decl! find-word as red-word! pc ctx RST_VAR_DECL
					if null? var [
						throw-error [pc "undefined symbol:" pc]
					]
				][	;-- global context
					var: as var-decl! find-in-ctx as red-word! pc ctx RST_VAR_DECL
					if null? var [
						var: make-var-decl pc null
						add-decl ctx pc as int-ptr! var
					]
				]
				e: as rst-expr! make-variable var pos
			]
			TYPE_SET_PATH [
				pc: parse-path pc end out ctx
				e: as rst-expr! out/value
				if pc <> pos [		;-- a system/* call
					s: as rst-stmt! e
					ctx/last-stmt/next: s
					ctx/last-stmt: s
					return pc
				]
			]
			default [
				return parse-expr pc end out ctx
			]
		]

		pc: _parse-assignment advance-next pc end end out ctx
		s: as rst-stmt! make-assignment e as rst-expr! out/value pos
		ctx/last-stmt/next: s
		ctx/last-stmt: s
		pc
	]

	parse-statement: func [
		pc		[cell!]
		end		[cell!]
		ctx		[context!]
		return: [cell!]
		/local
			pc2 [cell!]
			w	[red-word!]
			sym [integer!]
			ptr [ptr-value!]
			s	[rst-stmt!]
			ty	[integer!]
			c2	[context!]
			pp	[ptr-ptr!]
			d	[var-decl!]
			blk [red-block!]
			sub [sub-fn!]
			sub? [logic!]
			add? [logic!]
			saved-blk [red-block!]
	][
		add?: no
		ptr/value: null
		switch TYPE_OF(pc) [
			TYPE_WORD [
				w: as red-word! pc
				sym: symbol/resolve w/symbol
				pc: case [
					sym = k_with [parse-with pc end :ptr ctx]
					sym = k_use [pc]
					true [
						add?: yes
						parse-expr pc end :ptr ctx
					]
				]
			]
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
					sym = k_enum [pc: parse-enum pc end ctx]
					sym = k_import [pc: parse-imports pc end ctx]
					sym = k_export [0]
					sym = k_syscall [0]
					sym = k_script [
						pc: advance-next pc end
						if TYPE_OF(pc) = TYPE_FILE [
							compiler/script: pc
						]
					]
					true [
						add?: yes
						pc: parse-expr pc end :ptr ctx
					]
				]
			]
			TYPE_SET_WORD [
				pc2: advance-next pc end
				pc: switch TYPE_OF(pc2) [
					TYPE_WORD [
						w: as red-word! pc2
						sym: symbol/resolve w/symbol
						case [
							any [sym = k_func sym = k_function][
								fetch-func pc end ctx
							]
							sym = k_alias [
								parse-alias pc end ctx
							]
							sym = k_context [
								if FUNC_CTX?(ctx) [throw-error [pc "context has to be declared at root level"]]

								add?: yes
								pc2: expect-next pc2 end TYPE_BLOCK
								saved-blk: cur-blk
								c2: parse-context pc as red-block! pc2 ctx null
								cur-blk: saved-blk
								if c2/n-typed > ctx/n-typed [ctx/n-typed: c2/n-typed]
								ptr/value: as int-ptr! c2
								pc2
							]
							true [parse-assignment pc end :ptr ctx]
						]
					]
					TYPE_BLOCK [	;-- subroutine?
						sub?: no
						if FUNC_CTX?(ctx) [
							w: as red-word! pc
							sym: symbol/resolve w/symbol
							pp: hashmap/get ctx/decls sym
							if pp <> null [
								d: as var-decl! pp/value
								ty: NODE_TYPE(d)
								if ty = RST_SUBROUTINE [
									throw-error [pc "cannot redefine subroutine!"]
								]
								if ty = RST_VAR_DECL [
									blk: as red-block! d/typeref
									if all [blk <> null 1 = block/rs-length? blk][
										w: as red-word! block/rs-head blk
										if k_subroutine! = symbol/resolve w/symbol [
											sub?: yes
											SET_NODE_TYPE(d RST_SUBROUTINE)		;-- change type in-place
											sub: as sub-fn! d
											sub/accept: null
											sub/body: null
											sub/body-blk: as red-block! pc2
											pc: pc2
										]
									]
								]
							]
						]
						unless sub? [pc: parse-assignment pc end :ptr ctx]
						pc
					]
					default [parse-assignment pc end :ptr ctx]
				]
			]
			TYPE_SET_PATH [pc: parse-assignment pc end :ptr ctx]
			default [
				add?: yes
				pc: parse-expr pc end :ptr ctx
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

	parse-enum: func [
		pc		[cell!]
		end		[cell!]
		ctx		[context!]
		return: [cell!]
		/local
			n cnt	[integer!]
			e		[enumerator!]
			m m2	[member!]
			cur	c2	[member!]
			beg	b2	[rst-node! value]
			type	[rst-type!]
			name	[cell!]
			w		[red-word!]
			p tail	[cell!]
			int		[red-integer!]
			blk		[red-block!]
			sym		[integer!]
			val		[ptr-ptr!]
			saved-blk [red-block!]
			enum-val  [rst-node!]
	][
		name: expect-next pc end TYPE_WORD 
		blk: as red-block! expect-next name end TYPE_BLOCK

		p: block/rs-head blk
		tail: block/rs-tail blk
		if p = tail [return as cell! blk]

		e: xmalloc(enumerator!)
		type: make-enum-type name as int-ptr! e

		enter-block(blk)
		cur: as member! :beg
		n: 0
		cnt: 0
		while [p < tail][
			c2: as member! :b2
			b2/next: null
			while [all [p < tail TYPE_OF(p) = TYPE_SET_WORD]][
				m: make-member p
				m/type: type
				unless add-decl ctx p as int-ptr! m [
					throw-error [p "symbol name was already defined"]
				]
				c2/next: m
				c2: m
				cnt: cnt + 1
				p: p + 1
			]

			c2: as member! b2/next
			either null? c2 [
				m: make-member p
				m/type: type
				unless add-decl ctx p as int-ptr! m [
					throw-error [p "symbol name was already defined"]
				]
			][
				p: p - 1
			]
			switch TYPE_OF(p) [
				TYPE_WORD [
					m/index: n
				]
				TYPE_SET_WORD [
					p: advance-next p tail
					switch TYPE_OF(p) [
						TYPE_INTEGER [
							int: as red-integer! p
							n: int/value
						]
						TYPE_WORD [
							enum-val: find-word as red-word! p ctx RST_MEMBER
							if null? enum-val [throw-error [p "invalid value in enum" p]]
							m2: as member! enum-val
							n: m2/index
						]
						default [throw-error [p "invalid value in enum" p]]
					]
					m/index: n
				]
				default [throw-error [p "invalid syntax"]]
			]

			either c2 <> null [
				cur/next: c2
				until [
					m: c2
					m/index: n
					c2: c2/next
					c2 = null
				]
			][
				cur/next: m
			]
			cur: m
			cnt: cnt + 1
			n: n + 1
			p: p + 1
		]
		exit-block

		e/n-cases: cnt
		e/cases: as member! beg/next

		w: as red-word! name
		sym: symbol/resolve w/symbol
		if null <> hashmap/get ctx/typecache sym [
			throw-error [name "redefine type"]
		]
		hashmap/put ctx/typecache sym as int-ptr! type
		as cell! blk
	]

	parse-import: func [
		blk		[red-block!]
		attr	[integer!]
		lib		[cell!]
		ctx		[context!]
		/local
			p			[cell!]
			end			[cell!]
			name		[cell!]
			import-name	[cell!]
			ft			[fn-type!]
			fn			[import-fn!]
			saved-blk	[red-block!]
	][
		p: block/rs-head blk
		end: block/rs-tail blk
		if p = end [exit]

		enter-block(blk)

		while [p < end][
			name: expect p TYPE_SET_WORD
			import-name: expect-next p end TYPE_STRING
			p: expect-next import-name end TYPE_BLOCK

			fn: as import-fn! make-func name ctx yes
			fn/import-lib: lib
			fn/import-name: import-name
			ft: parse-fn-spec as red-block! p as fn! fn
			fn/type: as rst-type! ft 
			ADD_NODE_FLAGS(fn RST_IMPORT_FN)
			ADD_FN_ATTRS(ft attr)

			unless add-decl ctx name as int-ptr! fn [
				throw-error [name "symbol name was already defined"]
			]
			p: p + 1
		]

		exit-block
	]

	parse-imports: func [
		pc		[cell!]
		end		[cell!]
		ctx		[context!]
		return: [cell!]
		/local
			blk [red-block!]
			p	[cell!]
			sym [integer!]
			w	[red-word!]
			fn	[import-fn!]
			lib [cell!]
			attr [integer!]
			saved-blk [red-block!]
	][
		pc: expect-next pc end TYPE_BLOCK
		blk: as red-block! pc
		p: block/rs-head blk
		end: block/rs-tail blk
		if p = end [return pc]

		enter-block(blk)

		while [p < end][
			lib: expect p TYPE_STRING
			p: expect-next p end TYPE_WORD

			;-- calling convention
			w: as red-word! p
			attr: 0
			sym: symbol/resolve w/symbol
			attr: attr or case [
				sym = k_cdecl	 [FN_CC_CDECL]
				sym = k_stdcall	 [FN_CC_STDCALL]
				true [
					throw-error [p "unknown calling convention:" p]
					0
				]
			]

			p: expect-next p end TYPE_BLOCK
			parse-import as red-block! p attr lib ctx
			p: p + 1
		]

		exit-block
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
			end [cell!]
			ctx [context!]
	][
		cur-blk: src
		either null? f-ctx [
			ctx: make-ctx name parent no
			if parent <> null [
				unless add-decl parent name as int-ptr! ctx [
					throw-error [name "context name is already taken:" name]
				]
			]
		][ctx: f-ctx]
		pc: block/rs-head src
		end: block/rs-tail src
		while [pc < end][
			pc: parse-statement pc end ctx
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
			either T_WORD?(p) [
				sym: symbol/resolve p/symbol
				attr: attr or case [
					sym = k_cdecl	 [FN_CC_CDECL]
					sym = k_stdcall	 [FN_CC_STDCALL]
					sym = k_variadic [FN_VARIADIC]
					sym = k_typed	 [FN_TYPED]
					sym = k_infix	 [FN_INFIX]
					sym = k_callback [FN_CALLBACK]
					sym = k_custom	 [FN_CUSTOM]
					sym = k_catch	 [FN_CATCH]
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
			ty	[integer!]
			cur	[var-decl!]
			blk [red-block!]
			list [var-decl! value]
			add-locals [subroutine!]
	][
		add-locals: [
			until [
				if T_WORD?(t) [
					cur/next: make-var-decl t blk
					cur: cur/next
					ADD_NODE_FLAGS(cur RST_VAR_LOCAL)
				]
				t: t - 1
				n: n - 1
				zero? n
			]
		]
		list/next: null
		cur: :list
		n: 0
		while [p < end][
			ty: TYPE_OF(p)
			case [
				any [ty = TYPE_WORD ty = TYPE_STRING][n: n + 1]
				ty = TYPE_BLOCK [
					if zero? n [throw-error [p "missing locals"]]
					t: p - 1
					blk: as red-block! p
					add-locals
				]
				true [throw-error [p "invalid locals:" p]]
			]
			p: p + 1
		]
		if n > 0 [
			t: p - 1
			blk: null
			add-locals
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
			ty	 [integer!]
			saved-blk [red-block!]
	][
		ft: as fn-type! malloc size? fn-type!
		SET_TYPE_KIND(ft RST_TYPE_FUNC)
		ft/spec: spec

		p: block/rs-head spec
		end: block/rs-tail spec

		p: skip p end TYPE_STRING			;-- skip doc strings

		if p = end [return ft]

		if T_BLOCK?(p) [					;-- attributes
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
			ty: TYPE_OF(w)
			case [
				;; param = word "[" type "]" doc-string?
				all [s = 0 ty = TYPE_WORD][
					p2: expect-next p end TYPE_BLOCK
					cur/next: make-var-decl p as red-block! p2
					cur: cur/next
					flag: RST_VAR_PARAM or RST_VAR_LOCAL
					ADD_NODE_FLAGS(cur flag)
					p: p2 + 1
					ft/n-params: ft/n-params + 1
				]
				;; return-spec = return: "[" type "]" doc-string?
				all [s < 1 ty = TYPE_SET_WORD k_return = symbol/resolve w/symbol][
					s: 1
					p: expect-next as cell! w end TYPE_BLOCK
					ft/ret-typeref: as red-block! p
					p: p + 1
				]
				;; local-var = word+ ("[" type "]")? doc-string?
				all [s < 2 ty = TYPE_REFINEMENT k_local = symbol/resolve w/symbol fn <> null][
					s: 2
					p: parse-local as cell! w + 1 end fn
				]
				true [throw-error [w "invalid func spec" w]]
			]
			w: as red-word! skip p end TYPE_STRING
		]
		exit-block

		case [
			FN_VARIADIC?(ft) [ft/n-params: -1]
			FN_TYPED?(ft) [ft/n-params: -2]
			true [0]
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
		fn: make-func pc ctx no
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