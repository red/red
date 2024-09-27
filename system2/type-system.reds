Red/System [
	File: 	 %type-system.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2024 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#enum type-conv-result! [
	conv_illegal
	conv_ok				;-- cast is allowed
	conv_same			;-- same type
	conv_promote_ii		;-- promote int to int
	conv_promote_if		;-- promote int to float
	conv_promote_ff		;-- promote float to float
	conv_cast_ii
	conv_cast_if
	conv_cast_fi
	conv_cast_ff
]

#enum rst-type-kind! [
	RST_TYPE_VOID
	RST_TYPE_LOGIC
	RST_TYPE_INT
	RST_TYPE_BYTE
	RST_TYPE_FLOAT
	RST_TYPE_C_STR
	RST_TYPE_FUNC
	RST_TYPE_STRUCT
	RST_TYPE_ARRAY
	RST_TYPE_PTR
]

;-- types

#define SET_TYPE_KIND(node kind) [node/header: kind]
#define TYPE_KIND(node) (node/header and FFh)
#define ADD_TYPE_FLAGS(node flags) [node/header: node/header or (flags << 8)]
#define TYPE_FLAGS(node) (node/header >>> 8)

#define TYPE_HEADER [
	header		[integer!]		;-- Kind and flags
	token		[cell!]
]

rst-type!: alias struct! [
	TYPE_HEADER
]

#define INT_WIDTH(int) (int/header >>> 8 and FFh)
#define INT_SIGNED?(int) (int/header and 00010000h <> 0)

;-- /header bits: 0 - 7: type kind, 8 - 15: width, 16: signed? 
int-type!: alias struct! [
	TYPE_HEADER
	min			[integer!]
	max			[integer!]
]

#define FLOAT_64?(f)  (f/header and 01000000h <> 0)
#define FLOAT_FRAC(f) (f/header >>> 8 and FFh)
#define FLOAT_EXP(f)  (f/header >>> 16 and FFh)

;-- /header bits: 8 - 15: fraction width, 16 - 23: exp width, 24: is64?
float-type!: alias struct! [
	TYPE_HEADER
]

logic-type!: alias struct! [
	TYPE_HEADER
]

#define PTR_VALUE_SIZE(ptr) [ptr/header >>> 8]

;-- /header bits: 8 - 31 size in bytes
ptr-type!: alias struct! [
	TYPE_HEADER
	type		[rst-type!]
]

struct-type!: alias struct! [
	TYPE_HEADER
]

fn-type!: alias struct! [
	TYPE_HEADER
	spec		[red-block!]
	n-params	[integer!]
	params		[var-decl!]
	ret-typeref [red-block!]
	param-types [ptr-ptr!]
	ret-type	[rst-type!]
]

make-void-type: func [
	return: [rst-type!]
	/local
		type [rst-type!]
][
	type: as rst-type! malloc size? rst-type!
	SET_TYPE_KIND(type RST_TYPE_VOID)
	type
]

make-int-type: func [
	width	[integer!]
	signed? [logic!]
	return: [int-type!]
	/local
		type [int-type!]
		sign [integer!]
][
	type: as int-type! malloc size? int-type!
	sign: either signed? [1 << 16][0]
	type/header: RST_TYPE_INT or (width << 8) or sign
	either signed? [
		type/min: -1 << (width - 1)
		type/max: -1 xor (FFFFFFFFh << (width - 1))
	][
		0
	]
	type
]

make-float-type: func [
	width	[integer!]
	return: [float-type!]
	/local
		type [float-type!]
		frac [integer!]
		exp  [integer!]
		is64 [integer!]
][
	type: as float-type! malloc size? float-type!
	either width = 64 [
		frac: 52
		exp: 11
		is64: 1 << 24
	][
		frac: 23
		exp: 8
		is64: 0
	]
	type/header: RST_TYPE_FLOAT or (frac << 8) or (exp << 16) or is64
	type
]

make-logic-type: func [
	return: [logic-type!]
	/local
		type [logic-type!]
][
	type: as logic-type! malloc size? float-type!
	SET_TYPE_KIND(type RST_TYPE_LOGIC)
	type
]

#define INT_TYPE?(type)		[(type/header and FFh) = RST_TYPE_INT]
#define FLOAT_TYPE?(type)	[(type/header and FFh) = RST_TYPE_FLOAT]

type-name: func [
	t		[rst-type!]
	return: [c-string!]
	/local
		w	[integer!]
][
	switch TYPE_KIND(t) [
		RST_TYPE_INT [
			w: INT_WIDTH(t)
			either INT_SIGNED?(t) [
				switch w [
					8	["int8!"]
					16	["int16!"]
					32	["int32!"]
					default ["integer!"]
				]
			][
				switch w [
					8	["uint8!"]
					16	["uint16!"]
					32	["uint32!"]
					default ["unsigned!"]
				]
			]
		]
		RST_TYPE_FLOAT [
			either FLOAT_64?(t) ["float64!"]["float32!"]
		]
		RST_TYPE_BYTE ["byte!"]
		RST_TYPE_LOGIC ["logic!"]
		RST_TYPE_VOID ["void!"]
		RST_TYPE_PTR ["pointer!"]
		RST_TYPE_STRUCT ["struct!"]
		default ["void!"]
	]
]

