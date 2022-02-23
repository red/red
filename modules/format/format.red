Red [
	Title:       "General format function (dispatcher)"
	Description: https://github.com/hiiamboris/red-formatting/discussions/21
	Author:      @hiiamboris
	Rights:      "Copyright (C) 2021-2022 Red Foundation. All rights reserved."
    License: {
        Distributed under the Boost Software License, Version 1.0.
        See https://github.com/red/red/blob/master/BSL-License.txt
    }
]

; #include %../common/include-once.red
; #include %../common/assert.red
; #include %format-date-time.red
; #include %format-number-with-mask.red

context [
	fetch-named-mask: function [name [word! path!] locale [word! none!] contexts [block!]] [
		locale: system/locale/tools/expand-locale locale
		loc-data: system/locale/list/:locale
		nums: loc-data/numbers
		hives: [nums/(nums/system)/masks loc-data/calendar/masks]
		if path? name [name: as [] name]
		if empty? contexts [contexts: [[]]]
		foreach hive hives [
			hive: get hive
			foreach ctx contexts [
				path: as path! compose/into [hive (ctx) (name)] clear []
				mask: attempt [get/any path]
				if any [string? :mask  any-function? :mask] [return :mask]
			]
		]
		none
	]
	
	set 'format formatting/format: function [ 
		"Format a value"
		value  [number! money! date! time!] "Other types TBD"
		format [word! path! string!] "Mask or named format, e.g. 'datetime/full"
		/in locale [word! none!] "Locale to express value in"
	][
		switch type?/word value [
			integer! float! percent! money! [
				if any [word? format path? format] [
					format: any [
						fetch-named-mask format locale [number money []]
						do make error! rejoin ["Unknown format name: "format]
						; ERROR "Unknown format name: (format)"
					]
					if any-function? :format [format: format :value]
				]
				formatting/format-number-with-mask/in value format locale
			]
			date! time! [
				if any [word? format path? format] [
					ctx: case [
						time? :value [[time [] datetime]]		;-- fallback to datetime formats when only time is given
						date? :value [[datetime date []]]
					]
					format: any [
						fetch-named-mask format locale ctx
						fetch-named-mask format locale: 'red ctx	;-- fallback for standardized formats
						do make error! rejoin ["Unknown format name: "format]
						; ERROR "Unknown format name: (format)"
					]
					if any-function? :format [format: format :value]
				]
				formatting/format-date-time/in value format locale
			]
		]
	]
]

#assert [
	dt: 2-Feb-2022/21:50:06.66102+03:00
	"Wednesday, February 2, 2022 at 9:50:06 PM GMT+03:00" = format/in dt 'full            'en 
	"Wednesday, February 2, 2022 at 9:50:06 PM GMT+03:00" = format/in dt 'full            'en_US 
	           "February 2, 2022 at 9:50:06 PM GMT+3"     = format/in dt 'long            'en_US
	           "Feb 2, 2022, 9:50:06 PM"                  = format/in dt 'medium          'en_US
	           "2/2/22, 9:50 PM"                          = format/in dt 'short           'en_US
	"Wednesday, February 2, 2022 at 9:50:06 PM GMT+03:00" = format/in dt 'datetime/full   'en_US 
	           "February 2, 2022 at 9:50:06 PM GMT+3"     = format/in dt 'datetime/long   'en_US
	           "Feb 2, 2022, 9:50:06 PM"                  = format/in dt 'datetime/medium 'en_US
	           "2/2/22, 9:50 PM"                          = format/in dt 'datetime/short  'en_US
	"Wednesday, February 2, 2022"                         = format/in dt 'date/full       'en_US 
	           "February 2, 2022"                         = format/in dt 'date/long       'en_US
	           "Feb 2, 2022"                              = format/in dt 'date/medium     'en_US
	           "2/2/22"                                   = format/in dt 'date/short      'en_US
	"9:50:06 PM GMT+03:00"                                = format/in dt 'time/full       'en_US 
	"9:50:06 PM GMT+3"                                    = format/in dt 'time/long       'en_US
	"9:50:06 PM"                                          = format/in dt 'time/medium     'en_US
	"9:50 PM"                                             = format/in dt 'time/short      'en_US
	"среда, 2 февраля 2022 г., 21:50:06 GMT+03:00"        = format/in dt 'full            'ru
	"среда, 2 февраля 2022 г., 21:50:06 GMT+03:00"        = format/in dt 'full            'ru_RU
	       "2 февраля 2022 г., 21:50:06 GMT+3"            = format/in dt 'long            'ru_RU
	       "2 февр. 2022 г., 21:50:06"                    = format/in dt 'medium          'ru_RU
	       "02.02.2022, 21:50"                            = format/in dt 'short           'ru_RU
	       
	"2022-02-02T21:50:06.661+03:00"     = format dt 'RFC3339
	"2022-02-02T21:50:06.661+03:00"     = format dt 'Atom
	"2022-02-02T21:50:06.661+03:00"     = format dt 'W3C
	"2022-02-02T21:50:06.661+03:00"     = format dt 'W3C-DTF
	"20220202T215006+0300"              = format dt 'ISO8601
	"2022-02-02T21:50:06+0300"          = format dt 'ISO-8601
	"Wed, 02 Feb 22 21:50:06 +0300"     = format dt 'RFC822
	"Wed, 02 Feb 22 18:50:06 GMT"       = format dt 'RFC822-GMT
	"Wed, 02 Feb 2022 21:50:06 +0300"   = format dt 'RFC5322
	"Wed, 02 Feb 2022 21:50:06 +0300"   = format dt 'RFC2822
	"Wed, 02 Feb 2022 21:50:06 +0300"   = format dt 'RFC1123
	"Wed, 02 Feb 2022 21:50:06 +0300"   = format dt 'RSS
	"Wed, 02 Feb 2022 18:50:06 GMT"     = format dt 'HTTP
	"Wed, 02 Feb 2022 18:50:06 GMT"     = format dt 'HTTP1.1
	"Wed, 02 Feb 2022 18:50:06 GMT"     = format dt 'RFC7231
	"Wed, 02 Feb 2022 18:50:06 GMT"     = format dt 'RFC5322-GMT
	"Wed, 02 Feb 2022 18:50:06 GMT"     = format dt 'RFC2822-GMT
	"Wed, 02 Feb 2022 18:50:06 GMT"     = format dt 'RFC2616
	"Wednesday, 02-Feb-22 18:50:06 GMT" = format dt 'RFC850
	"Wednesday, 02-Feb-22 18:50:06 GMT" = format dt 'USENET
	"Wed, 02 Feb 22 21:50:06 +0300"     = format dt 'RFC1036
	
	(format now/date + dt/time 'RFC1036) = (format dt/time 'RFC1036)	;-- given time should use today's date 
	(format now/date + dt/time 'full) = (format dt/time 'datetime/full)	
]
