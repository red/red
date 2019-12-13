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
		hWnd [handle!]
		date [red-date!]
		/local
			st [tagSYSTEMTIME]
	][
		st: declare tagSYSTEMTIME		
		st/year-month: get-year-month date/date
		st/week-day: get-day date/date

		SendMessage hWnd MCM_SETCURSEL 0 as integer! st
	]

	process-calendar-change: func [
		hWnd [handle!]
		/local
			slot  [red-value!]
			st    [tagSYSTEMTIME]
			year  [integer!]
			month [integer!]
			day   [integer!]
	][
		st: declare tagSYSTEMTIME
		SendMessage hWnd MCM_GETCURSEL 0 as integer! st
		
		year:  cap WIN32_LOWORD(st/year-month) 			;-- possible overflow: Win32 1601:30827, Red -16384:16383
		month: WIN32_HIWORD(st/year-month)
		day:   WIN32_HIWORD(st/week-day)
		
		current-msg/hWnd: hWnd
		
		slot: get-facet current-msg FACE_OBJ_DATA
		date/make-at slot year month day 0.0 0 0 no no
		
		make-event current-msg 0 EVT_CHANGE
	]
	
	get-year-month: func [date [integer!] return: [integer!]][
		return DATE_GET_MONTH(date) << 16 or cap DATE_GET_YEAR(date)
	]
	
	get-day: func [date [integer!] return: [integer!]][
		return DATE_GET_DAY(date) << 16 and FFFF0000h
	]
	
	cap: func [year [integer!] return: [integer!]][
		if year < 1601  [year: 1601]
		if year > 16383 [year: 16383]
		return year
	]
]