Red/System [
	Title:   "Red/System C library bindings"
	Author:  "Nenad Rakocevic"
	File: 	 %lib-C.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
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
		length?:	 "strlen" [
			buffer		[c-string!]
			return:		[integer!]
		]
		quit:		 "exit" [
			status		[integer!]
		]
		putchar: 	 "putchar" [
			char		[byte!]
		]
		printf: 	 "printf" [[variadic]]
		sprintf:	 "sprintf" [[variadic]]
		strtod:		 "strtod" [
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
		float-power: "pow" [
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
	]
]

#either unicode? = yes [

	#define prin			[red/platform/prin*]
	#define prin-int		[red/platform/prin-int*]
	#define prin-hex		[red/platform/prin-hex*]
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

	prin-hex: func [i [integer!] return: [integer!]][
		printf ["%08X" i]
		i
	]

	prin-float: func [f [float!] return: [float!]][
		printf ["%.16g" f]
		f
	]

	prin-float32: func [f [float32!] return: [float32!]][
		printf ["%.7g" as-float f]
		f
	]
]