#define MAX_INT_WIDTH	64

type-system: context [
	integer-type:	as int-type! 0
	byte-type:		as int-type! 0
	float-type:		as float-type! 0
	float32-type:	as float-type! 0
	logic-type:		as logic-type! 0
	int32-type:		as int-type! 0
	uint32-type:	as int-type! 0
	int16-type:		as int-type! 0
	uint16-type:	as int-type! 0
	int8-type:		as int-type! 0
	uint8-type:		as int-type! 0
	int64-type:		as int-type! 0
	uint64-type:	as int-type! 0
	void-type:		as rst-type! 0

	k_integer!:		symbol/make "integer!"
	k_float!:		symbol/make "float!"
	k_byte!:		symbol/make "byte!"
	k_cstr!:		symbol/make "c-string!"
	k_float32!:		symbol/make "float32!"
	k_float64!:		symbol/make "float64!"
	k_logic!:		symbol/make "logic!"
	k_int-ptr!:		symbol/make "int-ptr!"
	k_byte-ptr!:	symbol/make "byte-ptr!"

	int-types: as ptr-array! 0

	init: func [][
		int-types: ptr-array/make 2 * MAX_INT_WIDTH + 1

		void-type: make-void-type
		integer-type: get-int-type 32 true
		uint32-type: get-int-type 32 false
		float-type: make-float-type 64
		float32-type: make-float-type 32
		logic-type: make-logic-type
		byte-type: get-int-type 8 false
	]

	make-cache: func [
		return: [int-ptr!]
		/local
			m	[int-ptr!]
	][
		m: hashmap/make 100
		hashmap/put m k_integer! as int-ptr! integer-type
		hashmap/put m k_float!	 as int-ptr! float-type
		hashmap/put m k_byte!	 as int-ptr! byte-type
		hashmap/put m k_float32! as int-ptr! float32-type
		hashmap/put m k_logic!	 as int-ptr! logic-type
		m
	]

	get-int-type: func [
		w		[integer!]
		signed?	[logic!]
		return: [int-type!]
		/local
			idx [integer!]
			p	[ptr-ptr!]
	][
		if any [w <= 0 w > MAX_INT_WIDTH][return null]
		idx: either signed? [w][w + MAX_INT_WIDTH]
		p: ARRAY_DATA(int-types) + idx
		if null? p/value [
			p/value: as int-ptr! make-int-type w signed?
		]
		as int-type! p/value
	]

	int-promotable?: func [		;-- check if int x is promotable to int y
		x	[rst-type!]
		y	[rst-type!]
		return: [logic!]
	][
		if x/header = y/header [return true]
		all [
			INT_WIDTH(x) < INT_WIDTH(y)
			any [INT_SIGNED?(y) INT_SIGNED?(y) = INT_SIGNED?(x)]
		]
	]

	promotable-to-float?: func [
		x		[rst-type!]
		y		[rst-type!]
		return: [logic!]
		/local
			r	[type-conv-result!]
	][
		r: convert x y
		all [r >= conv_same r <= conv_promote_ff]
	]

	unify: func [	;-- compute the least type which t1 and t2 could promote to
		t1		[rst-type!]
		t2		[rst-type!]
		return: [rst-type!]
	][
		if t1/header = t2/header [return t1]	;-- same type
		switch TYPE_KIND(t1) [
			RST_TYPE_INT [
				switch TYPE_KIND(t2) [
					RST_TYPE_INT [
						if int-promotable? t1 t2 [return t2]
						if int-promotable? t2 t1 [return t1]
					]
					RST_TYPE_FLOAT [
						if promotable-to-float? t1 t2 [return t2]
					]
					default [null]
				]
			]
			default [null]
		]
		null
	]

	promotable?: func [
		t1		[rst-type!]
		t2		[rst-type!]
		return: [logic!]
		/local
			r	[type-conv-result!]
	][
		r: convert t1 t2
		all [r >= conv_same r <= conv_promote_ff]
	]

	convert: func [				;-- convert type x to type y
		x	[rst-type!]
		y	[rst-type!]
		return: [type-conv-result!]
		/local
			frac [integer!]
	][
		if x/header = y/header [return conv_same]

		switch TYPE_KIND(x) [
			RST_TYPE_INT [
				switch TYPE_KIND(y) [
					RST_TYPE_INT RST_TYPE_BYTE [
						if int-promotable? x y [return conv_promote_ii]
					]
					RST_TYPE_FLOAT	[
						frac: FLOAT_FRAC(y)
						either INT_SIGNED?(x) [
							if INT_WIDTH(x) <= frac [return conv_promote_if]
						][
							if INT_WIDTH(x) <= (frac + 1) [return conv_promote_if]
						]
					]
					default [0]
				]
			]
			RST_TYPE_FLOAT [
				either TYPE_KIND(y) = RST_TYPE_FLOAT [
					0
				][
					return conv_illegal
				]
			]
		]
		conv_illegal
	]

	cast: func [
		x	[rst-type!]
		y	[rst-type!]
		return: [type-conv-result!]
	][
		if x/header = y/header [return conv_same]

		conv_illegal
	]

	type-size?: func [
		t		[rst-type!]
		return: [integer!]		;-- size in byte
	][
		4
	]
]