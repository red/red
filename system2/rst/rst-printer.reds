Red/System [
	File: 	 %rst-printer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

rst-printer: context [
	printer: declare visitor!

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

	visit-switch: func [e [switch!] i [integer!]][
		do-i i prin "switch "
		e/expr/accept as int-ptr! e/expr printer as int-ptr! i + 1
	]

	visit-break: func [b [break!] i [integer!]][
		do-i i prin "break"
	]

	visit-continue: func [v [continue!] i [integer!]][
		do-i i prin "continue"
	]

	visit-return: func [r [return!] i [integer!]][
		do-i i prin "return "
		r/expr/accept as int-ptr! r/expr printer null
	]

	visit-exit: func [r [exit!] i [integer!]][
		do-i i prin "exit"
	]

	visit-comment: func [r [rst-stmt!] i [integer!]][
		0
	]

	visit-fn-call: func [fc [fn-call!] i [integer!] /local arg [rst-expr!]][
		do-i i prin-token fc/token prin " ["
		arg: fc/args
		while [arg <> null][
			arg/accept as int-ptr! arg printer null
			prin " "
			arg: arg/next
		]
		prin "]"
	]

	visit-bin-op: func [e [bin-op!] i [integer!]][
		do-i i e/left/accept as int-ptr! e/left printer null prin " "
		prin-token e/token prin " "
		e/right/accept as int-ptr! e/right printer null
	]

	printer/visit-assign:	as visit-fn! :visit-assign
	printer/visit-literal:	as visit-fn! :visit-literal
	printer/visit-bin-op:	as visit-fn! :visit-bin-op
	printer/visit-var:		as visit-fn! :visit-var
	printer/visit-fn-call:	as visit-fn! :visit-fn-call
	printer/visit-if:		as visit-fn! :visit-if
	printer/visit-while:	as visit-fn! :visit-while
	printer/visit-break:	as visit-fn! :visit-break
	printer/visit-continue:	as visit-fn! :visit-continue
	printer/visit-return:	as visit-fn! :visit-return
	printer/visit-exit:		as visit-fn! :visit-exit
	printer/visit-comment:	as visit-fn! :visit-comment
	printer/visit-case:		as visit-fn! :visit-case
	printer/visit-switch:	as visit-fn! :visit-switch
	printer/visit-not:		as visit-fn! :visit-not
	printer/visit-size?:	as visit-fn! :visit-size?
	printer/visit-cast:		as visit-fn! :visit-cast

	do-i: func [i [integer!]][
		loop i [prin "    "]
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
		until [
			print-context ctx 0
			ctx: ctx/next
			null? ctx
		]
	]

	print-context: func [
		ctx		[context!]
		indent	[integer!]
		/local
			child [context!]
	][
		do-i indent prin "context "
		if NODE_FLAGS(ctx) and RST_FN_CTX <> 0 [prin "func:"]
		prin-token ctx/token prin " [^/"
		print-decls ctx/decls indent + 1
		print-stmts ctx/stmts indent + 1
		child: ctx/child
		while [child <> null][
			print-context child indent + 1
			child: child/next
		]
		do-i indent print-line "]"
	]
]