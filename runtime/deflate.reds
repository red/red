Red/System []

deflate: context [
	#define DICT_BITS		10
	#define DICT_SIZE		1024	;[1 << DICT_BITS]
	#define DICT_MASK		1023	;[DICT_SIZE - 1]
	#define DICT_BITS_R		14		;[24 - DICT_BITS]
	#define CACHE_SIZE		4
	#define CACHE_MASK		3		;[CACHE_SIZE - 1]
	#define MAX_OFF			32768	;[1 << 15]
	#define MIN_MATCH		3
	#define MAX_MATCH		258
	#define DICT_BUFF_SIZE	4096	;[DICT_SIZE * CACHE_SIZE]

	STATUS!: alias struct! [
		bits		[integer!]
		cnt			[integer!]
	]

	MIRROR: [
		#"^(00)" #"^(80)" #"^(40)" #"^(C0)" #"^(20)" #"^(A0)" #"^(60)" #"^(E0)" #"^(10)" #"^(90)" #"^(50)" #"^(D0)" #"^(30)" #"^(B0)" #"^(70)" #"^(F0)"
		#"^(08)" #"^(88)" #"^(48)" #"^(C8)" #"^(28)" #"^(A8)" #"^(68)" #"^(E8)" #"^(18)" #"^(98)" #"^(58)" #"^(D8)" #"^(38)" #"^(B8)" #"^(78)" #"^(F8)"
		#"^(04)" #"^(84)" #"^(44)" #"^(C4)" #"^(24)" #"^(A4)" #"^(64)" #"^(E4)" #"^(14)" #"^(94)" #"^(54)" #"^(D4)" #"^(34)" #"^(B4)" #"^(74)" #"^(F4)"
		#"^(0C)" #"^(8C)" #"^(4C)" #"^(CC)" #"^(2C)" #"^(AC)" #"^(6C)" #"^(EC)" #"^(1C)" #"^(9C)" #"^(5C)" #"^(DC)" #"^(3C)" #"^(BC)" #"^(7C)" #"^(FC)"
		#"^(02)" #"^(82)" #"^(42)" #"^(C2)" #"^(22)" #"^(A2)" #"^(62)" #"^(E2)" #"^(12)" #"^(92)" #"^(52)" #"^(D2)" #"^(32)" #"^(B2)" #"^(72)" #"^(F2)"
		#"^(0A)" #"^(8A)" #"^(4A)" #"^(CA)" #"^(2A)" #"^(AA)" #"^(6A)" #"^(EA)" #"^(1A)" #"^(9A)" #"^(5A)" #"^(DA)" #"^(3A)" #"^(BA)" #"^(7A)" #"^(FA)"
		#"^(06)" #"^(86)" #"^(46)" #"^(C6)" #"^(26)" #"^(A6)" #"^(66)" #"^(E6)" #"^(16)" #"^(96)" #"^(56)" #"^(D6)" #"^(36)" #"^(B6)" #"^(76)" #"^(F6)"
		#"^(0E)" #"^(8E)" #"^(4E)" #"^(CE)" #"^(2E)" #"^(AE)" #"^(6E)" #"^(EE)" #"^(1E)" #"^(9E)" #"^(5E)" #"^(DE)" #"^(3E)" #"^(BE)" #"^(7E)" #"^(FE)"
		#"^(01)" #"^(81)" #"^(41)" #"^(C1)" #"^(21)" #"^(A1)" #"^(61)" #"^(E1)" #"^(11)" #"^(91)" #"^(51)" #"^(D1)" #"^(31)" #"^(B1)" #"^(71)" #"^(F1)"
		#"^(09)" #"^(89)" #"^(49)" #"^(C9)" #"^(29)" #"^(A9)" #"^(69)" #"^(E9)" #"^(19)" #"^(99)" #"^(59)" #"^(D9)" #"^(39)" #"^(B9)" #"^(79)" #"^(F9)"
		#"^(05)" #"^(85)" #"^(45)" #"^(C5)" #"^(25)" #"^(A5)" #"^(65)" #"^(E5)" #"^(15)" #"^(95)" #"^(55)" #"^(D5)" #"^(35)" #"^(B5)" #"^(75)" #"^(F5)"
		#"^(0D)" #"^(8D)" #"^(4D)" #"^(CD)" #"^(2D)" #"^(AD)" #"^(6D)" #"^(ED)" #"^(1D)" #"^(9D)" #"^(5D)" #"^(DD)" #"^(3D)" #"^(BD)" #"^(7D)" #"^(FD)"
		#"^(03)" #"^(83)" #"^(43)" #"^(C3)" #"^(23)" #"^(A3)" #"^(63)" #"^(E3)" #"^(13)" #"^(93)" #"^(53)" #"^(D3)" #"^(33)" #"^(B3)" #"^(73)" #"^(F3)"
		#"^(0B)" #"^(8B)" #"^(4B)" #"^(CB)" #"^(2B)" #"^(AB)" #"^(6B)" #"^(EB)" #"^(1B)" #"^(9B)" #"^(5B)" #"^(DB)" #"^(3B)" #"^(BB)" #"^(7B)" #"^(FB)"
		#"^(07)" #"^(87)" #"^(47)" #"^(C7)" #"^(27)" #"^(A7)" #"^(67)" #"^(E7)" #"^(17)" #"^(97)" #"^(57)" #"^(D7)" #"^(37)" #"^(B7)" #"^(77)" #"^(F7)"
		#"^(0F)" #"^(8F)" #"^(4F)" #"^(CF)" #"^(2F)" #"^(AF)" #"^(6F)" #"^(EF)" #"^(1F)" #"^(9F)" #"^(5F)" #"^(DF)" #"^(3F)" #"^(BF)" #"^(7F)" #"^(FF)"
	]

	LXMIN: [0 11 19 35 67 131]
	DXMAX: [0 6 12 24 48 96 192 384 768 1536 3072 6144 12288 24576]
	LMIN: [11 13 15 17 19 23 27 31 35 43 51 59 67 83 99 115 131 163 195 227]
	DMIN: [1 2 3 4 5 7 9 13 17 25 33 49 65 97 129 193 257 385 513 769 1025 1537 2049 3073 4097 6145 8193 12289 16385 24577]

	rev16: func [
		n				[integer!]
		return:			[integer!]
		/local
			t			[integer!]
			r			[integer!]
	][
		t: n and FFh + 1
		r: (as integer! MIRROR/t) << 8
		t: n >>> 8 and FFh + 1
		r: r or as integer! MIRROR/t
		r
	]

	npow2: func [
		n				[integer!]
		return:			[integer!]
		/local
			t			[integer!]
	][
		t: 1 << log-b n
		if n <> t [
			t: t << 1
		]
		t
	]


	hash: func [
		s				[byte-ptr!]
		return:			[integer!]
		/local
			a			[integer!]
			b			[integer!]
			c			[integer!]
			x			[integer!]
	][
		a: as integer! s/1
		b: as integer! s/2
		c: as integer! s/3
		x: a << 16 or (b << 8) or c
		x: x >>> 16 xor x
		x: x * 7FEB352Dh
		x: x >>> 15 xor x
		x: x * 846CA68Bh
		x: x >>> 16 xor x
		x: x and DICT_MASK
		x
	]

	hash2: func [
		s				[byte-ptr!]
		return:			[integer!]
		/local
			a			[integer!]
			b			[integer!]
			c			[integer!]
			x			[integer!]
	][
		a: as integer! s/1
		b: as integer! s/2
		c: as integer! s/3
		x: a << 16 or (b << 8) or c
		x: x >>> DICT_BITS_R - x and CACHE_MASK
		x
	]

	write: func [
		dst				[byte-ptr!]
		end				[byte-ptr!]
		s				[STATUS!]
		code			[integer!]
		bitcnt			[integer!]
		return:			[byte-ptr!]
	][
		s/bits: code << s/cnt or s/bits
		s/cnt: s/cnt + bitcnt
		while [s/cnt >= 8][
			if dst < end [
				dst/1: as byte! s/bits
			]
			dst: dst + 1
			s/bits: s/bits >>> 8
			s/cnt: s/cnt - 8
		]
		dst
	]

	match: func [
		dst				[byte-ptr!]
		end				[byte-ptr!]
		s				[STATUS!]
		dist			[integer!]
		len				[integer!]
		return:			[byte-ptr!]
		/local
			lc			[integer!]
			lx			[integer!]
			pos			[integer!]
			dc			[integer!]
			dx			[integer!]
	][
		lc: len
		lx: log-b len - 3
		lx: lx - 2
		lx: either lx < 0 [0][lx]
		case [
			lx = 0 [lc: lc + 254]
			len >= 258 [
				lx: 0
				lc: 285
			]
			true [
				pos: lx + 1
				lc: len - LXMIN/pos >> lx
				lc: lx - 1 << 2 + 265 + lc
			]
		]
		either lc <= 279 [
			pos: lc - 256 << 1 + 1
			dst: write dst end s as integer! MIRROR/pos 7
		][
			pos: C0h - 280 + lc + 1
			dst: write dst end s as integer! MIRROR/pos 8
		]

		if lx <> 0 [
			pos: lc - 265 + 1
			dst: write dst end s len - LMIN/pos lx
		]

		dc: dist - 1
		dx: log-b npow2 dist >> 2
		dx: either dx < 0 [0][dx]
		if dx <> 0 [
			pos: dx + 1
			dc: as integer! dist > DXMAX/pos
			dc: dx + 1 << 1 + dc
		]
		pos: dc << 3 + 1
		dst: write dst end s as integer! MIRROR/pos 5
		if dx <> 0 [
			pos: dc + 1
			dst: write dst end s dist - DMIN/pos dx
		]
		dst
	]

	lit: func [
		dst				[byte-ptr!]
		end				[byte-ptr!]
		s				[STATUS!]
		c				[integer!]
		return:			[byte-ptr!]
		/local
			pos			[integer!]
	][
		if c <= 143 [
			pos: 30h + c + 1
			return write dst end s as integer! MIRROR/pos 8
		]
		pos: 90h - 144 + c + 1
		write dst end s 2 * (as integer! MIRROR/pos) + 1 9
	]

	_deflate: func [
		out				[byte-ptr!]
		out-size		[integer!]
		in				[byte-ptr!]
		in-size			[integer!]
		plen			[int-ptr!]
		return:			[integer!]
		/local
			i			[integer!]
			st			[STATUS! value]
			dst			[byte-ptr!]
			dend		[byte-ptr!]
			iend		[byte-ptr!]
			dict		[int-ptr!]
			ptr			[byte-ptr!]
			h			[integer!]
			c			[integer!]
			ents		[int-ptr!]
			sub			[byte-ptr!]
			pos			[integer!]
			s			[byte-ptr!]
			len			[integer!]
			dist		[integer!]
	][
		dict: system/stack/allocate DICT_BUFF_SIZE
		set-memory as byte-ptr! dict null-byte DICT_BUFF_SIZE << 2
		st/bits: 0 st/cnt: 0
		dst: out
		dend: dst + out-size
		iend: in + in-size

		dst: write dst dend st 1 1
		dst: write dst dend st 1 2
		while [in < iend][
			ptr: in
			h: hash in
			ents: dict + (h and DICT_MASK * CACHE_SIZE)
			i: 0
			while [i < CACHE_SIZE][
				pos: i + 1
				sub: as byte-ptr! ents/pos
				if all [
					sub <> null
					in > sub
					in < (sub + MAX_OFF)
					0 = compare-memory in sub MIN_MATCH
				][
					s: sub + MIN_MATCH
					dist: as integer! in - sub
					len: MIN_MATCH
					in: in + len
					while [
						all [
							s/1 = in/1
							len < MAX_MATCH
						]
					][
						len: len + 1
						s: s + 1
						in: in + 1
					]
					dst: match dst dend st dist len
					break
				]
				i: i + 1
			]
			if i = CACHE_SIZE [
				dst: lit dst dend st as integer! in/1
				in: in + 1
			]
			c: hash2 in
			pos: c and CACHE_MASK + 1
			ents/pos: as integer! ptr
		]

		dst: write dst dend st 0 7
		dst: write dst dend st 2 10
		dst: write dst dend st 2 3
		plen/value: as integer! dst - out
		0
	]
]

