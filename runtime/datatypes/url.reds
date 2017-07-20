Red/System [
	Title:   "Url! datatype runtime functions"
	Author:  "Xie Qingtian"
	File: 	 %url.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2015 Xie Qingtian. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/red-system/runtime/BSL-License.txt
	}
]

url: context [
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
		#if debug? = yes [if verbose > 0 [print-line "url/load"]]

		cell: string/load-in src size blk UTF-8
		cell/header: TYPE_URL							;-- implicit reset of all header flags
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
		url [red-url!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/push"]]

		copy-cell as red-value! url stack/push*
	]

	;-- Actions --
	
	make: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-url!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/make"]]
		
		either all [type = TYPE_URL TYPE_OF(spec) = TYPE_BLOCK][ ;-- file! inherits from url!
			to proto spec type
		][
			as red-url! string/make as red-string! proto spec type
		]
	]

	mold: func [
		url     [red-url!]
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
	][
		#if debug? = yes [if verbose > 0 [print-line "url/mold"]]

		limit: either OPTION?(arg) [
			int: as red-integer! arg
			int/value
		][0]

		s: GET_BUFFER(url)
		unit: GET_UNIT(s)
		p: (as byte-ptr! s/offset) + (url/head << (log-b unit))
		head: p

		tail: either zero? limit [						;@@ rework that part
			as byte-ptr! s/tail
		][
			either negative? part [p][p + (part << (log-b unit))]
		]
		if tail > as byte-ptr! s/tail [tail: as byte-ptr! s/tail]

		while [p < tail][
			cp: switch unit [
				Latin1 [as-integer p/value]
				UCS-2  [(as-integer p/2) << 8 + p/1]
				UCS-4  [p4: as int-ptr! p p4/value]
			]
			string/append-escaped-char buffer cp string/ESC_URL all?
			p: p + unit
		]

		return part - ((as-integer tail - head) >> (log-b unit)) - 1
	]
	
	to: func [
		proto	[red-value!]
		spec	[red-value!]
		type	[integer!]
		return:	[red-string!]
		/local
			buffer [red-string!]
			blk	   [red-block!]
			value  [red-value!]
			tail   [red-value!]
			s	   [series!]
			sep	   [byte!]
	][
		#if debug? = yes [if verbose > 0 [print-line "url/to"]]

		either all [type = TYPE_URL TYPE_OF(spec) = TYPE_BLOCK][ ;-- file! inherits from url!
			buffer: string/make-at proto 16 1
			buffer/header: TYPE_URL
			
			blk: as red-block! spec
			s: GET_BUFFER(blk)
			value: s/offset + blk/head
			tail: s/tail
			if value = tail [
				fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_URL spec]
			]
			actions/form value buffer null 0
			value: value + 1
			string/concatenate-literal buffer "://"
			if value = tail [return buffer]
			
			actions/form value buffer null 0
			value: value + 1
			if value = tail [return buffer]
			
			if TYPE_OF(value) = TYPE_INTEGER [
				string/concatenate-literal buffer ":"
				actions/form value buffer null 0
				value: value + 1
				if value = tail [return buffer]
			]
			string/append-char GET_BUFFER(buffer) as-integer #"/"
			until [
				actions/form value buffer null 0
				value: value + 1
				if value + 1 <= tail [
					sep: either TYPE_OF(value) = TYPE_ISSUE [#"#"][#"/"]
					string/append-char GET_BUFFER(buffer) as-integer sep
				]
				value = tail
			]
			buffer
		][
			string/to proto spec type
		]
	]

	eval-path: func [
		parent	[red-string!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			s	[series!] 
			new [red-string!]
			unit [integer!]
	][
		either value <> null [							;-- set-path
			fire [TO_ERROR(script bad-path-set) path element]
		][
			s: GET_BUFFER(parent)
			unit: GET_UNIT(s)
			new: string/make-at stack/push* 16 + string/rs-length? parent unit
			if (as-integer #"/") <> string/get-char (as byte-ptr! s/tail) - unit unit [
				string/concatenate-literal new "/"
			]
			actions/form element new null 0
			string/concatenate new parent -1 0 yes yes
			set-type as red-value! new TYPE_OF(parent)
		]
		as red-value! new
	]

	;-- I/O actions
	read: func [
		src		[red-value!]
		part	[red-value!]
		seek	[red-value!]
		binary? [logic!]
		lines?	[logic!]
		info?	[logic!]
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
		part: simple-io/request-http HTTP_GET as red-url! src null null binary? lines? info?
		if TYPE_OF(part) = TYPE_NONE [fire [TO_ERROR(access no-connect) src]]
		part
	]

	write: func [
		dest	[red-value!]
		data	[red-value!]
		binary? [logic!]
		lines?	[logic!]
		info?	[logic!]
		append? [logic!]
		part	[red-value!]
		seek	[red-value!]
		allow	[red-value!]
		as-arg	[red-value!]
		return:	[red-value!]
		/local
			blk		[red-block!]
			method	[red-word!]
			header	[red-block!]
			action	[integer!]
			sym		[integer!]
	][
		if any [
			OPTION?(seek)
			OPTION?(allow)
			OPTION?(as-arg)
		][
			--NOT_IMPLEMENTED--
		]

		either TYPE_OF(data) = TYPE_BLOCK [
			blk: as red-block! data
			either 0 = block/rs-length? blk [
				header: null
				action: HTTP_GET
			][
				method: as red-word! block/rs-head blk
				if TYPE_OF(method) <> TYPE_WORD [
					fire [TO_ERROR(script invalid-arg) method]
				]
				sym: symbol/resolve method/symbol
				action: case [
					sym = words/get  [HTTP_GET]
					sym = words/put  [HTTP_PUT]
					sym = words/post [HTTP_POST]
					true [--NOT_IMPLEMENTED-- 0]
				]
				either block/rs-next blk [null][
					header: as red-block! block/rs-head blk
					if TYPE_OF(header) <> TYPE_BLOCK [
						fire [TO_ERROR(script invalid-arg) header]
					]
				]
				data: as red-value! either block/rs-next blk [null][block/rs-head blk]
			]
		][
			header: null
			action: HTTP_POST
		]
		
		if all [
			data <> null
			TYPE_OF(data) <> TYPE_BLOCK
			TYPE_OF(data) <> TYPE_STRING
		][
			fire [TO_ERROR(script invalid-arg) data]
		]
		part: simple-io/request-http action as red-url! dest header data binary? lines? info?
		if TYPE_OF(part) = TYPE_NONE [fire [TO_ERROR(access no-connect) dest]]
		part
	]

	init: does [
		datatype/register [
			TYPE_URL
			TYPE_STRING
			"url!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			:to
			INHERIT_ACTION	;form
			:mold
			:eval-path
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
			INHERIT_ACTION	;change
			INHERIT_ACTION	;clear
			INHERIT_ACTION	;copy
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
