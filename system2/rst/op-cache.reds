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

	init: does [
		int-op-table: as ptr-ptr! malloc INT_WIDTH_CNT * 2 * size? int-ptr!		;-- signed and unsigned
		float-op-table: as ptr-ptr! malloc 2 * size? int-ptr!
		void-op: as fn-type! malloc size? fn-type!
		void-op/header: RST_TYPE_FUNC
		void-op/n-params: 0
		void-op/ret-type: type-system/void-type
	]

	init-op: func [
		f		[op!]
		opcode	[integer!]
		param-t [ptr-ptr!]
		ret-t	[rst-type!]
	][
		f/header: opcode << 8 or RST_TYPE_FUNC
		f/n-params: 2
		f/param-types: param-t
		f/ret-type: ret-t
	]

	create: func [
		type	[rst-type!]
		offset	[integer!]
		return: [op!]
		/local
			f	[op!]
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
		init-op f + RST_OP_GT   OP_INT_LT   + offset  pt type-system/logic-type
		init-op f + RST_OP_GTEQ OP_INT_LTEQ + offset  pt type-system/logic-type

		pt: parser/make-param-types type as rst-type! type-system/uint32-type
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
			signed	[integer!]
			p		[ptr-ptr!]
	][
		signed: as-integer FLOAT_64?(type)
		p: float-op-table + signed
		if null? p/value [p/value: as int-ptr! create type OP_FLT_ADD - OP_INT_ADD]
		(as op! p/value) + op
	]
]
