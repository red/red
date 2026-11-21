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
	#define MIN_MATCH		3
	#define MAX_MATCH		258
	#define WIN_SIZE		32768	;-- positions kept in the hash chains
	#define WIN_MASK		32767
	#define MAX_DIST		32767	;-- a match at 32768 would share its chain slot with the current position
	#define HASH_SIZE		32768	;-- hash of 3 bytes on 15 bits, fewer for short inputs (8 at least)
	#define TOO_FAR			4096	;-- a 3-byte match farther than that is coded as literals
	#define BLOCK_SYMS		16384	;-- symbols per block
	#define STORED_MAX		65535	;-- bytes per stored block
	#define LCODES			288		;-- literal/length codes (286 used)
	#define DCODES			32		;-- distance codes (30 used)
	#define TREES_SIZE		340		;-- LCODES + DCODES + 19 code-length codes, rounded

	DEFLATE!: alias struct! [
		bits		[integer!]				;-- bits not written yet, and their count
		cnt			[integer!]
		dst			[byte-ptr!]				;-- counts past `end` when the output does not fit
		end			[byte-ptr!]
		syms		[int-ptr!]				;-- block symbols: a byte, or distance << 8 + length - 3
		freq		[int-ptr!]				;-- symbol counts of the block: literals/lengths, distances, code lengths
		lens		[byte-ptr!]				;-- dynamic codes: lengths and bit-reversed codes, same layout
		codes		[int-ptr!]
		flens		[byte-ptr!]				;-- fixed codes
		fcodes		[int-ptr!]
		tmp			[int-ptr!]				;-- build-tree scratch
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

	MIRROR: protect #{
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

	ORDER: protect #{
		10 11 12 00 08 07 09 06
		0A 05 0B 04 0C 03 0D 02
		0E 01 0F 00
	}
	
	DBASE: protect [
		1 2 3 4 5 7 9 13 17 25 33 49 65 97 129 193
		257 385 513 769 1025 1537 2049 3073 4097 6145 8193 12289 16385 24577 0 0
	]

	DBITS: protect #{
		00 00 00 00 01 01 02 02
		03 03 04 04 05 05 06 06
		07 07 08 08 09 09 0A 0A
		0B 0B 0C 0C 0D 0D 00 00
	}

	LBASE: protect [
		3 4 5 6 7 8 9 10 11 13 15 17 19 23 27 31
		35 43 51 59 67 83 99 115 131 163 195 227 258 0 0
	]

	LBITS: protect #{
		00 00 00 00 00 00 00 00
		01 01 01 01 02 02 02 02
		03 03 03 03 04 04 04 04
		05 05 05 05 00 00 00 00
	}

	LEVELS: protect [						;-- zlib's match search of levels 1 to 9: good, lazy, nice, chain
		4	4	8	4
		4	5	16	8
		4	6	32	32
		4	4	16	16
		8	16	32	32
		8	16	128	128
		8	32	128	256
		32	128	258	1024
		32	258	258	4096
	]

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

	put-bits: func [
		s			[DEFLATE!]
		code		[integer!]
		bitcnt		[integer!]
		/local
			dst		[byte-ptr!]
	][
		s/bits: code << s/cnt or s/bits
		s/cnt: s/cnt + bitcnt
		while [s/cnt >= 8][
			dst: s/dst
			if dst < s/end [
				dst/1: as byte! s/bits
			]
			s/dst: dst + 1
			s/bits: s/bits >>> 8
			s/cnt: s/cnt - 8
		]
	]

	len-code: func [							;-- length code (0-28) of a match length - 3
		l			[integer!]
		return:		[integer!]
		/local
			e		[integer!]
	][
		if l < 8 [return l]
		if l = 255 [return 28]
		e: (log-b l) - 2
		(l >> e) + (e << 2)
	]

	dist-code: func [							;-- distance code (0-29) of a match distance - 1
		d			[integer!]
		return:		[integer!]
		/local
			e		[integer!]
	][
		if d < 4 [return d]
		e: (log-b d) - 1
		(d >> e) + (e << 1)
	]

	build-tree: func [							;-- Huffman code lengths of `freq`, none above `limit`
		freq		[int-ptr!]
		lens		[byte-ptr!]
		n			[integer!]
		limit		[integer!]
		w			[int-ptr!]					;-- scratch of 2 * n slots
		/local
			sy		[int-ptr!]
			num		[int-ptr!]
			m		[integer!]
			i		[integer!]
			j		[integer!]
			k		[integer!]
			x		[integer!]
			node	[integer!]
			leaf	[integer!]
			nxt		[integer!]
			avbl	[integer!]
			used	[integer!]
			depth	[integer!]
			total	[integer!]
	][
		set-memory lens null-byte n
		sy: w + n
		m: 0
		i: 1
		while [i <= n][							;-- the used symbols, sorted by count
			x: freq/i
			if x > 0 [
				j: m
				while [all [j >= 1 w/j > x]][
					k: j + 1
					w/k: w/j
					sy/k: sy/j
					j: j - 1
				]
				j: j + 1
				w/j: x
				sy/j: i
				m: m + 1
			]
			i: i + 1
		]
		if m < 2 [								;-- two codes at least, as zlib does
			lens/1: #"^(01)"
			lens/2: #"^(01)"
			if m = 1 [
				k: sy/1
				if k > 2 [
					lens/2: null-byte
					lens/k: #"^(01)"
				]
			]
			exit
		]
		w/1: w/1 + w/2							;-- in-place Huffman code lengths (Moffat & Katajainen)
		node: 1
		leaf: 3
		nxt: 2
		while [nxt < m][
			either any [leaf > m w/node < w/leaf][
				w/nxt: w/node
				w/node: nxt
				node: node + 1
			][
				w/nxt: w/leaf
				leaf: leaf + 1
			]
			either any [leaf > m all [node < nxt w/node < w/leaf]][
				w/nxt: w/nxt + w/node
				w/node: nxt
				node: node + 1
			][
				w/nxt: w/nxt + w/leaf
				leaf: leaf + 1
			]
			nxt: nxt + 1
		]
		k: m - 1
		w/k: 0
		nxt: m - 2
		while [nxt >= 1][
			k: w/nxt
			w/nxt: w/k + 1
			nxt: nxt - 1
		]
		avbl: 1
		used: 0
		depth: 0
		node: m - 1
		nxt: m
		while [avbl > 0][
			while [all [node >= 1 w/node = depth]][
				used: used + 1
				node: node - 1
			]
			while [avbl > used][
				w/nxt: depth
				nxt: nxt - 1
				avbl: avbl - 1
			]
			avbl: 2 * used
			depth: depth + 1
			used: 0
		]
		num: system/stack/allocate 16			;-- codes per length, longer ones moved to `limit`
		set-memory as byte-ptr! num null-byte 64
		i: 1
		while [i <= m][
			k: w/i
			if k > limit [k: limit]
			num/k: num/k + 1
			i: i + 1
		]
		total: 0
		i: 1
		while [i <= limit][
			total: num/i << (limit - i) + total
			i: i + 1
		]
		while [total > (1 << limit)][			;-- lengthens shorter codes until the code fits
			num/limit: num/limit - 1
			i: limit - 1
			while [num/i = 0][i: i - 1]
			num/i: num/i - 1
			k: i + 1
			num/k: num/k + 2
			total: total - 1
		]
		j: m									;-- the most frequent symbols get the shortest codes
		i: 1
		while [i <= limit][
			k: num/i
			while [k > 0][
				x: sy/j
				lens/x: as byte! i
				j: j - 1
				k: k - 1
			]
			i: i + 1
		]
	]

	gen-codes: func [							;-- canonical codes of code lengths, bit-reversed
		lens		[byte-ptr!]
		codes		[int-ptr!]
		n			[integer!]
		/local
			ncode	[int-ptr!]
			i		[integer!]
			k		[integer!]
			l		[integer!]
			c		[integer!]
	][
		ncode: system/stack/allocate 16
		set-memory as byte-ptr! ncode null-byte 64
		i: 1
		while [i <= n][
			l: as integer! lens/i
			if l > 0 [ncode/l: ncode/l + 1]
			i: i + 1
		]
		c: 0
		k: 0
		i: 1
		while [i <= 15][						;-- first code of each length
			c: c + k << 1
			k: ncode/i
			ncode/i: c
			i: i + 1
		]
		i: 1
		while [i <= n][
			l: as integer! lens/i
			c: 0
			if l > 0 [
				c: ncode/l
				ncode/l: c + 1
				c: (rev16 c) >>> (16 - l)
			]
			codes/i: c
			i: i + 1
		]
	]

	put-cl: func [								;-- code-length symbol: counts it, writes it if `emit?`
		s			[DEFLATE!]
		sym			[integer!]
		extra		[integer!]					;-- extra bits and their count
		bitcnt		[integer!]
		emit?		[logic!]
		/local
			lens	[byte-ptr!]
			codes	[int-ptr!]
			freq	[int-ptr!]
			k		[integer!]
	][
		freq: s/freq
		k: LCODES + DCODES + sym + 1
		freq/k: freq/k + 1
		if emit? [
			lens: s/lens
			codes: s/codes
			put-bits s codes/k as integer! lens/k
			if bitcnt > 0 [put-bits s extra bitcnt]
		]
	]

	send-tree: func [							;-- code lengths, run-length coded as zlib does
		s			[DEFLATE!]
		lens		[byte-ptr!]
		n			[integer!]
		emit?		[logic!]					;-- no: only counts the code-length symbols
		/local
			i		[integer!]
			k		[integer!]
			prev	[integer!]
			cur		[integer!]
			nlen	[integer!]
			cnt		[integer!]
			maxc	[integer!]
			minc	[integer!]
	][
		prev: -1
		nlen: as integer! lens/1
		cnt: 0
		maxc: 7
		minc: 4
		if nlen = 0 [
			maxc: 138
			minc: 3
		]
		i: 1
		while [i <= n][
			cur: nlen
			nlen: -1
			if i < n [
				k: i + 1
				nlen: as integer! lens/k
			]
			cnt: cnt + 1
			if any [cnt >= maxc cur <> nlen][
				case [
					cnt < minc [
						loop cnt [put-cl s cur 0 0 emit?]
					]
					cur <> 0 [
						if cur <> prev [
							put-cl s cur 0 0 emit?
							cnt: cnt - 1
						]
						put-cl s 16 cnt - 3 2 emit?
					]
					cnt <= 10 [put-cl s 17 cnt - 3 3 emit?]
					true [put-cl s 18 cnt - 11 7 emit?]
				]
				cnt: 0
				prev: cur
				case [
					nlen = 0 [
						maxc: 138
						minc: 3
					]
					cur = nlen [
						maxc: 6
						minc: 3
					]
					true [
						maxc: 7
						minc: 4
					]
				]
			]
			i: i + 1
		]
	]

	send-syms: func [							;-- block symbols and end of block
		s			[DEFLATE!]
		ns			[integer!]
		codes		[int-ptr!]
		lens		[byte-ptr!]
		/local
			syms	[int-ptr!]
			i		[integer!]
			k		[integer!]
			c		[integer!]
			l		[integer!]
			v		[integer!]
	][
		syms: s/syms
		i: 1
		while [i <= ns][
			v: syms/i
			either v < 256 [
				k: v + 1
				put-bits s codes/k as integer! lens/k
			][
				l: v and FFh
				c: len-code l
				k: c + 258
				put-bits s codes/k as integer! lens/k
				k: c + 1
				if LBITS/k <> null-byte [put-bits s l + 3 - LBASE/k as integer! LBITS/k]
				l: (v >>> 8) - 1
				c: dist-code l
				k: LCODES + c + 1
				put-bits s codes/k as integer! lens/k
				k: c + 1
				if DBITS/k <> null-byte [put-bits s l + 1 - DBASE/k as integer! DBITS/k]
			]
			i: i + 1
		]
		put-bits s codes/257 as integer! lens/257
	]

	flush-block: func [							;-- writes the block as stored, fixed or dynamic, the smallest
		s			[DEFLATE!]
		in			[byte-ptr!]
		start		[integer!]					;-- first position of the block
		stop		[integer!]					;-- position after it
		ns			[integer!]					;-- symbols in the block
		last?		[logic!]
		/local
			freq	[int-ptr!]
			lens	[byte-ptr!]
			flens	[byte-ptr!]
			src		[byte-ptr!]
			dst		[byte-ptr!]
			i		[integer!]
			k		[integer!]
			f		[integer!]
			n		[integer!]
			nlit	[integer!]
			ndist	[integer!]
			ncl		[integer!]
			dyn		[integer!]
			fix		[integer!]
			stored	[integer!]
	][
		freq: s/freq
		lens: s/lens
		flens: s/flens
		freq/257: 1								;-- end of block
		build-tree freq lens 286 15 s/tmp
		build-tree freq + LCODES lens + LCODES 30 15 s/tmp
		nlit: 286
		while [lens/nlit = null-byte][nlit: nlit - 1]
		ndist: 30
		k: LCODES + ndist
		while [lens/k = null-byte][
			ndist: ndist - 1
			k: k - 1
		]
		send-tree s lens nlit no
		send-tree s lens + LCODES ndist no
		build-tree freq + LCODES + DCODES lens + LCODES + DCODES 19 7 s/tmp
		ncl: 19
		k: LCODES + DCODES + 1 + as integer! ORDER/ncl
		while [all [ncl > 4 lens/k = null-byte]][
			ncl: ncl - 1
			k: LCODES + DCODES + 1 + as integer! ORDER/ncl
		]

		dyn: ncl * 3 + 17						;-- sizes in bits
		fix: 3
		i: 1
		while [i <= 286][
			f: freq/i
			if f > 0 [
				dyn: (as integer! lens/i) * f + dyn
				fix: (as integer! flens/i) * f + fix
				if i > 257 [
					k: i - 257
					k: (as integer! LBITS/k) * f
					dyn: dyn + k
					fix: fix + k
				]
			]
			i: i + 1
		]
		i: 1
		while [i <= 30][
			k: LCODES + i
			f: freq/k
			if f > 0 [
				dyn: (as integer! lens/k) * f + dyn
				k: (as integer! DBITS/i) + 5 * f
				fix: fix + k
				k: (as integer! DBITS/i) * f
				dyn: dyn + k
			]
			i: i + 1
		]
		i: 1
		while [i <= 19][
			k: LCODES + DCODES + i
			dyn: (as integer! lens/k) * freq/k + dyn
			i: i + 1
		]
		k: LCODES + DCODES + 17
		dyn: freq/k * 2 + dyn
		k: k + 1
		dyn: freq/k * 3 + dyn
		k: k + 1
		dyn: freq/k * 7 + dyn

		n: stop - start
		k: n + STORED_MAX - 1 / STORED_MAX		;-- stored blocks needed
		if k = 0 [k: 1]
		stored: s/cnt + 3 + 7 and -8 - s/cnt + 32 ;-- header and length of the first one
		stored: k - 1 * 40 + stored + (n * 8)

		f: as integer! last?
		either all [stored <= fix stored <= dyn][
			src: in + start - 1
			until [
				k: n
				if k > STORED_MAX [k: STORED_MAX]
				n: n - k
				i: 0
				if n = 0 [i: f]
				put-bits s i 3
				if s/cnt > 0 [put-bits s 0 8 - s/cnt]
				put-bits s k 16
				put-bits s k xor FFFFh 16
				dst: s/dst
				if dst + k <= s/end [copy-memory dst src k]
				s/dst: dst + k
				src: src + k
				n = 0
			]
		][
			either dyn < fix [
				put-bits s f or 4 3
				put-bits s nlit - 257 5
				put-bits s ndist - 1 5
				put-bits s ncl - 4 4
				gen-codes lens + LCODES + DCODES s/codes + LCODES + DCODES 19
				i: 1
				while [i <= ncl][
					k: LCODES + DCODES + 1 + as integer! ORDER/i
					put-bits s as integer! lens/k 3
					i: i + 1
				]
				gen-codes lens s/codes LCODES
				gen-codes lens + LCODES s/codes + LCODES DCODES
				send-tree s lens nlit yes
				send-tree s lens + LCODES ndist yes
				send-syms s ns s/codes lens
			][
				put-bits s f or 2 3
				send-syms s ns s/fcodes flens
			]
		]
		set-memory as byte-ptr! freq null-byte TREES_SIZE * 4
	]

	longest-match: func [						;-- longest match at `p` in the hash chain of `cand`
		in			[byte-ptr!]
		prev		[int-ptr!]
		p			[integer!]
		cand		[integer!]					;-- last earlier position with the same hash
		best		[integer!]					;-- length to beat
		max			[integer!]					;-- bytes left at `p`, MAX_MATCH at most
		dist		[int-ptr!]					;-- distance of the match found
		good		[integer!]					;-- a quarter of the candidates after a match that long
		nice		[integer!]					;-- a match that long ends the search
		chain		[integer!]					;-- candidates per search
		return:		[integer!]					;-- its length, or `best`
		/local
			scan	[byte-ptr!]
			stop	[byte-ptr!]
			s		[byte-ptr!]
			m		[byte-ptr!]
			e0		[byte!]
			e1		[byte!]
			limit	[integer!]
			len		[integer!]
			b1		[integer!]
			k		[integer!]
	][
		if best >= max [return best]
		if best >= good [chain: chain >> 2]
		if nice > max [nice: max]
		limit: p - MAX_DIST - 1
		if limit < 0 [limit: 0]
		scan: in + p - 1
		stop: scan + max
		b1: best + 1
		e1: scan/best
		e0: scan/b1
		until [
			m: in + cand - 1
			if all [m/b1 = e0 m/best = e1 m/1 = scan/1 m/2 = scan/2][
				s: scan + 3						;-- the third byte matches too: same hash
				m: m + 3
				while [all [s < stop s/1 = m/1]][
					s: s + 1
					m: m + 1
				]
				len: as integer! s - scan
				if len > best [
					dist/value: p - cand
					best: len
					if len >= nice [break]
					b1: best + 1
					e1: scan/best
					e0: scan/b1
				]
			]
			k: cand and WIN_MASK + 1
			cand: prev/k
			chain: chain - 1
			any [cand <= limit chain = 0]
		]
		best
	]

	compress: func [
		out			[byte-ptr!]
		out-size	[int-ptr!]
		in			[byte-ptr!]
		in-size		[integer!]
		level		[integer!]						;-- 1 to 9, -1: 6
		return:		[integer!]
		/local
			st		[DEFLATE! value]
			good	[integer!]						;-- match search of the level
			lazy	[integer!]
			nice	[integer!]
			chain	[integer!]
			work	[int-ptr!]
			head	[int-ptr!]
			prev	[int-ptr!]
			syms	[int-ptr!]
			freq	[int-ptr!]
			flens	[byte-ptr!]
			p		[integer!]						;-- position, 1-based
			last	[integer!]						;-- last position followed by 2 bytes
			h		[integer!]						;-- hash of the 3 bytes at `p`
			hmask	[integer!]
			cand	[integer!]						;-- last earlier position with the same hash
			len		[integer!]						;-- match at `p`
			dist	[integer!]
			plen	[integer!]						;-- match at `p - 1`
			pdist	[integer!]
			skip	[integer!]						;-- positions left inside the match coded last
			lit?	[logic!]						;-- the byte at `p - 1` is not coded yet
			ns		[integer!]						;-- symbols in the block
			start	[integer!]						;-- first position of the block
			pos		[integer!]						;-- first position not coded yet
			i		[integer!]
			k		[integer!]
	][
		;-- hash chains heads and links, block symbols, trees (integers), then code lengths (bytes)
		k: HASH_SIZE + WIN_SIZE + BLOCK_SYMS + (3 * TREES_SIZE) + (2 * LCODES) << 2 + (2 * TREES_SIZE)
		#either red-pass? = yes [
			work: allocate-virtual k no				;-- zeroed: empty hash chains, no symbol counted
		][
			work: as int-ptr! allocate k			;-- Red/System program: no allocate-virtual
			set-memory as byte-ptr! work null-byte k
		]
		head: work
		prev: head + HASH_SIZE
		syms: prev + WIN_SIZE
		freq: syms + BLOCK_SYMS
		st/syms: syms
		st/freq: freq
		st/codes: freq + TREES_SIZE
		st/fcodes: st/codes + TREES_SIZE
		st/tmp: st/fcodes + TREES_SIZE
		st/lens: as byte-ptr! st/tmp + (2 * LCODES)
		st/flens: st/lens + TREES_SIZE
		st/bits: 0
		st/cnt: 0
		st/dst: out
		st/end: out + out-size/1

		flens: st/flens								;-- fixed codes
		i: 1
		while [i <= (LCODES + DCODES)][
			k: 8
			if i > 144 [k: 9]
			if i > 256 [k: 7]
			if i > 280 [k: 8]
			if i > LCODES [k: 5]
			flens/i: as byte! k
			i: i + 1
		]
		gen-codes flens st/fcodes LCODES
		gen-codes flens + LCODES st/fcodes + LCODES DCODES

		if level < 1 [level: 6]
		k: level * 4 - 3
		good: LEVELS/k
		k: k + 1
		lazy: LEVELS/k
		k: k + 1
		nice: LEVELS/k
		k: k + 1
		chain: LEVELS/k

		k: 8										;-- hash table sized to the input: fewer pages touched
		while [all [k < 15 (1 << k) < in-size]][k: k + 1]
		hmask: (1 << k) - 1
		last: in-size - 2
		h: 0
		if last >= 1 [h: (as integer! in/1) << 5 xor as integer! in/2]
		dist: 0
		plen: MIN_MATCH - 1
		pdist: 0
		skip: 0
		lit?: no
		ns: 0
		start: 1
		pos: 1
		p: 1
		while [p <= in-size][
			cand: 0
			if p <= last [								;-- puts `p` at the head of its hash chain
				k: p + 2
				h: h << 5 xor (as integer! in/k) and hmask
				k: h + 1
				cand: head/k
				head/k: p
				k: p and WIN_MASK + 1
				prev/k: cand
			]
			either skip > 0 [skip: skip - 1][
				len: MIN_MATCH - 1
				if all [cand > 0 p - cand <= MAX_DIST plen < lazy][
					k: in-size - p + 1
					if k > MAX_MATCH [k: MAX_MATCH]
					len: longest-match in prev p cand plen k :dist good nice chain
					if all [len = MIN_MATCH dist > TOO_FAR][len: MIN_MATCH - 1]
				]
				either all [plen >= MIN_MATCH len <= plen][	;-- codes the match at `p - 1`
					ns: ns + 1
					syms/ns: pdist << 8 or (plen - MIN_MATCH)
					k: len-code plen - MIN_MATCH
					k: k + 258
					freq/k: freq/k + 1
					k: dist-code pdist - 1
					k: k + LCODES + 1
					freq/k: freq/k + 1
					pos: p - 1 + plen
					skip: plen - 2
					plen: MIN_MATCH - 1
					lit?: no
				][
					if lit? [								;-- codes the byte at `p - 1`
						k: p - 1
						i: as integer! in/k
						ns: ns + 1
						syms/ns: i
						k: i + 1
						freq/k: freq/k + 1
						pos: p
					]
					lit?: yes
					plen: len
					pdist: dist
				]
				if ns = BLOCK_SYMS [
					flush-block st in start pos ns no
					ns: 0
					start: pos
				]
			]
			p: p + 1
		]
		if lit? [
			i: as integer! in/in-size
			ns: ns + 1
			syms/ns: i
			k: i + 1
			freq/k: freq/k + 1
			pos: in-size + 1
		]
		flush-block st in start pos ns yes
		if st/cnt > 0 [								;-- pads the last byte
			put-bits st 0 8 - st/cnt
		]
		#either red-pass? = yes [free-virtual work][free as byte-ptr! work]
		out-size/value: as integer! st/dst - out
		if st/dst > st/end [
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

					if len > 0 [
						in: in - (s/bitcnt >> 3)		;-- give back the data bytes already in the bit buffer
						if in + len > as integer! iend [
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

						s/bitcnt: 0
						s/bits: 0
						read :in iend :s 0
					]
					if last > 0 [
						out-size/value: as integer! out - o
						if oend < out [return INFLATE-NO-MEM]
						return INFLATE-OK
					]
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
			if oend < out [return INFLATE-NO-MEM]
			return INFLATE-OK
		]
		INFLATE_END
	]
]

