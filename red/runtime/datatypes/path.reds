Red/System [
	Title:   "Path! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %path.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2011-2012 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/dockimbel/Red/blob/master/BSL-License.txt
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
		push p
		p
	]
	
	push: func [
		p [red-path!]
	][
		#if debug? = yes [if verbose > 0 [print-line "path/push"]]

		p/header: TYPE_PATH								;@@ type casting (from block! to path!)
		copy-cell as red-value! p stack/push
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
		path
	]
	
	form: func [
		path	  [red-path!]
		buffer	  [red-string!]
		part 	  [integer!]
		flags     [integer!]
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
			part: actions/form value buffer part flags
			if all [not zero? flags part <= 0][return part]
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
	
	datatype/register [
		TYPE_PATH
		TYPE_BLOCK
		"path"
		;-- General actions --
		:make
		null			;random
		null			;reflect
		null			;to
		:form
		:form			;mold
		null			;get-path
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
		INHERIT_ACTION	;append
		INHERIT_ACTION	;at
		INHERIT_ACTION	;back
		null			;change
		INHERIT_ACTION	;clear
		null			;copy
		null			;find
		INHERIT_ACTION	;head
		INHERIT_ACTION	;head?
		INHERIT_ACTION	;index?
		null			;insert
		INHERIT_ACTION	;length?
		INHERIT_ACTION	;next
		INHERIT_ACTION	;pick
		INHERIT_ACTION	;poke
		null			;remove
		null			;reverse
		null			;select
		null			;sort
		INHERIT_ACTION	;skip
		null			;swap
		INHERIT_ACTION	;tail
		INHERIT_ACTION	;tail?
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