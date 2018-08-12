Red/System [
	Title:   "ripemd160"
	Author:  "bitbegin"
	File: 	 %ripemd160.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
]

;-- transplanted from https://github.com/rhash/RHash/blob/master/librhash/has160.c

ripemd160: context [
	;-- five boolean functions
	#define RMD_F1(x y z) ((x) xor (y) xor (z))
	#define RMD_F2(x y z) ((((y) xor (z)) and (x)) xor (z))
	#define RMD_F3(x y z) (((x) or not (y)) xor (z))
	#define RMD_F4(x y z) ((((x) xor (y)) and (z)) xor (y))
	#define RMD_F5(x y z) ((x) xor ((y) or not (z)))

	#define RMD_FUNC(RFUNC A B C D E X S K) [
		A: A + RFUNC((B) (C) (D)) + (X) + K
		A: ROTL32((A) (S)) + (E)
		C: ROTL32((C) 10)
	]

	;-- steps for the left and right half of algorithm
	#define RMD_L1(A B C D E X S) [RMD_FUNC(RMD_F1 A B C D E X S 0)]
	#define RMD_L2(A B C D E X S) [RMD_FUNC(RMD_F2 A B C D E X S 5A827999h)]
	#define RMD_L3(A B C D E X S) [RMD_FUNC(RMD_F3 A B C D E X S 6ED9EBA1h)]
	#define RMD_L4(A B C D E X S) [RMD_FUNC(RMD_F4 A B C D E X S 8F1BBCDCh)]
	#define RMD_L5(A B C D E X S) [RMD_FUNC(RMD_F5 A B C D E X S A953FD4Eh)]
	#define RMD_R1(A B C D E X S) [RMD_FUNC(RMD_F5 A B C D E X S 50A28BE6h)]
	#define RMD_R2(A B C D E X S) [RMD_FUNC(RMD_F4 A B C D E X S 5C4DD124h)]
	#define RMD_R3(A B C D E X S) [RMD_FUNC(RMD_F3 A B C D E X S 6D703EF3h)]
	#define RMD_R4(A B C D E X S) [RMD_FUNC(RMD_F2 A B C D E X S 7A6D76E9h)]
	#define RMD_R5(A B C D E X S) [RMD_FUNC(RMD_F1 A B C D E X S 0)]

	length: 0
	message: allocate 64
	hash: [67452301h EFCDAB89h 98BADCFEh 10325476h C3D2E1F0h]

	init: does [
		length: 0
		hash/1: 67452301h
		hash/2: EFCDAB89h
		hash/3: 98BADCFEh
		hash/4: 10325476h
		hash/5: C3D2E1F0h
		set-memory message #"^(00)" 64
	]


	process-block: func [hash [int-ptr!] X [byte-ptr!]
		/local
			A	[integer!]
			B	[integer!]
			C	[integer!]
			D	[integer!]
			E	[integer!]
			a1	[integer!]
			b1	[integer!]
			c1	[integer!]
			d1	[integer!]
			e1	[integer!]
	][
		A: hash/1
		B: hash/2
		C: hash/3
		D: hash/4
		E: hash/5

		;-- rounds of the left half
		RMD_L1(A B C D E (get-int-at X  0) 11)
		RMD_L1(E A B C D (get-int-at X  1) 14)
		RMD_L1(D E A B C (get-int-at X  2) 15)
		RMD_L1(C D E A B (get-int-at X  3) 12)
		RMD_L1(B C D E A (get-int-at X  4)  5)
		RMD_L1(A B C D E (get-int-at X  5)  8)
		RMD_L1(E A B C D (get-int-at X  6)  7)
		RMD_L1(D E A B C (get-int-at X  7)  9)
		RMD_L1(C D E A B (get-int-at X  8) 11)
		RMD_L1(B C D E A (get-int-at X  9) 13)
		RMD_L1(A B C D E (get-int-at X 10) 14)
		RMD_L1(E A B C D (get-int-at X 11) 15)
		RMD_L1(D E A B C (get-int-at X 12)  6)
		RMD_L1(C D E A B (get-int-at X 13)  7)
		RMD_L1(B C D E A (get-int-at X 14)  9)
		RMD_L1(A B C D E (get-int-at X 15)  8)

		RMD_L2(E A B C D (get-int-at X  7)  7)
		RMD_L2(D E A B C (get-int-at X  4)  6)
		RMD_L2(C D E A B (get-int-at X 13)  8)
		RMD_L2(B C D E A (get-int-at X  1) 13)
		RMD_L2(A B C D E (get-int-at X 10) 11)
		RMD_L2(E A B C D (get-int-at X  6)  9)
		RMD_L2(D E A B C (get-int-at X 15)  7)
		RMD_L2(C D E A B (get-int-at X  3) 15)
		RMD_L2(B C D E A (get-int-at X 12)  7)
		RMD_L2(A B C D E (get-int-at X  0) 12)
		RMD_L2(E A B C D (get-int-at X  9) 15)
		RMD_L2(D E A B C (get-int-at X  5)  9)
		RMD_L2(C D E A B (get-int-at X  2) 11)
		RMD_L2(B C D E A (get-int-at X 14)  7)
		RMD_L2(A B C D E (get-int-at X 11) 13)
		RMD_L2(E A B C D (get-int-at X  8) 12)

		RMD_L3(D E A B C (get-int-at X  3) 11)
		RMD_L3(C D E A B (get-int-at X 10) 13)
		RMD_L3(B C D E A (get-int-at X 14)  6)
		RMD_L3(A B C D E (get-int-at X  4)  7)
		RMD_L3(E A B C D (get-int-at X  9) 14)
		RMD_L3(D E A B C (get-int-at X 15)  9)
		RMD_L3(C D E A B (get-int-at X  8) 13)
		RMD_L3(B C D E A (get-int-at X  1) 15)
		RMD_L3(A B C D E (get-int-at X  2) 14)
		RMD_L3(E A B C D (get-int-at X  7)  8)
		RMD_L3(D E A B C (get-int-at X  0) 13)
		RMD_L3(C D E A B (get-int-at X  6)  6)
		RMD_L3(B C D E A (get-int-at X 13)  5)
		RMD_L3(A B C D E (get-int-at X 11) 12)
		RMD_L3(E A B C D (get-int-at X  5)  7)
		RMD_L3(D E A B C (get-int-at X 12)  5)

		RMD_L4(C D E A B (get-int-at X  1) 11)
		RMD_L4(B C D E A (get-int-at X  9) 12)
		RMD_L4(A B C D E (get-int-at X 11) 14)
		RMD_L4(E A B C D (get-int-at X 10) 15)
		RMD_L4(D E A B C (get-int-at X  0) 14)
		RMD_L4(C D E A B (get-int-at X  8) 15)
		RMD_L4(B C D E A (get-int-at X 12)  9)
		RMD_L4(A B C D E (get-int-at X  4)  8)
		RMD_L4(E A B C D (get-int-at X 13)  9)
		RMD_L4(D E A B C (get-int-at X  3) 14)
		RMD_L4(C D E A B (get-int-at X  7)  5)
		RMD_L4(B C D E A (get-int-at X 15)  6)
		RMD_L4(A B C D E (get-int-at X 14)  8)
		RMD_L4(E A B C D (get-int-at X  5)  6)
		RMD_L4(D E A B C (get-int-at X  6)  5)
		RMD_L4(C D E A B (get-int-at X  2) 12)

		RMD_L5(B C D E A (get-int-at X  4)  9)
		RMD_L5(A B C D E (get-int-at X  0) 15)
		RMD_L5(E A B C D (get-int-at X  5)  5)
		RMD_L5(D E A B C (get-int-at X  9) 11)
		RMD_L5(C D E A B (get-int-at X  7)  6)
		RMD_L5(B C D E A (get-int-at X 12)  8)
		RMD_L5(A B C D E (get-int-at X  2) 13)
		RMD_L5(E A B C D (get-int-at X 10) 12)
		RMD_L5(D E A B C (get-int-at X 14)  5)
		RMD_L5(C D E A B (get-int-at X  1) 12)
		RMD_L5(B C D E A (get-int-at X  3) 13)
		RMD_L5(A B C D E (get-int-at X  8) 14)
		RMD_L5(E A B C D (get-int-at X 11) 11)
		RMD_L5(D E A B C (get-int-at X  6)  8)
		RMD_L5(C D E A B (get-int-at X 15)  5)
		RMD_L5(B C D E A (get-int-at X 13)  6)

		a1: A
		b1: B
		c1: C
		d1: D
		e1: E

		A: hash/1
		B: hash/2
		C: hash/3
		D: hash/4
		E: hash/5

		;-- rounds of the right half
		RMD_R1(A B C D E (get-int-at X  5)  8)
		RMD_R1(E A B C D (get-int-at X 14)  9)
		RMD_R1(D E A B C (get-int-at X  7)  9)
		RMD_R1(C D E A B (get-int-at X  0) 11)
		RMD_R1(B C D E A (get-int-at X  9) 13)
		RMD_R1(A B C D E (get-int-at X  2) 15)
		RMD_R1(E A B C D (get-int-at X 11) 15)
		RMD_R1(D E A B C (get-int-at X  4)  5)
		RMD_R1(C D E A B (get-int-at X 13)  7)
		RMD_R1(B C D E A (get-int-at X  6)  7)
		RMD_R1(A B C D E (get-int-at X 15)  8)
		RMD_R1(E A B C D (get-int-at X  8) 11)
		RMD_R1(D E A B C (get-int-at X  1) 14)
		RMD_R1(C D E A B (get-int-at X 10) 14)
		RMD_R1(B C D E A (get-int-at X  3) 12)
		RMD_R1(A B C D E (get-int-at X 12)  6)

		RMD_R2(E A B C D (get-int-at X  6)  9)
		RMD_R2(D E A B C (get-int-at X 11) 13)
		RMD_R2(C D E A B (get-int-at X  3) 15)
		RMD_R2(B C D E A (get-int-at X  7)  7)
		RMD_R2(A B C D E (get-int-at X  0) 12)
		RMD_R2(E A B C D (get-int-at X 13)  8)
		RMD_R2(D E A B C (get-int-at X  5)  9)
		RMD_R2(C D E A B (get-int-at X 10) 11)
		RMD_R2(B C D E A (get-int-at X 14)  7)
		RMD_R2(A B C D E (get-int-at X 15)  7)
		RMD_R2(E A B C D (get-int-at X  8) 12)
		RMD_R2(D E A B C (get-int-at X 12)  7)
		RMD_R2(C D E A B (get-int-at X  4)  6)
		RMD_R2(B C D E A (get-int-at X  9) 15)
		RMD_R2(A B C D E (get-int-at X  1) 13)
		RMD_R2(E A B C D (get-int-at X  2) 11)

		RMD_R3(D E A B C (get-int-at X 15)  9)
		RMD_R3(C D E A B (get-int-at X  5)  7)
		RMD_R3(B C D E A (get-int-at X  1) 15)
		RMD_R3(A B C D E (get-int-at X  3) 11)
		RMD_R3(E A B C D (get-int-at X  7)  8)
		RMD_R3(D E A B C (get-int-at X 14)  6)
		RMD_R3(C D E A B (get-int-at X  6)  6)
		RMD_R3(B C D E A (get-int-at X  9) 14)
		RMD_R3(A B C D E (get-int-at X 11) 12)
		RMD_R3(E A B C D (get-int-at X  8) 13)
		RMD_R3(D E A B C (get-int-at X 12)  5)
		RMD_R3(C D E A B (get-int-at X  2) 14)
		RMD_R3(B C D E A (get-int-at X 10) 13)
		RMD_R3(A B C D E (get-int-at X  0) 13)
		RMD_R3(E A B C D (get-int-at X  4)  7)
		RMD_R3(D E A B C (get-int-at X 13)  5)

		RMD_R4(C D E A B (get-int-at X  8) 15)
		RMD_R4(B C D E A (get-int-at X  6)  5)
		RMD_R4(A B C D E (get-int-at X  4)  8)
		RMD_R4(E A B C D (get-int-at X  1) 11)
		RMD_R4(D E A B C (get-int-at X  3) 14)
		RMD_R4(C D E A B (get-int-at X 11) 14)
		RMD_R4(B C D E A (get-int-at X 15)  6)
		RMD_R4(A B C D E (get-int-at X  0) 14)
		RMD_R4(E A B C D (get-int-at X  5)  6)
		RMD_R4(D E A B C (get-int-at X 12)  9)
		RMD_R4(C D E A B (get-int-at X  2) 12)
		RMD_R4(B C D E A (get-int-at X 13)  9)
		RMD_R4(A B C D E (get-int-at X  9) 12)
		RMD_R4(E A B C D (get-int-at X  7)  5)
		RMD_R4(D E A B C (get-int-at X 10) 15)
		RMD_R4(C D E A B (get-int-at X 14)  8)

		RMD_R5(B C D E A (get-int-at X 12)  8)
		RMD_R5(A B C D E (get-int-at X 15)  5)
		RMD_R5(E A B C D (get-int-at X 10) 12)
		RMD_R5(D E A B C (get-int-at X  4)  9)
		RMD_R5(C D E A B (get-int-at X  1) 12)
		RMD_R5(B C D E A (get-int-at X  5)  5)
		RMD_R5(A B C D E (get-int-at X  8) 14)
		RMD_R5(E A B C D (get-int-at X  7)  6)
		RMD_R5(D E A B C (get-int-at X  6)  8)
		RMD_R5(C D E A B (get-int-at X  2) 13)
		RMD_R5(B C D E A (get-int-at X 13)  6)
		RMD_R5(A B C D E (get-int-at X 14)  5)
		RMD_R5(E A B C D (get-int-at X  0) 15)
		RMD_R5(D E A B C (get-int-at X  3) 13)
		RMD_R5(C D E A B (get-int-at X  9) 11)
		RMD_R5(B C D E A (get-int-at X 11) 11)

		;-- update intermediate hash
		D: D + c1 + hash/2
		hash/2: hash/3 + d1 + E
		hash/3: hash/4 + e1 + A
		hash/4: hash/5 + a1 + B
		hash/5: hash/1 + b1 + C
		hash/1: D
	]

	update: func [msg [byte-ptr!] size [integer!]
		/local
			index		[integer!]
			left		[integer!]
	][
		index: length and 63
		length: length + size

		;-- fill partial block
		if index <> 0 [
			left: 64 - index
			copy-memory message + index msg either size < left [size][left]
			if size < left [exit]

			process-block hash message
			msg: msg + left
			size: size - left
		]

		while [size >= 64][
			process-block hash msg
			msg: msg + 64
			size: size - 64
		]

		if size <> 0 [
			copy-memory message msg size
		]
	]

	final: func [result [byte-ptr!]
		/local
			index	[integer!]
			shift	[integer!]
			p		[int-ptr!]
			temp	[integer!]
	][
		index: (length and 63) >> 2
		shift: (length and  3) * 8

		temp: not (FFFFFFFFh << shift)
		temp: temp and get-int-at message index
		put-int-at message index temp
		temp: 80h << shift
		temp: temp xor get-int-at message index
		put-int-at message index temp
		index: index + 1

		if index > 14 [
			while [index < 16][
				put-int-at message index 0
				index: index + 1
			]
			process-block hash message
			index: 0
		]
		while [index < 14][
			put-int-at message index 0
			index: index + 1
		]
		put-int-at message 14 length << 3
		put-int-at message 15 length >>> 29
		process-block hash message

		put-int-at result 0 hash/1
		put-int-at result 1 hash/2
		put-int-at result 2 hash/3
		put-int-at result 3 hash/4
		put-int-at result 4 hash/5
	]
]