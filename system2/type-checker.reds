Red/System [
	File: 	 %type-checker.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#include %type-system.reds

type-checker: context [
	checker: declare visitor!

	infer-type: func [
		var		[var-decl!]
		ctx		[context!]
		/local
			type [rst-type!]
	][
		assert var/init <> null
		type: as rst-type! var/init/accept as int-ptr! var/init checker null
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
		as rst-type! NODE_TYPE(e)
	]

	visit-bin-op: func [bin [bin-op!] expected [rst-type!] return: [rst-type!]][
		null
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