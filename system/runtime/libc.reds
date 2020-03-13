Red/System [
	Title:   "Red/System C library bindings"
	Author:  "Nenad Rakocevic"
	File: 	 %lib-C.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
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
		realloc:	"realloc" [		"Resize and return allocated memory."
			memory			[byte-ptr!]
			size			[integer!]
			return:			[byte-ptr!]
		]
		set-memory:	 "memset" [
			target		[byte-ptr!]
			filler		[byte!]
			size		[integer!]
			return:		[byte-ptr!]
		]
		#either debug? = yes [libc.move-memory:][move-memory:] "memmove" [
			target		[byte-ptr!]
			source		[byte-ptr!]
			size		[integer!]
			return:		[byte-ptr!]
		]
		#either debug? = yes [libc.copy-memory:][copy-memory:] "memcpy" [
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
		qsort:		"qsort" [
			base		[byte-ptr!]
			nitems		[integer!]
			width		[integer!]
			cmpfunc		[function! [[cdecl] a [int-ptr!] b [int-ptr!] return: [integer!]]]
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
		fmod:		"fmod" [
			x           [float!]
			y           [float!]
			return:     [float!]
		]
	]
]

#if debug? = yes [

	memguard: context [
		enabled?: no

		list: as int-ptr! allocate 4096
		tail:		list + 1024
		top:		list

		ignored: as int-ptr! allocate 256
		ignored/1: 0

		last-token: 0
		flag-skip-next: no

		push: func [v [integer!]][
			assert top < tail
			top/value: v
			top: top + 1
		]
		pop: func [return: [integer!]][
			assert top > list
			top: top - 1
			top/value
		]

		mark: func [return: [integer!]] [
			push 0
			last-token: last-token + 1
			last-token
		]
		back: func [token [integer!]] [
			assert token = last-token					;-- `back` should have a corresponding `mark`
			last-token: last-token - 1
			until [0 = pop]
		]
		reset: does [									;-- use it when memguard stack can't be preserved
			top: list
			last-token: 0
			flag-skip-next: no
		]
		
		ignore-node: func [node [int-ptr!]] [
			;@@ TBD: stack of intervals?
			assert not zero? as-integer node
			assert zero? ignored/1
			ignored/1: as-integer node
		]

		ignored?: func [h [byte-ptr!] t [byte-ptr!] return: [logic!]
			/local s [int-ptr!] ih [byte-ptr!] it [byte-ptr!]
		][
			unless enabled? [return yes]
			s: as int-ptr! ignored/1
			s: as int-ptr! s/value
			assert not zero? ignored/1
			ih: as byte-ptr! s/4
			it: ih + s/3
			assert not zero? as-integer ih
			assert not zero? as-integer it
			all [ih <= h t <= it]
		]

		add-node: func [node [int-ptr!]][
			push as-integer node						;-- node/value is series!
		]

		add-range: func [h [byte-ptr!] t [byte-ptr!]][
			push 0 - as-integer h
			push 0 - as-integer t
		]

		get-next-region: func [
			&p [int-ptr!]								;-- in/out: stack pointer
			&h [int-ptr!]								;-- out: head
			&t [int-ptr!]								;-- out: tail
			&n [int-ptr!]								;-- out: node (if any, else zero)
			return: [logic!]							;-- true if the region exists
			/local p [int-ptr!] n [int-ptr!] s [int-ptr!]
		][
			p: as int-ptr! &p/value
			p: p - 1
			assert p >= list
			case [
				zero? p/value [return no]				;-- end of the marked space
				p/value > 0 [							;-- node found
					n: as int-ptr! p/value
					s: as int-ptr! n/value
					&n/value: as-integer n
					&h/value: s/4							;-- series!/offset
					&t/value: &h/value + s/3				;-- series!/offset + series!/size
				]
				true [									;-- fixed range
					&t/value: 0 - p/value
					p: p - 1
					assert not zero? p/value
					assert p >= list
					&h/value: 0 - p/value
					&n/value: 0
				]
			]
			assert &t/value >= &h/value
			&p/value: as-integer p
			yes
		]

		check-range: func [
			hd	[byte-ptr!]
			tl	[byte-ptr!]
			return: [logic!]							;-- yes if region is allowed
			/local
				reg-hd [integer!] reg-tl [integer!] node [integer!]
				s [int-ptr!] p [integer!] heading? [logic!]
		][
			reg-hd: 0  reg-tl: 0  node: 0

			assert hd <= tl
			if top = list [return yes]					;-- do not do checks outside of mark/back scope
			if ignored? hd tl [return yes]
			
			assert enabled?
			p: as-integer top
			heading?: no
			while [get-next-region :p :reg-hd :reg-tl :node][
				assert reg-tl >= reg-hd

				if all [reg-hd <= as-integer hd tl <= as byte-ptr! reg-tl] [return yes]		;-- all OK

				if all [reg-hd <= as-integer hd hd <= as byte-ptr! reg-tl] [
					print-line  "*** MEMGUARD ALERT: over the tail access detected"
					print-line ["    registered series:^-" as byte-ptr! reg-hd ".." as byte-ptr! reg-tl]
					print-line ["    requested region: ^-" hd ".." tl]
					dump-regions
					assert 1 = 0
				]

				if all [reg-hd <= as-integer tl tl <= as byte-ptr! reg-tl] [
					print-line  "*** MEMGUARD ALERT: before the head access detected"
					print-line ["    registered series:^-" as byte-ptr! reg-hd ".." as byte-ptr! reg-tl]
					print-line ["    requested region: ^-" hd ".." tl]
					dump-regions
					assert 1 = 0
				]
			]
			print-line  "*** MEMGUARD ALERT: access to unallowed memory region detected"
			print-line ["    requested region: ^-" hd ".." tl]
			dump-regions
			; assert 1 = 0		;-- better to have assertion in a macro - to report the line number
			no
		]

		dump-regions: func [/local p [integer!] h [integer!] t [integer!] n [integer!] i [integer!]] [
			h: 0  t: 0  n: 0  i: 1
			print-line "  * Defined regions so far are:"
			p: as-integer top
			while [get-next-region :p :h :t :n] [
				either zero? n [
					print-line ["^-^-" i "^-" as byte-ptr! h ".." as byte-ptr! t " (fixed)"]
				][
					print-line ["^-^-" i "^-" as byte-ptr! h ".." as byte-ptr! t " (node=" as byte-ptr! n ")"]
				]
				i: i + 1
			]
		]
	]

	copy-memory: func [ 
		target		[byte-ptr!]
		source		[byte-ptr!]
		size		[integer!]				;; number of bytes to copy
		return:		[byte-ptr!]
	][
		assert target <> source
		assert any [
			(target + size) <= source
			(source + size) <= target
		]
		; memguard/check-range source source + size
		unless memguard/flag-skip-next [assert yes = memguard/check-range target target + size]
		memguard/flag-skip-next: no
		libc.copy-memory target source size
	]

	move-memory: func [ 
		target		[byte-ptr!]
		source		[byte-ptr!]
		size		[integer!]				;; number of bytes to copy
		return:		[byte-ptr!]
	][
		; memguard/check-range source source + size
		unless memguard/flag-skip-next [assert yes = memguard/check-range target target + size]
		memguard/flag-skip-next: no
		libc.move-memory target source size
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

	prin-float: func [
		f		[float!]
		return: [float!]
		/local s [c-string!] p [c-string!] e? [logic!] d [int-ptr!]
	][
		d: as int-ptr! :f
		case [
			d/2 = 7FF80000h [
				prin "1.#NaN"
			]
			f - (floor f) = 0.0 [
				s: "                        "				;-- 23 + 1 for NUL
				sprintf [s "%g.0" f]
				assert s/1 <> null-byte
				p: s
				e?: no
				while [p/1 <> null-byte][
					if p/1 = #"e" [e?: yes]
					p: p + 1
				]
				if any [e? p/-2 = #"F"][p: p - 2 p/1: null-byte]
				prin s
			]
			true [printf ["%.16g" f]]
		]
		f
	]

	prin-float32: func [f32 [float32!] return: [float32!] /local f [float!] d [int-ptr!]][
		d: as int-ptr! :f32
		case [
			d/1 = 7FC00000h [prin "1.#NaN"]
			d/1 = 7F800000h [prin "1.#INF"]
			d/1 = FF800000h [prin "-1.#INF"]
			true [
				f: as float! f32
				either f - (floor f) = 0.0 [
					printf ["%g.0" f]
				][
					printf ["%.7g" f]
				]
			]
		]
		f32
	]
]