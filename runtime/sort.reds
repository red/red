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

	#define SORT_COPY(a b) [copyfunc a b width swaptype]

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

	UNIT!: alias struct! [
		a	[integer!]
		b	[integer!]
		c	[integer!]
		d	[integer!]
	]

	BLOCK: 128
	BLOCK-USIZE: BLOCK / 4
	SHORTEST_MEDIAN_OF_MEDIANS: 50
	MAX_SWAPS: 12
	MAX_INSERTION: 20
	MAX_STEPS: 5
	SHORTEST_SHIFTING: 50

	swapfunc: func [
		a		 [byte-ptr!]
		b		 [byte-ptr!]
		n		 [integer!]
		swaptype [integer!]
		/local cnt [integer!] i [byte-ptr!] j [byte-ptr!]
			ii [int-ptr!] jj [int-ptr!] t1 [byte!] t2 [integer!]
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

	copyfunc: func [
		a			[byte-ptr!]
		b			[byte-ptr!]
		n			[integer!]
		swaptype	[integer!]
		/local cnt i j ii jj
	][
		either zero? swaptype [
			cnt: n >> 2
			ii: as int-ptr! a
			jj: as int-ptr! b
			loop cnt [
				jj/1: ii/1
				ii: ii + 1
				jj: jj + 1
			]
		][
			i: a
			j: b
			loop n [
				j/1: i/1
				i: i + 1
				j: j + 1
			]
		]
	]

	sort2: func [
		base	[byte-ptr!]
		a		[int-ptr!]
		b		[int-ptr!]
		swaps	[int-ptr!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
		/local
			cmp
			mp np temp
	][
		cmp: as cmpfunc! cmpfunc
		mp: base + (a/1 * width)
		np: base + (b/1 * width)
		if negative? cmp np mp op flags [
			temp: a/1
			a/1: b/1
			b/1: temp
			swaps/1: swaps/1 + 1
		]
	]

	sort3: func [
		base	[byte-ptr!]
		a		[int-ptr!]
		b		[int-ptr!]
		c		[int-ptr!]
		swaps	[int-ptr!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
	][
		sort2 base a b swaps width op flags cmpfunc
		sort2 base b c swaps width op flags cmpfunc
		sort2 base a b swaps width op flags cmpfunc
	]

	sort-adjacent: func [
		base	[byte-ptr!]
		a		[int-ptr!]
		swaps	[int-ptr!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
		/local
			b c
	][
		b: a/1 - 1
		c: a/1 + 1
		sort3 base :b a :c swaps width op flags cmpfunc
	]

	med3: func [
		a		[byte-ptr!]
		b		[byte-ptr!]
		c		[byte-ptr!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
		return: [byte-ptr!]
		/local cmp
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
			a [byte-ptr!] b [byte-ptr!] c [byte-ptr!] d [byte-ptr!] m [byte-ptr!]
			n [byte-ptr!] end [byte-ptr!] i [byte-ptr!] j [byte-ptr!] r [integer!]
			part [integer!] result [integer!] swaptype [integer!] swapped? [logic!]
			cmp
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

	;-- Shifts the first element to the right until it encounters a greater or equal element.
	shift-head: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc	[integer!]
		/local
			cmp i j t swaptype m mp np
	][
		cmp: as cmpfunc! cmpfunc
		SORT_SWAPINIT(base width)
		mp: base
		np: mp + width
		if all [
			num >= 2
			negative? cmp np mp op flags
		][
			SORT_SWAP(mp np)
			m: num - 2
			loop m [
				mp: np
				np: np + width
				if negative? cmp mp np op flags [
					break
				]
				SORT_SWAP(mp np)
			]
		]
	]

	;-- Shifts the last element to the left until it encounters a smaller or equal element.
	shift-tail: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc	[integer!]
		/local
			cmp i j t swaptype m mp np
	][
		cmp: as cmpfunc! cmpfunc
		SORT_SWAPINIT(base width)
		mp: base + (num * width) - width
		np: mp - width
		if all [
			num >= 2
			negative? cmp mp np op flags
		][
			SORT_SWAP(mp np)
			m: num - 2
			loop m [
				mp: np
				np: np - width
				if positive? cmp mp np op flags [
					break
				]
				SORT_SWAP(mp np)
			]
		]
	]

	;-- `O(n^2)` worst-case.
	insertion-sort: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc	[integer!]
		/local
			i j t swaptype m mp
	][
		m: 1
		while [m < num][
			shift-tail base m + 1 width op flags cmpfunc
			m: m + 1
		]
	]

	;-- Partially sorts a slice by shifting several out-of-order elements around.
	;-- Returns `true` if the slice is sorted at the end. This function is `O(n)` worst-case.
	partial-insertion-sort: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc	[integer!]
		return:	[logic!]
		/local
			cmp i j t swaptype m mp
	][
		cmp: as cmpfunc! cmpfunc
		SORT_SWAPINIT(base width)

		m: 1
		mp: base + width
		loop MAX_STEPS [
			while [
				all [
					m < num
					not negative? cmp mp mp - width op flags
				]
			][
				m: m + 1
				mp: mp + width
			]
			if m = num [return true]
			if num < SHORTEST_SHIFTING [return false]
			SORT_SWAP(mp (mp - width))
			shift-tail base m width op flags cmpfunc
			shift-head mp num - m width op flags cmpfunc
		]
		false
	]

	;-- Partitions it into elements smaller than `pivot`, followed by elements greater than or equal to `pivot`.
	;-- Returns the number of elements smaller than `pivot`.
	;-- Partitioning is performed block-by-block in order to minimize the cost of branching operations.
	;-- This idea is presented in the [BlockQuicksort][pdf] paper.
	;-- [pdf]: http://drops.dagstuhl.de/opus/volltexte/2016/6389/pdf/LIPIcs-ESA-2016-38.pdf
	partition-in-blocks: func [
		base	[byte-ptr!]
		num		[integer!]
		pivot	[byte-ptr!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc	[integer!]
		return:	[integer!]
		/local
			l block_l start_l end_l offsets_l
			r block_r start_r end_r offsets_r
			cmp i j t swaptype
			w is_done elem m w2 count mp np temp
			unit	[UNIT! value]
	][
		l: base
		block_l: BLOCK
		start_l: as byte-ptr! 0
		end_l: as byte-ptr! 0
		offsets_l: as byte-ptr! system/stack/allocate BLOCK-USIZE

		r: l + (num * width)
		block_r: BLOCK
		start_r: as byte-ptr! 0
		end_r: as byte-ptr! 0
		offsets_r: as byte-ptr! system/stack/allocate BLOCK-USIZE

		cmp: as cmpfunc! cmpfunc
		SORT_SWAPINIT(base width)

		forever [
			w: (as integer! r - l) / width
			is_done: w <= (2 * BLOCK)
			if is_done [
				if any [
					start_l < end_l
					start_r < end_r
				][w: w - BLOCK]
				case [
					start_l < end_l [
						block_r: w
					]
					start_r < end_r [
						block_l: w
					]
					true [
						block_l: w / 2
						block_r: w - block_l
					]
				]
			]
			if start_l = end_l [
				start_l: offsets_l
				end_l: offsets_l
				elem: l
				m: 0
				while [m < block_l][
					end_l/1: as byte! m
					unless negative? cmp elem pivot op flags [
						end_l: end_l + 1
					]
					elem: elem + width
					m: m + 1
				]
			]
			if start_r = end_r [
				start_r: offsets_r
				end_r: offsets_r
				elem: r
				m: 0
				while [m < block_r][
					elem: elem - width
					end_r/1: as byte! m
					if negative? cmp elem pivot op flags [
						end_r: end_r + 1
					]
					m: m + 1
				]
			]

			w: as integer! end_l - start_l
			w2: as integer! end_r - start_r
			count: w
			if w > w2 [count: w2]

			if count > 0 [
				temp: as byte-ptr! unit
				mp: l + ((as integer! start_l/1) * width)
				np: r - ((as integer! start_r/1) * width) - width
				SORT_COPY(mp temp)
				SORT_COPY(np mp)
				loop count - 1 [
					start_l: start_l + 1
					mp: l + ((as integer! start_l/1) * width)
					SORT_COPY(mp np)
					start_r: start_r + 1
					np: r - ((as integer! start_r/1) * width) - width
					SORT_COPY(np mp)
				]
				SORT_COPY(temp np)
				start_l: start_l + 1
				start_r: start_r + 1
			]

			if start_l = end_l [
				l: l + (block_l * width)
			]
			if start_r = end_r [
				r: r - (block_r * width)
			]
			if is_done [break]
		]

		case [
			start_l < end_l [
				while [start_l < end_l][
					end_l: end_l - 1
					mp: l + ((as integer! end_l/1) * width)
					r: r - width
					SORT_SWAP(mp r)
				]
				w: (as integer! r - base) / width
			]
			start_r < end_r [
				while [start_r < end_r][
					end_r: end_r - 1
					np: r - ((as integer! end_r/1) * width) - width
					SORT_SWAP(l np)
					l: l + width
				]
				w: (as integer! l - base) / width
			]
			true [
				w: (as integer! l - base) / width
			]
		]
		w
	]

	;-- Partitions it into elements smaller than `base[pivot]`, followed by elements greater than or equal to `base[pivot]`.
	;--
	partition: func [
		base	[byte-ptr!]
		num		[integer!]
		npivot	[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc	[integer!]
		pnum	[int-ptr!]
		return:	[logic!]
		/local
			cmp i j t swaptype
			_base mp l r
			pivot
	][
		_base: base
		cmp: as cmpfunc! cmpfunc
		SORT_SWAPINIT(base width)
		mp: base + (npivot * width)
		SORT_SWAP(base mp)
		pivot: base
		base: base + width
		num: num - 1

		l: 0
		r: num
		mp: base
		while [l < r][
			either negative? cmp mp pivot op flags [
				l: l + 1
				mp: mp + width
			][
				break
			]
		]
		mp: base + (r * width) - width
		while [l < r][
			either not negative? cmp mp pivot op flags [
				r: r - 1
				mp: mp - width
			][
				break
			]
		]
		base: base + (l * width)
		num: r - l
		either l >= r [
			pnum/value: 0
		][
			pnum/value: partition-in-blocks base num pivot width op flags cmpfunc
		]
		pnum/value: pnum/value + l
		mp: _base + (pnum/value * width)
		SORT_SWAP(_base mp)
		l >= r
	]

	partition-equal: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		npivot	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc	[integer!]
		return:	[integer!]
		/local
			cmp i j t swaptype
			mp np l r
			pivot
	][
		cmp: as cmpfunc! cmpfunc
		SORT_SWAPINIT(base width)
		mp: base + (npivot * width)
		SORT_SWAP(base mp)
		pivot: base
		base: base + width
		num: num - 1

		l: 0
		r: num
		mp: base
		np: base + (r * width)
		forever [
			while [
				all [
					l < r
					not negative? cmp pivot mp op flags
				]
			][
				l: l + 1
				mp: mp + width
			]
			while [
				all [
					l < r
					negative? cmp pivot np - width op flags
				]
			][
				r: r - 1
				np: np - width
			]
			if l >= r [break]
			r: r - 1
			np: np - width
			SORT_SWAP(mp np)
			l: l + 1
			mp: mp + width
		]
		l + 1
	]

	break-patterns: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc	[integer!]
		/local
			i j t swaptype
			random modulus pos m other mp np
	][
		if num >= 8 [
			SORT_SWAPINIT(base width)
			random: num
			modulus: 1 << log-b num
			if num <> modulus [
				modulus: modulus << 1
			]
			pos: num >>> 1 and FFFFFFFEh
			m: 0
			while [m < 3][
				random: random xor (random << 13)
				random: random xor (random >>> 17)
				random: random xor (random << 5)
				other: random and (modulus - 1)
				if other >= num [
					other: other - num
				]
				mp: base + ((pos - 1 + m) * width)
				np: base + (other * width)
				SORT_SWAP(mp np)
				m: m + 1
			]
		]
	]

	choose-pivot: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc	[integer!]
		pivot	[int-ptr!]
		return:	[logic!]
		/local
			a b c swaps
	][
		a: num >>> 2
		b: a + a
		c: b + a
		swaps: 0
		
		if num >= 8 [
			if num >= SHORTEST_MEDIAN_OF_MEDIANS [
				sort-adjacent base :a :swaps width op flags cmpfunc
				sort-adjacent base :b :swaps width op flags cmpfunc
				sort-adjacent base :c :swaps width op flags cmpfunc
			]

			sort3 base :a :b :c :swaps width op flags cmpfunc
		]

		if swaps < MAX_SWAPS [
			pivot/1: b
			return swaps = 0
		]

		reverse base num width

		pivot/1: num - 1 - b
		true
	]

	reverse: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		/local
			i j t swaptype mp np
	][
		SORT_SWAPINIT(base width)
		mp: base
		np: base + (num * width) - width
		forever [
			if mp >= np [
				break
			]
			mp: mp + width
			np: np - width
			SORT_SWAP(mp np)
		]
	]

	recurse: func [
		base	[byte-ptr!]
		num		[integer!]
		pred	[byte-ptr!]
		pred?	[logic!]
		limit	[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc	[integer!]
		/local
			was-balanced was-partitioned was-p
			npivot likely-sorted
			cmp i j t swaptype m n mp np
			temp mid left right left-num right-num
	][
		cmp: as cmpfunc! cmpfunc
		SORT_SWAPINIT(base width)
		was-balanced: true
		was-partitioned: true
		forever [
			if num <= MAX_INSERTION [
				insertion-sort base num width op flags cmpfunc
				exit
			]
			if limit = 0 [
				heap-sort base num width op flags cmpfunc
				exit
			]

			unless was-balanced [
				break-patterns base num width op flags cmpfunc
				limit: limit - 1
			]

			npivot: 0
			likely-sorted: choose-pivot base num width op flags cmpfunc :npivot
			if all [
				was-balanced
				was-partitioned
				likely-sorted
			][
				if partial-insertion-sort base num width op flags cmpfunc [
					exit
				]
			]
			if pred? [
				mp: pred
				np: base + (npivot * width)
				unless negative? cmp mp np op flags [
					mid: partition-equal base num width npivot op flags cmpfunc
					base: base + (mid * width)
					num: num - mid
					continue
				]
			]

			mid: 0
			was-p: partition base num npivot width op flags cmpfunc :mid
			either mid > (num - mid) [
				was-balanced: num - mid >= (num / 8)
			][
				was-balanced: mid >= (num / 8)
			]
			was-partitioned: was-p
			left: base
			left-num: mid
			right: base + (mid * width)
			right-num: num - mid
			temp: right
			right: right + width
			right-num: right-num - 1
			either left-num < right-num [
				recurse left left-num pred pred? limit width op flags cmpfunc
				base: right
				num: right-num
				pred: temp
				pred?: true
			][
				recurse right right-num temp true limit width op flags cmpfunc
				base: left
				num: left-num
			]
		]
	]

	pbqsort: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc	[integer!]
		/local
			limit
	][
		limit: 1 + log-b num
		recurse base num base false limit width op flags cmpfunc
	]

	;-- max heapify
	sift-down: func [
		base	[byte-ptr!]
		_max	[integer!]
		node	[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc	[integer!]
		/local
			cmp left right greater i j t swaptype lp rp np gp
	][
		cmp: as cmpfunc! cmpfunc
		SORT_SWAPINIT(base width)
		forever [
			left: node * 2 + 1
			right: left + 1
			lp: base + (left * width)
			rp: base + (right * width)
			np: base + (node * width)
			greater: either all [
				right < _max
				negative? cmp lp rp op flags
			][right][left]

			gp: base + (greater * width)
			if any [
				greater >= _max
				not negative? cmp np gp op flags
			][break]
			SORT_SWAP(np gp)
			node: greater
		]
	]

	;-- guarantees `O(n log n)` worst-case.
	heap-sort: func [
		base			[byte-ptr!]
		num				[integer!]
		width			[integer!]
		op				[integer!]
		flags			[integer!]
		cmpfunc			[integer!]
		/local
			i			[int-ptr!]
			j			[int-ptr!]
			t			[integer!]
			swaptype	[integer!]
			m			[integer!]
			mp			[byte-ptr!]
	][
		m: num / 2 - 1
		while [m >= 0][
			sift-down base num m width op flags cmpfunc
			m: m - 1
		]

		SORT_SWAPINIT(base width)
		m: num - 1
		mp: base + (m * width)
		while [m > 0][
			SORT_SWAP(base mp)
			sift-down base m 0 width op flags cmpfunc
			mp: mp - width
			m: m - 1
		]
	]

	grail-rotate: func [
		base	[byte-ptr!]
		n1		[integer!]
		n2		[integer!]
		width	[integer!]
		/local end cnt b1 swaptype i j t
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
			cmp a b c
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
			cmp a b c
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
		/local cmp h
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
			cmp K k1 k2 m1 m2 ak
	][
		cmp: as cmpfunc! cmpfunc
		if any [n1 < 3 n2 < 3][
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
			cmp m pm0 pm1 h p0 p1 rest swaptype i j t
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
