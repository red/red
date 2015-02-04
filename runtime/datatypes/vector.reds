Red/System [
	Title:   "Vector! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %vector.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

vector: context [
	verbose: 0
	
	rs-length?: func [
		vec 	[red-vector!]
		return: [integer!]
		/local
			s [series!]
	][
		s: GET_BUFFER(vec)
		assert (as-integer s/tail - s/offset) >> (GET_UNIT(s) >> 1) - vec/head >= 0
		(as-integer s/tail - s/offset) >> (GET_UNIT(s) >> 1) - vec/head
	]
	
	rs-skip: func [
		vec 	[red-vector!]
		len		[integer!]
		return: [logic!]
		/local
			s	   [series!]
			offset [integer!]
	][
		assert len >= 0
		s: GET_BUFFER(vec)
		offset: vec/head + len << (GET_UNIT(s) >> 1)

		if (as byte-ptr! s/offset) + offset <= as byte-ptr! s/tail [
			vec/head: vec/head + len
		]
		(as byte-ptr! s/offset) + offset >= as byte-ptr! s/tail
	]
	
	rs-next: func [
		vec 	[red-vector!]
		return: [logic!]
		/local
			s [series!]
	][
		rs-skip vec 1
	]
	
	rs-head: func [
		vec	    [red-vector!]
		return: [byte-ptr!]
		/local
			s [series!]
	][
		s: GET_BUFFER(vec)
		(as byte-ptr! s/offset) + (vec/head << (GET_UNIT(s) >> 1))
	]
	
	rs-tail: func [
		vec	    [red-vector!]
		return: [byte-ptr!]
		/local
			s [series!]
	][
		s: GET_BUFFER(vec)
		as byte-ptr! s/tail
	]

	rs-tail?: func [
		vec	    [red-vector!]
		return: [logic!]
		/local
			s [series!]
	][
		s: GET_BUFFER(vec)
		(as byte-ptr! s/offset) + (vec/head << (GET_UNIT(s) >> 1)) >= as byte-ptr! s/tail
	]

	rs-clear: func [
		vec [red-vector!]
		/local
			s [series!]
	][
		s: GET_BUFFER(vec)
		s/tail: as cell! (as byte-ptr! s/offset) + (vec/head << (GET_UNIT(s) >> 1))	
	]
	
	rs-append-int: func [
		vec		[red-vector!]
		n		[integer!]
		/local
			s	 [series!]
			p	 [byte-ptr!]
			p4	 [int-ptr!]
	][
		s: GET_BUFFER(vec)
		p: alloc-tail-unit s GET_UNIT(s)
		
		switch vec/type [
			TYPE_INTEGER [
				p4: as int-ptr! p
				p4/value: n
			]
			;TBD
		]
	]
	
	rs-append: func [
		vec		[red-vector!]
		value	[red-value!]
		return: [red-value!]
		/local
			int  [red-integer!]
			s	 [series!]
			p	 [byte-ptr!]
			p4	 [int-ptr!]
	][
		assert TYPE_OF(value) = vec/type
		s: GET_BUFFER(vec)
		p: alloc-tail-unit s GET_UNIT(s)
		
		switch TYPE_OF(value) [
			TYPE_INTEGER [
				int: as red-integer! value
				p4: as int-ptr! p
				p4/value: int/value
			]
			;TBD
		]
		value
	]
	
	rs-insert: func [
		vec		[red-vector!]
		offset	[integer!]								;-- offset from head in elements
		value	[red-value!]
		return: [series!]
		/local
			int	 [red-integer!]
			s	 [series!]
			p	 [byte-ptr!]
			p4	 [int-ptr!]
			unit [integer!]
	][
		s: GET_BUFFER(vec)
		unit: GET_UNIT(s)

		if ((as byte-ptr! s/tail) + unit) > ((as byte-ptr! s + 1) + s/size) [
			s: expand-series s 0
		]
		p: (as byte-ptr! s/offset) + (offset << (unit >> 1))

		move-memory										;-- make space
			p + unit
			p
			as-integer (as byte-ptr! s/tail) - p

		s/tail: as cell! (as byte-ptr! s/tail) + unit
		
		switch TYPE_OF(value) [
			TYPE_INTEGER [
				int: as red-integer! value
				p4: as int-ptr! p
				p4/value: int/value
			]
			;TBD
		]
		s
	]
	
	get-position: func [
		base	   [integer!]
		return:	   [integer!]
		/local
			vec	   [red-vector!]
			index  [red-integer!]
			s	   [series!]
			offset [integer!]
			max	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/get-position"]]

		vec: as red-vector! stack/arguments
		index: as red-integer! vec + 1

		assert TYPE_OF(vec)   = TYPE_VECTOR
		assert TYPE_OF(index) = TYPE_INTEGER

		s: GET_BUFFER(vec)

		if all [base = 1 index/value <= 0][base: base - 1]
		offset: vec/head + index/value - base			;-- index is one-based
		if negative? offset [offset: 0]
		max: (as-integer s/tail - s/offset) >> (GET_UNIT(s) >> 1)
		if offset > max [offset: max]

		offset
	]
	
	append-values: func [
		vec	[red-vector!]
		blk [red-block!]
		/local
			value [red-value!]
			tail  [red-value!]
	][
		value: block/rs-head blk
		tail:  block/rs-tail blk
		
		while [value < tail][
			rs-append vec value
			value: value + 1
		]
	]
	
	clone: func [
		vec		[red-vector!]							;-- clone the vector in-place
		return: [red-vector!]
		/local
			new    [node!]
			s	   [series!]
			target [series!]
			size   [integer!]
	][
		s: GET_BUFFER(vec)
		size: s/size									;-- @@ head position ignored
		new: alloc-bytes size
		
		unless zero? size [
			target: as series! new/value
			copy-memory
				as byte-ptr! target/offset
				as byte-ptr! s/offset
				size
			target/tail: as cell! ((as byte-ptr! target/offset) + size)
		]
		vec/node: new
		vec
	]
	
	push: func [
		vec [red-vector!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/push"]]

		copy-cell as red-value! vec stack/push*
	]
	
	make-at: func [
		slot	[red-value!]
		size	[integer!]
		type	[integer!]
		unit	[integer!]
		return: [red-vector!]
		/local
			vec [red-vector!]
			s	[series!]
	][
		vec: as red-vector! slot
		vec/header: TYPE_VECTOR							;-- implicit reset of all header flags
		vec/head: 	0
		vec/node: 	alloc-bytes size * unit
		vec/type:	type
		
		s: GET_BUFFER(vec)
		s/flags: s/flags and flag-unit-mask or unit
		vec
	]

	;--- Actions ---
	
	make: func [
		proto	[red-value!]
		spec	[red-value!]
		return:	[red-vector!]
		/local
			vec	  [red-vector!]
			int	  [red-integer!]
			value [red-value!]
			size  [integer!]
			unit  [integer!]
			type  [integer!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/make"]]
		
		size: 1
		unit: 4
		type: TYPE_OF(spec)
		
		switch type [
			TYPE_INTEGER [
				int: as red-integer! spec
				size: int/value
			]
			TYPE_BLOCK [
				size:  block/rs-length? as red-block! spec
				value: block/rs-head as red-block! spec
				type:  TYPE_OF(value)
				unit:  switch type [
					TYPE_INTEGER [size? integer!]
					;TBD
				]
			]
			default [--NOT_IMPLEMENTED--]
		]
		if zero? size [size: 1]
		
		vec: make-at stack/push* size type unit
		
		if TYPE_OF(spec) = TYPE_BLOCK [
			append-values vec as red-block! spec
		]
		vec
	]
	
	form: func [
		vec		[red-vector!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
		/local
			s		[series!]
			p		[int-ptr!]
			end		[int-ptr!]
			formed	[c-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/form"]]
		
		string/concatenate-literal buffer "make vector! ["
		part: part - 14

		s: GET_BUFFER(vec)
		p: (as int-ptr! s/offset) + vec/head			;@@ only for TYPE_INTEGER for now
		end: as int-ptr! s/tail
		
		while [p < end][
			formed: integer/form-signed p/value
			string/concatenate-literal buffer formed
			part: part - system/words/length? formed	;@@ optimize by removing length?
			
			if p + 1 < end [
				string/append-char GET_BUFFER(buffer) as-integer space
				part: part - 1
			]
			p: p + 1
		]		
		string/append-char GET_BUFFER(buffer) as-integer #"]"
		part - 1
	]
	
	mold: func [
		vec		[red-vector!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return:	[integer!]
		/local
			s	[series!]
			p	[int-ptr!]
			end [int-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/mold"]]
		
		form vec buffer arg part
	]
	
	;--- Property reading actions ---
	
	head?: func [
		return:	  [red-value!]
		/local
			vec	  [red-vector!]
			state [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/head?"]]

		vec:   as red-vector! stack/arguments
		state: as red-logic! vec
		
		state/header: TYPE_LOGIC
		state/value:  zero? vec/head
		as red-value! state
	]
	
	tail?: func [
		return:	  [red-value!]
		/local
			vec	  [red-vector!]
			state [red-logic!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/tail?"]]

		vec:   as red-vector! stack/arguments
		state: as red-logic! vec
		
		s: GET_BUFFER(vec)

		state/header: TYPE_LOGIC
		state/value:  (as byte-ptr! s/offset) + (vec/head << (GET_UNIT(s) >> 1)) = as byte-ptr! s/tail
		as red-value! state
	]
	
	index?: func [
		return:	  [red-value!]
		/local
			vec	  [red-vector!]
			index [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/index?"]]

		vec:   as red-vector! stack/arguments
		index: as red-integer! vec
		
		index/header: TYPE_INTEGER
		index/value:  vec/head + 1
		as red-value! index
	]
	
	length?: func [
		vec		[red-vector!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/length?"]]
		
		rs-length? vec
	]
	
	;--- Navigation actions ---
	
	at: func [
		return:	[red-value!]
		/local
			vec	[red-vector!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/at"]]
		
		vec: as red-vector! stack/arguments
		vec/head: get-position 1
		as red-value! vec
	]
	
	back: func [
		return:	[red-value!]
		/local
			vec	[red-vector!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/back"]]

		block/back										;-- identical behaviour as block!
	]
	
	next: func [
		return:	[red-value!]
		/local
			vec	[red-vector!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/next"]]
	
		rs-next as red-vector! stack/arguments
		stack/arguments
	]
		
	skip: func [
		return:	[red-value!]
		/local
			vec	[red-vector!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/skip"]]

		vec: as red-vector! stack/arguments
		vec/head: get-position 0
		as red-value! vec
	]
	
	head: func [
		return:	[red-value!]
		/local
			vec	[red-vector!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/head"]]

		vec: as red-vector! stack/arguments
		vec/head: 0
		as red-value! vec
	]
	
	tail: func [
		return:	[red-value!]
		/local
			vec	[red-vector!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/tail"]]

		vec: as red-vector! stack/arguments
		s: GET_BUFFER(vec)
		
		vec/head: (as-integer s/tail - s/offset) >> (GET_UNIT(s) >> 1)
		as red-value! vec
	]

	;--- Reading actions ---
	
	pick: func [
		vec		[red-vector!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			int    [red-integer!]
			s	   [series!]
			offset [integer!]
			unit   [integer!]
			p1	   [byte-ptr!]
			p4	   [int-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/pick"]]

		s: GET_BUFFER(vec)
		unit: GET_UNIT(s)

		offset: vec/head + index - 1					;-- index is one-based
		if negative? index [offset: offset + 1]

		p1: (as byte-ptr! s/offset) + (offset << (unit >> 1))

		either any [
			zero? index
			p1 >= as byte-ptr! s/tail
			p1 <  as byte-ptr! s/offset
		][
			none-value
		][
			switch vec/type [
				TYPE_INTEGER [
					p4: as int-ptr! p1
					int: as red-integer! stack/push*
					int/header: TYPE_INTEGER
					int/value: p4/value
					as red-value! int				
				]
				;TBD
			]
		]
	]
	
	;--- Modifying actions ---
			
	insert: func [
		vec		 [red-vector!]
		value	 [red-value!]
		part-arg [red-value!]
		only?	 [logic!]
		dup-arg	 [red-value!]
		append?	 [logic!]
		return:	 [red-value!]
		/local
			src		  [red-block!]
			cell	  [red-value!]
			limit	  [red-value!]
			int		  [red-integer!]
			char	  [red-char!]
			sp		  [red-vector!]
			s		  [series!]
			s2		  [series!]
			dup-n	  [integer!]
			cnt		  [integer!]
			part	  [integer!]
			len		  [integer!]
			added	  [integer!]
			vec-type  [integer!]
			tail?	  [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "vector/insert"]]

		dup-n: 1
		cnt:   1
		part: -1
		vec-type: vec/type

		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
			][
				sp: as red-vector! part-arg
				unless all [
					TYPE_OF(sp) = TYPE_VECTOR
					sp/node = vec/node
				][
					fire [TO_ERROR(script invalid-part) part-arg]
				]
				sp/head + 1								;-- /head is 0-based
			]
		]
		if OPTION?(dup-arg) [
			int: as red-integer! dup-arg
			cnt: int/value
			if negative? cnt [return as red-value! vec]
			dup-n: cnt
		]

		s: GET_BUFFER(vec)
		tail?: any [
			(as-integer s/tail - s/offset) >> (GET_UNIT(s) >> 1) = vec/head
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
			added: 0
			
			while [all [cell < limit added <> part]][	;-- multiple values case
				if TYPE_OF(cell) <> vec-type [
					fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(cell)]
				]
				either tail? [
					rs-append vec cell
				][
					rs-insert vec vec/head + added cell
				]
				added: added + 1
				cell: cell + 1
			]
			cnt: cnt - 1
		]
		unless append? [
			added: added * dup-n
			vec/head: vec/head + added
			s: GET_BUFFER(vec)
			assert (as byte-ptr! s/offset) + (vec/head << (GET_UNIT(s) >> 1)) <= as byte-ptr! s/tail
		]
		as red-value! vec
	]
	
	init: does [
		datatype/register [
			TYPE_VECTOR
			TYPE_VALUE
			"vector!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			null			;eval-path
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
			:at
			:back
			null			;change
			null			;clear
			null			;copy
			null			;find
			:head
			:head?
			:index?
			:insert
			:length?
			:next
			:pick
			null			;poke
			null			;remove
			null			;reverse
			null			;select
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
]