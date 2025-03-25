Red/System [
	File: 	 %rst-printer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

rst-printer: context [
	printer: declare visitor!
	init: does [
		printer/visit-assign:		as visit-fn! :visit-assign
		printer/visit-literal:		as visit-fn! :visit-literal
		printer/visit-lit-array:	as visit-fn! :visit-lit-array
		printer/visit-bin-op:		as visit-fn! :visit-bin-op
		printer/visit-var:			as visit-fn! :visit-var
		printer/visit-fn-call:		as visit-fn! :visit-fn-call
		printer/visit-if:			as visit-fn! :visit-if
		printer/visit-while:		as visit-fn! :visit-while
		printer/visit-until:		as visit-fn! :visit-until
		printer/visit-break:		as visit-fn! :visit-break
		printer/visit-continue:		as visit-fn! :visit-continue
		printer/visit-return:		as visit-fn! :visit-return
		printer/visit-comment:		as visit-fn! :visit-comment
		printer/visit-case:			as visit-fn! :visit-case
		printer/visit-switch:		as visit-fn! :visit-switch
		printer/visit-not:			as visit-fn! :visit-not
		printer/visit-size?:		as visit-fn! :visit-size?
		printer/visit-cast:			as visit-fn! :visit-cast
		printer/visit-declare:		as visit-fn! :visit-declare
		printer/visit-get-ptr:		as visit-fn! :visit-get-ptr
		printer/visit-path:			as visit-fn! :visit-path
		printer/visit-any-all:		as visit-fn! :visit-any-all
		printer/visit-throw:		as visit-fn! :visit-throw
		printer/visit-catch:		as visit-fn! :visit-catch
		printer/visit-native-call:	as visit-fn! :visit-native-call
		printer/visit-assert:		as visit-fn! :visit-assert
		printer/visit-context:		as visit-fn! :visit-context
	]

	prin-block: func [blk [red-block!]][
		#call [prin-block blk -1]
	]

	visit-assign: func [a [assignment!] i [integer!]][
		do-i i prin-token a/target/token prin " "
		a/expr/accept as int-ptr! a/expr printer null
	]

	visit-literal: func [e [rst-expr!] i [integer!]][
		do-i i prin-token e/token
	]

	visit-lit-array: func [e [rst-expr!] i [integer!]][
		do-i i prin-token e/token
	]

	visit-var: func [v [variable!] i [integer!]][
		do-i i prin-token v/token
	]

	visit-if: func [e [if!] i [integer!]][
		do-i i prin either e/false-blk <> null ["either"]["if"] prin " "
		e/cond/accept as int-ptr! e/cond printer null
		prin " "
		prin-block e/true-blk
		if e/false-blk <> null [
			prin-block e/false-blk
		]
	]

	visit-while: func [w [while!] i [integer!]][
		do-i i prin-token w/token prin " "
		prin-block w/cond-blk
		prin-block w/body-blk
	]

	visit-until: func [w [while!] i [integer!]][
		do-i i prin-token w/token prin " "
		prin-block w/body-blk
	]

	visit-case: func [e [case!] i [integer!] /local c [if!]][
		do-i i print-line "case ["
		c: e/cases
		while [c <> null][
			c/cond/accept as int-ptr! c/cond printer as int-ptr! i + 1
			prin " "
			prin-block c/true-blk
			print lf
			c: as if! c/f-branch
		]
		do-i i print-line "]"
	]

	visit-not: func [b [break!] i [integer!]][
		do-i i prin "not"
	]

	visit-size?: func [b [break!] i [integer!]][
		do-i i prin "size?"
	]

	visit-cast: func [c [cast!] i [integer!]][
		do-i i prin "as "
		prin-token c/typeref prin " "
		c/expr/accept as int-ptr! c/expr printer null
	]

	visit-declare: func [c [cast!] i [integer!]][
		do-i i prin "declare "
		prin-token c/typeref prin " "
	]

	visit-switch: func [e [switch!] i [integer!] /local cases [switch-case!]][
		do-i i prin "switch "
		e/expr/accept as int-ptr! e/expr printer null
		cases: e/cases
		while [cases <> null][
			print lf
			do-i i + 1
			cases/expr/accept as int-ptr! cases/expr printer null
			prin " "
			prin-block as red-block! cases/token
			cases: cases/next
		]
		if e/defcase <> null [
			print lf
			do-i i + 1
			prin "default "
			cases: e/defcase
			prin-block as red-block! cases/token
		]
	]

	visit-break: func [b [break!] i [integer!]][
		do-i i prin "break"
	]

	visit-continue: func [v [continue!] i [integer!]][
		do-i i prin "continue"
	]

	visit-return: func [r [return!] i [integer!]][
		do-i i
		either null? r/expr [
			prin "exit"
		][
			prin "return "
			r/expr/accept as int-ptr! r/expr printer null
		]
	]

	visit-path: func [p [path!] i [integer!]][
		do-i i prin-token p/token
	]

	visit-any-all: func [p [path!] i [integer!]][
		do-i i prin "anyall"
	]

	visit-comment: func [r [rst-stmt!] i [integer!]][
		0
	]

	visit-get-ptr: func [g [get-ptr!] i [integer!]][
		do-i i print "get-ptr"
	]

	visit-throw: func [r [rst-stmt!] i [integer!]][
		do-i i print "throw"
	]

	visit-catch: func [c [catch!] i [integer!]][
		do-i i print "catch [^/"
		print-body c/body i + 1
		do-i i print "]"
	]

	visit-native-call: func [n [native-call!] i [integer!]][
		do-i i switch n/native/id [
			N_PUSH [print "push"]
			N_POP [print "pop"]
			N_LOG_B [0]
			N_GET_STACK_TOP [print "get stack/top"]
			N_GET_STACK_FRAME [print "get stack/frame"]
			N_SET_STACK_TOP [print "set stack/top"]
			N_SET_STACK_FRAME [print "set stack/frame"]
			N_STACK_ALIGN [0]
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
			N_ATOMIC_BIN_OP [0]
			default [0]
		]
	]

	visit-assert: func [r [rst-stmt!] i [integer!]][
		0
	]

	visit-context: func [ctx [context!] i [integer!]][
		print-context ctx i + 1
	]

	visit-fn-call: func [fc [fn-call!] i [integer!] /local arg [rst-expr!]][
		do-i i prin-token fc/token prin " ["
		if fc/args <> null [
			arg: fc/args/next
			while [arg <> null][
				arg/accept as int-ptr! arg printer null
				prin " "
				arg: arg/next
			]
		]
		prin "]"
	]

	visit-bin-op: func [e [bin-op!] i [integer!]][
		do-i i e/left/accept as int-ptr! e/left printer null prin " "
		prin-token e/token prin " "
		e/right/accept as int-ptr! e/right printer null
	]

	do-i: func [i [integer!]][
		loop i [prin "    "]
	]

	print-body: func [
		stmt	[rst-stmt!]
		indent	[integer!]
	][
		while [stmt <> null][
			stmt/accept as int-ptr! stmt printer as int-ptr! indent
			stmt: stmt/next
			prin "^/"
		]
	]

	print-stmt: func [stmt [rst-stmt!]][
		stmt/accept as int-ptr! stmt printer null
		prin "^/"
	]

	print-stmts: func [
		stmt	[rst-stmt!]
		indent	[integer!]
	][
		while [
			stmt: stmt/next
			stmt <> null
		][
			stmt/accept as int-ptr! stmt printer as int-ptr! indent
			prin "^/"
		]
	]

	print-var-decl: func [
		var		[var-decl!]
		indent	[integer!]
		/local
			expr [rst-expr!]
	][
		do-i indent prin-token var/token prin " "
		either all [
			var/init <> null
			NODE_FLAGS(var) and RST_VAR_PARAM = 0
		][
			expr: var/init
			expr/accept as int-ptr! expr printer null
		][
			prin-block var/typeref
		]
	]

	print-func: func [
		fn		[fn!]
		indent	[integer!]
		/local
			expr [rst-expr!]
			t	 [fn-type!]
	][
		do-i indent prin-token fn/token prin " func "
		t: as fn-type! fn/type
		prin-block t/spec
	]

	print-decls: func [
		decls	[int-ptr!]
		indent	[integer!]
		/local
			n		[integer!]
			kv		[int-ptr!]
			expr	[rst-expr!]
			empty?	[logic!]
			type	[integer!]
	][
		n: hashmap/size? decls
		if zero? n [exit]

		empty?: yes
		do-i indent prin "decls ["
		kv: null
		loop n [
			kv: hashmap/next decls kv
			expr: as rst-expr! kv/2
			type: NODE_TYPE(expr)
			if type <> RST_CONTEXT [
				empty?: no
				prin "^/"
			]
			switch type [
				RST_VAR_DECL [print-var-decl as var-decl! expr indent + 1]
				RST_FUNC	 [print-func as fn! expr indent + 1]
				default [0]
			]
		]
		unless empty? [prin "^/" do-i indent] print-line "]"
	]

	print-program: func [
		ctx		[context!]
	][
		probe "print-program"
		print-context ctx 0
	]

	print-context: func [
		ctx		[context!]
		indent	[integer!]
	][
		do-i indent prin "context "
		if NODE_FLAGS(ctx) and RST_FN_CTX <> 0 [prin "func:"]
		prin-token ctx/token prin " [^/"
		print-decls ctx/decls indent + 1
		print-stmts ctx/stmts indent + 1
		do-i indent print-line "]"
	]
]