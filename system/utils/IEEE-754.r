REBOL [
	Title:    "Red/System IEEE-754 library"
	Author:   "Nenad Rakocevic"
	File: 	  %IEEE-754.r
	Tabs:	 4
	Rights:   "Copyright (C) 2000-2011-2015 Eric Long,-2018 Red Foundation. All rights reserved."
	License:  "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Comment:  {
		64-bit split/to-native functions from http://www.nwlink.com/~ecotope1/reb/decimal.r
		Added 32-bit support, compacted a bit the existing code.
	}
]

IEEE-754: context [

	specials: [
		single [
			#INF	#{7F800000}
			#INF-	#{FF800000}
			#NaN	#{7FC00000}							;-- Quiet NaN
			#0-		#{80000000}
		]
		double [
			#INF	#{7FF0000000000000}
			#INF-	#{FFF0000000000000}
			#NaN	#{7FF8000000000000}					;-- Quiet NaN
			#0-		#{8000000000000000}
		]
	]

	split64: func [
		"Returns block containing three components of double floating point value"
		n [number!] /local sign exp frac
	][
		sign: either negative? n [n: negate n 1][0]

		either zero? n [exp: frac: 0][
			either zero? 1024 - exp: to integer! log-2 n [
				exp: 1023
			][
				if positive? (2 ** exp) - n [exp: exp - 1]
			]
			frac: n / (2 ** exp)

			either positive? exp: exp + 1023 [
				frac: frac - 1         					;-- drop the first bit for normals
				frac: frac * (2 ** 52) 					;-- make the remaining fraction an
														;-- "integer"
			][
				frac: 2 ** (51 + exp) * frac  			;-- denormals
				exp: 0
			]
		]
		reduce [sign exp frac]
	]

	to-binary64: func [
		"convert a numerical value into native binary format"
		n  [number! issue!]
		/rev     "reverse binary output"
		/rev4	 "reverse binary output by blocks of 4 bytes"
		/split	 "returns result as two integer values in unswapped order"
		/local out sign exp frac
	][
		either issue? n [
			out: copy select specials/double next n
		][
			set [sign exp frac] split64 n
			out: make binary! 8
			loop 6 [
				insert out to char! byte: frac // 256
				frac: frac - byte / 256
			]
			insert out to char! exp // 16 * 16  + frac
			insert out to char! exp / 16 + (128 * sign)
		]
		case [
			rev	  [copy reverse out]
			rev4  [
				out: reverse out
				append out copy/part out 4
				copy skip out 4
			]
			split [reduce [to integer! copy/part out 4 to integer! skip out 4]]
			'else [out]
		]
	]

	split32: func [
		"Returns block containing three components of single floating point value"
		n [number!] /local sign exp frac
	][
		sign: either negative? n [n: negate n 1][0]

		either zero? n [exp: frac: 0][
			either zero? 128 - exp: to integer! log-2 n [
				exp: 127
			][
				if positive? (2 ** exp) - n [exp: exp - 1]
			]
			frac: n / (2 ** exp)

			either positive? exp: exp + 127 [
				frac: frac - 1
				frac: frac * (2 ** 23) 					;-- make the remaining fraction an "integer"
			][
				frac: 2 ** (22 + exp) * frac  			;-- denormals
				exp: 0
			]
			frac: to integer! frac + .5
			if frac = 8388608 [							;-- 8388608 = 2 ** 23
				frac: 0
				exp: exp + 1
			]
		]
		reduce [sign exp frac]
	]

	to-binary32: func [
		"convert a numerical value into native binary format"
		n  [number! issue!]
		/rev     "reverse binary output"
		/local out sign exp frac
	][
		either issue? n [
			out: copy select specials/single next n
		][
			set [sign exp frac] split32 n
			out: make binary! 4
			loop 2 [
				insert out to char! byte: frac // 256
				frac: frac - byte / 256
			]
			insert out to char! exp * 128 // 256  + frac
			insert out to char! exp / 2 + (128 * sign)
		]
		either rev [copy reverse out][out]
	]
]