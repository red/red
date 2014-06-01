Red/System [
	Title:   "binary! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	binary: 	 %binary.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/red-system/runtime/BSL-License.txt
	}
]

binary: context [
	verbose: 0

	push: func [
		binary [red-binary!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/push"]]
		
		copy-cell as red-value! binary stack/push*
	]

	get-length: func [
		bin		   [red-binary!]
		return:	   [integer!]
		/local
			s	   [series!]
			offset [integer!]
	][
		s: GET_BUFFER(bin)
		offset: bin/head
		if negative? offset [offset: 0]					;-- @@ beware of symbol/index leaking here...
		(as-integer s/tail - s/offset) - offset
	]

	get-byte: func [
		p	    [byte-ptr!]
		return: [integer!]
		/local
			p4	[int-ptr!]
	][
		as-integer p/value
	]

	get-position: func [
		base	   [integer!]
		return:	   [integer!]
		/local
			bin	   [red-binary!]
			index  [red-integer!]
			s	   [series!]
			offset [integer!]
			max	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/get-position"]]

		bin: as red-binary! stack/arguments
		index: as red-integer! bin + 1

		assert TYPE_OF(bin) = TYPE_BINARY
		assert TYPE_OF(index) = TYPE_INTEGER

		s: GET_BUFFER(bin)

		if all [base = 1 index/value <= 0][base: base - 1]
		offset: bin/head + index/value - base			;-- index is one-based
		if negative? offset [offset: 0]
		max: (as-integer s/tail - s/offset)
		if offset > max [offset: max]

		offset
	]

	equal?: func [
		bin1	  [red-binary!]							;-- first operand
		bin2	  [red-binary!]							;-- second operand
		op		  [integer!]							;-- type of comparison
		match?	  [logic!]								;-- match bin2 within bin1 (sizes matter less)
		return:	  [logic!]
		/local
			s1	  [series!]
			s2	  [series!]
			size1 [integer!]
			size2 [integer!]
			end	  [byte-ptr!]
			p1	  [byte-ptr!]
			p2	  [byte-ptr!]
			p4	  [int-ptr!]
			c1	  [integer!]
			c2	  [integer!]
			lax?  [logic!]
			res	  [logic!]
	][
		;@@ can I cast binary value into string and use string's comparison instead of this code?

		s1: GET_BUFFER(bin1)
		s2: GET_BUFFER(bin2)
		size2: (as-integer s2/tail - s2/offset) - bin2/head

		either match? [
			if zero? size2 [
				return any [op = COMP_EQUAL op = COMP_STRICT_EQUAL]
			]
		][
			size1: (as-integer s1/tail - s1/offset) - bin1/head

			either size1 <> size2 [							;-- shortcut exit for different sizes
				if any [op = COMP_EQUAL op = COMP_STRICT_EQUAL][return false]
				if op = COMP_NOT_EQUAL [return true]
			][
				if zero? size1 [							;-- shortcut exit for empty strings
					return any [
						op = COMP_EQUAL 		op = COMP_STRICT_EQUAL
						op = COMP_LESSER_EQUAL  op = COMP_GREATER_EQUAL
					]
				]
			]
		]
		end: as byte-ptr! s2/tail						;-- only one "end" is needed
		p1:  (as byte-ptr! s1/offset) + (bin1/head)
		p2:  (as byte-ptr! s2/offset) + (bin2/head)
		lax?: op <> COMP_STRICT_EQUAL
		
		until [	
			c1: as-integer p1/1
			c2: as-integer p2/1
			if lax? [
				if all [65 <= c1 c1 <= 90][c1: c1 + 32]	;-- lowercase c1
				if all [65 <= c2 c2 <= 90][c2: c2 + 32] ;-- lowercase c2
			]
			p1: p1 + 1
			p2: p2 + 1
			any [
				c1 <> c2
				p2 >= end
			]
		]
		switch op [
			COMP_EQUAL			[res: c1 = c2]
			COMP_NOT_EQUAL		[res: c1 <> c2]
			COMP_STRICT_EQUAL	[res: c1 = c2]
			COMP_LESSER			[res: c1 <  c2]
			COMP_LESSER_EQUAL	[res: c1 <= c2]
			COMP_GREATER		[res: c1 >  c2]
			COMP_GREATER_EQUAL	[res: c1 >= c2]
		]
		res
	]

	rs-skip: func [
		bin 	[red-binary!]
		len		[integer!]
		return: [logic!]
		/local
			s	   [series!]
			offset [integer!]
	][
		assert len >= 0
		s: GET_BUFFER(bin)
		offset: bin/head + len

		if (as byte-ptr! s/offset) + offset <= as byte-ptr! s/tail [
			bin/head: bin/head + len
		]
		(as byte-ptr! s/offset) + offset >= as byte-ptr! s/tail
	]
	
	rs-next: func [
		bin 	[red-binary!]
		return: [logic!]
	][
		rs-skip bin 1
	]

	append-char: func [
		s		[series!]
		cp		[integer!]								;-- codepoint
		return: [series!]
		/local
			p	[byte-ptr!]
			p4	[int-ptr!]
	][
		case [
			cp <= 7Fh [
				s/tail: as cell! (as byte-ptr! s/tail) + 1	;-- safe to increment here
				p: alloc-tail-unit s 1	
				p/0: as-byte cp
			]
			cp <= 07FFh [
				s/tail: as cell! (as byte-ptr! s/tail) + 2	;-- safe to increment here
				p: alloc-tail-unit s 2
				p/-1: as-byte cp >> 6 or C0h
				p/0:  as-byte cp and 3Fh or 80h
			]
			cp < 0000FFFFh [
				s/tail: as cell! (as byte-ptr! s/tail) + 3	;-- safe to increment here
				p: alloc-tail-unit s 3
				p/-2: as-byte cp >> 12 or E0h
				p/-1: as-byte cp >> 6 and 3Fh or 80h
				p/0:  as-byte cp      and 3Fh or 80h
			]
			cp < 0010FFFFh [
				s/tail: as cell! (as byte-ptr! s/tail) + 4	;-- safe to increment here
				p: alloc-tail-unit s 4
				p/-3: as-byte cp >> 18 or F0h
				p/-2: as-byte cp >> 12 and 3Fh or 80h
				p/-1: as-byte cp >> 6  and 3Fh or 80h
				p/0:  as-byte cp       and 3Fh or 80h
			]
		]
		s: GET_BUFFER(s)							;-- refresh s pointer if relocated by alloc-tail-unit
		s/tail: as cell! p
		s
	]

	insert-char: func [
		s		[series!]
		offset	[integer!]								;-- offset from head in bytes
		cp		[integer!]								;-- codepoint
		return: [series!]
		/local
			p	 [byte-ptr!]
			unit [integer!]
	][
		case [
			cp <= 7Fh      [unit: 1]
			cp <= 07FFh    [unit: 2]
			cp < 0000FFFFh [unit: 3]
			true           [unit: 4]
		]
		if (as byte-ptr! s/tail + unit) > ((as byte-ptr! s + 1) + s/size) [
			s: expand-series s 0
		]
		p: (as byte-ptr! s/offset) + offset
		
		move-memory										;-- make space
			p + unit
			p
			as-integer (as byte-ptr! s/tail) - p

		s/tail: as cell! (as byte-ptr! s/tail) + unit
		
		poke-char s p cp
		s
	]


	poke-char: func [
		s		[series!]
		p		[byte-ptr!]								;-- target passed as pointer to favor the general code path
		cp		[integer!]								;-- codepoint
		return: [series!]
		/local
			p4	[int-ptr!]
	][
		case [
			cp <= 7Fh [
				p/1: as-byte cp
			]
			cp <= 07FFh [
				p/1: as-byte cp >> 6 or C0h
				p/2: as-byte cp and 3Fh or 80h
			]
			cp < 0000FFFFh [
				p/1: as-byte cp >> 12 or E0h
				p/2: as-byte cp >> 6 and 3Fh or 80h
				p/3: as-byte cp      and 3Fh or 80h
			]
			cp < 0010FFFFh [
				p/1: as-byte cp >> 18 or F0h
				p/2: as-byte cp >> 12 and 3Fh or 80h
				p/3: as-byte cp >> 6  and 3Fh or 80h
				p/4: as-byte cp       and 3Fh or 80h
			]
		]
		s
	]

	append-byte: func [
		s		[series!]
		byte    [byte!]								;-- codepoint
		return: [series!]
		/local
			p	[byte-ptr!]
			p4	[int-ptr!]
	][
		s/tail: as cell! (as byte-ptr! s/tail) + 1	;-- safe to increment here					
		p: alloc-tail-unit s 1					
		p/0: byte
		s: GET_BUFFER(s)							;-- refresh s pointer if relocated by alloc-tail-unit
		s/tail: as cell! p
		s
	]

	insert-byte: func [
		s		[series!]
		offset	[integer!]							;-- offset from head in bytes
		byte	[byte!]								;-- codepoint
		return: [series!]
		/local
			p	 [byte-ptr!]
			unit [integer!]
	][
		if (as byte-ptr! s/tail) > ((as byte-ptr! s + 1) + s/size) [
			s: expand-series s 0
		]
		p: (as byte-ptr! s/offset) + offset
		move-memory										;-- make space
			p + 1
			p
			as-integer (as byte-ptr! s/tail) - p

		p/1: byte
		s/tail: as cell! (as byte-ptr! s/tail) + 1
		s
	]

	concatenate: func [									;-- append bin2 to bin1
		bin1      [red-binary!]							;-- binary! to extend
		bin2	  [red-string!]							;-- binary! or string! to append to bin1
		part	  [integer!]							;-- bin2 characters to append, -1 means all
		offset	  [integer!]							;-- offset from head in bytes
		insert?	  [logic!]								;-- insert bin2 at bin1 index instead of appending
		/local
			type  [integer!]
			instr [red-string!]
			inbin [red-binary!]
			s1	  [series!]
			s2	  [series!]
			unit2 [integer!]
			size  [integer!]
			size2 [integer!]
			p	  [byte-ptr!]
			limit [byte-ptr!]
			cp	  [integer!]
			h1	  [integer!]
			h2	  [integer!]
	][
		s1: GET_BUFFER(bin1)
		s2: GET_BUFFER(bin2)
		unit2: GET_UNIT(s2)
		h1: either TYPE_OF(bin1) = TYPE_SYMBOL [0][bin1/head]	;-- make symbol! used as string! pass safely
		h2: either TYPE_OF(bin2) = TYPE_SYMBOL [0][bin2/head]	;-- make symbol! used as string! pass safely
		
		size2: (as-integer s2/tail - s2/offset) - h2
		size:  (as-integer s1/tail - s1/offset) + size2
		if s1/size < size [s1: expand-series s1 size]
		
		if part >= 0 [
			part: part << (unit2 >> 1)
			if part < size2 [size2: part]				;-- optionally limit bin2 characters to copy
		]
		if insert? [
			move-memory									;-- make space
				(as byte-ptr! s1/offset) + h1 + offset + size2
				(as byte-ptr! s1/offset) + h1 + offset
				(as-integer s1/tail - s1/offset) - h1
		]
		
		;@@ maybe to convert string to UTF8	if unit2 > 1
		p: either insert? [
			(as byte-ptr! s1/offset) + offset + h1
		][
			as byte-ptr! s1/tail
		]
		copy-memory	p (as byte-ptr! s2/offset) + h2 size2
		p: p + size2

		if insert? [p: (as byte-ptr! s1/tail) + size2] 
		
		s1/tail: as cell! p							;-- reset tail just before NUL
	]

	;-- Actions --

	make: func [
		spec	 [red-value!]
		return:	 [red-binary!]
		/local
			binary [red-binary!]
			size   [integer!]
			int	   [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/make"]]
		
		size: 4 ;default size at least 4 bytes... or should we choose another number?
		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				size: int/value
			]
			default [--NOT_IMPLEMENTED--]
		]
		binary: as red-binary! stack/push*
		binary/header: TYPE_BINARY							;-- implicit reset of all header flags
		binary/head: 	0
		binary/node: 	alloc-bytes size					;-- alloc enough space for at least a Latin1 string
		binary
	]

	random: func [
		bin		[red-binary!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			int [red-integer!]
			s	 [series!]
			size [integer!]
			unit [integer!]
			temp [integer!]
			idx	 [byte-ptr!]
			head [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/random"]]

		either seed? [
			bin/header: TYPE_UNSET				;-- TODO: calc string to seed.
		][
			temp: 0
			s: GET_BUFFER(bin)
			unit: GET_UNIT(s)
			head: (as byte-ptr! s/offset) + bin/head
			size: (as-integer s/tail - s/offset) - bin/head

			if only? [
				either positive? size [
					idx: head + (_random/rand % size)
					int: as red-integer! bin
					int/header: TYPE_INTEGER
					int/value: as-integer idx/value
				][
					bin/header: TYPE_NONE
				]
			]

			while [size > 0][
				idx: head + (_random/rand % size)
				copy-memory as byte-ptr! :temp head 1
				copy-memory head idx 1
				copy-memory idx as byte-ptr! :temp 1
				head: head + 1
				size: size - 1
			]
		]
		as red-value! bin
	]

	compare: func [
		bin1	  [red-binary!]							;-- first operand
		bin2	  [red-binary!]							;-- second operand
		op		  [integer!]							;-- type of comparison
		return:	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/compare"]]

		;@@ can I cast binary value into string and use string's comparison instead of this code?

		if any [
			all [
				op = COMP_STRICT_EQUAL
				TYPE_OF(bin2) <> TYPE_BINARY
			]
			all [
				op <> COMP_STRICT_EQUAL
				TYPE_OF(bin2) <> TYPE_BINARY
			]
		][RETURN_COMPARE_OTHER]
		
		equal? bin1 bin2 op no							;-- match?: no
	]

	form: func [
		value      [red-binary!]
		buffer	   [red-string!]
		arg		   [red-value!]
		part 	   [integer!]
		return:    [integer!]
		/local
			bin    [series!]
			formed [c-string!]
			len    [integer!]
			bytes  [integer!]
			pout   [byte-ptr!]
			head   [byte-ptr!]
			tail   [byte-ptr!]
			byte   [integer!]
			h	   [c-string!]
			i	   [integer!]
			n      [integer!] ;counter for chars on line
			s      [series!]  ;output buffer
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/form"]]
		bin: GET_BUFFER(value)
		head: (as byte-ptr! bin/offset) + value/head
		tail: as byte-ptr! bin/tail
		bytes: as-integer tail - head
		len: (2 * bytes) + 3

		s: GET_BUFFER(buffer)

		s: append-byte s #"#"
		s: append-byte s #"{"
		;using line break after each 32. byte
		if bytes > 32 [
			s: append-byte s #"^/"
			len: len + 1
		]
		h: "0123456789ABCDEF"
		n: 0
		while [head < tail][
			n: either n = 32 [
				s: append-byte s #"^/"
				len: len + 1
				1
			][	n + 1 ]

			byte: as-integer head/1
			i: byte >> 4 and 15 + 1
			s: append-byte s h/i
			i: byte and 15 + 1								;-- byte // 16 + 1
			s: append-byte s h/i
			head: head + 1
		]
		s: append-byte s #"}"
		part - len
	]

	mold: func [
		binary    [red-binary!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			int	   [red-integer!]
			limit  [integer!]
			s	   [series!]
			cp	   [integer!]
			p	   [byte-ptr!]
			p4	   [int-ptr!]
			head   [byte-ptr!]
			tail   [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/mold"]]

		form binary buffer arg part
	]

	eval-path: func [
		parent	[red-binary!]							;-- implicit type casting
		element	[red-value!]
		set?	[logic!]
		return:	[red-value!]
		/local
			int [red-integer!]
	][
		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				either set? [
					poke parent int/value stack/arguments null
					stack/arguments
				][
					pick parent int/value null
				]
			]
;			TYPE_WORD [
;				either set? [
;					element: find parent element null no no no null null no no no no
;					actions/poke as red-series! element 2 stack/arguments null
;					stack/arguments
;				][
;					select parent element null no no no null null no no
;				]
;			]
			default [
				print-line "*** Error: invalid value in path!"
				halt
				null
			]
		]
	]

;	rs-make-at: func [
;		slot	[cell!]
;		size 	[integer!]								;-- number of cells to pre-allocate
;		return:	[red-binary!]
;		/local 
;			p	[node!]
;			str	[red-binary!]
;	][
;		p: alloc-series size 1 0
;		set-type slot TYPE_BINARY						;@@ decide to use or not 'set-type...
;		binary: as red-binary! slot
;		binary/head: 0
;		binary/node: p
;		binary
;	]
	;--- Property reading actions ---

	head?: func [
		return:	  [red-value!]
		/local
			bin	  [red-binary!]
			state [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/head?"]]

		bin:   as red-binary! stack/arguments
		state: as red-logic! bin

		state/header: TYPE_LOGIC
		state/value:  zero? bin/head
		as red-value! state
	]

	tail?: func [
		return:	  [red-value!]
		/local
			bin	  [red-binary!]
			state [red-logic!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/tail?"]]

		bin:   as red-binary! stack/arguments
		state: as red-logic! bin

		s: GET_BUFFER(bin)

		state/header: TYPE_LOGIC
		state/value:  (as byte-ptr! s/offset) + bin/head = as byte-ptr! s/tail
		as red-value! state
	]

	index?: func [
		return:	  [red-value!]
		/local
			bin	  [red-binary!]
			index [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/index?"]]

		bin:   as red-binary! stack/arguments
		index: as red-integer! bin

		index/header: TYPE_INTEGER
		index/value:  bin/head + 1
		as red-value! index
	]

	length?: func [
		bin		[red-binary!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/length?"]]

		get-length bin
	]

	;--- Navigation actions ---

	at: func [
		return:	[red-value!]
		/local
			bin	[red-binary!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/at"]]

		bin: as red-binary! stack/arguments
		bin/head: get-position 1
		as red-value! bin
	]

	back: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/back"]]

		block/back										;-- identical behaviour as block!
	]

	next: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/next"]]

		rs-next as red-binary! stack/arguments
		stack/arguments
	]

	skip: func [
		return:	[red-value!]
		/local
			bin	[red-binary!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/skip"]]

		bin: as red-binary! stack/arguments
		bin/head: get-position 0
		as red-value! bin
	]

	head: func [
		return:	[red-value!]
		/local
			bin	[red-binary!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/head"]]

		bin: as red-binary! stack/arguments
		bin/head: 0
		as red-value! bin
	]

	tail: func [
		return:	[red-value!]
		/local
			bin	[red-binary!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/tail"]]

		bin: as red-binary! stack/arguments
		s: GET_BUFFER(bin)

		bin/head: as-integer s/tail - s/offset
		as red-value! bin
	]

	find: func [
		bin         [red-binary!]
		value       [red-value!]
		part        [red-value!]
		only?       [logic!]
		case?       [logic!]
		any?        [logic!]                            ;@@ not implemented
		with-arg    [red-string!]                       ;@@ not implemented
		skip        [red-integer!]
		last?       [logic!]
		reverse?    [logic!]
		tail?       [logic!]
		match?      [logic!]
		return:     [red-value!]
		/local
			s       [series!]
			s2      [series!]
			buffer  [byte-ptr!]
			pattern [byte-ptr!]
			end     [byte-ptr!]
			end2    [byte-ptr!]
			result  [red-value!]
			int     [red-integer!]
			char    [red-char!]
			bin2    [red-binary!]
			head2   [integer!]
			p1      [byte-ptr!]
			p2      [byte-ptr!]
			p4      [int-ptr!]
			c1      [integer!]
			c2      [integer!]
			step    [integer!]
			limit   [byte-ptr!]
			part?   [logic!]
			op      [integer!]
			found?  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/find"]]

		result: stack/push as red-value! bin
		
		s: GET_BUFFER(bin)
		buffer: (as byte-ptr! s/offset) + bin/head
		end: as byte-ptr! s/tail

		if any [                            ;-- early exit if string is empty or at tail
			s/offset = s/tail
			all [not reverse? buffer >= end]
		][
			result/header: TYPE_NONE
			return result
		]

		step: 1
		part?: no

		;-- Options processing --
		
		if any [any? OPTION?(with-arg)][--NOT_IMPLEMENTED--]
		
		if OPTION?(skip) [
			assert TYPE_OF(skip) = TYPE_INTEGER
			step: skip/value
		]
		if OPTION?(part) [
			limit: either TYPE_OF(part) = TYPE_INTEGER [
				int: as red-integer! part
				if int/value <= 0 [                     ;-- early exit if part <= 0
					result/header: TYPE_NONE
					return result
				]
				(as byte-ptr! s/offset) + int/value - 1 ;-- int argument is 1-based
			][
				bin2: as red-binary! part
				unless all [
					TYPE_OF(bin2) = TYPE_OF(bin)
					bin2/node = bin/node
				][
					print "*** Error: invalid /part series argument"    ;@@ replace with error!
					halt
				]
				(as byte-ptr! s/offset) + bin2/head
			]
			part?: yes
		]
		case [
			last? [
				step: 0 - step
				buffer: either part? [limit][as byte-ptr! s/tail]
				end: as byte-ptr! s/offset
			]
			reverse? [
				step: 0 - step
				buffer: either part? [limit][(as byte-ptr! s/offset) + bin/head - 1]
				end: as byte-ptr! s/offset
				if buffer < end [                           ;-- early exit if bin/head = 0
					result/header: TYPE_NONE
					return result
				]
			]
			true [
				buffer: (as byte-ptr! s/offset) + bin/head
				end: either part? [limit + 1][as byte-ptr! s/tail] ;-- + unit => compensate for the '>= test
			]
		]
		case?: not case?                                ;-- inverted case? meaning
		reverse?: any [reverse? last?]                  ;-- reduce both flags to one
		pattern: null
		
		;-- Value argument processing --
		
		switch TYPE_OF(value) [
			TYPE_BINARY [
				bin2: as red-binary! value
				head2: bin2/head
				s2: GET_BUFFER(bin2)
				pattern: (as byte-ptr! s2/offset) + head2
				end2:    (as byte-ptr! s2/tail)
			]
			TYPE_INTEGER
			TYPE_CHAR [
				char: as red-char! value
				c2: char/value
				if c2 > FFh [
					print ["** Script error: value out of range: " c2 lf] ;@@ Replace with error!
				]
				if all [case? 65 <= c2 c2 <= 90][c2: c2 + 32] ;-- lowercase c2
			]
			default [
				result/header: TYPE_NONE
				return result
			]
		]
		
		;-- Search loop --
		until [
			either pattern = null [
				c1: as-integer buffer/1
				if all [case? 65 <= c1 c1 <= 90][c1: c1 + 32] ;-- lowercase c1
				found?: c1 = c2
				
				if any [
					match?                              ;-- /match option returns tail of match (no loop)
					all [found? tail? not reverse?]     ;-- /tail option too, but only when found pattern
				][
					buffer: buffer + step
				]
			][
				p1: buffer
				p2: pattern
				until [                                 ;-- series comparison
					c1: as-integer p1/1
					c2: as-integer p2/1
					
					if all [case? 65 <= c1 c1 <= 90][c1: c1 + 32] ;-- lowercase c1
					if all [case? 65 <= c2 c2 <= 90][c2: c2 + 32] ;-- lowercase c2
					found?: c1 = c2
					
					p1: p1 + 1
					p2: p2 + 1
					any [
						not found?                      ;-- no match
						p2 >= end2                      ;-- searched binary tail reached
						all [reverse? p1 <= end]        ;-- search buffer exhausted at head
						all [not reverse? p1 >= end]    ;-- search buffer exhausted at tail
					]
				]
				if all [
					found?
					p2 < end2                           ;-- search binary tail not reached
					any [                               ;-- search buffer exhausted
						all [reverse? p1 <= end]
						all [not reverse? p1 >= end]
					]
				][found?: no]                           ;-- partial match case, make it fail

				if all [found? any [match? tail?]][buffer: p1]
			]
			buffer: buffer + step
			any [
				match?                                  ;-- /match option limits to one comparison
				all [not match? found?]                 ;-- match found
				all [reverse? buffer < end]             ;-- head of block series reached
				all [not reverse? buffer >= end]        ;-- tail of block series reached
			]
		]
		buffer: buffer - step                           ;-- compensate for extra step
		if all [tail? reverse? null? pattern][          ;-- additional step for tailed reversed search
			buffer: buffer - step
		]
		
		either found? [
			bin: as red-binary! result
			bin/head: (as-integer buffer - s/offset)    ;-- just change the head position on stack
		][
			result/header: TYPE_NONE                    ;-- change the stack 1st argument to none.
		]
		result
	]

	select: func [
		bin		 [red-binary!]
		value	 [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		return:	 [red-value!]
		/local
			s	   [series!]
			p	   [byte-ptr!]
			int    [red-integer!]
			result [red-value!]
	][
		result: find bin value part only? case? any? with-arg skip last? reverse? true no
		
		if TYPE_OF(result) <> TYPE_NONE [
			bin: as red-binary! result
			s: GET_BUFFER(bin)
			
			p: (as byte-ptr! s/offset) + bin/head
			
			either p < as byte-ptr! s/tail [
				int: as red-integer! result
				int/header: TYPE_INTEGER
				int/value:  as-integer p/1
			][
				result/header: TYPE_NONE
			]
		]
		result
	]

	;--- Modifying actions ---
		
	insert: func [
		bin		 [red-binary!]
		value	 [red-value!]
		part-arg [red-value!]
		only?	 [logic!]
		dup-arg	 [red-value!]
		append?	 [logic!]
		return:	 [red-value!]
		/local
			src		  [red-block!]
			bin2      [red-binary!]
			cell	  [red-value!]
			limit	  [red-value!]
			int		  [red-integer!]
			char	  [red-char!]
			sp		  [red-binary!]
			form-slot [red-value!]
			form-buf  [red-string!]
			s		  [series!]
			s2		  [series!]
			dup-n	  [integer!]
			cnt		  [integer!]
			part	  [integer!]
			len		  [integer!]
			rest	  [integer!]
			added	  [integer!]
			type	  [integer!]
			tail?	  [logic!]
			cp 		  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/insert"]]

		dup-n: 1
		cnt:  1
		part: -1
		
		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
			][
				sp: as red-binary! part-arg
				assert all [
					TYPE_OF(sp) = TYPE_STRING			;@@ replace by ANY_STRING?
					TYPE_OF(sp) = TYPE_FILE
					sp/node = bin/node
				]
				sp/head + 1								;-- /head is 0-based
			]
		]
		if OPTION?(dup-arg) [
			int: as red-integer! dup-arg
			cnt: int/value
			if negative? cnt [return as red-value! bin]
			dup-n: cnt
		]
		
		form-slot: stack/push*							;-- reserve space for FORMing incompatible values
		
		s: GET_BUFFER(bin)
		tail?: any [
			(as-integer s/tail - s/offset) = bin/head
			append?
		]
		
		while [not zero? cnt][							;-- /dup support
			either TYPE_OF(value) = TYPE_BLOCK [		;@@ replace it with: typeset/any-block?
				src: as red-block! value
				s2: GET_BUFFER(src)
				cell:  s2/offset + src/head
				limit: cell + block/rs-length? src
			][
				cell:  value
				limit: value + 1
			]
			rest: 0
			added: 0
			while [
				all [cell < limit added <> part]		;-- multiple values case
			][
				type: TYPE_OF(cell)
				case [
					type = TYPE_INTEGER [
						char: as red-char! cell
						either char/value <= FFh [
							s: GET_BUFFER(bin)
							either tail? [
								append-byte s as-byte char/value
							][
								insert-byte s bin/head + added as-byte char/value
							]
							added: added + 1
						][
							print ["** Script error: value out of range: " char/value lf] ;@@ Replace with error!
						]
					]
					type = TYPE_CHAR [
						char: as red-char! cell
						cp: char/value
						s: GET_BUFFER(bin)
						either tail? [
							append-char s cp
						][
							insert-char s bin/head + added cp
						]
						case [
							cp <= 7Fh      [added: added + 1]
							cp <= 07FFh    [added: added + 2]
							cp < 0000FFFFh [added: added + 3]
							true           [added: added + 4]
						]
					]
					type = TYPE_BINARY [
						bin2: as red-binary! cell
						len: get-length bin2
						rest: len		 					;-- if not /part, use whole value length
						if positive? part [					;-- /part support
							rest: part - added
							if rest > len [rest: len]
						]
						either tail? [
							concatenate bin as red-string! bin2 rest 0 no
						][
							concatenate bin as red-string! bin2 rest added yes
						]
						added: added + rest
					]
					true [
						either any [
							type = TYPE_STRING				;@@ replace with ANY_STRING?
							type = TYPE_FILE 
						][
							form-buf: as red-string! cell
						][
							;TBD: free previous form-buf node and series buffer
							form-buf: string/rs-make-at form-slot 16
							actions/form cell form-buf null 0
						]
						len: string/rs-length? form-buf
						rest: len		 					;-- if not /part, use whole value length
						if positive? part [					;-- /part support
							rest: part - added
							if rest > len [rest: len]
						]
						either tail? [
							concatenate bin form-buf rest 0 no
						][
							concatenate bin form-buf rest added yes
						]
						added: added + rest
					]
				]
				cell: cell + 1
			]
			cnt: cnt - 1
		]
		unless append? [
			added: added * dup-n
			bin/head: bin/head + added
			s: GET_BUFFER(bin)
			assert (as byte-ptr! s/offset) + (bin/head << (GET_UNIT(s) >> 1)) <= as byte-ptr! s/tail
		]
		stack/pop 1										;-- pop the FORM slot
		as red-value! bin
	]

	clear: func [
		bin		[red-binary!]
		return:	[red-value!]
		/local
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/clear"]]

		s: GET_BUFFER(bin)
		s/tail: as cell! (as byte-ptr! s/offset) + bin/head	
		as red-value! bin
	]

	poke: func [
		bin     [red-binary!]
		index   [integer!]
		data    [red-value!]
		boxed   [red-value!]
		return: [red-value!]
		/local
			s      [series!]
			offset [integer!]
			pos    [byte-ptr!]
			int    [red-integer!]
			value  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/poke"]]

		s: GET_BUFFER(bin)
		
		offset: bin/head + index - 1					;-- index is one-based
		if negative? index [offset: offset + 1]
		
		pos: (as byte-ptr! s/offset) + offset
		
		either any [
			zero? index
			pos >= as byte-ptr! s/tail
			pos <  as byte-ptr! s/offset
		][
			--NOT_IMPLEMENTED--
			;TBD: waiting for error!
		][
			switch TYPE_OF(data) [
				TYPE_INTEGER
				TYPE_CHAR [
					int: as red-integer! data
					value: int/value
					if any [value < 0 value > FFh][
						;@@ the error should print the original data, not integer value
						print ["** Script error: value out of range: " value lf] ;@@ Replace with error!
						halt
					]
					pos/1: as-byte value
					stack/set-last data
				]
				default [
					print-line "Error: POKE expected integer! or char! value"	;@@ replace by error! when ready
					halt
				]
			]	
		]
		as red-value! data
	]

	remove: func [
		bin	 	 [red-binary!]
		part-arg [red-value!]
		return:	 [red-binary!]
		/local
			s		[series!]
			part	[integer!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			int		[red-integer!]
			bin2	[red-binary!]
	][
		s:    GET_BUFFER(bin)
		head: (as byte-ptr! s/offset) + bin/head
		tail: as byte-ptr! s/tail
		
		if head = tail [return bin]						;-- early exit if nothing to remove

		part: 1

		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
			][
				bin2: as red-binary! part-arg
				unless all [
					TYPE_OF(bin2) = TYPE_OF(bin)		;-- handles ANY-STRING!
					bin2/node = bin/node
				][
					print "*** Error: invalid /part series argument"	;@@ replace with error!
					halt
				]
				bin2/head - bin/head
			]
			if part <= 0 [return bin]					;-- early exit if negative /part index
		]

		if head + part < tail [
			move-memory 
				head
				head + part
				as-integer tail - (head + part)
		]
		s/tail: as red-value! tail - part
		bin
	]

	reverse: func [
		bin	 	 [red-binary!]
		part-arg [red-value!]
		return:	 [red-binary!]
		/local
			s		[series!]
			part	[integer!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			temp	[byte-ptr!]
			int		[red-integer!]
			bin2	[red-binary!]
	][
		s:    GET_BUFFER(bin)
		head: (as byte-ptr! s/offset) + bin/head
		tail: as byte-ptr! s/tail

		if head = tail [return bin]						;-- early exit if nothing to reverse

		part: 0

		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
			][
				bin2: as red-binary! part-arg
				unless all [
					TYPE_OF(bin2) = TYPE_OF(bin)		;-- handles ANY-STRING!
					bin2/node = bin/node
				][
					print "*** Error: invalid /part series argument"	;@@ replace with error!
					halt
				]
				bin2/head - bin/head
			]
			if part <= 0 [return bin]					;-- early exit if negative /part index
		]

		if all [positive? part head + part < tail] [tail: head + part]
		tail: tail - 1								;-- point to last value
		temp: as byte-ptr! :part
		while [head < tail][
			copy-memory temp head 1
			copy-memory head tail 1
			copy-memory tail temp 1
			head: head + 1
			tail: tail - 1
		]
		bin
	]

	take: func [
		bin	    	[red-binary!]
		part-arg	[red-value!]
		deep?		[logic!]
		last?		[logic!]
		return:		[red-value!]
		/local
			int		[red-integer!]
			bin2	[red-binary!]
			char	[red-char!]
			offset	[byte-ptr!]
			tail	[byte-ptr!]
			s		[series!]
			buffer	[series!]
			node	[node!]
			part	[integer!]
			bytes	[integer!]
			size	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/take"]]

		size: get-length bin
		if size <= 0 [									;-- early exit if nothing to take
			set-type as cell! bin TYPE_NONE
			return as red-value! bin
		]
		s:    GET_BUFFER(bin)
		part: 1

		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
			][
				bin2: as red-binary! part-arg
				unless all [
					TYPE_OF(bin2) = TYPE_OF(bin)		;-- handles ANY-STRING!
					bin2/node = bin/node
				][
					print "*** Error: invalid /part series argument"	;@@ replace with error!
					halt
				]
				either bin2/head < bin/head [0][
					either last? [size - (bin2/head - bin/head)][bin2/head - bin/head]
				]
			]
			if part > size [part: size]
		]

		bytes:	part
		node: 	alloc-bytes bytes
		buffer: as series! node/value
		buffer/flags: s/flags							;@@ filter flags?

		bin2: as red-binary! stack/push*
		bin2/header: TYPE_BINARY
		bin2/node: 	node
		bin2/head: 	0

		either positive? part [
			tail: as byte-ptr! s/tail
			offset: (as byte-ptr! s/offset) + bin/head
			if last? [
				offset: tail - bytes
				s/tail: as cell! offset
			]
			copy-memory
				as byte-ptr! buffer/offset
				offset
				bytes
			buffer/tail: as cell! (as byte-ptr! buffer/offset) + bytes

			unless last? [
				move-memory
					offset
					offset + bytes
					as-integer tail - offset - bytes
				s/tail: as cell! tail - bytes
			]
		][return as red-value! bin2]

		if part = 1 [									;-- return integer!
			int: as red-integer! bin2
			int/header: TYPE_INTEGER
			int/value:  get-byte as byte-ptr! buffer/offset
		]
		as red-value! bin2
	]

	swap: func [
		bin1	 [red-string!]
		bin2	 [red-string!]
		return:	 [red-string!]
		/local
			s1		[series!]
			s2		[series!]
			byte	[byte!]
			head1	[byte-ptr!]
			head2	[byte-ptr!]
	][
		s1:    GET_BUFFER(bin1)
		head1: (as byte-ptr! s1/offset) + bin1/head
		if head1 = as byte-ptr! s1/tail [return bin1]				;-- early exit if nothing to swap

		s2:    GET_BUFFER(bin2)
		head2: (as byte-ptr! s2/offset) + bin2/head
		if head2 = as byte-ptr! s2/tail [return bin1]				;-- early exit if nothing to swap

		byte:    head1/1
		head1/1: head2/1
		head2/1: byte
		bin1
	]

	;--- Reading actions ---

	pick: func [
		bin     [red-binary!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			byte   [red-integer!]
			s      [series!]
			offset [integer!]
			p1     [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/pick"]]

		s: GET_BUFFER(bin)
		
		offset: bin/head + index - 1					;-- index is one-based
		if negative? index [offset: offset + 1]

		p1: (as byte-ptr! s/offset) + offset
		
		either any [
			zero? index
			p1 >= as byte-ptr! s/tail
			p1 <  as byte-ptr! s/offset
		][
			none-value
		][
			byte: as red-integer! stack/push*
			byte/header: TYPE_INTEGER		
			byte/value:  as-integer p1/1
			as red-value! byte
		]
	]

	;--- Misc actions ---

	copy: func [
		bin	    	[red-binary!]
		new			[red-binary!]
		part-arg	[red-value!]
		deep?		[logic!]
		types		[red-value!]
		return:		[red-series!]
		/local
			int		[red-integer!]
			bin2	[red-binary!]
			offset	[integer!]
			s		[series!]
			buffer	[series!]
			node	[node!]
			part	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "binary/copy"]]

		s: GET_BUFFER(bin)

		offset: bin/head
		part: (as-integer s/tail - s/offset) - offset

		if OPTION?(types) [--NOT_IMPLEMENTED--]

		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				case [
					int/value > part    [part]
					positive? int/value [int/value]
					true				[0]
				]
			][
				bin2: as red-binary! part-arg
				unless all [
					TYPE_OF(bin2) = TYPE_OF(bin)		;-- handles ANY-STRING!
					bin2/node = bin/node
				][
					print "*** Error: invalid /part series argument"	;@@ replace with error!
					halt
				]
				bin2/head - bin/head
			]
		]
		
		node: 	alloc-bytes part
		buffer: as series! node/value
		buffer/flags: s/flags							;@@ filter flags?
		
		unless zero? part [
			copy-memory 
				as byte-ptr! buffer/offset
				(as byte-ptr! s/offset) + offset
				part

			buffer/tail: as cell! (as byte-ptr! buffer/offset) + part
		]
		
		new/header: TYPE_BINARY
		new/node: 	node
		new/head: 	0
		
		as red-series! new
	]

	init: does [
		datatype/register [
			TYPE_BINARY
			TYPE_VALUE
			"binary!"
			;-- General actions --
			:make
			:random
			null			;reflect
			null			;to
			:form
			:mold
			:eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			null			;absolute
			null			;add
			null			;divide
			null			;multiply
			null			;negate
			null			;power
			null			;remainder
			null			;round
			null			;subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
			;-- Series actions --
			null			;append
			:at
			:back
			null			;change
			:clear
			:copy
			:find
			:head
			:head?
			:index?
			:insert
			:length?
			:next
			:pick
			:poke
			:remove
			:reverse
			:select
			null			;sort
			:skip
			:swap
			:tail
			:tail?
			:take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null			;modify
			null			;open
			null			;open?
			null			;query
			null			;read
			null			;rename
			null			;update
			null			;write
		]
	]
]
