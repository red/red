Red/System [
	Title:	"Mersenne Twister 19937	Random Function"
	Author: "Xie Qingtian"
	File: 	%random.reds
	Tabs:	4
	Rights: "Copyright (C) 2014-2015 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
	Notes: {
		Reference: http://en.wikipedia.org/wiki/Mersenne_twister
		Freely inspired by c-standard-library:
		http://code.google.com/p/c-standard-library/source/browse/src/internal/_rand.c
	}
	Possible improvement: {
		SIMD-oriented Fast Mersenne Twister (SFMT)
		http://www.math.sci.hiroshima-u.ac.jp/~%20m-mat/MT/SFMT/index.html
	}
]

_random: context [
	#define	MT_RANDOM_STATE_SIZE		624
	#define	MT_RANDOM_STATE_HALF_SIZE 	397

	idx: 0
	table: as int-ptr! 0

	srand: func [
		seed [integer!]
		/local c n
	][
		table/1: seed
		idx: 0
		c: 1
		n: 1
		until [
			n: n + 1
			table/n: table/c >> 30 xor table/c * 1812433253 + c
			c: c + 1
			n = MT_RANDOM_STATE_SIZE
		]
	]

	rand: func [
		return:   [integer!]
		/local
			c	  [integer!]
			n	  [integer!]
			state [integer!]
	][
		c: 1
		n: 2

		if idx = MT_RANDOM_STATE_SIZE [							;-- Refill rand	state table	if exhausted
			idx: 0
			until [
				state: table/c and 80000000h or (table/n and 7FFFFFFFh)
				n: c - 1 + MT_RANDOM_STATE_HALF_SIZE % MT_RANDOM_STATE_SIZE	+ 1		;--	need to	plus one due to	1-base array

				either state and 00000001h <> 0 [				;--	state is odd
					table/c: state >> 1 xor table/n xor 9908B0DFh
				][
					table/c: state >> 1 xor table/n
				]
				c: c + 1
				n: c + 1
				c = MT_RANDOM_STATE_SIZE
			]

			c: MT_RANDOM_STATE_HALF_SIZE
			n: MT_RANDOM_STATE_SIZE
			state: table/n and 80000000h or (table/1 and 7FFFFFFFh)
			either state and 00000001h <> 0 [
				table/n: state >> 1 xor table/c xor 9908B0DFh
			][
				table/n: state >> 1 xor table/c
			]
		]
		
		idx:   idx + 1
		state: table/idx

		;--	Add	a little extra mixing
		state: state >> 11 xor state
		state: state << 7  and 9D2C5680h xor state
		state: state << 15 and EFC60000h xor state
		state: state >> 18 xor state
		state
	]

	rand-secure: func [
		return:	[integer!]
		/local
			i	 [integer!]
	] [
		i: 0
		crypto/urandom (as byte-ptr! :i) 4
		i and 7FFFFFFFh									;-- range 0-2147483647 inclusive
	]

	int-uniform-distr: func [
		secure?	[logic!]
		max		[integer!]
		return:	[integer!]
		/local
			limit	 [integer!]
			rnd		 [integer!]
			neg?	 [logic!]
	] [
		case [
			max > 0 [neg?: false]
			max < 0 [
				;-- Special case
				;-- when max is -2147483648, we generate number in maxiumn range.
				;-- the randomness only depends on the rand function.
				if max = -2147483648 [
					rnd: either secure? [rand-secure] [rand]
					return -1 - rnd
				]
				max: 0 - max
				neg?: true
			]
			max = 0 [return 0]
		]
		limit: 2147483647 / max * max
		until [
			rnd: either secure? [rand-secure] [rand]
			limit > rnd
		]
		rnd: rnd % max + 1
		either neg? [0 - rnd][rnd]
	]

	init: does [
		table: as int-ptr! allocate MT_RANDOM_STATE_SIZE * size? integer!
		srand 19650218
		hash-secret: as-integer :hash-secret
		;#either OS = 'Linux [
		;	if 1 > crypto/getrandom as byte-ptr! :hash-secret 4 no [	;-- fall back on using /dev/urandom
		;		crypto/urandom as byte-ptr! :hash-secret 4
		;	]
		;][
		;	crypto/urandom as byte-ptr! :hash-secret 4
		;]
	]
]