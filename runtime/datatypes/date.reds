Red/System [
	Title:	 "Date! datatype runtime functions"
	Author:	 "Nenad Rakocevic"
	File: 	 %data.reds
	Tabs:	 4
	Rights:	 "Copyright (C) 2011-2017 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

date: context [
	verbose: 0
	
	box: func [
		year	[integer!]
		month	[integer!]
		day		[integer!]
		return: [red-date!]
		/local
			dt	[red-date!]
	][
		dt: as red-date! stack/arguments
		dt/header: TYPE_DATE
		dt/date: (year << 16) or (month << 12) or (day << 7)
		dt
	]

	;-- Actions --

	make: func [
		proto 	[red-value!]							;-- overwrite this slot with result
		spec	[red-value!]
		type	[integer!]
		return: [red-value!]
		/local
			value [red-value!]
			tail  [red-value!]
			v	  [red-value!]
			int	  [red-integer!]
			fl	  [red-float!]
			year  [integer!]
			month [integer!]
			day   [integer!]
			idx   [integer!]
			i	  [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/make"]]
		
		if TYPE_OF(spec) = TYPE_DATE [return spec]
		year:   0
		month:  1
		day:    1
		
		switch TYPE_OF(spec) [
			TYPE_BLOCK [
				value: block/rs-head as red-block! spec
				tail:  block/rs-tail as red-block! spec
				
				idx: 1
				while [value < tail][
					v: either TYPE_OF(value) = TYPE_WORD [
						_context/get as red-word! value
					][
						value
					]
					switch TYPE_OF(v) [
						TYPE_INTEGER [
							int: as red-integer! v
							i: int/value
						]
						TYPE_FLOAT [
							fl: as red-float! v
							i: as-integer fl/value
						]
						default [0]						;@@ fire error
					]
					switch idx [1 [year: i] 2 [month: i] 3 [day: i]]
					idx: idx + 1
					value: value + 1
				]
			]
			default [0]									;@@ fire error
		]
		as red-value! box year month day
	]
		
	form: func [
		dt		[red-date!]
		buffer	[red-string!]
		arg		[red-value!]
		part	[integer!]
		return:	[integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/form"]]
		
		mold dt buffer no no no arg part 0
	]
	
	mold: func [
		dt		[red-date!]
		buffer	[red-string!]
		only?	[logic!]
		all?	[logic!]
		flat?	[logic!]
		arg		[red-value!]
		part 	[integer!]
		indent	[integer!]
		return: [integer!]
		/local
			formed [c-string!]
			blk	   [red-block!]
			month  [red-string!]
			len	   [integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/mold"]]
		
		formed: integer/form-signed (dt/date >> 7) and 1Fh
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?
		
		string/append-char GET_BUFFER(buffer) as-integer #"-"
		
		blk: as red-block! #get system/locale/months
		month: as red-string! (block/rs-head blk) + ((dt/date >> 12) and 0Fh) - 1
		;if month > block/rs-tail [...]					;@@ fire error
		;if TYPE_OF(month) <> TYPE_STRING [...]			;@@ fire error
		
		string/concatenate buffer month 3 0 yes no
		part: part - 4									;-- 3 + separator
		
		string/append-char GET_BUFFER(buffer) as-integer #"-"
		
		formed: integer/form-signed dt/date >> 16
		string/concatenate-literal buffer formed
		len: 4 - length? formed
		if len > 0 [loop len [string/append-char GET_BUFFER(buffer) as-integer #"0"]]
		part - 5										;-- 4 + separator
	]
	
	init: does [
		datatype/register [
			TYPE_DATE
			TYPE_VALUE
			"date!"
			;-- General actions --
			:make
			null			;random
			null			;reflect
			null			;to
			:form
			:mold
			null			;eval-path
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