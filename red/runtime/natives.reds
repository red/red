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

natives: context [
	verbose: 0
	
	lf?: no												;-- used to print or not an ending newline

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
			actions/form* 0
			str: as red-string! arg + 1	
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

				default [
					print-line ["Error: unknown string encoding:" GET_UNIT(series)]
				]
			]
		][
			switch GET_UNIT(series) [
				Latin1 [platform/print-Latin1 as c-string! offset]
				UCS-2  [platform/print-UCS2   			   offset]
				UCS-4  [platform/print-UCS4   as int-ptr!  offset]

				default [
					print-line ["Error: unknown string encoding:" GET_UNIT(series)]
				]
			]
		]
		stack/set-last unset-value
	]
	
	compare: func [
		op		   [integer!]
		reverse	   [logic!]
		return:    [red-logic!]
		/local
			args   [red-value!]
			result [red-logic!]
	][
		args: stack/arguments
		result: as red-logic! args
		res: actions/compare args args + 1 op
		result/value: either reverse [not res][res]
		result/header: TYPE_LOGIC
		result
	]
	
	equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/equal?"]]
		compare COMP_EQUAL no
	]
	
	not-equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/not-equal?"]]
		compare COMP_EQUAL yes
	]
	
	strict-equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/strict-equal?"]]
		compare COMP_STRICT_EQUAL no
	]
	
	lesser?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/lesser?"]]
		compare COMP_LESSER no
	]
	
	greater?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/greater?"]]
		compare COMP_GREATER no
	]
	
	lesser-or-equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/lesser-or-equal?"]]
		compare COMP_LESSER_EQUAL no
	]	
	
	greater-or-equal?*: func [
		return:    [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/greater-or-equal?"]]
		compare COMP_GREATER_EQUAL no
	]
	
	not*: func [
		/local bool [red-logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "native/not"]]
		
		bool: as red-logic! stack/arguments
		bool/value: logic/false?						;-- run test before modifying stack
		bool/header: TYPE_LOGIC
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

]
