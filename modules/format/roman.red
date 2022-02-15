Red [
	Title:   "Roman numerals for Red formatting system"
	Author:  @hiiamboris
	Rights:  "Copyright (C) 2021-2022 Red Foundation. All rights reserved."
    License: {
        Distributed under the Boost Software License, Version 1.0.
        See https://github.com/red/red/blob/master/BSL-License.txt
    }
    Notes: {
    	In Unicode there are also single-letter codepoints like #"^(2172)"
    	not sure if it's worth supporting them, e.g. for lists?
    }
]

; #include %../common/assert.red
; #include %../common/new-each.red

context [
	roman: [											;-- ordered, so not a map
		0      "N"
		100000 "ↈ"
		90000  "ↂↈ"
		50000  "ↇ"
		40000  "ↂↇ"
		10000  "ↂ"
		9000   "Mↂ"
		5000   "ↁ"
		4000   "Mↁ"
		1000   "M"
		900    "CM"
		500    "D"
		400    "CD"
		100    "C"
		90     "XC"
		50     "L"
		40     "XL"
		10     "X"
		9      "IX"
		5      "V"
		4      "IV"
		1      "I"
	]
	
	set 'as-roman formatting/as-roman: function [
		"Convert integer number into a Roman numeral"
		num [integer!] "0 to 399'999"
	][
		case [
			all [0 < num num < 400000] [
				r: clear ""
				foreach [n s] skip roman 2 [
					append/dup r s to integer! num / n
					num: num % n
				]
				copy r
			]
			num = 0 [copy select roman 0]
			'else [cause-error 'script 'invalid-arg [num]]
		]
	]
]

#assert [
	"N"       = as-roman 0
	"I"       = as-roman 1
	"II"      = as-roman 2
	"III"     = as-roman 3
	"IV"      = as-roman 4
	"V"       = as-roman 5
	"VI"      = as-roman 6
	"XIV"     = as-roman 14
	"DCLXVI"  = as-roman 666
	error? try [as-roman -1]
]
