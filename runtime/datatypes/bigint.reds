Red/System [
	Title:   "bigint datatype runtime functions"
	Author:  "Bitbegin, Xie Qingtian"
	File: 	 %bigint.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

bigint: context [
	verbose: 0

	;-- caches for intermediate use
	_Q:				as red-bigint! 0
	_R:				as red-bigint! 0
	_Y:				as red-bigint! 0
	_T1:			as red-bigint! 0
	_T2:			as red-bigint! 0
	_T3:			as red-bigint! 0

	ciL:			4				;-- bigint! unit is 4 bytes
	biL:			ciL << 3		;-- bits in limb
	biLH:			ciL << 2		;-- half bits in limb
	BN_MAX_LIMB:	256				;-- 256 * 32 bits

	#define MULADDC_INIT [
		s0: 0 s1: 0 b0: 0 b1: 0 r0: 0 r1: 0 rx: 0 ry: 0
		b0: (b << biLH) >>> biLH
		b1: b >>> biLH
	]
	#define MULADDC_CORE [
		s0: (s/1 << biLH) >>> biLH
		s1: s/1 >>> biLH		s: s + 1
		rx: s0 * b1 			r0: s0 * b0
		ry: s1 * b0 			r1: s1 * b1
		r1: r1 + (rx >>> biLH)
		r1: r1 + (ry >>> biLH)
		rx: rx << biLH 			ry: ry << biLH
		r0: r0 + rx 			r1: r1 + as integer! (uint-less r0 rx)
		r0: r0 + ry 			r1: r1 + as integer! (uint-less r0 ry)
		r0: r0 + c 				r1: r1 + as integer! (uint-less r0 c)
		r0: r0 + d/1			r1: r1 + as integer! (uint-less r0 d/1)
		c: r1					d/1: r0		d: d + 1
	]

	;-- Count leading zero bits in a given integer
	clz: func [
		int			[integer!]
		return:		[integer!]
		/local
			mask	[integer!]
			ret		[integer!]
	][
		mask: 1 << (biL - 1)
		ret: 0
		
		loop biL [
			if (int and mask) <> 0 [
				break;
			]
			mask: mask >>> 1
			ret: ret + 1
		]
		ret
	]

	bitlen: func [
		big			[red-bigint!]
		return:		[integer!]
		/local
			s		[series!]
			p		[int-ptr!]
			ret		[integer!]
	][
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset

		if big/size = 0 [return 0]

		p: p + big/size - 1

		ret: biL - clz p/1
		ret + ((big/size - 1) * biL)
	]

	zero-big?: func [
		big		[red-bigint!]
		return: [logic!]
		/local
			s	[series!]
			p	[int-ptr!]
	][
		either big/size = 1 [
			s: GET_BUFFER(big)
			p: as int-ptr! s/offset
			p/value = 0
		][false]
	]

	left-shift: func [
		big			[red-bigint!]
		count		[integer!]
		/local
			ret		[integer!]
			i		[integer!]
			v0		[integer!]
			t1		[integer!]
			r0		[integer!]
			r1		[integer!]
			s		[series!]
			len		[integer!]
			p		[int-ptr!]
			p1		[int-ptr!]
			p2		[int-ptr!]
	][
		r0: 0
		v0: count / biL
		t1: count and (biL - 1)
		i: bitlen big
		i: i + count
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset

		if (big/size * biL) < i [
			len: i / biL
			if i % biL <> 0 [
				len: len + 1
			]
			grow big len
			s: GET_BUFFER(big)
			p: as int-ptr! s/offset
			big/size: len
		]

		len: big/size

		ret: 0

		if v0 > 0 [
			i: len
			while [i > v0][
				p1: p + i - 1
				p2: p + i - v0 - 1
				p1/1: p2/1
				i: i - 1
			]

			while [i > 0][
				p1: p + i - 1
				p1/1: 0
				i: i - 1
			]
		]

		if t1 > 0 [
			i: v0
			while [i < len][
				p1: p + i
				r1: p1/1 >>> (biL - t1)
				p1/1: p1/1 << t1
				p1/1: p1/1 or r0
				r0: r1
				i: i + 1
			]
		]

		if any [
			v0 > 0
			t1 > 0
		][
			shrink big
		]
	]

	right-shift: func [
		big			[red-bigint!]
		count		[integer!]
		/local
			ret		[integer!]
			i		[integer!]
			v0		[integer!]
			v1		[integer!]
			r0		[integer!]
			r1		[integer!]
			s		[series!]
			len		[integer!]
			p		[int-ptr!]
			p1		[int-ptr!]
			p2		[int-ptr!]
	][
		r0: 0
		v0: count / biL
		v1: count and (biL - 1)

		s: GET_BUFFER(big)
		p: as int-ptr! s/offset

		if any [
			v0 > big/size
			all [
				v0 = big/size
				v1 > 0
			]
		][
			load-int big 0 1
			exit
		]

		len: big/size

		ret: 0

		if v0 > 0 [
			i: 0
			while [i < (len - v0)][
				p1: p + i
				p2: p + i + v0
				p1/1: p2/1
				i: i + 1
			]

			while [i < len][
				p1: p + i
				p1/1: 0
				i: i + 1
			]
		]

		if v1 > 0 [
			i: len
			while [i > 0][
				p1: p + i - 1
				r1: p1/1 << (biL - v1)
				p1/1: p1/1 >>> v1
				p1/1: p1/1 or r0
				r0: r1
				i: i - 1
			]
		]

		if any [
			v0 > 0
			v1 > 0
		][
			shrink big
		]
	]

	serialize: func [
		big			[red-bigint!]
		buffer		[red-string!]
		flat?		[logic!]
		arg			[red-value!]
		part		[integer!]
		mold?		[logic!]
		return: 	[integer!]
		/local
			n		[integer!]
			s	 	[series!]
			i		[integer!]
			j		[integer!]
			k		[integer!]
			c		[integer!]
			saved	[integer!]
			bytes	[integer!]
			ss		[series!]
			h		[c-string!]
			Q		[red-bigint!]
			R		[red-bigint!]
			buf		[byte-ptr!]
			p		[byte-ptr!]
			pp		[int-ptr!]
	][
		;;@@ TBD Optimization, the string is ASCII only
		n: big/size
		n: either mold? [n * 8 + 3][n * 10 + 1]
		if n > 32 [n: n / 32 + n + 1]

		s: GET_BUFFER(buffer)
		s: expand-series s s/size + n			;-- allocate enough memory

		if big/sign = -1 [
			string/append-char s as-integer #"-"
			part: part - 1
		]

		bytes: 0
		either mold? [
			string/concatenate-literal buffer "0x"
			part: part - 2
			i: big/size
			n: i
			s: GET_BUFFER(big)
			pp: as int-ptr! s/offset
			s: GET_BUFFER(buffer)
			k: 0
			while [i > 0][
				j: ciL
				while [j > 0][
					c: (pp/i >>> ((j - 1) << 3)) and FFh
					h: string/byte-to-hex c
					if i = n [			;-- first unit
						either c = 0 [
							j: j - 1
							continue
						][
							if h/1 = #"0" [h: h + 1 part: part + 1]
						]
					]
					part: part - 2
					string/concatenate-literal buffer h

					bytes: bytes + 1
					if bytes % 32 = 0 [
						string/append-char s as-integer lf
						part: part - 1
					]

					k: 1
					j: j - 1
				]
				i: i - 1
			]
		][
			Q: _Q R: _R

			s: GET_BUFFER(buffer)
			buf: as byte-ptr! s/offset
			p: buf + n
			copy big Q
			Q/sign: 1
			while [0 < compare-int Q 0][
				div-int Q 10 null null
				ss: GET_BUFFER(R)
				pp: as int-ptr! ss/offset
				p: p - 1
				p/value: as byte! pp/value + 30h
			]
			n: n - (as-integer p - buf)
			buf: as byte-ptr! s/tail
			move-memory buf p n
			s/tail: as cell! (buf + n)
			part: part - n
		]
		part 
	]

	do-math: func [
		type		[math-op!]
		return:		[red-value!]
		/local
			left	[red-bigint!]
			right	[red-bigint!]
			big		[red-bigint!]
			rem		[red-bigint!]
			int		[red-integer!]
			ret		[integer!]
			n		[integer!]
	][
		left: as red-bigint! stack/arguments
		right: left + 1

		assert any [
			TYPE_OF(right) = TYPE_INTEGER
			TYPE_OF(right) = TYPE_BIGINT
		]

		big: as red-bigint! stack/push*
		switch TYPE_OF(right) [
			TYPE_INTEGER [
				int: as red-integer! right
				n: int/value
				switch type [
					OP_ADD [
						add-int left n big
					]
					OP_SUB [
						sub-int left n big
					]
					OP_MUL [
						mul-int left n big yes
					]
					OP_DIV [
						div-int left n big null
					]
					OP_REM [
						ret: 0
						mod-int :ret left n
						load-int big ret 1
					]
				]
			]
			TYPE_BIGINT [
				switch type [
					OP_ADD [
						add-big left right big
					]
					OP_SUB [
						sub-big left right big
					]
					OP_MUL [
						mul-big left right big
					]
					OP_DIV [
						rem: make-at stack/push* 1
						div-big left right big rem
					]
					OP_REM [
						mod-big big left right
					]
				]
			]
		]
		SET_RETURN(big)
	]

	make-at: func [
		slot		[red-value!]
		len 		[integer!]
		return:		[red-bigint!]
		/local
			big		[red-bigint!]
			s		[series!]
			p4		[int-ptr!]
	][
		if len = 0 [len: 1]

		;-- make bigint!
		big: as red-bigint! slot
		big/header: TYPE_UNSET
		big/node:	alloc-series len 4 0
		big/sign:	1
		big/size:	1
		big/header: TYPE_BIGINT

		;-- init to zero
		s: GET_BUFFER(big)
		p4: as int-ptr! s/offset
		loop len [
			p4/1: 0
			p4: p4 + 1
		]
		big
	]

	copy: func [
		src	 		[red-bigint!]
		big			[red-bigint!]
		return:		[red-bigint!]
		/local
			s1	 	[series!]
			s2	 	[series!]
			p1		[byte-ptr!]
			p2		[byte-ptr!]
			size	[integer!]
	][
		if src = big [return big]
		
		s1: GET_BUFFER(src)
		p1: as byte-ptr! s1/offset
		size: src/size * 4

		s2: GET_BUFFER(big)
		p2: as byte-ptr! s2/offset

		if s2/size < size [
			grow big src/size
			s2: GET_BUFFER(big)
			p2: as byte-ptr! s2/offset
		]

		big/sign: src/sign
		big/size: src/size
		if size > 0 [copy-memory p2 p1 size]
		big
	]

	grow: func [
		big			[red-bigint!]
		len			[integer!]
		/local
			s	 	[series!]
			p		[int-ptr!]
			ex_size	[integer!]
			ex_len	[integer!]
	][
		if len > BN_MAX_LIMB [fire [TO_ERROR(math overflow)]]
		if len = 0 [exit]

		s: GET_BUFFER(big)
		ex_size: len * 4 - s/size 
		if ex_size > 0 [
			s: expand-series s len * 4 
		]

		;-- set to zero
		p: as int-ptr! s/offset + big/size
		ex_len: len - big/size
		loop ex_len [
			p/1: 0
			p: p + 1
		]
		big/size: len
	]

	shrink: func [
		big			[red-bigint!]
		/local
			s	 	[series!]
			p		[int-ptr!]
			len		[integer!]
	][
		s: GET_BUFFER(big)
		len: big/size
		p: as int-ptr! s/offset
		p: p + len
		loop len [
			p: p - 1
			either p/1 = 0 [
				big/size: big/size - 1
			][
				break
			]
		]
		if big/size = 0 [big/size: 1]
	]

	;-- u1 < u2
	uint-less: func [
		u1			[integer!]
		u2			[integer!]
		return:		[logic!]
	][
		(as int-ptr! u1) < (as int-ptr! u2)
	]

	load-int: func [
		big		[red-bigint!]
		int		[integer!]
		sz		[integer!]				;-- buffer size
		/local
			s	[series!]
			p	[int-ptr!]
	][
		make-at as red-value! big sz
		big/size: 1
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset
		p/1: either int >= 0 [
			big/sign: 1
			int
		][
			big/sign: -1
			0 - int
		]
	]

	absolute-add: func [
		big1	 	[red-bigint!]
		big2		[red-bigint!]
		big			[red-bigint!]		;-- if null, added to big1
		/local
			s	 	[series!]
			s2	 	[series!]
			p		[int-ptr!]
			p2		[int-ptr!]
			i		[integer!]
			c		[integer!]
			tmp		[integer!]
			sz		[integer!]
			sz2		[integer!]
	][
		s2: GET_BUFFER(big2)
		p2: as int-ptr! s2/offset
		sz2: big2/size

		either null? big [big: big1][
			sz: either sz2 > big1/size [sz2][big1/size]
			make-at as red-value! big sz + 1
			copy big1 big
			big/size: sz
		]
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset

		c: 0
		i: 0
		loop sz2 [
			tmp: p2/1
			p/1: p/1 + c
			c: as integer! uint-less p/1 c
			p/1: p/1 + tmp
			c: c + as integer! uint-less p/1 tmp
			p: p + 1
			p2: p2 + 1
			i: i + 1
		]

		while [c > 0][
			p/1: p/1 + c
			c: as integer! uint-less p/1 c
			i: i + 1
			p: p + 1
		]
		if big/size < i [big/size: i]
	]

	sub-hlp: func [
		n			[integer!]
		s	 		[int-ptr!]
		d	 		[int-ptr!]
		/local
			c		[integer!]
			z		[integer!]
	][
		c: 0
		loop n [
			z: as integer! (uint-less d/1 c)
			d/1: d/1 - c
			c: z + as integer! (uint-less d/1 s/1)
			d/1: d/1 - s/1
			s: s + 1
			d: d + 1
		]
		
		while [c <> 0][
			z: as integer! (uint-less d/1 c)
			d/1: d/1 - c
			c: z
			d: d + 1
		]
	]
	
	;-- big1 must large than big2
	absolute-sub: func [
		big1	 	[red-bigint!]
		big2		[red-bigint!]
		big	 		[red-bigint!]
		/local
			s	 	[series!]
			s1	 	[series!]
			s2	 	[series!]
			p		[int-ptr!]
			p2		[int-ptr!]
			len		[integer!]
			c		[integer!]
			z		[integer!]
	][
		assert big1/size >= big2/size

		s1: GET_BUFFER(big1)
		s2: GET_BUFFER(big2)
		p2: as int-ptr! s2/offset
		len: big2/size

		either null? big [big: big1][
			make-at as red-value! big big1/size
			copy big1 big
		]
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset
		sub-hlp len p2 p
		shrink big
	]

	absolute-compare: func [
		big1	 	[red-bigint!]
		big2	 	[red-bigint!]
		return:	 	[integer!]
		/local
			s1	 	[series!]
			s2	 	[series!]
			p1		[int-ptr!]
			p2		[int-ptr!]
	][
		s1: GET_BUFFER(big1)
		s2: GET_BUFFER(big2)

		if all [
			big1/size = 0
			big2/size = 0
		][
			return 0
		]

		if big1/size > big2/size [return 1]
		if big2/size > big1/size [return -1]

		p1: as int-ptr! s1/offset
		p1: p1 + big1/size
		p2: as int-ptr! s2/offset
		p2: p2 + big2/size
		loop big1/size [
			p1: p1 - 1
			p2: p2 - 1
			if uint-less p2/1 p1/1 [return 1]
			if uint-less p1/1 p2/1 [return -1]
		]
		return 0
	]

	add-big: func [
		big1	 	[red-bigint!]
		big2		[red-bigint!]
		big	 		[red-bigint!]
	][
		either big1/sign <> big2/sign [
			either (absolute-compare big1 big2) >= 0 [
				absolute-sub big1 big2 big
			][
				absolute-sub big2 big1 big
			]
		][
			absolute-add big1 big2 big
		]
	]

	sub-big: func [
		big1	 	[red-bigint!]
		big2		[red-bigint!]
		big	 		[red-bigint!]
	][
		either big1/sign = big2/sign [
			either (absolute-compare big1 big2) >= 0 [
				absolute-sub big1 big2 big
			][
				absolute-sub big2 big1 big
			]
		][
			absolute-add big1 big2 big
		]
	]

	add-int: func [
		big		[red-bigint!]
		int		[integer!]
		ret		[red-bigint!]
	][
		load-int ret int big/size + 1
		add-big ret big null
	]

	sub-int: func [
		big		[red-bigint!]
		int		[integer!]
		ret		[red-bigint!]
	][
		load-int ret int big/size + 1
		either big/sign = ret/sign [
			if (absolute-compare ret big) < 0 [
				copy big ret
				load-int big int 1
			]
			absolute-sub ret big null
		][
			absolute-add ret big null
		]
	]

	mul-hlp: func [
		i			[integer!]
		s	 		[int-ptr!]
		d	 		[int-ptr!]
		b			[integer!]
		/local
			c		[integer!]
			t		[integer!]
			s0		[integer!]
			s1		[integer!]
			b0		[integer!]
			b1		[integer!]
			r0		[integer!]
			r1		[integer!]
			rx		[integer!]
			ry		[integer!]
	][
		c: 0
		t: 0

		while [i >= 8][
			MULADDC_INIT
			MULADDC_CORE   MULADDC_CORE
			MULADDC_CORE   MULADDC_CORE

			MULADDC_CORE   MULADDC_CORE
			MULADDC_CORE   MULADDC_CORE
			i: i - 8
		]

		while [i > 0][
			MULADDC_INIT
			MULADDC_CORE
			i: i - 1
		]

		t: t + 1

		until [
			d/1: d/1 + c
			c: as integer! uint-less d/1 c
			d: d + 1
			c = 0
		]
	]

	mul-big: func [
		big1		[red-bigint!]
		big2		[red-bigint!]
		big			[red-bigint!]		;-- result
		/local
			s	 	[series!]
			s1	 	[series!]
			s2	 	[series!]
			p		[int-ptr!]
			p1		[int-ptr!]
			p2		[int-ptr!]
			len1	[integer!]
			len2	[integer!]
			pt		[int-ptr!]
			len		[integer!]
	][
		len1: big1/size
		len2: big2/size
		s1: GET_BUFFER(big1)
		s2: GET_BUFFER(big2)
		p1: as int-ptr! s1/offset
		p2: as int-ptr! s2/offset

		len: len1 + len2 + 1
		either all [null? big big2/size = 1][
			big: big2
		][
			big: make-at as red-value! big len
		]
		big/size: len
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset

		while [len2 > 0][
			pt: p2 + len2 - 1
			mul-hlp len1 p1 (p + len2 - 1) pt/1
			len2: len2 - 1
		]

		big/sign: big1/sign * big2/sign
		shrink big
	]

	mul-int: func [
		big		[red-bigint!]
		int		[integer!]
		ret		[red-bigint!]
		signed? [logic!]
		/local
			s	 	[series!]
			p		[int-ptr!]
			len		[integer!]
			si		[integer!]
	][
		len: big/size
		si: either signed? [
			make-at as red-value! ret len + 2
			either int >= 0 [1][int: 0 - int -1]
		][
			ret/size: 0
			grow ret len + 2
			1
		]

		s: GET_BUFFER(big)
		p: as int-ptr! s/offset
		s: GET_BUFFER(ret)
		mul-hlp len p as int-ptr! s/offset int

		ret/size: len + 2
		ret/sign: big/sign * si
		shrink ret
	]

	uint-div: func [
		u1				[integer!]
		u0				[integer!]
		return:			[integer!]
		/local
			i			[integer!]
	][
		if u0 = 0 [return u1 / u0]
		if uint-less u1 u0 [return 0]

		i: 0
		while [true] [
			u1: u1 - u0
			i: i + 1
			if uint-less u1 u0 [return i]
		]
		return i
	]
	
	long-divide: func [
		u1				[integer!]
		u0				[integer!]
		d				[integer!]
		return:			[integer!]
		/local
			radix		[integer!]
			hmask		[integer!]
			d0			[integer!]
			d1			[integer!]
			q0			[integer!]
			q1			[integer!]
			rAX			[integer!]
			r0			[integer!]
			quotient	[integer!]
			u0_msw		[integer!]
			u0_lsw		[integer!]
			s			[integer!]
			tmp			[integer!]
	][
		radix: 1 << biLH
		hmask: radix - 1

		if any [
			d = 0
			not uint-less u1 d
		][
			return -1
		]

		s: clz d
		d: d << s

		u1: u1 << s
		tmp: u0 >>> (biL - s)
		tmp: tmp and ((0 - s) >> (biL - 1))
		u1: u1 or tmp
	    u0: u0 << s

		d1: d >>> biLH
		d0: d and hmask

		u0_msw: u0 >>> biLH
		u0_lsw: u0 and hmask
		
		q1: uint-div u1 d1
		r0: u1 - (d1 * q1)

		while [
			any [
				not uint-less q1 radix
				uint-less (radix * r0 + u0_msw) (q1 * d0)
			]
		][
			q1: q1 - 1;
			r0: r0 + d1

			unless uint-less r0 radix [break]
		]

		rAX: (u1 * radix) + (u0_msw - (q1 * d))
		q0: uint-div rAX d1
		r0: rAX - (q0 * d1)

		while [
			any [
				not uint-less q0 radix
				uint-less (radix * r0 + u0_lsw) (q0 * d0)
			]
		][
			q0: q0 - 1
			r0: r0 + d1

			unless uint-less r0 radix [break]
		]

		quotient: q1 * radix + q0
		quotient
	]

	;-- A = Q * B + R
	div-big: func [
		A	 		[red-bigint!]
		B	 		[red-bigint!]
		Q	 		[red-bigint!]
		R	 		[red-bigint!]
		return:	 	[logic!]
		/local
			Y		[red-bigint!]
			T1		[red-bigint!]
			T2		[red-bigint!]
			T3		[red-bigint!]
			i		[integer!]
			n		[integer!]
			t		[integer!]
			k		[integer!]
			s		[series!]
			px		[int-ptr!]
			py		[int-ptr!]
			pz		[int-ptr!]
			pt1		[int-ptr!]
			pt2		[int-ptr!]
			tmp		[integer!]
			tmp2	[integer!]
			ret		[integer!]
	][
		Y: _Y T1: _T1 T2: _T2 T3: _T3

		either null? B [B: Y][
			copy B Y
			Y/sign: 1
		]

		if 0 = compare-int B 0 [
			fire [TO_ERROR(math zero-divide)]
			return false
		]

		either null? R [
			R: _R
			grow R A/size
		][
			make-at as red-value! R A/size
		]
		copy A R

		either null? Q [
			Q: _Q
			Q/size: 0
			grow Q A/size + 2
			if (absolute-compare A B) < 0 [
				Q/size: 1
				return true
			]
		][
			if (absolute-compare A B) < 0 [
				load-int Q 0 1
				return true
			]
			make-at as red-value! Q A/size + 2
			Q/size: A/size + 2
		]

		R/sign: 1

		k: (bitlen Y) % biL
		
		either k < (biL - 1) [
			k: biL - 1 - k
			left-shift R k
			left-shift Y k
		][
			k: 0
		]

		n: R/size
		t: Y/size
		copy Y T1
		left-shift T1 (biL * (n - t))

		s: GET_BUFFER(Q)
		pz: as int-ptr! s/offset
		while [(compare-big R T1) >= 0][
			tmp: n - t + 1
			pz/tmp: pz/tmp + 1
			sub-big R T1 null
		]

		s: GET_BUFFER(R)
		px: as int-ptr! s/offset
		s: GET_BUFFER(Y)
		py: as int-ptr! s/offset

		i: n
		while [i > t][
			tmp: i - t
			either not uint-less px/i py/t [
				pz/tmp: -1
			][
				tmp2: i - 1
				pz/tmp: long-divide px/i px/tmp2 py/t
			]

			pz/tmp: pz/tmp + 1
			until [
				pz/tmp: pz/tmp - 1

				s: GET_BUFFER(T1)
				pt1: as int-ptr! s/offset
				pt1/1: either t < 2 [
					0
				][
					tmp2: t - 1
					py/tmp2
				]
				pt1/2: py/t
				T1/size: 2

				mul-int T1 pz/tmp T3 no

				s: GET_BUFFER(T2)
				pt2: as int-ptr! s/offset
				pt2/1: either i < 3 [0][
					tmp2: i - 2
					px/tmp2
				]
				pt2/2: either i < 2 [0][
					tmp2: i - 1
					px/tmp2
				]
				pt2/3: px/i
				T2/size: 3

				0 >= compare-big T3 T2
			]

			mul-int Y pz/tmp T1 no
			left-shift T1 biL * (tmp - 1)
			sub-big R T1 null
			s: GET_BUFFER(R)
			px: as int-ptr! s/offset
			if (compare-int R 0) < 0 [
				copy Y T1		
				left-shift T1 (biL * (tmp - 1))
				add-big R T1 null
				s: GET_BUFFER(R)
				px: as int-ptr! s/offset
				pz/tmp: pz/tmp - 1
			]
			i: i - 1
		]
		
		shrink Q
		Q/sign: A/sign * B/sign
		
		right-shift R k
		R/sign: A/sign
		shrink R

		if (compare-int R 0) = 0 [
			R/sign: 1
		]
		return true
	]
	
	div-int: func [
		A	 		[red-bigint!]
		int	 		[integer!]
		Q	 		[red-bigint!]
		R	 		[red-bigint!]
		return:	 	[logic!]
		/local
			s	 	[series!]
			p		[int-ptr!]
	][
		s: GET_BUFFER(_Y)
		p: as int-ptr! s/offset
		p/1: int
		_Y/size: 1
		_Y/sign: either int >= 0 [1][-1]
		div-big A null Q R
	]
	
	mod-big: func [
		R	 		[red-bigint!]
		A	 		[red-bigint!]
		B	 		[red-bigint!]
		return:	 	[logic!]
	][
		;-- temp error
		if (compare-int B 0) < 0 [
			fire [TO_ERROR(math zero-divide)]
			0								;-- pass the compiler's type-checking
			return false
		]

		div-big A B null R
		
		if (compare-int R 0) < 0 [
			add-big R B R
		]
		
		if (compare-big R B) >= 0 [
			sub-big R B R
		]
		
		return true
	]

	mod-int: func [
		r	 		[int-ptr!]
		A	 		[red-bigint!]
		b	 		[integer!]
		return:	 	[logic!]
		/local
			s	 	[series!]
			p		[int-ptr!]
			x		[integer!]
			y		[integer!]
			z		[integer!]
	][
		if b <= 0 [
			fire [TO_ERROR(math zero-divide)]
			return false
		]

		s: GET_BUFFER(A)
		p: as int-ptr! s/offset
		
		if b = 1 [
			r/1: 0
			return true
		]
		
		if b = 2 [
			r/1: p/1 and 1
			return true
		]
		
		y: 0
		p: p + A/size - 1
		loop A/size [
			x: p/1
			y: (y << biLH) or (x >>> biLH)
			z: uint-div y b
			y: y - (z * b)
			
			x: x << biLH
			y: (y << biLH) or (x >>> biLH)
			z: uint-div y b
			y: y - (z * b)
			
			p: p - 1
		]
		
		if all [
			A/sign < 0
			y <> 0
		][
			y: b - y
		]
		
		r/1: y
		return true
	]

	compare-big: func [
		big1	 	[red-bigint!]
		big2	 	[red-bigint!]
		return:	 	[integer!]
	][
		if all [
			big1/sign = 1
			big2/sign = -1
		][
			return 1
		]

		if all [
			big2/sign = 1
			big1/sign = -1
		][
			return -1
		]

		either big1/sign = 1 [
			return absolute-compare big1 big2
		][
			return absolute-compare big2 big1
		]
	]

	compare-int: func [
		big	 		[red-bigint!]
		int			[integer!]
		return:	 	[integer!]
		/local
			s		[series!]
			p		[int-ptr!]
	][
		assert big/size > 0

		s: GET_BUFFER(big)
		p: as int-ptr! s/offset

		either big/sign = -1 [-1][
			either big/size = 1 [p/1 - int][1]
		]
	]

	;--- Actions ---

	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-bigint!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/make"]]
		as red-bigint! to proto spec type
	]

	to: func [
		proto		[red-value!]
		spec		[red-value!]
		type		[integer!]								;-- target type
		return:		[red-value!]
		/local
			int		[red-integer!]
			bin		[red-binary!]
			big		[red-bigint!]
			s		[series!]
			sbin	[series!]
			pbig	[byte-ptr!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			len		[integer!]
			size	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/to"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				load-int as red-bigint! proto int/value 1
			]
			TYPE_BINARY [
				bin: as red-binary! spec
				sbin: GET_BUFFER(bin)
				head: (as byte-ptr! sbin/offset) + bin/head
				tail: as byte-ptr! sbin/tail
				size: as-integer tail - head
				either size = 0 [
					load-int as red-bigint! proto 0 1
				][
					len: size / 4
					if size % 4 <> 0 [
						len: len + 1
					]
					big: make-at proto len
					s: GET_BUFFER(big)
					pbig: as byte-ptr! s/offset
					big/size: len
					loop size [
						tail: tail - 1
						pbig/1: tail/1
						pbig: pbig + 1
					]
					shrink big
				]
			]
			TYPE_HEX [copy-big as red-bigint! spec as red-bigint! proto]
			default [fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_BIGINT spec]]
		]
		proto
	]

	form: func [
		big		[red-bigint!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/form"]]

		serialize big buffer yes arg part no
	]

	mold: func [
		big		[red-bigint!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return:	[integer!]
		/local
			formed [c-string!]
			s	   [series!]
			unit   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/mold"]]

		serialize big buffer flat? arg part no
	]

	compare: func [
		value1    [red-bigint!]						;-- first operand
		value2    [red-bigint!]						;-- second operand
		op	      [integer!]						;-- type of comparison
		return:   [integer!]
		/local
			res	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/compare"]]

		if all [
			op = COMP_STRICT_EQUAL
			TYPE_OF(value1) <> TYPE_OF(value2)
		][return 1]

		switch op [
			COMP_EQUAL		[res: compare-big value1 value2]
			COMP_NOT_EQUAL 	[res: not compare-big value1 value2]
			default [
				res: SIGN_COMPARE_RESULT(value1 value2)
			]
		]
		res
	]

	copy-big: func [
		big		[red-bigint!]
		dst		[red-bigint!]
		return: [red-bigint!]
	][
		make-at as red-value! dst big/size
		copy big dst
	]

	absolute: func [
		return: [red-bigint!]
		/local
			big [red-bigint!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bigint/absolute"]]

		big: copy-big as red-bigint! stack/arguments as red-bigint! stack/push*
		big/sign: 1
		stack/set-last as red-value! big
		big
	]

	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/add"]]

		as red-value! do-math OP_ADD
	]
	
	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/divide"]]

		as red-value! do-math OP_DIV
	]

	multiply: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/multiply"]]
		as red-value! do-math OP_MUL
	]

	subtract: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/subtract"]]

		as red-value! do-math OP_SUB
	]

	even?: func [
		big		[red-bigint!]
		return: [logic!]
		/local
			s	[series!]
			p	[int-ptr!]
	][
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset
		not as-logic p/value and 1
	]

	odd?: func [
		big		[red-bigint!]
		return: [logic!]
		/local
			s	[series!]
			p	[int-ptr!]
	][
		s: GET_BUFFER(big)
		p: as int-ptr! s/offset
		as-logic p/value and 1
	]

	negate: func [
		return: [red-bigint!]
		/local
			big [red-bigint!]
	][
		big: copy-big as red-bigint! stack/arguments as red-bigint! stack/push*
		big/sign: 0 - big/sign
		stack/set-last as red-value! big
		big
	]

	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bigint/remainder"]]
		as red-value! do-math OP_REM
	]

	#if debug? = yes [
		dump-bigint: func [
			big			[red-bigint!]
			/local
				s	 	[series!]
				p		[byte-ptr!]
		][
			s: GET_BUFFER(big)
			p: as byte-ptr! s/offset
			print-line [lf "===============dump bigint!==============="]
			print-line ["used: " big/size " sign: " big/sign " addr: " p]
			p: p + (big/size * 4)
			loop big/size * 4 [
				p: p - 1
				prin-hex-chars as-integer p/1 2
			]
			print-line lf
			print-line ["=============dump bigint! end=============" lf]
		]
	]

	init-caches: does [
		_Q:  make-at ALLOC_TAIL(root) 1
		_R:  make-at ALLOC_TAIL(root) 1
		_Y:  make-at ALLOC_TAIL(root) 1
		_T1: make-at ALLOC_TAIL(root) 1
		_T2: make-at ALLOC_TAIL(root) 1
		_T3: make-at ALLOC_TAIL(root) 1
	]

	init: does [
		datatype/register [
			TYPE_BIGINT
			TYPE_VALUE
			"bigint!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			:to
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute
			:add
			:divide
			:multiply
			:negate
			null			;power
			:remainder
			null			;round
			:subtract
			:even?
			:odd?
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;move
			null			;next
			null			;pick
			null			;poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]