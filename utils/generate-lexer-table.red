Red [
	Title:   "Generates low-level lexer table"
	Author:  "Nenad Rakocevic"
	File: 	 %generate-lexer-tables.r
	Tabs:	 4
	Rights:  "Copyright (C) 2019 Red Foundation. All rights reserved."
	License: "BSD-3 - https://github.com/red/red/blob/master/BSD-3-License.txt"
	Note: {
		Outputs: %runtime/lexer-transitions.reds
	}
]

context [
	states: [
		S_START							;-- 0
		S_LINE_CMT						;-- 1
		S_LINE_STR						;-- 2
		S_SKIP_STR						;-- 3
		S_M_STRING						;-- 4
		S_SKIP_MSTR						;-- 5
		S_FILE_1ST						;-- 6
		S_FILE							;-- 7
		S_FILE_HEX1						;-- 8
		S_FILE_HEX2						;-- 9
		S_FILE_STR						;-- 10
		S_SLASH							;-- 11
		S_SHARP							;-- 12
		S_BINARY						;-- 13
		S_LINE_CMT2						;-- 14
		S_CHAR							;-- 15
		S_SKIP_CHAR						;-- 16
		S_CONSTRUCT						;-- 17
		S_ISSUE							;-- 18
		S_NUMBER						;-- 19
		S_DOTNUM						;-- 20
		S_DECIMAL						;-- 21
		S_DEC_SPECIAL					;-- 22
		S_TUPLE							;-- 23
		S_DATE							;-- 24
		S_TIME_1ST						;-- 25
		S_TIME							;-- 26
		S_PAIR_1ST						;-- 27
		S_PAIR							;-- 28
		S_MONEY_1ST						;-- 29
		S_MONEY							;-- 30
		S_MONEY_DEC						;-- 31
		S_LESSER						;-- 32
		S_TAG							;-- 33
		S_TAG_STR						;-- 34
		S_SKIP_STR2						;-- 35
		S_TAG_STR2						;-- 36
		S_SKIP_STR3						;-- 37
		S_SIGN							;-- 38
		S_WORD							;-- 39
		S_WORDSET						;-- 40
		S_URL							;-- 41
		S_EMAIL							;-- 42
		S_PATH							;-- 43
		S_PATH_NUM						;--	44
		S_PATH_WORD						;-- 45
		--EXIT_STATES--					;-- 46
		T_EOF							;-- 47
		T_ERROR							;-- 48
		T_BLK_OP						;-- 49
		T_BLK_CL						;-- 50
		T_PAR_OP						;-- 51
		T_PAR_CL						;-- 52
		T_STRING						;-- 53
		T_WORD							;-- 54
		T_FILE							;-- 55
		T_REFINE						;-- 56
		T_BINARY						;-- 57
		T_CHAR							;-- 58
		T_MAP_OP						;-- 59
		T_CONS_MK						;-- 60
		T_ISSUE							;-- 61
		T_PERCENT						;-- 62
		T_INTEGER						;-- 63
		T_FLOAT							;-- 64
		T_TUPLE							;-- 65
		T_DATE							;-- 66
		T_PAIR							;-- 67
		T_TIME							;-- 68
		T_MONEY							;-- 69
		T_TAG							;-- 70
		T_URL							;-- 71
		T_EMAIL							;-- 72
		T_PATH							;-- 73
	]

	CSV-table: %../docs/lexer/lexer-FSM.csv
	;-- Read states from CSV file
	csv: read CSV-table

	;-- Determine CSV separator
	sep: [#";" 0 #"," 0]
	parse csv [some [#";" (sep/2: sep/2 + 1) | #"," (sep/4: sep/4 + 1) | skip]]
	sort/skip/all/compare sep 2 func [a b][a/2 < b/2]

	;-- Decode CSV
	matrix: load-csv/with read CSV-table first sep

	table: make binary! 2000

	;-- Generate the table content
	foreach line next matrix [
		out: make block! 50	
		foreach s next line [	
			either pos: find states to-word s [
				append out (index? pos) - 1
			][
				do make error! form reduce ["Error: state" s "not found"]
			]
		]
		append/only table out
	]

	template: compose/deep [Red/System [
		Note: "Auto-generated lexical scanner transitions table"
	]
	
	#enum lex-states! [
		(states)
	]
	
	transitions: (table)
	]

	write %../runtime/lexer-transitions.reds mold/only template
]
()