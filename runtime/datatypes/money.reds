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
	
	;-- Base --
	
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
	
	#define MONEY_OVERFLOW [fire [TO_ERROR(script type-limit) datatype/push TYPE_MONEY]]
	
	SIZE_DIGITS:   SIZE_BYTES * 2
	SIZE_INTEGRAL: SIZE_DIGITS - SIZE_SCALE
	
	SIZE_UNNORM: SIZE_DIGITS + SIZE_SCALE
	SIZE_BUFFER: (SIZE_UNNORM + (SIZE_UNNORM and 1)) >> 1
	
	SIZE_SBYTES: (SIZE_BUFFER + size? integer!) - (SIZE_BUFFER // size? integer!)
	SIZE_SSLOTS: SIZE_SBYTES >> 2
	
	HIGH_NIBBLE: #"^(0F)"
	LOW_NIBBLE:  #"^(F0)"
	
	SIGN_MASK:   4000h
	SIGN_OFFSET: 14
	
	INT32_MAX_DIGITS: 10
	INT32_MIN_AMOUNT: #{00000002147483648FFFFF}
	INT32_MAX_AMOUNT: #{00000002147483647FFFFF}
	
	;-- Sign --
	
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
		this    [integer!]
		that    [integer!]
		return: [integer!]
	][
		this + 1 << 4 or (that + 1)
	]
	
	;-- Amount --
	
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
	
	shift-left: func [
		amount  [byte-ptr!]
		size    [integer!]
		offset  [integer!]
		return: [byte-ptr!]
		/local
			this that [integer!]
			half      [byte!]
	][
		loop offset [
			this: 1
			that: this + 1
			loop size [
				half: either that > size [null-byte][amount/that >>> 4]
				amount/this: amount/this << 4 or half
				
				this: this + 1
				that: that + 1
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
			this that [integer!]
			half      [byte!]
	][
		loop offset [
			this: size
			that: this - 1
			loop size [
				half: either that < 1 [null-byte][amount/that << 4]
				amount/this: amount/this >>> 4 or half
				
				this: this - 1
				that: that - 1
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
		
		either zero? count [1][count]
	]
	
	;-- Slices --
	
	compare-slices: func [
		this-buffer [byte-ptr!] this-high? [logic!] this-count [integer!]
		that-buffer [byte-ptr!] that-high? [logic!] that-count [integer!]
		return: [integer!]
		/local
			delta index1 index2 end this that [integer!]
	][
		delta: integer/abs this-count - that-count
		switch integer/sign? this-count - that-count [
			-1 [index1: 1 - delta index2: 1 end: that-count]
			00 [index1: 1         index2: 1 end: this-count]
			+1 [index2: 1 - delta index1: 1 end: this-count]
			default [0]
		]
		
		index1: index1 + as integer! this-high?
		index2: index2 + as integer! that-high?
		
		until [
			this: either index1 < 1 [0][get-digit this-buffer index1]
			that: either index2 < 1 [0][get-digit that-buffer index2]
		
			index1: index1 + 1
			index2: index2 + 1
			end:    end - 1
			
			any [this <> that zero? end]
		]
		
		this - that
	]
	
	subtract-slice: func [
		this-buffer [byte-ptr!] this-high? [logic!] this-count [integer!]
		that-buffer [byte-ptr!] that-high? [logic!] that-count [integer!]
		/local
			this that borrow difference [integer!]
	][
		this-count: this-count + as integer! this-high?
		that-count: that-count + as integer! that-high?
		borrow: 0
		until [
			this: get-digit this-buffer this-count
			that: either that-count < 1 [0][get-digit that-buffer that-count]
			
			difference: this - that - borrow
			borrow: as integer! difference < 0
			if as logic! borrow [difference: difference + 10]
			
			set-digit this-buffer this-count difference
			
			this-count: this-count - 1
			that-count: that-count - 1
			
			zero? this-count
		]
	]
	
	;-- Construction --
	
	make-at: func [
		slot     [red-value!]
		sign     [logic!]
		currency [byte-ptr!]
		start    [byte-ptr!]
		point    [byte-ptr!]
		end      [byte-ptr!]
		return:  [red-money!]
		/local
			convert           [subroutine!]
			money             [red-money!]
			here amount limit [byte-ptr!]
			index stop step   [integer!]
	][
		money: as red-money! slot
		money/header: TYPE_MONEY
		
		zero-out money yes
		set-sign money as integer! sign
		;@@ TBD: store currency index
		amount: get-amount money
		
		convert: [
			here: here + step
			until [
				if here/value = #"'" [here: here + step continue]
				set-digit amount index as integer! here/value - #"0"
				
				here:  here + step
				index: index + step
				any [index = stop here = limit]
			]
		]
		
		here:  either null? point [end][point]
		limit: start
		index: SIZE_INTEGRAL
		stop:  0
		step:  -1
		
		convert
		
		if null? point [return money]
		
		here:  point
		limit: end
		index: SIZE_INTEGRAL + 1
		stop:  SIZE_DIGITS + 1
		step:  +1
		
		convert
		
		money
	]
	
	make-in: func [
		parent   [red-block!]
		sign     [logic!]
		currency [byte-ptr!]
		start    [byte-ptr!]
		point    [byte-ptr!]
		end      [byte-ptr!]
		return:  [red-money!]
	][
		make-at ALLOC_TAIL(parent) sign currency start point end
	]
	
	push: func [
		sign     [logic!]
		currency [byte-ptr!]
		start    [byte-ptr!]
		point    [byte-ptr!]
		end      [byte-ptr!]
		return:  [red-money!]	
	][
		make-at stack/push* sign currency start point end
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
		
		limit: either negative? sign [INT32_MIN_AMOUNT][INT32_MAX_AMOUNT]
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
			money             [red-money!]
			amount            [byte-ptr!]
			extra index start [integer!]
			power digit       [integer!]
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
	
	;-- Comparison --
		
	compare-money: func [
		this    [red-money!]
		that    [red-money!]
		return: [integer!]
		/local
			this-sign that-sign [integer!]
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
		
	;-- Math --
	
	absolute-money: func [
		money   [red-money!]
		return: [red-money!]
	][
		set-sign money 0
	]
	
	negate-money: func [
		money   [red-money!]
		return: [red-money!]
	][
		flip-sign money
	]
	
	add-money: func [
		augend  [red-money!]
		addend  [red-money!]
		return: [red-money!]
		/local
			left-amount right-amount   [byte-ptr!]
			augend-sign addend-sign    [integer!]
			index carry left right sum [integer!]
	][
		augend-sign: sign? augend
		addend-sign: sign? addend
		
		DISPATCH_SIGNS(augend-sign addend-sign)[			
			SIGN_00
			SIGN_-0
			SIGN_+0 [return augend]
			SIGN_0-
			SIGN_0+ [return addend]		
			SIGN_+- [return subtract-money augend absolute-money addend]
			SIGN_-+ [return subtract-money addend absolute-money augend]
			default [0]
		]
		
		left-amount:  get-amount augend
		right-amount: get-amount addend
		
		if (get-digit left-amount 1) + (get-digit right-amount 1) > 9 [MONEY_OVERFLOW]
		
		index: SIZE_DIGITS
		carry: 0
		
		loop index [
			left:  get-digit left-amount  index
			right: get-digit right-amount index
			
			sum: left + right + carry
			carry: sum / 10
			unless zero? carry [sum: sum + 6 and 0Fh]
			
			set-digit left-amount index sum
		
			index: index - 1
		]
		
		if as logic! carry [MONEY_OVERFLOW]
		
		augend
	]
	
	subtract-money: func [
		minuend    [red-money!]
		subtrahend [red-money!]
		return:    [red-money!]
		/local
			left-amount right-amount           [byte-ptr!]
			minuend-sign subtrahend-sign sign  [integer!]
			index borrow left right difference [integer!]
			lesser? flag                       [logic!]
	][
		minuend-sign: sign? minuend
		subtrahend-sign: sign? subtrahend
		
		DISPATCH_SIGNS(minuend-sign subtrahend-sign)[			
			SIGN_00
			SIGN_0-
			SIGN_0+ [return negate-money subtrahend]
			SIGN_-0
			SIGN_+0 [return minuend]
			SIGN_-+ [return negate-money add-money absolute-money minuend absolute-money subtrahend]
			SIGN_+- [return add-money minuend absolute-money subtrahend]
			default [
				lesser?: negative? compare-money minuend subtrahend
				sign: as integer! lesser?
				
				either positive? minuend-sign [flag: lesser?][
					minuend: absolute-money minuend
					subtrahend: absolute-money subtrahend
					flag: not lesser?
				]
				
				if flag [SWAP_ARGUMENTS(minuend subtrahend)]
			]
		]
		
		left-amount:  get-amount minuend
		right-amount: get-amount subtrahend
		
		index:  SIZE_DIGITS
		borrow: 0
	
		loop index [
			left:  get-digit left-amount  index
			right: get-digit right-amount index
			
			difference: left - right - borrow
			borrow: as integer! negative? difference
			if as logic! borrow [difference: difference + 10]
			
			set-digit left-amount index difference
		
			index: index - 1
		]
		
		set-sign minuend sign
	]
	
	multiply-money: func [
		multiplicand [red-money!]
		multiplier   [red-money!]
		return:      [red-money!]
		/local
			left-amount right-amount product       [byte-ptr!]
			multiplicand-sign multiplier-sign sign [integer!]
			left-count right-count                 [integer!]
			delta index1 index2 index3             [integer!]
			carry left right other result          [integer!]
	][
		multiplicand-sign: sign? multiplicand
		multiplier-sign:   sign? multiplier
		
		DISPATCH_SIGNS(multiplicand-sign multiplier-sign)[
			SIGN_00
			SIGN_0-
			SIGN_0+ [return multiplicand]
			SIGN_+0
			SIGN_-0 [return multiplier]
			default [sign: as integer! multiplicand-sign <> multiplier-sign]
		]
		
		left-amount:  get-amount multiplicand
		right-amount: get-amount multiplier
		
		left-count:  count-digits left-amount
		right-count: count-digits right-amount
		
		if (left-count + right-count) > (SIZE_UNNORM + 1) [MONEY_OVERFLOW]
		
		product: set-memory as byte-ptr! system/stack/allocate SIZE_SSLOTS null-byte SIZE_SBYTES
		
		delta:  SIZE_DIGITS - SIZE_BUFFER << 1
		index1: SIZE_DIGITS
		
		loop right-count [
			carry:  0
			index2: SIZE_DIGITS
			
			loop left-count [
				index3: index1 + index2 - delta
			
				left:  get-digit left-amount  index2
				right: get-digit right-amount index1
				other: get-digit product      index3
				
				result: left * right + other + carry
				carry:  result /  10
				result: result // 10
				
				set-digit product index3 result
				
				index2: index2 - 1
			]
			
			set-digit product index3 - 1 carry
			
			index1: index1 - 1
		]
		
		unless zero? get-digit product 1 [MONEY_OVERFLOW]
		
		product: product + SIZE_BUFFER - SIZE_BYTES
		
		shift-right product SIZE_BYTES SIZE_SCALE
		if zero-amount? product [MONEY_OVERFLOW]
		
		copy-memory left-amount product SIZE_BYTES
		set-sign multiplicand sign
	]
	
	divide-money: func [
		dividend   [red-money!]
		divisor    [red-money!]
		remainder? [logic!]
		only?      [logic!]
		return:    [red-money!]
		/local
			shift increment subtract        [subroutine!]
			greater? greatest?              [subroutine!]
			left-amount right-amount        [byte-ptr!]
			left-start right-start          [byte-ptr!]
			quotient buffer hold            [byte-ptr!]
			dividend-sign divisor-sign sign [integer!]
			left-count right-count          [integer!]
			size overflow digits index      [integer!]
			left-high? right-high?          [logic!]
	][
		dividend-sign: sign? dividend
		divisor-sign:  sign? divisor
		
		DISPATCH_SIGNS(dividend-sign divisor-sign)[
			SIGN_00
			SIGN_+0
			SIGN_-0 [fire [TO_ERROR(math zero-divide)]]
			SIGN_0-
			SIGN_0+ [return dividend]
			default [sign: as integer! dividend-sign <> divisor-sign]
		]
		
		left-amount:  get-amount dividend
		right-amount: get-amount divisor
		
		left-count:  count-digits left-amount
		right-count: count-digits right-amount
		
		if left-count + (SIZE_SCALE + 1 - right-count) > SIZE_DIGITS [MONEY_OVERFLOW]
		
		size: SIZE_DIGITS
		overflow: SIZE_SBYTES << 1 - SIZE_DIGITS
		
		unless any [remainder? only?][
			size: SIZE_SBYTES << 1
			hold: left-amount
			
			left-amount: set-memory as byte-ptr! system/stack/allocate SIZE_SSLOTS null-byte SIZE_SBYTES
			left-count:  left-count + SIZE_SCALE
			
			copy-memory left-amount + SIZE_SBYTES - SIZE_BYTES hold SIZE_BYTES
			shift-left left-amount SIZE_SBYTES SIZE_SCALE
		]
		
		left-high?:  as logic! left-count  and 1
		right-high?: as logic! right-count and 1
		
		left-start:  left-amount  + (size        - left-count  >> 1)
		right-start: right-amount + (SIZE_DIGITS - right-count >> 1)
		
		digits: either left-count < right-count [left-count][right-count]
		
		index:    size - (integer/abs left-count - right-count) - SIZE_SCALE
		quotient: set-memory as byte-ptr! system/stack/allocate SIZE_SSLOTS null-byte SIZE_SBYTES
		buffer:   quotient
		
		if any [remainder? only?][quotient: quotient + SIZE_SBYTES - SIZE_BYTES]
		
		shift: [
			digits: digits + 1
			index:  index  + 1
		]
		subtract: [
			subtract-slice
				left-start  left-high?  digits
				right-start right-high? right-count
		]
		increment: [
			set-digit quotient index (get-digit quotient index) + 1
		]
		greater?: [
			compare-slices
				right-start right-high? right-count
				left-start  left-high?  digits
		]
		greatest?: [
			compare-slices
				right-start right-high? right-count
				left-start  left-high?  left-count
		]
		;@@ TBD: bug with subroutines
		until [either greater? > 0 [either greatest? > 0 [yes][shift no]][subtract increment no]]
		
		unless remainder? [
			unless only? [
				shift-right quotient SIZE_SBYTES SIZE_SCALE
				quotient: quotient + SIZE_SBYTES - SIZE_BYTES
				left-amount: hold
			]
			if zero-amount? quotient [MONEY_OVERFLOW]
			unless zero? get-digit buffer overflow [MONEY_OVERFLOW]
			copy-memory left-amount quotient SIZE_BYTES
		]
		
		set-sign dividend sign
	]
	
	do-math: func [
		op      [integer!]
		return: [red-value!]
		/local
			left right result [red-money!]
			integer           [red-integer!]
	][
		left:  as red-money! stack/arguments
		right: left + 1
	
		;@@ TBD: take currencies into account
	
		switch TYPE_OF(left) [
			TYPE_MONEY [0]
			TYPE_INTEGER [
				integer: as red-integer! left
				left:    from-integer integer/value
			]
			TYPE_FLOAT [--NOT_IMPLEMENTED--]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(left)]
			]
		]
	
		switch TYPE_OF(right) [
			TYPE_MONEY [0]
			TYPE_INTEGER [
				integer: as red-integer! right
				right:   from-integer integer/value
			]
			TYPE_FLOAT [--NOT_IMPLEMENTED--]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(right)]
			]
		]
		
		result: switch op [
			OP_ADD [add-money left right]
			OP_SUB [subtract-money left right]
			OP_MUL [multiply-money left right]
			OP_DIV [divide-money left right no no]
			OP_REM [divide-money left right yes no]
			default [
				fire [TO_ERROR (script invalid-type) datatype/push TYPE_OF(left)]
				left
			]
		]
		
		SET_RETURN(result)
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
				fire [TO_ERROR(script bad-make-arg) datatype/push TYPE_MONEY spec]
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
	
	absolute: func [return: [red-money!]][absolute-money as red-money! stack/arguments]
	negate:   func [return: [red-money!]][negate-money as red-money! stack/arguments]
	
	add:       func [return: [red-value!]][do-math OP_ADD]
	subtract:  func [return: [red-value!]][do-math OP_SUB]
	multiply:  func [return: [red-value!]][do-math OP_MUL]
	divide:    func [return: [red-value!]][do-math OP_DIV]
	remainder: func [return: [red-value!]][do-math OP_REM]
	
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
			:make			;-- to
			:form
			:mold
			null			;eval-path
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
				null;:round
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
