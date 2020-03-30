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

money: context [
	verbose: 0
	
	;-- Base --
		
	#enum sizes! [
		SIZE_BYTES: 11								;-- total number of bytes used to store amount
		SIZE_SCALE: 05								;-- total number of digits (nibbles) used to store scale (fractional part)
	]
	
	SIZE_DIGITS:   SIZE_BYTES * 2					;-- total number of digits (nibbles) used to store amount
	SIZE_INTEGRAL: SIZE_DIGITS - SIZE_SCALE			;-- size of an integral part (digits)
	
	SIZE_UNNORM: SIZE_DIGITS + SIZE_SCALE					;-- size of unnormalized result (digits)
	SIZE_BUFFER: (SIZE_UNNORM + (SIZE_UNNORM and 1)) >> 1	;-- size of memory portion that stores unnormalized result (bytes)
	
	SIZE_SBYTES: (SIZE_BUFFER + size? integer!) - (SIZE_BUFFER // size? integer!)
	SIZE_SSLOTS: SIZE_SBYTES >> 2					;-- total number of bytes / stack slots allocated to hold unnormalized result
	
	HIGH_NIBBLE: #"^(0F)"
	LOW_NIBBLE:  #"^(F0)"
	
	SIGN_MASK:   4000h								;-- used to get/set sign bit in the header
	SIGN_OFFSET: 14
	
	HALF_FRACTIONAL: 00000500h						;-- used for tie-breaking in round (little-endian order)
	KEEP_FRACTIONAL: FFFF0F00h						;-- used to extract fractional part (little-endian order)
	MAX_FRACTIONAL:  as integer! (pow 10.0 as float! SIZE_SCALE) - 1.0
	
	INT32_MAX_DIGITS: 10
	INT32_MIN_AMOUNT: #{00000002147483648FFFFF}		;-- 0xF > 0x9, used to subvert comparison
	INT32_MAX_AMOUNT: #{00000002147483647FFFFF}
	
	#enum signs! [
	;--    sign	 -0+
	;--	integer	-101
	;-- 	 +1	 012
	
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
	
	#enum make-states! [
		S_START
		S_CURRENCY
		S_INTEGRAL
		S_FRACTIONAL
		S_END
	]
	
	#define SWAP_ARGUMENTS [use [hold][hold: value1 value1: value2 value2: hold]]
	#define DISPATCH_SIGNS [switch collate-signs sign1 sign2]
	#define MONEY_OVERFLOW [fire [TO_ERROR(script type-limit) datatype/push TYPE_MONEY]]
	
	;-- Sign --
	
	get-sign: func [
		money   [red-money!]
		return: [integer!]
	][
		money/header and SIGN_MASK >>> SIGN_OFFSET
	]
	
	set-sign: func [
		money   [red-money!]
		sign    [integer!]
		return: [red-money!]
	][
		assert any [sign = 0 sign = 1]
		money/header: money/header and (not SIGN_MASK) or (sign << SIGN_OFFSET)
		money
	]
	
	flip-sign: func [
		money   [red-money!]
		return: [red-money!]
	][
		set-sign money as integer! not as logic! get-sign money
	]
	
	collate-signs: func [
		sign1   [integer!]
		sign2   [integer!]
		return: [integer!]
	][
		assert all [1 >= integer/abs sign1 1 >= integer/abs sign2]
		sign1 + 1 << 4 or (sign2 + 1)
	]
	
	;-- Currency --
	
	get-currency-from: func [
		money   [red-money!]
		return: [red-value!]						;-- word or none
		/local
			index [integer!]
	][
		index: get-currency money
		if zero? index [return none/push]			;-- generic currency
		
		;@@ TBD: check extra list also
		block/rs-abs-at
			as red-block! #get system/locale/currencies/base
			index
	]
	
	get-currency: func [
		money   [red-money!]
		return: [integer!]
		/local
			place [byte-ptr!]
	][
		place: as byte-ptr! :money/amount1
		as integer! place/value
	]
	
	set-currency: func [
		money   [red-money!]
		index   [integer!]
		return: [red-money!]
		/local
			place [byte-ptr!]
	][
		assert all [index >= 0 index <= FFh]
		place: as byte-ptr! :money/amount1
		place/value: as byte! index
		money
	]
	
	get-index: func [
		sym     [integer!]
		return: [integer!]							;-- -1: invalid currency code
		/local
			list      [red-block!]
			here      [red-word!]
			head tail [red-value!]
			index     [integer!]
	][
		list: as red-block! #get system/locale/currencies/base
		head: block/rs-head list
		tail: block/rs-tail list
		here: as red-word! head
		
		index: 0
		until [
			if sym = symbol/resolve here/symbol [break]
			index: index + 1
			here:  here + 1
			
			here = tail
		]
		
		;@@ TBD: walk over extra list also
		either here = tail [-1][index]
	]
		
	get-symbol: func [
		index   [integer!]
		return: [integer!]
		/local
			base [red-block!]
			word [red-word!]
	][
		assert all [index > 0 index <= FFh]
		
		base: as red-block! #get system/locale/currencies/base
		word: as red-word! block/rs-abs-at base index
		
		;@@ TBD: walk over extra list also
		symbol/resolve word/symbol
	]
	
	same-currencies?: func [
		value1  [red-money!]
		value2  [red-money!]
		return: [logic!]
		/local
			currency1 [integer!]
			currency2 [integer!]
	][
		currency1: get-currency value1
		currency2: get-currency value2
	
		any [
			zero? currency1							;-- 0: generic currency
			zero? currency2
			currency1 = currency2
		]
	]
	
	;-- Amount --
	
	get-amount-from: func [
		money   [red-money!]
		return: [red-value!]
	][
		as red-value! set-currency					;-- same value but without currency
			as red-money! stack/push as red-value! money
			0
	]
	
	get-amount: func [
		money   [red-money!]
		return: [byte-ptr!]
	][
		(as byte-ptr! :money/amount1) + 1
	]
	
	set-amount: func [
		money   [red-money!]
		amount  [byte-ptr!]
		return: [red-money!]
	][
		copy-memory get-amount money amount SIZE_BYTES
		money
	]
	
	zero-amount?: func [
		amount  [byte-ptr!]
		return: [logic!]
		/local
			payload [int-ptr!]
	][
		payload: as int-ptr! amount - 1
		all [
			zero? (payload/1 and not FFh)			;-- little-endian order
			zero? payload/2
			zero? payload/3
		]
	]
	
	compare-amounts: func [
		amount1 [byte-ptr!]
		amount2 [byte-ptr!]
		return: [integer!]
	][
		compare-memory amount1 amount2 SIZE_BYTES
	]
	
	zero-out: func [
		money   [red-money!]
		return: [red-money!]
	][
		money/amount1: 0
		money/amount2: 0
		money/amount3: 0
		money
	]
	
	shift-left: func [
		amount  [byte-ptr!]
		size    [integer!]
		offset  [integer!]
		return: [byte-ptr!]
		/local
			index1 [integer!]
			index2 [integer!]
			half   [byte!]
	][
		loop offset [
			index1: 1
			index2: index1 + 1
			loop size [
				half: either index2 > size [null-byte][amount/index2 >>> 4]
				amount/index1: amount/index1 << 4 or half
				
				index1: index1 + 1
				index2: index2 + 1
			]
		]
		
		amount
	]
	
	shift-right: func [
		amount  [byte-ptr!]
		size    [integer!]
		offset  [integer!]
		return: [byte-ptr!]
		/local
			index1 [integer!]
			index2 [integer!]
			half   [byte!]
	][
		loop offset [
			index1: size
			index2: index1 - 1
			loop size [
				half: either index2 < 1 [null-byte][amount/index2 << 4]
				amount/index1: amount/index1 >>> 4 or half
				
				index1: index1 - 1
				index2: index2 - 1
			]
		]
		
		amount
	]
	
	;-- Digits --
	
	get-digit: func [
		amount  [byte-ptr!]
		index   [integer!]
		return: [integer!]
		/local
			bit byte offset [integer!]
	][
		assert positive? index
		
		bit:    index and 1
		byte:   index >> 1 + bit
		offset: either as logic! bit [4][0]
		
		as integer! amount/byte and (HIGH_NIBBLE << offset) >>> offset
	]
	
	set-digit: func [
		amount [byte-ptr!]
		index  [integer!]
		value  [integer!]
		/local
			bit byte offset reverse [integer!]
	][
		assert positive? index
		assert all [value >= 0 value <= 9]
	
		bit:     index and 1
		byte:    index >> 1 + bit
		offset:  either as logic! bit [4][0]
		reverse: either zero? offset  [4][0]
		
		amount/byte: amount/byte and (HIGH_NIBBLE << reverse) or as byte! (value << offset)
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
		
		either zero? count [1][count]				;-- 0 is a single digit
	]
	
	;-- Slices --
	
	compare-slices: func [
		buffer1 [byte-ptr!] high1? [logic!] count1 [integer!]
		buffer2 [byte-ptr!] high2? [logic!] count2 [integer!]
		return: [integer!]
		/local
			delta index1 index2 end digit1 digit2 [integer!]
	][
		delta: integer/abs count1 - count2
		switch integer/sign? count1 - count2 [
			-1 [index1: 1 - delta index2: 1 end: count2]
			00 [index1: 1         index2: 1 end: count1]
			+1 [index2: 1 - delta index1: 1 end: count1]
			default [0]
		]
		
		index1: index1 + as integer! high1?
		index2: index2 + as integer! high2?
		
		until [
			digit1: either index1 < 1 [0][get-digit buffer1 index1]
			digit2: either index2 < 1 [0][get-digit buffer2 index2]
		
			index1: index1 + 1
			index2: index2 + 1
			end:    end - 1
			
			any [digit1 <> digit2 zero? end]
		]
		
		digit1 - digit2
	]
	
	subtract-slice: func [
		buffer1 [byte-ptr!] high1? [logic!] count1 [integer!]
		buffer2 [byte-ptr!] high2? [logic!] count2 [integer!]
		/local
			digit1 digit2 borrow difference [integer!]
	][
		count1: count1 + as integer! high1?
		count2: count2 + as integer! high2?
		borrow: 0
		until [
			digit1: get-digit buffer1 count1
			digit2: either count2 < 1 [0][get-digit buffer2 count2]
			
			difference: digit1 - digit2 - borrow	;-- assumming buffer1 >= buffer2 
			borrow: as integer! difference < 0
			if as logic! borrow [difference: difference + 10]
			
			set-digit buffer1 count1 difference
			
			count1: count1 - 1
			count2: count2 - 1
			
			zero? count1
		]
	]
	
	;-- Construction --
	
	make-at: func [
		slot     [red-value!]
		sign     [logic!]							;-- yes: negative
		currency [byte-ptr!]						;-- can be null if currency code is not present
		start    [byte-ptr!]						;-- $ sign
		point    [byte-ptr!]						;-- can be null if fractional part is not present
		end      [byte-ptr!]						;-- points past the money literal
		return:  [red-money!]						;-- null if currency code is invalid
		/local
			convert           [subroutine!]
			money             [red-money!]
			amount limit here [byte-ptr!]
			str               [c-string!]
			index stop step   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/make-at"]]
		
		money: as red-money! slot
		money/header: TYPE_MONEY
		
		zero-out money
		set-sign money as integer! sign
		
		;-- currency code
		unless null? currency [
			index: get-index symbol/make-alt-utf8 currency 3
			if negative? index [return null]		;-- throw it back to lexer for proper error reporting
			set-currency money index
		]
		
		amount: get-amount money
		
		convert: [
			here: here + step
			until [
				if here/value = #"'" [here: here + step continue]	;-- skip thousands separators
				set-digit amount index as integer! here/value - #"0"
				
				here:  here + step
				index: index + step
				any [index = stop here = limit]
			]
		]
		
		;-- integral part
		here:  either null? point [end][point]
		limit: start
		index: SIZE_INTEGRAL
		stop:  0
		step:  -1
		
		convert
		
		if null? point [return money]
		
		;-- fractional part
		here:  point
		limit: end
		index: SIZE_INTEGRAL + 1
		stop:  SIZE_DIGITS + 1
		step:  +1
		
		convert
		
		money
	]
	
	make-in: func [
		slot     [red-value!]
		sign     [logic!]							;-- yes: negative
		currency [c-string!]						;-- null if generic currency, otherwise 3 bytes
		amount   [byte-ptr!]						;-- always SIZE_BYTES bytes
		return:  [red-money!]
		/local
			money [red-money!]
			index [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/make-in"]]
		
		money: as red-money! slot
		money/header: TYPE_MONEY
		
		set-sign money as integer! sign
		set-amount money amount
		
		;@@ TBD: assuming currency code is valid
		index: either null? currency [0][get-index symbol/make currency]
		set-currency money index
		
		money
	]
	
	push: func [
		sign     [logic!]							;-- yes: negative
		currency [c-string!]						;-- null if generic currency, otherwise 3-letter string
		amount   [c-string!]						;-- always SIZE_BYTES bytes
		return:  [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/push"]]
		make-in stack/push* sign currency as byte-ptr! amount
	]
	
	form-money: func [
		money   [red-money!]
		buffer  [red-string!]
		part    [integer!]
		all?	[logic!]							;-- yes: display all SIZE_SCALE fractional digits
		group?  [logic!]							;-- yes: decorate amount with thousand's separators
		return: [integer!]
		/local
			fill        [subroutine!]
			base        [red-block!]
			sym         [red-string!]
			word        [red-word!]
			after       [red-integer!]
			amount      [byte-ptr!]
			sign count  [integer!]
			index times [integer!]
	][
		amount: get-amount money
		sign:   sign? money
		
		;-- sign
		if negative? sign [
			string/concatenate-literal buffer "-"
			part: part - 1
		]
		
		;-- currency code
		index: get-currency money
		unless zero? index [						;-- generic currency
			sym: as red-string! symbol/get get-symbol index
			string/concatenate buffer sym -1 0 yes no
			part: part - string/rs-length? sym
		]
		
		string/concatenate-literal buffer "$"
		
		count: count-digits amount
		index: SIZE_DIGITS - count + 1
		
		fill: [
			loop times [
				string/concatenate-literal
					buffer
					integer/form-signed get-digit amount index
				
				if all [group? zero? (index + 1 // 3) index <> SIZE_INTEGRAL][
					string/concatenate-literal buffer "'"
					part: part - 1
				]
				
				index: index + 1
				part:  part - 1
			]		
		]
		
		;-- integral part
		times: count - SIZE_SCALE
		either positive? times [fill][
			string/concatenate-literal buffer "0"
			index: SIZE_INTEGRAL + 1
			part:  part - 1
		]
		
		;-- fractional part
		after: as red-integer! #get system/options/money-digits
		times: after/value
		if any [all? times > SIZE_SCALE][times: SIZE_SCALE]
		if positive? times [
			string/concatenate-literal buffer "."
			group?: no
			fill
		]
		
		part - 2									;-- compensate for $ and . characters
	]
	
	;-- Deconstruction --
	
	accessor!: alias function! [money [red-money!] return: [red-value!]]
	
	resolve-accessor: func [
		word    [red-word!]
		return: [integer!]
		/local
			sym [integer!]
	][
		sym: symbol/resolve word/symbol
		case [
			sym = words/code   [1]
			sym = words/amount [2]
			true [0]
		]
	]
	
	;-- Conversion --
	
	overflow?: func [
		money   [red-money!]
		return: [logic!]
		/local
			amount limit [byte-ptr!]
			sign count   [integer!]
	][
		sign: sign? money
		if zero? sign [return no]
		
		amount: get-amount money
		count:  (count-digits amount) - SIZE_SCALE
		if count <> INT32_MAX_DIGITS [return count > INT32_MAX_DIGITS]
		
		limit: either negative? sign [INT32_MIN_AMOUNT][INT32_MAX_AMOUNT]	;-- worst case: need to compare amount with constant buffers (equal size)
		positive? compare-amounts amount limit
	]
	
	to-integer: func [
		money   [red-money!]
		return: [integer!]
		/local
			amount             [byte-ptr!]
			sign integer index [integer!]
			start power digit  [integer!]
	][
		if overflow? money [fire [TO_ERROR(script type-limit) datatype/push TYPE_INTEGER]]
	
		sign: sign? money
		if zero? sign [return 0]
	
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
			money             [red-money!]
			amount            [byte-ptr!]
			extra index start [integer!]
			power digit       [integer!]
	][
		money: zero-out as red-money! stack/push*
		money/header: TYPE_MONEY
		
		if zero? int [return money]
		
		set-sign money as integer! negative? int
		
		extra: as integer! int = (1 << 31)			;-- if it's an integer minimum, prevent math overflow
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
		
		unless zero? extra [						;-- compensate for overflow prevention
			set-digit amount start extra + get-digit amount start
		]
		
		money
	]
	
	to-float: func [
		money   [red-money!]
		return: [float!]
		/local
			buffer       [red-string!]
			head         [byte-ptr!]
			float        [float!]
			sign delta   [integer!]
			length error [integer!]
	][
		sign: sign? money
		
		if zero? sign [return 0.0]
	
		buffer: string/make-at stack/push* SIZE_DIGITS + 6 Latin1	;-- max number of digits and -CCC$.
		form-money money buffer 0 yes no							;-- take all fractional digits into account
		
		delta:  (string/rs-find buffer as integer! #"$") + 1
		head:   (string/rs-head buffer) + delta
		length: (string/rs-length? buffer) - delta
		
		error: 0
		float: string/to-float head length :error
		stack/pop 1
		
		unless zero? error [
			fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_FLOAT money]
		]
		
		float * as float! sign
	]
	
	from-float: func [
		flt     [float!]
		return: [red-money!]
		/local
			money     [red-money!]
			formed    [c-string!]
			start end [byte-ptr!]
			point     [byte-ptr!]
			sign      [logic!]
	][
		formed: dtoa/form-float flt SIZE_DIGITS yes
		
		if (length? formed) > 19 [MONEY_OVERFLOW]	;-- e-notation for exponents larger than 16
		
		point: as byte-ptr! formed
		until [point: point + 1 point/value = #"."]
		
		if point/2 = #"#" [							;-- 1.#NaN, 1.#INF, -1.#INF
			fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_MONEY float/box flt]
		]
		
		if point/3 = #"e" [MONEY_OVERFLOW]			;-- e-notation for exponents smaller than -7
		
		sign:  formed/1 = #"-"
		start: as byte-ptr! either sign [formed][formed - 1]
		end:   as byte-ptr! formed + length? formed
		
		money: make-at stack/push* sign null start point end
		if all [0.0 <> flt zero-money? money][MONEY_OVERFLOW]	;-- underflow on too small float value
		money
	]
	
	to-binary: func [
		money   [red-money!]
		return: [red-binary!]
	][
		binary/load-in get-amount money SIZE_BYTES null
	]
	
	from-binary: func [
		bin     [red-binary!]
		return: [red-money!]
		/local
			money  [red-money!]
			head   [byte-ptr!]
			length [integer!]
			index  [integer!]
	][
		length: binary/rs-length? bin
		if length > SIZE_BYTES [length: SIZE_BYTES]	;-- take only first SIZE_BYTES bytes into account
		
		head: binary/rs-head bin
		index: 1
		loop length << 1 [
			if 9 < get-digit head index [
				fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_MONEY bin]
			]
			index: index + 1
		]
		
		money: zero-out as red-money! stack/push*
		money/header: TYPE_MONEY
		
		copy-memory (get-amount money) + SIZE_BYTES - length head length
		money
	]
	
	from-block: func [
		blk     [red-block!]
		return: [red-money!]
		/local
			bail           [subroutine!]
			money fraction [red-money!]
			wrd            [red-word!]
			int            [red-integer!]
			flt            [red-float!]
			head tail here [red-value!]
			currency state [integer!]
			type length    [integer!]
	][
		bail: [fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_MONEY blk]]
		
		length: block/rs-length? blk
		if any [length < 1 length > 3][bail]
		
		head: block/rs-head blk
		tail: block/rs-tail blk
		here: head
		
		currency: 0									;-- assuming generic currency by default
		state: S_START
		while [state <> S_END][
			type: TYPE_OF(here)
			switch state [
				S_START [
					switch type [
						TYPE_WORD    [state: S_CURRENCY]
						TYPE_FLOAT
						TYPE_INTEGER [state: S_INTEGRAL]
						default      [bail]
					]
				]
				S_CURRENCY [
					wrd: as red-word! here
					currency: get-index symbol/resolve wrd/symbol
					if negative? currency [bail]
					here: here + 1
					if here = tail [bail]
					state: S_INTEGRAL
				]
				S_INTEGRAL [
					switch type [
						TYPE_INTEGER [
							int: as red-integer! here
							money: from-integer int/value
						]
						TYPE_FLOAT [
							flt: as red-float! here
							money: from-float flt/value
						]
						default [bail]
					]
					here: here + 1
					state: either here = tail [S_END][
						if type = TYPE_FLOAT [bail]
						S_FRACTIONAL
					]
				]
				S_FRACTIONAL [
					either type <> TYPE_INTEGER [bail][
						int: as red-integer! here
						if any [negative? int/value int/value > MAX_FRACTIONAL][bail]
						
						fraction: set-sign from-integer int/value get-sign money
						shift-right get-amount fraction SIZE_BYTES SIZE_SCALE
						money: add-money money fraction
						
						here: here + 1
						if here <> tail [bail]
						state: S_END
					]
				]
			]
		]
		
		set-currency money currency
	]
	
	from-word: func [
		word    [red-word!]
		return: [red-money!]
		/local
			money [red-money!]
			index [integer!]
	][
		money: zero-out as red-money! stack/push*
		money/header: TYPE_MONEY
		
		index: get-index symbol/resolve word/symbol
		if negative? index [fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_MONEY word]]
		
		set-currency money index
	]
	
	from-string: func [
		str     [red-string!]
		return: [red-money!]
		/local
			bail make        [subroutine!]
			end? dot? digit? [subroutine!]
			money            [red-money!]
			tail head here   [byte-ptr!]
			currency digits  [byte-ptr!]
			start point      [byte-ptr!]
			char             [byte!]
			sign             [logic!]
	][
		bail: [fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_MONEY str]]
		make: [
			money: make-at stack/push* sign currency start point tail
			if null? money [bail]					;-- invalid currency code
			return money
		]
		
		end?:   [here >= tail]
		dot?:   [any [here/value  = #"." here/value  = #","]]
		digit?: [all [here/value >= #"0" here/value <= #"9"]]
		
		tail: string/rs-tail str
		head: string/rs-head str
		here: head
		
		;-- sign
		sign: no
		switch here/value [
			#"-" [here: here + 1 sign: yes]
			#"+" [here: here + 1]
			default [0]
		]
		
		;-- currency code
		currency: here
		while [not any [end? here/value = #"$"]][here: here + 1]
		
		if end? [here: currency]
		either here = currency [currency: null][
			if currency + 3 <> here [bail]			;-- invalid currency code won't pass symbol lookup in make-at, no need to check it here
		]
		
		start: here - as integer! here/value <> #"$"
		here:  start + 1
		if dot? [bail]								;-- forbid leading decimal separator
		
		;-- leading zeroes
		until [here: here + 1 any [here = tail here/value <> #"0"]]
		if any [here = tail dot?][here: here - 1]
		digits: here
		
		;-- integral part with optional thousands separators
		until [
			if here/value = #"'" [here: here + 1 continue]
			unless digit? [bail]
			here: here + 1
			any [end? dot?]
		]
		
		if any [here > tail all [dot? here + 1 = tail]][bail]	;-- forbid trailing decimal separator
		
		point: here
		if SIZE_INTEGRAL < as integer! point - digits [bail]
		if here = tail [point: null make]
		here: here + 1
		
		;-- fractional part
		until [unless digit? [bail] here: here + 1 end?]
		if here <> tail [bail]
		
		make
	]
	
	;-- Comparison --
	
	compare-money: func [
		value1  [red-money!]
		value2  [red-money!]
		return: [integer!]
		/local
			sign1 sign2 [integer!]
	][
		sign1: sign? value1
		sign2: sign? value2
		
		DISPATCH_SIGNS [
			SIGN_-- [SWAP_ARGUMENTS]
			SIGN_++ [0]
			default [return integer/sign? sign1 - sign2]
		]
		
		integer/sign? compare-amounts				;-- must return strictly -1, 0 or +1
			get-amount value1
			get-amount value2
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
	
	;-- Math --
	
	absolute-money: func [
		money   [red-money!]
		return: [red-money!]
	][
		set-sign money 0							;-- 0: clear sign bit
	]
	
	negate-money: func [
		money   [red-money!]
		return: [red-money!]
	][
		flip-sign money
	]
	
	add-money: func [								;-- long addition
		value1  [red-money!]
		value2  [red-money!]
		return: [red-money!]
		/local
			amount1 amount2 [byte-ptr!]
			sign1 sign2     [integer!]
			index carry sum [integer!]
			digit1 digit2   [integer!]
	][
		sign1: sign? value1
		sign2: sign? value2
		
		DISPATCH_SIGNS [
			SIGN_00
			SIGN_-0
			SIGN_+0 [return value1]
			SIGN_0-
			SIGN_0+ [return value2]		
			SIGN_+- [return subtract-money value1 absolute-money value2]
			SIGN_-+ [return subtract-money value2 absolute-money value1]
			default [0]
		]
		
		amount1: get-amount value1
		amount2: get-amount value2
		
		if (get-digit amount1 1) + (get-digit amount2 1) > 9 [MONEY_OVERFLOW]	;-- if sum of two most significant digits overflows
		
		index: SIZE_DIGITS
		carry: 0
		
		loop index [
			digit1: get-digit amount1 index
			digit2: get-digit amount2 index
			
			sum:   digit1 + digit2 + carry
			carry: sum / 10
			unless zero? carry [sum: sum + 6 and 0Fh]
			
			set-digit amount1 index sum
		
			index: index - 1
		]
		
		if as logic! carry [MONEY_OVERFLOW]
		
		value1
	]
	
	subtract-money: func [							;-- long subtraction
		value1  [red-money!]
		value2  [red-money!]
		return: [red-money!]
		/local
			amount1 amount2  [byte-ptr!]
			sign1 sign2 sign [integer!]
			index borrow     [integer!]
			digit1 digit2    [integer!]
			difference       [integer!]
			lesser? flag     [logic!]
	][
		sign1: sign? value1
		sign2: sign? value2
		
		DISPATCH_SIGNS [			
			SIGN_00
			SIGN_0-
			SIGN_0+ [return negate-money value2]
			SIGN_-0
			SIGN_+0 [return value1]
			SIGN_-+ [return negate-money add-money absolute-money value1 absolute-money value2]
			SIGN_+- [return add-money value1 absolute-money value2]
			default [
				lesser?: negative? compare-money value1 value2
				sign: as integer! lesser?
				
				either positive? sign1 [flag: lesser?][
					value1: absolute-money value1
					value2: absolute-money value2
					flag: not lesser?
				]
				
				if flag [SWAP_ARGUMENTS]
			]
		]
		
		amount1: get-amount value1
		amount2: get-amount value2
		
		index:  SIZE_DIGITS
		borrow: 0
	
		loop index [
			digit1: get-digit amount1 index
			digit2: get-digit amount2 index
			
			difference: digit1 - digit2 - borrow
			borrow: as integer! negative? difference
			if as logic! borrow [difference: difference + 10]
			
			set-digit amount1 index difference
		
			index: index - 1
		]
		
		set-sign value1 sign
	]
	
	multiply-money: func [							;-- long multiplication
		value1  [red-money!]
		value2  [red-money!]
		return: [red-money!]
		/local
			amount1 amount2 product [byte-ptr!]
			sign1 sign2             [integer!]
			count1 count2           [integer!]
			index1 index2 index3    [integer!]
			digit1 digit2 digit3    [integer!]
			sign delta carry result [integer!]
	][
		sign1: sign? value1
		sign2: sign? value2
		
		DISPATCH_SIGNS [
			SIGN_00
			SIGN_0-
			SIGN_0+ [return value1]
			SIGN_+0
			SIGN_-0 [return value2]
			default [sign: as integer! sign1 <> sign2]
		]
		
		amount1: get-amount value1
		amount2: get-amount value2
		
		count1: count-digits amount1
		count2: count-digits amount2
		
		if (count1 + count2) > (SIZE_UNNORM + 1) [MONEY_OVERFLOW]	;-- if after normalization it won't fit into payload
		
		product: set-memory as byte-ptr! system/stack/allocate SIZE_SSLOTS null-byte SIZE_SBYTES
		
		delta:  SIZE_DIGITS - SIZE_BUFFER << 1
		index1: SIZE_DIGITS
		
		loop count2 [
			carry:  0
			index2: SIZE_DIGITS
			
			loop count1 [
				index3: index1 + index2 - delta
			
				digit1: get-digit amount1 index2
				digit2: get-digit amount2 index1
				digit3: get-digit product index3
				
				result: digit1 * digit2 + digit3 + carry
				carry:  result /  10
				result: result // 10
				
				set-digit product index3 result
				
				index2: index2 - 1
			]
			
			set-digit product index3 - 1 carry
			
			index1: index1 - 1
		]
		
		unless zero? get-digit product 1 [MONEY_OVERFLOW]	;-- overflowed into most-significant digit
		
		shift-right product SIZE_SBYTES SIZE_SCALE
		product: product + SIZE_BUFFER - SIZE_BYTES
		
		if zero-amount? product [MONEY_OVERFLOW]	;-- got zero product from non-zero factors
		
		set-amount value1 product
		set-sign value1 sign
	]
	
	divide-money: func [							;-- shift-and-subtract algorithm
		value1     [red-money!]
		value2     [red-money!]
		remainder? [logic!]							;-- yes: calculate remainder instead
		only?      [logic!]							;-- yes: don't approximate fractional part
		return:    [red-money!]
		/local
			shift increment subtract [subroutine!]
			greater? greatest?       [subroutine!]
			amount1 amount2          [byte-ptr!]
			start1 start2            [byte-ptr!]
			quotient buffer hold     [byte-ptr!]
			sign1 sign2 sign         [integer!]
			count1 count2            [integer!]
			size overflow            [integer!]
			digits index             [integer!]
			high1? high2?            [logic!]
	][
		sign1: sign? value1
		sign2: sign? value2
		
		DISPATCH_SIGNS [
			SIGN_00
			SIGN_+0
			SIGN_-0 [fire [TO_ERROR(math zero-divide)]]
			SIGN_0-
			SIGN_0+ [return value1]
			default [
				sign: as integer! either remainder? [negative? sign1][sign1 <> sign2]
			]
		]
		
		amount1: get-amount value1
		amount2: get-amount value2
		
		count1: count-digits amount1
		count2: count-digits amount2
		
		if count1 + (SIZE_SCALE + 1 - count2) > SIZE_DIGITS [MONEY_OVERFLOW]	;-- if after normalization it won't fit into payload
		
		size: SIZE_DIGITS
		overflow: SIZE_SBYTES << 1 - SIZE_DIGITS
		
		unless any [remainder? only?][
			size: SIZE_SBYTES << 1
			hold: amount1
			
			amount1: set-memory as byte-ptr! system/stack/allocate SIZE_SSLOTS null-byte SIZE_SBYTES
			count1:  count1 + SIZE_SCALE
			
			copy-memory amount1 + SIZE_SBYTES - SIZE_BYTES hold SIZE_BYTES
			shift-left amount1 SIZE_SBYTES SIZE_SCALE
		]
		
		high1?: as logic! count1 and 1
		high2?: as logic! count2 and 1
		
		start1: amount1 + (size        - count1 >> 1)
		start2: amount2 + (SIZE_DIGITS - count2 >> 1)
		
		digits: either count1 < count2 [count1][count2]
		
		index:    size - (integer/abs count1 - count2) - SIZE_SCALE
		quotient: set-memory as byte-ptr! system/stack/allocate SIZE_SSLOTS null-byte SIZE_SBYTES
		buffer:   quotient
		
		if any [remainder? only?][quotient: quotient + SIZE_SBYTES - SIZE_BYTES]
		
		shift: [
			digits: digits + 1
			index:  index  + 1
		]
		subtract: [
			subtract-slice
				start1 high1? digits
				start2 high2? count2
		]
		increment: [
			set-digit quotient index (get-digit quotient index) + 1
		]
		greater?: [
			compare-slices
				start2 high2? count2
				start1 high1? digits
		]
		greatest?: [
			compare-slices
				start2 high2? count2
				start1 high1? count1
		]
		;@@ TBD: bug with subroutines
		until [either greater? > 0 [either greatest? > 0 [yes][shift no]][subtract increment no]]
		
		unless remainder? [
			unless only? [
				shift-right quotient SIZE_SBYTES SIZE_SCALE
				quotient: quotient + SIZE_SBYTES - SIZE_BYTES
				amount1: hold
			]
			if zero-amount? quotient [MONEY_OVERFLOW]				;-- got zero quotient from non-zero divisor
			unless zero? get-digit buffer overflow [MONEY_OVERFLOW] ;-- overflowed into most-significant digit
			set-amount value1 quotient
		]
		
		set-sign value1 sign
	]

	do-math-op: func [
		value1  [red-money!]
		value2  [red-money!]
		op      [integer!]
		return: [red-money!]
	][
		switch op [
			OP_ADD [add-money      value1 value2]
			OP_SUB [subtract-money value1 value2]
			OP_MUL [multiply-money value1 value2]
			OP_DIV [divide-money   value1 value2 no  no]
			OP_REM [divide-money   value1 value2 yes no]
			default [
				fire [TO_ERROR (script invalid-type) datatype/push TYPE_OF(value1)]
				value1								;-- pass compiler's type checking
			]
		]
	]

	do-math: func [
		op      [integer!]
		return: [red-value!]
		/local
			value1 value2 [red-money!]
			result        [red-value!]
			int           [red-integer!]
			flt           [red-float!]
			currency      [integer!]
			type1 type2   [integer!]
	][
		value1: as red-money! stack/arguments
		value2: value1 + 1
		
		type1: TYPE_OF(value1)
		type2: TYPE_OF(value2)
	
		if any [
			all [op = OP_MUL type1 = TYPE_MONEY type2 = TYPE_MONEY]
			all [any [op = OP_DIV op = OP_REM] type1 <> TYPE_MONEY type2 = TYPE_MONEY]
		][
			fire [TO_ERROR(script invalid-type) datatype/push type1]
		]
		
		switch type1 [
			TYPE_MONEY [0]
			TYPE_INTEGER [
				int: as red-integer! value1
				value1: from-integer int/value
			]
			TYPE_FLOAT [
				flt: as red-float! value1
				value1: from-float flt/value
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(value1)]
			]
		]
	
		switch type2 [
			TYPE_MONEY [0]
			TYPE_INTEGER [
				int: as red-integer! value2
				value2: from-integer int/value
			]
			TYPE_FLOAT [
				flt: as red-float! value2
				value2: from-float flt/value
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(value2)]
			]
		]
		
		unless same-currencies? value1 value2 [fire [TO_ERROR(script wrong-denom) value1 value2]]
		currency: get-currency value2				;-- preserve specific currency
		if zero? currency [currency: get-currency value1]
		
		result: as red-value! do-math-op value1 value2 op
		either all [op = OP_DIV type1 = TYPE_MONEY type2 = TYPE_MONEY][
			result: as red-value! float/box to-float as red-money! result
		][
			set-currency as red-money! result currency
		]
		
		SET_RETURN(result)							;-- swapped arguments
	]
	
	;-- Actions --
	
	make: func [
		proto   [red-value!]
		spec    [red-value!]
		type    [integer!]
		return: [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/make"]]
	
		switch TYPE_OF(spec) [
			TYPE_WORD  [from-word as red-word! spec]
			TYPE_BLOCK [from-block as red-block! spec]
			default    [to proto spec type]
		]
	]

	to: func [
		proto   [red-value!]
		spec    [red-value!]
		type    [integer!]
		return: [red-money!]
		/local
			integer [red-integer!]
			float   [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/to"]]
		
		switch TYPE_OF(spec) [
			TYPE_MONEY [
				as red-money! spec
			]
			TYPE_INTEGER [
				integer: as red-integer! spec
				from-integer integer/value
			]
			TYPE_FLOAT [
				float: as red-float! spec
				from-float float/value
			]
			TYPE_ANY_STRING [
				from-string as red-string! spec
			]
			default [
				fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_MONEY spec]
				as red-money! proto					;-- pass compiler's type checking
			]
		]
	]
	
	random: func [
		money   [red-money!]
		seed?   [logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-money!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/random"]]
		--NOT_IMPLEMENTED--
		money
	]
	
	form: func [
		money   [red-money!]
		buffer  [red-string!]
		arg     [red-value!]
		part    [integer!]
		return: [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/form"]]
		form-money money buffer part no yes
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
		#if debug? = yes [if verbose > 0 [print-line "money/mold"]]
		form-money money buffer part all? no
	]
		
	compare: func [
		money   [red-money!]
		value   [red-money!]
		op      [integer!]
		return: [integer!]
		/local
			integer [red-integer!]
			float   [red-float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/compare"]]
		
		if all [
			TYPE_OF(money) <> TYPE_OF(value)
			any [op = COMP_FIND op = COMP_SAME op = COMP_STRICT_EQUAL]
		][
			return 1
		]
		
		switch TYPE_OF(value) [
			TYPE_MONEY [
				unless same-currencies? money as red-money! value [
					fire [TO_ERROR(script wrong-denom) money as red-money! value]
				]
			]
			TYPE_INTEGER [
				integer: as red-integer! value
				value:   from-integer integer/value
			]
			TYPE_FLOAT [
				float: as red-float! value
				value: from-float float/value
			]
			default [RETURN_COMPARE_OTHER]
		]
		
		compare-money money value
	]
	
	absolute: func [return: [red-money!]][
		#if debug? = yes [if verbose > 0 [print-line "money/absolute"]]
		absolute-money as red-money! stack/arguments
	]
	
	negate: func [return: [red-money!]][
		#if debug? = yes [if verbose > 0 [print-line "money/negate"]]
		negate-money as red-money! stack/arguments
	]
	
	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/add"]]	
		do-math OP_ADD
	]
	
	subtract: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/subtract"]]
		do-math OP_SUB
	]
	
	multiply: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/multiply"]]
		do-math OP_MUL
	]
	
	divide: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/divide"]]
		do-math OP_DIV
	]
	
	remainder: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "money/remainder"]]	
		do-math OP_REM
	]
	
	round: func [
		value      [red-money!]
		_scale     [red-float!]
		_even?     [logic!]
		down?      [logic!]
		half-down? [logic!]
		floor?     [logic!]
		ceil?      [logic!]
		half-ceil? [logic!]
		return:    [red-money!]
		/local
			up down           [subroutine!]
			away ceil floor   [subroutine!]
			scale lower upper [red-money!]
			int               [red-integer!]
			sign type         [integer!]
			half?             [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/round"]]
		
		sign: sign? value
		if zero? sign [return value]
		
		scale: absolute-money either not OPTION?(_scale) [from-integer 1][
			type: TYPE_OF(_scale)
			switch type [
				TYPE_MONEY   [as red-money! _scale]
				TYPE_INTEGER [int: as red-integer! _scale from-integer int/value]
				TYPE_FLOAT   [from-float _scale/value]
				default [
					fire [TO_ERROR(script not-related) stack/get-call datatype/push type]
					value							;-- pass compiler's type checking
				]
			]
		]
		
		if zero-money? scale [fire [TO_ERROR(math overflow)]]
		value: absolute-money value
		
		lower: divide-money as red-money! stack/push as red-value! value scale yes no
		upper: subtract-money scale lower
		half?: lower/amount3 and KEEP_FRACTIONAL = HALF_FRACTIONAL
		
		up:    [add-money value upper]
		down:  [subtract-money value lower]
		away:  [either negative? compare-money lower upper [down][up]]
		ceil:  [either negative? sign [down][up]]
		floor: [either negative? sign [up][down]]
		
		case [
			_even?     [either all [half? even? value][down][away]]
			down?      [down]
			half-down? [either half? [down][away]]
			floor?     [floor]
			ceil?      [ceil]
			half-ceil? [either half? [ceil][away]]
			true       [away]
		]
		
		set-sign value as integer! negative? sign
		value
	]
	
	even?: func [
		money   [red-money!]
		return: [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/even?"]]
		not odd? money
	]
	
	odd?: func [
		money   [red-money!]
		return: [logic!]
		/local
			digit [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "money/odd?"]]
		
		digit: get-digit get-amount money SIZE_INTEGRAL	;-- check if least significant bit is set
		as logic! digit and 1
	]
	
	eval-path: func [
		money   [red-money!]
		element	[red-value!]
		value   [red-value!]
		path    [red-value!]
		case?   [logic!]
		return:	[red-value!]
		/local
			access [accessor!]
			int    [red-integer!]
			index  [integer!]
	][
		index: switch TYPE_OF(element) [
			TYPE_WORD    [resolve-accessor as red-word! element]
			TYPE_INTEGER [int: as red-integer! element int/value]
			default      [0]
		]
		
		access: as accessor! switch index [
			1 [:get-currency-from]
			2 [:get-amount-from]
			default [fire [TO_ERROR(script invalid-path) path element]]
		]
		
		access money
	]
	
	pick: func [
		money   [red-money!]
		index   [integer!]
		boxed   [red-value!]
		return: [red-value!]
		/local
			access [accessor!]
	][
		index: switch TYPE_OF(boxed) [
			TYPE_WORD    [resolve-accessor as red-word! boxed]
			TYPE_INTEGER [index]
			default      [0]
		]
		
		access: as accessor! switch index [
			1 [:get-currency-from]
			2 [:get-amount-from]
			default [fire [TO_ERROR(script out-of-range) boxed]]
		]
		
		access money
	]
	
	init: does [
		datatype/register [
			TYPE_MONEY
			TYPE_VALUE
			"money!"
			;-- General actions --
			:make
			:random
			null			;reflect
			:to
			:form
			:mold
			:eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			:absolute
			:add
			:divide
			:multiply
			:negate
			null			;power
			:remainder
			:round
			:subtract
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
			:pick
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
