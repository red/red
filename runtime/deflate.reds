Red/System [
	Title:	"deflate lib"
	Author: "bitbegin"
	File: 	%deflate-rs.reds
	Tabs:	4
	Rights:  "Copyright (C) 2011-2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

;-- this file can be included in RS environment, not only for Red's runtime

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

	DEFLATE!: alias struct! [
		bits		[integer!]
		cnt			[integer!]
	]

	INFLATE!: alias struct! [
		bits		[integer!]
		bitcnt		[integer!]
		lits		[int-ptr!]
		dsts		[int-ptr!]
		lens		[int-ptr!]
		tlit		[integer!]
		tdist		[integer!]
		tlen		[integer!]
	]

	#enum STATES! [
		STATE-HDR
		STATE-STORED
		STATE-FIXED
		STATE-DYN
		STATE-BLK
	]

	#enum DEFLATE-ERROR! [
		DEFLATE-OK: 0
		DEFLATE-NO-MEM: 1	;-- output buffer is too small, return the right size in `out-size`.
	]

	#enum INFLATE-ERROR! [
		INFLATE-OK: 0
		INFLATE-NO-MEM: 1	;-- output buffer is too small, return the right size in `out-size`.
		INFLATE_END			;-- error: wrong data format
		INFLATE_LEN			;-- error: wrong internal length
		INFLATE_HDR			;-- error: wrong header
		INFLATE_BLK			;-- error: wrong block
	]

	MIRROR: #{
		00 80 40 C0 20 A0 60 E0 10 90 50 D0 30 B0 70 F0
		08 88 48 C8 28 A8 68 E8 18 98 58 D8 38 B8 78 F8
		04 84 44 C4 24 A4 64 E4 14 94 54 D4 34 B4 74 F4
		0C 8C 4C CC 2C AC 6C EC 1C 9C 5C DC 3C BC 7C FC
		02 82 42 C2 22 A2 62 E2 12 92 52 D2 32 B2 72 F2
		0A 8A 4A CA 2A AA 6A EA 1A 9A 5A DA 3A BA 7A FA
		06 86 46 C6 26 A6 66 E6 16 96 56 D6 36 B6 76 F6
		0E 8E 4E CE 2E AE 6E EE 1E 9E 5E DE 3E BE 7E FE
		01 81 41 C1 21 A1 61 E1 11 91 51 D1 31 B1 71 F1
		09 89 49 C9 29 A9 69 E9 19 99 59 D9 39 B9 79 F9
		05 85 45 C5 25 A5 65 E5 15 95 55 D5 35 B5 75 F5
		0D 8D 4D CD 2D AD 6D ED 1D 9D 5D DD 3D BD 7D FD
		03 83 43 C3 23 A3 63 E3 13 93 53 D3 33 B3 73 F3
		0B 8B 4B CB 2B AB 6B EB 1B 9B 5B DB 3B BB 7B FB
		07 87 47 C7 27 A7 67 E7 17 97 57 D7 37 B7 77 F7
		0F 8F 4F CF 2F AF 6F EF 1F 9F 5F DF 3F BF 7F FF
	}

	LXMIN: [0 11 19 35 67 131]
	DXMAX: [0 6 12 24 48 96 192 384 768 1536 3072 6144 12288 24576]
	LMIN:  [11 13 15 17 19 23 27 31 35 43 51 59 67 83 99 115 131 163 195 227]
	DMIN:  [1 2 3 4 5 7 9 13 17 25 33 49 65 97 129 193 257 385 513 769 1025 1537 2049 3073 4097 6145 8193 12289 16385 24577]

	ORDER: #{
		10 11 12 00 08 07 09 06
		0A 05 0B 04 0C 03 0D 02
		0E 01 0F
	}
	
	DBASE: [
		1 2 3 4 5 7 9 13 17 25 33 49 65 97 129 193
		257 385 513 769 1025 1537 2049 3073 4097 6145 8193 12289 16385 24577 0 0
	]

	DBITS: #{
		00 00 00 00 01 01 02 02
		03 03 04 04 05 05 06 06
		07 07 08 08 09 09 0A 0A
		0B 0B 0C 0C 0D 0D 00 00
	}

	LBASE: [
		3 4 5 6 7 8 9 10 11 13 15 17 19 23 27 31
		35 43 51 59 67 83 99 115 131 163 195 227 258 0 0
	]

	LBITS: #{
		00 00 00 00 00 00 00 00
		01 01 01 01 02 02 02 02
		03 03 03 03 04 04 04 04
		05 05 05 05 00 00 00
	}

	rev16: func [
		n			[integer!]
		return:		[integer!]
		/local
			t		[integer!]
			r		[integer!]
	][
		t: n and FFh + 1
		r: (as integer! MIRROR/t) << 8
		t: n >>> 8 and FFh + 1
		r: r or as integer! MIRROR/t
		r
	]

	npow2: func [
		n			[integer!]
		return:		[integer!]
		/local
			t		[integer!]
	][
		t: 1 << log-b n
		if n <> t [
			t: t << 1
		]
		t
	]


	hash: func [
		s			[byte-ptr!]
		return:		[integer!]
		/local
			a		[integer!]
			b		[integer!]
			c		[integer!]
			x		[integer!]
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
		s			[byte-ptr!]
		return:		[integer!]
		/local
			a		[integer!]
			b		[integer!]
			c		[integer!]
			x		[integer!]
	][
		a: as integer! s/1
		b: as integer! s/2
		c: as integer! s/3
		x: a << 16 or (b << 8) or c
		x: x >>> DICT_BITS_R - x and CACHE_MASK
		x
	]

	write: func [
		dst			[byte-ptr!]
		end			[byte-ptr!]
		s			[DEFLATE!]
		code		[integer!]
		bitcnt		[integer!]
		return:		[byte-ptr!]
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
		dst			[byte-ptr!]
		end			[byte-ptr!]
		s			[DEFLATE!]
		dist		[integer!]
		len			[integer!]
		return:		[byte-ptr!]
		/local
			lc		[integer!]
			lx		[integer!]
			pos		[integer!]
			dc		[integer!]
			dx		[integer!]
	][
		lc: len
		lx: log-b len - 3
		lx: lx - 2
		if lx < 0 [lx: 0]
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
		dx: log-b (npow2 dist) >> 2
		if dx < 0 [dx: 0]
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
		dst			[byte-ptr!]
		end			[byte-ptr!]
		s			[DEFLATE!]
		c			[integer!]
		return:		[byte-ptr!]
		/local
			pos		[integer!]
	][
		if c <= 143 [
			pos: 30h + c + 1
			return write dst end s as integer! MIRROR/pos 8
		]
		pos: 90h - 144 + c + 1
		write dst end s 2 * (as integer! MIRROR/pos) + 1 9
	]

	compress: func [
		out			[byte-ptr!]
		out-size	[int-ptr!]
		in			[byte-ptr!]
		in-size		[integer!]
		return:		[integer!]
		/local
			i		[integer!]
			st		[DEFLATE! value]
			dst		[byte-ptr!]
			dend	[byte-ptr!]
			istart	[byte-ptr!]
			iend	[byte-ptr!]
			dict	[int-ptr!]
			ptr		[byte-ptr!]
			h		[integer!]
			c		[integer!]
			ents	[int-ptr!]
			sub		[byte-ptr!]
			pos		[integer!]
			s		[byte-ptr!]
			len		[integer!]
			dist	[integer!]
	][
		dict: system/stack/allocate DICT_BUFF_SIZE
		set-memory as byte-ptr! dict null-byte DICT_BUFF_SIZE << 2
		st/bits: 0 st/cnt: 0
		dst: out
		dend: dst + out-size/1
		istart: in
		iend: in + in-size

		dst: write dst dend st 1 1
		dst: write dst dend st 1 2
		while [in < iend][
			ptr: in
			h: hash in
			ents: dict + (h and DICT_MASK * CACHE_SIZE)
			either all [
				MIN_MATCH <= as integer! in - istart
				MIN_MATCH <= as integer! iend - in
			][
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
								in < iend
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
			][
				dst: lit dst dend st as integer! in/1
				in: in + 1
			]

			c: hash2 in
			pos: c and CACHE_MASK + 1
			ents/pos: as integer! ptr
		]

		;-- block end
		dst: write dst dend st 0 7
		;dst: write dst dend st 2 10
		;dst: write dst dend st 2 3
		if st/bits < 8 [
			dst: write dst dend st 0 8 - st/bits
		]
		out-size/value: as integer! dst - out
		if dst > dend [
			return DEFLATE-NO-MEM
		]
		DEFLATE-OK
	]

	read: func [
		src			[int-ptr!]
		end			[byte-ptr!]
		s			[INFLATE!]
		n			[integer!]
		return:		[integer!]
		/local
			in		[byte-ptr!]
			v		[integer!]
			t		[integer!]
	][
		in: as byte-ptr! src/1
		v: (1 << n) - 1 and s/bits
		s/bits: s/bits >> n
		s/bitcnt: s/bitcnt - n
		if s/bitcnt < 0 [s/bitcnt: 0]
		while [
			all [
				s/bitcnt < 16
				in < end
			]
		][
			t: as integer! in/1
			in: in + 1
			s/bits: t << s/bitcnt or s/bits
			s/bitcnt: s/bitcnt + 8
		]
		src/1: as integer! in
		v
	]

	build: func [
		tree		[int-ptr!]
		lens		[byte-ptr!]
		symcnt		[integer!]
		return:		[integer!]
		/local
			p		[int-ptr!]
			n		[integer!]
			cnt		[int-ptr!]
			first	[int-ptr!]
			codes	[int-ptr!]
			pos		[integer!]
			slot	[integer!]
			code	[integer!]
			len		[integer!]
			t		[integer!]
	][
		p: tree
		loop symcnt [
			p/1: 0
			p: p + 1
		]
		cnt: system/stack/allocate 16
		first: system/stack/allocate 16
		codes: system/stack/allocate 16
		set-memory as byte-ptr! cnt null-byte 16 * size? integer!
		cnt/1: 0 first/1: 0 codes/1: 0
		n: 0
		while [n < symcnt][
			pos: n + 1
			pos: as integer! lens/pos
			pos: pos + 1
			cnt/pos: cnt/pos + 1
			n: n + 1
		]
		n: 1
		while [n <= 15][
			pos: n + 1
			codes/pos: (codes/n + cnt/n) << 1
			first/pos: first/n + cnt/n
			n: n + 1
		]
		n: 0
		while [n < symcnt][
			pos: n + 1
			len: as integer! lens/pos
			if len = 0 [
				n: n + 1
				continue
			]
			pos: len + 1
			code: codes/pos
			codes/pos: codes/pos + 1
			slot: first/pos
			first/pos: first/pos + 1
			t: code << (32 - len)
			pos: slot + 1
			tree/pos: t or (n << 4) or len
			n: n + 1
		]
		first/16
	]

	decode: func [
		src			[int-ptr!]
		end			[byte-ptr!]
		s			[INFLATE!]
		tree		[int-ptr!]
		max			[integer!]
		return:		[integer!]
		/local
			key		[integer!]
			lo		[integer!]
			hi		[integer!]
			search	[integer!]
			guess	[integer!]
			pos		[integer!]
	][
		lo: 0
		hi: max
		search: (rev16 s/bits) << 16 or FFFFh
		while [lo < hi][
			guess: lo + hi / 2
			pos: guess + 1
			either (as byte-ptr! search) < (as byte-ptr! tree/pos) [hi: guess][
				lo: guess + 1
			]
		]
		key: tree/lo
		read src end s key and 0Fh
		key >>> 4 and 0FFFh
	]

	uncompress: func [
		out			[byte-ptr!]
		out-size	[int-ptr!]
		*in			[byte-ptr!]
		in-size		[integer!]
		return:		[integer!]
		/local
			*lits	[int-ptr!]
			*dsts	[int-ptr!]
			*lens	[int-ptr!]
			lens	[byte-ptr!]
			iend	[byte-ptr!]
			oend	[byte-ptr!]
			o		[byte-ptr!]
			in		[integer!]
			state	[STATES!]
			s		[INFLATE! value]
			last	[integer!]
			type	[integer!]
			len		[integer!]
			nlen	[integer!]
			num		[integer!]
			n		[integer!]
			i		[integer!]
			nlit	[integer!]
			ndist	[integer!]
			nlens	[byte-ptr!]
			sym		[integer!]
			dsym	[integer!]
			offs	[integer!]
			p		[byte-ptr!]
			pos		[integer!]
	][
		*lits: system/stack/allocate 288
		*dsts: system/stack/allocate 32
		*lens: system/stack/allocate 19
		set-memory as byte-ptr! s null-byte size? INFLATE!
		s/lits: *lits
		s/dsts: *dsts
		s/lens: *lens

		lens: as byte-ptr! system/stack/allocate 80		;(288 + 32) / 4
		nlens: as byte-ptr! system/stack/allocate 5

		o: out in: as integer! *in
		iend: *in + in-size
		oend: out + out-size/1
		state: STATE-HDR
		last: 0
		read :in iend s 0

		while [
			any [
				(as byte-ptr! in) < iend
				s/bitcnt <> 0
			]
		][
			switch state [
				STATE-HDR [
					type: 0
					last: read :in iend s 1
					type: read :in iend s 2
					switch type [
						0 [
							state: STATE-STORED
						]
						1 [
							state: STATE-FIXED
						]
						2 [
							state: STATE-DYN
						]
						default [
							out-size/value: as integer! out - o
							return INFLATE_HDR
						]
					]
				]
				STATE-STORED [
					read :in iend s s/bitcnt and 7
					len: read :in iend s 16
					nlen: read :in iend s 16
					in: in - 2
					s/bitcnt: 0
					if any [
						in + len > as integer! iend
						len = 0
					][
						out-size/value: as integer! out - o
						return INFLATE_LEN
					]
					p: as byte-ptr! in
					loop len [
						if oend > out [
							out/1: p/1
						]
						out: out + 1
						p: p + 1
					]
					in: in + len
					state: STATE-HDR
				]
				STATE-FIXED [
					n: 1
					while [n <= 144][
						lens/n: as byte! 8
						n: n + 1
					]
					while [n <= 256][
						lens/n: as byte! 9
						n: n + 1
					]
					while [n <= 280][
						lens/n: as byte! 7
						n: n + 1
					]
					while [n <= 288][
						lens/n: as byte! 8
						n: n + 1
					]
					while [n <= (288 + 32)][
						lens/n: as byte! 5
						n: n + 1
					]
					s/tlit: build s/lits lens 288
					s/tdist: build s/dsts lens + 288 32
					state: STATE-BLK
				]
				STATE-DYN [
					set-memory nlens null-byte 19
					nlit: 257 + read :in iend s 5
					ndist: 1 + read :in iend s 5
					nlen: 4 + read :in iend s 4
					n: 1
					while [n <= nlen][
						pos: 1 + as integer! ORDER/n
						nlens/pos: as byte! read :in iend s 3
						n: n + 1
					]
					s/tlen: build s/lens nlens 19

					n: 0
					while [n < (nlit + ndist)][
						sym: decode :in iend s s/lens s/tlen
						switch sym [
							16 [
								len: read :in iend s 2
								i: 3 + len
								while [i > 0] [
									pos: n + 1
									lens/pos: lens/n
									i: i - 1
									n: n + 1
								]
							]
							17 [
								len: read :in iend s 3
								i: 3 + len
								while [i > 0] [
									pos: n + 1
									lens/pos: null-byte
									i: i - 1
									n: n + 1
								]
							]
							18 [
								len: read :in iend s 7
								i: 11 + len
								while [i > 0] [
									pos: n + 1
									lens/pos: null-byte
									i: i - 1
									n: n + 1
								]
							]
							default [
								n: n + 1
								lens/n: as byte! sym
							]
						]
					]
					s/tlit: build s/lits lens nlit
					s/tdist: build s/dsts lens + nlit ndist
					state: STATE-BLK
				]
				STATE-BLK [
					sym: decode :in iend s s/lits s/tlit
					case [
						sym > 256 [
							sym: sym - 257
							pos: sym + 1
							len: read :in iend s as integer! LBITS/pos
							len: len + LBASE/pos
							dsym: decode :in iend s s/dsts s/tdist
							pos: dsym + 1
							offs: read :in iend s as integer! DBITS/pos
							offs: offs + DBASE/pos
							n: as integer! out - o
							if offs > n [
								out-size/value: n
								return INFLATE_BLK
							]
							loop len [
								p: out - offs
								if oend > out [
									out/1: p/1
								]
								out: out + 1
							]
						]
						sym = 256 [
							if last > 0 [
								out-size/value: as integer! out - o
								if oend < out [
									return INFLATE-NO-MEM
								]
								return INFLATE-OK
							]
							state: STATE-HDR
						]
						true [
							if oend > out [
								out/1: as byte! sym
							]
							out: out + 1
						]
					]
				]
			]
		]
		out-size/value: as integer! out - o
		if (as byte-ptr! in) = iend [
			return INFLATE-OK
		]
		INFLATE_END
	]
]

