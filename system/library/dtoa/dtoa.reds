Red/System [
	Title:   "Red float <-> string functions"
	Author:  "Xie Qingtian"
	File: 	 %dtoa.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: {
		This file partially port dtoa.c(by David M. Gay, downloaded from
		http://www.netlib.org/fp/dtoa.c) to the Red runtime.

		Please remember to check http://www.netlib.org/fp regularly (
		and especially before any Red release) for bugfixes and updates.

		FYI: a more readable version from Python, in %Python/dtoa.c
		http://hg.python.org/cpython

		!! For `dtoa`, only support mode 0 now !!
	}
]

#define WORD_0(x) [x/int2]						;-- for little endian
#define WORD_1(x) [x/int1]

#define BIG_INT_X(x) (as int-ptr! (as byte-ptr! x) + 20)

#define STORE_AND_INC(a b c) [
	a/value: b << 16 or (c and FFFFh)
	a: a + 1
]

#define EXP_SHIFT		20
#define EXP_SHIFT1		20
#define EXP_MSK1		00100000h
#define EXP_MSK11		00100000h
#define EXP_MASK		7FF00000h
#define NBITS			53
#define BIAS			1023
#define EMAX			1023
#define EMIN			-1022
#define ETINY			-1074					;-- smallest denormal is 2**Etiny
#define EXP_1			3FF00000h
#define EXP_11			3FF00000h
#define EBITS			11
#define FRAC_MASK		000FFFFFh
#define FRAC_MASK1		000FFFFFh
#define TEN_PMAX		22
#define BNDRY_MASK		000FFFFFh
#define BNDRY_MASK1 	000FFFFFh
#define SIGN_BIT		80000000h
#define LOG2P			1
#define TINY0			0
#define TINY1			1
#define INT_MAX			14

#define FLT_RADIX		2.0						;@@ value for machines except the IBM 360 and derivatives
#define DBL_MAX_10_EXP	308						;@@ value for IEEE_Arith
#define DBL_MAX_EXP		1024					;@@ value for IEEE_Arith
#define N_BIGTENS		5

#define BIG_0			[(FRAC_MASK1 or (DBL_MAX_EXP + BIAS - 1 * EXP_MSK1))]
#define BIG_1			FFFFFFFFh

