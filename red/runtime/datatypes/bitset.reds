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
	
	form-bytes: func [
		bits	[red-bitset!]
		buffer	[red-string!]
		part?	[logic!]
		part	[integer!]
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
	
	set-range: func [
		bits 	[red-bitset!]
		lower	[integer!]
		upper	[integer!]
		/local
			pos	  [byte-ptr!]
			pbits [byte-ptr!]
	][
		pbits: rs-head bits
		
		while [lower <= upper][
			BS_SET_BIT(pbits lower)						;-- could be optimized by setting bytes directly
			lower: lower + 1
		]
	]

	process-string: func [
		str		[red-string!]
		bits 	[red-bitset!]
		set?	[logic!]
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
	][
		s:	  GET_BUFFER(str)
		unit: GET_UNIT(s)
		p:	  (as byte-ptr! s/offset) + (str/head << (unit >> 1))
		tail: as byte-ptr! s/tail
		max:  0
		
		unless null? bits [pbits: rs-head bits]
		
		while [p < tail][
			switch unit [
				Latin1 [cp: as-integer p/1]
				UCS-2  [cp: (as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p cp: p4/1]
			]
			either set? [
				BS_SET_BIT(pbits cp)
			][
				if cp > max [max: cp]
			]
			p: p + unit
		]
		max
	]
	
	process: func [
		spec	[red-value!]
		bits 	[red-bitset!]
		set?	[logic!]
		return: [integer!]
		/local
			int	  [red-integer!]
			char  [red-char!]
			w	  [red-word!]
			value [red-value!]
			tail  [red-value!]
			pos	  [byte-ptr!]
			pbits [byte-ptr!]
			size  [integer!]
			max	  [integer!]
	][
		max:   0
		size:  0
		
		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				max: int/value
				if set? [
					pbits: rs-head bits
					BS_SET_BIT(pbits max)
				]
			]
			TYPE_STRING [
				max: process-string as red-string! spec bits set?
			]
			TYPE_CHAR [
				char: as red-char! spec
				max: char/value
				if set? [
					pbits: rs-head bits
					BS_SET_BIT(pbits max)
				]
			]
			TYPE_BINARY [
				--NOT_IMPLEMENTED--
			]
			TYPE_BLOCK [
				value: block/rs-head as red-block! spec
				tail:  block/rs-tail as red-block! spec

				while [value < tail][			
					max: process value bits set? yes	
					
					if all [
						TYPE_OF(value) = TYPE_CHAR
						value + 1 < tail 
					][				
						w: as red-word! value + 1					
						if all [
							TYPE_OF(w) = TYPE_WORD
							w/symbol = words/dash 
						][					
							value: value + 2							
							either all [
								value < tail
								TYPE_OF(value) = TYPE_CHAR
							][
								char: as red-char! value
								either set? [
									set-range bits max char/value
								][
									max: char/value
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
		if max < 8 [max: 8]
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
			s	 [series!]
			
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/make"]]
		
		size: process spec null no	
		size: either zero? (size and 7) [size][size + 8 and -8]	;-- round it to byte size
		
		bits: as red-bitset! stack/push*
		bits/header: TYPE_BITSET						;-- implicit reset of all header flags
		bits/node: 	 alloc-bytes size >> 3
		s: GET_BUFFER(bits)
		s/tail: as cell! ((as byte-ptr! s/tail) + s/size)
		
		process spec bits yes	
		bits
	]
	
	form: func [
		bits	  [red-bitset!]
		buffer	  [red-string!]
		arg		  [red-value!]
		part	  [integer!]
		return:	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/form"]]

		string/concatenate-literal buffer "make bitset! [#{"
		part: form-bytes bits buffer OPTION?(arg) part - 16
		string/concatenate-literal buffer "}]"
		part - 2
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
	
	pick: func [
		bits	[red-bitset!]
		index	[integer!]
		return:	[red-value!]
		/local
			pos	  [byte-ptr!]
			pbits [byte-ptr!]
			set?  [logic!]
			s	  [series!]
	][
		s: GET_BUFFER(bits)
		either (s/size << 3) < index [set?: no][
			pbits: as byte-ptr! s/offset
			BS_GET_BIT(pbits index set?)
		]
		as red-value! either set? [true-value][false-value]
	]
	
	poke: func [
		bits	[red-bitset!]
		index	[integer!]
		data    [red-value!]
		return:	[red-value!]
		/local
			bool  [red-logic!]
			int	  [red-integer!]
			pos	  [byte-ptr!]
			pbits [byte-ptr!]
			type  [integer!]
			s	  [series!]	
	][
		s: GET_BUFFER(bits)
		type: TYPE_OF(data)
		bool: as red-logic! data
		int:  as red-integer! data
		index: index - 1
		
		either any [
			type = TYPE_NONE
			all [type = TYPE_LOGIC not bool/value]
			all [type = TYPE_INTEGER zero? int/value]
		][
			pbits: as byte-ptr! s/offset
			BS_CLEAR_BIT(pbits index)
		][
			if (s/size << 3) < index [
				s: expand-series s (index >> 3) + 1
			]
			pbits: as byte-ptr! s/offset
			BS_SET_BIT(pbits index)
		]
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
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
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