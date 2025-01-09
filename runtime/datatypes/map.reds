Red/System [
	Title:   "Map! datatype runtime functions"
	Author:  "Qingtian Xie"
	File:	 %map.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

map: context [
	verbose: 0

	rs-length?: func [
		map 	[red-hash!]
		return: [integer!]
		/local
			s	 [series!]
			size [int-ptr!]
	][
		s: as series! map/table/value
		size: as int-ptr! s/offset
		size/value
	]
	
	valid-key?: func [type [integer!] return: [logic!]][
		switch type [
			TYPE_ALL_WORD
			TYPE_BINARY
			TYPE_ANY_STRING
			TYPE_MONEY
			TYPE_INTEGER TYPE_CHAR TYPE_FLOAT TYPE_DATE
			TYPE_PERCENT TYPE_TUPLE TYPE_PAIR TYPE_TIME
			TYPE_ANY_POINT								[yes]
			default										[no]
		]		
	]

	preprocess-key: func [
		key	 [red-value!]
		path [red-value!]
	][
		switch TYPE_OF(key) [
			TYPE_ANY_WORD [key/header: TYPE_SET_WORD]		;-- convert any-word! to set-word!
			TYPE_BINARY
			TYPE_ANY_STRING [_series/copy as red-series! key as red-series! key null yes null]
			TYPE_MONEY
			TYPE_INTEGER TYPE_CHAR TYPE_FLOAT TYPE_DATE TYPE_PERCENT
			TYPE_TUPLE TYPE_PAIR TYPE_TIME TYPE_ISSUE TYPE_REFINEMENT
			TYPE_ANY_POINT [0]
			default	[fire [TO_ERROR(script invalid-path) path datatype/push TYPE_OF(key)]]
		]
	]

	serialize: func [
		map		[red-hash!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent?	[logic!]
		tabs	[integer!]
		mold?	[logic!]
		return: [integer!]
		/local
			s		[series!]
			value	[red-value!]
			next	[red-value!]
			s-tail	[red-value!]
			blank	[byte!]
	][
		if positive? rs-length? map [
			either flat? [
				indent?: no
				blank: space
			][
				if mold? [
					either only? [indent?: no][
						string/append-char GET_BUFFER(buffer) as-integer lf
						part: part - 1
					]
				]
				blank: lf
			]

			s: GET_BUFFER(map)
			value: s/offset
			s-tail: s/tail
			cycles/push map/node
			
			while [value < s-tail][
				next: value + 1
				unless next/header = MAP_KEY_DELETED [
					if indent? [part: object/do-indent buffer tabs part]

					part: actions/mold value buffer only? all? flat? arg part tabs
					string/append-char GET_BUFFER(buffer) as-integer space
					part: part - 1
					
					part: actions/mold next buffer only? all? flat? arg part tabs

					if any [indent? next + 1 < s-tail][			;-- no final LF when FORMed
						string/append-char GET_BUFFER(buffer) as-integer blank
						part: part - 1
					]
				]
				if all [OPTION?(arg) part <= 0][
					cycles/pop
					return part
				]
				value: value + 2
			]
			cycles/pop
		]
		part
	]
	
	extend: func [
		map		[red-hash!]
		spec	[red-block!]
		case?	[logic!]
		return: [red-value!]
		/local
			src		[red-block!]
			cell	[red-value!]
			tail	[red-value!]
			value	[red-value!]
			op		[integer!]
			s		[series!]
			size	[integer!]
			table	[node!]
			key		[red-value!]
			val		[red-value!]
			psize	[int-ptr!]
			kkey	[red-value! value]
	][
		#if debug? = yes [if verbose > 0 [print-line "map/extend"]]

		src: as red-block! spec
		size: block/rs-length? src
		if size % 2 <> 0 [fire [TO_ERROR(script invalid-arg) spec]]
		
		s: GET_BUFFER(map)
		size: as-integer s/tail + size - s/offset
		if size > s/size [expand-series s size]

		s: GET_BUFFER(src)
		cell: s/offset + src/head
		tail: s/tail

		op: either case? [COMP_STRICT_EQUAL][COMP_EQUAL]
		table: map/table
		while [cell < tail][
			key: _hashtable/get table cell 0 0 op no no
			value: cell + 1
			either key = null [
				copy-cell cell kkey
				preprocess-key kkey null
				s: as series! map/node/value
				key: copy-cell kkey as cell! alloc-tail-unit s (size? cell!) << 1
				val: key + 1
				val/header: TYPE_UNSET
				_hashtable/put table key
			][
				val: key + 1
				if val/header = MAP_KEY_DELETED [	;-- increase size of keys
					s: as series! table/value
					psize: as int-ptr! s/offset
					psize/value: psize/value + 1
				]
			]
			copy-cell value key + 1
			cell: cell + 2
		]
		as red-value! map
	]
	
	push: func [
		map [red-hash!]
	][
		#if debug? = yes [if verbose > 0 [print-line "map/push"]]

		copy-cell as red-value! map stack/push*
	]
	
	make-at: func [
		slot	[red-value!]
		blk		[red-block!]
		size	[integer!]
		return:	[red-hash!]
		/local
			table [node!]
			map	  [red-hash!]
	][
		if blk = null [blk: block/make-at as red-block! slot size]
		table: _hashtable/init size blk HASH_TABLE_MAP 1
		map: as red-hash! slot
		set-type slot TYPE_MAP
		map/table: table
		map
	]

	;--- Actions ---

	make: func [
		proto	[red-hash!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-hash!]
		/local
			size	[integer!]
			int		[red-integer!]
			fl		[red-float!]
			blk		[red-block!]
			blk?	[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "map/make"]]

		blk?: no
		switch TYPE_OF(spec) [
			TYPE_INTEGER
			TYPE_FLOAT [
				if type = -1 [					;-- called by TO
					fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_MAP spec]
				]
				size: get-int-from spec
				if negative? size [fire [TO_ERROR(script out-of-range) spec]]
				size: size * 2
			]
			TYPE_ANY_LIST [
				size: block/rs-length? as red-block! spec
				if size % 2 <> 0 [fire [TO_ERROR(script invalid-arg) spec]]
				blk?: yes
			]
			TYPE_MAP [return copy as red-hash! spec proto null no null]
			default [fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_MAP spec]]
		]

		if zero? size [size: 2]
		either blk? [
			; use clone here to prevent extra copying of spec
			blk: block/clone as red-block! spec no no
			object/clear-nl-flags GET_BUFFER(blk)
		][
			blk: block/make-at as red-block! stack/push* size
		]
		make-at as red-value! blk blk size
	]

	to: func [
		proto		[red-hash!]
		spec		[red-value!]
		type		[integer!]
		return:		[red-hash!]
	][
		make proto spec -1
	]

	reflect: func [
		map		[red-hash!]
		field	[integer!]
		return:	[red-block!]
		/local
			blk		[red-block!]
			s-tail	[red-value!]
			value	[red-value!]
			next	[red-value!]
			new		[red-value!]
			size	[integer!]
			total	[integer!]
			cnt		[integer!]
			s		[series!]
	][
		blk: 		as red-block! stack/push*
		blk/header: TYPE_UNSET
		blk/head: 	0

		total: rs-length? map
		size: total
		s: GET_BUFFER(map)
		value: s/offset
		s-tail: s/tail
		if zero? size [size: 1]
		cnt: 0
		case [
			field = words/words [
				blk/node: alloc-cells size
				while [all [value < s-tail cnt < total]][
					next: value + 1
					unless next/header = MAP_KEY_DELETED [
						cnt: cnt + 1
						new: block/rs-append blk value
						if TYPE_OF(value) = TYPE_SET_WORD [
							new/header: TYPE_WORD
						]
					]
					value: value + 2
				]
			]
			field = words/values [
				blk/node: alloc-cells size
				while [all [value < s-tail cnt < total]][
					next: value + 1
					unless next/header = MAP_KEY_DELETED [
						cnt: cnt + 1
						block/rs-append blk next
					]
					value: value + 2
				]
			]
			field = words/body [
				blk/node: alloc-cells size * 2
				while [all [value < s-tail cnt < total]][
					next: value + 1
					unless next/header = MAP_KEY_DELETED [
						cnt: cnt + 1
						new: block/rs-append blk value
						new/header: new/header or flag-new-line
						block/rs-append blk next
					]
					value: value + 2
				]
			]
			true [
				--NOT_IMPLEMENTED--						;@@ raise error
			]
		]
		blk/header: TYPE_BLOCK
		as red-block! stack/set-last as red-value! blk
	]

	form: func [
		map		  [red-hash!]
		buffer	  [red-string!]
		arg		  [red-value!]
		part 	  [integer!]
		return:   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "map/form"]]

		if cycles/detect? as red-value! map buffer :part no [return part]
		serialize map buffer no no no arg part no 0 no
	]

	mold: func [
		map		[red-hash!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return:	[integer!]
		/local
			prev [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "map/mold"]]

		if cycles/detect? as red-value! map buffer :part yes [return part]
		
		unless only? [
			string/concatenate-literal buffer "#["
			prev: part - 2
		]
		part: serialize map buffer only? all? flat? arg prev yes indent + 1 yes
		
		either only? [part][
			if all [part <> prev indent > 0][part: object/do-indent buffer indent part]
			string/append-char GET_BUFFER(buffer) as-integer #"]"
			part - 1
		]
	]

	compare-each: func [
		blk1	   [red-hash!]							;-- first operand
		blk2	   [red-hash!]							;-- second operand
		op		   [integer!]							;-- type of comparison
		return:	   [integer!]
		/local
			size1  [integer!]
			size2  [integer!]
			key1   [red-value!]
			key2   [red-value!]
			value1 [red-value!]
			value2 [red-value!]
			res	   [integer!]
			n	   [integer!]
			start  [integer!]
			pace   [integer!]
			end    [integer!]
			same?  [logic!]
			case?  [logic!]
			table2 [node!]
	][
		same?: all [
			blk1/node = blk2/node
			blk1/head = blk2/head
		]
		if op = COMP_SAME [return either same? [0][-1]]
		if same? [return 0]
		if cycles/find? blk1/node [
			return either cycles/find? blk2/node [0][-1]
		]

		size1: rs-length? blk1
		size2: rs-length? blk2

		if size1 <> size2 [										;-- shortcut exit for different sizes
			return either any [
				op = COMP_EQUAL op = COMP_FIND op = COMP_STRICT_EQUAL op = COMP_NOT_EQUAL
			][1][SIGN_COMPARE_RESULT(size1 size2)]
		]

		if zero? size1 [return 0]								;-- shortcut exit for empty map!

		table2: blk2/table
		key1: block/rs-head as red-block! blk1
		key1: key1 - 2
		n: 0

		cycles/push blk1/node
		cycles/push blk2/node
		either op = COMP_STRICT_EQUAL [
			until [
				until [												;-- next key
					key1: key1 + 2
					value1: key1 + 1
					value1/header <> MAP_KEY_DELETED
				]
				key2: _hashtable/get table2 key1 0 0 COMP_STRICT_EQUAL no no

				res: either key2 = null [1][
					value1: key1 + 1								;-- find the same key, then compare values
					value2: key2 + 1
					actions/compare-value value1 value2 op
				]
				n: n + 1
				any [res <> 0 n = size1]
			]
		][
			end: 0
			until [
				until [												;-- next key
					key1: key1 + 2
					value1: key1 + 1
					value1/header <> MAP_KEY_DELETED
				]
				start: -1
				pace: 0
				until [
					key2: _hashtable/get-next table2 key1 :start :end :pace
					either key2 <> null [
						value1: key1 + 1
						value2: key2 + 1
						res: actions/compare-value value1 value2 COMP_EQUAL
					][res: 1 break]
					zero? res
				]
				n: n + 1
				any [res <> 0 n = size1]
			]
		]
		cycles/pop-n 2
		res
	]

	compare: func [
		map1	   [red-hash!]							;-- first operand
		map2	   [red-hash!]							;-- second operand
		op		   [integer!]							;-- type of comparison
		return:	   [integer!]
		/local type res
	][
		#if debug? = yes [if verbose > 0 [print-line "map/compare"]]

		type: TYPE_OF(map2)
		if type <> TYPE_MAP [RETURN_COMPARE_OTHER]
		switch op [
			COMP_EQUAL
			COMP_FIND
			COMP_SAME
			COMP_STRICT_EQUAL
			COMP_NOT_EQUAL [
				res: compare-each map1 map2 op
			]
			COMP_SORT
			COMP_CASE_SORT [
				res: as-integer map1/node - map2/node
			]
			default [
				res: -2
			]
		]
		res
	]

	eval-path: func [
		parent	[red-hash!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		gparent [red-value!]
		p-item	[red-value!]
		index	[integer!]
		case?	[logic!]
		get?	[logic!]
		tail?	[logic!]
		evt?	[logic!]
		return:	[red-value!]
		/local
			table	[node!]
			key		[red-value!]
			val		[red-value!]
			op		[integer!]
			s		[series!]
			size	[int-ptr!]
			k		[red-value! value]
	][
		op: either case? [COMP_STRICT_EQUAL][COMP_EQUAL]
		table: parent/table
		key: _hashtable/get table element 0 0 op no no

		either value <> null [						;-- set value
			either key = null [
				copy-cell element k
				preprocess-key k path
				s: as series! parent/node/value
				key: copy-cell k as cell! alloc-tail-unit s (size? cell!) << 1
				val: key + 1
				val/header: TYPE_UNSET
				_hashtable/put table key
			][
				val: key + 1
				if val/header = MAP_KEY_DELETED [	;-- increase size of keys
					s: as series! table/value
					size: as int-ptr! s/offset
					size/value: size/value + 1
				]
			]
			copy-cell value key + 1
		][
			val: key + 1
			if any [key = null val/header = MAP_KEY_DELETED][
				val: none-value
			]
			val
		]
	]

	;--- Reading actions ---

	;pick: func [
	;	map		[red-hash!]
	;	index	[red-value!]
	;	boxed	[red-value!]
	;	return:	[red-value!]
	;][
	;	#if debug? = yes [if verbose > 0 [print-line "map/pick"]]
	;
	;	eval-path map boxed null as red-value! none-value no
	;]

	;--- Modifying actions ---
	
	put: func [
		map		[red-hash!]
		field	[red-value!]
		value	[red-value!]
		case?	[logic!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "map/put"]]
		
		eval-path map field value as red-value! none-value null null -1 case? no yes no
		value
	]

	clear: func [
		map		[red-hash!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "map/clear"]]

		_hashtable/clear-map map/table
		as red-value! map
	]

	;poke: func [
	;	map		[red-hash!]
	;	index	[red-value!]
	;	data	[red-value!]
	;	boxed	[red-value!]
	;	return:	[red-value!]
	;][
	;	#if debug? = yes [if verbose > 0 [print-line "map/poke"]]
	;
	;	eval-path map boxed data as red-value! none-value no
	;]

	;--- Property reading actions ---

	length?: func [
		map		[red-hash!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "map/length?"]]

		rs-length? map
	]
	
	find: func [
		map			[red-hash!]
		value		[red-value!]
		part		[red-value!]
		only?		[logic!]
		case?		[logic!]
		same?		[logic!]
		any?		[logic!]
		with-arg	[red-string!]
		skip		[red-integer!]
		last?		[logic!]
		reverse?	[logic!]
		tail?		[logic!]
		match?		[logic!]
		return:		[red-value!]
		/local
			table [node!]
			key   [red-value!]
			val   [red-value!]
			op	  [integer!]
	][
		either same? [op: COMP_SAME][
			op: either case? [COMP_STRICT_EQUAL][COMP_EQUAL]
		]
		table: map/table
		key: _hashtable/get table value 0 0 op no no
		val: key + 1
		either any [
			key = null
			val/header = MAP_KEY_DELETED
		][none-value][
			if TYPE_OF(key) = TYPE_SET_WORD [
				copy-cell key as red-value! map
				key: as red-value! map
				key/header: TYPE_WORD
			]
			key
		]
	]

	;--- Navigation actions ---

	select: func [
		map		 [red-hash!]
		value	 [red-value!]
		part	 [red-value!]
		only?	 [logic!]
		case?	 [logic!]
		same?	 [logic!]
		any?	 [logic!]
		with-arg [red-string!]
		skip	 [red-integer!]
		last?	 [logic!]
		reverse? [logic!]
		return:	 [red-value!]
		/local
			table [node!]
			key   [red-value!]
			val   [red-value!]
			op	  [integer!]
	][
		either same? [op: COMP_SAME][
			op: either case? [COMP_STRICT_EQUAL][COMP_EQUAL]
		]
		table: map/table
		key: _hashtable/get table value 0 0 op no no
		val: key + 1
		either any [key = null val/header = MAP_KEY_DELETED][none-value][val]
	]

	remove: func [
		map	 	 [red-hash!]
		part-arg [red-value!]							;-- null if no /part
		key		 [red-value!]
		return:	 [red-hash!]
		/local
			k	 [red-value!]
			val	 [red-value!]
	][
		unless OPTION?(key) [
			fire [TO_ERROR(script missing-arg)]
		]
		k: _hashtable/get map/table key 0 0 COMP_STRICT_EQUAL no no
		val: k + 1
		if all [k <> null val/header <> MAP_KEY_DELETED][
			_hashtable/delete map/table k
		]
		map
	]

	;--- Misc actions ---

	set-many: func [
		blk		[red-block!]
		map		[red-hash!]
		size	[integer!]
		return: [logic!]
		/local
			w		[red-word!]
			k		[red-value!]
			v		[red-value!]
			tail	[red-value!]
			i		[integer!]
			type	[integer!]
	][
		i: 0
		k: block/rs-head as red-block! map
		tail: block/rs-tail as red-block! map
		w: as red-word! block/rs-head blk
		while [all [i < size k < tail]][
			type: TYPE_OF(w)
			unless ANY_WORD?(type) [fire [TO_ERROR(script invalid-arg) w]]
			v: k + 1
			either all [i % 2 = 0 v/header = MAP_KEY_DELETED][
				k: k + 2
				map/head: map/head + 2
			][
				v: _context/set w k
				if TYPE_OF(v) = TYPE_SET_WORD [v/header: TYPE_WORD]
				w: w + 1
				k: k + 1
				i: i + 1
			]
		]
		loop size - i [
			_context/set w none-value
			w: w + 1
		]
		i <> 0			;-- return false if map is empty
	]

	copy: func [
		map	    	[red-hash!]
		new			[red-hash!]
		part-arg	[red-value!]
		deep?		[logic!]
		types		[red-value!]
		return:		[red-hash!]
	][
		#if debug? = yes [if verbose > 0 [print-line "map/copy"]]

		new: as red-hash! block/clone as red-block! map deep? yes
		new/table:  map/table	;-- set it to old table, _hashtable/copy below may trigger GC
		new/table:  _hashtable/copy map/table new/node
		new/header: TYPE_MAP
		new
	]

	init: does [
		datatype/register [
			TYPE_MAP
			TYPE_VALUE
			"map!"
			;-- General actions --
			:make
			null			;random
			:reflect
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
			:clear
			:copy
			:find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			:length?
			null			;move
			null			;next
			null			;pick
			null			;poke
			:put
			:remove
			null			;reverse
			:select
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