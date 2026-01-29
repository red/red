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
		* Mergesort: implement Powersort https://www.wild-inter.net/publications/munro-wild-2018
		  stable, needs N / 2 auxiliary memory
		* Quicksort: implement Adaptive Symmetry Partition Sort https://arxiv.org/pdf/0706.0046
		  unstable, no extra memory needed
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

	#define SORT_SWAP_N(a b n) [swapfunc a b n * width swaptype]

	#define SORT_ARGS_EXT_DEF [
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
	]
	
	#define SORT_ARGS_EXT [width op flags cmpfunc]

	#define SORT_CMP(a b) [cmp a b op flags]

	#define SORT_COPY(dst src) [
		ii: as int-ptr! dst
		jj: as int-ptr! src
		loop width >> 2 [
			ii/value: jj/value
			ii: ii + 1
			jj: jj + 1
		]
	]

	swapfunc: func [
		a		 [byte-ptr!]
		b		 [byte-ptr!]
		n		 [integer!]
		swaptype [integer!]
		/local
			ii jj	[int-ptr!]
			t2		[integer!]
			i j		[byte-ptr!]
			t1		[byte!]
	][
		either zero? swaptype [
			ii: as int-ptr! a
			jj: as int-ptr! b
			loop n >> 2 [
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

	;-- mergesort

	run!: alias struct! [
		begin	[byte-ptr!]
		power	[integer!]
	]

	get-run-end: func [
		begin	[byte-ptr!]
		end		[byte-ptr!]
		SORT_ARGS_EXT_DEF
		return: [byte-ptr!]
		/local
			j	[byte-ptr!]
			cmp [cmpfunc!]
			swaptype [integer!]
	][
		SORT_SWAPINIT(begin width)
		cmp: as cmpfunc! cmpfunc

		j: begin
		if j = end [return j]
		if j + width = end [return j + width]
		either positive? SORT_CMP(j (j + width)) [
			until [
				j: j + width
				any [
					j + width = end
					0 >= SORT_CMP(j (j + width))
				]
			]
			;-- reverse it
			end: j
			while [begin < end][
				SORT_SWAP(begin end)
				begin: begin + width
				end: end - width
			]
		][
			until [
				j: j + width
				any [
					j + width = end
					0 < SORT_CMP(j (j + width))
				]
			]
		]
		j + width
	]

	cmp-args!: alias struct! [
		SORT_ARGS_EXT_DEF
	]

	merge-runs: func [	;-- Merges runs A[l..m-1] and A[m..r) in-place into A[l..r)
		l		[byte-ptr!]
		m		[byte-ptr!]
		r		[byte-ptr!]
		buffer	[byte-ptr!]
		args	[cmp-args!]
		/local
			n1 n2	[integer!]
			width	[integer!]
			op		[integer!]
			flags	[integer!]
			ii jj	[int-ptr!]
			cmp		[cmpfunc!]
			c1 c2 e1 e2 p c [byte-ptr!]
	][
		cmp: as cmpfunc! args/cmpfunc
		width: args/width
		op: args/op
		flags: args/flags

		n1: as-integer m - l
		n2: as-integer r - m
		either n1 <= n2 [
			copy-memory buffer l n1
			c1: buffer
			e1: buffer + n1
			c2: m
			e2: r
			p: l
			while [
				all [c1 < e1 c2 < e2]
			][
				either positive? SORT_CMP(c1 c2) [
					c: c2
					c2: c2 + width
				][
					c: c1
					c1: c1 + width
				]
				SORT_COPY(p c)
				p: p + width
			]
			if c1 < e1 [copy-memory p c1 (as-integer e1 - c1)]
		][
			copy-memory buffer m n2
			c1: m - width
			c2: buffer + n2 - width
			p: r - width
			while [
				all [c1 >= l c2 >= buffer]
			][
				either positive? SORT_CMP(c1 c2) [
					c: c1
					c1: c1 - width
				][
					c: c2
					c2: c2 - width
				]
				SORT_COPY(p c)
				p: p - width
			]
			if c2 >= buffer [copy-memory l buffer (as-integer c2 - buffer) + width]
		]
	]

	#define INSERTION_SORT(begin end n-sorted) [
		pn: begin + n-sorted
		while [pn < end][
			pm: pn
			while [positive? SORT_CMP((pm - width) pm)][
				SORT_SWAP((pm - width) pm)
				pm: pm - width
				if pm <= begin [break]
			]
			pn: pn + width
		]
	]

	mergesort: func [
		base	[byte-ptr!]
		num		[integer!]
		width	[integer!]
		op		[integer!]
		flags	[integer!]
		cmpfunc [integer!]
		/local
			n-stack top powerA lenA lenB [integer!]
			beginA endA beginB endB end p pn pm [byte-ptr!]
			min-run-len swaptype l r n-beginA n-beginB n-endB [integer!]
			a b		[logic!]
			args	[cmp-args! value]
			buffer	[byte-ptr!]
			cmp		[cmpfunc!]
			stack top-run [run!]
	][
		if num < 2 [exit]

		SORT_SWAPINIT(base width)
		cmp: as cmpfunc! cmpfunc

		buffer: allocate num / 2 * width
		n-stack: 1 + log-b num
		stack: as run! system/stack/allocate (size? run!) >> 2 * n-stack	;-- allocate 1 slot = 4 bytes
		set-memory as byte-ptr! stack null-byte n-stack * size? run!
		top: 0

		min-run-len: 24 * width
		end: base + (num * width)
		args/width: width
		args/op: op
		args/flags: flags
		args/cmpfunc: cmpfunc

		beginA: base
		endA: get-run-end base end SORT_ARGS_EXT
	 	powerA: 0

		lenA: as-integer endA - beginA
		if lenA < min-run-len [		;-- extend to min run length
			p: beginA + min-run-len
			endA: either p < end [p][end]
			;-- insertion sort begin with unsorted data
			INSERTION_SORT(beginA endA lenA)
		]
		while [endA < end][
			beginB: endA
			endB: get-run-end endA end SORT_ARGS_EXT
			lenB: as-integer endB - beginB
			if lenB < min-run-len [
				p: beginB + min-run-len
				endB: either p < end [p][end]
				;-- insertion sort begin with unsorted data
				INSERTION_SORT(beginB endB lenB)
			]

			n-beginA: (as-integer beginA - base) / width
			n-beginB: (as-integer beginB - base) / width
			n-endB:   (as-integer endB - base) / width
			l: n-beginA + n-beginB
			r: n-beginB + n-endB
			powerA: 0
			while [
				a: l >= num
				b: r >= num
				a = b
			][
				powerA: powerA + 1
				if a [
					l: l - num
					r: r - num
				]
				l: l << 1
				r: r << 1
			]
			powerA: powerA + 1

			while [
				top-run: stack + top
				top-run/power > powerA
			][
				top: top - 1
				merge-runs top-run/begin beginA endA buffer :args
				beginA: top-run/begin
			]

			top: top + 1
			top-run: stack + top
			top-run/begin: beginA
			top-run/power: powerA
			beginA: beginB
			endA: endB
		]

		while [top > 0][
			top-run: stack + top
			top: top - 1
			merge-runs top-run/begin beginA end buffer :args
			beginA: top-run/begin
		]
		free buffer
	]

	;-- quicksort

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
					pb: base + (num - m * width)
					SORT_SWAP_N(base pb left)
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
					all [rc < 0 pb <= pc]
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
					all [rc > 0 pb <= pc]
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

	qsort: func [
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
