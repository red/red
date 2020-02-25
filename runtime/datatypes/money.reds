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
	
	SIZE_DIGITS:   SIZE_BYTES * 2
	SIZE_INTEGRAL: SIZE_DIGITS - SIZE_SCALE
	
	#define HIGH_NIBBLE #"^(0F)"
	#define LOW_NIBBLE  #"^(F0)"
	
	#define SIGN_MASK   4000h
	#define SIGN_OFFSET 14
	
	#define MAX_INT_DIGITS 10
	
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
	
	zero-out: func [
		money [red-money!]
		all?  [logic!]
	][
		money/amount1: either all? [0][money/amount1 and FF000000h]
		money/amount2: 0
		money/amount3: 0
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
		byte:   index >>> 1 + bit
		offset: either as logic! bit [4][0]
		
		as integer! amount/byte
			and (HIGH_NIBBLE << offset)
			>>> offset
	]
	
	set-digit: func [
		amount  [byte-ptr!]
		index   [integer!]
		value   [integer!]
		/local
			bit byte offset reverse
			[integer!]
	][
		bit:     index and 1
		byte:    index >>> 1 + bit
		offset:  either as logic! bit [4][0]
		reverse: either offset = 0 [4][0]
		
		amount/byte: amount/byte
			and (HIGH_NIBBLE << reverse)
			or  as byte! (value << offset)
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

	from-integer: func [
		money   [red-money!]
		int     [integer!]
		return: [red-money!]
		/local
			amount
			[byte-ptr!]
			extra start index power digit
			[integer!]
	][
		zero-out money yes
		if int = 0 [return money]
		
		set-sign money as integer! int < 0
		
		extra: as integer! int = (1 << 31)
		int:   integer/abs int + extra
		
		amount: get-amount money
		start:  SIZE_DIGITS - SIZE_SCALE
		index:  start
		
		loop MAX_INT_DIGITS [
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
	
	;-- Natives --
	
	negative-money?: func [
		money   [red-money!]
		return: [logic!]
	][
		-1 = sign? money
	]
	
	zero-money?: func [
		money   [red-money!]
		return: [logic!]
	][
		0 = sign? money
	]
	
	positive-money?: func [
		money   [red-money!]
		return: [logic!]
	][
		1 = sign? money
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
				money:   from-integer money integer/value
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
		
		if sign < 0 [
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
	
	compare:   STUB
	
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
				null;:compare
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
