Red/System [
	Title:   "Bitset datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %bitset.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
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
	
	#enum bitset-cmd! [
		CMD_MAKE
		CMD_TO
		CMD_OTHER
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
			s	 [series!]
			p	 [byte-ptr!]
			byte [byte!]
	][
		s: GET_BUFFER(bits)
		if (s/size << 3) < index [
			byte: either FLAG_NOT?(s) [#"^(FF)"][null-byte]
			s: expand-series-filled s (index >> 3) + 1 byte
		]
		
		p: (as byte-ptr! s/offset) + (index >> 3) + 1
		if p > as byte-ptr! s/tail [s/tail: as cell! p]	;-- move forward tail pointer if required
		as byte-ptr! s/offset
	]
	
	virtual-bit?: func [
		bits	[red-bitset!]
		index	[integer!]								;-- 0-based
		return: [logic!]
		/local
			s [series!]
			p [byte-ptr!]
	][
		s: GET_BUFFER(bits)
		p: (as byte-ptr! s/offset) + (index >> 3) + 1
		any [
			index < 0
			p > as byte-ptr! s/tail
			p < as byte-ptr! s/offset					;-- overflow case
		]
	]
	
	invert-bytes: func [
		s [series!]
		/local
			p	 [byte-ptr!]
			tail [byte-ptr!]
	][
		p:	  as byte-ptr! s/offset
		tail: p + s/size 
		
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
	
	do-bitwise: func [
		type	[integer!]
		return: [red-bitset!]
		/local
			set1	[red-bitset!]
			set2	[red-bitset!]
			s1		[series!]
			s2		[series!]
			s		[series!]
			node	[node!]
			p		[byte-ptr!]
			p1		[byte-ptr!]
			p2		[byte-ptr!]
			i		[integer!]
			size1	[integer!]
			size2	[integer!]
			min		[integer!]
			max		[integer!]
			same?	[logic!]
	][
		set1: as red-bitset! stack/arguments
		if type = OP_UNIQUE [return set1]

		set2: set1 + 1
		if TYPE_OF(set2) <> TYPE_BITSET [
			fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(set2)]
		]

		s1: GET_BUFFER(set1)
		s2: GET_BUFFER(set2)
		size1: as-integer s1/tail - s1/offset
		size2: as-integer s2/tail - s2/offset
		min: size1
		max: size2
		if min > max [i: min min: max max: i]
		same?: (s1/flags and flag-bitset-not) = (s2/flags and flag-bitset-not)

		node: alloc-bytes-filled max null-byte
		s: as series! node/value
		p: as byte-ptr! s/offset
		unless same? [s/flags: s/flags or flag-bitset-not]
		
		p1:	  as byte-ptr! s1/offset
		p2:	  as byte-ptr! s2/offset
		i:  0
		while [i < min][
			p/value: switch type [
				OP_UNION
				OP_OR		[p1/value or p2/value]			;-- OR s1 with part(s2)
				OP_INTERSECT
				OP_AND		[p1/value and p2/value]
				OP_DIFFERENCE
				OP_XOR		[p1/value xor p2/value]
				OP_EXCLUDE	[p1/value and (not p2/value)]
			]
			p:  p  + 1
			p1: p1 + 1
			p2: p2 + 1
			i:  i + 1
		]

		min: max - i
		unless zero? min [
			if size2 < size1 [p2: p1]
			switch type [
				OP_EXCLUDE [
					if size1 > size2 [copy-memory p p2 min]
					p: p + min
				]
				OP_UNION
				OP_OR	[
					copy-memory p p2 min			;-- just copy remaining of s2
					p: p + min
				]
				OP_INTERSECT [p: p + min]
				OP_AND  []									;-- do nothing
				OP_DIFFERENCE
				OP_XOR	[
					i: 0
					until [
						p/value: null-byte xor p2/value
						p:  p  + 1
						p2: p2 + 1
						i:  i + 1
						i = min
					]
				]
			]
		]
		s/tail: as red-value! p

		set1: as red-bitset! stack/push*
		set1/header: TYPE_BITSET
		set1/node:	 node
		stack/set-last as red-value! set1
		set1
	]

	and~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bitset/and~"]]
		as red-value! do-bitwise OP_AND
	]

	or~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bitset/or~"]]
		as red-value! do-bitwise OP_OR
	]

	xor~: func [return:	[red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "bitset/xor~"]]
		as red-value! do-bitwise OP_XOR
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
		pbits: as byte-ptr! s/offset
		
		switch op [
			OP_SET [
				BS_PROCESS_SET_VIRTUAL(bits upper)
				while [lower <= upper][
					BS_SET_BIT(pbits lower)				;-- could be optimized by setting bytes directly
					lower: lower + 1
				]
			]
			OP_TEST [
				if virtual-bit? bits upper [return as-integer not?]
				while [lower <= upper][
					BS_TEST_BIT(pbits lower set?)		;-- could be optimized by testing bytes directly
					unless set? [return 0]
					lower: lower + 1
				]
			]
			OP_CLEAR [
				BS_PROCESS_CLEAR_VIRTUAL(bits upper)
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
		op		[bitset-op!]
		return: [integer!]
		/local
			s	  [series!]
			p	  [byte-ptr!]
			tail  [byte-ptr!]
			pos	  [byte-ptr!]							;-- required by BS_TEST_BIT
			pbits [byte-ptr!]
			p4	  [int-ptr!]
			unit  [integer!]
			max   [integer!]
			cp	  [integer!]
			size  [integer!]
			test? [logic!]
			set?  [logic!]								;-- required by BS_TEST_BIT
			not?  [logic!]
	][
		s:	  GET_BUFFER(str)
		unit: GET_UNIT(s)
		p:	  (as byte-ptr! s/offset) + (str/head << (log-b unit))
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
					BS_CLEAR_BIT(pbits cp)
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
		op		[bitset-op!]
		sub?	[logic!]
		cmd		[bitset-cmd!]
		return: [integer!]
		/local
			int	  [red-integer!]
			char  [red-char!]
			w	  [red-word!]
			value [red-value!]
			tail  [red-value!]
			pos	  [byte-ptr!]							;-- required by BS_TEST_BIT
			pbits [byte-ptr!]
			max	  [integer!]
			min	  [integer!]
			size  [integer!]
			type  [integer!]
			s	  [series!]
			set?  [logic!]								;-- required by BS_TEST_BIT
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
					pbits: as byte-ptr! s/offset
					
					switch op [
						OP_SET [
							BS_PROCESS_SET_VIRTUAL(bits max)
							BS_SET_BIT(pbits max)
						]
						OP_TEST [
							if virtual-bit? bits max [return as-integer not?]
							BS_TEST_BIT(pbits max test?)
							max: as-integer test?
						]
						OP_CLEAR [
							BS_PROCESS_CLEAR_VIRTUAL(bits max)
							BS_CLEAR_BIT(pbits max)
						]
					]
				]
			]
			TYPE_STRING [
				unless op = OP_MAX [
					s: GET_BUFFER(bits)
					not?: FLAG_NOT?(s)

					switch op [
						OP_SET [
							max: process-string as red-string! spec bits OP_MAX
							BS_PROCESS_SET_VIRTUAL(bits max)
						]
						OP_CLEAR [
							max: process-string as red-string! spec bits OP_MAX
							BS_PROCESS_CLEAR_VIRTUAL(bits max)
						]
						default []
					]
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
					size: process value bits op yes cmd
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
							if type <> TYPE_OF(value) [
								fire [TO_ERROR(script invalid-arg) value]
							]
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
								if min > size [fire [TO_ERROR(script past-end)]]
								switch op [
									OP_MAX	 []			;-- do nothing
									OP_SET	 [process-range 	 bits min size op]
									OP_TEST	 [max: process-range bits min size op]
									OP_CLEAR [process-range		 bits min size op]
								]
							][
								fire [TO_ERROR(script past-end)]
							]
						]
					]
					if size > max [max: size]
					value: value + 1
				]
			]
			default [
				switch cmd [
					CMD_MAKE [fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_BITSET spec]]
					CMD_TO	 [fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_BITSET spec]]
					default  [fire [TO_ERROR(script invalid-arg) spec]]
				]
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
	
	construct: func [
		proto	[red-value!]
		spec	[red-value!]
		cmd		[integer!]
		return: [red-bitset!]
		/local
			bits [red-bitset!]
			b2	 [red-bitset!]
			size [integer!]
			int	 [red-integer!]
			blk	 [red-block!]
			bin  [red-binary!]
			w	 [red-word!]
			s	 [series!]
			op	 [integer!]
			not? [logic!]
			byte [byte!]
	][
		bits: as red-bitset! stack/push*
		bits/header: TYPE_BITSET						;-- implicit reset of all header flags

		switch TYPE_OF(spec) [
			TYPE_BITSET [
				b2: as red-bitset! spec
				bits/node: copy-series GET_BUFFER(b2)
			]
			TYPE_INTEGER [
				if cmd = CMD_TO [
					fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_BITSET spec]
				]
				int: as red-integer! spec
				size: int/value
				if size <= 0 [
					fire [
						TO_ERROR(script out-of-range)
						int
					]
				]
				size: either zero? (size and 7) [size][size + 8 and -8]	;-- round to byte multiple
				size: size >> 3								;-- convert to bytes
				bits/node: alloc-bytes-filled size null-byte
				
				s: GET_BUFFER(bits)
				s/tail: as cell! ((as byte-ptr! s/offset) + size)
			]
			TYPE_BINARY [
				bin: as red-binary! spec
				size: binary/rs-length? bin
				bits/node: alloc-bytes size
				s: GET_BUFFER(bits)
				s/tail: as cell! ((as byte-ptr! s/offset) + size)
				copy-memory as byte-ptr! s/offset binary/rs-head bin size
			]
			default [
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
				byte: either not? [#"^(FF)"][null-byte]
				op: either not? [OP_CLEAR][OP_SET]
				
				size: process spec null OP_MAX no cmd		;-- 1st pass: determine size
				bits/node: alloc-bytes-filled size byte
				if not? [
					s: GET_BUFFER(bits)
					s/flags: s/flags or flag-bitset-not
				]
				process spec bits op no	cmd					;-- 2nd pass: set bits
				if not? [blk/head: blk/head - 1]			;-- restore series argument head
			]
		]
		bits
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
		type	[integer!]
		return: [red-bitset!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/make"]]
		construct proto spec CMD_MAKE
	]
	
	to: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return: [red-bitset!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/to"]]
		construct proto spec CMD_TO
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
	
	compare: func [
		bs1	   	[red-block!]							;-- first operand
		bs2   	[red-block!]							;-- second operand
		op		[integer!]								;-- type of comparison
		return: [integer!]
		/local
			s	  [series!]
			head  [byte-ptr!]
			p	  [byte-ptr!]
			p2	  [byte-ptr!]
			sz1   [integer!]
			sz2   [integer!]
			not?  [logic!]
			not2? [logic!]
			b1	  [byte!]
			b2	  [byte!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/compare"]]

		if TYPE_OF(bs2) <> TYPE_BITSET [RETURN_COMPARE_OTHER]
		
		s: 	  GET_BUFFER(bs1)
		head: as byte-ptr! s/offset
		p:	  as byte-ptr! s/tail
		sz1:  as-integer p - head
		not?: FLAG_NOT?(s)
		s: 	  GET_BUFFER(bs2)
		p2:   as byte-ptr! s/tail
		sz2:  as-integer p2 - s/offset
		
		if sz1 <> sz2 [
			return SIGN_COMPARE_RESULT(sz1 sz2)
		]
		if zero? sz1 [									;-- shortcut exit for empty bitsets
			return 0
		]

		not2?: FLAG_NOT?(s)
		if not? <> not2? [
			return SIGN_COMPARE_RESULT((as-integer not?) (as-integer not2?))
		]

		until [											;-- bits difference search (starting from highest bits)
			p: p - 1
			p2: p2 - 1
			any [p/value <> p2/value p = head]
		]
		b1: p/value
		b2: p2/value
		SIGN_COMPARE_RESULT(b1 b2)
	]
	
	eval-path: func [
		parent	[red-bitset!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			int [red-integer!]
	][
		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				either value <> null [
					poke parent int/value value element
					value
				][
					pick parent int/value element
				]
			]
			default [
				fire [
					TO_ERROR(script invalid-type)
					datatype/push TYPE_OF(element)
				]
				null
			]
		]
	]
	
	negate: func [
		bits	[red-bitset!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/negate"]]

		copy-cell as red-value! complement bits as red-value! bits
	]
	
	complement: func [
		bits	[red-bitset!]
		return:	[red-value!]
		/local
			s	 [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/complement"]]
		
		bits: copy bits as red-bitset! stack/push* null no null
		s: GET_BUFFER(bits)
		s/flags: s/flags xor flag-bitset-not
		invert-bytes s
		as red-value! bits
	]
	
	clear: func [
		bits	 [red-bitset!]
		return:	[red-value!]
		/local
			s	 [series!]
			p	 [byte-ptr!]
			tail [byte-ptr!]
			byte [byte!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/clear"]]

		s: 	  GET_BUFFER(bits)
		p: 	  as byte-ptr! s/offset
		tail: as byte-ptr! s/tail
		
		byte: either FLAG_NOT?(s) [#"^(FF)"][null-byte]
		while [p < tail][p/value: byte p: p + 1]
		as red-value! bits
	]
	
	copy: func [
		bits	 [red-bitset!]
		new		 [red-bitset!]
		part-arg [red-value!]
		deep?	 [logic!]
		types	 [red-value!]
		return:	 [red-bitset!]
		/local
			s [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/copy"]]
		
		s: GET_BUFFER(bits)
		new/header: TYPE_BITSET
		new/node:	copy-series s
		new
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
		
		process value bits OP_SET no CMD_OTHER
		as red-value! bits
	]
	
	length?: func [
		bits	[red-bitset!]
		return: [integer!]
		/local
			s [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/length?"]]

		s: GET_BUFFER(bits)
		(as-integer s/tail - s/offset) << 3
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
		
		set?: process boxed bits OP_TEST yes CMD_OTHER
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
	][
		#if debug? = yes [if verbose > 0 [print-line "bitset/poke"]]
		
		type: TYPE_OF(data)
		bool: as red-logic! data
		int:  as red-integer! data
		s:	  GET_BUFFER(bits)
		
		op: either any [
			type = TYPE_NONE
			all [type = TYPE_LOGIC not bool/value]
			all [type = TYPE_INTEGER zero? int/value]
		][
			OP_CLEAR
		][
			OP_SET
		]
		process boxed bits op no CMD_OTHER
		as red-value! data
	]
	
	remove: func [
		bits	[red-bitset!]
		part	[red-value!]
		return:	[red-value!]
		/local
			s  [series!]
			op [integer!]
	][
		unless OPTION?(part) [
			print-line "Remove Error: /part is required for bitset argument"
		]
		s: GET_BUFFER(bits)
		op: either FLAG_NOT?(s) [OP_SET][OP_CLEAR]
		process part bits op no CMD_OTHER
		as red-value! bits
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
			:to
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
			:negate
			null			;power
			null			;remainder
			null			;round
			null			;subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			:and~
			:complement
			:or~
			:xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			:clear
			:copy
			:find
			null			;head
			null			;head?
			null			;index?
			:insert
			:length?
			null			;move
			null			;next
			:pick
			:poke
			null			;put
			:remove
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
