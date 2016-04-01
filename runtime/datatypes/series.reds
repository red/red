Red/System [
	Title:   "Series! datatype runtime functions"
	Author:  "Nenad Rakocevic, Qingtian Xie"
	File: 	 %series.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

_series: context [
	verbose: 0

	rs-skip: func [
		ser 	[red-series!]
		len		[integer!]
		return: [logic!]
		/local
			s	   [series!]
			offset [integer!]
	][
		assert len >= 0
		s: GET_BUFFER(ser)
		offset: ser/head + len << (log-b GET_UNIT(s))

		if (as byte-ptr! s/offset) + offset <= as byte-ptr! s/tail [
			ser/head: ser/head + len
		]
		(as byte-ptr! s/offset) + offset >= as byte-ptr! s/tail
	]

	get-position: func [
		base	   [integer!]
		return:	   [integer!]
		/local
			ser	   [red-series!]
			index  [red-integer!]
			s	   [series!]
			offset [integer!]
			max	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/get-position"]]

		ser: as red-series! stack/arguments
		index: as red-integer! ser + 1

		assert TYPE_OF(index) = TYPE_INTEGER

		s: GET_BUFFER(ser)

		if all [base = 1 index/value <= 0][base: base - 1]
		offset: ser/head + index/value - base			;-- index is one-based
		if negative? offset [offset: 0]
		max: (as-integer s/tail - s/offset) >> (log-b GET_UNIT(s))
		if offset > max [offset: max]

		offset
	]

	get-length: func [
		ser		   [red-series!]
		absolute?  [logic!]
		return:	   [integer!]
		/local
			s	   [series!]
			offset [integer!]
	][
		s: GET_BUFFER(ser)
		offset: either absolute? [0][ser/head]
		if negative? offset [offset: 0]					;-- @@ beware of symbol/index leaking here...
		(as-integer s/tail - s/offset) >> (log-b GET_UNIT(s)) - offset
	]

	;-- Actions --
	
	random: func [
		ser		[red-series!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			char [red-char!]
			vec [red-vector!]
			s	 [series!]
			size [integer!]
			unit [integer!]
			len	 [integer!]
			temp [byte-ptr!]
			idx	 [byte-ptr!]
			head [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/random"]]

		either seed? [
			ser/header: TYPE_UNSET				;-- TODO: calc series to seed.
		][
			s: GET_BUFFER(ser)
			unit: GET_UNIT(s)
			head: (as byte-ptr! s/offset) + (ser/head << (log-b unit))
			size: (as-integer s/tail - s/offset) >> (log-b unit) - ser/head

			either only? [
				either positive? size [
					idx: head + (_random/rand % size << (log-b unit))
					switch TYPE_OF(ser) [
						TYPE_BLOCK
						TYPE_HASH
						TYPE_PAREN [
							copy-cell as cell! idx as cell! ser
						]
						TYPE_VECTOR [
							vec: as red-vector! ser
							copy-cell vector/get-value idx unit vec/type as cell! ser
						]
						default [								;@@ ANY-STRING!
							char: as red-char! ser
							char/header: TYPE_CHAR
							char/value: string/get-char idx unit
						]
					]
				][
					ser/header: TYPE_NONE
				]
			][
				len: size
				temp: as byte-ptr! stack/push*
				while [size > 0][
					idx: head + (_random/rand % size << (log-b unit))
					copy-memory temp head unit
					copy-memory head idx unit
					copy-memory idx temp unit
					head: head + unit
					size: size - 1
				]
				stack/pop 1
			]
			ownership/check as red-value! ser words/_random null ser/head len
		]
		as red-value! ser
	]
	
	reflect: func [
		ser		[red-series!]
		field	[integer!]
		return:	[red-value!]
		/local
			obj [red-object!]
			res [red-value!]
	][
		case [
			field = words/owned [
				obj: ownership/owned? ser/node
				res: as red-value! either null? obj [none-value][obj]
			]
			true [
				--NOT_IMPLEMENTED--						;@@ raise error
			]
		]
		stack/set-last res
	]

	;--- Property reading actions ---

	head?: func [
		return:	  [red-value!]
		/local
			ser	  [red-series!]
			state [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/head?"]]

		ser:   as red-series! stack/arguments
		state: as red-logic! ser

		state/header: TYPE_LOGIC
		state/value:  zero? ser/head
		as red-value! state
	]

	tail?: func [
		return:	  [red-value!]
		/local
			ser	  [red-series!]
			state [red-logic!]
			s	  [series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/tail?"]]

		ser:   as red-series! stack/arguments
		state: as red-logic! ser

		s: GET_BUFFER(ser)

		state/header: TYPE_LOGIC
		state/value:  (as byte-ptr! s/offset) + (ser/head << (log-b GET_UNIT(s))) = as byte-ptr! s/tail
		as red-value! state
	]

	index?: func [
		return:	  [red-value!]
		/local
			ser	  [red-series!]
			index [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/index?"]]

		ser:   as red-series! stack/arguments
		index: as red-integer! ser

		index/header: TYPE_INTEGER
		index/value:  ser/head + 1
		as red-value! index
	]

	length?: func [
		ser		[red-series!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/length?"]]

		get-length ser no
	]

	;--- Navigation actions ---

	at: func [
		return:	[red-value!]
		/local
			ser	[red-series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/at"]]

		ser: as red-series! stack/arguments
		ser/head: get-position 1
		as red-value! ser
	]

	back: func [
		return:	[red-value!]
		/local
			ser	[red-series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/back"]]
		
		ser: as red-series! stack/arguments
		if ser/head >= 1 [ser/head: ser/head - 1]
		as red-value! ser
	]

	next: func [
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/next"]]

		rs-skip as red-series! stack/arguments 1
		stack/arguments
	]

	skip: func [
		return:	[red-value!]
		/local
			ser	[red-series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/skip"]]

		ser: as red-series! stack/arguments
		ser/head: get-position 0
		as red-value! ser
	]

	head: func [
		return:	[red-value!]
		/local
			ser	[red-series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/head"]]

		ser: as red-series! stack/arguments
		ser/head: 0
		as red-value! ser
	]

	tail: func [
		return:	[red-value!]
		/local
			ser	[red-series!]
			s	[series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/tail"]]

		ser: as red-series! stack/arguments
		s: GET_BUFFER(ser)
		ser/head: (as-integer s/tail - s/offset) >> (log-b GET_UNIT(s))
		as red-value! ser
	]

	;--- Reading actions ---

	pick: func [
		ser		[red-series!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			char   [red-char!]
			vec    [red-vector!]
			s	   [series!]
			offset [integer!]
			unit   [integer!]
			p1	   [byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/pick"]]

		s: GET_BUFFER(ser)
		unit: GET_UNIT(s)

		offset: ser/head + index - 1					;-- index is one-based
		if negative? index [offset: offset + 1]

		either any [
			zero? index
			offset < 0
			offset >= ((as-integer s/tail - s/offset) >> (log-b unit))
		][
			none-value
		][
			p1: (as byte-ptr! s/offset) + (offset << (log-b unit))
			switch TYPE_OF(ser) [
				TYPE_BLOCK								;@@ any-block?
				TYPE_HASH
				TYPE_MAP
				TYPE_PAREN
				TYPE_PATH
				TYPE_GET_PATH
				TYPE_SET_PATH
				TYPE_LIT_PATH [s/offset + offset]
				TYPE_VECTOR [
					vec: as red-vector! ser
					vector/get-value p1 unit vec/type
				]
				TYPE_BINARY [integer/push as-integer p1/value]
				default [								;@@ ANY-STRING!
					char: as red-char! stack/push*
					char/header: TYPE_CHAR
					char/value:  string/get-char p1 unit
					as red-value! char
				]
			]
		]
	]

	;--- Modifying actions ---

	clear: func [
		ser		[red-series!]
		return:	[red-value!]
		/local
			s	 [series!]
			size [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/clear"]]

		s: GET_BUFFER(ser)
		size: (as-integer s/tail - s/offset) >> (log-b GET_UNIT(s)) - ser/head
		ownership/check as red-value! ser words/_clear null ser/head size
		s/tail: as cell! (as byte-ptr! s/offset) + (ser/head << (log-b GET_UNIT(s)))
		ownership/check as red-value! ser words/_cleared null ser/head 0
		as red-value! ser
	]

	poke: func [
		ser		[red-series!]
		index	[integer!]
		data	[red-value!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			s	   [series!]
			offset [integer!]
			pos	   [byte-ptr!]
			unit   [integer!]
			char   [red-char!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/poke"]]

		s: GET_BUFFER(ser)
		unit: GET_UNIT(s)

		offset: ser/head + index - 1					;-- index is one-based
		if negative? index [offset: offset + 1]

		either any [
			zero? index
			offset < 0
			offset >= ((as-integer s/tail - s/offset) >> (log-b unit))
		][
			fire [
				TO_ERROR(script out-of-range)
				integer/push index
			]
		][
			pos: (as byte-ptr! s/offset) + (offset << (log-b unit))
			switch TYPE_OF(ser) [
				TYPE_BLOCK								;@@ any-block?
				TYPE_HASH
				TYPE_PAREN
				TYPE_PATH
				TYPE_GET_PATH
				TYPE_SET_PATH
				TYPE_LIT_PATH [
					copy-cell data s/offset + offset
				]
				TYPE_BINARY [binary/set-value pos data]
				TYPE_VECTOR [
					if TYPE_OF(data) <> ser/extra [
						fire [TO_ERROR(script invalid-arg) data]
					]
					vector/set-value pos data unit
				]
				default [								;@@ ANY-STRING!
					char: as red-char! data
					if TYPE_OF(char) <> TYPE_CHAR [
						fire [TO_ERROR(script invalid-arg) char]
					]
					string/poke-char s pos char/value
				]
			]
			ownership/check as red-value! ser words/_poke data offset 1
			stack/set-last data
		]
		data
	]

	remove: func [
		ser	 	 [red-series!]
		part-arg [red-value!]
		return:	 [red-series!]
		/local
			s		[series!]
			part	[integer!]
			items	[integer!]
			unit	[integer!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			int		[red-integer!]
			ser2	[red-series!]
			hash	[red-hash!]
	][
		s:    GET_BUFFER(ser)
		unit: GET_UNIT(s)
		head: (as byte-ptr! s/offset) + (ser/head << (log-b unit))
		tail: as byte-ptr! s/tail

		if head = tail [return ser]						;-- early exit if nothing to remove

		part: unit
		items: 1

		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
			][
				ser2: as red-series! part-arg
				unless all [
					TYPE_OF(ser2) = TYPE_OF(ser)		;-- handles ANY-STRING!
					ser2/node = ser/node
				][
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
				]
				ser2/head - ser/head
			]
			if part <= 0 [return ser]					;-- early exit if negative /part index
			items: part
			part: part << (log-b unit)
		]
		ownership/check as red-value! ser words/_remove null ser/head items
		
		either head + part < tail [
			move-memory
				head
				head + part
				as-integer tail - (head + part)
			s/tail: as red-value! tail - part

			if TYPE_OF(ser) = TYPE_HASH [
				part: part >> (log-b unit)
				hash: as red-hash! ser
				_hashtable/refresh hash/table 0 - part ser/head + part
			]
		][
			s/tail: as red-value! head
		]
		ownership/check as red-value! ser words/_removed null ser/head 0
		ser
	]

	reverse: func [
		ser	 	 [red-series!]
		part-arg [red-value!]
		return:	 [red-series!]
		/local
			s		[series!]
			part	[integer!]
			items	[integer!]
			unit	[integer!]
			head	[byte-ptr!]
			tail	[byte-ptr!]
			temp	[byte-ptr!]
			int		[red-integer!]
			ser2	[red-series!]
			hash?	[logic!]
			hash	[red-hash!]
			table	[node!]
	][
		s:    GET_BUFFER(ser)
		unit: GET_UNIT(s)
		head: (as byte-ptr! s/offset) + (ser/head << (log-b unit))
		tail: as byte-ptr! s/tail
		part: 0
		
		if head = tail [return ser]						;-- early exit if nothing to reverse
		
		either OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
			][
				ser2: as red-series! part-arg
				unless all [
					TYPE_OF(ser2) = TYPE_OF(ser)		;-- handles ANY-STRING!
					ser2/node = ser/node
				][
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
				]
				ser2/head - ser/head
			]
			if part <= 0 [return ser]					;-- early exit if negative /part index
			items: part
			part: part << (log-b unit)
		][
			items: get-length ser no
		]
		
		hash?: TYPE_OF(ser) = TYPE_HASH
		if hash? [
			hash: as red-hash! ser
			table: hash/table
		]
		if all [positive? part head + part < tail] [tail: head + part]
		tail: tail - unit								;-- point to last value
		temp: as byte-ptr! stack/push*
		while [head < tail][							;-- TODO: optimise it according to unit
			copy-memory temp head unit
			copy-memory head tail unit
			copy-memory tail temp unit
			if hash? [
				_hashtable/delete table as red-value! head
				_hashtable/delete table as red-value! tail
				_hashtable/put table as red-value! head
				_hashtable/put table as red-value! tail
			]
			head: head + unit
			tail: tail - unit
		]
		stack/pop 1
		ownership/check as red-value! ser words/_reverse null ser/head items
		ser
	]

	take: func [
		ser	    	[red-series!]
		part-arg	[red-value!]
		deep?		[logic!]
		last?		[logic!]
		return:		[red-value!]
		/local
			int		[red-integer!]
			ser2	[red-series!]
			offset	[byte-ptr!]
			tail	[byte-ptr!]
			s		[series!]
			buffer	[series!]
			node	[node!]
			unit	[integer!]
			part	[integer!]
			bytes	[integer!]
			size	[integer!]
			hash	[red-hash!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/take"]]

		size: get-length ser no
		if size <= 0 [									;-- early exit if nothing to take
			set-type as cell! ser TYPE_NONE
			return as red-value! ser
		]
		s:    GET_BUFFER(ser)
		unit: GET_UNIT(s)
		part: 1

		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
			][
				ser2: as red-series! part-arg
				unless all [
					TYPE_OF(ser2) = TYPE_OF(ser)		;-- handles ANY-STRING!
					ser2/node = ser/node
				][
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
				]
				either ser2/head < ser/head [0][
					either last? [size - (ser2/head - ser/head)][ser2/head - ser/head]
				]
			]
			if part > size [part: size]
		]

		bytes:	part << (log-b unit)
		node: 	alloc-bytes bytes
		buffer: as series! node/value
		buffer/flags: s/flags							;@@ filter flags?

		ser2: as red-series! stack/push*
		ser2/header: TYPE_OF(ser)
		ser2/extra:  either TYPE_OF(ser) = TYPE_VECTOR [ser/extra][0]
		ser2/node:  node
		ser2/head:  0
		
		ownership/check as red-value! ser words/_take null ser/head part

		either positive? part [
			tail: as byte-ptr! s/tail
			offset: (as byte-ptr! s/offset) + (ser/head << (log-b unit))
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
			if TYPE_OF(ser) = TYPE_HASH [
				size: either last? [size - 1][ser/head + part]
				hash: as red-hash! ser
				_hashtable/refresh hash/table 0 - part size
				hash: as red-hash! ser2
				hash/table: _hashtable/init part ser2 HASH_TABLE_HASH 1
			]
		][return as red-value! ser2]
		
		ownership/check as red-value! ser words/_taken null ser/head 0
		as red-value! ser2
	]

	swap: func [
		ser1	 [red-series!]
		ser2	 [red-series!]
		return:	 [red-series!]
		/local
			s1		[series!]
			s2		[series!]
			char1	[integer!]
			char2	[integer!]
			unit1	[integer!]
			unit2	[integer!]
			head1	[byte-ptr!]
			head2	[byte-ptr!]
	][
		s1:    GET_BUFFER(ser1)
		unit1: GET_UNIT(s1)
		head1: (as byte-ptr! s1/offset) + (ser1/head << (log-b unit1))
		if head1 = as byte-ptr! s1/tail [return ser1]				;-- early exit if nothing to swap

		s2:    GET_BUFFER(ser2)
		unit2: GET_UNIT(s2)
		head2: (as byte-ptr! s2/offset) + (ser2/head << (log-b unit2))
		if head2 = as byte-ptr! s2/tail [return ser1]				;-- early exit if nothing to swap

		char1: string/get-char head1 unit1
		char2: string/get-char head2 unit2
		string/poke-char s1 head1 char2
		string/poke-char s2 head2 char1
		;ownership/check as red-value! ser1 words/_remove null offset part
		;ownership/check as red-value! ser2 words/_remove null offset part
		ser1
	]

	;--- Misc actions ---

	copy: func [
		ser	    	[red-series!]
		new			[red-series!]
		part-arg	[red-value!]
		deep?		[logic!]
		types		[red-value!]
		return:		[red-series!]
		/local
			int		[red-integer!]
			ser2	[red-series!]
			offset	[integer!]
			s		[series!]
			buffer	[series!]
			node	[node!]
			unit	[integer!]
			part	[integer!]
			type	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/copy"]]

		type: TYPE_OF(ser)
		s: GET_BUFFER(ser)
		unit: GET_UNIT(s)

		offset: ser/head
		part: (as-integer s/tail - s/offset) >> (log-b unit) - offset

		if OPTION?(types) [--NOT_IMPLEMENTED--]

		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				either int/value > part [part][int/value]
			][
				ser2: as red-series! part-arg
				unless all [
					TYPE_OF(ser2) = type				;-- handles ANY-STRING!
					ser2/node = ser/node
				][
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
				]
				ser2/head - ser/head
			]
		]
		if negative? part [
			part: 0 - part
			offset: offset - part
			if negative? offset [offset: 0 part: ser/head]
		]
		part:	part << (log-b unit)
		node:	alloc-bytes part
		buffer: as series! node/value
		buffer/flags: s/flags							;@@ filter flags?

		unless zero? part [
			offset: offset << (log-b unit)
			copy-memory
				as byte-ptr! buffer/offset
				(as byte-ptr! s/offset) + offset
				part

			buffer/tail: as cell! (as byte-ptr! buffer/offset) + part
		]

		new/header: type
		new/node:   node
		new/head:   0
		new/extra:  either type = TYPE_VECTOR [ser/extra][0]

		as red-series! new
	]
	
	modify: func [
		ser	    [red-series!]
		field	[red-word!]
		value	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			args [red-value!]
			sym	 [integer!]
	][
		sym: symbol/resolve field/symbol
		case [
			sym = words/owned [
				if TYPE_OF(value) = TYPE_NONE [
					ownership/unbind as red-value! ser
				]
				if TYPE_OF(value) = TYPE_BLOCK [
					args: block/rs-head as red-block! value
					assert TYPE_OF(args) = TYPE_OBJECT	;@@ raise error on invalid block
					ownership/set-owner 
						as red-value! ser
						as red-object! args
						as red-word! args + 1
				]
			]
			true [0]
		]
		value
	]

	init: does [
		datatype/register [
			TYPE_SERIES
			TYPE_VALUE
			"series!"
			;-- General actions --
			null			;make
			:random
			:reflect
			null			;to
			null			;form
			null			;mold
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
			:clear
			:copy
			null			;find
			:head
			:head?
			:index?
			null			;insert
			:length?
			:next
			:pick
			:poke
			null			;put
			:remove
			:reverse
			null			;select
			null			;sort
			:skip
			null			;swap
			:tail
			:tail?
			:take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			:modify
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