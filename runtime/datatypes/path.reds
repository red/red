Red/System [
	Title:   "Path! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %path.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

path: context [
	verbose: 0
	
	push*: func [
		size	[integer!]
		return: [red-path!]	
		/local
			p 	[red-path!]
	][
		#if debug? = yes [if verbose > 0 [print-line "path/push*"]]
		
		p: as red-path! ALLOC_TAIL(root)
		p/header: TYPE_PATH								;-- implicit reset of all header flags
		p/head:   0
		p/node:   alloc-cells size
		p/args:	  null
		push p
		p
	]
	
	push: func [
		p [red-path!]
	][
		#if debug? = yes [if verbose > 0 [print-line "path/push"]]

		p/header: TYPE_PATH								;@@ type casting (from block! to path!)
		p/args:	  null
		copy-cell as red-value! p stack/push*
	]


	;--- Actions ---
	
	make: func [
		proto 	 [red-value!]
		spec	 [red-value!]
		return:	 [red-path!]
		/local
			path [red-path!]
	][
		#if debug? = yes [if verbose > 0 [print-line "path/make"]]

		path: as red-path! block/make proto spec
		path/header: TYPE_PATH
		path/args:	 null
		path
	]
	
	form: func [
		path	  [red-path!]
		buffer	  [red-string!]
		arg		  [red-value!]
		part 	  [integer!]
		return:   [integer!]
		/local
			s	  [series!]
			value [red-value!]
			i     [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "path/form"]]
		
		s: GET_BUFFER(path)
		i: path/head
		value: s/offset + i
		
		while [value < s/tail][
			part: actions/form value buffer arg part
			if all [OPTION?(arg) part <= 0][return part]
			i: i + 1
			
			s: GET_BUFFER(path)
			value: s/offset + i
			if value < s/tail [
				string/append-char GET_BUFFER(buffer) as-integer slash
				part: part - 1
			]
		]
		part
	]
	
	mold: func [
		path	  [red-path!]
		buffer	  [red-string!]
		only?	  [logic!]
		all?	  [logic!]
		flat?	  [logic!]
		arg		  [red-value!]
		part 	  [integer!]
		indent	  [integer!]
		return:   [integer!]
		/local
			s	  [series!]
			value [red-value!]
			i     [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "path/mold"]]
	
		s: GET_BUFFER(path)
		i: path/head
		value: s/offset + i

		while [value < s/tail][
			part: actions/mold value buffer only? all? flat? arg part 0
			if all [OPTION?(arg) part <= 0][return part]
			i: i + 1

			s: GET_BUFFER(path)
			value: s/offset + i
			if value < s/tail [
				string/append-char GET_BUFFER(buffer) as-integer slash
				part: part - 1
			]
		]
		part
	]
	
	compare: func [
		value1	   [red-path!]							;-- first operand
		value2	   [red-path!]							;-- second operand
		op		   [integer!]							;-- type of comparison
		return:	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "path/compare"]]

		if TYPE_OF(value2) <> TYPE_PATH [RETURN_COMPARE_OTHER]
		block/compare-each as red-block! value1 as red-block! value2 op
	]
	
	copy: func [
		path    [red-path!]
		new		[red-path!]
		arg		[red-value!]
		deep?	[logic!]
		types	[red-value!]
		return:	[red-series!]
	][
		#if debug? = yes [if verbose > 0 [print-line "path/copy"]]

		path: as red-path! block/copy as red-block! path as red-block! new arg deep? types
		path/args:	 null
		as red-series! path
	]
	
	init: does [
		datatype/register [
			TYPE_PATH
			TYPE_BLOCK
			"path!"
			;-- General actions --
			:make
			null			;random
			INHERIT_ACTION	;reflect
			null			;to
			:form
			:mold
			INHERIT_ACTION	;eval-path
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
			INHERIT_ACTION	;at
			INHERIT_ACTION	;back
			INHERIT_ACTION	;change
			INHERIT_ACTION	;clear
			:copy
			INHERIT_ACTION	;find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			INHERIT_ACTION	;insert
			INHERIT_ACTION	;length?
			INHERIT_ACTION	;move
			INHERIT_ACTION	;next
			INHERIT_ACTION	;pick
			INHERIT_ACTION	;poke
			INHERIT_ACTION	;put
			INHERIT_ACTION	;remove
			INHERIT_ACTION	;reverse
			INHERIT_ACTION	;select
			null			;sort
			INHERIT_ACTION	;skip
			INHERIT_ACTION	;swap
			INHERIT_ACTION	;tail
			INHERIT_ACTION	;tail?
			INHERIT_ACTION	;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			INHERIT_ACTION	;modify
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