red-dtoa: context [
	P05:  [5 25 125]
	TENS: [
		1e0 1e1 1e2 1e3 1e4 1e5 1e6 1e7 1e8 1e9
		1e10 1e11 1e12 1e13 1e14 1e15 1e16 1e17 1e18 1e19
		1e20 1e21 1e22
	]
	BIGTENS:  [1e16 1e32 1e64 1e128 1e256]
	TINYTENS: [1e-16 1e-32 1e-64 1e-128 0.0]
	TINYTENS/5: 9007199254740992.0 * 9007199254740992e-256

	int64!: alias struct! [int1 [integer!] int2 [integer!]]

	big-int!: alias struct! [
		next	[big-int!]
		k		[integer!]
		maxwds	[integer!]
		sign	[integer!]
		wds		[integer!]
		x		[integer!]
	]

	cmp-info!: alias struct! [
		e0		[integer!]
		nd		[integer!]
		nd0		[integer!]
		scale	[integer!]
	]

	Balloc: func [
		k		[integer!]
		return: [big-int!]
		/local
			x	[integer!]
			len [integer!]						;@@ should be unsigned integer!
			big [big-int!]
	][
		x: 1 << k
		len: x - 1 * 4 + 8 + (size? big-int!) - 1 / 8

		big: as big-int! allocate len * 8		;@@ check if big = null
		big/k: k
		big/maxwds: x
		big/sign: 0
		big/wds: 0
		big
	]

	Bfree: func [
		p		[big-int!]
	][
		if p <> null [free as byte-ptr! p]
	]

	#define Bcopy(x y) [
		copy-memory (as byte-ptr! x) + 12 (as byte-ptr! y) + 12 (y/wds * 4 + 8)
	]

	Bmultiply: func [							;-- multiply two Bigints. Ignores the signs of a and b.
		a		[big-int!]
		b		[big-int!]
		return: [big-int!]
		/local
			k wa wb wc
			x xa xae xb xbe xc xc0
			y carry z z2 c
	][
		if any [
			all [a/x = 0	a/wds = 1]
			all [b/x = 0	b/wds = 1]
		][
			c: Balloc 0							;@@ check if c = null ?
			c/wds: 1
			c/x: 0
			return c
		]

		if a/wds < b/wds [c: a a: b b: c]

		k: a/k
		wa: a/wds
		wb: b/wds
		wc: wa + wb

		if wc > a/maxwds [k: k + 1]
		c: Balloc k								;@@ check if c = null ?
		x: BIG_INT_X(c)
		xa: x + wc
		while [x < xa][
			x/value: 0
			x: x + 1
		]

		xa: BIG_INT_X(a)
		xae: xa + wa
		xb: BIG_INT_X(b)
		xbe: xb + wb
		xc0: BIG_INT_X(c)
		while [xb < xbe][
			y: xb/value and FFFFh
			if y <> 0 [
				x: xa
				xc: xc0
				carry: 0
				until [
					z: x/value and FFFFh * y + (xc/value and FFFFh) + carry
					carry: z >>> 16
					z2: x/value >>> 16 * y + (xc/value >>> 16) + carry
					carry: z2 >>> 16
					STORE_AND_INC(xc z2 z)
					x: x + 1
					x = xae
				]
				xc/value: carry
			]

			y: xb/value >>> 16
			if y <> 0 [
				x: xa
				xc: xc0
				carry: 0
				z2: xc/value
				until [
					z: x/value and FFFFh * y + (xc/value >>> 16) + carry
					carry: z >>> 16
					STORE_AND_INC(xc z z2)
					z2: x/value >>> 16 * y + (xc/value and FFFFh) + carry
					carry: z2 >>> 16
					x: x + 1
					x = xae
				]
				xc/value: z2
			]
			xb: xb + 1
			xc0: xc0 + 1
		]
		xc0: BIG_INT_X(c)
		xc: xc0 + wc
		while [xc: xc - 1 all [wc > 0 zero? xc/1]][wc: wc - 1]
		c/wds: wc
		c
	]

	Bmult-add: func [							;-- multiply by m and add a
		b		[big-int!]
		m		[integer!]
		a		[integer!]
		return: [big-int!]
		/local
			i	[integer!]
			wds [integer!]
			carry [integer!]
			x	[int-ptr!]
			y	[integer!]
			xi	[integer!]
			z	[integer!]
			b1	[big-int!]
	][
		wds: b/wds
		x: BIG_INT_X(b)
		i: 0
		carry: a
		until [
			xi: x/value
			y: (xi and FFFFh) * m + carry
			z: xi >>> 16 * m + (y >>> 16)
			carry: z >>> 16
			x/value: z << 16 + (y and FFFFh)
			x: x + 1
			i: i + 1
			i = wds
		]
		if carry <> 0 [
			if wds >= b/maxwds [
				b1: Balloc b/k + 1				;@@ check b1 = null ?
				Bcopy(b1 b)
				Bfree b
				b: b1
			]
			x: BIG_INT_X(b)
			wds: wds + 1
			x/wds: carry
			b/wds: wds
		]
		b
	]

	Bpow5mult: func [							;-- multiply the Bigint b by 5**k.
		b		[big-int!]						;-- Ignores the sign of b.
		k		[integer!]
		return: [big-int!]
		/local
			b1	[big-int!]
			p5	[big-int!]
			p51	[big-int!]
			i	[integer!]
	][

		i: k and 3
		if i <> 0 [
			b: Bmult-add b P05/i 0				;@@ check if b = null ?
		]

		k: k >> 2
		if zero? k [return b]

		p5: int-to-big 625						;@@ check if p5 = null ?
		until [
			if k and 1 <> 0 [
				b1: Bmultiply b p5
				Bfree b
				b: b1							;@@ check if b = null ?
			]

			k: k >> 1
			if k <> 0 [
				p51: Bmultiply p5 p5
				Bfree p5
				p5: p51							;@@ check if p5 = null ?
			]
			zero? k
		]
		Bfree p5
		b
	]

	Blshift: func [								;-- shift a Bigint b left by k bits.
		b		[big-int!]
		k		[integer!]
		return: [big-int!]
		/local
			i k1 n n1 b1 x x1 xe z
	][
		if any [
			zero? k
			all [zero? b/x b/wds = 1]
		][return b]

		n: k >> 5
		k1: b/k
		n1: n + b/wds + 1
		i: b/maxwds
		while [n1 > i][
			k1: k1 + 1
			i: i << 1
		]

		b1: Balloc k1							;@@ check if b1 = null ?
		x1: BIG_INT_X(b1)
		i: 0
		while [i < n][
			x1/value: 0
			x1: x1 + 1
			i: i + 1
		]

		x: BIG_INT_X(b)
		xe: x + b/wds
		k: k and 1Fh
		either k <> 0 [
			k1: 32 - k
			z: 0
			until [
				x1/value: x/value << k or z
				z: x/value >>> k1
				x1: x1 + 1
				x:  x + 1
				x = xe
			]
			x1/value: z
			if z <> 0 [n1: n1 + 1]
		][
			until [
				x1/value: x/value
				x1: x1 + 1
				x:  x + 1
				x = xe
			]
		]
		b1/wds: n1 - 1
		Bfree b
		b1
	]

	Bcmp: func [
		a		[big-int!]
		b		[big-int!]
		return: [integer!]
		/local
			xa xa0 xb xb0 i j x y
	][
		i: a/wds
		j: b/wds
		if i <> j [return i - j]

		xa0: BIG_INT_X(a)
		xa: xa0 + j
		xb0: BIG_INT_X(b)
		xb: xb0 + j
		until [
			xa: xa - 1
			xb: xb - 1
			x: as byte-ptr! xa/value
			y: as byte-ptr! xb/value
			if x <> y [
				return either x < y [-1][1]
			]
			xb <= xb0
		]
		0
	]

	Bdiff: func [
		a		[big-int!]
		b		[big-int!]
		return: [big-int!]
		/local
			c i wa wb xa xae xb xbe xc
			borrow y z
	][

		i: Bcmp a b
		if zero? i [							;-- a = b
			c: Balloc 0
			c/wds: 1
			c/x: 0
			return c
		]

		either i < 0 [
			c: a
			a: b
			b: c
			i: 1
		][
			i: 0
		]

		c: Balloc a/k
		c/sign: i
		wa: a/wds
		xa: BIG_INT_X(a)
		xae: xa + wa
		wb: b/wds
		xb: BIG_INT_X(b)
		xbe: xb + wb
		xc: BIG_INT_X(c)
		borrow: 0
		until [
			y: xa/value and FFFFh - (xb/value and FFFFh) - borrow
			borrow: y and 00010000h >>> 16
			z: xa/value >>> 16 - (xb/value >>> 16) - borrow
			borrow: z and 00010000h >>> 16
			STORE_AND_INC(xc z y)
			xa: xa + 1
			xb: xb + 1
			xb = xbe
		]

		while [xa < xae][
			y: xa/value and FFFFh - borrow
			borrow: y and 00010000h >>> 16
			z: xa/value >>> 16 - borrow
			borrow: z and 00010000h >>> 16
			STORE_AND_INC(xc z y)
			xa: xa + 1
		]

		while [
			xc: xc - 1
			zero? xc/value
		][
			wa: wa - 1
		]
		c/wds: wa
		c
	]

	Bdshift: func [
		b		[big-int!]
		p2		[integer!]
		return: [integer!]
		/local
			rv	[integer!]
			x	[int-ptr!]
			wds [integer!]
	][
		x: BIG_INT_X(b)
		wds: b/wds
		rv: (hi0bits x/wds) - 4
		if p2 > 0 [rv: rv - p2]
		rv and 31
	]

	;-- special case of Bigint division.  The quotient is always in the range
	;-- 0 <= quotient < 10, and on entry the divisor S is normalized so that
	;-- its top 4 bits (28--31) are zero and bit 27 is set.
	Bquorem: func [
		b		[big-int!]
		s		[big-int!]
		return: [integer!]
		/local
			n bx bxe q sx sxe si bi
			borrow carry y ys z zs
	][
		n: s/wds
		if b/wds < n [return 0]
		sx: BIG_INT_X(s)
		bx: BIG_INT_X(b)
		;@@ do unsigned int division
		q: as-integer floor (uint-to-float bx/n) / (uint-to-float sx/n + 1)			;-- ensure q <= true quotient
		n: n - 1
		sxe: sx + n
		bxe: bx + n

		if q <> 0 [
			borrow: 0
			carry: 0
			until [
				si: sx/value
				ys: si and FFFFh * q + carry
				zs: si >>> 16 * q + (ys >>> 16)
				carry: zs >>> 16
				bi: bx/value
				y: bi and FFFFh - (ys and FFFFh) - borrow
				borrow: y and 00010000h >>> 16
				z: bi >>> 16 - (zs and FFFFh) - borrow
				borrow: z and 00010000h >>> 16
				STORE_AND_INC(bx z y)
				sx: sx + 1
				sx > sxe
			]
			if zero? bxe/value [
				bx: BIG_INT_X(b)
				while [
					bxe: bxe - 1
					all [bxe > bx zero? bxe/value]
				][n: n - 1]
				b/wds: n
			]
		]

		if 0 <= Bcmp b s [
			q: q + 1
			borrow: 0
			carry: 0
			bx: BIG_INT_X(b)
			sx: BIG_INT_X(s)
			until [
				si: sx/value
				ys: si and FFFFh + carry
				zs: si >>> 16 + (ys >>> 16)
				carry: zs >>> 16
				bi: bx/value
				y: bi and FFFFh - (ys and FFFFh) - borrow
				borrow: y and 00010000h >>> 16
				z: bi >>> 16 - (zs and FFFFh) - borrow
				borrow: z and 00010000h >>> 16
				STORE_AND_INC(bx z y)
				sx: sx + 1
				sx > sxe
			]
			bx: BIG_INT_X(b)
			bxe: bx + n
			if zero? bxe/value [
				while [
					bxe: bxe - 1
					all [bxe > bx zero? bxe/value]
				][n: n - 1]
				b/wds: n
			]
		]
		q
	]

	Bratio: func [						;-- Compute the ratio of two Bigints, as a double
		a		[big-int!]
		b		[big-int!]
		return: [float!]
		/local
			fa	[float!]
			fb	[float!]
			da	[int64!]
			db	[int64!]
			k	[integer!]
			ka	[integer!]
			kb	[integer!]
	][
		ka: 0
		kb: 0
		fa: big-to-float a :ka
		fb: big-to-float b :kb
		da: as int64! :fa
		db: as int64! :fb
		k: 32 * (a/wds - b/wds) + ka - kb
		either k > 0 [
			da/int2: da/int2 + (k * EXP_MSK1)
		][
			k: 0 - k
			db/int2: db/int2 + (k * EXP_MSK1)
		]
		fa / fb
	]

	hi0bits: func [						;-- count leading 0 bits in the 32-bit integer x
		x		[integer!]
		return: [integer!]
		/local
			k	[integer!]
	][
		k: 0
		if x and FFFF0000h = 0 [k: 16		x: x << 16]
		if x and FF000000h = 0 [k: k + 8	x: x << 8 ]
		if x and F0000000h = 0 [k: k + 4	x: x << 4 ]
		if x and C0000000h = 0 [k: k + 2	x: x << 2 ]
		if x and 80000000h = 0 [
			k: k + 1
			if x and 40000000h = 0 [return 32]
		]
		k
	]

	lo0bits: func [						;-- count trailing 0 bits in the 32-bit integer y,
		y		[int-ptr!]				;-- and shift y right by that number of bits.
		return: [integer!]
		/local
			k	[integer!]
			x	[integer!]
	][
		x: y/value
		if x and 7 <> 0 [
			if x and 1 <> 0 [return 0]
			if x and 2 <> 0 [y/value: x >>> 1	return 1]
			y/value: x >>> 2
			return 2
		]

		k: 0
		if x and FFFFh = 0 [k: 16		x: x >>> 16]
		if x and 00FFh = 0 [k: k + 8	x: x >>> 8 ]
		if x and 000Fh = 0 [k: k + 4	x: x >>> 4 ]
		if x and 0003h = 0 [k: k + 2	x: x >>> 2 ]
		if x and 1 = 0 [
			k: k + 1
			x: x >>> 1
			if x = 0 [return 32]
		]
		y/value: x
		k
	]

	int-to-big: func [					;-- convert a small nonnegative integer to a Bigint
		i		[integer!]
		return: [big-int!]
		/local
			b	[big-int!]
	][
		b: Balloc 1						;@@ Check if b = null ?
		b/x: i
		b/wds: 1
		b
	]

	big-to-float: func [
		a		[big-int!]
		e		[int-ptr!]
		return: [float!]
		/local
			xa xa0 w y z k d f
	][
		d:   declare int64!
		f:   as pointer! [float!] d
		xa0: BIG_INT_X(a)
		xa:  xa0 + a/wds - 1
		y:   xa/value

		k: hi0bits y
		e/value: 32 - k
		if k < EBITS [
			d/int2: EXP_1 or (y >>> (EBITS - k))
			w: either xa > xa0 [xa: xa - 1 xa/value][0]
			d/int1: y << (32 - EBITS + k) or (w >>> (EBITS - k))
			return f/value
		]

		z: either xa > xa0 [xa: xa - 1 xa/value][0]
		k: k - EBITS
		either k <> 0 [
			d/int2: EXP_1 or (y << k) or (z >>> (32 - k))
			y: either xa > xa0 [xa: xa - 1 xa/value][0]
			d/int1: z << k or (y >>> (32 - k))
		][
			d/int2: EXP_1 or y
			d/int1: z
		]
		return f/value
	]

	float-to-big: func [
		f		[float!]
		e		[int-ptr!]
		bits	[int-ptr!]
		return: [big-int!]
		/local
			d b de k x y z i w0
	][
		b:  Balloc 1
		x:  BIG_INT_X(b)
		d:  as int64! :f
		w0: WORD_0(d)
		z:  w0 and FRAC_MASK
		w0: w0 and 7FFFFFFFh			;-- clear sign bit, which we ignore
		d/int2: w0						;@@ little endian or big endian ?

		de: w0 >>> EXP_SHIFT
		if de <> 0 [z: z or EXP_MSK1]
		y: WORD_1(d)
		either zero? y [
			k: lo0bits :z
			x/1: z
			i: 1
			b/wds: 1
			k: k + 32
		][
			k: lo0bits :y
			either zero? k [
				x/1: y
			][
				x/1: z << (32 - k) or y
				z: z >>> k
			]
			x/2: z
			i: either z <> 0 [2][1]
			b/wds: i
		]

		either zero? de [
			e/value: de - BIAS - 52 + 1 + k
			bits/value: 32 * i - hi0bits x/i
		][
			e/value: de - BIAS - 52 + k
			bits/value: 53 - k
		]
		b
	]

	uint-to-float: func [
		i		[integer!]
		return: [float!]
		/local
			f	[float!]
			d	[int-ptr!]
	][
		;-- Based on this method: http://stackoverflow.com/a/429812/494472
		;-- A bit more explanation: http://lolengine.net/blog/2011/3/20/understanding-fast-float-integer-conversions
		f: 6755399441055744.0
		d: as int-ptr! :f
		d/value: i or d/value
		f - 6755399441055744.0
	]

	#define DTOA_RETERN_1 [
		Bfree b
		s/1: #"^@"
		decpt/value: k + 1
		sign/value: as-integer sign?
		length/value: as-integer s - s0
		return s0
	]

	#define DTOA_RETERN [
		Bfree SS
		if mhi <> null [
			if all [mlo <> null mlo <> mhi][
				Bfree mlo
			]
			Bfree mhi
		]
		DTOA_RETERN_1
	]

	#define DTOA_ROUND_OFF [
		while [
			s: s - 1
			s/1 = #"9"
		][
			if s = s0 [
				k: k + 1
				s/1: #"1"
				s: s + 1
				DTOA_RETERN
			]
		]
		s/1: s/1 + 1
		s: s + 1
	]

	float-to-ascii: func [
		f		[float!]
		decpt	[int-ptr!]
		sign	[int-ptr!]
		length	[int-ptr!]
		return: [c-string!]
		/local
			mlo [big-int!]
			mhi [big-int!]
			SS 	[big-int!]
			fsave bbits b2 b5 be dig i j j1
			k k0 ki k_check m2 m5 s2 s5 kf
			spec_case L denorm x d d2 sign?
			b b1 delta ds s s0 w0 w1 ww0
	][
		s0:    "-000000000000000000000000000000"		;-- 32 bits including ending null char
		s:     s0 + 1
		s0:    s
		mlo:   null
		mhi:   null
		SS:    null
		k:     0
		fsave: 0.0
		kf:    0.0
		d:     as int64! :f
		w0:    WORD_0(d)
		w1:    WORD_1(d)

		either zero? (w0 and SIGN_BIT) [
			sign?: no
		][
			sign?: yes
			w0: w0 and (not SIGN_BIT)
			d/int2: w0								;@@ WORD_0(d): w0 little endian or big endian ?
		]

		if w0 and EXP_MASK = EXP_MASK [
			decpt/value: 9999
			if all [
				zero? w1
				zero? (w0 and 000FFFFFh)
			][
				return either sign? ["-1.#INF"]["1.#INF"]
			]
			return "1.#NaN"
		]

		if f = 0.0 [
			decpt/value: 9998
			return either sign? ["-0.0"]["0.0"]
		]

		be: 0
		bbits: 0
		b: float-to-big f :be :bbits
		i: w0 >>> EXP_SHIFT1 and (EXP_MASK >> EXP_SHIFT1)
		fsave: f
		d2: d
		denorm: either zero? i [
			i: bbits + be + BIAS + 51
			x: either i > 32 [
				w0 << (64 - i) or (w1 >>> (i - 32))
			][
				w1 << (32 - i)
			]
			f: uint-to-float x
			ww0: WORD_0(d2)
			ww0: ww0 - (31 * EXP_MSK1)
			d2/int2: ww0						;@@ little endian or big endian ?
			i: i - (BIAS + 52)
			yes
		][
			ww0: WORD_0(d2)
			ww0: ww0 and FRAC_MASK1
			ww0: ww0 or EXP_11
			d2/int2: ww0						;@@ little endian or big endian ?
			i: i - BIAS
			no
		]

		ds: f - 1.5 * 0.289529654602168 + 0.1760912590558 + ((as-float i) * 0.301029995663981)
		f: fsave
		k: as-integer floor ds			;@@ Optimize it

		k_check: yes
		if all [k >= 0 k <= TEN_PMAX] [
			ki: k + 1							;-- adjust for 1-based array
			kf: TENS/ki							;@@ f < TENS/ki not work !
			if f < kf [k: k - 1]
			k_check: no
		]

		j: bbits - i - 1
		either j >= 0 [
			b2: 0
			s2: j
		][
			b2: 0 - j
			s2: 0
		]
		either k >= 0 [
			b5: 0
			s5: k
			s2: s2 + k
		][
			b2: b2 - k
			b5: 0 - k
			s5: 0
		]

		if all [be >= 0 k <= INT_MAX] [			;-- Do we have a "small" integer?
			ki: k + 1
			ds: TENS/ki
			until [
				L: as-integer floor (f / ds)
				f: f - (ds * uint-to-float L)
				s/1: #"0" + as byte! L
				s: s + 1
				f: f * 10.0
				f = 0.0
			]
			DTOA_RETERN_1
		]

		m2: b2
		m5: b5
		i: either denorm [be + (BIAS + 52)][1 + 53 - bbits]
		b2: b2 + i
		s2: s2 + i
		mhi: int-to-big 1
		if all [m2 > 0 s2 > 0][
			i: either m2 < s2 [m2][s2]
			b2: b2 - i
			m2: m2 - i
			s2: s2 - i
		]

		if b5 > 0 [
			if m5 > 0 [
				mhi: Bpow5mult mhi m5
				b1: Bmultiply mhi b
				Bfree b
				b: b1
			]
			j: b5 - m5
			if j <> 0 [b: Bpow5mult b j]
		]

		SS: int-to-big 1
		if s5 > 0 [SS: Bpow5mult SS s5]
		spec_case: no
		if all [
			zero? w1
			zero? (w0 and BNDRY_MASK)
			w0 and (EXP_MASK and (not EXP_MSK1)) <> 0
		][
			b2: b2 + LOG2P
			s2: s2 + LOG2P
			spec_case: yes
		]

		i: Bdshift SS s2
		b2: b2 + i
		m2: m2 + i
		s2: s2 + i
		if b2 > 0 [b:  Blshift b  b2]
		if s2 > 0 [SS: Blshift SS s2]
		if k_check [
			if 0 > Bcmp b SS [
				k: k - 1
				b: Bmult-add b 10 0
				mhi: Bmult-add mhi 10 0
			]
		]
		if m2 > 0 [
			mhi: Blshift mhi m2
		]

		mlo: mhi
		if spec_case [
			mhi: Balloc mhi/k
			Bcopy(mhi mlo)
			mhi: Blshift mhi LOG2P
		]

		while [true][
			dig: #"0" + Bquorem b SS
			j: Bcmp b mlo
			delta: Bdiff SS mhi
			j1: either delta/sign = 1 [1][Bcmp b delta]
			Bfree delta
			if all [
				zero? j1
				zero? (w1 and 1)
			][
				if dig = #"9" [
					s/1: #"9"
					s: s + 1
					DTOA_ROUND_OFF
				]
				if j > 0 [dig: dig + 1]
				s/1: dig
				s: s + 1
				DTOA_RETERN
			]

			if any [
				j < 0
				all [zero? j zero? (w1 and 1)]
			][
				case [
					all [zero? b/x  b/wds <= 1] []
					j1 > 0 [
						b: Blshift b 1
						j1: Bcmp b SS
						if any [
							j1 > 0
							all [zero? j1 (as-integer dig) and 1 <> 0]
						][
							if dig = #"9" [
								s/1: #"9"
								s: s + 1
								DTOA_ROUND_OFF
							]
							dig: dig + 1
						]
					]
					true []
				]
				s/1: dig
				s: s + 1
				DTOA_RETERN
			]

			if j1 > 0 [
				if dig = #"9" [
					s/1: #"9"
					s: s + 1
					DTOA_ROUND_OFF
				]
				s/1: dig + 1
				s: s + 1
				DTOA_RETERN
			]

			s/1: dig
			s: s + 1
			b: Bmult-add b 10 0
			either mlo = mhi [
				mlo: Bmult-add mhi 10 0
				mhi: mlo
			][
				mlo: Bmult-add mlo 10 0
				mhi: Bmult-add mhi 10 0
			]
		]
		s0
	]

	string-to-big: func [
		s		[byte-ptr!]
		nd0		[integer!]
		nd		[integer!]
		y9		[integer!]
		return: [big-int!]
		/local
			b i k x y
	][
		x: nd + 8 / 9
		k: 0
		y: 1
		while [x > y][y: y << 1 k: k + 1]

		b: Balloc k
		b/x: y9
		b/wds: 1

		if nd <= 9 [return b]

		s: s + 9
		i: 9
		while [i < nd0][
			b: Bmult-add b 10 as-integer s/1 - #"0"
			s: s + 1
			i: i + 1
		]

		s: s + 1
		while [i < nd][
			b: Bmult-add b 10 as-integer s/1 - #"0"
			s: s + 1
			i: i + 1
		]
		b
	]

	scaled-float-to-big: func [
		f		[float!]
		scale	[integer!]
		e		[int-ptr!]
		return: [big-int!]
		/local
			d	[int64!]
			b	[big-int!]
			x	[int-ptr!]
			x0	[integer!]
			x1	[integer!]
			exp [integer!]
	][
		d:     as int64! :f
		b:     Balloc 1
		x:     BIG_INT_X(b)
		b/wds: 2
		x0:    WORD_1(d)
		x1:    WORD_0(d) and FRAC_MASK
		exp:   ETINY - 1 + ((WORD_0(d) and EXP_MASK) >>> EXP_SHIFT)

		either exp < ETINY [exp: ETINY][x1: x1 or EXP_MSK1]

		if all [
			scale <> 0
			any [x0 <> 0 x1 <> 0]
		][
			exp: exp - scale
			if exp < ETINY [
				scale: ETINY - exp
				exp: ETINY
				if scale >= 32 [
					x0: x1
					x1: 0
					scale: scale - 32
				]
				if scale <> 0 [
					x0: x0 >>> scale or (x1 << (32 - scale))
					x1: x1 >>> scale
				]
			]
		]

		if zero? x1 [b/wds: 1]
		x/1: x0
		x/2: x1
		e/value: exp
		b
	]

	ulp: func [
		f		[float!]
		return: [float!]
		/local
			d	[int64!]
			L	[integer!]
	][
		d: as int64! :f
		L: d/int2 and EXP_MASK - (52 * EXP_MSK1)
		d/int2: L
		d/int1: 0
		f
	]

	sulp: func [							;-- sulp(x) is a version of ulp(x) that takes bc.scale into account
		f		[float!]
		bc		[cmp-info!]
		return: [float!]
		/local
			b	[int64!]
			u	[int64!]
	][
		b: as int64! :f
		u: b
		either all [
			bc/scale <> 0
			2 * 53 + 1 > (b/int2 and EXP_MASK >>> EXP_SHIFT)
		][
			u/int2: 53 + 2 * EXP_MSK1
			u/int1: 0
			f
		][
			ulp f
		]
	]

	#define BIGCOMP_BREAK [
		Bfree b
		Bfree d
		if any [
			dd > 0
			all [zero? dd odd <> 0]
		][
			f/value: f/value + sulp f/value bc
		]
		exit
	]

	bigcomp: func [
		rv		[int64!]
		s0		[byte-ptr!]
		bc		[cmp-info!]
		/local
			f	[pointer! [float!]]
			d	[big-int!]
			b	[big-int!]
			b2	[integer!]
			d2	[integer!]
			i	[integer!]
			j	[integer!]
			nd	[integer!]
			nd0	[integer!]
			odd	[integer!]
			p2	[integer!]
			p5	[integer!]
			dd	[integer!]
	][
		f:   as pointer! [float!] rv
		nd:  bc/nd
		nd0: bc/nd0
		p5:  nd + bc/e0
		p2:  0
		b:   scaled-float-to-big f/value bc/scale :p2
		odd: b/x and 1
		b:   Blshift b 1
		b/x: b/x or 1
		p2:  p2 - 1
		p2:  p2 - p5
		d:   int-to-big 1

		case [
			p5 > 0 [d: Bpow5mult d p5]
			p5 < 0 [b: Bpow5mult b 0 - p5]
			true []
		]

		either p2 > 0 [
			b2: p2
			d2: 0
		][
			b2: 0
			d2: 0 - p2
		]

		i: Bdshift d d2
		b2: b2 + i
		if b2 > 0 [b: Blshift b b2]
		d2: d2 + i
		if d2 > 0 [d: Blshift d d2]

		either 0 <= Bcmp b d [dd: -1][
			i: 0
			while [true][
				b: Bmult-add b 10 0
				j: 1 + either i < nd0 [i][i + 1]
				dd: (as-integer s0/j - #"0") - Bquorem b d
				i: i + 1
				if dd <> 0 [BIGCOMP_BREAK]
				if all [zero? b/x b/wds = 1][
					dd: as-integer i < nd
					BIGCOMP_BREAK
				]
				unless i < nd [
					dd: -1
					BIGCOMP_BREAK
				]
			]
		]
		BIGCOMP_BREAK
	]

	parse-exponent: func [
		s		[byte-ptr!]
		end		[byte-ptr!]
		return: [integer!]
		/local
			c	 [byte!]
			n	 [integer!]
			neg? [logic!]
	][
		neg?: no

		c: s/1
		if any [
			c = #"+"
			c = #"-"
		][
			neg?: c = #"-"
			s: s + 1
		]

		n: 0
		until [
			c: s/1 - #"0"
			n: n * 10
			n: n + c
			s: s + 1
			s = end
		]
		either neg? [0 - n][n]
	]

	#define STRTOD_RETURN [return either neg? [0.0 - rv][rv]]

	#define STRTOD_OVERFLOW [
		d/int2: EXP_MASK
		d/int1: 0
		STRTOD_RETURN
	]

	#define STRTOD_UNDERFLOW [return either neg? [-0.0][0.0]]

	#define STRTOD_BREAK [
		Bfree bb
		Bfree bd
		Bfree bs
		Bfree bd0
		Bfree delta
		if bc/nd > nd [
			bigcomp d s0 bc
		]
		if bc/scale <> 0 [
			d0/int2: EXP_1 - (2 * 53 * EXP_MSK1)
			d0/int1: 0
			rv: rv * rv0
		]
		STRTOD_RETURN
	]

	#define STRTOD_DROP_DOWN [
		if bc/scale <> 0 [
			L: d/int2 and EXP_MASK
			if L <= (2 * 53 + 1 * EXP_MSK1) [
				if L > (53 + 2 * EXP_MSK1) [STRTOD_BREAK]
				if bc/nd > nd [STRTOD_BREAK]
				STRTOD_UNDERFLOW
			]
		]
		L: d/int2 and EXP_MASK - EXP_MSK1
		d/int2: L or BNDRY_MASK1
		d/int1: FFFFFFFFh
		STRTOD_BREAK
	]

	string-to-float: func [
		start	[byte-ptr!]
		end		[byte-ptr!]
		return: [float!]
		/local
			rv	[float!]
			rv0 [float!]
			aadj2 [float!]
			bbe [integer!]
			bb	[big-int!]
			bb1	[big-int!]
			bd	[big-int!]
			bd0	[big-int!]
			bs	[big-int!]
			delta [big-int!]
			bb2 bb5 bd2 bd5 bs2 c dsign e e1
			i j k nd nd0 odd neg? s s0 s1
			aadj aadj1 adj y z next?
			L bc d d0 d2 w0 w1 ndigits fraclen
	][
		bb:    null
		bb1:   null
		bd:    null
		bd0:   null
		bs:    null
		delta: null
		next?: yes
		neg?:  no
		rv:    0.0
		rv0:   0.0
		aadj2: 0.0
		d:     as int64! :rv
		d0:    as int64! :rv0
		d2:    as int64! :aadj2
		s:     start
		c:     s/1

		if any [
			c = #"+"
			c = #"-"
		][
			neg?: c = #"-"
			s: s + 1
		]

		while [												;-- skip leading zero
			c: s/1
			all [
				c = #"0"
				s < end
			]
		][s: s + 1]

		if s = end [return 0.0]

		s0: s
		s1: s
		while [
			c: s/1
			all [c >= #"0" c <= #"9"]
		][s: s + 1]
		ndigits: as-integer s - s1
		fraclen: 0

		if any [c = #"." c = #","] [
			s: s + 1
			if zero? ndigits [
				s1: s
				while [c: s/1 c = #"0"][s: s + 1]
				fraclen: fraclen + (s - s1)
				s0: s
			]

			s1: s
			while [
				c: s/1
				all [c >= #"0" c <= #"9"]
			][s: s + 1]
			ndigits: ndigits + (s - s1)
			fraclen: fraclen + (s - s1)
		]
		nd:  ndigits
		nd0: ndigits - fraclen

		e: 0
		if any [c = #"e" c = #"E"][
			s: s + 1
			e: parse-exponent s end
		]

		e: e - (nd - nd0)
		if nd0 <= 0 [nd0: nd]

		if zero? nd [return either neg? [d/int2: 80000000h rv][0.0]]

		i: nd
		until [
			i: i - 1
			j: 1 + either i < nd0 [i][i + 1]				;-- adjust for 1-based
			if s0/j <> #"0" [i: i + 1 j: 0]
			zero? j
		]
		e: e + (nd - i)
		nd: i
		if nd0 > nd [nd0: nd]

		y: 0
		z: 0
		i: 0
		bc: declare cmp-info!
		e1: e
		bc/e0: e1
		until [
			j: 1 + either i < nd0 [i][i + 1]				;-- adjust for 1-based
			case [
				i < 9  [y: 10 * y + (s0/j - #"0")]
				i < 16 [z: 10 * z + (s0/j - #"0")]
				true   [j: 0]
			]
			i: i + 1
			any [i = nd zero? j]
		]

		k: either nd < 16 [nd][16]
		rv: as-float y
		if k > 9 [
			j: k - 8
			rv: TENS/j * rv + as-float z
		]

		if nd < 16 [
			if zero? e [STRTOD_RETURN]
			case [
				e > 0 [
					if e <= TEN_PMAX [
						e: e + 1
						rv: rv * TENS/e
						STRTOD_RETURN
					]
					i: 15 - nd
					if e <= (TEN_PMAX + i) [
						e: e - i + 1
						i: i + 1
						rv: rv * TENS/i
						rv: rv * TENS/e
						STRTOD_RETURN
					]
				]
				e >= (0 - TEN_PMAX) [
					e: 0 - e + 1
					rv: rv / TENS/e
					STRTOD_RETURN
				]
				true []
			]
		]

		e1: e1 + (nd - k)
		bc/scale: 0

		case [
			e1 > 0 [
				i: e1 and 15
				if i <> 0 [
					i: i + 1
					rv: rv * TENS/i
				]

				e1: e1 and (not 15)
				if e1 <> 0 [
					if e1 > DBL_MAX_10_EXP [STRTOD_OVERFLOW]
					e1: e1 >> 4
					j: 1
					while [e1 > 1][
						if e1 and 1 <> 0 [rv: rv * BIGTENS/j]
						j: j + 1
						e1: e1 >> 1
					]
					d/int2: d/int2 - (53 * EXP_MSK1)
					rv: rv * BIGTENS/j
					z: d/int2 and EXP_MASK
					if z > (DBL_MAX_EXP + BIAS - 53 * EXP_MSK1) [STRTOD_OVERFLOW]
					either z > (DBL_MAX_EXP + BIAS - 54 * EXP_MSK1) [
						d/int2: BIG_0
						d/int1: BIG_1
					][
						d/int2: d/int2 + (53 * EXP_MSK1)
					]
				]
			]
			e1 < 0 [
				e1: 0 - e1
				i: e1 and 15
				if i <> 0 [
					i: i + 1
					rv: rv / TENS/i
				]

				e1: e1 >> 4
				if e1 <> 0 [
					if e1 >= (1 << N_BIGTENS) [STRTOD_UNDERFLOW]
					if e1 and 10h <> 0 [bc/scale: 2 * 53]
					j: 1
					while [e1 > 0][
						if e1 and 1 <> 0 [rv: rv * TINYTENS/j]
						j: j + 1
						e1: e1 >> 1
					]

					j: 2 * 53 + 1 - (d/int2 and EXP_MASK >>> EXP_SHIFT)
					if all [
						bc/scale <> 0
						j > 0
					][
						either j >= 32 [
							d/int1: 0
							either j >= 53 [
								d/int2: 53 + 2 * EXP_MSK1
							][
								d/int2: d/int2 and (FFFFFFFFh << (j - 32))
							]
						][
							d/int1: d/int1 and (FFFFFFFFh << j)
						]
					]
					if rv = 0.0 [STRTOD_UNDERFLOW]
				]
			]
			true []
		]

		;-- Now the hard part -- adjusting rv to the correct value.
		bc/nd: nd
		bc/nd0: nd0

		if nd > 40 [
			i: 18
			until [
				i: i - 1
				j: 1 + either i < nd0 [i][i + 1]
				if s0/j <> #"0" [i: i + 1 j: 0]
				zero? j
			]
			e: e + (nd - i)
			nd: i
			if nd0 > nd [nd0: nd]
			if nd < 9 [
				y: 0
				i: 1
				while [i <= nd0][
					y: 10 * y + (s0/i - #"0")
					i: i + 1
				]
				while [i <= nd][
					i: i + 1
					y: 10 * y + (s0/i - #"0")
				]
			]

		]

		bd0: string-to-big s0 nd0 nd y
		bbe: 0
		while [true][
			bd: Balloc bd0/k
			Bcopy(bd bd0)
			bb: scaled-float-to-big rv bc/scale :bbe
			odd: bb/x and 1
			bs: int-to-big 1

			either e >= 0 [
				bb2: 0
				bb5: bb2
				bd2: e
				bd5: bd2
			][
				bb2: 0 - e
				bb5: bb2
				bd2: 0
				bd5: bd2
			]

			either bbe >= 0 [
				bb2: bb2 + bbe
			][
				bd2: bd2 - bbe
			]
			bs2: bb2
			bb2: bb2 + 1
			bd2: bd2 + 1

			i: either bb2 < bd2 [bb2][bd2]
			if i > bs2 [i: bs2]
			if i > 0 [
				bb2: bb2 - i
				bd2: bd2 - i
				bs2: bs2 - i
			]

			if bb5 > 0 [
				bs: Bpow5mult bs bb5
				bb1: Bmultiply bs bb
				Bfree bb
				bb: bb1
			]
			if bb2 > 0 [bb: Blshift bb bb2]
			if bd5 > 0 [bd: Bpow5mult bd bd5]
			if bd2 > 0 [bd: Blshift bd bd2]
			if bs2 > 0 [bs: Blshift bs bs2]

			delta: Bdiff bb bd
			dsign: delta/sign
			delta/sign: 0

			i: Bcmp delta bs
			if all [bc/nd > nd i <= 0][
				if dsign <> 0 [STRTOD_BREAK]

				if all [
					zero? d/int1
					zero? (d/int2 and BNDRY_MASK)
				][
					j: d/int2 and EXP_MASK >>> EXP_SHIFT
					if j - bc/scale >= 2 [
						rv: rv - (0.5 * sulp rv bc)
						STRTOD_BREAK
					]
				]

				bc/nd: nd
				i: -1
			]

			w0: WORD_0(d)
			w1: WORD_1(d)
			if i < 0 [
				if any [
					dsign <> 0
					w1 <> 0
					w0 and BNDRY_MASK <> 0
					w0 and EXP_MASK <= (2 * 53 + 1 * EXP_MSK1)
				][STRTOD_BREAK]

				if all [
					zero? delta/x
					delta/wds <= 1
				][STRTOD_BREAK]

				delta: Blshift delta LOG2P
				if 0 < Bcmp delta bs [STRTOD_DROP_DOWN]
				STRTOD_BREAK
			]

			if zero? i [
				case [
					dsign <> 0 [
						y: w0 and EXP_MASK
						j: either all [
							bc/scale <> 0
							y <= (2 * 53 * EXP_MSK1)
						][
							FFFFFFFFh and (FFFFFFFFh << (107 - (y >>> EXP_SHIFT)))
						][
							FFFFFFFFh
						]
						if all [
							w0 and BNDRY_MASK1 = BNDRY_MASK1
							w1 = j
						][
							d/int2: w0 and EXP_MASK + EXP_MSK1
							d/int1: 0
							STRTOD_BREAK
						]
					]
					not all [zero? (w0 and BNDRY_MASK) zero? w1][
						STRTOD_DROP_DOWN
					]
					true []
				]

				if zero? odd [STRTOD_BREAK]
				either dsign <> 0 [rv: rv + sulp rv bc][
					rv: rv - sulp rv bc
					if rv = 0.0 [
						if bc/nd > nd [STRTOD_BREAK]
						STRTOD_UNDERFLOW
					]
				]
				STRTOD_BREAK
			]

			aadj: Bratio delta bs
			either aadj <= 2.0 [
				case [
					dsign <> 0 [
						aadj: 1.0
						aadj1: 1.0
					]
					any [w1 <> 0 w0 and BNDRY_MASK <> 0][
						if all [w1 = TINY1 zero? w0][
							if bc/nd > nd [STRTOD_BREAK]
							STRTOD_UNDERFLOW
						]
						aadj: 1.0
						aadj1: -1.0
					]
					true [
						aadj: either aadj < (2.0 / FLT_RADIX) [
							1.0 / FLT_RADIX
						][
							aadj * 0.5
						]
						aadj1: 0.0 - aadj
					]
				]
			][
				aadj: aadj * 0.5
				aadj1: either dsign <> 0 [aadj][0.0 - aadj]
			]

			y: w0 and EXP_MASK
			either y = (DBL_MAX_EXP + BIAS - 1 * EXP_MSK1) [
				rv0: rv
				d/int2: w0 - (53 * EXP_MSK1)
				adj: aadj1 * ulp rv
				rv: rv + adj
				w0: WORD_0(d)
				either w0 and EXP_MASK >= (DBL_MAX_EXP + BIAS - 53 * EXP_MSK1) [
					if all [w0 = BIG_0 w1 = BIG_1][
						Bfree bb
						Bfree bd
						Bfree bs
						Bfree bd0
						Bfree delta
						STRTOD_OVERFLOW
					]
					d/int2: BIG_0
					d/int1: BIG_1
					next?: no
				][d/int2: w0 + (53 * EXP_MSK1)]
			][
				if all [
					bc/scale <> 0
					y <= (2 * 53 * EXP_MSK1)
				][
					if aadj <= 2147483647.0 [
						z: as-integer floor aadj
						if z <= 0 [z: 1]
						aadj: uint-to-float z
						aadj1: either dsign <> 0 [aadj][0.0 - aadj]
					]
					aadj2: aadj1
					d2/int2: d2/int2 + (107 * EXP_MSK1 - y)
					aadj1: aadj2
				]
				adj: aadj1 * ulp rv
				rv: rv + adj
			]

			if next? [
				z: d/int2 and EXP_MASK
				if bc/nd = nd [
					if zero? bc/scale [
						if y = z [
							aadj: aadj - floor aadj			;@@ Optimize it
							case [
								any [
									dsign <> 0
									d/int1 <> 0
									d/int2 and BNDRY_MASK <> 0
								][
									if any [aadj < 0.4999999 aadj > 0.5000001][
										STRTOD_BREAK
									]
								]
								aadj < (0.4999999 / FLT_RADIX) [STRTOD_BREAK]
								true []
							]
						]
					]
				]
			]
			Bfree bb
			Bfree bd
			Bfree bs
			Bfree delta
			next?: yes
		]
		rv
	]

	form-float: func [									;-- wrapper of `float-to-ascii` for convenient use
		f 		[float!]
		return: [c-string!]
		/local
			s	[byte-ptr!]
			end [byte-ptr!]
			ss	[c-string!]
			sig [integer!]
			e 	[integer!]
			len [integer!]
	][
		e: 0
		len: 0
		sig: 0
		s: as byte-ptr! float-to-ascii f :e :sig :len

		if e > 9997 [return as c-string! s]				;-- NaN, INFs, +/-0.0

		case [
			 any [e > 17 e < -3][						;-- e-format
				move-memory s + 2 s + 1 len
				s/2: #"."
				end: s + len
			]
			e > 0 [
				either e <= len [
					move-memory s + e + 1 s + e len - e
					e: e + 1
					s/e: #"."
					end: s + len
				][
					set-memory s + len #"0" e - len
					end: s + e
					e: e + 1
					s/e: #"."
				]
				e: 0
			]
			true [
				e: 0 - e + 2
				move-memory s + e s len + 1
				set-memory s #"0" e
				s/2: #"."
				end: s + len + e
				e: 0
			]
		]

		if end/1 = #"." [
			end: end + 1
			end/1: #"0"
		]
		if e <> 0 [
			end: end + 1
			end/1: #"e"
			ss: integer/form-signed e - 1
			len: length? ss
			copy-memory end + 1 as byte-ptr! ss len
			end: end + len
		]

		end/2: #"^@"
		if sig <> 0 [s: s - 1]
		as c-string! s
	]
]