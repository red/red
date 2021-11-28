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
		ip [red-vector!]
	][
		#if debug? = yes [if verbose > 0 [print-line "ipv6/push"]]

		copy-cell as red-value! ip stack/push*
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
		/local
			s	   [series!]
			ip	   [red-vector!]
			int	   [red-integer!]
			value  [red-value!]
			tail   [red-value!]
			blk    [red-block!]
			p	   [byte-ptr!]
			i	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "IPv6/make-to"]]

		if TYPE_OF(spec) <> TYPE_BLOCK [
			fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(spec)]
		]
		blk: as red-block! spec
		s: GET_BUFFER(blk)
		value: s/offset + blk/head
		tail:  s/tail
		
		ip: make-at stack/push*
		s: GET_BUFFER(ip)
		p: as byte-ptr! s/offset
		
		while [value < tail][
			int: as red-integer! value
			i: int/value
			if any [TYPE_OF(int) <> TYPE_INTEGER i > FFFFh][
				fire [TO_ERROR(script bad-to-arg) proto spec]
			]
			if p >= as byte-ptr! s/tail [
				fire [TO_ERROR(script bad-to-arg) proto spec]
			]
			p/1: as-byte i >> 8
			p/2: as-byte i
			p: p + 2
			value: value + 1
		]
		stack/set-last as red-value! ip
		ip
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
			s	  [series!]
			p	  [byte-ptr!]
			c cnt [integer!]
			v4?   [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "ipv6/mold"]]
		
		s: GET_BUFFER(vec)
		p: as byte-ptr! s/offset
		v4?: s/flags and flag-embed-v4 <> 0
		cnt: either v4? [6][8]
		loop cnt [
			c: (as-integer p/1) << 8 or (as-integer p/2)
			either zero? c [
				string/append-char GET_BUFFER(buffer) as-integer #"0"
			][
				string/concatenate-literal buffer to-hex c
			]
			p: p + 2
			if p < as byte-ptr! s/tail [string/append-char GET_BUFFER(buffer) as-integer #":"]
		]
		if v4? [tuple/serialize p buffer 4 part]
		part - string/rs-length? buffer
	]
	
	eval-path: func [
		ip		[red-vector!]							;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		get?	[logic!]
		tail?	[logic!]
		return:	[red-value!]
		/local
			int  [red-integer!]
			set? [logic!]
	][
		set?: value <> null
		either TYPE_OF(element) <> TYPE_INTEGER [
			fire [TO_ERROR(script invalid-arg) element]
			null
		][
			int: as red-integer! element
			either set? [
				poke ip int/value value null
				value
			][
				_series/pick as red-series! ip int/value null
			]
		]
	]
	
	pick: func [
		ip		[red-vector!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			int		[red-integer!]
			s		[series!]
			offset	[integer!]
			p		[byte-ptr!]
	][
		#if debug? = yes [if verbose > 0 [print-line "IPv6/pick"]]

		offset: index - 1					;-- index is one-based
		either any [zero? index	offset < 0 offset > 8][none-value][
			s: GET_BUFFER(ip)
			p: (as byte-ptr! s/offset) + (offset << 1)
			int: as red-integer! stack/push*
			int/header: TYPE_INTEGER
			int/value: (as-integer p/1) << 8 + (as-integer p/2)
			as red-value! int
		]
	]

	poke: func [
		ip		[red-vector!]
		index	[integer!]
		data	[red-value!]
		boxed	[red-value!]
		return:	[red-value!]
		/local
			int	   [red-integer!]
			s	   [series!]
			offset [integer!]
			p	   [byte-ptr!]
			i	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "IPv6/poke"]]

		offset: index - 1					;-- index is one-based
		either any [zero? index	offset < 0 offset > 8][
			fire [TO_ERROR(script out-of-range)	integer/push index]
		][
			if TYPE_OF(data) <> TYPE_INTEGER [fire [TO_ERROR(script invalid-arg) data]]
			s: GET_BUFFER(ip)
			p: (as byte-ptr! s/offset) + (offset << 1)
			int: as red-integer! data
			i: int/value
			p/1: as-byte i >> 8
			p/2: as-byte i
			stack/set-last data
		]
		data
	]

	init: does [
		datatype/register [
			TYPE_IPV6
			TYPE_VECTOR
			"IPv6!"
			;-- General actions --
			:make
			INHERIT_ACTION	;random
			null			;reflect
			:make			;to
			:form
			:mold
			:eval-path
			null			;set-path
			INHERIT_ACTION	;compare
			;-- Scalar actions --
			null			;absolute
			INHERIT_ACTION	;add
			INHERIT_ACTION	;divide
			INHERIT_ACTION	;multiply
			null			;negate
			null			;power
			null			;remainder
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
			INHERIT_ACTION	;copy
			null			;find
			null			;head
			null			;head?
			null			;index?
			null			;insert
			null			;length?
			null			;move
			null			;next
			:pick
			:poke
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