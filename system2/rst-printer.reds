Red/System [
	File: 	 %rst-printer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

rst-printer: context [
	printer: declare visitor!
	visit-assign: func [node [int-ptr!] data [int-ptr!] return: [int-ptr!]][
		null
	]
	printer/visit-assign: :visit-assign

	do-i: func [i [integer!]][
		loop i [prin "    "]
	]

	print-stmts: func [
		stmt	[rst-stmt!]
		indent	[integer!]
	][
		while [stmt <> null][
			stmt/accept as int-ptr! stmt printer as int-ptr! indent
			stmt: stmt/next
		]
	]

	print-decls: func [
		decl	[int-ptr!]
		indent	[integer!]
	][
		0
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