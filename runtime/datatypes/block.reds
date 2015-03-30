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
		assert (as-integer (s/tail - s/offset)) >> 4 - blk/head >= 0
		(as-integer (s/tail - s/offset)) >> 4 - blk/head
	]
	
	rs-next: func [
		blk 	[red-block!]
		return: [logic!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(blk)
		if (s/offset + blk/head + 1) <= s/tail [
			blk/head: blk/head + 1
		]
		s/offset + blk/head = s/tail
	]
	
	rs-head: func [
		blk 	[red-block!]
		return: [red-value!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(blk)
		s/offset + blk/head
	]
	
	rs-tail: func [
		blk 	[red-block!]
		return: [red-value!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(blk)
		s/tail
	]
	
	rs-tail?: func [
		blk 	[red-block!]
		return: [logic!]
		/local
			s [series!]
	][
		s: GET_BUFFER(blk)
		s/offset + blk/head = s/tail
	]

	rs-abs-at: func [
		blk 	[red-block!]
		pos		[integer!]
		return: [red-value!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(blk)
		assert s/offset + pos < s/tail
		s/offset + pos
	]
	
	rs-clear: func [
		blk 	[red-block!]
		/local
			s	[series!]
	][
		s: GET_BUFFER(blk)
		s/tail: s/offset + blk/head
	]
	
	rs-append: func [
		blk		[red-block!]
		value	[red-value!]
		return: [red-value!]
	][
		copy-cell value ALLOC_TAIL(blk)
	]
	
	rs-append-block: func [
		blk		[red-block!]
		blk2	[red-block!]
		return: [red-block!]
		/local
			value [red-value!]
			tail  [red-value!]
			s	  [series!]
	][
		s: GET_BUFFER(blk2)
		value: s/offset + blk2/head
		tail:  s/tail

		while [value < tail][
			copy-cell value ALLOC_TAIL(blk)
			value: value + 1
		]
		blk
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

		assert any [
			TYPE_OF(blk)   = TYPE_BLOCK
			TYPE_OF(blk)   = TYPE_HASH
		]
		assert TYPE_OF(index) = TYPE_INTEGER

		s: GET_BUFFER(blk)

		if all [base = 1 index/value <= 0][base: base - 1]
		offset: blk/head + index/value - base			;-- index is one-based
		if negative? offset [offset: 0]
		max: (as-integer s/tail - s/offset) >> 4
		if offset > max [offset: max]

		offset
	]
	
	clone: func [
		blk 	[red-block!]
		deep?	[logic!]
		return: [red-block!]
		/local
			new	   [red-block!]
			target [series!]
			value  [red-value!]
			tail   [red-value!]
			result [red-block!]
			size   [integer!]
			empty? [logic!]
	][
		assert TYPE_OF(blk) = TYPE_BLOCK
		
		value: block/rs-head blk
		tail:  block/rs-tail blk
		size:  (as-integer tail - value) >> 4
		
		empty?: zero? size
		if empty? [size: 1]
		
		new: as red-block! stack/push*					;-- slot allocated on stack!
		new/header: TYPE_BLOCK
		new/head:   0
		new/node:	alloc-cells size
		
		unless empty? [
			target: GET_BUFFER(new)
			copy-memory
				as byte-ptr! target/offset
				as byte-ptr! value
				size << 4
			target/tail: target/offset + size
		]
		
		if all [deep? not empty?][
			while [value < tail][
				if TYPE_OF(value) = TYPE_BLOCK [
					result: clone as red-block! value yes
					copy-cell as red-value! result value
					stack/pop 1
				]
				value: value + 1
			]
		]
		new
	]
	
	insert-value: func [
		blk		[red-block!]
		value	[red-value!]
		return: [red-block!]
		/local
			head   [red-value!]
			s	   [series!]
			size   [integer!]
	][
		s: GET_BUFFER(blk)
		size: as-integer s/tail + 1 - s/offset
		if size > s/size [s: expand-series s size]
		head: s/offset + blk/head
		
		move-memory										;-- make space
			as byte-ptr! head + 1
			as byte-ptr! head
			as-integer s/tail - head
			
		s/tail: s/tail + 1	
		copy-cell value head
		blk/head: blk/head + 1
		blk
	]
	
	insert-block: func [
		blk		[red-block!]
		blk2	[red-block!]
		return: [red-block!]
		/local
			value [red-value!]
			tail  [red-value!]
			s	  [series!]
	][
		s: GET_BUFFER(blk2)
		value: s/offset + blk2/head
		tail:  s/tail
		
		while [value < tail][
			insert-value blk value
			value: value + 1
		]
		blk
	]
	
	insert-thru: does [
		unless stack/acc-mode? [
			insert-value
				as red-block! stack/arguments - 1
				stack/arguments
		]
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
	
	append-thru: func [
		/local
			arg	[red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/append-thru"]]

		unless stack/acc-mode? [
			arg: as red-block! stack/arguments - 1
			;assert TYPE_OF(arg) = TYPE_BLOCK			;@@ disabled until we have ANY_BLOCK check

			copy-cell
				as cell! arg + 1
				ALLOC_TAIL(arg)
		]
	]
	
	select-word: func [
		blk		[red-block!]
		word	[red-word!]
		return: [red-value!]
		/local
			value [red-value!]
			tail  [red-value!]
			w	  [red-word!]
			sym	  [integer!]
	][
		value: rs-head blk
		tail:  rs-tail blk
		sym:   symbol/resolve word/symbol
		
		while [value < tail][
			if any [									;@@ replace with ANY_WORD?
				TYPE_OF(value) = TYPE_WORD
				TYPE_OF(value) = TYPE_SET_WORD
				TYPE_OF(value) = TYPE_GET_WORD
				TYPE_OF(value) = TYPE_LIT_WORD
			][
				w: as red-word! value
				if sym = symbol/resolve w/symbol [
					either value + 1 = tail [
						return none-value
					][
						return value + 1
					]
				]
			]
			value: value + 1
		]
		none-value
	]
	
	make-at: func [
		blk		[red-block!]
		size	[integer!]
		return: [red-block!]
	][
		blk/header: TYPE_BLOCK							;-- implicit reset of all header flags
		blk/head: 	0
		blk/node: 	alloc-cells size
		blk
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
		make-at blk size
	]
	
	push: func [
		blk [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/push"]]

		copy-cell as red-value! blk stack/push*
	]
	
	push*: func [
		size	[integer!]
		return: [red-block!]	
		/local
			blk [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/push*"]]
		
		blk: make-at as red-block! ALLOC_TAIL(root) size
		push blk
		blk
	]
	
	push-only*: func [
		size	[integer!]
		return: [red-block!]
		/local
			blk [red-block!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/push-only*"]]

		if zero? size [size: 1]
		make-at as red-block! stack/push* size
	]
	
	mold-each: func [
		blk		  [red-block!]
		buffer	  [red-string!]
		only?	  [logic!]
		all?	  [logic!]
		flat?	  [logic!]
		arg		  [red-value!]
		part 	  [integer!]
		indent	  [integer!]
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
			part: actions/mold value buffer only? all? flat? arg part indent
			
			if positive? depth [
				string/append-char GET_BUFFER(buffer) as-integer space
				part: part - 1
			]
			depth: depth - 1
			i: i + 1
		]
		s: GET_BUFFER(buffer)
		if i <> blk/head [								;-- test if not empty block
			s/tail: as cell! (as byte-ptr! s/tail) - GET_UNIT(s) ;-- remove extra white space
			part: part + 1
		]
		part
	]

	compare-each: func [
		blk1	   [red-block!]							;-- first operand
		blk2	   [red-block!]							;-- second operand
		op		   [integer!]							;-- type of comparison
		return:	   [integer!]
		/local
			s1	   [series!]
			s2	   [series!]
			size1  [integer!]
			size2  [integer!]
			type1  [integer!]
			type2  [integer!]
			end	   [red-value!]
			value1 [red-value!]
			value2 [red-value!]
			res	   [integer!]
	][
		s1: GET_BUFFER(blk1)
		s2: GET_BUFFER(blk2)
		size1: (as-integer s1/tail - s1/offset) >> 4 - blk1/head
		size2: (as-integer s2/tail - s2/offset) >> 4 - blk2/head

		if size1 <> size2 [										;-- shortcut exit for different sizes
			if any [
				op = COMP_EQUAL op = COMP_STRICT_EQUAL op = COMP_NOT_EQUAL
			][return 1]
		]

		if zero? size1 [return 0]								;-- shortcut exit for empty blocks

		value1: s1/offset + blk1/head
		value2: s2/offset + blk2/head
		end: s1/tail											;-- only one "end" is needed

		until [
			type1: TYPE_OF(value1)
			type2: TYPE_OF(value2)
			either any [
				type1 = type2
				all [word/any-word? type1 word/any-word? type2]
				all [											;@@ replace by ANY_NUMBER?
					any [type1 = TYPE_INTEGER type1 = TYPE_FLOAT]
					any [type2 = TYPE_INTEGER type2 = TYPE_FLOAT]
				]
			][
				res: actions/compare-value value1 value2 op
				value1: value1 + 1
				value2: value2 + 1
			][
				return SIGN_COMPARE_RESULT(type1 type2)
			]
			any [
				res <> 0
				value1 >= end
			]
		]
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
		if zero? size [size: 1]
		make-at as red-block! stack/push* size
	]

	random: func [
		blk		[red-block!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			s	 [series!]
			size [integer!]
			temp [red-value!]
			idx	 [red-value!]
			head [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/random"]]

		either seed? [
			blk/header: TYPE_UNSET						;-- TODO: calc block as seed
		][
			s: GET_BUFFER(blk)
			head: s/offset + blk/head
			size: rs-length? blk

			if only? [
				either positive? size [
					idx: head + (_random/rand % size)
					copy-cell idx as cell! blk
				][
					blk/header: TYPE_NONE
				]
			]

			temp: stack/push*
			while [size > 0][
				idx: head + (_random/rand % size)
				copy-cell head temp
				copy-cell idx head
				copy-cell temp idx
				head: head + 1
				size: size - 1
			]
			stack/pop 1
		]
		as red-value! blk
	]
	
	form: func [
		blk		  [red-block!]
		buffer	  [red-string!]
		arg		  [red-value!]
		part 	  [integer!]
		return:   [integer!]
		/local
			s	  [series!]
			buf	  [series!]
			value [red-value!]
			unit  [integer!]
			prev  [integer!]
			i     [integer!]
			c	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/form"]]

		s: GET_BUFFER(blk)
		i: blk/head
		value: s/offset + i
		c: 0
		
		while [value < s/tail][
			if all [OPTION?(arg) part <= 0][return part]
			
			prev: part
			part: actions/form value buffer arg part
			i: i + 1
			value: s/offset + i
			
			if value < s/tail [
				buf:  GET_BUFFER(buffer)
				unit: GET_UNIT(buf)
				c: string/get-char (as byte-ptr! buf/tail) - unit unit
				
				unless any [
					c = as-integer #"^/"
					c = as-integer #"^M"
					c = as-integer #"^-"
				][
					string/append-char buf as-integer space
					part: part - 1
				]
			]
		]
		
		s: GET_BUFFER(buffer)
		
		if s/offset < s/tail [
			unit: GET_UNIT(s)
			i: string/get-char (as byte-ptr! s/tail) - unit unit
		]
		part
	]
	
	mold: func [
		blk		[red-block!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/mold"]]
		
		unless only? [
			string/append-char GET_BUFFER(buffer) as-integer #"["
			part: part - 1
		]
		part: mold-each blk buffer no all? flat? arg part indent
		
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
		return:	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/compare"]]
		
		if TYPE_OF(blk2) <> TYPE_OF(blk1) [RETURN_COMPARE_OTHER]
		compare-each blk1 blk2 op
	]
	
	eval-path: func [
		parent	[red-block!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		return:	[red-value!]
		/local
			int  [red-integer!]
			set? [logic!]
			type [integer!]
	][
		set?: value <> null
		type: TYPE_OF(element)
		either type = TYPE_INTEGER [
			int: as red-integer! element
			either set? [
				poke parent int/value value null
				value
			][
				pick parent int/value null
			]
		][
			either set? [
				element: find parent element null no no no null null no no no no
				actions/poke as red-series! element 2 value null
				value
			][
				either all [
					TYPE_OF(parent) = TYPE_BLOCK
					type = TYPE_WORD
				][
					select-word parent as red-word! element
				][
					select parent element null yes no no null null no no
				]
			]
		]
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
		blk		[red-block!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/length?"]]
		
		rs-length? blk
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
	][
		#if debug? = yes [if verbose > 0 [print-line "block/next"]]
	
		rs-next as red-block! stack/arguments
		stack/arguments
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
			result	[red-value!]
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
			hash?	[logic!]
			table	[node!]
			hash	[red-hash!]
			any-blk? [logic!]
			key		[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/find"]]
		
		result: as red-value! blk
		hash?: TYPE_OF(blk) = TYPE_HASH
		if hash? [
			hash: as red-hash! blk
			table: hash/table
		]

		s: GET_BUFFER(blk)

		if any [							;-- early exit if blk is empty or at tail
			s/offset = s/tail
			all [not reverse? s/offset + blk/head >= s/tail]
		][
			result/header: TYPE_NONE
			return result
		]
		step:  1
		part?: no
		
		if OPTION?(skip) [
			assert TYPE_OF(skip) = TYPE_INTEGER
			step: skip/value
			unless positive? step [
				fire [TO_ERROR(script out-of-range) skip]
			]
		]
		if OPTION?(part) [
			part: either TYPE_OF(part) = TYPE_INTEGER [
				int: as red-integer! part
				if int/value <= 0 [						;-- early exit if part <= 0
					result/header: TYPE_NONE
					return result
				]
				s/offset + int/value - 1				;-- int argument is 1-based
			][
				b: as red-block! part
				unless all [
					TYPE_OF(b) = TYPE_OF(blk)			;-- handles ANY-BLOCK!
					b/node = blk/node
				][
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part)
				]
				s/offset + b/head
			]
			part?: yes
		]
		
		type: TYPE_OF(value)
		any-blk?: any [									;@@ replace with ANY_BLOCK?
			type = TYPE_BLOCK
			type = TYPE_PAREN
			type = TYPE_PATH
			type = TYPE_GET_PATH
			type = TYPE_SET_PATH
			type = TYPE_LIT_PATH
		]

		either any [
			match?
			any-blk?									;@@ temporary, because we don't hash block!
			not hash?
		][
			values: either only? [0][						;-- values > 0 => series comparison mode
				either any-blk? [
					b: as red-block! value
					s2: GET_BUFFER(b)
					value: s2/offset + b/head
					end2: s2/tail
					(as-integer s2/tail - s2/offset) >> 4 - b/head
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
					slot: either part? [part][s/offset + blk/head - 1]
					end: s/offset
					if slot < end [							;-- early exit if blk/head = 0
						result/header: TYPE_NONE
						return result
					]
				]
				true [
					slot: s/offset + blk/head
					end: either part? [part + 1][s/tail]	;-- + 1 => compensate for the '>= test
				]
			]
			op: either case? [COMP_STRICT_EQUAL][COMP_EQUAL] ;-- warning: /case <> STRICT...
			reverse?: any [reverse? last?]					;-- reduce both flags to one
			
			type: either type = TYPE_DATATYPE [
				dt: as red-datatype! value
				dt/value
			][-1]											;-- disable "type searching" mode
			
			until [
				either zero? values [
					found?: either positive? type [
						dt: as red-datatype! slot
						type = dt/value						;-- simple type comparison
					][
						actions/compare slot value op		;-- atomic comparison
					]
					if match? [slot: slot + 1]				;-- /match option returns tail of match
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
							all [reverse?     slot2 <= end]	;-- block series head reached
							all [not reverse? slot2 >= end]	;-- block series tail reached
						]
					]
					if all [n < values slot2 >= end][found?: no] ;-- partial match case, make it fail
					if all [match? found?][slot: slot2]		;-- slot2 points to tail of match
				]
				slot: slot + step
				any [
					match?									;-- /match option limits to one comparison
					all [not match? found?]					;-- match found
					all [reverse? slot < end]				;-- head of block series reached
					all [not reverse? slot >= end]			;-- tail of block series reached
				]
			]
			unless all [tail? not reverse?][slot: slot - step]	;-- point before/after found value
			if all [tail? reverse?][slot: slot - step]			;-- additional step for tailed reversed search
		
			either found? [
				blk: as red-block! result
				blk/head: (as-integer slot - s/offset) >> 4	;-- just change the head position on stack
			][
				result/header: TYPE_NONE					;-- change the stack 1st argument to none.
			]
		][
			key: _hashtable/get table value hash/head case? last? reverse?
			either any [
				key = null
				all [part? key > part]
				all [step > 1 (as-integer s/offset + blk/head - key) >> 4 % step <> 0]
			][
				result/header: TYPE_NONE
			][
				blk: as red-block! result
				if tail? [key: key + 1]
				blk/head: (as-integer key - s/offset) >> 4	;-- just change the head position on stack
			]
		]
		result
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
		return:	 [red-value!]
		/local
			s	   [series!]
			p	   [red-value!]
			b	   [red-block!]
			result [red-value!]
			type   [integer!]
			offset [integer!]
	][
		result: find blk value part only? case? any? with-arg skip last? reverse? no no
		
		if TYPE_OF(result) <> TYPE_NONE [
			offset: either only? [1][					;-- values > 0 => series comparison mode
				type: TYPE_OF(value)
				either any [							;@@ replace with ANY_BLOCK?
					type = TYPE_BLOCK
					type = TYPE_PAREN
					type = TYPE_PATH
					type = TYPE_GET_PATH
					type = TYPE_SET_PATH
					type = TYPE_LIT_PATH
				][
					b: as red-block! value
					s: GET_BUFFER(b)
					(as-integer s/tail - s/offset) >> 4 - b/head
				][1]
			]
			blk: as red-block! result
			s: GET_BUFFER(blk)
			p: s/offset + blk/head + offset
			
			either p < s/tail [
				copy-cell p result
			][
				result/header: TYPE_NONE
			]
		]
		result
	]

	compare-value: func [								;-- Compare function return integer!
		value1   [red-value!]
		value2   [red-value!]
		op		 [integer!]
		flags	 [integer!]
		return:  [integer!]
		/local
			action-compare offset res temp
	][
		#if debug? = yes [if verbose > 0 [print-line "block/compare-value"]]

		offset: flags >>> 1
		value1: value1 + offset
		value2: value2 + offset
		if flags and sort-reverse-mask = sort-reverse-mask [
			temp: value1 value1: value2 value2: temp
		]
		action-compare: as function! [
			value1  [red-value!]						;-- first operand
			value2  [red-value!]						;-- second operand
			op	    [integer!]							;-- type of comparison
			return: [integer!]
		] actions/get-action-ptr value1 ACT_COMPARE

		res: action-compare value1 value2 op
		if res = -2 [res: TYPE_OF(value1) - TYPE_OF(value2)]
		res
	]

	compare-call: func [								;-- Wrap red function!
		value1   [red-value!]
		value2   [red-value!]
		fun		 [integer!]
		flags	 [integer!]
		return:  [integer!]
		/local
			res  [red-value!]
			bool [red-logic!]
			int  [red-integer!]
			d    [red-float!]
			all? [logic!]
			num  [integer!]
			blk1 [red-block!]
			blk2 [red-block!]
			s1   [series!]
			s2   [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/compare-call"]]

		stack/mark-func words/_body						;@@ find something more adequate

		all?: flags and sort-all-mask = sort-all-mask
		if all? [
			num: flags >>> 2
			blk1: make-at as red-block! ALLOC_TAIL(root) num
			blk2: make-at as red-block! ALLOC_TAIL(root) num
			s1: GET_BUFFER(blk1)
			s2: GET_BUFFER(blk2)
			copy-memory as byte-ptr! s1/offset as byte-ptr! value1 num << 4
			copy-memory as byte-ptr! s2/offset as byte-ptr! value2 num << 4
			s1/tail: s1/tail + num
			s2/tail: s2/tail + num
			value1: as red-value! blk1
			value2: as red-value! blk2
		]

		flags: flags and sort-reverse-mask
		either zero? flags [
			stack/push value2
			stack/push value1
		][
			stack/push value1
			stack/push value2
		]
		_function/call as red-function! fun global-ctx	;FIXME: hardcoded origin context
		stack/unwind
		stack/pop 1

		res: stack/top
		switch TYPE_OF(res) [
			TYPE_LOGIC [
				bool: as red-logic! res
				either bool/value [1][-1]
			]
			TYPE_INTEGER [
				int: as red-integer! res
				negate int/value
			]
			TYPE_FLOAT [
				d: as red-float! res
				case [
					d/value > 0.0 [-1]
					d/value < 0.0 [1]
					true [0]
				]
			]
			TYPE_NONE [-1]
			default [1]
		]
	]

	sort: func [
		blk			[red-block!]
		case?		[logic!]
		skip		[red-integer!]
		comparator	[red-function!]
		part		[red-value!]
		all?		[logic!]
		reverse?	[logic!]
		stable?		[logic!]
		return:		[red-block!]
		/local
			s		[series!]
			head	[red-value!]
			cmp		[integer!]
			len		[integer!]
			len2	[integer!]
			step	[integer!]
			int		[red-integer!]
			blk2	[red-block!]
			fun		[red-function!]
			op		[integer!]
			flags	[integer!]
			offset	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/sort"]]

		step: 1
		flags: 0
		s: GET_BUFFER(blk)
		head: s/offset + blk/head
		if head = s/tail [return blk]					;-- early exit if nothing to reverse
		len: rs-length? blk

		if OPTION?(part) [
			len2: either TYPE_OF(part) = TYPE_INTEGER [
				int: as red-integer! part
				if int/value <= 0 [return blk]			;-- early exit if part <= 0
				int/value
			][
				blk2: as red-block! part
				unless all [
					TYPE_OF(blk2) = TYPE_OF(blk)		;-- handles ANY-STRING!
					blk2/node = blk/node
				][
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part)
				]
				blk2/head - blk/head
			]
			if len2 < len [
				len: len2
				if negative? len2 [
					len2: negate len2
					blk/head: blk/head - len2
					len: either negative? blk/head [blk/head: 0 0][len2]
					head: head - len
				]
			]
		]

		if OPTION?(skip) [
			assert TYPE_OF(skip) = TYPE_INTEGER
			step: skip/value
			if any [
				step <= 0
				len % step <> 0
				step > len
			][
				ERR_INVALID_REFINEMENT_ARG(refinements/_skip skip)
			]
			if step > 1 [len: len / step]
		]

		if reverse? [flags: flags or sort-reverse-mask]
		op: either case? [COMP_CASE_SORT][COMP_SORT]
		cmp: as-integer :compare-value

		if OPTION?(comparator) [
			switch TYPE_OF(comparator) [
				TYPE_FUNCTION [
					if all [all? OPTION?(skip)] [
						flags: flags or sort-all-mask
						flags: step << 2 or flags
					]
					cmp: as-integer :compare-call
					op: as-integer comparator
				]
				TYPE_INTEGER [
					int: as red-integer! comparator
					offset: int/value
					if any [offset < 1 offset > step][
						fire [
							TO_ERROR(script out-of-range)
							comparator
						]
					]
					flags: offset - 1 << 1 or flags
				]
				TYPE_BLOCK [
					blk2: as red-block! part
					;TBD handles block! value
				]
				default [
					ERR_INVALID_REFINEMENT_ARG((refinement/load "compare") comparator)
				]
			]
		]
		either stable? [
			_sort/mergesort as byte-ptr! head len step * (size? red-value!) op flags cmp
		][
			_sort/qsort as byte-ptr! head len step * (size? red-value!) op flags cmp
		]
		blk
	]
	
	;--- Reading actions ---
	
	pick: func [
		blk		[red-block!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
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
	
	insert: func [
		blk		  [red-block!]
		value	  [red-value!]
		part-arg  [red-value!]
		only?	  [logic!]
		dup-arg	  [red-value!]
		append?	  [logic!]
		return:	  [red-value!]
		/local
			src		[red-block!]
			cell	[red-value!]
			limit	[red-value!]
			head	[red-value!]
			key		[red-value!]
			hash	[red-hash!]
			table	[node!]
			int		[red-integer!]
			p		[int-ptr!]
			b		[red-block!]
			s		[series!]
			cnt		[integer!]
			part	[integer!]
			size	[integer!]
			slots	[integer!]
			values?	[logic!]
			head?	[logic!]
			tail?	[logic!]
			hash?	[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/insert"]]
		
		cnt:  1
		part: -1
		hash?: TYPE_OF(blk) = TYPE_HASH
		if hash? [
			hash: as red-hash! blk
			table: hash/table
		]

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
			if negative? cnt [return as red-value! blk]
		]
		
		values?: all [
			not only?									;-- /only support
			any [
				TYPE_OF(value) = TYPE_BLOCK				;@@ replace it with: typeset/any-block?
				TYPE_OF(value) = TYPE_PATH				;@@ replace it with: typeset/any-block?
			]
		]
		size: either values? [
			src: as red-block! value
			rs-length? src
		][
			1
		]
		if any [negative? part part > size][part: size] ;-- truncate if off-range part value
		
		s: GET_BUFFER(blk)
		head?: zero? blk/head
		tail?: any [(s/offset + blk/head = s/tail) append?]
		slots: part * cnt
		
		unless tail? [									;TBD: process head? case separately
			size: as-integer s/tail + slots - s/offset
			if size > s/size [s: expand-series s size]
			head: s/offset + blk/head
			move-memory									;-- make space
				as byte-ptr! head + slots
				as byte-ptr! head
				as-integer s/tail - head
			
			s/tail: s/tail + slots
		]

		if hash? [
			s: as series! table/value
			p: (as int-ptr! s/offset) + 1
			p: as int-ptr! p/value
			s: as series! p/value
			size: (as-integer s/tail + slots - s/offset) >> 2
			if size > s/size [s: expand-series-filled s size #"^(FF)"]
			unless tail? [
				p: (as int-ptr! s/offset) + blk/head
				move-memory
					as byte-ptr! p + slots
					as byte-ptr! p
					as-integer s/tail - as cell! p
			]
			s/tail: as cell! (as int-ptr! s/tail) + slots
		]

		while [not zero? cnt][							;-- /dup support
			either values? [
				s: GET_BUFFER(src)
				cell: s/offset + src/head
				limit: cell + part						;-- /part support

				either tail? [
					while [cell < limit][				;-- multiple values case
						key: copy-cell cell ALLOC_TAIL(blk)
						cell: cell + 1
						key: key - 1
						if hash? [_hashtable/put table key no]
					]
				][
					while [cell < limit][				;-- multiple values case
						copy-cell cell head
						if hash? [_hashtable/put table head no]
						head: head + 1
						cell: cell + 1
					]
				]
			][											;-- single value case
				either tail? [
					key: copy-cell value ALLOC_TAIL(blk)
					key: key - 1
					if hash? [_hashtable/put table key no]
				][
					copy-cell value head
					if hash? [_hashtable/put table head no]
				]
			]
			cnt: cnt - 1
		]
		unless append? [
			blk/head: blk/head + slots
			s: GET_BUFFER(blk)
			assert s/offset + blk/head <= s/tail

			if hash? [_hashtable/refresh table slots blk/head]
		]
		as red-value! blk
	]
	
	clear: func [
		blk		[red-block!]
		return:	[red-value!]
		/local
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/clear"]]

		s: GET_BUFFER(blk)
		s/tail: s/offset + blk/head
		as red-value! blk
	]
	
	poke: func [
		blk		[red-block!]
		index	[integer!]
		data	[red-value!]
		boxed	[red-value!]
		return:	[red-value!]
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
			fire [TO_ERROR(script out-of-range) boxed]
		][
			copy-cell data cell
			stack/set-last data
		]
		as red-value! data
	]
	
	remove: func [
		blk	 	 [red-block!]
		part-arg [red-value!]
		return:	 [red-block!]
		/local
			s		[series!]
			part	[integer!]
			head	[red-value!]
			int		[red-integer!]
			b		[red-block!]
			hash?	[logic!]
			hash	[red-hash!]
	][
		s: GET_BUFFER(blk)
		head: s/offset + blk/head
		if head = s/tail [return blk]					;-- early exit if nothing to remove
		
		part: 1

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
				b/head - blk/head
			]
			if part <= 0 [return blk]					;-- early exit if negative /part index
		]

		hash?: TYPE_OF(blk) = TYPE_HASH
		either head + part < s/tail [
			move-memory 
				as byte-ptr! head
				as byte-ptr! head + part
				as-integer s/tail - (head + part)
			s/tail: s/tail - part

			if hash? [
				hash: as red-hash! blk
				_hashtable/refresh hash/table 0 - part blk/head + part
			]
		][
			s/tail: head
		]
		blk
	]

	reverse: func [
		blk	 	 [red-block!]
		part-arg [red-value!]
		return:	 [red-block!]
		/local
			s		[series!]
			part	[integer!]
			size	[integer!]
			head	[red-value!]
			end		[red-value!]
			tmp		[red-value!]
			int		[red-integer!]
			b		[red-block!]
			hash?	[logic!]
			hash	[red-hash!]
			table	[node!]
	][
		s: GET_BUFFER(blk)
		head: s/offset + blk/head
		if head = s/tail [return blk]		;-- early exit if nothing to reverse
		size: rs-length? blk

		part: size

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
				b/head - blk/head
			]
			if part <= 0 [return blk]		;-- early exit if negative /part index
		]
		if part > size [part: size] 		;-- truncate if off-range part value

		hash?: TYPE_OF(blk) = TYPE_HASH
		if hash? [
			hash: as red-hash! blk
			table: hash/table
		]
		end: head + part - 1
		tmp: stack/push*
		while [head < end][
			copy-cell head tmp
			copy-cell end head
			copy-cell tmp end
			if hash? [
				_hashtable/delete table head
				_hashtable/delete table end
				_hashtable/put table head no
				_hashtable/put table end no
			]
			head: head + 1
			end: end - 1
		]
		stack/pop 1
		blk
	]

	take: func [
		blk	    	[red-block!]
		part-arg	[red-value!]
		deep?		[logic!]
		last?		[logic!]
		return:		[red-value!]
		/local
			int		[red-integer!]
			b		[red-block!]
			new		[red-block!]
			offset	[red-value!]
			slot	[red-value!]
			buffer	[series!]
			node	[node!]
			part	[integer!]
			slots	[integer!]
			type	[integer!]
			hash?	[logic!]
			hash	[red-hash!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/take"]]

		s: GET_BUFFER(blk)
		slots: rs-length? blk
		if slots <= 0 [								;-- return NONE if blk is empty
			set-type as cell! blk TYPE_NONE
			return as red-value! blk
		]

		offset: s/offset + blk/head
		part:   1

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
				either b/head < blk/head [0][
					either last? [slots - (b/head - blk/head)][b/head - blk/head]
				]
			]
			if part > slots [part: slots]
		]

		hash?: TYPE_OF(blk) = TYPE_HASH

		new:		as red-block! stack/push*
		new/header: either hash? [TYPE_HASH][TYPE_BLOCK]
		new/node: 	alloc-cells part + 1
		new/head: 	0
		buffer: 	as series! new/node/value

		either positive? part [
			if last? [
				offset: s/tail - part
				s/tail: offset
			]
			copy-memory
				as byte-ptr! buffer/offset
				as byte-ptr! offset
				part << 4
			buffer/tail: buffer/offset + part

			unless last? [
				move-memory
					as byte-ptr! offset
					as byte-ptr! offset + part
					as-integer s/tail - (offset + part)
				s/tail: s/tail - part
			]
			if hash? [
				slots: either last? [slots - 1][blk/head + part]
				hash: as red-hash! blk
				_hashtable/refresh hash/table 0 - part slots
			]
		][return as red-value! new]

		if deep? [
			slot: buffer/offset
			until [
				type: TYPE_OF(slot)
				if ANY_SERIES?(type) [
					actions/copy
						as red-series! slot
						slot						;-- overwrite the slot value
						null
						yes
						null
				]
				slot: slot + 1
				slot >= buffer/tail
			]
		]

		either part = 1	[							;-- flatten block
			copy-cell as cell! buffer/offset as cell! new
		][
			if hash? [
				hash: as red-hash! new
				hash/table: _hashtable/init part new no
				hash
			]
		]
		as red-value! new
	]

	swap: func [
		blk1	   [red-block!]
		blk2	   [red-block!]
		return:	   [red-block!]
		/local
			s		[series!]
			i		[integer!]
			tmp		[integer!]
			h1		[int-ptr!]
			h2		[int-ptr!]
			type1	[integer!]
			type2	[integer!]
			hash	[red-hash!]
			table	[node!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/swap"]]

		type1: TYPE_OF(blk1)
		type2: TYPE_OF(blk2)
		if all [
			type2 <> TYPE_BLOCK
			type2 <> TYPE_HASH
		][ERR_EXPECT_ARGUMENT(type2 2)]

		s: GET_BUFFER(blk1)
		h1: as int-ptr! s/offset + blk1/head
		if s/tail = as red-value! h1 [return blk1]		;-- early exit if nothing to swap

		s: GET_BUFFER(blk2)
		h2: as int-ptr! s/offset + blk2/head
		if s/tail = as red-value! h2 [return blk1]		;-- early exit if nothing to swap

		i: 0
		until [
			tmp: h1/value
			h1/value: h2/value
			h2/value: tmp
			h1: h1 + 1
			h2: h2 + 1
			i:	i + 1
			i = 4
		]

		if type1 = TYPE_HASH [
			hash: as red-hash! blk1
			h1: h1 - 4
			_hashtable/delete hash/table as red-value! h1
			_hashtable/put hash/table as red-value! h1 no
		]
		if type2 = TYPE_HASH [
			hash: as red-hash! blk2
			h2: h2 - 4
			_hashtable/delete hash/table as red-value! h2
			_hashtable/put hash/table as red-value! h2 no
		]
		blk1
	]

	trim: func [
		blk			[red-block!]
		head?		[logic!]
		tail?		[logic!]
		auto?		[logic!]
		lines?		[logic!]
		all?		[logic!]
		with-arg	[red-value!]
		return:		[red-series!]
		/local
			s		[series!]
			value	[red-value!]
			cur		[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/trim"]]

		s: GET_BUFFER(blk)
		value: s/offset + blk/head
		cur: value

		while [value < s/tail][
			if TYPE_OF(value) <> TYPE_NONE [
				unless value = cur [copy-cell value cur]
				cur: cur + 1
			]
			value: value + 1
		]
		s/tail: cur
		as red-series! blk
	]

	;--- Misc actions ---
	
	copy: func [
		blk	    	[red-block!]
		new			[red-block!]
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
			node	[node!]
			part	[integer!]
			slots	[integer!]
			type	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "block/copy"]]
		
		s: GET_BUFFER(blk)
		
		slots:	rs-length? blk
		offset: s/offset + blk/head
		part:   as-integer s/tail - offset				;@@ should be `part: slots`
		
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
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
				]
				b/head - blk/head
			]
			slots: part
			part: part << 4
		]
		
		node: 	alloc-cells slots + 1
		buffer: as series! node/value
		
		unless zero? part [
			copy-memory 
				as byte-ptr! buffer/offset
				as byte-ptr! offset
				part
				
			buffer/tail: buffer/offset + slots
		]
		
		new/header: TYPE_BLOCK
		new/node: 	node
		new/head: 	0
		
		if deep? [
			slot: buffer/offset
			until [
				type: TYPE_OF(slot)
				if ANY_SERIES?(type) [
					actions/copy 
						as red-series! slot
						slot						;-- overwrite the slot value
						null
						yes
						null
				]
				slot: slot + 1
				slot >= buffer/tail
			]
		]
		
		as red-series! new
	]

	init: does [
		datatype/register [
			TYPE_BLOCK
			TYPE_VALUE
			"block!"
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
			:sort
			:skip
			:swap
			:tail
			:tail?
			:take
			:trim
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