Red/System [
	Title:   "Money! datatype runtime functions"
	Author:  "Vladimir Vasilyev"
	File: 	 %money.reds
	Tabs:	 4
	Rights:  "Copyright (C) 2020 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

#define STUB [func [][--NOT_IMPLEMENTED--]]

money: context [
	verbose: 0
	
	#enum sizes! [
		SIZE_BYTES: 11
		SIZE_SCALE: 05
	]
	
	#enum signs! [
	;-- 		 -0+
	;--			-101
	;-- 	+1	 012
	
		SIGN_--: 00h
		SIGN_-0: 01h
		SIGN_-+: 02h
		
		SIGN_0-: 10h
		SIGN_00: 11h
		SIGN_0+: 12h
		
		SIGN_+-: 20h
		SIGN_+0: 21h
		SIGN_++: 22h
	]
	
	#define DISPATCH_SIGNS(this that) [switch collate-signs this that]
	#define SWAP_ARGUMENTS(this that) [use [hold][hold: this this: that that: hold]]
	
	SIZE_DIGITS:   SIZE_BYTES * 2
	SIZE_INTEGRAL: SIZE_DIGITS - SIZE_SCALE
	
	HIGH_NIBBLE: #"^(0F)"
	LOW_NIBBLE:  #"^(F0)"
	
	SIGN_MASK:   4000h
	SIGN_OFFSET: 14
	
	INT32_MAX_DIGITS: 10
	INT32_MIN_AMOUNT: #{00000002147483648FFFFF}
	INT32_MAX_AMOUNT: #{00000002147483647FFFFF}
	
	;-- Support --
	
	get-sign: func [
		money   [red-money!]
		return: [integer!]
	][
		money/header and SIGN_MASK >> SIGN_OFFSET
	]
	
	set-sign: func [
		money   [red-money!]
		sign    [integer!]
		return: [red-money!]
	][
		money/header: money/header
			and (not SIGN_MASK)
			or  (sign << SIGN_OFFSET)
		
		money
	]
	
	flip-sign: func [
		money   [red-money!]
		return: [red-money!]
	][
		set-sign money as integer! not as logic! get-sign money
	]
	
	collate-signs: func [
		this    [integer!]
		that    [integer!]
		return: [integer!]
	][
		this + 1 << 4 or (that + 1)
	]
	
	get-amount: func [
		money   [red-money!]
		return: [byte-ptr!]
	][
		(as byte-ptr! money) + (size? money) - SIZE_BYTES
	]

	zero-amount?: func [
		amount  [byte-ptr!]
		return: [logic!]
	][
		loop SIZE_BYTES [
			unless null-byte = amount/value [return no]
			amount: amount + 1
		]
		
		yes
	]
	
	compare-amounts: func [
		this    [byte-ptr!]
		that    [byte-ptr!]
		return: [integer!]
	][
		compare-memory this that SIZE_BYTES
	]
	
	zero-out: func [
		money   [red-money!]
		all?    [logic!]
		return: [red-money!]
	][
		money/amount1: either all? [0][money/amount1 and FF000000h]
		money/amount2: 0
		money/amount3: 0
		
		money
	]
	
	get-digit: func [
		amount  [byte-ptr!]
		index   [integer!]
		return: [integer!]
		/local
			bit byte offset
			[integer!]
	][
		bit:    index and 1
		byte:   index >> 1 + bit
		offset: either as logic! bit [4][0]
		
		as integer! amount/byte
			and (HIGH_NIBBLE << offset)
			>>> offset
	]
	
	set-digit: func [
		amount [byte-ptr!]
		index  [integer!]
		value  [integer!]
		/local
			bit byte offset reverse
			[integer!]
	][
		bit:     index and 1
		byte:    index >> 1 + bit
		offset:  either as logic! bit [4][0]
		reverse: either zero? offset  [4][0]
		
		amount/byte: amount/byte
			and (HIGH_NIBBLE << reverse)
			or  as byte! (value << offset)
	]
	
	count-digits: func [
		amount  [byte-ptr!]
		return: [integer!]
		/local
			count [integer!]
	][
		count: SIZE_DIGITS
		loop SIZE_BYTES [
			either null-byte = amount/value [count: count - 2][
				count: count - as integer! null-byte = (amount/value and LOW_NIBBLE)
				break
			]
			amount: amount + 1
		]
		
		either zero? count [1][count]
	]
	
	make-at: func [
		slot	[red-value!]
		sign    [integer!]
		amount1 [integer!]
		amount2 [integer!]
		amount3 [integer!]
		return:	[red-money!]
		/local
			money [red-money!]
	][
		money: as red-money! slot
		money/header: TYPE_MONEY or (sign << SIGN_OFFSET)
		money/amount1: amount1
		money/amount2: amount2
		money/amount3: amount3
		
		money
	]
	
	make-in: func [
		parent  [red-block!]
		sign    [integer!]
		amount1 [integer!]
		amount2 [integer!]
		amount3 [integer!]
		return: [red-money!]
	][
		make-at ALLOC_TAIL(parent) sign amount1 amount2 amount3
	]
	
	push: func [
		sign    [integer!]
		amount1 [integer!]
		amount2 [integer!]
		amount3 [integer!]
		return: [red-money!]
	][
		make-at stack/push* sign amount1 amount2 amount3
	]
	
	overflow?: func [
		money   [red-money!]
		return: [logic!]
		/local
			amount limit
			[byte-ptr!]
			sign count
			[integer!]
	][
		sign: sign? money
		if zero? sign [return no]
		
		amount: get-amount money
		count:  (count-digits amount) - SIZE_SCALE
		if count <> INT32_MAX_DIGITS [return count > INT32_MAX_DIGITS]
		
		limit: either negative? sign [INT32_MIN_AMOUNT][INT32_MAX_AMOUNT]
		positive? compare-amounts amount limit
	]
	
	to-integer: func [
		money   [red-money!]
		return: [integer!]
		/local
			amount
			[byte-ptr!]
			sign integer index start power digit
			[integer!]
	][
		sign: sign? money
		
		if zero? sign [return sign]
	
		amount:  get-amount money
		integer: 0
		index:   SIZE_INTEGRAL
		start:   index
		
		loop INT32_MAX_DIGITS [
			digit:   get-digit amount index
			power:   as integer! pow 10.0 as float! start - index
			integer: integer + (digit * power)
			
			index: index - 1
		]
		
		sign * integer
	]

	from-integer: func [
		int     [integer!]
		return: [red-money!]
		/local
			money
			[red-money!]
			amount
			[byte-ptr!]
			extra index start power digit
			[integer!]
	][
		money: zero-out as red-money! stack/push* yes
		money/header: TYPE_MONEY
		
		if zero? int [return money]
		
		set-sign money as integer! negative? int
		
		extra: as integer! int = (1 << 31)
		int:   integer/abs int + extra
		
		amount: get-amount money
		index:  SIZE_INTEGRAL
		start:  index
		
		loop INT32_MAX_DIGITS [
			power: as integer! pow 10.0 as float! start - index
			digit: int / power // 10
			
			unless zero? digit [set-digit amount index digit]
			
			index: index - 1
		]
		
		unless zero? extra [
			set-digit amount start extra + get-digit amount start
		]
		
		money
	]
		
	compare-money: func [
		this    [red-money!]
		that    [red-money!]
		return: [integer!]
		/local
			this-sign that-sign
			[integer!]
	][
		;@@ TBD: take currencies into account
	
		this-sign: sign? this
		that-sign: sign? that
		
		DISPATCH_SIGNS(this-sign that-sign)[
			SIGN_-- [SWAP_ARGUMENTS(this that) 0]
			SIGN_++ [0]
			default [return integer/sign? this-sign - that-sign]
		]
		
		integer/sign? compare-amounts get-amount this get-amount that
	]
	
	negative-money?: func [
		money   [red-money!]
		return: [logic!]
	][
		negative? sign? money
	]
	
	zero-money?: func [
		money   [red-money!]
		return: [logic!]
	][
		zero? sign? money
	]
	
	positive-money?: func [
		money   [red-money!]
		return: [logic!]
	][
		positive? sign? money
	]
	
	sign?: func [
		money   [red-money!]
		return: [integer!]
	][
		either zero-amount? get-amount money [0][
			either as logic! get-sign money [-1][+1]
		]
	]
		
	;-- Actions --

	make: func [
		proto   [red-value!]
		spec    [red-value!]
		type    [integer!]
		return: [red-money!]
		/local
			money   [red-money!]
			integer [red-integer!]
	][
		if TYPE_OF(spec) = TYPE_MONEY [return as red-money! spec]
		
		money: as red-money! proto
		money/header: TYPE_MONEY
		
		switch TYPE_OF(spec) [
			TYPE_INTEGER [
				integer: as red-integer! spec
				money:   from-integer integer/value
			]
			TYPE_FLOAT [--NOT_IMPLEMENTED--]
			default [
				fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_MONEY spec]
			]
		]
		
		money
	]
	
	;-- to: :make

	form: func [
		money   [red-money!]
		buffer  [red-string!]
		arg     [red-value!]
		part    [integer!]
		return: [integer!]
		/local
			amount [byte-ptr!]
			sign   [integer!]
	][
		amount: get-amount money
		sign:   sign? money
		
		if negative? sign [
			string/concatenate-literal buffer "-"
			part: part - 1
		]
		
		string/concatenate-literal buffer "$"
		
		loop SIZE_BYTES [
			string/concatenate-literal
				buffer
				string/byte-to-hex as integer! amount/value
				
			amount: amount + 1
		]
		
		part - SIZE_DIGITS - 1
	]
	
	mold: func [
		money   [red-money!]
		buffer  [red-string!]
		only?   [logic!]
		all?    [logic!]
		flat?   [logic!]
		arg     [red-value!]
		part    [integer!]
		indent  [integer!]		
		return: [integer!]
	][
		form money buffer arg part
	]
	
	random:    STUB
	
	compare: func [
		money   [red-money!]
		value   [red-money!]
		op      [integer!]
		return: [integer!]
		/local
			int [red-integer!]
	][
		if all [
			TYPE_OF(money) <> TYPE_OF(value)
			any [
				op = COMP_SORT
				op = COMP_CASE_SORT
				op = COMP_FIND
				op = COMP_SAME
				op = COMP_STRICT_EQUAL
			]
		][
			return 1
		]
		
		switch TYPE_OF(value) [
			TYPE_MONEY [0]
			TYPE_INTEGER [
				int:   as red-integer! value
				value: from-integer int/value
			]
			TYPE_FLOAT [--NOT_IMPLEMENTED--]
			default [RETURN_COMPARE_OTHER]
		]
		
		compare-money money value
	]
	
	absolute: func [return: [red-money!]][
		set-sign as red-money! stack/arguments 0
	]
	
	negate: func [return: [red-money!]][
		flip-sign as red-money! stack/arguments
	]
	
	add:       STUB
	subtract:  STUB
	multiply:  STUB
	divide:    STUB
	remainder: STUB
	
	round:     STUB
	
	even?: func [
		money   [red-money!]
		return: [logic!]
	][
		not odd? money
	]
	
	odd?: func [
		money   [red-money!]
		return: [logic!]
		/local
			digit [integer!]
	][
		digit: get-digit get-amount money SIZE_INTEGRAL
		as logic! digit and 1
	]

	init: does [
		datatype/register [
			TYPE_MONEY
			TYPE_VALUE
			"money!"
			;-- General actions --
			:make
				null;:random
			null			;reflect
			:make
			:form
			:mold
			null			;eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute
				null;:add
				null;:divide
				null;:multiply
			:negate
			null			;power
				null;:remainder
				null;:round
				null;:subtract
			:even?
			:odd?
			;-- Bitwise actions --
			null			;and~
			null			;complement
			null			;or~
			null			;xor~
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
]
