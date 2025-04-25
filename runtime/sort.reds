Red/System [
	Title:	"Sorting algorithm"
	Author: "Xie Qingtian"
	File: 	%sort.reds
	Tabs:	4
	Rights: "Copyright (C) 2014-2015 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: {
		Qsort: ported from Bentley & McIlroy's "Engineering a Sort Function".
		Mergesort: 
		!! only implemented a classic stable in-place merge sort for now !!
		Will improve it based on this the article, B-C. Huang and M. A. Langston, 
		"Fast Stable Merging and Sorting in Constant Extra Space (1989-1992)"
		(http://comjnl.oxfordjournals.org/content/35/6/643.full.pdf)
		(https://github.com/Mrrl/GrailSort)
	}
]

#define sort-reverse-mask	01h
#define sort-all-mask		02h

#enum sorting-flag! [
	SORT_NORMAL:	0
	SORT_REVERSE:	1
	SORT_ALL:		2
]

cmpfunc!: alias function! [
	a		[byte-ptr!]
	b		[byte-ptr!]
	op		[integer!]
	flags	[integer!]
	return: [integer!]
]

_sort: context [

	#define SORT_SWAPINIT(a width) [
		swaptype: either width % (size? integer!) = 0 [0][1]
	]

	#define SORT_SWAP(a b) [swapfunc a b width swaptype]

	#define SORT_SWAP_N(a b n) [
		loop n [
			SORT_SWAP(a b)
			a: a + width
			b: b + width
		]
	]

	#define SORT_ARGS_EXT_DEF [
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
	]
	
	#define SORT_ARGS_EXT [width op flags cmpfunc]

	swapfunc: func [
		a		 [byte-ptr!]
		b		 [byte-ptr!]
		n		 [integer!]
		swaptype [integer!]
		/local
			i j		[byte-ptr!]
			ii jj	[int-ptr!]
			t2 cnt	[integer!]
			t1		[byte!]
	][
		either zero? swaptype [
			cnt: n >> 2
			ii: as int-ptr! a
			jj: as int-ptr! b
			loop cnt [
				t2: ii/1
				ii/1: jj/1
				jj/1: t2
				ii: ii + 1
				jj: jj + 1
			]
		][
			i: a
			j: b
			loop n [
				t1: i/1
				i/1: j/1
				j/1: t1
				i: i + 1
				j: j + 1
			]
		]
	]

	med3: func [
		a		[byte-ptr!]
		b		[byte-ptr!]
		c		[byte-ptr!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
		return: [byte-ptr!]
		/local cmp [cmpfunc!]
	][
		cmp: as cmpfunc! cmpfunc
		either negative? cmp a b op flags [
			either negative? cmp b c op flags [b][
				either negative? cmp a c op flags [c][a]
			]
		][
			either positive? cmp b c op flags [b][
				either negative? cmp a c op flags [a][c]
			]
		]
	]

	qsort: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
		/local
			a b c d m n end i j [byte-ptr!] 
			r part result swaptype [integer!]
			swapped? [logic!]
			cmp [cmpfunc!]
	][
		cmp: as cmpfunc! cmpfunc
		SORT_SWAPINIT(base width)
		until [
			swapped?: false
			end: base + (num * width)

			if num < 7 [								;-- Insertion sort on smallest arrays
				m: base + width
				while [m < end][
					n: m
					while [
						all [
							n > base
							positive? cmp (n - width) n op flags
						]
					][
						SORT_SWAP((n - width) n)
						n: n - width
					]
					m: m + width
				]
				exit
			]
			m: base + (num / 2 * width)
			if num > 7 [
				a: base
				b: base + (num - 1 * width)
				if num > 40 [
					part: num >> 3 * width
					a: med3 a a + part a + (2 * part) op flags cmpfunc
					m: med3 m - part m m + part op flags cmpfunc
					b: med3 b - (2 * part) b - part b op flags cmpfunc
				]
				m: med3 a m b op flags cmpfunc
			]
			SORT_SWAP(base m)
			a: base + width
			b: a

			c: base + ((num - 1) * width)
			d: c
			forever [
				while [b <= c][
					result: cmp b base op flags
					if result > 0 [break]
					if zero? result [
						swapped?: true
						SORT_SWAP(a b)
						a: a + width
					]
					b: b + width
				]
				while [b <= c][
					result: cmp c base op flags
					if result < 0 [break]
					if zero? result [
						swapped?: true
						SORT_SWAP(c d)
						d: d - width
					]
					c: c - width
				]
				if b > c [break]
				SORT_SWAP(b c)
				swapped?: true
				b: b + width
				c: c - width
			]
			unless swapped? [			;-- switch to insertion sort 
				m: base + width
				while [m < end][
					n: m
					while [
						all [
							n > base
							positive? cmp (n - width) n op flags
						]
					][
						SORT_SWAP((n - width) n)
						n: n - width
					]
					m: m + width
				]
				exit
			]
			r: as-integer either (a - base) < (b - a) [a - base][b - a]
			if r > 0 [swapfunc base b - r r swaptype]

			r: as-integer either (d - c) < (end - d - width) [d - c][end - d - width]
			if r > 0 [swapfunc b end - r r swaptype]

			r: as-integer b - a
			if r > width [
				qsort base r / width width op flags cmpfunc
			]
			r: as-integer d - c
			if r > width [
				base: end - r
				num: r / width
			]
			r <= width
		]
	]

	grail-rotate: func [
		base	[byte-ptr!]
		n1		[integer!]
		n2		[integer!]
		width	[integer!]
		/local
			end b1 [byte-ptr!]
			swaptype [integer!]
	][
		SORT_SWAPINIT(base width)
		while [all [n1 <> 0 n2 <> 0]][
			end: base + (n1 * width)
			b1: end
			either n1 <= n2 [
				SORT_SWAP_N(base end n1)
				base: b1
				n2: n2 - n1
			][
				b1: base + ((n1 - n2) * width)
				SORT_SWAP_N(b1 end n2)
				n1: n1 - n2
			]
		]
	]

	grail-search-left: func [
		base	[byte-ptr!]
		num		[integer!]
		key		[byte-ptr!]
		SORT_ARGS_EXT_DEF
		return: [integer!]
		/local
			cmp [cmpfunc!]
			a b c [integer!]
	][
		cmp: as cmpfunc! cmpfunc
		a: -1
		b: num
		while [a < (b - 1)][
			c: a + ((b - a) >> 1)
			either 0 <= cmp base + (c * width) key op flags [b: c][a: c]
		]
		b
	]

	grail-search-right: func [
		base	[byte-ptr!]
		num		[integer!]
		key		[byte-ptr!]
		SORT_ARGS_EXT_DEF
		return: [integer!]
		/local
			cmp [cmpfunc!]
			a b c [integer!]
	][
		cmp: as cmpfunc! cmpfunc
		a: -1
		b: num
		while [a < (b - 1)][
			c: a + (b - a >> 1)
			either positive? cmp base + (c * width) key op flags [b: c][a: c]
		]
		b
	]

	grail-merge-nobuf: func [
		base	[byte-ptr!]
		n1		[integer!]
		n2		[integer!]
		SORT_ARGS_EXT_DEF
		/local 
			cmp [cmpfunc!]
			h 	[integer!]
	][
		cmp: as cmpfunc! cmpfunc
		either n1 < n2 [
			while [n1 <> 0][
				h: grail-search-left base + (n1 * width) n2 base SORT_ARGS_EXT
				if h <> 0 [
					grail-rotate base n1 h width
					base: base + (h * width)
					n2: n2 - h
				]
				either zero? n2 [n1: 0][
					until [
						base: base + width
						n1: n1 - 1
						any [
							zero? n1
							positive? cmp base base + (n1 * width) op flags
						]
					]
				]
			]
		][
			while [n2 <> 0][
				h: grail-search-right base n1 base + (n1 + n2 - 1 * width) SORT_ARGS_EXT
				if h <> n1 [
					grail-rotate base + (h * width) n1 - h n2 width
					n1: h
				]
				either zero? n1 [n2: 0][
					until [
						n2: n2 - 1
						any [
							zero? n2
							positive? cmp base + (n1 - 1 * width) base + (n1 + n2 - 1 * width) op flags
						]
					]
				]
			]
		]
	]

	grail-classic-merge: func [
		base	[byte-ptr!]
		n1		[integer!]
		n2		[integer!]
		SORT_ARGS_EXT_DEF
		/local
			ak	[byte-ptr!]
			cmp [cmpfunc!]
			K k1 k2 m1 m2 [integer!]
	][
		cmp: as cmpfunc! cmpfunc
		if any [n1 < 9 n2 < 9][
			grail-merge-nobuf base n1 n2 SORT_ARGS_EXT
			exit
		]
		K: either n1 < n2 [n1 + (n2 / 2)][n1 / 2]
		ak: base + (K * width)
		k1: grail-search-left base n1 ak SORT_ARGS_EXT
		k2: k1
		if all [
			k2 < n1
			zero? cmp base + (k2 * width) ak op flags
		][
			k2: k1 + grail-search-right base + (k1 * width) n1 - k1 ak SORT_ARGS_EXT
		]
		m1: grail-search-left base + (n1 * width) n2 ak SORT_ARGS_EXT
		m2: m1
		if all [
			m2 < n2
			zero? cmp base + (n1 + m2 * width) ak op flags
		][
			m2: m1 + grail-search-right base + (n1 + m1 * width) n2 - m1 ak SORT_ARGS_EXT
		]
		either k1 = k2 [
			grail-rotate base + (k2 * width) n1 - k2 m2 width
		][
			grail-rotate base + (k1 * width) n1 - k1 m1 width
			if m2 <> m1 [grail-rotate base + (k2 + m1 * width) n1 - k2 m2 - m1 width]
		]
		grail-classic-merge base + (k2 + m2 * width) n1 - k2 n2 - m2 SORT_ARGS_EXT
		grail-classic-merge base k1 m1 SORT_ARGS_EXT
	]

	mergesort: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
		/local
			pm0	pm1 [byte-ptr!]
			cmp [cmpfunc!]
			m h p0 p1 rest swaptype [integer!]
	][
		SORT_SWAPINIT(base width)
		cmp: as cmpfunc! cmpfunc
		h: 2
		m: 1
		while [m < num][
			pm0: base + (m - 1 * width)
			pm1: base + (m * width)
			if positive? cmp pm0 pm1 op flags [
				SORT_SWAP(pm0 pm1)
			]
			m: m + 2
		]
		while [h < num][
			p0: 0
			p1: num - (2 * h)
			while [p0 <= p1][
				grail-classic-merge base + (p0 * width) h h SORT_ARGS_EXT
				p0: p0 + (2 * h)
			]
			rest: num - p0
			if rest > h [grail-classic-merge base + (p0 * width) h rest - h SORT_ARGS_EXT]
			h: h * 2
		]
	]
]
