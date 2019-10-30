Red [
	Title:   "Binary tables and bit-arrays generator for the lexer"
	Author:  "Nenad Rakocevic"
	File: 	 %generate-misc-tables.red
	Tabs:	 4
	Rights:  "Copyright (C) 2014-2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

gen-bitarray: function [list][
	append/dup out: make binary! 32 null 32

	foreach c list [
		pos: (to-integer c) / 8 + 1
		bit: 1 << ((to-integer c) // 8)
		out/:pos: out/:pos or bit
	]
	print ["--gen-bitarray-- for" mold list]
	probe out
]

bin-classes: [
	C_BIN_SKIP										;-- 0
	C_BIN_BLANK										;-- 1
	C_BIN_LINE										;-- 2
	C_BIN_HEXA										;-- 3
	C_BIN_COMMENT									;-- 4
]

gen-bin16-table: function [][
	out: make binary! 256
	blank: charset "^-^M "
	hexa:  charset [#"A" - #"F" #"a" - #"f" #"0" - #"9"]
	
	repeat i 256 [
		c: to-char i - 1
		append out to-char case [
			find blank c [1]
			c = #"^/"    [2]
			find hexa c  [3]
			c = #";"	 [4]
			'else		 [0]
		]
	]
	print "--gen-bin16-table-- (lexer/bin16-classes)"
	probe out
]

gen-hexa-table: function [][
	out: make binary! 256
	digit: charset [#"0" - #"9"]
	upper: charset [#"A" - #"F"]
	lower: charset [#"a" - #"f"]
	
	repeat i 256 [
		c: to-char i - 1
		append out case [
			find digit c [to-char c - #"0"]
			find upper c [to-char c - #"A" + 10]
			find lower c [to-char c - #"a" + 10]
			'else		 [#{FF}]
		]
	]
	print "--gen-hexa-table-- (lexer/hexa-table)"
	probe out
]

date-classes: [
	C_DT_DIGIT			;-- 0		0-9
	C_DT_LETTER			;-- 1		abcdefghijlmnoprstuvy, ABCDEFGHIJLMNOPRSUVY
	C_DT_SLASH			;-- 2		/
	C_DT_DASH			;-- 3		-
	C_DT_T				;-- 4		T
	C_DT_W				;-- 5		W
	C_DT_PLUS			;-- 6		+
	C_DT_COLON			;-- 7		:
	C_DT_DOT			;-- 8		.
	C_DT_Z				;-- 9		Z
	C_DT_ILLEGAL		;-- 10		all the rest
	C_DT_EOF			;-- 11		EOF
]

gen-date-table: function [][
	out: make binary! 256
	digit: charset "0123456789"
	letter: charset "abcdefghijlmnoprstuvyABCDEFGHIJLMNOPRSUVY"
	
	repeat i 256 [
		c: to-char i - 1
		append out to-char case [
			find digit c	[0]
			find letter c	[1]
			c = #"/"    	[2]
			c = #"-"    	[3]
			c = #"T"    	[4]
			c = #"W"    	[5]
			c = #"+"    	[6]
			c = #":"    	[7]
			c = #"."	 	[8]
			c = #"Z"	 	[9]
			'else			[10]
		]
	]
	print "--gen-date-classes-table-- (lexer/date-classes)"
	probe out
]

gen-date-calc-table: function [][
	out: make binary! 256
	digit: charset "0123456789"
	lower: charset "abcdefghijlmnoprsuv"				;-- forces t and T to be zero (separator)
	upper: charset "ABCDEFGHIJLMNOPRSUV"
	yY: charset "yY"
	
	repeat i 256 [
		c: to-char i - 1
		append out to-char case [
			find digit c	[to-char c - #"0"]
			find lower c	[to-char c - 32]
			find upper c	[to-char c]
			find yY c    	[3]
			'else			[0]
		]
	]
	print "--gen-date-cumul-table-- (lexer/date-cumul)"
	probe out
]

gen-bitarray "BDELNPTbdelnpt"
gen-bitarray {/-~^^{}"}
gen-bin16-table
gen-hexa-table
gen-date-table
gen-date-calc-table