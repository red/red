Red/System [
	File: 	 %ir-printer.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

ir-printer: context [
	blocks: as vector! 0

	indent: func [
		i	[integer!]
	][
		loop i [prin "    "]
	]

	nl: does [print lf]
	sp: does [prin " "]

	prin-blk: func [b [basic-block!]][
		print ["#" b]
	]

	prin-ins: func [i [instr!]][
		print ["@" i]
	]

	print-instr: func [
		i		[instr!]
		/local
			args [ptr-array!]
			uses [df-edge!]
			p	 [ptr-ptr!]
			n	 [integer!]
			has-input? [logic!]
	][
		indent 2
		has-input?: yes
		prin-ins i
		sp
		prin switch INSTR_OPCODE(i) [
			INS_IF ["if "]
			INS_PHI ["phi "]
			INS_GOTO ["goto "]
			INS_SWITCH ["switch "]
			OP_DEFAULT_VALUE ["default value "]
			default [
				has-input?: no
				">Invalid INSTR<"
			]
		]
		if has-input? [
			args: i/inputs
			if all [args <> null args/length > 0][
				prin "("
				p: ARRAY_DATA(args)
				n: 0
				loop args/length [
					if n > 0 [prin ", "]
					print-df-edge as df-edge! p/value
					n: n + 1
					p: p + 1
				]
				prin ") "
			]
		]
	]

	print-end: func [
		i		[instr!]
		/local
			ii	[instr-end!]
			s	[ptr-array!]
			p	[ptr-ptr!]
	][
		print-instr i nl
		indent 3
		ii: as instr-end! i
		s: ii/succs
		p: ARRAY_DATA(s)
		switch INSTR_OPCODE(i) [
			INS_GOTO [
				prin "-> "
				print-dest as cf-edge! p/value nl
			]
			INS_IF [
				assert s/length = 2
				prin " true -> "
				print-dest as cf-edge! p/value nl
				indent 3
				prin " false -> "
				p: p + 1
				print-dest as cf-edge! p/value nl
			]
			default [0]
		]
	]

	print-df-edge: func [
		e		[df-edge!]
	][
		either any [null? e null? e/dst][
			prin "null"
		][
			prin-ins e/dst
		]
	]

	print-cf-edge: func [
		e		[cf-edge!]
	][
		prin " "
		either null? e [prin "<null>"][
			prin-ins as instr! e/src
			prin " -> "
			prin-blk e/dst
		]
	]

	print-dest: func [
		e		[cf-edge!]
	][
		either null? e/dst [prin "null"][
			prin-blk e/dst
		]
	]

	print-block: func [
		bb			[basic-block!]
		/local
			p		[ptr-ptr!]
			preds	[ptr-array!]
			i		[instr!]
	][
		indent 1
		prin "block " prin-blk bb
		preds: bb/preds
		p: ARRAY_DATA(preds)
		prin " preds:"
		loop preds/length [
			print-cf-edge as cf-edge! p/value
			p: p + 1
		]
		nl
		i: bb/next
		while [all [i <> null i <> bb]][
			either INSTR_END?(i) [
				print-end i
			][
				print-instr i
			]
			nl
			i: i/next
		]
	]
	
	print-blocks: func [
		start-bb	[basic-block!]
		/local
			p		[ptr-ptr!]
	][
		ir-graph/bfs-blocks start-bb blocks
		p: as ptr-ptr! blocks/data
		loop blocks/length [
			print-block as basic-block! p/value
			p: p + 1
		]
	]

	print-graph: func [
		ir		[ir-fn!]
	][
		if null? blocks [blocks: vector/make size? int-ptr! 100]
		
		print-line "SSA IR:"
		print-blocks ir/start-bb
		print-line "------"
	]
]