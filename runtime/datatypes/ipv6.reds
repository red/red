Red/System [
	Title:   "Vector! datatype runtime functions"
	Author:  "Nenad Rakocevic"
	File: 	 %ipv6.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2021 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

ipv6: context [
	verbose: 0

	to-hex: func [
		cp		[integer!]
		return: [c-string!]
		/local
			s [c-string!]
			h [c-string!]
			c [integer!]
			i [integer!]
	][	
		s: "00000000"
		h: "0123456789ABCDEF"
		c: 8
		while [cp <> 0][
			i: cp and 15 + 1							;-- cp // 16 + 1
			s/c: h/i
			cp: cp >> 4
			c: c - 1
		]
		s + c
	]
	
	push: func [
		vec [red-vector!]
	][
		#if debug? = yes [if verbose > 0 [print-line "ipv6/push"]]

		copy-cell as red-value! vec stack/push*
	]
	
	make-at: func [
		slot	[red-value!]
		return: [red-vector!]
		/local
			vec [red-vector!]
			s	[series!]
	][
		vec: as red-vector! slot
		vec/header: TYPE_UNSET
		vec/head: 	0
		vec/node: 	alloc-bytes-filled 16 null-byte
		vec/type:	TYPE_INTEGER
		vec/header: TYPE_IPV6						;-- implicit reset of all header flags
		
		s: GET_BUFFER(vec)
		s/tail: s/offset + 1						;-- 1 cell! = 16 bytes
		s/flags: s/flags and flag-unit-mask or 2	;-- unit: 2 bytes (16-bit)
		vec
	]

	;--- Actions ---
	
	make: func [
		proto	[red-value!]
		spec	[red-value!]
		dtype	[integer!]
		return:	[red-vector!]
	][
		#if debug? = yes [if verbose > 0 [print-line "ipv6/make"]]

		null
	]
	
	form: func [
		vec		[red-vector!]
		buffer	[red-string!]
		arg		[red-value!]
		part 	[integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "ipv6/form"]]
		
		mold vec buffer no no no arg part 0
	]
	
	mold: func [
		vec		[red-vector!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part	[integer!]
		indent	[integer!]
		return:	[integer!]
		/local
			s [series!]
			p [byte-ptr!]
			c [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "ipv6/mold"]]
		
		s: GET_BUFFER(vec)
		p: as byte-ptr! s/offset
		loop 8 [
			c: (as-integer p/1) << 8 or (as-integer p/2)
			either zero? c [
				string/append-char GET_BUFFER(buffer) as-integer #"0"
			][
				string/concatenate-literal buffer to-hex c
			]
			p: p + 2
			if p < as byte-ptr! s/tail [string/append-char GET_BUFFER(buffer) as-integer #":"]
		]
		part - string/rs-length? buffer		
	]

	;--- Modifying actions ---

	init: does [
		datatype/register [
			TYPE_IPV6
			TYPE_VECTOR
			"IPv6!"
			;-- General actions --
			:make
			INHERIT_ACTION	;random
			INHERIT_ACTION	;reflect
			null			;to
			:form
			:mold
			INHERIT_ACTION	;eval-path
			null			;set-path
			INHERIT_ACTION	;compare
			;-- Scalar actions --
			null			;absolute
			INHERIT_ACTION	;add
			INHERIT_ACTION	;divide
			INHERIT_ACTION	;multiply
			null			;negate
			null			;power
			INHERIT_ACTION	;remainder
			null			;round
			INHERIT_ACTION	;subtract
			null			;even?
			null			;odd?
			;-- Bitwise actions --
			INHERIT_ACTION	;and~
			null			;complement
			INHERIT_ACTION	;or~
			INHERIT_ACTION	;xor~
			;-- Series actions --
			null			;append
			null			;at
			null			;back
			null			;change
			null			;clear
			null			;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;move
			null			;next
			null			;pick
			null			;poke
			null			;put
			null			;remove
			null			;reverse
			null			;select
			null			;sort
			null			;skip
			null			;swap
			null			;tail
			null			;tail?
			null			;take
			null			;trim
			;-- I/O actions --
			null			;create
			null			;close
			null			;delete
			null		;modify
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