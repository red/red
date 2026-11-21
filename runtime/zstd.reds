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
		Encoding: one frame with its content size, no checksum; blocks matched as zstd's level 3 does.
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

	;-- encoder

	#define ZSTD_WINDOW			200000h				;-- farthest match: 2 MB
	#define ZSTD_PRIME1			9E3779B1h
	#define ZSTD_PRIME2			85EBCA77h

	ZSTD-ENC!: alias struct! [
		in			[byte-ptr!]						;-- input
		long		[int-ptr!]						;-- hash tables: position + 1 of the last 8 and 5 bytes seen
		short		[int-ptr!]
		lsh			[integer!]						;-- 32 - their log sizes
		ssh			[integer!]
		m5			[integer!]						;-- FFh: short hash of 5 bytes, 0: of 4
		rep1		[integer!]						;-- repeat offsets, as the decoder will have them
		rep2		[integer!]
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

	match-block: func [							;-- sequences and literals of a block, matched as zstd's level 3
		st		[ZSTD-ENC!]
		bstart	[byte-ptr!]
		bend	[byte-ptr!]
		/local
			in ip anchor m limit lits q q4 ld ls le [byte-ptr!]
			i4 long short sll sml sof s4 d4 [int-ptr!]
			cur cl cs hl hs len dist rep1 rep2 ns nl a b c t k lsh ssh m5 [integer!]
	][
		in: st/in
		long: st/long
		short: st/short
		lsh: st/lsh
		ssh: st/ssh
		m5: st/m5
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
			if all [len = 0 cl > 0 cur - cl < ZSTD_WINDOW][	;-- the same 8 bytes before
				m: in + cl - 1
				ZSTD_GET32(c m)
				q: m + 4
				ZSTD_GET32(k q)
				if all [c = a k = b][
					len: (match-len ip + 8 m + 8 bend) + 8
					dist: cur - cl + 1
				]
			]
			if all [len = 0 cs > 0 cur - cs < ZSTD_WINDOW][	;-- the same 5 bytes before
				m: in + cs - 1
				ZSTD_GET32(c m)
				if c = a [
					dist: cur - cs + 1
					q: ip + 1						;-- the same 8 bytes before, one byte further
					ZSTD_HASH(q)
					cl: long/hl
					long/hl: cur + 2
					if all [cl > 0 cur + 1 - cl < ZSTD_WINDOW][
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

	put-block: func [							;-- one block: compressed, RLE or raw
		st		[ZSTD-ENC!]
		src		[byte-ptr!]
		n		[integer!]
		last	[integer!]						;-- 1: last block
		dst		[byte-ptr!]
		return:	[byte-ptr!]						;-- position after the block
		/local
			p e		[byte-ptr!]
			r1 r2 room k csize b [integer!]
	][
		r1: st/rep1
		r2: st/rep2
		csize: -1
		room: n - (n >> 6) - 3						;-- compressed size worth it, at most
		if room > 1 [
			match-block st src src + n
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
		][
			either csize > 0 [
				b: csize << 3 or 4 or last
			][
				b: n << 3 or last
				copy-memory dst + 3 src n
				csize: n
				st/rep1: r1
				st/rep2: r2
			]
		]
		dst/1: as byte! b
		dst/2: as byte! b >> 8
		dst/3: as byte! b >> 16
		dst + 3 + csize
	]

	compress: func [
		out			[byte-ptr!]
		out-size	[int-ptr!]
		in			[byte-ptr!]
		in-size		[integer!]
		return:		[integer!]
		/local
			st		[ZSTD-ENC! value]
			work heap [int-ptr!]
			op p e	[byte-ptr!]
			n k lg sg bs ns [integer!]
	][
		n: in-size
		k: n + ZSTD_BLOCK_MAX - 1 / ZSTD_BLOCK_MAX
		if k = 0 [k: 1]
		k: k * 3 + n + 10							;-- largest frame: raw blocks
		if any [null? out out-size/value < k][
			out-size/value: k
			return ZSTD-NO-MEM
		]
		k: 6										;-- hash tables and match length: zstd's level 3 for this size
		if n > 64 [k: (log-b n - 1) + 1]
		lg: 17
		sg: 16
		st/m5: FFh
		case [
			n <= 16384 [
				lg: 15
				sg: 14
				st/m5: 0
			]
			n <= 131072 [
				lg: 16
				sg: 15
			]
			n <= 262144 [
				lg: 16
				st/m5: 0
			]
			true [0]
		]
		if lg > k [lg: k]							;-- tables half zstd's size: as good for small inputs
		if sg > (k - 1) [sg: k - 1]
		bs: n
		if bs > ZSTD_BLOCK_MAX [bs: ZSTD_BLOCK_MAX]
		ns: bs >> 2 + 2								;-- sequences of a block, at most
		k: (1 << lg) + (1 << sg) + (ns * 3) + 3524 << 2 + (ns * 3) + bs + 512
		heap: null
		either k <= 32768 [							;-- small inputs: on the native stack
			work: system/stack/allocate k >> 2 + 1
			set-memory as byte-ptr! work null-byte (1 << lg) + (1 << sg) << 2	;-- empty hash tables
		][
			#either red-pass? = yes [
				work: allocate-virtual k no			;-- zeroed: empty hash tables
			][
				work: as int-ptr! allocate k
				set-memory as byte-ptr! work null-byte k
			]
			heap: work
		]
		st/in: in
		st/long: work
		st/short: work + (1 << lg)
		st/lsh: 32 - lg
		st/ssh: 32 - sg
		st/sll: st/short + (1 << sg)
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
		st/cll: as byte-ptr! st/logs + 4
		st/cml: st/cll + ns
		st/cof: st/cml + ns
		st/lits: st/cof + ns
		st/hlens: st/lits + bs
		st/rep1: 1
		st/rep2: 4

		op: out										;-- frame header: content size
		op/1: #"^(28)"
		op/2: #"^(B5)"
		op/3: #"^(2F)"
		op/4: #"^(FD)"
		either n <= ZSTD_WINDOW [					;-- single segment: the window is the content
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
			op/6: #"^(58)"							;-- window of 2 MB
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
