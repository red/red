Red/System [
	Title:   "PARSE dialect interpreter"
	Author:  "Nenad Rakocevic"
	File: 	 %parse.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

parser: context [
	verbose: 0
	
	series: as red-block! 0
	rules:  as red-block! 0
	
	#define PARSE_MAX_DEPTH		10'000
	
	#define PARSE_SAVE_SERIES [							;-- protect series stack from recursive calls
		len: block/rs-length? series
		series/head: series/head + len
	]
	
	#define PARSE_RESTORE_SERIES [
		series/head: series/head - len
	]
	
	#define PARSE_PUSH_INPUTPOS  [
		in: as input! ALLOC_TAIL(rules)
		in/header: TYPE_POINT
		in/node:   input/node
		;in/size:  input/head
	]
	
	#define PARSE_PUSH_POSITIONS [
		p: as positions! ALLOC_TAIL(rules)
		p/header: TYPE_POINT
		p/rule:	  (as-integer cmd - block/rs-head rule) >> 4	;-- save cmd position
		p/input:  input/head									;-- save input position
		p/sub:	  len											;-- default value for sub-rule type
	]
	
	#define PARSE_SET_INPUT_LENGTH(word) [
		word: _series/get-length as red-series! input no
	]
	
	#define PARSE_CHECK_INPUT_EMPTY? [
		end?: any [
			_series/rs-tail? as red-series! input
			all [positive? part input/head >= part]
		]
	]
	
	#define PARSE_COPY_INPUT(slot) [
		min: p/input
		new: as red-series! slot
		copy-cell as red-value! input as red-value! new
		copy-cell as red-value! input base				;@@ remove once OPTION? fixed
		new/head: min
		actions/copy new as red-value! new base no null
	]
	
	#define PARSE_PICK_INPUT [
		value: base
		switch TYPE_OF(input) [
			TYPE_BINARY [
				int: as red-integer! base
				int/header: TYPE_INTEGER
				int/value: binary/rs-abs-at as red-binary! input offset
			]
			TYPE_STRING 								;TBD: replace with ANY_STRING
			TYPE_FILE
			TYPE_URL
			TYPE_TAG
			TYPE_EMAIL [
				char: as red-char! base
				char/header: TYPE_CHAR
				char/value: string/rs-abs-at as red-string! input offset
			]
			default [value: block/rs-abs-at input offset]
		]
	]
	
	#define PARSE_TRACE(event) [
		#if red-tracing? = yes [
			if OPTION?(fun) [
				rule/head: (as-integer cmd - block/rs-head rule) >> 4
				if negative? rule/head [rule/head: 0]
				unless fire-event fun words/event match? rule input [
					return as red-value! logic/push match?
				]
			]
		]
	]
	
	#define PARSE_ERROR [
		reset saved?
		fire
	]

	#enum states! [
		ST_PUSH_BLOCK
		ST_POP_BLOCK
		ST_PUSH_RULE
		ST_POP_RULE
		ST_CHECK_PENDING
		ST_DO_ACTION
		ST_NEXT_INPUT
		ST_NEXT_ACTION
		ST_MATCH
		ST_MATCH_RULE
		ST_FIND_ALTERN
		ST_WORD
		ST_END
		ST_EXIT
	]
	
	#enum rule-flags! [									;-- negative values to not collide with t/state counter
		R_NONE:			-1
		R_TO:			-2
		R_THRU:			-3
		R_COPY:			-4
		R_SET:			-5
		R_NOT:			-6
		R_INTO:			-7
		R_THEN:			-8
		R_REMOVE:		-9
		R_INSERT:		-10
		R_WHILE:		-11
		R_COLLECT:		-12
		R_KEEP:			-13
		R_KEEP_PAREN:	-14
		R_KEEP_PICK:	-15
		R_AHEAD:		-16
		R_CHANGE:		-17
		R_CHANGE_ONLY:	-18
	]
	
	triple!: alias struct! [
		header [integer!]
		min	   [integer!]
		max	   [integer!]
		state  [integer!]
	]
	
	positions!: alias struct! [
		header [integer!]
		rule   [integer!]
		input  [integer!]
		sub    [integer!]
	]
	
	input!: alias struct! [
		header [integer!]
		head   [integer!]
		node   [node!]
		pos	   [integer!]
	]
	
	#if debug? = yes [
		print-state: func [s [states!]][
			print "state: "
			print-line switch s [
				ST_PUSH_BLOCK	 ["ST_PUSH_BLOCK"]
				ST_POP_BLOCK	 ["ST_POP_BLOCK"]
				ST_PUSH_RULE	 ["ST_PUSH_RULE"]
				ST_POP_RULE	 	 ["ST_POP_RULE"]
				ST_CHECK_PENDING ["ST_CHECK_PENDING"]
				ST_DO_ACTION	 ["ST_DO_ACTION"]
				ST_NEXT_INPUT	 ["ST_NEXT_INPUT"]
				ST_NEXT_ACTION	 ["ST_NEXT_ACTION"]
				ST_MATCH		 ["ST_MATCH"]
				ST_MATCH_RULE	 ["ST_MATCH_RULE"]
				ST_FIND_ALTERN	 ["ST_FIND_ALTERN"]
				ST_WORD			 ["ST_WORD"]
				ST_END			 ["ST_END"]
				ST_EXIT			 ["ST_EXIT"]
			]
		]
	]
	
	advance: func [
		str		[red-string!]
		value	[red-value!]							;-- char! or string! value
		return:	[logic!]
		/local
			type [integer!]
			len	 [integer!]
	][
		type: TYPE_OF(value)
		len: either any [type = TYPE_CHAR type = TYPE_BITSET][1][
			assert any [
				type = TYPE_STRING
				type = TYPE_FILE
				type = TYPE_URL
				type = TYPE_TAG
				type = TYPE_EMAIL
				type = TYPE_BINARY
			]
			string/rs-length? as red-string! value
		]
		if type = TYPE_TAG [len: len + 2]
		_series/rs-skip as red-series! str len
	]
	
	find-altern: func [									;-- search for next '| symbol
		rule	[red-block!]
		pos		[red-value!]
		return: [integer!]								;-- >= 0 found, -1 not found 
		/local
			head  [red-value!]
			tail  [red-value!]
			value [red-value!]
			w	  [red-word!]
			s	  [series!]
	][
		s: GET_BUFFER(rule)
		head:  s/offset + ((as-integer pos - s/offset) >> 4)
		tail:  s/tail
		value: head
		
		while [value < tail][
			if TYPE_OF(value) = TYPE_WORD [
				w: as red-word! value
				if w/symbol = words/pipe [
					return ((as-integer value - head) >> 4)
				]
			]
			value: value + 1
		]
		-1
	]
	
	adjust-input-index: func [
		input	[red-series!]
		pos		[positions!]
		base    [integer!]
		offset  [integer!]
		return: [logic!]
	][
		input/head: input/head + base + offset
		pos/input: either zero? input/head [0][input/head - base]
		yes
	]
	
	find-token?: func [									;-- optimized fast token lookup
		rules	[red-block!]							;-- (could be optimized even further)
		input	[red-series!]
		token	[red-value!]
		comp-op	[integer!]
		part	[integer!]
		saved?	[logic!]
		return: [logic!]
		/local
			pos*   [positions!]
			head   [red-value!]
			tail   [red-value!]
			value  [red-value!]
			char   [red-char!]
			bits   [red-bitset!]
			s	   [series!]
			p	   [byte-ptr!]
			phead  [byte-ptr!]
			ptail  [byte-ptr!]
			pbits  [byte-ptr!]
			pos    [byte-ptr!]							;-- required by BS_TEST_BIT
			p4	   [int-ptr!]
			cp	   [integer!]
			size   [integer!]
			unit   [integer!]
			type   [integer!]
			res	   [integer!]
			set?   [logic!]								;-- required by BS_TEST_BIT
			not?   [logic!]
			match? [logic!]
	][
		s: GET_BUFFER(rules)
		assert s/offset <= (s/tail - 2)
		pos*: as positions! s/tail - 2
		s: GET_BUFFER(input)
		
		type: TYPE_OF(input)
		either any [									;TBD: replace with ANY_STRING + TYPE_BINARY
			type = TYPE_STRING
			type = TYPE_FILE
			type = TYPE_URL
			type = TYPE_TAG
			type = TYPE_EMAIL
			type = TYPE_BINARY
		][
			unit:  GET_UNIT(s)
			phead: (as byte-ptr! s/offset) + (input/head << (log-b unit))
			ptail: as byte-ptr! s/tail

			if positive? part [
				p: (as byte-ptr! s/offset) + (part << (log-b unit))
				if p < ptail [ptail: p]
			]
			p: phead
			
			switch TYPE_OF(token) [
				TYPE_BITSET [
					bits:  as red-bitset! token
					s:	   GET_BUFFER(bits)
					pbits: as byte-ptr! s/offset
					not?:  FLAG_NOT?(s)
					size:  s/size << 3

					until [
						cp: switch unit [
							Latin1 [as-integer p/value]
							UCS-2  [(as-integer p/2) << 8 + p/1]
							UCS-4  [p4: as int-ptr! p p4/value]
						]
						either size < cp [
							match?: not?				;-- virtual bit
						][
							BS_TEST_BIT(pbits cp match?)
						]
						if match? [
							return adjust-input-index input pos* 1 ((as-integer p - phead) >> (log-b unit))
						]
						p: p + unit
						p >= ptail
					]
				]
				TYPE_STRING
				TYPE_FILE
				TYPE_URL
				TYPE_TAG
				TYPE_EMAIL
				TYPE_BINARY [
					if all [type = TYPE_BINARY TYPE_OF(token) <> TYPE_BINARY][
						PARSE_ERROR [TO_ERROR(script parse-rule) token]
					]
					type: TYPE_OF(token)
					size: string/rs-length? as red-string! token
					if type = TYPE_TAG [size: size + 2]
					if (string/rs-length? as red-string! input) < size [return no]
					
					phead: as byte-ptr! s/offset
					unit:  log-b unit
					
					until [
						res: switch type [
							TYPE_BINARY [
								binary/equal? as red-binary! input as red-binary! token comp-op yes
							]
							TYPE_TAG [
								either string/match-tag? as red-string! input token comp-op [
									input/head: input/head + 1
									res: string/equal? as red-string! input as red-string! token comp-op yes
									input/head: input/head - 1
									res
								][1]					;-- force failure
							]
							default  [
								string/equal? as red-string! input as red-string! token comp-op yes
							]
						]
						if zero? res [return adjust-input-index input pos* size 0]
						input/head: input/head + 1
						phead + (input/head + size << unit) > ptail
					]
				]
				TYPE_CHAR [
					char: as red-char! token
					cp: char/value

					switch unit [
						Latin1 [
							while [p < ptail][
								if p/value = as-byte cp [
									return adjust-input-index input pos* 1 (as-integer p - phead)
								]
								p: p + 1
							]
						]
						UCS-2 [
							while [p < ptail][
								if (as-integer p/2) << 8 + p/1 = cp [
									return adjust-input-index input pos* 1 ((as-integer p - phead) >> 1)
								]
								p: p + 2
							]
						]
						UCS-4 [
							p4: as int-ptr! p
							while [p4 < as int-ptr! ptail][
								if p4/value = cp [
									return adjust-input-index input pos* 1 ((as-integer p4 - phead) >> 2)
								]
								p4: p4 + 1
							]
						]
					]
				]
				default [
					PARSE_ERROR [TO_ERROR(script parse-rule) token]
				]
			]
		][
			head:  s/offset + input/head
			tail:  s/tail
			if positive? part [
				value: s/offset + part
				if value < tail [tail: value]
			]
			value: head
			
			while [value < tail][
				if actions/compare value token comp-op [
					return adjust-input-index input pos* 1 ((as-integer value - head) >> 4)
				]
				value: value + 1
			]
		]
		no
	]
	
	loop-bitset: func [									;-- optimized bitset matching loop
		input	[red-series!]
		bits	[red-bitset!]
		min		[integer!]
		max		[integer!]
		counter [int-ptr!]
		part	[integer!]
		return: [logic!]
		/local
			s	   [series!]
			unit   [integer!]
			p	   [byte-ptr!]
			phead  [byte-ptr!]
			ptail  [byte-ptr!]
			pbits  [byte-ptr!]
			pos    [byte-ptr!]							;-- required by BS_TEST_BIT
			p4	   [int-ptr!]
			cp	   [integer!]
			cnt	   [integer!]
			size   [integer!]
			set?   [logic!]								;-- required by BS_TEST_BIT
			not?   [logic!]
			max?   [logic!]
			match? [logic!]
	][
		s:	   GET_BUFFER(input)
		unit:  GET_UNIT(s)
		phead: (as byte-ptr! s/offset) + (input/head << (log-b unit))
		ptail: as byte-ptr! s/tail
		
		if positive? part [
			p: (as byte-ptr! s/offset) + (part << (log-b unit))
			if p < ptail [ptail: p]
		]
		
		p:	   phead

		s:	   GET_BUFFER(bits)
		pbits: as byte-ptr! s/offset
		not?:  FLAG_NOT?(s)
		size:  s/size << 3
		
		cnt: 	0
		match?: yes
		max?:	max <> R_NONE
		
		until [
			cp: switch unit [
				Latin1 [as-integer p/value]
				UCS-2  [(as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p p4/value]
			]
			either size < cp [							;-- virtual bit
				match?: not?
			][
				BS_TEST_BIT(pbits cp match?)
			]
			if match? [
				p: p + unit
				cnt: cnt + 1
			]
			any [
				not match?
				p = ptail
				all [max? cnt >= max]
			]
		]
		input/head: input/head + ((as-integer p - phead) >> (log-b unit))
		counter/value: cnt
		
		either not max? [min <= cnt][all [min <= cnt cnt <= max]]
	]
	
	loop-token: func [									;-- fast literal matching loop
		input	[red-series!]
		token	[red-value!]
		min		[integer!]
		max		[integer!]
		counter [int-ptr!]
		comp-op	[integer!]
		part	[integer!]
		return: [logic!]
		/local
			len	   [integer!]
			cnt	   [integer!]
			type   [integer!]
			match? [logic!]
			end?   [logic!]
			s	   [series!]
	][
		PARSE_SET_INPUT_LENGTH(len)
		if any [zero? len len < min][return no]			;-- input too short
		
		cnt: 	0
		match?: yes
		type: 	TYPE_OF(input)
		
		either any [									;TBD: replace with ANY_STRING
			type = TYPE_STRING
			type = TYPE_FILE
			type = TYPE_URL
			type = TYPE_TAG
			type = TYPE_EMAIL
			type = TYPE_BINARY
		][
			either TYPE_OF(token)= TYPE_BITSET [
				match?: loop-bitset input as red-bitset! token min max counter part
				cnt: counter/value
			][
				until [									;-- ANY-STRING input matching
					match?: either type = TYPE_BINARY [
						binary/match? as red-binary! input token comp-op
					][
						string/match? as red-string! input token comp-op
					]
					end?: any [
						all [match? advance as red-string! input token]	;-- consume matched input
						all [positive? part input/head >= part]
					]
					cnt: cnt + 1
					any [
						not match?
						end?
						all [max <> R_NONE cnt >= max]
					]
				]
			]
		][
			until [										;-- ANY-BLOCK input matching
				match?:	actions/compare block/rs-head input token comp-op	;@@ sub-optimal!!
				end?: any [
					all [match? block/rs-next input]	;-- consume matched input
					all [positive? part input/head >= part]
				]
				cnt: cnt + 1
				any [
					not match?
					end?
					all [max <> R_NONE cnt >= max]
				]
			]
		]
		
		either match? [
			if all [max <> R_NONE any [min > cnt cnt > max]][match?: no]
		][
			cnt: cnt - 1
			match?: either max = R_NONE [min <= cnt][all [min <= cnt cnt <= max]]
		]
		counter/value: cnt
		match?
	]
	
	check-infinite-loop: func [
		input	[red-series!]
		rules	[red-block!]
		rule	[red-block!]
		saved?	[logic!]
		/local
			value	[red-value!]
			tail	[red-value!]
			blk		[red-block!]
			p		[positions!]
			in		[input!]
			node	[node!]
			s		[series!]
	][
		s: GET_BUFFER(rules)
		value: s/offset + rules/head
		tail:  s/tail
		node:  rule/node
		
		while [value < tail][
			if TYPE_OF(value) = TYPE_BLOCK [
				blk: as red-block! value
				if all [node = blk/node rule/head = blk/head value + 1 < tail][
					p: as positions! value - 1
					in: as input! value - 2
					if all [
						p/input = input/head
						in/node = input/node
					][
						PARSE_ERROR [TO_ERROR(script parse-infinite) rule]
					]
				]
			]
			value: value + 1
		]
	]
	
	check-limits: func [
		series [red-block!]
		rules  [red-block!]
		saved? [logic!]
		/local
			s [series!]
	][
		s: GET_BUFFER(series)
		if (as-integer s/tail - s/offset) >> 4 > PARSE_MAX_DEPTH [
			PARSE_ERROR [TO_ERROR(script parse-stack)]
		]
		
		s: GET_BUFFER(rules)
		if (as-integer s/tail - s/offset) >> 4 > PARSE_MAX_DEPTH [
			PARSE_ERROR [TO_ERROR(script parse-stack)]
		]
	]
	
	fire-event: func [
		fun	  	[red-function!]
		event   [red-word!]
		match? 	[logic!]
		rule	[red-block!]
		input   [red-series!]
		return: [logic!]
		/local
			loop? [logic!]
	][
		stack/mark-func words/_body						;@@ find something more adequate
		
		stack/push as red-value! event
		logic/push match?
		stack/push as red-value! rule
		stack/push as red-value! input
		stack/push as red-value! rules
		_function/call fun global-ctx					;FIXME: hardcoded origin context
		
		stack/unwind
		loop?: logic/top-true?
		stack/pop 1
		loop?
	]
	
	save-stack: func [
		return: [logic!]
		/local
			cnt	   [integer!]
			p	   [positions!]
			saved? [logic!]
	][
		cnt: block/rs-length? rules
		saved?: cnt <> 0
		if saved? [
			p: as positions! ALLOC_TAIL(rules)
			p/header: TYPE_POINT
			p/input:  series/head
			p/rule:   rules/head
			
			series/head: series/head + block/rs-length? series
			rules/head:  rules/head + cnt + 1			;-- account for the new position! slot
		]
		saved?
	]
	
	restore-stack: func [
		/local
			s [series!]
			p [positions!]
	][
		if rules/head > 0 [
			s: GET_BUFFER(rules)
			s/tail: s/tail - 1
			assert s/offset <= s/tail
			p: as positions! s/tail
			series/head: p/input
			rules/head: p/rule
		]
	]
	
	reset: func [saved? [logic!]][
		_series/clear as red-series! series
		_series/clear as red-series! rules
		if saved? [restore-stack]
	]
	
	eval: func [
		code	[red-value!]
		reset?	[logic!]
		saved?	[logic!]
		return: [red-value!]
		/local
			len	  [integer!]
			saved [red-value!]
			res	  [red-value!]
	][
		PARSE_SAVE_SERIES
		saved: stack/top
		catch RED_THROWN_ERROR [interpreter/eval as red-block! code no]
		PARSE_RESTORE_SERIES							;-- restore localy saved series/head first
		if system/thrown <> 0 [reset saved? re-throw]
		res: stack/top - 1
		if reset? [stack/top: saved]
		res
	]

	process: func [
		input	[red-series!]
		rule	[red-block!]
		comp-op	[integer!]
		;strict? [logic!]
		part	[integer!]
		fun		[red-function!]
		return: [red-value!]
		/local
			new		 [red-series!]
			int		 [red-integer!]
			int2	 [red-integer!]
			blk		 [red-block!]
			sym*	 [red-symbol!]
			cmd		 [red-value!]
			tail	 [red-value!]
			value	 [red-value!]
			value2	 [red-value!]
			base	 [red-value!]
			s-top	 [red-value!]
			char	 [red-char!]
			dt		 [red-datatype!]
			bool	 [red-logic!]
			w		 [red-word!]
			t 		 [triple!]
			p		 [positions!]
			in		 [input!]
			state	 [states!]
			pos		 [byte-ptr!]						;-- required by BS_TEST_BIT_ALT()
			type	 [integer!]
			dt-type	 [integer!]
			sym		 [integer!]
			min		 [integer!]
			max		 [integer!]
			s		 [series!]
			cnt		 [integer!]
			len		 [integer!]
			offset	 [integer!]
			cnt-col	 [integer!]
			saved	 [integer!]
			before   [integer!]
			upper?	 [logic!]
			end?	 [logic!]
			ended?	 [logic!]
			match?	 [logic!]
			loop?	 [logic!]
			pop?	 [logic!]
			break?	 [logic!]
			rule?	 [logic!]
			collect? [logic!]
			into?	 [logic!]
			only?	 [logic!]
			done?	 [logic!]
			saved?	 [logic!]
	][
		match?:	  yes
		end?:	  no
		ended?:   yes
		break?:	  no
		pop?:	  no
		rule?:	  no
		collect?: no
		value:	  null
		type:	  -1
		min:	  -1
		max:	  -1
		cnt:	   0
		cnt-col:   0
		state:    ST_PUSH_BLOCK
		
		saved?: save-stack
		base: stack/push*								;-- slot on stack for COPY/SET operations (until OPTION?() is fixed)
		input: as red-series! block/rs-append series as red-value! input ;-- input now points to the series stack entry
		cmd: (block/rs-head rule) - 1					;-- decrement to compensate for starting increment
		tail: block/rs-tail rule						;TBD: protect current rule block from changes
		
		until [
			#if debug? = yes [if verbose > 1 [print-state state]]
			
			switch state [
				ST_PUSH_BLOCK [
					check-limits series rules saved?
					
					#either debug? = yes [PARSE_PUSH_INPUTPOS][none/make-in rules]
					PARSE_SET_INPUT_LENGTH(len)
					PARSE_PUSH_POSITIONS
					block/rs-append rules as red-value! rule
					if all [value <> null value <> rule][
						assert TYPE_OF(value) = TYPE_BLOCK
						copy-cell value as red-value! rule
					]
					cmd: (block/rs-head rule) - 1		;-- decrement to compensate for starting increment
					tail: block/rs-tail rule			;TBD: protect current rule block from changes
					
					;#if debug? = yes [check-infinite-loop input rules rule saved?]
					PARSE_CHECK_INPUT_EMPTY?			;-- refresh end? flag
					PARSE_TRACE(_push)
					state: ST_NEXT_ACTION
				]
				ST_POP_BLOCK [
					either 3 = block/rs-length? rules [
						state: ST_END
					][
						loop?: no
						ended?: cmd = tail
						
						s: GET_BUFFER(rules)
						copy-cell s/tail - 1 as red-value! rule
						assert TYPE_OF(rule) = TYPE_BLOCK
						p: as positions! s/tail - 2
						
						cmd: (block/rs-head rule) + p/rule
						tail: block/rs-tail rule
						PARSE_TRACE(_pop)
						s/tail: s/tail - 3
						value: s/tail - 1
						assert s/offset <= value
						
						state: either TYPE_OF(value) = TYPE_INTEGER [
							ST_POP_RULE
						][
							either match? [ST_NEXT_ACTION][ST_FIND_ALTERN]
						]
					]
				]
				ST_PUSH_RULE [
					check-limits series rules saved?
					
					either any [type = R_COPY type = R_SET][
						block/rs-append rules cmd
					][
						t: as triple! ALLOC_TAIL(rules)
						t/header: TYPE_POINT
						t/min:	  min
						t/max:	  max
						t/state:  1
					]
					PARSE_SET_INPUT_LENGTH(len)
					PARSE_PUSH_POSITIONS
					int: as red-integer! ALLOC_TAIL(rules)
					int/header: TYPE_INTEGER
					int/value: type
					if cmd < tail [cmd: cmd + 1]		;-- move after the rule prologue
					value: cmd
					PARSE_TRACE(_push)
					state: ST_MATCH_RULE
				]
				ST_POP_RULE [
					s: GET_BUFFER(rules)
					assert s/offset <= (s/tail - 3)
					value: s/tail - 1
					
					either TYPE_OF(value) = TYPE_BLOCK [
						state: either pop? [pop?: no ST_POP_BLOCK][ST_NEXT_ACTION]
					][
						pop?: yes
						p: as positions! s/tail - 2
						int: as red-integer! value
						switch int/value [
							R_WHILE
							R_NONE [					;-- iterative rules (ANY, SOME, WHILE, ...)
								t: as triple! s/tail - 3
								cnt: t/state
								;-- Find out if a new loop is required
								loop?: match?
								if all [match? t/max <> R_NONE][ ;-- if rule matched and an upper bound exists,
									loop?: cnt < t/max			 ;-- but not reached yet, loop again
								]
								if all [						 ;-- try to avoid some infinite loops
									int/value <> R_WHILE
									input/head = p/input		 ;-- if no input was consumed (except for WHILE)
								][
									PARSE_SET_INPUT_LENGTH(len)
									if len >= p/sub [			 ;-- and if no input was forward-consumed (remove)
										loop?: no
										break?: no
									]
								]
								if any [						 ;-- don't loop if any:
									break?						 ;-- a BREAK or REJECT command was issued
									end? 						 ;-- don't loop if no more input
								][
									loop?: no
									break?: no
								]
								if loop? [
									;-- Reset state for a new loop
									t/state: cnt + 1
									cmd: (block/rs-head rule) + p/rule ;-- reset rule offset
									PARSE_TRACE(_iterate)
									state: ST_NEXT_ACTION
									pop?: no
								]
								;-- Postprocess match? value
								either match? [
									if all [not loop? cnt < t/min][match?: no]	;-- minimal number of iteration not reached
								][
									if any [				;-- last loop failed case
										t/min <= (cnt - 1)	;-- number of iteration more than lower bound
										zero? t/min			;-- or lower bound is zero (ANY, OPT, WHILE)
									][
										match?: yes			;-- make the last loop return success
									]
								]
							]
							R_TO
							R_THRU [
								either match? [
									if int/value = R_TO [
										input/head: p/input	;-- move input before the last match
										end?: no
									]
								][
									before: input/head
									end?: _series/rs-skip as red-series! input 1
									match?: before = input/head
									if positive? part [match?: input/head >= part or match?]
									
									either match? [
										w: as red-word! (block/rs-head rule) + p/rule + 1 ;-- TO/THRU argument
										match?: all [
											TYPE_OF(w) = TYPE_WORD 
											words/end = symbol/resolve w/symbol
										]
									][
										p/input: input/head	;-- refresh saved input head before new iteration
										cmd: (block/rs-head rule) + p/rule ;-- loop rule
										PARSE_TRACE(_pop)
										PARSE_TRACE(_iterate)
										state: ST_NEXT_ACTION
										pop?: no
									]
								]
							]
							R_COPY [
								if match? [
									PARSE_COPY_INPUT(p)
									_context/set as red-word! s/tail - 3 as red-value! new
								]
							]
							R_SET [
								if match? [
									either p/input = input/head [
										value: as red-value! none-value
									][
										offset: p/input
										PARSE_PICK_INPUT
									]
									_context/set as red-word! p - 1 value
								]
							]
							R_KEEP
							R_KEEP_PAREN
							R_KEEP_PICK [
								if match? [
									blk: as red-block! stack/top - 1
									assert any [
										TYPE_OF(blk) = TYPE_WORD
										TYPE_OF(blk) = TYPE_GET_WORD
										TYPE_OF(blk) = TYPE_BLOCK
									]
									into?: TYPE_OF(blk) = TYPE_GET_WORD
									if into? [
										blk: as red-block! _context/get as red-word! blk
										type: TYPE_OF(blk)
										unless ANY_SERIES?(type) [
											PARSE_ERROR [TO_ERROR(script parse-into-bad)]
										]
									]
									value: stack/top	;-- refer last value from paren expression
									offset: p/input		;-- required by PARSE_PICK_INPUT
									
									if int/value = R_KEEP [
										case [
											p/sub = R_COPY [			;-- KEEP COPY case
												value: _context/get as red-word! s/tail
											]
											offset + 1 < input/head [	;-- KEEP with matched size > 1
												PARSE_COPY_INPUT(value)
											]
											offset < input/head [
												PARSE_PICK_INPUT		;-- KEEP with matched size = 1
											]
											true [value: null]
										]
									]
									either int/value <> R_KEEP_PICK [
										offset: input/head	;-- ensures no looping
									][
										if offset >= input/head [value: null]
									]
									
									if value <> null [
										until [
											if int/value = R_KEEP_PICK [
												PARSE_PICK_INPUT
												offset: offset + 1
											]
											either into? [
												switch TYPE_OF(blk) [
													TYPE_BINARY [binary/insert as red-binary! blk value null yes null no]
													TYPE_STRING
													TYPE_FILE
													TYPE_URL 
													TYPE_TAG
													TYPE_EMAIL [string/insert as red-string! blk value null yes null no]
													default  [block/insert blk value null yes null no]
												]
											][
												block/rs-append blk value
											]
											offset = input/head
										]
									]
								]
							]
							R_REMOVE [
								if match? [
									int/value: input/head - p/input
									input/head: p/input
									assert int/value >= 0
									PARSE_SAVE_SERIES
									actions/remove input as red-value! int
									PARSE_RESTORE_SERIES
								]
							]
							R_CHANGE
							R_CHANGE_ONLY [
								cmd: cmd + 1
								if cmd >= tail [PARSE_ERROR [TO_ERROR(script parse-end) words/_change]]
								if match? [
									s-top: null
									switch TYPE_OF(cmd) [
										TYPE_PAREN [
											s-top: stack/top
											value: eval cmd no saved?
											PARSE_TRACE(_paren)
										]
										TYPE_WORD [
											value: _context/get as red-word! cmd
											if TYPE_OF(value) = TYPE_UNSET [
												PARSE_ERROR [TO_ERROR(script no-value) cmd]
											]
										]
										default	  [value: cmd]
									]
									only?: int/value = R_CHANGE_ONLY
									int/value: input/head - p/input
									input/head: p/input
									assert int/value >= 0
									copy-cell as red-value! int base	;@@ remove once OPTION? fixed
									PARSE_SAVE_SERIES
									new: as red-series! actions/change input value base only? null
									if s-top <> null [stack/top: s-top]
									PARSE_RESTORE_SERIES
									input/head: new/head
								]
							]
							R_AHEAD [
								input/head: p/input
								PARSE_CHECK_INPUT_EMPTY? ;-- refresh end? flag after backtracking
							]
							R_NOT [
								match?: not match?
							]
							R_COLLECT [
								cnt-col: cnt-col - 1
								value: stack/top - 1

								either stack/top - 2 = base [	;-- root unnamed block reached
									collect?: TYPE_OF(value) = TYPE_BLOCK
								][
									if TYPE_OF(value) = TYPE_BLOCK [
										blk: as red-block! stack/top - 2
										collect?: no

										switch TYPE_OF(blk) [
											TYPE_WORD [
												_context/set as red-word! blk value
												stack/pop 1
											]
											TYPE_GET_WORD [
												blk: as red-block! _context/get as red-word! blk
												block/insert-value blk value
											]
											default [
												assert TYPE_OF(blk) = TYPE_BLOCK
												block/rs-append blk value
												collect?: yes
											]
										]
									]
									stack/pop 1
								]
								if TYPE_OF(value) = TYPE_GET_WORD [	;-- COLLECT INTO exiting
									t: as triple! s/tail - 3
									unless t/max = -1 [
										blk: as red-block! _context/get as red-word! value
										blk/head: t/max	;-- restore saved block cursor
									]
								]
							]
							R_INTO [
								PARSE_CHECK_INPUT_EMPTY?
								unless end? [match?: no]
								
								s: GET_BUFFER(series)
								s/tail: s/tail - 1
								input: as red-series! s/tail - 1
								unless ended? [match?: no]
								if match? [input/head: input/head + 1]	;-- skip parsed series
								
								PARSE_CHECK_INPUT_EMPTY? ;-- refresh end? flag after popping series
								s: GET_BUFFER(rules)
							]
							R_THEN [
								PARSE_TRACE(_pop)
								s/tail: s/tail - 3		;-- pop rule stack frame
								state: either match? [cmd: tail ST_NEXT_ACTION][ST_FIND_ALTERN]
								pop?: no
							]
						]
						if pop? [
							PARSE_TRACE(_pop)
							s/tail: s/tail - 3			;-- pop rule stack frame
							assert s/offset <= s/tail
							if s/tail > s/offset [
								p: as positions! s/tail - 2
								p/sub: int/value		;-- save rule type in parent stack frame
							]
							state: ST_CHECK_PENDING
						]
					]
					pop?: no
				]
				ST_CHECK_PENDING [
					s: GET_BUFFER(rules)
					value: s/tail - 1
					assert s/offset <= value
					
					state: either TYPE_OF(value) <> TYPE_INTEGER [
						either match? [ST_NEXT_ACTION][ST_FIND_ALTERN]
					][
						ST_POP_RULE
					]
				]
				ST_DO_ACTION [
					dt-type: TYPE_OF(value)				;-- value is used in this state instead of cmd
					switch dt-type [					;-- allows to enter the state with cmd or :cmd (if word!)
						TYPE_WORD 	[
							if all [value <> cmd TYPE_OF(cmd) = TYPE_WORD][
								PARSE_ERROR [TO_ERROR(script parse-rule) value]
							]
							state: ST_WORD
						]
						TYPE_BLOCK 	[
							state: ST_PUSH_BLOCK
						]
						TYPE_TYPESET
						TYPE_DATATYPE [
							type: TYPE_OF(input)
							if any [					;TBD: replace with ANY_STRING?
								type = TYPE_STRING
								type = TYPE_FILE
								type = TYPE_URL
								type = TYPE_TAG
								type = TYPE_EMAIL
								type = TYPE_BINARY
							][
								PARSE_ERROR [TO_ERROR(script parse-unsupported)]
							]
							PARSE_CHECK_INPUT_EMPTY?
							either end? [match?: false][
								dt: as red-datatype! value
								value: block/rs-head input
								match?: either dt-type = TYPE_TYPESET [
									type: TYPE_OF(value)
									BS_TEST_BIT_ALT(dt type)
								][
									TYPE_OF(value) = dt/value
								]
								PARSE_TRACE(_match)
							]
							state: either match? [ST_NEXT_INPUT][ST_CHECK_PENDING]
						]
						TYPE_SET_WORD [
							_context/set as red-word! value as red-value! input
							state: ST_NEXT_ACTION
						]
						TYPE_GET_WORD [
							new: as red-series! _context/get as red-word! value
							either all [
								TYPE_OF(new) = TYPE_OF(input)
								new/node = input/node
							][
								input/head: new/head
								state: ST_NEXT_ACTION
							][
								PARSE_ERROR [TO_ERROR(script parse-invalid-ref) value]
							]
						]
						TYPE_INTEGER [
							int:  as red-integer! value
							if int/value < 0 [PARSE_ERROR [TO_ERROR(script out-of-range) int]]
							int2: as red-integer! cmd + 1
							if all [
								int2 < tail
								TYPE_OF(int2) = TYPE_WORD
							][
								int2: as red-integer! _context/get as red-word! cmd + 1
							]
							upper?: TYPE_OF(int2) = TYPE_INTEGER
							if any [
								int2 = tail
								all [upper?	int2 + 1 = tail]
								all [upper? int/value > int2/value]
							][
								PARSE_ERROR [TO_ERROR(script parse-rule) value]
							]
							if all [upper? int2/value < 0][
								PARSE_ERROR [TO_ERROR(script out-of-range) int2]
							]
							state: either all [zero? int/value not upper?][
								cmd: cmd + 1			;-- skip over sub-rule
								ST_CHECK_PENDING
							][
								min:  int/value
								max:  either upper? [cmd: cmd + 1 int2/value][min]
								type: R_NONE
								ST_PUSH_RULE
							]
						]
						TYPE_PAREN [
							s: GET_BUFFER(rule)
							offset: (as-integer cmd - s/offset) >> 4	;-- save rule position
							
							eval value yes saved?
							PARSE_TRACE(_paren)
							
							s: GET_BUFFER(rule)
							cmd: s/offset + offset		;-- refresh rule pointers,
							tail: s/tail				;-- in case the block was changed
							if cmd >= tail [cmd: tail - 1]	;-- avoid a "past end" state
							PARSE_SET_INPUT_LENGTH(len)
							if negative? len [input/head: input/head + len]
							state: ST_CHECK_PENDING
						]
						default [						;-- try to match a literal value
							state: ST_MATCH
						]
					]
				]
				ST_NEXT_INPUT [
					end?: _series/rs-skip as red-series! input 1
					if positive? part [end?: input/head >= part or end?]
					state: ST_CHECK_PENDING
				]
				ST_NEXT_ACTION [
					if cmd < tail [cmd: cmd + 1]
					
					state: either cmd = tail [
						s: GET_BUFFER(rules)
						value: s/tail - 1
						assert s/offset <= value
						either TYPE_OF(value) = TYPE_INTEGER [ST_POP_RULE][ST_POP_BLOCK]
					][
						PARSE_TRACE(_fetch)
						value: cmd
						ST_DO_ACTION
					]
				]
				ST_MATCH [
					type: TYPE_OF(input)
					either end? [
						match?: all [
							any [
								type = TYPE_STRING
								type = TYPE_FILE
								type = TYPE_URL
								type = TYPE_TAG
								type = TYPE_EMAIL
							]
							any [
								TYPE_OF(value) = TYPE_STRING
								TYPE_OF(value) = TYPE_FILE
								TYPE_OF(value) = TYPE_URL
							]
							zero? string/rs-length? as red-string! value
						]
					][
						end?: switch type [
							TYPE_BINARY [
								match?: either TYPE_OF(value) = TYPE_BITSET [
									binary/match-bitset? as red-binary! input as red-bitset! value
								][
									binary/match? as red-binary! input value comp-op
								]
								all [match? advance as red-string! input value]	;-- consume matched input
							]
							TYPE_STRING
							TYPE_FILE
							TYPE_URL
							TYPE_TAG
							TYPE_EMAIL [
								match?: either TYPE_OF(value) = TYPE_BITSET [
									string/match-bitset? as red-string! input as red-bitset! value
								][
									string/match? as red-string! input value comp-op
								]
								all [match? advance as red-string! input value]	;-- consume matched input
							]
							default [
								s: GET_BUFFER(input)
								value2: s/offset + input/head
								end?: value2 >= s/tail
								either end? [match?: false][
									match?: actions/compare value2 value comp-op
									if match? [input/head: input/head + 1] ;-- consume matched input
								]
								all [match? end?]
							]
						]
						if positive? part [end?: input/head >= part or end?]
					]
					PARSE_TRACE(_match)
					state: ST_CHECK_PENDING
				]
				ST_MATCH_RULE [
					either all [value = tail][
						w: switch type [
							R_TO		 [words/_to]
							R_THRU		 [words/_thru]
							R_NOT		 [words/_not]
							R_THEN		 [words/_then]
							R_REMOVE	 [words/_remove]
							R_WHILE		 [words/_while]
							R_COLLECT	 [words/_collect]
							R_KEEP
							R_KEEP_PICK
							R_KEEP_PAREN [words/_keep]
							R_AHEAD		 [words/_ahead]
							default		 [null]
						]
						if w <> null [PARSE_ERROR [TO_ERROR(script parse-end) w]]
						match?: yes
						state: ST_CHECK_PENDING
					][
						switch TYPE_OF(value) [
							TYPE_BLOCK	 [state: ST_PUSH_BLOCK]
							TYPE_WORD	 [state: ST_WORD rule?: all [type <> R_COLLECT type <> R_KEEP]]
							TYPE_DATATYPE
							TYPE_TYPESET
							TYPE_INTEGER [state: ST_DO_ACTION]
							default [
								either min = R_NONE [
									state: either any [type = R_TO type = R_THRU][
										match?: find-token? rules input value comp-op part saved?
										PARSE_TRACE(_match)
										ST_POP_RULE
									][
										ST_DO_ACTION	;-- set/get-words are sinking here
									]
								][
									match?: loop-token input value min max :cnt comp-op part
									if all [not match? zero? min][match?: yes]
									PARSE_TRACE(_match)
									s: GET_BUFFER(rules)
									PARSE_TRACE(_pop)
									s/tail: s/tail - 3	;-- pop rule stack frame
									assert s/offset <= s/tail
									state: ST_CHECK_PENDING
								]
								PARSE_CHECK_INPUT_EMPTY?
							]
						]
					]
				]
				ST_FIND_ALTERN [
					s: GET_BUFFER(rules)				;-- backtrack input
					p: as positions! s/tail - 2
					assert s/offset <= p
					input/head: p/input
					PARSE_CHECK_INPUT_EMPTY?			;-- refresh end? flag after backtracking
					
					cnt: find-altern rule cmd
					
					state: either cnt >= 0 [
						cmd: cmd + cnt					;-- point rule head to alternative part
						match?: yes						;-- reset match? flag
						ST_NEXT_ACTION
					][
						ST_POP_BLOCK
					]
				]
				ST_WORD [
					w: as red-word! cmd
					sym: symbol/resolve w/symbol
					#if debug? = yes [
						sym*: symbol/get sym
						if verbose > 0 [print-line ["parse: " sym*/cache]]
					]
					case [
						sym = words/pipe [				;-- |
							if cmd = tail [PARSE_ERROR [TO_ERROR(script parse-end) words/_pipe]]
							cmd: tail
							s: GET_BUFFER(rules)
							value: s/tail - 1
							assert s/offset <= value
							state: either TYPE_OF(value) = TYPE_INTEGER [ST_POP_RULE][ST_POP_BLOCK]
						]
						sym = words/skip [				;-- SKIP
							PARSE_CHECK_INPUT_EMPTY?
							match?: not end?
							PARSE_TRACE(_match)
							state: ST_NEXT_INPUT
						]
						sym = words/any* [				;-- ANY
							if cmd + 1 = tail [PARSE_ERROR [TO_ERROR(script parse-end) words/_any]]
							min:   0
							max:   R_NONE
							type:  R_NONE
							state: ST_PUSH_RULE
						]
						sym = words/some [				;-- SOME
							if cmd + 1 = tail [PARSE_ERROR [TO_ERROR(script parse-end) words/_some]]
							min:   1
							max:   R_NONE
							type:  R_NONE
							state: ST_PUSH_RULE
						]
						sym = words/copy [				;-- COPY
							cmd: cmd + 1
							if any [cmd = tail TYPE_OF(cmd) <> TYPE_WORD][
								PARSE_ERROR [TO_ERROR(script parse-end) words/_copy]
							]
							min:   R_NONE
							type:  R_COPY
							state: ST_PUSH_RULE
						]
						sym = words/thru [				;-- THRU
							min:   R_NONE
							type:  R_THRU
							state: ST_PUSH_RULE
						]
						sym = words/to [				;-- TO
							min:   R_NONE
							type:  R_TO
							state: ST_PUSH_RULE
						]
						sym = words/remove [			;-- REMOVE
							done?: no
							value: cmd + 1
							if all [value < tail TYPE_OF(value) = TYPE_WORD][
								new: as red-series! _context/get as red-word! value
								if all [TYPE_OF(new) = TYPE_OF(input) new/node = input/node][
									copy-cell as red-value! input base
									input/head: new/head
									PARSE_SAVE_SERIES
									actions/remove input base ;-- REMOVE position
									PARSE_RESTORE_SERIES
									cmd: value
									done?: yes
								]
							]
							state: either done? [ST_CHECK_PENDING][
								min:   R_NONE			;-- REMOVE rule
								type:  R_REMOVE
								ST_PUSH_RULE
							]
						]
						sym = words/break* [			;-- BREAK
							match?: yes
							break?: yes
							cmd:	cmd + 1
							pop?:	yes
							PARSE_TRACE(_match)
							state:	ST_POP_RULE
						]
						sym = words/opt [				;-- OPT
							if cmd + 1 = tail [PARSE_ERROR [TO_ERROR(script parse-end) words/_opt]]
							min:   0
							max:   1
							type:  R_NONE
							state: ST_PUSH_RULE
						]
						sym = words/keep [				;-- KEEP
							if cnt-col = 0 [PARSE_ERROR [TO_ERROR(script parse-keep) words/_keep]]
							value: cmd + 1
							min:   R_NONE
							type:  either TYPE_OF(value) = TYPE_PAREN [R_KEEP_PAREN][
								w: as red-word! value
								either all [
									(as red-value! w) < tail
									TYPE_OF(w) = TYPE_WORD
									words/pick = symbol/resolve w/symbol
								][
									cmd: cmd + 1
									value: cmd + 1
									R_KEEP_PICK
								][
									R_KEEP
								]
							]
							state: ST_PUSH_RULE
						]
						sym = words/fail [				;-- FAIL
							match?: no
							PARSE_TRACE(_match)
							state: ST_FIND_ALTERN
						]
						sym = words/ahead [				;-- AHEAD
							min:   R_NONE
							type:  R_AHEAD
							state: ST_PUSH_RULE
						]
						sym = words/while* [			;-- WHILE
							min:   0
							max:   R_NONE
							type:  R_WHILE
							state: ST_PUSH_RULE
						]
						sym = words/into [				;-- INTO
							type: TYPE_OF(input)
							unless ANY_BLOCK?(type) [
								PARSE_ERROR [TO_ERROR(script parse-block) input]
							]
							value: cmd + 1
							if value = tail [PARSE_ERROR [TO_ERROR(script parse-end) words/_into]]
							
							if TYPE_OF(value) = TYPE_WORD [
								value: _context/get as red-word! value
							]
							if TYPE_OF(value) <> TYPE_BLOCK [
								PARSE_ERROR [TO_ERROR(script parse-end) words/_into]
							]
							value: block/rs-head input
							type: TYPE_OF(value)
							either all [ANY_SERIES?(type) type <> TYPE_IMAGE][
								input: as red-series! block/rs-append series value
								min:  R_NONE
								type: R_INTO
								state: ST_PUSH_RULE
							][
								match?: no
								PARSE_TRACE(_match)
								state: ST_CHECK_PENDING
							]
						]
						sym = words/insert [			;-- INSERT
							w: as red-word! cmd + 1
							max: as-integer all [
								(as red-value! w) < tail
								TYPE_OF(w) = TYPE_WORD
								words/only = symbol/resolve w/symbol
							]
							cmd: cmd + max
							value: cmd + 1
							if value >= tail [PARSE_ERROR [TO_ERROR(script parse-end) words/_insert]]
							
							s-top: null
							saved: input/head
							either TYPE_OF(value) = TYPE_WORD [
								new: as red-series! _context/get as red-word! value
								if all [TYPE_OF(new) = TYPE_OF(input) new/node = input/node][
									cmd: value + 1		;-- INSERT position
									if cmd >= tail [PARSE_ERROR [TO_ERROR(script parse-rule) words/_insert]]
									switch TYPE_OF(cmd) [
										TYPE_PAREN [
											s-top: stack/top
											value: eval cmd no saved?
											PARSE_TRACE(_paren)
										]
										TYPE_WORD [
											value: _context/get as red-word! cmd
											if TYPE_OF(value) = TYPE_UNSET [
												PARSE_ERROR [TO_ERROR(script no-value) cmd]
											]
										]
										default	  [value: cmd]
									]
									input/head: new/head
								]
							][
								cmd: value
								if TYPE_OF(value) = TYPE_PAREN [
									s-top: stack/top
									value: eval value no saved?
									PARSE_TRACE(_paren)
								]
							]
							PARSE_SAVE_SERIES
							before: input/head
							if TYPE_OF(value) = TYPE_WORD [value: _context/get as red-word! value]
							actions/insert input value null as-logic max null no
							input/head: saved + (input/head - before)
							if s-top <> null [stack/top: s-top]
							PARSE_RESTORE_SERIES
							state: ST_NEXT_ACTION
						]
						sym = words/_change/symbol [	;-- CHANGE
							w: as red-word! cmd + 1
							max: as-integer all [
								(as red-value! w) < tail
								TYPE_OF(w) = TYPE_WORD
								words/only = symbol/resolve w/symbol
							]
							cmd: cmd + max
							if cmd >= tail [PARSE_ERROR [TO_ERROR(script parse-rule) words/_change]]
							
							done?: no
							value: cmd + 1
							if all [value < tail TYPE_OF(value) = TYPE_WORD][
								new: as red-series! _context/get as red-word! value
								if all [TYPE_OF(new) = TYPE_OF(input) new/node = input/node][
									cmd: value + 1		;-- CHANGE position
									if cmd >= tail [PARSE_ERROR [TO_ERROR(script parse-rule) words/_change]]
									s-top: null
									switch TYPE_OF(cmd) [
										TYPE_PAREN [
											s-top: stack/top
											value: eval cmd no saved?
											PARSE_TRACE(_paren)
										]
										TYPE_WORD [
											value: _context/get as red-word! cmd
											if TYPE_OF(value) = TYPE_UNSET [
												PARSE_ERROR [TO_ERROR(script no-value) cmd]
											]
										]
										default	  [value: cmd]
									]
									copy-cell as red-value! input base 	;@@ remove once OPTION? fixed
									input/head: new/head
									PARSE_SAVE_SERIES
									if TYPE_OF(value) = TYPE_WORD [value: _context/get as red-word! value]
									actions/change input value base as-logic max null
									if s-top <> null [stack/top: s-top]
									PARSE_RESTORE_SERIES
									done?: yes
								]
							]
							state: either done? [ST_CHECK_PENDING][
								min:   R_NONE			;-- CHANGE rule
								type:  either max = 1 [R_CHANGE_ONLY][R_CHANGE]
								ST_PUSH_RULE
							]
						]
						sym = words/end [				;-- END
							PARSE_CHECK_INPUT_EMPTY?
							match?: end?
							PARSE_TRACE(_match)
							state: ST_CHECK_PENDING
						]
						sym = words/then [				;-- THEN
							min:   R_NONE
							type:  R_THEN
							state: ST_PUSH_RULE
						]
						sym = words/if* [				;-- IF
							cmd: cmd + 1
							if any [cmd = tail TYPE_OF(cmd) <> TYPE_PAREN][
								PARSE_ERROR [TO_ERROR(script parse-end) words/_if]
							]
							bool: as red-logic! eval cmd yes saved?
							type: TYPE_OF(bool)
							match?: not any [
								type = TYPE_NONE
								all [type = TYPE_LOGIC not bool/value]
							]
							PARSE_TRACE(_match)
							state: ST_CHECK_PENDING
						]
						sym = words/not* [				;-- NOT
							min:   R_NONE
							type:  R_NOT
							state: ST_PUSH_RULE
						]
						sym = words/quote [				;-- QUOTE
							cmd: cmd + 1
							if cmd = tail [PARSE_ERROR [TO_ERROR(script parse-end) words/_quote]]
							value: cmd
							state: ST_MATCH
						]
						sym = words/collect [			;-- COLLECT
							cnt-col: cnt-col + 1
							max: R_NONE
							into?: no
							w: as red-word! cmd + 1
							
							if all [
								(as red-value! w) < tail
								TYPE_OF(w) = TYPE_WORD
							][
								sym: symbol/resolve w/symbol
								into?: any [sym = words/into sym = words/after]
								
								if any [into? sym = words/set][
									w: w + 1
									if any [
										w >= tail
										TYPE_OF(w) <> TYPE_WORD	
									][
										PARSE_ERROR [TO_ERROR(script parse-end) words/_collect]
									]
									either into? [get-word/push w][stack/push as red-value! w]
									cmd: as red-value! w
								]
							]
							either into? [
								blk: as red-block! _context/get w
								max: either sym = words/after [-1][blk/head] ;-- save block cursor
							][
								block/push* 8
							]
							min:   R_NONE
							type:  R_COLLECT
							state: ST_PUSH_RULE
						]
						sym = words/reject [			;-- REJECT
							match?: no
							break?: yes
							pop?:	yes
							PARSE_TRACE(_match)
							state:	ST_POP_RULE
						]
						sym = words/set [				;-- SET
							cmd: cmd + 1
							if any [cmd = tail TYPE_OF(cmd) <> TYPE_WORD][
								PARSE_ERROR [TO_ERROR(script parse-end) words/_set]
							]
							min:   R_NONE
							type:  R_SET
							state: ST_PUSH_RULE
						]
						sym = words/none [				;-- NONE
							match?: yes
							PARSE_TRACE(_match)
							state: ST_CHECK_PENDING
						]
						true [
							value: _context/get w
							if TYPE_OF(value) = TYPE_UNSET [
								PARSE_ERROR [TO_ERROR(script parse-rule) w]
							]
							state: either rule? [ 		;-- enable fast loops for word argument
								either TYPE_OF(value) = TYPE_WORD [ST_MATCH][ST_MATCH_RULE]
							][ST_DO_ACTION]
						]
					]
					rule?: no
				]
				ST_END [
					if match? [match?: cmd = tail]
					
					PARSE_SET_INPUT_LENGTH(cnt)
					if all [positive? part cnt > 0][cnt: part - input/head]
					if all [
						cnt > 0
						1 = block/rs-length? series
					][
						match?: no
					]
					PARSE_TRACE(_end)
					state: ST_EXIT
				]
			]
			state = ST_EXIT
		]
		reset saved?
		
		either collect? [
			base + 1
		][
			as red-value! logic/push match?
		]
	]

	init: does [
		series: block/make-in root 8
		rules:  block/make-in root 100
	]
]
