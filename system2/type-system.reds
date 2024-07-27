Red/System [
	File: 	 %type-system.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

#enum type-conv-result! [
	conv_illegal
	conv_void
	conv_same			;-- same type
	conv_promote_ii		;-- promote int to int
	conv_promote_if		;-- promote int to float
	conv_promote_ff		;-- promote float to float
	conv_cast_ii
	conv_cast_if
	conv_cast_fi
	conv_cast_ff
]

;-- types

#define INT_WIDTH(int) (int/header >>> 8 and FFh)
#define INT_SIGNED?(int) (int/header and 00010000h <> 0)

;-- /header bits: 0 - 7: kind, 8 - 15: width, 16: signed? 
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

ptr-type!: alias struct! [
	TYPE_HEADER
	type		[rst-type!]
]

struct-type!: alias struct! [
	TYPE_HEADER
]

fn-type!: alias struct! [
	TYPE_HEADER
	n-params	[integer!]
	params		[var-decl!]
	ret-typeref [red-block!]
	param-types [ptr-ptr!]
	ret-type	[rst-type!]
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

	init: func [][
		integer-type: make-int-type 32 true
		uint32-type: make-int-type 32 false
		float-type: make-float-type 64
		float32-type: make-float-type 32
		logic-type: make-logic-type
		byte-type: make-int-type 8 false
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
		]
		conv_illegal
	]
]