Red [
	Title:       "Mask date/time formatter"
	Description: https://github.com/hiiamboris/red-formatting/discussions/4
	Author:      [@hiiamboris @greggirwin]
	Rights:      "Copyright (C) 2021-2022 Red Foundation. All rights reserved."
    License: {
        Distributed under the Boost Software License, Version 1.0.
        See https://github.com/red/red/blob/master/BSL-License.txt
    }
    Notes: {
		On numbering systems:
		According to my study of CLDR, only Hawaiians are using mixed
		numbering systems in Gregorian dates (lower Roman months)
		Rest of the world sticks to default numbering system for all digits
		So no partial numbering system swapping is implemented: one system applies to everything
    	Non-gregorian calendars we don't support, but they commonly mix different digit sets.
    	
		On literal format:
		'' works as single quote both inside '...' range and outside it
		this is unlike ICU and SQL which treat '' as empty string and '''' as single quote
		they're using '' to enforce splitting of masks e.g. "m''m" is 2 patterns, not single "mm"
		but I'm not sure we need this kind of behavior knowing we have a lot of pattern alternatives
    }
]


			
; #include %../common/include-once.red
; #include %../common/show-trace.red

; #include %charmaps.red
; #include %ordinal.red
; #include %roman.red

; #include %../common/with.red
; #include %../common/localize-macro.red
; #include %../common/new-each.red

; #include %../common/composite.red
; #include %../common/error-macro.red
; #include %../common/count.red

; #include %../common/profiling.red
; #include %../common/show-trace.red

formatting/date-time-ctx: context [
	abs: :absolute
	digit!: charset "0123456789"						;-- localized using default numbering system
	
	
	;;=======  INDEPENDENT FUNCS  =======
	
	with: func [ctx code] [bind code ctx]				;@@ temp helper until we have one in runtime

	;@@ uncomment this once we have apply
	; formatting/form-integer: function [
		; "Format an integer number using min/max widths"
		; int [integer!] "Nonnegative"
		; /min w1 [integer!] "Minimum width (zero-padded)"
		; /max w2 [integer!] "Maximum width (significant part truncated)"
	; ] with formatting [
		; copy apply form-integer* 'int
	; ]
	
	;; this func is much faster than format-number-with-mask and can truncate (common for year formatting)
	form-integer*: formatting/form-integer*: function [
		"Format an integer number using min/max widths"
		int [integer!] "Nonnegative"
		/min w1 [integer!] "Minimum width (zero-padded)"
		/max w2 [integer!] "Maximum width (significant part truncated)"
	][
		if int < 0 [cause-error 'script 'invalid-arg [int]]
		
		;; routine-based variant, though it's abuse of split-float
		r: second formatting/split-float* 1.0 * int 0 0 ["" "" "" "" ""] 
		if w1 [insert/dup r #"0" w1 - length? r] 
		if w2 [remove/part r skip tail r negate w2]
		
		;; mezz variant that has no GC pressure, but is slower:
		; w1: any [w1 1]
		; r: tail "000000000"
		; while [int > 0] [
			; r: back r
			; x: int % 10
			; int: int - x / 10 
			; r/1: #"0" + x
		; ]
		; if w2 [r: skip tail r negate system/words/min length? r w2]
		; loop w1 - length? r [r: back r  r/1: #"0"]
		
		;; variant that uses 'form' which allocates RAM:
		; r: form int
		; if w1 [insert/dup r #"0" w1 - length? r] 
		; if w2 [remove/part r skip tail r negate w2]
		
		r
	]
	
	#assert [
		"0"    = formatting/form-integer*         0
		"00"   = formatting/form-integer*/min     0    2
		"1999" = formatting/form-integer*         1999
		"89"   = formatting/form-integer*/max     1989 2
		"02"   = formatting/form-integer*/min/max 2    2 2
		"02"   = formatting/form-integer*/min/max 2002 2 2
	]
	
	hour?: function [time [time!] type [integer!] "11, 12 or 23"] [
		switch/default type [
			23 [time/hour // 24]
			11 [time/hour // 12]
			12 [time/hour - 1 // 12 + 1]
		][cause-error 'script 'invalid-arg [type]]
	]
	
	#assert [
		12 = hour? 12:00 23
		23 = hour? 23:00 23
		0  = hour? 24:00 23
		1  = hour? 25:00 23
		12 = hour? 24:00 12
		11 = hour? 23:00 12
		12 = hour? 12:00 12
		12 = hour?  0:00 12
		11 = hour? 23:00 11
		0  = hour? 12:00 11
		0  = hour?  0:00 11
	]
	
	;; always rounded down, otherwise have to modify seconds too,
	;; but what if there are no seconds in the mask?
	;; that would lead to invalid subseconds (with extra leading '1' digit)
	subsecond?: function [time [time!] size [integer!]] [
		f: time/second % 1.0 * (10 ** size) + 1e-6		;-- 1e-6 compensates for rounding error
		form-integer*/min round/to/floor f 1 size
	]
	
	#assert [
		"000000" = subsecond? 1:2:3         6
		"765432" = subsecond? 1:2:3.7654321 6
		"765432" = subsecond? 1:2:3.7654327 6
		"765400" = subsecond? 1:2:3.7654    6
		"76540"  = subsecond? 1:2:3.7654    5
		"06540"  = subsecond? 1:2:3.0654    5
		"0654"   = subsecond? 1:2:3.0654    4
		"065"    = subsecond? 1:2:3.0654    3
		"06"     = subsecond? 1:2:3.0654    2
		"0"      = subsecond? 1:2:3.0654    1
		"0"      = subsecond? 1:2:3.0354    1
	]
	
	;; translates from astronomical into BC/AD numbering
	;; see https://en.wikipedia.org/wiki/Astronomical_year_numbering
	abs-year?: function [year [integer!]] [
		either year >= 1 [year][1 - year]
	]
	
	#assert [
		1999 = abs-year? 1999
		2    = abs-year? 2
		1    = abs-year? 1
		1    = abs-year? 0
		2    = abs-year? -1
		2000 = abs-year? -1999
	]
	
	;; implements 'popular' interpretation of the term 'century'
	;; according to: https://en.wikipedia.org/wiki/Century#Start_and_end_of_centuries
	century?: function [year [integer!]] [
		1 + to integer! (abs-year? year) / 100
	]
	
	#assert [
		21 = century? 2000
		20 = century? 1999
		1  = century? 1									;-- 1 AD
		1  = century? 0									;-- 1 BC
		21 = century? -1999								;-- 2000 BC = XXIth BC
	]
	
	era?: function [year [integer!] /religious] [
		pick pick [[BC AD] [BCE CE]] religious year <= 0
	]
	yearsign?: function [year [integer!]] [
		pick "-+" year <= 0
	]
	
	#assert [
		'AD  = era?/religious 1
		'CE  = era? 1
		'BC  = era?/religious 0
		'BCE = era? 0
		'BC  = era?/religious -1
		'BCE = era? -1
		#"+" = yearsign? 1
		#"-" = yearsign? 0
		#"-" = yearsign? -1
	]
	
	am-pm?: function [time [time!]] [
		pick [am pm] time < 12:00
	]
	
	#assert [
		'am = am-pm? 11:59
		'am = am-pm?  0:00
		'pm = am-pm? 12:00 
		'pm = am-pm? 23:59
	]
	
	zone?: function [date [date!] size [integer!] sep? [logic!] z? [logic!]] [
		#assert [all [1 <= size size <= 4]]
		all [z?  zero? date/zone  return "Z"]
		s: clear ""
		insert s pick "+-" date/zone >= 0:0
		append s form-integer*/min abs date/zone/hour size - 1 % 2 + 1
		if size > 2 [
			if sep? [append s #":"]	
			append s form-integer*/min date/zone/minute 2
		]
		s
	]
	
	#assert [
		d0: 1/1/1/1:0+0:00
		d1: 1/1/1/1:0+1:30
		"Z"      = zone? d0 1 no  yes
		"Z"      = zone? d0 4 yes yes
		"+0"     = zone? d0 1 no  no
		"+1"     = zone? d1 1 no  no
		"+01"    = zone? d1 2 no  no
		"+01"    = zone? d1 2 yes no
		"+01"    = zone? d1 2 yes yes
		"+1:30"  = zone? d1 3 yes no
		"+1:30"  = zone? d1 3 yes no
		"+130"   = zone? d1 3 no  no
		"+01:30" = zone? d1 4 yes no
		"+0130"  = zone? d1 4 no  no
		"+0000"  = zone? d0 4 no  no
	]
	
	
	;; combines roman numerals with ordinal suffix to get 'XXIst' etc
	;; this allocates (as-ordinal does) but I suppose it doesn't matter for this use case
	as-roman-ordinal: function [n [integer!] /in locale [word! none!]] [
		s: as-ordinal/in n locale
		t: find/last/tail s digit!
		change/part s as-roman n t
		s
	]
	
	#assert [
		"XVIth" = as-roman-ordinal/in 16 'en
		"XXIst" = as-roman-ordinal/in 21 'en
	]
	
	;; non-allocating, but does not modify the original
	lowercase: function [s [string!]] [
		system/words/lowercase append clear "" s
	]
	uppercase: function [s [string!]] [
		system/words/uppercase append clear "" s
	]
	
	
	
	;;=======  LOCALE FUNCS  =======
	
	
	.locale: none
	
	localize-path: function [
		"Fetch a path from locale's calendar data (none if not found)"
		path [path!]
	][
		#assert [.locale]
		path: as path! compose/into [
			system locale list (.locale) calendar format (as block! path)
		] clear []
		widths: [char short abbr full] 
		while [
			all [
				not found: attempt [get path]
				2 <= length? widths
			]
		][
		replace path widths/1 widths/2
			widths: next widths							;-- try fall back widths if no such path
		]
		found
	]
	
	;; used to transform Red /weekday index into key in locale data
	weekdays: [mon tue wed thu fri sat sun]
	
	localize: function [
		"Fetch a named value from locale's calendar data (none if not found)"
		item        [word!] "e.g. month or AD"
		width       [word!] "one of [full abbr short char]"
		/pick index [integer!] "Index of month, quarter, day"
	][
		path: switch item [
			AD BC CE BCE [[eras     (width) (item) ]]
			am pm        [[periods  (width) (item) ]]
			month        [[months   (width) (index)]]
			day          [[days     (width) (system/words/pick weekdays index)]]
			quarter      [[quarters (width) (index)]]
		]
		#assert [path]
		localize-path as path! compose/into path clear []
	]

	; localize!: function [
		; "Fetch a named value from locale's calendar data (pass thru if not found)"
		; item        [word!] "e.g. month or AD"
		; width       [word!] "one of [full abbr short char]"
		; /pick index [integer!] "Index of month, quarter, day"
	; ][
		; any [apply localize 'item  item] 
	; ]
	
	local-era?: function [
		year       [integer!]
		width      [word!]
		religious? [logic!]
	][
		eras: [- -]
		eras/1: era?/religious year
		eras/2: era? year
		unless religious? [reverse eras]
		any [
			localize eras/1 width						;-- try to find translation
			localize eras/2 width
			select [AD "AD" BC "BC" CE "CE" BCE "BCE"] eras/1	;-- fall back to default
		]
	]
	
	local-quarter?: function [
		date  [date!]
		width [word!]
	][
		q: 1 + to integer! date/month - 1 / 3
		any [localize/pick 'quarter width q  q]			;-- fall back to number
	]
	
	
	
	;;=======  OTHER STATEFUL FUNCS  =======
	
	
	;; vars that persist between restarts
	.date:  none										;-- what is being formatted
	.ampm?: no											;-- AM or PM marker is present in the mask?
	
	;; state flags that are reset between restarts
	.prev-pat: none										;-- adjacent patterns
	.next-pat: none
	
	reset: does [
		set [.locale .date .prev-pat .next-pat] none
		.ampm?: no
	]
	
	;; changes time to UTC before it is emitted
	to-utc: does [.date: to-UTC-date .date]
	
	;; "12" and "012" patterns are ambiguous as there are 12 months and 12 hours
	;; the worst case is like this: "25th day at 12" - has only day and hour patterns
	;;   I don't think we can predict the meaning in this case, and will output day and month instead
	;;   "25th day at 12pm" (note "pm") OTOH is better: having pm marker hints that we want time
	;; another problematic case: "11th month, 25th day at 12": we want both month and hour, but they're symmetric 
	;;   "25th day of 11th month at 12" OTOH we can sort out: pattern that is closer to date pattern is month
	;; so the following parameters should be considered:
	;;  - count of 12/012 patterns - 1 or 2
	;;    if 1, we should ask: is there any time pattern in the mask? if so, we want time, otherwise month
	;;    if 2, we should ask: what comes first, date or time? and output in this order
	;;  - presence of any time-related pattern (only minute and AM/PM matter)
	;;  - adjacence to AM/PM or minute pattern = hour, otherwise month
	;; and implementation parameters:
	;;  - order: month-hour/hour-month, which we swap in case we got it wrong
	;;  - number of 12/012 patterns already encountered (what to choose next)
	;;  - prev and next patterns, so we can check if order is correct
	;; but this is all too complex, and instead I'm only considering adjacence to minute or am/pm, for now
	neighbors12: ["aaa" "a.m." "p.m." "aa" "am" "pm" "a" "p" "mi" "mm" "59"]   
	is-hour?: does [
		any [
			find neighbors12 .prev-pat
			find neighbors12 .next-pat
		]
	]
	hour-or-month: does [either is-hour? [hour? .date/time 12][.date/month]]
	
	;; similarly, 59 minutes and 59 seconds: disambiguated by adjacency to any hour pattern
	neighbors59: ["hh23" "023" "hhh" "h23" "23" "hh" "hh12" "012" "h12" "12" "hh11" "011" "h11" "11"]
	is-59-minute?: does [
		any [
			find neighbors59 .prev-pat
			find neighbors59 .next-pat
		]
	]
	minute-or-second: does [either is-59-minute? [.date/minute][to integer! .date/second]]
		
	;; "mm" pattern: primarily month, but after hour or before second or AM/PM it's minute
	;; goal here is to be smart enough to fix the likely mistake of `hh:mm:ss`
	left-of-mm: copy neighbors59
	right-of-mm: ["ss" "59"]
	is-mm-minute?: does [
		any [
			find left-of-mm  .prev-pat
			find right-of-mm .next-pat
		]
	]
	minute-or-month: does [either is-mm-minute? [.date/minute][.date/month]]
	
	;; map is used to speed up pattern lookup, given how many there are
	rule-map: #()
	build-rule-map: function [] [
		clear rule-map
		foreach [pat prep emit] rules [
			key: pat/1 
			blk: any [rule-map/:key  rule-map/:key: copy []]
			repend blk [pat prep emit]
		]
		;; now sort rule-map longest-first, so we don't have to bother with pattern order
		cmp: func [a b] [(length? a) >= length? b]
		foreach [char blk] rule-map [
			sort/skip/compare blk 3 :cmp
		]
		; ?? rule-map
	]
	
	lookup-pattern: function [
		"Find pattern that matches given input mask at current offset"
		input [string!]
		;; returns [pattern code] or none
	][
		if all [
			key: input/1
			blk: rule-map/:key
		][
			;; simple way not used for performance reasons :(
			; locate blk [pat - - .. find/match/case input pat]
			forall blk [
				pat: blk/1
				if find/match/case input pat [return blk]
				blk: skip blk 2
			]
			none
		]
	]
	
	
	;; rules are open for modification, in case user wants some extended formats not available out of the box
	;; build-rule-map should be called after modification
	
	;; it is automatically sorted by length, but should be manually sorted by usefulness (most common first)
	;; format is: "pattern"  [what to do when found]  [what to do to emit]
	;; "found" stage is only used so far to set .ampm? presence flag and to-utc conversion
	rules: with formatting [
		"hh23"        [] [form-integer*/min hour? .date/time 23 2]
		"023"         [] [form-integer*/min hour? .date/time 23 2]
		"hhh"         [] [form-integer*/min hour? .date/time 23 2]
		"h23"         [] [hour? .date/time 23]
		"23"          [] [hour? .date/time 23]
		"hh12"        [] [form-integer*/min hour? .date/time 12 2]
		; "012"         [] [form-integer*/min hour? .date/time 12 2]	disambiguated below
		"h12"         [] [hour? .date/time 12]
		; "12"          [] [hour? .date/time 12]						disambiguated below
		"hh11"        [] [form-integer*/min hour? .date/time 11 2]
		"011"         [] [form-integer*/min hour? .date/time 11 2]
		"h11"         [] [hour? .date/time 11]
		"11"          [] [hour? .date/time 11]
		
		"mi"          [] [form-integer*/min .date/minute 2]
		"ss"          [] [form-integer*/min to integer! .date/second 2]
		
		"yyyy"        [] [form-integer*/min abs .date/year 4]		;-- year 0001, year 12345, year 0123 BC (always positive)
		"year"        [] [form-integer*/min abs .date/year 4]
		"1999"        [] [form-integer*     abs .date/year]			;-- year 1, year 12345, year 123 BC, always >= 0
		"yy"          [] [form-integer*/min/max abs .date/year 2 2]	;-- year 01, year 99, only within century, always >= 0
		"yr"          [] [form-integer*/min/max abs .date/year 2 2]
		"99"          [] [form-integer*/min/max abs .date/year 2 2]
		
		; "mm"          [] [form-integer*/min .date/month 2]			disambiguated below
		"m"           [] [.date/month]
		
		"Month"       [] [localize/pick 'month 'full .date/month]
		"December"    [] [localize/pick 'month 'full .date/month]
		"Mon"         [] [localize/pick 'month 'abbr .date/month]
		"Dec"         [] [localize/pick 'month 'abbr .date/month]
		"M"           [] [localize/pick 'month 'char .date/month]
		"D"           [] [localize/pick 'month 'char .date/month]
		
		"dd"          [] [form-integer*/min .date/day 2]
		"031"         [] [form-integer*/min .date/day 2]
		"d"           [] [.date/day]
		"31"          [] [.date/day]
		
		"7"           [] [.date/weekday]
		
		"wwww"        [] [lowercase localize/pick 'day 'full .date/weekday]
		"Wwww"        [] [          localize/pick 'day 'full .date/weekday]
		"sunday"      [] [lowercase localize/pick 'day 'full .date/weekday]
		"Sunday"      [] [          localize/pick 'day 'full .date/weekday]
		"day"         [] [lowercase localize/pick 'day 'full .date/weekday]
		"Day"         [] [          localize/pick 'day 'full .date/weekday]
		"www"         [] [lowercase localize/pick 'day 'abbr .date/weekday]
		"Www"         [] [          localize/pick 'day 'abbr .date/weekday]
		"sun"         [] [lowercase localize/pick 'day 'abbr .date/weekday]
		"Sun"         [] [          localize/pick 'day 'abbr .date/weekday]
		"dy"          [] [lowercase localize/pick 'day 'abbr .date/weekday]
		"Dy"          [] [          localize/pick 'day 'abbr .date/weekday]
		"ww"          [] [lowercase localize/pick 'day 'short .date/weekday]
		"Ww"          [] [          localize/pick 'day 'short .date/weekday]
		"su"          [] [lowercase localize/pick 'day 'short .date/weekday]
		"Su"          [] [          localize/pick 'day 'short .date/weekday]
		"w"           [] [lowercase localize/pick 'day 'char .date/weekday]
		"W"           [] [          localize/pick 'day 'char .date/weekday]
		"s"           [] [lowercase localize/pick 'day 'char .date/weekday]
		"S"           [] [          localize/pick 'day 'char .date/weekday]
		
		"aaa"  [.ampm?: yes] [lowercase localize am-pm? .date/time 'full]
		"AAA"  [.ampm?: yes] [uppercase localize am-pm? .date/time 'full]
		"a.m." [.ampm?: yes] [lowercase localize am-pm? .date/time 'full]
		"A.M." [.ampm?: yes] [uppercase localize am-pm? .date/time 'full]
		"p.m." [.ampm?: yes] [lowercase localize am-pm? .date/time 'full]
		"P.M." [.ampm?: yes] [uppercase localize am-pm? .date/time 'full]
		"aa"   [.ampm?: yes] [lowercase localize am-pm? .date/time 'abbr]
		"AA"   [.ampm?: yes] [uppercase localize am-pm? .date/time 'abbr]
		"am"   [.ampm?: yes] [lowercase localize am-pm? .date/time 'abbr]
		"AM"   [.ampm?: yes] [uppercase localize am-pm? .date/time 'abbr]
		"pm"   [.ampm?: yes] [lowercase localize am-pm? .date/time 'abbr]
		"PM"   [.ampm?: yes] [uppercase localize am-pm? .date/time 'abbr]
		"a"    [.ampm?: yes] [lowercase localize am-pm? .date/time 'char]
		"A"    [.ampm?: yes] [uppercase localize am-pm? .date/time 'char]
		"p"    [.ampm?: yes] [lowercase localize am-pm? .date/time 'char]
		"P"    [.ampm?: yes] [uppercase localize am-pm? .date/time 'char]
		
		"ffffff"      [] [subsecond? .date/time 6]
		"fffff"       [] [subsecond? .date/time 5]
		"ffff"        [] [subsecond? .date/time 4]
		"fff"         [] [subsecond? .date/time 3]
		"ff"          [] [subsecond? .date/time 2]
		"f"           [] [subsecond? .date/time 1]
		
		;; GMT patterns should affect time, even date, retroactively, so `to-utc` may restart the process
		"GMT"   [to-utc] ["GMT"]
		"UTC"   [to-utc] ["UTC"]
		"+ZZZZ"       [] [zone? .date 4 no  yes]
		"+0000Z"      [] [zone? .date 4 no  yes]
		"+ZZ:ZZ"      [] [zone? .date 4 yes yes]
		"+00:00Z"     [] [zone? .date 4 yes yes]
		"+zzzz"       [] [zone? .date 4 no  no]
		"+0000"       [] [zone? .date 4 no  no]
		"+zz:zz"      [] [zone? .date 4 yes no]
		"+00:00"      [] [zone? .date 4 yes no]
		"+z:zz"       [] [zone? .date 3 yes no]
		"+0:00"       [] [zone? .date 3 yes no]
		"+zz"         [] [zone? .date 2 no  no]
		"+00"         [] [zone? .date 2 no  no]
		"+z"          [] [zone? .date 1 no  no]
		"+0"          [] [zone? .date 1 no  no]
		
		;; date pattern only has era sign (and no other signs), as it does not deal with time intervals
		"+"           [] [yearsign? .date/year]
		
		"eee"         [] [          local-era? .date/year 'full yes]	;-- no case change by default
		"Anno Domini" [] [          local-era? .date/year 'full yes]
		"anno domini" [] [lowercase local-era? .date/year 'full yes]
		"Common Era"  [] [          local-era? .date/year 'full no]
		"common era"  [] [lowercase local-era? .date/year 'full no]
		"ee"          [] [          local-era? .date/year 'abbr yes]
		"AD"          [] [          local-era? .date/year 'abbr yes]
		"ad"          [] [lowercase local-era? .date/year 'abbr yes]
		"CE"          [] [          local-era? .date/year 'abbr no]
		"ce"          [] [lowercase local-era? .date/year 'abbr no]
		
		"20th"        [] [as-ordinal century? .date/year]
		"CRth"        [] [as-roman-ordinal century? .date/year]	;-- Ist century
		"XXth"        [] [as-roman-ordinal century? .date/year]
		"CR"          [] [as-roman   century? .date/year]			;-- I century
		"XX"          [] [as-roman   century? .date/year]
		"cr"          [] [lowercase as-roman century? .date/year]	;-- i century
		"cth"         [] [as-ordinal century? .date/year]			;-- 1st century, not 01st century
		"c"           [] [           century? .date/year]			;-- 1 century, not 01 century
		"20"          [] [           century? .date/year]
		
		"qqq"         [] [local-quarter? .date 'full]
		"4th quarter" [] [local-quarter? .date 'full]
		"qq"          [] [local-quarter? .date 'abbr]
		"q4"          [] [lowercase local-quarter? .date 'abbr]
		"Q4"          [] [local-quarter? .date 'abbr]
		"q"           [] [local-quarter? .date 'char]
		"4"           [] [local-quarter? .date 'char]
		
		;; we have both 60 seconds and 60 minutes, so need to disambiguate
		"59"          [] [form-integer*/min minute-or-second 2]
		
		;; ambiguous - see hour-or-month
		"012"         [] [form-integer*/min hour-or-month 2]
		"12"          [] [hour-or-month]
		
		;; ambiguous - see minute-or-month
		"mm"          [] [form-integer*/min minute-or-month 2]
		
		;; "hh" depends on AM/PM presence in the mask, and only 12/23 formats are supported 
		"hh" [] [
			form-integer*/min
				hour? .date/time
				pick [12 23] .ampm?
				2
		]
	]
	
	=emit-literal=: [
		#"'" [
			#"'" not #"'" keep (#"'")					;-- "x''x" case
		|	some [
				"''" keep (#"'")						;-- "x' '' 'x" case
			|	keep pick to #"'"
			] #"'"
		]
	]
	
	reserved!: charset [#"A" - #"Z" #"a" - #"z" #"0" - #"9"]
	
	;; this has to support lookahead and lookbehind (.prev-pat and .next-pat) for some patterns
	;; and it has to avoid allocations when possible, so is a bit involved
	formatting/format-date-time: function [
		"Format date or time (of today), using mask as a template"
		dt [date! time!]
		mask [string!] {e.g. "012:59:59 'of' Sunday December 31st, 1999"}
		/in locale [word! none!] "Override default locale"		;-- here affects digits only
		/local r
		/extern .date .prev-pat .next-pat .locale
	][
		reset
		.locale: system/locale/tools/expand-locale locale
		charmap: formatting/update-charmap/for .locale
		.date: either date? dt [dt][now/date + dt]
		out: make string! 10 + length? mask
		
		sequence: clear []
		patterns: clear []
		parse mask [collect into sequence any [			;-- extract the masks used so we can look around in that space
			p: if (set [pat: prep: emit:] blk: lookup-pattern p)
			(do prep  repend patterns [pat emit])
			keep ('pattern)
			(n: length? pat) n skip
		|	=emit-literal=
		|	reserved! (do make error! rejoin ["Invalid mask pattern at "mold p])
		; |	reserved! (ERROR "Invalid mask pattern at (mold p)")
		|	keep skip
		] mask:]
		
		.prev-pat: .next-pat: none
		; for-each [p: pat code] patterns [				;-- eval pattern code and combine the output
		repeat i (length? patterns) / 2 [				;@@ should be for-each
			set [pat: code:] p: skip patterns i - 1 * 2
		
			#assert [not empty? pat]
			e: any [find s: sequence 'pattern  tail s]
			append/part out s e
			sequence: next e
			.prev-pat: p/-2
			.next-pat: p/3
			set/any 'r do code
			if integer? :r [r: form-integer* r]			;-- use internal form to avoid allocations
			#assert [any [char? :r string? :r]]
			if string? :r [
				forall r [								;-- localize digits in results only
					if find digit! r/1 [r/1: charmap/default/(r/1)]	;@@ this should be `map`
				]
			]
			append out r
		]
		append out sequence								;-- flush out the rest of literal text
		out
	]
	

	build-rule-map
	
	; probe formatting/format-date-time now "023:59:59"
	; trace/deep [
	; probe formatting/format-date-time/in now/precise "31/Dec/1999 'at' 023:59:59.ffff XXth" 'en
	; ]
]

#assert [
	;; for testing 'en' locale is used, because 'testing' locale lacks a huge lot of data and I'm lazy to fill it
	fmt: func [dt mask] [formatting/format-date-time/in dt mask 'en]
	
	dt: 09/03/2004/08:07:06.05432+07:30
	
	"2004"              = fmt dt "yyyy"
	"2004"              = fmt dt "year"
	"2004"              = fmt dt "1999"
	"04"                = fmt dt "yy"
	"04"                = fmt dt "yr"
	"04"                = fmt dt "99"
	
	"03"                = fmt dt "mm"
	"3"                 = fmt dt "m"
	"March"             = fmt dt "Month"
	"March"             = fmt dt "December"
	"Mar"               = fmt dt "Mon"
	"Mar"               = fmt dt "Dec"
	"M"                 = fmt dt "M"
	"M"                 = fmt dt "D"
	
	"09"                = fmt dt "dd"
	"09"                = fmt dt "031"
	"9"                 = fmt dt "d"
	"9"                 = fmt dt "31"
	
	"tuesday"           = fmt dt "wwww"
	"tuesday"           = fmt dt "sunday"
	"tuesday"           = fmt dt "day"
	"Tuesday"           = fmt dt "Wwww"
	"Tuesday"           = fmt dt "Day"
	"tue"               = fmt dt "www"
	"tue"               = fmt dt "sun"
	"tue"               = fmt dt "dy"
	"Tue"               = fmt dt "Www"
	"Tue"               = fmt dt "Sun"
	"Tue"               = fmt dt "Dy"
	"tu"                = fmt dt "ww"
	"tu"                = fmt dt "su"
	"Tu"                = fmt dt "Ww"
	"Tu"                = fmt dt "Su"
	"t"                 = fmt dt "w"
	"t"                 = fmt dt "s"
	"T"                 = fmt dt "W"
	"T"                 = fmt dt "S"
	"2"                 = fmt dt "7"
	
	"am"                = fmt dt "aaa"
	"am"                = fmt dt "a.m."
	"am"                = fmt dt "p.m."
	"AM"                = fmt dt "AAA"
	"AM"                = fmt dt "A.M."
	"AM"                = fmt dt "P.M."
	"am"                = fmt dt "aa"
	"am"                = fmt dt "am"
	"am"                = fmt dt "pm"
	"AM"                = fmt dt "AA"
	"AM"                = fmt dt "AM"
	"AM"                = fmt dt "PM"
	"a"                 = fmt dt "a"
	"A"                 = fmt dt "A"
	"a"                 = fmt dt "p"
	"A"                 = fmt dt "P"
	
	"08"                = fmt dt "hh23"
	"08"                = fmt dt "023"
	"08"                = fmt dt "hhh"
	"8"                 = fmt dt "h23"
	"8"                 = fmt dt "23"
	"08"                = fmt dt "hh12"					;-- 012 is below - it needs context
	"8"                 = fmt dt "h12"
	"08"                = fmt dt "hh11"
	"08"                = fmt dt "011"
	"8"                 = fmt dt "h11"
	"8"                 = fmt dt "11"
	
	"07"                = fmt dt "mi"
	"06"                = fmt dt "ss"
	"054320"            = fmt dt "ffffff"
	"05432"             = fmt dt "fffff"
	"0543"              = fmt dt "ffff"
	"054"               = fmt dt "fff"
	"05"                = fmt dt "ff"
	"0"                 = fmt dt "f"					;-- time is never rounded, otherwise it's a mess

	"GMT"               = fmt dt "GMT"
	"+0730"             = fmt dt "+ZZZZ"
	"+0730"             = fmt dt "+0000Z"
	"+07:30"            = fmt dt "+ZZ:ZZ"
	"+07:30"            = fmt dt "+00:00Z"
	"+0730"             = fmt dt "+zzzz"
	"+0730"             = fmt dt "+0000"
	"+07:30"            = fmt dt "+zz:zz"
	"+07:30"            = fmt dt "+00:00"
	"+7:30"             = fmt dt "+z:zz"
	"+7:30"             = fmt dt "+0:00"
	"+07"               = fmt dt "+zz"
	"+07"               = fmt dt "+00"
	"+7"                = fmt dt "+z"
	"+7"                = fmt dt "+0"
	
	"+"                 = fmt dt "+"					;-- year sign
	
	"Anno Domini"       = fmt dt "eee"
	"Anno Domini"       = fmt dt "Anno Domini"
	"anno domini"       = fmt dt "anno domini"
	"Common Era"        = fmt dt "Common Era"
	"common era"        = fmt dt "common era"
	"AD"                = fmt dt "ee"
	"AD"                = fmt dt "AD"
	"ad"                = fmt dt "ad"
	"CE"                = fmt dt "CE"
	"ce"                = fmt dt "ce"
		
	"21st"              = fmt dt "20th"
	"XXIst"             = fmt dt "CRth"
	"XXIst"             = fmt dt "XXth"
	"XXI"               = fmt dt "CR"
	"XXI"               = fmt dt "XX"
	"xxi"               = fmt dt "cr"
	"21st"              = fmt dt "cth"
	"21"                = fmt dt "c"
	"21"                = fmt dt "20"
	
	"1st quarter"       = fmt dt "qqq"
	"1st quarter"       = fmt dt "4th quarter"
	"Q1"                = fmt dt "qq"
	"Q1"                = fmt dt "Q4"
	"q1"                = fmt dt "q4"
	"1"                 = fmt dt "q"
	"1"                 = fmt dt "4"
		
	"08:07:06"          = fmt dt "hh:mi:ss"
	"08:07:06 am"       = fmt dt "hh:mi:ss pm"
	"08:07:06"          = fmt dt "hh:mm:ss"				;-- mm is polymorphic
	"08:07"             = fmt dt "hh:mm"
	   "07:06"          = fmt dt    "mm:ss"
	"08:07:06"          = fmt dt "023:59:59"
	"08:07:06"          = fmt dt "011:59:59"
	"08:07:06"          = fmt dt "012:59:59"
	
	"9/Mar/2004 at 08:07:06.0543 in XXIst century AD" = fmt dt "31/Dec/1999 'at' 023:59:59.ffff 'in' XXth 'century' AD"
	"8 hours o'clock"   = fmt dt "h12 'hours o''clock'"
	
	dt: 09/03/2004/12:07:06.05432
	"12"                = fmt dt "hh23"
	"12"                = fmt dt "023"
	"12"                = fmt dt "hhh"
	"12"                = fmt dt "h23"
	"12"                = fmt dt "23"
	"12"                = fmt dt "hh12"
	"12"                = fmt dt "h12"
	"00"                = fmt dt "hh11"
	"00"                = fmt dt "011"
	"0"                 = fmt dt "h11"
	"0"                 = fmt dt "11"
	
	"Z"                 = fmt dt "+ZZZZ"
	"Z"                 = fmt dt "+0000Z"
	"Z"                 = fmt dt "+ZZ:ZZ"
	"Z"                 = fmt dt "+00:00Z"
	"+0000"             = fmt dt "+zzzz"
	"+0000"             = fmt dt "+0000"
	"+00:00"            = fmt dt "+zz:zz"
	"+00:00"            = fmt dt "+00:00"
	"+0:00"             = fmt dt "+z:zz"
	"+0:00"             = fmt dt "+0:00"
	"+00"               = fmt dt "+zz"
	"+00"               = fmt dt "+00"
	"+0"                = fmt dt "+z"
	"+0"                = fmt dt "+0"

	"12:07:06"          = fmt dt "hh:mi:ss"
	"12:07:06 pm"       = fmt dt "hh:mi:ss am"
	"12:07:06"          = fmt dt "023:59:59"
	"00:07:06"          = fmt dt "011:59:59"
	"00:07:06 pm"       = fmt dt "011:59:59 am"
	"12:07:06"          = fmt dt "012:59:59"
	"12:07:06 pm"       = fmt dt "012:59:59 am"
	
	dt: 09/03/2004/0:07:06.05432-14:00
	"00"                = fmt dt "hh23"
	"00"                = fmt dt "023"
	"00"                = fmt dt "hhh"
	"0"                 = fmt dt "h23"
	"0"                 = fmt dt "23"
	"12"                = fmt dt "hh12"
	"12"                = fmt dt "h12"
	"00"                = fmt dt "hh11"
	"00"                = fmt dt "011"
	"0"                 = fmt dt "h11"
	"0"                 = fmt dt "11"
	
	"-1400"             = fmt dt "+ZZZZ"
	"-1400"             = fmt dt "+0000Z"
	"-14:00"            = fmt dt "+ZZ:ZZ"
	"-14:00"            = fmt dt "+00:00Z"
	"-1400"             = fmt dt "+zzzz"
	"-1400"             = fmt dt "+0000"
	"-14:00"            = fmt dt "+zz:zz"
	"-14:00"            = fmt dt "+00:00"
	"-14:00"            = fmt dt "+z:zz"
	"-14:00"            = fmt dt "+0:00"
	"-14"               = fmt dt "+zz"
	"-14"               = fmt dt "+00"
	"-14"               = fmt dt "+z"
	"-14"               = fmt dt "+0"

	dt: 02/03/0004/08:07:06.05432
	"0004"              = fmt dt "yyyy"
	"4"                 = fmt dt "1999"
	"04"                = fmt dt "yy"
	
	dt/year: 12004										;-- can't be loaded directly (#5023)
	"12004"             = fmt dt "yyyy"
	"12004"             = fmt dt "1999"
	"04"                = fmt dt "yy"
	"+12004 CE"         = fmt dt "+yyyy CE"
	
	dt: 02/03/-0004/08:07:06.05432
	"0004 Before Common Era" = fmt dt "yyyy Common Era"
	"0004 BCE"          = fmt dt "yyyy CE"
	"0004 BC"           = fmt dt "yyyy AD"
	"-0004"             = fmt dt "+yyyy"
	"-4"                = fmt dt "+1999"
	"04"                = fmt dt "yy"
	"-04"               = fmt dt "+yy"
	"-1"                = fmt dt "+c"
	"I BC"              = fmt dt "XX AD"
	
	"04'04"             = fmt dt "yy''yy"				;-- quotation rules tricks
	"04'04"             = fmt dt "yy''''yy"
	"04y'y04"           = fmt dt "yy'y''y'yy"
	"04'y'y'04"         = fmt dt "yy'''y''y'''yy"
]