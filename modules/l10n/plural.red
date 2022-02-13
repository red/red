Red [
	Title:       "Plural number spelling rules for Red"
	Description: "Manually converted from CLDR"
	Author:      @hiiamboris
	Rights:      "Copyright (C) 2021 Red Foundation. All rights reserved."
	Notes: {
		Original CLDR rules are here:
		https://unicode-org.github.io/cldr-staging/charts/latest/supplemental/language_plural_rules.html
		https://github.com/unicode-org/cldr/blob/main/common/supplemental/plurals.xml
		https://github.com/unicode-org/cldr/blob/main/common/supplemental/ordinals.xml
	}
    License: {
        Distributed under the Boost Software License, Version 1.0.
        See https://github.com/red/red/blob/master/BSL-License.txt
        
        Source data license: https://github.com/unicode-cldr/cldr-core/blob/master/LICENSE
    }
]

;; operands, quote from http://unicode.org/reports/tr35/tr35-numbers.html#Operands
;; n 	absolute value of the source number.
;; i 	integer digits of n.
;; v 	number of visible fraction digits in n, with trailing zeros.
;; w 	number of visible fraction digits in n, without trailing zeros.
;; f 	visible fraction digits in n, with trailing zeros.
;; t 	visible fraction digits in n, without trailing zeros.
;; c 	compact decimal exponent value: exponent of the power of 10 used in compact decimal formatting.
;; e 	currently, synonym for ‘c’. however, may be redefined in the future.

;; !! w and c are not used in any locales so I removed them !!
;; most general spec for cardinals is then `n i v f t e`
;; most general spec for ordinals is `n i`

;@@ I wonder if they really *meant* `n` is the source number?
;@@ because if during formatting we round n=9.99999999 to 10
;@@ we should expect rule for n=10 to succeed but it won't
;@@ TODO: reconsider `n` value

system/locale/cardinal: to map! to block! object [
	af: bg: tr: func [n i v f t e] [pick [one other] n = 1]
	ar: function [n i v f t e] [
		r2: n % 100
		case [
			n = 0 ['zero]
			n = 1 ['one]
			n = 2 ['two]
			all [3 <= r2 r2 <= 10] ['few]
			r2 >= 11 ['many]
			'else ['other]
		]
	]
	cs: func [n i v f t e] [
		case [
			all [i = 1 v = 0] ['one]
			all [v = 0 2 <= i i <= 4] ['few]
			v <> 0 ['many]
			'else ['other]
		]
	]
	de: en: et: func [n i v f t e] [either all [i = 1 v = 0] ['one]['other]]
	es: func [n i v f t e] [
		case [
			n = 1 ['one]
			any [
				all [e = 0 v = 0 i <> 0 i % 1'000'000 = 0]
				not all [0 <= e e <= 5]
			] ['many]
			'else ['other]
		]
	]
	jp: ko: zh: func [n i v f t e] ['other]
	fr: func [n i v f t e] [
		case [
			any [i = 0 i = 1] ['one]
			any [
				all [e = 0 v = 0 i <> 0 i % 1'000'000 = 0]
				not all [0 <= e e <= 5]
			] ['many]
			'else ['other]
		]
	]
	he: func [n i v f t e] [
		case [
			v <> 0 ['other]
			i = 1 ['one]
			i = 2 ['two]
			all [n % 10 = 0 n >= 20] ['many]
			'else ['other]
		]
	]
	hi: func [n i v f t e] [either any [i = 0 n = 1] ['one]['other]]
	it: func [n i v f t e] [
		case [
			all [i = 1 v = 0] ['one]
			any [
				e < 0
				e > 5
				all [e = 0 i <> 0 v = 0 i % 1'000'000 = 0]
			] ['many]
			'else ['other]
		]
	]
	pl: function [n i v f t e] [
		r1: i % 10  r2: i % 100
		case [
			all [i = 1 v = 0] ['one]
			all [v = 0 all [2 <= r1 r1 <= 4] not all [12 <= r2 r2 <= 14]] ['few]
			all [
				v = 0
				any [
					all [i <> 1 r1 <= 1]
					r1 >= 5
					all [12 <= r2 r2 <= 14]
				]
			] ['many]
			'else ['other]
		]
	]
	pt: func [n i v f t e] [
		case [
			i <= 1 ['one] 
			any [
				e < 0
				e > 5
				all [e = 0 v = 0 i <> 0 i % 1'000'000 = 0]
			] ['many]
			'else ['other]
		]
	]
	ru: function [n i v f t e] [
		r1: i % 10  r2: i % 100
		case [
			all [v = 0 r1 = 1 r2 <> 11] ['one]
			all [v = 0 all [2 <= r1 r1 <= 4] not all [12 <= r2 r2 <= 14]] ['few]
			all [
				v = 0
				any [r1 = 0 r1 >= 5 all [11 <= r2 r2 <= 14]]
			] ['many]
			'else ['other]
		]
	]
]
	
;; only `n` and `i` are used by ordinals according to CLDR table
;; so I removed the extra args (even `i` is used rarely here)
;; key to that seems that ordinals only make sense for integers
;; but I think functions should accept floats as well for more robustness (e.g. float 8.0 formatted as 8th)
system/locale/ordinal: to map! to block! object [
	af: ar: bg: cs: de: es: et: he: jp: ko: pl: pt: ru: zh: func [n i] ['other]
	en: function [n i] [
		r1: n % 10  r2: n % 100
		case [
			all [r1 = 1 r2 <> 11] ['one] 
			all [r1 = 2 r2 <> 12] ['two] 
			all [r1 = 3 r2 <> 13] ['few] 
			'else ['other]
		]
	]
	fr: func [n i] [pick [one other] n = 1]
	hi: func [n i] [
		;; switch is type-sensitive, select is too (bug), so have to use case
		;; case with `=` is also more tolerant to floating point imprecisions
		case [
			n = 1 ['one]
			any [n = 2 n = 3] ['two]
			n = 4 ['few]
			n = 6 ['many]
			'else ['other]
		]
	]
	it: func [n i] [
		either any [n = 11 n = 8 n = 80 n = 800] ['many]['other]	;-- = to support floats too 
	] 
]