Red/System [
	Title:	 "Date! datatype runtime functions"
	Author:	 "Nenad Rakocevic, Xie Qingtian"
	File: 	 %date.reds
	Tabs:	 4
	Rights:	 "Copyright (C) 2017-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

date: context [
	verbose: 0
	
	#define DATE_GET_YEAR(d)		 (d >> 17)
	#define DATE_GET_MONTH(d)		 ((d >> 12) and 0Fh)
	#define DATE_GET_DAY(d)			 ((d >> 7) and 1Fh)
	#define DATE_GET_ZONE(d)		 (d and 7Fh)		;-- sign included
	#define DATE_GET_ZONE_SIGN(d)	 (as-logic d and 40h >>	6)
	#define DATE_GET_ZONE_HOURS(d)	 (d and 3Fh >> 2)	;-- sign excluded
	#define DATE_GET_ZONE_MINUTES(d) (d and 03h * 15)
	#define DATE_GET_SECONDS(t)		 (t // 60.0)
	#define DATE_GET_TIME_FLAG(d)	 (as-logic d >> 16 and 01h)
	
	#define DATE_SET_YEAR(d year)	 (d and 0001FFFFh or (year << 17))
	#define DATE_SET_MONTH(d month)	 (d and FFFF0FFFh or (month and 0Fh << 12))
	#define DATE_SET_DAY(d day)		 (d and FFFFF07Fh or (day and 1Fh << 7))
	#define DATE_SET_ZONE(d zone)	 (d and FFFFFF80h or (zone and 7Fh))
	#define DATE_SET_ZONE_NEG(z) 	 (z or 40h)
	#define DATE_SET_TIME_FLAG(d)	 (d or 00010000h)
	#define DATE_CLEAR_TIME_FLAG(d)	 (d and FFFEFFFFh)
	
	throw-error: func [spec [red-value!]][
		fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_DATE spec]
	]
	
	push-field: func [
		dt		[red-date!]
		field	[integer!]
		return: [red-value!]
		/local
			d	 [integer!]
			s	 [integer!]
			w	 [integer!]
			wd	 [integer!]
			days [integer!]
			d1	 [integer!]
			d2	 [integer!]
			y	 [integer!]
			t	 [float!]
	][
		d: dt/date
		t: to-local-time dt/time DATE_GET_ZONE(d)
		as red-value! switch field [
			1 [push d and FFFEFF80h 0.0]
			2 [integer/push DATE_GET_YEAR(d)]
			3 [integer/push DATE_GET_MONTH(d)]
			4 [integer/push DATE_GET_DAY(d)]
			5 12 [
				either DATE_GET_TIME_FLAG(d) [
					t: (as-float DATE_GET_ZONE_HOURS(d)) * 3600.0
						+ ((as-float DATE_GET_ZONE_MINUTES(d)) * 60.0)

					if DATE_GET_ZONE_SIGN(d) [t: 0.0 - t]
					time/push t
				][none/push]
			]
			6 [either DATE_GET_TIME_FLAG(d) [time/push t][none/push]]
			7 [integer/push time/get-hours t]
			8 [integer/push time/get-minutes t]
			9 [float/push DATE_GET_SECONDS(t)]
		   10 [integer/push (date-to-days d) + 2 % 7 + 1]
		   11 [integer/push get-yearday d]
		   13 [
				wd: (Jan-1st-of d) + 3 % 7				;-- start the week on Sunday
				days: 7 - wd
				d: get-yearday d
				d: either d <= days [1][d + wd - 1 / 7 + 1]
				integer/push d
			]
		   14 [
		   		wd: 0
		   		d1: W1-1-of d :wd						;-- first day of first week
		   		days: date-to-days d
		   		w: either days >= d1 [
		   			y: 1 + DATE_GET_YEAR(d)
		   			d2: W1-1-of DATE_SET_YEAR(d y) :wd	;-- first day of first week of next year
		   			either days < d2 [days - d1 / 7 + 1][1]
		   		][
		   			switch wd [
		   				1 2 3 4 [1]
		   				5		[53]
		   				6		[either leap-year? DATE_GET_YEAR(d) - 1 [53][52]]
		   				7		[52]
		   			]
		   		]
		   		integer/push w
		   	]
		   default [assert false]
		]
	]
	
	leap-year?: func [
		year	[integer!]
		return: [logic!]
	][
		any [all [year and 3 = 0 year % 100 <> 0] year % 400 = 0]
	]
	
	Jan-1st-of: func [
		d		[integer!]
		return: [integer!]								;-- returns Jan-1st(d) in Gregorian days
	][
		d: DATE_SET_DAY(d 1)
		d: DATE_SET_MONTH(d 1)
		date-to-days d
	]
	
	W1-1-of: func [										;-- 1st day of W1
		d		[integer!]
		weekday [int-ptr!]								;-- set to weekday of Jan-1st
		return: [integer!]								;-- returns W1-1 in Gregorian days
		/local
			days [integer!]
			base [integer!]
			wd	 [integer!]
	][
		days: Jan-1st-of d
		wd: days + 2 % 7 + 1
		weekday/value: wd
		base: either wd < 5 [1][8]						;-- before Friday, go prev Monday, from Friday, go to next one
		days + base - wd								;-- adjust to closest Monday
	]
	
	to-epoch: func [
		dt		[red-date!]
		return: [integer!]
		/local
			base [integer!]
			tm	 [integer!]
	][
		base: (date-to-days dt/date) - (Jan-1st-of 1970 << 17) * 86400
		tm: as-integer (dt/time + 0.5)
		base + tm
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
		time?	[logic!]
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
		f: 10000.0 * as-float days
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
		d: y << 17 or (m << 12) or (d << 7) or tz
		d and FFFEFFFFh or ((as-integer time?) << 16)
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

	get-yearday: func [
		date	[integer!]
		return: [integer!]
	][
		(date-to-days date) - (Jan-1st-of date) + 1
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
		m: DATE_GET_ZONE_MINUTES(tz)
		if DATE_GET_ZONE_SIGN(tz) [h: 0 - h m: 0 - m]
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

	normalize-time: func [
		days	[integer!]
		ft-ptr	[float-ptr!]
		tz		[integer!]
		return:	[integer!]							;-- days
		/local
			ft	  [float!]
			d	  [integer!]
			hz	  [integer!]
			htz	  [float!]
			tt	  [float!]
			h	  [float!]
	][
		hz: DATE_GET_ZONE_HOURS(tz)
		if DATE_GET_ZONE_SIGN(tz) [hz: 0 - hz]
		htz: (as-float hz) + ((as-float DATE_GET_ZONE_MINUTES(tz)) / 60.0)
		ft: ft-ptr/value

		h: ft / time/h-factor
		d: (as-integer h + htz) / 24
		days: days + d
		h: as float! (d * 24)
		ft: ft - (h * time/h-factor)
		if ft + (htz * time/h-factor) < 0.0 [
			days: days - 1
			ft: 24.0 * time/h-factor + ft
		]
		ft-ptr/value: ft
		days
	]
	
	difference?: func [
		dt1		[red-date!]
		dt2		[red-date!]
		return: [red-time!]
		/local
			t	[red-time!]
			d1	[integer!]
			d2	[integer!]
			tm	[float!]
	][
		d1: date-to-days dt1/date
		d2: date-to-days dt2/date
		d1: d1 - d2 * 24
		tm: dt1/time - dt2/time
		t: as red-time! dt1
		t/header: TYPE_TIME
		t/time: (as float! d1) * time/h-factor + tm
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
			dd	  [integer!]
			tt	  [float!]
			days? [logic!]
			time? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/do-math"]]
		left:  as red-date! stack/arguments
		right: as red-date! left + 1
		days?: no						;-- return days?
		time?: DATE_GET_TIME_FLAG(left/date)

		switch TYPE_OF(right) [			;-- left value is always a date!, only need to check right value
			TYPE_INTEGER [
				int: as red-integer! right
				dd: int/value
				tt: 0.0
			]
			TYPE_TIME [
				time?: yes
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
		days: normalize-time days :ft tz
		
		either days? [
			int: as red-integer! left
			int/header: TYPE_INTEGER
			int/value: days
		][
			left/date: days-to-date days tz time?
			left/time: ft
		]
		left
	]
	
	set-month: func [
		dt	[red-date!]
		v	[integer!]
		/local
			y [integer!]
			d [integer!]
	][
		d: dt/date
		y: v - 1 / 12
		if any [y < 0 v <= 0][y: y - 1]
		y: DATE_GET_YEAR(d) + y
		d: DATE_SET_YEAR(d y)
		v: v % 12
		if v <= 0 [v: 12 + v]
		dt/date: days-to-date
			date-to-days DATE_SET_MONTH(d v)
			DATE_GET_ZONE(d)
			DATE_GET_TIME_FLAG(dt/date)
	]

	set-time: func [
		dt	 [red-date!]
		tm	 [float!]
		utc? [logic!]									;-- convert input time to UTC
		/local
			d	[integer!]
			dd	[integer!] 
			tz	[integer!]
	][
		tz: DATE_GET_ZONE(dt/date)
		dd: date-to-days dt/date
		if utc? [tm: to-utc-time tm tz]
		dd: normalize-time dd :tm tz
		dt/date: days-to-date dd tz DATE_GET_TIME_FLAG(dt/date)
		dt/time: tm
	]
	
	set-timezone: func [
		dt 	  [red-date!]
		value [red-value!]
		both? [logic!]
		/local
			int	   [red-integer!]
			tm	   [red-time!]
			d	   [integer!]
			h	   [integer!]
			m	   [integer!]
			v	   [integer!]
			delta  [float!]
			t	   [float!]
			neg?   [logic!]
	][
		switch TYPE_OF(value) [
			TYPE_INTEGER [
				int: as red-integer! value
				h: int/value
				m: 0
			]
			TYPE_TIME [
				tm: as red-time! value
				h: time/get-hours tm/time
				m: time/get-minutes tm/time
			]
			default [fire [TO_ERROR(script invalid-arg) value]]
		]
		d: dt/date
		neg?: either h < 0 [h: 0 - h yes][no]
		v: h << 2 or (m / 15 and 03h)
		if neg? [v: DATE_SET_ZONE_NEG(v)]

		either both? [									;-- /timezone
			dt/date: DATE_SET_ZONE(d v)
			delta: ((as float! h) * time/h-factor) + ((as float! m) * time/m-factor)
			if neg? [delta: 0.0 - delta]
			set-time dt dt/time + delta yes
		][												;-- /zone
			t: to-local-time dt/time DATE_GET_ZONE(d)
			dt/date: DATE_SET_ZONE(d v)
			dt/time: to-utc-time t v
		]
	]

	set-all: func[
		dt     [red-date!]
		year   [integer!]
		month  [integer!]
		day    [integer!]
		hour   [integer!]
		minute [integer!]
		second [integer!]
		nsec   [integer!] 
		/local d t
	][
		d: 0 t: 0.0
		d: DATE_SET_YEAR(d year)
		d: DATE_SET_MONTH(d month)
		d: DATE_SET_DAY(d day)
		d: DATE_SET_TIME_FLAG(d)
		t:  (3600.0 * as float! hour)
		  + (60.0   * as float! minute)
		  + (         as float! second)
		  + (1e-9   * as float! nsec)
		dt/header: TYPE_DATE
		dt/date: d
		dt/time: t
	]
	
	create: func [
		proto 	[red-value!]							;-- overwrite this slot with result
		spec	[red-value!]
		type	[integer!]
		norm?	[logic!]								;-- yes: normalize, no: error on invalid input
		return: [red-value!]
		/local
			value [red-value!]
			tail  [red-value!]
			v	  [red-value!]
			int	  [red-integer!]
			fl	  [red-float!]
			tm	  [red-time!]
			dt	  [red-date!]
			cnt   [integer!]
			i	  [integer!]
			year  [integer!]
			month [integer!]
			day   [integer!]
			hour  [integer!]
			min	  [integer!]
			mn	  [integer!]
			sec   [integer!]
			zone  [integer!]
			d	  [integer!]
			h	  [integer!]
			t	  [float!]
			ftime [float!]
			sec-t [float!]
			zone-t[float!]
			neg?  [logic!]
	][
		if TYPE_OF(spec) = TYPE_DATE [return spec]
		
		year:   0
		month:  1
		day:    1
		ftime:	0.0
		hour:	0
		min:	0
		sec:	0
		sec-t:	0.0
		zone:	0
		zone-t:	0.0
		
		switch TYPE_OF(spec) [
			TYPE_ANY_LIST [
				value: block/rs-head as red-block! spec
				tail:  block/rs-tail as red-block! spec
				
				cnt: 0
				while [value < tail][
					i: 0
					t: 0.0
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
						TYPE_TIME [
							if cnt < 3 [throw-error spec]
							tm: as red-time! v
							t: tm/time
						]
						default [throw-error spec]
					]
					switch cnt [
						0 [day:	  i]
						1 [month: i]
						2 [year:  i]
						3 [hour:  i ftime:	t]
						4 [min:	  i zone-t:	t]
						5 [sec:	  i sec-t:	t]
						6 [zone:  i zone-t:	t]
						default [throw-error spec]
					]
					cnt: cnt + 1
					value: value + 1
				]
				if any [
					all [cnt < 3 cnt > 7]				;-- nb of args out of range
					all [cnt = 4 hour <> 0]				;-- time expected to be a time! value
					all [cnt = 5 hour <> 0]				;-- time expected to be a time! value
				][throw-error spec]
				
				if any [cnt = 5 cnt = 7][
					either all [
						any [all [cnt = 5 min = 0] all [cnt = 7 zone = 0]]
						zone-t <> 0.0
					][
						i: time/get-hours zone-t
						mn: (time/get-minutes zone-t) / 15
					][
						i: either all [cnt = 5 min <> 0][min][zone]
						mn: 0
					]
					if all [cnt = 7 zone-t = 0.0 any [zone > 15 zone < -15]][
						throw-error spec
					]
					neg?: either i < 0 [i: 0 - i yes][no]
					zone: i << 2 and 7Fh or mn
					if neg? [zone: DATE_SET_ZONE_NEG(zone)]
				]
				if any [cnt = 6 cnt = 7][
					t: ((as-float hour) * 3600.0) + ((as-float min) * 60.0)
					ftime: either sec-t = 0.0 [t + as-float sec][t + sec-t]
				]
			]
			default [throw-error spec]
		]
		if all [day >= 100 day > year][i: year year: day day: i]	;-- allow year to be first

		dt: as red-date! stack/arguments
		dt/header: TYPE_DATE
		dt/date: DATE_SET_YEAR(0 year)
		set-month dt month
		dt/date: days-to-date day + date-to-days dt/date 0 cnt > 3
		set-time dt ftime no
		
		unless norm? [
			d: dt/date
			h: time/get-hours ftime
			if any [cnt = 4 cnt = 5][min: time/get-minutes ftime]
			if any [
				year  <> DATE_GET_YEAR(d)
				month <> DATE_GET_MONTH(d)
				day   <> DATE_GET_DAY(d)
				all [ftime <> 0.0 any [
					h < 0 h > 23
					min <> time/get-minutes dt/time
				]]
				all [ftime = 0.0 any [
					hour <> time/get-hours dt/time
					min  <> time/get-minutes dt/time
				]]
			][throw-error spec]
		]
		dt/date: DATE_SET_ZONE(dt/date zone)
		set-time dt dt/time yes
		
		as red-value! dt
	]

	;-- Actions --

	make: func [
		proto 	[red-value!]							;-- overwrite this slot with result
		spec	[red-value!]
		type	[integer!]
		return: [red-value!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/make"]]
		
		create proto spec type no
	]

	random: func [
		dt		[red-date!]
		seed?	[logic!]
		secure? [logic!]
		only?   [logic!]
		return: [red-value!]
		/local
			d	  [integer!]
			n	  [integer!]
			dd	  [integer!]
			tz	  [integer!]
			s	  [float!]
			d1	  [integer!]
			time? [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/random"]]

		d: dt/date
		d1: as integer! dt/time
		either seed? [
			_random/srand d1
			dt/header: TYPE_UNSET
		][
			time?: DATE_GET_TIME_FLAG(d)
			dt/date: days-to-date _random/rand % date-to-days d DATE_GET_ZONE(d) time?
			if time? [
				dt/date: DATE_SET_ZONE(dt/date _random/rand)
				s: (as-float _random/rand) / 2147483647.0 * 3600.0
				s: (floor s) / 3600.0
				dt/time: s * 24.0 * time/h-factor
				set-time dt dt/time yes
			]
		]
		as red-value! dt
	]
	
	to: func [
		proto 	[red-value!]							;-- overwrite this slot with result
		spec	[red-value!]							;-- epoch time
		type	[integer!]
		return: [red-value!]
		/local
			dt	 [red-date!]
			int  [red-integer!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/to"]]

		switch TYPE_OF(spec) [
			TYPE_INTEGER  [0]
			TYPE_DATE	  [return spec]
			TYPE_ANY_LIST [return create proto spec type yes]
			default 	  [fire [TO_ERROR(script bad-to-arg) datatype/push TYPE_DATE spec]]
		]
		int: as red-integer! spec
		dt: as red-date! proto
		dt/header: TYPE_DATE
		dt/date: days-to-date (int/value / 86400) + (Jan-1st-of 1970 << 17) 0 yes
		dt/time: (as-float int/value % 86400)
		if int/value < 0 [set-time dt dt/time no]
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
			year   [integer!]
			sep	   [integer!]
			sign   [byte!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/mold"]]
		
		d: dt/date
		year: DATE_GET_YEAR(d)
		sep: either year < 0 [as-integer #"/"][as-integer #"-"]
		
		formed: integer/form-signed DATE_GET_DAY(d)
		string/concatenate-literal buffer formed
		part: part - length? formed						;@@ optimize by removing length?
		
		string/append-char GET_BUFFER(buffer) sep
		
		blk: as red-block! #get system/locale/months
		month: as red-string! (block/rs-head blk) + DATE_GET_MONTH(d) - 1
		if any [month > block/rs-tail blk TYPE_OF(month) <> TYPE_STRING][
			fire [TO_ERROR(script invalid-months)]
		]
		string/concatenate buffer month 3 0 yes no
		part: part - 4									;-- 3 + separator
		
		string/append-char GET_BUFFER(buffer) sep
		
		formed: integer/form-signed year
		part: either year >= 0 [
			len: 4 - length? formed
			if len > 0 [loop len [string/append-char GET_BUFFER(buffer) as-integer #"0"]]
			part - 5									;-- 4 + separator
		][
			part - length? formed
		]
		string/concatenate-literal buffer formed
		
		if DATE_GET_TIME_FLAG(d) [
			zone: DATE_GET_ZONE(d)
			string/append-char GET_BUFFER(buffer) as-integer #"/"
			time/serialize to-local-time dt/time zone buffer part

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
			tm	   [red-time!]
			dt2	   [red-date!]
			days   [integer!]
			field  [integer!]
			sym	   [integer!]
			v	   [integer!]
			d	   [integer!]
			wd	   [integer!]
			time?  [logic!]
			error? [logic!]
	][
		error?: no

		switch TYPE_OF(element) [
			TYPE_INTEGER [
				int: as red-integer! element
				field: int/value
				if any [field < 1 field > 14][error?: yes]
			]
			TYPE_WORD [
				word: as red-word! element
				sym: symbol/resolve word/symbol
				case [
					sym = words/date   	 [field: 1]
					sym = words/year   	 [field: 2]
					sym = words/month  	 [field: 3]
					sym = words/day	   	 [field: 4]
					sym = words/zone   	 [field: 5]
					sym = words/time   	 [field: 6]
					sym = words/hour   	 [field: 7]
					sym = words/minute 	 [field: 8]
					sym = words/second 	 [field: 9]
					sym = words/weekday	 [field: 10]
					sym = words/yearday	 [field: 11]
					sym = words/julian 	 [field: 11]
					sym = words/timezone [field: 12]
					sym = words/week 	 [field: 13]
					sym = words/isoweek	 [field: 14]
					true 			   [error?: yes]
				]
			]
			default [error?: yes]
		]
		if error? [fire [TO_ERROR(script invalid-path) path element]]

		either value <> null [
			if any [all [2 <= field field <= 4] field = 10 field = 11 field = 13 field = 14][
				if TYPE_OF(value) <> TYPE_INTEGER [fire [TO_ERROR(script invalid-arg) value]]
				int: as red-integer! value
				v: int/value
			]
			d: dt/date
			time?: DATE_GET_TIME_FLAG(d)
			switch field [
				1 [
					if TYPE_OF(value) <> TYPE_DATE [fire [TO_ERROR(script invalid-arg) value]]
					dt2: as red-date! value
					v: DATE_GET_ZONE(d)
					dt/date: DATE_SET_ZONE(dt2/date v)
				]
				2 [dt/date: DATE_SET_YEAR(d v)]			;-- /year:
				3 [set-month dt v]						;-- /month:
				4 [										;-- /day:
					dt/date: days-to-date v + date-to-days DATE_SET_DAY(d 0) DATE_GET_ZONE(d) time?
				]
				5 12 [									;-- /zone: /timezone:
					dt/date: DATE_SET_TIME_FLAG(d)
					set-timezone dt value field = 12
				]
				6 [										;-- /time:
					switch TYPE_OF(value) [
						TYPE_NONE [
							dt/date: DATE_CLEAR_TIME_FLAG(d)
							dt/time: 0.0
						]
						TYPE_TIME [
							dt/date: DATE_SET_TIME_FLAG(d)
							tm: as red-time! value
							set-time dt tm/time yes
						]
						default [fire [TO_ERROR(script invalid-arg) value]]
					]
				]
				7 8 9 [									;-- /hour: /minute: /second:
					stack/keep
					if TYPE_OF(element) = TYPE_INTEGER [
						int: as red-integer! element
						int/value: int/value - 6		;-- normalize accessor for time!
					]
					time/eval-path as red-time! dt element value path case?
					set-time dt dt/time field = 7
					dt/date: DATE_SET_TIME_FLAG(dt/date)
				]
				10  [									;-- /weekday:
					days: date-to-days d
					dt/date: days-to-date days + (v - 1) - (days + 2 % 7) DATE_GET_ZONE(d) time?
				]
				11 [									;-- /yearday: /julian: 
					dt/date: days-to-date v + (Jan-1st-of d) - 1 DATE_GET_ZONE(d) time?
				]
				13 [									;-- /week:
					days: Jan-1st-of d
					if v > 1 [
						wd: days + 3 % 7				;-- start the week on Sunday
						days: days + (v - 2 * 7) + 7 - wd
					]
					dt/date: days-to-date days DATE_GET_ZONE(d) time?
				]
				14 [									;-- /isoweek:
					wd: 0
					dt/date: days-to-date v - 1 * 7 + W1-1-of d :wd DATE_GET_ZONE(d) time?
				]
				default [assert false]
			]
			object/check-owner as red-value! dt
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
			type [integer!]
			res	 [integer!]
			d1	 [integer!]
			d2	 [integer!]
			t1	 [float!]
			t2	 [float!]
			eq?	 [logic!]
	][
		#if debug? = yes [if verbose > 0 [print-line "date/compare"]]

		type: TYPE_OF(value2)
		if type <> TYPE_DATE [RETURN_COMPARE_OTHER]
		d1: DATE_CLEAR_TIME_FLAG(value1/date) >> 7		;-- remove TZ, clear time? flag
		d2: DATE_CLEAR_TIME_FLAG(value2/date) >> 7
		t1: floor value1/time + 0.5						;-- in UTC already, round to integer
		t2: floor value2/time + 0.5
		
		eq?: all [d1 = d2 t1 = t2]
		
		switch op [
			COMP_EQUAL
			COMP_FIND
			COMP_SAME
			COMP_NOT_EQUAL
			COMP_STRICT_EQUAL [res: as-integer not eq?]
			default [
				either eq? [res: 0][
					res: SIGN_COMPARE_RESULT(d1 d2)
					if res = 0 [res: SIGN_COMPARE_RESULT(t1 t2)]
				]
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

		if any [index < 1 index > 14][fire [TO_ERROR(script out-of-range) boxed]]
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
			:to
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