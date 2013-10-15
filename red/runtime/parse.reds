Red/System [
	Title:   "PARSE dialect interpreter"
	Author:  "Nenad Rakocevic"
	File: 	 %parse.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2013 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

parser: context [
	verbose: 0
	
	#define PUSH_RULE_INFO(low up flags) [
		t: as triple! ALLOC_TAIL(rules)
		t/header: TYPE_TRIPLE
		t/min:	  low
		t/max:	  up
		t/state:  flags
	]

	#enum states! [
		ST_PUSH_RULE
		ST_POP_RULE
		ST_DO_ACTION
		ST_NEXT_INPUT
		ST_NEXT_ACTION
		ST_MATCH
		ST_LOOP_MATCH
		ST_FIND_ALTERN
		ST_WORD
		ST_END
		ST_EXIT
	]
	
	#enum rule-flags! [
		R_NONE:		 -1
		R_TO:		 -2
		R_THRU:		 -3
		R_COPY:		 -4
		R_SET:		 -5
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
		pad    [integer!]
	]
	
	print-state: func [s [integer!]][
		print "state: "
		print-line switch s [
			ST_PUSH_RULE	 ["ST_PUSH_RULE"]
			ST_POP_RULE		 ["ST_POP_RULE"]
			ST_DO_ACTION	 ["ST_DO_ACTION"]
			ST_NEXT_INPUT	 ["ST_NEXT_INPUT"]
			ST_NEXT_ACTION	 ["ST_NEXT_ACTION"]
			ST_MATCH		 ["ST_MATCH"]
			ST_LOOP_MATCH	 ["ST_LOOP_MATCH"]
			ST_FIND_ALTERN	 ["ST_FIND_ALTERN"]
			ST_WORD			 ["ST_WORD"]
			ST_END			 ["ST_END"]
			ST_EXIT			 ["ST_EXIT"]
		]
	]
	
	skip-spaces: func [
		str		[red-string!]
		return:	[logic!]
		/local
			s	 [series!]
			unit [integer!]
			p	 [byte-ptr!]
			p4	 [int-ptr!]
			tail [byte-ptr!]
			cnt	 [integer!]
			c    [byte!]
	][
		s:	  GET_BUFFER(str)
		unit: GET_UNIT(s)
		p:    string/rs-head str
		tail: string/rs-tail str
		cnt: 0
		
		while [p < tail][							;-- jump over whitespaces
			c: as-byte switch unit [
				Latin1 [as-integer p/value]
				UCS-2  [(as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p p4/value]
			]
			if all [c <> #" " c <> #"^-" c <> #"^/" c <> #"^M"][
				str/head: str/head + cnt
				return no
			]
			cnt: cnt + 1
			p: p + unit
		]
		unless zero? cnt [str/head: str/head + cnt]
		yes
	]
	
	advance: func [
		str		[red-string!]
		value	[red-value!]							;-- char! or string! value
		over?	[logic!]
		return:	[logic!]
		/local
			end? [logic!]
	][
		end?: either TYPE_OF(value) = TYPE_CHAR [
			string/rs-next str
		][
			assert TYPE_OF(value) = TYPE_STRING
			string/rs-skip str string/rs-length? as red-string! value
		]
		if over? [end?: skip-spaces str]
		end?
	]
	
	find-altern: func [									;-- search for next '| symbol
		rule	[red-block!]
		return: [logic!]
		/local
			head  [red-value!]
			tail  [red-value!]
			value [red-value!]
			w	  [red-word!]
	][
		head:  block/rs-head rule
		tail:  block/rs-tail rule
		value: head
		
		while [value < tail][
			if TYPE_OF(value) = TYPE_WORD [
				w: as red-word! value
				if w/symbol = words/pipe [
					rule/head: rule/head + 1 + ((as-integer value - head) >> 4)
					return yes
				]
			]
			value: value + 1
		]
		no
	]
	
	take-last: func [
		stack   [red-block!]
		return: [red-series!]
		/local
			s [series!]
	][
		s: GET_BUFFER(stack)
		assert s/offset < (s/tail - 1)
		as red-series! s/tail - 1 
	]
	
	do-loop-token: func [
		input	[red-series!]
		token	[red-value!]
		min		[integer!]
		max		[integer!]
		over?	[logic!]
		return: [logic!]
		/local
			w	   [red-word!]
			len	   [integer!]
			cnt	   [integer!]
			type   [integer!]
			type-i [integer!]
			match? [logic!]
			end?   [logic!]
	][
		w: null
		type:   TYPE_OF(token)
		type-i: TYPE_OF(input)
		
		if type = TYPE_WORD [
			w: as red-word! token
			token: _context/get w
		]
		
		len: either any [						;TBD: replace with ANY_STRING
			type-i = TYPE_STRING
			type-i = TYPE_FILE
		][
			string/rs-length? as red-string! input
		][
			block/rs-length? as red-block! input
		]
		if len < min [return no]				;-- input too short
		
		case [
			type = TYPE_BITSET [
				--NOT_IMPLEMENTED--
			]
			all [								;-- SKIP special case
				w <> null
				words/skip = symbol/resolve w/symbol
			][
				match?: either max = R_NONE [yes][either len < max [no][len: max yes]]
				input/head: input/head + len
			]
			true [
				cnt: 0
				either any [					;TBD: replace with ANY_STRING
					type-i = TYPE_STRING
					type-i = TYPE_FILE
				][
					until [
						match?: string/match? as red-string! input token COMP_EQUAL
						end?: all [match? advance as red-string! input token over?]	;-- consume matched input
						cnt: cnt + 1
						any [
							not match?
							end?
							all [max <> R_NONE cnt >= max]
						]
					]
				][
					until [
						match?:	actions/compare block/rs-head input token COMP_EQUAL
						end?: all [match? block/rs-next input]	;-- consume matched input
						cnt: cnt + 1
						any [
							not match?
							end?
							all [max <> R_NONE cnt >= max]
						]
					]
				]	
				unless match? [
					cnt: cnt - 1
					match?: either max = R_NONE [min <= cnt][all [min <= cnt cnt <= max]]
				]
			]
		]
		match?
	]

	do-rule: func [	
		job		[red-block!]
		rule	[red-block!]
		over?	[logic!]
		case?	[logic!]
		return: [logic!]
		/local
			input  [red-series!]
			new	   [red-series!]
			series [red-block!]
			rules  [red-block!]
			int	   [red-integer!]
			int2   [red-integer!]
			cmd	   [red-value!]
			tail   [red-value!]
			value  [red-value!]
			dt	   [red-datatype!]
			w	   [red-word!]
			t 	   [triple!]
			p	   [positions!]
			state  [integer!]
			type   [integer!]
			sym	   [integer!]
			min	   [integer!]
			max	   [integer!]
			s	   [series!]
			cnt	   [integer!]
			upper? [logic!]
			end?   [logic!]
			match? [logic!]
			below? [logic!]
			loop?  [logic!]
	][
		int: as red-integer! block/rs-head job
		state:  int/value
		match?: yes
		end?:   no
		
		series: as red-block! int + 1
		rules:  as red-block! int + 2
		input:  as red-series! block/rs-head series
		
		PUSH_RULE_INFO(R_NONE R_NONE R_NONE)
		
		until [
			;#if debug = yes [
			if verbose > 0 [print-state state]
			;]
			
			switch state [
				ST_PUSH_RULE [
					p: as positions! ALLOC_TAIL(rules)
					p/header: TYPE_POSITIONS
					p/rule:	  rule/head					;-- save cmd position
					p/input:  input/head				;-- save input position
					
					rule: block/rs-append rules as red-value! rule
					cmd:  block/rs-head rule
					tail: block/rs-tail rule			;TBD: protect current rule block from changes
					state: either cmd = tail [ST_POP_RULE][ST_DO_ACTION]
				]
				ST_POP_RULE [
					either 3 = block/rs-length? rules [
						state: ST_END
					][
						loop?: no
						s: GET_BUFFER(rules)
						t: as triple! s/tail - 3
						
						either t/min <> R_NONE [
							cnt: t/state
							below?: cnt < t/min
							loop?: either t/max = R_NONE [match?][cnt < t/max]
							t/state: cnt + 1
							p: as positions! s/tail - 2
							rule/head: p/rule 			;-- reset rule start for new iteration
							unless match? [
								input/head: p/input
								match?: any [t/min <= cnt zero? t/min]
							]
						][
							switch t/state [
								R_TO 	[]
								R_THRU 	[]
								R_COPY 	[]
								R_SET 	[]
								default []				;-- R_NONE
							]
						]
						
						if any [end? not loop?][s/tail: s/tail - 3]	;-- pop rule stack frame
						
						rule: take-last rules
						cmd:  block/rs-head rule
						tail: block/rs-tail rule
						
						state: either end? [
							if all [t/min > 0 cnt < t/min][match?: no]
							either 3 = block/rs-length? rules [ST_NEXT_ACTION][ST_POP_RULE]
						][
							either loop? [ST_DO_ACTION][ST_NEXT_ACTION]
						]
					]
				]
				ST_DO_ACTION [
					type: TYPE_OF(cmd)
					switch type [
						TYPE_WORD 	[
							state: ST_WORD
						]
						TYPE_BLOCK 	[
							rule/head: rule/head + 
								((as-integer cmd - block/rs-head rule) >> 4) ;-- sync head with cmd
							rule: as red-block! cmd
							PUSH_RULE_INFO(R_NONE R_NONE R_NONE)
							state: ST_PUSH_RULE
						]	
						TYPE_SET_WORD [
							_context/set as red-word! cmd as red-value! input
							state: ST_NEXT_ACTION
						]
						TYPE_GET_WORD [
							new: as red-series! _context/get as red-word! cmd
							either all [
								TYPE_OF(new) = TYPE_OF(input)
								new/node = input/node
							][
								input/head: new/head
								state: ST_NEXT_ACTION
							][
								print-line "*** Parse Error: get-word refers to a different series!"
							]
						]
						TYPE_INTEGER [
							int:  as red-integer! cmd
							int2: as red-integer! cmd + 1
							upper?: TYPE_OF(int2) = TYPE_INTEGER
							if any [
								int2 = tail
								all [upper?	int2 + 1 = tail]
								all [upper? int/value > int2/value]
							][
								print-line "*** Parse Error: invalid integer rule"
							]
							min:   int/value
							max:   either upper? [cmd: cmd + 1 int2/value][min]
							type:  1
							state: ST_LOOP_MATCH
							
						]
						TYPE_PAREN [
							interpreter/eval as red-block! cmd
							state: ST_NEXT_ACTION
						]
						default [						;-- try to match a literal value
							state: ST_MATCH
						]
					]
				]
				ST_NEXT_INPUT [
					type: TYPE_OF(input)
					end?: either any [					;TBD: replace with ANY_STRING
						type = TYPE_STRING
						type = TYPE_FILE
					][
						string/rs-next as red-string! input
					][
						block/rs-next input
					]
					state: ST_NEXT_ACTION
				]
				ST_NEXT_ACTION [
					if cmd < tail [cmd: cmd + 1]
					
					state: either cmd = tail [
						either 3 = block/rs-length? rules [ST_END][ST_POP_RULE]
					][
						ST_DO_ACTION
					]
				]
				ST_MATCH [
					either end? [
						state: ST_POP_RULE
					][
						type: TYPE_OF(input)
						end?: either any [					;TBD: replace with ANY_STRING?
							type = TYPE_STRING
							type = TYPE_FILE
						][
							match?: string/match? as red-string! input cmd COMP_EQUAL
							all [match? advance as red-string! input cmd over?]	;-- consume matched input
						][
							match?: actions/compare block/rs-head input cmd COMP_EQUAL
							all [match? block/rs-next input]				;-- consume matched input
						]				
						state: either match? [ST_NEXT_ACTION][ST_FIND_ALTERN]
					]
				]
				ST_LOOP_MATCH [
					if cmd < tail [cmd: cmd + 1]
					
					either all [cmd = tail][
						state: either 3 = block/rs-length? rules [ST_END][ST_POP_RULE]
					][
						state: either TYPE_OF(cmd) = TYPE_BLOCK [
							rule/head: rule/head + 
								((as-integer cmd - block/rs-head rule) >> 4) ;-- sync head with cmd
							rule: as red-block! cmd
							PUSH_RULE_INFO(min max type)
							ST_PUSH_RULE
						][
							match?: do-loop-token input cmd min max over?
							either match? [ST_NEXT_ACTION][ST_FIND_ALTERN]
						]
					]
				]
				ST_FIND_ALTERN [
					state: either find-altern rule [
						cmd: block/rs-head rule			;-- rule head changed by find-altern
						ST_DO_ACTION
					][
						match?: no
						ST_POP_RULE
					]
				]
				ST_WORD [
					w: as red-word! cmd
					sym: symbol/resolve w/symbol
					case [								;TBD: order the words by decreasing usage frequency
						sym = words/pipe [				;-- |
							state: ST_POP_RULE
						]
						sym = words/skip [				;-- SKIP
							match?: not end?
							state: ST_NEXT_INPUT
						]
						sym = words/any* [				;-- ANY
							min:   0
							max:   R_NONE
							type:  1
							state: ST_LOOP_MATCH
						]
						sym = words/break* [			;-- BREAK
							match?: yes
							state: ST_POP_RULE
						]
						sym = words/copy [				;-- COPY

						]
						sym = words/end [				;-- END
							end?: yes
							type: TYPE_OF(input)
							match?: either any [					;TBD: replace with ANY_STRING
								type = TYPE_STRING
								type = TYPE_FILE
							][
								zero? string/rs-length? as red-string! input
							][					
								zero? block/rs-length? as red-block! input
							]					
							state: ST_NEXT_ACTION
						]
						sym = words/fail [				;-- FAIL
							match?: no
							state: ST_FIND_ALTERN
						]
						sym = words/into [				;-- INTO

						]
						sym = words/opt [				;-- OPT
							min:   0
							max:   1
							type:  1
							state: ST_LOOP_MATCH
						]
						sym = words/not* [				;-- NOT

						]
						sym = words/quote [				;-- QUOTE

						]
						sym = words/reject [			;-- REJECT
							match?: no
							state: ST_POP_RULE
						]
						sym = words/set [				;-- SET

						]
						sym = words/some [				;-- SOME
							min:   1
							max:   R_NONE
							type:  1
							state: ST_LOOP_MATCH
						]
						sym = words/thru [				;-- THRU

						]
						sym = words/to [				;-- TO

						]
						sym = words/none [				;-- NONE
							match?: yes
							state: ST_NEXT_ACTION
						]
						true [
							dt: as red-datatype! _context/get w
							switch TYPE_OF(dt) [
								TYPE_BLOCK [
									rule/head: rule/head + 
										((as-integer cmd - block/rs-head rule) >> 4) ;-- sync head with cmd
									rule: as red-block! dt
									PUSH_RULE_INFO(R_NONE R_NONE R_NONE)
									state: ST_PUSH_RULE
								]
								TYPE_DATATYPE [
									value: block/rs-head input
									match?: TYPE_OF(value) = dt/value
									state: either match? [ST_NEXT_INPUT][ST_FIND_ALTERN]
								]
								TYPE_BITSET [
									--NOT_IMPLEMENTED--
								]
								default [
									print-line [
										"*** Parse Error: datatype not supported:"
										TYPE_OF(dt)
									]
									halt
								]
							]
						]
					]
				]
				ST_END [
					if match? [match?: cmd = tail]
					type: TYPE_OF(input)
					
					cnt: either any [				;TBD: replace with ANY_STRING?
						type = TYPE_STRING
						type = TYPE_FILE
					][
						if over? [skip-spaces as red-string! input]
						string/rs-length? as red-string! input
					][
						block/rs-length? input
					]
					if any [
						cnt > 0
						1 < block/rs-length? series
					][
						match?: no
					]
					state: ST_EXIT
				]
			]
			state = ST_EXIT
		]
		match?
	]
	
	process: func [
		input [red-series!]
		rule  [red-block!]
		over?  [logic!]
		case? [logic!]
		;strict? [logic!]
		return: [logic!]
		/local
			job    [red-block!]
			series [red-block!]
	][
		job: block/push* 3
		integer/load-in job ST_PUSH_RULE			;-- pos 1: state
		series: block/make-in job 8					;-- pos 2: input stack block @@TBD: alloc statically
		block/make-in job 32						;-- pos 3: rule stack block  @@TBD: alloc statically
		
		input: block/rs-append series as red-value! input	;-- input now points to the series stack entry
		
		if all [
			over?
			any [									;TBD: replace with ANY_STRING
				TYPE_OF(input) = TYPE_STRING
				TYPE_OF(input) = TYPE_FILE
			]
		][
			skip-spaces as red-string! input
		]
		
		do-rule job rule over? case?
	]
]