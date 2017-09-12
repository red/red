Red/System [
	Title:   "Red/System C library bindings"
	Author:  "Nenad Rakocevic"
	File: 	 %lib-C.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#import [
	LIBC-file cdecl [
		allocate:	 "malloc" [
			size		[integer!]
			return:		[byte-ptr!]
		]
		free:		 "free" [
			block		[byte-ptr!]
		]
		set-memory:	 "memset" [
			target		[byte-ptr!]
			filler		[byte!]
			size		[integer!]
			return:		[byte-ptr!]
		]
		move-memory: "memmove" [
			target		[byte-ptr!]
			source		[byte-ptr!]
			size		[integer!]
			return:		[byte-ptr!]
		]
		copy-memory: "memcpy" [
			target		[byte-ptr!]
			source		[byte-ptr!]
			size		[integer!]
			return:		[byte-ptr!]
		]
		compare-memory: "memcmp" [
			ptr1		[byte-ptr!]
			ptr2		[byte-ptr!]
			size		[integer!]
			return:		[integer!]
		]
		length?:	 "strlen" [
			buffer		[c-string!]
			return:		[integer!]
		]
		quit:		 "exit" [
			status		[integer!]
		]
		fflush:		 "fflush" [
			fd			[integer!]
			return:		[integer!]
		]
		putchar: 	 "putchar" [
			char		[byte!]
		]
		printf: 	 "printf"	[[variadic]]
		sprintf:	 "sprintf"	[[variadic] return: [integer!]]
		swprintf:	 "swprintf"	[[variadic] return: [integer!]]
		strtod:		 "strtod"  [
			str			[byte-ptr!]
			endptr		[byte-ptr!]
			return:		[float!]
		]
	]

	LIBM-file cdecl [
		ceil:		 "ceil" [
			d			[float!]
			return:		[float!]
		]
		floor:		 "floor" [
			d			[float!]
			return:		[float!]
		]
		pow: 		 "pow" [
			base		[float!]
			exponent	[float!]
			return:		[float!]
		]
		sin:		 "sin" [
			radians		[float!]
			return:		[float!]
		]
		cos:		 "cos" [
			radians		[float!]
			return:		[float!]
		]
		tan:		 "tan" [
			radians		[float!]
			return:		[float!]
		]
		asin:		 "asin" [
			radians		[float!]
			return:		[float!]
		]
		acos:		 "acos" [
			radians		[float!]
			return:		[float!]
		]
		atan:		 "atan" [
			radians		[float!]
			return:		[float!]
		]
		atan2:		"atan2" [
			y			[float!]
			x			[float!]
			return:		[float!]
		]
		ldexp:		"ldexp" [
			value		[float!]
			exponent	[integer!]
			return:		[float!]
		]
		frexp:		"frexp" [
			x			[float!]
			exponent	[int-ptr!]
			return:		[float!]
		]
		log-10:		"log10" [
			value		[float!]
			return:		[float!]
		]
		log-2:		"log" [
			value		[float!]
			return:		[float!]
		]
		sqrt:		"sqrt" [
			value		[float!]
			return:		[float!]
		]
	]
]

#either unicode? = yes [

	#define prin			[red/platform/prin*]
	#define prin-int		[red/platform/prin-int*]
	#define prin-hex		[red/platform/prin-hex*]
	#define prin-2hex		[red/platform/prin-2hex*]
	#define prin-float		[red/platform/prin-float*]
	#define prin-float32	[red/platform/prin-float32*]
	
][
	prin: func [s [c-string!] return: [c-string!] /local p][
		p: s
		while [p/1 <> null-byte][
			putchar p/1
			p: p + 1
		]
		s
	]

	prin-int: func [i [integer!] return: [integer!]][
		printf ["%i" i]
		i
	]
	
	prin-2hex: func [i [integer!] return: [integer!]][
		printf ["%02X" i]
		i
	]

	prin-hex: func [i [integer!] return: [integer!]][
		printf ["%08X" i]
		i
	]

	prin-float: func [f [float!] return: [float!] /local s p e?][
		either f - (floor f) = 0.0 [
			s: "                        "				;-- 23 + 1 for NUL
			sprintf [s "%g.0" f]
			assert s/1 <> null-byte
			p: s
			e?: no
			while [p/1 <> null-byte][
				if p/1 = #"e" [e?: yes]
				p: p + 1
			]
			if e? [p: p - 2 p/1: null-byte]
			prin s
		][
			printf ["%.16g" f]
		]
		f
	]

	prin-float32: func [f32 [float32!] return: [float32!] /local f [float!]][
		f: as float! f32
		either f - (floor f) = 0.0 [
			printf ["%g.0" f]
		][
			printf ["%.7g" f]
		]
		f32
	]
]