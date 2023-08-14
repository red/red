Red/System [
	Title:   "Red native functions"
	Author:  "Nenad Rakocevic"
	File: 	 %natives.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2018 Red Foundation. All rights reserved."
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
			blk	  [red-block!]
			value [red-value!]
			tail  [red-value!]
			bool  [red-logic!]
			type  [integer!]
	][
		#typecheck any
		blk: as red-block! stack/push stack/arguments
		value: block/rs-head blk
		tail:  block/rs-tail blk
		
		while [value < tail][
			value: interpreter/eval-next blk value tail no
			
			bool: as red-logic! stack/arguments
			type: TYPE_OF(bool)
			unless any [type = TYPE_NONE all [type = TYPE_LOGIC not bool/value]][exit]
		]
		RETURN_NONE
	]
	
	all*: func [
		check? [logic!]
		/local
			blk	  [red-block!]
			value [red-value!]
			tail  [red-value!]
	][
		#typecheck all
		blk: as red-block! stack/push stack/arguments
		value: block/rs-head blk
		tail:  block/rs-tail blk
		
		if value = tail [RETURN_NONE]
		
		while [value < tail][
			value: interpreter/eval-next blk value tail no
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
			assert system/thrown = 0
			catch RED_THROWN_BREAK [interpreter/eval cond yes]
			switch system/thrown [
				RED_THROWN_BREAK
				RED_THROWN_CONTINUE	[
					system/thrown: 0
					fire [TO_ERROR(throw while-cond)]
				]
				0 					[0]
				default				[re-throw]
			]
			logic/true?
		][
			stack/reset
			assert system/thrown = 0
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
			assert system/thrown = 0
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
		check? [logic!]
		/local
			body  [red-block!]
			count [integer!]
			id 	  [integer!]
			saved [int-ptr!]
	][
		#typecheck loop
		coerce-counter*
		count: integer/get*
		unless positive? count [RETURN_NONE]			;-- if counter <= 0, no loops
		body: as red-block! stack/arguments + 1
		
		stack/mark-loop words/_body		
		loop count [
			stack/reset
			catch RED_THROWN_BREAK [interpreter/eval body yes]
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
		
		coerce-counter as red-value! count
		i: integer/get as red-value! count
		unless positive? i [RETURN_NONE]				;-- if counter <= 0, no loops
		
		count/value: 1
	
		stack/mark-loop words/_body
		until [
			stack/reset
			_context/set w as red-value! count
			assert system/thrown = 0
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
			assert system/thrown = 0
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
			value  [red-value!]
			series [red-value!]
			body   [red-block!]
			size   [integer!]
	][
		#typecheck foreach
		value: stack/arguments
		series: stack/arguments + 1
		body: as red-block! stack/arguments + 2
		
		stack/push series								;-- copy arguments to stack top in reverse order
		stack/push value								;-- (required by foreach-next)
		
		stack/mark-loop words/_body
		stack/set-last unset-value
		
		either TYPE_OF(value) = TYPE_BLOCK [
			size: block/rs-length? as red-block! value
			if 0 >= size [fire [TO_ERROR(script invalid-arg) value]]
			
			while [foreach-next-block size][			;-- foreach [..]
				stack/reset
				assert system/thrown = 0
				catch RED_THROWN_BREAK	[interpreter/eval body no]
				switch system/thrown [
					RED_THROWN_BREAK	[system/thrown: 0 break]
					RED_THROWN_CONTINUE	[system/thrown: 0 continue]
					0 					[0]
					default				[re-throw]
				]
			]
		][
			if TYPE_OF(series) = TYPE_MAP [fire [TO_ERROR(script invalid-arg) value]]
			
			while [foreach-next][						;-- foreach <word!>
				stack/reset
				assert system/thrown = 0
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
			saved  [red-series!]
			series [red-series!]
			img	   [red-image!]
			type   [integer!]
			break? [logic!]
			end?   [logic!]
	][
		#typecheck forall
		w:    as red-word!  stack/arguments
		body: as red-block! stack/arguments + 1
		
		saved: as red-series! word/get w				;-- save series (for resetting on end)
		type: TYPE_OF(saved)
		unless ANY_SERIES?(type) [ERR_EXPECT_ARGUMENT(type 0)]
		
		w: word/push w									;-- word argument
		break?: no
		
		stack/mark-loop words/_body
		series: as red-series! _context/get w	
		loop get-series-length series [
			stack/reset
			assert system/thrown = 0
			catch RED_THROWN_BREAK	[interpreter/eval body no]
			switch system/thrown [
				RED_THROWN_BREAK	[system/thrown: 0 break?: yes break]
				RED_THROWN_CONTINUE	
				0 [
					series: as red-series! _context/get w
					if series/node <> saved/node [fire [TO_ERROR(script bad-loop-series) series]]
					series/head: series/head + 1
					end?: either TYPE_OF(series) = TYPE_IMAGE [
						img: as red-image! series
						IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) <= img/head
					][
						_series/rs-tail? series
					]
					if end? [break]
					if system/thrown = RED_THROWN_CONTINUE [
						system/thrown: 0
						continue
					]
				]
				default	[re-throw]
			]
		]
		system/thrown: 0
		stack/unwind-last
		unless break? [_context/set w as red-value! saved]
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

		part: integer/push 0							;-- store number of words to set
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
			assert system/thrown = 0
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
	
	func*: func [check? [logic!] /local flags [integer!]][
		#typecheck func
		flags: _function/validate as red-block! stack/arguments
		_function/push 
			as red-block! stack/arguments
			as red-block! stack/arguments + 1
			null
			0
			null
			flags
		stack/set-last stack/get-top
	]
	
	function*: func [
		check? [logic!]
		/local spec [red-block!]
	][
		#typecheck function
		spec: block/clone as red-block! stack/arguments no no	;-- copy it before modifying it
		copy-cell as red-value! spec stack/arguments
		_function/collect-words	spec as red-block! stack/arguments + 1
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
		blk: block/clone as red-block! stack/arguments no no
		blk: as red-block! copy-cell as red-value! blk stack/arguments
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
			blk	  [red-block!]
			value [red-value!]
			tail  [red-value!]
			true? [logic!]
	][
		#typecheck [case all?]
		blk: as red-block! stack/push stack/arguments
		value: block/rs-head blk
		tail:  block/rs-tail blk
		if value = tail [RETURN_NONE]

		stack/mark-native words/_anon
		true?: false
		while [value < tail][
			value: interpreter/eval-next blk value tail no	;-- eval condition
			if value = tail [break]
			either logic/true? [
				either TYPE_OF(value) = TYPE_BLOCK [	;-- if true, eval what follows it
					stack/reset
					interpreter/eval as red-block! value yes
					value: value + 1
				][
					value: interpreter/eval-next blk value tail no
				]
				if negative? all? [stack/unwind-last exit]	;-- early exit with last value on stack (unless /all)
				true?: yes
			][
				value: value + 1						;-- single value only allowed for cases bodies
			]
		]
		stack/unwind-last
		unless true? [RETURN_NONE]
	]
	
	do*: func [
		check?  [logic!]
		expand? [integer!]
		args 	[integer!]
		next	[integer!]
		trace	[integer!]
		return: [integer!]
		/local
			cframe [byte-ptr!]
			arg	   [red-value!]
			do-arg [red-value!]
			fun	   [red-function!]
			slot   [red-value!]
			blk	   [red-block!]
			job	   [red-value!]
			pos	   [integer!]
			thrown [integer!]
			fun?   [logic!]
			defer? [logic!]
			do-block [subroutine!]
	][
		#typecheck [do expand? args next trace]
		arg: stack/arguments
		cframe: stack/get-ctop							;-- save the current call frame pointer
		do-arg: stack/arguments + args
		fun: 	as red-function! stack/arguments + trace
		
		if OPTION?(do-arg) [
			copy-cell do-arg #get system/script/args
		]
		fun?: OPTION?(fun)
		if fun? [
			with [interpreter][
				either trace? [fun?: no][				;-- pass-thru, ignore handler if one is in use already
					fun-locs: _function/count-locals fun/spec 0 no
					fun-evts: decode-filter fun
					copy-cell as red-value! fun as red-value! trace-fun
					trace?: tracing?: yes
					fire-init
				]
			]
		]
		if next > 0 [slot: _context/get as red-word! stack/arguments + next]
		
		do-block: [
			if expand? > 0 [
				job: #get system/build/config
				stack/mark-native words/_anon
				#call [preprocessor/expand as red-block! arg job]
				stack/unwind
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
		defer?: no
		assert system/thrown = 0
		
		catch RED_THROWN_ERROR [
			switch TYPE_OF(arg) [
				TYPE_ANY_LIST [do-block]
				TYPE_PATH  [
					interpreter/eval-path arg arg arg + 1 null no no no no
				]
				TYPE_STRING [
					lexer/scan-alt arg as red-string! arg -1 no yes yes no null null null
					do-block
				]
				TYPE_URL 
				TYPE_FILE  [#call [do-file as red-file! arg none-value]]
				TYPE_ERROR [defer?: yes]
				default	   [interpreter/eval-expression arg arg + 1 null no no yes]
			]
		]
		if defer? [stack/throw-error as red-object! arg]
		
		if fun? [
			thrown: system/thrown
			system/thrown: 0
			with [interpreter][
				fire-end
				copy-cell none-value as red-value! trace-fun
				trace?: tracing?: no
			]
			system/thrown: thrown
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
			0			[0]								;-- no exception case
			default 	[re-throw 0]					;-- all other exceptions (0 to make compiler happy)
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
			TYPE_ANY_PATH [
				interpreter/eval-path value null null null no yes no case? <> -1
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
		_any?  [integer!]
		case?  [integer!]
		_only? [integer!]
		_some? [integer!]
		/local
			w	   [red-word!]
			value  [red-value!]
			blk	   [red-block!]
			any?   [logic!]
			only?  [logic!]
			some?  [logic!]
	][
		#typecheck [set _any? case? _only? _some?]
		
		w: as red-word! stack/arguments
		value: stack/arguments + 1
		any?:  _any?  <> -1
		only?: _only? <> -1
		some?: _some? <> -1
		
		if all [not any? TYPE_OF(value) = TYPE_UNSET][fire [TO_ERROR(script need-value) w]]
		
		switch TYPE_OF(w) [
			TYPE_ANY_PATH [
				value: stack/push stack/arguments
				copy-cell stack/arguments + 1 stack/arguments
				interpreter/eval-path value null null null yes yes no case? <> -1
			]
			TYPE_OBJECT [
				object/set-many as red-object! w value any? only? some?
				stack/set-last value
			]
			TYPE_BLOCK [
				blk: as red-block! w
				stack/mark-native words/_anon
				set-many blk value block/rs-length? blk any? only? some?
				stack/unwind
				stack/set-last value
			]
			default [
				_context/set w value
				stack/set-last value
			]
		]
	]

	print*: func [check? [logic!]][
		do-print check? yes
	]

	prin*: func [check? [logic!]][
		#typecheck -prin-									;-- `prin` would be replaced by lexer
		do-print check? lf?
	]

	do-print: func [
		check?	[logic!]
		lf?		[logic!]
		/local
			arg		[red-value!]
			str		[red-string!]
			blk		[red-block!]
			oldhd	[integer!]
			s		[series!]
			block?	[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/do-print"]]
		arg: stack/arguments

		block?: TYPE_OF(arg) = TYPE_BLOCK
		if block? [
			;-- for recursive printing, reduce/into should put result into the buffer tail
			s: GET_BUFFER(buffer-blk)
			oldhd: buffer-blk/head 							;-- save the old buffer head
			buffer-blk/head: (as-integer s/tail - s/offset) >> (log-b GET_UNIT(s))

			stack/push as red-value! buffer-blk
			assert stack/top - 2 = stack/arguments			;-- check for correct stack layout
			reduce* no 1
			blk: as red-block! arg
			blk/head: 0										;-- head changed by reduce/into
			stack/set-last as red-value! buffer-blk 		;-- provide the modified-head buffer to form*
		]

		if TYPE_OF(arg) <> TYPE_STRING [actions/form* -1]
		
		str: as red-string! stack/arguments
		assert any [
			TYPE_OF(str) = TYPE_STRING
			TYPE_OF(str) = TYPE_SYMBOL						;-- symbol! and string! structs are overlapping
		]
		dyn-print/red-print str lf?
		if block? [											;-- restore the buffer head & clean up what was printed
			block/rs-clear buffer-blk 
			buffer-blk/head: oldhd			
		]
		last-lf?: lf?
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
				any [
					type = TYPE_FLOAT
					type = TYPE_PERCENT
					type = TYPE_PAIR
					type = TYPE_TIME
				][
					res: all [arg1/data2 = arg2/data2 arg1/data3 = arg2/data3]
				]
				type = TYPE_TUPLE [
					either TUPLE_SIZE?(arg1) = TUPLE_SIZE?(arg2) [
						res: 0 = tuple/compare as red-tuple! arg1 as red-tuple! arg2 COMP_EQUAL
					][
						res: false
					]
				]
				any [
					type = TYPE_NONE
					type = TYPE_UNSET
				][
					res: true
				]
				type = TYPE_MONEY [
					res: zero? money/compare as red-money! arg1 as red-money! arg2 COMP_SAME
				]
				any [
					type = TYPE_ACTION
					type = TYPE_NATIVE
					type = TYPE_POINT2D
				][
					res: all [arg1/data1 = arg2/data1 arg1/data2 = arg2/data2]
				]
				type = TYPE_OP [
					res: all [arg1/data2 = arg2/data2 arg1/data3 = arg2/data3]
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
			blk	  [red-block!]
			value	 [red-value!]
			tail	 [red-value!]
			arg		 [red-value!]
			target	 [red-block!]
			type	 [integer!]
			tail-pos [integer!]
			into?	 [logic!]
			blk?	 [logic!]
			append?  [logic!]
	][
		#typecheck [reduce into]
		arg: stack/arguments
		blk?: TYPE_OF(arg) = TYPE_BLOCK
		into?: into >= 0

		if blk? [
			blk: as red-block! stack/push arg
			value: block/rs-head blk
			tail:  block/rs-tail blk
		]

		stack/mark-native words/_body

		either into? [
			target: as red-block! arg + into
			tail-pos: block/rs-length? target
			append?: block/rs-tail? as red-block! stack/push as red-value! target
		][
			if blk? [block/push-only* (as-integer tail - value) >> 4]
			append?: yes
		]
		either blk? [
			while [value < tail][
				value: interpreter/eval-next blk value tail yes
				clear-newline stack/arguments + 1
				either append? [block/append*][actions/insert* -1 0 -1]
				stack/keep									;-- preserve the reduced block on stack
			]
		][
			type: TYPE_OF(arg)
			either any [
				type = TYPE_FUNCTION
				type = TYPE_NATIVE
				type = TYPE_ACTION
				type = TYPE_OP
				type = TYPE_ROUTINE
			][
				stack/set-last arg
			][
				interpreter/eval-expression arg arg + 1 null no yes no ;-- for non block! values
			]
			if into? [either append? [block/append*][actions/insert* -1 0 -1]]
		]
		if all [into? append?][
			ownership/check 
				stack/arguments
				words/_insert
				arg
				tail-pos
				(block/rs-length? target) - tail-pos
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
			value	[red-value!]
			tail	[red-value!]
			new		[red-block!]
			result	[red-value!]
			into?	[logic!]
			append? [logic!]
	][
		value: block/rs-head blk
		tail:  block/rs-tail blk
		into?: all [root? OPTION?(into)]

		new: either into? [
			append?: block/rs-tail? into
			into
		][
			append?: yes
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
					either append? [
						copy-cell as red-value! blk ALLOC_TAIL(new)
					][
						block/insert-value new as red-value! blk
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
								either append? [
									copy-cell result ALLOC_TAIL(new)
								][
									block/insert-value new result
								]
							][
								either append? [
									block/rs-append-block new as red-block! result
								][
									block/insert-block new as red-block! result
								]
							]
						]
					]
				]
				default [
					either append? [
						copy-cell value ALLOC_TAIL(new)
					][
						block/insert-value new value
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
		either TYPE_OF(arg) <> TYPE_BLOCK [
			fire [TO_ERROR(script expect-val) datatype/push TYPE_BLOCK datatype/push TYPE_OF(arg)]
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
			blk  [red-block!]
			used [float!]
	][
		#typecheck [stats show info]
		case [
			show >= 0 [
				;TBD
				integer/box memory/total
			]
			info >= 0 [
				blk: block/push-only* 5
				memory-info blk 2
				stack/set-last as red-value! blk
			]
			true [
				used: memory-info null 1
				either used > 2147483647.0 [
					float/box used
				][
					integer/box as-integer used
				]
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
			word  [red-word!]
			vctx  [red-context!]
			ctx	  [node!]
			self? [logic!]
			idx	  [integer!]
	][
		#typecheck [bind copy]
		value: stack/arguments
		ref: value + 1
		
		ctx: either any [
			TYPE_OF(ref) = TYPE_FUNCTION
			;TYPE_OF(ref) = TYPE_OBJECT
		][
			fun: as red-function! ref
			fun/ctx
		][
			word: as red-word! ref
			word/ctx
		]
		
		either TYPE_OF(value) = TYPE_BLOCK [
			vctx: TO_CTX(ctx)
			self?: TYPE_OF(ref) = TYPE_OBJECT
			either negative? copy [
				_context/bind as red-block! value vctx self?
			][
				stack/set-last 
					as red-value! _context/bind
						block/clone as red-block! value yes yes
						vctx
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
			obj		[red-object!]
			ctx		[red-context!]
			native	[red-native!]
			word	[red-word!]
			res		[red-value!]
	][
		#typecheck in
		obj:  as red-object! stack/arguments
		word: as red-word! stack/arguments + 1
		ctx: either any [
			TYPE_OF(obj) = TYPE_OBJECT
			TYPE_OF(obj) = TYPE_FUNCTION
			TYPE_OF(obj) = TYPE_ROUTINE
		][
			GET_CTX(obj)
		][
			native: as red-native! obj
			TO_CTX(native/more)
		]
		switch TYPE_OF(word) [
			TYPE_WORD
			TYPE_GET_WORD
			TYPE_SET_WORD
			TYPE_LIT_WORD
			TYPE_REFINEMENT [
				either negative? _context/bind-word ctx word [res: as red-value! none-value][
					res: as red-value! word
					if TYPE_OF(word) = TYPE_REFINEMENT [res/header: TYPE_WORD]
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
			type   [integer!]
			len	   [integer!]
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
				type: TYPE_OF(input)
				len: either ANY_STRING?(type) [
					string/rs-length? as red-string! input
				][
					block/rs-length? as red-block! input
				]
				logic/box zero? len
				return 0
			]
		]
		cframe: stack/get-ctop							;-- save the current call frame pointer
		
		assert system/thrown = 0
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
			type2	 [integer!]
			case?	 [logic!]
	][
		set1: stack/arguments
		set2: set1 + 1
		type: TYPE_OF(set1)

		if all [
			op <> OP_UNIQUE
			either any [type = TYPE_BLOCK type = TYPE_HASH][
				type2: TYPE_OF(set2)
				all [type2 <> TYPE_BLOCK type2 <> TYPE_HASH]
			][
				type <> TYPE_OF(set2)
			]
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
			TYPE_DATE	 [
				if op <> OP_DIFFERENCE [ERR_EXPECT_ARGUMENT(type 1)]
				date/difference? as red-date! set1 as red-date! set2
			]
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
			str	[red-string!]
			ret	[red-string!]
			len	[integer!]
	][
		#typecheck dehex
		str: as red-string! stack/arguments
		ret: as red-string! stack/push*
		len: string/rs-length? str
		string/make-at as red-value! ret len Latin1
		string/decode-url str ret
		stack/set-last as red-value! ret
		ret
	]

	enhex*: func [
		check?  [logic!]
		return: [red-string!]
		/local
			str	[red-string!]
			ret	[red-string!]
			len	[integer!]
	][
		#typecheck enhex
		str: as red-string! stack/arguments
		ret: as red-string! stack/push*
		len: string/rs-length? str
		string/make-at as red-value! ret len Latin1
		either TYPE_OF(str) = TYPE_STRING [
			string/encode-url str ret string/ESC_URI
		][
			string/encode-url str ret string/ESC_URL
		]
		stack/set-last as red-value! ret
		ret
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
		ret/header: TYPE_NONE
		ret/node: switch base [
			16 [binary/decode-16 p len unit]
			2  [binary/decode-2  p len unit]
			58 [binary/decode-58 p len unit]
			64 [binary/decode-64 p len unit]
			default [fire [TO_ERROR(script invalid-arg) int] null]
		]
		if ret/node <> null [ret/header: TYPE_BINARY]			;- if null, RETURN_NONE
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
		data/cache: null

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
		ret/header: TYPE_NONE
		ret/node: switch base [
			64 [binary/encode-64 p len]
			58 [binary/encode-58 p len]
			16 [binary/encode-16 p len]
			2  [binary/encode-2  p len]
			default [fire [TO_ERROR(script invalid-arg) int] null]
		]
		if ret/node <> null [ret/header: TYPE_STRING]	;-- ret/node = null, return NONE
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
		switch TYPE_OF(res) [							;@@ Add pair!
			TYPE_MONEY [
				res/value: money/negative-money? as red-money! res				
			]
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
		switch TYPE_OF(res) [							;@@ Add pair!
			TYPE_MONEY [
				res/value: money/positive-money? as red-money! res
			]
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
		switch TYPE_OF(res) [							;@@ Add pair! 
			TYPE_MONEY [
				ret: money/sign? as red-money! stack/arguments
			]
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
					true		  [ 0]
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
			pos	 [integer!]
			res	 [integer!]
	][
		#typecheck [shift left logical]
		data: as red-integer! stack/arguments
		bits: data + 1
		pos: bits/value
		if pos < 0 [pos: 0]
		
		res: case [
			left >= 0 [
				either pos > 31 [0][data/value << pos]
			]
			logical >= 0 [
				either pos > 31 [0][data/value >>> pos]
			]
			true [
				either pos > 31 [
					either data/value < 0 [-1][0]
				][
					data/value >> pos
				]
			]
		]
		data/value: res
	]

	to-hex*: func [
		check? [logic!]
		size   [integer!]
		/local
			arg	  [red-integer!]
			limit [red-integer!]
			p	  [c-string!]
			part  [integer!]
	][
		#typecheck [to-hex size]
		arg: as red-integer! stack/arguments
		limit: arg + size
		
		p: string/to-hex arg/value no
		part: either not OPTION?(limit) [0][
			unless positive? limit/value [fire [TO_ERROR(script invalid-arg) limit]]
			8 - limit/value
		]
		if negative? part [part: 0]
		issue/make-at stack/arguments p + part
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
		
		either f/value = (PI / 2.0) [					;-- see #3441 on `tangent 90` handling
			f/value: 1.0 / 0.0
		][
			either f/value = (PI / -2.0) [
				f/value: -1.0 / 0.0
			][
				f/value: tan f/value
			]
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
		radians [integer!]
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
		#either OS = 'Windows [
			f/value: atan2 y x
		][
			either all [								;-- bugfix for libc (all Linux versions)
				x - x <> 0.0							;-- if both x and y are infinite (or NaN)
				y - y <> 0.0
			][
				f/value: x - x							;-- then the result should be NaN
			][
				f/value: atan2 y x
			]
		]
		if radians < 0 [f/value: 180.0 / PI * f/value]			;-- to degrees
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
			pt	 [red-point3D!]
			ret  [red-logic!]
	][
		#typecheck -zero?- 								;-- `zero?` would be converted to `0 =` by lexer
		i: as red-integer! stack/arguments
		ret: as red-logic! i
		ret/value: switch TYPE_OF(i) [
			TYPE_MONEY [
				money/zero-money? as red-money! i
			]
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
			TYPE_POINT2D [
				pt: as red-point3D! i
				all [pt/x = as-float32 0 pt/y = as-float32 0]
			]
			TYPE_POINT2D [
				pt: as red-point3D! i
				all [pt/x = as-float32 0 pt/y = as-float32 0 pt/z = as-float32 0]
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
		f/value: (log-e f/value) / 0.6931471805599453
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
		f/value: log-e f/value
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
			type   [integer!]
			result [red-logic!]
	][
		#typecheck value?
		value: stack/arguments
		type: TYPE_OF(value)
		if ANY_WORD?(type) [
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
			type [integer!]
	][
		err: as red-object! stack/get-top
		assert TYPE_OF(err) = TYPE_ERROR
		id: error/get-id err
		type: error/get-type err
		either all [id = type id = words/errors/throw/symbol] [			;-- check if error is of type THROW
			re-throw 									;-- let the error pass through
		][
			stack/adjust-post-try
		]
	]
	
	try*: func [
		check?  [logic!]
		_all	[integer!]
		keep	[integer!]
		return: [integer!]
		/local
			arg	   [red-value!]
			cframe [byte-ptr!]
			result [integer!]
	][
		#typecheck [try _all keep]
		arg: stack/arguments
		cframe: stack/get-ctop							;-- save the current call frame pointer
		result: 0
		
		either _all = -1 [
			stack/mark-try words/_try
		][
			stack/mark-try-all words/_try
		]
		assert system/thrown = 0
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
				0 RED_THROWN_ERROR [stack/adjust-post-try]
				default [re-throw]
			]
		][												;-- TRY/ALL case, catch everything
			stack/adjust-post-try
		]
		system/thrown: 0
		if keep <> -1 [error/capture as red-object! stack/arguments]
		result
	]

	uppercase*: func [
		check? [logic!]
		part [integer!]
	][
		#typecheck [uppercase part]
		case-folding/change stack/arguments part yes
	]

	lowercase*: func [
		check? [logic!]
		part [integer!]
	][
		#typecheck [lowercase part]
		case-folding/change stack/arguments part no
	]
	
	as-pair*: func [
		check? [logic!]
		/local
			pair [red-pair!]
			arg	 [red-value!]
			int  [red-integer!]
			fl	 [red-float!]
			i	 [integer!]
			get-value [subroutine!]
	][
		#typecheck as-pair
		arg: stack/arguments
		pair: as red-pair! arg
		
		get-value: [
			switch TYPE_OF(arg) [
				TYPE_INTEGER [
					int: as red-integer! arg
					i: int/value
				]
				TYPE_FLOAT	 [
					fl: as red-float! arg
					if float/special? fl/value [fire [TO_ERROR(script invalid-arg) arg]]
					i: as-integer fl/value
				]
				default		 [assert false]
			]
			i
		]
		pair/x: get-value
		arg: arg + 1
		pair/y: get-value
		pair/header: TYPE_PAIR
	]
	
	as-point: func [
		size	 [integer!]
		/local
			p	 [red-point3D!]
			arg	 [red-value!]
			int  [red-integer!]
			fl	 [red-float!]
			f32  [float32!]
			get-value [subroutine!]
	][
		arg: stack/arguments
		p: as red-point3D! arg

		get-value: [
			switch TYPE_OF(arg) [
				TYPE_INTEGER [
					int: as red-integer! arg
					f32: as-float32 int/value
				]
				TYPE_FLOAT	 [
					fl: as red-float! arg
					f32: as-float32  fl/value
				]
				default		[assert false]
			]
			f32
		]
		p/x: get-value
		arg: arg + 1
		p/y: get-value
		either size = 2 [
			p/header: TYPE_POINT2D
		][
			arg: arg + 1
			p/z: get-value
			p/header: TYPE_POINT3D
		]
	]
	as-point2D*: func [check? [logic!]][#typecheck as-point2D  as-point 2]
	as-point3D*: func [check? [logic!]][#typecheck as-point3D  as-point 3]
	
	as-money*: func [
		check? [logic!]
		/local
			argument [red-value!]
			amount   [red-value!]
			currency [red-word!]
			mny      [red-money!]
			flt		 [red-float!]
			int		 [red-integer!]
			index    [integer!]
	][
		#typecheck as-money
		argument: stack/arguments
		currency: as red-word! argument
		amount:   stack/arguments + 1
		
		index: money/get-currency-index currency/symbol
		if negative? index [fire [TO_ERROR(script bad-denom) word/push currency]]
		
		switch TYPE_OF(amount) [
			TYPE_INTEGER [
				int: as red-integer! amount
				mny: money/from-integer int/value
			]
			TYPE_FLOAT [
				flt: as red-float! amount
				mny: money/from-float flt/value
			]
			default [assert false]
		]
		
		money/set-currency mny index
		SET_RETURN(mny)
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
		if interpreter/tracing? [interpreter/fire-throw]
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
		assert system/thrown = 0
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
			stack/set-last stack/get-top
			stack/top: stack/arguments + 1
			if interpreter/tracing? [interpreter/fire-catch]
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
			seconds	[float!]
	][
		#typecheck [wait all?] ;only?]
		val: as red-float! stack/arguments
		switch TYPE_OF(val) [
			TYPE_INTEGER [
				int: as red-integer! val
				seconds: as-float int/value
			]
			TYPE_FLOAT [
				seconds: val/value
			]
			TYPE_TIME [
				seconds: val/value
			]
			default [fire [TO_ERROR(script invalid-arg) val]]
		]
		val/header: TYPE_NONE
		platform/wait seconds
		#if modules contains 'View [exec/gui/do-events yes]
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
			any [type = crypto/_crc32 type = crypto/_tcp type = crypto/_adler32]
		][
			ERR_INVALID_REFINEMENT_ARG(refinements/_with method)
		]
		
		;-- TCP and CRC32 ignore [/with spec] entirely. For these methods
		;	we process them and exit. No other dispatching needed.
		if type = crypto/_crc32 [integer/box crypto/CRC32 data len   exit]
		if type = crypto/_tcp   [integer/box crypto/CRC_IP data len  exit]
		if type = crypto/_adler32 [integer/box crypto/adler32 data len exit]

		
		either _with >= 0 [								;-- /with was used
			spec: arg + _with
			switch TYPE_OF(spec) [
				TYPE_STRING TYPE_BINARY [
					if type = crypto/_hash [
						;-- /with 'spec arg for 'hash method must be an integer.
						ERR_INVALID_REFINEMENT_ARG(refinements/_with spec)
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
				ERR_INVALID_REFINEMENT_ARG(refinements/_with method)
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
				if TYPE_OF(word) = TYPE_WORD [
					_context/set word unset-value
				]
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
			i	 [integer!]
			flags[integer!]
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
			i: 0
			while [cell < tail][
				flags: either nl? xor any [step = 1 zero? (i % step)][
					cell/header and flag-nl-mask
				][
					cell/header or flag-new-line
				]
				cell/header: flags
				cell: cell + 1
				i: i + 1
			]
		][
			if s/tail <= cell [exit]
			flags: either nl? [
				cell/header or flag-new-line
			][
				cell/header and flag-nl-mask
			]
			cell/header: flags
		]
	]
	
	new-line?*: func [
		check? [logic!]
		/local
			bool [red-logic!]
			cell [cell!]
			blk  [red-block!]
			s	 [series!]
			nl?	 [logic!]
	][
		#typecheck new-line?
		
		blk: as red-block! stack/arguments
		s: GET_BUFFER(blk)
		cell: s/offset + blk/head
		nl?: either s/tail <= cell [no][cell/header and flag-new-line <> 0]
	
		bool: as red-logic! stack/arguments
		bool/header: TYPE_LOGIC
		bool/value:  nl?
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
		unless ANY_STRING?(type) [
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
		unless ANY_STRING?(type) [
			w: as red-word! name
			s: GET_BUFFER(symbols)
			name: word/as-string as red-word! name
		]
		PLATFORM_TO_CSTR(cstr name len)
		
		len: platform/get-env cstr null 0
		either len > 0 [
			buffer: as c-string! allocate #either OS = 'Windows [len * 2][len]
			platform/get-env cstr buffer len
			PLATFORM_LOAD_STR(name buffer (len - 1))
			free as byte-ptr! buffer
		][
			name/header: TYPE_NONE
		]
		stack/set-last as red-value! name	
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
		_date	[integer!]
		weekday	[integer!]
		yearday	[integer!]
		precise	[integer!]
		utc		[integer!]
		/local
			dt	[red-date!]
			int [red-integer!]
			tm	[float!]
			n	[integer!]
	][
		#typecheck [now year month day time zone _date weekday yearday precise utc]
		if all [
			any [time = -1 precise = -1]													;-- not /time/precise both
			year + month + day + time + zone + _date + weekday + yearday + precise >= -7 	;-- (-9 + 2) - 2 refs at once
		][
			fire [TO_ERROR(script bad-refines)]
		]

		dt: as red-date! stack/arguments
		dt/header: TYPE_DATE
		dt/date: platform/get-date utc >= 0
		if _date > -1 [
			dt/date: dt/date and FFFEFF80h				;-- clear time? flag and TZ data.
			dt/time: 0.0
			exit
		]
		dt/date: DATE_SET_TIME_FLAG(dt/date)
		
		tm: platform/get-time yes precise >= 0
		date/normalize-time 0 :tm DATE_GET_ZONE(dt/date)
		dt/time: tm
		n: 0
		case [
			year    > -1 [n: 2]
			month   > -1 [n: 3]
			day     > -1 [n: 4]
			zone    > -1 [n: 5]
			time    > -1 [n: 6]
			weekday > -1 [n: 10]
			yearday > -1 [
				int: as red-integer! dt
				int/header: TYPE_INTEGER
				int/value: date/get-yearday dt/date
				exit
			]
			true [exit]
		]
		if n > 0 [
			stack/keep
			stack/set-last date/push-field dt n
		]
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
			if ANY_PATH?(type) [path: as red-path! proto]
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

	browse*: func [
		check?	[logic!]
		/local
			url [red-string!]
			src [red-string!]
	][
		#typecheck browse

		src: as red-string! stack/arguments
		either TYPE_OF(src) = TYPE_FILE [
			url: string/rs-make-at stack/push* string/rs-length? src
			file/to-local-path as red-file! src url no
		][url: src]

		#case [
			OS = 'Windows [
				platform/ShellExecute 0 #u16 "open" unicode/to-utf16 url 0 0 1
			]
			any [OS = 'Linux OS = 'macOS][
				use [tool [c-string!] n [integer!] s [c-string!] cmd [byte-ptr!] len [integer!]][
					#either OS = 'macOS [tool: "open " n: 5][tool: "xdg-open " n: 9]
					len: -1
					s: unicode/to-utf8 url :len
					cmd: allocate len + n + 1
					copy-memory cmd as byte-ptr! tool n
					copy-memory cmd + n as byte-ptr! s len + 1
					ext-process/OS-call as-c-string cmd no no no yes null null null
					free cmd
				]
			]
			true [fire [TO_ERROR(internal not-here) words/_browse]]
		]
		unset/push-last
	]

	compress*: func [
		check?	 [logic!]
		/local
			method	[red-word!]
			sym		[integer!]
			arg		[red-binary!]
			src		[byte-ptr!]
			srclen	[integer!]
			buffer	[byte-ptr!]
			buflen	[integer!]
			res		[integer!]
			s		[series!]
			dst		[red-binary! value]
	][
		#typecheck compress
		arg: as red-binary! stack/arguments
		method: as red-word! arg + 1
		either TYPE_OF(arg) <> TYPE_BINARY [		;-- any-string!
			srclen: -1
			src: as byte-ptr! unicode/to-utf8 as red-string! arg :srclen
		][
			src: binary/rs-head arg
			srclen: binary/rs-length? arg
		]
		buflen: srclen + 32

		sym: symbol/resolve method/symbol
		loop 2 [	;-- try again in case fails the first time
			binary/make-at as red-value! dst buflen
			s: GET_BUFFER(dst)
			buffer: as byte-ptr! s/offset
			case [
				compressor/zlib = sym [
					res: zlib-compress buffer :buflen src srclen
				]
				compressor/deflate = sym [
					res: deflate/compress buffer :buflen src srclen
				]
				compressor/gzip = sym [
					res: gzip-compress buffer :buflen src srclen
				]
				true [fire [TO_ERROR(script invalid-arg) method]]
			]
			if res <> 1 [break]
		]
		if res <> 0 [
			fire [TO_ERROR(script invalid-data)]
		]
		s/tail: as cell! (buffer + buflen)
		stack/set-last as red-value! dst
	]

	decompress*: func [
		check?	 [logic!]
		size	 [integer!]
		/local
			method	[red-word!]
			sym		[integer!]
			arg		[red-binary!]
			sz		[red-integer!]
			src		[byte-ptr!]
			srclen	[integer!]
			res		[integer!]
			dst		[red-binary! value]
			dstlen	[integer!]
			s		[series!]
			buf		[byte-ptr!]
	][
		#typecheck [decompress size]
		arg: as red-binary! stack/arguments
		method: as red-word! arg + 1
		src: binary/rs-head arg
		srclen: binary/rs-length? arg

		dstlen: 0
		if size > 0 [
			sz: as red-integer! arg + size
			dstlen: sz/value
		]
		sym: symbol/resolve method/symbol
		case [
			compressor/zlib = sym [
				if dstlen <= srclen [
					;-- if dstlen is too small, calculate real buffer size before decompress
					dstlen: 0
					zlib-uncompress null :dstlen src srclen
				]
			]
			compressor/deflate = sym [
				if dstlen <= srclen [
					dstlen: 0
					deflate/uncompress null :dstlen src srclen
				]
			]
			compressor/gzip = sym [
				dstlen: 0
				;-- get buffer size from gzip format header
				gzip-uncompress null :dstlen src srclen
			]
			true [fire [TO_ERROR(script invalid-arg) method]]
		]

		loop 2 [	;-- try again in case fails the first time
			binary/make-at as red-value! dst dstlen
			s: GET_BUFFER(dst)
			buf: as byte-ptr! s/offset
			res: case [
				sym = compressor/zlib	 [zlib-uncompress buf :dstlen src srclen]
				sym = compressor/deflate [deflate/uncompress buf :dstlen src srclen]
				sym = compressor/gzip	 [gzip-uncompress buf :dstlen src srclen]
			]
			if res <> 1 [break]
		]
		if res <> 0 [fire [TO_ERROR(script invalid-data)]]
		s/tail: as cell! (buf + dstlen)
		stack/set-last as red-value! dst
	]
	
	
	recycle*: func [
		check? [logic!]
		on?    [integer!]
		off?   [integer!]
	][
		#typecheck [recycle on? off?]

		case [
			on?  > -1 [collector/active?: yes  unset/push-last]
			off? > -1 [collector/active?: no   unset/push-last]
			true	  [collector/do-mark-sweep stats* no -1 -1]
		]
	]
	
	transcode*: func [
		check? [logic!]
		next   [integer!]
		one    [integer!]
		prescan[integer!]
		scan   [integer!]
		part   [integer!]
		into   [integer!]
		trace  [integer!]
		/local
			offset len type [integer!]
			next? one? all? scan? load? [logic!]
			slot arg [red-value!]
			bin	bin2 [red-binary!]
			blk	out  [red-block!]
			int	  [red-integer!]
			str	  [red-string!]
			dt	  [red-datatype!]
			fun	  [red-function!]
			s	  [series!]
			cs    [c-string!]
	][
		#typecheck [transcode next one prescan scan part into trace]

		scan?: prescan < 0
		load?: scan < 0
		all?:  all [one < 0 load?]
		next?: next >= 0
		slot: stack/push*
		if all [next? any [one < 0 not load?]][
			blk: block/preallocate as red-block! slot 2 no
			s: GET_BUFFER(blk)
			s/tail: s/offset + 2
			slot: s/offset
		]
		out: either into < 0 [null][stack/arguments + into]
		offset: 0
		len: -1
		bin: as red-binary! stack/arguments
		type: TYPE_OF(bin)
		arg: stack/arguments + part
		fun: either trace < 0 [null][stack/arguments + trace]
		
		if OPTION?(arg) [
			switch TYPE_OF(arg) [
				TYPE_INTEGER [
					int: as red-integer! arg
					len: int/value
				]
				TYPE_BINARY [
					if type <> TYPE_BINARY [fire [TO_ERROR(script not-same-type)]]
					bin2: as red-binary! arg
					len: bin2/head - bin/head
				]
				TYPE_STRING [
					if type <> TYPE_STRING [fire [TO_ERROR(script not-same-type)]]
					str: as red-string! arg
					len: str/head - bin/head
				]
				default [0]
			]
			if len < 0 [len: 0]
		]
		one?: any [next? not all? not load?]
		either type = TYPE_BINARY [
			if len < 0 [len: binary/rs-length? bin]
			cs: as c-string! binary/rs-head bin
			if all [									;-- skip the BOM, don't load it as word
				len >= 3
				cs/1 = #"^(EF)"
				cs/2 = #"^(BB)"
				cs/3 = #"^(BF)"
			][
				len: len - 3
				cs: cs + 3
				bin/head: bin/head + 3
			]
			type: lexer/scan slot as byte-ptr! cs len one? scan? load? no :offset fun as red-series! bin out
		][
			str: as red-string! bin
			if len < 0 [len: string/rs-length? str]
			type: lexer/scan-alt slot str len one? scan? load? no :offset fun out
		]
		
		if any [not scan? not load?][
			if zero? len [stack/set-last none-value exit]
			either zero? type [slot/header: TYPE_NONE][
				if type < 0 [type: TYPE_ERROR]
				dt: as red-datatype! slot
				dt/header: TYPE_DATATYPE
				dt/value: type
			]
		]
		if all [next? any [one < 0 not load?]][
			bin: as red-binary! copy-cell as red-value! bin s/offset + 1
			s: GET_BUFFER(bin)
			bin/head: bin/head + offset					;-- move the input after the lexed token
			slot: as red-value! blk
		]
		either null? out [stack/set-last slot][stack/set-last as red-value! out]
	]
	
	apply*: func [
		check?	[logic!]
		_all	[integer!]
		safer	[integer!]
		/local
			args  [red-block!]
			fun	  [red-value!]
			value [red-value!]
			name  [red-word!]
			path  [red-path!]
			s	  [series!]
			mode  [integer!]
			type  [integer!]
	][	
		#typecheck [apply _all safer]

		fun: stack/arguments
		args: as red-block! fun + 1
		path: null

		switch TYPE_OF(fun) [
			TYPE_PATH
			TYPE_ANY_WORD [
				either TYPE_OF(fun) = TYPE_PATH [
					path: as red-path! fun
					name: as red-word! block/rs-head path
				][
					name: as red-word! fun
				]
				value: _context/get name
				type: TYPE_OF(value)
				unless ALL_FUNCTION?(type) [fire [TO_ERROR(script invalid-arg) fun]]
				fun: stack/push value
			]
			TYPE_ALL_FUNCTION [name: words/_applied]
			default			  [assert false]
		]
		if TYPE_OF(fun) = TYPE_OP [set-type fun GET_OP_SUBTYPE(fun)]
		
		s: GET_BUFFER(args)
		mode: either _all >= 0 [interpreter/MODE_APPLY][interpreter/MODE_APPLY_SOME]
		if safer >= 0 [mode: mode or interpreter/MODE_APPLY_SAFER]
		stack/set-interp-flag
		
		interpreter/eval-code
			fun
			s/offset + args/head
			s/tail
			args
			no
			path
			as red-value! name
			null
			mode
			no
	]

	;--- Natives helper functions ---
	
	max-min: func [
		max? [logic!]
		/local
			arg		[red-value!]
			arg2	[red-value!]
			value	[red-value!]
			fval	[red-float!]
			p		[red-pair!]
			p2		[red-pair!]
			pt		[red-point2D!]
			pt2		[red-point2D!]
			pt3 	[red-point3D!]
			pt3b 	[red-point3D!]
			tp		[red-tuple!]
			buf		[byte-ptr!]
			buf2	[byte-ptr!]
			i		[integer!]
			n		[integer!]
			size	[integer!]
			type	[integer!]
			type2	[integer!]
			f32		[float32!]
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

		if any [type = TYPE_FLOAT type = TYPE_PERCENT][
			fval: as red-float! arg
			if all [
				float/NaN? fval/value
				any [type2 = TYPE_FLOAT type2 = TYPE_PERCENT type2 = TYPE_INTEGER]
			][exit]
		]
		if any [type2 = TYPE_FLOAT type2 = TYPE_PERCENT][
			fval: as red-float! arg2
			if all [
				float/NaN? fval/value
				any [type = TYPE_FLOAT type = TYPE_PERCENT type = TYPE_INTEGER]
			][
				stack/set-last arg2
				exit
			]
		]

		if any [
			all [any [type2 = TYPE_PAIR type2 = TYPE_POINT2D type2 = TYPE_POINT3D] any [type = TYPE_INTEGER type = TYPE_FLOAT]]
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
				p: as red-pair! arg
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
					TYPE_POINT2D [
						pt: as red-point2D! arg			;-- promote argument to point2D!
						pt/header: TYPE_POINT2D
						pt/x: as-float32 p/x
						pt/y: as-float32 p/y
						
						pt2: as red-point2D! arg2
						either max? [
							if any [pt/x < pt2/x float/NaN-f32? pt2/x] [pt/x: pt2/x]
							if any [pt/y < pt2/y float/NaN-f32? pt2/y] [pt/y: pt2/y]
						][
							if any [pt/x > pt2/x float/NaN-f32? pt2/x] [pt/x: pt2/x]
							if any [pt/y > pt2/y float/NaN-f32? pt2/y] [pt/y: pt2/y]
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
			TYPE_POINT2D [
				pt: as red-point2D! arg
				switch type2 [
					TYPE_POINT2D [
						pt2: as red-point2D! arg2
						either max? [
							if any [pt/x < pt2/x float/NaN-f32? pt2/x] [pt/x: pt2/x]
							if any [pt/y < pt2/y float/NaN-f32? pt2/y] [pt/y: pt2/y]
						][
							if any [pt/x > pt2/x float/NaN-f32? pt2/x] [pt/x: pt2/x]
							if any [pt/y > pt2/y float/NaN-f32? pt2/y] [pt/y: pt2/y]
						]
					]
					TYPE_PAIR [
						p: as red-pair! arg2
						either max? [
							if pt/x < as-float32 p/x [pt/x: as-float32 p/x]
							if pt/y < as-float32 p/y [pt/y: as-float32 p/y]
						][
							if pt/x > as-float32 p/x [pt/x: as-float32 p/x]
							if pt/y > as-float32 p/y [pt/y: as-float32 p/y]
						]
					]
					TYPE_FLOAT
					TYPE_INTEGER [
						f32: as-float32 arg-to-float arg2
						either max? [
							if any [pt/x < f32 float/NaN-f32? f32] [pt/x: f32]
							if any [pt/y < f32 float/NaN-f32? f32] [pt/y: f32]
						][
							if any [pt/x > f32 float/NaN-f32? f32] [pt/x: f32]
							if any [pt/y > f32 float/NaN-f32? f32] [pt/y: f32]
						]
						if arg <> stack/arguments [stack/set-last arg]
					]
					default [comp?: yes]
				]
			]
			TYPE_POINT3D [
				pt3: as red-point3D! arg
				switch type2 [
					TYPE_POINT3D [
						pt3b: as red-point3D! arg2
						either max? [
							if any [pt3/x < pt3b/x float/NaN-f32? pt3b/x] [pt3/x: pt3b/x]
							if any [pt3/y < pt3b/y float/NaN-f32? pt3b/y] [pt3/y: pt3b/y]
							if any [pt3/z < pt3b/z float/NaN-f32? pt3b/z] [pt3/z: pt3b/z]
						][
							if any [pt3/x > pt3b/x float/NaN-f32? pt3b/x] [pt3/x: pt3b/x]
							if any [pt3/y > pt3b/y float/NaN-f32? pt3b/y] [pt3/y: pt3b/y]
							if any [pt3/z > pt3b/z float/NaN-f32? pt3b/z] [pt3/z: pt3b/z]
						]
					]
					TYPE_FLOAT
					TYPE_INTEGER [
						f32: as-float32 arg-to-float arg2
						either max? [
							if any [pt3/x < f32 float/NaN-f32? f32] [pt3/x: f32]
							if any [pt3/y < f32 float/NaN-f32? f32] [pt3/y: f32]
							if any [pt3/z < f32 float/NaN-f32? f32] [pt3/z: f32]
						][
							if any [pt3/x > f32 float/NaN-f32? f32] [pt3/x: f32]
							if any [pt3/y > f32 float/NaN-f32? f32] [pt3/y: f32]
							if any [pt3/z > f32 float/NaN-f32? f32] [pt3/z: f32]
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
						either size = TUPLE_SIZE?(tp) [
							either max? [
								until [n: n + 1 if buf/n < buf2/n [buf/n: buf2/n] n = size]
							][
								until [n: n + 1 if buf/n > buf2/n [buf/n: buf2/n] n = size]
							]
						][comp?: yes]
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
			if any [integer/overflow? fl float/NaN? fl/value][
				fire [TO_ERROR(script type-limit) datatype/push TYPE_INTEGER]
			]
			as-integer fl/value
		]
	]

	arg-to-float: func [
		arg 	[red-value!]
		return: [float!]
		/local
			fl	[red-float!]
			int	[red-integer!]
	][
		either TYPE_OF(arg) = TYPE_INTEGER [
			int: as red-integer! arg
			as-float int/value
		][
			fl: as red-float! arg
			fl/value
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

		f/value: switch type [
			TYPE_SINE	 [asin d]
			TYPE_COSINE  [acos d]
			TYPE_TANGENT [atan d]
		]

		if radians < 0 [f/value: f/value * 180.0 / PI]			;-- to degrees
		f
	]

	get-series-length: func [
		series  [red-series!]
		return: [integer!]	
		/local
			img  [red-image!]
	][
		either TYPE_OF(series) = TYPE_IMAGE [
			img: as red-image! series
			IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) - img/head
		][
			_series/get-length series no
		]
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
		either any [
			ANY_BLOCK?(type)
			type = TYPE_MAP
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
		any?  [logic!]
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
		type: TYPE_OF(value)
		block?: any [type = TYPE_MAP ANY_BLOCK?(type)]
		if block? [blk: as red-block! value]
		
		i: 1
		if all [block? not only?][							;-- pre-check of unset values and non-words
			while [i <= size][
				v: _series/pick as red-series! blk i null	;-- NONE if accessed over the tail
				w: as red-word! _series/pick as red-series! words i null
				type: TYPE_OF(w)
				unless ANY_WORD?(type) [					;-- cannot set non-word
					fire [TO_ERROR(script invalid-arg) w]
				]
				
				if all [not any? TYPE_OF(v) = TYPE_UNSET][	;-- requires /any refinement
					fire [TO_ERROR(script need-value) w]
				]
				
				i: i + 1
			]
		]
		
		i: 1
		while [i <= size][
			v: either all [block? not only?][_series/pick as red-series! blk i null][value]
			unless all [some? TYPE_OF(v) = TYPE_NONE][
				w: as red-word! _series/pick as red-series! words i null
				type: TYPE_OF(w)
				unless ANY_WORD?(type) [fire [TO_ERROR(script invalid-arg) w]]
				stack/keep								;-- avoid object event handler overwritting stack slots
				_context/set w v						;-- can trigger object event handler
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
			type    [integer!]
	][
		arg: stack/arguments
		bool: as red-logic! arg
		series: as red-series! arg - 2
		part: either size = 1 [null][arg - 3]
		type: TYPE_OF(series)
		
		assert any [
			ANY_SERIES?(type)
			type = TYPE_MAP
		]

		unless any [
			TYPE_OF(arg) = TYPE_NONE
			all [TYPE_OF(arg) = TYPE_LOGIC not bool/value]
		][
			series/head: series/head - size
			assert series/head >= 0
			pos: as red-series! actions/remove series part arg
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
		assert any [
			ANY_SERIES?(type)
			type = TYPE_MAP
		]
		assert TYPE_OF(blk) = TYPE_BLOCK

		result: all [loop? series  size > 0]
		if result [
			switch type [
				TYPE_ANY_STRING
				TYPE_VECTOR
				TYPE_BINARY [
					set-many-string blk as red-string! series size
				]
				TYPE_MAP [
					if size <> 2 [
						fire [TO_ERROR(script invalid-arg) blk]
					]
					result: map/set-many blk as red-hash! series size
				]
				TYPE_IMAGE [
					#case [
						any [OS = 'Windows OS = 'macOS OS = 'Linux] [
							image/set-many blk as red-image! series size
						]
						true [--NOT_IMPLEMENTED--]
					]
				]
				default [
					set-many blk as red-value! series size yes no no	;@@ allow set/any semantics
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
			type   [integer!]
			result [logic!]
	][
		word:   as red-word!   stack/arguments - 1
		series: as red-series! stack/arguments - 2
		type:   TYPE_OF(series)
		
		assert any [
			ANY_SERIES?(type)
			type = TYPE_MAP
		]
		assert TYPE_OF(word) = TYPE_WORD
		
		result: loop? series
		if result [
			_context/set word actions/pick series 1 null
			series/head: series/head + 1
		]
		result
	]
	
	forall-next?: func [									;@@ inline?
		return: [logic!]
		/local
			series [red-series!]
			img	   [red-image!]
	][
		series: as red-series! _context/get as red-word! stack/arguments - 1
		series/head: series/head + 1
		either TYPE_OF(series) = TYPE_IMAGE [
			img: as red-image! series
			IMAGE_WIDTH(img/size) * IMAGE_HEIGHT(img/size) <= img/head
		][
			_series/rs-tail? series
		]
	]
	
	forall-end: func [									;@@ inline?
		/local
			series [red-series!]
			word   [red-word!]
			type   [integer!]
	][
		word: 	as red-word!   stack/arguments - 1
		series: as red-series! stack/arguments - 2
		type:   TYPE_OF(series)
		
		assert any [
			ANY_SERIES?(type)
			type = TYPE_MAP
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
	
	coerce-counter: func [
		slot 	[red-value!]
		/local
			int [red-integer!]
			fl	[red-float!]
			i	[integer!]
	][
		if TYPE_OF(slot) = TYPE_FLOAT [
			fl: as red-float! slot
			i: as-integer fl/value
			int: as red-integer! slot
			int/header: TYPE_INTEGER
			int/value: i
		]
	]
	
	coerce-counter*: does [coerce-counter stack/arguments]
	
	inc-counter: func [w [red-word!] /local int [red-integer!]][
		assert TYPE_OF(w) = TYPE_WORD
		int: as red-integer! _context/get w
		assert TYPE_INTEGER = TYPE_OF(int)
		int/value: int/value + 1
		_context/set w as red-value! int
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
			:enhex*
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
			:as-point2D*
			:as-point3D*
			:as-money*
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
			:browse*
			:compress*
			:decompress*
			:recycle*
			:transcode*
			:apply*
		]
	]

]
