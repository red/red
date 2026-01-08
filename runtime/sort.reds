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
		* Mergesort: 
		!! only implemented a classic stable in-place merge sort for now !!
		Will improve it based on this the article, B-C. Huang and M. A. Langston, 
		"Fast Stable Merging and Sorting in Constant Extra Space (1989-1992)"
		(http://comjnl.oxfordjournals.org/content/35/6/643.full.pdf)
		(https://github.com/Mrrl/GrailSort)

		* Adaptive Symmetry Partition Sort: https://arxiv.org/pdf/0706.0046
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
		swaptype: either all [
			(as-integer a) % (size? integer!) = 0	;-- base address is aligned
			width % (size? integer!) = 0			;-- element size is aligned
		][0][1]
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

	#define SORT_CMP(a b) [cmp a b op flags]

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

	#define N_SAMPLE_SKIP 97

	symmetry-partition-sort: func [
		base	[byte-ptr!]
		s		[integer!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
		/local
			pb pc pa pj pm [byte-ptr!]
			cmp [cmpfunc!]
			i v vL m left right skip eq ineq rc swaptype [integer!]
	][
		SORT_SWAPINIT(base width)
		cmp: as cmpfunc! cmpfunc

		left: 0 right: 0
		forever [
			if num < 8 [				;-- Insertion sort on smallest arrays
				pc: base + (num * width)
				pb: base + width
				while [pb < pc][
					pm: pb
					while [positive? SORT_CMP((pm - width) pm)][
						SORT_SWAP((pm - width) pm)
						pm: pm - width
						if pm <= base [break]
					]
					pb: pb + width
				]
				exit
			]
			m: either s < 0 [0 - s][s]
			either m <= 2 [			;-- place 1st, 2nd and the last
				v: either num < 512 [num][63]
				pc: base + (v - 1 * width)
				pm: base + width

				SORT_SWAP(pm (base + (v / 2 * width)))
				if positive? SORT_CMP(base pm) [SORT_SWAP(base pm)]
				if positive? SORT_CMP(pm pc) [
					SORT_SWAP(pm pc)
					if positive? SORT_CMP(base pm) [SORT_SWAP(base pm)]
				]
				left: 1 right: 1
				pc: pc - width
			][
				v: either m > (num / 256) [num][16 * m - 1]
				if s < 0 [			;-- sorted items on right end, move them to left end
					either v < num [
						left: m
						s: 0 - s
					][
						left: m + 1 / 2
						right: m / 2
					]
					swapfunc base base + (num - m * width) left * width swaptype
					left: left - 1
				]
				if s > 0 [
					pb: base + (m * width)
					pc: base + (v * width)
					if v < num [
						skip: num / v * width
						pj: pb
						pa: pb
						while [pa < pc][
							SORT_SWAP(pa pj)
							pa: pa + width
							pj: pj + skip
						]
					]
					i: m / 2
					right: i
					until [
						pb: pb - width
						pc: pc - width
						SORT_SWAP(pb pc)
						i: i - 1
						zero? i
					]
					left: m - 1 / 2
				]
				pm: base + (left * width)
				pc: pm + (v - m * width)
			]

			;-- fat partition begins
			pb: pm + width
			pa: pb
			until [
				while [
					rc: SORT_CMP(pb pm)
					rc < 0
				][
					pb: pb + width
				]
				if pb >= pc [break]
				if zero? rc [
					if pa <> pb [SORT_SWAP(pb pa)]
					pa: pa + width
					pb: pb + width
					continue
				]
				while [
					rc: SORT_CMP(pc pm)
					rc > 0
				][
					pc: pc - width
				]
				if pb >= pc [break]
				SORT_SWAP(pb pc)
				if zero? rc [
					if pa <> pb [SORT_SWAP(pb pa)]
					pa: pa + width
				]
				pb: pb + width
				pc: pc - width
				pb > pc
			]

			;-- move equal items
			eq: as-integer pa - pm
			ineq: as-integer pb - pa
			if ineq < eq [pa: pm + ineq]
			pc: pb
			while [pm < pa][
				pc: pc - width
				SORT_SWAP(pc pm)
				pm: pm + width
			]

			;-- fat partition ends
			vL: (as-integer pb - base) / width
			if right < (v - vL) [
				symmetry-partition-sort pb 0 - right v - vL SORT_ARGS_EXT
			]
			vL: vL - (eq / width)
			either v < num [
				if left < vL [
					symmetry-partition-sort base left vL SORT_ARGS_EXT
				]
				s: v
			][
				if left >= vL [exit]
				s: left
				num: vL
			]
		]
	]

	adaptive-sort: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
		/local
			pb pc pa pj [byte-ptr!]
			cmp [cmpfunc!]
			i j ne rc D-inv d left m order swaptype [integer!]
	][
		SORT_SWAPINIT(base width)
		cmp: as cmpfunc! cmpfunc
		order: 0

		;-- find 1st run
		ne: num * width
		i: width
		while [i < ne][
			rc: cmp base + i - width base + i op flags
			if rc <> 0 [
				either zero? order [order: either rc < 0 [1][-1]][	;-- 1: increasing, -1: decreasing
					if rc * order > 0 [break]
				]
			]
			i: i + width
		]
	
		;-- calc difference of inversions and orders
		D-inv: order * (i / width)
		j: i + width
		while [j < ne][
			rc: cmp base + j - width base + j op flags
			either rc < 0 [D-inv: D-inv + 1][
				if rc > 0 [D-inv: D-inv - 1]
			]
			j: j + (N_SAMPLE_SKIP * width)
		]
	
		pb: base + i - width		;-- point to last element of the 1st run
		d: either D-inv < 0 [0 - D-inv][D-inv]
		if d > (num / 512) [		;-- if the data is not very random, i.e partially ordered
			if order * D-inv < 0 [	;-- 1st run is reverse, re-find it
				pb: base
				order: 0 - order
			]

			pc: base + (num * width)
			pj: pb
			forever [				;-- a simplified "natural mergesort"
				pj: pj + (10 * width)
				pa: pj - width
				if pj >= pc [break]
				while [
					all [
						pj < pc
						(order * cmp pj - width pj op flags) <= 0
					]
				][
					pj: pj + width
				]
				while [
					all [
						pa > pb
						(order * cmp pa - width pa op flags) <= 0
					]
				][
					pa: pa - width
				]
				if (as-integer pj - pa) < (4 * width) [continue]		;-- not good, try again
				if pb <> base [				;-- find knots in 1st and 2nd run
					j: (as-integer pj - pa) / width / 2
					m: (as-integer pb - base) / width / 4
					if j > m [j: m]
					i: 0
					while [i < j][
						if (order * cmp pb - (i * width) pa + (i * width) op flags) <= 0 [
							break
						]
						i: i + 1
					]
					if i >= j [continue]	;-- oops, try again
					pb: pb + ((1 - i) * width)
					pa: pa + (i * width)
				]
				;-- merge two runs
				either pa <> pb [
					while [pa < pj][
						SORT_SWAP(pb pa)
						pb: pb + width
						pa: pa + width
					]
				][pb: pj]
				pb: pb - width
			]
		]
		left: (as-integer pb - base) / width + 1
		if order = -1 [
			pc: base
			while [pc < pb][
				SORT_SWAP(pc pb)
				pc: pc + width
				pb: pb - width
			]
		]
		if (left < num) [symmetry-partition-sort base left num width op flags cmpfunc]
	]
]
