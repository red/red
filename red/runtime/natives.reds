Red/System [
	Title:   "Red native functions"
	Author:  "Nenad Rakocevic"
	File: 	 %natives.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
	}
]

#define RETURN_NONE [
	stack/reset
	none/push-last
]

#define RETURN_UNSET [
	stack/reset
	unset/push-last
]

natives: context [
	verbose: 0
	lf?: 	 no											;-- used to print or not an ending newline
	
	table: as int-ptr! allocate NATIVES_NB * size? integer!
	top: 0

	register: func [
		[variadic]
		count	   [integer!]
		list	   [int-ptr!]
		/local
			offset [integer!]
	][
		offset: 0
		
		until [
			table/top: list/value
			top: top + 1
			assert top < NATIVES_NB
			list: list + 1
			count: count - 1
			zero? count
		]
	]
	
	;--- Natives ----
	
	if*: does [
		either logic/false? [
			RETURN_NONE
		][
			interpreter/eval as red-block! stack/arguments + 1 no
		]
	]
	
	unless*: does [
		stack/mark-native words/_body
		either logic/false? [
			interpreter/eval as red-block! stack/arguments + 1 no
		][
			RETURN_NONE
		]
	]
	
	either*: func [
		/local offset [integer!]
	][
		offset: either logic/true? [1][2]
		interpreter/eval as red-block! stack/arguments + offset no
	]
	
	any*: func [
		/local
			value [red-value!]
			tail  [red-value!]
	][
		value: block/rs-head as red-block! stack/arguments
		tail:  block/rs-tail as red-block! stack/arguments
		
		while [value < tail][
			value: interpreter/eval-next value tail
			if logic/true? [exit]
		]
		RETURN_NONE
	]
	
	all*: func [
		/local
			value [red-value!]
			tail  [red-value!]
	][
		value: block/rs-head as red-block! stack/arguments
		tail:  block/rs-tail as red-block! stack/arguments
		
		while [value < tail][
			value: interpreter/eval-next value tail
			if logic/false? [
				RETURN_NONE
				exit
			]
		]
	]
	
	while*:	func [
		/local
			cond [red-block!]
			body [red-block!]
	][
		cond: as red-block! stack/arguments
		body: as red-block! stack/arguments + 1
		
		stack/mark-native words/_body
		while [
			interpreter/eval cond
			logic/true?
		][
			interpreter/eval body
		]
		stack/unwind
		RETURN_UNSET
	]
	
	until*: func [
		/local
			body [red-block!]
	][
		body: as red-block! stack/arguments

		stack/mark-native words/_body
		until [
			interpreter/eval body
			logic/true?
		]
		stack/unwind-last
	]
	
	loop*: func [
		/local
			body [red-block!]
			i	 [integer!]
	][
		i: integer/get*
		unless positive? i [exit]						;-- if counter <= 0, no loops
		body: as red-block! stack/arguments + 1
	
		stack/mark-native words/_body
		until [	
			interpreter/eval body
			i: i - 1
			zero? i
		]
		stack/unwind-last
	]
	
	repeat*: func [
		/local
			w	   [red-word!]
			body   [red-block!]
			count  [red-integer!]
			cnt	   [integer!]
			i	   [integer!]
	][
		w: 	   as red-word!    stack/arguments
		count: as red-integer! stack/arguments + 1
		body:  as red-block!   stack/arguments + 2
		
		i: integer/get as red-value! count
		unless positive? i [exit]						;-- if counter <= 0, no loops
		count/value: 1
	
		stack/mark-native words/_body
		until [	
			_context/set w as red-value! count
			interpreter/eval body
			count/value: count/value + 1
			i: i - 1
			zero? i
		]
		stack/unwind-last
	]
	
	foreach*:	does []
	forall*:	does []
	func*:		does []
	function*:	does []
	does*:		does []
	has*:		does []
	exit*:		does []
	return*:	does []
	switch*:	does []
	case*:		does []
	
	do*: does [
		interpreter/eval as red-block! stack/arguments no
	]
	
	get*:		does []
	set*:		does []

	print*: does [
		lf?: yes
		prin*
		lf?: no
	]
	
	prin*: func [
		/local
			arg		[red-value!]
			str		[red-string!]
			series	[series!]
			offset	[byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/prin"]]
		
		arg: stack/arguments
		
		either TYPE_OF(arg) = TYPE_STRING [
			str: as red-string! arg
		][
			actions/form* -1
			str: as red-string! stack/arguments + 1
			assert any [
				TYPE_OF(str) = TYPE_STRING
				TYPE_OF(str) = TYPE_SYMBOL					;-- symbol! and string! structs are overlapping
			]
		]
		series: GET_BUFFER(str)
		offset: (as byte-ptr! series/offset) + (str/head << (GET_UNIT(series) >> 1))

		either lf? [
			switch GET_UNIT(series) [
				Latin1 [platform/print-line-Latin1 as c-string! offset]
				UCS-2  [platform/print-line-UCS2 				offset]
				UCS-4  [platform/print-line-UCS4   as int-ptr!  offset]

				default [									;@@ replace by an assertion
					print-line ["Error: unknown string encoding: " GET_UNIT(series)]
				]
			]
		][
			switch GET_UNIT(series) [
				Latin1 [platform/print-Latin1 as c-string! offset]
				UCS-2  [platform/print-UCS2   			   offset]
				UCS-4  [platform/print-UCS4   as int-ptr!  offset]

				default [									;@@ replace by an assertion
					print-line ["Error: unknown string encoding: " GET_UNIT(series)]
				]
			]
		]
		stack/set-last unset-value
	]
	
	compare: func [
		op		   [integer!]
		return:    [red-logic!]
		/local
			args   [red-value!]
			result [red-logic!]
	][
		args: stack/arguments
		result: as red-logic! args
		result/value: actions/compare args args + 1 op
		result/header: TYPE_LOGIC
		result
	]
	
	equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/equal?"]]
		compare COMP_EQUAL
	]
	
	not-equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/not-equal?"]]
		compare COMP_NOT_EQUAL
	]
	
	strict-equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/strict-equal?"]]
		compare COMP_STRICT_EQUAL
	]
	
	lesser?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/lesser?"]]
		compare COMP_LESSER
	]
	
	greater?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/greater?"]]
		compare COMP_GREATER
	]
	
	lesser-or-equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/lesser-or-equal?"]]
		compare COMP_LESSER_EQUAL
	]	
	
	greater-or-equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/greater-or-equal?"]]
		compare COMP_GREATER_EQUAL
	]
	
	same?*: does []
	
	not*: func [
		/local bool [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/not"]]
		
		bool: as red-logic! stack/arguments
		bool/value: logic/false?						;-- run test before modifying stack
		bool/header: TYPE_LOGIC
	]
	
	halt*: does [halt]
	
	type?*: func [
		word?	 [integer!]
		return:  [red-value!]
		/local
			dt	 [red-datatype!]
			w	 [red-word!]
			name [names!]
	][
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
	
	load*: func [
		/local
			str [red-string!]
			s	[series!]
	][
		str: as red-string! stack/arguments
		s: GET_BUFFER(str)
		tokenizer/scan as c-string! s/offset null	;@@ temporary limited to Latin-1
	]

	;--- Natives helper functions ---
	
	loop?: func [
		series     [red-series!]
		return:    [logic!]	
		/local
			s	   [series!]
	][
		s: GET_BUFFER(series)
	
		either TYPE_OF(series) = TYPE_BLOCK [			;@@ replace with any-block?/any-string? check
			s/offset + series/head < s/tail
		][
			(as byte-ptr! s/offset)
				+ (series/head << (GET_UNIT(s) >> 1))
				< (as byte-ptr! s/tail)
		]
	]
	
	set-many-to-many: func [
		words	[red-block!]
		series	[red-series!]
		size	[integer!]
		/local
			i	[integer!]
	][
		i: 1
		while [i <= size][
			_context/set
				as red-word! block/pick words i
				actions/pick series i
			i: i + 1
		]
	]
	
	foreach-next-block: func [
		size	[integer!]								;-- number of words in the block
		return: [logic!]
		/local
			series [red-series!]
			blk    [red-block!]
			result [logic!]
	][
		blk:    as red-block!  stack/arguments - 1
		series: as red-series! stack/arguments - 2

		assert any [									;@@ replace with any-block?/any-string? check
			TYPE_OF(series) = TYPE_BLOCK
			TYPE_OF(series) = TYPE_STRING
		]
		assert TYPE_OF(blk) = TYPE_BLOCK

		set-many-to-many blk series size
		result: loop? series
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
			TYPE_OF(series) = TYPE_STRING
		]
		assert TYPE_OF(word) = TYPE_WORD
		
		_context/set word actions/pick series 1
		result: loop? series
		series/head: series/head + 1
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
			TYPE_OF(series) = TYPE_STRING
		]
		assert TYPE_OF(word) = TYPE_WORD

		_context/set word as red-value! series			;-- reset series to its initial offset
	]
	
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
		:foreach*
		:forall*
		:func*
		:function*
		:does*
		:has*
		:exit*
		:return*
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
		:halt*
		:type?*
		:load*
	]

]
