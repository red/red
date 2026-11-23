Red/System [
	Title:   "Zstandard compression"
	Author:  "Nenad Rakocevic"
	File: 	 %zstd.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Note: {
		Zstandard frames (RFC 8878), written from the specification.
		Decoding: every frame and block type, skippable frames, content checksums; no dictionaries.
		Encoding: one frame with its content size, no checksum; levels 1 to 19 (default 3), zstd's settings and match finders, optimal parsing and block splitting at the highest.
	}
]

;-- this file can be included in RS environment, not only for Red's runtime (needs %deflate.reds)

zstd: context [
	#define ZSTD_MAGIC			FD2FB528h
	#define ZSTD_BLOCK_MAX		131072				;-- largest block content
	#define ZSTD_BIG			7FFFFFFFh			;-- output limit when only counting
	#define ZSTD_CHECK_SIZE		1000000h			;-- outputs of 16 MB or more: their frames decoded without writing before the allocation

	#enum ZSTD-ERROR! [
		ZSTD-OK: 0
		ZSTD-NO-MEM: 1								;-- output buffer is too small, the right size in `out-size`
		ZSTD-BAD									;-- error: invalid or unsupported data
	]

	ZSTD-DEC!: alias struct! [
		op			[byte-ptr!]						;-- output position (a count when not writing)
		rep1		[integer!]						;-- repeat offsets
		rep2		[integer!]
		rep3		[integer!]
		window		[integer!]						;-- farthest a match can reach back
		unchecked?	[logic!]						;-- sizing: a content size taken from its frame, the blocks not decoded
		ll			[int-ptr!]						;-- sequence tables: baseline << 16, bit count << 8, code
		of			[int-ptr!]
		ml			[int-ptr!]
		ll-log		[integer!]						;-- their accuracy logs, -1: no table yet
		of-log		[integer!]
		ml-log		[integer!]
		huf			[byte-ptr!]						;-- literals table: symbol of each code prefix
		hufl		[byte-ptr!]						;-- code length of each code prefix
		huf-log		[integer!]						;-- longest code, -1: no table yet
		weights		[byte-ptr!]						;-- Huffman weights
		wtab		[int-ptr!]						;-- FSE table of the weights
		norm		[int-ptr!]						;-- normalized counts of a table description
		nxt			[int-ptr!]						;-- scratch of build-fse
	]

	LL-BASE: protect [
		0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
		16 18 20 22 24 28 32 40 48 64 128 256 512 1024 2048 4096
		8192 16384 32768 65536
	]

	LL-BITS: protect #{
		00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
		01 01 01 01 02 02 03 03 04 06 07 08 09 0A 0B 0C
		0D 0E 0F 10
	}

	ML-BASE: protect [
		3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18
		19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34
		35 37 39 41 43 47 51 59 67 83 99 131 259 515 1027 2051
		4099 8195 16387 32771 65539
	]

	ML-BITS: protect #{
		00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
		00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
		01 01 01 01 02 02 03 03 04 04 05 07 08 09 0A 0B
		0C 0D 0E 0F 10
	}

	LL-NORM: protect [								;-- predefined distributions
		4 3 2 2 2 2 2 2 2 2 2 2 2 1 1 1 2 2 2 2 2 2 2 2 2 3 2 1 1 1 1 1
		-1 -1 -1 -1
	]

	ML-NORM: protect [
		1 4 3 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
		1 1 1 1 1 1 1 1 1 1 1 1 1 1 -1 -1 -1 -1 -1 -1 -1
	]

	OF-NORM: protect [
		1 1 1 1 1 1 2 2 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 -1 -1 -1 -1 -1
	]

	;-- backward bit streams (read from their last byte): locals acc, cnt, p, start, pad
	;-- acc holds `cnt` unread bits, right-aligned; bytes past the start read as zeros, counted in `pad`

	#either target = 'IA-32 [						;-- unaligned 32-bit reads and writes
		#define ZSTD_FILL [							;-- whole bytes while they fit, from one word when 4 are left (fn fw fp)
			if cnt <= 24 [
				either (as-integer p - start) >= 4 [
					fn: 32 - cnt >> 3
					if fn > 3 [fn: 3]
					fp: as int-ptr! (p - 4)
					fw: fp/value
					p: p - fn
					fn: fn << 3
					acc: acc << fn or (fw >>> (32 - fn))
					cnt: cnt + fn
				][
					while [cnt <= 24][
						acc: acc << 8
						either p > start [
							p: p - 1
							acc: acc or as integer! p/1
						][
							pad: pad + 8
						]
						cnt: cnt + 8
					]
				]
			]
		]
		#define ZSTD_COPY8(_d _s _e) [					;-- forward copy up to `_e`, 8 bytes at a time: up to 7 bytes past it (s4 d4)
			while [_d < _e][
				s4: as int-ptr! _s
				d4: as int-ptr! _d
				d4/value: s4/value
				s4: s4 + 1
				d4: d4 + 1
				d4/value: s4/value
				_d: _d + 8
				_s: _s + 8
			]
		]
	][
		#define ZSTD_FILL [
			while [cnt <= 24][
				acc: acc << 8
				either p > start [
					p: p - 1
					acc: acc or as integer! p/1
				][
					pad: pad + 8
				]
				cnt: cnt + 8
			]
		]
		#define ZSTD_COPY8(_d _s _e) [
			while [_d < _e][
				_d/1: _s/1
				_d/2: _s/2
				_d/3: _s/3
				_d/4: _s/4
				_d/5: _s/5
				_d/6: _s/6
				_d/7: _s/7
				_d/8: _s/8
				_d: _d + 8
				_s: _s + 8
			]
		]
	]

	#define ZSTD_BITS(_v _n) [						;-- 24 bits at most after a fill
		cnt: cnt - _n
		_v: acc >>> cnt and ((1 << _n) - 1)
	]

	#define ZSTD_OPEN(_s _n) [						;-- stream of `_n` bytes at `_s`, `_n` > 0
		start: _s
		p: _s + _n - 1
		acc: as integer! p/1
		cnt: log-b acc							;-- bits under the end marker
		pad: 0
	]

	#define ZSTD_END? [all [p = start cnt = pad]]	;-- every bit read, none past the start

	#either target = 'IA-32 [
		#define ZSTD_GET32(_v _p) [
			i4: as int-ptr! _p
			_v: i4/value
		]
	][
		#define ZSTD_GET32(_v _p) [
			_v: (as integer! _p/4) << 24 or ((as integer! _p/3) << 16) or ((as integer! _p/2) << 8) or as integer! _p/1
		]
	]

	le16: func [p [byte-ptr!] return: [integer!]][
		(as integer! p/2) << 8 or as integer! p/1
	]

	le24: func [p [byte-ptr!] return: [integer!]][
		(as integer! p/3) << 16 or ((as integer! p/2) << 8) or as integer! p/1
	]

	le32: func [p [byte-ptr!] return: [integer!]][
		(as integer! p/4) << 24 or ((as integer! p/3) << 16) or ((as integer! p/2) << 8) or as integer! p/1
	]

	;-- XXH64 on 32-bit integers: a 64-bit value is a pair of words, high and low

	#define ZSTD_MUL64(_h _l _bh _bl) [				;-- _h:_l * _bh:_bl, low 64 bits
		a0: _l and FFFFh
		a1: _l >>> 16
		b0: _bl and FFFFh
		b1: _bl >>> 16
		t0: a0 * b0
		t1: a0 * b1
		t2: a1 * b0
		t3: t0 >>> 16 + (t1 and FFFFh) + (t2 and FFFFh)
		_h: a1 * b1 + (t1 >>> 16) + (t2 >>> 16) + (t3 >>> 16) + (_h * _bl) + (_l * _bh)
		_l: t3 << 16 or (t0 and FFFFh)
	]

	#define ZSTD_ADD64(_h _l _bh _bl) [
		t0: (_l >>> 1) + (_bl >>> 1) + (_l and _bl and 1) >>> 31
		_h: _h + _bh + t0
		_l: _l + _bl
	]

	#define ZSTD_ROTL64(_h _l _r) [					;-- 0 < _r < 32
		t0: _h << _r or (_l >>> (32 - _r))
		_l: _l << _r or (_h >>> (32 - _r))
		_h: t0
	]

	#define ZSTD_ROUND64(_h _l _ih _il) [			;-- acc: rotl(acc + input * P2, 31) * P1
		ZSTD_MUL64(_ih _il C2B2AE3Dh 27D4EB4Fh)
		ZSTD_ADD64(_h _l _ih _il)
		ZSTD_ROTL64(_h _l 31)
		ZSTD_MUL64(_h _l 9E3779B1h 85EBCA87h)
	]

	XXH-ROT: protect [1 7 12 18]

	mul64: func [								;-- x * bh:bl, in place (x/1: high word, x/2: low)
		x		[int-ptr!]
		bh		[integer!]
		bl		[integer!]
		/local
			h l a0 a1 b0 b1 t0 t1 t2 t3 [integer!]
	][
		h: x/1
		l: x/2
		ZSTD_MUL64(h l bh bl)
		x/1: h
		x/2: l
	]

	xxh-round: func [							;-- x: round(0, ih:il), as the accumulators
		x		[int-ptr!]
		ih		[integer!]
		il		[integer!]
		/local
			h l a0 a1 b0 b1 t0 t1 t2 t3 [integer!]
	][
		h: 0
		l: 0
		ZSTD_ROUND64(h l ih il)
		x/1: h
		x/2: l
	]

	xxh-mix: func [								;-- h: rotl(h xor x * a, r) * b + c
		h		[int-ptr!]
		x		[int-ptr!]
		ah al r bh bl ch cl [integer!]
		/local
			t0		[integer!]
	][
		mul64 x ah al
		h/1: h/1 xor x/1
		h/2: h/2 xor x/2
		if r > 0 [ZSTD_ROTL64(h/1 h/2 r)]
		mul64 h bh bl
		ZSTD_ADD64(h/1 h/2 ch cl)
	]

	xxh64: func [								;-- low word of the XXH64 hash of `data`, seed 0
		data	[byte-ptr!]
		len		[integer!]
		return:	[integer!]
		/local
			p e		[byte-ptr!]
			i4 v h x [int-ptr!]
			hh hl ih il k r a0 a1 b0 b1 t0 t1 t2 t3 [integer!]
	][
		p: data
		e: data + len
		v: system/stack/allocate 8					;-- 4 accumulators
		h: system/stack/allocate 2
		x: system/stack/allocate 2
		either len >= 32 [
			v/1: 60EA27EEh							;-- P1 + P2
			v/2: ADC0B5D6h
			v/3: C2B2AE3Dh							;-- P2
			v/4: 27D4EB4Fh
			v/5: 0
			v/6: 0
			v/7: 61C8864Eh							;-- -P1
			v/8: 7A143579h
			while [(as-integer e - p) >= 32][
				k: 1
				loop 4 [
					ZSTD_GET32(il p)
					p: p + 4
					ZSTD_GET32(ih p)
					p: p + 4
					hh: v/k
					k: k + 1
					hl: v/k
					ZSTD_ROUND64(hh hl ih il)
					v/k: hl
					k: k - 1
					v/k: hh
					k: k + 2
				]
			]
			h/1: 0
			h/2: 0
			k: 1
			while [k <= 4][
				r: XXH-ROT/k
				hh: k * 2 - 1
				hl: k * 2
				ih: v/hh
				il: v/hl
				ZSTD_ROTL64(ih il r)
				ZSTD_ADD64(h/1 h/2 ih il)
				k: k + 1
			]
			k: 1
			while [k <= 8][							;-- merges the accumulators
				ih: v/k
				k: k + 1
				xxh-round x ih v/k
				k: k + 1
				xxh-mix h x 0 1 0 9E3779B1h 85EBCA87h 85EBCA77h C2B2AE63h
			]
		][
			h/1: 27D4EB2Fh							;-- P5
			h/2: 165667C5h
		]
		ZSTD_ADD64(h/1 h/2 0 len)
		while [(as-integer e - p) >= 8][
			ZSTD_GET32(il p)
			p: p + 4
			ZSTD_GET32(ih p)
			p: p + 4
			xxh-round x ih il
			xxh-mix h x 0 1 27 9E3779B1h 85EBCA87h 85EBCA77h C2B2AE63h
		]
		if (as-integer e - p) >= 4 [
			x/1: 0
			ZSTD_GET32(il p)
			x/2: il
			p: p + 4
			xxh-mix h x 9E3779B1h 85EBCA87h 23 C2B2AE3Dh 27D4EB4Fh 165667B1h 9E3779F9h
		]
		while [p < e][
			x/1: 0
			x/2: as integer! p/1
			p: p + 1
			xxh-mix h x 27D4EB2Fh 165667C5h 11 9E3779B1h 85EBCA87h 0 0
		]
		h/2: h/2 xor (h/1 >>> 1)					;-- avalanche
		mul64 h C2B2AE3Dh 27D4EB4Fh
		h/2: h/2 xor (h/2 >>> 29) xor (h/1 << 3)
		h/1: h/1 xor (h/1 >>> 29)
		mul64 h 165667B1h 9E3779F9h
		h/2 xor h/1
	]

	;-- FSE tables

	#define ZSTD_FILLF [							;-- forward bits of read-ncount, zeros past the end
		while [cnt <= 24][
			if pos < size [
				i: pos + 1
				acc: (as integer! src/i) << cnt or acc
			]
			pos: pos + 1
			cnt: cnt + 8
		]
	]

	read-ncount: func [							;-- reads a table description: normalized counts
		src		[byte-ptr!]
		size	[integer!]
		norm	[int-ptr!]						;-- counts of symbols 0..n-1, -1: "less than one"
		maxsym	[integer!]
		maxlog	[integer!]
		info	[int-ptr!]						;-- out: accuracy log, symbol count
		return:	[integer!]						;-- bytes read, 0: invalid
		/local
			acc cnt pos al rem thr nb mx c s z i [integer!]
	][
		acc: 0
		cnt: 0
		pos: 0
		ZSTD_FILLF
		al: acc and 15 + 5
		acc: acc >>> 4
		cnt: cnt - 4
		if al > maxlog [return 0]
		rem: (1 << al) + 1							;-- probability points left, plus one
		thr: 1 << al
		nb: al + 1
		s: 0
		while [all [rem > 1 s <= maxsym]][
			ZSTD_FILLF
			mx: thr << 1 - 1 - rem
			c: thr - 1 and acc
			either c < mx [
				acc: acc >>> (nb - 1)
				cnt: cnt - nb + 1
			][
				c: thr << 1 - 1 and acc
				if c >= thr [c: c - mx]
				acc: acc >>> nb
				cnt: cnt - nb
			]
			c: c - 1
			s: s + 1
			norm/s: c
			either c < 0 [rem: rem - 1][rem: rem - c]
			if c = 0 [								;-- repeat flags of zero counts: 2 bits, 3 = one more flag
				until [
					ZSTD_FILLF
					z: acc and 3
					acc: acc >>> 2
					cnt: cnt - 2
					loop z [
						s: s + 1
						if s > (maxsym + 1) [return 0]
						norm/s: 0
					]
					z <> 3
				]
			]
			while [rem < thr][
				nb: nb - 1
				thr: thr >> 1
			]
		]
		if rem <> 1 [return 0]
		info/1: al
		info/2: s
		i: pos << 3 - cnt + 7 >> 3
		if i > size [return 0]
		i
	]

	fse-spread: func [							;-- symbol of each table cell, placed as the format does
		table	[int-ptr!]
		norm	[int-ptr!]
		nsym	[integer!]
		al		[integer!]
		/local
			size high pos step mask s i k x [integer!]
	][
		size: 1 << al
		high: size								;-- cells above `high` hold the "less than one" symbols
		s: 0
		while [s < nsym][
			i: s + 1
			if norm/i = -1 [
				table/high: s
				high: high - 1
			]
			s: s + 1
		]
		pos: 0
		step: size >> 1 + (size >> 3) + 3
		mask: size - 1
		s: 0
		while [s < nsym][
			i: s + 1
			x: norm/i
			while [x > 0][
				k: pos + 1
				table/k: s
				until [
					pos: pos + step and mask
					pos < high
				]
				x: x - 1
			]
			s: s + 1
		]
	]

	build-fse: func [							;-- decoding table: baseline << 16, bit count << 8, symbol
		table	[int-ptr!]
		norm	[int-ptr!]
		nsym	[integer!]
		al		[integer!]
		nxt		[int-ptr!]						;-- scratch: next state of each symbol
		/local
			size s i k x nb [integer!]
	][
		fse-spread table norm nsym al
		size: 1 << al
		i: 1
		while [i <= nsym][
			x: norm/i
			if x = -1 [x: 1]
			nxt/i: x
			i: i + 1
		]
		k: 1
		while [k <= size][
			s: table/k
			i: s + 1
			x: nxt/i
			nxt/i: x + 1
			nb: al - log-b x
			table/k: (x << nb - size) << 16 or (nb << 8) or s
			k: k + 1
		]
	]

	seq-table: func [							;-- decoding table of a sequence field
		mode	[integer!]						;-- predefined, RLE, FSE or repeat
		src		[byte-ptr!]
		size	[integer!]
		table	[int-ptr!]
		alog	[int-ptr!]						;-- accuracy log of the table, -1: none yet
		dnorm	[int-ptr!]						;-- predefined distribution
		dnsym	[integer!]
		dal		[integer!]
		maxsym	[integer!]
		maxlog	[integer!]
		st		[ZSTD-DEC!]
		return:	[integer!]						;-- bytes read, -1: invalid
		/local
			info	[int-ptr!]
			k		[integer!]
	][
		if mode = 0 [
			build-fse table dnorm dnsym dal st/nxt
			alog/value: dal
			return 0
		]
		if mode = 1 [
			if size < 1 [return -1]
			k: as integer! src/1
			if k > maxsym [return -1]
			table/1: k
			alog/value: 0
			return 1
		]
		if mode = 2 [
			info: system/stack/allocate 2
			k: read-ncount src size st/norm maxsym maxlog info
			if k = 0 [return -1]
			build-fse table st/norm info/2 info/1 st/nxt
			alog/value: info/1
			return k
		]
		either alog/value < 0 [-1][0]
	]

	;-- Huffman literals

	weights-fse: func [							;-- FSE-coded Huffman weights
		src		[byte-ptr!]
		size	[integer!]
		st		[ZSTD-DEC!]
		return:	[integer!]						;-- weights decoded, -1: invalid
		/local
			info table fp [int-ptr!]
			w p start	[byte-ptr!]
			acc cnt pad al s1 s2 n k v c nb fn fw [integer!]
	][
		info: system/stack/allocate 2
		k: read-ncount src size st/norm 255 6 info
		if k = 0 [return -1]
		al: info/1
		table: st/wtab
		build-fse table st/norm info/2 al st/nxt
		if k >= size [return -1]
		v: size - k
		w: src + k
		ZSTD_OPEN(w v)
		if acc = 0 [return -1]
		ZSTD_FILL
		ZSTD_BITS(s1 al)
		ZSTD_BITS(s2 al)
		w: st/weights
		n: 0
		forever [									;-- two states take turns, until a read passes the start
			if n > 253 [return -1]
			k: s1 + 1
			c: table/k
			n: n + 1
			w/n: as byte! c
			ZSTD_FILL
			nb: c >>> 8 and FFh
			ZSTD_BITS(v nb)
			s1: c >>> 16 + v
			if cnt < pad [
				k: s2 + 1
				n: n + 1
				w/n: as byte! table/k
				break
			]
			if n > 253 [return -1]
			k: s2 + 1
			c: table/k
			n: n + 1
			w/n: as byte! c
			ZSTD_FILL
			nb: c >>> 8 and FFh
			ZSTD_BITS(v nb)
			s2: c >>> 16 + v
			if cnt < pad [
				k: s1 + 1
				n: n + 1
				w/n: as byte! table/k
				break
			]
		]
		n
	]

	read-huffman: func [						;-- reads a tree description, builds the literals table
		src		[byte-ptr!]
		size	[integer!]
		st		[ZSTD-DEC!]
		return:	[integer!]						;-- bytes read, 0: invalid
		/local
			rank	[int-ptr!]
			w t nb	[byte-ptr!]
			hdr n used total mb rest x i k len pos [integer!]
	][
		if size < 1 [return 0]
		hdr: as integer! src/1
		w: st/weights
		either hdr >= 128 [							;-- 4-bit weights
			n: hdr - 127
			used: n + 1 >> 1 + 1
			if used > size [return 0]
			i: 1
			while [i <= n][
				k: i + 1 >> 1 + 1
				x: as integer! src/k
				w/i: as byte! x >>> 4
				k: i + 1
				w/k: as byte! x and 0Fh
				i: i + 2
			]
		][
			used: hdr + 1
			if used > size [return 0]
			n: weights-fse src + 1 hdr st
			if n < 0 [return 0]
		]
		rank: system/stack/allocate 16				;-- symbols per weight (1-based: weight + 1)
		set-memory as byte-ptr! rank null-byte 64
		total: 0
		i: 1
		while [i <= n][
			x: as integer! w/i
			if x > 12 [return 0]
			k: x + 1
			rank/k: rank/k + 1
			if x > 0 [total: 1 << (x - 1) + total]
			i: i + 1
		]
		if total = 0 [return 0]
		mb: (log-b total) + 1						;-- longest code
		if mb > 12 [return 0]
		rest: (1 << mb) - total						;-- the last weight completes a power of two
		x: log-b rest
		if (1 << x) <> rest [return 0]
		x: x + 1
		n: n + 1
		w/n: as byte! x
		k: x + 1
		rank/k: rank/k + 1
		if any [rank/2 < 2 rank/2 and 1 <> 0][return 0]
		pos: 0										;-- first table entry of each weight
		x: 1
		while [x <= mb][
			k: x + 1
			len: rank/k << (x - 1)
			rank/k: pos
			pos: pos + len
			x: x + 1
		]
		t: st/huf
		nb: st/hufl
		i: 1
		while [i <= n][
			x: as integer! w/i
			if x > 0 [
				k: x + 1
				pos: rank/k
				len: 1 << (x - 1)
				rank/k: pos + len
				set-memory t + pos as byte! i - 1 len
				set-memory nb + pos as byte! mb + 1 - x len
			]
			i: i + 1
		]
		st/huf-log: mb
		used
	]

	huf-stream: func [							;-- decodes `n` literals from one Huffman stream
		dst		[byte-ptr!]
		n		[integer!]
		src		[byte-ptr!]
		size	[integer!]
		st		[ZSTD-DEC!]
		write?	[logic!]						;-- no: only checks the stream
		return:	[logic!]
		/local
			t nb e p start [byte-ptr!]
			fp	[int-ptr!]
			acc cnt pad mb mask v k fn fw [integer!]
	][
		if size < 1 [return false]
		ZSTD_OPEN(src size)
		if acc = 0 [return false]
		t: st/huf
		nb: st/hufl
		mb: st/huf-log
		mask: (1 << mb) - 1
		unless write? [								;-- the codes read, nothing written
			while [n > 0][
				ZSTD_FILL
				k: acc >>> (cnt - mb) and mask + 1
				cnt: cnt - as integer! nb/k
				n: n - 1
				if n > 0 [							;-- two codes per fill: 12 bits at most each
					k: acc >>> (cnt - mb) and mask + 1
					cnt: cnt - as integer! nb/k
					n: n - 1
				]
			]
			return ZSTD_END?
		]
		e: dst + n
		while [dst < e][
			ZSTD_FILL
			k: acc >>> (cnt - mb) and mask + 1
			dst/1: t/k
			cnt: cnt - as integer! nb/k
			dst: dst + 1
			if dst < e [							;-- two codes per fill: 12 bits at most each
				k: acc >>> (cnt - mb) and mask + 1
				dst/1: t/k
				cnt: cnt - as integer! nb/k
				dst: dst + 1
			]
		]
		ZSTD_END?
	]

	;-- blocks

	read-block: func [							;-- decodes a compressed block at st/op
		src		[byte-ptr!]
		size	[integer!]
		fend	[byte-ptr!]						;-- output limit
		fstart	[byte-ptr!]						;-- frame start: the farthest a match can reach
		bmax	[integer!]						;-- block content limit
		write?	[logic!]						;-- no: only counts the output
		st		[ZSTD-DEC!]
		return:	[integer!]						;-- ZSTD-NO-MEM: out of room
		/local
			op lp lend q bstart m e p start w [byte-ptr!]
			llt oft mlt s4 d4 fp [int-ptr!]
			b0 lt sf hs regen csize streams k n nseq modes qn s1 s2 s3 seg fn fw [integer!]
			acc cnt pad lls ofs mls llc ofc mlc c v x ov dist ml ll r rep1 rep2 rep3 win [integer!]
	][
		if size < 2 [return ZSTD-BAD]
		op: st/op
		bstart: op
		;-- literals section
		b0: as integer! src/1
		lt: b0 and 3
		sf: b0 >>> 2 and 3
		either lt < 2 [								;-- raw or RLE literals
			switch sf [
				1 [
					hs: 2
					if size < 2 [return ZSTD-BAD]
					regen: (le16 src) >>> 4
				]
				3 [
					hs: 3
					if size < 3 [return ZSTD-BAD]
					regen: (le24 src) >>> 4
				]
				default [
					hs: 1
					regen: b0 >>> 3
				]
			]
			if regen > bmax [return ZSTD-BAD]
			either lt = 0 [
				csize: regen
			][
				csize: 1
			]
		][											;-- Huffman-coded literals
			streams: 4
			switch sf [
				0 [
					streams: 1
					hs: 3
					if size < 3 [return ZSTD-BAD]
					k: le24 src
					regen: k >>> 4 and 3FFh
					csize: k >>> 14 and 3FFh
				]
				1 [
					hs: 3
					if size < 3 [return ZSTD-BAD]
					k: le24 src
					regen: k >>> 4 and 3FFh
					csize: k >>> 14 and 3FFh
				]
				2 [
					hs: 4
					if size < 4 [return ZSTD-BAD]
					k: le32 src
					regen: k >>> 4 and 3FFFh
					csize: k >>> 18
				]
				default [
					hs: 5
					if size < 5 [return ZSTD-BAD]
					k: le32 src
					regen: k >>> 4 and 3FFFFh
					csize: (as integer! src/5) << 10 or (k >>> 22)
				]
			]
			if regen > bmax [return ZSTD-BAD]
			if all [streams = 4 regen < 6][return ZSTD-BAD]
		]
		if hs + csize > size [return ZSTD-BAD]
		lp: as byte-ptr! 0
		lend: lp + regen
		if write? [
			either lt = 0 [
				lp: src + hs
				lend: lp + regen
			][
				if regen > (as-integer fend - op) [return ZSTD-NO-MEM]
				lend: fend							;-- literals decoded at the end of the free output
				lp: lend - regen
				if lt = 1 [
					k: hs + 1
					set-memory lp src/k regen
				]
			]
		]
		if lt >= 2 [								;-- Huffman-coded: the tree and streams checked when counting too
			q: src + hs
			qn: csize
			either lt = 2 [
				k: read-huffman q qn st
				if k = 0 [return ZSTD-BAD]
				q: q + k
				qn: qn - k
			][
				if st/huf-log < 0 [return ZSTD-BAD]
			]
			either streams = 1 [
				unless huf-stream lp regen q qn st write? [return ZSTD-BAD]
			][
				if qn < 10 [return ZSTD-BAD]
				s1: le16 q
				s2: le16 q + 2
				s3: le16 q + 4
				k: qn - 6 - s1 - s2 - s3
				if k < 1 [return ZSTD-BAD]
				seg: regen + 3 >> 2
				q: q + 6
				unless huf-stream lp seg q s1 st write? [return ZSTD-BAD]
				q: q + s1
				unless huf-stream lp + seg seg q s2 st write? [return ZSTD-BAD]
				q: q + s2
				unless huf-stream lp + (seg * 2) seg q s3 st write? [return ZSTD-BAD]
				q: q + s3
				unless huf-stream lp + (seg * 3) regen - (seg * 3) q k st write? [return ZSTD-BAD]
			]
		]
		k: hs + csize
		q: src + k
		qn: size - k

		;-- sequences section
		if qn < 1 [return ZSTD-BAD]
		nseq: as integer! q/1
		k: 1
		if nseq >= 128 [
			either nseq = 255 [
				if qn < 3 [return ZSTD-BAD]
				nseq: (le16 q + 1) + 7F00h
				k: 3
			][
				if qn < 2 [return ZSTD-BAD]
				nseq: nseq - 128 << 8 + as integer! q/2
				k: 2
			]
		]
		either nseq = 0 [
			if qn <> 1 [return ZSTD-BAD]
		][
			if qn <= k [return ZSTD-BAD]
			k: k + 1
			modes: as integer! q/k
			if modes and 3 <> 0 [return ZSTD-BAD]
			q: q + k
			qn: qn - k
			k: seq-table modes >>> 6 q qn st/ll :st/ll-log LL-NORM 36 6 35 9 st
			if k < 0 [return ZSTD-BAD]
			q: q + k
			qn: qn - k
			k: seq-table modes >>> 4 and 3 q qn st/of :st/of-log OF-NORM 29 5 31 8 st
			if k < 0 [return ZSTD-BAD]
			q: q + k
			qn: qn - k
			k: seq-table modes >>> 2 and 3 q qn st/ml :st/ml-log ML-NORM 53 6 52 9 st
			if k < 0 [return ZSTD-BAD]
			q: q + k
			qn: qn - k
			if qn < 1 [return ZSTD-BAD]
			ZSTD_OPEN(q qn)
			if acc = 0 [return ZSTD-BAD]
			llt: st/ll
			oft: st/of
			mlt: st/ml
			rep1: st/rep1
			rep2: st/rep2
			rep3: st/rep3
			win: st/window
			ZSTD_FILL
			c: st/ll-log
			ZSTD_BITS(lls c)
			c: st/of-log
			ZSTD_BITS(ofs c)
			ZSTD_FILL
			c: st/ml-log
			ZSTD_BITS(mls c)
			while [nseq > 0][
				k: lls + 1
				llc: llt/k
				k: ofs + 1
				ofc: oft/k
				k: mls + 1
				mlc: mlt/k
				c: ofc and FFh						;-- offset code: its bit count
				ZSTD_FILL
				either c <= 24 [
					ZSTD_BITS(v c)
				][
					if c > 30 [return ZSTD-BAD]
					k: c - 24
					ZSTD_BITS(v k)
					ZSTD_FILL
					ZSTD_BITS(x 24)
					v: v << 24 or x
				]
				ov: 1 << c + v
				c: mlc and FFh + 1
				k: as integer! ML-BITS/c
				ZSTD_FILL
				ZSTD_BITS(v k)
				ml: ML-BASE/c + v
				c: llc and FFh + 1
				k: as integer! LL-BITS/c
				ZSTD_FILL
				ZSTD_BITS(v k)
				ll: LL-BASE/c + v
				either ov > 3 [
					dist: ov - 3
					rep3: rep2
					rep2: rep1
					rep1: dist
				][
					if ll = 0 [ov: ov + 1]
					switch ov [
						1 [dist: rep1]
						2 [
							dist: rep2
							rep2: rep1
							rep1: dist
						]
						3 [
							dist: rep3
							rep3: rep2
							rep2: rep1
							rep1: dist
						]
						default [
							dist: rep1 - 1
							rep3: rep2
							rep2: rep1
							rep1: dist
						]
					]
				]
				r: as-integer lend - lp				;-- literals left
				if ll > r [return ZSTD-BAD]
				k: as-integer op - fstart
				if any [dist < 1 dist > (k + ll) dist > win][return ZSTD-BAD]	;-- before the frame or the window
				k: as-integer fend - op
				if ml + r > k [						;-- the match or the literals left do not fit
					if write? [return ZSTD-NO-MEM]
					return ZSTD-BAD
				]
				either write? [
					e: op + ll
					either all [r - ll >= 7 k - r >= 7][	;-- 8 bytes at a time: 7 more literals to read, room for 7 more before them
						m: lp + ll
						ZSTD_COPY8(op lp e)
						op: e
						lp: m
					][
						while [op < e][
							op/1: lp/1
							op: op + 1
							lp: lp + 1
						]
					]
					m: op - dist
					e: op + ml
					either all [dist >= 4 k - ml - r >= 7][	;-- 8 bytes at a time: room for 7 more before the literals left
						ZSTD_COPY8(op m e)
						op: e
					][
						while [op < e][
							op/1: m/1
							op: op + 1
							m: m + 1
						]
					]
				][
					op: op + ll + ml
					lp: lp + ll
				]
				nseq: nseq - 1
				if nseq > 0 [
					ZSTD_FILL
					k: llc >>> 8 and FFh
					ZSTD_BITS(v k)
					lls: llc >>> 16 + v
					k: mlc >>> 8 and FFh
					ZSTD_BITS(v k)
					mls: mlc >>> 16 + v
					ZSTD_FILL
					k: ofc >>> 8 and FFh
					ZSTD_BITS(v k)
					ofs: ofc >>> 16 + v
				]
			]
			unless ZSTD_END? [return ZSTD-BAD]
			st/rep1: rep1
			st/rep2: rep2
			st/rep3: rep3
		]
		r: as-integer lend - lp						;-- last literals
		if r > (as-integer fend - op) [
			if write? [return ZSTD-NO-MEM]
			return ZSTD-BAD
		]
		either write? [
			if r > 0 [move-memory op lp r]
		][
			lp: lend
		]
		op: op + r
		if (as-integer op - bstart) > bmax [return ZSTD-BAD]
		st/op: op
		ZSTD-OK
	]

	read-frames: func [							;-- decodes every frame of `in`
		in		[byte-ptr!]
		in-size	[integer!]
		out		[byte-ptr!]						;-- null: only counts the output
		out-len	[integer!]
		size	[int-ptr!]						;-- out: output size
		st		[ZSTD-DEC!]
		verify?	[logic!]						;-- counting: compressed blocks decoded, even when the frame gives its size
		return:	[integer!]
		/local
			p e q oend fend fstart [byte-ptr!]
			write? skip? last? single? check? [logic!]
			k n fhd fsz dsz hs w x fcs bmax b type bsize res ub [integer!]
	][
		write?: not null? out
		p: in
		e: in + in-size
		st/op: out
		st/unchecked?: no
		oend: out + out-len
		unless write? [oend: as byte-ptr! ZSTD_BIG]
		if p = e [return ZSTD-BAD]					;-- no frame
		while [p < e][
			k: as-integer e - p
			if k < 4 [return ZSTD-BAD]
			n: le32 p
			either n and FFFFFFF0h = 184D2A50h [	;-- skippable frame
				if k < 8 [return ZSTD-BAD]
				n: le32 p + 4
				if any [n < 0 n > (k - 8)][return ZSTD-BAD]
				p: p + 8 + n
			][
				if n <> ZSTD_MAGIC [return ZSTD-BAD]
				if k < 5 [return ZSTD-BAD]
				p: p + 4
				fhd: as integer! p/1				;-- frame header
				if fhd and 08h <> 0 [return ZSTD-BAD]
				single?: fhd and 20h <> 0
				check?: fhd and 04h <> 0
				dsz: fhd and 3
				if dsz = 3 [dsz: 4]
				fsz: fhd >>> 6
				fsz: either fsz = 0 [as integer! single?][1 << fsz]
				hs: 1 + dsz + fsz
				unless single? [hs: hs + 1]
				if hs > (k - 4) [return ZSTD-BAD]
				bmax: ZSTD_BLOCK_MAX
				st/window: 7FFFFFFFh					;-- single segment: up to the frame start
				q: p + 1
				unless single? [
					w: as integer! q/1
					x: w >>> 3
					if x > 21 [return ZSTD-BAD]		;-- windows of 2 GB and more
					if x < 21 [
						n: 1 << (x + 10)
						n: n >> 3 * (w and 7) + n
						st/window: n
						if n < bmax [bmax: n]
					]
					q: q + 1
				]
				n: 0								;-- dictionary ID: none supported
				switch dsz [
					1 [n: as integer! q/1]
					2 [n: le16 q]
					4 [n: le32 q]
					default [0]
				]
				if n <> 0 [return ZSTD-BAD]
				q: q + dsz
				fcs: -1
				switch fsz [
					1 [fcs: as integer! q/1]
					2 [fcs: (le16 q) + 256]
					4 [
						fcs: le32 q
						if fcs < 0 [return ZSTD-BAD]
					]
					8 [
						fcs: le32 q
						if any [fcs < 0 0 <> le32 q + 4][return ZSTD-BAD]
					]
					default [0]
				]
				if all [single? fcs < bmax][bmax: fcs]
				p: p + hs
				fstart: st/op
				fend: oend
				if fcs >= 0 [
					if fcs > (as-integer oend - fstart) [
						if write? [return ZSTD-NO-MEM]
						return ZSTD-BAD
					]
					fend: fstart + fcs
				]
				skip?: all [not write? fcs >= 0 not verify?]
				if skip? [st/unchecked?: yes]
				st/rep1: 1
				st/rep2: 4
				st/rep3: 8
				st/ll-log: -1
				st/of-log: -1
				st/ml-log: -1
				st/huf-log: -1
				ub: 0								;-- most content the blocks can hold
				until [								;-- blocks
					if (as-integer e - p) < 3 [return ZSTD-BAD]
					b: le24 p
					p: p + 3
					last?: b and 1 = 1
					type: b >>> 1 and 3
					bsize: b >>> 3
					if bsize > bmax [return ZSTD-BAD]
					n: bsize
					if type = 1 [n: 1]				;-- one byte, repeated
					if n > (as-integer e - p) [return ZSTD-BAD]
					if all [type < 2 not skip?][
						if bsize > (as-integer fend - st/op) [
							if all [write? fcs < 0][return ZSTD-NO-MEM]
							return ZSTD-BAD
						]
						if write? [
							either type = 0 [
								copy-memory st/op p bsize
							][
								set-memory st/op p/1 bsize
							]
						]
						st/op: st/op + bsize
					]
					ub: ub + bsize
					switch type [
						0 [p: p + bsize]
						1 [p: p + 1]
						2 [
							ub: ub - bsize + bmax
							unless skip? [
								res: read-block p bsize fend fstart bmax write? st
								if res <> ZSTD-OK [
									if any [res = ZSTD-BAD not write? fcs >= 0][return ZSTD-BAD]
									return res
								]
							]
							p: p + bsize
						]
						default [return ZSTD-BAD]
					]
					if ub < 0 [ub: ZSTD_BIG]
					last?
				]
				if check? [
					if (as-integer e - p) < 4 [return ZSTD-BAD]
					if write? [
						if (xxh64 fstart as-integer st/op - fstart) <> le32 p [return ZSTD-BAD]
					]
					p: p + 4
				]
				either skip? [
					if fcs > ub [return ZSTD-BAD]	;-- a content size its blocks cannot hold
					st/op: fend
				][
					if all [fcs >= 0 st/op <> fend][return ZSTD-BAD]
				]
			]
		]
		size/value: as-integer st/op - out
		ZSTD-OK
	]

	uncompress: func [
		out			[byte-ptr!]						;-- null: computes the size only
		out-size	[int-ptr!]
		in			[byte-ptr!]
		in-size		[integer!]
		return:		[integer!]
		/local
			st		[ZSTD-DEC! value]
			n		[integer!]
			res		[integer!]
	][
		st/ll: system/stack/allocate 512			;-- tables on the native stack: 15.5 KB
		st/of: system/stack/allocate 256
		st/ml: system/stack/allocate 512
		st/huf: as byte-ptr! system/stack/allocate 1024
		st/hufl: as byte-ptr! system/stack/allocate 1024
		st/weights: as byte-ptr! system/stack/allocate 64
		st/wtab: system/stack/allocate 64
		st/norm: system/stack/allocate 260
		st/nxt: system/stack/allocate 260
		n: 0
		unless null? out [
			res: read-frames in in-size out out-size/value :n st no
			if res <> ZSTD-NO-MEM [
				out-size/value: n
				return res
			]
		]
		res: read-frames in in-size null 0 :n st no		;-- the output size
		if all [res = ZSTD-OK st/unchecked? any [n >> 5 >= in-size n >= ZSTD_CHECK_SIZE]][	;-- 32 times the input or 16 MB or more: verified, decoding without writing
			res: read-frames in in-size null 0 :n st yes
		]
		if res <> ZSTD-OK [return res]
		if all [not null? out n <= out-size/value][return ZSTD-BAD]
		out-size/value: n
		either n > 0 [ZSTD-NO-MEM][ZSTD-OK]
	]

	unpack: func [									;-- decodes into a new buffer (freed by `release`), null on error
		in			[byte-ptr!]
		in-size		[integer!]
		out-size	[int-ptr!]						;-- if not null, receives the decoded size
		return:		[byte-ptr!]
		/local
			out		[byte-ptr!]
			n		[integer!]
			res		[integer!]
	][
		n: 0
		res: uncompress null :n in in-size
		if res <> ZSTD-NO-MEM [return null]			;-- invalid or empty
		#either red-pass? = yes [
			out: as byte-ptr! allocate-virtual n no
		][
			out: allocate n							;-- Red/System program: no allocate-virtual
			if null? out [return null]
		]
		res: uncompress out :n in in-size
		if res <> ZSTD-OK [
			release out
			return null
		]
		unless null? out-size [out-size/value: n]
		out
	]

	release: func [p [byte-ptr!]][					;-- frees a buffer made by `unpack`
		#either red-pass? = yes [free-virtual as int-ptr! p][free p]
	]

	;-- encoder

	#define ZSTD_PRIME1			9E3779B1h
	#define ZSTD_PRIME2			85EBCA77h
	#define ZSTD_PRIME3			1E35A7BDh			;-- 3-byte hash, zstd's
	#define ZSTD_OPT_NUM		4096				;-- optimal parser: positions priced in one pass, at most
	#define ZSTD_MAX_PRICE		40000000h
	#define ZSTD_SPLITS			196					;-- block splitter: split points of a block, at most (zstd's)

	ZSTD-ENC!: alias struct! [
		in			[byte-ptr!]						;-- input
		long		[int-ptr!]						;-- hash tables: position + 1 of the last 8 and 5 bytes seen
		short		[int-ptr!]
		lsh			[integer!]						;-- 32 - their log sizes
		ssh			[integer!]
		m5			[integer!]						;-- short hash of 4 to 7 bytes: 0, FFh, FFFFh, FFFFFFh
		window		[integer!]						;-- farthest match
		depth		[integer!]						;-- -1: the two tables above, 0 to 2: hash chains, lazy steps
		attempts	[integer!]						;-- hash chains: candidates per search
		cmask		[integer!]						;-- chain size - 1
		ins			[integer!]						;-- next position to put in the chains
		skip?		[logic!]						;-- only the positions searched go in the chains
		tree?		[logic!]						;-- a binary tree instead: smaller and larger subtrees of each position
		bmask		[integer!]						;-- positions in the tree - 1
		h3			[int-ptr!]						;-- optimal parser: position + 1 of the last 3 bytes seen
		h3sh		[integer!]						;-- 32 - its log size, 0: no table
		ins3		[integer!]						;-- next position to put in it
		parser		[integer!]						;-- optimal parser: 0 none, 1 prices in whole bits, 2 with fractions, 3 also first block parsed twice
		mml			[integer!]						;-- shortest match: 3 or 4
		suff		[integer!]						;-- match length taken at once
		opt			[int-ptr!]						;-- positions, 8 slots: price, offset value, match and literal lengths, repeat offsets
		mt			[int-ptr!]						;-- matches at a position: offset value, length
		lf			[int-ptr!]						;-- counts of literals, literal lengths, match lengths, offset codes
		llf			[int-ptr!]
		mlf			[int-ptr!]
		ofq			[int-ptr!]
		lsum		[integer!]						;-- their sums, llsum 0: none yet
		llsum		[integer!]
		mlsum		[integer!]
		osum		[integer!]
		lbase		[integer!]						;-- their weights: base prices
		llbase		[integer!]
		mlbase		[integer!]
		obase		[integer!]
		split?		[logic!]						;-- blocks cut where the parts are smaller (zstd's block splitter)
		sof2		[int-ptr!]						;-- offset values of a part, as written
		rep1		[integer!]						;-- repeat offsets, as the decoder will have them
		rep2		[integer!]
		rep3		[integer!]
		lits		[byte-ptr!]						;-- literals of the block
		nlits		[integer!]
		sll			[int-ptr!]						;-- sequences: literal length, match length, offset + 3 or 1
		sml			[int-ptr!]
		sof			[int-ptr!]
		nseq		[integer!]
		cll			[byte-ptr!]						;-- their codes
		cml			[byte-ptr!]
		cof			[byte-ptr!]
		freq		[int-ptr!]						;-- 256: symbol counts
		hlens		[byte-ptr!]						;-- 512: Huffman code lengths, then weights
		hcodes		[int-ptr!]						;-- 256: Huffman code << 8 or length
		tmp			[int-ptr!]						;-- 512: build-tree scratch
		norm		[int-ptr!]						;-- 64: normalized counts
		cells		[int-ptr!]						;-- 512: symbols of the table cells
		stab		[int-ptr!]						;-- 3 x 512: next states of LL, OF, ML
		tt			[int-ptr!]						;-- 3 x 128: bit count and state deltas per symbol
		logs		[int-ptr!]						;-- 3: their accuracy logs
	]

	ZSTD-SEQS!: alias struct! [					;-- a block's sequences and literals, as the matcher left them
		sll			[int-ptr!]
		sml			[int-ptr!]
		sof			[int-ptr!]
		cll			[byte-ptr!]
		cml			[byte-ptr!]
		cof			[byte-ptr!]
		lits		[byte-ptr!]
		nlits		[integer!]
		nseq		[integer!]
		src			[byte-ptr!]						;-- the block's bytes
	]

	LL-CODE: protect #{
		00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
		10 10 11 11 12 12 13 13 14 14 14 14 15 15 15 15
		16 16 16 16 16 16 16 16 17 17 17 17 17 17 17 17
		18 18 18 18 18 18 18 18 18 18 18 18 18 18 18 18
	}

	ML-CODE: protect #{
		00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
		10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F
		20 20 21 21 22 22 23 23 24 24 24 24 25 25 25 25
		26 26 26 26 26 26 26 26 27 27 27 27 27 27 27 27
		28 28 28 28 28 28 28 28 28 28 28 28 28 28 28 28
		29 29 29 29 29 29 29 29 29 29 29 29 29 29 29 29
		2A 2A 2A 2A 2A 2A 2A 2A 2A 2A 2A 2A 2A 2A 2A 2A
		2A 2A 2A 2A 2A 2A 2A 2A 2A 2A 2A 2A 2A 2A 2A 2A
	}

	RTB: protect [0 473195 504333 520860 550000 700000 750000 830000]	;-- round-up thresholds, 20-bit fractions

	ZSTD-LEVELS: protect #{						;-- levels 1 to 19, zstd's: window, chain, hash and search logs, match length, matcher, length taken at once / 4
		;-- matchers: 0 two hash tables, 1 to 3 hash chains (greedy, lazy, lazy2), 4 binary tree (lazy2), 5 to 7 binary tree and optimal parser 1 to 3
		;-- inputs above 256 KB
		13 0D 0E 01 07 00 00  14 0F 10 01 06 00 00  15 10 11 01 05 00 00  15 12 12 01 05 00 00
		15 12 13 03 05 01 00  15 12 13 03 05 02 00  15 13 14 04 05 02 00  15 13 14 04 05 03 00
		16 14 15 04 05 03 00  16 15 16 05 05 03 00  16 15 16 06 05 03 00  16 16 17 06 05 03 00
		16 16 16 04 05 04 00  16 16 17 05 05 04 00  16 17 17 06 05 04 00  16 16 16 05 05 05 0C
		17 17 16 05 04 05 10  17 17 16 06 03 06 10  17 18 16 07 03 07 40
		;-- up to 256 KB
		12 0D 0E 01 06 00 00  12 0E 0E 01 05 00 00  12 10 10 01 04 00 00  12 10 11 03 05 01 00
		12 11 12 05 05 01 00  12 12 13 03 05 02 00  12 12 13 04 04 02 00  12 12 13 04 04 03 00
		12 12 13 05 04 03 00  12 12 13 06 04 03 00  12 12 13 05 04 04 00  12 13 13 07 04 04 00
		12 12 13 04 04 05 04  12 12 13 04 03 05 08  12 12 13 06 03 05 20  12 13 13 06 03 06 20
		12 13 13 08 03 06 40  12 13 13 06 03 07 20  12 13 13 08 03 07 40
		;-- up to 128 KB
		11 0C 0D 01 06 00 00  11 0D 0F 01 05 00 00  11 0F 10 02 05 00 00  11 11 11 02 04 00 00
		11 10 11 03 04 01 00  11 10 11 03 04 02 00  11 10 11 03 04 03 00  11 10 11 04 04 03 00
		11 10 11 05 04 03 00  11 10 11 06 04 03 00  11 11 11 05 04 04 00  11 12 11 07 04 04 00
		11 12 11 03 04 05 03  11 12 11 04 03 05 08  11 12 11 06 03 05 40  11 12 11 06 03 06 20
		11 12 11 08 03 06 40  11 12 11 0A 03 06 80  11 12 11 05 03 07 40
		;-- up to 16 KB
		0E 0E 0F 01 05 00 00  0E 0E 0F 01 04 00 00  0E 0E 0F 02 04 00 00  0E 0E 0E 04 04 01 00
		0E 0E 0E 03 04 02 00  0E 0E 0E 04 04 03 00  0E 0E 0E 06 04 03 00  0E 0E 0E 08 04 03 00
		0E 0F 0E 05 04 04 00  0E 0F 0E 09 04 04 00  0E 0F 0E 03 04 05 03  0E 0F 0E 04 03 05 06
		0E 0F 0E 05 03 06 08  0E 0F 0F 06 03 06 10  0E 0F 0F 07 03 06 40  0E 0F 0F 05 03 07 0C
		0E 0F 0F 06 03 07 20  0E 0F 0F 07 03 07 40  0E 0F 0F 08 03 07 40
	}

	OF-FREQS: protect #{06 02 01 01 02 03 04 04 04 03 02}	;-- first counts of offset codes 0 to 10 (then 1), zstd's

	;-- bit streams read backward: locals bits, cnt, op

	#define ZSTD_PUT(_v _n) [						;-- _v below 1 << _n, 24 bits at most after a flush
		bits: _v << cnt or bits
		cnt: cnt + _n
	]

	#define ZSTD_FLUSH [
		while [cnt >= 8][
			op/1: as byte! bits
			op: op + 1
			bits: bits >>> 8
			cnt: cnt - 8
		]
	]

	#either target = 'IA-32 [
		#define ZSTD_FLUSHW(_lim) [					;-- ZSTD_FLUSH, one word store when 4 bytes are left before `_lim` (fw4 fwk)
			if cnt >= 8 [
				either (as-integer _lim - op) >= 4 [
					fw4: as int-ptr! op
					fw4/value: bits
					fwk: cnt >> 3
					op: op + fwk
					bits: bits >>> (fwk << 3)
					cnt: cnt and 7
				][
					ZSTD_FLUSH
				]
			]
		]
	][
		#define ZSTD_FLUSHW(_lim) [ZSTD_FLUSH]
	]

	#define ZSTD_CLOSE [							;-- end marker, then the last byte
		ZSTD_PUT(1 1)
		ZSTD_FLUSH
		if cnt > 0 [
			op/1: as byte! bits
			op: op + 1
		]
	]

	#define ZSTD_FLUSH16 [
		if cnt > 16 [
			op/1: as byte! bits
			op/2: as byte! bits >>> 8
			op: op + 2
			bits: bits >>> 16
			cnt: cnt - 16
		]
	]

	#define ZSTD_ESTART(_x _stab _tt _s) [			;-- first state of an FSE encoder: symbol _s
		k2: _s << 1 + 1
		c2: _tt/k2
		nb: c2 + 8000h >> 16
		v: nb << 16 - c2
		k2: k2 + 1
		k2: v >> nb + _tt/k2 + 1
		_x: _stab/k2
	]

	#define ZSTD_ESYM(_x _stab _tt _s) [			;-- encodes symbol _s from state _x
		k2: _s << 1 + 1
		nb: _x + _tt/k2 >> 16
		v: (1 << nb) - 1 and _x
		ZSTD_PUT(v nb)
		k2: k2 + 1
		k2: _x >> nb + _tt/k2 + 1
		_x: _stab/k2
	]

	#either target = 'IA-32 [
		#define ZSTD_LITS(_d _s _n _e) [				;-- copies a block's literals: 8 bytes at a time, up to 7 past them, when `_e` allows (ld ls le s4 d4)
			either _s + _n + 7 <= _e [
				ld: _d
				ls: _s
				le: ld + _n
				while [ld < le][
					s4: as int-ptr! ls
					d4: as int-ptr! ld
					d4/value: s4/value
					s4: s4 + 1
					d4: d4 + 1
					d4/value: s4/value
					ld: ld + 8
					ls: ls + 8
				]
			][
				copy-memory _d _s _n
			]
		]
	][
		#define ZSTD_LITS(_d _s _n _e) [copy-memory _d _s _n]
	]

	#define ZSTD_HASH(_p) [							;-- hl, hs: hashes of the 8 and 5 bytes at _p, read in a and b
		ZSTD_GET32(a _p)
		q4: _p + 4
		ZSTD_GET32(b q4)
		t: a * ZSTD_PRIME1
		hl: b * ZSTD_PRIME2 xor t >>> lsh + 1
		hs: b and m5 * ZSTD_PRIME2 xor t >>> ssh + 1
	]

	match-len: func [							;-- equal bytes at `p` and `m`, `p` stopping at `e`
		p		[byte-ptr!]
		m		[byte-ptr!]
		e		[byte-ptr!]
		return:	[integer!]
		/local
			s	[byte-ptr!]
			i4	[int-ptr!]
			a	[integer!]
	][
		s: p
		#if target = 'IA-32 [
			while [p + 4 <= e][
				i4: as int-ptr! p
				a: i4/value
				i4: as int-ptr! m
				a: a xor i4/value
				if a <> 0 [
					a: a and (0 - a)				;-- lowest differing bit
					return (as-integer p - s) + ((log-b a) >> 3)
				]
				p: p + 4
				m: m + 4
			]
		]
		while [all [p < e p/1 = m/1]][
			p: p + 1
			m: m + 1
		]
		as-integer p - s
	]

	match-block: func [							;-- sequences and literals of a block, matched on two hash tables (lowest levels)
		st		[ZSTD-ENC!]
		bstart	[byte-ptr!]
		bend	[byte-ptr!]
		/local
			in ip anchor m limit lits q q4 ld ls le [byte-ptr!]
			i4 long short sll sml sof s4 d4 [int-ptr!]
			cur cl cs hl hs len dist rep1 rep2 ns nl a b c t k lsh ssh m5 win [integer!]
	][
		in: st/in
		long: st/long
		short: st/short
		lsh: st/lsh
		ssh: st/ssh
		m5: st/m5
		win: st/window
		rep1: st/rep1
		rep2: st/rep2
		sll: st/sll
		sml: st/sml
		sof: st/sof
		lits: st/lits
		ns: 0
		nl: 0
		ip: bstart
		anchor: bstart
		limit: bend - 8
		while [ip < limit][
			cur: as-integer ip - in
			ZSTD_HASH(ip)
			cl: long/hl
			cs: short/hs
			long/hl: cur + 1
			short/hs: cur + 1
			len: 0
			dist: 0
			if rep1 <= (cur + 1) [					;-- the last offset, one byte further
				q: ip + 1
				m: q - rep1
				ZSTD_GET32(c q)
				ZSTD_GET32(k m)
				if c = k [
					len: (match-len q + 4 m + 4 bend) + 4
					ip: q
				]
			]
			if all [len = 0 cl > 0 cur - cl < win][	;-- the same 8 bytes before
				m: in + cl - 1
				ZSTD_GET32(c m)
				q: m + 4
				ZSTD_GET32(k q)
				if all [c = a k = b][
					len: (match-len ip + 8 m + 8 bend) + 8
					dist: cur - cl + 1
				]
			]
			if all [len = 0 cs > 0 cur - cs < win][	;-- the same 5 bytes before
				m: in + cs - 1
				ZSTD_GET32(c m)
				if c = a [
					dist: cur - cs + 1
					q: ip + 1						;-- the same 8 bytes before, one byte further
					ZSTD_HASH(q)
					cl: long/hl
					long/hl: cur + 2
					if all [cl > 0 cur + 1 - cl < win][
						q4: in + cl - 1
						ZSTD_GET32(c q4)
						q4: q4 + 4
						ZSTD_GET32(k q4)
						if all [c = a k = b][
							m: in + cl - 1
							len: (match-len q + 8 m + 8 bend) + 8
							ip: q
							dist: cur + 2 - cl
						]
					]
					if len = 0 [len: (match-len ip + 4 m + 4 bend) + 4]
				]
			]
			either len = 0 [
				k: as-integer ip - anchor
				ip: ip + (k >> 8) + 1				;-- faster through data without matches
			][
				k: 1								;-- repeat code
				if dist > 0 [
					m: ip - dist					;-- extends the match backward
					while [all [ip > anchor m > in]][
						q: ip - 1
						q4: m - 1
						if q/1 <> q4/1 [break]
						ip: q
						m: q4
						len: len + 1
					]
					rep2: rep1
					rep1: dist
					k: dist + 3
				]
				ns: ns + 1
				sof/ns: k
				sml/ns: len
				k: as-integer ip - anchor
				sll/ns: k
				ZSTD_LITS((lits + nl) anchor k bend)
				nl: nl + k
				ip: ip + len
				anchor: ip
				if ip <= limit [
					q: in + cur + 2					;-- positions inside the match
					ZSTD_HASH(q)
					long/hl: cur + 3
					short/hs: cur + 3
					q: ip - 2
					ZSTD_HASH(q)
					long/hl: (as-integer q - in) + 1
					q: ip - 1
					ZSTD_HASH(q)
					short/hs: (as-integer q - in) + 1
					while [ip <= limit][			;-- the offset before the last one, at once
						k: as-integer ip - in
						if rep2 > k [break]
						q: ip - rep2
						ZSTD_GET32(c ip)
						ZSTD_GET32(t q)
						if c <> t [break]
						len: (match-len ip + 4 q + 4 bend) + 4
						c: rep2
						rep2: rep1
						rep1: c
						ZSTD_HASH(ip)
						long/hl: k + 1
						short/hs: k + 1
						ns: ns + 1
						sll/ns: 0
						sml/ns: len
						sof/ns: 1
						ip: ip + len
						anchor: ip
					]
				]
			]
		]
		k: as-integer bend - anchor
		copy-memory lits + nl anchor k
		st/nlits: nl + k
		st/nseq: ns
		st/rep1: rep1
		st/rep2: rep2
	]

	#define ZSTD_CHASH(_p) [						;-- hl: hash of the first 4 to 6 bytes at _p (as m5 says)
		ZSTD_GET32(a _p)
		q4: _p + 4
		ZSTD_GET32(b q4)
		hl: b and m5 * ZSTD_PRIME2 xor (a * ZSTD_PRIME1) >>> lsh + 1
	]

	bt-walk: func [								;-- puts `ip` in the binary tree; mode 1: its longer matches too, into st/mt
		st		[ZSTD-ENC!]
		ip		[byte-ptr!]
		iend	[byte-ptr!]						;-- matches stop there
		best	[integer!]						;-- length to beat
		mode	[integer!]						;-- 0: only the insertion
		nm		[integer!]						;-- matches already in st/mt
		return:	[integer!]						;-- mode 0: positions to skip, else matches in st/mt
		/local
			in m q4		[byte-ptr!]
			i4 head bt sp lp nd mt [int-ptr!]
			cur cand mi low btlow bmask n len lsm llg mend k a b hl lsh m5 dummy [integer!]
	][
		in: st/in
		head: st/long
		bt: st/short
		lsh: st/lsh
		m5: st/m5
		bmask: st/bmask
		mt: st/mt
		cur: as-integer ip - in
		ZSTD_CHASH(ip)
		cand: head/hl								;-- position + 1, 0: none
		head/hl: cur + 1							;-- `ip` becomes the root
		low: cur - st/window
		if low < 0 [low: 0]
		btlow: cur - bmask							;-- positions up to this one: their subtrees are not kept
		k: cur and bmask << 1
		sp: bt + k									;-- where the next smaller and larger positions go
		lp: sp + 1
		lsm: 0										;-- bytes shared with every smaller and larger position left
		llg: 0
		mend: cur + 9								;-- farthest match end: repetitive data skipped
		dummy: 0
		n: st/attempts
		while [all [cand > low n > 0]][
			mi: cand - 1
			nd: bt + (mi and bmask << 1)			;-- its subtrees: smaller, larger
			len: lsm
			if llg < len [len: llg]
			m: in + mi
			len: (match-len ip + len m + len iend) + len
			if len > best [
				best: len
				if mi + len > mend [mend: mi + len]
				if mode > 0 [
					nm: nm + 1
					k: nm << 1
					mt/k: len
					k: k - 1
					mt/k: cur - mi + 3
					if len > ZSTD_OPT_NUM [break]
				]
			]
			if ip + len = iend [break]				;-- no byte left to order them: that subtree is dropped
			k: len + 1
			either m/k < ip/k [
				sp/value: cand
				lsm: len
				if mi <= btlow [
					sp: :dummy
					break
				]
				sp: nd + 1
				cand: nd/2
			][
				lp/value: cand
				llg: len
				if mi <= btlow [
					lp: :dummy
					break
				]
				lp: nd
				cand: nd/1
			]
			n: n - 1
		]
		sp/value: 0
		lp/value: 0
		either mode = 0 [
			k: 0
			if best > 384 [							;-- long repetitive data: faster
				k: best - 384
				if k > 192 [k: 192]
			]
			mend: mend - cur - 8
			if mend < k [mend: k]
			mend
		][
			st/ins: mend - 8
			nm
		]
	]

	bt-update: func [							;-- puts in the binary tree the positions before `ip`
		st		[ZSTD-ENC!]
		ip		[byte-ptr!]
		iend	[byte-ptr!]
		/local
			in		[byte-ptr!]
			cur pos k [integer!]
	][
		in: st/in
		cur: as-integer ip - in
		pos: st/ins
		while [pos < cur][
			k: bt-walk st in + pos iend 8 0 0
			pos: pos + k
			if st/skip? [pos: cur]				;-- through data without matches: only the positions searched
		]
		st/ins: cur
	]

	tree-search: func [							;-- longest match at `ip` worth its offset, in the binary tree, positions before `ip` inserted first
		st		[ZSTD-ENC!]
		ip		[byte-ptr!]
		iend	[byte-ptr!]
		dist	[int-ptr!]						;-- out: distance of the match
		return:	[integer!]						;-- its length, 0: none of 4 bytes at least
		/local
			mt		[int-ptr!]
			n i k len ml ob [integer!]
	][
		if (as-integer ip - st/in) < st/ins [return 0]	;-- inside repetitive data: skipped
		bt-update st ip iend
		n: bt-walk st ip iend 3 1 0
		mt: st/mt
		ml: 0
		ob: 999999999
		i: 1
		while [i <= n][							;-- longer and farther: kept if worth more bits, as zstd does
			k: i << 1
			len: mt/k
			k: k - 1
			if (len - ml * 4) > ((log-b mt/k - 2) - (log-b ob)) [
				ml: len
				ob: mt/k
			]
			i: i + 1
		]
		dist/value: ob - 3
		ml
	]

	chain-search: func [						;-- longest match at `ip` in its hash chain, positions before `ip` inserted first
		st		[ZSTD-ENC!]
		ip		[byte-ptr!]
		iend	[byte-ptr!]						;-- matches stop there
		dist	[int-ptr!]						;-- out: distance of the match
		return:	[integer!]						;-- its length, 0: none of 4 bytes at least
		/local
			in q q4 m	[byte-ptr!]
			i4 head chain [int-ptr!]
			cur pos a b hl k n ml len cand low minc lsh m5 cmask [integer!]
	][
		if st/tree? [return tree-search st ip iend dist]
		in: st/in
		head: st/long
		chain: st/short
		lsh: st/lsh
		m5: st/m5
		cmask: st/cmask
		cur: as-integer ip - in
		pos: st/ins
		while [pos < cur][
			q: in + pos
			ZSTD_CHASH(q)
			k: pos and cmask + 1
			chain/k: head/hl
			head/hl: pos + 1
			pos: pos + 1
			if st/skip? [pos: cur]				;-- through data without matches: only the positions searched
		]
		st/ins: cur
		ZSTD_CHASH(ip)
		cand: head/hl							;-- position + 1, 0: none
		low: cur - st/window
		if low < 0 [low: 0]
		minc: cur - cmask - 1					;-- older positions: their chain slot was reused
		n: st/attempts
		ml: 3
		while [all [cand > low n > 0]][
			m: in + cand - 1
			q: m + ml - 3						;-- the 4 bytes up to the one a longer match needs
			q4: ip + ml - 3
			ZSTD_GET32(a q)
			ZSTD_GET32(b q4)
			if a = b [
				len: match-len ip m iend
				if len > ml [
					ml: len
					dist/value: cur - cand + 1
					if ip + len = iend [break]
				]
			]
			k: cand - 1
			if k <= minc [break]
			k: k and cmask + 1
			cand: chain/k
			n: n - 1
		]
		if ml < 4 [ml: 0]
		ml
	]

	chain-block: func [						;-- sequences and literals of a block, lazy matching on hash chains
		st		[ZSTD-ENC!]
		bstart	[byte-ptr!]
		bend	[byte-ptr!]
		/local
			in ip anchor start limit lits q m ld ls le [byte-ptr!]
			i4 sll sml sof s4 d4 [int-ptr!]
			rep1 rep2 ns nl ml ob mlr k cur depth g1 g2 a b c dist [integer!]
	][
		in: st/in
		rep1: st/rep1
		rep2: st/rep2
		sll: st/sll
		sml: st/sml
		sof: st/sof
		lits: st/lits
		depth: st/depth
		dist: 0
		ns: 0
		nl: 0
		ip: bstart
		anchor: bstart
		limit: bend - 8
		while [ip < limit][
			ml: 0
			ob: 1									;-- repeat code, else offset + 3
			start: ip + 1
			cur: as-integer ip - in
			if rep1 <= (cur + 1) [					;-- the last offset, one byte further
				q: ip + 1
				m: q - rep1
				ZSTD_GET32(a q)
				ZSTD_GET32(b m)
				if a = b [ml: (match-len q + 4 m + 4 bend) + 4]
			]
			unless all [ml > 0 depth = 0][			;-- greedy: a repeat match is kept at once
				k: chain-search st ip bend :dist
				if k > ml [
					ml: k
					ob: dist + 3
					start: ip
				]
				if ml < 4 [
					k: as-integer ip - anchor
					k: k >> 8 + 1
					ip: ip + k						;-- faster through data without matches
					st/skip?: k > 8
					continue
				]
				if depth > 0 [
					while [ip < limit][				;-- a better match one byte further, two for lazy2?
						ip: ip + 1
						cur: cur + 1
						if rep1 <= cur [
							m: ip - rep1
							ZSTD_GET32(a ip)
							ZSTD_GET32(b m)
							if a = b [
								mlr: (match-len ip + 4 m + 4 bend) + 4
								g1: ml * 3 - (log-b ob) + 1
								if mlr * 3 > g1 [
									ml: mlr
									ob: 1
									start: ip
								]
							]
						]
						k: chain-search st ip bend :dist
						if k > 0 [
							g2: k * 4 - (log-b dist + 3)
							g1: ml * 4 - (log-b ob) + 4
							if g2 > g1 [
								ml: k
								ob: dist + 3
								start: ip
								continue
							]
						]
						if all [depth = 2 ip < limit][
							ip: ip + 1
							cur: cur + 1
							if rep1 <= cur [
								m: ip - rep1
								ZSTD_GET32(a ip)
								ZSTD_GET32(b m)
								if a = b [
									mlr: (match-len ip + 4 m + 4 bend) + 4
									g1: ml * 4 - (log-b ob) + 1
									if mlr * 4 > g1 [
										ml: mlr
										ob: 1
										start: ip
									]
								]
							]
							k: chain-search st ip bend :dist
							if k > 0 [
								g2: k * 4 - (log-b dist + 3)
								g1: ml * 4 - (log-b ob) + 7
								if g2 > g1 [
									ml: k
									ob: dist + 3
									start: ip
									continue
								]
							]
						]
						break
					]
				]
				if ob > 3 [							;-- extends the match backward
					dist: ob - 3
					m: start - dist
					while [all [start > anchor m > in]][
						q: start - 1
						m: m - 1
						if q/1 <> m/1 [break]
						start: q
						ml: ml + 1
					]
					rep2: rep1
					rep1: dist
				]
			]
			ns: ns + 1
			sof/ns: ob
			sml/ns: ml
			k: as-integer start - anchor
			sll/ns: k
			ZSTD_LITS((lits + nl) anchor k bend)
			nl: nl + k
			ip: start + ml
			anchor: ip
			st/skip?: no
			while [ip <= limit][					;-- the offset before the last one, at once
				k: as-integer ip - in
				if rep2 > k [break]
				q: ip - rep2
				ZSTD_GET32(a ip)
				ZSTD_GET32(b q)
				if a <> b [break]
				ml: (match-len ip + 4 q + 4 bend) + 4
				c: rep2
				rep2: rep1
				rep1: c
				ns: ns + 1
				sll/ns: 0
				sml/ns: ml
				sof/ns: 1
				ip: ip + ml
				anchor: ip
			]
		]
		k: as-integer bend - anchor
		copy-memory lits + nl anchor k
		st/nlits: nl + k
		st/nseq: ns
		st/rep1: rep1
		st/rep2: rep2
	]

	;-- optimal parser: prices in 1/256 bits, from the statistics of the sequences already chosen

	#define ZSTD_H3(_p) [							;-- h3: slot of the 3 bytes at _p
		ZSTD_GET32(a _p)
		h3: a << 8 * ZSTD_PRIME3 >>> h3sh + 1
	]

	#define ZSTD_WEIGHT(_w _s) [					;-- _w: about log2 (_s + 1) << 8, with a fraction if fr
		_w: _s + 1
		hb: log-b _w
		either fr [_w: _w << 8 >> hb + (hb << 8)][_w: hb << 8]
	]

	#define ZSTD_LITPRICE(_w _b) [					;-- _w: price of the literal _b, 1 bit at least
		k2: 1 + as integer! _b
		ZSTD_WEIGHT(_w lf/k2)
		_w: st/lbase - _w
		if _w < 256 [_w: 256]
	]

	#define ZSTD_MLPRICE(_w _m) [					;-- _w: price of the match length _m
		k2: _m - 3
		either k2 < 128 [
			k2: k2 + 1
			c2: as integer! ML-CODE/k2
		][
			c2: (log-b k2) + 36
		]
		k2: c2 + 1
		ZSTD_WEIGHT(_w mlf/k2)
		_w: (as integer! ML-BITS/k2) << 8 + st/mlbase - _w
	]

	#define ZSTD_NEWREP(_d _s _o _z) [				;-- repeat offsets _d after a match of offset value _o, from _s (_z: 1 without literals)
		either _o > 3 [
			_d/3: _s/2
			_d/2: _s/1
			_d/1: _o - 3
		][
			rc: _o - 1 + _z
			either rc = 0 [
				_d/1: _s/1
				_d/2: _s/2
				_d/3: _s/3
			][
				either rc = 3 [ro: _s/1 - 1][
					rc: rc + 1
					ro: _s/rc
					rc: rc - 1
				]
				either rc >= 2 [_d/3: _s/2][_d/3: _s/3]
				_d/2: _s/1
				_d/1: ro
			]
		]
	]

	ll-price: func [							;-- price of a literal length
		st		[ZSTD-ENC!]
		ll		[integer!]
		return:	[integer!]
		/local
			f		[int-ptr!]
			c k w hb px [integer!]
			fr		[logic!]
	][
		px: 0
		if ll >= ZSTD_BLOCK_MAX [				;-- a block of literals only: a bit more than the longest length
			ll: ZSTD_BLOCK_MAX - 1
			px: 256
		]
		either ll < 64 [
			k: ll + 1
			c: as integer! LL-CODE/k
		][
			c: (log-b ll) + 19
		]
		k: c + 1
		f: st/llf
		fr: st/parser > 1
		ZSTD_WEIGHT(w f/k)
		(as integer! LL-BITS/k) << 8 + st/llbase - w + px
	]

	off-price: func [							;-- price of an offset value (offset + 3 or repeat code)
		st		[ZSTD-ENC!]
		ob		[integer!]
		return:	[integer!]
		/local
			f		[int-ptr!]
			c k w hb [integer!]
			fr		[logic!]
	][
		c: log-b ob
		k: c + 1
		f: st/ofq
		fr: st/parser > 1
		ZSTD_WEIGHT(w f/k)
		w: c << 8 + st/obase - w + 51			;-- 1/5 bit more per match: fewer sequences, faster decoding
		if all [not fr c >= 20][w: c - 19 << 9 + w]	;-- far offsets dearer, for the same reason
		w
	]

	opt-count: func [							;-- statistics after a sequence
		st		[ZSTD-ENC!]
		p		[byte-ptr!]						;-- its literals
		ll		[integer!]
		ob		[integer!]						;-- offset value
		ml		[integer!]
		/local
			f		[int-ptr!]
			e		[byte-ptr!]
			c k		[integer!]
	][
		f: st/lf
		e: p + ll
		while [p < e][
			k: 1 + as integer! p/1
			f/k: f/k + 2
			p: p + 1
		]
		st/lsum: ll << 1 + st/lsum
		either ll < 64 [
			k: ll + 1
			c: as integer! LL-CODE/k
		][
			c: (log-b ll) + 19
		]
		f: st/llf
		k: c + 1
		f/k: f/k + 1
		f: st/ofq
		k: (log-b ob) + 1
		f/k: f/k + 1
		k: ml - 3
		either k < 128 [
			k: k + 1
			c: as integer! ML-CODE/k
		][
			c: (log-b k) + 36
		]
		f: st/mlf
		k: c + 1
		f/k: f/k + 1
		st/llsum: st/llsum + 1
		st/mlsum: st/mlsum + 1
		st/osum: st/osum + 1
	]

	opt-bases: func [							;-- base prices: weights of the sums
		st		[ZSTD-ENC!]
		/local
			w hb	[integer!]
			fr		[logic!]
	][
		fr: st/parser > 1
		ZSTD_WEIGHT(w st/lsum)
		st/lbase: w
		ZSTD_WEIGHT(w st/llsum)
		st/llbase: w
		ZSTD_WEIGHT(w st/mlsum)
		st/mlbase: w
		ZSTD_WEIGHT(w st/osum)
		st/obase: w
	]

	opt-shrink: func [							;-- counts divided by 1 << sh, kept above 0 (unless 0 when z?), their sum
		f		[int-ptr!]
		n		[integer!]
		sh		[integer!]
		z?		[logic!]
		return:	[integer!]
		/local
			i s v	[integer!]
	][
		s: 0
		i: 1
		while [i <= n][
			v: f/i >> sh
			if any [not z? f/i > 0][v: v + 1]
			f/i: v
			s: s + v
			i: i + 1
		]
		s
	]

	opt-scale: func [							;-- counts divided when their sum passes 2 << lg, their sum
		f		[int-ptr!]
		n		[integer!]
		lg		[integer!]
		return:	[integer!]
		/local
			i s		[integer!]
	][
		s: 0
		i: 1
		while [i <= n][
			s: s + f/i
			i: i + 1
		]
		i: s >> lg
		if i <= 1 [return s]
		i: log-b i
		opt-shrink f n i no
	]

	opt-stats: func [							;-- statistics at a block's start: from its literals at first, else the last ones scaled down
		st		[ZSTD-ENC!]
		src		[byte-ptr!]
		n		[integer!]
		/local
			f		[int-ptr!]
			p e		[byte-ptr!]
			k		[integer!]
	][
		either st/llsum = 0 [
			f: st/lf
			set-memory as byte-ptr! f null-byte 1024
			p: src
			e: src + n
			while [p < e][
				k: 1 + as integer! p/1
				f/k: f/k + 1
				p: p + 1
			]
			st/lsum: opt-shrink f 256 8 yes
			f: st/llf
			k: 1
			while [k <= 36][
				f/k: 1
				k: k + 1
			]
			f/1: 4
			f/2: 2
			st/llsum: 40
			f: st/mlf
			k: 1
			while [k <= 53][
				f/k: 1
				k: k + 1
			]
			st/mlsum: 53
			f: st/ofq
			k: 1
			while [k <= 32][
				f/k: 1
				if k <= 11 [f/k: as integer! OF-FREQS/k]
				k: k + 1
			]
			st/osum: 53
		][
			st/lsum: opt-scale st/lf 256 12
			st/llsum: opt-scale st/llf 36 11
			st/mlsum: opt-scale st/mlf 53 11
			st/osum: opt-scale st/ofq 32 11
		]
		opt-bases st
	]

	opt-matches: func [							;-- matches at `ip` into st/mt, of increasing lengths: repeat offsets, 3 bytes, binary tree
		st		[ZSTD-ENC!]
		ip		[byte-ptr!]
		iend	[byte-ptr!]
		reps	[int-ptr!]						;-- repeat offsets at `ip`
		z		[integer!]						;-- 1: no literals before `ip`
		return:	[integer!]						;-- matches in st/mt
		/local
			in m		[byte-ptr!]
			i4 mt h3t	[int-ptr!]
			cur best nm r lim ro len a b k mml h3 h3sh pos [integer!]
	][
		in: st/in
		cur: as-integer ip - in
		if cur < st/ins [return 0]				;-- inside repetitive data: skipped
		bt-update st ip iend
		mt: st/mt
		mml: st/mml
		best: mml - 1
		nm: 0
		r: z
		lim: z + 3
		while [r < lim][						;-- repeat offsets, as the decoder reads them (3 without literals: the last - 1)
			either r = 3 [ro: reps/1 - 1][
				k: r + 1
				ro: reps/k
			]
			if all [ro > 0 ro <= cur ro <= st/window][
				m: ip - ro
				ZSTD_GET32(a ip)
				ZSTD_GET32(b m)
				if mml = 3 [					;-- the first 3 bytes only
					a: a << 8
					b: b << 8
				]
				if a = b [
					len: (match-len ip + mml m + mml iend) + mml
					if len > best [
						best: len
						nm: nm + 1
						k: nm << 1
						mt/k: len
						k: k - 1
						mt/k: r - z + 1
						if any [len > st/suff ip + len = iend][return nm]
					]
				]
			]
			r: r + 1
		]
		if all [mml = 3 best < 3][				;-- the last 3 bytes seen, if not too far
			h3t: st/h3
			h3sh: st/h3sh
			pos: st/ins3
			while [pos < cur][
				m: in + pos
				ZSTD_H3(m)
				pos: pos + 1
				h3t/h3: pos
			]
			st/ins3: cur
			ZSTD_H3(ip)
			k: h3t/h3 - 1						;-- -1: none
			if all [k >= 0 cur - k <= st/window cur - k < 40000h][
				len: match-len ip in + k iend
				if len >= 3 [
					best: len
					nm: 1
					mt/1: cur - k + 3
					mt/2: len
					if any [len > st/suff ip + len = iend][
						st/ins: cur + 1					;-- `ip` not put in the tree
						return 1
					]
				]
			]
		]
		bt-walk st ip iend best 1 nm
	]

	opt-block: func [							;-- sequences and literals of a block: the cheapest path through its matches
		st		[ZSTD-ENC!]
		bstart	[byte-ptr!]
		bend	[byte-ptr!]
		/local
			in ip anchor limit lits p ld ls le [byte-ptr!]
			opt mt lf mlf sll sml sof rep e e1 e2 r0 r1 s4 d4 [int-ptr!]
			ns nl cur last nm i k k2 c2 hb w w2 l1 ll ml mlen start ob op price base
			pm pmo pmm pml sm so sl rc ro z suff mml pos se ss sp [integer!]
			fr done? [logic!]
	][
		in: st/in
		opt: st/opt
		mt: st/mt
		lf: st/lf
		mlf: st/mlf
		sll: st/sll
		sml: st/sml
		sof: st/sof
		lits: st/lits
		suff: st/suff
		mml: st/mml
		fr: st/parser > 1
		rep: system/stack/allocate 3
		rep/1: st/rep1
		rep/2: st/rep2
		rep/3: st/rep3
		opt-stats st bstart as-integer bend - bstart
		ns: 0
		nl: 0
		ip: bstart
		anchor: bstart
		limit: bend - 8
		if ip = in [ip: ip + 1]					;-- no match at the first byte
		while [ip < limit][
			ll: as-integer ip - anchor
			z: 0
			if ll = 0 [z: 1]
			nm: opt-matches st ip bend rep z
			if nm = 0 [
				ip: ip + 1
				continue
			]
			opt/1: ll-price st ll				;-- position 0: the literals before
			opt/3: 0
			opt/4: ll
			opt/5: rep/1
			opt/6: rep/2
			opt/7: rep/3
			k: nm << 1
			ml: mt/k
			done?: no
			either ml > suff [					;-- long enough: taken at once
				k: k - 1
				so: mt/k
				sm: ml
				sl: 0
				cur: 0
				last: ml
				done?: yes
			][
				pos: 1							;-- prices of the first matches
				while [pos < mml][
					e: opt + (pos << 3)
					e/1: ZSTD_MAX_PRICE
					e/3: 0
					e/4: ll + pos
					pos: pos + 1
				]
				w: ll-price st 0
				base: opt/1 + w
				i: 1
				while [i <= nm][
					k: i << 1
					ml: mt/k
					k: k - 1
					ob: mt/k
					op: off-price st ob
					while [pos <= ml][
						ZSTD_MLPRICE(w pos)
						e: opt + (pos << 3)
						e/1: base + op + w
						e/2: ob
						e/3: pos
						e/4: 0
						pos: pos + 1
					]
					i: i + 1
				]
				last: pos - 1
				e: opt + (pos << 3)
				e/1: ZSTD_MAX_PRICE
				cur: 0
				while [cur < last][				;-- each next position: one literal more, or matches from there
					cur: cur + 1
					e: opt + (cur << 3)
					e1: e - 8
					k: e1/4 + 1
					p: ip + cur - 1
					ZSTD_LITPRICE(w p/1)
					w2: ll-price st k
					price: e1/1 + w + w2
					w2: ll-price st k - 1
					price: price - w2
					if price <= e/1 [
						pm: e/1					;-- a match ending here, replaced
						pmo: e/2
						pmm: e/3
						pml: e/4
						e/1: price
						e/2: e1/2
						e/3: e1/3
						e/4: k
						e/5: e1/5
						e/6: e1/6
						e/7: e1/7
						if all [fr pml = 0 ip + cur < bend][	;-- that match and one literal: cheaper at the next position?
							w: ll-price st 1
							w2: ll-price st 0
							l1: w - w2
							if l1 < 0 [
								p: ip + cur
								ZSTD_LITPRICE(w p/1)
								pm: pm + w + l1
								w2: ll-price st k + 1
								price: price + w + w2
								w2: ll-price st k
								price: price - w2
								e2: e + 8
								if all [pm < price pm < e2/1][
									k: cur - pmm
									r0: opt + (k << 3)
									z: 0
									if r0/4 = 0 [z: 1]
									r0: r0 + 4
									r1: e2 + 4
									ZSTD_NEWREP(r1 r0 pmo z)
									e2/1: pm
									e2/2: pmo
									e2/3: pmm
									e2/4: 1
									if last <= cur [
										last: cur + 1
										e2: e2 + 8
										e2/1: ZSTD_MAX_PRICE
									]
								]
							]
						]
					]
					if e/4 = 0 [						;-- a match ends here: the repeat offsets after it
						k: cur - e/3
						r0: opt + (k << 3)
						z: 0
						if r0/4 = 0 [z: 1]
						r0: r0 + 4
						r1: e + 4
						ZSTD_NEWREP(r1 r0 e/2 z)
					]
					p: ip + cur
					if p > limit [continue]				;-- matches start 8 bytes before the end at least
					if cur = last [break]
					unless fr [
						e2: e + 8
						if e2/1 <= (e/1 + 128) [continue]	;-- the next position already cheaper: not searched
					]
					z: 0
					if e/4 = 0 [z: 1]
					r1: e + 4
					nm: opt-matches st p bend r1 z
					if nm = 0 [continue]
					k: nm << 1
					ml: mt/k
					if any [ml > suff cur + ml >= ZSTD_OPT_NUM p + ml >= bend][	;-- long enough: taken at once
						k: k - 1
						so: mt/k
						sm: ml
						sl: 0
						last: cur + ml
						done?: yes
						break
					]
					w: ll-price st 0
					base: e/1 + w
					start: mml
					i: 1
					while [i <= nm][
						k: i << 1
						ml: mt/k
						k: k - 1
						ob: mt/k
						op: off-price st ob
						mlen: ml
						while [mlen >= start][			;-- lengths down to the previous match's
							pos: cur + mlen
							ZSTD_MLPRICE(w mlen)
							price: base + op + w
							e2: opt + (pos << 3)
							either any [pos > last price < e2/1][
								while [last < pos][
									last: last + 1
									e1: opt + (last << 3)
									e1/1: ZSTD_MAX_PRICE
									e1/4: 1
								]
								e2/1: price
								e2/2: ob
								e2/3: mlen
								e2/4: 0
							][
								unless fr [break]		;-- shorter ones not tried
							]
							mlen: mlen - 1
						]
						start: ml + 1
						i: i + 1
					]
					e2: opt + (last + 1 << 3)
					e2/1: ZSTD_MAX_PRICE
				]
				unless done? [
					e: opt + (last << 3)
					sm: e/3
					so: e/2
					sl: e/4
					cur: last - sm
				]
			]
			if sm = 0 [							;-- no match on the path: literals only
				ip: ip + last
				continue
			]
			either sl = 0 [						;-- the repeat offsets after the last match
				e: opt + (cur << 3)
				z: 0
				if e/4 = 0 [z: 1]
				r0: e + 4
				ZSTD_NEWREP(rep r0 so z)
			][
				e: opt + (last << 3)
				rep/1: e/5
				rep/2: e/6
				rep/3: e/7
				cur: cur - sl
			]
			se: cur + 2							;-- the path's sequences, written backward into opt from se down to ss
			ss: se
			e: opt + (se << 3)
			if sl > 0 [							;-- literals after the last match
				e/3: 0
				e/4: sl
				ss: se - 1
				e: e - 8
			]
			e/2: so
			e/3: sm
			sp: cur
			forever [
				e1: opt + (sp << 3)
				e/4: e1/4						;-- literals before the match
				if e1/3 = 0 [break]
				ss: ss - 1
				e: e - 8
				e/2: e1/2
				e/3: e1/3
				sp: sp - e1/4 - e1/3
			]
			pos: ss
			while [pos <= se][
				e: opt + (pos << 3)
				ll: e/4
				mlen: e/3
				if mlen = 0 [					;-- literals only: the start of the next path
					ip: anchor + ll
					break
				]
				ob: e/2
				opt-count st anchor ll ob mlen
				ns: ns + 1
				sll/ns: ll
				sml/ns: mlen
				sof/ns: ob
				ZSTD_LITS((lits + nl) anchor ll bend)
				nl: nl + ll
				anchor: anchor + ll + mlen
				ip: anchor
				pos: pos + 1
			]
			opt-bases st
		]
		k: as-integer bend - anchor
		copy-memory lits + nl anchor k
		st/nlits: nl + k
		st/nseq: ns
		st/rep1: rep/1
		st/rep2: rep/2
		st/rep3: rep/3
	]

	fse-log: func [								;-- accuracy log for `n` symbols of values up to `maxv`
		maxlog	[integer!]
		n		[integer!]
		maxv	[integer!]
		return:	[integer!]
		/local
			tl k x [integer!]
	][
		tl: (log-b n - 1) - 2
		if tl > maxlog [tl: maxlog]
		k: (log-b n) + 1
		x: (log-b maxv) + 2
		if x < k [k: x]
		if k > tl [tl: k]
		if tl < 5 [tl: 5]
		tl
	]

	fse-norm: func [							;-- counts normalized to 1 << al, none below 1
		count	[int-ptr!]
		nsym	[integer!]
		total	[integer!]
		al		[integer!]
		norm	[int-ptr!]
		/local
			size low still s c p r k big bigp nz [integer!]
	][
		size: 1 << al
		low: total >> al
		still: size
		big: 1
		bigp: 0
		nz: 0
		s: 1
		while [s <= nsym][
			c: count/s
			p: 0
			if c > 0 [
				nz: nz + 1
				p: 1
				if c > low [
					r: c << al
					p: r / total
					r: r - (p * total)				;-- fraction left: small counts round up past a threshold
					if p < 8 [
						k: p + 1
						if (r << 10) > ((RTB/k >> 10) * total) [p: p + 1]
					]
				]
				if p > bigp [
					bigp: p
					big: s
				]
			]
			norm/s: p
			still: still - p
			s: s + 1
		]
		if (0 - still) < (bigp >> 1) [
			norm/big: norm/big + still
			exit
		]
		still: size - nz							;-- too many rounded up: one each, then shares of the rest
		k: 0
		bigp: 0
		s: 1
		while [s <= nsym][
			c: count/s
			p: 0
			if c > 0 [
				p: c * still / total + 1
				if p > bigp [
					bigp: p
					big: s
				]
			]
			norm/s: p
			k: k + p
			s: s + 1
		]
		norm/big: norm/big + size - k
	]

	put-ncount: func [							;-- table description of normalized counts
		norm	[int-ptr!]
		nsym	[integer!]
		al		[integer!]
		dst		[byte-ptr!]
		return:	[integer!]						;-- bytes written
		/local
			op		[byte-ptr!]
			prev0?	[logic!]
			bits cnt rem thr nb s c mx start [integer!]
	][
		op: dst
		bits: al - 5
		cnt: 4
		rem: (1 << al) + 1
		thr: 1 << al
		nb: al + 1
		s: 1
		prev0?: no
		while [all [s <= nsym rem > 1]][
			if prev0? [								;-- zero counts after a zero: repeat flags
				start: s
				while [norm/s = 0][s: s + 1]
				while [s >= (start + 24)][
					start: start + 24
					bits: FFFFh << cnt or bits
					op/1: as byte! bits
					op/2: as byte! bits >>> 8
					op: op + 2
					bits: bits >>> 16
				]
				while [s >= (start + 3)][
					start: start + 3
					bits: 3 << cnt or bits
					cnt: cnt + 2
				]
				bits: s - start << cnt or bits
				cnt: cnt + 2
				ZSTD_FLUSH16
			]
			c: norm/s
			s: s + 1
			mx: thr << 1 - 1 - rem
			either c < 0 [rem: rem + c][rem: rem - c]
			c: c + 1
			if c >= thr [c: c + mx]
			bits: c << cnt or bits
			cnt: cnt + nb
			if c < mx [cnt: cnt - 1]
			prev0?: c = 1
			while [rem < thr][
				nb: nb - 1
				thr: thr >> 1
			]
			ZSTD_FLUSH16
		]
		while [cnt > 0][
			op/1: as byte! bits
			op: op + 1
			bits: bits >>> 8
			cnt: cnt - 8
		]
		as-integer op - dst
	]

	fse-ctable: func [							;-- encoding table of normalized counts
		norm	[int-ptr!]
		nsym	[integer!]
		al		[integer!]
		stab	[int-ptr!]						;-- next states, by symbol then sub-state
		tt		[int-ptr!]						;-- 2 per symbol: bit count delta, state delta
		cells	[int-ptr!]						;-- scratch: 1 << al
		/local
			pos		[int-ptr!]
			size total s i k x mb [integer!]
	][
		fse-spread cells norm nsym al
		size: 1 << al
		pos: system/stack/allocate 64				;-- first sub-state of each symbol
		total: 0
		s: 1
		while [s <= nsym][
			x: norm/s
			i: s * 2 - 1
			k: i + 1
			pos/s: total
			case [
				x = 0 [
					tt/i: al + 1 << 16 - size
					tt/k: 0
				]
				x <= 1 [							;-- 1 or "less than one"
					tt/i: al << 16 - size
					tt/k: total - 1
					total: total + 1
				]
				true [
					mb: al - log-b x - 1
					tt/i: mb << 16 - (x << mb)
					tt/k: total - x
					total: total + x
				]
			]
			s: s + 1
		]
		k: 1
		while [k <= size][
			s: cells/k + 1
			i: pos/s + 1
			pos/s: i
			stab/i: size + k - 1
			k: k + 1
		]
	]

	seq-mode: func [							;-- mode of a sequence field, its table written at `dst`
		codes	[byte-ptr!]
		ns		[integer!]
		dnorm	[int-ptr!]						;-- predefined distribution
		dnsym	[integer!]
		dal		[integer!]
		maxlog	[integer!]
		f		[integer!]						;-- field: 0 LL, 1 OF, 2 ML
		st		[ZSTD-ENC!]
		dst		[byte-ptr!]
		room	[integer!]
		info	[int-ptr!]						;-- out: mode, bytes written
		return:	[logic!]						;-- false: no room
		/local
			count stab tt logs [int-ptr!]
			p e		[byte-ptr!]
			i k mx last mode n tl [integer!]
	][
		count: st/freq
		set-memory as byte-ptr! count null-byte 256
		p: codes
		e: codes + ns
		while [p < e][
			k: 1 + as integer! p/1
			count/k: count/k + 1
			p: p + 1
		]
		mx: 0
		last: 0
		i: 1
		while [i <= 64][
			if count/i > 0 [
				last: i
				if count/i > mx [mx: count/i]
			]
			i: i + 1
		]
		stab: st/stab + (f * 512)
		tt: st/tt + (f * 128)
		logs: st/logs + f
		n: 0
		either mx = ns [							;-- choices of zstd's level 3
			mode: 1
			if ns <= 2 [mode: 0]
		][
			mode: 2
			if any [ns < (1 << dal) mx < (ns >> (dal - 1))][mode: 0]
		]
		switch mode [
			0 [
				fse-ctable dnorm dnsym dal stab tt st/cells
				logs/1: dal
			]
			1 [
				if room < 1 [return false]
				dst/1: as byte! last - 1
				n: 1
				stab/1: 0							;-- one state, no bits
				k: last * 2 - 1
				tt/k: 0
				k: k + 1
				tt/k: 0
				logs/1: 0
			]
			default [
				if room < 128 [return false]
				tl: fse-log maxlog ns last - 1
				fse-norm count last ns tl st/norm
				n: put-ncount st/norm last tl dst
				fse-ctable st/norm last tl stab tt st/cells
				logs/1: tl
			]
		]
		info/1: mode
		info/2: n
		true
	]

	#define ZSTD_EXTRAS(_k) [						;-- extra bits of sequence _k: literal length, match length, offset
		c: 1 + as integer! cll/_k
		nb: as integer! LL-BITS/c
		v: sll/_k - LL-BASE/c
		ZSTD_PUT(v nb)
		ZSTD_FLUSHW(lim)
		c: 1 + as integer! cml/_k
		nb: as integer! ML-BITS/c
		v: sml/_k - ML-BASE/c
		ZSTD_PUT(v nb)
		ZSTD_FLUSHW(lim)
		nb: as integer! cof/_k
		v: sof/_k - (1 << nb)
		ZSTD_PUT(v nb)
		ZSTD_FLUSHW(lim)
	]

	put-seqs: func [							;-- sequences section, -1: more than `room` bytes
		st		[ZSTD-ENC!]
		dst		[byte-ptr!]
		room	[integer!]
		return:	[integer!]
		/local
			op lim mp cll cml cof [byte-ptr!]
			sll sml sof info stl sto stm ttl tto ttm logs fw4 [int-ptr!]
			ns k c c2 v nb k2 xl xo xm bits cnt modes fwk [integer!]
	][
		ns: st/nseq
		op: dst
		lim: dst + room
		if room < 4 [return -1]
		case [
			ns < 128 [
				op/1: as byte! ns
				op: op + 1
			]
			ns < 7F00h [
				op/1: as byte! ns >> 8 + 128
				op/2: as byte! ns
				op: op + 2
			]
			true [
				op/1: as byte! 255
				k: ns - 7F00h
				op/2: as byte! k
				op/3: as byte! k >> 8
				op: op + 3
			]
		]
		if ns = 0 [return as-integer op - dst]
		sll: st/sll
		sml: st/sml
		sof: st/sof
		cll: st/cll
		cml: st/cml
		cof: st/cof
		k: 1
		while [k <= ns][							;-- codes
			v: sll/k
			either v < 64 [
				c: v + 1
				cll/k: LL-CODE/c
			][
				cll/k: as byte! (log-b v) + 19
			]
			v: sml/k - 3
			either v < 128 [
				c: v + 1
				cml/k: ML-CODE/c
			][
				cml/k: as byte! (log-b v) + 36
			]
			cof/k: as byte! log-b sof/k
			k: k + 1
		]
		mp: op
		op: op + 1
		info: system/stack/allocate 2
		unless seq-mode cll ns LL-NORM 36 6 9 0 st op as-integer lim - op info [return -1]
		modes: info/1 << 6
		op: op + info/2
		unless seq-mode cof ns OF-NORM 29 5 8 1 st op as-integer lim - op info [return -1]
		modes: info/1 << 4 or modes
		op: op + info/2
		unless seq-mode cml ns ML-NORM 53 6 9 2 st op as-integer lim - op info [return -1]
		modes: info/1 << 2 or modes
		op: op + info/2
		mp/1: as byte! modes
		stl: st/stab								;-- bit stream: sequences last to first
		sto: stl + 512
		stm: sto + 512
		ttl: st/tt
		tto: ttl + 128
		ttm: tto + 128
		logs: st/logs
		bits: 0
		cnt: 0
		k: ns
		c: as integer! cml/k
		ZSTD_ESTART(xm stm ttm c)
		c: as integer! cof/k
		ZSTD_ESTART(xo sto tto c)
		c: as integer! cll/k
		ZSTD_ESTART(xl stl ttl c)
		forever [
			ZSTD_EXTRAS(k)
			k: k - 1
			if k = 0 [break]
			if (as-integer lim - op) < 16 [return -1]
			c: as integer! cof/k
			ZSTD_ESYM(xo sto tto c)
			c: as integer! cml/k
			ZSTD_ESYM(xm stm ttm c)
			ZSTD_FLUSHW(lim)
			c: as integer! cll/k
			ZSTD_ESYM(xl stl ttl c)
			ZSTD_FLUSHW(lim)
		]
		if (as-integer lim - op) < 8 [return -1]
		nb: logs/3									;-- final states
		v: (1 << nb) - 1 and xm
		ZSTD_PUT(v nb)
		nb: logs/2
		v: (1 << nb) - 1 and xo
		ZSTD_PUT(v nb)
		ZSTD_FLUSH
		nb: logs/1
		v: (1 << nb) - 1 and xl
		ZSTD_PUT(v nb)
		ZSTD_CLOSE
		as-integer op - dst
	]

	put-weights: func [							;-- Huffman tree description: weights of symbols 0..n-1
		dst		[byte-ptr!]
		w		[byte-ptr!]
		n		[integer!]
		st		[ZSTD-ENC!]
		return:	[integer!]						;-- bytes written, 0: no description fits
		/local
			count stab tt xs [int-ptr!]
			op		[byte-ptr!]
			i j k mx last tl bits cnt v nb c2 k2 sz [integer!]
	][
		sz: 0
		count: st/tmp
		set-memory as byte-ptr! count null-byte 64
		i: 1
		while [i <= n][
			k: 1 + as integer! w/i
			count/k: count/k + 1
			i: i + 1
		]
		mx: 0
		last: 0
		i: 1
		while [i <= 13][
			if count/i > 0 [
				last: i
				if count/i > mx [mx: count/i]
			]
			i: i + 1
		]
		if all [n > 2 mx > 1 mx < n][				;-- FSE-coded weights, two states
			tl: fse-log 6 n last - 1
			fse-norm count last n tl st/norm
			k: put-ncount st/norm last tl dst + 1
			stab: st/stab
			tt: st/tt
			fse-ctable st/norm last tl stab tt st/cells
			op: dst + 1 + k
			bits: 0
			cnt: 0
			xs: system/stack/allocate 2				;-- states of the odd and even positions
			i: n
			while [i >= 1][							;-- from the end, the last two set the states
				j: 2 - (i and 1)
				k: as integer! w/i
				either i >= (n - 1) [
					ZSTD_ESTART(xs/j stab tt k)
				][
					ZSTD_ESYM(xs/j stab tt k)
					ZSTD_FLUSH
				]
				i: i - 1
			]
			v: (1 << tl) - 1 and xs/2
			ZSTD_PUT(v tl)
			v: (1 << tl) - 1 and xs/1
			ZSTD_PUT(v tl)
			ZSTD_CLOSE
			sz: as-integer op - dst - 1
			if sz >= (n >> 1) [sz: 0]
		]
		if sz > 0 [
			dst/1: as byte! sz
			return sz + 1
		]
		if n > 128 [return 0]
		dst/1: as byte! 127 + n						;-- 4-bit weights
		i: 1
		while [i <= n][
			k: i + 1 >> 1 + 1
			v: (as integer! w/i) << 4
			if i < n [
				c2: i + 1
				v: v or as integer! w/c2
			]
			dst/k: as byte! v
			i: i + 2
		]
		n + 1 >> 1 + 1
	]

	huf-put: func [								;-- one Huffman stream, literals written last to first
		dst		[byte-ptr!]
		src		[byte-ptr!]
		n		[integer!]
		codes	[int-ptr!]						;-- code << 8 or length
		return:	[integer!]						;-- bytes written
		/local
			op p	[byte-ptr!]
			bits cnt k c v [integer!]
	][
		op: dst
		bits: 0
		cnt: 0
		p: src + n
		while [p > src][
			p: p - 1
			k: 1 + as integer! p/1
			c: codes/k
			v: c >>> 8
			k: c and FFh
			ZSTD_PUT(v k)
			if p > src [							;-- two codes per flush: 11 bits at most each
				p: p - 1
				k: 1 + as integer! p/1
				c: codes/k
				v: c >>> 8
				k: c and FFh
				ZSTD_PUT(v k)
			]
			ZSTD_FLUSH
		]
		ZSTD_CLOSE
		as-integer op - dst
	]

	put-raw: func [								;-- raw or RLE literals section
		dst		[byte-ptr!]
		lits	[byte-ptr!]
		n		[integer!]
		rle?	[logic!]
		room	[integer!]
		return:	[integer!]						;-- bytes written, -1: no room
		/local
			hs t sz k [integer!]
	][
		hs: 1
		if n > 31 [hs: 2]
		if n > 4095 [hs: 3]
		t: as integer! rle?
		sz: hs + n
		if rle? [sz: hs + 1]
		if sz > room [return -1]
		switch hs [
			1 [dst/1: as byte! n << 3 or t]
			2 [
				k: n << 4 or 4 or t
				dst/1: as byte! k
				dst/2: as byte! k >> 8
			]
			default [
				k: n << 4 or 12 or t
				dst/1: as byte! k
				dst/2: as byte! k >> 8
				dst/3: as byte! k >> 16
			]
		]
		either rle? [
			k: hs + 1
			dst/k: lits/1
		][
			copy-memory dst + hs lits n
		]
		sz
	]

	put-lits: func [							;-- literals section, -1: more than `room` bytes
		st		[ZSTD-ENC!]
		dst		[byte-ptr!]
		room	[integer!]
		return:	[integer!]
		/local
			freq codes rank [int-ptr!]
			lens w p e lits q [byte-ptr!]
			n i k x mx maxsym tl mb hc t bits sz seg s1 s2 s3 s4 pos [integer!]
	][
		n: st/nlits
		lits: st/lits
		if n < 64 [return put-raw dst lits n no room]
		freq: st/freq
		set-memory as byte-ptr! freq null-byte 1024
		p: lits
		e: lits + n
		while [p < e][
			k: 1 + as integer! p/1
			freq/k: freq/k + 1
			p: p + 1
		]
		maxsym: 256
		while [freq/maxsym = 0][maxsym: maxsym - 1]
		mx: 0
		i: 1
		while [i <= maxsym][
			if freq/i > mx [mx: freq/i]
			i: i + 1
		]
		if mx = n [return put-raw dst lits n yes room]
		hc: 3										;-- compressed literals header
		if n >= 1024 [hc: 4]
		if n >= 16384 [hc: 5]
		if all [mx > (n >> 7 + 4) room > (hc + 140)][	;-- else too flat to be worth coding
			tl: (log-b n - 1) - 1					;-- longest code, as zstd's
			if tl > 11 [tl: 11]
			k: (log-b n) + 1
			x: (log-b maxsym - 1) + 2
			if x < k [k: x]
			if k > tl [tl: k]
			lens: st/hlens
			deflate/build-tree freq lens maxsym tl st/tmp
			mb: 0
			i: 1
			while [i <= maxsym][
				x: as integer! lens/i
				if x > mb [mb: x]
				i: i + 1
			]
			w: lens + 256							;-- weights
			rank: system/stack/allocate 16
			set-memory as byte-ptr! rank null-byte 64
			bits: 0
			i: 1
			while [i <= maxsym][
				x: as integer! lens/i
				either x > 0 [
					bits: freq/i * x + bits
					x: mb + 1 - x
					k: x + 1
					rank/k: rank/k + 1
				][
					x: 0
				]
				w/i: as byte! x
				i: i + 1
			]
			t: put-weights dst + hc w maxsym - 1 st
			sz: bits >> 3 + 1 + t
			if n >= 256 [sz: sz + 9]
			if all [t > 0 sz < (n - (n >> 6) - 2) sz + hc <= room][
				pos: 0								;-- codes: weights in increasing order, then symbols
				x: 1
				while [x <= mb][
					k: x + 1
					i: rank/k
					rank/k: pos
					pos: i << (x - 1) + pos
					x: x + 1
				]
				codes: st/hcodes
				i: 1
				while [i <= maxsym][
					x: as integer! w/i
					if x > 0 [
						k: x + 1
						pos: rank/k
						rank/k: 1 << (x - 1) + pos
						codes/i: pos >> (x - 1) << 8 or (mb + 1 - x)
					]
					i: i + 1
				]
				q: dst + hc + t
				either n < 256 [
					k: huf-put q lits n codes
				][
					seg: n + 3 >> 2
					s1: huf-put q + 6 lits seg codes
					s2: huf-put q + 6 + s1 lits + seg seg codes
					s3: huf-put q + 6 + s1 + s2 lits + (seg * 2) seg codes
					s4: huf-put q + 6 + s1 + s2 + s3 lits + (seg * 3) n - (seg * 3) codes
					q/1: as byte! s1
					q/2: as byte! s1 >> 8
					q/3: as byte! s2
					q/4: as byte! s2 >> 8
					q/5: as byte! s3
					q/6: as byte! s3 >> 8
					k: s1 + s2 + s3 + s4 + 6
				]
				k: k + t							;-- compressed size
				switch hc [
					3 [
						x: either n < 256 [0][4]	;-- one stream or four
						x: k << 14 or (n << 4) or x or 2
						dst/1: as byte! x
						dst/2: as byte! x >> 8
						dst/3: as byte! x >> 16
					]
					4 [
						x: k << 18 or (n << 4) or 10
						dst/1: as byte! x
						dst/2: as byte! x >> 8
						dst/3: as byte! x >> 16
						dst/4: as byte! x >>> 24
					]
					default [
						x: k << 22 or (n << 4) or 14
						dst/1: as byte! x
						dst/2: as byte! x >> 8
						dst/3: as byte! x >> 16
						dst/4: as byte! x >>> 24
						dst/5: as byte! k >> 10
					]
				]
				return hc + k
			]
		]
		put-raw dst lits n no room
	]

	put-part: func [							;-- the sequences and literals in st as one block of `n` bytes at `src`: compressed, RLE or raw
		st		[ZSTD-ENC!]
		src		[byte-ptr!]
		n		[integer!]
		last	[integer!]						;-- 1: last block
		dst		[byte-ptr!]
		r1		[integer!]						;-- repeat offsets before them, the decoder's if the block is not compressed
		r2		[integer!]
		r3		[integer!]
		return:	[byte-ptr!]						;-- position after the block
		/local
			p e		[byte-ptr!]
			room k csize b [integer!]
	][
		csize: -1
		room: n - (n >> 6) - 3						;-- compressed size worth it, at most
		if room > 1 [
			k: put-lits st dst + 3 room - 1
			if k > 0 [
				csize: put-seqs st dst + 3 + k room - k
				if csize >= 0 [csize: csize + k]
			]
		]
		p: src
		e: src + n
		if all [csize < 25 n > 0][					;-- one byte value: RLE block
			while [all [p < e p/1 = src/1]][p: p + 1]
		]
		either all [p = e n > 0][
			b: n << 3 or 2 or last
			dst/4: src/1
			csize: 1
			st/rep1: r1								;-- no sequences seen by the decoder
			st/rep2: r2
			st/rep3: r3
		][
			either csize > 0 [
				b: csize << 3 or 4 or last
			][
				b: n << 3 or last
				copy-memory dst + 3 src n
				csize: n
				st/rep1: r1
				st/rep2: r2
				st/rep3: r3
			]
		]
		dst/1: as byte! b
		dst/2: as byte! b >> 8
		dst/3: as byte! b >> 16
		dst + 3 + csize
	]

	seq-view: func [							;-- st's sequences and literals: those of sequences a to b - 1 of the block in v (b = all: its last literals too)
		st		[ZSTD-ENC!]
		v		[ZSTD-SEQS!]
		a		[integer!]
		b		[integer!]
		len		[int-ptr!]						;-- out: their size in bytes
		return:	[byte-ptr!]						;-- their first byte
		/local
			sll sml	[int-ptr!]
			i lo mo l2 m2 [integer!]
	][
		sll: v/sll
		sml: v/sml
		lo: 0										;-- literals and match bytes before sequence a, then before b
		mo: 0
		i: 1
		while [i <= a][
			lo: lo + sll/i
			mo: mo + sml/i
			i: i + 1
		]
		l2: lo
		m2: mo
		while [i <= b][
			l2: l2 + sll/i
			m2: m2 + sml/i
			i: i + 1
		]
		if b = v/nseq [l2: v/nlits]
		st/sll: sll + a
		st/sml: sml + a
		st/sof: v/sof + a
		st/cll: v/cll + a
		st/cml: v/cml + a
		st/cof: v/cof + a
		st/lits: v/lits + lo
		st/nlits: l2 - lo
		st/nseq: b - a
		len/value: l2 - lo + m2 - mo
		v/src + lo + mo
	]

	part-size: func [							;-- size of the block put-part writes at dst for sequences a to b - 1
		st		[ZSTD-ENC!]
		v		[ZSTD-SEQS!]
		a		[integer!]
		b		[integer!]
		dst		[byte-ptr!]
		return:	[integer!]
		/local
			p e		[byte-ptr!]
			len		[integer!]
	][
		len: 0
		p: seq-view st v a b :len
		e: put-part st p len 0 dst st/rep1 st/rep2 st/rep3
		as-integer e - dst
	]

	split-seqs: func [							;-- where sequences a to b - 1 (a block of `full` bytes) are smaller in halves, as zstd's splitter cuts them
		st		[ZSTD-ENC!]
		v		[ZSTD-SEQS!]
		a		[integer!]
		b		[integer!]
		full	[integer!]
		dst		[byte-ptr!]						;-- scratch output
		parts	[int-ptr!]						;-- out: split points, in order
		np		[int-ptr!]						;-- their count
		/local
			mid s1 s2 k [integer!]
	][
		if any [b - a < 300 np/value >= ZSTD_SPLITS][exit]
		mid: a + b / 2
		s1: part-size st v a mid dst
		s2: part-size st v mid b dst
		if s1 + s2 < full [
			split-seqs st v a mid s1 dst parts np
			if np/value < ZSTD_SPLITS [				;-- the first half may have used the last ones
				k: np/value + 1
				np/value: k
				parts/k: mid
				split-seqs st v mid b s2 dst parts np
			]
		]
	]

	fix-reps: func [							;-- offset values of st's sequences into `o`: a repeat code an offset where the decoder's repeat offsets (st) differ from the encoder's (c)
		st		[ZSTD-ENC!]
		c		[int-ptr!]						;-- the encoder's repeat offsets
		o		[int-ptr!]
		/local
			d sll sof [int-ptr!]
			i z k ob od oc rc ro [integer!]
	][
		d: system/stack/allocate 3
		d/1: st/rep1
		d/2: st/rep2
		d/3: st/rep3
		sll: st/sll
		sof: st/sof
		i: 1
		while [i <= st/nseq][
			ob: sof/i
			z: 0
			if sll/i = 0 [z: 1]
			o/i: ob
			if ob <= 3 [
				rc: ob - 1 + z
				either rc = 3 [
					od: d/1 - 1
					oc: c/1 - 1
				][
					rc: rc + 1
					od: d/rc
					oc: c/rc
				]
				if od <> oc [o/i: oc + 3]
			]
			k: o/i
			ZSTD_NEWREP(d d k z)
			ZSTD_NEWREP(c c ob z)
			i: i + 1
		]
		st/rep1: d/1
		st/rep2: d/2
		st/rep3: d/3
	]

	split-block: func [							;-- the block's sequences cut where the parts are smaller, one block each (zstd's block splitter)
		st		[ZSTD-ENC!]
		src		[byte-ptr!]
		n		[integer!]
		last	[integer!]						;-- 1: last block
		dst		[byte-ptr!]
		r1		[integer!]						;-- repeat offsets before the block
		r2		[integer!]
		r3		[integer!]
		return:	[byte-ptr!]						;-- position after the blocks
		/local
			v		[ZSTD-SEQS! value]
			parts c	[int-ptr!]
			p q		[byte-ptr!]
			np i a b len full lb e1 e2 e3 d1 d2 d3 [integer!]
	][
		v/sll: st/sll
		v/sml: st/sml
		v/sof: st/sof
		v/cll: st/cll
		v/cml: st/cml
		v/cof: st/cof
		v/lits: st/lits
		v/nlits: st/nlits
		v/nseq: st/nseq
		v/src: src
		e1: st/rep1									;-- the encoder's repeat offsets after the block
		e2: st/rep2
		e3: st/rep3
		parts: system/stack/allocate ZSTD_SPLITS + 1		;-- and the block's end
		np: 0
		full: part-size st v 0 v/nseq dst
		split-seqs st v 0 v/nseq full dst parts :np
		q: null
		if np > 0 [
			np: np + 1
			parts/np: v/nseq
			c: system/stack/allocate 3
			c/1: r1
			c/2: r2
			c/3: r3
			st/rep1: r1								;-- the decoder's, in st
			st/rep2: r2
			st/rep3: r3
			q: dst
			a: 0
			len: 0
			i: 1
			while [i <= np][
				b: parts/i
				p: seq-view st v a b :len
				if (as-integer q - dst) + len > n [	;-- a raw part would pass the block's room: one block instead
					q: null
					break
				]
				d1: st/rep1
				d2: st/rep2
				d3: st/rep3
				fix-reps st c st/sof2
				st/sof: st/sof2
				lb: 0
				if i = np [lb: last]
				q: put-part st p len lb q d1 d2 d3
				a: b
				i: i + 1
			]
		]
		st/sll: v/sll
		st/sml: v/sml
		st/sof: v/sof
		st/cll: v/cll
		st/cml: v/cml
		st/cof: v/cof
		st/lits: v/lits
		st/nlits: v/nlits
		st/nseq: v/nseq
		if null? q [
			st/rep1: e1
			st/rep2: e2
			st/rep3: e3
			q: put-part st src n last dst r1 r2 r3
		]
		q
	]

	put-block: func [							;-- one block, or several where zstd's splitter finds them smaller
		st		[ZSTD-ENC!]
		src		[byte-ptr!]
		n		[integer!]
		last	[integer!]						;-- 1: last block
		dst		[byte-ptr!]
		return:	[byte-ptr!]						;-- position after the block
		/local
			r1 r2 r3 [integer!]
	][
		r1: st/rep1
		r2: st/rep2
		r3: st/rep3
		if n - (n >> 6) - 3 > 1 [					;-- else not worth compressing
			case [
				st/depth < 0 [match-block st src src + n]
				st/parser = 0 [chain-block st src src + n]
				true [
					if all [st/parser = 3 st/llsum = 0 n > 8][	;-- first block: parsed twice, the first time for statistics
						opt-block st src src + n
						set-memory as byte-ptr! st/long null-byte 4 << (32 - st/lsh)
						if st/h3sh > 0 [set-memory as byte-ptr! st/h3 null-byte 4 << (32 - st/h3sh)]
						st/ins: 0
						st/ins3: 0
						st/rep1: r1
						st/rep2: r2
						st/rep3: r3
					]
					opt-block st src src + n
				]
			]
			if all [st/split? st/nseq >= 300][return split-block st src n last dst r1 r2 r3]
		]
		put-part st src n last dst r1 r2 r3
	]

	compress: func [
		out			[byte-ptr!]
		out-size	[int-ptr!]
		in			[byte-ptr!]
		in-size		[integer!]
		level		[integer!]						;-- 1 to 19, -1: 3
		return:		[integer!]
		/local
			st		[ZSTD-ENC! value]
			work heap q [int-ptr!]
			op p e lv [byte-ptr!]
			n k lg sg bs ns w x h3 h3n [integer!]
	][
		n: in-size
		k: n + ZSTD_BLOCK_MAX - 1 / ZSTD_BLOCK_MAX
		if k = 0 [k: 1]
		k: k * 3 + n + 10							;-- largest frame: raw blocks
		if any [null? out out-size/value < k][
			out-size/value: k
			return ZSTD-NO-MEM
		]
		if level < 1 [level: 3]
		k: 0										;-- zstd's settings of the level for this input size
		if n <= 262144 [k: 1]
		if n <= 131072 [k: 2]
		if n <= 16384 [k: 3]
		lv: ZSTD-LEVELS + (k * 19 + level - 1 * 7)
		w: as integer! lv/1
		sg: as integer! lv/2
		lg: as integer! lv/3
		st/attempts: 1 << as integer! lv/4
		k: as integer! lv/5
		st/mml: 4									;-- more only in the hashes
		if k < 4 [
			st/mml: 3
			k: 4									;-- hashes of 4 bytes at least
		]
		st/m5: (1 << (k - 4 * 8)) - 1
		k: as integer! lv/6							;-- matcher
		st/depth: k - 1
		st/tree?: k >= 4
		st/parser: 0
		if st/tree? [
			st/depth: 2
			st/parser: k - 4
		]
		st/suff: (as integer! lv/7) << 2
		k: 6										;-- tables sized to the input
		if n > 64 [k: (log-b n - 1) + 1]
		h3: 0
		st/split?: no
		either st/tree? [							;-- as zstd's: hash and tree logs up to the window's + 1
			if k > w [k: w]
			if lg > (k + 1) [lg: k + 1]
			if sg > (k + 1) [sg: k + 1]
			if all [st/parser > 0 st/mml = 3][
				h3: 17
				if h3 > k [h3: k]
			]
			st/split?: all [st/parser > 0 k >= 17]	;-- as zstd: optimal parsing, windows of 128 KB at least
		][
			if lg > k [lg: k]
			either st/depth < 0 [
				if sg > (k - 1) [sg: k - 1]			;-- two tables half zstd's size: as good for small inputs
			][
				if sg > k [sg: k]
				if sg > w [sg: w]
			]
		]
		st/window: 1 << w
		st/cmask: (1 << sg) - 1
		st/bmask: (1 << (sg - 1)) - 1
		st/ins: 0
		st/ins3: 0
		st/skip?: no
		bs: n
		if bs > ZSTD_BLOCK_MAX [bs: ZSTD_BLOCK_MAX]
		ns: bs >> 2 + 2								;-- sequences of a block, at most
		if st/mml < 4 [ns: bs / 3 + 2]
		x: 0										;-- tree, optimal parser: matches, positions, statistics
		if st/tree? [x: st/attempts + 4 << 1]
		if st/parser > 0 [x: ZSTD_OPT_NUM + 3 << 3 + 377 + x]
		if st/split? [x: x + ns]
		h3n: 0
		if h3 > 0 [h3n: 1 << h3]
		k: (1 << lg) + (1 << sg) + h3n + (ns * 3) + 3524 + x << 2 + (ns * 3) + bs + 512
		heap: null
		#either red-pass? = yes [
			either k <= 32768 [						;-- small inputs: on the native stack
				work: system/stack/allocate k >> 2 + 1
				set-memory as byte-ptr! work null-byte (1 << lg) + (1 << sg) + h3n << 2	;-- empty hash tables
			][
				work: allocate-virtual k no			;-- zeroed: empty hash tables
				heap: work
			]
		][
			work: as int-ptr! allocate k			;-- Red/System program: on the heap, its host can commit the stack page by page (Rebol2: 4 KB)
			set-memory as byte-ptr! work null-byte k
			heap: work
		]
		st/in: in
		st/long: work
		st/short: work + (1 << lg)
		st/h3: st/short + (1 << sg)
		st/h3sh: 0
		if h3 > 0 [st/h3sh: 32 - h3]
		st/lsh: 32 - lg
		st/ssh: 32 - sg
		st/sll: st/h3 + h3n
		st/sml: st/sll + ns
		st/sof: st/sml + ns
		st/freq: st/sof + ns
		st/hcodes: st/freq + 256
		st/tmp: st/hcodes + 256
		st/norm: st/tmp + 512
		st/cells: st/norm + 64
		st/stab: st/cells + 512
		st/tt: st/stab + 1536
		st/logs: st/tt + 384
		q: st/logs + 4
		st/mt: q
		if st/tree? [q: q + (st/attempts + 4 << 1)]
		st/opt: q
		if st/parser > 0 [
			st/lf: q + (ZSTD_OPT_NUM + 3 << 3)
			st/llf: st/lf + 256
			st/mlf: st/llf + 36
			st/ofq: st/mlf + 53
			q: st/ofq + 32
		]
		st/sof2: q
		if st/split? [q: q + ns]
		st/cll: as byte-ptr! q
		st/cml: st/cll + ns
		st/cof: st/cml + ns
		st/lits: st/cof + ns
		st/hlens: st/lits + bs
		st/rep1: 1
		st/rep2: 4
		st/rep3: 8
		st/llsum: 0

		op: out										;-- frame header: content size
		op/1: #"^(28)"
		op/2: #"^(B5)"
		op/3: #"^(2F)"
		op/4: #"^(FD)"
		either n <= st/window [					;-- single segment: the window is the content
			case [
				n < 256 [
					op/5: #"^(20)"
					op/6: as byte! n
					op: op + 6
				]
				n < 65792 [
					op/5: #"^(60)"
					k: n - 256
					op/6: as byte! k
					op/7: as byte! k >> 8
					op: op + 7
				]
				true [
					op/5: #"^(A0)"
					op: op + 5
				]
			]
		][
			op/5: #"^(80)"
			op/6: as byte! w - 10 << 3				;-- window of the level
			op: op + 6
		]
		if n >= 65792 [
			op/1: as byte! n
			op/2: as byte! n >> 8
			op/3: as byte! n >> 16
			op/4: as byte! n >>> 24
			op: op + 4
		]
		p: in
		e: in + n
		until [										;-- blocks
			k: as-integer e - p
			if k > ZSTD_BLOCK_MAX [k: ZSTD_BLOCK_MAX]
			op: put-block st p k as integer! p + k = e op
			p: p + k
			p = e
		]
		unless null? heap [
			#either red-pass? = yes [free-virtual heap][free as byte-ptr! heap]
		]
		out-size/value: as-integer op - out
		ZSTD-OK
	]
]
