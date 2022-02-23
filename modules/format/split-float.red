Red [
	Title:       "Basic number formatter"
	Description: https://github.com/hiiamboris/red-formatting/discussions/11
	Author:      @hiiamboris
	Rights:      "Copyright (C) 2021-2022 Red Foundation. All rights reserved."
    License: {
        Distributed under the Boost Software License, Version 1.0.
        See https://github.com/red/red/blob/master/BSL-License.txt
    }
    Notes: {
    	#include it into %environment/routines.reds to avoid recompilation
    }
]


formatting: context [
	;; have to list all other funcs right here, or compiler will crash after next `make formatting`
	charmaps: #()										;-- new items added on locale change
	build-charmap:
	update-charmap:
	as-roman:
	as-ordinal:
	date-time-ctx:
	date-time-rules:
	form-integer:										;-- user-facing wrapper
	form-integer*:										;-- zero-alloc version
	format-date-time:
	number-ctx:
	format-number-with-mask:
	form-logic:
	logic-formats:
	translate:
	capitalize:
	format:
		none

	split-float*: routine [
		"Format a number into separate parts (internal use only)"
		number  [float!]   "To be formatted"
		exp     [integer!] "Exponent base to express it in"
		figures [integer!] "Nonnegative number of significant figures to keep (whole + fractional), 0 = unlimited"
		result  [block!]   "Block of five strings"
		return: [block!]   {[sign whole-part frac-part exp-sign exp-part], e.g. 1.230e4 -> ["+" "1" "230" "+" "4"]}
		/local
			pdot sign len len2 [integer!]
			str str2 [c-string!]
			ssign swhole sfrac sesign sexp [red-string!]
			zero [logic!]
	][
		if figures < 0 [figures: 0]							;-- set to unlimited for negative
		assert all [exp >= -5000 exp <= 5000]				;-- in debug mode warn the coder that he's doing smth bad
		if exp < -5000 [exp: -5000]							;-- min 80bit=~10^-4951, min 64bit=~10^-324 
		if exp >  5000 [exp:  5000]							;-- we don't want to alloc more than 10k per number anyway
		pdot: 0 sign: 0 len: 0
		str: dtoa/float-to-ascii number figures :pdot :sign :len no		;-- figures=0 here means use all digits
		;; returns: pdot = 9999 for specials, 9998 for zero
		;;          sign = 1 for negative except -inf, 0 otherwise
		; print-wide [pdot sign len str lf]
		if pdot = 9999 [fire [TO_ERROR(script invalid-arg) number]]		;-- INF/NAN cannot be split into parts
		zero: pdot = 9998
		pdot: pdot - exp
		str2: str
		case [
			zero [str: "00"  str2: str  pdot: 1  len: 2]	;-- no allocation needed
			pdot < 1 [										;-- prepend zeroes
				len2: len
				len: len - pdot + 1  pdot: 1
				str: as c-string! allocate len
				fill  as byte-ptr! str  as byte-ptr! str + len  #"0"
				copy-memory  as byte-ptr! str + len - len2  as byte-ptr! str2  len2
			]
			pdot >= len [									;-- append zeroes
				len2: len
				len: pdot + 1
				str: as c-string! allocate len
				fill  as byte-ptr! str  as byte-ptr! str + len  #"0"
				copy-memory  as byte-ptr! str  as byte-ptr! str2  len2
			]
			true [0]										;-- no action needed
		]
		
		assert 5 = block/rs-length? result
		
		swhole: as red-string! block/rs-abs-at result 1
		assert TYPE_STRING = TYPE_OF(swhole)
		string/rs-reset swhole
		string/concatenate-literal-part swhole str pdot
		
		sfrac: as red-string! block/rs-abs-at result 2
		assert TYPE_STRING = TYPE_OF(sfrac)
		string/rs-reset sfrac
		string/concatenate-literal-part sfrac str + pdot len - pdot
		
		if str2 <> str [free as byte-ptr! str]
		
		str:   integer/form-signed either exp < 0 [0 - exp][exp]
		sexp:  as red-string! block/rs-abs-at result 4
		assert TYPE_STRING = TYPE_OF(sexp)
		string/rs-reset sexp
		string/concatenate-literal sexp str
		
		
		str:    either exp < 0 ["-"]["+"]
		sesign: as red-string! block/rs-abs-at result 3
		assert TYPE_STRING = TYPE_OF(sesign)
		string/rs-reset sesign
		string/concatenate-literal sesign str
		
		str:   either number < 0.0 ["-"]["+"]
		ssign: as red-string! block/rs-abs-at result 0
		assert TYPE_STRING = TYPE_OF(ssign)
		string/rs-reset ssign
		string/concatenate-literal ssign str
		
		as red-block! SET_RETURN(result)
	]

; probe split-float 1.2345e-100 -100 0
]

;@@ need this?
split-float: function [
	"Format a number into separate parts"
	number  [float!]   "To be formatted"
	exp     [integer!] "Exponent base to express it in"
	figures [integer!] "Nonnegative number of significant figures to keep (whole + fractional), 0 = unlimited"
	; return: [block!]   {[sign whole-part frac-part exp-sign exp-part], e.g. 1.230e4 -> ["+" "1" "230" "+" "4"]}
][
	copy/deep formatting/split-float* number exp figures ["" "" "" "" ""]  
]
	
