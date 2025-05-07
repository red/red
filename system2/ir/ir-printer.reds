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

	prin-ins: func [i [instr!] /local c [instr-const!] v [cell!] val [val!] var [var-decl!]][
		either INSTR_OPCODE(i) = INS_CONST [
			c: as instr-const! i
			v: c/value
			
			if null? v [
				print ["null"]
				exit
			]
			switch TYPE_OF(v) [
				TYPE_ADDR [
					val: as val! v
					var: as var-decl! val/ptr
					prin-token var/token
					print ["&" val/ptr]
				]
				TYPE_INT64 [prin "int64"]
				TYPE_VOID [prin "void"]
				default [prin-token v]
			]
		][
			print ["@" i]
		]
	]

	prin-op: func [
		i		[instr-op!]
		/local
			var [var-decl!]
			fn	[fn!]
			n	[native!]
	][
		switch INSTR_OPCODE(i) [
			OP_BOOL_EQ			[prin "bool.="]
			OP_BOOL_AND			[prin "bool.and"]
			OP_BOOL_OR			[prin "bool.or"]
			OP_BOOL_NOT			[prin "bool.not"]
			OP_INT_ADD			[prin "int.add"]
			OP_INT_SUB			[prin "int.sub"]
			OP_INT_MUL			[prin "int.mul"]
			OP_INT_DIV			[prin "int.div"]
			OP_INT_MOD			[prin "int.mod"]
			OP_INT_REM			[prin "int.rem"]
			OP_INT_AND			[prin "int.and"]
			OP_INT_OR			[prin "int.or"]
			OP_INT_XOR			[prin "int.xor"]
			OP_INT_SHL			[prin "int.<<"]
			OP_INT_SAR			[prin "int.>>>"]
			OP_INT_SHR			[prin "int.>>"]
			OP_INT_EQ			[prin "int.="]
			OP_INT_NE			[prin "int.<>"]
			OP_INT_LT			[prin "int.<"]
			OP_INT_LTEQ			[prin "int.<="]
			OP_FLT_ADD			[prin "float.add"]
			OP_FLT_SUB			[prin "float.sub"]
			OP_FLT_MUL			[prin "float.mul"]
			OP_FLT_DIV			[prin "float.div"]
			OP_FLT_MOD			[prin "float.mod"]
			OP_FLT_REM			[prin "float.rem"]
			OP_FLT_ABS			[prin "float.abs"]
			OP_FLT_CEIL			[prin "float.ceil"]
			OP_FLT_FLOOR		[prin "float.floor"]
			OP_FLT_SQRT			[prin "float.sqrt"]
			OP_FLT_ROUND		[prin "float.round"]
			OP_FLT_BITEQ		[prin "float.biteq"]
			OP_FLT_EQ			[prin "float.="]
			OP_FLT_NE			[prin "float.<>"]
			OP_FLT_LT			[prin "float.<"]
			OP_FLT_LTEQ			[prin "float.<="]
			OP_INT_CAST			[prin "int-to-int"]
			OP_FLOAT_CAST		[prin "float-to-float32"]
			OP_FLOAT_PROMOTE	[prin "float32-to-float"]
			OP_BITS_VIEW		[print "bits-view"]
			OP_INT_TO_F			[prin "int-to-float"]
			OP_FLT_TO_I			[prin "float-to-int"]
			OP_DEFAULT_VALUE	[prin "default value"]
			OP_CALL_FUNC		[
				fn: as fn! i/target
				prin "call " prin-token fn/token
			]
			OP_GET_GLOBAL		[
				var: as var-decl! i/target
				prin "get " prin-token var/token
			]
			OP_SET_LOCAL
			OP_SET_GLOBAL		[
				var: as var-decl! i/target
				prin "set " prin-token var/token
			]
			OP_PTR_LOAD	[
				prin "ptr load"
			]
			OP_PTR_STORE [
				print "ptr store"
			]
			OP_PTR_ADD [print "ptr add"]
			OP_PTR_SUB [print "ptr sub"]
			OP_PTR_EQ  [print "ptr ="]
			OP_PTR_NE  [print "ptr <>"]
			OP_PTR_LT  [print "ptr <"]
			OP_PTR_LTEQ [print "ptr <="]
			OP_GET_PTR [
				print "get-ptr"
			]
			OP_GET_FIELD [
				print "get-field"
			]
			OP_SET_FIELD [
				print "set-field"
			]
			OP_CATCH_BEG [print "catch begin"]
			OP_CATCH_END [print "catch end"]
			OP_THROW [print "throw"]
			OP_TYPED_VALUE [print "typed-value"]
			OP_CALL_NATIVE [
				n: as native! i/target
				n/id
				print ["call native " n/id]
			]
			default [
				print ["unknown op " INSTR_OPCODE(i)]
			]
		]
	]

	print-instr: func [
		i		[instr!]
		/local
			args [ptr-array!]
			uses [df-edge!]
			p	 [ptr-ptr!]
			n	 [integer!]
	][
		indent 2
		prin-ins i
		sp
		prin switch INSTR_OPCODE(i) [
			INS_IF ["if "]
			INS_PHI ["phi "]
			INS_RETURN ["return "]
			INS_GOTO ["goto "]
			INS_SWITCH ["switch "]
			default [
				prin-op as instr-op! i
				" "
			]
		]

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
			prin "null-edge"
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
		bfs-blocks start-bb blocks
		p: as ptr-ptr! blocks/data
		loop blocks/length [
			print-block as basic-block! p/value
			p: p + 1
		]
	]

	print-graph: func [
		ir		[ir-fn!]
		/local
			p	[ptr-ptr!]
	][
		if null? blocks [blocks: vector/make size? int-ptr! 100]
		
		print-line "SSA IR:"
		if ir/params <> null [
			indent 1 prin "params: "
			p: ARRAY_DATA(ir/params)
			loop ir/params/length [
				prin-ins as instr! p/value sp
				p: p + 1
			]
			nl
		]
		print-blocks ir/start-bb
		print-line ""
	]
]