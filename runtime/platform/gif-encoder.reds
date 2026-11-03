Red/System [
	Title:   "GIF encoder"
	Author:  "Nenad Rakocevic"
	File: 	 %gif-encoder.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2026 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Note: {
		Single-frame GIF89a encoder, for image backends without an OS GIF encoder.
		Up to 256 colors are kept exact, more are reduced by median cut.
		Pixels with an alpha below 128 become transparent.
	}
]

#define GIF_COLOR_SLOTS		1024					;-- exact colors hash table (power of 2)
#define GIF_HIST_SIZE		32768					;-- RGB 5-5-5 histogram
#define GIF_HASH_SIZE		5003					;-- LZW strings hash table (prime)
#define GIF_MAX_CODES		4096

#define GIF_BIN(pixel) [(pixel >> 9 and 7C00h or (pixel >> 6 and 03E0h) or (pixel >> 3 and 1Fh) + 1)]

gif-encoder: context [

	box!: alias struct! [							;-- median cut box, in 5-5-5 RGB bins
		r0		[integer!]
		r1		[integer!]
		g0		[integer!]
		g1		[integer!]
		b0		[integer!]
		b1		[integer!]
		count	[integer!]							;-- pixels in the box
	]

	encoder!: alias struct! [
		bin		[red-binary!]
		palette	[int-ptr!]							;-- 256 RGB colors
		colors	[integer!]							;-- opaque colors, also the transparent index
		trans?	[logic!]
		keys	[int-ptr!]							;-- exact colors: RGB or 01000000h, 0: free slot
		indexes	[int-ptr!]							;-- exact colors: palette index of each key
		map		[byte-ptr!]							;-- reduced colors: palette index of each bin
		prev	[integer!]							;-- last pixel looked up, and its index
		prev-idx [integer!]
		block	[byte-ptr!]							;-- data sub-block: length byte + 255 bytes
		used	[integer!]							;-- bytes in the sub-block
		acc		[integer!]							;-- pending code bits
		bits	[integer!]							;-- number of pending bits
		width	[integer!]							;-- current code width
	]

	find-slot: func [
		keys	[int-ptr!]
		rgb		[integer!]
		return: [integer!]							;-- slot of rgb, or the free slot for it
		/local
			key	[integer!]
			i	[integer!]
	][
		key: rgb or 01000000h
		i: rgb * 9E3779B1h >>> 22 + 1
		while [all [keys/i <> 0 keys/i <> key]][
			i: i + 1
			if i > GIF_COLOR_SLOTS [i: 1]
		]
		i
	]

	collect-colors: func [
		enc		[encoder!]
		data	[int-ptr!]
		end		[int-ptr!]
		return: [logic!]							;-- no: more than 256 colors
		/local
			keys	[int-ptr!]
			indexes	[int-ptr!]
			pal		[int-ptr!]
			pixel	[integer!]
			prev	[integer!]
			rgb		[integer!]
			i		[integer!]
			n		[integer!]
	][
		keys: enc/keys
		indexes: enc/indexes
		pal: enc/palette
		n: 0
		prev: not data/value
		while [data < end][
			pixel: data/value
			if pixel <> prev [
				prev: pixel
				either pixel >>> 24 < 128 [enc/trans?: yes][
					rgb: pixel and 00FFFFFFh
					i: find-slot keys rgb
					if zero? keys/i [
						if n = 256 [return no]
						keys/i: rgb or 01000000h
						indexes/i: n
						n: n + 1
						pal/n: rgb
					]
				]
			]
			data: data + 1
		]
		enc/colors: n
		not all [enc/trans? n = 256]
	]

	shrink: func [									;-- fits the box to its non-empty bins
		hist	[int-ptr!]
		box		[box!]
		/local
			r g b i c n		[integer!]
			r0 r1 g0 g1 b0 b1 [integer!]
	][
		r0: 31
		r1: 0
		g0: 31
		g1: 0
		b0: 31
		b1: 0
		n: 0
		r: box/r0
		while [r <= box/r1][
			g: box/g0
			while [g <= box/g1][
				i: r << 10 + (g << 5) + box/b0 + 1
				b: box/b0
				while [b <= box/b1][
					c: hist/i
					if c > 0 [
						n: n + c
						if r < r0 [r0: r]
						if r > r1 [r1: r]
						if g < g0 [g0: g]
						if g > g1 [g1: g]
						if b < b0 [b0: b]
						if b > b1 [b1: b]
					]
					i: i + 1
					b: b + 1
				]
				g: g + 1
			]
			r: r + 1
		]
		box/r0: r0
		box/r1: r1
		box/g0: g0
		box/g1: g1
		box/b0: b0
		box/b1: b1
		box/count: n
	]

	split: func [									;-- splits the box at the median of its longest side
		hist	[int-ptr!]
		box		[box!]
		new		[box!]
		/local
			proj	[int-ptr!]
			slices	[int-ptr!]
			r g b i j c [integer!]
			axis len lo hi s sum [integer!]
	][
		proj: system/stack/allocate 96				;-- pixels per slice, for each axis
		set-memory as byte-ptr! proj null-byte 96 * 4
		r: box/r0
		while [r <= box/r1][
			g: box/g0
			while [g <= box/g1][
				i: r << 10 + (g << 5) + box/b0 + 1
				b: box/b0
				while [b <= box/b1][
					c: hist/i
					j: r + 1
					proj/j: proj/j + c
					j: g + 33
					proj/j: proj/j + c
					j: b + 65
					proj/j: proj/j + c
					i: i + 1
					b: b + 1
				]
				g: g + 1
			]
			r: r + 1
		]
		axis: 0
		lo: box/r0
		hi: box/r1
		len: box/r1 - box/r0
		if box/g1 - box/g0 >= len [
			axis: 1
			lo: box/g0
			hi: box/g1
			len: box/g1 - box/g0
		]
		if box/b1 - box/b0 > len [
			axis: 2
			lo: box/b0
			hi: box/b1
		]
		slices: proj + (axis * 32)
		sum: 0
		s: lo
		forever [
			j: s + 1
			sum: sum + slices/j
			if any [sum >= (box/count >> 1) s >= hi][break]
			s: s + 1
		]
		if s >= hi [s: hi - 1]

		copy-memory as byte-ptr! new as byte-ptr! box size? box!
		switch axis [
			0 [
				box/r1: s
				new/r0: s + 1
			]
			1 [
				box/g1: s
				new/g0: s + 1
			]
			2 [
				box/b1: s
				new/b0: s + 1
			]
		]
		shrink hist box
		shrink hist new
	]

	nearest: func [
		pal		[int-ptr!]
		n		[integer!]
		r		[integer!]
		g		[integer!]
		b		[integer!]
		return: [integer!]							;-- index of the palette color nearest to r.g.b
		/local
			best dist d c dr dg db i [integer!]
	][
		best: 0
		dist: 7FFFFFFFh
		i: 1
		while [i <= n][
			c: pal/i
			dr: c >> 16 - r
			dg: c >> 8 and FFh - g
			db: c and FFh - b
			d: dr * dr + (dg * dg) + (db * db)
			if d < dist [
				dist: d
				best: i - 1
			]
			i: i + 1
		]
		best
	]

	quantize: func [								;-- median cut, sets the palette and the bins map
		enc		[encoder!]
		data	[int-ptr!]
		end		[int-ptr!]
		/local
			hist	[int-ptr!]
			pal		[int-ptr!]
			map		[byte-ptr!]
			sums	[float-ptr!]
			boxes	[box!]
			box		[box!]
			p		[int-ptr!]
			pixel i j k n r g b most target [integer!]
			count	[float!]
	][
		hist: system/stack/allocate GIF_HIST_SIZE
		set-memory as byte-ptr! hist null-byte GIF_HIST_SIZE * 4
		p: data
		while [p < end][
			pixel: p/value
			either pixel >>> 24 < 128 [enc/trans?: yes][
				i: GIF_BIN(pixel)
				hist/i: hist/i + 1
			]
			p: p + 1
		]
		target: 256
		if enc/trans? [target: 255]

		boxes: as box! system/stack/allocate 256 * 7
		boxes/r0: 0
		boxes/r1: 31
		boxes/g0: 0
		boxes/g1: 31
		boxes/b0: 0
		boxes/b1: 31
		shrink hist boxes
		n: 1
		while [n < target][							;-- splits the most populated box
			most: 0
			i: 0
			while [i < n][
				box: boxes + i
				if all [
					box/count > most
					any [box/r1 > box/r0 box/g1 > box/g0 box/b1 > box/b0]
				][
					most: box/count
					k: i
				]
				i: i + 1
			]
			if zero? most [break]					;-- each box is a single bin
			split hist boxes + k boxes + n
			n: n + 1
		]

		map: enc/map
		k: 0
		while [k < n][
			box: boxes + k
			r: box/r0
			while [r <= box/r1][
				g: box/g0
				while [g <= box/g1][
					i: r << 10 + (g << 5) + box/b0 + 1
					b: box/b0
					while [b <= box/b1][
						map/i: as byte! k
						i: i + 1
						b: b + 1
					]
					g: g + 1
				]
				r: r + 1
			]
			k: k + 1
		]

		sums: as float-ptr! system/stack/allocate 256 * 6	;-- RGB sums of each box
		set-memory as byte-ptr! sums null-byte 256 * 24
		p: data
		while [p < end][
			pixel: p/value
			if pixel >>> 24 >= 128 [
				i: GIF_BIN(pixel)
				j: (as-integer map/i) * 3 + 1
				r: pixel >> 16 and FFh
				sums/j: sums/j + as float! r
				j: j + 1
				g: pixel >> 8 and FFh
				sums/j: sums/j + as float! g
				j: j + 1
				b: pixel and FFh
				sums/j: sums/j + as float! b
			]
			p: p + 1
		]
		pal: enc/palette
		k: 1
		j: 1
		while [k <= n][
			box: boxes + (k - 1)
			count: as float! box/count
			r: as-integer sums/j / count + 0.5
			j: j + 1
			g: as-integer sums/j / count + 0.5
			j: j + 1
			b: as-integer sums/j / count + 0.5
			j: j + 1
			pal/k: r << 16 or (g << 8) or b
			k: k + 1
		]
		enc/colors: n

		i: 1
		while [i <= GIF_HIST_SIZE][					;-- maps each used bin to its nearest color
			if hist/i > 0 [
				j: i - 1
				r: j >> 10 << 3 + 4
				g: j >> 5 and 1Fh << 3 + 4
				b: j and 1Fh << 3 + 4
				map/i: as byte! nearest pal n r g b
			]
			i: i + 1
		]
	]

	index-of: func [
		enc		[encoder!]
		pixel	[integer!]
		return: [integer!]
		/local
			idx	[int-ptr!]
			map	[byte-ptr!]
			i	[integer!]
	][
		if pixel = enc/prev [return enc/prev-idx]
		enc/prev: pixel
		either pixel >>> 24 < 128 [i: enc/colors][
			either null? enc/map [
				idx: enc/indexes
				i: find-slot enc/keys pixel and 00FFFFFFh
				i: idx/i
			][
				map: enc/map
				i: GIF_BIN(pixel)
				i: as-integer map/i
			]
		]
		enc/prev-idx: i
		i
	]

	put-byte: func [
		enc		[encoder!]
		byte	[integer!]
		/local
			p	[byte-ptr!]
	][
		enc/used: enc/used + 1
		p: enc/block + enc/used
		p/1: as byte! byte
		if enc/used = 255 [
			p: enc/block
			p/1: as byte! 255
			binary/rs-append enc/bin p 256
			enc/used: 0
		]
	]

	put-code: func [
		enc		[encoder!]
		code	[integer!]
		/local
			acc bits [integer!]
	][
		acc: enc/acc or (code << enc/bits)
		bits: enc/bits + enc/width
		while [bits >= 8][
			put-byte enc acc and FFh
			acc: acc >>> 8
			bits: bits - 8
		]
		enc/acc: acc
		enc/bits: bits
	]

	compress: func [								;-- LZW, emits the image data sub-blocks
		enc			[encoder!]
		data		[int-ptr!]
		end			[int-ptr!]
		min-width	[integer!]
		/local
			hkeys	[int-ptr!]
			hcodes	[int-ptr!]
			p		[byte-ptr!]
			clear-code eoi avail ent k key i disp [integer!]
	][
		hkeys: system/stack/allocate GIF_HASH_SIZE
		hcodes: system/stack/allocate GIF_HASH_SIZE
		set-memory as byte-ptr! hkeys #"^(FF)" GIF_HASH_SIZE * 4
		p: as byte-ptr! system/stack/allocate 64
		enc/block: p
		enc/used: 0
		enc/acc: 0
		enc/bits: 0
		enc/width: min-width + 1
		clear-code: 1 << min-width
		eoi: clear-code + 1
		avail: clear-code + 2

		put-code enc clear-code
		enc/prev: not data/value
		ent: index-of enc data/value
		data: data + 1
		while [data < end][
			k: index-of enc data/value
			data: data + 1
			key: k << 12 + ent
			i: k << 4 xor ent + 1
			if hkeys/i = key [
				ent: hcodes/i
				continue
			]
			if hkeys/i <> -1 [						;-- slot taken: secondary probe
				disp: GIF_HASH_SIZE - i + 1
				if i = 1 [disp: 1]
				until [
					i: i - disp
					if i < 1 [i: i + GIF_HASH_SIZE]
					any [hkeys/i = key hkeys/i = -1]
				]
				if hkeys/i = key [
					ent: hcodes/i
					continue
				]
			]
			put-code enc ent
			if all [enc/width < 12 avail >= (1 << enc/width)][enc/width: enc/width + 1]
			ent: k
			either avail < GIF_MAX_CODES [
				hkeys/i: key
				hcodes/i: avail
				avail: avail + 1
			][
				put-code enc clear-code
				set-memory as byte-ptr! hkeys #"^(FF)" GIF_HASH_SIZE * 4
				avail: clear-code + 2
				enc/width: min-width + 1
			]
		]
		put-code enc ent
		if all [enc/width < 12 avail >= (1 << enc/width)][enc/width: enc/width + 1]
		put-code enc eoi
		if enc/bits > 0 [put-byte enc enc/acc]
		if enc/used > 0 [
			p/1: as byte! enc/used
			binary/rs-append enc/bin p enc/used + 1
		]
	]

	encode: func [
		data	[int-ptr!]							;-- ARGB pixels
		width	[integer!]
		height	[integer!]
		slot	[red-value!]
		return: [red-binary!]
		/local
			enc		[encoder! value]
			bin		[red-binary!]
			end		[int-ptr!]
			pal		[int-ptr!]
			p		[byte-ptr!]
			c i n bits [integer!]
	][
		bin: binary/make-at slot 4096
		if any [zero? width zero? height][return bin]

		end: data + (width * height)
		enc/bin: bin
		enc/palette: system/stack/allocate 256
		set-memory as byte-ptr! enc/palette null-byte 256 * 4
		enc/keys: system/stack/allocate GIF_COLOR_SLOTS
		set-memory as byte-ptr! enc/keys null-byte GIF_COLOR_SLOTS * 4
		enc/indexes: system/stack/allocate GIF_COLOR_SLOTS
		enc/map: null
		enc/trans?: no
		unless collect-colors enc data end [
			enc/map: as byte-ptr! system/stack/allocate GIF_HIST_SIZE >> 2
			quantize enc data end
		]
		n: enc/colors
		if enc/trans? [n: n + 1]
		bits: 1
		while [1 << bits < n][bits: bits + 1]

		p: as byte-ptr! system/stack/allocate 192	;-- 768 bytes, for the color table
		copy-memory p as byte-ptr! "GIF89a" 6
		p/7: as byte! width
		p/8: as byte! width >> 8
		p/9: as byte! height
		p/10: as byte! height >> 8
		p/11: as byte! F0h or (bits - 1)			;-- global color table, 8-bit components
		p/12: null-byte								;-- background color index
		p/13: null-byte								;-- pixel aspect ratio
		binary/rs-append bin p 13

		set-memory p null-byte 768
		pal: enc/palette
		i: 1
		while [i <= enc/colors][
			c: pal/i
			p/1: as byte! c >> 16
			p/2: as byte! c >> 8
			p/3: as byte! c
			p: p + 3
			i: i + 1
		]
		p: p - (enc/colors * 3)
		binary/rs-append bin p 3 << bits

		if enc/trans? [								;-- graphic control extension
			p/1: #"^(21)"
			p/2: #"^(F9)"
			p/3: #"^(04)"
			p/4: #"^(01)"							;-- transparent color flag
			p/5: null-byte							;-- delay
			p/6: null-byte
			p/7: as byte! enc/colors				;-- transparent color index
			p/8: null-byte
			binary/rs-append bin p 8
		]
		p/1: #"^(2C)"								;-- image descriptor
		p/2: null-byte
		p/3: null-byte
		p/4: null-byte
		p/5: null-byte
		p/6: as byte! width
		p/7: as byte! width >> 8
		p/8: as byte! height
		p/9: as byte! height >> 8
		p/10: null-byte
		if bits < 2 [bits: 2]
		p/11: as byte! bits							;-- LZW minimum code size
		binary/rs-append bin p 11

		compress enc data end bits
		p/1: null-byte								;-- block terminator
		p/2: #"^(3B)"								;-- trailer
		binary/rs-append bin p 2
		bin
	]
]
