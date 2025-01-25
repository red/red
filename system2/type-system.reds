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
	RST_TYPE_ENUM
	RST_TYPE_FUNC
	RST_TYPE_NULL
	RST_TYPE_STRUCT
	RST_TYPE_ARRAY
	RST_TYPE_PTR
	RST_TYPE_UNRESOLVED
	RST_TYPE_RESOLVING
]

#define T_WORD?(v)  [TYPE_OF(v) = TYPE_WORD]
#define T_BLOCK?(v) [TYPE_OF(v) = TYPE_BLOCK]

;-- types

#define SET_TYPE_KIND(node kind) [node/header: kind]
#define TYPE_KIND(node) (node/header and FFh)
#define ADD_TYPE_FLAGS(node flags) [node/header: node/header or (flags << 8)]
#define TYPE_FLAGS(node) (node/header >>> 8)

#define TYPE_HEADER [
	header		[integer!]		;-- Kind: 0 - 7 bits, flags: 8 - 31
	token		[cell!]
]

rst-type!: alias struct! [
	TYPE_HEADER
]

unresolved-type!: alias struct! [
	TYPE_HEADER
	typeref		[cell!]
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

#define PTR_SIZE?(ptr) (ptr/header >>> 8 and 0Fh)
#define SET_PTR_SIZE(ptr sz) [ptr/header and FFh or (sz << 8)]

;-- /header bits: 8 - 11: pointer size in byte
ptr-type!: alias struct! [
	TYPE_HEADER
	type		[rst-type!]
]

array-type!: alias struct! [	;-- inherit ptr-type!
	TYPE_HEADER
	type		[rst-type!]
	length		[integer!]
]

struct-field!: alias struct! [
	name		[red-word!]
	type		[rst-type!]
	offset		[integer!]
]

#define FLAG_ST_VALUE	0100h
#define STRUCT_VALUE?(t) [t/header = (FLAG_ST_VALUE or RST_TYPE_STRUCT)]

struct-type!: alias struct! [
	TYPE_HEADER
	size		[integer!]		;-- size of the struct in bytes
	n-fields	[integer!]		;-- number of fields
	fields		[struct-field!]	;-- array of struct-field!
]

enum-type!: alias struct! [
	TYPE_HEADER
	enum		[enumerator!]
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

make-enum-type: func [
	id			[cell!]
	enumerator	[int-ptr!]
	return:		[rst-type!]
	/local
		type [enum-type!]
][
	type: xmalloc(enum-type!)
	SET_TYPE_KIND(type RST_TYPE_ENUM)
	type/token: id
	type/enum: as enumerator! enumerator
	as rst-type! type
]

make-null-type: func [
	return: [rst-type!]
	/local
		type [rst-type!]
][
	type: xmalloc(rst-type!)
	SET_TYPE_KIND(type RST_TYPE_NULL)
	type
]

make-ptr-type: func [
	vtype	[rst-type!]		;-- value type this pointer point to
	return: [rst-type!]
	/local
		t	[ptr-type!]
][
	t: xmalloc(ptr-type!)
	t/header: RST_TYPE_PTR or (target/addr-size << 8)
	t/type: vtype
	as rst-type! t
]

make-int-type: func [
	width	[integer!]
	signed? [logic!]
	return: [rst-type!]
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
	as rst-type! type
]

make-float-type: func [
	width	[integer!]
	return: [rst-type!]
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
	as rst-type! type
]

make-logic-type: func [
	return: [rst-type!]
	/local
		type [logic-type!]
][
	type: as logic-type! malloc size? float-type!
	SET_TYPE_KIND(type RST_TYPE_LOGIC)
	as rst-type! type
]

make-array-type: func [
	len		[integer!]
	vtype	[rst-type!]		;-- value type
	return: [rst-type!]
	/local
		a	[array-type!]
][
	a: xmalloc(array-type!)
	SET_TYPE_KIND(a RST_TYPE_ARRAY)
	a/length: len
	a/type: vtype
	as rst-type! a
]

#define INT_TYPE?(type)		[(type/header and FFh) = RST_TYPE_INT]
#define FLOAT_TYPE?(type)	[(type/header and FFh) = RST_TYPE_FLOAT]

int-signed?: func [
	t		[rst-type!]
	return: [logic!]
][
	all [INT_TYPE?(t) INT_SIGNED?(t)]
]

field-offset?: func [
	st		[struct-type!]
	idx		[integer!]
	return: [integer!]
	/local
		f	[struct-field!]
][
	assert idx < st/n-fields
	f: st/fields + idx
	f/offset
]

struct-size?: func [
	st		[struct-type!]
	return: [integer!]
	/local
		f	[struct-field!]
		sz	[integer!]
		n	[integer!]
		ofs [integer!]
][
	sz: 0
	f: st/fields
	loop st/n-fields [
		n: type-size? f/type
		ofs: either n > 1 [align-up sz n][sz]
		sz: ofs + n
		f/offset: ofs
		f: f + 1
	]
	st/size: sz
	sz
]

type-size?: func [
	t		[rst-type!]
	return: [integer!]		;-- size in byte
	/local
		w	[integer!]
		st	[struct-type!]
][
	switch TYPE_KIND(t) [
		RST_TYPE_INT [
			w: INT_WIDTH(t)
			w >> 3
		]
		RST_TYPE_FLOAT [
			either FLOAT_64?(t) [8][4]
		]
		RST_TYPE_BYTE [1]
		RST_TYPE_LOGIC [1]
		RST_TYPE_VOID [0]
		RST_TYPE_PTR [PTR_SIZE?(t)]
		RST_TYPE_NULL
		RST_TYPE_ARRAY [target/addr-size]
		RST_TYPE_STRUCT [
			st: as struct-type! t
			either st/size > -1 [st/size][struct-size? st]
		]
		default [0]	
	]
]

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
		RST_TYPE_NULL ["null"]
		RST_TYPE_FUNC ["function!"]
		RST_TYPE_PTR ["pointer!"]
		RST_TYPE_STRUCT ["struct!"]
		RST_TYPE_ARRAY ["array!"]
		default ["void!"]
	]
]

