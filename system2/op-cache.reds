Red/System [
	File: 	 %op-cache.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#define INT_WIDTH_CNT	4	;-- int 8, 16, 32, 64

op-cache: context [
	int-op-table: as ptr-ptr! 0
	float-op-table: as ptr-ptr! 0

	init: does [
		int-op-table: as ptr-ptr! malloc INT_WIDTH_CNT * 2 * size? int-ptr!		;-- signed and unsigned
		float-op-table: as ptr-ptr! malloc 2 * size? int-ptr!
	]

	init-op: func [
		f		[fn-type!]
		param-t [ptr-ptr!]
		ret-t	[rst-type!]
	][
		SET_TYPE_KIND(f RST_TYPE_FUNC)
		f/n-params: 2
		f/param-types: param-t
		f/ret-type: ret-t
	]

	make-params: func [
		ltype	[rst-type!]
		rtype	[rst-type!]
		return: [ptr-ptr!]
		/local
			pt	[ptr-ptr!]
			t2	[ptr-ptr!]
	][
		pt: as ptr-ptr! malloc 2 * size? int-ptr!
		pt/value: as int-ptr! ltype
		t2: pt + 1
		t2/value: as int-ptr! rtype
		pt
	]

	create: func [
		type	[rst-type!]
		return: [fn-type!]
		/local
			f	[fn-type!]
			pt	[ptr-ptr!]
	][
		f: as fn-type! malloc RST_OP_SIZE * size? fn-type!

		pt: make-params type type
		init-op f + RST_OP_ADD pt type
		init-op f + RST_OP_SUB pt type
		init-op f + RST_OP_MUL pt type
		init-op f + RST_OP_DIV pt type
		init-op f + RST_OP_MOD pt type
		init-op f + RST_OP_REM pt type
		init-op f + RST_OP_AND pt type
		init-op f + RST_OP_OR  pt type
		init-op f + RST_OP_XOR pt type
		init-op f + RST_OP_EQ  pt type-system/logic-type
		init-op f + RST_OP_NE  pt type-system/logic-type
		init-op f + RST_OP_LT   pt type-system/logic-type
		init-op f + RST_OP_LTEQ pt type-system/logic-type
		init-op f + RST_OP_GT   pt type-system/logic-type
		init-op f + RST_OP_GTEQ pt type-system/logic-type
		pt: make-params type as rst-type! type-system/uint32-type
		init-op f + RST_OP_SHL pt type
		init-op f + RST_OP_SAR pt type
		init-op f + RST_OP_SHR pt type
		f
	]

	get-int-op: func [
		op		[rst-op!]
		type	[rst-type!]
		return: [fn-type!]
		/local
			w	[integer!]
			ops	[fn-type!]
			p	[ptr-ptr!]
	][
		w: INT_WIDTH(type)
		p: int-op-table + (log-b w >> 3)
		if INT_SIGNED?(type) [p: p + INT_WIDTH_CNT]
		if null? p/value [p/value: as int-ptr! create type]
		ops: as fn-type! p/value
		ops + op
	]

	get-float-op: func [
		op		[rst-op!]
		type	[rst-type!]
		return:	[fn-type!]
		/local
			signed	[integer!]
			p		[ptr-ptr!]
	][
		signed: as-integer FLOAT_64?(type)
		p: float-op-table + signed
		if null? p/value [p/value: as int-ptr! create type]
		(as fn-type! p/value) + op
	]
]
