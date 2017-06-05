Red/System [
	Title:   "Red native functions"
	Author:  "Nenad Rakocevic"
	File: 	 %natives.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define RETURN_NONE [
	stack/reset
	none/push-last
	exit
]

#define DO_EVAL_BLOCK [
	if expand? > 0 [
		job: #get system/build/config
		#call [preprocessor/expand as red-block! arg job]
	]
	either negative? next [
		interpreter/eval as red-block! arg yes
	][
		stack/keep
		blk: as red-block! stack/push arg
		pos: interpreter/eval-single arg
		blk: as red-block! copy-cell as red-value! blk slot
		blk/head: pos
	]
]

natives: context [
	verbose:  0
	lf?: 	  no										;-- used to print or not an ending newline
	last-lf?: no
	
	table: as int-ptr! 0
	top: 1
	
	buffer-blk: as red-block! 0

	register: func [
		[variadic]
		count	   [integer!]
		list	   [int-ptr!]
	][
		until [
			table/top: list/value
			top: top + 1
			assert top <= NATIVES_NB
			list: list + 1
			count: count - 1
			zero? count
		]
	]
	
	;--- Natives ----
	
	if*: func [check? [logic!]][
		#typecheck if
		either logic/false? [
			RETURN_NONE
		][
			interpreter/eval as red-block! stack/arguments + 1 yes
		]
	]
	
	unless*: func [check? [logic!]][
		#typecheck -unless-								;-- `unless` would be converted to `if not` by lexer
		either logic/false? [
			interpreter/eval as red-block! stack/arguments + 1 yes
		][
			RETURN_NONE
		]
	]
	
	either*: func [
		check? [logic!]
		/local offset [integer!]
	][
		#typecheck either
		offset: either logic/true? [1][2]
		interpreter/eval as red-block! stack/arguments + offset yes
	]
	
	any*: func [
		check? [logic!]
		/local
			value [red-value!]
			tail  [red-value!]
	][
		#typecheck any
		value: block/rs-head as red-block! stack/arguments
		tail:  block/rs-tail as red-block! stack/arguments
		
		while [value < tail][
			value: interpreter/eval-next value tail no
			if logic/true? [exit]
		]
		RETURN_NONE
	]
	
	all*: func [
		check? [logic!]
		/local
			value [red-value!]
			tail  [red-value!]
	][
		#typecheck all
		value: block/rs-head as red-block! stack/arguments
		tail:  block/rs-tail as red-block! stack/arguments
		
		if value = tail [RETURN_NONE]
		
		while [value < tail][
			value: interpreter/eval-next value tail no
			if logic/false? [RETURN_NONE]
		]
	]
	
	while*:	func [
		check? [logic!]
		/local
			cond  [red-block!]
			body  [red-block!]
	][
		#typecheck while
		cond: as red-block! stack/arguments
		body: as red-block! stack/arguments + 1
		
		stack/mark-loop words/_body
		while [
			interpreter/eval cond yes
			logic/true?
		][
			stack/reset
			catch RED_THROWN_BREAK [interpreter/eval body yes]
			switch system/thrown [
				RED_THROWN_BREAK	[system/thrown: 0 break]
				RED_THROWN_CONTINUE	[system/thrown: 0 continue]
				0 					[0]
				default				[re-throw]
			]
		]
		stack/unwind
		stack/reset
		unset/push-last
	]
	
	until*: func [
		check? [logic!]
		/local
			body  [red-block!]
	][
		#typecheck until
		body: as red-block! stack/arguments

		stack/mark-loop words/_body
		until [
			stack/reset
			catch RED_THROWN_BREAK	[interpreter/eval body yes]
			switch system/thrown [
				RED_THROWN_BREAK	[system/thrown: 0 break]
				RED_THROWN_CONTINUE	[system/thrown: 0 continue]
				0 					[0]
				default				[re-throw]
			]
			logic/true?
		]
		stack/unwind-last
	]
	
	loop*: func [
		[catch]
		check? [logic!]
		/local
			body  [red-block!]
			count [integer!]
			id 	  [integer!]
			saved [int-ptr!]
	][
		#typecheck loop
		count: integer/get*
		unless positive? count [RETURN_NONE]			;-- if counter <= 0, no loops
		body: as red-block! stack/arguments + 1
		
		stack/mark-loop words/_body		
		loop count [
			stack/reset
			saved: system/stack/top						;--	FIXME: solve loop/catch conflict
			interpreter/eval body yes
			system/stack/top: saved
			
			switch system/thrown [
				RED_THROWN_BREAK	[system/thrown: 0 break]
				RED_THROWN_CONTINUE	[system/thrown: 0 continue]
				0 					[0]
				default				[id: system/thrown throw id]
			]
		]
		stack/unwind-last
	]
	
	repeat*: func [
		check? [logic!]
		/local
			w	   [red-word!]
			body   [red-block!]
			count  [red-integer!]
			i	   [integer!]
	][
		#typecheck repeat
		
		w: 	   as red-word!    stack/arguments
		count: as red-integer! stack/arguments + 1
		body:  as red-block!   stack/arguments + 2
		
		i: integer/get as red-value! count
		unless positive? i [RETURN_NONE]				;-- if counter <= 0, no loops
		
		count/value: 1
	
		stack/mark-loop words/_body
		until [
			stack/reset
			_context/set w as red-value! count
			catch RED_THROWN_BREAK [interpreter/eval body yes]
			switch system/thrown [
				RED_THROWN_BREAK [system/thrown: 0 break]
				RED_THROWN_CONTINUE
				0 [
					system/thrown: 0
					count/value: count/value + 1
					i: i - 1
				]
				default	[re-throw]
			]
			zero? i
		]
		stack/unwind-last
	]
	
	forever*: func [
		check? [logic!]
		/local
			body  [red-block!]
	][
		#typecheck -forever-							;-- `forever` would be replaced by lexer
		body: as red-block! stack/arguments
		
		stack/mark-loop words/_body
		forever [
			catch RED_THROWN_BREAK	[interpreter/eval body no]
			switch system/thrown [
				RED_THROWN_BREAK	[system/thrown: 0 break]
				RED_THROWN_CONTINUE	[system/thrown: 0 continue]
				0 					[stack/pop 1]
				default				[re-throw]
			]
		]
		stack/unwind-last
	]
	
	foreach*: func [
		check? [logic!]
		/local
			value [red-value!]
			body  [red-block!]
			size  [integer!]
	][
		#typecheck foreach
		value: stack/arguments
		body: as red-block! stack/arguments + 2
		
		stack/push stack/arguments + 1					;-- copy arguments to stack top in reverse order
		stack/push value								;-- (required by foreach-next)
		
		stack/mark-loop words/_body
		stack/set-last unset-value
		
		either TYPE_OF(value) = TYPE_BLOCK [
			size: block/rs-length? as red-block! value
			
			while [foreach-next-block size][			;-- foreach [..]
				stack/reset
				catch RED_THROWN_BREAK	[interpreter/eval body no]
				switch system/thrown [
					RED_THROWN_BREAK	[system/thrown: 0 break]
					RED_THROWN_CONTINUE	[system/thrown: 0 continue]
					0 					[0]
					default				[re-throw]
				]
			]
		][
			while [foreach-next][						;-- foreach <word!>
				stack/reset
				catch RED_THROWN_BREAK	[interpreter/eval body no]
				switch system/thrown [
					RED_THROWN_BREAK	[system/thrown: 0 break]
					RED_THROWN_CONTINUE	[system/thrown: 0 continue]
					0 					[0]
					default				[re-throw]
				]
			]
		]
		stack/unwind-last
	]
	
	forall*: func [
		check? [logic!]
		/local
			w	   [red-word!]
			body   [red-block!]
			saved  [red-value!]
			series [red-series!]
			type   [integer!]
			break? [logic!]
	][
		#typecheck forall
		w:    as red-word!  stack/arguments
		body: as red-block! stack/arguments + 1
		
		saved: word/get w							;-- save series (for resetting on end)
		type: TYPE_OF(saved)
		unless ANY_SERIES?(type) [ERR_EXPECT_ARGUMENT(type 0)]
		
		w: word/push w								;-- word argument
		break?: no
		
		stack/mark-loop words/_body
		while [loop? as red-series! _context/get w][
			stack/reset
			catch RED_THROWN_BREAK	[interpreter/eval body no]
			switch system/thrown [
				RED_THROWN_BREAK	[system/thrown: 0 break?: yes break]
				RED_THROWN_CONTINUE	
				0 [
					series: as red-series! _context/get w
					series/head: series/head + 1
					if system/thrown = RED_THROWN_CONTINUE [
						system/thrown: 0
						continue
					]
				]
				default	[re-throw]
			]
		]
		stack/unwind-last
		unless break? [_context/set w saved]
	]
	
	remove-each*: func [
		check? [logic!]
		/local
			value  [red-value!]
			body   [red-block!]
			part   [red-integer!]
			size   [integer!]
			multi? [logic!]
	][
		#typecheck remove-each
		value: stack/arguments
		body: as red-block! stack/arguments + 2

		part: as red-integer! integer/push 0			;-- store number of words to set
		stack/push stack/arguments + 1					;-- copy arguments to stack top in reverse order
		stack/push value								;-- (required by foreach-next)

		stack/mark-loop words/_body
		multi?: TYPE_OF(value) = TYPE_BLOCK
		
		either multi? [
			size: block/rs-length? as red-block! value
			part/value: size
		][
			size: 1
		]
		while [either multi? [foreach-next-block size][foreach-next]][	;-- each [...] / each <word!>
			stack/reset
			catch RED_THROWN_BREAK	[interpreter/eval body no]
			switch system/thrown [
				RED_THROWN_BREAK	[system/thrown: 0 break]
				RED_THROWN_CONTINUE	[system/thrown: 0 continue]
				0 					[0]
				default				[re-throw]
			]
			remove-each-next size
		]
		stack/set-last unset-value
		stack/unwind-last
	]
	
	func*: func [check? [logic!]][
		#typecheck func
		_function/validate as red-block! stack/arguments
		_function/push 
			as red-block! stack/arguments
			as red-block! stack/arguments + 1
			null
			0
			null
		stack/set-last stack/top - 1
	]
	
	function*: func [check? [logic!]][
		#typecheck function
		_function/collect-words
			as red-block! stack/arguments
			as red-block! stack/arguments + 1
		func* check?
	]
	
	does*: func [check? [logic!]][
		#typecheck -does-								;-- `does` would be replaced by lexer
		copy-cell stack/arguments stack/push*
		block/make-at as red-block! stack/arguments 1
		func* check?
	]
	
	has*: func [
		check? [logic!]
		/local blk [red-block!]
	][
		#typecheck has
		blk: as red-block! stack/arguments
		block/insert-value blk as red-value! refinements/local
		blk/head: blk/head - 1
		func* check?
	]
		
	switch*: func [
		check?   [logic!]
		default? [integer!]
		/local
			pos	 [red-value!]
			end  [red-value!]
			alt	 [red-block!]
			blk  [red-block!]
			s	 [series!]
	][
		#typecheck [switch default?]
		
		pos: select-key* yes yes
		
		either TYPE_OF(pos) = TYPE_NONE [
			either negative? default? [
				RETURN_NONE
			][
				alt: as red-block! stack/arguments + 2
				interpreter/eval alt yes
				exit									;-- early exit with last value on stack
			]
		][
			if TYPE_OF(pos) = TYPE_BLOCK [
				stack/reset
				interpreter/eval as red-block! pos yes	;-- do the block
				exit									;-- early exit with last value on stack
			]
		]
		RETURN_NONE
	]
	
	case*: func [
		check?	  [logic!]
		all? 	  [integer!]
		/local
			value [red-value!]
			tail  [red-value!]
			true? [logic!]
	][
		#typecheck [case all?]
		value: block/rs-head as red-block! stack/arguments
		tail:  block/rs-tail as red-block! stack/arguments
		if value = tail [RETURN_NONE]

		true?: false
		while [value < tail][
			value: interpreter/eval-next value tail no	;-- eval condition
			if value = tail [break]
			either logic/true? [
				either TYPE_OF(value) = TYPE_BLOCK [	;-- if true, eval what follows it
					stack/reset
					interpreter/eval as red-block! value yes
					value: value + 1
				][
					value: interpreter/eval-next value tail no
				]
				if negative? all? [exit]				;-- early exit with last value on stack (unless /all)
				true?: yes
			][
				value: value + 1						;-- single value only allowed for cases bodies
			]
		]
		unless true? [RETURN_NONE]
	]
	
	do*: func [
		check?  [logic!]
		expand? [integer!]
		args 	[integer!]
		next	[integer!]
		return: [integer!]
		/local
			cframe [byte-ptr!]
			arg	   [red-value!]
			do-arg [red-value!]
			str	   [red-string!]
			slot   [red-value!]
			blk	   [red-block!]
			job	   [red-value!]
			pos	   [integer!]
	][
		#typecheck [do expand? args next]
		arg: stack/arguments
		cframe: stack/get-ctop							;-- save the current call frame pointer
		do-arg: stack/arguments + args
		
		if OPTION?(do-arg) [
			copy-cell do-arg #get system/script/args
		]
		if next > 0 [slot: _context/get as red-word! stack/arguments + next]
		
		catch RED_THROWN_BREAK [
			switch TYPE_OF(arg) [
				TYPE_BLOCK [DO_EVAL_BLOCK]
				TYPE_PATH  [
					interpreter/eval-path arg arg arg + 1 no no no no
					stack/set-last arg + 1
				]
				TYPE_STRING [
					str: as red-string! arg
					#call [system/lexer/transcode str none no]
					DO_EVAL_BLOCK
				]
				TYPE_URL 
				TYPE_FILE  [#call [do-file as red-file! arg]]
				TYPE_ERROR [
					stack/throw-error as red-object! arg
				]
				default [interpreter/eval-expression arg arg + 1 no no yes]
			]
		]
		switch system/thrown [
			RED_THROWN_BREAK
			RED_THROWN_CONTINUE
			RED_THROWN_RETURN
			RED_THROWN_EXIT [
				either stack/eval? cframe yes [			;-- if parent call is interpreted,
					re-throw 							;-- let the exception pass through
					0									;-- 0 to make compiler happy
				][
					system/thrown						;-- request an early exit from caller
				]
			]
			0			[0]
			default 	[re-throw 0]					;-- 0 to make compiler happy
		]
	]
	
	get*: func [
		check? [logic!]
		any?   [integer!]
		case?  [integer!]
		/local
			value [red-value!]
	][
		#typecheck [get any? case?]
		value: stack/arguments
		
		switch TYPE_OF(value) [
			TYPE_PATH
			TYPE_GET_PATH
			TYPE_SET_PATH
			TYPE_LIT_PATH [
				interpreter/eval-path value null null no yes no case? <> -1
			]
			TYPE_OBJECT [
				object/reflect as red-object! value words/values
			]
			default [
				value: _context/get as red-word! stack/arguments
				if all [any? = -1 TYPE_OF(value) = TYPE_UNSET][
					fire [TO_ERROR(script no-value) stack/arguments]
				]
				stack/set-last value
			]
		]
	]
	
	set*: func [
		check? [logic!]
		any?   [integer!]
		case?  [integer!]
		_only? [integer!]
		_some? [integer!]
		/local
			w	   [red-word!]
			value  [red-value!]
			res	   [red-value!]
			blk	   [red-block!]
			obj	   [red-object!]
			ctx	   [red-context!]
			old	   [red-value!]
			slot   [red-value!]
			type   [integer!]
			s	   [series!]
			node   [node!]
			only?  [logic!]
			some?  [logic!]
	][
		#typecheck [set any? case? _only? _some?]
		w: as red-word! stack/arguments
		value: stack/arguments + 1
		only?: _only? <> -1
		some?: _some? <> -1
		
		if all [any? = -1 TYPE_OF(value) = TYPE_UNSET][
			fire [TO_ERROR(script need-value) w]
		]
		
		switch TYPE_OF(w) [
			TYPE_PATH
			TYPE_GET_PATH
			TYPE_SET_PATH
			TYPE_LIT_PATH [
				value: stack/push stack/arguments
				copy-cell stack/arguments + 1 stack/arguments
				interpreter/eval-path value null null yes yes no case? <> -1
			]
			TYPE_OBJECT [
				object/set-many as red-object! w value only? some?
				stack/set-last value
			]
			TYPE_BLOCK [
				blk: as red-block! w
				set-many blk value block/rs-length? blk only? some?
				stack/set-last value
			]
			default [
				node: w/ctx
				ctx: TO_CTX(node)
				s: as series! ctx/self/value
				obj: as red-object! s/offset + 1
				
				either all [TYPE_OF(obj) = TYPE_OBJECT obj/on-set <> null][
					slot: _context/get w
					old: stack/push slot
					copy-cell value slot
					object/fire-on-set obj w old value
				][
					_context/set w value
				]
				stack/set-last value
			]
		]
	]

	print*: func [check? [logic!]][
		lf?: yes											;@@ get rid of this global state
		prin* check?
		lf?: no
		last-lf?: yes
	]
	
	prin*: func [
		check? [logic!]
		/local
			arg		[red-value!]
			str		[red-string!]
			blk		[red-block!]
			series	[series!]
			offset	[byte-ptr!]
			size	[integer!]
			unit	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/prin"]]
		#typecheck -prin-									;-- `prin` would be replaced by lexer
		arg: stack/arguments

		if TYPE_OF(arg) = TYPE_BLOCK [
			block/rs-clear buffer-blk
			stack/push as red-value! buffer-blk
			assert stack/top - 2 = stack/arguments			;-- check for correct stack layout
			reduce* no 1
			blk: as red-block! arg
			blk/head: 0										;-- head changed by reduce/into
		]

		actions/form* -1
		str: as red-string! stack/arguments
		assert any [
			TYPE_OF(str) = TYPE_STRING
			TYPE_OF(str) = TYPE_SYMBOL						;-- symbol! and string! structs are overlapping
		]
		series: GET_BUFFER(str)
		unit: GET_UNIT(series)
		offset: (as byte-ptr! series/offset) + (str/head << (log-b unit))
		size: as-integer (as byte-ptr! series/tail) - offset

		either lf? [
			switch unit [
				Latin1 [platform/print-line-Latin1 as c-string! offset size]
				UCS-2  [platform/print-line-UCS2 				offset size]
				UCS-4  [platform/print-line-UCS4   as int-ptr!  offset size]

				default [									;@@ replace by an assertion
					print-line ["Error: unknown string encoding: " unit]
				]
			]
		][
			switch unit [
				Latin1 [platform/print-Latin1 as c-string! offset size]
				UCS-2  [platform/print-UCS2   			   offset size]
				UCS-4  [platform/print-UCS4   as int-ptr!  offset size]

				default [									;@@ replace by an assertion
					print-line ["Error: unknown string encoding: " unit]
				]
			]
			fflush 0
		]
		last-lf?: no
		stack/set-last unset-value
	]
	
	equal?*: func [
		check?  [logic!]
		return: [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/equal?"]]
		actions/compare* COMP_EQUAL
	]
	
	not-equal?*: func [
		check?  [logic!]
		return: [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/not-equal?"]]
		actions/compare* COMP_NOT_EQUAL
	]
	
	strict-equal?*: func [
		check?  [logic!]
		return: [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/strict-equal?"]]
		actions/compare* COMP_STRICT_EQUAL
	]
	
	lesser?*: func [
		check?  [logic!]
		return: [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/lesser?"]]
		actions/compare* COMP_LESSER
	]
	
	greater?*: func [
		check?  [logic!]
		return: [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/greater?"]]
		actions/compare* COMP_GREATER
	]
	
	lesser-or-equal?*: func [
		check?  [logic!]
		return: [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/lesser-or-equal?"]]
		actions/compare* COMP_LESSER_EQUAL
	]	
	
	greater-or-equal?*: func [
		check?  [logic!]
		return: [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/greater-or-equal?"]]
		actions/compare* COMP_GREATER_EQUAL
	]
	
	same?: func [
		arg1    [red-value!]
		arg2    [red-value!]
		return:	[logic!]
		/local
			type   [integer!]
			res    [logic!]
	][
		type: TYPE_OF(arg1)
		res: false
		
		if type = TYPE_OF(arg2) [
			case [
				any [
					type = TYPE_DATATYPE
					type = TYPE_LOGIC
					type = TYPE_OBJECT
				][
					res: arg1/data1 = arg2/data1
				]
				any [
					type = TYPE_CHAR
					type = TYPE_INTEGER
					type = TYPE_BITSET
				][
					res: arg1/data2 = arg2/data2
				]
				ANY_SERIES?(type) [
					res: all [arg1/data1 = arg2/data1 arg1/data2 = arg2/data2]
				]
				type = TYPE_FLOAT	[
					res: all [arg1/data2 = arg2/data2 arg1/data3 = arg2/data3]
				]
				any [
					type = TYPE_NONE
					type = TYPE_UNSET
				][
					res: true
				]
				true [
					res: all [
						arg1/data1 = arg2/data1
						arg1/data2 = arg2/data2
						arg1/data3 = arg2/data3
					]
				]
			]
		]
		res
	]
	
	same?*: func [
		check?  [logic!]
		return:	[red-logic!]
		/local
			result [red-logic!]
			arg1   [red-value!]
			arg2   [red-value!]
	][
		arg1: stack/arguments
		arg2: arg1 + 1
		
		result: as red-logic! arg1
		result/value: same? arg1 arg2
		result/header: TYPE_LOGIC
		result
	]

	not*: func [
		check? [logic!]
		/local
			bool [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/not"]]
		
		bool: as red-logic! stack/arguments
		bool/value: logic/false?						;-- run test before modifying stack
		bool/header: TYPE_LOGIC
	]
	
	type?*: func [
		check?   [logic!]
		word?	 [integer!]
		return:  [red-value!]
		/local
			dt	 [red-datatype!]
			w	 [red-word!]
			name [names!]
	][
		#typecheck [type? word?]
		
		either negative? word? [
			dt: as red-datatype! stack/arguments		;-- overwrite argument
			dt/value: TYPE_OF(dt)						;-- extract type before overriding
			dt/header: TYPE_DATATYPE
			as red-value! dt
		][
			w: as red-word! stack/arguments				;-- overwrite argument
			name: name-table + TYPE_OF(w)				;-- point to the right datatype name record
			stack/set-last as red-value! name/word
		]
	]
	
	reduce*: func [
		check? [logic!]
		into   [integer!]
		/local
			value [red-value!]
			tail  [red-value!]
			arg	  [red-value!]
			into? [logic!]
			blk?  [logic!]
	][
		#typecheck [reduce into]
		arg: stack/arguments
		blk?: TYPE_OF(arg) = TYPE_BLOCK
		into?: into >= 0

		if blk? [
			value: block/rs-head as red-block! arg
			tail:  block/rs-tail as red-block! arg
		]

		stack/mark-native words/_body

		either into? [
			as red-block! stack/push arg + into
		][
			if blk? [block/push-only* (as-integer tail - value) >> 4]
		]

		either blk? [
			while [value < tail][
				value: interpreter/eval-next value tail yes
				either into? [actions/insert* -1 0 -1][block/append*]
				stack/keep									;-- preserve the reduced block on stack
			]
		][
			interpreter/eval-expression arg arg + 1 no yes no ;-- for non block! values
			if into? [actions/insert* -1 0 -1]
		]
		stack/unwind-last
	]
	
	compose-block: func [
		blk		[red-block!]
		deep?	[logic!]
		only?	[logic!]
		into	[red-block!]
		root?	[logic!]
		return: [red-block!]
		/local
			value  [red-value!]
			tail   [red-value!]
			new	   [red-block!]
			result [red-value!]
			into?  [logic!]
	][
		value: block/rs-head blk
		tail:  block/rs-tail blk
		into?: all [root? OPTION?(into)]

		new: either into? [
			into
		][
			block/push-only* (as-integer tail - value) >> 4	
		]
		while [value < tail][
			switch TYPE_OF(value) [
				TYPE_BLOCK [
					blk: either deep? [
						compose-block as red-block! value deep? only? into no
					][
						as red-block! value
					]
					either into? [
						block/insert-value new as red-value! blk
					][
						copy-cell as red-value! blk ALLOC_TAIL(new)
					]
				]
				TYPE_PAREN [
					blk: as red-block! value
					unless zero? block/rs-length? blk [
						interpreter/eval blk yes
						result: stack/arguments
						blk: as red-block! result 
						
						unless any [
							TYPE_OF(result) = TYPE_UNSET
							all [
								not only?
								TYPE_OF(result) = TYPE_BLOCK
								zero? block/rs-length? blk
							]
						][
							either any [
								only? 
								TYPE_OF(result) <> TYPE_BLOCK
							][
								either into? [
									block/insert-value new result
								][
									copy-cell result ALLOC_TAIL(new)
								]
							][
								either into? [
									block/insert-block new as red-block! result
								][
									block/rs-append-block new as red-block! result
								]
							]
						]
					]
				]
				default [
					either into? [
						block/insert-value new value
					][
						copy-cell value ALLOC_TAIL(new)
					]
				]
			]
			value: value + 1
		]
		new
	]
	
	compose*: func [
		check?  [logic!]
		deep	[integer!]
		only	[integer!]
		into	[integer!]
		/local
			arg	  [red-value!]
			into? [logic!]
	][
		#typecheck [compose deep only into]
		arg: stack/arguments
		either TYPE_OF(arg) <> TYPE_BLOCK [					;-- pass-thru for non block! values
			into?: into >= 0
			stack/mark-native words/_body
			if into? [as red-block! stack/push arg + into]
			interpreter/eval-expression arg arg + 1 no yes no
			if into? [actions/insert* -1 0 -1]
			stack/unwind-last
		][
			stack/set-last
				as red-value! compose-block
					as red-block! arg
					as logic! deep + 1
					as logic! only + 1
					as red-block! stack/arguments + into
					yes
		]
	]
	
	stats*: func [
		check?  [logic!]
		show	[integer!]
		info	[integer!]
		/local
			blk [red-block!]
	][
		#typecheck [stats show info]
		case [
			show >= 0 [
				;TBD
				integer/box memory/total
			]
			info >= 0 [
				blk: block/push* 5
				memory-info blk 2
				stack/set-last as red-value! blk
			]
			true [
				integer/box memory/total
			]
		]
	]
	
	bind*: func [
		check? [logic!]
		copy [integer!]
		/local
			value [red-value!]
			ref	  [red-value!]
			fun	  [red-function!]
			obj	  [node!]
			word  [red-word!]
			ctx	  [node!]
			self? [logic!]
			idx	  [integer!]
	][
		#typecheck [bind copy]
		value: stack/arguments
		ref: value + 1
		
		either any [
			TYPE_OF(ref) = TYPE_FUNCTION
			;TYPE_OF(ref) = TYPE_OBJECT
		][
			fun: as red-function! ref
			ctx: fun/ctx
		][
			word: as red-word! ref
			ctx: word/ctx
		]
		
		either TYPE_OF(value) = TYPE_BLOCK [
			obj: either TYPE_OF(ref) = TYPE_OBJECT [
				self?: yes
				object/save-self-object as red-object! ref
			][
				self?: no
				null
			]
			either negative? copy [
				_context/bind as red-block! value TO_CTX(ctx) obj self?
			][
				stack/set-last 
					as red-value! _context/bind
						block/clone as red-block! value yes no
						TO_CTX(ctx)
						obj
						self?
			]
		][
			word: as red-word! value
			idx: _context/find-word TO_CTX(ctx) word/symbol no
			if idx <> -1 [
				word/ctx: ctx
				word/index: idx
			]
		]
	]
	
	in*: func [
		check? [logic!]
		/local
			obj  [red-object!]
			ctx  [red-context!]
			word [red-word!]
			res	 [red-value!]
	][
		#typecheck in
		obj:  as red-object! stack/arguments
		word: as red-word! stack/arguments + 1
		ctx: GET_CTX(obj)
		
		switch TYPE_OF(word) [
			TYPE_WORD
			TYPE_GET_WORD
			TYPE_SET_WORD
			TYPE_LIT_WORD
			TYPE_REFINEMENT [
				either negative? _context/bind-word ctx word [
					res: as red-value! none-value
				][
					res: as red-value! word
				]
				stack/set-last res
			]
			TYPE_BLOCK
			TYPE_PAREN [
				0
			]
			default [0]
		]
	]

	parse*: func [
		check?  [logic!]
		case?	[integer!]
		;strict? [integer!]
		part	[integer!]
		trace	[integer!]
		return: [integer!]
		/local
			op	   [integer!]
			input  [red-series!]
			limit  [red-series!]
			int	   [red-integer!]
			res	   [red-value!]
			cframe [byte-ptr!]
	][
		#typecheck [parse case? part trace]
		op: either as logic! case? + 1 [COMP_STRICT_EQUAL][COMP_EQUAL]
		
		input: as red-series! stack/arguments
		limit: as red-series! stack/arguments + part
		part: 0
		
		if OPTION?(limit) [
			part: either TYPE_OF(limit) = TYPE_INTEGER [
				int: as red-integer! limit
				int/value + input/head
			][
				unless all [
					TYPE_OF(limit) = TYPE_OF(input)
					limit/node = input/node
				][
					ERR_INVALID_REFINEMENT_ARG(refinements/_part limit)
				]
				limit/head
			]
			if part <= 0 [
				logic/box zero? either any [
					TYPE_OF(input) = TYPE_STRING		;@@ replace with ANY_STRING?
					TYPE_OF(input) = TYPE_FILE
					TYPE_OF(input) = TYPE_URL
					TYPE_OF(input) = TYPE_TAG
					TYPE_OF(input) = TYPE_EMAIL
				][
					string/rs-length? as red-string! input
				][
					block/rs-length? as red-block! input
				]
				return 0
			]
		]
		cframe: stack/get-ctop							;-- save the current call frame pointer
		
		catch RED_THROWN_BREAK [
			res: parser/process
				input
				as red-block! stack/arguments + 1
				op
				;as logic! strict? + 1
				part
				as red-function! stack/arguments + trace
		]
		switch system/thrown [
			RED_THROWN_BREAK
			RED_THROWN_CONTINUE
			RED_THROWN_RETURN
			RED_THROWN_EXIT [
				either stack/eval? cframe yes [			;-- if parent call is interpreted,
					re-throw 							;-- let the exception pass through
					0									;-- 0 to make compiler happy
				][
					system/thrown						;-- request an early exit from caller
				]
			]
			0			[stack/set-last res 0]			;-- 0 to make compiler happy
			default 	[re-throw 0]					;-- 0 to make compiler happy
		]
	]

	do-set-op: func [
		cased	 [integer!]
		skip	 [integer!]
		op		 [integer!]
		/local
			set1	 [red-value!]
			set2	 [red-value!]
			skip-arg [red-value!]
			type	 [integer!]
			case?	 [logic!]
	][
		set1: stack/arguments
		set2: set1 + 1
		type: TYPE_OF(set1)

		if all [
			op <> OP_UNIQUE
			type <> TYPE_OF(set2)
		][
			fire [TO_ERROR(script expect-val) datatype/push type datatype/push TYPE_OF(set2)]
		]
		skip-arg: set1 + skip
		case?:	  as logic! cased + 1

		switch type [
			TYPE_BLOCK   
			TYPE_HASH    [block/do-set-op case? as red-integer! skip-arg op]
			TYPE_STRING  [string/do-set-op case? as red-integer! skip-arg op]
			TYPE_BITSET  [bitset/do-bitwise op]
			TYPE_TYPESET [typeset/do-bitwise op]
			default 	 [ERR_EXPECT_ARGUMENT(type 1)]
		]
	]
	
	union*: func [
		check? [logic!]
		cased  [integer!]
		skip   [integer!]
	][
		#typecheck [union cased skip]
		do-set-op cased skip OP_UNION
	]
	
	intersect*: func [
		check? [logic!]
		cased  [integer!]
		skip   [integer!]
	][
		#typecheck [intersect cased skip]
		do-set-op cased skip OP_INTERSECT
	]
	
	unique*: func [
		check? [logic!]
		cased  [integer!]
		skip   [integer!]
	][
		#typecheck [unique cased skip]
		do-set-op cased skip OP_UNIQUE
	]
	
	difference*: func [
		check? [logic!]
		cased  [integer!]
		skip   [integer!]
	][
		#typecheck [difference cased skip]
		do-set-op cased skip OP_DIFFERENCE
	]

	exclude*: func [
		check? [logic!]
		cased  [integer!]
		skip   [integer!]
	][
		#typecheck [exclude cased skip]
		do-set-op cased skip OP_EXCLUDE
	]

	complement?*: func [
		check?  [logic!]
		return: [red-logic!]
		/local
			bits   [red-bitset!]
			s	   [series!]
			result [red-logic!]
	][
		#typecheck complement
		bits: as red-bitset! stack/arguments
		s: GET_BUFFER(bits)
		result: as red-logic! bits

		either TYPE_OF(bits) =  TYPE_BITSET [
			result/value: s/flags and flag-bitset-not = flag-bitset-not
		][
			ERR_EXPECT_ARGUMENT((TYPE_OF(bits)) 1)
		]

		result/header: TYPE_LOGIC
		result
	]

	dehex*: func [
		check?  [logic!]
		return: [red-string!]
		/local
			str		[red-string!]
			buffer	[red-string!]
			s		[series!]
			p		[byte-ptr!]
			p4		[int-ptr!]
			tail	[byte-ptr!]
			unit	[integer!]
			cp		[integer!]
			len		[integer!]
	][
		#typecheck dehex
		str: as red-string! stack/arguments
		s: GET_BUFFER(str)
		unit: GET_UNIT(s)
		p: (as byte-ptr! s/offset) + (str/head << (log-b unit))
		tail: as byte-ptr! s/tail
		if p = tail [return str]						;-- empty string case

		len: string/rs-length? str
		stack/keep										;-- keep last value
		buffer: string/rs-make-at stack/push* len * unit

		while [p < tail][
			cp: switch unit [
				Latin1 [as-integer p/value]
				UCS-2  [(as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p p4/value]
			]

			p: p + unit
			if all [
				cp = as-integer #"%"
				p + unit < tail							;-- must be %xx
			][
				p: string/decode-utf8-hex p unit :cp false
			]
			string/append-char GET_BUFFER(buffer) cp unit
		]
		stack/set-last as red-value! buffer
		buffer
	]

	debase*: func [
		check?   [logic!]
		base-arg [integer!]
		/local
			data [red-string!]
			int  [red-integer!]
			base [integer!]
			s	 [series!]
			p	 [byte-ptr!]
			len  [integer!]
			unit [integer!]
			ret  [red-binary!]
	][
		#typecheck [debase base-arg]
		data: as red-string! stack/arguments
		base: either positive? base-arg [
			int: as red-integer! data + 1
			int/value
		][64]

		s:  GET_BUFFER(data)
		unit: GET_UNIT(s)
		p:	  string/rs-head data
		len:  string/rs-length? data

		ret: as red-binary! data
		ret/head: 0
		ret/header: TYPE_BINARY
		ret/node: switch base [
			16 [binary/decode-16 p len unit]
			2  [binary/decode-2  p len unit]
			64 [binary/decode-64 p len unit]
			default [fire [TO_ERROR(script invalid-arg) int] null]
		]
		if ret/node = null [ret/header: TYPE_NONE]				;- RETURN_NONE
	]

	enbase*: func [
		check?   [logic!]
		base-arg [integer!]
		/local
			data [red-string!]
			int  [red-integer!]
			base [integer!]
			p	 [byte-ptr!]
			len  [integer!]
			ret  [red-binary!]
	][
		#typecheck [enbase base-arg]
		data: as red-string! stack/arguments
		base: either positive? base-arg [
			int: as red-integer! data + 1
			int/value
		][64]

		p: either TYPE_OF(data) = TYPE_STRING [
			len: -1
			as byte-ptr! unicode/to-utf8 data :len
		][
			len: binary/rs-length? as red-binary! data
			binary/rs-head as red-binary! data
		]

		ret: as red-binary! data
		ret/head: 0
		ret/header: TYPE_STRING
		ret/node: switch base [
			64 [binary/encode-64 p len]
			16 [binary/encode-16 p len]
			2  [binary/encode-2  p len]
			default [fire [TO_ERROR(script invalid-arg) int] null]
		]
		if ret/node = null [ret/header: TYPE_NONE]				;- RETURN_NONE
	]

	negative?*: func [
		check?  [logic!]
		return:	[red-logic!]
		/local
			num [red-integer!]
			f	[red-float!]
			res [red-logic!]
	][
		#typecheck -negative?-							;-- `negative?` would be replaced by lexer
		res: as red-logic! stack/arguments
		switch TYPE_OF(res) [							;@@ Add money! pair!
			TYPE_INTEGER [
				num: as red-integer! res
				res/value: negative? num/value
			]
			TYPE_FLOAT TYPE_TIME TYPE_PERCENT [
				f: as red-float! res
				res/value: f/value < 0.0
			]
			default [ERR_EXPECT_ARGUMENT((TYPE_OF(res)) 1)]
		]
		res/header: TYPE_LOGIC
		res
	]

	positive?*: func [
		check?  [logic!]
		return: [red-logic!]
		/local
			num [red-integer!]
			f	[red-float!]
			res [red-logic!]
	][
		#typecheck -positive?-							;-- `positive?` would be replaced by lexer
		res: as red-logic! stack/arguments
		switch TYPE_OF(res) [							;@@ Add money! pair!
			TYPE_INTEGER [
				num: as red-integer! res
				res/value: positive? num/value
			]
			TYPE_FLOAT TYPE_TIME TYPE_PERCENT [
				f: as red-float! res
				res/value: f/value > 0.0
			]
			default [ERR_EXPECT_ARGUMENT((TYPE_OF(res)) 1)]
		]
		res/header: TYPE_LOGIC
		res
	]

	sign?*: func [
		check?  [logic!]
		return: [red-integer!]
		/local
			i   [red-integer!]
			f	[red-float!]
			res [red-value!]
			ret [integer!]
	][
		#typecheck sign?
		res: stack/arguments
		ret: 0
		switch TYPE_OF(res) [							;@@ Add money! pair! 
			TYPE_INTEGER [
				i: as red-integer! stack/arguments
				ret: case [
					i/value > 0 [ 1]
					i/value < 0 [-1]
					i/value = 0 [ 0]
				]
			]
			TYPE_FLOAT TYPE_TIME TYPE_PERCENT [
				f: as red-float! stack/arguments
				ret: case [
					f/value > 0.0 [ 1]
					f/value < 0.0 [-1]
					f/value = 0.0 [ 0]
				]
			]
			default [ERR_EXPECT_ARGUMENT((TYPE_OF(res)) 1)]
		]
		integer/box ret
	]

	max*: func [check? [logic!]][
		#typecheck -max-								;-- `max` would be replaced by lexer
		max-min true
	]

	min*: func [check? [logic!]][
		#typecheck -min-								;-- `min` would be replaced by lexer
		max-min false
	]

	shift*: func [
		check?	[logic!]
		left	[integer!]
		logical	[integer!]
		/local
			data [red-integer!]
			bits [red-integer!]
	][
		#typecheck [shift left logical]
		data: as red-integer! stack/arguments
		bits: data + 1
		case [
			left >= 0 [
				data/value: data/value << bits/value
			]
			logical >= 0 [
				data/value: data/value >>> bits/value
			]
			true [
				data/value: data/value >> bits/value
			]
		]
	]

	to-hex*: func [
		check? [logic!]
		size   [integer!]
		/local
			arg	  [red-integer!]
			limit [red-integer!]
			buf   [red-word!]
			p	  [c-string!]
			part  [integer!]
	][
		#typecheck [to-hex size]
		arg: as red-integer! stack/arguments
		limit: arg + size

		p: string/to-hex arg/value no
		part: either OPTION?(limit) [8 - limit/value][0]
		if negative? part [part: 0]
		buf: issue/load p + part

		stack/set-last as red-value! buf
	]

	sine*: func [
		check?  [logic!]
		radians [integer!]
		/local
			f	[red-float!]
	][
		#typecheck [sine radians]
		f: degree-to-radians* radians TYPE_SINE
		f/value: sin f/value
		if DBL_EPSILON > float/abs f/value [f/value: 0.0]
		f
	]

	cosine*: func [
		check?  [logic!]
		radians [integer!]
		/local
			f	[red-float!]
	][
		#typecheck [cosine radians]
		f: degree-to-radians* radians TYPE_COSINE
		f/value: cos f/value
		if DBL_EPSILON > float/abs f/value [f/value: 0.0]
		f
	]

	tangent*: func [
		check?  [logic!]
		radians [integer!]
		/local
			f	[red-float!]
	][
		#typecheck [tangent radians]
		f: degree-to-radians* radians TYPE_TANGENT
		either (float/abs f/value) = (PI / 2.0) [
			fire [TO_ERROR(math overflow)]
		][
			f/value: tan f/value
		]
		f
	]

	arcsine*: func [
		check?  [logic!]
		radians [integer!]
	][
		#typecheck [arcsine radians]
		arc-trans radians TYPE_SINE
	]

	arccosine*: func [
		check?  [logic!]
		radians [integer!]
	][
		#typecheck [arccosine radians]
		arc-trans radians TYPE_COSINE
	]

	arctangent*: func [
		check?  [logic!]
		radians [integer!]
	][
		#typecheck [arctangent radians]
		arc-trans radians TYPE_TANGENT
	]

	arctangent2*: func [
		check? [logic!]
		/local
			f	[red-float!]
			n	[red-integer!]
			x	[float!]
			y	[float!]
	][
		#typecheck [arctangent2 radians]
		f: as red-float! stack/arguments 
		either TYPE_OF(f) <> TYPE_FLOAT [
			n: as red-integer! f
			y: as-float n/value
		][
			y: f/value
		]
		f: as red-float! stack/arguments + 1
		either TYPE_OF(f) <> TYPE_FLOAT [
			n: as red-integer! f
			x: as-float n/value
			f/header: TYPE_FLOAT
		][
			x: f/value
		]
		f/value: atan2 y x
		stack/set-last as red-value! f
	]

	NaN?*: func [
		check?  [logic!]
		return: [red-logic!]
		/local
			f	 [red-float!]
			ret  [red-logic!]
	][
		#typecheck NaN?
		f: as red-float! stack/arguments
		ret: as red-logic! f
		ret/value: float/NaN? f/value
		ret/header: TYPE_LOGIC
		ret
	]

	zero?*: func [
		check?  [logic!]
		return: [red-logic!]
		/local
			i	 [red-integer!]
			f	 [red-float!]
			p	 [red-pair!]
			ret  [red-logic!]
	][
		#typecheck -zero?- 								;-- `zero?` would be converted to `0 =` by lexer
		i: as red-integer! stack/arguments
		ret: as red-logic! i
		ret/value: switch TYPE_OF(i) [
			TYPE_INTEGER
			TYPE_CHAR [
				i/value = 0
			]
			TYPE_FLOAT
			TYPE_PERCENT
			TYPE_TIME [
				f: as red-float! i
				f/value = 0.0
			]
			TYPE_PAIR [
				p: as red-pair! i
				all [p/x = 0 p/y = 0]
			]
			TYPE_TUPLE [
				tuple/all-zero? as red-tuple! i
			]
			default [false]
		]
		ret/header: TYPE_LOGIC
		ret
	]
	
	size?*: func [
		check?  [logic!]
		/local
			name [red-file!]
			fd	 [integer!]
	][
		name: as red-file! stack/arguments
		fd: simple-io/open-file file/to-OS-path name simple-io/RIO_READ yes
		either fd < 0 [
			none/push-last
		][
			integer/box simple-io/file-size? fd
			simple-io/close-file fd
		]
	]

	log-2*: func [
		check? [logic!]
		/local
			f  [red-float!]
	][
		#typecheck log-2
		f: argument-as-float
		f/value: (log-2 f/value) / 0.6931471805599453
	]

	log-10*: func [
		check? [logic!]
		/local
			f  [red-float!]
	][
		#typecheck log-10
		f: argument-as-float
		f/value: log-10 f/value
	]

	log-e*: func [
		check? [logic!]
		/local
			f  [red-float!]
	][
		#typecheck log-e
		f: argument-as-float
		f/value: log-2 f/value
	]

	exp*: func [
		check? [logic!]
		/local
			f  [red-float!]
	][
		#typecheck exp
		f: argument-as-float
		f/value: pow 2.718281828459045235360287471 f/value
	]

	square-root*: func [
		check? [logic!]
		/local
			f  [red-float!]
	][
		#typecheck square-root
		f: argument-as-float
		f/value: sqrt f/value
	]
	
	construct*: func [
		check? [logic!]
		_with  [integer!]
		only   [integer!]
		/local
			proto [red-object!]
	][
		#typecheck [construct _with only]
		proto: either _with >= 0 [as red-object! stack/arguments + 1][null]
		
		stack/set-last as red-value! object/construct
			as red-block! stack/arguments
			proto
			only >= 0
	]

	value?*: func [
		check? [logic!]
		/local
			value  [red-value!]
			result [red-logic!]
	][
		#typecheck value?
		value: stack/arguments
		if TYPE_OF(value) = TYPE_WORD [
			value: _context/get as red-word! stack/arguments
		]
		result: as red-logic! stack/arguments
		result/value: TYPE_OF(value) <> TYPE_UNSET
		result/header: TYPE_LOGIC
		result
	]
	
	handle-thrown-error: func [
		/local
			err	[red-object!]
			id  [integer!]
	][
		err: as red-object! stack/top - 1
		assert TYPE_OF(err) = TYPE_ERROR
		id: error/get-type err
		either id = words/errors/throw/symbol [			;-- check if error is of type THROW
			re-throw 									;-- let the error pass through
		][
			stack/adjust-post-try
		]
	]
	
	try*: func [
		check?  [logic!]
		_all	[integer!]
		return: [integer!]
		/local
			arg	   [red-value!]
			cframe [byte-ptr!]
			result [integer!]
	][
		#typecheck [try _all]
		arg: stack/arguments
		system/thrown: 0								;@@ To be removed
		cframe: stack/get-ctop							;-- save the current call frame pointer
		result: 0
		
		either _all = -1 [
			stack/mark-try words/_try
		][
			stack/mark-try-all words/_try
		]
		catch RED_THROWN_ERROR [
			interpreter/eval as red-block! arg yes
			stack/unwind-last							;-- bypass it in case of error
		]
		either _all = -1 [
			switch system/thrown [
				RED_THROWN_BREAK
				RED_THROWN_CONTINUE
				RED_THROWN_RETURN
				RED_THROWN_EXIT [
					either stack/eval? cframe yes [		;-- if parent call is interpreted,
						re-throw 						;-- let the exception pass through
					][
						result: system/thrown			;-- request an early exit from caller
					]
				]
				RED_THROWN_ERROR [
					handle-thrown-error
				]
				0		[stack/adjust-post-try]
				default [re-throw]
			]
		][												;-- TRY/ALL case, catch everything
			stack/adjust-post-try
		]
		system/thrown: 0
		result
	]

	uppercase*: func [
		check? [logic!]
		part [integer!]
	][
		#typecheck [uppercase part]
		case-folding/change-case stack/arguments part yes
	]

	lowercase*: func [
		check? [logic!]
		part [integer!]
	][
		#typecheck [lowercase part]
		case-folding/change-case stack/arguments part no
	]
	
	as-pair*: func [
		check? [logic!]
		/local
			pair [red-pair!]
			arg	 [red-value!]
			int  [red-integer!]
			fl	 [red-float!]
	][
		#typecheck as-pair
		arg: stack/arguments
		pair: as red-pair! arg
		
		switch TYPE_OF(arg) [
			TYPE_INTEGER [
				int: as red-integer! arg
				pair/x: int/value
			]
			TYPE_FLOAT	 [
				fl: as red-float! arg
				pair/x: as-integer fl/value
			]
			default		 [assert false]
		]
		arg: arg + 1
		switch TYPE_OF(arg) [
			TYPE_INTEGER [
				int: as red-integer! arg
				pair/y: int/value
			]
			TYPE_FLOAT	 [
				fl: as red-float! arg
				pair/y: as-integer fl/value
			]
			default		[assert false]
		]
		pair/header: TYPE_PAIR
	]
	
	break*: func [check? [logic!] returned [integer!]][
		#typecheck [break returned]
		stack/throw-break returned <> -1 no
	]
	
	continue*: func [check? [logic!]][
		#typecheck continue
		stack/throw-break no yes
	]
	
	exit*: func [check? [logic!]][
		#typecheck exit
		stack/throw-exit no
	]
	
	return*: func [check? [logic!]][
		#typecheck return
		stack/throw-exit yes
	]
	
	throw*: func [
		check? [logic!]
		name   [integer!]
	][
		#typecheck [throw name]
		if name = -1 [unset/push]						;-- fill this slot anyway for CATCH		
		stack/throw-throw RED_THROWN_THROW
	]
	
	catch*: func [
		check? [logic!]
		name   [integer!]
		/local
			arg	   [red-value!]
			c-name [red-word!]
			t-name [red-word!]
			word   [red-word!]
			tail   [red-word!]
			found? [logic!]
	][
		#typecheck [catch name]
		found?: no
		arg: stack/arguments
		
		if name <> -1 [c-name: as red-word! arg + name]
		
		stack/mark-catch words/_body
		catch RED_THROWN_THROW [interpreter/eval as red-block! arg yes]
		t-name: as red-word! stack/arguments + 1
		stack/unwind-last
		
		if system/thrown > 0 [
			if system/thrown <> RED_THROWN_THROW [re-throw]
			if name <> -1 [
				either TYPE_OF(t-name) = TYPE_WORD [
					either TYPE_OF(c-name) = TYPE_BLOCK [
						word: as red-word! block/rs-head as red-block! c-name
						tail: as red-word! block/rs-tail as red-block! c-name
						while [word < tail][
							if TYPE_OF(word) <> TYPE_WORD [
								fire [TO_ERROR(script invalid-refine-arg) words/_name c-name]
							]
							if EQUAL_WORDS?(t-name word) [found?: yes break]
							word: word + 1
						]
					][
						found?: EQUAL_WORDS?(t-name c-name)
					]
				][
					found?: no							;-- THROW with no /NAME refinement
				]
				unless found? [
					copy-cell as red-value! t-name stack/arguments + 1 ;-- ensure t-name is at args + 1
					stack/ctop: stack/ctop - 1			;-- skip the current CATCH call frame
					stack/throw-throw RED_THROWN_THROW
				]
			]
			system/thrown: 0
			stack/set-last stack/top - 1
			stack/top: stack/arguments + 1
		]
	]
	
	extend*: func [
		check? [logic!]
		case?  [integer!]
		/local
			arg [red-value!]
	][
		#typecheck [extend case?]
		arg: stack/arguments
		switch TYPE_OF(arg) [
			TYPE_MAP 	[
				map/extend
					as red-hash! arg
					as red-block! arg + 1
					case? <> -1
			]
			TYPE_OBJECT [--NOT_IMPLEMENTED--]
		]
	]

	to-local-file*: func [
		check? [logic!]
		full?  [integer!]
		/local
			src  [red-file!]
			out  [red-string!]
	][
		#typecheck [to-local-file full?]
		src: as red-file! stack/arguments
		out: string/rs-make-at stack/push* string/rs-length? as red-string! src
		file/to-local-path src out full? <> -1
		stack/set-last as red-value! out
	]

	wait*: func [
		check?	[logic!]
		all?	[integer!]
		;only?	[integer!]
		/local
			val		[red-float!]
			int		[red-integer!]
			time	[integer!]
			ftime	[float!]
	][
		#typecheck [wait all?] ;only?]
		val: as red-float! stack/arguments
		switch TYPE_OF(val) [
			TYPE_INTEGER [
				int: as red-integer! val
				time: int/value * #either OS = 'Windows [1000][1000000]
			]
			TYPE_FLOAT [
				ftime: val/value * #either OS = 'Windows [1000.0][1000000.0]
				if ftime < 1.0 [ftime: 1.0]
				time: as-integer ftime
			]
			TYPE_TIME [
				time: as-integer (val/value / #either OS = 'Windows [1E6][1E3])
			]
			default [fire [TO_ERROR(script invalid-arg) val]]
		]
		val/header: TYPE_NONE
		platform/wait time
	]

	checksum*: func [
		check?		[logic!]
		_with		[integer!]
		/local
			arg		[red-value!]
			str		[red-string!]
			method	[red-word!]
			type	[integer!]
			data	[byte-ptr!]
			len		[integer!]
			spec	[red-value!]
			key		[byte-ptr!]
			key-len [integer!]
			hash-size [red-integer!]
			b		[byte-ptr!]
	][
		#typecheck [checksum _with]
		arg: stack/arguments
		len: -1
		if TYPE_OF(arg) = TYPE_FILE [
			arg: simple-io/read as red-file! arg null null yes no
			;@@ optimization: free the data after checksum
		]
		switch TYPE_OF(arg) [
			TYPE_STRING [
				str: as red-string! arg
				;-- Passing len of -1 tells to-utf8 to convert all chars,
				;	and it mods len to hold the length of the UTF8 result.
				data: as byte-ptr! unicode/to-utf8 str :len
				;-- len now contains the decoded data length.
			]
			TYPE_BINARY [
				data: binary/rs-head as red-binary! arg
				len: binary/rs-length? as red-binary! arg
			]
			default [
				fire [TO_ERROR(script invalid-arg) stack/arguments]
			]
		]

		arg: stack/arguments
		method: as red-word! arg + 1
		type: symbol/resolve method/symbol

		if not crypto/known-method? type [
			fire [TO_ERROR(script invalid-arg) method]
		]

		;-- Trying to use /with in combination with TCP or CRC32 is an error.
		if all [
			_with >= 0
			any [type = crypto/_crc32  type = crypto/_tcp]
		][
			ERR_INVALID_REFINEMENT_ARG((refinement/load "with") method)
		]
		
		;-- TCP and CRC32 ignore [/with spec] entirely. For these methods
		;	we process them and exit. No other dispatching needed.
		if type = crypto/_crc32 [integer/box crypto/CRC32 data len   exit]
		if type = crypto/_tcp   [integer/box crypto/CRC_IP data len  exit]

		
		either _with >= 0 [								;-- /with was used
			spec: arg + _with
			switch TYPE_OF(spec) [
				TYPE_STRING TYPE_BINARY [
					if type = crypto/_hash [
						;-- /with 'spec arg for 'hash method must be an integer.
						ERR_INVALID_REFINEMENT_ARG((refinement/load "with") spec)
					]
					;-- If we get here, the method returns an HMAC (MD5 or SHA*).
					either TYPE_OF(spec) = TYPE_STRING [
						key-len: -1							;-- Tell to-utf8 to decode everything
						key: as byte-ptr! unicode/to-utf8 as red-string! arg + _with :key-len
					][
						key-len: binary/rs-length? as red-binary! arg + _with
						key: binary/rs-head as red-binary! arg + _with
					]
					;-- key-len now contains the decoded key length
					b: crypto/get-hmac data len key key-len type
					;!! len is reused here, set to the expected digest size.
					;!! You can't set it before calling get-hmac.
					len: crypto/alg-digest-size crypto/alg-from-symbol type
					stack/set-last as red-value! binary/load b len
					free b
				]
				TYPE_INTEGER [
					hash-size: as red-integer! arg + _with
					integer/box crypto/HASH_STRING data len hash-size/value
				]
				default [
					fire [TO_ERROR(script invalid-arg) spec]
				]
			]
		][												;-- /with was not used
			either type = crypto/_hash [
				ERR_INVALID_REFINEMENT_ARG((refinement/load "with") method)
			][
				;-- If we get here, the method returns a digest (MD5 or SHA*). 
				b: crypto/get-digest data len crypto/alg-from-symbol type
				;!! len is reused here, being set to the expected result size of
				;	the hash call. So you can't set it before making that call.
				len: crypto/alg-digest-size crypto/alg-from-symbol type
				stack/set-last as red-value! binary/load b len
				free b
			]
		]
	]
	
	unset*: func [
		check?	[logic!]
		/local
			blk  [red-block!]
			word [red-word!]
			tail [red-word!]
	][
		#typecheck unset
		word: as red-word! stack/arguments
		
		either TYPE_OF(word) = TYPE_WORD [
			_context/set word unset-value
		][
			blk: as red-block! word
			word: as red-word! block/rs-head blk
			tail: as red-word! block/rs-tail blk
			
			while [word < tail][
				_context/set word unset-value
				word: word + 1
			]
		]
		unset/push-last
	]
	
	new-line*: func [
		check? [logic!]
		_all   [integer!]
		skip   [integer!]
		/local
			cell [cell!]
			tail [cell!]
			blk  [red-block!]
			int	 [red-integer!]
			bool [red-logic!]
			s	 [series!]
			step [integer!]
			nl?  [logic!]
	][
		#typecheck [new-line _all skip]
		blk: as red-block! stack/arguments
		bool: as red-logic! blk + 1
		nl?: bool/value
		
		s: GET_BUFFER(blk)
		cell: s/offset + blk/head
		
		either any [_all <> -1 skip <> -1][
			step: 1
			if skip <> -1 [
				int: as red-integer! blk + skip
				unless positive? int/value [
					fire [TO_ERROR(script out-of-range) int]
				]
				step: int/value
			]
			tail: s/tail
			while [cell < tail][
				cell/header: either nl? [
					cell/header or flag-new-line
				][
					cell/header and flag-nl-mask
				]
				cell: cell + step
			]
		][
			cell/header: either nl? [
				cell/header or flag-new-line
			][
				cell/header and flag-nl-mask
			]
		]
	]
	
	new-line?*: func [
		check? [logic!]
		/local
			bool [red-logic!]
			cell [cell!]
	][
		#typecheck new-line?
		cell: block/rs-head as red-block! stack/arguments
		bool: as red-logic! stack/arguments
		bool/header: TYPE_LOGIC
		bool/value: cell/header and flag-new-line <> 0
	]
	
	context?*: func [
		check? [logic!]
		/local
			word [red-word!]
			s	 [series!]
	][
		#typecheck context?
		word: as red-word! stack/arguments
		s: as series! word/ctx/value
		stack/set-last s/offset + 1						;-- return back-reference
	]

	set-env*: func [
		check?	[logic!]
		/local
			name	[red-string!]
			value	[red-string!]
			type	[integer!]
			cname	[c-string!]
			cvalue	[c-string!]
			len		[integer!]
			s		[series!]
			w		[red-word!]
	][
		#typecheck set-env
		name: as red-string! stack/arguments
		value: name + 1

		type: TYPE_OF(name)
		unless any [						;-- any-word!
			type = TYPE_STRING				;@@ replace with ANY_STRING?
			type = TYPE_FILE 
			type = TYPE_URL
			type = TYPE_TAG
			type = TYPE_EMAIL
		][
			w: as red-word! name
			s: GET_BUFFER(symbols)
			name: as red-string! s/offset + w/symbol - 1
		]
		PLATFORM_TO_CSTR(cname name len)
		either TYPE_OF(value) = TYPE_NONE [
			cvalue: null
		][
			PLATFORM_TO_CSTR(cvalue value len)
		]
		platform/set-env cname cvalue
		stack/set-last as red-value! value
	]

	get-env*: func [
		check?	[logic!]
		/local
			name	[red-string!]
			cstr	[c-string!]
			type	[integer!]
			s		[series!]
			w		[red-word!]
			buffer	[c-string!]
			len		[integer!]
	][
		#typecheck get-env
		name: as red-string! stack/arguments
		type: TYPE_OF(name)
		unless any [						;-- any-word!
			type = TYPE_STRING				;@@ replace with ANY_STRING?
			type = TYPE_FILE 
			type = TYPE_URL
			type = TYPE_EMAIL
		][
			w: as red-word! name
			s: GET_BUFFER(symbols)
			name: as red-string! s/offset + w/symbol - 1
		]
		PLATFORM_TO_CSTR(cstr name len)
		
		len: platform/get-env cstr null 0
		either len > 0 [
			buffer: as c-string! allocate #either OS = 'Windows [len * 2][len]
			platform/get-env cstr buffer len
			PLATFORM_LOAD_STR(name buffer (len - 1))
			free as byte-ptr! buffer
			stack/set-last as red-value! name	
		][
			name/header: TYPE_NONE
		]
	]

	list-env*: func [
		check?	[logic!]
	][
		#typecheck list-env
		list-env
	]

	now*: func [
		check?	[logic!]
		year	[integer!]
		month	[integer!]
		day		[integer!]
		time	[integer!]
		zone	[integer!]
		date	[integer!]
		weekday	[integer!]
		yearday	[integer!]
		precise	[integer!]
		utc		[integer!]
		/local
			dt	[red-date!]
	][
		#typecheck [now year month day time zone date weekday yearday precise utc]
		if time = -1 [--NOT_IMPLEMENTED--]

		dt: as red-date! stack/arguments
		dt/header: TYPE_TIME
		dt/time: platform/get-time utc >= 0 precise >= 0
	]
	
	as*: func [
		check?	[logic!]
		/local
			proto [red-value!]
			spec  [red-value!]
			dt	  [red-datatype!]
			path  [red-path!]
			type  [integer!]
			type2 [integer!]
	][
		#typecheck as
		proto: stack/arguments
		spec: proto + 1
		
		type:  TYPE_OF(proto)
		type2: TYPE_OF(spec)
		
		if type = TYPE_DATATYPE [
			dt: as red-datatype! proto
			type: dt/value
		]
		either any [
			all [ANY_BLOCK_STRICT?(type) ANY_BLOCK_STRICT?(type2)]
			all [ANY_STRING?(type) ANY_STRING?(type2)]
		][
			copy-cell spec proto
			set-type proto type
			if ANY_PATH?(type) [
				path: as red-path! proto
				path/args: null
			]
		][
			fire [TO_ERROR(script not-same-class) datatype/push type2 datatype/push type]
		]
	]
	
	call*: func [
		check?	[logic!]
		wait	[integer!]
		show	[integer!]
		console	[integer!]
		shell	[integer!]
		input	[integer!]
		output	[integer!]
		error	[integer!]
		return: [red-integer!]
		/local
			cmd	[red-string!]
			in	[red-string!]
			out [red-string!]
			err	[red-string!]
			new	[red-string!]
	][
		#typecheck [call wait show console shell input output error]
		
		cmd: as red-string! stack/arguments
		if string/rs-tail? cmd [return integer/box 0]
		
		if TYPE_OF(cmd) = TYPE_FILE [
			new: string/rs-make-at stack/push* string/rs-length? cmd
			file/to-local-path as red-file! cmd new no
			cmd: new
		]
		
		in: as red-string! stack/arguments + input
		unless OPTION?(in)[in: null]
		
		out: as red-string! stack/arguments + output
		unless OPTION?(out)[out: null]
		
		err: as red-string! stack/arguments + error
		unless OPTION?(err)[err: null]
		
		ext-process/call cmd wait > -1 show > -1 console > -1 shell > -1 in out err
	]

	;--- Natives helper functions ---
	
	max-min: func [
		max? [logic!]
		/local
			arg		[red-value!]
			arg2	[red-value!]
			value	[red-value!]
			p		[red-pair!]
			p2		[red-pair!]
			tp		[red-tuple!]
			buf		[byte-ptr!]
			buf2	[byte-ptr!]
			i		[integer!]
			n		[integer!]
			size	[integer!]
			type	[integer!]
			type2	[integer!]
			b		[byte!]
			result	[logic!]
			comp?	[logic!]
	][
		arg:	stack/arguments
		arg2:	arg + 1
		result: not max?								;-- false for max, true for min
		type:	TYPE_OF(arg)
		type2:	TYPE_OF(arg2)
		comp?:	no
		
		if any [
			all [type2 = TYPE_PAIR  any [type = TYPE_INTEGER type = TYPE_FLOAT]]
			all [type2 = TYPE_TUPLE any [type = TYPE_INTEGER type = TYPE_FLOAT]]
		][
			value: arg
			arg: arg2
			arg2: value
			n: type
			type: type2
			type2: n
		]
		
		switch type [
			TYPE_PAIR [
				p:  as red-pair! arg
				switch type2 [
					TYPE_PAIR [
						p2: as red-pair! arg2
						either max? [
							if p/x < p2/x [p/x: p2/x]
							if p/y < p2/y [p/y: p2/y]
						][
							if p/x > p2/x [p/x: p2/x]
							if p/y > p2/y [p/y: p2/y]
						]
					]
					TYPE_FLOAT
					TYPE_INTEGER [
						i: arg-to-integer arg2
						either max? [
							if p/x < i [p/x: i]
							if p/y < i [p/y: i]
						][
							if p/x > i [p/x: i]
							if p/y > i [p/y: i]
						]
						if arg <> stack/arguments [stack/set-last arg]
					]
					default [comp?: yes]
				]
			]
			TYPE_TUPLE [
				tp: as red-tuple! arg
				buf: (as byte-ptr! tp) + 4
				size: TUPLE_SIZE?(tp)
				n: 0
				switch type2 [
					TYPE_TUPLE [
						tp: as red-tuple! arg2
						buf2: (as byte-ptr! tp) + 4
						if size <> TUPLE_SIZE?(tp) [
							fire [TO_ERROR(script out-of-range) arg2]
						]
						either max? [
							until [n: n + 1 if buf/n < buf2/n [buf/n: buf2/n] n = size]
						][
							until [n: n + 1 if buf/n > buf2/n [buf/n: buf2/n] n = size]
						]
					]
					TYPE_FLOAT
					TYPE_INTEGER [
						i: arg-to-integer arg2
						b: either i > 255 [as-byte 255][either i < 0 [as-byte 0][as-byte i]]
						either max? [
							until [n: n + 1 if buf/n < b [buf/n: b] n = size]
						][
							until [n: n + 1 if buf/n > b [buf/n: b] n = size]
						]
						if arg <> stack/arguments [stack/set-last arg]
					]
					default [comp?: yes]
				]
			]
			default [comp?: yes]
		]
		if comp? [
			result: actions/compare arg arg2 COMP_LESSER
			if result = max? [stack/set-last arg2]
		]
	]
	
	arg-to-integer: func [
		arg 	[red-value!]
		return: [integer!]
		/local
			fl	[red-float!]
			int	[red-integer!]
	][
		either TYPE_OF(arg) = TYPE_INTEGER [
			int: as red-integer! arg
			int/value
		][
			fl: as red-float! arg
			if integer/overflow? fl [
				fire [TO_ERROR(script type-limit) datatype/push TYPE_INTEGER]
			]
			as-integer fl/value
		]
	]

	argument-as-float: func [
		return: [red-float!]
		/local
			fl	[red-float!]
			int	[red-integer!]
	][
		fl: as red-float! stack/arguments
		if TYPE_OF(fl) <> TYPE_FLOAT [
			fl/header: TYPE_FLOAT
			int: as red-integer! fl
			fl/value: as-float int/value
		]
		fl
	]

	degree-to-radians*: func [
		radians [integer!]
		type	[integer!]
		return: [red-float!]
		/local
			f	[red-float!]
			val [float!]
	][
		f: argument-as-float
		val: f/value
		if radians < 0 [val: degree-to-radians val type]
		f/value: val
		f
	]

	arc-trans: func [
		radians [integer!]
		type	[integer!]
		return: [red-float!]
		/local
			f	[red-float!]
			d	[float!]
	][
		f: argument-as-float
		d: f/value

		either all [type <> TYPE_TANGENT any [d < -1.0 d > 1.0]] [
			fire [TO_ERROR(math overflow)]
		][
			f/value: switch type [
				TYPE_SINE	 [asin d]
				TYPE_COSINE  [acos d]
				TYPE_TANGENT [atan d]
			]
		]

		if radians < 0 [f/value: f/value * 180.0 / PI]			;-- to degrees
		f
	]

	loop?: func [
		series  [red-series!]
		return: [logic!]	
		/local
			s	 [series!]
			type [integer!]
			img  [red-image!]
	][
	
		type: TYPE_OF(series)
		if type = TYPE_IMAGE [
			img: as red-image! series
			return IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) > img/head
		]
		s: GET_BUFFER(series)
		either any [									;@@ replace with any-block?
			type = TYPE_BLOCK
			type = TYPE_MAP
			type = TYPE_HASH
			type = TYPE_PAREN
			type = TYPE_PATH
			type = TYPE_GET_PATH
			type = TYPE_SET_PATH
			type = TYPE_LIT_PATH
		][
			s/offset + series/head < s/tail
		][
			(as byte-ptr! s/offset)
				+ (series/head << (log-b GET_UNIT(s)))
				< (as byte-ptr! s/tail)
		]
	]
	
	set-many: func [
		words [red-block!]
		value [red-value!]
		size  [integer!]
		only? [logic!]
		some? [logic!]
		/local
			w		[red-word!]
			v		[red-value!]
			blk		[red-block!]
			i		[integer!]
			type	[integer!]
			block?	[logic!]
	][
		i: 1
		type: TYPE_OF(value)
		block?: any [type = TYPE_BLOCK type = TYPE_HASH type = TYPE_MAP]
		if block? [blk: as red-block! value]
		
		while [i <= size][
			v: either all [block? not only?][_series/pick as red-series! blk i null][value]
			unless all [some? TYPE_OF(v) = TYPE_NONE][
				w: as red-word! _series/pick as red-series! words i null
				type: TYPE_OF(w)
				unless any [
					type = TYPE_WORD
					type = TYPE_GET_WORD
					type = TYPE_SET_WORD
					type = TYPE_LIT_WORD
				][
					fire [TO_ERROR(script invalid-arg) w]
				]
				_context/set w v
			]
			i: i + 1
		]
	]
	
	set-many-string: func [
		words [red-block!]
		str	  [red-string!]
		size  [integer!]
		/local
			i [integer!]
	][
		i: 1
		while [i <= size][
			_context/set (as red-word! _series/pick as red-series! words i null) _series/pick as red-series! str i null
			i: i + 1
		]
	]
	
	remove-each-init: func [/local part [red-integer!]][
		part: as red-integer! stack/arguments - 3
		assert TYPE_OF(part) = TYPE_INTEGER
		part/value: block/rs-length? as red-block! stack/arguments - 1
	]

	remove-each-next: func [
		size  [integer!]								;-- nb of elements to remove
		/local
			arg		[red-value!]
			bool	[red-logic!]
			series	[red-series!]
			pos		[red-series!]
			part	[red-value!]
	][
		arg: stack/arguments
		bool: as red-logic! arg
		series: as red-series! arg - 2
		part: either size = 1 [null][arg - 3]
		
		assert any [									;@@ replace with any-block?/any-string? check
			TYPE_OF(series) = TYPE_BLOCK
			TYPE_OF(series) = TYPE_HASH
			TYPE_OF(series) = TYPE_PAREN
			TYPE_OF(series) = TYPE_PATH
			TYPE_OF(series) = TYPE_GET_PATH
			TYPE_OF(series) = TYPE_SET_PATH
			TYPE_OF(series) = TYPE_LIT_PATH
			TYPE_OF(series) = TYPE_STRING
			TYPE_OF(series) = TYPE_FILE
			TYPE_OF(series) = TYPE_URL
			TYPE_OF(series) = TYPE_TAG
			TYPE_OF(series) = TYPE_EMAIL
			TYPE_OF(series) = TYPE_VECTOR
			TYPE_OF(series) = TYPE_BINARY
			TYPE_OF(series) = TYPE_MAP
			TYPE_OF(series) = TYPE_IMAGE
		]

		unless any [
			TYPE_OF(arg) = TYPE_NONE
			all [TYPE_OF(arg) = TYPE_LOGIC not bool/value]
		][
			series/head: series/head - size
			assert series/head >= 0
			pos: as red-series! actions/remove series as red-value! part
			series/head: pos/head
		]
	]

	foreach-next-block: func [
		size	[integer!]								;-- number of words in the block
		return: [logic!]
		/local
			series [red-series!]
			blk    [red-block!]
			type   [integer!]
			result [logic!]
	][
		blk:    as red-block!  stack/arguments - 1
		series: as red-series! stack/arguments - 2

		type: TYPE_OF(series)
		assert any [									;@@ replace with any-block?/any-string? check
			type = TYPE_BLOCK
			type = TYPE_HASH
			type = TYPE_PAREN
			type = TYPE_PATH
			type = TYPE_GET_PATH
			type = TYPE_SET_PATH
			type = TYPE_LIT_PATH
			type = TYPE_STRING
			type = TYPE_FILE
			type = TYPE_URL
			type = TYPE_TAG
			type = TYPE_EMAIL
			type = TYPE_VECTOR
			type = TYPE_BINARY
			type = TYPE_MAP
			type = TYPE_IMAGE
		]
		assert TYPE_OF(blk) = TYPE_BLOCK

		result: loop? series
		if result [
			switch type [
				TYPE_STRING
				TYPE_FILE
				TYPE_URL
				TYPE_TAG
				TYPE_EMAIL
				TYPE_VECTOR
				TYPE_BINARY [
					set-many-string blk as red-string! series size
				]
				TYPE_IMAGE [
					#either OS = 'Windows [
						image/set-many blk as red-image! series size
					][
						--NOT_IMPLEMENTED--
					]
				]
				default [
					set-many blk as red-value! series size no no
				]
			]
		]
		series/head: series/head + size
		result
	]
	
	foreach-next: func [
		return: [logic!]
		/local
			series [red-series!]
			word   [red-word!]
			result [logic!]
	][
		word:   as red-word!   stack/arguments - 1
		series: as red-series! stack/arguments - 2

		assert any [									;@@ replace with any-block?/any-string? check
			TYPE_OF(series) = TYPE_BLOCK
			TYPE_OF(series) = TYPE_HASH
			TYPE_OF(series) = TYPE_PAREN
			TYPE_OF(series) = TYPE_PATH
			TYPE_OF(series) = TYPE_GET_PATH
			TYPE_OF(series) = TYPE_SET_PATH
			TYPE_OF(series) = TYPE_LIT_PATH
			TYPE_OF(series) = TYPE_STRING
			TYPE_OF(series) = TYPE_FILE
			TYPE_OF(series) = TYPE_URL
			TYPE_OF(series) = TYPE_TAG
			TYPE_OF(series) = TYPE_EMAIL
			TYPE_OF(series) = TYPE_VECTOR
			TYPE_OF(series) = TYPE_BINARY
			TYPE_OF(series) = TYPE_MAP
			TYPE_OF(series) = TYPE_IMAGE
		]
		assert TYPE_OF(word) = TYPE_WORD
		
		result: loop? series
		if result [
			_context/set word actions/pick series 1 null
			series/head: series/head + 1
		]
		result
	]
	
	forall-loop: func [									;@@ inline?
		return: [logic!]
		/local
			series [red-series!]
			word   [red-word!]
	][
		word: as red-word! stack/arguments - 1
		assert TYPE_OF(word) = TYPE_WORD

		series: as red-series! _context/get word
		loop? series
	]
	
	forall-next: func [									;@@ inline?
		/local
			series [red-series!]
	][
		series: as red-series! _context/get as red-word! stack/arguments - 1
		series/head: series/head + 1
	]
	
	forall-end: func [									;@@ inline?
		/local
			series [red-series!]
			word   [red-word!]
	][
		word: 	as red-word!   stack/arguments - 1
		series: as red-series! stack/arguments - 2
		
		assert any [									;@@ replace with any-block?/any-string? check
			TYPE_OF(series) = TYPE_BLOCK
			TYPE_OF(series) = TYPE_HASH
			TYPE_OF(series) = TYPE_PAREN
			TYPE_OF(series) = TYPE_PATH
			TYPE_OF(series) = TYPE_GET_PATH
			TYPE_OF(series) = TYPE_SET_PATH
			TYPE_OF(series) = TYPE_LIT_PATH
			TYPE_OF(series) = TYPE_STRING
			TYPE_OF(series) = TYPE_FILE
			TYPE_OF(series) = TYPE_URL
			TYPE_OF(series) = TYPE_TAG
			TYPE_OF(series) = TYPE_EMAIL
			TYPE_OF(series) = TYPE_VECTOR
			TYPE_OF(series) = TYPE_BINARY
		]
		assert TYPE_OF(word) = TYPE_WORD

		_context/set word as red-value! series			;-- reset series to its initial offset
	]
	
	forall-end-adjust: func [
		/local
			changed	[red-series!]
			series	[red-series!]
	][
		changed: as red-series! _context/get as red-word! stack/arguments - 1
		series: as red-series! stack/arguments - 2
		series/head: changed/head
	]
	
	repeat-init*: func [
		cell  	[red-value!]
		return: [integer!]
		/local
			int [red-integer!]
	][
		copy-cell stack/arguments cell
		int: as red-integer! cell
		int/value										;-- overlapping /value field for integer! and char!
	]
	
	repeat-set: func [
		cell  [red-value!]
		value [integer!]
		/local
			int [red-integer!]
	][
		assert any [
			TYPE_OF(cell) = TYPE_INTEGER
			TYPE_OF(cell) = TYPE_CHAR
		]
		int: as red-integer! cell
		int/value: value								;-- overlapping /value field for integer! and char!
	]
	
	init: does [
		table: as int-ptr! allocate NATIVES_NB * size? integer!
		buffer-blk: block/make-in red/root 32			;-- block buffer for PRIN's reduce/into

		register [
			:if*
			:unless*
			:either*
			:any*
			:all*
			:while*
			:until*
			:loop*
			:repeat*
			:forever*
			:foreach*
			:forall*
			:remove-each*
			:func*
			:function*
			:does*
			:has*
			:switch*
			:case*
			:do*
			:get*
			:set*
			:print*
			:prin*
			:equal?*
			:not-equal?*
			:strict-equal?*
			:lesser?*
			:greater?*
			:lesser-or-equal?*
			:greater-or-equal?*
			:same?*
			:not*
			:type?*
			:reduce*
			:compose*
			:stats*
			:bind*
			:in*
			:parse*
			:union*
			:intersect*
			:unique*
			:difference*
			:exclude*
			:complement?*
			:dehex*
			:negative?*
			:positive?*
			:max*
			:min*
			:shift*
			:to-hex*
			:sine*
			:cosine*
			:tangent*
			:arcsine*
			:arccosine*
			:arctangent*
			:arctangent2*
			:NaN?*
			:log-2*
			:log-10*
			:log-e*
			:exp*
			:square-root*
			:construct*
			:value?*
			:try*
			:uppercase*
			:lowercase*
			:as-pair*
			:break*
			:continue*
			:exit*
			:return*
			:throw*
			:catch*
			:extend*
			:debase*
			:to-local-file*
			:wait*
			:checksum*
			:unset*
			:new-line*
			:new-line?*
			:enbase*
			:context?*
			:set-env*
			:get-env*
			:list-env*
			:now*
			:sign?*
			:as*
			:call*
			:zero?*
			:size?*
		]
	]

]
