Red/System [
	Title:	"Windows calendar widget"
	Author: "Vladimir Vasilyev"
	File: 	%calendar.reds
	Tabs: 	4
	Rights: "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

with [platform][
	change-calendar: func [
		handle [handle!]
		date   [red-date!]
		/local
			time [tagSYSTEMTIME]
	][
		time: declare tagSYSTEMTIME		
		time/year-month: get-year-month date
		time/week-day: get-day date

		SendMessage handle MCM_SETCURSEL 0 as integer! time
	]
	
	sync-calendar: func [
		handle [handle!]
		/local
			slot  [red-value!]
			time  [tagSYSTEMTIME]
			year  [integer!]
			month [integer!]
			day   [integer!]
	][
		time: declare tagSYSTEMTIME
		SendMessage handle MCM_GETCURSEL 0 as integer! time
		
		year:  cap WIN32_LOWORD(time/year-month)
		month: WIN32_HIWORD(time/year-month)
		day:   WIN32_HIWORD(time/week-day)
		
		current-msg/hWnd: handle
		
		slot: get-facet current-msg FACE_OBJ_DATA
		date/make-at slot year month day 0.0 0 0 no no
	]
	
	init-calendar: func [
		handle [handle!]
		data   [red-value!]
	][
		either TYPE_OF(data) = TYPE_DATE [
			change-calendar handle as red-date! data
		][
			sync-calendar handle
		]
	]
	
	update-calendar-color: func [
		handle [handle!]
		color  [red-value!]
	][
		switch TYPE_OF(color) [
			TYPE_TUPLE [SendMessage handle MCM_SETCOLOR 0 color/data1]
			TYPE_NONE  [SendMessage handle MCM_SETCOLOR 0 00FFFFFFh]
			default    [0]
		]
	]
	
	process-calendar-change: func [handle [handle!]][
		sync-calendar handle
		make-event current-msg 0 EVT_CHANGE
	]
	
	get-year-month: func [date [red-date!] return: [integer!]][
		return DATE_GET_MONTH(date/date) << 16 or cap DATE_GET_YEAR(date/date)
	]
	
	get-day: func [date [red-date!] return: [integer!]][
		return DATE_GET_DAY(date/date) << 16 and FFFF0000h
	]
	
	;-- possible overflow: Win32 1601:30827, Red -16384:16383
	cap: func [year [integer!] return: [integer!]][
		if year < 1601  [year: 1601]
		if year > 16383 [year: 16383]
		return year
	]
]
