Red/System [
	Title:   "File! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %file.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2013-2015 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

file: context [
	verbose: 0

	rs-load: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		size	 [integer!]
		return:  [red-string!]
	][
		load-in src size root
	]

	load-in: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		size	 [integer!]
		blk		 [red-block!]
		return:  [red-string!]
		/local
			cell [red-string!]
	][
		#if debug? = yes [if verbose > 0 [print-line "file/load"]]
		
		cell: string/load-in src size blk UTF-8
		cell/header: TYPE_FILE							;-- implicit reset of all header flags
		normalize as red-file! cell
		cell
	]

	load: func [
		src		 [c-string!]							;-- UTF-8 source string buffer
		size	 [integer!]
		return:  [red-string!]
	][
		load-in src size null
	]

	push: func [
		file [red-file!]
	][
		#if debug? = yes [if verbose > 0 [print-line "file/push"]]
		
		copy-cell as red-value! file stack/push*
	]

	to-local-path: func [
		src		[red-file!]
		out		[red-string!]
		full?	[logic!]
		/local
			s	 [series!]
			p	 [byte-ptr!]
			end  [byte-ptr!]
			unit [integer!]
			c	 [integer!]
			d	 [integer!]
	][
		s: GET_BUFFER(src)
		unit: GET_UNIT(s)
		p: (as byte-ptr! s/offset) + (src/head << (log-b unit))
		end: (as byte-ptr! s/tail)
		s: GET_BUFFER(out)

		;-- prescan for: /c/dir, convert it to c:/ on Windows
		c: string/get-char p unit
		either c = as-integer #"/" [
			#if OS = 'Windows [
				p: p + unit
				if p < end [
					c: string/get-char p unit
					p: p + unit
				]
				if c <> as-integer #"/" [		;-- %/c
					if p < end [d: string/get-char p unit]
					either d = as-integer #"/" [
						string/append-char s c
						string/append-char s as-integer #":"
					][
						string/append-char s OS_DIR_SEP
					]
				]
			]
			string/append-char s OS_DIR_SEP
		][
			string/append-char s c
		]

		while [p: p + unit p < end][
			c: string/get-char p unit
			string/append-char s either c = as-integer #"/" [OS_DIR_SEP][c]
		]
		out
	]

	normalize: func [
		file    [red-file!]
		/local
			s	   [series!]
			unit   [integer!]
			cp	   [integer!]
			p	   [byte-ptr!]
			tail   [byte-ptr!]
	][
		s: GET_BUFFER(file)
		unit: GET_UNIT(s)
		p: (as byte-ptr! s/offset) + (file/head << (unit >> 1))
		tail: as byte-ptr! s/tail

		while [p < tail][
			cp: string/get-char p unit
			if cp = as-integer #"\" [
				string/poke-char s p as-integer #"/"
			]
			p: p + unit
		]
	]

	;-- Actions --

	make: func [
		proto	 [red-value!]
		spec	 [red-value!]
		type	 [integer!]
		return:	 [red-file!]
		/local
			file [red-file!]
	][
		#if debug? = yes [if verbose > 0 [print-line "file/make"]]

		file: as red-file! string/make proto spec type
		set-type as red-value! file TYPE_FILE
		file
	]

	mold: func [
		file    [red-file!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			int	   [red-integer!]
			limit  [integer!]
			s	   [series!]
			unit   [integer!]
			cp	   [integer!]
			p	   [byte-ptr!]
			p4	   [int-ptr!]
			head   [byte-ptr!]
			tail   [byte-ptr!]
			empty? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "file/mold"]]

		limit: either OPTION?(arg) [
			int: as red-integer! arg
			int/value
		][0]

		s: GET_BUFFER(file)
		unit: GET_UNIT(s)
		p: (as byte-ptr! s/offset) + (file/head << (log-b unit))
		head: p
		empty?: p = as byte-ptr! s/tail

		tail: either zero? limit [						;@@ rework that part
			as byte-ptr! s/tail
		][
			either negative? part [p][p + (part << (log-b unit))]
		]
		if tail > as byte-ptr! s/tail [tail: as byte-ptr! s/tail]

		string/append-char GET_BUFFER(buffer) as-integer #"%"
		either empty? [
			string/concatenate-literal buffer {""}
		][
			while [p < tail][
				cp: switch unit [
					Latin1 [as-integer p/value]
					UCS-2  [(as-integer p/2) << 8 + p/1]
					UCS-4  [p4: as int-ptr! p p4/value]
				]
				string/append-escaped-char buffer cp string/ESC_URL all?
				p: p + unit
			]
		]
		part - ((as-integer tail - head) >> (log-b unit)) - 1
	]

	;-- I/O actions
	read: func [
		src		[red-value!]
		part	[red-value!]
		seek	[red-value!]
		binary? [logic!]
		lines?	[logic!]
		as-arg	[red-value!]
		return:	[red-value!]
	][
		if any [
			OPTION?(part)
			OPTION?(seek)
			OPTION?(as-arg)
		][
			--NOT_IMPLEMENTED--
		]
		simple-io/read as red-file! src binary? lines?
	]

	write: func [
		dest	[red-value!]
		data	[red-value!]
		binary? [logic!]
		lines?	[logic!]
		append? [logic!]
		part	[red-value!]
		seek	[red-value!]
		allow	[red-value!]
		as-arg	[red-value!]
		return:	[red-value!]
	][
		if any [
			OPTION?(seek)
			OPTION?(allow)
			OPTION?(as-arg)
		][
			--NOT_IMPLEMENTED--
		]
		simple-io/write as red-file! dest data part binary? append?
		as red-value! unset-value
	]

	init: does [
		datatype/register [
			TYPE_FILE
			TYPE_STRING
			"file!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			INHERIT_ACTION	;form
			:mold
			INHERIT_ACTION	;eval-path
			null			;set-path
			INHERIT_ACTION	;compare
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
			null			;change
			INHERIT_ACTION	;clear
			INHERIT_ACTION	;copy
			INHERIT_ACTION	;find
			INHERIT_ACTION	;head
			INHERIT_ACTION	;head?
			INHERIT_ACTION	;index?
			INHERIT_ACTION	;insert
			INHERIT_ACTION	;length?
			INHERIT_ACTION	;next
			INHERIT_ACTION	;pick
			INHERIT_ACTION	;poke
			null			;put
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
			:read
			null			;rename
			null			;update
			:write
		]
	]
]
