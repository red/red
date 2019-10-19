Red/System [
	Title:   "Series! datatype runtime functions"
	Author:  "Nenad Rakocevic, Qingtian Xie"
	File: 	 %series.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2015-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

_series: context [
	verbose: 0
	
	rs-tail?: func [
		ser		[red-series!]
		return: [logic!]
		/local
			s	   [series!]
			offset [integer!]
	][
		s: GET_BUFFER(ser)
		offset: ser/head << (log-b GET_UNIT(s))
		(as byte-ptr! s/offset) + offset >= as byte-ptr! s/tail
	]

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

	trim-head: func [									;-- cuts the head if it's after the tail
		ser 	[red-series!]
		return:	[series!]
		/local
			s	[series!]
			sz	[integer!]
	][
		s: GET_BUFFER(ser)
		sz: (as-integer s/tail - s/offset) >> log-b GET_UNIT(s)
		if ser/head > sz [ser/head: sz]
		s
	]

	trim-head-into: func [								;-- cuts the head if it's after the tail, puts result into `new`
		ser 	[red-series!]
		new 	[red-series!]
		return:	[series!]
	][
		copy-cell as cell! ser as cell! new
		trim-head new
	]

	get-position: func [
		base	   [integer!]
		return:	   [integer!]
		/local
			ser	   [red-series!]
			index  [red-integer!]
			s	   [series!]
			offset [integer!]
			width  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/get-position"]]

		ser: as red-series! stack/arguments
		index: as red-integer! ser + 1

		assert TYPE_OF(index) = TYPE_INTEGER

		s: GET_BUFFER(ser)

		if all [base = 1 index/value <= 0][base: base - 1]
		offset: ser/head + index/value - base			;-- index is one-based
		if negative? offset [offset: 0]
		width: (as-integer s/tail - s/offset) >> (log-b GET_UNIT(s))
		if offset > width [offset: width]
		offset
	]

	get-length: func [
		ser		   [red-series!]
		absolute?  [logic!]
		return:	   [integer!]
		/local
			s	   [series!]
			offset [integer!]
			width  [integer!]
	][
		s: GET_BUFFER(ser)
		offset: either absolute? [0][ser/head]
		if negative? offset [offset: 0]					;-- @@ beware of symbol/index leaking here...
		width: (as-integer s/tail - s/offset) >> (log-b GET_UNIT(s))
		either offset > width [ser/head: width 0][width - offset] ;-- past-end index adjustment
	]

	;-- Actions --

	random: func [
		ser		[red-series!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			int	 [red-integer!]
			char [red-char!]
			vec  [red-vector!]
			s	 [series!]
			size [integer!]
			unit [integer!]
			len	 [integer!]
			val  [red-value! value]
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
						TYPE_BINARY [
							int: as red-integer! ser
							int/header: TYPE_INTEGER
							int/value: string/get-char idx unit
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
				temp: as byte-ptr! :val
				while [size > 0][
					idx: head + (_random/rand % size << (log-b unit))
					if idx <> head [
						copy-memory temp head unit
						copy-memory head idx unit
						copy-memory idx temp unit
					]
					head: head + unit
					size: size - 1
				]
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
		state/value:  (as byte-ptr! s/offset) + (ser/head << (log-b GET_UNIT(s))) >= as byte-ptr! s/tail
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
	
	move: func [
		origin   [red-series!]
		target   [red-series!]
		part-arg [red-value!]
		return:	 [red-value!]
		/local
			s	  [series!]
			s2	  [series!]
			part  [integer!]
			limit [integer!]
			items [integer!]
			unit  [integer!]
			unit2 [integer!]
			size  [integer!]
			index [integer!]
			type1 [integer!]
			type2 [integer!]
			src   [byte-ptr!]
			tail  [byte-ptr!]
			dst   [byte-ptr!]
			end	  [byte-ptr!]
			temp  [byte-ptr!]
			int	  [red-integer!]
			hash  [red-hash!]
			cell  [red-value!]
			origin' [red-series! value]
			target' [red-series! value]
	][
		s:    trim-head-into origin origin'
		unit: GET_UNIT(s)
		src: (as byte-ptr! s/offset) + (origin'/head << (log-b unit))
		tail: as byte-ptr! s/tail
		if src = tail [return as red-value! target]

		part: unit
		items: 1

		if OPTION?(part-arg) [
			int: as red-integer! part-arg
			part: int/value
			if part <= 0 [return as red-value! target]	;-- early exit if negative /part index
			limit: (as-integer tail - src) >> log-b unit
			if part > limit [part: limit]
			items: part
			part: part << (log-b unit)
		]
		
		type1: TYPE_OF(origin')
		either origin'/node = target/node [				;-- same series case
			trim-head-into target target'
			dst: (as byte-ptr! s/offset) + (target'/head << (log-b unit))
			if src = dst [return as red-value! target]	;-- early exit if no move is required
			if all [dst > src dst <> tail part > (as-integer tail - dst)][
				return as red-value! origin
			]
			if dst > tail [dst: tail]					;-- avoid overflows if part is too big
			ownership/check as red-value! target' words/_move null origin'/head items

			temp: allocate part							;@@ suboptimal for unit < 16
			copy-memory	temp src part
			either dst > src [							;-- slide in-between elements
				end: src + part
				size: as-integer dst - end
				either dst = tail [
					move-memory src end size
				][
					move-memory src end size + unit		;-- extend size to include target slot
					dst: dst + unit						;-- ensure insertion is done past the provided index
				]
				dst: dst - part							;-- adjust dst after moving items
			][
				move-memory dst + part dst as-integer src - dst 
			]
			copy-memory dst temp part
			free temp

			if type1 = TYPE_HASH [
				hash: as red-hash! origin'
				_hashtable/move hash/table target'/head origin'/head items
			]

			index: target'/head - items
		][												;-- different series case
			type2: TYPE_OF(target)
			if any [
				all [ANY_BLOCK?(type1)  ANY_STRING?(type2)]
				all [ANY_STRING?(type1)	ANY_BLOCK?(type2)]
			][
				fire [TO_ERROR(script move-bad) datatype/push type1 datatype/push type2]
			]
			ownership/check as red-value! target words/_move null origin'/head items
			
			s2: trim-head-into target target'
			unit2: GET_UNIT(s2)
			if unit <> unit2 [
				if any [
					type1 = TYPE_BINARY
					type1 = TYPE_VECTOR
					type2 = TYPE_BINARY
					type2 = TYPE_VECTOR
				][
					fire [TO_ERROR(script move-bad) datatype/push type1 datatype/push type2]
				]
				string/move-chars as red-string! origin' as red-string! target' part
				return as red-value! target
			]
			;-- make enough space in target
			size: as-integer (as byte-ptr! s2/tail) + part - as byte-ptr! s2/offset
			if size > s2/size [s2: expand-series s2 size * 2]
			dst: (as byte-ptr! s2/offset) + (target'/head << (log-b unit))
			
			;-- slide target series to right from insertion position
			move-memory dst + part dst as-integer (as byte-ptr! s2/tail) - dst
			s2/tail: as cell! (as byte-ptr! s2/tail) + part
			
			;-- copy elements from source to target
			copy-memory dst src part
			
			;-- collapse source series over copied elements
			move-memory src src + part as-integer tail - (src + part)
			s/tail: as cell! tail - part

			if type1 = TYPE_HASH [
				hash: as red-hash! origin'
				part: (as-integer s/tail - s/offset) >> 4 - hash/head
				_hashtable/refresh hash/table 0 - items hash/head + items part yes
			]
			if type2 = TYPE_HASH [
				hash: as red-hash! target'
				part: (as-integer s2/tail - dst) >> 4 - items - hash/head
				_hashtable/refresh hash/table items hash/head part yes
				cell: as red-value! dst
				loop items [
					_hashtable/put hash/table cell
					cell: cell + 1
				]
			]
			index: target'/head
		]
		ownership/check as red-value! target' words/_moved null index items
		target/node: target'/node
		; origin/node: origin'/node
		as red-value! origin
	]
	
	change: func [
		ser		 [red-series!]
		value	 [red-value!]
		part-arg [red-value!]
		only?	 [logic!]
		dup-arg  [red-value!]
		return:	 [red-series!]
		/local
			s			[series!]
			s2			[series!]
			part		[integer!]
			items		[integer!]
			unit		[integer!]
			unit2		[integer!]
			bytes1		[integer!]
			bytes2		[integer!]
			shift		[integer!]
			trail		[integer!]
			shift-bytes	[integer!]
			trail-bytes	[integer!]
			size		[integer!]
			new-size	[integer!]
			new-part	[integer!]
			n			[integer!]
			left		[integer!]
			type		[integer!]
			head		[integer!]
			src			[byte-ptr!]
			dst			[byte-ptr!]
			cell		[red-value!]
			limit		[red-value!]
			int			[red-integer!]
			ser2		[red-series!]
			ser2'		[red-series! value]					;-- temp alias with head <= tail
			hash		[red-hash!]
			table		[node!]
			values? 	[logic!]
			neg?		[logic!]
			part?		[logic!]
			blk?		[logic!]
			self?		[logic!]
			divided?	[logic!]
			cnt			[integer!]
	][
		cnt: 1
		if OPTION?(dup-arg) [
			int: as red-integer! dup-arg
			cnt: int/value
			if cnt < 0 [cnt: 0]
		]
		part?: OPTION?(part-arg)
		if all [not part? zero? cnt] [return ser]

		self?: no
		s: trim-head ser
		unit: log-b GET_UNIT(s)
		head: ser/head
		size: (as-integer s/tail - s/offset) >> unit

		type: TYPE_OF(ser)
		blk?: ANY_BLOCK?(type)

		ser2: as red-series! value
		values?: either all [only? blk?][no][
			left: TYPE_OF(value)
			self?: ser/node = ser2/node					;-- ser and value are the same series
			ANY_BLOCK?(left)
		]

		items: either any [self? values?][
			s2: trim-head-into ser2 ser2'
			unit2: log-b GET_UNIT(s2)
			cell: as cell! (as byte-ptr! s2/offset) + (ser2'/head << unit2)
			get-length ser2' no
		][
			cell: value
			1
		]
		limit: cell + items

		part: items * cnt
		if part? [
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
				trim-head-into ser2 ser2'
				ser2'/head - head
			]
			if negative? part [
				part: 0 - part
				either part > head [part: head head: 0][head: head - part]
				ser/head: head
				neg?: yes
			]
		]
		left: size - head
		if part > left [part: left]

		if all [
			zero? part
			limit = cell
		][return ser]									;-- early exit if nothing to change

		either any [blk? self?][
			new-part: items * cnt
			new-size: size - part + new-part
			n: new-size << unit
			ownership/check as red-value! ser words/_change null head part
			if n > s/size [s: expand-series s n << 1]
			dst: (as byte-ptr! s/offset) + (head << unit)
			src: as byte-ptr! cell
			bytes1: part << unit
			bytes2: items << unit
			if zero? cnt [bytes2: 0]
			trail: left - part
			shift: items * cnt - part
			trail-bytes: trail << unit
			shift-bytes: shift << unit
			either shift <= 0 [
				if bytes2 > 0 [move-memory dst src bytes2]						;-- items -> part (possible overlap)
				if trail > 0 [
					move-memory dst + (bytes2 * cnt) dst + bytes1 trail-bytes	;-- contract the trail (possible overlap)
				]
			][
				divided?: no
				if trail > 0 [													;-- at least 1 item remains after the part; move it to the right
					move-memory dst + (bytes2 * cnt) dst + bytes1 trail-bytes	;-- move the trail (possible overlap)
					divided?: all [												;-- src becomes divided into 2 segments by the expansion
						self?
						trail > shift											;-- if there's an intersection between the *new trail* and *items*
					]
				]
				assert bytes2 > 0
				either divided? [
					move-memory dst src bytes1											;-- fill the part (possible overlap)
					move-memory dst + bytes1 src + bytes1 + shift-bytes shift-bytes		;-- fill the gap after part (possible overlap)
				][
					move-memory dst src bytes2											;-- move the `items` (possible overlap)
				]
			]
			s/tail: as cell! (as byte-ptr! s/offset) + (new-size << unit)
			;@@ FIXME: THAT DOESN'T WORK:
			; if type = TYPE_HASH [
			; 	hash: as red-hash! ser
			; 	table: hash/table
			; 	if part > 0 [_hashtable/clear table head part]							;-- forget the old part
			; 	if trail > 0 [_hashtable/refresh table shift head + part trail yes]		;-- shift the trail
			; 	if size > new-size [_hashtable/clear table new-size size - new-size]	;-- forget the now past tail items
			; ]
		][
			if part? [
				dst: (as byte-ptr! s/offset) + (head << unit)
				bytes1: part << unit
				trail-bytes: left - part << unit
				;-- don't know the size of the formed items yet; change-range will decide
				;@@ FIXME: this is sub-optimal for long trails
				if all [trail-bytes > 0 part > 0] [
					move-memory dst dst + bytes1 trail-bytes
					s/tail: as cell! dst + trail-bytes
				]
			]
			if cnt > 0 [
				items: switch type [
					TYPE_BINARY [
						binary/change-range as red-binary! ser cell limit part?
					]
					TYPE_VECTOR [
						vector/change-range as red-vector! ser cell limit part?
					]
					default [								;-- ANY-STRING!
						string/change-range as red-string! ser cell limit part?
					]
				]
			]
			new-part: items * cnt
			if all [cnt > 1 items > 0] [
				s: GET_BUFFER(ser)
				unit: log-b GET_UNIT(s)
				size: (as-integer s/tail - s/offset) >> unit
				either part? [
					new-size: size + new-part - items		;-- shrunk it before ^^
				][
					new-size: head + new-part				;-- the part to be overridden
					if new-size < size [new-size: size]
				]
				n: new-size << unit
				if n > s/size [s: expand-series s n << 1]
				s/tail: as cell! (as byte-ptr! s/offset) + n
			]
		]

		if all [cnt > 1 items > 0] [					;-- /dup
			src: (as byte-ptr! s/offset) + (head << unit)
			bytes2: items << unit
			dst: src + bytes2
			loop cnt - 1 [
				copy-memory dst src bytes2
				dst: dst + bytes2
			]
		]
		; if type = TYPE_HASH [
		; 	hash: as red-hash! ser
		; 	table: hash/table
		; 	cell: as cell! s/offset + head
		; 	loop new-part [_hashtable/put table cell  cell: cell + 1]		;-- insert the items
		; ]

		;@@ FIXME: temporary solution - reinsert everything after the head:
		if type = TYPE_HASH [
			hash: as red-hash! ser
			table: hash/table
			_hashtable/clear table head size - head
			cell: as cell! s/offset + head
			loop new-size - head [_hashtable/put table cell  cell: cell + 1]
		]
		ownership/check as red-value! ser words/_changed null head new-part
		ser/head: head + new-part											;-- set head after the change
		ser
	]

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

		if size <= 0 [return as red-value! ser]    ;-- early exit if nothing to clear

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
		part-arg [red-value!]							;-- null if no /part
		key-arg  [red-value!]
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
		part: unit
		items: 1

		if part-arg <> null [
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

		if OPTION?(key-arg) [
			ser: as red-series! actions/find ser key-arg null no yes no no null null no no no no
			if TYPE_OF(ser) = TYPE_NONE [return ser]
			items: items + 1			;-- remove key + value
			part: part + unit
		]

		head: (as byte-ptr! s/offset) + (ser/head << (log-b unit))
		tail: as byte-ptr! s/tail

		if head >= tail [return ser]						;-- early exit if nothing to remove

		ownership/check as red-value! ser words/_remove null ser/head items
		
		either head + part < tail [
			move-memory
				head
				head + part
				as-integer tail - (head + part)
			s/tail: as red-value! tail - part

			if TYPE_OF(ser) = TYPE_HASH [
				items: as-integer tail - (head + part)
				part: part >> 4
				hash: as red-hash! ser
				_hashtable/refresh hash/table 0 - part ser/head + part items >> 4 yes
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
			val		[red-value! value]
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
			part: ser/head								;-- preserve the head
			items: get-length ser no
			ser/head: part
			part: 0
		]
		
		hash?: TYPE_OF(ser) = TYPE_HASH
		if hash? [
			hash: as red-hash! ser
			table: hash/table
		]
		if all [positive? part head + part < tail] [tail: head + part]
		tail: tail - unit								;-- point to last value
		temp: as byte-ptr! :val
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
			head	[integer!]
			unit	[integer!]
			part	[integer!]
			bytes	[integer!]
			size	[integer!]
			hash	[red-hash!]
			part2	[integer!]
			ser'	[red-series! value]
			part-arg'	[red-value! value]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/take"]]
		s: trim-head-into ser ser'
		head: ser'/head
		size: get-length ser' yes
		unit: GET_UNIT(s)
		part: 1
		part2: 1

		either OPTION?(part-arg) [
			either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				part: int/value
				if last? [								;-- integer /last/part counts from the tail
					if part < 0 [part: 0]
					head: size - part
					if head < 0 [head: 0]
				]
			][
				ser2: as red-series! part-arg'
				trim-head-into as red-series! part-arg as red-series! part-arg'
				unless all [
					TYPE_OF(ser2) = TYPE_OF(ser)		;-- handles ANY-STRING!
					ser2/node = ser/node
				][
					ERR_INVALID_REFINEMENT_ARG(refinements/_part part-arg)
				]
				part: ser2/head - head
				if all [
					last?								;-- series /last/part takes everything after the biggest of ends
					part > 0
				][										;-- set head to the biggest end
					head: head + part
					if head > size [head: size]
				]
			]
			part2: part
			either last? [
				part: size - head
			][
				if part < 0 [
					part: 0 - part
					head: head - part
					if head < 0 [
						part: part + head
						head: 0
					]
				]
				if part > (size - head) [part: size - head]
			]
		][;; either OPTION?(part-arg)
			if head >= size [							;-- early exit if nothing to take (and part = 1)
				set-type as cell! ser TYPE_NONE
				return as red-value! ser
			]
			if last? [head: size - 1]
		]

		bytes:	part << (log-b unit)
		node: 	alloc-bytes bytes
		s:      GET_BUFFER(ser')
		buffer: as series! node/value
		buffer/flags: s/flags							;@@ filter flags?
		tail: as byte-ptr! s/tail

		ser2: as red-series! stack/push*
		ser2/header: TYPE_OF(ser)
		ser2/extra:  either TYPE_OF(ser) = TYPE_VECTOR [ser'/extra][0]
		ser2/node:  node
		ser2/head:  0

		ownership/check as red-value! ser' words/_take null head part2

		offset: (as byte-ptr! s/offset) + (head << (log-b unit))
		copy-memory
			as byte-ptr! buffer/offset
			offset
			bytes
		buffer/tail: as cell! (as byte-ptr! buffer/offset) + bytes

		unless head + part >= size [
			move-memory
				offset
				offset + bytes
				as-integer tail - offset - bytes
		]
		s/tail: as cell! tail - bytes

		ser'/head: head
		if TYPE_OF(ser) = TYPE_HASH [
			hash: as red-hash! ser'
			_hashtable/refresh hash/table 0 - part ser'/head + part size - ser'/head - part yes
			hash: as red-hash! ser2
			hash/header: TYPE_BLOCK		;-- set to TYPE_BLOCK so we don't mark hash/table
			hash/table: _hashtable/init part ser2 HASH_TABLE_HASH 1
			hash/header: TYPE_HASH
		]
		
		ownership/check as red-value! ser' words/_taken null ser'/head 0
		ser/node: ser'/node								;-- could have been relocated

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
		if head1 >= as byte-ptr! s1/tail [return ser1]				;-- early exit if nothing to swap

		s2:    GET_BUFFER(ser2)
		unit2: GET_UNIT(s2)
		head2: (as byte-ptr! s2/offset) + (ser2/head << (log-b unit2))
		if head2 >= as byte-ptr! s2/tail [return ser1]				;-- early exit if nothing to swap

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
			flag	[integer!]
			len		[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "series/copy"]]

		type: TYPE_OF(ser)
		s: GET_BUFFER(ser)
		unit: GET_UNIT(s)
		flag: ser/header and flag-new-line

		offset: ser/head
		len: (as-integer s/tail - s/offset) >> (log-b unit)
		part: len - offset
		if part < 0 [part: 0]

		if OPTION?(types) [--NOT_IMPLEMENTED--]

		if OPTION?(part-arg) [
			part: either TYPE_OF(part-arg) = TYPE_INTEGER [
				int: as red-integer! part-arg
				int/value
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
			if negative? part [
				part: 0 - part
				offset: offset - part
				if negative? offset [offset: 0 part: ser/head]
			]
		]

		if offset > len [part: 0 offset: len]
		if offset + part > len [part: len - offset]

		new/header: TYPE_UNSET
		part:	part << (log-b unit)
		node:	alloc-bytes part
		s: GET_BUFFER(ser)
		buffer: as series! node/value
		buffer/flags: s/flags							;@@ filter flags?
		buffer/flags: buffer/flags and not flag-series-owned

		unless zero? part [
			offset: offset << (log-b unit)
			copy-memory
				as byte-ptr! buffer/offset
				(as byte-ptr! s/offset) + offset
				part

			buffer/tail: as cell! (as byte-ptr! buffer/offset) + part
		]

		new/header: type or flag
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
			:change
			:clear
			:copy
			null			;find
			:head
			:head?
			:index?
			null			;insert
			:length?
			:move
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
