Red/System [
	File: 	 %op-cache.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define INT_WIDTH_CNT	4	;-- int 8, 16, 32, 64

#define op! fn-type!

op-cache: context [
	int-op-table: as ptr-ptr! 0
	float-op-table: as ptr-ptr! 0
	void-op: as op! 0

	op-bool-eq: as op! 0
	op-bool-and: as op! 0
	op-bool-or: as op! 0
	op-bool-not: as op! 0

	init: func [/local pt [ptr-ptr!] t [rst-type!]][
		int-op-table: as ptr-ptr! malloc INT_WIDTH_CNT * 2 * size? int-ptr!		;-- signed and unsigned
		float-op-table: as ptr-ptr! malloc 2 * size? int-ptr!
		void-op: as fn-type! malloc size? fn-type!
		void-op/header: RST_TYPE_FUNC
		void-op/n-params: 0
		void-op/ret-type: type-system/void-type

		t: type-system/logic-type
		pt: as ptr-ptr! malloc size? int-ptr!
		pt/value: as int-ptr! t
		op-bool-not: make-op OP_BOOL_NOT pt t

		pt: parser/make-param-types t t
		op-bool-eq: xmalloc(op!)
		init-op op-bool-eq OP_BOOL_EQ pt t
	]

	make-op: func [
		opcode	[integer!]
		param-t [ptr-ptr!]
		ret-t	[rst-type!]
		return: [op!]
		/local
			f	[op!]
	][
		f: xmalloc(op!)
		f/header: opcode << 8 or RST_TYPE_FUNC
		f/n-params: 1
		f/param-types: param-t
		f/ret-type: ret-t
		f
	]

	init-op: func [
		f		[op!]
		opcode	[integer!]
		param-t [ptr-ptr!]
		ret-t	[rst-type!]
		return: [op!]
	][
		f/header: opcode << 8 or RST_TYPE_FUNC
		f/n-params: 2
		f/param-types: param-t
		f/ret-type: ret-t
		f
	]

	create: func [
		type	[rst-type!]
		offset	[integer!]
		return: [op!]
		/local
			f	[op!]
			fn	[op!]
			pt	[ptr-ptr!]
	][
		f: as op! malloc RST_OP_SIZE * size? op!

		pt: parser/make-param-types type type
		init-op f + RST_OP_ADD  OP_INT_ADD  + offset  pt type
		init-op f + RST_OP_SUB  OP_INT_SUB  + offset  pt type
		init-op f + RST_OP_MUL  OP_INT_MUL  + offset  pt type
		init-op f + RST_OP_DIV  OP_INT_DIV  + offset  pt type
		init-op f + RST_OP_MOD  OP_INT_MOD  + offset  pt type
		init-op f + RST_OP_REM  OP_INT_REM  + offset  pt type
		init-op f + RST_OP_AND  OP_INT_AND  + offset  pt type
		init-op f + RST_OP_OR   OP_INT_OR   + offset  pt type
		init-op f + RST_OP_XOR  OP_INT_XOR  + offset  pt type
		init-op f + RST_OP_EQ   OP_INT_EQ   + offset  pt type-system/logic-type
		init-op f + RST_OP_NE   OP_INT_NE   + offset  pt type-system/logic-type
		init-op f + RST_OP_LT   OP_INT_LT   + offset  pt type-system/logic-type
		init-op f + RST_OP_LTEQ OP_INT_LTEQ + offset  pt type-system/logic-type

		fn: init-op f + RST_OP_GT OP_INT_LT + offset pt type-system/logic-type
		ADD_FN_ATTRS(fn FN_COMMUTE)
		fn: init-op f + RST_OP_GTEQ OP_INT_LTEQ + offset  pt type-system/logic-type
		ADD_FN_ATTRS(fn FN_COMMUTE)

		pt: parser/make-param-types type type-system/uint32-type
		init-op f + RST_OP_SHL OP_INT_SHL pt type
		init-op f + RST_OP_SAR OP_INT_SAR pt type
		init-op f + RST_OP_SHR OP_INT_SHR pt type
		f
	]

	get-int-op: func [
		op		[opcode!]
		type	[rst-type!]
		return: [op!]
		/local
			w	[integer!]
			ops	[op!]
			p	[ptr-ptr!]
	][
		w: INT_WIDTH(type)
		p: int-op-table + (log-b w >> 3)
		if INT_SIGNED?(type) [p: p + INT_WIDTH_CNT]
		if null? p/value [p/value: as int-ptr! create type 0]
		ops: as op! p/value
		ops + op
	]

	get-float-op: func [
		op		[opcode!]
		type	[rst-type!]
		return:	[op!]
		/local
			f64	[integer!]
			p	[ptr-ptr!]
	][
		f64: as-integer FLOAT_64?(type)
		p: float-op-table + f64
		if null? p/value [p/value: as int-ptr! create type OP_FLT_ADD - OP_INT_ADD]
		(as op! p/value) + op
	]

	get-ptr-op: func [
		op		[opcode!]
		type	[ptr-type!]
		return: [op!]
		/local
			f	[op!]
			fn	[op!]
			t	[rst-type!]
			pt	[ptr-ptr!]
			beg [integer!]
			idx [integer!]
	][
		f: type/op-table
		t: as rst-type! type
		beg: OP_PTR_ADD
		if null? f [
			f: as op! malloc (OP_GET_PTR - OP_PTR_ADD) * size? op!

			pt: parser/make-param-types t type-system/integer-type
			init-op f + (OP_PTR_ADD - beg)  OP_PTR_ADD   pt t
			init-op f + (OP_PTR_SUB - beg)  OP_PTR_SUB   pt t

			pt: parser/make-param-types t t
			init-op f + (OP_PTR_EQ - beg)   OP_PTR_EQ    pt type-system/logic-type
			init-op f + (OP_PTR_NE - beg)   OP_PTR_NE    pt type-system/logic-type
			init-op f + (OP_PTR_LT - beg)   OP_PTR_LT    pt type-system/logic-type
			init-op f + (OP_PTR_LTEQ - beg) OP_PTR_LTEQ  pt type-system/logic-type
			type/op-table: f
		]

		idx: switch op [
			RST_OP_ADD [OP_PTR_ADD]
			RST_OP_SUB [OP_PTR_SUB]
			RST_OP_EQ [OP_PTR_EQ]
			RST_OP_NE [OP_PTR_NE]
			RST_OP_LT [OP_PTR_LT]
			RST_OP_LTEQ [OP_PTR_LTEQ]
			default [dprint ["invalid ptr op: " op] 0]
		]
		f + (idx - beg)
	]
]