#define MAX_INT_WIDTH	64

k_integer!:		symbol/make "integer!"
k_float!:		symbol/make "float!"
k_byte!:		symbol/make "byte!"
k_cstr!:		symbol/make "c-string!"
k_float32!:		symbol/make "float32!"
k_float64!:		symbol/make "float64!"
k_logic!:		symbol/make "logic!"
k_int-ptr!:		symbol/make "int-ptr!"
k_byte-ptr!:	symbol/make "byte-ptr!"
k_pointer!:		symbol/make "pointer!"
k_struct!:		symbol/make "struct!"
k_function!:	symbol/make "function!"
k_subroutine!:	symbol/make "subroutine!"
k_value:		symbol/make "value"

type-system: context [
	integer-type:	as rst-type! 0
	byte-type:		as rst-type! 0
	float-type:		as rst-type! 0
	float32-type:	as rst-type! 0
	logic-type:		as rst-type! 0
	int32-type:		as rst-type! 0
	uint32-type:	as rst-type! 0
	int16-type:		as rst-type! 0
	uint16-type:	as rst-type! 0
	int8-type:		as rst-type! 0
	uint8-type:		as rst-type! 0
	int64-type:		as rst-type! 0
	uint64-type:	as rst-type! 0
	void-type:		as rst-type! 0
	null-type:		as rst-type! 0
	cstr-type:		as rst-type! 0
	int-ptr-type:	as rst-type! 0
	byte-ptr-type:	as rst-type! 0

	int-types: as ptr-array! 0

	init: func [][
		int-types: ptr-array/make 2 * MAX_INT_WIDTH + 1

		void-type: make-void-type
		null-type: make-null-type
		integer-type: get-int-type 32 true
		int32-type: get-int-type 32 true
		uint32-type: get-int-type 32 false
		int64-type: get-int-type 64 true
		uint64-type: get-int-type 64 false
		float-type: make-float-type 64
		float32-type: make-float-type 32
		logic-type: make-logic-type
		byte-type: get-int-type 8 false
		cstr-type: make-array-type 0 byte-type
		int-ptr-type: make-ptr-type integer-type
		byte-ptr-type: make-ptr-type byte-type
		target/int-type: get-int-type target/int-width true
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
		hashmap/put m k_cstr!	 as int-ptr! cstr-type
		m
	]

	lit-array-type?: func [
		val		[cell!]
		return: [rst-type!]
	][
		either T_BLOCK?(val) [
			null
		][
			cstr-type
		]
	]

	get-int-type: func [
		w		[integer!]
		signed?	[logic!]
		return: [rst-type!]
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
		as rst-type! p/value
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
		if any [null? t1 null? t2][return null]

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
			RST_TYPE_NULL [
				if TYPE_KIND(y) >= RST_TYPE_FUNC [return conv_same]
			]
			default [conv_illegal]
		]
		conv_illegal
	]

	cast: func [		;-- cast x to y
		x	[rst-type!]
		y	[rst-type!]
		return: [type-conv-result!]
	][
		switch TYPE_KIND(x) [
			RST_TYPE_NULL [
				switch TYPE_KIND(y) [
					RST_TYPE_PTR [conv_ok]
					default [conv_ok]
				]
			]
			RST_TYPE_PTR [
				conv_ok
			]
			default [
				either x/header = y/header [conv_same][conv_illegal]
			]
		]
	]
]