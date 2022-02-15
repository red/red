Red [
	Title:  "Ordinal number formatter"
	Author: @hiiamboris
	Rights: "Copyright (C) 2021-2022 Red Foundation. All rights reserved."
    License: {
        Distributed under the Boost Software License, Version 1.0.
        See https://github.com/red/red/blob/master/BSL-License.txt
    }
]

; #include %../common/assert.red
; #include %../common/new-each.red
; #include %locale.red

formatting/as-ordinal: as-ordinal: function [
	"Format a number as ordinal quantity"
	number [integer!]									;@@ should we accept float?
	/in locale [word! none!] "Locale to express value in"
][
	sl: system/locale
	locale: any [locale sl/locale]
	sl/tools/expand-locale locale
	lang: to word! first split form locale #"_"			;@@ maybe stash language in the locale data?
	quantity: sl/ordinal/:lang							;-- call ordinal function
		n: absolute number								;-- number itself
		1 + to integer! log-10 max 1.0 n  				;-- digit count
	rejoin [number sl/list/:locale/numbers/ordinal-suffixes/:quantity]
]

#assert [
	"1st"   = as-ordinal/in 1   'en
	"2nd"   = as-ordinal/in 2   'en
	"3rd"   = as-ordinal/in 3   'en
	"4th"   = as-ordinal/in 4   'en
	"5th"   = as-ordinal/in 5   'en
	"0th"   = as-ordinal/in 0   'en
	"11th"  = as-ordinal/in 11  'en
	"123rd" = as-ordinal/in 123 'en
	"123rd" = as-ordinal/in 123 'en_US
	"123rd" = as-ordinal/in 123 'en_GB
	"123-й" = as-ordinal/in 123 'ru
	"123-й" = as-ordinal/in 123 'ru_RU
	"123-й" = as-ordinal/in 123 'ru_BY
]
