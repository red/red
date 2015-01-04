Red/System [
	Title:	"Sorting algorithm"
	Author: "Xie Qingtian"
	File: 	%sort.reds
	Tabs:	4
	Rights: "Copyright (C) 2014 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
	Notes: {
		Qsort: ported from Bentley & McIlroy's "Engineering a Sort Function".
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

_qsort: context [

	#define SWAPINIT(a width) [
		swaptype: either any [
			(as-integer a) % (size? integer!) <> 0
			width % (size? integer!) > 0
		][
			2
		][
			either width = size? integer! [0][1]
		]
	]

	#define SWAP(a b) [
		either zero? swaptype [
			i: as int-ptr! a
			j: as int-ptr! b
			t: i/1
			i/1: j/1
			j/1: t
		][
			swapfunc a b width swaptype
		]
	]

	swapfunc: func [
		a		 [byte-ptr!]
		b		 [byte-ptr!]
		n		 [integer!]
		swaptype [integer!]
		/local cnt i j ii jj t1 t2
	][
		either swaptype > 1 [
			cnt: n
			i: a
			j: b
			until [
				t1: i/1
				i/1: j/1
				j/1: t1
				i: i + 1
				j: j + 1
				cnt: cnt - 1
				zero? cnt
			]
		][
			cnt: n / 4
			ii: as int-ptr! a
			jj: as int-ptr! b
			until [
				t2: ii/1
				ii/1: jj/1
				jj/1: t2
				ii: ii + 1
				jj: jj + 1
				cnt: cnt - 1
				zero? cnt
			]
		]
	]

	med3: func [
		a		[byte-ptr!]
		b		[byte-ptr!]
		c		[byte-ptr!]
		op		[integer!]
		cmpfunc [integer!]
		return: [byte-ptr!]
		/local cmp
	][
		cmp: as cmpfunc! cmpfunc
		either negative? cmp a b op 0 [
			either negative? cmp b c op 0 [b][
				either negative? cmp a c op 0 [c][a]
			]
		][
			either positive? cmp b c op 0 [b][
				either negative? cmp a c op 0 [a][c]
			]
		]
	]

	sort: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
		/local
			cmp a b c d m n end i j t r part result swaptype swapped?
	][
		cmp: as cmpfunc! cmpfunc
		until [
			SWAPINIT(base width)
			swapped?: false
			end: base + (num * width)

			if num < 8 [								;-- Insertion sort on smallest arrays
				m: base + width
				while [m < end][
					n: m
					until [
						if positive? cmp (n - width) n op flags [
							SWAP((n - width) n)
						]
						n: n - width
						n <= base
					]
					m: m + width
				]
				exit
			]
			m: base + (num / 2 * width)
			a: base
			b: base + ((num - 1) * width)
			if num > 40 [
				part: num / 8 * width
				a: med3 a a + part a + (2 * part) op cmpfunc
				m: med3 m - part m m + part op cmpfunc
				b: med3 b - (2 * part) b - part b op cmpfunc
			]
			m: med3 a m b op cmpfunc
			
			SWAP(base m)
			a: base + width
			b: a
			c: base + ((num - 1) * width)
			d: c
			until [
				while [
					result: cmp b base op flags
					all [
						b <= c
						result <= 0
					]
				][
					if zero? result [
						swapped?: true
						SWAP(a b)
						a: a + width
					]
					b: b + width
				]
				while [
					result: cmp c base op flags
					all [
						b <= c
						result >= 0
					]
				][
					if zero? result [
						swapped?: true
						SWAP(c d)
						d: d - width
					]
					c: c - width
				]
				if b <= c [
					SWAP(b c)
					swapped?: true
					b: b + width
					c: c - width
				]
				b > c
			]
			unless swapped? [
				m: base + width
				while [m < end][
					n: m
					until [
						if positive? cmp (n - width) n op flags [
							SWAP((n - width) n)
						]
						n: n - width
						n <= base
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
				sort base r / width width op flags cmpfunc
			]
			r: as-integer d - c
			if r > width [
				base: end - r
				num: r / width
			]
			r <= width
		]
	]
]
