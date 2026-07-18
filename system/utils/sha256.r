REBOL [
	Title:   "SHA-256 implementation for host-side compiler utilities"
	File:    %sha256.r
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

sha256: context [
	native-digest-pages: none

	round-constants: [
		 1116352408  1899447441 -1245643825  -373957723
		  961987163  1508970993 -1841331548 -1424204075
		 -670586216   310598401   607225278  1426881987
		 1925078388 -2132889090 -1680079193 -1046744716
		 -459576895  -272742522   264347078   604807628
		  770255983  1249150122  1555081692  1996064986
		-1740746414 -1473132947 -1341970488 -1084653625
		 -958395405  -710438585   113926993   338241895
		  666307205   773529912  1294757372  1396182291
		 1695183700  1986661051 -2117940946 -1838011259
		-1564481375 -1474664885 -1035236496  -949202525
		 -778901479  -694614492  -200395387   275423344
		  430227734   506948616   659060556   883997877
		  958139571  1322822218  1537002063  1747873779
		 1955562222  2024104815 -2067236844 -1933114872
		-1866530822 -1538233109 -1090935817  -965641998
	]

	wrap32: func [value [integer! decimal!]][
		while [value > 2147483647.0][value: value - 4294967296.0]
		while [value < -2147483648.0][value: value + 4294967296.0]
		to integer! value
	]

	add2: func [a b [integer!]][wrap32 (0.0 + a + b)]
	add4: func [a b c d [integer!]][wrap32 (0.0 + a + b + c + d)]
	add5: func [a b c d e [integer!]][wrap32 (0.0 + a + b + c + d + e)]

	rotate-right: func [value bits [integer!]][
		(shift/logical value bits) or (shift/left value (32 - bits))
	]

	word-to-binary: func [value [integer!]][
		debase/base to-hex value 16
	]

	read-word: func [data [binary!] offset [integer!]][
		to integer! copy/part at data offset 4
	]

	use-native: func [handler][native-digest-pages: :handler]

	digest-pages: func [
		data [binary!]
		code-limit page-size [integer!]
		/local slots hashes native-result offset bytes page
	][
		slots: (round/to/ceiling code-limit page-size) / page-size
		hashes: make binary! (slots * 32)
		insert/dup tail hashes #{00} (slots * 32)
		if :native-digest-pages [
			native-result: sha256/native-digest-pages data code-limit page-size hashes
			if native-result = slots [return hashes]
		]

		clear hashes
		offset: 0
		while [offset < code-limit][
			bytes: min page-size (code-limit - offset)
			page: copy/part at data (offset + 1) bytes
			append hashes digest page
			offset: offset + bytes
		]
		hashes
	]

	digest: func [
		data [binary! string!]
		/local message input-length bit-length high low words offset chunk i
			a b c d e f g h h0 h1 h2 h3 h4 h5 h6 h7
			small0 small1 big0 big1 choice majority temp1 temp2 result value
	][
		message: copy (to binary! data)
		input-length: length? message
		append message #{80}
		while [((length? message) // 64) <> 56][append message #{00}]

		bit-length: (to decimal! input-length) * 8.0
		high: to integer! (bit-length / 4294967296.0)
		low: wrap32 (bit-length - ((to decimal! high) * 4294967296.0))
		append message word-to-binary high
		append message word-to-binary low

		h0:  1779033703
		h1: -1150833019
		h2:  1013904242
		h3: -1521486534
		h4:  1359893119
		h5: -1694144372
		h6:   528734635
		h7:  1541459225
		words: make block! 64

		repeat chunk ((length? message) / 64) [
			clear words
			insert/dup tail words 0 64
			offset: ((chunk - 1) * 64) + 1
			repeat i 16 [
				words/:i: read-word message (offset + ((i - 1) * 4))
			]
			for i 17 64 1 [
				value: words/(i - 15)
				small0: (rotate-right value 7) xor (rotate-right value 18)
				small0: small0 xor (shift/logical value 3)
				value: words/(i - 2)
				small1: (rotate-right value 17) xor (rotate-right value 19)
				small1: small1 xor (shift/logical value 10)
				words/:i: add4 words/(i - 16) small0 words/(i - 7) small1
			]

			a: h0
			b: h1
			c: h2
			d: h3
			e: h4
			f: h5
			g: h6
			h: h7
			repeat i 64 [
				big1: (rotate-right e 6) xor (rotate-right e 11)
				big1: big1 xor (rotate-right e 25)
				choice: (e and f) xor ((complement e) and g)
				temp1: add5 h big1 choice round-constants/:i words/:i
				big0: (rotate-right a 2) xor (rotate-right a 13)
				big0: big0 xor (rotate-right a 22)
				majority: (a and b) xor (a and c)
				majority: majority xor (b and c)
				temp2: add2 big0 majority

				h: g
				g: f
				f: e
				e: add2 d temp1
				d: c
				c: b
				b: a
				a: add2 temp1 temp2
			]

			h0: add2 h0 a
			h1: add2 h1 b
			h2: add2 h2 c
			h3: add2 h3 d
			h4: add2 h4 e
			h5: add2 h5 f
			h6: add2 h6 g
			h7: add2 h7 h
		]

		result: make binary! 32
		foreach value reduce [h0 h1 h2 h3 h4 h5 h6 h7][
			append result word-to-binary value
		]
		result
	]
]
