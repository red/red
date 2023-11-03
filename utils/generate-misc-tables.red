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
		pos: to-integer (to-integer c) / 8 + 1
		bit: 1 << ((to-integer c) // 8)
		out/:pos: out/:pos or bit
	]
	print ["--gen-bitarray-- for" mold list]
	probe out
]

bin-classes: [
	C_BIN_ILLEGAL									;-- 0
	C_BIN_BLANK										;-- 1
	C_BIN_HEXA										;-- 2
	C_BIN_COMMENT									;-- 3
]

gen-bin16-table: function [][
	out: make binary! 256
	blank: charset "^-^/^M "
	hexa:  charset [#"A" - #"F" #"a" - #"f" #"0" - #"9"]
	
	repeat i 256 [
		c: to-char i - 1
		append out to-char case [
			find blank c [1]
			find hexa c  [2]
			c = #";"	 [3]
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

float-classes: [
	C_FL_ILLEGAL									;-- 0
	C_FL_SIGN										;-- 1
	C_FL_DIGIT										;-- 2
	C_FL_EXP										;-- 3
	C_FL_DOT										;-- 4
	C_FL_QUOTE										;-- 5
	C_FL_EOF										;-- 6
]

gen-float-classes-table: function [][
	out: make binary! 256
	digit: charset [#"0" - #"9"]
	
	repeat i 256 [
		c: to-char i - 1
		append out case [
			find digit c [2]
			c = #"."     [4]
			find "+-" c	 [1]
			find "eE" c	 [3]
			c = #"'"	 [5]
			'else		 [0]
		]
	]
	print "--gen-fl-classes-- (lexer/fl-classes)"
	probe out
]

gen-bitarray {@/-~^^{}"}
gen-bin16-table
gen-hexa-table
gen-float-classes-table
