Red/System [
	File: 	 %rst-printer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

rst-printer: context [
	printer: declare visitor!

	visit-assign: func [
		;node [int-ptr!] data [int-ptr!] return: [int-ptr!]
		VISIT_FN_SPEC
		/local
			a		[assignment!]
			indent	[integer!]
	][
		a: as assignment! node
		indent: as-integer data
		do-i indent prin-token a/target/token prin ": "
		a/expr/accept as int-ptr! a/expr printer null
		null
	]

	visit-literal: func [
		VISIT_FN_SPEC
		/local
			e		[rst-expr!]
			i		[integer!]
	][
		e: as rst-expr! node
		i: as-integer data
		do-i i prin-token e/token
		null
	]

	visit-bin-op: func [
		;node [int-ptr!] data [int-ptr!] return: [int-ptr!]
		VISIT_FN_SPEC
		/local
			e		[bin-op!]
			i		[integer!]
	][
		e: as bin-op! node
		i: as-integer data
		do-i i e/left/accept as int-ptr! e/left printer null prin " "
		prin-token e/token prin " "
		e/right/accept as int-ptr! e/right printer null
		null
	]

	printer/visit-assign:	:visit-assign
	printer/visit-literal:	:visit-literal
	printer/visit-bin-op:	:visit-bin-op

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

	print-var: func [
		var		[variable!]
		indent	[integer!]
		/local
			expr [rst-expr!]
	][
		do-i indent prin-token var/token prin ": "
		if var/init <> null [
			expr: as rst-expr! var/init
			expr/accept as int-ptr! expr printer null
		]
	]

	print-decls: func [
		decls	[int-ptr!]
		indent	[integer!]
		/local
			n		[integer!]
			kv		[int-ptr!]
			expr	[rst-expr!]
			empty?	[logic!]
	][
		n: hashmap/size? decls
		if zero? n [exit]

		empty?: yes
		do-i indent prin "decls ["
		kv: null
		loop n [
			kv: hashmap/next decls kv
			expr: as rst-expr! kv/2
			if NODE_TYPE(expr) <> RST_CONTEXT [
				empty?: no
				prin "^/"
				print-var as variable! expr indent + 1
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
		do-i indent prin "context " prin-token ctx/token prin " [^/"
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