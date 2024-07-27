Red/System [
	File: 	 %type-checker.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

type-checker: context [
	checker: declare visitor!

	infer-type: func [
		var		[var-decl!]
		ctx		[context!]
		/local
			type [rst-type!]
	][
		either var/init <> null [
			assert null? var/typeref
			var/type: as rst-type! var/init/accept as int-ptr! var/init checker null
		][
			assert var/typeref <> null
			0
		]
	]

	;; check assignment
	visit-assign: func [
		a [assignment!] expected [rst-type!] return: [rst-type!]
		/local
			type	[rst-type!]
	][
		type: as rst-type! a/expr/accept as int-ptr! a/expr checker null	;-- expression's type
		
		null
	]

	visit-literal: func [e [literal!] expected [rst-type!] return: [rst-type!]][
		e/type
	]

	visit-bin-op: func [bin [bin-op!] expected [rst-type!] return: [rst-type!]
		/local
			op	[fn-type!]
			ltype rtype [rst-type!]
	][
		ltype: as rst-type! bin/left/accept as int-ptr! bin/left checker as int-ptr! expected
		rtype: as rst-type! bin/right/accept as int-ptr! bin/right checker as int-ptr! expected
		op: either NODE_FLAGS(bin) and RST_INFIX_OP <> 0 [
			lookup-infix-op as-integer bin/op ltype rtype
		][
			assert bin/op <> null
			as fn-type! bin/op
		]
		null
	]

	lookup-infix-op: func [
		op			[integer!]
		ltype		[rst-type!]
		rtype		[rst-type!]
		return: 	[fn-type!]
		/local
			utype	[rst-type!]
			ft		[fn-type!]
	][
		ft: null
		case [
			all [op >= RST_OP_ADD op <= RST_OP_XOR][
				utype: type-system/unify ltype rtype
				if null? utype [utype: ltype]
				ft: switch TYPE_KIND(utype) [
					RST_TYPE_INT [op-cache/get-int-op op utype]
					RST_TYPE_FLOAT [
						either op <= RST_OP_DIV [
							op-cache/get-float-op op utype
						][null]
					]
					RST_TYPE_PTR [null]
				]
			]
			all [INT_TYPE?(ltype) op >= RST_OP_SHL op <= RST_OP_SHR][
				ft: op-cache/get-int-op op ltype
			]
			all [op >= RST_OP_EQ op <= RST_OP_GTEQ][
				utype: type-system/unify ltype rtype
				if null? utype [
					if all [INT_TYPE?(ltype) INT_TYPE?(rtype)][
						ft: null
					]
					if FLOAT_TYPE?(rtype) [utype: rtype]
				]
			]
			true [null]
		]
		ft
	]

	checker/visit-assign:	as visit-fn! :visit-assign
	checker/visit-literal:	as visit-fn! :visit-literal
	checker/visit-bin-op:	as visit-fn! :visit-bin-op

	check: func [
		ctx		[context!]
		/local
			stmt	[rst-stmt!]
			n		[integer!]
			kv		[int-ptr!]
			var		[var-decl!]
			type	[integer!]
			decls	[int-ptr!]
	][
		if null? ctx [exit]

		decls: ctx/decls
		n: hashmap/size? decls
		kv: null
		loop n [
			kv: hashmap/next decls kv
			var: as var-decl! kv/2
			type: NODE_TYPE(var)
			if type = RST_VAR_DECL [infer-type var ctx]
		]

		stmt: ctx/stmts
		while [
			stmt: stmt/next
			stmt <> null
		][
			stmt/accept as int-ptr! stmt checker as int-ptr! ctx
		]
		check ctx/child
		check ctx/next
	]
]