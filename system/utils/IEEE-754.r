REBOL [
	Title:    "Red/System IEEE-754 library"
	Author:   "Nenad Rakocevic"
	File: 	  %IEEE-754.r
	Tabs:	 4
	Rights:   "Copyright (C) 2000-2011-2015 Eric Long, Nenad Rakocevic. All rights reserved."
	License:  "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Comment:  {
		64-bit split/to-native functions from http://www.nwlink.com/~ecotope1/reb/decimal.r
		Added 32-bit support, compacted a bit the existing code.
	}
]

IEEE-754: context [
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
				frac: frac - 1         				; drop the first bit for normals
				frac: frac * (2 ** 52) 				; make the remaining fraction an
													; "integer"
			][
				frac: 2 ** (51 + exp) * frac  		; denormals
				exp: 0
			]
		]
		reduce [sign exp frac]
	]

	to-binary64: func [
		"convert a numerical value into native binary format"
		n  [number!]
		/rev     "reverse binary output"
		/local out sign exp frac
	][
		set [sign exp frac] split64 n
		out: make binary! 8
		loop 6 [
			insert out to char! byte: frac // 256
			frac: frac - byte / 256
		]
		insert out to char! exp // 16 * 16  + frac
		insert out to char! exp / 16 + (128 * sign)
		either rev [copy reverse out][out]
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
				frac: frac * (2 ** 23) 				; make the remaining fraction an "integer"
			][
				frac: 2 ** (22 + exp) * frac  		; denormals
				exp: 0
			]
			frac: to integer! frac + .5
		]
		reduce [sign exp frac]
	]

	to-binary32: func [
		"convert a numerical value into native binary format"
		n  [number!]
		/rev     "reverse binary output"
		/local out sign exp frac
	][
		set [sign exp frac] split32 n
		out: make binary! 4
		loop 2 [
			insert out to char! byte: frac // 256
			frac: frac - byte / 256
		]
	    insert out to char! exp * 128 // 256  + frac
	    insert out to char! exp / 2 + (128 * sign)
		either rev [copy reverse out][out]
	]
]