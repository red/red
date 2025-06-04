Red/System [
	File: 	 %lowering.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

lowering-env!: alias struct! [
	mark			[integer!]
	buffer			[dyn-array! value]	;-- dyn-array<instr!>
	new-instrs		[dyn-array! value]	;-- dyn-array<instr!>
	fn				[ir-fn!]
	cur-ctx			[ssa-ctx!]
	ssa-ctx			[ssa-ctx!]
	phis			[list!]				;-- list<instr-phi!>
]

;-- Lowering SSA IR to machine-level IR in-place
lowering: context [

	#define MARK_INS(i m) [
		i/mark: m
		i/instr: null
	]

	map: func [
		old		[instr!]
		new		[instr!]
		env		[lowering-env!]
	][
		old/mark: env/mark
		old/instr: new
		new/mark: env/mark
		replace-instr old new
		remove-instr old
	]

	map-keep: func [
		old		[instr!]
		new		[instr!]
		env		[lowering-env!]
	][
		old/mark: env/mark
		old/instr: new
		new/mark: env/mark
		replace-instr old new
	]

	map-n-keep: func [
		"map old instr to multiple instrs in new. keep the old instr."
		old		[instr!]
		new		[ptr-array!]
		env		[lowering-env!]
		/local
			fn	[ir-fn!]
			p	[ptr-ptr!]
			pp	[ptr-ptr!]
			idx [integer!]
			rps	[dyn-array!]
			i	[instr!]
	][
		p: ARRAY_DATA(new)
		either new/length = 1 [
			map old as instr! p/value env
		][
			fn: env/fn
			old/instr: null
			old/mark: fn/mark
			fn/mark: fn/mark + 1

			idx: old/mark - env/mark - 1
			rps: env/new-instrs 
			dyn-array/grow rps idx + 1
			pp: dyn-array/get-slot rps idx
			pp/value: as int-ptr! new
			if idx >= rps/length [rps/length: idx + 1]
			loop new/length [
				i: as instr! p/value
				i/mark: env/mark
				p: p + 1
			]
		]
	]

	map-n: func [
		"map old instr to multiple instrs in new"
		old		[instr!]
		new		[ptr-array!]	;-- array<instr!>
		env		[lowering-env!]
	][
		map-n-keep old new env
		kill-instr old
		remove-instr old
	]

	map-0: func [
		"map old instr to void instr"
		old		[instr!]
		env		[lowering-env!]
	][
		map-n old empty-array env
	]

	get-new-instrs: func [
		old		[instr!]
		env		[lowering-env!]
		return: [ptr-array!]
		/local
			p	[ptr-ptr!]
	][
		if old/mark = env/mark [return null]
		if old/mark > env/mark [
			p: dyn-array/get-slot env/new-instrs old/mark - env/mark - 1
			return as ptr-array! p/value
		]
		null
	]

	refresh-dests: func [
		edges	[ptr-array!]	;-- array<df-edge!>
		env		[lowering-env!]
		return: [ptr-array!]	;-- array<instr!>
		/local
			p	[ptr-ptr!]
			e	[df-edge!]
			old	[instr!]
			new [ptr-array!]
			i	[instr!]
			buf [dyn-array!]
	][
		buf: env/buffer
		dyn-array/clear buf
		p: ARRAY_DATA(edges)
		loop edges/length [
			e: as df-edge! p/value
			old: e/dst
			either null? old [
				dyn-array/append buf null
			][
				new: get-new-instrs old env
				either null? new [
					i: either old/instr <> null [old/instr][old]
					dyn-array/append buf as int-ptr! i
				][
					dyn-array/append-n buf new
				]
			]
			p: p + 1
		]
		dyn-array/to-array buf
	]

	refresh-inputs: func [
		i		[instr!]
		env		[lowering-env!]
		/local
			new [ptr-array!]
	][
		new: refresh-dests i/inputs env
		ir-graph/set-inputs i new
	]

	gen-equal: func [
		i		[instr!]
		env		[lowering-env!]
		return: [instr!]
	][
		refresh-inputs i env
		i
	]

	gen-int-cmp: func [
		i		[instr!]
		env		[lowering-env!]
		return: [instr!]
	][
		refresh-inputs i env
		i
	]

	gen-truncate: func [
		i		[instr-op!]
		type	[rst-type!]
		env		[lowering-env!]
		return: [instr!]
		/local
			w		[integer!]
			arith-w [integer!]
			trunc-i	[instr!]
			p		[ptr-ptr!]
			mark-return [subroutine!]
	][
		mark-return: [
			MARK_INS(i env/mark)
			return as instr! i
		]
		if INSTR_FLAGS(i) and F_NO_INT_TRUNC <> 0 [mark-return]
		ADD_INS_FLAGS(i F_NO_INT_TRUNC)

		w: INT_WIDTH(type)
		arith-w: target/int-width
		if w >= arith-w [mark-return]
		if all [
			target/int32-arith?
			w <= 32
		][
			if w = 32 [mark-return]
			arith-w: 32
		]

		env/cur-ctx/pt: i/next
		type: either arith-w = target/int-width [
			target/int-type
		][
			type-system/get-int-type arith-w false
		]
		trunc-i: ir-graph/add-int-cast i type i/ret-type env/cur-ctx
		map-keep as instr! i trunc-i env
		;-- trunc-i's input changed by map-keep, we need to set it back
		p: ARRAY_DATA(trunc-i/inputs)
		update-uses as df-edge! p/value as instr! i
		;; XXX
		;; e: as df-edge! p/value
		;; e/dst: as instr! i
		trunc-i
	]

	gen-truncate-op: func [
		i		[instr-op!]
		env		[lowering-env!]
	][
		refresh-inputs as instr! i env
		gen-truncate i i/ret-type env
	]

	gen-call: func [
		i		[instr!]
		env		[lowering-env!]
		/local
			old [instr!]
			op	[instr-op!]
			arr [ptr-array!]
			p	[ptr-ptr!]
			args [array-value!]
			ret-ty [rst-type!]
			inputs [ptr-array!]
	][
		inputs: refresh-dests i/inputs env
		op: as instr-op! i
		ret-ty: op/ret-type
		either all [STRUCT_VALUE?(ret-ty) 8 = type-size? ret-ty yes][
			old: i
			op: ir-graph/copy-op op
			i: ir-graph/add-op op inputs env/cur-ctx
			arr: ptr-array/make 2
			p: ARRAY_DATA(arr)
			loop 2 [
				op: ir-graph/make-op OP_RET_VALUE 0 null type-system/integer-type
				INIT_ARRAY_VALUE(args i)
				ir-graph/set-inputs as instr! op as ptr-array! :args
				insert-instr i/next as instr! op
				p/value: as int-ptr! op
				p: p + 1
			]
			map-n old arr env
		][
			ir-graph/set-inputs i inputs
		]
	]

	make-ptr-const: func [
		type	[ptr-type!]
		val		[var-decl!]
		return: [instr-const!]
		/local
			c	[instr-const!]
			v	[val!]
	][
		c: xmalloc(instr-const!)
		c/header: F_NOT_VOID << 8 or INS_CONST
		c/type: as rst-type! type
		v: xmalloc(val!)
		v/header: TYPE_ADDR
		v/ptr: as int-ptr! val
		c/value: as cell! v
		c
	]

	ptr-add: func [
		base	[instr!]
		offset	[instr!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			op		[instr-op!]
			ty		[rst-type!]
			ptypes	[ptr-ptr!]
			args	[array-2! value]
	][
		ty: instr-type? base
		;either INSTR_CONST?(offset) [
			
		;][
			ptypes: as ptr-ptr! malloc 2 * size? int-ptr!
			op: ir-graph/make-op OP_PTR_ADD 2 ptypes ty
			ptypes/value: as int-ptr! ty
			ptypes: ptypes + 1
			ptypes/value: as int-ptr! type-system/get-int-type target/int-width yes
			INIT_ARRAY_2(args base offset)
			ir-graph/add-op op as ptr-array! :args ctx
		;]
	]

	ptr-load: func [
		vtype	[rst-type!]
		base	[instr!]
		offset	[integer!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			ofs [instr!]
			int [red-integer!]
			op	[instr-op!]
			args [array-value!]
	][
		if offset <> 0 [
			int: xmalloc(red-integer!)
			int/header: TYPE_INTEGER
			int/value: offset
			ofs: as instr! ir-graph/const-int int ctx/graph
			base: ptr-add base ofs ctx
		]
		op: ir-graph/make-op OP_PTR_LOAD 0 null vtype
		INIT_ARRAY_VALUE(args base)
		ir-graph/add-op op as ptr-array! :args ctx
	]

	ptr-store: func [
		vtype	[rst-type!]		;-- value type
		base	[instr!]
		offset	[integer!]
		val		[instr!]
		ctx		[ssa-ctx!]
		return: [instr!]
		/local
			op	[instr-op!]
			ofs [instr!]
			int [red-integer!]
			args [array-2! value]
	][
		if offset <> 0 [
			int: xmalloc(red-integer!)
			int/header: TYPE_INTEGER
			int/value: offset
			ofs: as instr! ir-graph/const-int int ctx/graph
			base: ptr-add base ofs ctx
		]
		op: ir-graph/make-op OP_PTR_STORE 0 null vtype
		INIT_ARRAY_2(args base val)
		ir-graph/add-op op as ptr-array! :args ctx
	]

	norm-struct-value: func [
		vtype	[rst-type!]		;-- value type
		return: [ptr-array!]
		/local
			arr [ptr-array!]
			p	[ptr-ptr!]
			n	[integer!]
			sz	[integer!]
	][
		sz: type-size? vtype yes
		assert sz % 4 = 0

		n: sz / 4
		arr: ptr-array/make n
		p: ARRAY_DATA(arr)
		loop n [
			p/value: as int-ptr! type-system/integer-type
			p: p + 1
		]
		arr
	]

	gen-loads: func [
		vtype	[rst-type!]		;-- value type
		base	[instr!]
		offset	[integer!]
		ctx		[ssa-ctx!]
		return: [ptr-array!]
		/local
			arr [ptr-array!]
			i	[instr!]
			p	[ptr-ptr!]
			ta	[ptr-array!]
	][
		ta: null
		if STRUCT_VALUE?(vtype) [
			ta: norm-struct-value vtype
		]
		;-- TBD handle 64bit integer! on 32bit target, which will generate 2 loads
		if null? ta [
			i: ptr-load vtype base offset ctx
			arr: ptr-array/make 1
			p: ARRAY_DATA(arr)
			p/value: as int-ptr! i
			return arr
		]

		arr: ta
		p: ARRAY_DATA(ta)
		loop ta/length [
			vtype: as rst-type! p/value
			i: ptr-load vtype base offset ctx
			p/value: as int-ptr! i
			offset: offset + type-size? vtype no
			p: p + 1
		]
		arr
	]

	gen-stores: func [
		vtype	[rst-type!]		;-- value type
		base	[instr!]
		offset	[integer!]
		inputs	[ptr-array!]
		start	[integer!]		;-- start idx of args in inputs array
		ctx		[ssa-ctx!]
		/local
			p	[ptr-ptr!]
			pp	[ptr-ptr!]
			ta	[ptr-array!]
	][
		ta: null
		if STRUCT_VALUE?(vtype) [
			ta: norm-struct-value vtype
		]
		;-- TBD handle 64bit integer! on 32bit target, which will generate 2 loads
		if null? ta [
			pp: ARRAY_DATA(inputs)
			pp: pp + start
			ptr-store vtype base offset as instr! pp/value ctx
			exit
		]

		pp: ARRAY_DATA(inputs)
		p: ARRAY_DATA(ta)
		pp: pp + start
		loop ta/length [
			vtype: as rst-type! p/value
			ptr-store vtype base offset as instr! pp/value ctx
			offset: offset + type-size? vtype no
			pp: pp + 1
			p: p + 1
		]
	]

	norm-global-type: func [
		ty		[rst-type!]
		return: [rst-type!]
	][
		switch TYPE_KIND(ty) [
			RST_TYPE_ARRAY
			RST_TYPE_STRUCT [
				type-system/int32-type	;-- 32-bit reference to data section
			]
			default [ty]	
		]
	]

	gen-get-global: func [
		i		[instr!]
		env		[lowering-env!]
		/local
			o	[instr-op!]
			var	[var-decl!]
			vt	[rst-type!]
			ty	[ptr-type!]
			ptr [instr-const!]
			new [ptr-array!]
	][
		o: as instr-op! i
		var: as var-decl! o/target
		vt: var/type
		ty: as ptr-type! make-ptr-type vt
		ptr: make-ptr-const ty var
		new: gen-loads norm-global-type vt as instr! ptr 0 env/cur-ctx
		map-n i new env
	]

	gen-set-global: func [
		i		[instr!]
		env		[lowering-env!]
		/local
			inputs [ptr-array!]
			o	[instr-op!]
			var	[var-decl!]
			vt	[rst-type!]
			ty	[ptr-type!]
			ptr [instr-const!]
	][
		inputs: refresh-dests i/inputs env
		o: as instr-op! i
		var: as var-decl! o/target
		vt: var/type
		ty: as ptr-type! make-ptr-type vt
		ptr: make-ptr-const ty var
		gen-stores norm-global-type vt as instr! ptr 0 inputs 0 env/cur-ctx
		kill-instr i
		remove-instr i
	]

	gen-set-local: func [
		i		[instr!]
		env		[lowering-env!]
		/local
			inputs [ptr-array!]
			o	[instr-op!]
			var	[ssa-var!]
	][
		inputs: refresh-dests i/inputs env
		o: as instr-op! i
		var: as ssa-var! o/target
		gen-stores type-system/integer-type var/instr 0 inputs 0 env/cur-ctx
		kill-instr i
		remove-instr i
	]

	get-member-offset: func [
		st		[struct-type!]
		m		[member!]
		offset	[int-ptr!]
		return: [rst-type!]
		/local
			n	[integer!]
	][
		n: 0
		until [
			n: n + field-offset? st m/index
			st: as struct-type! m/type
			m: m/next
			any [null? m NOT_STRUCT_VALUE?(st)]
		]
		offset/value: n
		as rst-type! st
	]

	gen-set-field: func [
		i		[instr!]
		env		[lowering-env!]
		/local
			o		[instr-op!]
			m		[member!]
			p		[ptr-ptr!]
			p2		[ptr-ptr!]
			ty		[struct-type!]
			vt		[rst-type!]
			base	[instr!]
			offset	[integer!]
			arg-idx [integer!]
			inputs	[ptr-array!]
	][
		inputs: refresh-dests i/inputs env
		
		o: as instr-op! i
		m: as member! o/target
		either m <> null [
			p: o/param-types
			ty: as struct-type! p/value	;-- struct type
			p: p + 1
			vt: as rst-type! p/value	;-- field type

			switch TYPE_KIND(ty) [
				RST_TYPE_STRUCT [
					base: as instr! ptr-array/pick inputs 0
					offset: 0
					vt: get-member-offset ty m :offset
					arg-idx: 1
				]
				RST_TYPE_ARRAY RST_TYPE_PTR [
					offset: 0
					arg-idx: 2
					p: ARRAY_DATA(inputs)
					p2: p + 1
					base: ptr-add as instr! p/value as instr! p2/value env/cur-ctx
				]
				default [dprint ["unsupported set-field " TYPE_KIND(ty)] 0]
			]
		][
			vt: o/ret-type
			base: as instr! ptr-array/pick inputs 0
			offset: 0
			arg-idx: 1
		]
		gen-stores vt base offset inputs arg-idx env/cur-ctx
		kill-instr i
		remove-instr i
	]

	gen-get-field: func [
		i		[instr!]
		env		[lowering-env!]
		/local
			o		[instr-op!]
			m		[member!]
			p		[ptr-ptr!]
			p2		[ptr-ptr!]
			ty		[struct-type!]
			vt		[rst-type!]
			decl	[var-decl!]
			base	[instr!]
			ofs		[instr!]
			offset	[integer!]
			inputs	[ptr-array!]
			new		[ptr-array!]
			int		[red-integer!]
			ctx		[ssa-ctx!]
	][
		inputs: refresh-dests i/inputs env
		
		ctx: env/cur-ctx
		o: as instr-op! i
		m: as member! o/target
		either NODE_TYPE(m) = RST_MEMBER [
			vt: m/type
			p: o/param-types
			ty: as struct-type! p/value	;-- struct type
			switch TYPE_KIND(ty) [
				RST_TYPE_STRUCT [
					offset: 0
					vt: get-member-offset ty m :offset
					base: as instr! ptr-array/pick inputs 0
				]
				RST_TYPE_PTR RST_TYPE_ARRAY [
					offset: 0
					p: ARRAY_DATA(inputs)
					p2: p + 1
					base: ptr-add as instr! p/value as instr! p2/value ctx
				]
				default [0]
			]
		][
			vt: o/ret-type
			offset: 0
			base: as instr! ptr-array/pick inputs 0
		]

		either INSTR_GET_PTR?(i) [
			if offset <> 0 [
				int: xmalloc(red-integer!)
				int/header: TYPE_INTEGER
				int/value: offset
				ofs: as instr! ir-graph/const-int int ctx/graph
				base: ptr-add base ofs ctx
			]
			map i base env
		][
			new: gen-loads vt base offset ctx
			map-n i new env
		]
	]

	gen-float-to-int: func [
		i		[instr!]
		env		[lowering-env!]
		/local
			o		[instr-op!]
			p		[ptr-ptr!]
			ft tt	[rst-type!]
	][
		o: as instr-op! i
		p: o/param-types
		ft: as rst-type! p/value
		tt: o/ret-type
		
		refresh-inputs i env
		
	]

	gen-op: func [
		i		[instr!]
		env		[lowering-env!]
		/local
			new [instr!]
	][
		new: i
		switch INSTR_OPCODE(i) [
			OP_INT_ADD
			OP_INT_SUB
			OP_INT_MUL			
			OP_INT_DIV			
			OP_INT_REM			
			OP_INT_MOD			[gen-truncate-op as instr-op! i env exit]
			;OP_INT_AND			
			;OP_INT_OR			
			;OP_INT_XOR			
			;OP_INT_SHL			
			;OP_INT_SAR			
			;OP_INT_SHR			[0]
			OP_INT_EQ			[new: gen-equal i env]
			;OP_INT_NE			[0]
			OP_INT_LT			[new: gen-int-cmp i env]
			OP_INT_LTEQ			[new: gen-int-cmp i env]
			;OP_DEFAULT_VALUE	[0]
			OP_CALL_FUNC		[gen-call i env exit]
			OP_GET_GLOBAL		[gen-get-global i env exit]
			OP_SET_GLOBAL		[gen-set-global i env exit]
			OP_SET_LOCAL		[gen-set-local i env exit]
			OP_SET_FIELD		[gen-set-field i env exit]
			OP_GET_FIELD		[gen-get-field i env exit]
			OP_FLT_TO_I			[gen-float-to-int i env]
			default [
				if i/inputs <> null [refresh-inputs i env]
				0 ;dprint ["Internal Error: Unknown Opcode: " INSTR_OPCODE(i)]
			]
		]
		either i <> new [map i new env][MARK_INS(i env/mark)]
	]

	gen-phi: func [
		i		[instr!]
		env		[lowering-env!]
		/local
			new-i	[ptr-array!]
			i2		[instr!]
			inputs	[ptr-array!]
			arr		[ptr-array!]
			len n j	[integer!]
			ninputs [integer!]
			p pp pi	[ptr-ptr!]
			p2		[ptr-ptr!]
	][
		if INSTR_FLAGS(i) and F_INS_KILLED <> 0 [exit]

		new-i: get-new-instrs i env
		either null? new-i [
			either null? i/instr [
				refresh-inputs i env
			][	;-- phi is replaced by 1 instr
				i2: i/instr
				insert-instr i i2
				ir-graph/set-inputs i2 refresh-dests i/inputs env
				remove-instr i
			]
		][	;-- phi is replaced by N instrs
			ninputs: i/inputs/length
			inputs: refresh-dests i/inputs env
			pi: ARRAY_DATA(inputs)
			len: new-i/length
			p: ARRAY_DATA(new-i)
			n: 0
			while [n < len][
				i2: as instr! p/value
				insert-instr i i2
				arr: ptr-array/make ninputs
				pp: ARRAY_DATA(arr)
				j: 0
				while [j < ninputs][
					p2: pi + n + (j * ninputs)
					pp/value: p2/value
					pp: pp + 1
					j: j + 1
				]
				ir-graph/set-inputs i2 arr
				n: n + 1
				p: p + 1
			]
			remove-instr i
		]
	]

	do-block: func [
		bb			[basic-block!]
		env			[lowering-env!]
		/local
			ctx		[ssa-ctx!]
			i		[instr!]
			next-i	[instr!]
			code	[integer!]
			offset	[integer!]
			base	[instr!]
			r		[instr-return!]
			arr		[ptr-array!]
			p		[ptr-ptr!]
			inputs	[ptr-array!]
	][
		ctx: env/cur-ctx
		ctx/closed?: no
		ctx/block: bb

		i: bb/next
		while [all [i <> null i <> bb]][
			;ir-printer/print-instr i
			next-i: i/next		;-- i may be removed
			code: INSTR_OPCODE(i)
			switch code [
				INS_PHI [
					env/phis: make-list as int-ptr! i env/phis
					get-new-instrs i env
				]
				INS_RETURN [refresh-inputs i env]
				default [
					either code >= OP_BOOL_EQ [
						env/cur-ctx/pt: i
						gen-op i env
					][
						if i/inputs <> null [refresh-inputs i env]
					]
				]
			]
			i: next-i
		]
	]

	do-fn: func [
		fn		[ir-fn!]
		/local
			env		[lowering-env!]
			cur-ctx	[ssa-ctx! value]
			succs	[ptr-array!]
			i		[integer!]
			b		[basic-block!]
			e		[cf-edge!]
			pp		[ptr-ptr!]
			vec		[vector!]
			l		[list!]
			arr		[ptr-array!]
			ins		[instr!]
	][
		ir-graph/init-ssa-ctx :cur-ctx null 0 fn/start-bb
		cur-ctx/graph: fn
		env: as lowering-env! malloc size? lowering-env!
		env/cur-ctx: :cur-ctx
		env/fn: fn
		dyn-array/init env/buffer 4
		dyn-array/init env/new-instrs 4
		env/mark: fn/mark + 1
		fn/mark: fn/mark + 2

		arr: fn/params
		pp: ARRAY_DATA(arr)
		loop arr/length [
			ins: as instr! pp/value
			MARK_INS(ins env/mark)
			pp: pp + 1
		]

		vec: vector/make size? int-ptr! 4
		vector/append-ptr vec as byte-ptr! fn/start-bb
		fn/start-bb/mark: env/mark
		i: 0
		while [i < vec/length][
			b: as basic-block! vector/pick-ptr vec i
			do-block b env
			succs: block-successors cur-ctx/block
			if succs <> null [
				pp: ARRAY_DATA(succs)
				loop succs/length [
					e: as cf-edge! pp/value
					b: e/dst
					if b/mark < env/mark [
						vector/append-ptr vec as byte-ptr! b
						b/mark: env/mark
					]
					pp: pp + 1
				]
			]
			i: i + 1
		]
		vector/destroy vec

		l: env/phis
		while [l <> null][
			gen-phi as instr! l/head env
			l: l/tail
		]

		ssa-optimizer/run :cur-ctx
	]
]