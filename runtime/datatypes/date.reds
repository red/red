Red/System [
	Title:	 "Date! datatype runtime functions"
	Author:	 "Nenad Rakocevic, Xie Qingtian"
	File: 	 %date.reds
	Tabs:	 4
	Rights:	 "Copyright (C) 2017 Nenad Rakocevic. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

date: context [
	verbose: 0
	
	#define DATE_GET_YEAR(d)		 (d >> 16)
	#define DATE_GET_MONTH(d)		 ((d >> 12) and 0Fh)
	#define DATE_GET_DAY(d)			 ((d >> 7) and 1Fh)
	#define DATE_GET_ZONE(d)		 (d and 7Fh)		;-- sign included
	#define DATE_GET_ZONE_SIGN(d)	 (as-logic d and 40h >>	6)
	#define DATE_GET_ZONE_HOURS(d)	 (d and 3Fh >> 2)	;-- sign excluded
	#define DATE_GET_ZONE_MINUTES(d) (d and 03h * 15)
	#define DATE_GET_HOURS(t)		 (floor t / time/h-factor)
	#define DATE_GET_MINUTES(t)		 (floor t / time/oneE9 // 3600.0 / 60.0)
	#define DATE_GET_SECONDS(t)		 (t / time/oneE9 // 60.0)
	
	#define DATE_SET_YEAR(d year)	 (d and 0000FFFFh or (year << 16))
	#define DATE_SET_MONTH(d month)	 (d and FFFF0FFFh or (month and 0Fh << 12))
	#define DATE_SET_DAY(d day)		 (d and FFFFF07Fh or (day and 1Fh << 7))
	#define DATE_SET_ZONE(d zone)	 (d and FFFFFFC0h or (zone and 7Fh))
	
	push-field: func [
		dt		[red-date!]
		field	[integer!]
		return: [red-value!]
		/local
			d [integer!]
			t [float!]
	][
		d: dt/date
		t: dt/time
		as red-value! switch field [
			1 [integer/push DATE_GET_YEAR(d)]
			2 [integer/push DATE_GET_MONTH(d)]
			3 [integer/push DATE_GET_DAY(d)]
			4 [
				time/push
					(as-float DATE_GET_ZONE_HOURS(d)) * 3600.0	;@@ TBD: add sign support
					+ ((as-float DATE_GET_ZONE_MINUTES(d)) * 60.0)
					/ time/nano
			]
			5 [time/push t]
			6 [integer/push as-integer DATE_GET_HOURS(t)]
			7 [integer/push as-integer DATE_GET_MINUTES(t)]
			8 [float/push DATE_GET_SECONDS(t)]
			9 [integer/push (date-to-days d) + 2 % 7 + 1]
		   10 [integer/push (date-to-days d) - (Jan-1st-of d) + 1]
		   default [assert false]
		]
	]
	
	Jan-1st-of: func [
		d		[integer!]
		return: [integer!]								;-- in days
	][
		d: DATE_SET_DAY(d 1)
		d: DATE_SET_MONTH(d 1)
		date-to-days d
	]
	
	make-in: func [
		parent	[red-block!]
		date	[integer!]
		high	[integer!]
		low		[integer!]
		return: [red-date!]
		/local
			cell [cell!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/make-in"]]

		cell: ALLOC_TAIL(parent)
		cell/header: TYPE_DATE
		cell/data1:  date
		cell/data2:  low
		cell/data3:  high
		as red-date! cell
	]
	
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
		dt/time: 0.0
		dt
	]
	
	push: func [
		date	[integer!]
		time	[float!]
		return: [red-date!]
		/local
			dt	[red-date!]
	][
		dt: as red-date! stack/push*
		dt/header: TYPE_DATE
		dt/date: date
		dt/time: time
		dt
	]

	days-to-date: func [
		days	[integer!]
		tz		[integer!]
		return: [integer!]
		/local
			y	[integer!]
			m	[integer!]
			d	[integer!]
			dd	[integer!]
			mi	[integer!]
			f	[float!]
	][
		;@@ use int64 once we have it
		f: 10000.0 * days
		y: as-integer (f + 14780.0 / 3652425.0)

		dd: days - (365 * y + (y / 4) - (y / 100) + (y / 400))
		if dd < 0 [
			y: y - 1
			dd: days - (365 * y + (y / 4) - (y / 100) + (y / 400))
		]

		mi: 100 * dd + 52 / 3060
		m: mi + 2 % 12 + 1
		y: y + (mi + 2 / 12)
		d: dd - (mi * 306 + 5 / 10) + 1
		y << 16 or (m << 12) or (d << 7) or tz
	]

	date-to-days: func [
		date	[integer!]
		return: [integer!]
		/local
			y	[integer!]
			m	[integer!]
			d	[integer!]
	][
		y: DATE_GET_YEAR(date)
		m: DATE_GET_MONTH(date)
		d: DATE_GET_DAY(date)
		m: (m + 9) % 12
		y: y - (m / 10)
		365 * y + (y / 4) - (y / 100) + (y / 400) + ((m * 306 + 5) / 10) + (d - 1)
	]

	dt-to-nanosec: func [
		date	[integer!]
		tm		[float!]
		return: [float!]
		/local
			h	[integer!]
	][
		h: 24 * date-to-days date
		(as float! h) * time/h-factor + tm
	]

	julian-date: func [
		date	[integer!]
		return: [integer!]
	][
		0
	]

	convert-time: func [
		tm		[float!]
		tz		[integer!]
		to-utc? [logic!]
		return: [float!]
		/local
			m	[integer!]
			h	[integer!]
			hh	[float!]
			mm	[float!]
	][
		h: DATE_GET_ZONE_HOURS(tz)
		if DATE_GET_ZONE_SIGN(tz) [h: 0 - h]
		m: tz and 03h * 15
		hh: (as float! h) * time/h-factor
		mm: (as float! m) * time/m-factor
		either to-utc? [tm: tm - hh - mm][tm: tm + hh + mm]
		tm
	]

	to-local-time: func [
		tm		[float!]
		tz		[integer!]
		return: [float!]
	][
		convert-time tm tz no
	]

	to-utc-time: func [
		tm		[float!]
		tz		[integer!]
		return: [float!]
	][
		convert-time tm tz yes
	]


	difference?: func [
		dt1		[red-date!]
		dt2		[red-date!]
		return: [red-time!]
		/local
			t1	[float!]
			t2	[float!]
			t	[red-time!]
	][
		t1: dt-to-nanosec dt1/date dt1/time
		t2: dt-to-nanosec dt2/date dt2/time
		t: as red-time! dt1
		t/header: TYPE_TIME
		t/time: t1 - t2
		t
	]

	do-math: func [
		type	  [integer!]
		return:	  [red-date!]
		/local
			left  [red-date!]
			right [red-date!]
			int   [red-integer!]
			tm	  [red-time!]
			days  [integer!]
			tz	  [integer!]
			ft	  [float!]
			d	  [integer!]
			dd	  [integer!]
			tt	  [float!]
			h	  [float!]
			days? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/do-math"]]
		left:  as red-date! stack/arguments
		right: as red-date! left + 1
		days?: no						;-- return days?

		switch TYPE_OF(right) [			;-- left value is always a date!, only need to check right value
			TYPE_INTEGER [
				int: as red-integer! right
				dd: int/value
				tt: 0.0
			]
			TYPE_TIME [
				tm: as red-time! right
				dd: 0
				tt: tm/time
			]
			TYPE_DATE [
				if type = OP_ADD [
					fire [TO_ERROR(script not-related) words/_add datatype/push TYPE_DATE]
				]
				days?: yes
				dd: date-to-days right/date
				tt: right/time
			]
			default [
				fire [TO_ERROR(script invalid-type) datatype/push TYPE_OF(right)]
			]
		]

		tz: DATE_GET_ZONE(left/date)
		days: date-to-days left/date
		ft: left/time
		switch type [
			OP_ADD [days: days + dd ft: ft + tt]
			OP_SUB [days: days - dd	ft: ft - tt]
			default [0]
		]

		;-- normalize time
		h: ft / time/h-factor
		d: (as-integer h) / 24
		days: days + d
		h: as float! (d * 24)
		ft: ft - (h * time/h-factor)
		if ft < 0.0 [
			days: days - 1
			ft: 24.0 * time/h-factor + ft
		]

		either days? [
			int: as red-integer! left
			int/header: TYPE_INTEGER
			int/value: days
		][
			left/date: days-to-date days tz
			left/time: ft
		]
		left
	]

	set-time: func [
		dt	[red-date!]
		tm	[float!]
		/local
			h	[float!]
			d	[integer!]
			dd	[integer!] 
			tz	[integer!]
	][
		tz: DATE_GET_ZONE(dt/date)
		dd: date-to-days dt/date

		;-- normalize time
		h: tm / time/h-factor
		d: (as-integer h) / 24
		dd: dd + d
		h: as float! (d * 24)
		tm: tm - (h * time/h-factor)
		if tm < 0.0 [
			dd: dd - 1
			tm: 24.0 * time/h-factor + tm
		]
		dt/date: days-to-date dd tz
		dt/time: tm
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

	random: func [
		dt		[red-date!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			y	[integer!]
			d	[integer!]
			n	[integer!]
			dd	[integer!]	
			s	[float!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/random"]]

		d: dt/date
		either seed? [
			_random/srand d
			dt/header: TYPE_UNSET
		][
			y: DATE_GET_YEAR(d)
			n: _random/rand % y + 1			
			if y < 0 [n: 0 - n]
			dd: _random/rand % (d and FFFFh)
			dt/date: n << 16 or (dd and 80h) or DATE_GET_ZONE(d)

			s: (as-float _random/rand) / 2147483647.0
			dt/time: s * 24.0 * time/h-factor
		]
		as red-value! dt
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
			hour   [integer!]
			mn	   [integer!]
			len	   [integer!]
			d	   [integer!]
			zone   [integer!]
			sign   [byte!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/mold"]]
		
		d: dt/date
		formed: integer/form-signed DATE_GET_DAY(d)
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?
		
		string/append-char GET_BUFFER(buffer) as-integer #"-"
		
		blk: as red-block! #get system/locale/months
		month: as red-string! (block/rs-head blk) + DATE_GET_MONTH(d) - 1
		;if month > block/rs-tail [...]					;@@ fire error
		;if TYPE_OF(month) <> TYPE_STRING [...]			;@@ fire error
		
		string/concatenate buffer month 3 0 yes no
		part: part - 4									;-- 3 + separator
		
		string/append-char GET_BUFFER(buffer) as-integer #"-"
		
		formed: integer/form-signed DATE_GET_YEAR(d)
		string/concatenate-literal buffer formed
		len: 4 - length? formed
		if len > 0 [loop len [string/append-char GET_BUFFER(buffer) as-integer #"0"]]
		part: part - 5									;-- 4 + separator
		
		if dt/time <> 0.0 [
			zone: DATE_GET_ZONE(d)
			string/append-char GET_BUFFER(buffer) as-integer #"/"
			part: time/mold as red-time! dt buffer only? all? flat? arg part - 1 indent

			if zone <> 0 [
				sign: either as-logic zone >> 6 [#"-"][#"+"]
				string/append-char GET_BUFFER(buffer) as-integer sign
				hour: DATE_GET_ZONE_HOURS(d)
				if hour < 10 [
					string/append-char GET_BUFFER(buffer) as-integer #"0"
					part: part - 1
				]
				formed: integer/form-signed hour
				string/concatenate-literal buffer formed
				part: part - 1 - length? formed			;@@ optimize by removing length?
				
				string/append-char GET_BUFFER(buffer) as-integer #":"
				mn: DATE_GET_ZONE_MINUTES(d)
				if mn < 10 [
					string/append-char GET_BUFFER(buffer) as-integer #"0"
					part: part - 1
				]
				formed: integer/form-signed mn
				string/concatenate-literal buffer formed
				part: part - 1 - length? formed			;@@ optimize by removing length?
			]
		]
		part
	]

	add: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "date/add"]]
		as red-value! do-math OP_ADD
	]

	subtract: func [return: [red-value!]][
		#if debug? = yes [if verbose > 0 [print-line "date/subtract"]]
		as red-value! do-math OP_SUB
	]

	eval-path: func [
		dt		[red-date!]								;-- implicit type casting
		element	[red-value!]
		value	[red-value!]
		path	[red-value!]
		case?	[logic!]
		return:	[red-value!]
		/local
			word   [red-word!]
			int	   [red-integer!]
			fl	   [red-float!]
			tm	   [red-time!]
			p	   [red-pair!]
			field  [integer!]
			sym	   [integer!]
			v	   [integer!]
			d	   [integer!]
			h	   [integer!]
			m	   [integer!]
			fval   [float!]
			error? [logic!]
	][
		error?: no

		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				field: int/value
				if any [field < 1 field > 10][error?: yes]
			]
			TYPE_WORD [
				word: as red-word! element
				sym: symbol/resolve word/symbol
				case [
					sym = words/year   [field: 1]
					sym = words/month  [field: 2]
					sym = words/day	   [field: 3]
					sym = words/zone   [field: 4]
					sym = words/time   [field: 5]
					sym = words/hour   [field: 6]
					sym = words/minute [field: 7]
					sym = words/second [field: 8]
					sym = words/weekday[field: 9]
					sym = words/julian [field: 10]
					true 			   [error?: yes]
				]
			]
			default [error?: yes]
		]
		if error? [fire [TO_ERROR(script invalid-path) stack/arguments element]]

		either value <> null [
			if any [all [1 <= field field <= 3] field = 9 field = 10][
				if TYPE_OF(value) <> TYPE_INTEGER [fire [TO_ERROR(script invalid-arg) value]]
				int: as red-integer! value
				v: int/value
			]
			d: dt/date
			switch field [
				1 [dt/date: DATE_SET_YEAR(d v)]
				2 [dt/date: days-to-date v + date-to-days DATE_SET_MONTH(d 0) 0]
				3 [dt/date: days-to-date v + date-to-days DATE_SET_DAY(d 0) 0]
				4 [
					switch TYPE_OF(value) [
						TYPE_INTEGER [
							int: as red-integer! value
							h: int/value
							m: 0
						]
						TYPE_TIME [
							tm: as red-time! value
							h: time/get-hour tm/time
							m: time/get-minute tm/time
						]
						TYPE_PAIR [
							p: as red-pair! value
							h: p/x
							m: p/y
						]
						default [fire [TO_ERROR(script invalid-arg) value]]
					]
					if h < 0 [h: 0 - h and 0Fh or 10h]	;-- properly set the sign bit
					v: h << 2 or (m / 15 and 03h)
					dt/date: DATE_SET_ZONE(d v)
				]
				5 [
					either TYPE_OF(value) = TYPE_TIME [
						tm: as red-time! value
						dt/time: tm/time
					][
						stack/keep
						time/eval-path as red-time! dt as red-value! integer/push 3 value path case?	;-- set seconds
					]
					set-time dt dt/time
				]
				6 7 8 [
					stack/keep
					time/eval-path as red-time! dt element value path case?
					set-time dt dt/time
					return value
				]
				9  [d: date-to-days d dt/date: days-to-date d + (v % 7) - (d + 2 % 7 + 1) 0]
				10 [dt/date: days-to-date v + (Jan-1st-of d) - 1 0]
				default [assert false]
			]
			value
		][
			value: push-field dt field
			stack/pop 1									;-- avoids moving stack up
			value
		]
	]

	compare: func [
		value1    [red-date!]							;-- first operand
		value2    [red-date!]							;-- second operand
		op	      [integer!]							;-- type of comparison
		return:   [integer!]
		/local
			type	[integer!]
			res		[integer!]
			t1		[float!]
			t2		[float!]
			eq?		[logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/compare"]]

		type: TYPE_OF(value2)
		if type <> TYPE_DATE [RETURN_COMPARE_OTHER]

		t1: dt-to-nanosec value1/date value1/time
		t2: dt-to-nanosec value2/date value2/time
		eq?: float/almost-equal t1 t2
		switch op [
			COMP_EQUAL
			COMP_NOT_EQUAL [res: as-integer not eq?]
			COMP_SAME
			COMP_STRICT_EQUAL [res: as-integer t1 <> t2]
			default [
				either eq? [res: 0][res: SIGN_COMPARE_RESULT(t1 t2)]
			]
		]
		res
	]

	pick: func [
		dt		[red-date!]
		index	[integer!]
		boxed	[red-value!]
		return:	[red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/pick"]]

		if any [index < 1 index > 10][fire [TO_ERROR(script out-of-range) boxed]]
		push-field dt index
	]
	
	init: does [
		datatype/register [
			TYPE_DATE
			TYPE_VALUE
			"date!"
			;-- General actions --
			:make
			:random
			null			;reflect
			null			;to
			:form
			:mold
			:eval-path
			null			;set-path
			:compare
			;-- Scalar actions --
			null			;absolute
			:add
			null			;divide
			null			;multiply
			null			;negate
			null			;power
			null			;remainder
			null			;round
			:subtract
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