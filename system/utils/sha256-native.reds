Red/System [
	Title:   "Native SHA-256 helper for the host compiler"
	File:    %sha256-native.reds
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

sha256-native: context [
	rotate-right: func [value bits [integer!] return: [integer!]][
		(value >>> bits) or (value << (32 - bits))
	]

	read-be32: func [p [byte-ptr!] return: [integer!]][
		(((as integer! p/1) << 24) or ((as integer! p/2) << 16))
			or (((as integer! p/3) << 8) or (as integer! p/4))
	]

	write-be32: func [p [byte-ptr!] value [integer!]][
		p/1: as byte! (value >>> 24)
		p/2: as byte! (value >>> 16)
		p/3: as byte! (value >>> 8)
		p/4: as byte! value
	]

	init-constants: func [k [int-ptr!]][
		k/1: 1116352408   k/2: 1899447441   k/3: -1245643825  k/4: -373957723
		k/5: 961987163    k/6: 1508970993   k/7: -1841331548  k/8: -1424204075
		k/9: -670586216   k/10: 310598401   k/11: 607225278   k/12: 1426881987
		k/13: 1925078388  k/14: -2132889090 k/15: -1680079193 k/16: -1046744716
		k/17: -459576895  k/18: -272742522  k/19: 264347078   k/20: 604807628
		k/21: 770255983   k/22: 1249150122  k/23: 1555081692  k/24: 1996064986
		k/25: -1740746414 k/26: -1473132947 k/27: -1341970488 k/28: -1084653625
		k/29: -958395405  k/30: -710438585  k/31: 113926993   k/32: 338241895
		k/33: 666307205   k/34: 773529912   k/35: 1294757372  k/36: 1396182291
		k/37: 1695183700  k/38: 1986661051  k/39: -2117940946 k/40: -1838011259
		k/41: -1564481375 k/42: -1474664885 k/43: -1035236496 k/44: -949202525
		k/45: -778901479  k/46: -694614492  k/47: -200395387  k/48: 275423344
		k/49: 430227734   k/50: 506948616   k/51: 659060556   k/52: 883997877
		k/53: 958139571   k/54: 1322822218  k/55: 1537002063  k/56: 1747873779
		k/57: 1955562222  k/58: 2024104815  k/59: -2067236844 k/60: -1933114872
		k/61: -1866530822 k/62: -1538233109 k/63: -1090935817 k/64: -965641998
	]

	process-block: func [
		data [byte-ptr!]
		state w k [int-ptr!]
		/local i j p value wm16 wm7 small0 small1 big0 big1 choice majority temp1 temp2
			a b c d e f g h
	][
		i: 1
		while [i <= 16][
			p: data + ((i - 1) * 4)
			w/i: read-be32 p
			i: i + 1
		]
		while [i <= 64][
			j: i - 15
			value: w/j
			small0: (rotate-right value 7) xor (rotate-right value 18)
			small0: small0 xor (value >>> 3)
			j: i - 2
			value: w/j
			small1: (rotate-right value 17) xor (rotate-right value 19)
			small1: small1 xor (value >>> 10)
			j: i - 16
			wm16: w/j
			j: i - 7
			wm7: w/j
			w/i: wm16 + small0 + wm7 + small1
			i: i + 1
		]

		a: state/1
		b: state/2
		c: state/3
		d: state/4
		e: state/5
		f: state/6
		g: state/7
		h: state/8
		i: 1
		while [i <= 64][
			big1: (rotate-right e 6) xor (rotate-right e 11)
			big1: big1 xor (rotate-right e 25)
			choice: (e and f) xor ((not e) and g)
			temp1: h + big1 + choice + k/i + w/i
			big0: (rotate-right a 2) xor (rotate-right a 13)
			big0: big0 xor (rotate-right a 22)
			majority: (a and b) xor (a and c)
			majority: majority xor (b and c)
			temp2: big0 + majority

			h: g
			g: f
			f: e
			e: d + temp1
			d: c
			c: b
			b: a
			a: temp1 + temp2
			i: i + 1
		]

		state/1: state/1 + a
		state/2: state/2 + b
		state/3: state/3 + c
		state/4: state/4 + d
		state/5: state/5 + e
		state/6: state/6 + f
		state/7: state/7 + g
		state/8: state/8 + h
	]

	digest-page: func [
		data [byte-ptr!]
		length [integer!]
		out [byte-ptr!]
		state w k [int-ptr!]
		tail [byte-ptr!]
		/local blocks remaining offset padding-blocks p i
	][
		state/1: 1779033703
		state/2: -1150833019
		state/3: 1013904242
		state/4: -1521486534
		state/5: 1359893119
		state/6: -1694144372
		state/7: 528734635
		state/8: 1541459225

		blocks: length / 64
		offset: 0
		i: 0
		while [i < blocks][
			process-block (data + offset) state w k
			offset: offset + 64
			i: i + 1
		]

		remaining: length - offset
		set-memory tail null-byte 128
		if remaining > 0 [copy-memory tail (data + offset) remaining]
		i: remaining + 1
		tail/i: as byte! 80h
		padding-blocks: either remaining < 56 [1][2]
		p: tail + (padding-blocks * 64 - 4)
		write-be32 p (length * 8)
		process-block tail state w k
		if padding-blocks = 2 [process-block (tail + 64) state w k]

		i: 1
		while [i <= 8][
			write-be32 (out + ((i - 1) * 4)) state/i
			i: i + 1
		]
	]

	digest-pages: func [
		data [byte-ptr!]
		code-limit page-size [integer!]
		out [byte-ptr!]
		return: [integer!]
		/local slots slot offset length workspace w k state tail
	][
		if any [code-limit < 0 page-size <= 0][return -1]
		slots: either code-limit = 0 [0][(code-limit + page-size - 1) / page-size]
		workspace: allocate 672
		if workspace = null [return -1]
		w: as int-ptr! workspace
		k: as int-ptr! (workspace + 256)
		state: as int-ptr! (workspace + 512)
		tail: workspace + 544
		init-constants k

		slot: 0
		offset: 0
		while [slot < slots][
			length: either (code-limit - offset) < page-size [code-limit - offset][page-size]
			digest-page (data + offset) length (out + (slot * 32)) state w k tail
			offset: offset + length
			slot: slot + 1
		]

		free workspace
		slots
	]
]
