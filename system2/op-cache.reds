Red/System [
	File: 	 %op-cache.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define INT_WIDTH_CNT	4	;-- int 8, 16, 32, 64

#define op! fn-type!

make-op: func [
	opcode	 [opcode!]
	n-params [integer!]
	param-t	 [ptr-ptr!]
	ret-t	 [rst-type!]
	return:  [op!]
	/local
		op	 [op!]
][
	op: as op! malloc size? op!
	op/header: opcode << 8 or RST_TYPE_FUNC
	op/n-params: n-params
	op/param-types: param-t
	op/ret-type: ret-t
	op
]

op-cache: context [
	int-op-table: as ptr-ptr! 0
	float-op-table: as ptr-ptr! 0

	init: does [
		int-op-table: as ptr-ptr! malloc INT_WIDTH_CNT * 2 * size? int-ptr!		;-- signed and unsigned
		float-op-table: as ptr-ptr! malloc 2 * size? int-ptr!
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
		return: [op!]
		/local
			f	[op!]
			pt	[ptr-ptr!]
	][
		f: as op! malloc RST_OP_SIZE * size? op!

		pt: parser/make-param-types type type
		init-op f + RST_OP_ADD  RST_OP_ADD   pt type
		init-op f + RST_OP_SUB  RST_OP_SUB   pt type
		init-op f + RST_OP_MUL  RST_OP_MUL   pt type
		init-op f + RST_OP_DIV  RST_OP_DIV   pt type
		init-op f + RST_OP_MOD  RST_OP_MOD   pt type
		init-op f + RST_OP_REM  RST_OP_REM   pt type
		init-op f + RST_OP_AND  RST_OP_AND   pt type
		init-op f + RST_OP_OR   RST_OP_OR    pt type
		init-op f + RST_OP_XOR  RST_OP_XOR   pt type
		init-op f + RST_OP_EQ   RST_OP_EQ    pt type-system/logic-type
		init-op f + RST_OP_NE   RST_OP_NE    pt type-system/logic-type
		init-op f + RST_OP_LT   RST_OP_LT    pt type-system/logic-type
		init-op f + RST_OP_LTEQ RST_OP_LTEQ  pt type-system/logic-type
		init-op f + RST_OP_GT   RST_OP_GT    pt type-system/logic-type
		init-op f + RST_OP_GTEQ RST_OP_GTEQ  pt type-system/logic-type

		pt: parser/make-param-types type as rst-type! type-system/uint32-type
		init-op f + RST_OP_SHL RST_OP_SHL pt type
		init-op f + RST_OP_SAR RST_OP_SAR pt type
		init-op f + RST_OP_SHR RST_OP_SHR pt type
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
		if null? p/value [p/value: as int-ptr! create type]
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
		if null? p/value [p/value: as int-ptr! create type]
		(as op! p/value) + op
	]
]
