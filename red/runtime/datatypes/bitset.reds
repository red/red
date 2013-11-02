Red/System [
	Title:   "Bitset datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %bitset.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

bitset: context [
	verbose: 0
	
	#enum bitset-op! [
		OP_MAX											;-- calculate highest value
		OP_SET											;-- set value bits
		OP_TEST											;-- test if value bits are set
		OP_CLEAR										;-- clear value bits
	]
	
	rs-head: func [
		bits	[red-bitset!]
		return: [byte-ptr!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(bits)
		as byte-ptr! s/offset
	]
	
	rs-tail: func [
		bits	[red-bitset!]
		return: [byte-ptr!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(bits)
		as byte-ptr! s/tail
	]
	
	bound-check: func [
		bits	[red-bitset!]
		index	[integer!]								;-- 0-based
		return: [byte-ptr!]
		/local
			s [series!]
	][
		s: GET_BUFFER(bits)
		if (s/size << 3) < index [s: expand-series s (index >> 3) + 1]
;zeroing buffer!!!
		as byte-ptr! s/offset
	]
	
	virtual-bit?: func [
		bits	[red-bitset!]
		index	[integer!]								;-- 0-based
		return: [logic!]
		/local
			s [series!]
	][
		s: GET_BUFFER(bits)
		any [index < 0 (s/size << 3) < index]
	]
	
	match?: func [										;-- called from PARSE
		pbits	[byte-ptr!]
		index	[integer!]								;-- 0-based
		case?	[logic!]
		return: [logic!]
		/local
			match? [logic!]
	][													;-- no out of bound index checking!
		BS_TEST_BIT(pbits index match?)
		
		if all [not case? not match?][
			either all [65 <= index index <= 90][		;-- try with lowercasing
				index: index + 32
				BS_TEST_BIT(pbits index match?)
			][
				if all [97 <= index index <= 122][		;-- try with uppercasing
					index: index - 32
					BS_TEST_BIT(pbits index match?)
				]
			]
		]
		match?
	]
	
	invert: func [
		bits [red-bitset!]
		/local
			s	 [series!]
			p	 [byte-ptr!]
			tail [byte-ptr!]
	][
		s: 	  GET_BUFFER(bits)
		p:	  as byte-ptr! s/offset
		tail: as byte-ptr! s/tail
		
		while [p < tail][
			p/value: not p/value
			p: p + 1
		]
	]
	
	form-bytes: func [
		bits	[red-bitset!]
		buffer	[red-string!]
		part?	[logic!]
		part	[integer!]
		invert? [logic!]
		return:	[integer!]
		/local
			s	   [series!]
			p	   [byte-ptr!]
			tail   [byte-ptr!]
			byte   [integer!]
			c	   [byte!]
			nibble [integer!]
	][
		s:	  GET_BUFFER(bits)
		p:	  as byte-ptr! s/offset
		tail: as byte-ptr! s/tail

		while [p < tail][								;@@ could be optimized for speed
			byte: as-integer p/value
			if invert? [byte: 255 - byte]
			
			nibble: byte >> 4							;-- high nibble
			c: either nibble < 10 [#"0" + nibble][#"A" + (nibble - 10)]
			string/append-char GET_BUFFER(buffer) as-integer c
			
			nibble: byte and 15							;-- low nibble
			c: either nibble < 10 [#"0" + nibble][#"A" + (nibble - 10)]
			string/append-char GET_BUFFER(buffer) as-integer c
			
			p: p + 1
			part: part - 1
			if all [part? negative? part][return part]
		]
		part
	]
	
	process-range: func [
		bits 	[red-bitset!]
		lower	[integer!]
		upper	[integer!]
		op		[integer!]
		return: [integer!]
		/local
			pos	  [byte-ptr!]
			pbits [byte-ptr!]
			set?  [logic!]
			s	  [series!]
			not?  [logic!]
	][
		s: GET_BUFFER(bits)
		not?: FLAG_NOT?(s)
		
		switch op [
			OP_SET [
				pbits: bound-check bits upper
				while [lower <= upper][
					BS_SET_BIT(pbits lower)				;-- could be optimized by setting bytes directly
					lower: lower + 1
				]
			]
			OP_TEST [
				if virtual-bit? bits upper [return as-integer not?]
				pbits: rs-head bits
				while [lower <= upper][
					BS_TEST_BIT(pbits lower set?)		;-- could be optimized by testing bytes directly
					unless set? [return 0]
					lower: lower + 1
				]
			]
			OP_CLEAR [
				if virtual-bit? bits upper [return as-integer not?]
				pbits: rs-head bits
				while [lower <= upper][
					BS_CLEAR_BIT(pbits lower)			;-- could be optimized by clearing bytes directly
					lower: lower + 1
				]
			]
		]
		1
	]

	process-string: func [
		str		[red-string!]
		bits 	[red-bitset!]
		op		[integer!]
		return: [integer!]
		/local
			s	  [series!]
			p	  [byte-ptr!]
			tail  [byte-ptr!]
			pos	  [byte-ptr!]
			pbits [byte-ptr!]
			p4	  [int-ptr!]
			unit  [integer!]
			max   [integer!]
			cp	  [integer!]
			size  [integer!]
			test? [logic!]
			set?  [logic!]
			not?  [logic!]
	][
		s:	  GET_BUFFER(str)
		unit: GET_UNIT(s)
		p:	  (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		tail: as byte-ptr! s/tail
		max:  0
		size: s/size << 3
		not?: FLAG_NOT?(s)
		
		unless null? bits [pbits: rs-head bits]
		test?: op = OP_TEST
		
		while [p < tail][
			switch unit [
				Latin1 [cp: as-integer p/1]
				UCS-2  [cp: (as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p cp: p4/1]
			]
			switch op [
				OP_MAX	 []
				OP_SET	 [BS_SET_BIT(pbits cp)]
				OP_TEST	 [
					if size < cp [return as-integer not?]
					BS_TEST_BIT(pbits cp set?)
				]
				OP_CLEAR [
					if size < cp [return as-integer not?]
					BS_CLEAR_BIT(pbits max)
				]
			]
			if cp > max [max: cp]
			
			if all [test? not set?][return 0]
			p: p + unit
		]
		either all [test? set?][1][max]
	]
	
	process: func [
		spec	[red-value!]
		bits 	[red-bitset!]
		op		[integer!]
		sub?	[logic!]
		return: [integer!]
		/local
			int	  [red-integer!]
			char  [red-char!]
			w	  [red-word!]
			value [red-value!]
			tail  [red-value!]
			pos	  [byte-ptr!]
			pbits [byte-ptr!]
			max	  [integer!]
			min	  [integer!]
			size  [integer!]
			type  [integer!]
			s	  [series!]
			test? [logic!]
			not?  [logic!]
	][
		max: 0
		
		switch TYPE_OF(spec) [
			TYPE_CHAR
			TYPE_INTEGER [
				type: TYPE_OF(spec)
				max: either type = TYPE_CHAR [
					char: as red-char! spec
					char/value
				][
					int: as red-integer! spec
					int/value
				]
				unless op = OP_MAX [
					s: GET_BUFFER(bits)
					not?: FLAG_NOT?(s)
					switch op [
						OP_SET   [
							pbits: bound-check bits max
							BS_SET_BIT(pbits max)
						]
						OP_TEST  [
							if virtual-bit? bits max [return as-integer not?]
							pbits: rs-head bits
							BS_TEST_BIT(pbits max test?)
							max: as-integer test?
						]
						OP_CLEAR [
							if virtual-bit? bits max [return as-integer not?]
							pbits: rs-head bits
							BS_CLEAR_BIT(pbits max)
						]
					]
				]
			]
			TYPE_STRING [
				if op = OP_SET [
					max: process-string as red-string! spec bits OP_MAX
					pbits: bound-check bits max
				]
				max: process-string as red-string! spec bits op
			]
			TYPE_BINARY [
				--NOT_IMPLEMENTED--
			]
			TYPE_BLOCK [
				value: block/rs-head as red-block! spec
				tail:  block/rs-tail as red-block! spec
				test?: op = OP_TEST
				
				while [value < tail][
					size: process value bits op yes
					if all [test? zero? size][return 0]	;-- size > 0 => TRUE, 0 => FALSE
					
					type: TYPE_OF(value)
					if all [
						any [type = TYPE_CHAR type = TYPE_INTEGER]
						value + 1 < tail 
					][
						w: as red-word! value + 1
						if all [
							TYPE_OF(w) = TYPE_WORD
							w/symbol = words/dash 
						][
							value: value + 2
							type: TYPE_OF(value)
							either all [
								value < tail
								any [type = TYPE_CHAR type = TYPE_INTEGER]
							][
								min: size
								size: either type = TYPE_CHAR [
									char: as red-char! value
									char/value
								][
									int: as red-integer! value
									int/value
								]
								switch op [
									OP_MAX	 []			;-- do nothing
									OP_SET	 [process-range 	 bits min size op]
									OP_TEST	 [max: process-range bits min size op]
									OP_CLEAR [process-range		 bits min size op]
								]
							][
								print-line "*** Make Error: invalid upper bound in bitset range"
							]
						]
					]
					if size > max [max: size]
					value: value + 1
				]
			]
			default [
				print-line "*** Make Error: bitset spec argument not supported!"
			]
		]
		
		if all [not sub? any [op = OP_SET op = OP_MAX]][
			max: max + 8 and -8	>> 3					;-- round to byte
			if zero? max [max: 1]
			
			if op = OP_SET [
				s: GET_BUFFER(bits)
				tail: as red-value! ((as byte-ptr! s/offset) + max)
				if tail > s/tail [s/tail: tail]			;-- move tail pointer forward if expanded bitset
			]
		]
		max
	]
	
	push: func [
		bits [red-bitset!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/push"]]

		copy-cell as red-value! bits stack/push*
	]
	
	;-- Actions --
	
	make: func [
		proto	[red-value!]
		spec	[red-value!]
		return: [red-bitset!]
		/local
			bits [red-bitset!]
			size [integer!]
			int	 [red-integer!]
			blk	 [red-block!]
			w	 [red-word!]
			s	 [series!]
			not? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/make"]]
		
		bits: as red-bitset! stack/push*
		bits/header: TYPE_BITSET						;-- implicit reset of all header flags

		either TYPE_OF(spec) = TYPE_INTEGER [
			int: as red-integer! spec
			size: int/value
			if size <= 0 [print-line "*** Make Error: bitset invalid integer argument!"]
			size: either zero? (size and 7) [size][size + 8 and -8]	;-- round to byte multiple
			size: size >> 3								;-- convert to bytes
			bits/node: alloc-bytes size
			
			s: GET_BUFFER(bits)
			s/tail: as cell! ((as byte-ptr! s/offset) + size)
		][
			not?: no
			
			if TYPE_OF(spec) = TYPE_BLOCK [
				blk: as red-block! spec
				w: as red-word! block/rs-head blk
				not?: all [
					TYPE_OF(w) = TYPE_WORD
					w/symbol = words/not*
				]
				if not? [blk/head: blk/head + 1]		;-- skip NOT
			]
			
			size: process spec null OP_MAX no			;-- 1st pass: determine size
			bits/node: alloc-bytes size
			process spec bits OP_SET no					;-- 2nd pass: set bits
			
			if not? [
				s: GET_BUFFER(bits)
				s/flags: s/flags or flag-bitset-not
				blk/head: blk/head - 1					;-- restore series argument head
				invert bits
			]
		]
;zeroing buffer!!!
		bits
	]
	
	form: func [
		bits	[red-bitset!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return: [integer!]
		/local
			s	 [series!]
			not? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/form"]]

		s: GET_BUFFER(bits)
		not?: FLAG_NOT?(s)
		
		string/concatenate-literal buffer "make bitset! "
		if not? [string/concatenate-literal buffer "[not "]
		
		string/concatenate-literal buffer "#{"
		part: form-bytes bits buffer OPTION?(arg) part - 13 not?
		string/append-char GET_BUFFER(buffer) as-integer #"}"
		
		either not? [
			string/append-char GET_BUFFER(buffer)as-integer #"]"
			part - 7									;-- account for extra chars
		][
			part - 1
		]
	]
	
	mold: func [
		bits	[red-bitset!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/mold"]]

		form bits buffer arg part
	]
	
	find: func [
		bits	 [red-bitset!]
		value	 [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		tail?	 [logic!]
		match?	 [logic!]
		return:	 [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/find"]]
		
		pick bits 0 value
	]
	
	insert: func [
		bits	 [red-bitset!]
		value	 [red-value!]
		part-arg [red-value!]
		only?	 [logic!]
		dup-arg	 [red-value!]
		append?	 [logic!]
		return:	 [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/insert"]]
		
		process value bits OP_SET no
		as red-value! bits
	]
	
	pick: func [
		bits	[red-bitset!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			set? [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/pick"]]
		
		set?: process boxed bits OP_TEST yes
		as red-value! either positive? set? [true-value][false-value]
	]
	
	poke: func [
		bits	[red-bitset!]
		index	[integer!]
		data	[red-value!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			bool  [red-logic!]
			int	  [red-integer!]
			type  [integer!]
			op	  [integer!]
			s	  [series!]
			not?  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/poke"]]
		
		type: TYPE_OF(data)
		bool: as red-logic! data
		int:  as red-integer! data
		s:	  GET_BUFFER(bits)
		not?: FLAG_NOT?(s)
		
		op: either any [
			type = TYPE_NONE
			all [type = TYPE_LOGIC not bool/value]
			all [type = TYPE_INTEGER zero? int/value]
		][
			either not? [OP_SET][OP_CLEAR]
		][
			either not? [OP_CLEAR][OP_SET]
		]
		process boxed bits op no
		as red-value! data
	]
	
	init: does [
		datatype/register [
			TYPE_BITSET
			TYPE_VALUE
			"bitset!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			null			;get-path
			null			;set-path
			null			;compare
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
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			:find
			null			;head
			null			;head?
			null			;index?
			:insert
			null			;length?
			null			;next
			:pick
			:poke
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
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