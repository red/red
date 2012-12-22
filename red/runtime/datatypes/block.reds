Red/System [
	Title:   "Block! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %block.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

block: context [
	verbose: 0
	
	depth: 0											;-- used to trace nesting level for FORM/MOLD

	rs-length?: func [
		blk 	[red-block!]
		return: [integer!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(blk)
		(as-integer (s/tail - s/offset)) >> 4 - blk/head
	]
	
	rs-head: func [
		blk 	[red-block!]
		return: [red-value!]
	][
		s: GET_BUFFER(blk)
		s/offset
	]
	
	rs-tail: func [
		blk 	[red-block!]
		return: [red-value!]
	][
		s: GET_BUFFER(blk)
		s/tail
	]
	
	get-position: func [
		base	   [integer!]
		return:	   [integer!]
		/local
			blk	   [red-block!]
			index  [red-integer!]
			s	   [series!]
			offset [integer!]
			max	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/get-position"]]

		blk: as red-block! stack/arguments
		index: as red-integer! blk + 1

		assert TYPE_OF(blk)   = TYPE_BLOCK
		assert TYPE_OF(index) = TYPE_INTEGER

		s: GET_BUFFER(blk)

		offset: blk/head + index/value - base			;-- index is one-based
		if negative? offset [offset: 0]
		max: (as-integer s/tail - s/offset) >> 4
		if offset > max [offset: max]

		offset
	]
	
	append*: func [
		return: [red-block!]
		/local
			arg	[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/append*"]]

		arg: as red-block! stack/arguments
		;assert TYPE_OF(arg) = TYPE_BLOCK				;@@ disabled until we have ANY_BLOCK check

		copy-cell
			as cell! arg + 1
			ALLOC_TAIL(arg)
			
		arg
	]

	make-in: func [
		parent	[red-block!]
		size 	[integer!]								;-- number of cells to pre-allocate
		return:	[red-block!]
		/local
			blk [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/make-in"]]
		
		blk: either null? parent [
			_root
		][
			assert TYPE_OF(parent) = TYPE_BLOCK
			as red-block! ALLOC_TAIL(parent)
		]		
		blk/header: TYPE_BLOCK							;-- implicit reset of all header flags
		blk/head: 	0
		blk/node: 	alloc-cells size	
		blk
	]
	
	push*: func [
		size	[integer!]
		return: [red-block!]	
		/local
			blk [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/push*"]]
		
		blk: as red-block! ALLOC_TAIL(root)
		blk/header: TYPE_BLOCK							;-- implicit reset of all header flags
		blk/head: 	0
		blk/node: 	alloc-cells size
		push blk
		blk
	]
	
	push: func [
		blk [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/push"]]

		copy-cell as red-value! blk stack/push*
	]
	
	mold-each: func [
		blk		  [red-block!]
		buffer	  [red-string!]
		only?	  [logic!]
		all?	  [logic!]
		flat?	  [logic!]
		arg		  [red-value!]
		part 	  [integer!]
		return:   [integer!]
		/local
			s	  [series!]
			value [red-value!]
			i     [integer!]
	][
		s: GET_BUFFER(blk)
		i: blk/head
		while [
			value: s/offset + i
			value < s/tail
		][
			if all [OPTION?(arg) part <= 0][return part]
			
			depth: depth + 1
			part: actions/mold value buffer only? all? flat? arg part
			
			if positive? depth [
				string/append-char GET_BUFFER(buffer) as-integer space
				part: part - 1
			]
			depth: depth - 1
			i: i + 1
		]
		s: GET_BUFFER(buffer)
		if i <> blk/head [								;-- test if not empty block
			s/tail: as cell! (as byte-ptr! s/tail) - 1	;-- remove extra white space
			part: part + 1
		]
		part
	]

	compare-each: func [
		blk1	   [red-block!]							;-- first operand
		blk2	   [red-block!]							;-- second operand
		op		   [integer!]							;-- type of comparison
		return:	   [logic!]
		/local
			s1	   [series!]
			s2	   [series!]
			size1  [integer!]
			size2  [integer!]
			end	   [red-value!]
			value1 [red-value!]
			value2 [red-value!]
			res	   [logic!]
	][
		s1: GET_BUFFER(blk1)
		s2: GET_BUFFER(blk2)
		size1: (as-integer s1/tail - s1/offset) >> 4 - blk1/head
		size2: (as-integer s2/tail - s2/offset) >> 4 - blk2/head

		if size1 <> size2 [								;-- shortcut exit for different sizes
			if any [op = COMP_EQUAL op = COMP_STRICT_EQUAL][return false]
			if op = COMP_NOT_EQUAL [return true]
		]
		if zero? size1 [								;-- shortcut exit for empty blocks
			return any [op = COMP_EQUAL op = COMP_STRICT_EQUAL]
		]
		
		value1: s1/offset + blk1/head
		value2: s2/offset + blk2/head
		end: s1/tail									;-- only one "end" is needed
		until [
			res: actions/compare value1 value2 op
			value1: value1 + 1
			value2: value2 + 1
			any [
				not res
				value1 >= end
			]
		]
		if op = COMP_NOT_EQUAL [res: not res]
		res
	]

	;--- Actions ---
	
	make: func [
		proto 	 [red-value!]
		spec	 [red-value!]
		return:	 [red-block!]
		/local
			blk  [red-block!]
			size [integer!]
			int	 [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/make"]]

		size: 1
		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				int: as red-integer! spec
				size: int/value
			]
			default [--NOT_IMPLEMENTED--]
		]
		blk: as red-block! stack/push*
		blk/header: TYPE_BLOCK							;-- implicit reset of all header flags
		blk/head: 	0
		blk/node: 	alloc-cells size
		blk
	]
	
	form: func [
		blk		  [red-block!]
		buffer	  [red-string!]
		arg		  [red-value!]
		part 	  [integer!]
		return:   [integer!]
		/local
			s	  [series!]
			value [red-value!]
			i     [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/form"]]

		s: GET_BUFFER(blk)
		i: blk/head
		
		while [
			value: s/offset + i
			value < s/tail
		][
			if all [OPTION?(arg) part <= 0][return part]
			
			part: actions/form value buffer arg part
			i: i + 1
			
			if 	s/offset + i < s/tail [
				string/append-char GET_BUFFER(buffer) as-integer space
				part: part - 1
			]
		]
		part
	]
	
	mold: func [
		blk		  [red-block!]
		buffer	  [red-string!]
		only?	  [logic!]
		all?	  [logic!]
		flat?	  [logic!]
		arg		  [red-value!]
		part 	  [integer!]
		return:   [integer!]
		/local
			s	  [series!]
			value [red-value!]
			i     [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/mold"]]
		
		unless only? [
			string/append-char GET_BUFFER(buffer) as-integer #"["
			part: part - 1
		]
		part: mold-each blk buffer only? all? flat? arg part
		
		unless only? [
			string/append-char GET_BUFFER(buffer) as-integer #"]"
			part: part - 1
		]
		part
	]
	
	compare: func [
		blk1	   [red-block!]							;-- first operand
		blk2	   [red-block!]							;-- second operand
		op		   [integer!]							;-- type of comparison
		return:	   [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/compare"]]
		
		if TYPE_OF(blk2) <> TYPE_BLOCK [RETURN_COMPARE_OTHER]
		compare-each blk1 blk2 op
	]
	
	;--- Property reading actions ---
	
	head?: func [
		return:	  [red-value!]
		/local
			blk	  [red-block!]
			state [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/head?"]]

		blk:   as red-block! stack/arguments
		state: as red-logic! blk
		
		state/header: TYPE_LOGIC
		state/value:  zero? blk/head
		as red-value! state
	]
	
	tail?: func [
		return:	  [red-value!]
		/local
			blk	  [red-block!]
			state [red-logic!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/tail?"]]

		blk:   as red-block! stack/arguments
		state: as red-logic! blk
		
		s: GET_BUFFER(blk)

		state/header: TYPE_LOGIC
		state/value:  (s/offset + blk/head) = s/tail
		as red-value! state
	]
	
	index?: func [
		return:	  [red-value!]
		/local
			blk	  [red-block!]
			index [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/index?"]]

		blk:   as red-block! stack/arguments
		index: as red-integer! blk
		
		index/header: TYPE_INTEGER
		index/value:  blk/head + 1
		as red-value! index
	]
	
	length?: func [
		return: [red-value!]
		/local
			blk	[red-block!]
			int [red-integer!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/length?"]]
		
		blk: as red-block! stack/arguments
		
		s: GET_BUFFER(blk)
		
		int: as red-integer! blk
		int/header: TYPE_INTEGER
		int/value:  (as-integer s/tail - s/offset - blk/head) >> 4
		as red-value! int
	]
	
	;--- Navigation actions ---
	
	at: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/at"]]
		
		blk: as red-block! stack/arguments
		blk/head: get-position 1
		as red-value! blk
	]
	
	back: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/back"]]

		blk: as red-block! stack/arguments

		s: GET_BUFFER(blk)

		if blk/head >= 1 [blk/head: blk/head - 1]
		as red-value! blk
	]
	
	next: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/next"]]
	
		blk: as red-block! stack/arguments
		
		s: GET_BUFFER(blk)
		
		if (s/offset + blk/head + 1) <= s/tail [
			blk/head: blk/head + 1
		]
		as red-value! blk
	]
		
	skip: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/skip"]]

		blk: as red-block! stack/arguments
		blk/head: get-position 0
		as red-value! blk
	]
	
	head: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/head"]]

		blk: as red-block! stack/arguments
		blk/head: 0
		as red-value! blk
	]
	
	tail: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/tail"]]

		blk: as red-block! stack/arguments
		s: GET_BUFFER(blk)
		
		blk/head: (as-integer s/tail - s/offset) >> 4
		as red-value! blk
	]
	
	find: func [
		blk			[red-block!]
		value		[red-value!]
		part		[red-value!]
		only?		[logic!]
		case?		[logic!]
		any?		[logic!]
		with-arg	[red-string!]
		skip		[red-integer!]
		last?		[logic!]
		reverse?	[logic!]
		tail?		[logic!]
		match?		[logic!]
		return:		[red-value!]
		/local
			s		[series!]
			s2		[series!]
			slot	[red-value!]
			slot2	[red-value!]
			end		[red-value!]
			end2	[red-value!]
			int		[red-integer!]
			b		[red-block!]
			dt		[red-datatype!]
			values	[integer!]
			step	[integer!]
			n		[integer!]
			part?	[logic!]
			op		[integer!]
			type	[integer!]
			found?	[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/find"]]
		
		s: GET_BUFFER(blk)
		if s/offset = s/tail [							;-- early exit if blk is empty
			blk/header: TYPE_NONE
			return s/offset
		]
		step:  1
		part?: no
		
		if OPTION?(skip) [
			assert TYPE_OF(skip) = TYPE_INTEGER
			step: skip/value
		]
		if OPTION?(part) [
			part: either TYPE_OF(part) = TYPE_INTEGER [
				int: as red-integer! part
				s/offset + int/value - 1				;-- int argument is 1-based
			][
				b: as red-block! part
				unless all [
					TYPE_OF(b) = TYPE_OF(blk)			;-- handles ANY-BLOCK!
					b/node = blk/node
				][
					print "*** Error: invalid /part series argument"	;@@ replace with error!
					halt
				]
				s/offset + b/head
			]
			part?: yes
		]
		
		type: TYPE_OF(value)
		values: either only? [0][						;-- values > 0 => series comparison mode
			either any [								;@@ replace with ANY_BLOCK?
				type = TYPE_BLOCK
				type = TYPE_PAREN
				type = TYPE_PATH
				type = TYPE_GET_PATH
				type = TYPE_SET_PATH
				type = TYPE_LIT_PATH
			][
				b: as red-block! value
				s2: GET_BUFFER(b)
				value: s2/offset + b/head
				end2: s2/tail
				(as-integer s2/tail - s2/offset) >> 4 - b/head - 1 ;-- -1 => adjusted for loop comparison
			][0]
		]
		if negative? values [values: 0]					;-- empty value series case
		
		case [
			last? [
				step: 0 - step
				slot: either part? [part][s/tail - 1]
				end: s/offset
			]
			reverse? [
				step: 0 - step
				slot: either part? [part][s/offset + blk/head]
				end: s/offset
			]
			true [
				slot: s/offset + blk/head
				end: either part? [part + 1][s/tail]	;-- + 1 => compensate for the '>= test
			]
		]
		op: either case? [COMP_STRICT_EQUAL][COMP_EQUAL] ;-- warning: /case <> STRICT...
		reverse?: any [reverse? last?]					;-- reduce both flags to one
		if match? [tail?: yes]
		
		type: either type = TYPE_DATATYPE [
			dt: as red-datatype! value
			dt/value
		][-1]											;-- disable "type searching" mode
		
		until [
			either zero? values [
				found?: either positive? type [
					type = TYPE_OF(slot)		;-- simple type comparison
				][
					actions/compare slot value op ;-- atomic comparison
				]
			][
				n: 0
				slot2: slot
				until [									;-- series comparison
					found?: actions/compare slot2 value + n op
					slot2: slot2 + 1
					n: n + 1
					any [
						not found?						;-- no match
						n = values						;-- values exhausted
						slot2 >= end2					;-- block series tail reached
					]
				]
				if all [match? found?][slot: slot2 + 1]
			]
			slot: slot + step
			any [
				match?									;-- /match option limits to one comparison
				all [not match? found?]					;-- match found
				all [reverse? slot <= end]				;-- head of block series reached
				all [not reverse? slot >= end]			;-- tail of block series reached
			]
		]
		unless tail? [slot: slot - step]				;-- point before/after found value
		
		either found? [
			blk/head: (as-integer slot - s/offset) >> 4	;-- just change the head position on stack
		][
			blk/header: TYPE_NONE						;-- change the stack 1st argument to none.
		]
		slot
	]
	
	select: func [
		blk		 [red-block!]
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
		/local
			s	 [series!]
			p	 [red-value!]
	][
		p: find blk value part only? case? any? with-arg skip last? reverse? no no
		
		if TYPE_OF(blk) <> TYPE_NONE [
			s: GET_BUFFER(blk)
			p: s/offset + blk/head + 1
			either p < s/tail [
				stack/set-last p
			][
				blk/header: TYPE_NONE
			]
		]
		p
	]
	
	;--- Reading actions ---
	
	pick: func [
		blk	       [red-block!]
		index  	   [integer!]
		return:	   [red-value!]
		/local
			cell   [red-value!]
			s	   [series!]
			offset [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/pick"]]

		s: GET_BUFFER(blk)

		offset: blk/head + index - 1					;-- index is one-based
		if negative? index [offset: offset + 1]
		cell: s/offset + offset
		
		either any [
			zero? index
			cell >= s/tail
			cell < s/offset
		][
			none-value
		][
			cell
		]
	]
	
	;--- Modifying actions ---
	
	append: func [
		blk		  [red-block!]
		value	  [red-value!]
		part-arg  [red-value!]
		only?	  [logic!]
		dup-arg	  [red-value!]
		return:	  [red-value!]
		/local
			src	  [red-block!]
			cell  [red-value!]
			limit [red-value!]
			int	  [red-integer!]
			b	  [red-block!]
			s	  [series!]
			cnt	  [integer!]
			part  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/append"]]
		
		cnt:  1
		part: -1
		
		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
			][
				b: as red-block! part-arg
				assert all [
					TYPE_OF(b) = TYPE_BLOCK
					b/node = blk/node
				]
				b/head + 1								;-- /head is 0-based
			]
		]
		if OPTION?(dup-arg) [
			int: as red-integer! dup-arg
			cnt: int/value
		]
		
		while [not zero? cnt][							;-- /dup support
			either all [
				not only?								;-- /only support
				any [
					TYPE_OF(value) = TYPE_BLOCK			;@@ replace it with: typeset/any-block?
					TYPE_OF(value) = TYPE_PATH			;@@ replace it with: typeset/any-block?
				]
			][
				src: as red-block! value
				if negative? part [part: rs-length? src] ;-- if not /part, use whole value length
				s: GET_BUFFER(src)
				cell: s/offset + src/head
				limit: cell + part						;-- /part support

				while [cell < limit][					;-- multiple values case
					copy-cell cell ALLOC_TAIL(blk)
					cell: cell + 1
				]
			][											;-- single value case
				copy-cell value	ALLOC_TAIL(blk)
			]
			cnt: cnt - 1
		]
		as red-value! blk
	]
	
	clear: func [
		return:	[red-value!]
		/local
			blk	[red-block!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/clear"]]

		blk: as red-block! stack/arguments
		s: GET_BUFFER(blk)
		s/tail: s/offset + blk/head
		as red-value! blk
	]
	
	poke: func [
		blk		   [red-block!]
		index	   [integer!]
		data       [red-value!]
		return:	   [red-value!]
		/local
			cell   [red-value!]
			s	   [series!]
			offset [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/poke"]]

		s: GET_BUFFER(blk)
		
		offset: blk/head + index - 1					;-- index is one-based
		if negative? index [offset: offset + 1]
		cell: s/offset + offset

		either any [
			zero? index
			cell >= s/tail
			cell < s/offset
		][
			;TBD: placeholder waiting for error! to be implemented
			stack/set-last none-value					;@@ should raise an error!
		][
			copy-cell data cell
			stack/set-last data
		]
		as red-value! data
	]
	
	;--- Misc actions ---
	
	copy: func [
		blk	    	[red-block!]
		part-arg	[red-value!]
		deep?		[logic!]
		types		[red-value!]
		return:		[red-series!]
		/local
			int		[red-integer!]
			b		[red-block!]
			offset	[red-value!]
			slot	[red-value!]
			buffer	[series!]
			new		[node!]
			part	[integer!]
			slots	[integer!]
			type	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/copy"]]
		
		s: GET_BUFFER(blk)
		
		slots:	rs-length? blk
		offset: s/offset + blk/head
		part:   as-integer s/tail - offset
		
		if OPTION?(types) [--NOT_IMPLEMENTED--]
		
		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				case [
					int/value > (part >> 4) [part >> 4]
					positive? int/value 	[int/value]
					true					[0]
				]
			][
				b: as red-block! part-arg
				unless all [
					TYPE_OF(b) = TYPE_OF(blk)			;-- handles ANY-BLOCK!
					b/node = blk/node
				][
					print "*** Error: invalid /part series argument"	;@@ replace with error!
					halt
				]
				b/head
			]
			slots: part
			part: part << 4
		]
		
		new: 	alloc-cells slots + 1
		buffer: as series! new/value
		
		unless zero? part [
			copy-memory 
				as byte-ptr! buffer/offset
				as byte-ptr! offset
				part
				
			buffer/tail: buffer/offset + slots
		]
		blk/node: new									;-- reuse the block slot
		blk/head: 0										;-- reset head offset
		
		if deep? [
			slot: buffer/offset
			until [
				type: TYPE_OF(slot)
				if any [								;@@ replace with ANY_SERIES?
					type = TYPE_BLOCK
					type = TYPE_PAREN
					type = TYPE_PATH
					type = TYPE_GET_PATH
					type = TYPE_SET_PATH
					type = TYPE_LIT_PATH
					type = TYPE_STRING
				][
					actions/copy as red-series! slot null yes null
				]
				slot: slot + 1
				slot >= buffer/tail
			]
		]
		
		as red-series! blk
	]

	
	datatype/register [
		TYPE_BLOCK
		TYPE_VALUE
		"block!"
		;-- General actions --
		:make
		null			;random
		null			;reflect
		null			;to
		:form
		:mold
		null			;get-path
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
		:append
		:at
		:back
		null			;change
		:clear
		:copy
		:find
		:head
		:head?
		:index?
		null			;insert
		:length?
		:next
		:pick
		:poke
		null			;remove
		null			;reverse
		:select
		null			;sort
		:skip
		null			;swap
		:tail
		:tail?
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